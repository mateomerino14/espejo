extends TestCase
## Pruebas del piso: los pasos suenan distinto dentro de una zona y a sal fuera de ella.

const SURFACE_SCENE := preload("res://src/world/footstep_surface/footstep_surface.tscn")

var _root: Node3D
var _footsteps: FootstepComponent


## Arma una zona de madera en el origen y un componente de pasos para consultarla.
func before_each() -> void:
	_root = add_to_tree(Node3D.new())
	var zone: FootstepSurface = SURFACE_SCENE.instantiate()
	zone.surface = "madera"
	_root.add_child(zone)
	_footsteps = FootstepComponent.new()
	var audio := AudioStreamPlayer3D.new()
	audio.name = "Audio"
	_footsteps.add_child(audio)
	_root.add_child(_footsteps)


## Libera la escena.
func after_each() -> void:
	_root.free()


## Dentro de la zona el piso es de madera y fuera es de sal.
func test_surface_under_point() -> void:
	await wait_physics_frames(2)
	assert_true(_footsteps.surface_at(Vector3.ZERO) == &"madera", "Dentro: madera")
	assert_true(_footsteps.surface_at(Vector3(5.0, 0.0, 0.0)) == FootstepSurface.SALT, "Fuera: sal")
