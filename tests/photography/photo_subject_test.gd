extends TestCase
## Pruebas de los sujetos de foto en la sala: la inscripción queda en la foto solo si sale en
## cuadro.

const ROOM_SCENE := preload("res://src/world/test_room/test_room.tscn")
const SETTLE_FRAMES := 10
const NEAR_INSCRIPTION := Vector3(-1.5, 0.05, -3.0)

var _room: Node3D
var _player: Player
var _camera: PhotoCamera


## Carga la sala y deja a Lucía frente a la pared de la inscripción.
func before_each() -> void:
	_room = ROOM_SCENE.instantiate()
	add_to_tree(_room)
	_player = _room.get_node("Player")
	_camera = _player.get_node("Head/Camera3D/PhotoCamera")
	_player.global_position = NEAR_INSCRIPTION


## Suelta la cámara y libera la sala cuando termine de avisar la foto.
func after_each() -> void:
	Input.action_release("camera_raise")
	_room.queue_free()


## Fotografiar la pared guarda la descripción de la inscripción.
func test_photo_captures_inscription() -> void:
	var photo := await _take_photo()
	assert_true(photo.captions.size() == 1, "La foto debe mostrar la inscripción")


## De espaldas a la pared, la foto no muestra nada fuera de lo común.
func test_photo_misses_subject_behind() -> void:
	_player.rotation.y = PI
	var photo := await _take_photo()
	assert_true(photo.captions.is_empty(), "La inscripción no debe salir en la foto")


## Levanta la cámara, dispara y devuelve la foto revelada.
func _take_photo() -> Photo:
	await wait_physics_frames(SETTLE_FRAMES)
	Input.action_press("camera_raise")
	await wait_physics_frames(SETTLE_FRAMES)
	_camera.shoot()
	return await _camera.photo_taken
