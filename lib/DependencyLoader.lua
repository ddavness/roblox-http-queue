--[[
    File: http-queue/DependencyLoader.lua
    Description: Loads runtime dependencies

    SPDX-License-Identifier: MIT
]]

--[[
    EXTERNAL DEPENDENCIES:
    - evaera/promise (Built in the roblox-ts runtime)
    - osyrisrblx/t (@rbxts/t)
]]

local dependencies = {}
local TS = _G[script.Parent]

if TS then
    -- Module was loaded via Roblox-TS
    dependencies.Promise = TS.Promise
    dependencies.t = TS.import(script.Parent, TS.getModule(script.Parent, "t").lib.ts).t
elseif script.Parent.Parent.Parent.Name == "_Index" then
    -- This looks like a Wally package
    dependencies.Promise = require(script.Parent.Parent.Promise)
    dependencies.t = require(script.Parent.Parent.t)
else
    -- Load dependencies locally
    dependencies.Promise = require(script.Promise)
    dependencies.t = require(script.t)
end

dependencies.HttpService = game:GetService("HttpService")

return dependencies
