class_name MapView
extends Control
## Dibujo del mapa: el piso ya recorrido con tinta sobre papel, lo que falta recorrer tapado por una
## bruma, Lucía como una flecha y marcas para apachetas, espejos y salida. El norte queda arriba.

enum Mark { APACHETA, MIRROR, EXIT }

const PAPER := Color(0.8, 0.82, 0.84)
const FLOOR := Color(0.95, 0.96, 0.97)
const INK := Color(0.16, 0.2, 0.28)
const APACHETA_COLOR := Color(0.75, 0.42, 0.14)
const MIRROR_COLOR := Color(0.25, 0.45, 0.75)
const EXIT_COLOR := Color(0.62, 0.12, 0.1)
const PLAYER_COLOR := Color(0.62, 0.12, 0.1)
const MARGIN := 24.0
## Grosor del borde de tinta alrededor del piso, en píxeles.
const WALL_INK := 2.0
const MARK_SIZE := 7.0
const MARK_LINE := 3.5
## Proporción del ancho de un espejo respecto de su alto.
const MIRROR_THICKNESS := 0.45
const ARROW_LENGTH := 20.0
const ARROW_WIDTH := 12.0
## Cuánto de la flecha queda delante del punto de Lucía.
const ARROW_FRONT := 0.6
## Celdas de bruma de más alrededor del piso, para que tape también su borde de tinta.
const MIST_BORDER_CELLS := 1
const EMPTY_FONT_SIZE := 18
const EMPTY_TEXT := "Todavía no recorriste nada"

## Piso del nivel visto desde arriba: polígonos en el suelo (x, z).
var floor_polygons: Array[PackedVector2Array] = []
## Marcas por tipo: posiciones en el suelo (x, z).
var marks: Dictionary[Mark, Array] = {}
var player_position := Vector2.ZERO
## Hacia dónde mira Lucía, en radianes alrededor del eje vertical.
var player_heading := 0.0

var _bounds := Rect2()
## La bruma tiene que vivir mientras se dibuja: si se libera al terminar _draw, sale en blanco.
var _mist_texture: ImageTexture
var _scale := 1.0
var _offset := Vector2.ZERO


## Vuelve a dibujar con lo que se recorrió hasta ahora.
func refresh() -> void:
	queue_redraw()


## Papel, piso con su borde, bruma sobre lo no recorrido, marcas y flecha, encajados en el
## recuadro.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PAPER)
	if floor_polygons.is_empty() or GameState.explored.is_empty():
		var font := get_theme_default_font()
		draw_string(
			font, size / 2.0, EMPTY_TEXT, HORIZONTAL_ALIGNMENT_CENTER, -1, EMPTY_FONT_SIZE, INK
		)
		return
	_fit()
	var shapes: Array[PackedVector2Array] = []
	for polygon in floor_polygons:
		shapes.append(_to_map(polygon))
	for shape in shapes:
		for grown in Geometry2D.offset_polygon(shape, WALL_INK):
			draw_colored_polygon(grown, INK)
	for shape in shapes:
		draw_colored_polygon(shape, FLOOR)
	_draw_mist()
	_draw_marks()
	_draw_player()


## Encaja todo el piso del nivel en el recuadro, sin deformarlo.
func _fit() -> void:
	_bounds = Rect2(floor_polygons[0][0], Vector2.ZERO)
	for polygon in floor_polygons:
		for point in polygon:
			_bounds = _bounds.expand(point)
	var available := size - Vector2.ONE * MARGIN * 2.0
	_scale = minf(available.x / _bounds.size.x, available.y / _bounds.size.y)
	_offset = (size - _bounds.size * _scale) / 2.0


## Tapa con papel las celdas que Lucía todavía no recorrió, con bordes suaves.
func _draw_mist() -> void:
	var first := GameState.map_cell(Vector3(_bounds.position.x, 0.0, _bounds.position.y))
	first -= Vector2i.ONE * MIST_BORDER_CELLS
	var last := GameState.map_cell(Vector3(_bounds.end.x, 0.0, _bounds.end.y))
	last += Vector2i.ONE * MIST_BORDER_CELLS
	var cells := last - first + Vector2i.ONE
	var mist := Image.create(cells.x, cells.y, false, Image.FORMAT_RGBA8)
	mist.fill(PAPER)
	for cell: Vector2i in GameState.explored:
		var pixel := cell - first
		if pixel.x >= 0 and pixel.y >= 0 and pixel.x < cells.x and pixel.y < cells.y:
			mist.set_pixelv(pixel, Color.TRANSPARENT)
	var corner := Vector2(first) * GameState.MAP_CELL
	var area := Rect2(_point(corner), Vector2(cells) * GameState.MAP_CELL * _scale)
	_mist_texture = ImageTexture.create_from_image(mist)
	draw_texture_rect(_mist_texture, area, false)


## Pasa un polígono del suelo al dibujo.
func _to_map(polygon: PackedVector2Array) -> PackedVector2Array:
	var shape := PackedVector2Array()
	for point in polygon:
		shape.append(_point(point))
	return shape


## Pasa un punto del suelo al dibujo.
func _point(ground: Vector2) -> Vector2:
	return _offset + (ground - _bounds.position) * _scale


## Apachetas, espejos y salida, solo donde ya se pasó.
func _draw_marks() -> void:
	for kind: Mark in marks:
		for ground: Vector2 in marks[kind]:
			if not GameState.is_explored(Vector3(ground.x, 0.0, ground.y)):
				continue
			var at := _point(ground)
			match kind:
				Mark.APACHETA:
					draw_circle(at, MARK_SIZE, APACHETA_COLOR)
				Mark.MIRROR:
					var half := Vector2(MARK_SIZE * MIRROR_THICKNESS, MARK_SIZE)
					draw_rect(Rect2(at - half, half * 2.0), MIRROR_COLOR)
				Mark.EXIT:
					var arm := Vector2.ONE * MARK_SIZE
					var cross := Vector2(arm.x, -arm.y)
					draw_line(at - arm, at + arm, EXIT_COLOR, MARK_LINE)
					draw_line(at - cross, at + cross, EXIT_COLOR, MARK_LINE)


## La flecha de Lucía, apuntando hacia donde mira.
func _draw_player() -> void:
	var at := _point(player_position)
	var forward := Vector2(-sin(player_heading), -cos(player_heading))
	var side := Vector2(-forward.y, forward.x)
	var tip := at + forward * ARROW_LENGTH * ARROW_FRONT
	var back := at - forward * ARROW_LENGTH * (1.0 - ARROW_FRONT)
	var wing := side * ARROW_WIDTH / 2.0
	draw_colored_polygon(PackedVector2Array([tip, back + wing, back - wing]), PLAYER_COLOR)
