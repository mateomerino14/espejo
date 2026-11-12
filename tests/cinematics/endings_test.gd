extends TestCase
## Pruebas de los finales: cada uno arranca, y quedarse mirando un espejo cuenta para el final.

const ENDINGS: Array[PackedScene] = [
	preload("res://src/cinematics/endings/ending_returned.tscn"),
	preload("res://src/cinematics/endings/ending_deal.tscn"),
	preload("res://src/cinematics/endings/ending_taken.tscn"),
]
const MIRROR_SCENE := preload("res://src/world/mirror/mirror.tscn")


## Deja la partida limpia.
func after_each() -> void:
	GameState.reset()


## Los tres finales cargan y empiezan su primer plano.
func test_endings_start() -> void:
	for scene in ENDINGS:
		var ending: CinematicScene = add_to_tree(scene.instantiate())
		await tree.create_timer(0.3).timeout
		assert_true(ending.director != null, "El final %s debe arrancar" % ending.name)
		ending.free()


## Quedarse mirando un espejo de cerca cuenta una vez, hasta mirar a otro lado.
func test_staring_at_mirror_counts() -> void:
	GameState.reset()
	var root := Node3D.new()
	add_to_tree(root)
	var mirror: Mirror = MIRROR_SCENE.instantiate()
	mirror.stare_seconds = 0.2
	root.add_child(mirror)
	var eye := Camera3D.new()
	root.add_child(eye)
	eye.global_position = Vector3(0.0, 0.0, 1.2)
	eye.current = true
	await tree.create_timer(0.5).timeout
	assert_true(GameState.mirror_stares == 1, "Debe contar una mirada")
	root.free()
