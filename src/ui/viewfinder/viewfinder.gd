class_name Viewfinder
extends CanvasLayer
## Pantalla del visor: aparece al levantar la cámara con su marco, fotos restantes y batería, y
## destella al disparar con flash.

const SHOWN_ALPHA := 1.0
const HIDDEN_ALPHA := 0.0
const FADE_SECONDS := 0.15
const FLASH_ALPHA := 0.85
const FLASH_FADE_SECONDS := 0.35
const FILM_FORMAT := "%d / %d"
const BATTERY_FORMAT := "%d %%"
const PERCENT := 100.0

var _fade: Tween

@onready var _screen: Control = $Screen
@onready var _film_label: Label = %FilmLabel
@onready var _battery_label: Label = %BatteryLabel
@onready var _flash: ColorRect = $Flash


## Escucha a la cámara por el bus y arranca oculto.
func _ready() -> void:
	_screen.modulate.a = HIDDEN_ALPHA
	_screen.visible = false
	_flash.modulate.a = HIDDEN_ALPHA
	EventBus.camera_raised.connect(_on_camera_raised)
	EventBus.film_changed.connect(_on_film_changed)
	EventBus.camera_battery_changed.connect(_on_battery_changed)
	EventBus.photo_taken.connect(_on_photo_taken)


## Muestra u oculta el visor con un fundido corto.
func _on_camera_raised(is_raised: bool) -> void:
	if _fade:
		_fade.kill()
	var target := HIDDEN_ALPHA
	if is_raised:
		target = SHOWN_ALPHA
		_screen.visible = true
	_fade = create_tween()
	_fade.tween_property(_screen, "modulate:a", target, FADE_SECONDS)
	if not is_raised:
		_fade.tween_callback(_screen.hide)


## Muestra cuántas fotos quedan en el rollo.
func _on_film_changed(remaining: int, capacity: int) -> void:
	_film_label.text = FILM_FORMAT % [remaining, capacity]


## Muestra la batería del flash en porcentaje.
func _on_battery_changed(current: float, maximum: float) -> void:
	_battery_label.text = BATTERY_FORMAT % roundi(current / maximum * PERCENT)


## Blanquea la pantalla un instante si la foto llevó flash.
func _on_photo_taken(photo: Photo) -> void:
	if not photo.has_flash:
		return
	_flash.modulate.a = FLASH_ALPHA
	create_tween().tween_property(_flash, "modulate:a", HIDDEN_ALPHA, FLASH_FADE_SECONDS)
