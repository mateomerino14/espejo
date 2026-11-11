"""Genera las voces de los personajes con Piper (síntesis de voz local, voces libres).

Uso: python3 build_voices.py <carpeta_de_voces_piper> <salida>

Las voces se bajan de huggingface.co/rhasspy/piper-voices: es_MX-ald-medium para Javier (más grave)
y es_AR-daniela-high para Lucía.
"""

import os
import subprocess
import sys
import tempfile

VOICES = {
    "javier": ("es_MX-ald-medium", -2.0, 1.12),
    "lucia": ("es_AR-daniela-high", 0.0, 1.08),
}
# Cada línea: archivo, personaje y texto
LINES = [
    (
        "intro_javier_1",
        "javier",
        "Llegamos. Doña Rosa ya debe estar dormida, pero nos dejó la luz prendida.",
    ),
    ("intro_javier_2", "javier", "Mañana salimos al amanecer, si la lluvia nos deja."),
    ("intro_lucia_1", "lucia", "Voy a sacar unas fotos. Con el agua, el cielo se ve dos veces."),
    ("intro_javier_3", "javier", "No te alejes. Con esta agua no se sabe dónde termina el salar."),
]


def main():
    """Sintetiza cada línea, le baja el tono si hace falta y la guarda en Ogg."""
    voices_dir, out_dir = sys.argv[-2], sys.argv[-1]
    os.makedirs(out_dir, exist_ok=True)
    for name, who, text in LINES:
        model, semitones, length = VOICES[who]
        with tempfile.TemporaryDirectory() as tmp:
            raw = os.path.join(tmp, "raw.wav")
            subprocess.run(
                [
                    sys.executable,
                    "-m",
                    "piper",
                    "-m",
                    os.path.join(voices_dir, model + ".onnx"),
                    "--length-scale",
                    str(length),
                    "-f",
                    raw,
                ],
                input=text.encode(),
                check=True,
                capture_output=True,
            )
            ratio = 2 ** (semitones / 12)
            filters = f"asetrate=22050*{ratio},aresample=44100,atempo={1 / ratio},highpass=f=90,"
            filters += "apad=pad_dur=0.3"
            subprocess.run(
                [
                    "ffmpeg",
                    "-v",
                    "error",
                    "-y",
                    "-i",
                    raw,
                    "-af",
                    filters,
                    "-c:a",
                    "libvorbis",
                    "-q:a",
                    "6",
                    os.path.join(out_dir, name + ".ogg"),
                ],
                check=True,
            )
        print(name)


main()
