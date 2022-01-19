module Types exposing
    ( ArgValue(..)
    , InterpolationKind(..)
    , TKey
    , TSegment(..)
    , TValue
    , Translations
    , concatenateTextSegments
    , encodeArgValue
    , genArgValue
    , getInterpolationVarNames
    , indicifyInterpolations
    , interpolationKindToTypeAnn
    , isIntlInterpolation
    , optimizeJson
    , transformExprToString
    )

import Array
import Dict exposing (Dict)
import Elm.CodeGen as CG
import Json.Encode as E
import List.NonEmpty exposing (NonEmpty)



-- Internal representation all formats get converted to


type alias Translations =
    List ( TKey, TValue )


type alias TValue =
    NonEmpty TSegment


type alias TKey =
    String


type TSegment
    = -- a simple text
      Text String
      -- {$var}
    | Interpolation String
      -- {$var -> case var of [List String TValue]} [TValue]
    | InterpolationCase String TValue (Dict String TValue)
      -- {$var -> case var of [List String TValue]} [TValue]
    | PluralCase String (List ( String, ArgValue )) TValue (Dict String TValue)
      -- {NUMBER($var, minimumFractionDigits: 2)}
    | FormatNumber String (List ( String, ArgValue ))
      -- {DATE($var, hour12: true)}
    | FormatDate String (List ( String, ArgValue ))


type ArgValue
    = BoolArg Bool
    | StringArg String
    | NumberArg Float


encodeArgValue : ArgValue -> E.Value
encodeArgValue v =
    case v of
        BoolArg b ->
            E.bool b

        StringArg s ->
            E.string s

        NumberArg f ->
            E.float f


genArgValue : ArgValue -> CG.Expression
genArgValue v =
    case v of
        BoolArg b ->
            if b then
                CG.apply [ CG.fqFun [ "Json", "Encode" ] "bool", CG.val "True" ]

            else
                CG.apply [ CG.fqFun [ "Json", "Encode" ] "bool", CG.val "False" ]

        StringArg s ->
            CG.apply [ CG.fqFun [ "Json", "Encode" ] "string", CG.string s ]

        NumberArg f ->
            CG.apply [ CG.fqFun [ "Json", "Encode" ] "float", CG.float f ]


type InterpolationKind
    = SimpleInterpolation
      -- Type and toString transformer
    | IntlInterpolation { ann : CG.TypeAnnotation, toString : CG.Expression -> CG.Expression }


interpolationKindToTypeAnn : InterpolationKind -> CG.TypeAnnotation
interpolationKindToTypeAnn kind =
    case kind of
        SimpleInterpolation ->
            CG.stringAnn

        IntlInterpolation { ann } ->
            ann


transformExprToString : InterpolationKind -> CG.Expression -> CG.Expression
transformExprToString kind =
    case kind of
        SimpleInterpolation ->
            identity

        IntlInterpolation { toString } ->
            toString


isIntlInterpolation : InterpolationKind -> Bool
isIntlInterpolation kind =
    case kind of
        SimpleInterpolation ->
            False

        IntlInterpolation _ ->
            True


classifyInterpolationSegment : TSegment -> Maybe ( String, InterpolationKind )
classifyInterpolationSegment segment =
    case segment of
        Interpolation var ->
            Just ( var, SimpleInterpolation )

        InterpolationCase var _ _ ->
            Just ( var, SimpleInterpolation )

        PluralCase var _ _ _ ->
            Just
                ( var
                , IntlInterpolation
                    { ann = CG.floatAnn
                    , toString = \expr -> CG.apply [ CG.fqFun [ "String" ] "fromFloat", expr ]
                    }
                )

        FormatNumber var _ ->
            Just
                ( var
                , IntlInterpolation
                    { ann = CG.floatAnn
                    , toString = \expr -> CG.apply [ CG.fqFun [ "String" ] "fromFloat", expr ]
                    }
                )

        FormatDate var _ ->
            Just
                ( var
                , IntlInterpolation
                    { ann = CG.fqTyped [ "Time" ] "Posix" []
                    , toString =
                        \expr ->
                            CG.applyBinOp
                                (CG.fqFun [ "String" ] "fromInt")
                                CG.pipel
                                (CG.apply [ CG.fqFun [ "Time" ] "posixToMillis", expr ])
                    }
                )

        Text _ ->
            Nothing


