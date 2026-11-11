extends TestCase
## Pruebas del guardado: cada nivel guarda al empezar y al continuar vuelven las notas leídas.

const LEVEL_SCENE := preload("res://src/world/level_01/level_01.tscn")
const MAIN_MENU_SCENE := preload("res://src/ui/main_menu/main_menu.tscn")
const NOTE_ID := "nota_rosa"

var _level: Level01


## Empieza sin partida guardada.
func before_each() -> void:
	SaveGame.clear()


## Libera lo que haya quedado y borra la partida de prueba.
func after_each() -> void:
	if _level:
		_level.free()
	SaveGame.clear()
	GameState.reset()


## Al empezar un nivel ya queda una partida para continuar.
func test_starting_a_level_saves() -> void:
	_level = LEVEL_SCENE.instantiate()
	add_to_tree(_level)
	assert_true(SaveGame.has_save(), "Debe guardarse al empezar el nivel")


## Al continuar se abre el mismo nivel con las notas que ya se habían leído.
func test_continue_restores_notes() -> void:
	_level = LEVEL_SCENE.instantiate()
	add_to_tree(_level)
	GameState.mark_note_read(NOTE_ID)
	SaveGame.save(_level.scene_file_path)
	_level.free()
	_level = null
	GameState.reset()
	var level_path := SaveGame.load_pending()
	assert_true(level_path.ends_with("level_01.tscn"), "Debe recordar el nivel")
	_level = (load(level_path) as PackedScene).instantiate()
	add_to_tree(_level)
	assert_true(GameState.has_read_note(NOTE_ID), "Debe recordar las notas leídas")


## En el menú, Continuar solo se puede usar si hay partida guardada.
func test_menu_continue_needs_a_save() -> void:
	var menu: Node = MAIN_MENU_SCENE.instantiate()
	add_to_tree(menu)
	assert_true(menu.get_node("%ContinueButton").disabled, "Sin partida debe estar apagado")
	menu.free()
	SaveGame.save(LEVEL_SCENE.resource_path)
	menu = MAIN_MENU_SCENE.instantiate()
	add_to_tree(menu)
	assert_false(menu.get_node("%ContinueButton").disabled, "Con partida debe estar disponible")
	menu.free()
