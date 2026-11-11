class_name Qispi
extends CharacterBody3D
## El Q'ispi: vive del otro lado del reflejo. Acecha, sigue los ruidos, caza a Lucía si la ve o
## si ella lo mira por el visor, y el flash lo aturde cada vez por menos tiempo.

## Cambió de estado: acecha, rastrea, caza o está aturdido.
signal state_changed(new_state: State)

enum State { STALK, TRACK, HUNT, STUNNED }

const GROUP := &"enemies"
const HORIZONTAL_PLANE := Vector3(1.0, 0.0, 1.0)
const ARRIVAL_DISTANCE := 0.7
const CATCH_DISTANCE := 1.0
const TURN_SPEED := 6.0
const LOOK_AROUND_SPEED := 1.4
const RETARGET_DISTANCE := 0.5
## Mundo y puertas: lo que tapa la vista.
const WORLD_MASK := 17

@export_group("Velocidades (m/s)")
@export var stalk_speed := 1.0
@export var track_speed := 1.8
@export var hunt_speed := 3.6
@export var acceleration := 12.0

@export_group("Acecho")
## Radio alrededor de su punto de inicio por el que deambula.
@export var wander_radius := 6.0
@export var wander_wait_seconds := 2.0

@export_group("Tiempos (s)")
@export var track_look_seconds := 3.0
@export var lose_sight_seconds := 2.5

@export_group("Flash")
@export var flash_range := 7.0
@export_range(5.0, 90.0) var flash_angle_degrees := 30.0
@export var stun_seconds := 3.0
## Cada flash lo aturde esta fracción del anterior: se acostumbra durante la noche.
@export_range(0.1, 1.0) var stun_resistance := 0.7
@export var min_stun_seconds := 0.8

@export_group("Visor")
## Si Lucía lo mira por el visor a esta distancia o menos, se da cuenta.
@export var watched_range := 10.0

var state := State.STALK

var _player: Player
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _home := Transform3D.IDENTITY
var _state_timer := 0.0
var _unseen_time := 0.0
var _is_waiting := false
var _has_caught := false
var _is_camera_raised := false
var _last_known_position := Vector3.ZERO
var _move_target := Vector3.ZERO
var _move_speed := 0.0
var _stun_duration := 0.0

@onready var _agent: NavigationAgent3D = $NavigationAgent3D
@onready var _hearing: NoiseHearing = $NoiseHearing
@onready var _sight: PlayerSight = $Eyes
@onready var _stride_audio: StrideAudio = $StrideAudio
@onready var _animator: QispiAnimator = $Model
@onready var _shriek: AudioStreamPlayer3D = $Shriek
@onready var _face_light: OmniLight3D = $FaceLight


## Busca a Lucía, escucha el mundo y empieza a acechar.
func _ready() -> void:
	_home = global_transform
	_stun_duration = stun_seconds
	_player = get_tree().get_first_node_in_group(Player.GROUP) as Player
	_hearing.heard.connect(_on_heard)
	EventBus.flash_fired.connect(_on_flash_fired)
	EventBus.camera_raised.connect(_on_camera_raised)
	_enter_state(State.STALK)


## Actualiza el estado, avanza por el camino y revisa si alcanzó a Lucía.
func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	if _has_caught:
		_move_speed = 0.0
	else:
		_update_state(delta)
	_follow_path(delta)
	var previous_position := global_position
	move_and_slide()
	var travelled := (global_position - previous_position) * HORIZONTAL_PLANE
	_stride_audio.register_movement(travelled.length(), travelled.length() / delta)
	_animator.register_movement(travelled.length() / delta)
	_check_catch()


## Vuelve a su lugar y a acechar; se usa al reaparecer Lucía. No olvida los flashes.
func reset() -> void:
	global_transform = _home
	velocity = Vector3.ZERO
	_has_caught = false
	_face_light.visible = false
	_animator.reset()
	_enter_state(State.STALK)


## Despierta al ente dormido: desde ahora acecha, oye y caza.
func wake() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	_enter_state(State.STALK)


## Posición de su cara, a donde mira Lucía al ser atrapada.
func get_face_position() -> Vector3:
	return _animator.get_face_position()


## Deriva a la lógica del estado actual.
func _update_state(delta: float) -> void:
	match state:
		State.STALK:
			_update_stalk(delta)
		State.TRACK:
			_update_track(delta)
		State.HUNT:
			_update_hunt(delta)
		State.STUNNED:
			_update_stunned(delta)


## Deambula cerca de su lugar, con pausas, hasta notar a Lucía.
func _update_stalk(delta: float) -> void:
	if _notices_player():
		_enter_state(State.HUNT)
		return
	if _is_waiting:
		_state_timer -= delta
		if _state_timer <= 0.0:
			_is_waiting = false
			_go_to(_random_point_near(_home.origin), stalk_speed)
	elif _has_arrived():
		_is_waiting = true
		_state_timer = wander_wait_seconds
		_move_speed = 0.0


## Va hacia lo último que supo, mira alrededor y, si no encuentra nada, vuelve a acechar.
func _update_track(delta: float) -> void:
	if _notices_player():
		_enter_state(State.HUNT)
		return
	if _has_arrived():
		_move_speed = 0.0
		rotation.y += LOOK_AROUND_SPEED * delta
		_state_timer -= delta
		if _state_timer <= 0.0:
			_enter_state(State.STALK)


