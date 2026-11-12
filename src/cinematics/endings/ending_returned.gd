class_name EndingReturned
extends CinematicScene
## Final "El reflejo devuelto": al amanecer, con la última foto del rollo, el flash deshace el
## reflejo y el agua devuelve a Javier. Se van, y en el agua un chico camina hacia el cerro.

const DAWN := &"amanecer"
const APPROACH := &"acerca"
const PHOTO := &"foto"
const JAVIER_WAKES := &"javier_despierta"
const LUCIA_ANSWERS := &"lucia_responde"
const LEAVE := &"se_van"
const MATEO := &"mateo"
## Del gesto de apuntar al disparo, y lo que tarda en volver la vista.
const AIM_SECONDS := 1.3
const BLIND_SECONDS := 2.5

@export var lucia: Node3D
@export var javier: Node3D
@export var qispi: QispiAnimator
@export var qispi_near: Marker3D
@export var flash: Light3D
@export var flash_energy := 12.0
@export var shutter: AudioStreamPlayer3D
@export var car: Node3D
@export var car_start: Marker3D
@export var car_stop: Marker3D
@export var drive_seconds := 9.0
## Mateo, que solo se ve en el agua: va en la capa del reflejo.
@export var mateo: Node3D
@export_flags_3d_render var mateo_layer := 1024
@export var mateo_goal: Marker3D


## Javier y Mateo esperan su momento.
func _ready() -> void:
	super()
	javier.visible = false
	mateo.visible = false
	for mesh: VisualInstance3D in mateo.find_children("*", "VisualInstance3D", true, false):
		mesh.layers = mateo_layer
	flash.light_energy = 0.0
	car.global_transform = car_start.global_transform


## Lo que pasa en cada plano.
func _on_cue(cue: StringName) -> void:
	match cue:
		DAWN:
			play(lucia, IDLE)
		APPROACH:
			qispi.global_transform = qispi_near.global_transform
			play(lucia, AIM)
		PHOTO:
			create_tween().tween_callback(_shoot).set_delay(AIM_SECONDS)
		JAVIER_WAKES:
			play(lucia, IDLE)
			play(javier, TALK)
		LUCIA_ANSWERS:
			play(javier, IDLE)
			play(lucia, TALK)
		LEAVE:
			lucia.visible = false
			javier.visible = false
			drive(car, car_start.global_transform, car_stop.global_transform, drive_seconds)
		MATEO:
			mateo.visible = true
			walk(mateo, mateo_goal.global_position, play.bind(mateo, IDLE))


## La última foto: el destello ciega, el Q'ispi ya no está y en su lugar queda Javier.
func _shoot() -> void:
	director.flash_screen(BLIND_SECONDS)
	pulse(flash, flash_energy, BLIND_SECONDS)
	shutter.play()
	qispi.visible = false
	javier.visible = true
	face(javier, lucia.global_position)
	face(lucia, javier.global_position)
	play(lucia, IDLE)
	play(javier, IDLE)
