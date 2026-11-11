extends TestCase
## Pruebas del Q'ispi en la sala: oye, caza al ver o al ser mirado, el flash lo aturde cada vez
## menos y al alcanzar a Lucía ella reaparece.

const ROOM_SCENE := preload("res://src/world/test_room/test_room.tscn")
const SETTLE_FRAMES := 10
## Lucía queda detrás del ente, fuera de su vista.
const BEHIND_QISPI := Vector3(0.5, 0.05, 3.0)
const QISPI_START := Vector3(2.5, 0.05, -5.0)
const QUICK_SECONDS := 0.05
## A esta distancia el flash le alcanza la cara.
const FLASH_SPOT := Vector3(1.0, 0.05, 0.0)

var _room: Node3D
var _player: Player
var _qispi: Qispi
var _caught := 0


## Carga la sala con Lucía a espaldas del ente.
func before_each() -> void:
	_room = ROOM_SCENE.instantiate()
	add_to_tree(_room)
	_player = _room.get_node("Player")
	_qispi = _room.get_node("Qispi")
	_player.global_position = BEHIND_QISPI
	EventBus.player_caught.connect(_on_player_caught)


## Suelta las teclas y libera la sala.
func after_each() -> void:
	Input.action_release("camera_raise")
	EventBus.player_caught.disconnect(_on_player_caught)
	EventBus.camera_raised.emit(false)
	_room.free()


## Un ruido cerca lo pone a rastrear.
func test_noise_makes_it_track() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	assert_true(_qispi.state == Qispi.State.STALK, "Debe empezar acechando")
	EventBus.noise_emitted.emit(QISPI_START + Vector3.RIGHT, 1.0)
	assert_true(_qispi.state == Qispi.State.TRACK, "Debe ir a ver el ruido")


## Si Lucía queda en su cono de visión, la caza.
func test_sight_makes_it_hunt() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	_qispi.rotation.y = PI
	await wait_physics_frames(2)
	assert_true(_qispi.state == Qispi.State.HUNT, "Debe cazarla al verla")


## Mirarlo por el visor también le avisa, aunque esté de espaldas.
func test_watching_through_camera_makes_it_hunt() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	_qispi.set_physics_process(false)
	Input.action_press("camera_raise")
	await wait_physics_frames(SETTLE_FRAMES)
	_qispi.set_physics_process(true)
	await wait_physics_frames(2)
	assert_true(_qispi.state == Qispi.State.HUNT, "Debe notar que lo miran")


## El flash en la cara lo aturde, y el segundo dura menos.
func test_flash_stuns_with_growing_resistance() -> void:
	_player.global_position = FLASH_SPOT
	await wait_physics_frames(SETTLE_FRAMES)
	_flash_at_face()
	assert_true(_qispi.state == Qispi.State.STUNNED, "Debe quedar aturdido")
	var first := await _count_stunned_frames()
	_flash_at_face()
	var second := await _count_stunned_frames()
	assert_true(second < first, "El segundo flash debe aturdirlo menos")


## Un flash hacia otro lado no le hace nada.
func test_flash_away_does_nothing() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	var eye := _player.get_eye_position()
	EventBus.flash_fired.emit(eye, (eye - _qispi.get_face_position()).normalized())
	assert_false(_qispi.state == Qispi.State.STUNNED, "No debe aturdirse")


## Al alcanzarla avisa la captura y Lucía reaparece en su punto, con el ente en el suyo.
func test_catch_respawns_player() -> void:
	var director: RespawnDirector = _room.get_node("RespawnDirector")
	director.scare_seconds = QUICK_SECONDS
	director.black_hold_seconds = QUICK_SECONDS
	var screen: DeathScreen = director.get_node("DeathScreen")
	screen.fade_out_seconds = QUICK_SECONDS
	screen.fade_in_seconds = QUICK_SECONDS
	await wait_physics_frames(SETTLE_FRAMES)
	_player.global_position = _qispi.global_position + Vector3(0.5, 0.0, 0.0)
	await wait_physics_frames(2)
	assert_true(_caught == 1, "Debe avisar una captura")
	await tree.create_timer(QUICK_SECONDS * 8.0).timeout
	var spawn: Vector3 = _room.get_node("SpawnPoint").global_position
	assert_true(_player.global_position.distance_to(spawn) < 0.5, "Debe reaparecer en su punto")
	assert_true(_qispi.global_position.distance_to(QISPI_START) < 0.5, "El ente debe volver")


## Dispara un destello desde los ojos de Lucía hacia la cara del ente.
func _flash_at_face() -> void:
	var eye := _player.get_eye_position()
	EventBus.flash_fired.emit(eye, (_qispi.get_face_position() - eye).normalized())


## Cuenta los cuadros de física que pasa aturdido.
func _count_stunned_frames() -> int:
	var frames := 0
	while _qispi.state == Qispi.State.STUNNED:
		await tree.physics_frame
		frames += 1
	return frames


## Cuenta las capturas.
func _on_player_caught() -> void:
	_caught += 1
