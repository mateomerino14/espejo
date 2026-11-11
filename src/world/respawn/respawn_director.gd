class_name RespawnDirector
extends Node
## Dirige la captura: funde a negro, lleva a Lucía al punto de reaparición y reinicia a los entes.

## Dónde reaparece Lucía.
@export var spawn_point: Node3D
## Segundos de susto mirando al ente antes de fundir a negro.
@export var scare_seconds := 1.4
## Segundos en negro antes de reaparecer.
@export var black_hold_seconds := 1.6

var is_respawning := false

@onready var _death_screen: DeathScreen = $DeathScreen
@onready var _hold_timer: Timer = $HoldTimer


## Escucha las capturas de Lucía.
func _ready() -> void:
	EventBus.player_caught.connect(_on_player_caught)


## Corre la secuencia completa de captura y reaparición.
func _on_player_caught() -> void:
	if is_respawning:
		return
	is_respawning = true
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	player.set_controls_enabled(false)
	_hold_timer.start(scare_seconds)
	await _hold_timer.timeout
	await _death_screen.fade_out()
	_hold_timer.start(black_hold_seconds)
	await _hold_timer.timeout
	player.respawn_at(spawn_point.global_transform)
	for enemy: Qispi in get_tree().get_nodes_in_group(Qispi.GROUP):
		enemy.reset()
	await _death_screen.fade_in()
	player.set_controls_enabled(true)
	is_respawning = false
