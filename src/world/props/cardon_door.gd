class_name CardonDoor
extends Node3D
## Puerta de cardón: se abre y se cierra con la tecla de usar, girando sobre sus bisagras.
##
## El Q'ispi la atraviesa: vive en el reflejo y la puerta solo está en la capa de puertas.

const OPEN_PROMPT := "Abrir la puerta"
const CLOSE_PROMPT := "Cerrar la puerta"
const LOCKED_PROMPT := "Está cerrada con llave"
const UNLOCK_PROMPT := "Abrir con %s"
const UNLOCKED_NOTICE := "Abriste la puerta con %s"

@export var is_open := false
## Cerrada con llave: no se abre, solo lo dice.
@export var is_locked := false
## Herramienta que la abre si está con llave; vacío si no hay llave que la abra.
@export var key_tool := ""
## Marca con que se recuerda que ya se abrió con su llave; única en el nivel.
@export var done_id := ""
## Objetivo una vez abierta con su llave; vacío para no cambiarlo.
@export var objective_after := ""
## Positivo: con el marco en una pared de pasillo, la puerta se abre hacia el cuarto.
@export var open_angle_degrees := 100.0
@export var swing_seconds := 0.8
## Volumen del crujido para quien escuche (0 a 1).
@export var creak_loudness := 0.25
## Volumen del golpe al cerrarse y del traqueteo de la manija con llave (0 a 1).
@export var knock_loudness := 0.15

var _swing: Tween

@onready var _hinge: Node3D = $Hinge
@onready var _interactable: Interactable = $Hinge/Interactable
@onready var _creak: AudioStreamPlayer3D = $Hinge/Creak
@onready var _open: AudioStreamPlayer3D = $Hinge/Open
@onready var _shut: AudioStreamPlayer3D = $Hinge/Shut
@onready var _rattle: AudioStreamPlayer3D = $Hinge/Rattle


## Deja la puerta en su posición inicial y conecta la interacción.
func _ready() -> void:
	if not done_id.is_empty() and GameState.is_done(done_id):
		is_locked = false
	_hinge.rotation.y = _target_angle()
	_interactable.set_prompt_builder(_build_prompt)
	_interactable.interacted.connect(_on_interacted)


## Abre o cierra con un giro: al abrir suenan pestillo y bisagra; al cerrar, crujido y golpe.
func set_open(value: bool) -> void:
	is_open = value
	if _swing:
		_swing.kill()
	_swing = create_tween().set_trans(Tween.TRANS_SINE)
	_swing.tween_property(_hinge, "rotation:y", _target_angle(), swing_seconds)
	if value:
		_open.play()
	else:
		_swing.tween_callback(_on_shut)
		_creak.play()
	EventBus.noise_emitted.emit(global_position, creak_loudness)


## La puerta llegó al marco: golpe de madera.
func _on_shut() -> void:
	_shut.play()
	EventBus.noise_emitted.emit(global_position, knock_loudness)


## Devuelve el giro de la bisagra según si está abierta.
func _target_angle() -> float:
	if is_open:
		return deg_to_rad(open_angle_degrees)
	return 0.0


## Arma el texto según si está abierta, con llave o si Lucía lleva la llave.
func _build_prompt(_player: Player) -> String:
	if is_locked and _has_key():
		return UNLOCK_PROMPT % key_tool
	if is_locked:
		return LOCKED_PROMPT
	if is_open:
		return CLOSE_PROMPT
	return OPEN_PROMPT


## La usa Lucía: abre o cierra; con llave, la abre si tiene la llave y si no, traquetea.
func _on_interacted(_player: Player) -> void:
	if is_locked and _has_key():
		_unlock()
		return
	if is_locked:
		_rattle.play()
		EventBus.noise_emitted.emit(global_position, knock_loudness)
		return
	set_open(not is_open)


## Dice si Lucía lleva la llave de esta puerta.
func _has_key() -> bool:
	return not key_tool.is_empty() and GameState.has_tool(key_tool)


## Gasta la llave, la abre, lo recuerda y da el objetivo siguiente.
func _unlock() -> void:
	GameState.use_tool(key_tool)
	GameState.mark_done(done_id)
	is_locked = false
	EventBus.notice_requested.emit(UNLOCKED_NOTICE % key_tool)
	set_open(true)
	if not objective_after.is_empty():
		GameState.set_objective(objective_after)
