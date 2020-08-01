# Roblox Http Queue

**For help and updates, join our [Discord server!](https://discord.gg/RBhP6Ad)**

## Current version: `v1.0.0`

Writing code to make requests is simple, and maybe fun. Writing code that gracefully handles everything that can go wrong in a request... Well, that's a boring thing to do.

This library is intended to help easing this by, in particular, handling servers that impose rate limits. Writing code to handle that and make sure every request we make is accepted<b>*</b> by the server and is not lost.

This project is powered by [evaera's Promise implementation](https://github.com/evaera/roblox-lua-promise) and [Osyris' **t** typechecking library](https://github.com/osyrisrblx/t).

You can use this library according to the terms of the MIT license.

<b>*</b> <small>For *accepted* I mean "not rate-limited". I cannot make guarantees that the service will not refuse to process the request due to, for example, invalid tokens or permissions.</small>

## Installation

### GitHub Releases

Just grab the `.rbxmx` file from the releases page and drop into your project - as simple as that!

### Roblox-TS users

Use `npm`:

```
npm install @rbxts/http-queue
```

## Usage

Require the module:

```lua
local Http = require(game:GetService("ServerScriptService").HttpQueue)
```

Create a request and send it:

```lua
local request = Http.HttpRequest.new("https://some.website.com/", "GET", nil, {auth = "im very cool", cool = true})
-- Actual Request URL is https://some.website.com/?auth=im very cool&cool=true

-- The :Send() method returns a Promise that resolves to a response!
request:Send():andThen(function(response)
    print(response.Body)
end):catch(function(err)
    print("ERROR!", err)
end)

-- Do some work while we wait for the response to arrive

-- If you want to yield the script until the response arrives
local response = request:AwaitSend()
```

This is cool and all, but we can make this more interesting. Let's say you want to use Trello in your application. Unfortunately, the rate limiting of Trello is very tight (10 requests per 10 seconds per token for Roblox clients).

Instead of worrying about it yourself, you can delegate the responsability of dealing with the rate limits to a queue.

```lua
local TrelloQueue = Http.HttpQueue.new({
    retryAfter = {cooldown = 10} -- If rate limited, retry in 10 seconds
    maxSimultaneousSendOperations = 10 -- Don't send more than 10 requests at a time (optional)
})

-- Let's change the name to a Trello board, 1000 times (don't do this at home!)
for i = 1, 1000 do
    local request = Http.HttpRequest.new("https://api.trello.com/1/boards/5d6f8ec6764c2112a27e3d12", "PUT", nil, {
        key = "Your developer key",
        token = "Your developer token",
        name = "Your board's new name (" .. tostring(i) ..")"
    }))

    TrelloQueue:Push(request):andThen(function(response)
        -- This will never print "429 Too Many Requests"
        print(response.StatusMessage)
    end)
end

-- Do some work while we wait for the response to arrive

-- If you want to yield the script until the response comes in:
local response = TrelloQueue:AwaitPush(request)
```

Depending on what service you're using, sometimes the cooldown period varies over time: When creating a new Queue, you can specify how to deal with this on the `retryAfter` option:

- `{cooldown = (number)}` - If you know that the cooldown period is a fixed number of seconds.
- `{header = (string)}` - If the cooldown time is present, in **seconds**, in a response header sent by the service.
- `{callback = (function)}` - For all other cases. Takes the server response and returns the number of seconds that the queue should stall before sending more requests.

**Examples:**

```lua
-- Cooldown is fixed to 5 seconds
local staticQueue = HttpQueue.new({
    retryAfter = {cooldown = 5}
})

-- We check the "x-rate-limit-cooldown-s" header to determine how long to stall
local headerQueue = HttpQueue.new({
    retryAfter = {header = "x-rate-limit-cooldown-s"}
})

-- We use a callback to parse the response body and retrieve the cooldown period
local callbackQueue = HttpQueue.new({
    retryAfter = {callback = function(response)
        -- Our service returns a JSON body. The cooldown period is noted in milliseconds on the "cooldown" field.
        return game:GetService("HttpService"):JSONDecode(response.Body).cooldown / 1000
    end}
})
```

The queue works on a "first come, first serve" basis. This means that requests being pushed first will be dealt with first by the queue. (**HOWEVER, this doesn't mean the responses will arrive in order!**)

You can override that behavior by passing a `priority` parameter to the `:Push()` or `:AwaitPush()` methods. There are three options available:

`HttpRequestPriority.Normal` - the default priority. The request is pushed to the back of the regular queue.

`HttpRequestPriority.Prioritary` - The request is pushed to the back of the prioritary queue, that is done by the queue runner before the regular queue.

`HttpRequestPriority.First` - The request is pushed to the front of the prioritary queue.

**NOTE:** The priority features should be used sparingly.

**Example:**

```lua
TrelloQueue:Push(request, Http.HttpRequestPriority.Prioritary)
```

## Type Guards

This library also comes with type guard functions that allow you to check whether a value is actually what you want:

`isHttpRequest(value)`

`isHttpRequestPriority(value)`

`isHttpResponse(value)`

`isHttpQueue(value)`
