class_name HintBox
extends PanelContainer
## Cuadro de consejos de controles, arriba a la derecha. Muestra un consejo a la vez, con la tecla o
## el botón del aparato con que se juega, y cada consejo una sola vez.

const SHOW_SECONDS := 7.0
## Pausa entre un consejo y el siguiente, para que el primero se desvanezca.
const GAP_SECONDS := 0.8
const FADE_SPEED := 3.0
const SHOWN_ALPHA := 1.0
const HIDDEN_ALPHA := 0.0
## Consejos que pasan delante de los que esperan, porque sirven en ese mismo momento.
const URGENT: Array[String] = ["caza"]

## Consejo que se está mostrando; vacío si no hay ninguno.
var current := ""

var _queue: Array[String] = []

@onready var _label: Label = %HintLabel
@onready var _timer: Timer = %HintTimer


## Arranca oculto y escucha los pedidos de consejos.
func _ready() -> void:
	modulate.a = HIDDEN_ALPHA
	EventBus.hint_requested.connect(request)
	InputDevice.changed.connect(_refresh_text)
	_timer.timeout.connect(_on_timeout)


## Aparece mientras hay un consejo; si no, se desvanece.
func _process(delta: float) -> void:
	var target := HIDDEN_ALPHA
	if not current.is_empty():
		target = SHOWN_ALPHA
	modulate.a = move_toward(modulate.a, target, FADE_SPEED * delta)


## Pone en la fila un consejo, si están activados y el jugador todavía no lo vio.
func request(id: String) -> void:
	if not Settings.hints_enabled or id in Settings.seen_hints:
		return
	if id == current or id in _queue or HintCatalog.text(id).is_empty():
		return
	if id in URGENT:
		_queue.push_front(id)
	else:
		_queue.append(id)
	_show_next()


## Muestra el siguiente consejo de la fila si no hay otro en pantalla.
func _show_next() -> void:
	if not current.is_empty() or _queue.is_empty() or not _timer.is_stopped():
		return
	current = _queue.pop_front()
	Settings.mark_hint_seen(current)
	_refresh_text()
	_timer.start(SHOW_SECONDS)


## Escribe el consejo actual con las teclas del aparato que se está usando.
func _refresh_text() -> void:
	if not current.is_empty():
		_label.text = HintCatalog.text(current)


## Al acabar un consejo deja una pausa; al acabar la pausa, sigue con la fila.
func _on_timeout() -> void:
	if current.is_empty():
		_show_next()
		return
	current = ""
	_timer.start(GAP_SECONDS)
