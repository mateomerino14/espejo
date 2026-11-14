# Espejo

Juego de terror en primera persona en el salar de Uyuni durante la temporada de lluvias, cuando el salar se vuelve un espejo. Lucía, una fotógrafa de La Paz, descubre que algo vive del otro lado de los reflejos y que solo puede verlo a través de su cámara.

Es la segunda historia del Manqha Pacha, después de [Socavón](https://github.com/mateomerino14/socavon).

## Estado

Versión `1.0.1`: el juego completo, con cinco niveles, tres finales y versión para Windows en [Releases](https://github.com/mateomerino14/espejo/releases).

| Fase | Entrega | Estado |
|---|---|---|
| 0. Base | Proyecto, jugador, sala de prueba, CI | Lista |
| 1. Cámara | Visor, flash, fotos y álbum | Lista |
| 2. Ente | El Q'ispi, visible solo en reflejos | Lista |
| 3. Nivel 1 | Hostal de sal | Lista |
| 4. Niveles 2 a 5 | El resto del salar | Lista |
| 5. Pulido | Menú, cinemáticas, finales, consejos de controles y versión para Windows | Lista |

## Controles

También se ven en el juego, en **Controles**, desde el menú principal o la pausa. Mientras juegas, un cuadro arriba a la derecha enseña cada control la primera vez que hace falta, con la tecla o el botón según juegues con teclado o mando; se apaga en Opciones.

| Acción | Teclado y ratón | Mando |
|---|---|---|
| Moverse | WASD | Stick izquierdo |
| Mirar | Ratón | Stick derecho |
| Correr | Shift | L3 |
| Agacharse | Ctrl o C | B |
| Usar, abrir, leer, esconderse | E | A |
| Asomarse | Q y Z | LB y RB |
| Levantar la cámara (mantener) | Clic derecho | LT |
| Tomar foto | Clic izquierdo | RT |
| Álbum | Tab | Back |
| Pausa | Esc | Start |

## Desarrollo

- Motor: Godot 4.7.2 (Forward+, física Jolt).
- Modelos: scripts de Blender en `tools/blender/` (ver su README).
- Sonidos: grabaciones CC0 de Freesound armadas con `tools/audio/build_sounds.py` (ver su README); el ente y el crujido de las puertas, con `python3 tools/generate_sounds.py assets/audio`.
- Pruebas: `godot --headless --path . --script res://tests/run_tests.gd`.
- Convenciones de ramas, commits, código y arquitectura: [reglas.md](reglas.md).
