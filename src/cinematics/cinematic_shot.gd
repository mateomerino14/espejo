class_name CinematicShot
extends Node3D
## Un plano de una cinemática: la cámara va de From a To mientras dura, con un subtítulo opcional y
## un momento que la escena puede usar para mover a los personajes.

@export var duration := 4.0
@export var fov := 50.0
## Texto en pantalla durante el plano: un diálogo, o el lugar y la fecha.
@export_multiline var subtitle := ""
## Nombre del momento que empieza con este plano; la escena decide qué pasa.
@export var cue: StringName
## Si se asigna, la cámara le apunta todo el plano en vez de seguir el giro de los marcadores.
@export var look_target: Node3D

@onready var _from: Marker3D = $From
@onready var _to: Marker3D = $To


## Dónde está la cámara en [param progress], de 0 (inicio del plano) a 1 (final).
func camera_transform(progress: float) -> Transform3D:
	var eased := smoothstep(0.0, 1.0, progress)
	var view := _from.global_transform.interpolate_with(_to.global_transform, eased)
	if look_target:
		view = view.looking_at(look_target.global_position, Vector3.UP)
	return view
