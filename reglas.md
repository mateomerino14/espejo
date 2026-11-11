# Estándares de desarrollo

Espejo — convenciones de ramas, commits, codificación y arquitectura en Godot.

---

## ESTÁNDARES DE RAMAS

| Rama | Uso |
|---|---|
| `main` | Versión estable, solo con luz verde |
| `develop` | Integración de los módulos terminados |
| `feat/<modulo>` | Desarrollo de un módulo o mecánica, en `snake_case` (ej. `feat/camara`) |
| `fix/<tema>` | Corrección puntual sobre `develop` |
| `style/<tema>` | Cambio visual o de ambientación sin tocar la lógica |
| `refactor/<tema>` | Reestructuración o limpieza sin cambiar el comportamiento |
| `test/<tema>` | Pruebas nuevas o ajustes de pruebas |
| `docs/<tema>` | Documentación (README, reglas, diseño) |
| `build/<tema>` | Exportación del juego y publicación de versiones |

### Flujo

1. Cada módulo se desarrolla en su rama, creada desde `develop`.
2. Al terminarlo se abre un Pull Request hacia `develop`. GitHub Actions debe pasar antes del merge.
3. Cuando `develop` reúne una entrega completa y se aprueba, se abre un Pull Request de `develop` hacia `main`.
4. Después del merge, la rama de trabajo se borra; en el repositorio solo quedan `main` y `develop`.

---

## ESTÁNDARES DE COMMITS

Se usa Conventional Commits, con todos los commits a nombre del autor del repositorio y sin coautores.

### Tipos de commit

| Tipo | Uso |
|---|---|
| `feat` | Nueva mecánica o funcionalidad |
| `fix` | Corrección de errores |
| `style` | Cambios visuales, de luz o de ambientación sin afectar la lógica |
| `refactor` | Reestructuración de código sin modificar el comportamiento |
| `docs` | Documentación |
| `test` | Creación o actualización de pruebas |
| `chore` | Configuración del proyecto, CI y herramientas |
| `build` | Exportación del ejecutable, presets y publicación de versiones en Releases |

### Formato

```
<tipo>: <Descripción>
```

### Ejemplos válidos

```
feat: Agrega el visor de la cámara que revela los reflejos
fix: Evita que el flash aturda al ente fuera de cuadro
style: Enfría el tinte del visor
test: Prueba que el rollo no pasa de 24 fotos
```

### Reglas

- El mensaje comienza con mayúscula después del prefijo.
- Describe la funcionalidad, no los archivos modificados.
- Un commit representa una única funcionalidad, corrección o mejora.
- Evitar mensajes genéricos: `cambios`, `correcciones`, `actualización`, `prueba`.

---

## ESTÁNDARES DE CODIFICACIÓN

### Idioma

- El código se escribe en inglés: clases, variables, funciones, señales, nodos y acciones de entrada.
- Los textos que ve el jugador, los comentarios y la documentación van en español.

### Comentarios

- Cada clase lleva un comentario de documentación (`##`) de una línea bajo `extends` que dice su propósito.
- Cada función lleva un comentario `##` de una línea que describe su propósito.
- Dentro de las funciones solo se dejan avisos importantes, de una línea.
- Las variables exportadas llevan `##` solo cuando su nombre no basta.
- Eliminar el código comentado antes de cada commit.

```gdscript
## Carga batería sin pasar del máximo.
func add_battery(amount: float) -> void:
	battery = minf(battery + amount, max_battery)
	battery_changed.emit(battery, max_battery)
```

### Sintaxis

El formato sigue la guía oficial de GDScript y se valida con gdtoolkit: `gdformat --check src tests` y `gdlint src tests`. Para corregir el formato: `gdformat src tests`. El código sin uso (funciones sin llamadas, señales sin oyentes, constantes o variables sin leer) se busca con `python3 tools/find_unused.py src tests` y no debe quedar ninguno; una señal se declara cuando ya tiene quien la escuche.

**Tipado estático siempre.** Una declaración sin tipo es un error del proyecto (`untyped_declaration`). Se usa `:=` cuando el tipo se deduce.

