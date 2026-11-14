extends Node
## Estado de la partida (autoload "GameState"): las notas que Lucía ya leyó, el objetivo, la
## mochila, la cámara, el álbum y lo que decide el final: las ofrendas que dejó, las fotos que
## guardan pistas y cuánto se quedó mirando espejos.

## Cómo termina la historia.
enum Ending { RETURNED, DEAL, TAKEN }

## Apachetas en todo el juego; con todas sus ofrendas el ente puede devolver lo que se llevó.
const TOTAL_OFFERINGS := 4
## Fotos de pistas que hacen falta para entender qué es el Q'ispi.
const REQUIRED_CLUES := 3
## Con menos ofrendas que esto el salar no la deja ir.
const MIN_OFFERINGS := 2
## Veces que puede quedarse mirando un espejo antes de que el ente aprenda su cara.
const MAX_MIRROR_STARES := 3

var read_notes := PackedStringArray()
## Apachetas donde Lucía ya dejó su ofrenda.
var offerings := PackedStringArray()
var clue_photos := PackedStringArray()
var mirror_stares := 0
## Espejos que Lucía ya tapó, para que sigan tapados al continuar.
var covered_mirrors := PackedStringArray()
## Lo que Lucía tiene que hacer ahora.
var objective := ""
## Lo que lleva en la mochila: cuántas de cada tipo, por ItemCatalog.Type.
var items: Dictionary[int, int] = {}
## Lo que lleva para abrir caminos, por su nombre visible, como "la llave del hostal".
var tools := PackedStringArray()
## Fotos que quedan en el rollo de la cámara y carga del flash; negativas con la cámara recién
## cargada, como al empezar la noche.
var camera_film := -1
var camera_battery := -1.0
## Fotos del álbum, que viajan de un nivel a otro.
var photos: Array[Photo] = []


## Recuerda que Lucía leyó una nota.
func mark_note_read(note_id: String) -> void:
	if not has_read_note(note_id):
		read_notes.append(note_id)


## Dice si Lucía ya leyó esa nota.
func has_read_note(note_id: String) -> bool:
	return read_notes.has(note_id)


## Recuerda la ofrenda dejada en la apacheta [param apacheta_id].
func add_offering(apacheta_id: String) -> void:
	if not offerings.has(apacheta_id):
		offerings.append(apacheta_id)


## Dice si ya dejó ofrenda en esa apacheta.
func has_offering(apacheta_id: String) -> bool:
	return offerings.has(apacheta_id)


## Guarda que una foto mostró la pista [param clue_id].
func add_clue_photo(clue_id: String) -> void:
	if not clue_photos.has(clue_id):
		clue_photos.append(clue_id)


## Cuenta que Lucía se quedó mirando un espejo.
func add_mirror_stare() -> void:
	mirror_stares += 1


## Recuerda que tapó el espejo [param mirror_id].
func mark_mirror_covered(mirror_id: String) -> void:
	if not covered_mirrors.has(mirror_id):
		covered_mirrors.append(mirror_id)


## Cuántas cosas de ese tipo lleva.
func count_item(type: ItemCatalog.Type) -> int:
	return items.get(type, 0)


## Guarda en la mochila lo que quepa y devuelve cuántas guardó.
func add_item(type: ItemCatalog.Type, amount: int) -> int:
	var added := mini(amount, ItemCatalog.max_stack(type) - count_item(type))
	if added <= 0:
		return 0
	items[type] = count_item(type) + added
	EventBus.inventory_changed.emit(type, items[type])
	return added


## Gasta una cosa de ese tipo si la tiene; dice si pudo.
func use_item(type: ItemCatalog.Type) -> bool:
	if count_item(type) <= 0:
		return false
	items[type] = count_item(type) - 1
	EventBus.inventory_changed.emit(type, items[type])
	return true


## Recuerda cómo quedó la cámara, para el nivel siguiente.
func keep_camera(film: int, battery: float) -> void:
	camera_film = film
	camera_battery = battery


## Cambia el objetivo y avisa, solo si es otro.
func set_objective(text: String) -> void:
	if text == objective:
		return
	objective = text
	EventBus.objective_changed.emit(text)


## Elige el final según lo que hizo Lucía en toda la noche.
func choose_ending() -> Ending:
	if offerings.size() < MIN_OFFERINGS or mirror_stares >= MAX_MIRROR_STARES:
		return Ending.TAKEN
	if offerings.size() >= TOTAL_OFFERINGS and clue_photos.size() >= REQUIRED_CLUES:
		return Ending.RETURNED
	return Ending.DEAL


## Vuelve al estado de una partida nueva.
func reset() -> void:
	read_notes.clear()
	offerings.clear()
	clue_photos.clear()
	mirror_stares = 0
	covered_mirrors.clear()
	objective = ""
	items.clear()
	tools.clear()
	camera_film = -1
	camera_battery = -1.0
	photos.clear()
