local Http = require(game:GetService("ServerScriptService").httpqueue)

wait(2)

for i = 1, 100 do
    local request = Http.HttpRequest.new("https://davness.dev/", "GET")
    request:Send():andThen(function(response)
            print("REQUEST " .. i .. " successful!")
            print(response.StatusMessage)
        end)
        :catch(function(err)
            warn("REQUEST " .. i .. " FAILED!")
            print(err)
        end)
    print("Sent reqeust " .. i)
end