**No usar el operador ternario (`a if cond else b`) en la lógica**; se prefieren bloques `if`/`else` explícitos o un valor por defecto que se reemplaza.

```gdscript
# Correcto
var rate := deceleration
if direction != Vector3.ZERO:
	rate = acceleration

# Incorrecto
var rate := acceleration if direction != Vector3.ZERO else deceleration
```

**Evitar valores mágicos**; se declaran como `const` con nombre, o como `@export` cuando se ajustan desde el editor.

```gdscript
const MAX_LEVEL := 3
@export var walk_speed := 2.4
```

**Nombres:**

| Elemento | Convención | Ejemplo |
|---|---|---|
| Archivos y carpetas | `snake_case` | `photo_camera.gd` |
| Clases (`class_name`) | `PascalCase` | `PhotoCamera` |
| Nodos en escenas | `PascalCase` | `Viewfinder` |
| Funciones y variables | `snake_case` | `get_battery_ratio()` |
| Privados | prefijo `_` | `_fire_flash()` |
| Constantes y enums | `CONSTANT_CASE` | `MIN_LEVEL` |
| Señales | pasado o cambio | `battery_changed`, `photo_taken` |
| Acciones de entrada | `snake_case` | `camera_raise` |

---

## ARQUITECTURA

### Estructura

```
src/
├── core/             Autoloads globales (EventBus)
├── enemies/          El Q'ispi (qispi/) y sus sentidos, pasos y animación (components/)
├── player/           Lucía
│   ├── player.tscn / player.gd      Raíz: lee la entrada y coordina
│   ├── first_person_camera.gd       Mirada, balanceo y asomarse
│   └── components/                  Piezas independientes (aliento, pasos, cámara de fotos, susto)
├── photography/      Fotos del rollo y sujetos que vale la pena fotografiar
├── world/            Niveles, espejos (mirror/), materiales del salar (materials/), reaparición (respawn/) y salas de prueba
└── ui/               HUD, visor de la cámara, álbum y pantalla de captura
assets/               Modelos (.gltf del Q'ispi), texturas y audio
tests/                Pruebas, en carpetas que reflejan src/
tools/                Generadores de modelos (blender/), sonidos y navegación; nada de aquí entra al juego
```

Cada escena vive junto a su script con el mismo nombre (`player.tscn` y `player.gd`). La estructura crece con cada módulo y se actualiza aquí en el mismo Pull Request.

### Responsabilidades

| Capa | Puede | No puede |
|---|---|---|
| Raíz de sistema (`Player`) | Leer la entrada, decidir el estado, llamar a sus componentes, publicar en `EventBus` | Contener la lógica interna de un componente |
| Componente | Resolver una sola cosa y avisar con señales propias | Conocer a otros componentes o leer la entrada |
| `EventBus` | Transportar eventos entre sistemas que no se conocen | Guardar estado |
| HUD y audio | Escuchar `EventBus` y presentar | Cambiar el estado del juego |

**Señales hacia arriba, llamadas hacia abajo:** un nodo llama métodos de sus hijos y escucha las señales de ellos; nunca busca a su padre ni a sus hermanos.

**`EventBus` solo para eventos que cruzan sistemas**, como el ruido que oye el ente. La comunicación dentro de una escena usa señales locales.

### Física

| Capa | Uso |
|---|---|
| 1 | Mundo (suelo, paredes, muebles) |
| 2 | Jugador |
| 3 | Interactuables |
| 4 | Enemigos (el ente) |

### Capas de render

| Capa | Uso |
|---|---|
| 1 | Todo lo que se ve a simple vista |
| 11 | Reflejo: solo se ve por el visor de la cámara y en los espejos (más adelante, también en el agua) |

### Cámara de fotos

- `PhotoCamera` vive en la cámara del jugador: levantada, acerca la vista y suma la capa 11 a lo que se dibuja.
- Cada foto es un `Photo` con su imagen, si llevó flash y las descripciones de los `PhotoSubject` que salieron en cuadro, cerca y sin nada en medio.
- El álbum y el visor solo escuchan `EventBus` (`camera_raised`, `film_changed`, `camera_battery_changed`, `photo_taken`).

### Espejos

