class_name LampFlicker
extends OmniLight3D
## Llama de kerosene: la luz tiembla sola, con algún bajón de vez en cuando.

## Cuánto se aleja la intensidad de la base, como fracción de ella.
@export_range(0.0, 1.0) var flicker := 0.18
## Qué tan rápido cambia la llama.
@export var speed := 7.0

var _base_energy := 0.0
var _noise := FastNoiseLite.new()
var _time := 0.0


## Guarda la intensidad base y elige un ruido distinto para cada lámpara.
func _ready() -> void:
	_base_energy = light_energy
	_noise.seed = randi()
	_noise.frequency = 1.0


## Hace temblar la llama.
func _process(delta: float) -> void:
	_time += delta * speed
	light_energy = _base_energy * (1.0 + _noise.get_noise_1d(_time) * flicker)
