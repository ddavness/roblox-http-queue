local Http = require(game:GetService("ServerScriptService").httpqueue)

wait(5)

local queue = Http.HttpQueue.new("Retry-After", "x-rate-limit-api-token-max", "x-rate-limit-api-token-remaining", 500, 10)

local query = {
    key = "d31703e3e5ea5587ca5800f86e407182",
    token = "dfdc98d417379393afa6c7a222d58d207a324af514e60298bd53d1f0dc91cd85"
}

for i = 1, 50 do
    print("Pushing request " .. i)
    query.name = "Name change " .. tostring(i)

    local request = Http.HttpRequest.new("https://api.trello.com/1/boards/5d6f8ec6764c2112a27e3d12", "PUT", nil, query)
    print(request.Url)

    queue:Push(request)
        :andThen(function(response)
            print("REQUEST " .. i .. " successful!")
            print(response.StatusMessage)
        end)
        :catch(function(err)
            warn("REQUEST " .. i .. " FAILED!")
            print(err)
        end)
end