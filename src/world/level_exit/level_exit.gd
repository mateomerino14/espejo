class_name LevelExit
extends Area3D
## Salida del nivel: si se cumple lo que pide, pasa al nivel siguiente con su tránsito.

@export var message := "Saliste del nivel"
## Escena del siguiente nivel; vacía mientras no exista.
@export_file("*.tscn") var next_level_path := ""
## Si se puede salir ya; el nivel la abre cuando se cumple lo que pide.
@export var is_open := true
## Lo que se le dice a la jugadora si llega antes de tiempo.
@export var closed_message := ""
## Cruce del salar que se muestra antes del nivel siguiente; sin él, el nivel se carga directo.
@export var transition: TransitionData
## Nota que hay que haber leído para salir; vacía si no hace falta ninguna.
@export var required_note := ""
## Herramienta que hace falta para salir, como los remos del bote; se gasta al salir.
@export var required_tool := ""
## Lo que se le dice a la jugadora si le falta la nota o la herramienta.
@export var missing_message := ""

var is_used := false


## Escucha cuando algo entra en la zona.
func _ready() -> void:
	body_entered.connect(_on_body_entered)


## La primera vez que entra el jugador con la salida abierta, avisa y pasa al siguiente nivel.
func _on_body_entered(body: Node3D) -> void:
	if is_used or not body is Player:
		return
	if not is_open:
		EventBus.notice_requested.emit(closed_message)
		return
	if not _has_requirements():
		EventBus.notice_requested.emit(missing_message)
		return
	if not required_tool.is_empty():
		GameState.use_tool(required_tool)
	is_used = true
	EventBus.notice_requested.emit(message)
	if next_level_path.is_empty():
		return
	if transition:
		Transition.go(get_tree(), transition, next_level_path)
	else:
		get_tree().change_scene_to_file.call_deferred(next_level_path)


## Dice si Lucía ya leyó la nota y lleva la herramienta que pide la salida.
func _has_requirements() -> bool:
	if not required_note.is_empty() and not GameState.has_read_note(required_note):
		return false
	return required_tool.is_empty() or GameState.has_tool(required_tool)
