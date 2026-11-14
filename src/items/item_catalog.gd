class_name ItemCatalog
extends RefCounted
## Catálogo de lo que Lucía lleva en la mochila: tipos, nombres, topes, qué es cada cosa, para qué
## sirve, su modelo y su dibujo en el inventario.

enum Type { NONE, COCA, CANDLE, BLANKET, FILM, BATTERY }

## Orden en que el inventario muestra los objetos.
const DISPLAY_ORDER: Array[Type] = [Type.FILM, Type.BATTERY, Type.COCA, Type.CANDLE, Type.BLANKET]

const NAMES: Dictionary[Type, String] = {
	Type.COCA: "hojas de coca",
	Type.CANDLE: "vela",
	Type.BLANKET: "manta",
	Type.FILM: "rollo de fotos",
	Type.BATTERY: "pilas",
}

## Nombre con artículo, para los avisos.
const NAMES_WITH_ARTICLE: Dictionary[Type, String] = {
	Type.COCA: "unas hojas de coca",
	Type.CANDLE: "una vela",
	Type.BLANKET: "una manta",
	Type.FILM: "un rollo de fotos",
	Type.BATTERY: "unas pilas",
}

const MAX_STACK: Dictionary[Type, int] = {
	Type.COCA: 4,
	Type.CANDLE: 4,
	Type.BLANKET: 3,
	Type.FILM: 3,
	Type.BATTERY: 3,
}

## Qué es cada cosa, como lo contaría Lucía.
const DESCRIPTIONS: Dictionary[Type, String] = {
	Type.COCA: "Un puñado de hojas de coca. Doña Rosa siempre tenía en la cocina.",
	Type.CANDLE: "Una vela de cebo, de las que se prenden en las apachetas.",
	Type.BLANKET: "Una manta de lana de las camas del hostal. Pesa y tapa bien.",
	Type.FILM: "Un rollo de 24 fotos para la cámara.",
	Type.BATTERY: "Pilas para el flash.",
}

## Para qué sirve cada cosa.
const USES: Dictionary[Type, String] = {
	Type.COCA: "Con una vela, es la ofrenda de una apacheta: aquieta al Q'ispi un rato.",
	Type.CANDLE: "Con hojas de coca, es la ofrenda de una apacheta.",
	Type.BLANKET: "Tapa un espejo: el Q'ispi ya no puede salir por él.",
	Type.FILM: "Se carga solo cuando se acaba el rollo de la cámara.",
	Type.BATTERY: "Se cambian solas cuando el flash se queda sin carga.",
}

## Modelo de cada cosa, para recogerla del suelo y para su dibujo.
const VISUALS: Dictionary[Type, String] = {
	Type.COCA: "res://src/items/visuals/coca.tscn",
	Type.CANDLE: "res://src/items/visuals/candle.tscn",
	Type.BLANKET: "res://src/items/visuals/blanket.tscn",
	Type.FILM: "res://src/items/visuals/film.tscn",
	Type.BATTERY: "res://src/items/visuals/battery.tscn",
}

## Dibujo de cada cosa en el inventario.
const ICONS: Dictionary[Type, Texture2D] = {
	Type.COCA: preload("res://assets/ui/items/coca.png"),
	Type.CANDLE: preload("res://assets/ui/items/candle.png"),
	Type.BLANKET: preload("res://assets/ui/items/blanket.png"),
	Type.FILM: preload("res://assets/ui/items/film.png"),
	Type.BATTERY: preload("res://assets/ui/items/battery.png"),
}


## Devuelve el nombre que ve la jugadora.
static func display_name(type: Type) -> String:
	return NAMES.get(type, "")


## Devuelve el nombre con su artículo, como "una vela".
static func name_with_article(type: Type) -> String:
	return NAMES_WITH_ARTICLE.get(type, "")


## Devuelve cuántas caben en la mochila.
static func max_stack(type: Type) -> int:
	return MAX_STACK.get(type, 0)


## Devuelve qué es.
static func description(type: Type) -> String:
	return DESCRIPTIONS.get(type, "")


## Devuelve para qué sirve.
static func use(type: Type) -> String:
	return USES.get(type, "")


## Devuelve el modelo.
static func visual(type: Type) -> PackedScene:
	return load(VISUALS[type])


## Devuelve el dibujo.
static func icon(type: Type) -> Texture2D:
	return ICONS.get(type)
