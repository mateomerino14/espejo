class_name ToolPickup
extends Node3D
## Algo que abre el camino, como una llave o los remos del bote. No va a la mochila con lo demás:
## se lleva hasta que se usa.

const PICK_PROMPT := "Recoger %s"
const PICKED_NOTICE := "Recogiste %s"

## Nombre de la herramienta, como lo ve la jugadora; con él la pide la puerta o el bote.
@export var tool_name := ""
## Modelo de la herramienta.
@export var visual: PackedScene
## Objetivo una vez recogida; vacío para no cambiarlo.
@export var objective_after := ""

@onready var _interactable: Interactable = $Interactable


## Pone el modelo, conecta la interacción y desaparece si ya se había recogido.
func _ready() -> void:
	_interactable.prompt = PICK_PROMPT % tool_name
	_interactable.interacted.connect(_on_interacted)
	if visual:
		add_child(visual.instantiate())
	_hide_if_taken.call_deferred()


## Al continuar una partida en que ya la tenía o ya la usó, no vuelve a aparecer.
func _hide_if_taken() -> void:
	if GameState.has_tool(tool_name) or GameState.is_done(_done_id()):
		queue_free()


## La recoge, avisa y da el objetivo siguiente.
func _on_interacted(_player: Player) -> void:
	GameState.add_tool(tool_name)
	GameState.mark_done(_done_id())
	EventBus.notice_requested.emit(PICKED_NOTICE % tool_name)
	if not objective_after.is_empty():
		GameState.set_objective(objective_after)
	queue_free()


## Marca con que se recuerda que ya se recogió.
func _done_id() -> String:
	return "recogida:" + tool_name
