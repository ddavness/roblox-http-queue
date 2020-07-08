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

if TS then
    -- Module was loaded via Roblox-TS
    --[[dependencies.Promise = TS.Promise

    -- TS's promise interface is different so we have to come up with an adapter
    function dependencies.Promise.async(callback)
        local promise = dependencies.Promise.new(function(resolve, reject, onCancel)
            dependencies.Promise.spawn(function()
                callback(resolve, reject, onCancel)
            end)
        end)

        return promise
    end]]

    dependencies.t = TS.import(script.Parent, TS.getModule(script.Parent, "t").lib.ts)
else
    -- Load dependencies locally
    dependencies.t = require(script.t)
end

-- TEMPORARY PATCH: DONT USE ROBLOX-TS LIBRARY PROMISE (UNTIL REFACTOR IS OUT)
dependencies.Promise = require(script.Promise)

dependencies.HttpService = game:GetService("HttpService")

return dependencies
