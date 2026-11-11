class_name Player
extends CharacterBody3D
## Lucía: lee la entrada, ordena a sus componentes y publica eventos en EventBus.

enum MoveState { IDLE, WALK, SPRINT, CROUCH }

## Grupo declarado en player.tscn; así el ente la encuentra aunque esté antes en el árbol.
const GROUP := &"player"
const HORIZONTAL_PLANE := Vector3(1.0, 0.0, 1.0)
const CROUCH_HEIGHT_TOLERANCE := 0.05
## Distancia que se deja entre la cabeza y la pared al asomarse.
const LEAN_WALL_MARGIN := 0.2

@export_group("Velocidades (m/s)")
@export var walk_speed := 2.4
@export var sprint_speed := 4.6
@export var crouch_speed := 1.2

## Fracción de la velocidad que conserva mientras mira por el visor.
@export_range(0.1, 1.0) var raised_speed_scale := 0.55

@export_group("Aceleración")
@export var acceleration := 10.0
@export var deceleration := 14.0
@export var air_control := 0.3

@export_group("Agacharse")
@export var stand_height := 1.7
@export var crouch_height := 1.1
## Distancia desde los ojos hasta la coronilla.
@export var eye_offset := 0.12
@export var crouch_transition_speed := 9.0

## Falso: hay que mantener la tecla. Verdadero: se alterna con cada pulsación. Viene de Settings.
var crouch_toggles := false
var move_state := MoveState.IDLE

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _capsule: CapsuleShape3D
var _is_crouch_requested := false
var _controls_enabled := true

@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _ceiling_check: ShapeCast3D = $CeilingCheck
@onready var _head: FirstPersonCamera = $Head
@onready var _stamina: StaminaComponent = $StaminaComponent
@onready var _footsteps: FootstepComponent = $FootstepComponent
@onready var _lean_check: RayCast3D = $LeanCheck
@onready var _photo_camera: PhotoCamera = $Head/Camera3D/PhotoCamera
@onready var _caught_reaction: CaughtReaction = $CaughtReaction
@onready var _interactor: Interactor = $Head/Camera3D/Interactor


## Prepara la cápsula, conecta los componentes y pone a Lucía de pie.
func _ready() -> void:
	_capsule = _collision.shape as CapsuleShape3D
	Settings.changed.connect(_apply_settings)
	_apply_settings()
	_connect_components()
	_apply_height(stand_height)
	_head.position.y = stand_height - eye_offset


## Atiende las acciones de una sola pulsación: usar lo que hay al frente y disparar la cámara.
func _unhandled_input(event: InputEvent) -> void:
	if not _controls_enabled:
		return
	if crouch_toggles and event.is_action_pressed("crouch"):
		_is_crouch_requested = not _is_crouch_requested
	elif event.is_action_pressed("interact"):
		_interactor.try_interact(self)
	elif event.is_action_pressed("camera_shoot") and _is_mouse_captured():
		_photo_camera.shoot()


## Mueve a Lucía y alimenta a la cabeza, el aliento y los pasos.
func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	var lean := 0.0
	if _controls_enabled:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		lean = Input.get_axis("lean_left", "lean_right")
		if not crouch_toggles:
			_is_crouch_requested = Input.is_action_pressed("crouch")
		_photo_camera.set_raised(Input.is_action_pressed("camera_raise"))
	_update_crouch(delta)
	_update_move_state(input_dir)
	_stamina.set_draining(move_state == MoveState.SPRINT)

	var previous_position := global_position
	_apply_gravity(delta)
	_apply_movement(input_dir, delta)
	move_and_slide()

	var travelled := (global_position - previous_position) * HORIZONTAL_PLANE
	_footsteps.register_movement(travelled.length(), move_state, global_position)
	_head.update_bob(delta, _horizontal_speed() / walk_speed, is_on_floor())
	if move_state == MoveState.SPRINT:
		lean = 0.0
	_head.update_lean(delta, lean, _free_space_to_side(lean))
	_interactor.update_focus(self)


## Activa o desactiva la entrada, por ejemplo mientras la atrapan.
func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled
	_head.look_enabled = enabled


## Lleva a Lucía al punto indicado, de pie, quieta, con aliento lleno y la cámara abajo.
func respawn_at(spawn: Transform3D) -> void:
	_caught_reaction.reset()
	_photo_camera.reset()
	global_transform = spawn
	velocity = Vector3.ZERO
	_is_crouch_requested = false
	_apply_height(stand_height)
	_head.reset_look()
	_stamina.refill()


