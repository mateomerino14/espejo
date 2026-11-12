extends TestCase
## Pruebas del nivel 1: tiene lo necesario, se puede recorrer de punta a punta y la nota de Javier
## despierta al Q'ispi.

const LEVEL_SCENE := preload("res://src/world/level_01/level_01.tscn")
const REQUIRED: Array[String] = [
	"Player",
	"Hud",
	"Viewfinder",
	"Album",
	"NoteViewer",
	"RespawnDirector",
	"SpawnPoint",
	"NavigationRegion3D",
	"Qispi",
	"Exit",
	"WorldEnvironment",
]
const SETTLE_FRAMES := 10
## Distancia máxima entre el final del camino y la salida.
const REACH_TOLERANCE := 1.0

var _level: Level01


## Carga el nivel.
func before_each() -> void:
	_level = LEVEL_SCENE.instantiate()
	add_to_tree(_level)


## Libera el nivel.
func after_each() -> void:
	_level.free()


## Tiene todas las piezas obligatorias.
func test_has_required_nodes() -> void:
	for node_name in REQUIRED:
		assert_true(_level.has_node(node_name), "Falta %s" % node_name)


## Hay camino caminable desde el cuarto de Lucía hasta la salida.
func test_exit_is_reachable() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	var map := _level.get_world_3d().navigation_map
	var start: Vector3 = _level.get_node("SpawnPoint").global_position
	var goal: Vector3 = _level.get_node("Exit").global_position
	var path := NavigationServer3D.map_get_path(map, start, goal, true)
	assert_false(path.is_empty(), "Debe haber camino")
	if not path.is_empty():
		var end := path[path.size() - 1]
		var gap := Vector2(end.x - goal.x, end.z - goal.z).length()
		assert_true(
			gap <= REACH_TOLERANCE, "El camino debe llegar a la salida (queda a %.1f m)" % gap
		)


## El Q'ispi duerme hasta que Lucía lee la nota de Javier; la nota de Doña Rosa no lo despierta.
func test_javier_note_wakes_qispi() -> void:
	var qispi: Qispi = _level.get_node("Qispi")
	assert_true(qispi.process_mode == Node.PROCESS_MODE_DISABLED, "Debe empezar dormido")
	_level.get_node("RosaNote/Interactable").interact(null)
	_level.get_node("NoteViewer").close()
	assert_true(qispi.process_mode == Node.PROCESS_MODE_DISABLED, "La nota de Rosa no lo despierta")
	_level.get_node("JavierNote/Interactable").interact(null)
	_level.get_node("NoteViewer").close()
	assert_true(qispi.process_mode == Node.PROCESS_MODE_INHERIT, "La nota de Javier lo despierta")
