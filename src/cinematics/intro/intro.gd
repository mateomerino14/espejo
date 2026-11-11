class_name IntroCinematic
extends Node3D
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

## Ruedas del auto, que giran al andar.
const WHEELS: Array[String] = ["WheelFL", "WheelFR", "WheelBL", "WheelBR"]

const IDLE := &"idle"
const WALK := &"walk"
const TALK := &"talk"
const AIM := &"camera_aim"
const LOOPED: Array[StringName] = [&"idle", &"walk", &"talk"]
## Cambio suave entre animaciones.
const BLEND_SECONDS := 0.3
## Velocidad al caminar de los personajes.
const WALK_SPEED := 1.1
## Del gesto de apuntar al disparo.
const AIM_SECONDS := 1.4
const FLASH_FADE_SECONDS := 0.3

@export_group("Auto")
@export var car: Node3D
@export var car_start: Marker3D
@export var car_stop: Marker3D
@export var drive_seconds := 8.5
@export var wheel_radius := 0.4
## Luz de techo que se prende al abrir las puertas.
@export var car_light: OmniLight3D
@export var car_light_energy := 1.4

@export_group("Personajes")
@export var javier: Node3D
@export var lucia: Node3D
@export var javier_out: Marker3D
@export var lucia_out: Marker3D
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

var _wheels: Array[Node3D] = []

@onready var _director: CinematicDirector = $CinematicDirector
@onready var _engine: AudioStreamPlayer3D = $Sounds/Engine
@onready var _car_door: AudioStreamPlayer3D = $Sounds/CarDoor
@onready var _shutter: AudioStreamPlayer3D = $Sounds/Shutter


## Esconde a todos hasta su momento y escucha los planos.
func _ready() -> void:
	for wheel_name: String in WHEELS:
		_wheels.append(car.find_child(wheel_name) as Node3D)
	car.global_transform = car_start.global_transform
	javier.visible = false
	lucia.visible = false
	qispi.visible = false
	flash.light_energy = 0.0
	car_light.light_energy = 0.0
	_director.cue_reached.connect(_on_cue_reached)


## Lo que pasa al empezar cada plano.
func _on_cue_reached(cue: StringName) -> void:
	match cue:
		ARRIVAL:
			_drive_in()
		GET_OUT:
			_get_out()
		JAVIER_TALKS:
			_play(javier, TALK)
			_play(lucia, IDLE)
		LUCIA_TALKS:
			_play(javier, IDLE)
			_play(lucia, TALK)
		JAVIER_LEAVES:
			_play(lucia, IDLE)
			_walk(javier, door.global_position, _enter_hostel)
		LUCIA_WALKS:
			_walk(lucia, shore.global_position, _face_water)
		FIRST_PHOTO:
			_take_photo(qispi_far)
		SECOND_PHOTO:
			_take_photo(qispi_near)
			lightning.strike(true)
		LOWER_CAMERA:
			_play(lucia, IDLE)


## El auto cruza el agua y frena frente al hostal.
func _drive_in() -> void:
	var drive := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	drive.tween_method(_place_car, 0.0, 1.0, drive_seconds)


## Ubica el auto en [param progress] del camino y hace girar las ruedas.
func _place_car(progress: float) -> void:
	var before := car.global_position
	car.global_transform = car_start.global_transform.interpolate_with(
		car_stop.global_transform, progress
	)
	var turn := before.distance_to(car.global_position) / wheel_radius
	for wheel in _wheels:
		wheel.rotate_object_local(Vector3.RIGHT, turn)


## Se apaga el motor, suenan las puertas y los dos quedan afuera.
func _get_out() -> void:
	_engine.stop()
	_car_door.play()
	car_light.light_energy = car_light_energy
	javier.global_transform = javier_out.global_transform
	lucia.global_transform = lucia_out.global_transform
	javier.visible = true
	lucia.visible = true
	_play(javier, IDLE)
	_play(lucia, IDLE)


## Javier abre la puerta del hostal y entra.
func _enter_hostel() -> void:
	door.set_open(true)
	javier.visible = false


## Lucía queda mirando el agua.
func _face_water() -> void:
	_play(lucia, IDLE)


## Lucía apunta y dispara; con el destello, el Q'ispi aparece en el reflejo en [param spot].
func _take_photo(spot: Marker3D) -> void:
	_play(lucia, AIM)
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


## Camina hasta [param target] mirando hacia allá y al llegar llama a [param arrived].
func _walk(actor: Node3D, target: Vector3, arrived: Callable) -> void:
	var flat_target := Vector3(target.x, actor.global_position.y, target.z)
	_face(actor, flat_target)
	_play(actor, WALK)
	var seconds := actor.global_position.distance_to(flat_target) / WALK_SPEED
	var walk := create_tween()
	walk.tween_property(actor, "global_position", flat_target, seconds)
	walk.tween_callback(arrived)


## Gira al personaje hacia [param point]; los modelos miran hacia +Z.
func _face(actor: Node3D, point: Vector3) -> void:
	var direction := point - actor.global_position
	actor.rotation.y = atan2(direction.x, direction.z)


## Hace sonar una animación del personaje, en bucle si corresponde.
func _play(actor: Node3D, animation_name: StringName) -> void:
	var player := actor.find_child("AnimationPlayer") as AnimationPlayer
	var animation := player.get_animation(animation_name)
	if animation_name in LOOPED:
		animation.loop_mode = Animation.LOOP_LINEAR
	player.play(animation_name, BLEND_SECONDS)
