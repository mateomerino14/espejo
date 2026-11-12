class_name FootprintTrail
extends Node3D
## Huellas mojadas del Q'ispi: aparecen en el piso a cada paso, aunque a él no se lo vea, y se
## secan de a poco.

## Huellas a la vez; las más viejas se reusan.
@export var max_prints := 30
@export var print_size := Vector3(0.18, 0.3, 0.38)
## Separación de cada pie respecto del centro.
@export var foot_spacing := 0.15
## Lo que tarda una huella en secarse.
@export var dry_seconds := 25.0
@export var texture: Texture2D

var _prints: Array[Decal] = []
var _next := 0
var _is_left := true


## Prepara las huellas, todas secas al principio.
func _ready() -> void:
	for i in max_prints:
		var footprint := Decal.new()
		footprint.texture_albedo = texture
		footprint.size = print_size
		footprint.visible = false
		footprint.top_level = true
		add_child(footprint)
		_prints.append(footprint)


## Deja una huella debajo, alternando los pies, mirando hacia donde camina.
func place() -> void:
	var footprint := _prints[_next]
	_next = (_next + 1) % _prints.size()
	var side := foot_spacing
	if _is_left:
		side = -foot_spacing
	_is_left = not _is_left
	var heading := global_basis.get_euler().y
	var where := global_position + global_basis.x * side
	footprint.global_transform = Transform3D(Basis(Vector3.UP, heading), where)
	footprint.modulate.a = 1.0
	footprint.visible = true
	create_tween().tween_property(footprint, "modulate:a", 0.0, dry_seconds)
