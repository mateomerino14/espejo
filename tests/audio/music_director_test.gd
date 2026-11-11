extends TestCase
## Pruebas de la música: sigue el estado del Q'ispi y cambia de capa.

const MUSIC_SCENE := preload("res://src/audio/music_director.tscn")

var _music: MusicDirector


## Crea la música sin Q'ispi, con cambios instantáneos.
func before_each() -> void:
	_music = MUSIC_SCENE.instantiate()
	_music.fade_seconds = 0.05
	_music.chase_fade_seconds = 0.05
	add_to_tree(_music)


## Libera la música.
func after_each() -> void:
	_music.free()


## Cada estado del Q'ispi tiene su ánimo.
func test_mood_follows_qispi_state() -> void:
	assert_true(MusicDirector.mood_for(Qispi.State.STALK) == MusicDirector.Mood.CALM, "Acecho")
	assert_true(MusicDirector.mood_for(Qispi.State.TRACK) == MusicDirector.Mood.TENSION, "Rastreo")
	assert_true(
		MusicDirector.mood_for(Qispi.State.STUNNED) == MusicDirector.Mood.TENSION, "Aturdido"
	)
	assert_true(MusicDirector.mood_for(Qispi.State.HUNT) == MusicDirector.Mood.CHASE, "Caza")


## Al empezar solo se oye la calma; al cazar sube la persecución y baja la calma.
func test_chase_replaces_calm() -> void:
	var calm: AudioStreamPlayer = _music.get_node("Calm")
	var chase: AudioStreamPlayer = _music.get_node("Chase")
	assert_true(chase.volume_db <= MusicDirector.SILENT_DB, "La persecución empieza callada")
	_music.set_mood(MusicDirector.Mood.CHASE)
	await tree.create_timer(0.2).timeout
	assert_true(chase.volume_db > MusicDirector.SILENT_DB, "La persecución debe sonar")
	assert_true(calm.volume_db <= MusicDirector.SILENT_DB, "La calma debe apagarse")
