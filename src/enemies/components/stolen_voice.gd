class_name StolenVoice
extends AudioStreamPlayer3D
## Las voces que el Q'ispi le robó a otros: cada tanto, desde donde está, llama a Lucía con la voz
## de Javier o de Doña Rosa, para que vaya a buscarlos.

@export var min_wait := 25.0
@export var max_wait := 50.0

@onready var _timer: Timer = $Timer


## Espera la primera llamada.
func _ready() -> void:
	_timer.timeout.connect(_on_timer_timeout)
	_timer.start(randf_range(min_wait, max_wait))


## Llama, si el ente está despierto, y espera la próxima.
func _on_timer_timeout() -> void:
	if can_process():
		play()
	_timer.start(randf_range(min_wait, max_wait))