## Corre hacia Lucía; si la pierde un rato, va a rastrear donde la vio por última vez.
func _update_hunt(delta: float) -> void:
	if _notices_player():
		_unseen_time = 0.0
		_last_known_position = _player.global_position
	else:
		_unseen_time += delta
		if _unseen_time >= lose_sight_seconds:
			_enter_state(State.TRACK)
			return
	_go_to(_last_known_position, hunt_speed)


## Se retuerce quieto; al pasarse va a buscar a Lucía donde estaba.
func _update_stunned(delta: float) -> void:
	_move_speed = 0.0
	_state_timer -= delta
	if _state_timer <= 0.0:
		_animator.set_stunned(false)
		_last_known_position = _player.global_position
		_enter_state(State.TRACK)


## Cambia de estado y prepara lo que necesita al empezar.
func _enter_state(new_state: State) -> void:
	state = new_state
	_hearing.enabled = state != State.STUNNED
	_sight.enabled = state != State.STUNNED
	match state:
		State.STALK:
			_is_waiting = false
			_go_to(_random_point_near(_home.origin), stalk_speed)
		State.TRACK:
			_state_timer = track_look_seconds
			_go_to(_last_known_position, track_speed)
		State.HUNT:
			_unseen_time = 0.0
		State.STUNNED:
			_state_timer = _stun_duration
			_stun_duration = maxf(_stun_duration * stun_resistance, min_stun_seconds)
			_animator.set_stunned(true)
			_shriek.play()
	state_changed.emit(state)


## Dice si sabe dónde está Lucía: porque la ve o porque ella lo mira por el visor.
func _notices_player() -> bool:
	return _sight.can_see(_player) or _is_watched()


## Dice si Lucía lo está mirando por el visor: cerca, en cuadro y sin nada en medio.
func _is_watched() -> bool:
	if not _is_camera_raised or _player == null:
		return false
	var camera := get_viewport().get_camera_3d()
	var face := get_face_position()
	if camera == null or camera.global_position.distance_to(face) > watched_range:
		return false
	return camera.is_position_in_frustum(face) and _has_clear_line(camera.global_position, face)


## Dice si no hay nada sólido entre los dos puntos.
func _has_clear_line(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, WORLD_MASK)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Fija el destino y la velocidad; no recalcula el camino por cambios mínimos.
func _go_to(target: Vector3, speed: float) -> void:
	_move_speed = speed
	if target.distance_to(_move_target) > RETARGET_DISTANCE or _agent.is_navigation_finished():
		_move_target = target
		_agent.target_position = target


## Dice si llegó al destino, o al punto más cercano si el destino no tiene camino.
func _has_arrived() -> bool:
	var offset := (_move_target - global_position) * HORIZONTAL_PLANE
	if offset.length() <= ARRIVAL_DISTANCE:
		return true
	return _agent.is_navigation_finished() and not _agent.is_target_reachable()


## Avanza hacia el siguiente punto del camino y gira hacia donde va.
func _follow_path(delta: float) -> void:
	var desired := Vector3.ZERO
	if _move_speed > 0.0 and not _has_arrived():
		var next_point := _agent.get_next_path_position()
		var direction := ((next_point - global_position) * HORIZONTAL_PLANE).normalized()
		desired = direction * _move_speed
		if direction != Vector3.ZERO:
			rotation.y = lerp_angle(
				rotation.y, atan2(-direction.x, -direction.z), TURN_SPEED * delta
			)
	velocity.x = move_toward(velocity.x, desired.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired.z, acceleration * delta)


## Aplica la gravedad mientras está en el aire.
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta


## Avisa una sola vez si alcanzó a Lucía; aturdido no atrapa.
func _check_catch() -> void:
	if _has_caught or state == State.STUNNED or _player == null:
		return
	var offset := (_player.global_position - global_position) * HORIZONTAL_PLANE
	if offset.length() <= CATCH_DISTANCE:
		_has_caught = true
		if offset != Vector3.ZERO:
			rotation.y = atan2(-offset.x, -offset.z)
		_animator.play_catch()
		# Una luz fría solo en la embestida, para que su cara se vea en el susto.
		_face_light.visible = true
		EventBus.player_caught.emit()


## Devuelve un punto caminable al azar cerca del indicado; sin mapa listo, el mismo punto.
func _random_point_near(center: Vector3) -> Vector3:
	var map := _agent.get_navigation_map()
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return center
	var offset := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * wander_radius
	return NavigationServer3D.map_get_closest_point(map, center + offset)


## Va hacia el ruido: si acechaba, a rastrear; si cazaba sin verla, actualiza dónde buscar.
## Dormido no oye nada.
func _on_heard(origin: Vector3, _strength: float) -> void:
	if not can_process():
		return
	match state:
		State.STALK, State.TRACK:
			_last_known_position = origin
			_enter_state(State.TRACK)
		State.HUNT:
			_last_known_position = origin


## Recuerda si Lucía mira por el visor.
func _on_camera_raised(is_raised: bool) -> void:
	_is_camera_raised = is_raised


## Queda aturdido si el destello le da en la cara de cerca y sin nada en medio; dormido no.
func _on_flash_fired(origin: Vector3, direction: Vector3) -> void:
	if not can_process() or _has_caught or state == State.STUNNED:
		return
	var face := get_face_position()
	if origin.distance_to(face) > flash_range:
		return
	if direction.angle_to(face - origin) > deg_to_rad(flash_angle_degrees) / 2.0:
		return
	if _has_clear_line(origin, face):
		_enter_state(State.STUNNED)
