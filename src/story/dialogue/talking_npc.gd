class_name TalkingNpc
extends Node3D
## Alguien con quien Lucía puede hablar: dice sus líneas en orden, con voz y subtítulos, y gesticula
## mientras habla. Se puede volver a escuchar cuando termina.

## Empezó a hablar; [param seconds] es lo que dura toda la conversación.
signal conversation_started(seconds: float)
signal conversation_finished

## Silencio entre una línea y la siguiente.
const LINE_PAUSE := 0.5
const BLEND_SECONDS := 0.4

@export var prompt := "Hablar"
@export var lines: Array[DialogueLine] = []
@export var animation_player: AnimationPlayer
@export var idle_animation := &"sit"
@export var talk_animation := &"talk"

var is_talking := false
var has_talked := false
var _line_index := 0

@onready var _interactable: Interactable = $Interactable
@onready var _voice: AudioStreamPlayer3D = $Voice
@onready var _line_timer: Timer = $LineTimer


## Deja las animaciones en bucle, espera quieto y escucha a Lucía.
func _ready() -> void:
	_interactable.prompt = prompt
	_interactable.interacted.connect(_on_interacted)
	_line_timer.timeout.connect(_on_line_timeout)
	if animation_player:
		for animation_name: StringName in [idle_animation, talk_animation]:
			animation_player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
		animation_player.play(idle_animation)


## Lo que dura la conversación entera, con las pausas.
func total_seconds() -> float:
	var seconds := 0.0
	for line in lines:
		seconds += line.get_seconds() + LINE_PAUSE
	return seconds


## Empieza a decir sus líneas desde la primera.
func talk() -> void:
	if is_talking or lines.is_empty():
		return
	is_talking = true
	_interactable.enabled = false
	_line_index = 0
	if animation_player:
		animation_player.play(talk_animation, BLEND_SECONDS)
	conversation_started.emit(total_seconds())
	_say_current_line()


## Muestra el subtítulo y reproduce la voz de la línea que toca.
func _say_current_line() -> void:
	var line := lines[_line_index]
	EventBus.subtitle_requested.emit(line.text, line.get_seconds())
	_voice.stream = line.voice
	if line.voice:
		_voice.play()
	_line_timer.start(line.get_seconds() + LINE_PAUSE)


## Pasa a la siguiente línea, o termina.
func _on_line_timeout() -> void:
	_line_index += 1
	if _line_index < lines.size():
		_say_current_line()
		return
	is_talking = false
	has_talked = true
	_interactable.enabled = true
	if animation_player:
		animation_player.play(idle_animation, BLEND_SECONDS)
	conversation_finished.emit()


## Lucía le habla.
func _on_interacted(_player: Player) -> void:
	talk()
