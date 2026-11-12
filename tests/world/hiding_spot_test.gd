extends TestCase
## Pruebas de los escondites: Lucía entra y sale, el Q'ispi no la ve adentro y, si la vio entrar,
## sabe dónde buscar.

const ROOM_SCENE := preload("res://src/world/test_room/test_room.tscn")
const WARDROBE_SCENE := preload("res://src/world/hiding_spot/wardrobe.tscn")
const WARDROBE_SPOT := Vector3(-3.0, 0.0, 3.0)
const SETTLE_FRAMES := 5

var _room: Node3D
var _player: Player
var _qispi: Qispi
var _wardrobe: HidingSpot


## Carga la sala con un ropero y Lucía delante.
func before_each() -> void:
	_room = add_to_tree(ROOM_SCENE.instantiate())
	_player = _room.get_node("Player")
	_qispi = _room.get_node("Qispi")
	_qispi.set_physics_process(false)
	_wardrobe = WARDROBE_SCENE.instantiate()
	_wardrobe.move_seconds = 0.05
	_room.add_child(_wardrobe)
	_wardrobe.global_position = WARDROBE_SPOT
	_player.global_position = _wardrobe.get_exit_transform().origin


## Libera la sala.
func after_each() -> void:
	_room.free()


## Al esconderse queda adentro, sin cuerpo que choque, y el ropero sabe que está ocupado.
func test_hides_inside() -> void:
	_player.hide_in(_wardrobe)
	await tree.create_timer(0.2).timeout
	assert_true(_player.is_hidden(), "Debe estar escondida")
	assert_true(_wardrobe.occupant == _player, "El ropero debe saber que está ocupado")
	var inside := _wardrobe.get_inside_transform().origin
	assert_true(_player.global_position.distance_to(inside) < 0.05, "Debe quedar adentro")


## Al salir vuelve a quedar delante y libre.
func test_leaves_hiding() -> void:
	_player.hide_in(_wardrobe)
	await tree.create_timer(0.2).timeout
	_player.leave_hiding()
	await tree.create_timer(0.2).timeout
	assert_false(_player.is_hidden(), "Ya no debe estar escondida")
	assert_true(_wardrobe.occupant == null, "El ropero debe quedar libre")
	var offset := _wardrobe.get_exit_transform().origin - _player.global_position
	assert_true(Vector2(offset.x, offset.z).length() < 0.25, "Debe quedar delante")


## Escondida, la vista del ente no la ve aunque esté encima.
func test_sight_ignores_hidden_player() -> void:
	_player.hide_in(_wardrobe)
	var sight: PlayerSight = _qispi.get_node("Eyes")
	sight.global_position = _player.get_eye_position() + Vector3(0.0, 0.0, 0.5)
	assert_false(sight.can_see(_player), "No debe verla escondida")


## Si la estaba cazando y la perdió recién, sabe en qué ropero se metió y la encuentra.
func test_knows_spot_if_it_saw_her_enter() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	_qispi.wake()
	_qispi.set_physics_process(false)
	_qispi.state = Qispi.State.HUNT
	_player.hide_in(_wardrobe)
	assert_true(_qispi.get("_suspected_spot") == _wardrobe, "Debe sospechar del ropero")
	assert_true(_qispi.call("_finds_player_in", _wardrobe), "Debe encontrarla al revisar")
