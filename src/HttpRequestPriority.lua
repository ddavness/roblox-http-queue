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
    __index = function(_, index)
        error(tostring(index) .. " is not a valid HttpRequestPriority!")
    end
})
