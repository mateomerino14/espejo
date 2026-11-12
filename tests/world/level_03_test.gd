extends TestCase
## Pruebas del nivel 3, el cementerio de trenes: se llega a la salida y al altar del Tío por la
## rampa, y el altar y la lista de Mateo son pistas.

const LEVEL_SCENE := preload("res://src/world/level_03/level_03.tscn")
const REACH_TOLERANCE := 1.0

var _level: GameLevel


## Carga el nivel con una partida limpia.
func before_each() -> void:
	GameState.reset()
	_level = add_to_tree(LEVEL_SCENE.instantiate())


## Libera el nivel.
func after_each() -> void:
	_level.free()
	GameState.reset()


## Hay camino desde la entrada hasta la salida y hasta la lista de Mateo, dentro del vagón.
func test_exit_and_altar_are_reachable() -> void:
	var map := _level.get_world_3d().navigation_map
	var start: Vector3 = _level.get_node("SpawnPoint").global_position
	await wait_for_paths(map, start, _positions(["Exit", "MateoList"]), REACH_TOLERANCE)
	for goal_name: String in ["Exit", "MateoList"]:
		var goal: Vector3 = _level.get_node(goal_name).global_position
		var path := NavigationServer3D.map_get_path(map, start, goal, true)
		assert_false(path.is_empty(), "Debe haber camino hasta %s" % goal_name)
		var end := path[path.size() - 1]
		assert_true(
			end.distance_to(goal) < REACH_TOLERANCE, "El camino debe llegar a %s" % goal_name
		)


## El altar y la lista cuentan como pistas.
func test_altar_and_list_are_clues() -> void:
	var clues := PackedStringArray()
	for node_name: String in ["TioSubject", "ListSubject"]:
		clues.append((_level.get_node(node_name) as PhotoSubject).clue_id)
	assert_true(clues.has("altar") and clues.has("lista"), "Deben ser pistas")


## En el charco suenan pasos de agua, aunque también esté sobre la tierra.
func test_puddle_wins_over_dirt() -> void:
	await wait_physics_frames(2)
	var footsteps: FootstepComponent = _level.get_node("Player/FootstepComponent")
	var puddle: Node3D = _level.get_node("PuddleSurface")
	assert_true(footsteps.surface_at(puddle.global_position) == &"agua", "En el charco: agua")
	assert_true(footsteps.surface_at(Vector3(20.0, 0.0, 20.0)) == &"tierra", "Afuera: tierra")


## Dónde están los nodos nombrados.
func _positions(node_names: Array[String]) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for node_name in node_names:
		result.append((_level.get_node(node_name) as Node3D).global_position)
	return result
