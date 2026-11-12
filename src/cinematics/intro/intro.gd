class_name IntroCinematic
extends CinematicScene
## Cinemática de inicio: el 4x4 de Javier llega al hostal bajo la lluvia, conversan, él entra y
## Lucía se queda sacando fotos al agua. Con cada flash, en el reflejo hay alguien más cerca.

const ARRIVAL := &"llegada"
const GET_OUT := &"bajan"
const JAVIER_TALKS := &"javier_habla"
const LUCIA_TALKS := &"lucia_habla"
const JAVIER_LEAVES := &"javier_entra"
const LUCIA_WALKS := &"lucia_camina"
const FIRST_PHOTO := &"primera_foto"
const SECOND_PHOTO := &"segunda_foto"
const LOWER_CAMERA := &"baja_camara"

## Del gesto de apuntar al disparo.
const AIM_SECONDS := 1.4
const FLASH_FADE_SECONDS := 0.3

@export_group("Auto")
@export var car: Node3D
@export var car_start: Marker3D
@export var car_stop: Marker3D
@export var drive_seconds := 8.5
## Luz de techo que se prende al abrir las puertas.
@export var car_light: OmniLight3D
@export var car_light_energy := 1.4

@export_group("Personajes")
@export var javier: Node3D
@export var lucia: Node3D
@export var javier_out: Marker3D
@export var lucia_out: Marker3D
## Marcadores que rodean el auto por delante hasta la puerta del hostal.
@export var javier_path: Node3D
@export var door: CardonDoor
@export var shore: Marker3D

@export_group("Reflejo")
## El Q'ispi con su animador, que lo deja en la capa del reflejo: solo se ve en el agua.
@export var qispi: QispiAnimator
@export var qispi_far: Marker3D
@export var qispi_near: Marker3D
@export var lightning: Lightning
@export var flash: OmniLight3D
@export var flash_energy := 14.0

@onready var _engine: AudioStreamPlayer3D = $Sounds/Engine
@onready var _car_door: AudioStreamPlayer3D = $Sounds/CarDoor
@onready var _shutter: AudioStreamPlayer3D = $Sounds/Shutter


## Esconde a todos hasta su momento y escucha los planos.
func _ready() -> void:
	super()
	car.global_transform = car_start.global_transform
	javier.visible = false
	lucia.visible = false
	qispi.visible = false
	flash.light_energy = 0.0
	car_light.light_energy = 0.0


## Lo que pasa al empezar cada plano.
func _on_cue(cue: StringName) -> void:
	match cue:
		ARRIVAL:
			drive(car, car_start.global_transform, car_stop.global_transform, drive_seconds)
		GET_OUT:
			_get_out()
		JAVIER_TALKS:
			play(javier, TALK)
			play(lucia, IDLE)
		LUCIA_TALKS:
			play(javier, IDLE)
			play(lucia, TALK)
		JAVIER_LEAVES:
			play(lucia, IDLE)
			walk_path(javier, javier_path.get_children(), _enter_hostel)
		LUCIA_WALKS:
			walk(lucia, shore.global_position, _face_water)
		FIRST_PHOTO:
			_take_photo(qispi_far)
		SECOND_PHOTO:
			_take_photo(qispi_near)
			lightning.strike(true)
		LOWER_CAMERA:
			play(lucia, IDLE)


## Se apaga el motor, suenan las puertas y los dos quedan afuera.
func _get_out() -> void:
	_engine.stop()
	_car_door.play()
	car_light.light_energy = car_light_energy
	javier.global_transform = javier_out.global_transform
	lucia.global_transform = lucia_out.global_transform
	javier.visible = true
	lucia.visible = true
	play(javier, IDLE)
	play(lucia, IDLE)


## Javier abre la puerta del hostal y entra.
func _enter_hostel() -> void:
	door.set_open(true)
	javier.visible = false


## Lucía queda mirando el agua.
func _face_water() -> void:
	play(lucia, IDLE)


## Lucía apunta y dispara; con el destello, el Q'ispi aparece en el reflejo en [param spot].
func _take_photo(spot: Marker3D) -> void:
	play(lucia, AIM)
	var shot := create_tween()
	shot.tween_interval(AIM_SECONDS)
	shot.tween_callback(_flash_at.bind(spot))
	shot.tween_property(flash, "light_energy", 0.0, FLASH_FADE_SECONDS)


## El destello: el Q'ispi queda en su lugar, visible solo en el agua.
func _flash_at(spot: Marker3D) -> void:
	qispi.global_transform = spot.global_transform
	qispi.visible = true
	flash.light_energy = flash_energy
	_shutter.play()
