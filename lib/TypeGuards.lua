--[[
    File: https-queue/TypeGuards.lua
    Description: Type guards to validate http-queue interfaces

    SPDX-License-Identifier: MIT
]]

local t = require(script.Parent.DependencyLoader).t

local guards = {}

guards.isHttpRequest = t.intersection(t.strictInterface({
    Url = t.string,
    Send = t.callback,
    AwaitSend = t.callback
}), function(o)
    return getmetatable(o) == "HttpRequest"
end)

guards.isHttpRequestPriority = t.number --[[t.intersection(t.strictInterface({
    Normal = t.number,
    Prioritary = t.number,
    First = t.number
}), function(o)
    return getmetatable(o) == "HttpRequestPriority"
end)]]

guards.isHttpResponse = t.intersection(t.strictInterface({
    ConnectionSuccessful = t.boolean,
    RequestSuccessful = t.boolean,
    StatusCode = t.number,
    StatusMessage = t.string,
    Headers = t.map(t.string, t.string),
    Body = t.string
}), function(o)
    return getmetatable(o) == "HttpResponse"
end)

guards.isHttpQueue = t.intersection(t.strictInterface({
    __metatable = t.literal("HttpQueue"),
    QueueSize = t.callback,
    Push = t.callback,
    AwaitPush = t.callback
}), function(o)
    return getmetatable(o) == "HttpQueue"
end)

return guards
