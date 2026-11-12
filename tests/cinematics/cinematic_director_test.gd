extends TestCase
## Pruebas de las cinemáticas: los planos pasan en orden, avisan sus momentos y la cámara los sigue.

const DIRECTOR_SCENE := preload("res://src/cinematics/cinematic_director.tscn")
const SHOT_SCRIPT := preload("res://src/cinematics/cinematic_shot.gd")

var _root: Node3D
var _director: CinematicDirector
var _camera: Camera3D
var _cues: Array[StringName] = []


## Arma dos planos cortos con su cámara.
func before_each() -> void:
	_root = add_to_tree(Node3D.new())
	_camera = Camera3D.new()
	_root.add_child(_camera)
	var shots := Node3D.new()
	_root.add_child(shots)
	shots.add_child(_make_shot(&"primero", Vector3(0.0, 1.0, 0.0), Vector3(2.0, 1.0, 0.0)))
	shots.add_child(_make_shot(&"segundo", Vector3(5.0, 2.0, 0.0), Vector3(5.0, 2.0, 2.0)))
	_director = DIRECTOR_SCENE.instantiate()
	_director.camera = _camera
	_director.shots_root = shots
	_director.cue_reached.connect(_cues.append)
	_root.add_child(_director)


## Libera la escena.
func after_each() -> void:
	_root.free()


## Al empezar, la cámara está al inicio del primer plano y se avisó su momento.
func test_first_shot_starts() -> void:
	await tree.process_frame
	await tree.process_frame
	assert_true(_cues == [&"primero"], "Debe avisar el primer momento")
	assert_true(
		_camera.global_position.distance_to(Vector3(0.0, 1.0, 0.0)) < 0.2, "Cámara al inicio"
	)


## Pasado el primero, sigue el segundo plano.
func test_shots_follow_in_order() -> void:
	await tree.create_timer(0.35).timeout
	assert_true(_cues == [&"primero", &"segundo"], "Deben pasar los dos momentos en orden")
	assert_true(_camera.global_position.x > 4.0, "La cámara debe estar en el segundo plano")


## El plano mueve la cámara de From a To.
func test_shot_interpolates_camera() -> void:
	var shot: CinematicShot = _root.get_child(1).get_child(0)
	assert_almost_eq(
		shot.camera_transform(0.5).origin.x, 1.0, "A mitad de plano, a mitad de camino"
	)


## Crea un plano de 0,2 s que va de [param from] a [param to].
func _make_shot(cue: StringName, from: Vector3, to: Vector3) -> CinematicShot:
	var shot: CinematicShot = SHOT_SCRIPT.new()
	shot.duration = 0.2
	shot.cue = cue
	shot.add_child(_make_marker("From", from))
	shot.add_child(_make_marker("To", to))
	return shot


## Crea un marcador con nombre en [param point].
func _make_marker(marker_name: String, point: Vector3) -> Marker3D:
	var marker := Marker3D.new()
	marker.name = marker_name
	marker.position = point
	return marker
