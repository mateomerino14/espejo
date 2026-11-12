class_name MirrorPassage
extends Node
## El Q'ispi sale de los espejos destapados: cada tanto, si acecha lejos de Lucía, aparece en el
## espejo destapado más cercano a ella y va a buscarla. Tapar los espejos le cierra el paso.

@export var qispi: Qispi
@export var min_wait := 18.0
@export var max_wait := 35.0
## Solo usa espejos a esta distancia de Lucía, como máximo.
@export var reach := 14.0
## Solo salta si está más lejos que esto de ella.
@export var min_jump_distance := 7.0
## Sale este tanto por delante del vidrio.
@export var step_out := 0.8

@onready var _timer: Timer = $Timer
@onready var _sound: AudioStreamPlayer3D = $Sound


## Espera el primer salto.
func _ready() -> void:
	_timer.timeout.connect(_on_timer_timeout)
	_timer.start(randf_range(min_wait, max_wait))


## Devuelve el espejo destapado más cercano a [param point] dentro del alcance, o null.
func nearest_open_mirror(point: Vector3) -> Mirror:
	var nearest: Mirror
	var nearest_distance := reach
	for mirror: Mirror in get_tree().get_nodes_in_group(Mirror.GROUP):
		var distance := mirror.global_position.distance_to(point)
		if mirror.coverable and not mirror.is_covered and distance <= nearest_distance:
			nearest = mirror
			nearest_distance = distance
	return nearest


## Si puede, sale por el espejo destapado más cercano a Lucía; luego espera el próximo.
func _on_timer_timeout() -> void:
	_timer.start(randf_range(min_wait, max_wait))
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	if player == null or player.is_hidden() or not _can_jump(player):
		return
	var mirror := nearest_open_mirror(player.global_position)
	if mirror == null:
		return
	var spot := mirror.global_position + mirror.global_basis.z * step_out
	spot.y = qispi.global_position.y
	qispi.emerge_at(spot, player.global_position)
	_sound.global_position = mirror.global_position
	_sound.play()


## Despierto, acechando tranquilo y lejos de ella.
func _can_jump(player: Player) -> bool:
	if not qispi.can_process() or qispi.state != Qispi.State.STALK or qispi.is_calm():
		return false
	return qispi.global_position.distance_to(player.global_position) >= min_jump_distance
