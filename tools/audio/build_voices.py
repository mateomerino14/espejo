"""Genera las voces de los personajes con Piper (síntesis de voz local, voces libres).

Uso: python3 build_voices.py <carpeta_de_voces_piper> <salida>

Las voces se bajan de huggingface.co/rhasspy/piper-voices: es_MX-ald-medium para Javier (más grave)
y es_AR-daniela-high para Lucía; Don Celestino usa es_MX-claude-high, más grave y lento. Las líneas que
ya tienen su archivo se saltan: para rehacer una, se borra su .ogg.
"""

import os
import subprocess
import sys
import tempfile

VOICES = {
    "javier": ("es_MX-ald-medium", -2.0, 1.12),
    "lucia": ("es_AR-daniela-high", 0.0, 1.08),
    "rosa": ("es_AR-daniela-high", -4.0, 1.2),
    "celestino": ("es_MX-claude-high", -3.0, 1.3),
}
# Efectos extra: la voz desde el agua tiene eco, y la otra Lucía habla más grave y lenta
EFFECTS = {
    "": "",
    "agua": ",aecho=0.8:0.7:180|420:0.45|0.3,lowpass=f=3200",
    "otra": ",asetrate=44100*0.9,aresample=44100,atempo=1.05",
    "robada": ",vibrato=f=5.5:d=0.25,aecho=0.7:0.6:90|230:0.35|0.2,highpass=f=220,lowpass=f=3600",
}
# Cada línea: archivo, personaje, texto y efecto
LINES = [
    (
        "intro_javier_1",
        "javier",
        "Llegamos. Doña Rosa ya debe estar dormida, pero nos dejó la luz prendida.",
        "",
    ),
    ("intro_javier_2", "javier", "Mañana salimos al amanecer, si la lluvia nos deja.", ""),
    (
        "intro_lucia_1",
        "lucia",
        "Voy a sacar unas fotos. Con el agua, el cielo se ve dos veces.",
        "",
    ),
    (
        "intro_javier_3",
        "javier",
        "No te alejes. Con esta agua no se sabe dónde termina el salar.",
        "",
    ),
    ("final1_lucia_1", "lucia", "Última foto.", ""),
    ("final1_javier_1", "javier", "¿Lucía? ¿Qué hago acá? Estaba en el baño, y el espejo...", ""),
    ("final1_lucia_2", "lucia", "Ya pasó. Vámonos, Javier.", ""),
    ("final2_lucia_1", "lucia", "Llévate el mío. Pero devuélvemelo a él.", ""),
    ("final2_javier_1", "javier", "Una foto para el recuerdo, antes de irnos.", ""),
    ("final2_lucia_2", "lucia", "Javier. No te quedes mirando el agua.", "agua"),
    ("final3_javier_1", "javier", "¿Nos vamos, Lucía?", ""),
    ("final3_lucia_1", "lucia", "Vamos.", "otra"),
    ("robada_javier_1", "javier", "Lucía... ¿dónde estás?", "robada"),
    ("robada_javier_2", "javier", "Lucía, ven. Estoy acá, en el espejo.", "robada"),
    ("robada_javier_3", "javier", "No te asustes. Soy yo.", "robada"),
    ("robada_rosa_1", "rosa", "Señorita... ¿ya tapó los espejos?", "robada"),
    ("robada_rosa_2", "rosa", "Venga a la cocina, que se le enfría el api.", "robada"),
    ("celestino_1", "celestino", "Llegaste, hija. Rosa me avisó que vendrías.", ""),
    (
        "celestino_2",
        "celestino",
        "El Quispi no es malo ni bueno. Es el salar mirándose a sí mismo. Cuando alguien se queda "
        "mucho rato mirando el agua, el agua aprende su cara.",
        "",
    ),
    (
        "celestino_3",
        "celestino",
        "A tu amigo lo tiene en el reflejo. Para devolverlo, hay que darle algo a cambio.",
        "",
    ),
    (
        "celestino_4",
        "celestino",
        "Las ofrendas en las apachetas, si las dejaste. O algo tuyo... tu propio reflejo, "
        "si no te queda otra.",
        "",
    ),
    (
        "celestino_5",
        "celestino",
        "Anda al centro del salar antes que amanezca, y llévate la cámara. Lo que la luz muestra, "
        "el agua no se lo puede quedar.",
        "",
    ),
]


def main():
    """Sintetiza cada línea, le baja el tono si hace falta y la guarda en Ogg."""
    voices_dir, out_dir = sys.argv[-2], sys.argv[-1]
    os.makedirs(out_dir, exist_ok=True)
    for name, who, text, effect in LINES:
        if os.path.exists(os.path.join(out_dir, name + ".ogg")):
            continue
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
            filters += "apad=pad_dur=0.3" + EFFECTS[effect]
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
