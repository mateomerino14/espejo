class_name HidingSpot
extends Node3D
## Escondite: Lucía entra y desde adentro solo puede mirar hacia afuera, entre las rendijas. El
## Q'ispi no la ve ahí, pero revisa los escondites cercanos a donde la perdió, y si la vio entrar,
## la encuentra.

const GROUP := &"hiding_spots"
const ENTER_PROMPT := "Esconderse"

## Lo que tarda Lucía en entrar o salir.
@export var move_seconds := 0.7
## Lo que suena al entrar y al salir: la puerta que se abre y se cierra con Lucía adentro.
@export var enter_sound: AudioStream
@export var leave_sound: AudioStream
## Cuánto puede girar la cabeza adentro, hacia cada lado.
@export_range(0.0, 90.0) var look_limit_degrees := 35.0

## Quién está escondido adentro, si hay alguien.
var occupant: Player

@onready var _inside: Marker3D = $Inside
@onready var _exit: Marker3D = $Exit
@onready var _search: Marker3D = $Search
@onready var _interactable: Interactable = $Interactable
@onready var _sound: AudioStreamPlayer3D = $Sound


## Se anota en el grupo de escondites y escucha cuando lo usan.
func _ready() -> void:
	add_to_group(GROUP)
	_interactable.set_prompt_builder(_build_prompt)
	_interactable.interacted.connect(_on_interacted)


## Dónde quedan los pies de Lucía adentro y hacia dónde mira (su −Z).
func get_inside_transform() -> Transform3D:
	return _inside.global_transform


## Dónde queda Lucía al salir.
func get_exit_transform() -> Transform3D:
	return _exit.global_transform


## Dónde se para el Q'ispi para revisarlo.
func get_search_position() -> Vector3:
	return _search.global_position


## Lucía entra.
func enter(player: Player) -> void:
	occupant = player
	_interactable.enabled = false
	_play(enter_sound)


## Lucía sale, o la sacan.
func leave() -> void:
	occupant = null
	_interactable.enabled = true
	_play(leave_sound)


## Ofrece esconderse si está vacío.
func _build_prompt(_player: Player) -> String:
	return ENTER_PROMPT


## Lucía lo usa para esconderse.
func _on_interacted(player: Player) -> void:
	if occupant == null:
		player.hide_in(self)


## Hace sonar [param stream], o el sonido que trae el escondite si no hay otro.
func _play(stream: AudioStream) -> void:
	if stream:
		_sound.stream = stream
	_sound.play()
