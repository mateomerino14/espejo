extends TestCase
## Pruebas de la puerta de cardón: se abre y se cierra al usarla, cruje y cambia su texto.

const DOOR_SCENE := preload("res://src/world/props/cardon_door.tscn")

var _door: CardonDoor
var _interactable: Interactable
var _noises := 0


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


## Cuenta los ruidos.
func _on_noise_emitted(_origin: Vector3, _loudness: float) -> void:
	_noises += 1
