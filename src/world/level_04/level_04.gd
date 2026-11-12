class_name Level04
extends GameLevel
## Nivel 4, la isla Incahuasi: Don Celestino espera en la cima junto a su q'oa. Mientras habla, el
## humo aquieta al Q'ispi; cuando termina, Lucía puede bajar al bote y seguir hacia el centro del
## salar.

## Lo que el Q'ispi sigue quieto después de que Don Celestino termina.
const TALK_MARGIN_SECONDS := 10.0
const OPEN_NOTICE := "Don Celestino te deja su bote, en la orilla oeste."

@export var celestino: TalkingNpc
@export var exit: LevelExit
@export var qispi: Qispi


## Cierra la salida hasta que Don Celestino hable.
func _ready() -> void:
	super()
	exit.is_open = false
	celestino.conversation_started.connect(_on_conversation_started)
	celestino.conversation_finished.connect(_on_conversation_finished)


## Mientras habla, el Q'ispi no se acerca.
func _on_conversation_started(seconds: float) -> void:
	qispi.calm_for(seconds + TALK_MARGIN_SECONDS)


## La primera vez que termina, abre la salida y avisa dónde está el bote.
func _on_conversation_finished() -> void:
	if exit.is_open:
		return
	exit.is_open = true
	EventBus.notice_requested.emit(OPEN_NOTICE)
