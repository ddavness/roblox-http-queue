--[[
    File: http-queue/DataUtils.lua
    Description: Data structures and basic synchronization utilities

    SPDX-License-Identifier: MIT
]]

local dataUtils = {}

-- Small linked list implementation
function dataUtils.newLLNode(item)
    return {Data = item, Prev = nil, Next = nil}
end

function dataUtils.addNodeToFirst(node, root)
    if not root.First then
        root.First = node
        root.Last = node
    else
        root.First.Prev = node
        node.Next = root.First
        node.Prev = nil
        root.First = node
    end
end

function dataUtils.addNodeToLast(node, root)
    if not root.Last then
        root.First = node
        root.Last = node
    else
        root.Last.Next = node
        node.Prev = root.Last
        node.Next = nil
        root.Last = node
    end
end

return dataUtils
