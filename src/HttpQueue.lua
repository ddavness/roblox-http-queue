--[[
    File: http-queue/HttpQueue.lua
    Description: Creates a self-regulating queue for rate-limited services

    SPDX-License-Identifier: MIT
]]

local HttpRequest = require(script.Parent.HttpRequest)
local HttpRequestPriority = require(script.Parent.HttpRequestPriority)