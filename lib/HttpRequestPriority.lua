--[[
    File: http-queue/HttpRequestPriority.lua
    Description: Enum to determine how a request should be queued.

    SPDX-License-Identifier: MIT
]]

local PriorityMeta = {
    __metatable = "HttpRequestPriority",
    __index = function(_, index)
        error("Attempt to index non-existant value HttpRequestPriority." .. tostring(index))
    end,
    __eq = function(me, other)
        return getmetatable(me) == getmetatable(other) and me.Value == other.Value
    end
}

return setmetatable({
    First = setmetatable({ Value = 1 }, PriorityMeta),
    Prioritary = setmetatable({ Value = 2 }, PriorityMeta),
    Normal = setmetatable({ Value = 3 }, PriorityMeta)
}, {
    __index = function(_, index)
        error(tostring(index) .. " is not a valid HttpRequestPriority!")
    end
})
