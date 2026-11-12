extends TestCase
## Pruebas del álbum: guarda las fotos, pausa al abrirse y se hojea sin salirse del rollo.

const ALBUM_SCENE := preload("res://src/ui/album/album.tscn")

var _album: Album


## Crea el álbum.
func before_each() -> void:
	_album = ALBUM_SCENE.instantiate()
	add_to_tree(_album)


## Cierra el álbum, devuelve el juego y lo libera.
func after_each() -> void:
	_album.set_open(false)
	_album.free()


## Al abrirlo pausa el juego y muestra la última foto.
func test_opens_on_last_photo_and_pauses() -> void:
	EventBus.photo_taken.emit(Photo.new(true, PackedStringArray()))
	EventBus.photo_taken.emit(Photo.new(true, PackedStringArray(["Algo en la pared"])))
	_album.set_open(true)
	assert_true(tree.paused, "El juego debe pausarse")
	assert_true(_album.current == 1, "Debe abrir en la última foto")
	assert_true(_album.get_node("%Caption").text == "Algo en la pared", "Debe mostrar lo revelado")


## Hojear no pasa de la primera ni de la última foto.
func test_navigation_stays_inside_roll() -> void:
	EventBus.photo_taken.emit(Photo.new(false, PackedStringArray()))
	_album.set_open(true)
	_album.show_photo(-3)
	assert_true(_album.current == 0, "No debe pasar de la primera")
	_album.show_photo(5)
	assert_true(_album.current == 0, "No debe pasar de la última")


## Al cerrarlo el juego sigue.
func test_closing_resumes_game() -> void:
	_album.set_open(true)
	_album.set_open(false)
	assert_false(tree.paused, "El juego debe seguir")
