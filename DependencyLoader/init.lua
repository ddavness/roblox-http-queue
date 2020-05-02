--[[
    File: http-queue/DependencyLoader.lua
    Description: Loads runtime dependencies

    SPDX-License-Identifier: MIT
]]

--[[
    EXTERNAL DEPENDENCIES:
    - evaera/roblox-lua-promise (Built in the roblox-ts runtime)
    - osyrisrblx/t (@rbxts/t)
]]

local dependencies = {}
local TS = _G[script.Parent]

-- Module was loaded via Roblox-TS
if TS then
    warn("Loaded via TS")
    dependencies.Promise = TS.Promise
    dependencies.t = TS.import(script, TS.getModule(script, "t"))
else
    warn("Loading locally")
    -- Load dependencies locally
    dependencies.Promise = require(script.Promise)
    dependencies.t = require(script.t)
end

dependencies.HttpService = game:GetService("HttpService")

return dependencies
