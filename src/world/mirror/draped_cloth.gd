class_name DrapedCloth
extends RefCounted
## Arma la malla de una manta colgada sobre un marco: se dobla por arriba hacia atrás, cae con
## pliegues verticales que se abren hacia abajo y el borde inferior queda un poco desparejo.

const COLUMNS := 24
const ROWS := 32
## Cuántos pliegues entran a lo ancho y cuánto sobresale cada uno abajo, en metros.
const FOLDS := 3.5
const FOLD_DEPTH := 0.05
## Lo que la manta pasa por detrás del marco al doblarse arriba.
const WRAP_BACK := 0.06
## Fracción del alto que ocupa el doblez de arriba.
const WRAP_SHARE := 0.06
## Cuánto baja o sube el borde inferior entre un pliegue y otro.
const HEM_WAVE := 0.04


## Malla de la manta para un marco de [param size] (ancho y alto), con el frente hacia +Z.
static func build(size: Vector2, seed_value: int) -> ArrayMesh:
	var noise := RandomNumberGenerator.new()
	noise.seed = seed_value
	var phase := noise.randf_range(0.0, TAU)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in ROWS + 1:
		var down := float(row) / ROWS
		for column in COLUMNS + 1:
			var across := float(column) / COLUMNS
			tool.set_uv(Vector2(across, down))
			tool.add_vertex(_point(size, across, down, phase))
	for row in ROWS:
		for column in COLUMNS:
			var a := row * (COLUMNS + 1) + column
			var b := a + 1
			var c := a + COLUMNS + 1
			var d := c + 1
			tool.add_index(a)
			tool.add_index(b)
			tool.add_index(c)
			tool.add_index(b)
			tool.add_index(d)
			tool.add_index(c)
	tool.generate_normals()
	tool.generate_tangents()
	return tool.commit()


## Dónde queda un punto de la manta: [param across] va de izquierda a derecha y [param down] de
## arriba abajo, los dos de 0 a 1.
static func _point(size: Vector2, across: float, down: float, phase: float) -> Vector3:
	var fold_wave := sin(across * FOLDS * TAU + phase)
	var x := (across - 0.5) * size.x
	var y := size.y / 2.0 - down * size.y
	var z := FOLD_DEPTH * (1.0 + fold_wave) * down * down
	if down < WRAP_SHARE:
		var bend := 1.0 - down / WRAP_SHARE
		z -= WRAP_BACK * bend * bend
	if is_equal_approx(down, 1.0):
		y -= HEM_WAVE * (0.5 + 0.5 * fold_wave)
	return Vector3(x, y, z)
