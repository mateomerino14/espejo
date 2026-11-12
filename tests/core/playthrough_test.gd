extends TestCase
## Prueba de la partida entera: desde la cinemática de inicio, cada escena lleva a la siguiente
## hasta los finales, y cada final vuelve al menú.

const INTRO := "res://src/cinematics/intro/intro.tscn"
const ROUTER := "res://src/cinematics/endings/ending_router.tscn"
const MAIN_MENU := "res://src/ui/main_menu/main_menu.tscn"
const ORDER: Array[String] = [
	INTRO,
	"res://src/world/level_01/level_01.tscn",
	"res://src/world/level_02/level_02.tscn",
	"res://src/world/level_03/level_03.tscn",
	"res://src/world/level_04/level_04.tscn",
	"res://src/world/level_05/level_05.tscn",
	ROUTER,
]
## Propiedades con las que una escena dice cuál viene después.
const NEXT_PROPERTIES: Array[StringName] = [&"next_level_path", &"next_scene"]


## Siguiendo las salidas desde la intro se pasa por todos los niveles en orden.
func test_levels_are_chained_in_order() -> void:
	var visited: Array[String] = [INTRO]
	var current := INTRO
	while current != ROUTER and visited.size() <= ORDER.size():
		current = _next_scene_of(current)
		visited.append(current)
	assert_true(visited == ORDER, "Orden de la partida: %s" % [visited])


## Cada final carga y vuelve al menú principal.
func test_endings_return_to_menu() -> void:
	for ending: String in EndingRouter.ENDINGS.values():
		assert_true(_next_scene_of(ending) == MAIN_MENU, "%s vuelve al menú" % ending)


## La escena que sigue a [param path], leída de sus nodos sin abrirla.
func _next_scene_of(path: String) -> String:
	var scene := load(path) as PackedScene
	assert_true(scene != null, "%s carga" % path)
	var state := scene.get_state()
	for node_index in state.get_node_count():
		for property_index in state.get_node_property_count(node_index):
			var property := state.get_node_property_name(node_index, property_index)
			var value: Variant = state.get_node_property_value(node_index, property_index)
			if property in NEXT_PROPERTIES and value is String and not value.is_empty():
				return value
	return ""
