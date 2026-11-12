class_name CinematicScene
extends Node3D
## Base de las escenas de cinemática: hace caminar, hablar y girar a los personajes, mueve el auto
## y destella el flash. Cada escena decide qué pasa al empezar cada plano en [method _on_cue].

const IDLE := &"idle"
const WALK := &"walk"
const TALK := &"talk"
const AIM := &"camera_aim"
## Parado con la cámara en las dos manos, a la altura del pecho.
const HOLD := &"camera_idle"
const LOOPED: Array[StringName] = [&"idle", &"walk", &"talk", &"camera_idle"]
## Ruedas del auto, que giran al andar.
const WHEELS: Array[String] = ["WheelFL", "WheelFR", "WheelBL", "WheelBR"]
## Cambio suave entre animaciones.
const BLEND_SECONDS := 0.3
## Velocidad al caminar de los personajes.
const WALK_SPEED := 1.1
const WHEEL_RADIUS := 0.4

@onready var director: CinematicDirector = $CinematicDirector


## Escucha los planos del director.
func _ready() -> void:
	director.cue_reached.connect(_on_cue)


## Lo que pasa al empezar un plano con momento; cada escena lo define.
func _on_cue(_cue: StringName) -> void:
	pass


## Hace sonar una animación del personaje, en bucle si corresponde.
func play(actor: Node3D, animation_name: StringName) -> void:
	var player := actor.find_child("AnimationPlayer") as AnimationPlayer
	var animation := player.get_animation(animation_name)
	if animation_name in LOOPED:
		animation.loop_mode = Animation.LOOP_LINEAR
	player.play(animation_name, BLEND_SECONDS)


## Camina hasta [param target] mirando hacia allá y al llegar llama a [param arrived].
func walk(actor: Node3D, target: Vector3, arrived: Callable) -> void:
	var flat_target := Vector3(target.x, actor.global_position.y, target.z)
	face(actor, flat_target)
	play(actor, WALK)
	var seconds := actor.global_position.distance_to(flat_target) / WALK_SPEED
	var steps := create_tween()
	steps.tween_property(actor, "global_position", flat_target, seconds)
	steps.tween_callback(arrived)


## Camina por los marcadores de [param points] en orden y al final llama a [param arrived].
func walk_path(actor: Node3D, points: Array[Node], arrived: Callable) -> void:
	if points.is_empty():
		arrived.call()
		return
	var next := points.pop_front() as Node3D
	walk(actor, next.global_position, walk_path.bind(actor, points, arrived))


## Gira al personaje hacia [param point]; los modelos miran hacia +Z.
func face(actor: Node3D, point: Vector3) -> void:
	var direction := point - actor.global_position
	actor.rotation.y = atan2(direction.x, direction.z)


## Lleva el auto de [param from] a [param to] frenando al final, con las ruedas girando.
func drive(car: Node3D, from: Transform3D, to: Transform3D, seconds: float) -> void:
	var wheels: Array[Node3D] = []
	for wheel_name: String in WHEELS:
		wheels.append(car.find_child(wheel_name) as Node3D)
	car.global_transform = from
	var trip := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	trip.tween_method(_place_car.bind(car, from, to, wheels), 0.0, 1.0, seconds)


## Destella [param light] hasta [param energy] y lo apaga en [param fade_seconds].
func pulse(light: Light3D, energy: float, fade_seconds: float) -> void:
	light.light_energy = energy
	create_tween().tween_property(light, "light_energy", 0.0, fade_seconds)


## Ubica el auto en [param progress] del viaje y hace girar las ruedas lo que avanzó.
func _place_car(
	progress: float, car: Node3D, from: Transform3D, to: Transform3D, wheels: Array[Node3D]
) -> void:
	var before := car.global_position
	car.global_transform = from.interpolate_with(to, progress)
	var turn := before.distance_to(car.global_position) / WHEEL_RADIUS
	for wheel in wheels:
		wheel.rotate_object_local(Vector3.RIGHT, turn)
