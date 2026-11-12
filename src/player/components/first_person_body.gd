class_name FirstPersonBody
extends Node3D
## Los brazos de Lucía vistos desde sus ojos: las manos sostienen la cámara contra el pecho, la
## levantan para mirar por el visor y se estiran al usar algo. Van en su propia capa, que los
## espejos no dibujan: Lucía no se ve en ellos.

const HOLD := &"camera_idle"
const AIM := &"camera_aim"
const REACH := &"interact"
const LOOPED: Array[StringName] = [&"camera_idle", &"camera_aim"]
const BLEND_SECONDS := 0.25

@export var photo_camera: PhotoCamera
@export var interactor: Interactor
## Capa de render del cuerpo propio.
@export_flags_3d_render var render_layers := 2048

var _animation: AnimationPlayer


## Prepara los brazos y escucha a la cámara y a las manos.
func _ready() -> void:
	_animation = find_children("*", "AnimationPlayer", true, false).front() as AnimationPlayer
	for animation_name in LOOPED:
		_animation.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		mesh.layers = render_layers
	_animation.animation_finished.connect(_on_animation_finished)
	photo_camera.raised_changed.connect(_on_raised_changed)
	interactor.interacted.connect(_on_interacted)
	_animation.play(HOLD)


## Levanta la cámara al ojo o la baja al pecho.
func _on_raised_changed(is_raised: bool) -> void:
	if is_raised:
		_animation.play(AIM, BLEND_SECONDS)
	else:
		_animation.play(HOLD, BLEND_SECONDS)


## Estira la mano hacia lo que usa.
func _on_interacted() -> void:
	if not photo_camera.is_raised:
		_animation.play(REACH, BLEND_SECONDS)


## Al terminar el gesto, vuelve a sostener la cámara.
func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == REACH:
		_animation.play(HOLD, BLEND_SECONDS)