- `Mirror` dibuja su reflejo con una cámara puesta en el ojo reflejado, cuyo plano cercano es el propio vidrio; así nada de lo que hay detrás de la pared se cuela en la imagen.
- El vidrio mira hacia +Z local y se cuelga a pocos milímetros de la pared. Su tamaño se ajusta con `size`, y la nitidez, con `resolution`.
- Cuando el ojo está detrás del espejo, el reflejo deja de dibujarse.

### El Q'ispi

- Estados: `STALK` (deambula cerca de su punto de inicio), `TRACK` (va a un ruido o a donde la perdió y mira alrededor), `HUNT` (corre hacia Lucía) y `STUNNED` (aturdido por el flash).
- Nota a Lucía si la ve (`PlayerSight`) o si ella lo mira por el visor de cerca y sin nada en medio.
- El flash (`EventBus.flash_fired`) lo aturde si le da en la cara dentro de `flash_range`; cada flash dura `stun_resistance` veces el anterior, hasta `min_stun_seconds`.
- Al alcanzarla emite `EventBus.player_caught`: `CaughtReaction` muestra su cara aunque no se mire por el visor y `RespawnDirector` lleva a Lucía a su `spawn_point`.
- `QispiAnimator` pasa todo su cuerpo a la capa de render 11 y le quita la sombra, que lo delataría a simple vista.
- En la embestida se enciende `FaceLight`, una luz fría que deja ver su cara durante el susto.

### Navegación

- Cada nivel tiene un `NavigationRegion3D` con su malla en un `.tres` junto a la escena; solo se hornea el grupo `navigation_source`.
- Al cambiar la geometría se vuelve a hornear: `godot --headless --path . -s tools/bake_navmesh.gd -- res://ruta/al/nivel.tscn`.

### Buses de audio

| Bus | Uso |
|---|---|
| `Master` | Volumen general |
| `Ambiente` | Viento, lluvia y fondo |
| `Efectos` | Pisadas, cámara y el ente |

Todo sonido nuevo se asigna a `Ambiente` o a `Efectos`, nunca directo a `Master`.

### Grupos

| Grupo | Uso |
|---|---|
| `player` | Declarado en `player.tscn`; el ente encuentra así al jugador |
| `enemies` | Declarado en `qispi.tscn`; `RespawnDirector` los reinicia al reaparecer Lucía |
| `navigation_source` | Geometría que se hornea en la navegación |
| `photo_subjects` | Lo agrega cada `PhotoSubject`; la cámara los revisa al disparar |

---

## PRUEBAS

- Las pruebas viven en `tests/`, con archivos `<nombre>_test.gd` que extienden `TestCase`; cada método `test_` es una prueba.
- Se ejecutan sin abrir el editor: `godot --headless --path . --script res://tests/run_tests.gd`.
- Cada componente con lógica tiene pruebas unitarias; los recorridos del jugador se prueban dentro de una escena real.
- En cada Pull Request, GitHub Actions valida el formato, el lint y el código sin uso, importa el proyecto y corre las pruebas.
- Un módulo se considera terminado cuando sus pruebas pasan en GitHub Actions y el README está actualizado.

---

## ASSETS

- Las superficies usan los materiales triplanares de `src/world/materials/`, así no necesitan UV.
- Los modelos salen de scripts de Blender en `tools/blender/` y se exportan a `assets/models/` (glTF u OBJ), con escala real en metros.
- El audio se guarda en `.ogg`; los efectos cortos pueden ir en `.wav`.
- Los sonidos y voces se generan con scripts en `tools/`; para cambiar uno se cambia su script y se vuelve a generar. Al reemplazar uno por una grabación real se mantiene el mismo nombre de archivo.
- Un sonido que debe repetirse sin corte lleva sus puntos de bucle en el WAV o se marca con bucle al importarlo.
- Los archivos fuente `.blend` se guardan fuera del repositorio o, si se suben, en `assets/source/`.

---

## BUENAS PRÁCTICAS GENERALES

- Cada archivo tiene una única responsabilidad principal.
- Los valores de ajuste se exponen con `@export` agrupados con `@export_group`.
- Evitar código duplicado y código sin uso.
- No incluir credenciales en el repositorio.
