class_name DialogueLine
extends Resource
## Una línea que dice un personaje: el texto del subtítulo y su voz grabada.

## Segundos de lectura por letra, para las líneas que no tienen voz.
const SECONDS_PER_LETTER := 0.06
const MIN_SECONDS := 2.0

@export_multiline var text := ""
@export var voice: AudioStream


## Cuánto dura la línea: lo que dura la voz, o lo que se tarda en leerla.
func get_seconds() -> float:
	if voice:
		return voice.get_length()
	return maxf(text.length() * SECONDS_PER_LETTER, MIN_SECONDS)
