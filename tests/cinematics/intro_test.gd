extends TestCase
## Pruebas de la cinemática de inicio: arranca con el auto en camino y los personajes adentro.

const INTRO_SCENE := preload("res://src/cinematics/intro/intro.tscn")
const DRIVE_SECONDS := 0.6
const MIN_TRAVEL := 0.01
## El coseno entre la trompa y el avance: casi paralelos.
const ALIGNED := 0.99

var _intro: IntroCinematic


## Carga la cinemática.
func before_each() -> void:
	_intro = add_to_tree(INTRO_SCENE.instantiate())


## Libera la cinemática.
func after_each() -> void:
	_intro.free()


## El auto avanza desde su inicio, Lucía y Javier todavía no bajan y el Q'ispi no está.
func test_starts_with_car_arriving() -> void:
	var start := _intro.car_start.global_position
	await tree.create_timer(DRIVE_SECONDS).timeout
	assert_true(_intro.car.global_position.distance_to(start) > MIN_TRAVEL, "El auto debe avanzar")
	assert_false(_intro.lucia.visible, "Lucía sigue en el auto")
	assert_false(_intro.javier.visible, "Javier sigue en el auto")
	assert_false(_intro.qispi.visible, "El Q'ispi aparece recién con el flash")


## El auto avanza de frente: su trompa (+Z del modelo) apunta hacia donde va.
func test_car_drives_forward() -> void:
	var travel := (_intro.car_stop.global_position - _intro.car_start.global_position).normalized()
	var nose := _intro.car_start.global_basis.z.normalized()
	assert_true(nose.dot(travel) > ALIGNED, "La trompa debe mirar hacia donde avanza")
