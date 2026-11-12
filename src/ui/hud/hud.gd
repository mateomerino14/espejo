class_name Hud
extends CanvasLayer
## HUD mínimo: barra de aliento que aparece al gastarlo, lo que se puede usar al frente, avisos
## breves que se desvanecen solos y subtítulos cuando alguien habla.

const FULL_RATIO := 0.995
const SHOWN_ALPHA := 1.0
const HIDDEN_ALPHA := 0.0
const FADE_SPEED := 3.0
const NOTICE_SECONDS := 3.0
const PROMPT_FORMAT := "[E]  %s"

var _target_alpha := {}

@onready var _stamina_bar: ProgressBar = %StaminaBar
@onready var _prompt_label: Label = %PromptLabel
@onready var _notice_label: Label = %NoticeLabel
@onready var _notice_timer: Timer = %NoticeTimer
@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _subtitle_timer: Timer = %SubtitleTimer


## Escucha al bus y arranca con todo oculto.
func _ready() -> void:
	for control: Control in [_stamina_bar, _notice_label, _subtitle_label]:
		control.modulate.a = HIDDEN_ALPHA
		_target_alpha[control] = HIDDEN_ALPHA
	_prompt_label.text = ""
	_notice_timer.timeout.connect(_on_notice_timeout)
	_subtitle_timer.timeout.connect(_on_subtitle_timeout)
	EventBus.stamina_changed.connect(_on_stamina_changed)
	EventBus.interaction_prompt_changed.connect(_on_interaction_prompt_changed)
	EventBus.notice_requested.connect(_on_notice_requested)
	EventBus.subtitle_requested.connect(_on_subtitle_requested)


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
	_prompt_label.text = ""
	if not prompt.is_empty():
		_prompt_label.text = PROMPT_FORMAT % prompt


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
