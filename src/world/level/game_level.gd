class_name GameLevel
extends Node3D
## Base de los niveles: al empezar restaura la partida si se eligió continuar y la guarda; también
## la guarda con cada ofrenda. Muestra el nombre del nivel y, un poco después, el objetivo. Lo que
## se juntó en niveles anteriores sigue en GameState.

const TITLE_DELAY_SECONDS := 1.0
const OBJECTIVE_DELAY_SECONDS := 2.5
## Al llegar desde un tránsito, el nivel aparece desde negro.
const ARRIVAL_FADE_SECONDS := 1.5
## Por encima del HUD y del visor.
const ARRIVAL_LAYER := 9

## Nombre del nivel, que aparece abajo a la izquierda al empezar.
@export var title := ""
## Lo primero que tiene que hacer Lucía en este nivel.
@export var objective := ""
## Hasta dónde ve Lucía alrededor, para dibujar el mapa; afuera se ve más lejos que en el hostal.
@export var map_reach := 4.0


## Empieza el mapa en blanco, restaura lo pendiente, guarda, escucha las ofrendas, aparece desde
## negro si viene de un tránsito y presenta el nivel.
func _ready() -> void:
	var first_objective := objective
	GameState.explored.clear()
	if SaveGame.has_pending():
		SaveGame.restore_state(SaveGame.take_pending())
		if not GameState.objective.is_empty():
			first_objective = GameState.objective
	GameState.objective = ""
	SaveGame.save(scene_file_path)
	EventBus.offering_made.connect(_on_offering_made)
	if Transition.take_arrival():
		_fade_in_from_black()
	_present(first_objective)


## Muestra el nombre del nivel y después su objetivo.
func _present(first_objective: String) -> void:
	get_tree().create_timer(TITLE_DELAY_SECONDS).timeout.connect(_show_title)
	get_tree().create_timer(OBJECTIVE_DELAY_SECONDS).timeout.connect(
		_give_objective.bind(first_objective)
	)


## Pide al HUD el nombre del nivel.
func _show_title() -> void:
	if is_inside_tree() and not title.is_empty():
		EventBus.level_title_requested.emit(title)


## Da el primer objetivo, salvo que ya haya otro.
func _give_objective(first_objective: String) -> void:
	if is_inside_tree() and GameState.objective.is_empty():
		GameState.set_objective(first_objective)


## Aparece desde el negro en que terminó el tránsito.
func _fade_in_from_black() -> void:
	var layer := CanvasLayer.new()
	layer.layer = ARRIVAL_LAYER
	var curtain := ColorRect.new()
	curtain.color = Color.BLACK
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(curtain)
	add_child(layer)
	var tween := create_tween()
	tween.tween_property(curtain, "modulate:a", 0.0, ARRIVAL_FADE_SECONDS)
	tween.tween_callback(layer.queue_free)


## Cada ofrenda guarda la partida.
func _on_offering_made(_origin: Vector3) -> void:
	SaveGame.save(scene_file_path)
