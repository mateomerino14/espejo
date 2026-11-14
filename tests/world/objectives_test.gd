extends TestCase
## Pruebas de lo que abre las salidas: herramientas, puertas con llave, notas que dan objetivo,
## salidas que piden algo, zonas de objetivo y emboscadas del Q'ispi; y que en cada nivel se llegue
## a lo que hace falta.

const TOOL_SCENE := preload("res://src/items/tool_pickup/tool_pickup.tscn")
const DOOR_SCENE := preload("res://src/world/props/cardon_door.tscn")
const EXIT_SCENE := preload("res://src/world/level_exit/level_exit.tscn")
const NOTE_SCENE := preload("res://src/story/readable_note.tscn")
const TRIGGER_SCENE := preload("res://src/story/objective_trigger/objective_trigger.tscn")
const ROOM_SCENE := preload("res://src/world/test_room/test_room.tscn")
const AMBUSH_SCENE := preload("res://src/enemies/encounters/qispi_ambush.tscn")
const LEVEL_PATH := "res://src/world/level_%02d/level_%02d.tscn"
const KEY := "la llave de prueba"
const OBJECTIVE := "Sal por la puerta"
const OTHER_OBJECTIVE := "Busca la llave"
const NOTE_ID := "nota_de_prueba"
const REACH_TOLERANCE := 1.6
const SETTLE_FRAMES := 5

var _nodes: Array[Node] = []


## Partida limpia.
func before_each() -> void:
	GameState.reset()


## Libera lo creado y limpia el estado.
func after_each() -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()
	GameState.reset()


## Recoger una herramienta la guarda, da el objetivo y la quita del suelo.
func test_tool_pickup() -> void:
	var tool: ToolPickup = TOOL_SCENE.instantiate()
	tool.tool_name = KEY
	tool.objective_after = OBJECTIVE
	_add(tool)
	tool.get_node("Interactable").interact(null)
	assert_true(GameState.has_tool(KEY), "Lleva la llave")
	assert_true(GameState.objective == OBJECTIVE, "Da el objetivo siguiente")
	assert_true(tool.is_queued_for_deletion(), "Ya no está en el suelo")


## Con la llave, la puerta cerrada se abre, la llave se gasta y queda recordado.
func test_door_opens_with_key() -> void:
	var door: CardonDoor = DOOR_SCENE.instantiate()
	door.is_locked = true
	door.key_tool = KEY
	door.done_id = "puerta_de_prueba"
	door.objective_after = OBJECTIVE
	_add(door)
	var use: Interactable = door.get_node("Hinge/Interactable")
	use.interact(null)
	assert_true(door.is_locked, "Sin llave no se abre")
	GameState.add_tool(KEY)
	use.interact(null)
	assert_false(door.is_locked, "Con la llave se abre")
	assert_true(door.is_open, "Y queda abierta")
	assert_false(GameState.has_tool(KEY), "La llave se queda en la puerta")
	assert_true(GameState.is_done("puerta_de_prueba"), "Se recuerda abierta")
	assert_true(GameState.objective == OBJECTIVE, "Da el objetivo siguiente")
	var restored: CardonDoor = DOOR_SCENE.instantiate()
	restored.is_locked = true
	restored.done_id = "puerta_de_prueba"
	_add(restored)
	assert_false(restored.is_locked, "Al continuar sigue sin llave")


## Leer una nota da su objetivo la primera vez.
func test_note_gives_objective() -> void:
	var note: ReadableNote = NOTE_SCENE.instantiate()
	note.note = NoteData.new()
	note.note.id = NOTE_ID
	note.objective_after = OBJECTIVE
	_add(note)
	note.get_node("Interactable").interact(null)
	assert_true(GameState.objective == OBJECTIVE, "Da el objetivo")
	GameState.set_objective(OTHER_OBJECTIVE)
	note.get_node("Interactable").interact(null)
	assert_true(GameState.objective == OTHER_OBJECTIVE, "Releerla no lo vuelve a dar")


## Una salida que pide una nota y una herramienta no deja salir sin ellas.
func test_exit_requirements() -> void:
	var exit: LevelExit = EXIT_SCENE.instantiate()
	exit.required_note = NOTE_ID
	exit.required_tool = KEY
	_add(exit)
	assert_false(exit._has_requirements(), "Sin nada no sale")
	GameState.mark_note_read(NOTE_ID)
	assert_false(exit._has_requirements(), "Sin la herramienta no sale")
	GameState.add_tool(KEY)
	assert_true(exit._has_requirements(), "Con las dos sale")


