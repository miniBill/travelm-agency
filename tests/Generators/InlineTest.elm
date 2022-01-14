module Generators.InlineTest exposing (..)

import CodeGen.Shared exposing (Context)
import Dict.NonEmpty
import Elm.Pretty
import Expect
import Generators.Inline as Inline
import Generators.Names exposing (defaultNames)
import State exposing (NonEmptyState)
import Test exposing (Test, describe, test)
import Types exposing (TSegment(..), Translations)
import Util exposing (emptyIntl)


context : Context
context =
    { version = "1.0.0", moduleName = [ "Test" ], names = defaultNames, intl = emptyIntl }


simpleState : Translations -> NonEmptyState ()
simpleState translations =
    Dict.NonEmpty.singleton "messages" <|
        Dict.NonEmpty.singleton "en" { pairs = translations, resources = () }


suite : Test
suite =
    describe "Inline Generator"
        [ test "single language" <|
            \_ ->
                simpleState
                    [ ( "key3", ( Text "value3 ", [ Interpolation "bla", Interpolation "blub" ] ) )
                    , ( "key1", ( Text "value1", [] ) )
                    , ( "key2", ( Text "value2 ", [ Interpolation "bla" ] ) )
                    ]
                    |> Inline.toFile context
                    |> Elm.Pretty.pretty 120
                    |> Expect.equal """module Test exposing (I18n, en)

{-| This file was generated by elm-i18n version 1.0.0.


-}


type alias I18n =
    { key1 : String, key2 : String -> String, key3 : { bla : String, blub : String } -> String }


{-| `I18n` instance containing all values for the language En


-}
en : I18n
en =
    { key1 = "value1", key2 = \\bla_ -> "value2 " ++ bla_, key3 = \\data_ -> "value3 " ++ data_.bla ++ data_.blub }
"""
        , test "multiple languages with different placeholder names" <|
            \_ ->
                (Dict.NonEmpty.singleton "messages" <|
                    Dict.NonEmpty.fromList
                        ( ( "de"
                          , { pairs =
                                [ ( "key"
                                  , ( Text "value "
                                    , [ Interpolation "bla", Interpolation "blub" ]
                                    )
                                  )
                                ]
                            , resources = ()
                            }
                          )
                        , [ ( "en"
                            , { pairs =
                                    [ ( "key"
                                      , ( Interpolation "howdy"
                                        , [ Text "text", Interpolation "blub" ]
                                        )
                                      )
                                    ]
                              , resources = ()
                              }
                            )
                          ]
                        )
                )
                    |> Inline.toFile context
                    |> Elm.Pretty.pretty 120
                    |> Expect.equal """module Test exposing (I18n, de, en)

{-| This file was generated by elm-i18n version 1.0.0.


-}


type alias I18n =
    { key : { bla : String, blub : String, howdy : String } -> String }


{-| `I18n` instance containing all values for the language De


-}
de : I18n
de =
    { key = \\data_ -> "value " ++ data_.bla ++ data_.blub }


{-| `I18n` instance containing all values for the language En


-}
en : I18n
en =
    { key = \\data_ -> data_.howdy ++ "text" ++ data_.blub }
"""
        ]
