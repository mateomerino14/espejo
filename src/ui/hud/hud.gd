class_name Hud
extends CanvasLayer
## HUD mínimo: barra de aliento que aparece al gastarlo, lo que se puede usar al frente, avisos
## breves que se desvanecen solos y subtítulos cuando alguien habla; el nombre del nivel abajo a la
## izquierda y el objetivo arriba a la izquierda, anunciado con un sonido.

const FULL_RATIO := 0.995
const SHOWN_ALPHA := 1.0
const HIDDEN_ALPHA := 0.0
const FADE_SPEED := 3.0
const NOTICE_SECONDS := 3.0
const TITLE_SECONDS := 4.5
const OBJECTIVE_SECONDS := 7.0
const PROMPT_FORMAT := "[%s]  %s"

var _target_alpha := {}
## Lo que se puede hacer con lo que está al frente; se reescribe si cambia el aparato.
var _prompt := ""

@onready var _stamina_bar: ProgressBar = %StaminaBar
@onready var _prompt_label: Label = %PromptLabel
@onready var _notice_label: Label = %NoticeLabel
@onready var _notice_timer: Timer = %NoticeTimer
@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _subtitle_timer: Timer = %SubtitleTimer
@onready var _title_label: Label = %TitleLabel
@onready var _title_timer: Timer = %TitleTimer
@onready var _objective_box: Control = %ObjectiveBox
@onready var _objective_label: Label = %ObjectiveLabel
@onready var _objective_timer: Timer = %ObjectiveTimer
@onready var _objective_sound: AudioStreamPlayer = %ObjectiveSound


## Escucha al bus y arranca con todo oculto.
func _ready() -> void:
	for control: Control in [
		_stamina_bar, _notice_label, _subtitle_label, _title_label, _objective_box
	]:
		control.modulate.a = HIDDEN_ALPHA
		_target_alpha[control] = HIDDEN_ALPHA
	_prompt_label.text = ""
	_notice_timer.timeout.connect(_on_notice_timeout)
	_subtitle_timer.timeout.connect(_on_subtitle_timeout)
	_title_timer.timeout.connect(_hide.bind(_title_label))
	_objective_timer.timeout.connect(_hide.bind(_objective_box))
	EventBus.level_title_requested.connect(_on_level_title_requested)
	EventBus.objective_changed.connect(_on_objective_changed)
	EventBus.stamina_changed.connect(_on_stamina_changed)
	EventBus.interaction_prompt_changed.connect(_on_interaction_prompt_changed)
	EventBus.notice_requested.connect(_on_notice_requested)
	EventBus.subtitle_requested.connect(_on_subtitle_requested)
	InputDevice.changed.connect(_write_prompt)


## Acerca la transparencia de cada elemento a la que le toca.
func _process(delta: float) -> void:
	for control: Control in _target_alpha:
		control.modulate.a = move_toward(
			control.modulate.a, _target_alpha[control], FADE_SPEED * delta
		)


## Actualiza la barra y la muestra solo si falta aliento.
func _on_stamina_changed(current: float, maximum: float) -> void:
	_stamina_bar.max_value = maximum
	_stamina_bar.value = current
	_target_alpha[_stamina_bar] = HIDDEN_ALPHA
	if current / maximum < FULL_RATIO:
		_target_alpha[_stamina_bar] = SHOWN_ALPHA


## Muestra qué se puede hacer con lo que está al frente.
func _on_interaction_prompt_changed(prompt: String) -> void:
	_prompt = prompt
	_write_prompt()


## Escribe la acción al frente con la tecla o el botón de usar del aparato actual.
func _write_prompt() -> void:
	_prompt_label.text = ""
	if not _prompt.is_empty():
		_prompt_label.text = PROMPT_FORMAT % [InputDevice.label(&"interact"), _prompt]


## Muestra un aviso breve que se desvanece solo.
func _on_notice_requested(text: String) -> void:
	_notice_label.text = text
	_target_alpha[_notice_label] = SHOWN_ALPHA
	_notice_timer.start(NOTICE_SECONDS)


## Desvanece el aviso cuando se acaba su tiempo.
func _on_notice_timeout() -> void:
	_target_alpha[_notice_label] = HIDDEN_ALPHA


## Muestra lo que dice alguien mientras dura la línea.
func _on_subtitle_requested(text: String, seconds: float) -> void:
	_subtitle_label.text = text
	_target_alpha[_subtitle_label] = SHOWN_ALPHA
	_subtitle_timer.start(seconds)


## Desvanece el subtítulo cuando termina la línea.
func _on_subtitle_timeout() -> void:
	_target_alpha[_subtitle_label] = HIDDEN_ALPHA


## Muestra el nombre del nivel abajo a la izquierda.
func _on_level_title_requested(title: String) -> void:
	_title_label.text = title
	_target_alpha[_title_label] = SHOWN_ALPHA
	_title_timer.start(TITLE_SECONDS)


## Anuncia el nuevo objetivo arriba a la izquierda, con su sonido.
func _on_objective_changed(text: String) -> void:
	if text.is_empty():
		return
	_objective_label.text = text
	_objective_sound.play()
	_target_alpha[_objective_box] = SHOWN_ALPHA
	_objective_timer.start(OBJECTIVE_SECONDS)


## Desvanece un elemento cuando se acaba su tiempo.
func _hide(control: Control) -> void:
	_target_alpha[control] = HIDDEN_ALPHA
