module Api exposing (SignRequest, SignResponse, signIPA)

import Http
import Json.Decode as D
import Json.Encode as E


type alias SignRequest =
    { ipaPath : String
    , cert : String
    , mobileProvision : String
    , password : String
    }


type alias SignResponse =
    { success : Bool
    , output : Maybe String
    , error : Maybe String
    }


encodeSignRequest : SignRequest -> E.Value
encodeSignRequest req =
    E.object
        [ ( "ipaPath", E.string req.ipaPath )
        , ( "cert", E.string req.cert )
        , ( "mobileProvision", E.string req.mobileProvision )
        , ( "password", E.string req.password )
        ]


signResponseDecoder : D.Decoder SignResponse
signResponseDecoder =
    D.map3 SignResponse
        (D.field "success" D.bool)
        (D.maybe (D.field "output" D.string))
        (D.maybe (D.field "error" D.string))


signIPA : String -> SignRequest -> (Result Http.Error SignResponse -> msg) -> Cmd msg
signIPA apiUrl request toMsg =
    let
        -- If apiUrl is empty, use relative path /api
        -- Otherwise use the full URL (for external backend)
        baseUrl =
            if String.isEmpty apiUrl || apiUrl == "" then
                "/api"
            else
                apiUrl
    in
    Http.post
        { url = baseUrl ++ "/sign"
        , body = Http.jsonBody (encodeSignRequest request)
        , expect = Http.expectJson toMsg signResponseDecoder
        }
