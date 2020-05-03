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

local newHttpQueueCheck = t.strict(t.strictInterface({
    retryAfter = t.union(
        t.strictInterface({
            header = t.string
        }),
        t.strictInterface({
            cooldown = validInt
        })
    ),
    maxSimultaneousSendOperations = t.optional(validInt)
}))

local pushCheck = t.strict(t.tuple(guards.isHttpRequest, t.optional(guards.isHttpRequestPriority)))

--[[**
    Creates an HttpQueue. It is a self-regulating queue for REST APIs that impose rate limits. When you push a request to the queue,
    the queue will send the ones added first to the remote server (unless you specify a priority). The queue automatically handles
    the rate limits in order to, as humanly as possible, respect the service's rate limits and Terms of Service.

    A queue is NOT A SILVER BULLET NEITHER A GUARANTEE of not spamming invalid requests, though. Depending on your game's
    playerbase/number of servers compared to the rate limit of the services, it might not scale well.

    @param options The options for the queue.
    @param [t:string|nil] options.retryAfter.header If the reqeuest is rate limited, look for this header to determine how long to wait (in seconds). If defined, don't provide options.retryAfter.cooldown
    @param [t:number|nil] options.retryAfter.cooldown Define a cooldown period directly. If defined, do not define options.retryAfter.header
    @param [t:number|nil] options.maxSimultaneousSendOperations How many requests should be sent at the same time (maximum). Defaults to 10.
**--]]
function HttpQueue.new(options)
    newHttpQueueCheck(options)

    local prioritaryQueue = {}
    local regularQueue = {}

    local queueSize = 0

    local queueExecutor = coroutine.create(function()
        local interrupted = false
        local restart = false
        local main = coroutine.running()
        local availableWorkers = options.maxSimultaneousSendOperations or 10
        local cooldown
        if options.retryAfter.header then
            local header = options.retryAfter.header
            cooldown = function(response)
                wait(response.Headers[header])
            end
        else
            cooldown = function()
                wait(options.retryAfter.cooldown)
            end
        end

        local function sendNode(node)
            node.Data.Request:Send():andThen(function(response)
                if response.StatusCode == 429 then
 
                    interrupted = true
                    restart = true
                    cooldown(response)
                    interrupted = false

                    sendNode(node) -- try again!
                else
                    coroutine.resume(node.Data.Callback, response)

                    -- Resolve the request
                    if node.Next then
                        node.Next.Prev = nil
                    end
                    node.Next = nil

                    -- Release resources
                    queueSize = queueSize - 1
                    availableWorkers = availableWorkers + 1
                    if coroutine.status(main) == "suspended" then
                        coroutine.resume(main)
                    end
                end
            end)
        end

        while true do
            restart = false
            while prioritaryQueue.First do
                while interrupted or availableWorkers == 0 do
                    coroutine.yield()
                end
                if restart then
                    break
                end

                local node = prioritaryQueue.First
                availableWorkers = availableWorkers - 1

                sendNode(node)

                prioritaryQueue.First = node.Next
                if not prioritaryQueue.First then
                    prioritaryQueue.Last = nil
                end
            end

            if restart then
                -- LANGUAGE EXTENSION: LUAU SUPPORTS CONTINUE
                continue
            end

            while regularQueue.First do
                while interrupted or availableWorkers == 0 do
                    coroutine.yield()
                end
                if restart then
                    break
                end

                local node = regularQueue.First
                availableWorkers = availableWorkers - 1

                sendNode(node)

                regularQueue.First = node.Next
                if not regularQueue.First then
                    regularQueue.Last = nil
                end
            end

            if not restart then
                coroutine.yield()
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

        if not priority or priority == Priority.Normal then
            datautil.addNodeToLast(datautil.newLLNode(requestBody), regularQueue)
        elseif priority == Priority.Prioritary then
            datautil.addNodeToLast(datautil.newLLNode(requestBody), prioritaryQueue)
        elseif priority == Priority.First then
            datautil.addNodeToFirst(datautil.newLLNode(requestBody), prioritaryQueue)
        end
        queueSize = queueSize + 1

        coroutine.resume(queueExecutor)
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