{-| Replaces all interpolations with numbers starting from 0.
Interpolations are assigned numbers in alphabetical order.
Multiple interpolations with the same key get the same number.
-}
indicifyInterpolations : TValue -> TValue
indicifyInterpolations =
    let
        sortByInterpolation =
            classifyInterpolationSegment >> Maybe.map Tuple.first >> Maybe.withDefault ""
    in
    List.NonEmpty.indexedMap Tuple.pair
        >> List.NonEmpty.sortBy (Tuple.second >> sortByInterpolation)
        >> (\( first, rest ) ->
                List.foldl
                    (\( i, segment ) ( currentIndex, previousVar, segments ) ->
                        let
                            handleInterpolation var toSegment =
                                if previousVar == Just var then
                                    ( currentIndex, Just var, List.NonEmpty.cons ( i, toSegment <| String.fromInt <| currentIndex - 1 ) segments )

                                else
                                    ( currentIndex + 1, Just var, List.NonEmpty.cons ( i, toSegment <| String.fromInt currentIndex ) segments )
                        in
                        case segment of
                            Interpolation var ->
                                handleInterpolation var Interpolation

                            InterpolationCase var default cases ->
                                handleInterpolation var (\v -> InterpolationCase v default cases)

                            PluralCase var numOpts default cases ->
                                handleInterpolation var (\v -> PluralCase v numOpts default cases)    

                            FormatNumber var args ->
                                handleInterpolation var (\v -> FormatNumber v args)

                            FormatDate var args ->
                                handleInterpolation var (\v -> FormatDate v args)

                            Text _ ->
                                ( currentIndex, previousVar, List.NonEmpty.cons ( i, segment ) segments )
                    )
                    (case first of
                        ( i, Interpolation var ) ->
                            ( 1, Just var, List.NonEmpty.singleton ( i, Interpolation "0" ) )

                        ( i, InterpolationCase var default cases ) ->
                            ( 1, Just var, List.NonEmpty.singleton ( i, InterpolationCase "0" default cases ) )

                        ( i, PluralCase var numOpts default cases ) ->
                            ( 1, Just var, List.NonEmpty.singleton ( i, PluralCase "0" numOpts default cases ) )

                        ( i, FormatNumber var args ) ->
                            ( 1, Just var, List.NonEmpty.singleton ( i, FormatNumber var args ) )

                        ( i, FormatDate var args ) ->
                            ( 1, Just var, List.NonEmpty.singleton ( i, FormatDate var args ) )

                        ( _, Text _ ) ->
                            ( 0, Nothing, List.NonEmpty.singleton first )
                    )
                    rest
           )
        >> (\( _, _, indicedSegments ) -> indicedSegments)
        >> List.NonEmpty.sortBy Tuple.first
        >> List.NonEmpty.map Tuple.second


optimizeJson : Translations -> E.Value
optimizeJson translations =
    let
        wrapVar : String -> String
        wrapVar var =
            "{" ++ var ++ "}"

        encodeArgs : List ( String, ArgValue ) -> String
        encodeArgs =
            List.map (\( k, v ) -> (E.string k |> E.encode 0) ++ ":" ++ (encodeArgValue v |> E.encode 0))
                >> String.join ","

        optimizeSegments : TValue -> String
        optimizeSegments =
            indicifyInterpolations
                >> List.NonEmpty.map
                    (\segment ->
                        case segment of
                            Text str ->
                                str

                            Interpolation var ->
                                wrapVar var

                            InterpolationCase var _ _ ->
                                wrapVar var

                            PluralCase var _ _ _ ->
                                wrapVar var

                            FormatNumber var args ->
                                wrapVar <| "N" ++ var ++ encodeArgs args

                            FormatDate var args ->
                                wrapVar <| "D" ++ var ++ encodeArgs args
                    )
                >> List.NonEmpty.toList
                >> String.join ""
    in
    translations
        |> List.map (Tuple.second >> optimizeSegments)
        |> Array.fromList
        |> E.array E.string


getInterpolationVarNames : NonEmpty TSegment -> Dict String InterpolationKind
getInterpolationVarNames =
    List.NonEmpty.toList
        >> List.filterMap classifyInterpolationSegment
        >> Dict.fromList


{-| Concatenate multiple text segments that occur after each other
-}
concatenateTextSegments : NonEmpty TSegment -> NonEmpty TSegment
concatenateTextSegments ( first, rest ) =
    List.foldl
        (\segment (( mostRecentSeg, otherSegs ) as segs) ->
            case ( segment, mostRecentSeg ) of
                ( Text t1, Text t2 ) ->
                    ( Text (t2 ++ t1), otherSegs )

                _ ->
                    List.NonEmpty.cons segment segs
        )
        (List.NonEmpty.singleton first)
        rest
        |> List.NonEmpty.reverse
