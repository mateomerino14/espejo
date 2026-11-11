class_name FootstepSurface
extends Area3D
## Zona del piso que cambia cómo suenan los pasos: tierra, madera o agua sobre el suelo de sal.

## El piso del salar, cuando no hay ninguna zona.
const SALT := &"sal"
## Capa de física donde viven estas zonas, para que los pasos las encuentren.
const PHYSICS_LAYER := 32

@export_enum("sal", "tierra", "madera", "agua") var surface: String = "tierra"


## Deja la zona en su capa propia y sin detectar nada por su cuenta.
func _ready() -> void:
	collision_layer = PHYSICS_LAYER
	collision_mask = 0
	monitoring = false
