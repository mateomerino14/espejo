class_name EndingTaken
extends CinematicScene
## Final "El salar mira de vuelta": el Q'ispi le roba el reflejo a Lucía y toma su lugar. Desde
## abajo del agua se ve a alguien con su cara subir al 4x4 de Javier.

const SHORE := &"orilla"
const GRAB := &"agarra"
const BELOW := &"abajo"
const JAVIER_ASKS := &"javier"
const SHE_ANSWERS := &"vamos"
const LEAVE := &"se_van"
## Del manotazo al blanco.
const GRAB_SECONDS := 1.0
const BLIND_SECONDS := 2.0

@export var lucia: Node3D
@export var javier: Node3D
@export var qispi: QispiAnimator
@export var underwater: Array[CanvasItem] = []
@export var underside: GeometryInstance3D
@export var music: MusicDirector
@export var lightning: Lightning
@export var car: Node3D
@export var car_start: Marker3D
@export var car_stop: Marker3D
@export var drive_seconds := 8.0
@export var lucia_car: Marker3D


## La vista de abajo del agua espera su momento.
func _ready() -> void:
	super()
	_set_underwater(false)
	car.global_transform = car_start.global_transform


## Lo que pasa en cada plano.
func _on_cue(cue: StringName) -> void:
	match cue:
		SHORE:
			play(lucia, IDLE)
		GRAB:
			music.set_mood(MusicDirector.Mood.TENSION)
			qispi.play_catch()
			create_tween().tween_callback(_take_her).set_delay(GRAB_SECONDS)
		BELOW:
			walk(lucia, lucia_car.global_position, play.bind(lucia, IDLE))
		JAVIER_ASKS:
			play(javier, TALK)
		SHE_ANSWERS:
			play(javier, IDLE)
		LEAVE:
			lucia.visible = false
			javier.visible = false
			drive(car, car_start.global_transform, car_stop.global_transform, drive_seconds)


## El blanco del relámpago, y ya no es Lucía la que queda arriba.
func _take_her() -> void:
	director.flash_screen(BLIND_SECONDS)
	lightning.strike(true)
	qispi.visible = false
	_set_underwater(true)


## Muestra u oculta la vista desde abajo del agua.
func _set_underwater(enabled: bool) -> void:
	underside.visible = enabled
	for overlay in underwater:
		overlay.visible = enabled
