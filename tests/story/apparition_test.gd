extends TestCase
## Pruebas de la aparición: si Lucía la ve por el visor, al bajar la cámara ya no está.

const APPARITION_SCENE := preload("res://src/story/apparition/apparition.tscn")
const IN_FRONT := Vector3(0, -1.6, -5)

var _camera: Camera3D
var _apparition: Apparition


## Pone una cámara y la aparición delante de ella.
func before_each() -> void:
	_camera = Camera3D.new()
	_camera.position = Vector3(0, 1.6, 0)
	add_to_tree(_camera)
	_camera.make_current()
	_apparition = APPARITION_SCENE.instantiate()
	_apparition.position = _camera.position + IN_FRONT
	add_to_tree(_apparition)


## Baja la cámara y libera lo que quede.
func after_each() -> void:
	EventBus.camera_raised.emit(false)
	_camera.free()
	if is_instance_valid(_apparition):
		_apparition.free()


## Vista por el visor, desaparece al bajar la cámara.
func test_vanishes_after_being_seen() -> void:
	EventBus.camera_raised.emit(true)
	await tree.process_frame
	await tree.process_frame
	assert_true(_apparition.was_seen, "Debe contar como vista")
	EventBus.camera_raised.emit(false)
	assert_true(_apparition.is_queued_for_deletion(), "Debe desaparecer")


## Sin mirar por el visor sigue ahí.
func test_stays_without_camera() -> void:
	await tree.process_frame
	EventBus.camera_raised.emit(false)
	assert_false(_apparition.was_seen, "No debe contar como vista")
	assert_false(_apparition.is_queued_for_deletion(), "Debe seguir ahí")