## La zona da su objetivo solo si toca en ese momento de la historia.
func test_objective_trigger_follows_story() -> void:
	var trigger: ObjectiveTrigger = TRIGGER_SCENE.instantiate()
	trigger.objective = OBJECTIVE
	trigger.after_objective = OTHER_OBJECTIVE
	_add(trigger)
	var room: Node3D = _add(ROOM_SCENE.instantiate())
	var player: Player = room.get_node("Player")
	trigger._on_body_entered(player)
	assert_false(GameState.objective == OBJECTIVE, "Todavía no toca")
	GameState.set_objective(OTHER_OBJECTIVE)
	trigger._on_body_entered(player)
	assert_true(GameState.objective == OBJECTIVE, "Ahora sí da el objetivo")


## La emboscada despierta al Q'ispi, lo saca en su punto a rastrear a Lucía y no se repite.
func test_ambush_brings_qispi_once() -> void:
	var room: Node3D = _add(ROOM_SCENE.instantiate())
	var player: Player = room.get_node("Player")
	var qispi: Qispi = room.get_node("Qispi")
	var ambush: QispiAmbush = AMBUSH_SCENE.instantiate()
	ambush.done_id = "emboscada_de_prueba"
	ambush.qispi = qispi
	ambush.spawn_offset = Vector3(1, 0, 0)
	room.add_child(ambush)
	await wait_physics_frames(SETTLE_FRAMES)
	ambush._on_body_entered(player)
	assert_true(qispi.state == Qispi.State.TRACK, "Sale a rastrearla")
	assert_true(qispi.global_position.distance_to(ambush.global_position) < 1.5, "Sale en su punto")
	assert_true(GameState.is_done("emboscada_de_prueba"), "Se recuerda")


## Nivel 1: la llave de la cocina abre la puerta del comedor, y se llega a la llave y a la salida.
func test_level_1_kitchen_key() -> void:
	var level: Node3D = _add(load(LEVEL_PATH % [1, 1]).instantiate())
	await wait_physics_frames(SETTLE_FRAMES)
	var key: ToolPickup = level.get_node("DiningKey")
	var door: CardonDoor = level.get_node("BackDoor")
	assert_true(door.is_locked and door.key_tool == key.tool_name, "La llave abre la puerta")
	await _assert_reachable(level, [key, level.get_node("Exit")])


## Nivel 4: los remos están en la ladera y el bote los pide.
func test_level_4_oars() -> void:
	var level: Node3D = _add(load(LEVEL_PATH % [4, 4]).instantiate())
	await wait_physics_frames(SETTLE_FRAMES)
	var oars: ToolPickup = level.get_node("Oars")
	var exit: LevelExit = level.get_node("Exit")
	assert_true(exit.required_tool == oars.tool_name, "El bote pide los remos")
	await _assert_reachable(level, [oars])


## Nivel 3: la salida pide la lista de Mateo, que está en el vagón del Tío.
func test_level_3_needs_list() -> void:
	var level: Node3D = _add(load(LEVEL_PATH % [3, 3]).instantiate())
	var exit: LevelExit = level.get_node("Exit")
	var list: ReadableNote = level.get_node("MateoList")
	assert_true(exit.required_note == list.note.id, "La salida pide la lista")


## Agrega al árbol y recuerda para liberar.
func _add(node: Node) -> Node:
	add_to_tree(node)
	_nodes.append(node)
	return node


## Comprueba que hay camino desde el comienzo del nivel hasta cada nodo.
func _assert_reachable(level: Node3D, targets: Array) -> void:
	var map := level.get_world_3d().navigation_map
	var start: Vector3 = (level.get_node("Player") as Node3D).global_position
	var goals: Array[Vector3] = []
	for target: Node3D in targets:
		goals.append(target.global_position)
	await wait_for_paths(map, start, goals, REACH_TOLERANCE)
	for target: Node3D in targets:
		var path := NavigationServer3D.map_get_path(map, start, target.global_position, true)
		var end := start
		if not path.is_empty():
			end = path[path.size() - 1]
		assert_true(
			end.distance_to(target.global_position) < REACH_TOLERANCE, "Llega a %s" % target.name
		)
