extends TestCase
## Pruebas de las notas: leerlas las abre en pantalla con el juego en pausa y las marca leídas.

const NOTE_SCENE := preload("res://src/story/readable_note.tscn")
const VIEWER_SCENE := preload("res://src/ui/note_viewer/note_viewer.tscn")
const BOOK := preload("res://src/story/notes/libro_huespedes.tres")

var _note: ReadableNote
var _viewer: NoteViewer


## Pone una nota y el visor de notas.
func before_each() -> void:
	GameState.reset()
	_note = NOTE_SCENE.instantiate()
	_note.note = BOOK
	add_to_tree(_note)
	_viewer = VIEWER_SCENE.instantiate()
	add_to_tree(_viewer)


## Cierra el visor y libera todo.
func after_each() -> void:
	_viewer.close()
	_note.free()
	_viewer.free()
	GameState.reset()


## Leer la nota la muestra, pausa el juego y la marca como leída.
func test_reading_opens_and_marks() -> void:
	var interactable: Interactable = _note.get_node("Interactable")
	assert_true(interactable.get_prompt(null).begins_with("Leer"), "Debe ofrecer leerla")
	interactable.interact(null)
	assert_true(_viewer.is_open and tree.paused, "Debe abrirse con el juego en pausa")
	assert_true(_viewer.get_node("%Title").text == BOOK.title, "Debe mostrar su título")
	assert_true(GameState.has_read_note(BOOK.id), "Debe quedar leída")
	assert_true(interactable.get_prompt(null).begins_with("Volver a leer"), "Debe ofrecer releerla")


## Al cerrarla el juego sigue.
func test_closing_resumes() -> void:
	_note.get_node("Interactable").interact(null)
	_viewer.close()
	assert_false(tree.paused, "El juego debe seguir")
