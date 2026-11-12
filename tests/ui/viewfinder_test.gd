extends TestCase
## Pruebas del visor: aparece con la cámara y muestra el rollo y la batería.

const VIEWFINDER_SCENE := preload("res://src/ui/viewfinder/viewfinder.tscn")
const FADE_SECONDS := 0.3

var _viewfinder: Viewfinder


## Crea el visor.
func before_each() -> void:
	_viewfinder = VIEWFINDER_SCENE.instantiate()
	add_to_tree(_viewfinder)


## Libera el visor.
func after_each() -> void:
	_viewfinder.free()


## Al levantar la cámara el visor se ve, y al bajarla se oculta.
func test_follows_camera() -> void:
	var screen: Control = _viewfinder.get_node("Screen")
	EventBus.camera_raised.emit(true)
	await tree.create_timer(FADE_SECONDS).timeout
	assert_true(screen.visible and screen.modulate.a > 0.9, "El visor debe verse")
	EventBus.camera_raised.emit(false)
	await tree.create_timer(FADE_SECONDS).timeout
	assert_false(screen.visible, "El visor debe ocultarse")


## Muestra cuántas fotos quedan y cuánta batería.
func test_shows_film_and_battery() -> void:
	EventBus.film_changed.emit(7, 24)
	EventBus.camera_battery_changed.emit(25.0, 100.0)
	assert_true(_viewfinder.get_node("%FilmLabel").text == "7 / 24", "Debe mostrar el rollo")
	assert_true(_viewfinder.get_node("%BatteryLabel").text == "25 %", "Debe mostrar la batería")
