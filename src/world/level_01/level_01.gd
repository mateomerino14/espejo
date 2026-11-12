class_name Level01
extends Node3D
## Nivel 1, la llegada: el hostal de sal de noche. Al leer la nota de Javier despierta el Q'ispi, y
## cada ofrenda en la apacheta guarda la partida.

## Nota que despierta al ente.
@export var wake_note: NoteData
## El Q'ispi, dormido hasta que Lucía lee la nota.
@export var qispi: Qispi


## Restaura la partida guardada o empieza una limpia, guarda y espera la nota del ente.
func _ready() -> void:
	GameState.reset()
	if SaveGame.has_pending():
		SaveGame.restore_state(SaveGame.take_pending())
	SaveGame.save(scene_file_path)
	EventBus.note_opened.connect(_on_note_opened)
	EventBus.offering_made.connect(_on_offering_made)


## Si Lucía leyó la nota de Javier, el Q'ispi despierta.
func _on_note_opened(note: NoteData) -> void:
	if note.id == wake_note.id and qispi.process_mode == Node.PROCESS_MODE_DISABLED:
		qispi.wake()


## Cada ofrenda guarda la partida.
func _on_offering_made(_origin: Vector3) -> void:
	SaveGame.save(scene_file_path)
