extends TestCase
## Pruebas del nivel 5, el centro del salar: se llega del bote al espejo del centro esquivando los
## conos de sal, la salida lleva a los finales y el reflejo de Javier solo se ve en el agua.

const LEVEL_SCENE := preload("res://src/world/level_05/level_05.tscn")
const LEVEL_04_SCENE := preload("res://src/world/level_04/level_04.tscn")
const ROUTER_PATH := "res://src/cinematics/endings/ending_router.tscn"
const LEVEL_05_PATH := "res://src/world/level_05/level_05.tscn"
const MAX_SETTLE_FRAMES := 300
const REACH_TOLERANCE := 1.5
const REFLECTION_LAYER := 1024

var _level: GameLevel


## Carga el nivel con una partida limpia.
func before_each() -> void:
	GameState.reset()
	_level = add_to_tree(LEVEL_SCENE.instantiate())


## Libera el nivel.
func after_each() -> void:
	_level.free()
	GameState.reset()


## Hay camino desde el bote hasta la apacheta y el espejo del centro.
func test_center_is_reachable() -> void:
	var map := _level.get_world_3d().navigation_map
	var start: Vector3 = _level.get_node("SpawnPoint").global_position
	var far_goal: Vector3 = _level.get_node("Exit").global_position
	for i in MAX_SETTLE_FRAMES:
		if NavigationServer3D.map_get_closest_point(map, far_goal).distance_to(far_goal) < 1.0:
			break
		await wait_physics_frames(1)
	for goal_name: String in ["NavigationRegion3D/Apacheta", "Exit"]:
		var goal: Vector3 = _level.get_node(goal_name).global_position
		var path := NavigationServer3D.map_get_path(map, start, goal, true)
		assert_false(path.is_empty(), "Debe haber camino hasta %s" % goal_name)
		var end := path[path.size() - 1]
		assert_true(
			end.distance_to(goal) < REACH_TOLERANCE, "El camino debe llegar a %s" % goal_name
		)


## La salida del centro abre el final; la del nivel 4 lleva acá.
func test_exits_are_chained() -> void:
	var exit: LevelExit = _level.get_node("Exit")
	assert_true(exit.next_level_path == ROUTER_PATH, "El centro lleva a los finales")
	var island: Node = LEVEL_04_SCENE.instantiate()
	var island_exit: LevelExit = island.get_node("Exit")
	assert_true(island_exit.next_level_path == LEVEL_05_PATH, "La isla lleva al centro")
	island.free()


## Javier va solo en la capa del reflejo y camina hacia el espejo del centro.
func test_javier_is_only_a_reflection() -> void:
	var guide: ReflectionGuide = _level.get_node("JavierReflection")
	for mesh: VisualInstance3D in guide.find_children("*", "VisualInstance3D", true, false):
		assert_true(mesh.layers == REFLECTION_LAYER, "Solo se ve en el reflejo")
	var last := guide.waypoints[guide.waypoints.size() - 1]
	var mirror: Node3D = _level.get_node("CenterMirror")
	assert_true(
		(
			Vector2(last.x, last.z).distance_to(
				Vector2(mirror.global_position.x, mirror.global_position.z)
			)
			< 5.0
		),
		"Termina junto al espejo"
	)


## La apacheta del centro tiene su propio nombre.
func test_center_apacheta_has_its_own_id() -> void:
	var apacheta: Apacheta = _level.get_node("NavigationRegion3D/Apacheta")
	assert_true(apacheta.apacheta_id == "salar_centro", "La apacheta del centro tiene su nombre")
