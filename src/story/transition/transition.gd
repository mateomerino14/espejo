class_name Transition
extends Node3D
## Tránsito entre niveles: Lucía cruza el salar, a pie o en el bote, y dice lo que piensa; a veces
## el Q'ispi la sigue en el reflejo del agua. La pantalla funde a negro y se carga el nivel
## siguiente, que muestra su nombre al empezar.

## Termina el tránsito, visto entero o saltado.
signal finished

const SCENE_PATH := "res://src/story/transition/transition.tscn"
const NIGHT := preload("res://src/story/transition/night_environment.tres")
const DAWN := preload("res://src/story/transition/dawn_environment.tres")
const OPAQUE := 1.0
const CLEAR := 0.0
const WALK := &"walk"
const STAND := &"idle"
const BLEND_SECONDS := 0.3
const SUBTITLE_FORMAT := "Lucía: %s"
## Metros por segundo que cubre la caminata de Lucía a velocidad normal de la animación.
const LUCIA_NATURAL_SPEED := 1.1
## El Q'ispi camina más lento que su animación normal: acecha.
const QISPI_ANIMATION_SPEED := 0.6
## Capa que solo se ve en los reflejos.
const REFLECTION_LAYER := 11
## La luz de la luna al amanecer viene más baja y más tibia.
const DAWN_MOON_COLOR := Color(1.0, 0.72, 0.6)
const DAWN_MOON_ENERGY := 0.9

## Tránsito pendiente: lo deja la salida del nivel y lo toma esta escena al abrirse.
static var _pending_data: TransitionData
static var _pending_level := ""
## Queda en verdadero hasta que el nivel siguiente toma la llegada.
static var _has_arrival := false

## Si es falso no se reproduce solo; las pruebas lo apagan para controlarlo.
@export var enabled := true
@export var data: TransitionData
## Nivel que se carga al terminar; vacío en las pruebas.
@export_file("*.tscn") var next_level_path := ""

@export_group("Recorrido")
## Metros que Lucía avanza hacia la cámara.
@export var walk_distance := 7.0
## Metros que el Q'ispi avanza detrás de ella.
@export var qispi_walk_distance := 3.0

@export_group("Tiempos (s)")
@export var fade_seconds := 1.2
@export var walk_seconds := 11.0
@export var line_delay_seconds := 1.5
## Segundos en negro antes de cargar el nivel, para que Lucía termine de hablar.
@export var hold_seconds := 1.5
## Pasos de Lucía en el agua.
@export var step_seconds := 0.55

var is_playing := false

var _skip_requested := false
var _traveller_start := Vector3.ZERO
var _qispi_start := Vector3.ZERO

@onready var _environment: WorldEnvironment = $WorldEnvironment
@onready var _moon: DirectionalLight3D = $Moon
@onready var _rain: Node3D = $Rain
@onready var _rain_sound: AudioStreamPlayer = $RainSound
@onready var _trains: Node3D = $Horizon/Trains
@onready var _island: Node3D = $Horizon/Island
@onready var _boat: Node3D = $Boat
@onready var _lucia: Node3D = $Lucia
@onready var _qispi: Node3D = $Qispi
@onready var _voice: AudioStreamPlayer = $Voice
@onready var _steps: AudioStreamPlayer3D = $Lucia/Steps
@onready var _step_timer: Timer = $StepTimer
@onready var _wait_timer: Timer = $WaitTimer
@onready var _curtain: ColorRect = %Curtain
@onready var _subtitle: Label = %Subtitle


## Abre el tránsito hacia un nivel; la escena toma lo pendiente al cargarse.
static func go(tree: SceneTree, transition_data: TransitionData, level_path: String) -> void:
	_pending_data = transition_data
	_pending_level = level_path
	tree.change_scene_to_file.call_deferred(SCENE_PATH)


## Dice si el nivel que se abre viene de un tránsito, y lo olvida para la próxima vez.
static func take_arrival() -> bool:
	var arrived := _has_arrival
	_has_arrival = false
	return arrived


## Toma el tránsito pendiente, arma el salar y empieza solo si está activado.
func _ready() -> void:
	if _pending_data:
		data = _pending_data
		next_level_path = _pending_level
		_pending_data = null
		_pending_level = ""
	_curtain.modulate.a = OPAQUE
	_subtitle.text = ""
	_step_timer.timeout.connect(_steps.play)
	_hide_from_camera(_qispi)
	_apply_data()
	_traveller_start = _traveller().position
	_qispi_start = _qispi.position
	if enabled:
		play.call_deferred()