## Devuelve la posición de los ojos, que es lo que el ente intenta ver.
func get_eye_position() -> Vector3:
	return _head.global_position


## Dice si la cápsula está por debajo de la altura de pie.
func is_crouching() -> bool:
	return _capsule.height < stand_height - CROUCH_HEIGHT_TOLERANCE


## Reenvía las señales de los componentes al bus y publica su estado inicial.
func _connect_components() -> void:
	_stamina.changed.connect(EventBus.stamina_changed.emit)
	_photo_camera.raised_changed.connect(EventBus.camera_raised.emit)
	_photo_camera.battery_changed.connect(EventBus.camera_battery_changed.emit)
	_photo_camera.film_changed.connect(EventBus.film_changed.emit)
	_photo_camera.photo_taken.connect(EventBus.photo_taken.emit)
	_photo_camera.flash_fired.connect(EventBus.flash_fired.emit)
	_interactor.focus_changed.connect(EventBus.interaction_prompt_changed.emit)
	# Los componentes emitieron su estado en su _ready, que corre antes que este.
	EventBus.stamina_changed.emit(_stamina.current, _stamina.max_stamina)
	EventBus.camera_battery_changed.emit(_photo_camera.battery, _photo_camera.max_battery)
	EventBus.film_changed.emit(_photo_camera.film_remaining, _photo_camera.film_capacity)


## Elige quieto, caminar, correr o agachada según la entrada y el aliento.
func _update_move_state(input_dir: Vector2) -> void:
	var new_state := MoveState.WALK
	if input_dir == Vector2.ZERO:
		new_state = MoveState.IDLE
	elif _is_crouch_requested or is_crouching():
		new_state = MoveState.CROUCH
	elif _can_sprint(input_dir):
		new_state = MoveState.SPRINT
	move_state = new_state


## Dice si puede correr: pide correr hacia adelante, le queda aliento y no mira por el visor.
func _can_sprint(input_dir: Vector2) -> bool:
	return (
		Input.is_action_pressed("sprint")
		and input_dir.y < 0.0
		and _stamina.can_sprint()
		and not _photo_camera.is_raised
	)


## Devuelve la velocidad máxima del estado actual, más lenta mirando por el visor.
func _speed_for_state() -> float:
	var speed := walk_speed
	match move_state:
		MoveState.SPRINT:
			speed = sprint_speed
		MoveState.CROUCH:
			speed = crouch_speed
	if _photo_camera.is_raised:
		speed *= raised_speed_scale
	return speed


## Aplica la gravedad mientras está en el aire.
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta


## Acelera hacia la dirección pedida, con menos control en el aire.
func _apply_movement(input_dir: Vector2, delta: float) -> void:
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var target := direction * _speed_for_state()
	var rate := deceleration
	if direction != Vector3.ZERO:
		rate = acceleration
	if not is_on_floor():
		rate *= air_control
	velocity.x = move_toward(velocity.x, target.x, rate * delta)
	velocity.z = move_toward(velocity.z, target.z, rate * delta)


## Agacha o levanta a Lucía; no se levanta si hay techo encima.
func _update_crouch(delta: float) -> void:
	var target_height := crouch_height
	if not _is_crouch_requested and not _ceiling_check.is_colliding():
		target_height = stand_height
	_apply_height(lerpf(_capsule.height, target_height, crouch_transition_speed * delta))
	_head.set_target_height(target_height - eye_offset)


## Ajusta la cápsula para que sus pies sigan en el suelo.
func _apply_height(height: float) -> void:
	_capsule.height = height
	_collision.position.y = height / 2.0


## Devuelve la rapidez en el plano del suelo.
func _horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


## Devuelve cuánto puede asomarse hacia ese lado antes de tocar la pared.
func _free_space_to_side(direction: float) -> float:
	if direction == 0.0:
		return _head.lean_distance
	_lean_check.position.y = _head.position.y
	_lean_check.target_position = Vector3(
		signf(direction) * (_head.lean_distance + LEAN_WALL_MARGIN), 0, 0
	)
	_lean_check.force_raycast_update()
	if not _lean_check.is_colliding():
		return _head.lean_distance
	var distance := _lean_check.global_position.distance_to(_lean_check.get_collision_point())
	return maxf(distance - LEAN_WALL_MARGIN, 0.0)


## Dice si el ratón está capturado, para no disparar al volver a la ventana.
func _is_mouse_captured() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


## Toma la sensibilidad y el modo de agacharse de los ajustes guardados.
func _apply_settings() -> void:
	crouch_toggles = Settings.crouch_toggles
	_head.sensitivity_scale = Settings.mouse_sensitivity
