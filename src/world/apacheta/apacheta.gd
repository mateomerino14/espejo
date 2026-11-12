class_name Apacheta
extends Node3D
## Apacheta: montículo de piedras donde se deja coca y una vela para pedir permiso al lugar. Cada
## ofrenda aquieta al Q'ispi un rato, guarda la partida y cuenta para el final.

const OFFER_PROMPT := "Dejar coca y una vela"
const DONE_PROMPT := "Tu ofrenda sigue encendida"
const NOTICE := "Dejaste coca en la apacheta. Algo, lejos, se aquietó."

## Nombre único de esta apacheta, para recordar si ya tiene ofrenda.
@export var apacheta_id := ""

@onready var _interactable: Interactable = $Interactable
@onready var _offering: Node3D = $Offering
@onready var _sound: AudioStreamPlayer3D = $Sound


## Muestra la ofrenda si ya se dejó en una partida anterior.
func _ready() -> void:
	_interactable.set_prompt_builder(_build_prompt)
	_interactable.interacted.connect(_on_interacted)
	_offering.visible = GameState.has_offering(apacheta_id)


## Ofrece dejar la ofrenda, o recuerda que ya está.
func _build_prompt(_player: Player) -> String:
	if GameState.has_offering(apacheta_id):
		return DONE_PROMPT
	return OFFER_PROMPT


## Deja la coca y la vela una sola vez.
func _on_interacted(_player: Player) -> void:
	if GameState.has_offering(apacheta_id):
		return
	GameState.add_offering(apacheta_id)
	_offering.visible = true
	_sound.play()
	EventBus.notice_requested.emit(NOTICE)
	EventBus.offering_made.emit(global_position)
