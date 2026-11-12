extends TestCase
## Pruebas del final: depende de las ofrendas, las fotos de pistas y los espejos.


## Empieza cada prueba con una partida limpia.
func before_each() -> void:
	GameState.reset()


## Deja la partida limpia para las demás pruebas.
func after_each() -> void:
	GameState.reset()


## Con todas las ofrendas y las pistas, el agua devuelve a Javier.
func test_all_offerings_and_clues_return_him() -> void:
	for i in GameState.TOTAL_OFFERINGS:
		GameState.add_offering()
	for clue: String in ["espejo", "lista", "altar"]:
		GameState.add_clue_photo(clue)
	assert_true(GameState.choose_ending() == GameState.Ending.RETURNED, "Final bueno")


## Con algunas ofrendas, el trato.
func test_some_offerings_make_a_deal() -> void:
	for i in GameState.MIN_OFFERINGS:
		GameState.add_offering()
	assert_true(GameState.choose_ending() == GameState.Ending.DEAL, "Final del trato")


## Sin ofrendas, o mirándose demasiado en los espejos, el salar se la lleva.
func test_few_offerings_or_mirrors_take_her() -> void:
	assert_true(GameState.choose_ending() == GameState.Ending.TAKEN, "Sin ofrendas")
	for i in GameState.TOTAL_OFFERINGS:
		GameState.add_offering()
	for i in GameState.MAX_MIRROR_STARES:
		GameState.add_mirror_stare()
	assert_true(GameState.choose_ending() == GameState.Ending.TAKEN, "Mirándose demasiado")


## La misma pista dos veces cuenta una sola.
func test_clue_counts_once() -> void:
	GameState.add_clue_photo("espejo")
	GameState.add_clue_photo("espejo")
	assert_true(GameState.clue_photos.size() == 1, "Una sola pista")
