class_name Hud
extends CanvasLayer
## HUD mínimo: la barra de aliento aparece al gastarlo y se desvanece al llenarse.

const FULL_RATIO := 0.995
const SHOWN_ALPHA := 1.0
const HIDDEN_ALPHA := 0.0
const FADE_SPEED := 3.0

var _target_alpha := HIDDEN_ALPHA

@onready var _stamina_bar: ProgressBar = %StaminaBar


## Escucha el aliento y arranca con la barra oculta.
func _ready() -> void:
	_stamina_bar.modulate.a = HIDDEN_ALPHA
	EventBus.stamina_changed.connect(_on_stamina_changed)


## Acerca la transparencia de la barra a la que le toca.
func _process(delta: float) -> void:
	_stamina_bar.modulate.a = move_toward(
		_stamina_bar.modulate.a, _target_alpha, FADE_SPEED * delta
	)


## Actualiza la barra y la muestra solo si falta aliento.
func _on_stamina_changed(current: float, maximum: float) -> void:
	_stamina_bar.max_value = maximum
	_stamina_bar.value = current
	_target_alpha = HIDDEN_ALPHA
	if current / maximum < FULL_RATIO:
		_target_alpha = SHOWN_ALPHA
