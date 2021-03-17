# Roblox Http Queue (for Roblox-TS)
## `@rbxts/http-queue`

## Current version: `v1.1.1`

Writing code to make requests is simple, and maybe fun. Writing code that gracefully handles everything that can go wrong in a request... Well, that's a boring thing to do.

This library is intended to help easing this by, in particular, handling servers that impose rate limits. Writing code to handle that and make sure every request we make is accepted<b>*</b> by the server and is not lost.

This project is powered by [evaera's Promise implementation](https://github.com/evaera/roblox-lua-promise) and [Osyris' **t** typechecking library](https://github.com/osyrisrblx/t).

You can use this library according to the terms of the MIT license.

<b>*</b> <small>For *accepted* I mean "not rate-limited". I cannot make guarantees that the service will not refuse to process the request due to, for example, invalid tokens or permissions.</small>

## Installation (for Roblox-TS users)

Use `npm`:

```
npm install @rbxts/http-queue
```

## Usage

Require the module:

```ts
import {HttpRequest, HttpQueue} from "@rbxts/http-queue"
```

Create a request and send it:

```ts
const request = new HttpRequest("https://some.website.com/", "GET", undefined,{
    auth: "im very cool",
    cool: true
})

// Actual Request URL is https://some.website.com/?auth=im%20very%20cool&cool=true

// The :Send() method returns a Promise that resolves to a response!
request.Send().then(response => {
    print(response.Body)
}).catch(err => {
    print("ERROR!", err as unknown)
})

// Do some work while we wait for the response to arrive

// If you want to yield the script until the response arrives
let response = request.AwaitSend()
```

This is cool and all, but we can make this more interesting. Let's say you want to use Trello in your application. Unfortunately, the rate limiting of Trello is very tight (10 requests per 10 seconds per token for Roblox clients).

Instead of worrying about it yourself, you can delegate the responsability of dealing with the rate limits to a queue.

```ts
const trelloQueue = new HttpQueue({
    retryAfter: {cooldown: 10}, // If rate limited, retry in 10 seconds
    maxSimultaneousSendOperations: 10 // Don't send more than 10 requests at a time
})

// Let's change the name to a Trello board, 1000 times (don't do this at home!)
for (let i = 1; i <= 1000; i++) {
    let request = new HttpRequest("https://api.trello.com/1/boards/5d6f8ec6764c2112a27e3d12", "PUT", undefined, {
        key: "Your developer key",
        token: "Your developer token",
        name: `Your board's new name (${tostring(i)})`
    })

    trelloQueue.Push(request).then(response => {
		// This will never print "429 Too Many Requests"
        print(response.StatusMessage)
	})
}

// Do some work while we wait for the response to arrive

// If you want to yield the script until the response comes in:
let yielded_for_response = trelloQueue.AwaitPush(request)
```

Depending on what service you're using, sometimes the cooldown period varies over time: When creating a new Queue, you can specify how to deal with this on the `retryAfter` option:

- `{cooldown = (number)}` - If you know that the cooldown period is a fixed number of seconds.
- `{header = (string)}` - If the cooldown time is present, in **seconds**, in a response header sent by the service.
- `{callback = (function)}` - For all other cases. Takes the server response and returns the number of seconds that the queue should stall before sending more requests.

**Examples:**

```ts
// Cooldown is fixed to 5 seconds
const staticQueue = new HttpQueue({
    retryAfter: {cooldown: 5}
})

// We check the "x-rate-limit-cooldown-s" header to determine how long to stall
const headerQueue = new HttpQueue({
    retryAfter: {header: "x-rate-limit-cooldown-s"}
})

// We use a callback to parse the response body and retrieve the cooldown period
const callbackQueue = new HttpQueue({
    retryAfter: {callback: (response: HttpResponse) => {
            // Our service returns a JSON body. The cooldown period is noted in milliseconds on the "cooldown" field.
            return game.GetService("HttpService").JSONDecode(response.Body).cooldown / 1000
        }
    }
})
```

The queue works on a "first come, first serve" basis. This means that requests being pushed first will be dealt with first by the queue. (**HOWEVER, this doesn't mean the responses will arrive in order!**)

You can override that behavior by passing a `priority` parameter to the `:Push()` or `:AwaitPush()` methods. There are three options available:

`HttpRequestPriority.Normal` - the default priority. The request is pushed to the back of the regular queue.

`HttpRequestPriority.Prioritary` - The request is pushed to the back of the prioritary queue, that is done by the queue runner before the regular queue.

`HttpRequestPriority.First` - The request is pushed to the front of the prioritary queue.

**NOTE:** The priority features should be used sparingly.

**Example:**

```ts
import {HttpRequestPriority} from "@rbxts/http-queue"

trelloQueue.Push(request, HttpRequestPriority.Prioritary)
```

## Type Guards

This library also comes with type guard functions that allow you to check whether a value is actually what you want:

`isHttpRequest(value)`

`isHttpRequestPriority(value)`

`isHttpResponse(value)`

`isHttpQueue(value)`
