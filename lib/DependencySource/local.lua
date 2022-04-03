--[[
    File: http-queue/DependencySource/local.lua
    Description: Loads runtime dependencies. This file is bundled on GitHub releases and on the Roblox library.

    SPDX-License-Identifier: MIT
]]

--[[
    EXTERNAL DEPENDENCIES:
    - evaera/promise
    - osyrisrblx/t
]]

local dependencies = {}

-- The dependencies are bundled
dependencies.Promise = require(script.Promise)
dependencies.t = require(script.t)

dependencies.HttpService = game:GetService("HttpService")

return dependencies
