local Http = require(game:GetService("ServerScriptService").httpqueue)

wait(5)

local queue = Http.HttpQueue.new("Retry-After", "x-rate-limit-api-token-max", "x-rate-limit-api-token-remaining", nil, 9)

local query = {
    key = "YOUR KEY HERE",
    token = "YOUR TOKEN HERE"
}

for i = 1, 300 do
    print("Pushing request " .. i)
    query.name = "Name change " .. tostring(i)

    local request = Http.HttpRequest.new("https://api.trello.com/1/boards/5d6f8ec6764c2112a27e3d12", "PUT", nil, query)
    local promise
    if i == 200 then
        promise = queue:Push(request, Http.HttpRequestPriority.First)
    elseif i >= 100 then
        promise = queue:Push(request, Http.HttpRequestPriority.Prioritary)
    else
        promise = queue:Push(request)
    end

    promise
        :andThen(function(response)
            print("REQUEST " .. i .. " successful!")
            print(response.StatusMessage)
        end)
        :catch(function(err)
            warn("REQUEST " .. i .. " FAILED!")
            print(err)
        end)
end