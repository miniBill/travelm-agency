module SimpleI18nFirstCase exposing (..)

import Dict
import Dict.NonEmpty
import State exposing (State)
import Types.Segment exposing (TSegment(..))
import Util.Shared exposing (Generator, buildMain, dynamicOpts, inlineOpts)


main : Generator
main =
    buildMain [ { inlineOpts | i18nArgFirst = True }, { dynamicOpts | i18nArgFirst = True } ] state


state : State ()
state =
    Dict.singleton "messages" <|
        Dict.NonEmpty.singleton "en"
            { pairs =
                Dict.fromList
                    [ ( "singleText", ( Text "the text", [] ) )
                    , ( "interpolation", ( Text "Hello ", [ Interpolation "planet", Text "!" ] ) )
                    , ( "greeting", ( Text "Good ", [ Interpolation "timeOfDay", Text ", ", Interpolation "name" ] ) )
                    ]
            , fallback = Nothing
            , resources = ()
            }
