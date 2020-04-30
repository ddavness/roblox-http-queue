--[[
    File: http-queue/HttpRequestPriority.lua
    Description: Enum to determine how a request should be queued.

    SPDX-License-Identifier: MIT
]]

return setmetatable({
    First = 1,
    Prioritary = 2,
    Normal = 3
}, {
    __index = function(i)
        error(tostring(i) .. " is not a valid HttpRequestPriority!")
    end
})
