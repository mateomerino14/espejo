class_name Lightning
extends Node3D
## Relámpagos sobre el salar: un destello que ilumina todo y el trueno que llega después, antes si
## cayó cerca.

## Pulsos del destello: fracción del máximo y segundos que tarda en llegar.
const PULSES: Array[Vector2] = [
	Vector2(1.0, 0.04), Vector2(0.0, 0.12), Vector2(0.7, 0.05), Vector2(0.0, 0.35)
]

## Luz del destello en su pulso más fuerte.
@export var flash_energy := 6.0
## Segundos entre relámpagos al azar, si caen solos.
@export var min_wait := 14.0
@export var max_wait := 28.0
@export var auto_strikes := true

@export_group("Trueno (s)")
@export var near_delay := 0.25
@export var far_delay := 2.5

@onready var _light: DirectionalLight3D = $Flash
@onready var _thunder_near: AudioStreamPlayer = $ThunderNear
@onready var _thunder_far: AudioStreamPlayer = $ThunderFar
@onready var _timer: Timer = $Timer


## Apaga el destello y programa el primer relámpago.
func _ready() -> void:
	_light.light_energy = 0.0
	_timer.timeout.connect(_on_timer_timeout)
	if auto_strikes:
		_timer.start(randf_range(min_wait, max_wait))


## Destella dos veces y hace sonar el trueno, cerca o lejos.
func strike(is_near: bool) -> void:
	var flash := create_tween()
	for pulse in PULSES:
		flash.tween_property(_light, "light_energy", flash_energy * pulse.x, pulse.y)
	var thunder := _thunder_far
	var delay := far_delay
	if is_near:
		thunder = _thunder_near
		delay = near_delay
	create_tween().tween_callback(thunder.play).set_delay(delay)


## Un relámpago lejano y el siguiente a la espera.
func _on_timer_timeout() -> void:
	strike(false)
	_timer.start(randf_range(min_wait, max_wait))
