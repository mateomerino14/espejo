# Espejo

Juego de terror en primera persona en el salar de Uyuni durante la temporada de lluvias, cuando el salar se vuelve un espejo. Lucía, una fotógrafa de La Paz, descubre que algo vive del otro lado de los reflejos y que solo puede verlo a través de su cámara.

Es la segunda historia del Manqha Pacha, después de [Socavón](https://github.com/mateomerino14/socavon).

## Estado

En desarrollo. La hoja de ruta está en el documento de diseño.

| Fase | Entrega | Estado |
|---|---|---|
| 0. Base | Proyecto, jugador, sala de prueba, CI | Lista |
| 1. Cámara | Visor, flash, fotos y álbum | Lista |
| 2. Ente | El Q'ispi, visible solo en reflejos | Lista |
| 3. Nivel 1 | Hostal de sal | Jugable |
| 4. Niveles 2 a 5 | El resto del salar | Pendiente |
| 5. Pulido | Menú, cinemáticas, finales y versión para Windows | En curso: menú, pausa y exe listos |

## Controles

| Acción | Teclado y ratón | Mando |
|---|---|---|
| Moverse | WASD | Stick izquierdo |
| Correr | Shift | RB |
| Agacharse | Ctrl o C | B |
| Usar, abrir, leer | E | A |
| Asomarse | Q y Z | Sticks presionados |
| Levantar la cámara | Clic derecho | LT |
| Tomar foto | Clic izquierdo | RT |
| Álbum | Tab | Back |
| Pausa | Escape | Start |

## Desarrollo

- Motor: Godot 4.7.2 (Forward+, física Jolt).
- Modelos: scripts de Blender en `tools/blender/` (ver su README).
- Sonidos de la cámara y del ente: `python3 tools/generate_sounds.py assets/audio`.
- Pruebas: `godot --headless --path . --script res://tests/run_tests.gd`.
- Convenciones de ramas, commits, código y arquitectura: [reglas.md](reglas.md).
