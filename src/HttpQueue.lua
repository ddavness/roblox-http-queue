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

local newHttpQueueCheck = t.strict(t.tuple(t.option(t.string), t.option(t.string), t.option(t.string), t.option(t.number)))
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
**--]]
function HttpQueue.new(retryAfterHeader, rateLimitCapHeader,
                       availableRequestsHeader, reserveSlots)
    newHttpQueueCheck(retryAfterHeader, rateLimitCapHeader,
        availableRequestsHeader, reserveSlots)

    local headers = {
        RetryAfter = retryAfterHeader or "Retry-After",
        RateLimit = rateLimitCapHeader,
        Available = availableRequestsHeader
    }

    local mutex = datautil.newMutex()
    local prioritaryQueue = {}
    local regularQueue = {}

    local queueExecutor = coroutine.wrap(function()
        local interrupted = false
        while true do
            -- Do the prioritary queue
            mutex.lock()
            while prioritaryQueue.First do
                local node = prioritaryQueue.First

                node.Data.Request:Send():andThen(function(response)
                    if response.StatusCode == 429 or response.StatusCode == 503 then
                        mutex.unlock()
                        interrupted = true
                        wait(response.Headers[headers.RetryAfter] or response.Headers["Retry-After"])
                        break
                    else
                        coroutine.resume(node.Data.Callback, response)
                    end
                end)

                -- Resolve the request
                node.Next.Prev = nil
                prioritaryQueue.First = node.Next
                node.Next = nil
            end

            if interrupted then
                break
            end
        end
    end)

    if reserveSlots then
        prioritaryQueue = table.create(reserveSlots)
        regularQueue = table.create(reserveSlots)
    end

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

        mutex.unlock()

        queueExecutor()
        return promise
    end

    function httpQueue:AwaitPush(request, priority)
        local _, response = self:Push(request, priority):await()
        return response
    end

    function httpQueue:QueueSize()
        return #prioritaryQueue + #regularQueue
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
