class_name Level04
extends GameLevel
## Nivel 4, la isla: Don Celestino aquieta al Q'ispi mientras habla y después abre el bote.

## Lo que el Q'ispi sigue quieto después de que Don Celestino termina.
const TALK_MARGIN_SECONDS := 10.0
const OPEN_NOTICE := "Don Celestino te deja su bote. Los remos están en la ladera norte."
const BOAT_OBJECTIVE := "Don Celestino dejó los remos entre los cardones de la ladera norte"

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


## La primera vez que termina, abre la salida, avisa dónde está el bote y lo da de objetivo.
func _on_conversation_finished() -> void:
	if exit.is_open:
		return
	exit.is_open = true
	EventBus.notice_requested.emit(OPEN_NOTICE)
	GameState.set_objective(BOAT_OBJECTIVE)
