class_name ReflectionGuide
extends Node3D
## Alguien que solo se ve en el reflejo del agua y camina delante de Lucía hacia donde tiene que
## ir: avanza mientras ella lo sigue de cerca y la espera si se queda atrás. Su modelo mira hacia
## +Z.

## Distancia a un punto del camino para darlo por alcanzado.
const ARRIVE_DISTANCE := 0.3
const BLEND_SECONDS := 0.3

## Los puntos por los que camina, en orden, en coordenadas del mundo.
@export var waypoints: PackedVector3Array = []
@export var player: Node3D
@export var animation_player: AnimationPlayer
@export var walk_animation := &"walk"
@export var idle_animation := &"idle"
@export var walk_speed := 1.3
## Si Lucía está más lejos que esto, la espera quieto.
@export var lead_distance := 10.0
## Capa en la que se dibuja: la del reflejo, para que solo aparezca en el agua y los espejos.
@export_flags_3d_render var render_layers := 1024

var _index := 0


## Lo pasa a la capa del reflejo y lo deja esperando.
func _ready() -> void:
	for mesh: VisualInstance3D in find_children("*", "VisualInstance3D", true, false):
		mesh.layers = render_layers
	if animation_player:
		for animation_name: StringName in [walk_animation, idle_animation]:
			animation_player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
		animation_player.play(idle_animation)


## Si Lucía lo sigue, camina hacia el próximo punto; si no, espera.
func _physics_process(delta: float) -> void:
	if is_finished() or not _is_followed():
		_play(idle_animation)
		return
	var to_target := waypoints[_index] - global_position
	to_target.y = 0.0
	if to_target.length() < ARRIVE_DISTANCE:
		_index += 1
		return
	global_position += to_target.normalized() * minf(walk_speed * delta, to_target.length())
	rotation.y = atan2(to_target.x, to_target.z)
	_play(walk_animation)


## Si ya llegó al último punto.
func is_finished() -> bool:
	return _index >= waypoints.size()


## Si Lucía está lo bastante cerca como para seguirlo.
func _is_followed() -> bool:
	return player and global_position.distance_to(player.global_position) <= lead_distance


## Cambia de animación solo si hace falta.
func _play(animation_name: StringName) -> void:
	if animation_player and animation_player.current_animation != animation_name:
		animation_player.play(animation_name, BLEND_SECONDS)
