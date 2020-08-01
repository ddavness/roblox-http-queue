--[[
    File: http-queue/HttpQueue.lua
    Description: Creates a self-regulating queue for rate-limited services

    SPDX-License-Identifier: MIT
]]

local Priority = require(script.Parent.HttpRequestPriority)
local newHttpResponse = require(script.Parent.HttpResponse)

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
        }),
        t.strictInterface({
            callback = t.callback
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
    @param [t:number(HttpResponse)|nil] options.retryAfter.callback Pass a function that takes a rate-limited response and returns the cooldown period (in seconds). If defined, do not define options.retryAfter.header
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
        elseif options.retryAfter.cooldown then
            local cooldown = options.retryAfter.cooldown
            cooldown = function()
                wait(cooldown)
            end
        else
            local callback = options.retryAfter.callback
            cooldown = function(response)
                wait(callback(response))
            end
        end

        local function resolveNode(node)
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

        local function httpStall()
            -- HttpService stalled (number of requests exceeded)
            wait(30)
        end

        local function stall(stallMethod, response)
            interrupted = true
            restart = true
            stallMethod(response)
            interrupted = false
        end

        local function sendNode(node)
            return Promise.async(function(resolve)
                node.Data.Request:Send():andThen(function(response)
                    if response.StatusCode == 429 then
                        stall(cooldown, response)
                        sendNode(node) -- try again!
                    else
                        coroutine.resume(node.Data.Callback, response)
                    end

                    resolve(node)
                end):catch(function(err)
                    -- Did we exceed the HttpService limits?
                    if err:match("Number of requests exceeded limit") then
                        stall(httpStall)
                        sendNode(node) -- try again!
                    else
                        coroutine.resume(node.Data.Callback, err)
                    end

                    resolve(node)
                end)
            end)
        end

        local function doQueue(queue)
            while queue.First do
                while interrupted or availableWorkers == 0 do
                    coroutine.yield()
                end
                if restart then
                    break
                end

                local node = queue.First
                availableWorkers = availableWorkers - 1

                sendNode(node):andThen(resolveNode)

                queue.First = node.Next
                if not queue.First then
                    queue.Last = nil
                end
            end
        end

        while true do
            restart = false
            doQueue(prioritaryQueue)
            doQueue(regularQueue)

            if not restart then
                coroutine.yield()
            end
        end
    end)

    local httpQueue = {}

    --[[**
        Pushes a request to the queue to be sent whenever possible.

        @param [t:HttpRequest] request The request to be sent.
        @param [t:HttpRequestPriority] priority The priority of the request in relation to other requests in the same queue.

        @returns [t:Promise<HttpResponse>] A promise to a HttpResponse that is resolved when it is available.
    **--]]
    function httpQueue:Push(request, priority)
        pushCheck(request, priority)

        local requestBody = {Request = request}
        local promise = Promise.async(function(resolve, reject)
            requestBody.Callback = coroutine.running()
            local response = coroutine.yield()
            if guards.isHttpResponse(response) then
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

    --[[**
        Pushes a request to the queue to be sent whenever possible.

        @param [t:HttpRequest] request The request to be sent.
        @param [t:HttpRequestPriority] priority The priority of the request in relation to other requests in the same queue.

        @returns [t:HttpResponse] The server's response to the request.
    **--]]
    function httpQueue:AwaitPush(request, priority)
        local resolved, response = self:Push(request, priority):await()
        return resolved and response or newHttpResponse(false, response)
    end

    --[[**
        @returns [t:number] The number of unsent requests in the queue.
    **--]]
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
