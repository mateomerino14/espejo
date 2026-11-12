class_name EndingDeal
extends CinematicScene
## Final "El trato": Lucía le da su reflejo al Q'ispi a cambio de Javier. Él vuelve, pero en la
## foto de despedida frente al hostal solo queda la sal.

const SHORE := &"orilla"
const DEAL := &"trato"
const JAVIER_BACK := &"javier_vuelve"
const HOSTEL := &"hostal"
const PHOTO := &"foto"
const DEVELOPED := &"revelado"
## Lo que tarda el reflejo de Lucía en irse después de hablar.
const DEAL_SECONDS := 2.6
const BLIND_SECONDS := 1.2

@export var lucia: Node3D
@export var javier: Node3D
@export var qispi: QispiAnimator
@export var water: WaterSurface
@export var camera: Camera3D
## Capa en la que queda Lucía: ni el agua ni la foto la ven.
@export_flags_3d_render var lost_layer := 2048
@export var javier_back: Marker3D
@export var lucia_hostel: Marker3D
@export var javier_hostel: Marker3D
@export var shutter: AudioStreamPlayer3D
@export var photo: CanvasLayer


## Javier y la foto esperan su momento.
func _ready() -> void:
	super()
	javier.visible = false
	photo.visible = false


## Lo que pasa en cada plano.
func _on_cue(cue: StringName) -> void:
	match cue:
		SHORE:
			play(lucia, IDLE)
		DEAL:
			create_tween().tween_callback(_give_reflection).set_delay(DEAL_SECONDS)
		JAVIER_BACK:
			play(lucia, IDLE)
			face(lucia, javier.global_position)
		HOSTEL:
			lucia.global_transform = lucia_hostel.global_transform
			javier.global_transform = javier_hostel.global_transform
			play(lucia, IDLE)
			play(javier, HOLD)
		PHOTO:
			play(javier, AIM)
			director.flash_screen(BLIND_SECONDS)
			shutter.play()
		DEVELOPED:
			camera.cull_mask &= ~lost_layer
			photo.visible = true


## Lucía deja de reflejarse, el Q'ispi se va y Javier aparece detrás de ella.
func _give_reflection() -> void:
	for mesh: VisualInstance3D in lucia.find_children("*", "VisualInstance3D", true, false):
		mesh.layers = lost_layer
	water.set_reflected_layers(water.reflected_layers & ~lost_layer)
	qispi.visible = false
	javier.global_transform = javier_back.global_transform
	javier.visible = true
	play(javier, IDLE)
