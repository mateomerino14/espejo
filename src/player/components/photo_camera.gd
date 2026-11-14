class_name PhotoCamera
extends Node3D
## Cámara de Lucía: el visor revela lo que vive en los reflejos, el flash gasta batería y cada
## foto queda en el rollo. Cuando se acaba el rollo o la pila, carga otro de la mochila; cómo
## quedó la cámara sigue en el nivel siguiente.

signal raised_changed(is_raised: bool)
signal battery_changed(current: float, maximum: float)
signal film_changed(remaining: int, capacity: int)
signal photo_taken(photo: Photo)
signal flash_fired(origin: Vector3, direction: Vector3)

## Lo que tarda en apagarse el destello.
const FLASH_FADE_SECONDS := 0.25
## Cuadros que se esperan para que la imagen ya tenga el destello dibujado.
const DEVELOP_FRAMES := 2
## Sin pantalla (pruebas en CI) no hay imagen que capturar.
const HEADLESS_DISPLAY := "headless"
## Después del obturador, Lucía pasa el rollo con la palanca.
const ADVANCE_DELAY := 0.45
## Y el flash empieza a cargarse para la próxima foto.
const CHARGE_DELAY := 0.8
## Lo que tarda en cargar un rollo o cambiar las pilas de la mochila.
const RELOAD_DELAY := 1.2
const FILM_NOTICE := "Cargaste un rollo nuevo"
const BATTERY_NOTICE := "Cambiaste las pilas del flash"

## Cámara del jugador, cuya vista se acerca y revela la capa del reflejo.
@export var camera: Camera3D

@export_group("Visor")
## Capa de render que solo se ve por el visor.
@export_range(1, 20) var reveal_layer := 11
@export var zoom_fov := 52.0
@export var zoom_speed := 6.0

@export_group("Flash")
@export var max_battery := 100.0
@export var flash_cost := 12.5
@export var flash_energy := 4.0
## Segundos entre una foto y la siguiente.
@export var cooldown := 1.2

@export_group("Rollo")
@export var film_capacity := 24
## Volumen del obturador para quien escuche (0 a 1).
@export var shutter_loudness := 0.3

var is_raised := false
var battery := 0.0
var film_remaining := 0

var _default_fov := 0.0
var _is_loading_film := false
var _is_loading_batteries := false
var _cooldown_left := 0.0

@onready var _flash: SpotLight3D = $FlashLight
@onready var _shutter: AudioStreamPlayer3D = $Shutter
@onready var _raise_sound: AudioStreamPlayer3D = $Raise
@onready var _lower_sound: AudioStreamPlayer3D = $Lower
@onready var _advance: AudioStreamPlayer3D = $Advance
@onready var _flash_charge: AudioStreamPlayer3D = $FlashCharge
@onready var _dry_fire: AudioStreamPlayer3D = $DryFire


## Arranca como quedó en el nivel anterior, o con la pila llena y el rollo nuevo, y el reflejo
## oculto.
func _ready() -> void:
	battery = max_battery
	if GameState.camera_battery >= 0.0:
		battery = GameState.camera_battery
	film_remaining = film_capacity
	if GameState.camera_film >= 0:
		film_remaining = GameState.camera_film
	_default_fov = camera.fov
	_flash.light_energy = 0.0
	camera.set_cull_mask_value(reveal_layer, false)
	battery_changed.emit(battery, max_battery)
	film_changed.emit(film_remaining, film_capacity)
	battery_changed.connect(_remember.unbind(2))
	film_changed.connect(_remember.unbind(2))
	EventBus.inventory_changed.connect(_reload_from_bag.unbind(2))


## Acerca la vista mientras mira por el visor y descuenta la espera entre fotos.
func _process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	var target_fov := _default_fov
	if is_raised:
		target_fov = zoom_fov
	camera.fov = lerpf(camera.fov, target_fov, zoom_speed * delta)


## Levanta o baja la cámara; levantada, la vista muestra la capa del reflejo.
func set_raised(value: bool) -> void:
	if value == is_raised:
		return
	is_raised = value
	camera.set_cull_mask_value(reveal_layer, value)
	if value:
		_raise_sound.play()
	else:
		_lower_sound.play()
	raised_changed.emit(value)


