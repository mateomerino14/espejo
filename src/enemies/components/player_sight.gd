class_name PlayerSight
extends Node3D
## Vista del ente: ve a Lucía dentro del cono y del alcance, sin nada en medio y sin esconderse.

## Mundo y puertas: lo que tapa la vista.
const WORLD_MASK := 17

@export_range(10.0, 180.0) var field_of_view_degrees := 110.0
@export var view_range := 12.0
## A esta distancia la nota siempre, aunque esté fuera del cono.
@export var touch_range := 1.3

var enabled := true


## Dice si ve a Lucía en este momento.
func can_see(player: Player) -> bool:
	if not enabled or player == null or player.is_hidden():
		return false
	var target := player.get_eye_position()
	var distance := global_position.distance_to(target)
	if distance <= touch_range:
		return true
	if distance > view_range or not _is_inside_cone(target):
		return false
	return _has_clear_line(target)


## Dice si el punto cae dentro del cono de visión.
func _is_inside_cone(target: Vector3) -> bool:
	var to_target := (target - global_position).normalized()
	return (-global_basis.z).angle_to(to_target) <= deg_to_rad(field_of_view_degrees) / 2.0


## Dice si no hay nada sólido entre los ojos y el punto.
func _has_clear_line(target: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position, target, WORLD_MASK)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
