class_name HintTrigger
extends Area3D
## Zona redonda que pide un consejo de controles cuando Lucía se acerca; va dentro de las apachetas,
## los escondites y los espejos. El consejo no se repite.

## Capa de Lucía.
const PLAYER_LAYER := 2

## Identificador del consejo en HintCatalog.
@export var hint_id := ""
## Distancia a la que Lucía lo pide.
@export var radius := 3.0


## Arma su zona y escucha a Lucía.
func _ready() -> void:
	collision_layer = 0
	collision_mask = PLAYER_LAYER
	monitorable = false
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	var shape := CollisionShape3D.new()
	shape.shape = sphere
	add_child(shape)
	body_entered.connect(_on_body_entered)


## Pide el consejo al llegar Lucía.
func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		EventBus.hint_requested.emit(hint_id)
