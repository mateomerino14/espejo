class_name Mirror
extends Node3D
## Espejo plano: una cámara puesta en el reflejo del ojo mira a través del marco del espejo y
## dibuja también la capa del reflejo, donde vive el ente. Algunos se pueden tapar con una manta.

## Lo taparon.
signal covered

## Por debajo de esta distancia al vidrio no se actualiza el reflejo.
const MIN_EYE_DISTANCE := 0.01
## Giro que hace mirar a la cámara del reflejo hacia el frente del espejo.
const FACING_FRONT := Basis(Vector3.UP, PI)
## Ancho del marco alrededor del vidrio y grosor de la madera.
const FRAME_BORDER := 0.06
const FRAME_DEPTH := 0.04
## Separación entre el vidrio y la madera, para que no parpadeen.
const GLASS_GAP := 0.005
const GROUP := &"mirrors"
const COVER_PROMPT := "Tapar el espejo con una manta"
## La manta cuelga un poco más grande que el marco y apenas por delante.
const COVER_MARGIN := 0.08
const COVER_DEPTH := 0.03

## Ancho y alto del vidrio en metros; el vidrio mira hacia +Z.
@export var size := Vector2(1.0, 1.6)
## Alto en píxeles de la imagen del reflejo.
@export var resolution := 720
@export var far := 40.0

@export_group("Mirarse")
## Si cuenta cuando Lucía se queda mirándose; el espejo del menú no cuenta.
@export var counts_stares := true
## Quedarse este tiempo mirándolo de cerca cuenta como mirarse.
@export var stare_seconds := 3.0
@export var stare_distance := 2.2
@export_range(5.0, 60.0) var stare_angle_degrees := 22.0

@export_group("Manta")
## Si Lucía puede taparlo; los espejos del nivel 1 no.
@export var coverable := false
@export var is_covered := false

var _stare_time := 0.0
var _has_counted_stare := false

@onready var _surface: MeshInstance3D = $Surface
@onready var _frame: CSGBox3D = $Frame
@onready var _viewport: SubViewport = $Reflection
@onready var _camera: Camera3D = $Reflection/Camera3D
@onready var _cover: MeshInstance3D = $Cover
@onready var _interactable: Interactable = $Interactable
@onready var _cover_sound: AudioStreamPlayer3D = $CoverSound


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
	var cloth_size := Vector2(size.x + COVER_MARGIN * 2.0, size.y + COVER_MARGIN * 2.0)
	_cover.mesh = DrapedCloth.build(cloth_size, hash(name))
	_cover.position.z = COVER_DEPTH
	var reach := _interactable.get_child(0) as CollisionShape3D
	(reach.shape as BoxShape3D).size = Vector3(size.x, size.y, COVER_DEPTH * 10.0)
	_interactable.prompt = COVER_PROMPT
	_interactable.interacted.connect(_on_interacted)
	_show_cover()
	add_to_group(GROUP)


## Sigue al ojo de quien mira y cuenta si se queda mirándose.
func _process(delta: float) -> void:
	if is_covered:
		return
	var eye := get_viewport().get_camera_3d()
	if eye:
		update_reflection(eye.global_position)
		if counts_stares:
			_update_stare(eye, delta)


## Lo tapa con la manta: deja de reflejar y de contar miradas.
func cover() -> void:
	if is_covered:
		return
	is_covered = true
	_cover_sound.play()
	_show_cover()
	covered.emit()


## Lo deja tapado sin ruido ni aviso, como al continuar una partida.
func restore_cover() -> void:
	is_covered = true
	_show_cover()


## Dice si [param eye] mira el espejo de frente y de cerca.
func is_stared_at(eye: Camera3D) -> bool:
	var to_glass := global_position - eye.global_position
	if to_glass.length() > stare_distance:
		return false
	if (global_transform.affine_inverse() * eye.global_position).z <= MIN_EYE_DISTANCE:
		return false
	return (-eye.global_basis.z).angle_to(to_glass) <= deg_to_rad(stare_angle_degrees)


## Acumula el tiempo mirándolo; al pasar el límite cuenta una vez, hasta que mire a otro lado.
func _update_stare(eye: Camera3D, delta: float) -> void:
	if not is_stared_at(eye):
		_stare_time = 0.0
		_has_counted_stare = false
		return
	_stare_time += delta
	if _stare_time >= stare_seconds and not _has_counted_stare:
		_has_counted_stare = true
		GameState.add_mirror_stare()


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


## Muestra la manta y apaga el reflejo si está tapado; si no, deja tapar solo a los que se puede.
func _show_cover() -> void:
	_cover.visible = is_covered
	_interactable.enabled = coverable and not is_covered
	if is_covered:
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


## Lucía lo tapa.
func _on_interacted(_player: Player) -> void:
	cover()
