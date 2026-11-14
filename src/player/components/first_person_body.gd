class_name FirstPersonBody
extends Node3D
## Los brazos de Lucía vistos desde sus ojos: las manos sostienen la cámara contra el pecho y la
## levantan para mirar por el visor. Van en su propia capa, que los espejos no dibujan: Lucía no se
## ve en ellos.

const HOLD := &"camera_idle"
const AIM := &"camera_aim"
const LOOPED: Array[StringName] = [&"camera_idle", &"camera_aim"]
const BLEND_SECONDS := 0.25

@export var photo_camera: PhotoCamera
## Capa de render del cuerpo propio.
@export_flags_3d_render var render_layers := 2048

var _animation: AnimationPlayer


## Prepara los brazos y escucha a la cámara.
func _ready() -> void:
	_animation = find_children("*", "AnimationPlayer", true, false).front() as AnimationPlayer
	for animation_name in LOOPED:
		_animation.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		mesh.layers = render_layers
	photo_camera.raised_changed.connect(_on_raised_changed)
	_animation.play(HOLD)


## Levanta la cámara al ojo o la baja al pecho.
func _on_raised_changed(is_raised: bool) -> void:
	if is_raised:
		_animation.play(AIM, BLEND_SECONDS)
	else:
		_animation.play(HOLD, BLEND_SECONDS)
