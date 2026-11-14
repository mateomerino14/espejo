class_name QispiAmbush
extends Area3D
## Emboscada: cuando Lucía cruza la zona, el Q'ispi sale de golpe en un punto y va por ella, con un
## golpe de susto. Pasa una sola vez y no se repite al continuar la partida.

## Marca con que se recuerda que ya pasó; única en el nivel.
@export var done_id := ""
@export var qispi: Qispi
## Dónde sale el Q'ispi, respecto de la zona que lo dispara.
@export var spawn_offset := Vector3(0.0, 0.0, -8.0)
## Solo pasa si el objetivo actual es este; vacío para que pase siempre.
@export var after_objective := ""

@onready var _spawn: Marker3D = $Spawn
@onready var _sting: AudioStreamPlayer = $Sting


## Pone el punto de salida y escucha a Lucía.
func _ready() -> void:
	_spawn.position = spawn_offset
	body_entered.connect(_on_body_entered)


## Hace salir al Q'ispi una vez, si toca en este momento de la historia; lo despierta si dormía.
func _on_body_entered(body: Node3D) -> void:
	if not body is Player or GameState.is_done(done_id):
		return
	if not after_objective.is_empty() and GameState.objective != after_objective:
		return
	GameState.mark_done(done_id)
	_sting.play()
	if qispi.process_mode == Node.PROCESS_MODE_DISABLED:
		qispi.wake()
	qispi.emerge_at(_spawn.global_position, body.global_position)
