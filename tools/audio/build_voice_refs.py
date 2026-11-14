"""Arma las muestras de timbre de cada personaje que imita Chatterbox (tools/generate_voices.py).

Todas leen la misma frase neutra con Kokoro: Lucía con la voz ef_dora, Doña Rosa con la misma un poco
más grave, Javier con em_alex algo más grave y Don Celestino con em_santa, más grave todavía. Las
muestras ya están en tools/audio_sources/voice_refs; este script solo hace falta para cambiarlas.

Uso: python3 tools/audio/build_voice_refs.py
Requiere: kokoro, soundfile y ffmpeg.
"""

import subprocess
import tempfile
from pathlib import Path

import numpy as np
import soundfile as sf
from kokoro import KPipeline

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "audio_sources" / "voice_refs"
SENTENCE = (
    "Cuando llueve en el salar, el agua se queda quieta y el cielo se ve dos veces. Hay que "
    "caminar despacio, porque no se sabe dónde termina."
)
KOKORO_RATE = 24000
KOKORO_SPEED = 0.95
# Personaje: (voz de Kokoro, tono). Un tono mayor que 1 aclara la voz y uno menor la oscurece.
VOICES = {
    "lucia": ("ef_dora", 1.0),
    "rosa": ("ef_dora", 0.9),
    "javier": ("em_alex", 0.94),
    "celestino": ("em_santa", 0.88),
}


def shift_pitch(source, pitch, out):
    """Cambia el tono sin cambiar la duración."""
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(source), "-af",
                    f"asetrate={KOKORO_RATE}*{pitch},aresample={KOKORO_RATE},atempo={1 / pitch:.4f}",
                    str(out)], check=True)


def main():
    """Genera una muestra por personaje."""
    pipeline = KPipeline(lang_code="e", repo_id="hexgrad/Kokoro-82M")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, (voice, pitch) in VOICES.items():
        with tempfile.TemporaryDirectory() as tmp:
            raw = Path(tmp) / "raw.wav"
            chunks = [chunk for _, _, chunk in pipeline(SENTENCE, voice=voice, speed=KOKORO_SPEED)]
            sf.write(raw, np.concatenate(chunks), KOKORO_RATE)
            shift_pitch(raw, pitch, OUTPUT_DIR / f"{name}.wav")
        print("muestra", name)


if __name__ == "__main__":
    main()
