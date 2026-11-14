class_name Level02
extends GameLevel
## Nivel 2, el hostal vacío: Lucía vuelve y no hay nadie. El Q'ispi sale de los espejos destapados;
## al taparlos todos, la puerta principal se abre.

const LEFT_NOTICE := "Espejos sin tapar: %d"
const DONE_NOTICE := "Tapaste todos los espejos. La puerta principal ya no está trabada."
const DONE_OBJECTIVE := "Sal del hostal por la puerta principal"

@export var front_door: CardonDoor
## Nodo cuyos hijos son los espejos que hay que tapar.
@export var mirrors_root: Node

var _mirrors: Array[Mirror] = []


## Deja tapados los que ya se taparon y escucha los que faltan.
func _ready() -> void:
	super()
	for child in mirrors_root.get_children():
		var mirror := child as Mirror
		_mirrors.append(mirror)
		if GameState.covered_mirrors.has(mirror.name):
			mirror.restore_cover()
		mirror.covered.connect(_on_mirror_covered.bind(mirror))
	front_door.is_locked = uncovered_count() > 0


## Cuántos espejos quedan sin tapar.
func uncovered_count() -> int:
	var count := 0
	for mirror in _mirrors:
		if not mirror.is_covered:
			count += 1
	return count


## Recuerda el espejo tapado, avisa cuántos faltan y, con el último, abre la puerta y da el
## objetivo de salir.
func _on_mirror_covered(mirror: Mirror) -> void:
	GameState.mark_mirror_covered(mirror.name)
	var left := uncovered_count()
	if left > 0:
		EventBus.notice_requested.emit(LEFT_NOTICE % left)
		return
	front_door.is_locked = false
	EventBus.notice_requested.emit(DONE_NOTICE)
	GameState.set_objective(DONE_OBJECTIVE)
