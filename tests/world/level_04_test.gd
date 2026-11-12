extends TestCase
## Pruebas del nivel 4, la isla Incahuasi: se sube desde la orilla hasta Don Celestino y se baja al
## bote; la salida queda cerrada hasta escucharlo, y mientras habla el Q'ispi no se acerca.

const LEVEL_SCENE := preload("res://src/world/level_04/level_04.tscn")
const REACH_TOLERANCE := 1.5

var _level: Level04


## Carga el nivel con una partida limpia.
func before_each() -> void:
	GameState.reset()
	_level = add_to_tree(LEVEL_SCENE.instantiate())


## Libera el nivel.
func after_each() -> void:
	_level.free()
	GameState.reset()


## Hay camino desde la orilla hasta la cima, la apacheta y el bote.
func test_summit_and_boat_are_reachable() -> void:
	var map := _level.get_world_3d().navigation_map
	var start: Vector3 = _level.get_node("SpawnPoint").global_position
	var goal_names: Array[String] = ["Celestino", "NavigationRegion3D/Apacheta", "Exit"]
	await wait_for_paths(map, start, _positions(goal_names), REACH_TOLERANCE)
	for goal_name: String in ["Celestino", "NavigationRegion3D/Apacheta", "Exit"]:
		var goal: Vector3 = _level.get_node(goal_name).global_position
		var path := NavigationServer3D.map_get_path(map, start, goal, true)
		assert_false(path.is_empty(), "Debe haber camino hasta %s" % goal_name)
		var end := path[path.size() - 1]
		assert_true(
			end.distance_to(goal) < REACH_TOLERANCE, "El camino debe llegar a %s" % goal_name
		)


## La salida empieza cerrada y se abre cuando Don Celestino termina de hablar.
func test_exit_opens_after_talking() -> void:
	assert_false(_level.exit.is_open, "Al llegar, la salida está cerrada")
	_level.celestino.conversation_finished.emit()
	assert_true(_level.exit.is_open, "Después de escucharlo, se abre")


## Cuando Don Celestino empieza a hablar, el Q'ispi se aquieta.
func test_talking_calms_qispi() -> void:
	_level.qispi.wake()
	_level.celestino.talk()
	assert_true(_level.qispi.is_calm(), "Mientras habla, el Q'ispi está quieto")


## La apacheta de la cima es la cuarta ofrenda posible.
func test_summit_apacheta_has_its_own_id() -> void:
	var apacheta: Apacheta = _level.get_node("NavigationRegion3D/Apacheta")
	assert_true(apacheta.apacheta_id == "isla_cima", "La apacheta de la cima tiene su nombre")


## Dónde están los nodos nombrados.
func _positions(node_names: Array[String]) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for node_name in node_names:
		result.append((_level.get_node(node_name) as Node3D).global_position)
	return result
