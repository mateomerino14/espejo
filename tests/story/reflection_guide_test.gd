extends TestCase
## Pruebas del guía en el reflejo: camina hacia sus puntos mientras Lucía lo sigue y la espera si
## se queda atrás.

const SECONDS_STEP := 0.5

var _guide: ReflectionGuide
var _player: Node3D


## Arma un guía con dos puntos y una Lucía de mentira.
func before_each() -> void:
	_player = add_to_tree(Node3D.new())
	_guide = ReflectionGuide.new()
	_guide.waypoints = PackedVector3Array([Vector3(0, 0, -5), Vector3(0, 0, -10)])
	_guide.player = _player
	_guide.walk_speed = 2.0
	_guide.lead_distance = 6.0
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
	_player.global_position = Vector3(0, 0, 20)
	_guide._physics_process(SECONDS_STEP)
	assert_true(_guide.global_position.is_zero_approx(), "Debe esperar")


## Al pasar por todos los puntos, termina.
func test_finishes_at_last_point() -> void:
	for i in 40:
		_player.global_position = _guide.global_position
		_guide._physics_process(SECONDS_STEP)
	assert_true(_guide.is_finished(), "Debe terminar el camino")
	assert_true(_guide.global_position.distance_to(Vector3(0, 0, -10)) < 0.5, "En el último punto")
