extends TestCase
## Pruebas del álbum: guarda las fotos, que siguen de un nivel a otro, pausa al abrirse y se hojea
## sin salirse del rollo.

const ALBUM_SCENE := preload("res://src/ui/album/album.tscn")

var _album: Album


## Crea el álbum vacío.
func before_each() -> void:
	GameState.photos.clear()
	_album = ALBUM_SCENE.instantiate()
	add_to_tree(_album)


## Cierra el álbum, devuelve el juego, lo libera y lo deja vacío.
func after_each() -> void:
	_album.set_open(false)
	_album.free()
	GameState.photos.clear()


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


## Un álbum nuevo, como el del nivel siguiente, tiene las fotos de antes.
func test_photos_follow_to_next_level() -> void:
	EventBus.photo_taken.emit(Photo.new(false, PackedStringArray()))
	var next: Album = ALBUM_SCENE.instantiate()
	add_to_tree(next)
	next.set_open(true)
	assert_true(next.get_node("%Counter").text == "1 / 1", "Debe tener la foto de antes")
	next.set_open(false)
	next.free()
