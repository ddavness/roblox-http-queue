--[[
    File: http-queue/DependencySource/wally.lua
    Description: Loads runtime dependencies. This file is bundled on the Wally package only

    SPDX-License-Identifier: MIT
]]

--[[
    EXTERNAL DEPENDENCIES:
    - evaera/promise
    - osyrisrblx/t
]]

local dependencies = {}

dependencies.Promise = require(script.Parent.Parent.Promise)
dependencies.t = require(script.Parent.Parent.t)

dependencies.HttpService = game:GetService("HttpService")

return dependencies
