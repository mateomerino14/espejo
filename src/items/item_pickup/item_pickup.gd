class_name ItemPickup
extends Node3D
## Algo que Lucía recoge del suelo para la mochila: coca, velas, mantas, rollos o pilas. Si no le
## cabe, lo deja donde está.

const PICK_PROMPT := "Recoger %s"
const PICKED_NOTICE := "Recogiste %s"
const FULL_NOTICE := "No te cabe más: %s"

@export var item_type := ItemCatalog.Type.COCA
## Cuántas hay juntas, como una pila de mantas.
@export var count := 1

@onready var _interactable: Interactable = $Interactable


## Pone el modelo y el texto, y escucha cuando Lucía la recoge.
func _ready() -> void:
	add_child(ItemCatalog.visual(item_type).instantiate())
	_interactable.prompt = PICK_PROMPT % ItemCatalog.display_name(item_type)
	_interactable.interacted.connect(_on_interacted)


## Guarda lo que quepa; lo que sobra se queda en el suelo.
func _on_interacted(_player: Player) -> void:
	var added := GameState.add_item(item_type, count)
	if added <= 0:
		EventBus.notice_requested.emit(FULL_NOTICE % ItemCatalog.display_name(item_type))
		return
	count -= added
	EventBus.notice_requested.emit(PICKED_NOTICE % ItemCatalog.name_with_article(item_type))
	if count <= 0:
		queue_free()
