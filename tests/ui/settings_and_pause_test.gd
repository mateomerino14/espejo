extends TestCase
## Pruebas de los ajustes y del menú de pausa: guardar, límites, pausar y aplicar al jugador.

const LEVEL_SCENE := preload("res://src/world/level_01/level_01.tscn")
const DEFAULT_SENSITIVITY := 1.0
const DEFAULT_VOLUME := 1.0

var _level: Node3D


## Vuelve a los ajustes por defecto y carga el nivel 1; el ejecutor ya usa un archivo de prueba.
func before_each() -> void:
	_restore_defaults()
	_level = LEVEL_SCENE.instantiate()
	add_to_tree(_level)


## Quita la pausa, libera el nivel y vuelve a los ajustes de siempre.
func after_each() -> void:
	tree.paused = false
	_level.free()
	_restore_defaults()


## Los ajustes guardados se recuperan al volver a cargarlos.
func test_settings_survive_reload() -> void:
	Settings.set_mouse_sensitivity(1.75)
	Settings.set_crouch_toggles(true)
	Settings.set_master_volume(0.4)
	_restore_defaults()
	Settings.load_settings()
	assert_almost_eq(Settings.mouse_sensitivity, 1.75, "Debe recuperar la sensibilidad")
	assert_true(Settings.crouch_toggles, "Debe recuperar agacharse alterno")
	assert_almost_eq(Settings.master_volume, 0.4, "Debe recuperar el volumen")


## La sensibilidad no sale de sus límites.
func test_sensitivity_is_clamped() -> void:
	Settings.set_mouse_sensitivity(10.0)
	assert_almost_eq(Settings.mouse_sensitivity, Settings.MAX_SENSITIVITY, "Tope máximo")
	Settings.set_mouse_sensitivity(0.0)
	assert_almost_eq(Settings.mouse_sensitivity, Settings.MIN_SENSITIVITY, "Tope mínimo")


## El jugador toma los ajustes al cambiar.
func test_player_applies_settings() -> void:
	var player: Player = _level.get_node("Player")
	Settings.set_crouch_toggles(true)
	assert_true(player.crouch_toggles, "El jugador debe pasar a agacharse alterno")


## Abrir el menú pausa el juego y cerrarlo lo reanuda.
func test_pause_menu_pauses_and_resumes() -> void:
	var menu: PauseMenu = _level.get_node("PauseMenu")
	menu.open()
	assert_true(tree.paused, "Abrir el menú debe pausar")
	assert_true(menu.visible, "El menú debe verse")
	menu.close()
	assert_false(tree.paused, "Cerrar el menú debe reanudar")
	assert_false(menu.visible, "El menú debe ocultarse")


## En calidad baja se apagan la iluminación global y la niebla volumétrica.
func test_low_quality_turns_off_expensive_effects() -> void:
	var environment: Environment = _level.get_node("WorldEnvironment").environment
	Settings.set_high_quality(false)
	assert_false(environment.sdfgi_enabled, "Debe apagar la iluminación global")
	assert_false(environment.volumetric_fog_enabled, "Debe apagar la niebla volumétrica")
	Settings.set_high_quality(true)
	assert_true(environment.sdfgi_enabled, "Debe volver a encenderla")


## Deja los ajustes en sus valores por defecto sin escribir en disco.
func _restore_defaults() -> void:
	Settings.mouse_sensitivity = DEFAULT_SENSITIVITY
	Settings.crouch_toggles = false
	Settings.master_volume = DEFAULT_VOLUME
	Settings.high_quality = true
