--[[
    File: http-queue/HttpQueue.lua
    Description: Creates a self-regulating queue for rate-limited services

    SPDX-License-Identifier: MIT
]]

local HttpRequest = require(script.Parent.HttpRequest)
local HttpRequestPriority = require(script.Parent.HttpRequestPriority)
local deps = require(script.Parent.DependencyLoader)

local Promise, t = deps.Promise, deps.t

local HttpQueue = {}

local newHttpQueueCheck = t.tuple(t.option(t.string), t.option(t.string), t.option(t.string), t.option(t.number))

--[[**
    Creates an HttpRequest.
    
    @param [t:String|nil] retryAfterHeader The header the queue will look for if rate limits are exceeded. Defaults to "Retry-After"
    @param [t:String|nil] rateLimitCapHeader The header the queue will look for to determine the global rate limit. Not all services provide this header - and that's okay.
    @param [t:String|nil] availableRequestsHeader The header the queue will look for to determine the available request quota. Not all services provide this header - and that's okay.
    @param [t:number|nil] reserveSlots How many request slots to allocate ahead of time. This will not impose a limit to the number of requests you can push to the queue - it's purely for performance reasons.
**--]]
function HttpQueue.new(retryAfterHeader, rateLimitCapHeader,
                       availableRequestsHeader, reserveSlots)
    assert(newHttpQueueCheck(retryAfterHeader, rateLimitCapHeader,
        availableRequestsHeader, reserveSlots))

    local headers = {
        RetryAfter = retryAfterHeader or "Retry-After",
        RateLimit = rateLimitCapHeader,
        Available = availableRequestsHeader
    }

    local prioritaryQueue = {}
    local regularQueue = {}

    if reserveSlots then
        prioritaryQueue = table.create(reserveSlots)
        regularQueue = table.create(reserveSlots)
    end

    local httpQueue = {}

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
