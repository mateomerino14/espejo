extends TestCase
## Pruebas del nivel 2: se puede ir de la puerta trasera a la principal, tapar todos los espejos
## abre la salida y el Q'ispi sale por el espejo destapado más cercano a Lucía.

const LEVEL_SCENE := preload("res://src/world/level_02/level_02.tscn")
const SETTLE_FRAMES := 10

var _level: Level02


## Carga el nivel con una partida limpia.
func before_each() -> void:
	GameState.reset()
	_level = add_to_tree(LEVEL_SCENE.instantiate())


## Libera el nivel.
func after_each() -> void:
	_level.free()
	GameState.reset()


## Hay camino desde donde entra Lucía hasta la puerta principal.
func test_exit_is_reachable() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	var map := _level.get_world_3d().navigation_map
	var start: Vector3 = _level.get_node("SpawnPoint").global_position
	var goal: Vector3 = _level.get_node("Exit").global_position
	var path := NavigationServer3D.map_get_path(map, start, goal, true)
	assert_false(path.is_empty(), "Debe haber camino")
	assert_true(path[path.size() - 1].distance_to(goal) < 1.0, "El camino debe llegar a la salida")


## La puerta principal está trabada hasta tapar el último espejo.
func test_covering_all_mirrors_opens_door() -> void:
	var door: CardonDoor = _level.get_node("FrontDoor")
	assert_true(door.is_locked, "Empieza trabada")
	var mirrors := _level.get_node("Mirrors").get_children()
	for mirror: Mirror in mirrors:
		assert_true(door.is_locked, "Sigue trabada mientras quede alguno")
		mirror.cover()
	assert_false(door.is_locked, "Con todos tapados se abre")
	assert_true(GameState.covered_mirrors.size() == mirrors.size(), "Recuerda los tapados")


## El Q'ispi sale por el espejo destapado más cercano a Lucía, y no por uno tapado.
func test_passage_uses_nearest_open_mirror() -> void:
	var passage: MirrorPassage = _level.get_node("MirrorPassage")
	var r5: Mirror = _level.get_node("Mirrors/R5Mirror")
	var point := r5.global_position
	assert_true(passage.nearest_open_mirror(point) == r5, "Debe elegir el más cercano")
	r5.cover()
	assert_false(passage.nearest_open_mirror(point) == r5, "Tapado ya no sirve")
