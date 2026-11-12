class_name BatteryPickup
extends Node3D
## Pilas para el flash de la cámara: se recogen una vez y desaparecen.

const PROMPT := "Recoger pilas"
const NOTICE := "Pilas nuevas para el flash."

## Cuánta batería devuelven, en las mismas unidades que la cámara.
@export var charge := 50.0

@onready var _interactable: Interactable = $Interactable


## Escucha cuando Lucía las recoge.
func _ready() -> void:
	_interactable.prompt = PROMPT
	_interactable.interacted.connect(_on_interacted)


## Carga el flash, avisa y desaparece.
func _on_interacted(player: Player) -> void:
	player.recharge_camera(charge)
	EventBus.notice_requested.emit(NOTICE)
	queue_free()
