class_name WaterSurface
extends Node3D
## Agua quieta sobre el salar: refleja el cielo, las luces y también la capa del reflejo, donde vive
## el ente. Una cámara en el reflejo de la cámara activa dibuja lo que el agua devuelve.

## Lo que se ve reflejado: todo, incluida la capa del reflejo.
const ALL_LAYERS := 0xFFFFF

## Ancho y largo del agua en metros.
@export var size := Vector2(400.0, 400.0)
## Fracción de la resolución de la pantalla con la que se dibuja el reflejo.
@export_range(0.25, 1.0) var resolution_scale := 0.5
@export var far := 300.0

@onready var _surface: MeshInstance3D = $Surface
@onready var _viewport: SubViewport = $Reflection
@onready var _camera: Camera3D = $Reflection/Camera3D


## Arma la superficie y le pasa la imagen del reflejo.
func _ready() -> void:
	var plane := PlaneMesh.new()
	plane.size = size
	_surface.mesh = plane
	_camera.cull_mask = ALL_LAYERS
	_camera.far = far
	var material := _surface.material_override as ShaderMaterial
	material.set_shader_parameter("reflection", _viewport.get_texture())


## Sigue a la cámara activa.
func _process(_delta: float) -> void:
	var eye := get_viewport().get_camera_3d()
	if eye == null or eye == _camera:
		return
	var screen := get_viewport().get_visible_rect().size
	_viewport.size = Vector2i(
		roundi(screen.x * resolution_scale), roundi(screen.y * resolution_scale)
	)
	_camera.fov = eye.fov
	_camera.global_transform = reflect(eye.global_transform, global_position.y)


## Refleja una cámara en el plano horizontal a la altura [param height]. La imagen sale espejada
## de izquierda a derecha para que la cámara siga siendo una rotación válida; el agua la invierte.
static func reflect(view: Transform3D, height: float) -> Transform3D:
	var flip := Vector3(1.0, -1.0, 1.0)
	var turned := Basis(-view.basis.x * flip, view.basis.y * flip, view.basis.z * flip)
	var origin := view.origin * flip + Vector3(0.0, 2.0 * height, 0.0)
	return Transform3D(turned, origin)
