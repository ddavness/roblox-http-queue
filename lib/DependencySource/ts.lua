--[[
    File: http-queue/DependencySource/ts.lua
    Description: Loads runtime dependencies. This file is bundled on the NPM distribution only

    SPDX-License-Identifier: MIT
]]

--[[
    EXTERNAL DEPENDENCIES:
    - evaera/promise (Built in the roblox-ts runtime)
    - osyrisrblx/t (@rbxts/t)
]]

local dependencies = {}
local TS = _G[script.Parent]

dependencies.Promise = TS.Promise
dependencies.t = TS.import(script.Parent, TS.getModule(script.Parent, "t").lib.ts).t

dependencies.HttpService = game:GetService("HttpService")

return dependencies
