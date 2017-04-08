effect module BroadcastChannel
    where { command = MyCmd, subscription = MySub }
    exposing
        ( send
        , listen
        )

{-| BroadcastChannel makes it possible to talk to other browsing contexts with
the same origin.

Browsing contexts are windows, tabs, frames, iframes and workers.

The API here attempts to cover the typical usage scenarios.

**Note:** This package is heavily inspired by `elm-lang/websocket`.
Most of its code is reused here.

# BroadcastChannel

@docs listen, send

-}

import Dict
import Task exposing (Task)
import BroadcastChannel.LowLevel as BC


-- COMMANDS


type MyCmd msg
    = Send String String


{-| Send a message to a particular channel name. You might say something like this:

    send "user" "logout"

-}
send : String -> String -> Cmd msg
send name message =
    command (Send name message)


cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap _ (Send url msg) =
    Send url msg



-- SUBSCRIPTIONS


type MySub msg
    = Listen String (String -> msg)


{-| Subscribe to any incoming messages on a broadcast channel. You might say something
like this:

    type Msg = UserLogout | ...

    subscriptions model =
      listen "user" UserLogout

Useful if the user logs out in another tab. We can then do something about it
in this tab.

-}
listen : String -> (String -> msg) -> Sub msg
listen name tagger =
    subscription (Listen name tagger)


subMap : (a -> b) -> MySub a -> MySub b
subMap func sub =
    case sub of
        Listen url tagger ->
            Listen url (tagger >> func)



-- MANAGER


type alias State msg =
    { channels : ChannelsDict
    , subs : SubsDict msg
    }


type alias ChannelsDict =
    Dict.Dict String BC.BroadcastChannel


type alias SubsDict msg =
    Dict.Dict String (List (String -> msg))


init : Task Never (State msg)
init =
    Task.succeed (State Dict.empty Dict.empty)



-- HANDLE APP MESSAGES


(&>) t1 t2 =
    Task.andThen (\_ -> t2) t1


onEffects :
    Platform.Router msg Msg
    -> List (MyCmd msg)
    -> List (MySub msg)
    -> State msg
    -> Task Never (State msg)
onEffects router cmds subs state =
    let
        sendMessages =
            sendMessagesHelp cmds state.channels

        newSubs =
            buildSubDict subs Dict.empty

        cleanup _ =
            let
                newEntries =
                    Dict.map (\k v -> []) newSubs

                leftStep name _ getNewChannels =
                    getNewChannels
                        |> Task.andThen
                            (\newChannels ->
                                open router name
                                    |> Task.andThen (\channel -> Task.succeed (Dict.insert name channel newChannels))
                            )

                bothStep name _ channel getNewChannels =
                    Task.map (Dict.insert name channel) getNewChannels

                rightStep name channel getNewChannels =
                    close channel &> getNewChannels

                collectNewChannels =
                    Dict.merge leftStep bothStep rightStep newEntries state.channels (Task.succeed Dict.empty)
            in
                collectNewChannels
                    |> Task.andThen (\newChannels -> Task.succeed (State newChannels newSubs))
    in
        sendMessages
            |> Task.andThen cleanup


sendMessagesHelp : List (MyCmd msg) -> ChannelsDict -> Task Never ChannelsDict
sendMessagesHelp cmds channelsDict =
    case cmds of
        [] ->
            Task.succeed channelsDict

        (Send name msg) :: rest ->
            case Dict.get name channelsDict of
                Just channel ->
                    BC.send channel msg
                        &> sendMessagesHelp rest channelsDict

                _ ->
                    sendMessagesHelp rest channelsDict


buildSubDict : List (MySub msg) -> SubsDict msg -> SubsDict msg
buildSubDict subs dict =
    case subs of
        [] ->
            dict

        (Listen name tagger) :: rest ->
            buildSubDict rest (Dict.update name (add tagger) dict)


add : a -> Maybe (List a) -> Maybe (List a)
add value maybeList =
    case maybeList of
        Nothing ->
            Just [ value ]

        Just list ->
            Just (value :: list)



-- HANDLE SELF MESSAGES


type Msg
    = Receive String String
    | Open String BC.BroadcastChannel


onSelfMsg : Platform.Router msg Msg -> Msg -> State msg -> Task Never (State msg)
onSelfMsg router selfMsg state =
    case selfMsg of
        Receive name str ->
            let
                sends =
                    Dict.get name state.subs
                        |> Maybe.withDefault []
                        |> List.map (\tagger -> Platform.sendToApp router (tagger str))
            in
                Task.sequence sends &> Task.succeed state

        Open name channel ->
            Task.succeed (updateChannel name channel state)


updateChannel : String -> BC.BroadcastChannel -> State msg -> State msg
updateChannel name channel state =
    { state | channels = Dict.insert name channel state.channels }


open : Platform.Router msg Msg -> String -> Task Never BC.BroadcastChannel
open router name =
    let
        doOpen channel =
            Platform.sendToSelf router (Open name channel) |> Task.andThen (\_ -> Task.succeed channel)
    in
        BC.open name
            { onMessage = \_ msg -> Platform.sendToSelf router (Receive name msg)
            }
            |> Task.andThen doOpen



-- CLOSE CONNECTIONS


close : BC.BroadcastChannel -> Task Never ()
close channel =
    BC.close channel
