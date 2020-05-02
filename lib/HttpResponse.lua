--[[
    File: http-queue/HttpResponse.lua
    Description: Private wrapper for an HttpService response

    SPDX-License-Identifier: MIT
]]

local function newHttpResponse(success, result)
    local HttpResponse = {}

    HttpResponse.ConnectionSuccessful = success
    HttpResponse.RequestSuccessful = success and result.Success
    HttpResponse.StatusCode = success and result.StatusCode or 0
    HttpResponse.StatusMessage = success and (result.StatusCode .. " " .. result.StatusMessage) or result
    HttpResponse.Headers = success and result.Headers or {}
    HttpResponse.Body = success and (result.Body or "") or nil

    return setmetatable(HttpResponse, {
        __metatable = "HttpResponse",
        __index = function(_, index)
            error("Attempt to index non-existant value HttpResponse." .. tostring(index))
        end
    })
end

return newHttpResponse
