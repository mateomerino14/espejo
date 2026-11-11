# Sonidos

Los sonidos de Espejo salen de grabaciones de [Freesound](https://freesound.org) con licencia CC0 (dominio público). `freesound_ids.json` lista cada grabación con su autor; `build_sounds.py` las recorta, limpia y mezcla:

- Pasos sobre sal, tierra, madera y agua (cuatro de cada uno).
- La cámara: levantarla, bajarla, obturador, palanca del rollo, clic sin rollo y la carga del flash (sintetizada).
- Papel, libro y puertas.
- Ambiente: viento del salar, la llama de la lámpara, crujidos de sal y gotas.
- Música en tres capas que se cruzan según el Q'ispi: calma (bordón y viento tonal), tensión (segunda menor, chelo raspado y latido) y persecución (bombo legüero en 6/8, violín raspado). Además, cuatro frases de quena lejanas y desafinadas.

Los pasos de uso están al principio del script. El grito, el aturdimiento del ente y el crujido de las puertas siguen saliendo de `tools/generate_sounds.py`.

## Voces

`build_voices.py` genera lo que dicen los personajes con [Piper](https://github.com/rhasspy/piper), una síntesis de voz que corre en la computadora. Javier usa la voz `es_MX-ald-medium` (dominio público) un poco más grave, y Lucía usa `es_AR-daniela-high`, entrenada con un corpus CC BY-SA 4.0, por lo que sus audios llevan esa misma licencia y van en los créditos. Las líneas y su texto están al principio del script; el subtítulo de cada plano repite el mismo texto.

```bash
pip install piper-tts
python3 tools/audio/build_voices.py <carpeta_con_los_onnx> assets/audio/voices
```
