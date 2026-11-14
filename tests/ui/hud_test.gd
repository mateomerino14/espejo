extends TestCase
## Pruebas del HUD: la barra de aliento, lo que se puede usar al frente, los avisos, el nombre del
## nivel y el objetivo.

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


## Muestra lo que se puede usar al frente y lo borra cuando no hay nada.
func test_shows_interaction_prompt() -> void:
	var prompt: Label = _hud.get_node("%PromptLabel")
	EventBus.interaction_prompt_changed.emit("Abrir la puerta")
	assert_true(prompt.text == "[E]  Abrir la puerta", "Debe mostrar la acción")
	EventBus.interaction_prompt_changed.emit("")
	assert_true(prompt.text.is_empty(), "Debe borrarse")


## Los avisos aparecen con su texto.
func test_shows_notice() -> void:
	EventBus.notice_requested.emit("Saliste del hotel")
	await _wait_frames(FADE_FRAMES)
	var notice: Label = _hud.get_node("%NoticeLabel")
	assert_true(
		notice.text == "Saliste del hotel" and notice.modulate.a > 0.0, "Debe verse el aviso"
	)


## Espera la cantidad de frames de dibujo indicada.
func _wait_frames(count: int) -> void:
	for i in count:
		await tree.process_frame


## El nombre del nivel aparece abajo a la izquierda.
func test_shows_level_title() -> void:
	EventBus.level_title_requested.emit("Nivel 1 · Prueba")
	await _wait_frames(FADE_FRAMES)
	var title: Label = _hud.get_node("%TitleLabel")
	assert_true(title.text == "Nivel 1 · Prueba", "Debe mostrar el nombre del nivel")
	assert_true(title.modulate.a > 0.0, "El nombre debe verse")


## Un objetivo nuevo se anuncia con su sonido; repetirlo no lo vuelve a anunciar.
func test_announces_new_objective() -> void:
	GameState.objective = ""
	GameState.set_objective("Tapa los espejos")
	var label: Label = _hud.get_node("%ObjectiveLabel")
	var sound: AudioStreamPlayer = _hud.get_node("%ObjectiveSound")
	assert_true(label.text == "Tapa los espejos", "Debe mostrar el objetivo")
	assert_true(sound.playing, "Debe sonar el aviso")
	sound.stop()
	GameState.set_objective("Tapa los espejos")
	assert_false(sound.playing, "El mismo objetivo no se anuncia otra vez")
	GameState.objective = ""
