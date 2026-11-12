extends TestCase
## Pruebas de las puertas de cardón: abrir suena a pestillo y bisagra, cerrar a crujido y golpe.

const DOOR_SCENE := preload("res://src/world/props/cardon_door.tscn")

var _door: CardonDoor


## Pone una puerta cerrada.
func before_each() -> void:
	_door = add_to_tree(DOOR_SCENE.instantiate())


## Libera la puerta.
func after_each() -> void:
	_door.free()


## Al abrir suena la apertura; al cerrar, el crujido corto.
func test_open_and_close_sounds() -> void:
	var opening: AudioStreamPlayer3D = _door.get_node("Hinge/Open")
	var creak: AudioStreamPlayer3D = _door.get_node("Hinge/Creak")
	_door.set_open(true)
	assert_true(opening.playing and not creak.playing, "Al abrir suena el pestillo y la bisagra")
	opening.stop()
	_door.set_open(false)
	assert_true(creak.playing and not opening.playing, "Al cerrar cruje")
