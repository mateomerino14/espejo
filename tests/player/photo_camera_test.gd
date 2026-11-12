extends TestCase
## Pruebas de la cámara: el visor revela el reflejo, las fotos gastan rollo y el flash batería.

const CAMERA_SCENE := preload("res://src/player/components/photo_camera.tscn")
const REVEAL_LAYER := 11

var _view: Camera3D
var _camera: PhotoCamera
var _photos: Array[Photo] = []


## Arma una cámara del jugador con su cámara de fotos, sin espera entre disparos.
func before_each() -> void:
	_view = Camera3D.new()
	_camera = CAMERA_SCENE.instantiate()
	_camera.camera = _view
	_camera.cooldown = 0.0
	_view.add_child(_camera)
	add_to_tree(_view)
	_camera.photo_taken.connect(_photos.append)


## Libera la cámara cuando termine de avisar la última foto.
func after_each() -> void:
	_view.queue_free()


## Levantar la cámara muestra la capa del reflejo y bajarla la oculta.
func test_raising_reveals_reflection_layer() -> void:
	assert_false(_view.get_cull_mask_value(REVEAL_LAYER), "A simple vista no se ve el reflejo")
	_camera.set_raised(true)
	assert_true(_view.get_cull_mask_value(REVEAL_LAYER), "Por el visor se ve el reflejo")
	_camera.set_raised(false)
	assert_false(_view.get_cull_mask_value(REVEAL_LAYER), "Al bajarla vuelve a ocultarse")


## Sin mirar por el visor no se puede disparar.
func test_cannot_shoot_without_raising() -> void:
	_camera.shoot()
	assert_true(_camera.film_remaining == _camera.film_capacity, "No debe gastar rollo")


## Cada foto gasta una del rollo y una carga de flash, y llega revelada.
func test_shot_spends_film_and_battery() -> void:
	_camera.set_raised(true)
	_camera.shoot()
	await _camera.photo_taken
	assert_true(_camera.film_remaining == _camera.film_capacity - 1, "Debe gastar una foto")
	assert_almost_eq(
		_camera.battery, _camera.max_battery - _camera.flash_cost, "Debe gastar una carga"
	)
	assert_true(_photos.size() == 1 and _photos[0].has_flash, "La foto debe llevar flash")


## Sin batería la foto sale sin flash y no descuenta nada más.
func test_no_flash_without_battery() -> void:
	_camera.battery = _camera.flash_cost / 2.0
	_camera.set_raised(true)
	_camera.shoot()
	await _camera.photo_taken
	assert_false(_photos[0].has_flash, "La foto no debe llevar flash")
	assert_almost_eq(_camera.battery, _camera.flash_cost / 2.0, "No debe gastar batería")


## Hay que esperar al flash entre una foto y otra.
func test_cooldown_blocks_quick_second_shot() -> void:
	_camera.cooldown = 1.0
	_camera.set_raised(true)
	_camera.shoot()
	_camera.shoot()
	assert_true(_camera.film_remaining == _camera.film_capacity - 1, "Solo debe tomar una foto")


## Con el rollo terminado ya no dispara.
func test_film_runs_out() -> void:
	_camera.film_remaining = 1
	_camera.set_raised(true)
	_camera.shoot()
	assert_true(_camera.film_remaining == 0, "Debe gastar la última foto")
	assert_false(_camera.can_shoot(), "Sin rollo no debe poder disparar")


## Sin rollo el obturador hace un clic seco: no hay foto ni ruido que el ente oiga.
func test_dry_fire_without_film() -> void:
	_camera.film_remaining = 0
	_camera.set_raised(true)
	_camera.shoot()
	await tree.process_frame
	assert_true(_photos.is_empty(), "No debe salir ninguna foto")
	assert_true(_camera.get_node("DryFire").playing, "Debe sonar el clic seco")


## Una foto con una pista en cuadro la guarda para el final.
func test_clue_in_frame_counts() -> void:
	GameState.reset()
	var subject := PhotoSubject.new()
	subject.clue_id = "prueba"
	_view.add_child(subject)
	subject.position = Vector3(0.0, 0.0, -2.0)
	_camera.set_raised(true)
	_camera.shoot()
	await _camera.photo_taken
	assert_true(GameState.clue_photos.has("prueba"), "Debe guardar la pista")
	GameState.reset()
