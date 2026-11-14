extends TestCase
## Pruebas del mapa: el piso sale de la malla de navegación, se dibuja solo lo recorrido, marca la
## apacheta, los espejos sin tapar y la salida, pausa el juego y lo recorrido vuelve al continuar.

const LEVEL_SCENE := preload("res://src/world/level_02/level_02.tscn")
const SETTLE_FRAMES := 10
const START := Vector3(0, 0, -20)
const FAR_AWAY := Vector3(0, 0, 4)
const REACH := 4.0

var _level: Level02


## Abre el hostal vacío con el estado limpio.
func before_each() -> void:
	GameState.reset()
	SaveGame.clear()
	_level = LEVEL_SCENE.instantiate()
	add_to_tree(_level)
	await wait_physics_frames(SETTLE_FRAMES)


## Libera el nivel, deja el juego sin pausa y borra la partida.
func after_each() -> void:
	_level.get_tree().paused = false
	if is_instance_valid(_level):
		_level.free()
	GameState.reset()
	SaveGame.clear()


## Solo cuenta como visto lo que está cerca de donde pasó Lucía.
func test_only_nearby_is_explored() -> void:
	GameState.explore_around(START, REACH)
	assert_true(GameState.is_explored(START), "Lo cercano queda dibujado")
	assert_false(GameState.is_explored(FAR_AWAY), "Lo lejano sigue sin dibujar")


## Abierto, pausa el juego, dibuja el piso del hostal y marca la apacheta, los espejos y la
## salida; cerrado, sigue el juego.
func test_map_has_floor_and_marks() -> void:
	var screen: MapScreen = _level.find_child("MapScreen", true, false)
	screen.open()
	assert_true(_level.get_tree().paused, "Detiene el juego")
	var view: MapView = screen.get_node("%MapView")
	assert_false(view.floor_polygons.is_empty(), "Dibuja el piso")
	assert_true(view.marks[MapView.Mark.APACHETA].size() == 1, "Marca la apacheta")
	var mirrors: int = view.marks[MapView.Mark.MIRROR].size()
	assert_true(mirrors == _level.uncovered_count(), "Marca los espejos sin tapar")
	assert_false(view.marks[MapView.Mark.EXIT].is_empty(), "Marca la salida")
	screen.close()
	assert_false(_level.get_tree().paused, "Al cerrar sigue el juego")


## Lo recorrido se guarda y vuelve al continuar la partida.
func test_explored_survives_continue() -> void:
	GameState.explore_around(START, REACH)
	SaveGame.save(_level.scene_file_path)
	_level.free()
	GameState.reset()
	_level = (load(SaveGame.load_pending()) as PackedScene).instantiate()
	add_to_tree(_level)
	assert_true(GameState.is_explored(START), "Vuelve lo recorrido")
