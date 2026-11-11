extends Node
## Estado de la partida (autoload "GameState"): las notas que Lucía ya leyó.

var read_notes := PackedStringArray()


## Recuerda que Lucía leyó una nota.
func mark_note_read(note_id: String) -> void:
	if not has_read_note(note_id):
		read_notes.append(note_id)


## Dice si Lucía ya leyó esa nota.
func has_read_note(note_id: String) -> bool:
	return read_notes.has(note_id)


## Vuelve al estado de una partida nueva.
func reset() -> void:
	read_notes.clear()
