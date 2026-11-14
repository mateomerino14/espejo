class_name InventoryScreen
extends CanvasLayer
## Inventario: detiene el juego y muestra la mochila de Lucía con el dibujo de cada cosa, qué es y
## para qué sirve; también la cámara, las herramientas, el objetivo y las fotos de pistas.

const SLOT_SCENE := preload("res://src/ui/inventory_screen/inventory_slot.tscn")
const OBJECTIVE_FORMAT := "Objetivo: %s"
const NO_OBJECTIVE := "Objetivo: sigue adelante"
const CAMERA_FORMAT := "Cámara: quedan %d fotos en el rollo  ·  pila del flash al %d %%"
const TOOLS_FORMAT := "Llevas %s"
const CLUES_FORMAT := "Fotos de pistas: %d"
const LIST_SEPARATOR := ", "
const PERCENT := 100.0

var is_open := false

var _slots: Array[InventorySlot] = []
var _selected := 0

@onready var _slot_row: HBoxContainer = %SlotRow
@onready var _objective_label: Label = %ObjectiveLabel
@onready var _camera_label: Label = %CameraLabel
@onready var _clues_label: Label = %CluesLabel
@onready var _tools_label: Label = %ToolsLabel
@onready var _detail_name: Label = %DetailName
@onready var _detail_description: Label = %DetailDescription
@onready var _detail_use: Label = %DetailUse


## Arma una casilla por cosa y arranca cerrado.
func _ready() -> void:
	for type: ItemCatalog.Type in ItemCatalog.DISPLAY_ORDER:
		var slot: InventorySlot = SLOT_SCENE.instantiate()
		_slot_row.add_child(slot)
		slot.hovered.connect(_select.bind(_slots.size()))
		_slots.append(slot)
	visible = false


## Su tecla abre o cierra; abierto, Escape cierra y las flechas o A y D eligen.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if is_open:
			close()
		elif _can_open():
			open()
		else:
			return
		get_viewport().set_input_as_handled()
		return
	if not is_open:
		return
	if event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_select(wrapi(_selected - 1, 0, _slots.size()))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_select(wrapi(_selected + 1, 0, _slots.size()))
		get_viewport().set_input_as_handled()


## Detiene el juego y muestra la mochila tal como está.
func open() -> void:
	is_open = true
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh()


## Cierra y sigue el juego.
func close() -> void:
	is_open = false
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Solo se abre jugando: no en pausa, con el álbum o con una nota abierta.
func _can_open() -> bool:
	return not get_tree().paused and get_tree().get_first_node_in_group(Player.GROUP) != null


## Pone lo que lleva, la cámara, las herramientas, el objetivo y las pistas; elige la primera
## cosa que tenga.
func _refresh() -> void:
	var first_owned := -1
	for index in _slots.size():
		var type := ItemCatalog.DISPLAY_ORDER[index]
		_slots[index].show_item(type, GameState.count_item(type))
		if first_owned < 0 and GameState.count_item(type) > 0:
			first_owned = index
	_objective_label.text = NO_OBJECTIVE
	if not GameState.objective.is_empty():
		_objective_label.text = OBJECTIVE_FORMAT % GameState.objective
	_camera_label.text = CAMERA_FORMAT % [_film(), roundi(_battery_ratio() * PERCENT)]
	_clues_label.text = CLUES_FORMAT % GameState.clue_photos.size()
	_tools_label.visible = not GameState.tools.is_empty()
	_tools_label.text = TOOLS_FORMAT % LIST_SEPARATOR.join(GameState.tools)
	_select(maxi(first_owned, 0))


## Marca una cosa y cuenta qué es y para qué sirve.
func _select(index: int) -> void:
	_selected = index
	for slot_index in _slots.size():
		_slots[slot_index].set_selected(slot_index == index)
	var type := ItemCatalog.DISPLAY_ORDER[index]
	var item_name := ItemCatalog.display_name(type)
	_detail_name.text = item_name.left(1).to_upper() + item_name.substr(1)
	_detail_description.text = ItemCatalog.description(type)
	_detail_use.text = ItemCatalog.use(type)


## Fotos que quedan en el rollo de la cámara.
func _film() -> int:
	var camera := _camera()
	if camera:
		return camera.film_remaining
	return 0


## Carga del flash, de 0 a 1.
func _battery_ratio() -> float:
	var camera := _camera()
	if camera:
		return camera.battery / camera.max_battery
	return 0.0


## La cámara de Lucía, si está en el nivel.
func _camera() -> PhotoCamera:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	if player:
		return player.photo_camera()
	return null
