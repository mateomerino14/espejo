extends TestCase
## Pruebas de los brazos de Lucía: siguen a la cámara y al usar algo, y los espejos no los ven.

const PLAYER_SCENE := preload("res://src/player/player.tscn")
const MIRROR_SCENE := preload("res://src/world/mirror/mirror.tscn")

var _player: Player
var _body: FirstPersonBody
var _animation: AnimationPlayer


## Arma a Lucía con sus brazos.
func before_each() -> void:
	_player = add_to_tree(PLAYER_SCENE.instantiate())
	_body = _player.get_node("Head/Camera3D/FirstPersonBody")
	_animation = _body.find_children("*", "AnimationPlayer", true, false).front()


## Libera a Lucía.
func after_each() -> void:
	_player.free()


## Al empezar sostiene la cámara; al levantarla la lleva al ojo y al bajarla vuelve al pecho.
func test_arms_follow_camera() -> void:
	assert_true(_animation.current_animation == FirstPersonBody.HOLD, "Sostiene la cámara")
	var camera: PhotoCamera = _player.get_node("Head/Camera3D/PhotoCamera")
	camera.set_raised(true)
	assert_true(_animation.current_animation == FirstPersonBody.AIM, "La levanta")
	camera.set_raised(false)
	assert_true(_animation.current_animation == FirstPersonBody.HOLD, "La baja")


## Al usar algo no estira la mano: sigue sosteniendo la cámara.
func test_keeps_holding_when_interacting() -> void:
	var interactor: Interactor = _player.get_node("Head/Camera3D/Interactor")
	interactor.interacted.emit()
	assert_true(_animation.current_animation == FirstPersonBody.HOLD, "Sigue con la cámara")


## Los espejos no dibujan la capa de los brazos: Lucía no se ve en ellos.
func test_mirrors_skip_own_body() -> void:
	var mirror: Node = MIRROR_SCENE.instantiate()
	var reflection: Camera3D = mirror.get_node("Reflection/Camera3D")
	assert_false(reflection.cull_mask & _body.render_layers, "El espejo no debe ver a Lucía")
	mirror.free()
