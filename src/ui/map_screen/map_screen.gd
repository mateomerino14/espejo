class_name MapScreen
extends CanvasLayer
## Mapa: Lucía lo va dibujando mientras camina; con su tecla detiene el juego y muestra por dónde
## ya pasó, dónde está, las apachetas, los espejos que faltan tapar y la salida.

const OBJECTIVE_FORMAT := "Objetivo: %s"
const TITLE_FORMAT := "Mapa · %s"
const PLAIN_TITLE := "Mapa"
## Cada cuánto anota por dónde anda Lucía.
const TRACK_SECONDS := 0.25

var is_open := false

var _track_time := 0.0

@onready var _view: MapView = %MapView
@onready var _title_label: Label = %MapTitle
@onready var _objective_label: Label = %MapObjective


## Arranca cerrado.
func _ready() -> void:
	visible = false


## Mientras se juega, anota lo que Lucía alcanza a ver.
func _process(delta: float) -> void:
	if is_open or get_tree().paused:
		return
	_track_time += delta
	if _track_time < TRACK_SECONDS:
		return
	_track_time = 0.0
	_explore()


## Su tecla abre o cierra; abierto, Escape también cierra.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("map"):
		if is_open:
			close()
		elif _can_open():
			open()
		else:
			return
		get_viewport().set_input_as_handled()
	elif is_open and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


## Detiene el juego y dibuja el mapa como está.
func open() -> void:
	is_open = true
	visible = true
	get_tree().paused = true
	_fill()


## Cierra y sigue el juego.
func close() -> void:
	is_open = false
	visible = false
	get_tree().paused = false


## Solo se abre jugando: no en pausa ni con otra pantalla abierta.
func _can_open() -> bool:
	return not get_tree().paused and _player() != null


## Anota como recorrido lo que rodea a Lucía.
func _explore() -> void:
	var player := _player()
	if player == null:
		return
	var level := player.owner as GameLevel
	if level:
		GameState.explore_around(player.global_position, level.map_reach)


## Pasa al dibujo el piso del nivel, las marcas, a Lucía y el objetivo.
func _fill() -> void:
	_explore()
	var player := _player()
	var level := player.owner
	_view.floor_polygons = _floor_of(level)
	_view.marks = {
		MapView.Mark.APACHETA: _positions(level.find_children("*", "Apacheta", true, false)),
		MapView.Mark.MIRROR: _positions(_open_mirrors(level)),
		MapView.Mark.EXIT: _positions(level.find_children("*", "LevelExit", true, false)),
	}
	_view.player_position = Vector2(player.global_position.x, player.global_position.z)
	_view.player_heading = player.global_rotation.y
	_view.refresh()
	_title_label.text = PLAIN_TITLE
	if level is GameLevel and not (level as GameLevel).title.is_empty():
		_title_label.text = TITLE_FORMAT % (level as GameLevel).title
	_objective_label.text = OBJECTIVE_FORMAT % GameState.objective
	_objective_label.visible = not GameState.objective.is_empty()


## El piso por donde se puede andar, sacado de la malla de navegación, visto desde arriba.
static func _floor_of(level: Node) -> Array[PackedVector2Array]:
	var polygons: Array[PackedVector2Array] = []
	for region: NavigationRegion3D in level.find_children("*", "NavigationRegion3D", true, false):
		var mesh := region.navigation_mesh
		if mesh == null:
			continue
		var vertices := mesh.get_vertices()
		for index in mesh.get_polygon_count():
			var polygon := PackedVector2Array()
			for vertex in mesh.get_polygon(index):
				var point := region.global_transform * vertices[vertex]
				polygon.append(Vector2(point.x, point.z))
			polygons.append(polygon)
	return polygons


## Los espejos que todavía se pueden tapar.
static func _open_mirrors(level: Node) -> Array[Node]:
	var mirrors: Array[Node] = []
	for mirror: Mirror in level.find_children("*", "Mirror", true, false):
		if mirror.coverable and not mirror.is_covered:
			mirrors.append(mirror)
	return mirrors


## Dónde están en el suelo.
static func _positions(nodes: Array[Node]) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for node: Node3D in nodes:
		points.append(Vector2(node.global_position.x, node.global_position.z))
	return points


## Lucía, si está en el nivel.
func _player() -> Player:
	return get_tree().get_first_node_in_group(Player.GROUP) as Player
