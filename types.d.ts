/*
    File: http-queue/types.d.ts
    Description: Roblox-TS typings for the http-queue library (package: @rbxts/http-queue)

    SPDX-License-Identifier: MIT
*/

/**
 * Defines the priority of a given request in the queue.
 *
 * @param First The request will be placed at the front of the prioritary queue.
 * @param Prioritary The request will be placed at the back of the prioritary queue.
 * @param Normal The request will be placed at the back of the regular queue.
 */

type StringDictionary = { [k: string]: keyof string };

interface HttpRequestPriority {
    /**The request will be placed at the front of the prioritary queue. */
    First: number;
    /**The request will be placed at the back of the prioritary queue. */
    Prioritary: number;
    /**The request will be placed at the back of the regular queue. */
    Normal: number;
}

/**
 * Defines an Http request.
 */
interface HttpRequest {
    /**
     * The computed url to send the request to
     */
    readonly Url: string;

    /**
     * Sends the request to the specified Url.
     *
     * @returns A promise to a HttpResponse that is resolved when it is available.
     */
    Send(): Promise<HttpResponse>;

    /**
     * @yields
     *
     * @returns The server's response to the request.
     */
    AwaitSend(): HttpResponse;
}

interface HttpRequestConstructor {
    /**
     * @constructor Creates an HttpRequest
     *
     * @param Url The url endpoint the request is being sent to.
     * @param Method A string containing the method/verb being used in the request.
     * @param Body The body of the request. Only applicable if you're going to send data (POST, PUT, etc.)
     * @param Query Url query options (which are then appended to the url)
     * @param Headers Additional headers to be included in the request
     *
     * @example
     * let request = new HttpRequest("https://example.org", "GET", {
     *     isCool: true,
     *     qwerty: "keyboard",
     *     from: "roblox"
     * }, )
     */
    new (
        Url: string,
        Method: string,
        Query?: { [k: string]: keyof string | number | boolean } | undefined,
        Body?: string | undefined,
        Headers?: StringDictionary | undefined,
    ): HttpRequest;
}

/**
 * Defines the server's response to an Http request.
 */
interface HttpResponse {
    /**
     * Whether the connection to the remote server was successful. This is related to HttpService itself.
     * This field can carry a value of false in the following conditions:
     *
     * - HttpService is disabled;
     * - The remote server is down or refusing to connect;
     * - Trust issues with the TLS certificates;
     * - Other issues not completely related to the protocol itself.
     *
     * If this value is false, all other values are undefined.
     */
    readonly ConnectionSuccessful: boolean;

    /**
     * Whether the request to the server was successful. This is directly tied to the request itself.
     * It will be true if the status code is within the range of 200-299, false otherwise.
     */
    readonly RequestSuccessful: boolean;

    /**
     * The status code returned by the remote server.
     */
    readonly StatusCode: number;

    /**
     * An human-readable string representation of the status code returned by the remote server.
     */
    readonly StatusMessage: string;

    /**
     * A dictionary containing the response headers returned by the remote server.
     */
    readonly Headers: StringDictionary;

    /**
     * The data returned by the server.
     */
    readonly Body: string;
}

/**
 * A self-regulating queue for REST APIs that impose rate limits.
 * When you push a request to the queue, the queue will send the ones added first to the
 * remote server (unless you specify a priority). The queue automatically handles the rate limits
 * in order to, as humanly as possible, respect the service's rate limits and Terms of Service.
 *
 * A queue is NOT A SILVER BULLET NEITHER A GUARANTEE of not spamming invalid requests, though.
 * Depending on your game's playerbase/number of servers compared to the rate limit of the services,
 * it might not scale well.
 */
interface HttpQueue {
    /**
     * Pushes a request to the queue to be sent whenever possible.
     *
     * @param request The request to be sent.
     * @param priority The priority of the request in relation to other requests in the same queue.
     *
     * @returns A promise to a HttpResponse that is resolved when it is available.
     */
    Push(request: HttpRequest, priority?: HttpRequestPriority): Promise<HttpResponse>;

    /**
     * @yields Pushes a request to the queue to be sent whenever possible.
     *
     * @param request The request to be sent.
     * @param priority The priority of the request in relation to other requests in the same queue.
     *
     * @returns The server's response to the request.
     */
    AwaitPush(request: HttpRequest, priority?: HttpRequestPriority): HttpResponse;

    /**
     * Determines how many unsent requests there are in the queue
     */
    QueueSize(): number;
}

interface HttpQueueConstructor {
    /**
     * @constructor Creates an HttpQueue
     *
     * @param options The options for the queue.
     * @param options.retryAfter.header If the reqeuest is rate limited, look for this header to determine how long to wait (in seconds)
     * @param options.retryAfter.cooldown Define a cooldown period directly
     * @param options.maxSimultaneousSendOperations How many requests should be sent at the same time (maximum). Defaults to 10.
     *
     * @returns An empty HttpQueue
     */
    new (options: {
        retryAfter: { header: string } | { cooldown: number };
        maxSimultaneousSendOperations?: number;
    }): HttpQueue;
}

// Export type guards
declare function isHttpRequest(obj: any): obj is HttpRequest;
declare function isHttpRequestPriority(obj: any): obj is HttpRequestPriority;
declare function isHttpResponse(obj: any): obj is HttpResponse;
declare function isHttpQueue(obj: any): obj is HttpQueue;

declare const HttpRequest: new () => HttpRequestConstructor;
declare const HttpQueue: new () => HttpQueueConstructor;
declare const HttpRequestPriority: HttpRequestPriority;

export {
    HttpRequest,
    HttpResponse,
    HttpRequestPriority,
    HttpQueue,
    isHttpRequest,
    isHttpRequestPriority,
    isHttpResponse,
    isHttpQueue,
};
