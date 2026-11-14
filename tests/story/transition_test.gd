extends TestCase
## Pruebas del tránsito entre niveles: Lucía cruza el salar, habla y se puede saltar; el Q'ispi
## solo se ve en el reflejo. También que cada salida tenga su tránsito, con voz.

const TRANSITION_SCENE := preload("res://src/story/transition/transition.tscn")
const BOAT_DATA := preload("res://src/story/transition/hacia_centro.tres")
const FAST_SECONDS := 0.05
const FAST_WALK_SECONDS := 0.3
const FAST_LINE_DELAY := 0.1
const FINISH_FRAMES := 120
## Cuadros hasta que Lucía ya está hablando.
const LINE_FRAMES := 30
const SKIP_FRAMES := 10
const LEVELS_WITH_TRANSITION: Array[int] = [1, 2, 3, 4]
const LEVEL_PATH := "res://src/world/level_%02d/level_%02d.tscn"

var _transition: Transition
var _finished := false


## Arma un tránsito acelerado a pie, con lluvia, trenes y el Q'ispi, sin nivel siguiente.
func before_each() -> void:
	_transition = TRANSITION_SCENE.instantiate()
	_transition.enabled = false
	var data := TransitionData.new()
	data.line_audio = BOAT_DATA.line_audio
	data.line_text = BOAT_DATA.line_text
	data.has_rain = true
	data.horizon = TransitionData.Horizon.TRAINS
	data.shows_qispi = true
	_transition.data = data
	_speed_up(_transition)
	_transition.finished.connect(_on_finished)
	add_to_tree(_transition)


## Libera el tránsito.
func after_each() -> void:
	if is_instance_valid(_transition):
		_transition.free()


## Visto entero: Lucía avanza hacia la cámara y dice su línea con subtítulo.
func test_plays_whole_transition() -> void:
	var lucia: Node3D = _transition.get_node("Lucia")
	var start := lucia.position
	_transition.play()
	await wait_physics_frames(LINE_FRAMES)
	var subtitle: Label = _transition.get_node("%Subtitle")
	assert_true(subtitle.text.begins_with("Lucía: "), "Lucía dice su línea con subtítulo")
	await wait_physics_frames(FINISH_FRAMES)
	assert_true(_finished, "El tránsito debe terminar")
	assert_false(_transition.is_playing, "Al terminar ya no se reproduce")
	var walked := lucia.position.z - start.z
	assert_almost_eq(
		walked, _transition.walk_distance, "Lucía camina hacia la cámara", FAST_SECONDS
	)


## Lo que pide el tránsito se ve; el Q'ispi solo en la capa del reflejo, que la cámara no muestra.
func test_shows_rain_trains_and_qispi_only_in_reflection() -> void:
	assert_true((_transition.get_node("Rain") as Node3D).visible, "Debe llover")
	assert_true((_transition.get_node("Horizon/Trains") as Node3D).visible, "Se ven los trenes")
	assert_false((_transition.get_node("Horizon/Island") as Node3D).visible, "No se ve la isla")
	var camera: Camera3D = _transition.get_node("Camera3D")
	var layer := Transition.REFLECTION_LAYER
	assert_false(camera.get_cull_mask_value(layer), "La cámara no ve la capa del reflejo")
	for mesh: VisualInstance3D in _transition.get_node("Qispi").find_children(
		"*", "VisualInstance3D", true, false
	):
		assert_true(mesh.layers == 1 << (layer - 1), "El Q'ispi solo está en el reflejo")


## En el bote, Lucía va dentro y avanza con él.
func test_boat_carries_lucia() -> void:
	_transition.free()
	_transition = TRANSITION_SCENE.instantiate()
	_transition.enabled = false
	_transition.data = BOAT_DATA
	_speed_up(_transition)
	add_to_tree(_transition)
	var boat: Node3D = _transition.get_node("Boat")
	assert_true(boat.visible, "Se ve el bote")
	assert_true(_transition.get_node("Boat/Lucia") != null, "Lucía va en el bote")


## Saltarlo lo termina enseguida.
func test_skip_ends_quickly() -> void:
	_transition.walk_seconds = FINISH_FRAMES
	_transition.play()
	await wait_physics_frames(SKIP_FRAMES)
	_transition.skip()
	await wait_physics_frames(SKIP_FRAMES)
	assert_true(_finished, "Saltado, el tránsito debe terminar")


## Cada salida de los niveles 1 a 4 lleva su tránsito con la voz de Lucía.
func test_every_exit_has_its_transition() -> void:
	for number in LEVELS_WITH_TRANSITION:
		var level: Node3D = load(LEVEL_PATH % [number, number]).instantiate()
		var exit: LevelExit = level.get_node("Exit")
		assert_true(exit.transition != null, "La salida del nivel %d debe tener tránsito" % number)
		if exit.transition:
			assert_true(exit.transition.line_audio != null, "El tránsito %d tiene voz" % number)
			assert_false(exit.transition.line_text.is_empty(), "Y su texto")
		level.free()


## Acelera los tiempos de un tránsito para la prueba.
func _speed_up(transition: Transition) -> void:
	for property: String in ["fade_seconds", "hold_seconds"]:
		transition.set(property, FAST_SECONDS)
	transition.walk_seconds = FAST_WALK_SECONDS
	transition.line_delay_seconds = FAST_LINE_DELAY


## Anota que el tránsito terminó.
func _on_finished() -> void:
	_finished = true
