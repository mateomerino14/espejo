class_name Level01
extends GameLevel
## Nivel 1, la llegada: el hostal de sal de noche. Al leer la nota de Javier despierta el Q'ispi.

const OUT_OBJECTIVE := "Javier no está. Sal del hostal por la puerta del comedor"

## Nota que despierta al ente.
@export var wake_note: NoteData
## El Q'ispi, dormido hasta que Lucía lee la nota.
@export var qispi: Qispi


## Prepara la partida y espera la nota del ente.
func _ready() -> void:
	super()
	EventBus.note_opened.connect(_on_note_opened)


## Si Lucía leyó la nota de Javier, el Q'ispi despierta y el objetivo pasa a salir del hostal.
func _on_note_opened(note: NoteData) -> void:
	if note.id == wake_note.id and qispi.process_mode == Node.PROCESS_MODE_DISABLED:
		qispi.wake()
		GameState.set_objective(OUT_OBJECTIVE)
