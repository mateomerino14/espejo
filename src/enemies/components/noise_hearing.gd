class_name NoiseHearing
extends Node3D
## Oído del ente: escucha los ruidos del bus y avisa los que llegan hasta él.

signal heard(origin: Vector3, strength: float)

## Distancia a la que se oye un ruido de volumen 1.
@export var hearing_radius := 18.0

var enabled := true


## Se suscribe a los ruidos del mundo.
func _ready() -> void:
	EventBus.noise_emitted.connect(_on_noise_emitted)


## Devuelve hasta qué distancia se oye un ruido de ese volumen.
func get_reach(loudness: float) -> float:
	return loudness * hearing_radius


## Avisa el ruido si llegó; la fuerza baja con la distancia. Fuera del mundo no oye nada.
func _on_noise_emitted(origin: Vector3, loudness: float) -> void:
	if not enabled or not is_inside_tree():
		return
	var reach := get_reach(loudness)
	var distance := global_position.distance_to(origin)
	if distance <= reach:
		heard.emit(origin, 1.0 - distance / reach)
