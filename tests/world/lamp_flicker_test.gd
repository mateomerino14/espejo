extends TestCase
## Pruebas de la llama: tiembla sin salirse de su rango.

const BASE_ENERGY := 2.0
const FRAMES := 60

var _lamp: LampFlicker


## Crea una lámpara con intensidad conocida.
func before_each() -> void:
	_lamp = LampFlicker.new()
	_lamp.light_energy = BASE_ENERGY
	add_to_tree(_lamp)


## Libera la lámpara.
func after_each() -> void:
	_lamp.free()


## La intensidad cambia y se queda dentro del temblor permitido.
func test_flickers_within_range() -> void:
	var lowest := INF
	var highest := -INF
	for i in FRAMES:
		await tree.process_frame
		lowest = minf(lowest, _lamp.light_energy)
		highest = maxf(highest, _lamp.light_energy)
	var margin := BASE_ENERGY * _lamp.flicker
	assert_true(highest > lowest, "La llama debe temblar")
	assert_true(lowest >= BASE_ENERGY - margin - 0.001, "No debe bajar de más")
	assert_true(highest <= BASE_ENERGY + margin + 0.001, "No debe subir de más")
