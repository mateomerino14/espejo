class_name HintDirector
extends Node
## Pide los consejos que dependen de lo que pasa en el juego: los primeros pasos, la primera cosa
## que se puede usar, la cámara, la primera foto, la mochila, el flash sin pila y cuando el
## Q'ispi rastrea o caza.

const START_HINTS: Array[String] = ["caminar", "camara", "correr", "mapa"]


## Pide los consejos del comienzo y escucha al juego.
func _ready() -> void:
	EventBus.interaction_prompt_changed.connect(_on_interaction_prompt_changed)
	EventBus.camera_raised.connect(_on_camera_raised)
	EventBus.photo_taken.connect(_on_photo_taken.unbind(1))
	EventBus.camera_battery_changed.connect(_on_battery_changed)
	EventBus.inventory_changed.connect(_on_inventory_changed)
	_start.call_deferred()


## Ya con todo el nivel cargado: los consejos del comienzo y los Q'ispi que rastrean o cazan.
func _start() -> void:
	for id in START_HINTS:
		EventBus.hint_requested.emit(id)
	for qispi: Qispi in get_tree().get_nodes_in_group(Qispi.GROUP):
		qispi.state_changed.connect(_on_qispi_state_changed)


## Lo primero que se puede usar enseña la tecla de usar.
func _on_interaction_prompt_changed(prompt: String) -> void:
	if not prompt.is_empty():
		EventBus.hint_requested.emit("usar")


## Con el visor arriba, cómo tomar la foto.
func _on_camera_raised(is_raised: bool) -> void:
	if is_raised:
		EventBus.hint_requested.emit("foto")


## Después de la primera foto, dónde se guardan.
func _on_photo_taken() -> void:
	EventBus.hint_requested.emit("album")


## Al guardar algo en la mochila, cómo verla.
func _on_inventory_changed(_type: ItemCatalog.Type, count: int) -> void:
	if count > 0:
		EventBus.hint_requested.emit("inventario")


## Sin pila para el flash, que hay que buscar pilas.
func _on_battery_changed(current: float, _maximum: float) -> void:
	if is_zero_approx(current):
		EventBus.hint_requested.emit("pilas")


## Cuando el Q'ispi sigue a Lucía, cómo no hacer ruido; cuando la caza, cómo escapar.
func _on_qispi_state_changed(state: Qispi.State) -> void:
	if state == Qispi.State.TRACK:
		EventBus.hint_requested.emit("rastro")
		EventBus.hint_requested.emit("asomarse")
	elif state == Qispi.State.HUNT:
		EventBus.hint_requested.emit("caza")
