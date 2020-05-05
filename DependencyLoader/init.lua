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

    -- TS's promise interface is different so we have to come up with an adapter
    function dependencies.Promise.async(callback)
        local promise = dependencies.Promise.new(function(resolve, reject, onCancel)
            dependencies.Promise.spawn(function()
                callback(resolve, reject, onCancel)
            end)
        end)

        return promise
    end

    dependencies.t = TS.import(script.Parent, TS.getModule(script.Parent, "t").lib.ts)
else
    warn("Loading locally")
    -- Load dependencies locally
    dependencies.Promise = require(script.Promise)
    dependencies.t = require(script.t)
end

dependencies.HttpService = game:GetService("HttpService")

return dependencies