## Escape o usar saltan el tránsito.
func _input(event: InputEvent) -> void:
	if is_playing and (event.is_action_pressed("pause") or event.is_action_pressed("interact")):
		get_viewport().set_input_as_handled()
		skip()


## Reproduce el tránsito completo y carga el nivel siguiente.
func play() -> void:
	is_playing = true
	_start_moving()
	await _fade(_curtain, CLEAR)
	if await _wait(line_delay_seconds):
		_say()
	if await _wait(walk_seconds - line_delay_seconds - fade_seconds * 2.0):
		await _fade(_curtain, OPAQUE)
	_step_timer.stop()
	await _wait(hold_seconds)
	_finish()


## Corta lo que falta y pasa al nivel siguiente.
func skip() -> void:
	_skip_requested = true
	if not _wait_timer.is_stopped():
		_wait_timer.stop()
		_wait_timer.timeout.emit()


## Arma la hora, la lluvia, el horizonte, el bote y al Q'ispi según el tránsito.
func _apply_data() -> void:
	var is_dawn := data != null and data.is_dawn
	_environment.environment = NIGHT
	if is_dawn:
		_environment.environment = DAWN
		_moon.light_color = DAWN_MOON_COLOR
		_moon.light_energy = DAWN_MOON_ENERGY
	var has_rain := data != null and data.has_rain
	_rain.visible = has_rain
	_rain_sound.playing = has_rain
	_trains.visible = data != null and data.horizon == TransitionData.Horizon.TRAINS
	_island.visible = data != null and data.horizon == TransitionData.Horizon.ISLAND
	var is_boat := data != null and data.is_boat
	_boat.visible = is_boat
	if is_boat:
		_lucia.reparent(_boat, false)
		_lucia.position = Vector3.ZERO
	_qispi.visible = data != null and data.shows_qispi


## Lucía camina hacia la cámara, o el bote se desliza con ella; el Q'ispi la sigue en el reflejo.
func _start_moving() -> void:
	var speed := walk_distance / walk_seconds
	var tween := create_tween().set_parallel()
	tween.tween_property(
		_traveller(), "position", _traveller_start + Vector3.BACK * walk_distance, walk_seconds
	)
	if _boat.visible:
		_animate(_lucia, STAND, 1.0)
	else:
		_animate(_lucia, WALK, speed / LUCIA_NATURAL_SPEED)
		_step_timer.start(step_seconds)
	if _qispi.visible:
		_animate(_qispi, WALK, QISPI_ANIMATION_SPEED)
		tween.tween_property(
			_qispi, "position", _qispi_start + Vector3.BACK * qispi_walk_distance, walk_seconds
		)


## Lo que avanza hacia la cámara: el bote o Lucía.
func _traveller() -> Node3D:
	if _boat.visible:
		return _boat
	return _lucia


## Deja un modelo solo en la capa del reflejo: la cámara no lo ve, el agua sí.
func _hide_from_camera(model: Node3D) -> void:
	for mesh: VisualInstance3D in model.find_children("*", "VisualInstance3D", true, false):
		mesh.layers = 0
		mesh.set_layer_mask_value(REFLECTION_LAYER, true)


## Hace sonar una animación del modelo en bucle, con la velocidad indicada.
func _animate(model: Node3D, animation_name: StringName, speed_scale: float) -> void:
	var player := model.find_child("AnimationPlayer") as AnimationPlayer
	player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	player.play(animation_name, BLEND_SECONDS)
	player.speed_scale = speed_scale


## Lucía dice su línea, con subtítulo, si el tránsito tiene una.
func _say() -> void:
	if data == null or data.line_audio == null:
		return
	_voice.stream = data.line_audio
	_voice.play()
	_subtitle.text = SUBTITLE_FORMAT % data.line_text
	get_tree().create_timer(data.line_audio.get_length()).timeout.connect(
		_subtitle.set_text.bind("")
	)


## Deja la pantalla en negro, avisa la llegada y abre el nivel siguiente.
func _finish() -> void:
	_step_timer.stop()
	_curtain.modulate.a = OPAQUE
	is_playing = false
	finished.emit()
	if not next_level_path.is_empty():
		_has_arrival = true
		get_tree().change_scene_to_file.call_deferred(next_level_path)


## Desvanece la cortina hacia la transparencia indicada.
func _fade(control: Control, alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(control, "modulate:a", alpha, fade_seconds)
	await tween.finished


## Espera unos segundos; devuelve falso si la jugadora saltó el tránsito.
func _wait(seconds: float) -> bool:
	if _skip_requested:
		return false
	_wait_timer.start(seconds)
	await _wait_timer.timeout
	return not _skip_requested
