extends TestCase
## Pruebas de la salida del nivel: al cruzarla Lucía, avisa una sola vez.

const EXIT_SCENE := preload("res://src/world/level_exit/level_exit.tscn")
const PLAYER_SCENE := preload("res://src/player/player.tscn")
const SETTLE_FRAMES := 6

var _exit: LevelExit
var _player: Player
var _notices := PackedStringArray()


## Pone la salida y a Lucía lejos de ella.
func before_each() -> void:
	_exit = EXIT_SCENE.instantiate()
	_exit.message = "Saliste del hotel"
	add_to_tree(_exit)
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector3(0, 0, 10)
	add_to_tree(_player)
	_player.set_physics_process(false)
	EventBus.notice_requested.connect(_on_notice_requested)


## Libera todo.
func after_each() -> void:
	EventBus.notice_requested.disconnect(_on_notice_requested)
	_exit.free()
	_player.free()


## Al entrar Lucía avisa, y no vuelve a avisar.
func test_notifies_once() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	assert_true(_notices.is_empty(), "Lejos no debe avisar")
	_player.global_position = Vector3.ZERO
	await wait_physics_frames(SETTLE_FRAMES)
	_player.global_position = Vector3(0, 0, 10)
	await wait_physics_frames(SETTLE_FRAMES)
	_player.global_position = Vector3.ZERO
	await wait_physics_frames(SETTLE_FRAMES)
	assert_true(_notices == PackedStringArray(["Saliste del hotel"]), "Debe avisar una sola vez")


## Cerrada, recuerda lo que falta cada vez y no deja pasar; al abrirse, deja salir.
func test_closed_exit_only_reminds() -> void:
	_exit.is_open = false
	_exit.closed_message = "Todavía no"
	await wait_physics_frames(SETTLE_FRAMES)
	_player.global_position = Vector3.ZERO
	await wait_physics_frames(SETTLE_FRAMES)
	assert_false(_exit.is_used, "Cerrada no se usa")
	_player.global_position = Vector3(0, 0, 10)
	_exit.is_open = true
	await wait_physics_frames(SETTLE_FRAMES)
	_player.global_position = Vector3.ZERO
	await wait_physics_frames(SETTLE_FRAMES)
	assert_true(
		_notices == PackedStringArray(["Todavía no", "Saliste del hotel"]),
		"Primero recuerda, después deja salir"
	)


## Guarda los avisos.
func _on_notice_requested(text: String) -> void:
	_notices.append(text)
