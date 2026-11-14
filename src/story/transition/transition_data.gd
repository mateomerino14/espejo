class_name TransitionData
extends Resource
## Lo que cuenta un tránsito entre niveles: qué dice Lucía, a qué hora y qué se ve en el horizonte.

## Qué hay en el horizonte, detrás de Lucía.
enum Horizon { NONE, TRAINS, ISLAND }

## Lo que dice Lucía mientras cruza el salar.
@export var line_audio: AudioStream
@export_multiline var line_text := ""
## Si llueve, como al salir del hostal.
@export var has_rain := false
## Si ya amanece, como en el último cruce.
@export var is_dawn := false
@export var horizon := Horizon.NONE
## Si Lucía va en el bote de Don Celestino en vez de caminar.
@export var is_boat := false
## Si en el reflejo del agua, y solo ahí, el Q'ispi la sigue.
@export var shows_qispi := false
