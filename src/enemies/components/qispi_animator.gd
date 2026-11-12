class_name QispiAnimator
extends Node3D
## Anima al Q'ispi: quieto, acechando o corriendo según su rapidez, retorciéndose aturdido y la
## embestida al atrapar. También deja su cuerpo en la capa del reflejo.

const IDLE := &"idle"
const WALK := &"walk"
const RUN := &"run"
const STUNNED := &"stunned"
const CATCH := &"catch"
const LOOPING: Array[StringName] = [IDLE, WALK, RUN, STUNNED]
const NORMAL_SPEED := 1.0
const HEAD_BONE := &"head"
## Distancia desde la base del hueso de la cabeza hasta los ojos.
const EYES_ALONG_HEAD := 0.14
## La embestida y el aturdimiento entran más rápido que los demás cambios.
const SUDDEN_BLEND_RATIO := 0.4

## Capas de render del cuerpo: por defecto solo la del reflejo.
@export_flags_3d_render var render_layers := 1024
## Si su cuerpo invisible proyecta sombra a simple vista.
@export var casts_shadow := false
## Por debajo de esta rapidez se queda quieto.
@export var idle_below_speed := 0.25
## Desde esta rapidez corre en vez de acechar.
@export var run_from_speed := 2.6
## Metros que avanza en un ciclo de acecho a velocidad normal.
@export var walk_stride := 1.6
## Metros que avanza en un ciclo de carrera a velocidad normal.
@export var run_stride := 3.0
## Segundos de mezcla al cambiar de animación.
@export var blend_seconds := 0.25

var _player: AnimationPlayer
var _skeleton: Skeleton3D
var _head_bone := -1
var _is_locked := false


## Busca el reproductor y el esqueleto, deja en bucle lo que se repite y pasa el cuerpo al reflejo.
func _ready() -> void:
	_player = find_children("*", "AnimationPlayer", true, false).front() as AnimationPlayer
	_skeleton = find_children("*", "Skeleton3D", true, false).front() as Skeleton3D
	_head_bone = _skeleton.find_bone(HEAD_BONE)
	for animation_name in LOOPING:
		_player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		mesh.layers = render_layers
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if casts_shadow:
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_player.play(IDLE)


## Elige la animación según la rapidez y ajusta su velocidad para que los pies no patinen.
func register_movement(speed: float) -> void:
	if _is_locked:
		return
	if speed < idle_below_speed:
		_play(IDLE, NORMAL_SPEED)
	elif speed < run_from_speed:
		_play(WALK, speed / _natural_speed(WALK, walk_stride))
	else:
		_play(RUN, speed / _natural_speed(RUN, run_stride))


## Posición de los ojos en el mundo, siguiendo a la cabeza animada.
func get_face_position() -> Vector3:
	var head := _skeleton.global_transform * _skeleton.get_bone_global_pose(_head_bone)
	return head.origin + head.basis.y.normalized() * EYES_ALONG_HEAD


## Se retuerce mientras dura el aturdimiento; al terminar vuelve a moverse normal.
func set_stunned(is_stunned: bool) -> void:
	_is_locked = is_stunned
	if is_stunned:
		_play_sudden(STUNNED)


## Lanza la embestida y se queda en ella hasta que lo reinicien.
func play_catch() -> void:
	_is_locked = true
	_play_sudden(CATCH)


## Vuelve a la pose quieta; se usa al reaparecer Lucía.
func reset() -> void:
	_is_locked = false
	_player.speed_scale = NORMAL_SPEED
	_player.play(IDLE)


## Cambia de golpe a una animación, a velocidad normal.
func _play_sudden(animation_name: StringName) -> void:
	_player.speed_scale = NORMAL_SPEED
	_player.play(animation_name, blend_seconds * SUDDEN_BLEND_RATIO)


## Cambia de animación con mezcla solo si es otra, y ajusta su velocidad.
func _play(animation_name: StringName, speed_scale: float) -> void:
	if _player.current_animation != animation_name:
		_player.play(animation_name, blend_seconds)
	_player.speed_scale = speed_scale


## Metros por segundo que cubre la animación a velocidad normal.
func _natural_speed(animation_name: StringName, stride: float) -> float:
	return stride / _player.get_animation(animation_name).length
