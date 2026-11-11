extends TestCase
## Pruebas del espejo: la cámara del reflejo se pone en el ojo reflejado y mira por el vidrio.

const MIRROR_SCENE := preload("res://src/world/mirror/mirror.tscn")
const EYE := Vector3(0.3, 0.2, 2.0)

var _mirror: Mirror
var _camera: Camera3D
var _viewport: SubViewport


## Crea un espejo en el origen que mira hacia +Z.
func before_each() -> void:
	_mirror = MIRROR_SCENE.instantiate()
	add_to_tree(_mirror)
	_mirror.set_process(false)
	_camera = _mirror.get_node("Reflection/Camera3D")
	_viewport = _mirror.get_node("Reflection")


## Libera el espejo.
func after_each() -> void:
	_mirror.free()


## La cámara queda detrás del vidrio, mirando hacia el frente, con el vidrio como plano cercano.
func test_camera_sits_at_reflected_eye() -> void:
	_mirror.update_reflection(EYE)
	var position := _camera.global_position
	assert_almost_eq(position.x, EYE.x, "Debe conservar la posición lateral")
	assert_almost_eq(position.z, -EYE.z, "Debe quedar detrás del vidrio")
	assert_almost_eq((-_camera.global_basis.z).z, 1.0, "Debe mirar hacia el frente")
	assert_almost_eq(_camera.near, EYE.z, "El plano cercano debe ser el vidrio")


## Con el ojo detrás del espejo no se dibuja el reflejo.
func test_eye_behind_disables_reflection() -> void:
	_mirror.update_reflection(-EYE)
	assert_true(
		_viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED,
		"No debe dibujar el reflejo"
	)


## La cámara del reflejo ve la capa del ente.
func test_reflection_sees_entity_layer() -> void:
	assert_true(_camera.get_cull_mask_value(11), "El reflejo debe mostrar la capa del ente")


## La imagen del reflejo tiene la proporción del vidrio.
func test_image_matches_glass() -> void:
	var ratio := float(_viewport.size.x) / _viewport.size.y
	assert_almost_eq(ratio, _mirror.size.x / _mirror.size.y, "Debe tener la forma del vidrio", 0.01)
