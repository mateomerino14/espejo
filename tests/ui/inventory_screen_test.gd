extends TestCase
## Pruebas de la mochila: guarda hasta su tope, el inventario muestra lo que lleva Lucía, la cámara,
## el objetivo y las pistas, y pausa el juego; no se abre con el juego en pausa.

const SCREEN_SCENE := preload("res://src/ui/inventory_screen/inventory_screen.tscn")
const PLAYER_SCENE := preload("res://src/player/player.tscn")
const PICKUP_SCENE := preload("res://src/items/item_pickup/item_pickup.tscn")
const CANDLE_COUNT := 2
const OBJECTIVE := "Tapa todos los espejos"
const CANDLE_INDEX := 3

var _screen: InventoryScreen
var _player: Player


## Arma a Lucía con velas en la mochila y el inventario cerrado.
func before_each() -> void:
	GameState.reset()
	_player = PLAYER_SCENE.instantiate()
	add_to_tree(_player)
	GameState.add_item(ItemCatalog.Type.CANDLE, CANDLE_COUNT)
	_screen = SCREEN_SCENE.instantiate()
	add_to_tree(_screen)


## Cierra, libera y deja el juego sin pausa.
func after_each() -> void:
	_screen.get_tree().paused = false
	_screen.free()
	_player.free()
	GameState.reset()


## La mochila no pasa de su tope y gastar descuenta.
func test_bag_respects_its_limit() -> void:
	var limit := ItemCatalog.max_stack(ItemCatalog.Type.BLANKET)
	var added := GameState.add_item(ItemCatalog.Type.BLANKET, limit + 2)
	assert_true(added == limit, "Solo guarda hasta el tope")
	assert_true(GameState.use_item(ItemCatalog.Type.BLANKET), "Puede gastar una")
	assert_true(GameState.count_item(ItemCatalog.Type.BLANKET) == limit - 1, "Descuenta una")


## Lo que no cabe se queda en el suelo.
func test_pickup_leaves_what_does_not_fit() -> void:
	var limit := ItemCatalog.max_stack(ItemCatalog.Type.BLANKET)
	GameState.add_item(ItemCatalog.Type.BLANKET, limit - 1)
	var pile: ItemPickup = PICKUP_SCENE.instantiate()
	pile.item_type = ItemCatalog.Type.BLANKET
	pile.count = 3
	add_to_tree(pile)
	pile.get_node("Interactable").interact(_player)
	assert_true(GameState.count_item(ItemCatalog.Type.BLANKET) == limit, "Llena la mochila")
	assert_true(pile.count == 2, "Quedan dos en el suelo")
	pile.free()


## Abierto, muestra lo que lleva, la cámara, el objetivo y elige lo primero que tiene.
func test_shows_bag_camera_and_objective() -> void:
	GameState.set_objective(OBJECTIVE)
	_screen.open()
	assert_true(_screen.get_tree().paused, "Detiene el juego")
	var candle: InventorySlot = _screen.get_node("%SlotRow").get_child(CANDLE_INDEX)
	assert_true(candle.type == ItemCatalog.Type.CANDLE, "La cuarta casilla es la vela")
	assert_true((candle.get_node("%CountLabel") as Label).text == "2 / 4", "Cuenta lo que lleva")
	assert_true(
		(_screen.get_node("%ObjectiveLabel") as Label).text.ends_with(OBJECTIVE), "Objetivo"
	)
	assert_true((_screen.get_node("%CameraLabel") as Label).text.contains("24 fotos"), "El rollo")
	assert_true((_screen.get_node("%DetailName") as Label).text == "Vela", "Elige la vela")
	_screen.close()
	assert_false(_screen.get_tree().paused, "Al cerrar sigue el juego")


## Con el juego en pausa, por ejemplo con el álbum abierto, no se abre.
func test_does_not_open_while_paused() -> void:
	_screen.get_tree().paused = true
	var event := InputEventAction.new()
	event.action = &"inventory"
	event.pressed = true
	_screen._input(event)
	assert_false(_screen.is_open, "No se abre en pausa")
