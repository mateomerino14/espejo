extends TestCase
## Pruebas del HUD: la barra de aliento aparece al gastarlo y se oculta al llenarse.

const HUD_SCENE := preload("res://src/ui/hud/hud.tscn")
const MAX_STAMINA := 100.0
const FADE_FRAMES := 30

var _hud: Hud
var _bar: ProgressBar


## Crea el HUD.
func before_each() -> void:
	_hud = HUD_SCENE.instantiate()
	add_to_tree(_hud)
	_bar = _hud.get_node("%StaminaBar")


## Libera el HUD.
func after_each() -> void:
	_hud.free()


## Con aliento gastado la barra se ve y marca lo que queda.
func test_bar_shows_when_stamina_is_spent() -> void:
	EventBus.stamina_changed.emit(40.0, MAX_STAMINA)
	await _wait_frames(FADE_FRAMES)
	assert_almost_eq(_bar.value, 40.0, "La barra debe marcar el aliento que queda")
	assert_true(_bar.modulate.a > 0.0, "La barra debe verse")


## Con el aliento lleno la barra queda oculta.
func test_bar_hides_when_full() -> void:
	EventBus.stamina_changed.emit(MAX_STAMINA, MAX_STAMINA)
	await _wait_frames(FADE_FRAMES)
	assert_almost_eq(_bar.modulate.a, 0.0, "La barra debe ocultarse")


## Espera la cantidad de frames de dibujo indicada.
func _wait_frames(count: int) -> void:
	for i in count:
		await tree.process_frame
