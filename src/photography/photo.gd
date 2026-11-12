class_name Photo
extends RefCounted
## Una foto del rollo: la imagen revelada, si se tomó con flash y lo que se ve en ella.

## Ancho de la imagen guardada; se achica para no llenar la memoria con 24 capturas.
const STORED_WIDTH := 960

var texture: Texture2D
var has_flash := false
## Lo que la foto revela, como texto para el álbum.
var captions := PackedStringArray()


## Crea la foto con lo que se encontró en cuadro al disparar.
func _init(flash: bool, found: PackedStringArray) -> void:
	has_flash = flash
	captions = found


## Guarda la imagen capturada, achicada a su ancho de álbum.
func develop(image: Image) -> void:
	if image == null or image.is_empty():
		return
	var height := roundi(float(image.get_height()) * STORED_WIDTH / image.get_width())
	image.resize(STORED_WIDTH, height, Image.INTERPOLATE_BILINEAR)
	texture = ImageTexture.create_from_image(image)
