# Sonidos

Los sonidos de Espejo salen de grabaciones de [Freesound](https://freesound.org) con licencia CC0 (dominio público). `freesound_ids.json` lista cada grabación con su autor; `build_sounds.py` las recorta, limpia y mezcla:

- Pasos sobre sal, tierra, madera y agua (cuatro de cada uno).
- La cámara: levantarla, bajarla, obturador, palanca del rollo, clic sin rollo y la carga del flash (sintetizada).
- Papel, libro y puertas.
- Ambiente: viento del salar, la llama de la lámpara, crujidos de sal y gotas.
- Música en tres capas que se cruzan según el Q'ispi: calma (bordón y viento tonal), tensión (segunda menor, chelo raspado y latido) y persecución (bombo legüero en 6/8, violín raspado). Además, cuatro frases de quena lejanas y desafinadas.

Las puertas y los escondites salen de grabaciones CC0 de [OpenGameArt](https://opengameart.org): `oga_sources.json` dice de qué paquete viene cada una y `build_oga_sounds.py` las baja y mezcla (la puerta que se abre con su bisagra, el golpe al cerrarse, el ropero y el casillero al entrar y al salir).

```bash
pip install py7zr
python3 tools/audio/build_oga_sounds.py <carpeta_de_descarga> assets/audio
```

Los pasos de uso están al principio del script. El grito, el aturdimiento del ente y el crujido de las puertas siguen saliendo de `tools/generate_sounds.py`.

## Voces

`tools/generate_voices.py` genera lo que dicen los personajes con [Chatterbox Multilingual](https://github.com/resemble-ai/chatterbox): cada personaje imita su muestra de timbre de `tools/audio_sources/voice_refs` y actúa la línea con la emoción que le toca; [faster-whisper](https://github.com/SYSTRAN/faster-whisper) escucha cada toma y se queda con la que mejor se entiende. Las líneas, su texto, su emoción y su efecto (agua, la otra Lucía o una voz robada) están al principio del script; el subtítulo de cada plano repite el mismo texto.

Las muestras de timbre salen de [Kokoro](https://huggingface.co/hexgrad/Kokoro-82M) con `tools/audio/build_voice_refs.py`: Lucía con `ef_dora`, Doña Rosa con la misma más grave, Javier con `em_alex` y Don Celestino con `em_santa`.

```bash
pip install chatterbox-tts faster-whisper kokoro soundfile "setuptools<70"
python3 tools/audio/build_voice_refs.py
python3 tools/generate_voices.py            # todas
python3 tools/generate_voices.py celestino_2  # solo esas
```
