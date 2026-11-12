extends TestCase
## Pruebas del agua: la cámara del reflejo queda debajo del agua, mirando el mundo dado vuelta.


## Una cámara a 1,5 m sobre el agua se refleja 1,5 m por debajo y mirando hacia arriba.
func test_reflected_camera_goes_below_water() -> void:
	var view := Transform3D.IDENTITY.looking_at(Vector3(0.0, -1.0, -4.0), Vector3.UP)
	view.origin = Vector3(2.0, 1.5, 3.0)
	var reflected := WaterSurface.reflect(view, 0.0)
	assert_almost_eq(reflected.origin.y, -1.5, "Debe quedar igual de lejos del agua, debajo")
	assert_almost_eq(reflected.origin.x, 2.0, "No se corre de costado")
	var looking := -view.basis.z
	var reflected_looking := -reflected.basis.z
	assert_almost_eq(
		reflected_looking.y, -looking.y, "Si la cámara mira abajo, el reflejo mira arriba"
	)
	assert_almost_eq(reflected.basis.determinant(), 1.0, "Debe seguir siendo una rotación válida")
