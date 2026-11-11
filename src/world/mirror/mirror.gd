class_name Mirror
extends Node3D
## Espejo plano: una cámara puesta en el reflejo del ojo mira a través del marco del espejo y
## dibuja también la capa del reflejo, donde vive el ente.

## Por debajo de esta distancia al vidrio no se actualiza el reflejo.
const MIN_EYE_DISTANCE := 0.01
## Giro que hace mirar a la cámara del reflejo hacia el frente del espejo.
const FACING_FRONT := Basis(Vector3.UP, PI)
## Ancho del marco alrededor del vidrio y grosor de la madera.
const FRAME_BORDER := 0.06
const FRAME_DEPTH := 0.04
## Separación entre el vidrio y la madera, para que no parpadeen.
const GLASS_GAP := 0.005

## Ancho y alto del vidrio en metros; el vidrio mira hacia +Z.
@export var size := Vector2(1.0, 1.6)
## Alto en píxeles de la imagen del reflejo.
@export var resolution := 720
@export var far := 40.0

@onready var _surface: MeshInstance3D = $Surface
@onready var _frame: CSGBox3D = $Frame
@onready var _viewport: SubViewport = $Reflection
@onready var _camera: Camera3D = $Reflection/Camera3D


## Ajusta el vidrio, el marco y la imagen al tamaño del espejo.
func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size = size
	_surface.mesh = quad
	_frame.size = Vector3(size.x + FRAME_BORDER * 2.0, size.y + FRAME_BORDER * 2.0, FRAME_DEPTH)
	_frame.position.z = -FRAME_DEPTH / 2.0 - GLASS_GAP
	_viewport.size = Vector2i(roundi(resolution * size.x / size.y), resolution)
	var material := _surface.material_override as ShaderMaterial
	material.set_shader_parameter("reflection", _viewport.get_texture())


## Sigue al ojo de quien mira.
func _process(_delta: float) -> void:
	var eye := get_viewport().get_camera_3d()
	if eye:
		update_reflection(eye.global_position)


## Pone la cámara del reflejo en el ojo reflejado, con el vidrio como plano cercano.
func update_reflection(eye: Vector3) -> void:
	var local_eye := global_transform.affine_inverse() * eye
	var is_in_front := local_eye.z > MIN_EYE_DISTANCE
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if not is_in_front:
		return
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var reflected := Vector3(local_eye.x, local_eye.y, -local_eye.z)
	_camera.global_transform = global_transform * Transform3D(FACING_FRONT, reflected)
	_camera.set_frustum(size.y, Vector2(local_eye.x, -local_eye.y), local_eye.z, far)
