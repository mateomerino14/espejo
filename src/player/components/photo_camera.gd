class_name PhotoCamera
extends Node3D
## Cámara de Lucía: el visor revela lo que vive en los reflejos, el flash gasta batería y cada
## foto queda en el rollo.

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
var _cooldown_left := 0.0

@onready var _flash: SpotLight3D = $FlashLight
@onready var _shutter: AudioStreamPlayer3D = $Shutter
@onready var _focus: AudioStreamPlayer3D = $Focus


## Arranca con la batería llena, el rollo nuevo y el reflejo oculto.
func _ready() -> void:
	battery = max_battery
	film_remaining = film_capacity
	_default_fov = camera.fov
	_flash.light_energy = 0.0
	camera.set_cull_mask_value(reveal_layer, false)
	battery_changed.emit(battery, max_battery)
	film_changed.emit(film_remaining, film_capacity)


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
		_focus.play()
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
func shoot() -> void:
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
	EventBus.noise_emitted.emit(global_position, shutter_loudness)
	_develop(Photo.new(has_flash, _find_captions()))


## Devuelve lo que la foto alcanza a mostrar de los sujetos que hay en cuadro.
func _find_captions() -> PackedStringArray:
	var captions := PackedStringArray()
	for subject: PhotoSubject in get_tree().get_nodes_in_group(PhotoSubject.GROUP):
		if subject.is_visible_from(camera):
			captions.append(subject.caption)
	return captions


## Espera a que el cuadro con el destello se dibuje, lo guarda y apaga el flash.
func _develop(photo: Photo) -> void:
	for frame in DEVELOP_FRAMES:
		await get_tree().process_frame
	if DisplayServer.get_name() != HEADLESS_DISPLAY:
		photo.develop(camera.get_viewport().get_texture().get_image())
	create_tween().tween_property(_flash, "light_energy", 0.0, FLASH_FADE_SECONDS)
	photo_taken.emit(photo)
