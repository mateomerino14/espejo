extends TestCase
## Pruebas de los consejos de controles: se muestran uno a la vez y una sola vez, se piden al
## acercarse a lo que explican, se pueden apagar y la tabla de controles nombra cada acción.

const HINT_BOX_SCENE := preload("res://src/ui/hints/hint_box.tscn")
const CONTROLS_SCENE := preload("res://src/ui/controls_panel/controls_panel.tscn")
const OPTIONS_SCENE := preload("res://src/ui/options_panel/options_panel.tscn")
const HINTED_SCENES: Array[String] = [
	"res://src/world/apacheta/apacheta.tscn",
	"res://src/world/hiding_spot/wardrobe.tscn",
	"res://src/world/hiding_spot/locker.tscn",
	"res://src/world/hiding_spot/crevice.tscn",
	"res://src/world/mirror/mirror.tscn",
]

var _box: HintBox


## Consejos activados y sin ver.
func before_each() -> void:
	Settings.hints_enabled = true
	Settings.seen_hints.clear()
	_box = HINT_BOX_SCENE.instantiate()
	add_to_tree(_box)


## Libera el cuadro y deja los consejos como al empezar.
func after_each() -> void:
	_box.free()
	Settings.hints_enabled = true
	Settings.seen_hints.clear()


## Un consejo pedido se muestra con su tecla y queda visto: no se repite.
func test_shows_each_hint_once() -> void:
	EventBus.hint_requested.emit("album")
	assert_true(_box.current == "album", "Debe mostrar el consejo del álbum")
	assert_true(_box.get_node("%HintLabel").text.contains("abre el álbum"), "Con su texto")
	assert_true("album" in Settings.seen_hints, "Queda visto")
	_box.current = ""
	EventBus.hint_requested.emit("album")
	assert_true(_box.current.is_empty(), "Uno visto no se repite")


## Uno a la vez: el segundo espera a que acabe el primero y su pausa; el urgente pasa delante.
func test_queues_hints() -> void:
	EventBus.hint_requested.emit("album")
	EventBus.hint_requested.emit("espejo")
	EventBus.hint_requested.emit("caza")
	assert_true(_box.current == "album", "Sigue el primero")
	_box._on_timeout()
	_box._timer.stop()
	_box._on_timeout()
	assert_true(_box.current == "caza", "El urgente pasa delante")


## Las apachetas, los escondites y los espejos piden un consejo que existe.
func test_props_ask_for_known_hints() -> void:
	for path: String in HINTED_SCENES:
		var prop: Node = load(path).instantiate()
		var trigger: HintTrigger = prop.get_node("HintTrigger")
		assert_true(HintCatalog.TEXTS.has(trigger.hint_id), "%s pide un consejo que existe" % path)
		prop.free()


## Apagados no se muestran; al encenderlos de nuevo vuelven desde el principio.
func test_can_be_turned_off() -> void:
	Settings.hints_enabled = false
	EventBus.hint_requested.emit("album")
	assert_true(_box.current.is_empty(), "Apagados no salen")
	Settings.seen_hints.append("espejo")
	var options: OptionsPanel = OPTIONS_SCENE.instantiate()
	add_to_tree(options)
	var toggle: CheckButton = options.get_node("%HintsToggle")
	toggle.button_pressed = false
	toggle.button_pressed = true
	assert_true(Settings.hints_enabled, "La opción los enciende")
	assert_true(Settings.seen_hints.is_empty(), "Y vuelven a salir todos")
	options.free()


## La tabla de controles tiene, por cada acción, su tecla y su botón.
func test_controls_table_names_every_action() -> void:
	var panel: ControlsPanel = CONTROLS_SCENE.instantiate()
	add_to_tree(panel)
	var cells := panel.get_node("%Grid").get_children()
	var columns := ControlsPanel.HEADERS.size()
	assert_true(cells.size() == (ControlsPanel.ROWS.size() + 1) * columns, "Tres celdas por acción")
	for cell: Label in cells:
		assert_false(cell.text == InputDevice.UNBOUND_NAME, "Ninguna acción sin tecla")
	panel.free()
