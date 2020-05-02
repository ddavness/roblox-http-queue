--[[
    File: http-queue/init.lua
    Description: Front-end for the http-queue library

    SPDX-License-Identifier: MIT
]]

local exports = {
    HttpRequestPriority = require(script.HttpRequestPriority),
    HttpRequest = require(script.HttpRequest),
    HttpQueue = require(script.HttpQueue)
}

for name, guard in pairs(require(script.TypeGuards)) do
    exports[name] = guard
end

return exports
