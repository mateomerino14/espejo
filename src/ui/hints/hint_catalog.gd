class_name HintCatalog
extends RefCounted
## Textos de los consejos de controles. Entre llaves van las acciones, separadas por "|", que
## InputDevice cambia por su tecla o botón en el aparato con que se juega.

const TEXTS: Dictionary[String, String] = {
	"caminar":
	(
		"{move_forward|move_left|move_back|move_right} para caminar  ·  "
		+ "{look_left|look_right|look_up|look_down} para mirar"
	),
	"camara": "Mantén {camera_raise} para mirar por el visor: ahí se ve lo que vive en el reflejo",
	"foto":
	"Con el visor arriba, {camera_shoot} toma una foto. El flash aturde al Q'ispi un momento",
	"correr":
	"{sprint} para correr, aunque gasta aliento  ·  {crouch} para agacharte y pisar sin ruido",
	"usar": "{interact} para usar, abrir, leer o esconderte",
	"album": "{album} abre el álbum con tus fotos",
	"inventario": "{inventory} abre la mochila: ahí ves lo que llevas y para qué sirve",
	"pilas": "El flash se quedó sin pila: las fotos salen sin flash hasta que encuentres pilas",
	"asomarse": "{lean_left} y {lean_right} para asomarte por las esquinas sin salir",
	"escondite":
	"En roperos, casilleros y grietas te puedes esconder; si te ve entrar, te encuentra",
	"espejo": "En los espejos se ve al Q'ispi aunque no esté a la vista",
	"apacheta":
	"En las apachetas dejas coca y una vela: el Q'ispi se aquieta un rato y se guarda la partida",
	"rastro": "El Q'ispi te sigue por el ruido: agáchate con {crouch} o escóndete",
	"caza":
	(
		"¡Te vio! Corre con {sprint}, escóndete o deslúmbralo con el flash "
		+ "({camera_raise} y {camera_shoot})"
	),
}


## Texto de un consejo con las teclas o botones del aparato actual; vacío si no existe.
static func text(id: String) -> String:
	if not TEXTS.has(id):
		return ""
	return InputDevice.fill(TEXTS[id])
