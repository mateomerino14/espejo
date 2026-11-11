class_name CaughtReaction
extends Node
## Susto al ser atrapada: la vista gira a la cara del ente, que se ve aunque no se mire por el
## visor, se acerca, tiembla y suena su grito.

## El temblor vertical va a otro ritmo que el horizontal para que no parezca un círculo.
const SHAKE_VERTICAL_RATIO := 1.3

## Cuerpo que gira hacia el captor, cabeza que sube o baja la mirada y cámara que tiembla.
@export var body: Node3D
@export var head: Node3D
@export var camera: Camera3D
## Capa de render del reflejo, que se muestra durante el susto.
@export_range(1, 20) var reveal_layer := 11

## Rapidez con la que la mirada se clava en la cara.
@export var turn_speed := 9.0
## Metros que la vista se arrastra hacia la cara.
@export var pull_distance := 0.15
@export var pull_speed := 3.0
## Temblor de la vista en el momento del susto, que se va calmando.
@export var shake_strength := 0.03
@export var shake_decay := 1.6
@export var shake_frequency := 38.0

var _catcher: Qispi
var _shake := 0.0
var _time := 0.0

@onready var _scream: AudioStreamPlayer = $Scream


## Escucha las capturas.
func _ready() -> void:
	EventBus.player_caught.connect(_on_player_caught)
	set_process(false)


## Mira a la cara del captor, se acerca y tiembla.
func _process(delta: float) -> void:
	_time += delta
	var face := _catcher.get_face_position()
	var to_face := face - head.global_position
	var flat := Vector2(to_face.x, to_face.z)
	var yaw := atan2(-to_face.x, -to_face.z)
	var pitch := atan2(to_face.y, flat.length())
	body.rotation.y = lerp_angle(body.rotation.y, yaw, turn_speed * delta)
	head.rotation.x = lerp_angle(head.rotation.x, pitch, turn_speed * delta)
	var target_pull := Vector3.FORWARD * pull_distance
	camera.position = camera.position.move_toward(target_pull, pull_speed * delta)
	_shake = move_toward(_shake, 0.0, shake_decay * shake_strength * delta)
	camera.h_offset = sin(_time * shake_frequency) * _shake
	camera.v_offset = cos(_time * shake_frequency * SHAKE_VERTICAL_RATIO) * _shake


## Deja la vista quieta y normal; se usa al reaparecer.
func reset() -> void:
	_catcher = null
	set_process(false)
	camera.set_cull_mask_value(reveal_layer, false)
	camera.position = Vector3.ZERO
	camera.h_offset = 0.0
	camera.v_offset = 0.0


## Busca al captor más cercano y empieza el susto.
func _on_player_caught() -> void:
	_catcher = _closest_enemy()
	if _catcher == null:
		return
	_time = 0.0
	_shake = shake_strength
	_scream.play()
	camera.set_cull_mask_value(reveal_layer, true)
	set_process(true)


## Devuelve el ente más cercano a Lucía, o nada si no hay.
func _closest_enemy() -> Qispi:
	var closest: Qispi
	var best := INF
	for enemy: Qispi in get_tree().get_nodes_in_group(Qispi.GROUP):
		var distance := enemy.global_position.distance_to(body.global_position)
		if distance < best:
			best = distance
			closest = enemy
	return closest
