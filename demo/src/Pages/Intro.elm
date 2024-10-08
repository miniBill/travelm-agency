module Pages.Intro exposing (init, viewExplanation)

import Accordion
import Dict exposing (Dict)
import File exposing (InputFile)
import Html exposing (Html)
import Html.Attributes exposing (class)
import Http
import InputType exposing (InputType)
import Model exposing (Model)
import Msg exposing (Msg(..))
import Page
import Ports exposing (GeneratorMode)
import Translations exposing (I18n, Language)


init : Model -> ( Model, Cmd Msg )
init model =
    model
        |> Model.setInputTypeAndModeDefaults ( InputType.Json, Ports.Inline )
        |> Page.loadInputFiles { directory = "intro", files = ( { name = "example", language = "en" }, [] ) }
        |> Page.withTranslations Translations.loadIntro


viewExplanation : Model -> List (Html Msg)
viewExplanation ({ i18n } as model) =
    [ Html.p [] [ Html.text <| Translations.introPreamble i18n ]
    , Html.h2 [] [ Html.text <| Translations.introExplanationHeadline i18n ]
    , Html.p [] [ Html.text <| Translations.introExplanationBody i18n ]
    , Html.h2 [] [ Html.text <| Translations.introAdvantagesHeadline i18n ]
    , Accordion.view
        { headline = Translations.introAdvantageReadabilityHeadline i18n
        , content = Translations.introAdvantageReadabilityBody [ class "highlighted" ] i18n
        , id = "readability"
        }
        model
    , Accordion.view
        { headline = Translations.introAdvantageTypeSafetyHeadline i18n
        , content = Translations.introAdvantageTypeSafetyBody { code = [ class "highlighted" ], list = [], item = [] } i18n
        , id = "type_safety"
        }
        model
    , Accordion.view
        { headline = Translations.introAdvantagePerformanceHeadline i18n
        , content = Translations.introAdvantagePerformanceBody [ class "highlighted" ] i18n
        , id = "performance"
        }
        model
    , Html.h2 [] [ Html.text <| Translations.introDisadvantagesHeadline i18n ]
    , Accordion.view
        { headline = Translations.introDisadvantageProgrammabilityHeadline i18n
        , content = [ Html.text <| Translations.introDisadvantageProgrammabilityBody i18n ]
        , id = "programmability"
        }
        model
    , Accordion.view
        { headline = Translations.introDisadvantageToolchainHeadline i18n
        , content = [ Html.text <| Translations.introDisadvantageToolchainBody i18n ]
        , id = "toolchain"
        }
        model
    , Html.h2 [] [ Html.text <| Translations.introTutorialHowtoHeadline i18n ]
    , Html.p [] [ Html.text <| Translations.introTutorialHowtoBody i18n ]
    , Html.p [] [ Html.text <| Translations.introTutorialMobileAdditional i18n ]
    , Html.h2 [] [ Html.text <| Translations.introTextsFeatureHeadline i18n ]
    , Html.p [] [ Html.text <| Translations.introTextsFeatureBody i18n ]
    ]
