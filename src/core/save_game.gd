extends Node
## Partida guardada en disco (autoload "SaveGame"): el nivel, las notas leídas, el objetivo, la
## mochila, la cámara y lo que decide el final. Las fotos del álbum no se guardan.
##
## Se escribe al empezar cada nivel. Al continuar, el nivel se carga y toma lo pendiente.

const DEFAULT_PATH := "user://partida.cfg"
const SECTION := "partida"
const LEVEL_KEY := "nivel"
const NOTES_KEY := "notas"
const OFFERINGS_KEY := "ofrendas"
const CLUES_KEY := "pistas"
const STARES_KEY := "miradas"
const COVERED_KEY := "espejos_tapados"
const OBJECTIVE_KEY := "objetivo"
const ITEMS_KEY := "mochila"
const TOOLS_KEY := "herramientas"
const FILM_KEY := "rollo"
const BATTERY_KEY := "pila"

var save_path := DEFAULT_PATH

var _pending := {}


## Dice si hay una partida guardada para continuar.
func has_save() -> bool:
	return FileAccess.file_exists(save_path)


## Guarda el nivel indicado y las notas leídas hasta ahora.
func save(level_path: String) -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION, LEVEL_KEY, level_path)
	config.set_value(SECTION, NOTES_KEY, GameState.read_notes)
	config.set_value(SECTION, OFFERINGS_KEY, GameState.offerings)
	config.set_value(SECTION, CLUES_KEY, GameState.clue_photos)
	config.set_value(SECTION, STARES_KEY, GameState.mirror_stares)
	config.set_value(SECTION, COVERED_KEY, GameState.covered_mirrors)
	config.set_value(SECTION, OBJECTIVE_KEY, GameState.objective)
	config.set_value(SECTION, ITEMS_KEY, GameState.items)
	config.set_value(SECTION, TOOLS_KEY, GameState.tools)
	config.set_value(SECTION, FILM_KEY, GameState.camera_film)
	config.set_value(SECTION, BATTERY_KEY, GameState.camera_battery)
	config.save(save_path)


## Carga la partida guardada y abre su nivel; el nivel la aplica al empezar.
func continue_game() -> void:
	var level_path := load_pending()
	if not level_path.is_empty():
		get_tree().change_scene_to_file(level_path)


## Lee la partida guardada para que la tome el próximo nivel y devuelve qué nivel era.
func load_pending() -> String:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return ""
	for key in config.get_section_keys(SECTION):
		_pending[key] = config.get_value(SECTION, key)
	return _pending[LEVEL_KEY]


## Borra lo guardado y empieza desde el nivel indicado.
func new_game(first_level_path: String) -> void:
	clear()
	GameState.reset()
	get_tree().change_scene_to_file(first_level_path)


## Dice si el próximo nivel que cargue debe restaurar una partida.
func has_pending() -> bool:
	return not _pending.is_empty()


## Vuelca en GameState lo que guardaba la partida pendiente.
func restore_state(pending: Dictionary) -> void:
	GameState.read_notes = pending.get(NOTES_KEY, PackedStringArray())
	GameState.offerings = pending.get(OFFERINGS_KEY, PackedStringArray())
	GameState.clue_photos = pending.get(CLUES_KEY, PackedStringArray())
	GameState.mirror_stares = pending.get(STARES_KEY, 0)
	GameState.covered_mirrors = pending.get(COVERED_KEY, PackedStringArray())
	GameState.objective = pending.get(OBJECTIVE_KEY, "")
	GameState.items.assign(pending.get(ITEMS_KEY, {}))
	GameState.tools = pending.get(TOOLS_KEY, PackedStringArray())
	GameState.camera_film = pending.get(FILM_KEY, -1)
	GameState.camera_battery = pending.get(BATTERY_KEY, -1.0)


## Entrega la partida por restaurar y la olvida.
func take_pending() -> Dictionary:
	var pending := _pending
	_pending = {}
	return pending


## Borra la partida guardada.
func clear() -> void:
	_pending = {}
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
