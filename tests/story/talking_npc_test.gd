extends TestCase
## Pruebas de los personajes que hablan: dicen sus líneas en orden con subtítulos y avisan al
## terminar.

const CELESTINO_SCENE := preload("res://src/story/celestino/celestino.tscn")

var _npc: TalkingNpc
var _subtitles := PackedStringArray()
var _finished := 0


## Pone a Don Celestino con líneas cortas, sin voz.
func before_each() -> void:
	_npc = CELESTINO_SCENE.instantiate()
	var lines: Array[DialogueLine] = []
	for text: String in ["Hola", "Chau"]:
		var line := DialogueLine.new()
		line.text = text
		lines.append(line)
	_npc.lines = lines
	add_to_tree(_npc)
	_subtitles.clear()
	_finished = 0
	EventBus.subtitle_requested.connect(_on_subtitle_requested)
	_npc.conversation_finished.connect(_on_finished)


## Libera todo.
func after_each() -> void:
	EventBus.subtitle_requested.disconnect(_on_subtitle_requested)
	_npc.free()


## Las líneas salen en orden y al final avisa una vez y vuelve a esperar.
func test_says_lines_in_order() -> void:
	_npc.talk()
	assert_true(_npc.is_talking, "Debe estar hablando")
	assert_true(_subtitles == PackedStringArray(["Hola"]), "Empieza por la primera")
	var timer: Timer = _npc.get_node("LineTimer")
	timer.timeout.emit()
	assert_true(_subtitles == PackedStringArray(["Hola", "Chau"]), "Sigue con la segunda")
	timer.timeout.emit()
	assert_false(_npc.is_talking, "Terminó")
	assert_true(_npc.has_talked and _finished == 1, "Avisa que terminó")


## Mientras habla, volver a pedirle que hable no repite nada.
func test_ignores_talk_while_talking() -> void:
	_npc.talk()
	_npc.talk()
	assert_true(_subtitles.size() == 1, "No debe empezar de nuevo")


## Las líneas de Don Celestino tienen voz y su duración es la de la voz.
func test_celestino_lines_have_voice() -> void:
	var original: TalkingNpc = CELESTINO_SCENE.instantiate()
	assert_true(original.lines.size() == 5, "Don Celestino dice cinco líneas")
	for line in original.lines:
		assert_true(line.voice != null, "Cada línea tiene voz")
		assert_true(is_equal_approx(line.get_seconds(), line.voice.get_length()), "Dura su voz")
	original.free()


## Guarda los subtítulos.
func _on_subtitle_requested(text: String, _seconds: float) -> void:
	_subtitles.append(text)


## Cuenta los finales de conversación.
func _on_finished() -> void:
	_finished += 1
