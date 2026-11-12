class_name GameLevel
extends Node3D
## Base de los niveles: al empezar restaura la partida si se eligió continuar y la guarda; también
## la guarda con cada ofrenda. Lo que se juntó en niveles anteriores sigue en GameState.


## Restaura lo pendiente, guarda y escucha las ofrendas.
func _ready() -> void:
	if SaveGame.has_pending():
		SaveGame.restore_state(SaveGame.take_pending())
	SaveGame.save(scene_file_path)
	EventBus.offering_made.connect(_on_offering_made)


## Cada ofrenda guarda la partida.
func _on_offering_made(_origin: Vector3) -> void:
	SaveGame.save(scene_file_path)
