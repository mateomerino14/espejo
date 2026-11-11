class_name CardonDoor
extends Node3D
## Puerta de cardón: se abre y se cierra con la tecla de usar, girando sobre sus bisagras.
##
## El Q'ispi la atraviesa: vive en el reflejo y la puerta solo está en la capa de puertas.

const OPEN_PROMPT := "Abrir la puerta"
const CLOSE_PROMPT := "Cerrar la puerta"
const LOCKED_PROMPT := "Está cerrada con llave"

@export var is_open := false
## Cerrada con llave: no se abre, solo lo dice.
@export var is_locked := false
## Positivo: con el marco en una pared de pasillo, la puerta se abre hacia el cuarto.
@export var open_angle_degrees := 100.0
@export var swing_seconds := 0.8
## Volumen del crujido para quien escuche (0 a 1).
@export var creak_loudness := 0.25

var _swing: Tween

@onready var _hinge: Node3D = $Hinge
@onready var _interactable: Interactable = $Hinge/Interactable
@onready var _creak: AudioStreamPlayer3D = $Hinge/Creak


## Deja la puerta en su posición inicial y conecta la interacción.
func _ready() -> void:
	_hinge.rotation.y = _target_angle()
	_interactable.set_prompt_builder(_build_prompt)
	_interactable.interacted.connect(_on_interacted)


## Abre o cierra la puerta con un giro y un crujido que se oye.
func set_open(value: bool) -> void:
	is_open = value
	if _swing:
		_swing.kill()
	_swing = create_tween().set_trans(Tween.TRANS_SINE)
	_swing.tween_property(_hinge, "rotation:y", _target_angle(), swing_seconds)
	_creak.play()
	EventBus.noise_emitted.emit(global_position, creak_loudness)


## Devuelve el giro de la bisagra según si está abierta.
func _target_angle() -> float:
	if is_open:
		return deg_to_rad(open_angle_degrees)
	return 0.0


## Arma el texto según si está abierta o con llave.
func _build_prompt(_player: Player) -> String:
	if is_locked:
		return LOCKED_PROMPT
	if is_open:
		return CLOSE_PROMPT
	return OPEN_PROMPT


## La usa Lucía: la abre si está cerrada y la cierra si está abierta; con llave no hace nada.
func _on_interacted(_player: Player) -> void:
	if not is_locked:
		set_open(not is_open)
