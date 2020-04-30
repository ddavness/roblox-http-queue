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
interface HttpRequestPriority {
    /**The request will be placed at the front of the prioritary queue. */
    First: number,
    /**The request will be placed at the back of the prioritary queue. */
    Prioritary: number,
    /**The request will be placed at the back of the regular queue. */
    Normal: number
}
