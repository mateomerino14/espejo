class_name MusicDirector
extends Node
## Música que sigue al Q'ispi: calma con una quena lejana mientras acecha, tensión cuando rastrea
## un ruido o está aturdido, y bombo con cuerdas raspadas cuando caza. Sin Q'ispi queda en calma.

enum Mood { CALM, TENSION, CHASE }

## Volumen de una capa apagada.
const SILENT_DB := -60.0

## El Q'ispi del nivel; la música cambia con su estado.
@export var qispi: Qispi
## Lo que tarda en pasar de una capa a otra.
@export var fade_seconds := 3.0
## La persecución entra casi de golpe.
@export var chase_fade_seconds := 0.5

@export_group("Quena (s)")
@export var quena_min_wait := 35.0
@export var quena_max_wait := 80.0

var mood := Mood.CALM

var _base_volumes: Dictionary[Mood, float] = {}
var _fade: Tween

@onready var _layers: Dictionary[Mood, AudioStreamPlayer] = {
	Mood.CALM: $Calm,
	Mood.TENSION: $Tension,
	Mood.CHASE: $Chase,
}
@onready var _quena: AudioStreamPlayer = $Quena
@onready var _quena_timer: Timer = $QuenaTimer


## Arranca todas las capas juntas, con solo la calma audible, y escucha al Q'ispi.
func _ready() -> void:
	for layer_mood: Mood in _layers:
		var layer := _layers[layer_mood]
		_base_volumes[layer_mood] = layer.volume_db
		if layer_mood != Mood.CALM:
			layer.volume_db = SILENT_DB
		layer.play()
	_quena_timer.timeout.connect(_on_quena_timer_timeout)
	_restart_quena_timer()
	if qispi:
		qispi.state_changed.connect(_on_qispi_state_changed)


## Pasa a [param new_mood]: sube su capa y baja las demás.
func set_mood(new_mood: Mood) -> void:
	if new_mood == mood:
		return
	mood = new_mood
	var seconds := fade_seconds
	if new_mood == Mood.CHASE:
		seconds = chase_fade_seconds
	if _fade:
		_fade.kill()
	_fade = create_tween().set_parallel()
	for layer_mood: Mood in _layers:
		var target := SILENT_DB
		if layer_mood == new_mood:
			target = _base_volumes[layer_mood]
		_fade.tween_property(_layers[layer_mood], "volume_db", target, seconds)
	if new_mood != Mood.CALM:
		_quena.stop()


## Devuelve el ánimo de la música para un estado del Q'ispi.
static func mood_for(state: Qispi.State) -> Mood:
	match state:
		Qispi.State.HUNT:
			return Mood.CHASE
		Qispi.State.TRACK, Qispi.State.STUNNED:
			return Mood.TENSION
		_:
			return Mood.CALM


## Sigue el estado del Q'ispi.
func _on_qispi_state_changed(new_state: Qispi.State) -> void:
	set_mood(mood_for(new_state))


## En calma, de vez en cuando suena una frase de quena a lo lejos.
func _on_quena_timer_timeout() -> void:
	if mood == Mood.CALM:
		_quena.play()
	_restart_quena_timer()


## Espera un rato al azar hasta la próxima frase.
func _restart_quena_timer() -> void:
	_quena_timer.start(randf_range(quena_min_wait, quena_max_wait))
