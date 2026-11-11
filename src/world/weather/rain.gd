class_name Rain
extends GPUParticles3D
## Lluvia que cae siempre alrededor de la cámara activa, para no llenar todo el salar de gotas.

## La lluvia empieza a caer a esta altura sobre la cámara.
@export var height_above := 8.0


## Acompaña a la cámara.
func _process(_delta: float) -> void:
	var eye := get_viewport().get_camera_3d()
	if eye:
		global_position = eye.global_position + Vector3(0.0, height_above, 0.0)
