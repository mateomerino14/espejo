class_name NoteData
extends Resource
## Texto que Lucía encuentra: notas, cartas, recortes, registros o inscripciones.

## Identificador único, para recordar que ya se leyó.
@export var id := ""
@export var title := ""
## Quién la escribió y cuándo, si se sabe.
@export var signature := ""
@export_multiline var body := ""
