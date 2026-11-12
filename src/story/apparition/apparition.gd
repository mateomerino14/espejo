class_name Apparition
extends Node3D
## Aparición: alguien que solo se ve por el visor. Cuando Lucía lo ve y baja la cámara, ya no está.

## Distancia hasta la que cuenta como visto por el visor.
@export var seen_range := 14.0

var was_seen := false

var _is_camera_raised := false

@onready var _face: Node3D = $Face


## Escucha cuándo Lucía levanta o baja la cámara.
func _ready() -> void:
	EventBus.camera_raised.connect(_on_camera_raised)


## Mientras mira por el visor, revisa si la aparición está en cuadro.
func _process(_delta: float) -> void:
	if not _is_camera_raised or was_seen:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var face := _face.global_position
	if camera.global_position.distance_to(face) <= seen_range:
		was_seen = camera.is_position_in_frustum(face)


## Al bajar la cámara después de verla, desaparece.
func _on_camera_raised(is_raised: bool) -> void:
	_is_camera_raised = is_raised
	if not is_raised and was_seen:
		queue_free()
