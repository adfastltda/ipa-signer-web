port module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as D


-- Ports
port uploadFiles : { ipa : String, cert : String, provision : String, password : String, apiUrl : String } -> Cmd msg
port uploadProgress : (D.Value -> msg) -> Sub msg
port getApiUrl : () -> Cmd msg
port receiveApiUrl : (String -> msg) -> Sub msg
port openFileSelector : String -> Cmd msg
port fileSelected : ((String, String) -> msg) -> Sub msg


type alias Model =
    { ipaFile : Maybe String
    , certFile : Maybe String
    , provFile : Maybe String
    , password : String
    , apiUrl : String
    , status : Status
    }


type alias SignResult =
    { success : Bool
    , message : String
    , downloadUrl : Maybe String
    , installUrl : Maybe String
    , otaUrl : Maybe String
    , error : Maybe String
    }


type Status
    = Idle
    | Loading
    | Success SignResult
    | Error String


type Msg
    = SelectIPA
    | SelectCert
    | SelectProv
    | FileSelected String String
    | PasswordChanged String
    | Submit
    | ApiUrlReceived String
    | UploadResult D.Value


signResultDecoder : D.Decoder SignResult
signResultDecoder =
    D.map6 SignResult
        (D.field "success" D.bool)
        (D.field "message" D.string)
        (D.maybe (D.field "downloadUrl" D.string))
        (D.maybe (D.field "installUrl" D.string))
        (D.maybe (D.field "otaUrl" D.string))
        (D.maybe (D.field "error" D.string))


init : () -> ( Model, Cmd Msg )
init _ =
    ( { ipaFile = Nothing
      , certFile = Nothing
      , provFile = Nothing
      , password = ""
      , apiUrl = ""
      , status = Idle
      }
    , getApiUrl ()
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectIPA ->
            ( model, openFileSelector "ipa" )

        SelectCert ->
            ( model, openFileSelector "cert" )

        SelectProv ->
            ( model, openFileSelector "provision" )

        FileSelected fileType name ->
            case fileType of
                "ipa" ->
                    ( { model | ipaFile = Just name }, Cmd.none )
                "cert" ->
                    ( { model | certFile = Just name }, Cmd.none )
                "provision" ->
                    ( { model | provFile = Just name }, Cmd.none )
                _ ->
                    ( model, Cmd.none )

        PasswordChanged password ->
            ( { model | password = password }, Cmd.none )

        Submit ->
            case ( model.ipaFile, model.certFile, model.provFile ) of
                ( Just ipa, Just cert, Just prov ) ->
                    ( { model | status = Loading }
                    , uploadFiles
                        { ipa = ipa
                        , cert = cert
                        , provision = prov
                        , password = model.password
                        , apiUrl = model.apiUrl
                        }
                    )

                _ ->
                    ( { model | status = Error "Please select all required files" }, Cmd.none )

        ApiUrlReceived url ->
            ( { model | apiUrl = url }, Cmd.none )

        UploadResult value ->
            case D.decodeValue signResultDecoder value of
                Ok result ->
                    if result.success then
                        ( { model | status = Success result }, Cmd.none )
                    else
                        ( { model | status = Error (Maybe.withDefault "Signing failed" result.error) }, Cmd.none )

                Err err ->
                    ( { model | status = Error ("Failed to parse response: " ++ D.errorToString err) }, Cmd.none )


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ h1 [] [ text "IPA Signer" ]
        , div [ class "form" ]
            [ div [ class "field" ]
                [ label [] [ text "IPA File" ]
                , button [ onClick SelectIPA ] [ text "Select IPA" ]
                , text (Maybe.withDefault "No file selected" model.ipaFile)
                ]
            , div [ class "field" ]
                [ label [] [ text "Certificate (.p12)" ]
                , button [ onClick SelectCert ] [ text "Select .p12" ]
                , text (Maybe.withDefault "No file selected" model.certFile)
                ]
            , div [ class "field" ]
                [ label [] [ text "Mobile Provision" ]
                , button [ onClick SelectProv ] [ text "Select .mobileprovision" ]
                , text (Maybe.withDefault "No file selected" model.provFile)
                ]
            , div [ class "field" ]
                [ label [] [ text "Certificate Password" ]
                , input
                    [ type_ "password"
                    , value model.password
                    , onInput PasswordChanged
                    , placeholder "Enter password"
                    ]
                    []
                ]
            , button
                [ onClick Submit
                , disabled (model.ipaFile == Nothing || model.certFile == Nothing || model.provFile == Nothing || model.status == Loading)
                , class "submit"
                ]
                [ text (if model.status == Loading then "Signing..." else "Sign IPA") ]
            ]
        , viewStatus model.status
        ]


viewStatus : Status -> Html Msg
viewStatus status =
    case status of
        Idle ->
            text ""

        Loading ->
            div [ class "status loading" ] [ text "Processing... This may take a minute." ]

        Success result ->
            div [ class "status success" ]
                [ p [] [ text result.message ]
                , case (result.downloadUrl, result.otaUrl) of
                    (Just downloadUrl, Just otaUrl) ->
                        div [ class "links" ]
                            [ a [ href downloadUrl, attribute "download" "signed.ipa", class "button" ] [ text "Download IPA" ]
                            , a [ href otaUrl, class "button install" ] [ text "Install on iPhone" ]
                            ]
                    _ ->
                        text ""
                ]

        Error msg ->
            div [ class "status error" ] [ text ("Error: " ++ msg) ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ receiveApiUrl ApiUrlReceived
        , uploadProgress UploadResult
        , fileSelected (\(t, n) -> FileSelected t n)
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
