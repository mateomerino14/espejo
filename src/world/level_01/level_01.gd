class_name Level01
extends Node3D
## Nivel 1, la llegada: el hostal de sal de noche. Al leer la nota de Javier despierta el Q'ispi.

## Nota que despierta al ente.
@export var wake_note: NoteData
## El Q'ispi, dormido hasta que Lucía lee la nota.
@export var qispi: Qispi


## Empieza una partida limpia y espera la nota que despierta al ente.
func _ready() -> void:
	GameState.reset()
	EventBus.note_opened.connect(_on_note_opened)


## Si Lucía leyó la nota de Javier, el Q'ispi despierta.
func _on_note_opened(note: NoteData) -> void:
	if note.id == wake_note.id and qispi.process_mode == Node.PROCESS_MODE_DISABLED:
		qispi.wake()
