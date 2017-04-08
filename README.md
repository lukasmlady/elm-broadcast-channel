# BroadcastChannel

Communicate across browsing contexts (windows, tabs, frames, iframes, or workers) with the same origin.

See [Can I Use](http://caniuse.com/#feat=broadcastchannel) for browser support.

## Usage

`BroadcastChannel` exposes two function:

- `listen` for creating subscriptions
- `send` for creating commands

### Broadcasting a message

Use `BroadcastChannel.send "test_channel" "my message!"` to create a send command.

### Subscribing to a channel

Use `BroadcastChannel.listen "test_channel" NewMessage` to create a channel subscription.

## Example

```elm
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import BroadcastChannel


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { input : String
    , messages : List String
    }


init : ( Model, Cmd Msg )
init =
    ( Model "" [], Cmd.none )



-- UPDATE


type Msg
    = Input String
    | Send
    | NewMessage String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg { input, messages } =
    case msg of
        Input newInput ->
            ( Model newInput messages, Cmd.none )

        Send ->
            ( Model "" messages, BroadcastChannel.send "test_channel" input )

        NewMessage str ->
            ( Model input (str :: messages), Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    BroadcastChannel.listen "test_channel" NewMessage



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text "Broadcast a message to other browsing contexts:" ]
        , input [ onInput Input, value model.input ] [ text "-" ]
        , button [ onClick Send ] [ text "Send" ]
        , ul [] (List.map (\item -> li [] [ text item ]) model.messages)
        ]
```
