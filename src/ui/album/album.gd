class_name Album
extends CanvasLayer
## Álbum de fotos: guarda lo que llega del rollo y se hojea con pausa, una foto a la vez. Las fotos
## viven en GameState, así que siguen de un nivel a otro.

const EMPTY_TEXT := "Todavía no tomaste ninguna foto"
const NO_CAPTION_TEXT := "No se ve nada fuera de lo común"
const COUNTER_FORMAT := "%d / %d"
const CAPTION_SEPARATOR := "\n"

var current := 0

@onready var _image: TextureRect = %Image
@onready var _caption: Label = %Caption
@onready var _counter: Label = %Counter


## Escucha las fotos nuevas y arranca cerrado.
func _ready() -> void:
	visible = false
	EventBus.photo_taken.connect(_on_photo_taken)


## Abre y cierra el álbum; abierto, pasa las fotos con las flechas.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("album"):
		set_open(not visible)
	elif not visible:
		return
	elif event.is_action_pressed("ui_cancel"):
		set_open(false)
	elif event.is_action_pressed("ui_right"):
		show_photo(current + 1)
	elif event.is_action_pressed("ui_left"):
		show_photo(current - 1)
	else:
		return
	get_viewport().set_input_as_handled()


## Abre el álbum en la última foto y pausa el juego, o lo cierra y vuelve a jugar.
func set_open(is_open: bool) -> void:
	visible = is_open
	get_tree().paused = is_open
	if is_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		show_photo(GameState.photos.size() - 1)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Muestra la foto indicada, sin salirse del rollo.
func show_photo(index: int) -> void:
	var photos := GameState.photos
	if photos.is_empty():
		_image.texture = null
		_caption.text = EMPTY_TEXT
		_counter.text = ""
		return
	current = clampi(index, 0, photos.size() - 1)
	var photo := photos[current]
	_image.texture = photo.texture
	_caption.text = NO_CAPTION_TEXT
	if not photo.captions.is_empty():
		_caption.text = CAPTION_SEPARATOR.join(photo.captions)
	_counter.text = COUNTER_FORMAT % [current + 1, photos.size()]


## Guarda la foto nueva al final del álbum, que sigue en los niveles siguientes.
func _on_photo_taken(photo: Photo) -> void:
	GameState.photos.append(photo)
