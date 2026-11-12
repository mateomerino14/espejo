extends TestCase
## Pruebas de las huellas del Q'ispi: cada paso deja una, alternando los pies.

const QISPI_SCENE := preload("res://src/enemies/qispi/qispi.tscn")

var _qispi: Qispi
var _trail: FootprintTrail


## Crea un Q'ispi quieto.
func before_each() -> void:
	_qispi = add_to_tree(QISPI_SCENE.instantiate())
	_qispi.process_mode = Node.PROCESS_MODE_DISABLED
	_trail = _qispi.get_node("FootprintTrail")


## Libera al Q'ispi.
func after_each() -> void:
	_qispi.free()


## Dos pasos dejan dos huellas visibles, una a cada lado.
func test_steps_leave_alternating_prints() -> void:
	_trail.place()
	_trail.place()
	var shown: Array[Decal] = []
	for child in _trail.get_children():
		var footprint := child as Decal
		if footprint and footprint.visible:
			shown.append(footprint)
	assert_true(shown.size() == 2, "Debe haber dos huellas")
	var left := _qispi.global_basis.x.dot(shown[0].global_position - _qispi.global_position)
	var right := _qispi.global_basis.x.dot(shown[1].global_position - _qispi.global_position)
	assert_true(left * right < 0.0, "Deben ir una a cada lado")
