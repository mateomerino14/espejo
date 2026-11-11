extends TestCase
## Pruebas del jugador dentro de la sala de prueba: camina sobre el suelo y sus pasos hacen ruido.

const ROOM_SCENE := preload("res://src/world/test_room/test_room.tscn")
const SETTLE_FRAMES := 20
const WALK_FRAMES := 90
const MIN_WALKED_METERS := 1.5

var _room: Node3D
var _player: Player
var _noises := 0


## Carga la sala y deja que el jugador se asiente en el suelo.
func before_each() -> void:
	_room = ROOM_SCENE.instantiate()
	add_to_tree(_room)
	_player = _room.get_node("Player")
	EventBus.noise_emitted.connect(_on_noise_emitted)


## Suelta las teclas y libera la sala.
func after_each() -> void:
	Input.action_release("move_forward")
	EventBus.noise_emitted.disconnect(_on_noise_emitted)
	_room.free()


## Al mantener adelante, avanza por la sala sin caerse.
func test_walks_forward_on_floor() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	assert_true(_player.is_on_floor(), "Debe empezar apoyado en el suelo")
	var start := _player.global_position
	Input.action_press("move_forward")
	await wait_physics_frames(WALK_FRAMES)
	var walked := start.z - _player.global_position.z
	assert_true(walked > MIN_WALKED_METERS, "Debe avanzar por la sala (avanzó %.2f m)" % walked)
	assert_true(_player.is_on_floor(), "Debe seguir en el suelo")
	assert_true(_player.move_state == Player.MoveState.WALK, "Debe estar caminando")
	assert_true(_noises > 0, "Sus pasos deben emitir ruido")


## Cuenta los ruidos emitidos.
func _on_noise_emitted(_origin: Vector3, _loudness: float) -> void:
	_noises += 1
