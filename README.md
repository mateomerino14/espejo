# Espejo

Juego de terror en primera persona en el salar de Uyuni durante la temporada de lluvias, cuando el salar se vuelve un espejo. Lucía, una fotógrafa de La Paz, descubre que algo vive del otro lado de los reflejos y que solo puede verlo a través de su cámara.

Es la segunda historia del Manqha Pacha, después de [Socavón](https://github.com/mateomerino14/socavon).

## Estado

Versión `1.1.0`: el juego completo, con cinco niveles, tres finales y versión para Windows en [Releases](https://github.com/mateomerino14/espejo/releases); ahora con objetivos, mochila, mapa, tránsitos entre niveles, consejos de controles y voces nuevas.

| Fase | Entrega | Estado |
|---|---|---|
| 0. Base | Proyecto, jugador, sala de prueba, CI | Lista |
| 1. Cámara | Visor, flash, fotos y álbum | Lista |
| 2. Ente | El Q'ispi, visible solo en reflejos | Lista |
| 3. Nivel 1 | Hostal de sal | Lista |
| 4. Niveles 2 a 5 | El resto del salar | Lista |
| 5. Pulido | Menú, cinemáticas, finales, consejos de controles y versión para Windows | Lista |

## Qué hay en el juego

- **La cámara de Lucía:** por el visor se ve lo que vive en el reflejo; el flash aturde al Q'ispi y cada foto queda en el álbum. Cuando se acaba el rollo o la pila, carga otro de la mochila.
- **El Q'ispi:** invisible a simple vista, se ve por el visor y en los espejos. Oye, rastrea y caza; a veces sale de golpe en una emboscada.
- **Mochila:** hojas de coca y velas para las apachetas, mantas para tapar espejos, rollos y pilas. Con la tecla I se ve qué es cada cosa y para qué sirve, junto con la cámara, el objetivo y las fotos de pistas. Lo que lleva pasa de un nivel a otro.
- **Mapa:** con la tecla M, Lucía dibuja por dónde pasó, con las apachetas, los espejos que faltan tapar y la salida.
- **Objetivos:** el nombre del nivel aparece abajo a la izquierda y el objetivo arriba a la izquierda, con un aviso. Cada salida se abre haciendo algo: una llave, mantas para los espejos, una nota que dice a dónde ir o los remos del bote.
- **Tránsitos:** entre nivel y nivel, Lucía cruza el salar y dice lo que piensa; a veces el Q'ispi la sigue en el reflejo del agua.
- **Tres finales**, según las ofrendas, las fotos de pistas y cuántas veces se quedó mirándose en un espejo.

## Niveles

1. **El hostal de sal:** Javier no está. Su nota despierta al Q'ispi, y la puerta del comedor tiene llave: está en la cocina de Doña Rosa.
2. **El hostal vacío:** el Q'ispi sale por los espejos destapados. Hay que taparlos todos con las mantas de las camas para abrir la puerta principal.
3. **El cementerio de trenes:** el sombrero de Javier junto al agua y, en el vagón del Tío, la lista de Mateo que dice a dónde ir.
4. **La isla Incahuasi:** Don Celestino espera en la cima; después hay que buscar los remos de su bote en la ladera norte.
5. **El centro del salar:** el agua refleja el amanecer, Javier camina en el reflejo y en el centro espera un espejo.

## Prensa

En [`prensa/`](prensa/README.md) hay un tráiler y capturas del juego por si se quiere publicar.

## Controles

También se ven en el juego, en **Controles**, desde el menú principal o la pausa. Mientras juegas, un cuadro arriba a la derecha enseña cada control la primera vez que hace falta, con la tecla o el botón según juegues con teclado o mando; se apaga en Opciones.

| Acción | Teclado y ratón | Mando |
|---|---|---|
| Moverse | WASD | Stick izquierdo |
| Mirar | Ratón | Stick derecho |
| Correr | Shift | L3 |
| Agacharse | Ctrl o C | B |
| Usar, abrir, leer, esconderse | E | A |
| Inventario | I | Cruceta arriba |
| Mapa | M | R3 |
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
