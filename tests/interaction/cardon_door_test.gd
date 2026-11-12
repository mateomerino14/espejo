extends TestCase
## Pruebas de la puerta de cardón: se abre y se cierra al usarla, cruje, golpea al cerrarse y cambia
## su texto.

const DOOR_SCENE := preload("res://src/world/props/cardon_door.tscn")

var _door: CardonDoor
var _interactable: Interactable
var _noises := 0
var _last_loudness := 0.0


## Crea una puerta cerrada que se mueve rápido.
func before_each() -> void:
	_door = DOOR_SCENE.instantiate()
	_door.swing_seconds = 0.1
	add_to_tree(_door)
	_interactable = _door.get_node("Hinge/Interactable")
	EventBus.noise_emitted.connect(_on_noise_emitted)


## Libera la puerta.
func after_each() -> void:
	EventBus.noise_emitted.disconnect(_on_noise_emitted)
	_door.free()


## Al usarla se abre girando sobre la bisagra y suena.
func test_opens_when_used() -> void:
	assert_true(_interactable.get_prompt(null) == CardonDoor.OPEN_PROMPT, "Cerrada se ofrece abrir")
	_interactable.interact(null)
	await tree.create_timer(0.3).timeout
	var hinge: Node3D = _door.get_node("Hinge")
	assert_almost_eq(
		rad_to_deg(hinge.rotation.y), _door.open_angle_degrees, "Debe quedar abierta", 1.0
	)
	assert_true(_noises == 1, "Debe crujir")
	assert_true(
		_interactable.get_prompt(null) == CardonDoor.CLOSE_PROMPT, "Abierta se ofrece cerrar"
	)


## Usarla de nuevo la cierra.
func test_closes_when_used_again() -> void:
	_interactable.interact(null)
	_interactable.interact(null)
	await tree.create_timer(0.3).timeout
	assert_almost_eq(_door.get_node("Hinge").rotation.y, 0.0, "Debe quedar cerrada")
	assert_almost_eq(_last_loudness, _door.knock_loudness, "Al llegar al marco debe golpear")


## Con llave no se abre, lo dice y solo traquetea la manija, más bajo que el crujido.
func test_locked_door_stays_closed() -> void:
	_door.is_locked = true
	assert_true(
		_interactable.get_prompt(null) == CardonDoor.LOCKED_PROMPT, "Debe decir que tiene llave"
	)
	_interactable.interact(null)
	assert_false(_door.is_open, "No debe abrirse")
	assert_true(_noises == 1, "La manija debe traquetear")
	assert_almost_eq(
		_last_loudness, _door.knock_loudness, "El traqueteo suena menos que el crujido"
	)


## Cuenta los ruidos.
func _on_noise_emitted(_origin: Vector3, loudness: float) -> void:
	_noises += 1
	_last_loudness = loudness
