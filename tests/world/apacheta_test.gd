extends TestCase
## Pruebas de las apachetas y las pilas: la ofrenda se deja una vez, aquieta al Q'ispi y cuenta;
## las pilas cargan el flash.

const ROOM_SCENE := preload("res://src/world/test_room/test_room.tscn")
const APACHETA_SCENE := preload("res://src/world/apacheta/apacheta.tscn")
const BATTERY_SCENE := preload("res://src/world/pickups/battery_pickup.tscn")

var _room: Node3D
var _player: Player
var _qispi: Qispi
var _apacheta: Apacheta
var _offerings := 0


## Carga la sala con una apacheta.
func before_each() -> void:
	GameState.reset()
	_room = add_to_tree(ROOM_SCENE.instantiate())
	_player = _room.get_node("Player")
	_qispi = _room.get_node("Qispi")
	_apacheta = APACHETA_SCENE.instantiate()
	_apacheta.apacheta_id = "prueba"
	_room.add_child(_apacheta)
	EventBus.offering_made.connect(_on_offering_made)


## Libera la sala y limpia la partida.
func after_each() -> void:
	EventBus.offering_made.disconnect(_on_offering_made)
	_room.free()
	GameState.reset()


## La ofrenda se deja una sola vez y cuenta para el final.
func test_offering_counts_once() -> void:
	var use: Interactable = _apacheta.get_node("Interactable")
	use.interact(_player)
	use.interact(_player)
	assert_true(GameState.offerings.size() == 1, "Debe contar una ofrenda")
	assert_true(_offerings == 1, "Debe avisar una sola vez")
	assert_true(_apacheta.get_node("Offering").visible, "La vela debe quedar encendida")


## Una ofrenda saca al Q'ispi de la caza y lo deja sin notar a Lucía un rato.
func test_offering_calms_qispi() -> void:
	await wait_physics_frames(5)
	_qispi.state = Qispi.State.HUNT
	_apacheta.get_node("Interactable").interact(_player)
	assert_true(_qispi.state == Qispi.State.STALK, "Debe dejar de cazar")
	assert_true(_qispi.is_calm(), "Debe quedar aquietado")


## Las pilas cargan el flash y desaparecen.
func test_batteries_recharge_flash() -> void:
	var camera: PhotoCamera = _player.get_node("Head/Camera3D/PhotoCamera")
	camera.battery = 0.0
	var batteries: BatteryPickup = BATTERY_SCENE.instantiate()
	_room.add_child(batteries)
	batteries.get_node("Interactable").interact(_player)
	assert_almost_eq(camera.battery, batteries.charge, "Debe cargar el flash")
	await tree.process_frame
	assert_false(is_instance_valid(batteries), "Las pilas deben desaparecer")


## Cuenta los avisos de ofrenda.
func _on_offering_made(_origin: Vector3) -> void:
	_offerings += 1
