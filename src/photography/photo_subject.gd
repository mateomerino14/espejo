class_name PhotoSubject
extends Node3D
## Algo que vale la pena fotografiar: si sale en cuadro, la foto guarda su descripción.

const GROUP := &"photo_subjects"
## Capa de física que tapa la vista (el mundo).
const OCCLUDER_MASK := 1
## Margen para no contar como obstáculo la superficie donde está el sujeto.
const SURFACE_MARGIN := 0.15

## Texto que aparece en el álbum bajo la foto.
@export_multiline var caption := ""
@export var max_distance := 8.0


## Se registra para que la cámara lo encuentre.
func _ready() -> void:
	add_to_group(GROUP)


## Dice si la cámara lo ve: cerca, dentro del cuadro y sin nada en medio.
func is_visible_from(camera: Camera3D) -> bool:
	var from := camera.global_position
	var distance := from.distance_to(global_position)
	if distance > max_distance or not camera.is_position_in_frustum(global_position):
		return false
	var query := PhysicsRayQueryParameters3D.create(from, global_position, OCCLUDER_MASK)
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var hit_position: Vector3 = hit.position
	return from.distance_to(hit_position) >= distance - SURFACE_MARGIN
