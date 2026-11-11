class_name Ambience
extends Node3D
## Fondo del salar: el viento no para y, de vez en cuando, la sal cruje o cae una gota cerca de
## quien escucha.

@export_group("Acentos")
@export var min_wait := 6.0
@export var max_wait := 18.0
## Los acentos suenan a esta distancia, como máximo, de la cámara.
@export var accent_radius := 5.0

@onready var _wind: AudioStreamPlayer = $Wind
@onready var _accent: AudioStreamPlayer3D = $Accent
@onready var _timer: Timer = $AccentTimer


## Arranca el viento y espera el primer acento.
func _ready() -> void:
	_wind.play()
	_timer.timeout.connect(_on_timer_timeout)
	_timer.start(randf_range(min_wait, max_wait))


## Hace sonar un acento en algún punto alrededor de la cámara y espera al siguiente.
func _on_timer_timeout() -> void:
	var listener := get_viewport().get_camera_3d()
	if listener:
		var angle := randf() * TAU
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * randf_range(1.0, accent_radius)
		_accent.global_position = listener.global_position + offset
		_accent.play()
	_timer.start(randf_range(min_wait, max_wait))
