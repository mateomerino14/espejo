class_name CinematicDirector
extends Node
## Pasa los planos de una cinemática en orden, con sus voces y subtítulos, y, al terminar o si la
## jugadora la salta, funde a negro, muestra el texto final y cambia de escena.

signal cue_reached(cue: StringName)

const OPAQUE := 1.0
const CLEAR := 0.0

@export var camera: Camera3D
## Nodo cuyos hijos son los planos, en el orden en que se ven.
@export var shots_root: Node
@export_file("*.tscn") var next_scene := ""
@export var fade_seconds := 1.5
## Texto sobre negro antes de la escena siguiente.
@export_multiline var closing_text := ""
@export var closing_seconds := 4.0

var _shots: Array[CinematicShot] = []
var _index := -1
var _time := 0.0
var _is_closing := false

@onready var _curtain: ColorRect = %Curtain
@onready var _subtitle: Label = %Subtitle
@onready var _closing: Label = %Closing
@onready var _voice: AudioStreamPlayer = $Voice


## Junta los planos, oculta el ratón y abre desde negro.
func _ready() -> void:
	for child in shots_root.get_children():
		var shot := child as CinematicShot
		if shot:
			_shots.append(shot)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_closing.modulate.a = CLEAR
	_curtain.modulate.a = OPAQUE
	create_tween().tween_property(_curtain, "modulate:a", CLEAR, fade_seconds)
	_next_shot.call_deferred()


## Mueve la cámara dentro del plano y pasa al siguiente cuando termina.
func _process(delta: float) -> void:
	if _is_closing or _index < 0 or _index >= _shots.size():
		return
	_time += delta
	var shot := _shots[_index]
	camera.global_transform = shot.camera_transform(minf(_time / shot.duration, 1.0))
	if _time >= shot.duration:
		_next_shot()


## Usar o pausa saltan la cinemática.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


## Funde a negro, muestra el texto final y pasa a la escena siguiente.
func close() -> void:
	if _is_closing:
		return
	_is_closing = true
	_subtitle.text = ""
	_voice.stop()
	var fade := create_tween()
	fade.tween_property(_curtain, "modulate:a", OPAQUE, fade_seconds)
	if not closing_text.is_empty():
		_closing.text = closing_text
		fade.tween_property(_closing, "modulate:a", OPAQUE, fade_seconds)
		fade.tween_interval(closing_seconds)
		fade.tween_property(_closing, "modulate:a", CLEAR, fade_seconds)
	fade.tween_callback(_change_scene)


## Empieza el plano siguiente, o cierra si no quedan.
func _next_shot() -> void:
	_index += 1
	_time = 0.0
	if _index >= _shots.size():
		close()
		return
	var shot := _shots[_index]
	camera.fov = shot.fov
	camera.global_transform = shot.camera_transform(0.0)
	_subtitle.text = shot.subtitle
	if shot.voice:
		_voice.stream = shot.voice
		_voice.play()
	if not shot.cue.is_empty():
		cue_reached.emit(shot.cue)


## Carga la escena que sigue.
func _change_scene() -> void:
	get_tree().change_scene_to_file(next_scene)
