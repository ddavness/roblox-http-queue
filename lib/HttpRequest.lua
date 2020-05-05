--[[
    File: http-queue/HttpRequest.lua
    Description: Wrapper for an HttpService request

    SPDX-License-Identifier: MIT
]]

local deps = require(script.Parent.DependencyLoader)
local newHttpResponse = require(script.Parent.HttpResponse)
local HttpService, Promise, t = deps.HttpService, deps.Promise, deps.t

local HttpRequest = {}

local requestCheck = t.strict(
    t.tuple(t.string, t.string, t.optional(t.string),
        t.optional(t.map(t.string, t.union(t.string, t.number, t.boolean))),
        t.optional(t.map(t.string, t.string))
    )
)

--[[**
    Creates an HttpRequest.
    
    @param [t:String] Url The url endpoint the request is being sent to.
    @param [t:String] Method A string containing the method/verb being used in the request.
    @param [t:String|nil] Body The body of the request. Only applicable if you're going to send data (POST, PUT, etc.)
    @param [t:Dictionary<string,string|bool|number>|nil] Query Url query options (which are then appended to the url)
    @param [t:Dictionary<string,string>|nil] Headers Additional headers to be included in the request
**--]]
function HttpRequest.new(Url, Method, Body, Query, Headers)
    requestCheck(Url, Method, Body, Query, Headers)

    -- Now we can assume type-safety!
    local endpoint = Url
    if t.table(Query) then
        local queryString = "?"
        for i, v in pairs (Query) do
            queryString = queryString .. HttpService:UrlEncode(i) .. "=" .. HttpService:UrlEncode(tostring(v)) .. "&"
        end
        endpoint = endpoint .. queryString:sub(1, -2)
    end

    local httpRequest = {}

    httpRequest.Url = endpoint

    --[[**
        Sends the request to the specified Url.

        @returns [t:HttpResponse] The server's response to the request.
    **--]]
    function httpRequest:AwaitSend()
        -- Placeholder
        local success, result = pcall(function()
            return HttpService:RequestAsync({
                Url = endpoint,
                Method = Method,
                Headers = Headers,
                Body = (Method == "GET" or Method == "HEAD") and nil or Body
            })
        end)

        return newHttpResponse(success, result)
    end

    --[[**
        Sends the request to the specified Url.

        @returns [t:Promise<HttpResponse>] A promise to a HttpResponse that is resolved when it is available.
    **--]]
    function httpRequest:Send()
        return Promise.async(function(resolve, reject)
            local response = self:AwaitSend()
            if response.ConnectionSuccessful then
                resolve(response)
            else
                reject(response.StatusMessage)
            end
        end)
    end

    return setmetatable(httpRequest, {
        __metatable = "HttpRequest",
        __index = function(_, index)
            error("Attempt to index non-existant value HttpRequest." .. tostring(index))
        end
    })
end

return setmetatable(HttpRequest, {
    __metatable = "HttpRequest",
    __index = function(_, index)
        error("Attempt to index non-existant value HttpRequest." .. tostring(index))
    end
})
