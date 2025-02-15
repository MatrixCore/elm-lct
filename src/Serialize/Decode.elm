module Serialize.Decode exposing (..)
import Serialize.Encode exposing (currentVersion)
import SerializableData exposing (..)
import Json.Decode as D
import GenericDict as Dict

eventsList : D.Decoder (List Event)
eventsList =
    D.list D.string

dimensionName : D.Decoder DimensionName
dimensionName =
    D.map stringToDimensionName D.string
    |> D.andThen
        (\v ->
            case v of
                Just name ->
                    D.succeed name
                Nothing ->
                    D.fail "Unknown dimension name"
        )

range : D.Decoder ( Float, Float )
range =
    D.map2
        (\a b -> ( a, b ) )
        ( D.field "a" D.float )
        ( D.field "b" D.float )

rangeDescription : D.Decoder RangeDescription
rangeDescription =
    D.map2
        (\desc r ->
            { description = desc
            , range = r
            }
        )
        ( D.field "description" D.string )
        ( D.field "range" range )

point : D.Decoder Point
point =
    D.field "type" D.string
    |> D.andThen (\type_ ->
        case type_ of
            "value" ->
                D.map2 Value
                    ( D.field "eventline" D.int )
                    ( D.field "value" D.float )
            "described" ->
                D.map3 Described
                    ( D.field "eventline" D.int )
                    ( D.field "value" D.float )
                    ( D.field "desc" D.string )
            _ ->
                D.fail "Point is neither 'value' nor 'described'"
    )

dimension : D.Decoder Dimension
dimension =
    D.map5
        (\texts points plus minus color ->
            { texts = texts
            , points = points
            , plus = plus
            , minus = minus
            , color = color
            }
        )
        ( D.field "texts" ( D.list rangeDescription ) )
        ( D.field "points" ( D.list point ) )
        ( D.field "plus" D.string )
        ( D.field "minus" D.string )
        ( D.field "color" D.string )

dimensionKeyValue : D.Decoder ( DimensionName, Dimension )
dimensionKeyValue =
    D.map2
        (\k v -> ( k, v ) )
        ( D.field "key" dimensionName )
        ( D.field "value" dimension )

configuration : D.Decoder Configuration
configuration =
    D.map
        (\v -> { eventSpacing = v })
        ( D.field "eventSpacing" D.int )

diagram_v0 : D.Decoder Diagram
diagram_v0 =
    D.map6
        (\textHeight width graphHeight events dimensions config ->
            { textHeight = textHeight
            , width = width
            , graphHeight = graphHeight
            , events = events
            , dimensions = Dict.fromList dimensionNameToString dimensions
            , config = config
            , ux =
                { interactable = Nothing
                , focusedDimension = Nothing
                }
            }
        )
        ( D.field "textHeight" D.int )
        ( D.field "width" D.int )
        ( D.field "graphHeight" D.int )
        ( D.field "events" eventsList )
        ( D.field "dimensions" (D.list dimensionKeyValue) )
        ( D.field "config" configuration )

diagram : D.Decoder Diagram
diagram =
    D.field "version" D.int
    |> D.andThen
        (\version ->
            case version of
                0 ->
                    diagram_v0
                _ ->
                    D.fail ("Can't handle version " ++ String.fromInt version)
        )