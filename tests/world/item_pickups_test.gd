extends TestCase
## Pruebas de lo que hay para recoger en los niveles: Lucía llega a cada cosa, y en el hostal vacío
## hay una manta para cada espejo.

const LEVEL_PATH := "res://src/world/level_%02d/level_%02d.tscn"
const LEVELS: Array[int] = [1, 2, 3, 4, 5]
## Lo que está sobre una mesa o una cama queda un poco lejos de la malla del piso.
const REACH_TOLERANCE := 1.6
const SETTLE_FRAMES := 5


## Hay camino desde el comienzo hasta cada cosa para recoger.
func test_every_item_is_reachable() -> void:
	for number in LEVELS:
		var level: Node3D = load(LEVEL_PATH % [number, number]).instantiate()
		add_to_tree(level)
		await wait_physics_frames(SETTLE_FRAMES)
		var start: Vector3 = (level.get_node("Player") as Node3D).global_position
		var goals: Array[Vector3] = []
		for item: Node3D in level.get_node("Items").get_children():
			goals.append(item.global_position)
		var map := level.get_world_3d().navigation_map
		await wait_for_paths(map, start, goals, REACH_TOLERANCE)
		for item: Node3D in level.get_node("Items").get_children():
			var path := NavigationServer3D.map_get_path(map, start, item.global_position, true)
			var end := start
			if not path.is_empty():
				end = path[path.size() - 1]
			var gap := end.distance_to(item.global_position)
			assert_true(gap < REACH_TOLERANCE, "Nivel %d: debe llegar a %s" % [number, item.name])
		level.free()
		GameState.reset()


## En el hostal vacío hay tantas mantas como espejos para tapar.
func test_one_blanket_per_mirror() -> void:
	var level: Level02 = load(LEVEL_PATH % [2, 2]).instantiate()
	add_to_tree(level)
	var blankets := 0
	for item: ItemPickup in level.get_node("Items").get_children():
		if item.item_type == ItemCatalog.Type.BLANKET:
			blankets += item.count
	assert_true(blankets >= level.uncovered_count(), "Debe haber una manta por espejo")
	level.free()
	GameState.reset()
