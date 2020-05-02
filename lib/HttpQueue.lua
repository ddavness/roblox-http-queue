--[[
    File: http-queue/HttpQueue.lua
    Description: Creates a self-regulating queue for rate-limited services

    SPDX-License-Identifier: MIT
]]

local Priority = require(script.Parent.HttpRequestPriority)
local datautil = require(script.Parent.DataUtils)
local guards = require(script.Parent.TypeGuards)
local deps = require(script.Parent.DependencyLoader)

local Promise, t = deps.Promise, deps.t

local HttpQueue = {}

local validInt = t.intersection(t.integer, t.numberPositive)
local newHttpQueueCheck = t.strict(t.tuple(t.option(t.string), t.option(t.string), t.option(t.string), t.option(validInt), t.option(validInt)))
local pushCheck = t.strict(t.tuple(guards.isHttpRequest, t.option(guards.isHttpRequestPriority)))

--[[**
    Creates an HttpQueue. It is a self-regulating queue for REST APIs that impose rate limits. When you push a request to the queue,
    the queue will send the ones added first to the remote server (unless you specify a priority). The queue automatically handles
    the rate limits in order to, as humanly as possible, respect the service's rate limits and Terms of Service.

    A queue is NOT A SILVER BULLET NEITHER A GUARANTEE of not spamming invalid requests, though. Depending on your game's
    playerbase/number of servers compared to the rate limit of the services, it might not scale well.

    @param [t:String|nil] retryAfterHeader The header the queue will look for if rate limits are exceeded. Defaults to "Retry-After"
    @param [t:String|nil] rateLimitCapHeader The header the queue will look for to determine the global rate limit. Not all services provide this header - and that's okay.
    @param [t:String|nil] availableRequestsHeader The header the queue will look for to determine the available request quota. Not all services provide this header - and that's okay.
    @param [t:number|nil] reserveSlots How many request slots to allocate ahead of time. This will not impose a limit to the number of requests you can push to the queue - it's purely for performance reasons.
    @param [t:number|nil] simultaneousSendCap How many requests should be sent at the same time (maximum). Defaults to 10.
**--]]
function HttpQueue.new(retryAfterHeader, rateLimitCapHeader,
                       availableRequestsHeader, reserveSlots, simultaneousSendCap)
    newHttpQueueCheck(retryAfterHeader, rateLimitCapHeader,
        availableRequestsHeader, reserveSlots, simultaneousSendCap)

    local headers = {
        RetryAfter = retryAfterHeader or "Retry-After",
        RateLimit = rateLimitCapHeader,
        Available = availableRequestsHeader
    }

    local mutex = datautil.newMutex()

    local prioritaryQueue = {}
    local regularQueue = {}
    if reserveSlots then
        prioritaryQueue = table.create(reserveSlots)
        regularQueue = table.create(reserveSlots)
    end

    local queueSize = 0

    local queueExecutor = coroutine.wrap(function()
        local interrupted = false
        local waiting = nil
        local availableWorkers = simultaneousSendCap or 10

        local function sendNode(node)
            node.Data.Request:Send():andThen(function(response)
                if response.StatusCode == 429 or response.StatusCode == 503 then
                    mutex.unlock()
                    interrupted = true
                    wait(response.Headers[headers.RetryAfter] or response.Headers["Retry-After"])
                    interrupted = false
                    sendNode(node) -- try again!
                else
                    coroutine.resume(node.Data.Callback, response)

                    -- Resolve the request
                    node.Next.Prev = nil
                    node.Next = nil

                    -- Release resources
                    queueSize = queueSize - 1
                    availableWorkers = availableWorkers + 1
                    if waiting then
                        coroutine.resume(waiting)
                        waiting = nil
                    end
                end
            end)
        end

        while true do
            -- Do the prioritary queue
            mutex.lock()
            while prioritaryQueue.First do
                while interrupted or availableWorkers == 0 do
                    waiting = coroutine.running()
                    coroutine.yield()
                end

                local node = prioritaryQueue.First
                availableWorkers = availableWorkers - 1

                sendNode(node)

                prioritaryQueue.First = node.Next
            end

            if interrupted then
                break
            end
        end
    end)

    local httpQueue = {}

    function httpQueue:Push(request, priority)
        pushCheck(request, priority)

        local requestBody = {Request = request}
        local promise = Promise.async(function(resolve, reject)
            requestBody.Callback = coroutine.running()
            local response = coroutine.yield()
            if response.ConnectionSuccessful then
                resolve(response)
            else
                reject(response)
            end
        end)

        mutex.lock()

        if not priority or priority == Priority.Normal then
            datautil.addNodeToLast(datautil.newLLNode(requestBody), regularQueue)
        elseif priority == Priority.Prioritary then
            datautil.addNodeToLast(datautil.newLLNode(requestBody), prioritaryQueue)
        elseif priority == Priority.First then
            datautil.addNodeToFirst(datautil.newLLNode(requestBody), prioritaryQueue)
        end
        queueSize = queueSize + 1

        mutex.unlock()

        queueExecutor()
        return promise
    end

    function httpQueue:AwaitPush(request, priority)
        local _, response = self:Push(request, priority):await()
        return response
    end

    function httpQueue:QueueSize()
        return queueSize
    end

    return setmetatable(httpQueue, {
        __metatable = "HttpQueue",
        __index = function(_, index)
            error("Attempt to index non-existant value HttpQueue." .. tostring(index))
        end
    })
end

return setmetatable(HttpQueue, {
    __metatable = "HttpQueue",
    __index = function(_, index)
        error("Attempt to index non-existant value HttpQueue." .. tostring(index))
    end
})