## Baja la cámara de golpe, como al reaparecer.
func reset() -> void:
	is_raised = false
	camera.set_cull_mask_value(reveal_layer, false)
	raised_changed.emit(false)


## Dice si puede disparar: mirando por el visor, con rollo y sin esperar al flash.
func can_shoot() -> bool:
	return is_raised and film_remaining > 0 and _cooldown_left <= 0.0


## Toma una foto, con flash si queda batería; la imagen se revela al dibujarse el cuadro.
## Sin rollo, el obturador hace un clic seco y no dispara.
func shoot() -> void:
	if is_raised and film_remaining == 0 and _cooldown_left <= 0.0:
		_cooldown_left = cooldown
		_dry_fire.play()
		return
	if not can_shoot():
		return
	_cooldown_left = cooldown
	film_remaining -= 1
	film_changed.emit(film_remaining, film_capacity)
	var has_flash := battery >= flash_cost
	if has_flash:
		battery -= flash_cost
		battery_changed.emit(battery, max_battery)
		_flash.light_energy = flash_energy
		flash_fired.emit(global_position, -global_basis.z)
	_shutter.play()
	_play_after(_advance, ADVANCE_DELAY)
	if battery >= flash_cost:
		_play_after(_flash_charge, CHARGE_DELAY)
	EventBus.noise_emitted.emit(global_position, shutter_loudness)
	_develop(Photo.new(has_flash, _find_captions()))
	_reload_from_bag()


## Hace sonar [param sound] dentro de [param delay] segundos.
func _play_after(sound: AudioStreamPlayer3D, delay: float) -> void:
	create_tween().tween_callback(sound.play).set_delay(delay)


## Devuelve lo que la foto alcanza a mostrar de los sujetos en cuadro y guarda las pistas.
func _find_captions() -> PackedStringArray:
	var captions := PackedStringArray()
	for subject: PhotoSubject in get_tree().get_nodes_in_group(PhotoSubject.GROUP):
		if subject.is_visible_from(camera):
			captions.append(subject.caption)
			if not subject.clue_id.is_empty():
				GameState.add_clue_photo(subject.clue_id)
	return captions


## Espera a que el cuadro con el destello se dibuje, lo guarda y apaga el flash.
func _develop(photo: Photo) -> void:
	for frame in DEVELOP_FRAMES:
		await get_tree().process_frame
	if DisplayServer.get_name() != HEADLESS_DISPLAY:
		photo.develop(camera.get_viewport().get_texture().get_image())
	create_tween().tween_property(_flash, "light_energy", 0.0, FLASH_FADE_SECONDS)
	photo_taken.emit(photo)


## Si se acabó el rollo o la pila y hay repuesto en la mochila, lo carga al rato.
func _reload_from_bag() -> void:
	if film_remaining == 0 and not _is_loading_film:
		if GameState.use_item(ItemCatalog.Type.FILM):
			_is_loading_film = true
			get_tree().create_timer(RELOAD_DELAY).timeout.connect(_load_film)
	if battery < flash_cost and not _is_loading_batteries:
		if GameState.use_item(ItemCatalog.Type.BATTERY):
			_is_loading_batteries = true
			get_tree().create_timer(RELOAD_DELAY).timeout.connect(_load_batteries)


## Pone el rollo nuevo, con el ruido de la palanca.
func _load_film() -> void:
	_is_loading_film = false
	film_remaining = film_capacity
	film_changed.emit(film_remaining, film_capacity)
	_advance.play()
	EventBus.notice_requested.emit(FILM_NOTICE)


## Pone las pilas nuevas, con el zumbido del flash.
func _load_batteries() -> void:
	_is_loading_batteries = false
	battery = max_battery
	battery_changed.emit(battery, max_battery)
	_flash_charge.play()
	EventBus.notice_requested.emit(BATTERY_NOTICE)


## Recuerda cómo está la cámara, para el nivel siguiente.
func _remember() -> void:
	GameState.keep_camera(film_remaining, battery)
