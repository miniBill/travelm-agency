module Inline.I18n exposing (I18n, Language(..), differentVars, greeting, init, languageFromString, languageSwitchInfo, languageToString, languages, load, orderDemo, specialCharacters, staticText)

{-| This file was generated by elm-i18n version 2.6.0.


-}


{-| Initialize an i18n instance based on a language


-}
init : Language -> I18n
init lang =
    case lang of
        De ->
            de

        En ->
            en

        Fr ->
            fr


{-| Switch to another i18n instance based on a language


-}
load : Language -> I18n -> I18n
load lang _ =
    init lang


type alias I18n =
    { differentVars_ : { elmEn : String, unionGer : String } -> String
    , greeting_ : String -> String
    , languageSwitchInfo_ : String -> String
    , orderDemo_ : { language : String, name : String } -> String
    , specialCharacters_ : String
    , staticText_ : String
    }


differentVars : I18n -> { elmEn : String, unionGer : String } -> String
differentVars i18n =
    i18n.differentVars_


greeting : I18n -> String -> String
greeting i18n =
    i18n.greeting_


languageSwitchInfo : I18n -> String -> String
languageSwitchInfo i18n =
    i18n.languageSwitchInfo_


orderDemo : I18n -> { language : String, name : String } -> String
orderDemo i18n =
    i18n.orderDemo_


specialCharacters : I18n -> String
specialCharacters i18n =
    i18n.specialCharacters_


staticText : I18n -> String
staticText i18n =
    i18n.staticText_


{-| `I18n` instance containing all values for the language De


-}
de : I18n
de =
    { differentVars_ =
        \data ->
            "Beispiel 5: Sprachen können verschiedene Variablen verwenden. In Elm muss dann die "
                ++ data.unionGer
                ++ " aller Variablen übergeben werden."
    , greeting_ = \name -> "Beispiel 2: Eine String-Interpolation mit einer einzelnen Variable - Hallo " ++ name ++ "!"
    , languageSwitchInfo_ =
        \currentLanguage -> "Du kannst hier deine Sprache von " ++ currentLanguage ++ " zu einer anderen ändern."
    , orderDemo_ =
        \data ->
            "Beispiel 4: Die Reihenfolge der benannten Platzhalter bleibt konsistent auch wenn die Sprachen sich ändern! Name: "
                ++ data.name
                ++ ", Sprache: "
                ++ data.language
    , specialCharacters_ =
        "Beispiel 3: Mit dem richtigen Escaping werden auch spezielle Chars \" ' { korrekt dargestellt"
    , staticText_ = "Beispiel 1: Ein einfacher, statischer Text."
    }


{-| `I18n` instance containing all values for the language En


-}
en : I18n
en =
    { differentVars_ =
        \data ->
            "Example 5: Languages may use different variables. But then, you have to pass the union of all bindings in "
                ++ data.elmEn
                ++ "."
    , greeting_ = \name -> "Example 2: A string interpolation with one variable - Hello " ++ name
    , languageSwitchInfo_ =
        \currentLanguage -> "You may switch languages from " ++ currentLanguage ++ " to another one here."
    , orderDemo_ =
        \data ->
            "Example 4: The order of the named placeholder keys stays consistent even when switching languages! Language: "
                ++ data.language
                ++ ", Name: "
                ++ data.name
                ++ "."
    , specialCharacters_ =
        "Example 3: With the right escape sequences, even special characters \" ' { are displayed correctly"
    , staticText_ = "Example 1: A simple, static text."
    }


{-| `I18n` instance containing all values for the language Fr


-}
fr : I18n
fr =
    { differentVars_ =
        \_ ->
            "Exemple 5 : Les langues peuvent utiliser différentes variables. L'union de toutes les variables doit alors être passée dans Elm. "
    , greeting_ = \name -> "Exemple 2 : Une interpolation de chaîne avec une seule variable - Bonjour " ++ name ++ " !"
    , languageSwitchInfo_ =
        \currentLanguage -> "Vous pouvez changer votre langue de " ++ currentLanguage ++ " à une autre ici"
    , orderDemo_ =
        \data ->
            "Exemple 4 : L'ordre des espaces réservés nommés reste cohérent même si les langues changent! Name: "
                ++ data.name
                ++ ", Langue: "
                ++ data.language
    , specialCharacters_ =
        "Exemple 3 : Avec l'échappement correct, les caractères spéciaux \" ' { s'affichent également correctement"
    , staticText_ = "Un simple texte statique"
    }


{-| Enumeration of the supported languages


-}
type Language
    = De
    | En
    | Fr


{-| A list containing all `Language`s


-}
languages : List Language
languages =
    [ De, En, Fr ]


{-| Convert a `Language` to its `String` representation.


-}
languageToString : Language -> String
languageToString lang_ =
    case lang_ of
        De ->
            "de"

        En ->
            "en"

        Fr ->
            "fr"


{-| Maybe parse a `Language` from a `String`. 
This only considers the keys given during compile time, if you need something like 'en-US' to map to the correct `Language`,
you should write your own parsing function.


-}
languageFromString : String -> Maybe Language
languageFromString lang_ =
    case lang_ of
        "de" ->
            Just De

        "en" ->
            Just En

        "fr" ->
            Just Fr

        _ ->
            Nothing
