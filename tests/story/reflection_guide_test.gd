extends TestCase
## Pruebas del guía en el reflejo: avanza si Lucía lo sigue y la espera si se queda atrás.

const SECONDS_STEP := 0.5
const FIRST_POINT := Vector3(0, 0, -5)
const LAST_POINT := Vector3(0, 0, -10)
const LEAD_DISTANCE := 6.0
## Lucía tan atrás que el guía la espera.
const FAR_BEHIND := Vector3(0, 0, 20)
const WALK_STEPS := 40
const ARRIVE_TOLERANCE := 0.5

var _guide: ReflectionGuide
var _player: Node3D


## Arma un guía con dos puntos y una Lucía de mentira.
func before_each() -> void:
	_player = add_to_tree(Node3D.new())
	_guide = ReflectionGuide.new()
	_guide.waypoints = PackedVector3Array([FIRST_POINT, LAST_POINT])
	_guide.player = _player
	_guide.walk_speed = 2.0
	_guide.lead_distance = LEAD_DISTANCE
	add_to_tree(_guide)
	_guide.set_physics_process(false)


## Libera todo.
func after_each() -> void:
	_guide.free()
	_player.free()


## Con Lucía cerca, avanza hacia el primer punto.
func test_walks_when_followed() -> void:
	_guide._physics_process(SECONDS_STEP)
	assert_true(_guide.global_position.z < 0.0, "Debe avanzar hacia -Z")


## Con Lucía lejos, se queda esperando.
func test_waits_when_left_behind() -> void:
	_player.global_position = FAR_BEHIND
	_guide._physics_process(SECONDS_STEP)
	assert_true(_guide.global_position.is_zero_approx(), "Debe esperar")


## Al pasar por todos los puntos, termina.
func test_finishes_at_last_point() -> void:
	for i in WALK_STEPS:
		_player.global_position = _guide.global_position
		_guide._physics_process(SECONDS_STEP)
	assert_true(_guide.is_finished(), "Debe terminar el camino")
	assert_true(
		_guide.global_position.distance_to(LAST_POINT) < ARRIVE_TOLERANCE, "En el último punto"
	)
