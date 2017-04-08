module BroadcastChannel.LowLevel
    exposing
        ( BroadcastChannel
        , open
        , Settings
        , send
        , close
        )

{-| Low-level bindings to [the JavaScript API for BroadcastChannel][bc]. This is
useful primarily for making effect modules like <BroadcastChannel>.
This module will help you make a really nice subscription-based API.

[bc]: https://developer.mozilla.org/en-US/docs/Web/API/Broadcast_Channel_API#Browser_compatibility


# BroadcastChannel

@docs BroadcastChannel


# Using BroadcastChannel

@docs open, Settings, send, close

-}

import Native.BroadcastChannel
import Task exposing (Task)


{-| A value representing a broadcast channel.
-}
type BroadcastChannel
    = BroadcastChannel


{-| Creates a broadcast channel with given name.
-}
open : String -> Settings -> Task Never BroadcastChannel
open =
    Native.BroadcastChannel.open


{-| The settings describe how a `BroadcastChannel` work as long as it is still open.

The `onMessage` function gives you access to (1) the `BroadcastChannel` itself so you
can use functions like `send` and `close` and (2) the `Message` received
so you can decide what to do next.

You will typically want to set up a channel before sending/receiving messages from
it. That way the `onMessage` can communicate with the other parts of your
program. **Ideally this is handled by the effect library you are using though.
Most people should not be working with this stuff directly.**

-}
type alias Settings =
    { onMessage : BroadcastChannel -> String -> Task Never ()
    }


{-| Close a `BroadcastChannel`. If the channel is already closed, it does nothing.
-}
close : BroadcastChannel -> Task Never ()
close channel =
    Native.BroadcastChannel.close


{-| Send a string over the `BroadcastChannel`.
-}
send : BroadcastChannel -> String -> Task Never ()
send =
    Native.BroadcastChannel.send
