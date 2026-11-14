class_name LevelExit
extends Area3D
## Salida del nivel: al cruzarla avisa a la jugadora y pasa al nivel siguiente, con su tránsito si
## tiene uno. Mientras está cerrada, solo recuerda qué falta.

@export var message := "Saliste del nivel"
## Escena del siguiente nivel; vacía mientras no exista.
@export_file("*.tscn") var next_level_path := ""
## Si se puede salir ya; el nivel la abre cuando se cumple lo que pide.
@export var is_open := true
## Lo que se le dice a la jugadora si llega antes de tiempo.
@export var closed_message := ""
## Cruce del salar que se muestra antes del nivel siguiente; sin él, el nivel se carga directo.
@export var transition: TransitionData

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
	is_used = true
	EventBus.notice_requested.emit(message)
	if next_level_path.is_empty():
		return
	if transition:
		Transition.go(get_tree(), transition, next_level_path)
	else:
		get_tree().change_scene_to_file.call_deferred(next_level_path)
