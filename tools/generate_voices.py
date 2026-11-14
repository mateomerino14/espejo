"""Genera las voces del juego con Chatterbox: cada personaje imita su muestra de timbre
(tools/audio_sources/voice_refs, armadas con tools/audio/build_voice_refs.py) y actúa su línea con la
emoción que le toca. Whisper escucha cada toma y se queda con la que mejor se entiende.

Uso: python3 tools/generate_voices.py [ids]
Sin ids rehace todas; con ids, solo esas. Requiere chatterbox-tts, faster-whisper, torchaudio y
ffmpeg.
"""

import difflib
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import torch
import torchaudio
from chatterbox.mtl_tts import ChatterboxMultilingualTTS
from faster_whisper import WhisperModel

ROOT = Path(__file__).resolve().parent.parent
OUTPUT_DIR = ROOT / "assets" / "audio" / "voices"
REFS_DIR = ROOT / "tools" / "audio_sources" / "voice_refs"
OUTPUT_RATE = 44100
PEAK_DB = -1.0
SEED = 1545
LANGUAGE = "es"

# Afuera, en el salar, casi no hay eco; los efectos cambian el lugar o a quien habla.
OPEN_AIR = "apad=pad_dur=0.6,aecho=0.8:0.4:60|140:0.15|0.08"
EFFECTS = {
    "": OPEN_AIR,
    # La voz que sube del agua: lejana y con eco.
    "agua": "apad=pad_dur=1.5,aecho=0.8:0.7:180|420:0.45|0.3,lowpass=f=3200",
    # La otra Lucía: más grave y lenta.
    "otra": "asetrate=44100*0.9,aresample=44100,atempo=1.05," + OPEN_AIR,
    # Una voz robada por el Q'ispi: tiembla y suena desde dentro de un espejo.
    "robada": "apad=pad_dur=1.2,vibrato=f=5.5:d=0.25,aecho=0.7:0.6:90|230:0.35|0.2,highpass=f=220,"
    "lowpass=f=3600",
}

# Emociones: exageración de Chatterbox (más es más intenso) y peso de la guía (menos es más pausado).
EMOTIONS = {
    "calm": (0.45, 0.5),
    "warm": (0.55, 0.45),
    "uneasy": (0.65, 0.35),
    "fear": (0.75, 0.35),
    "firm": (0.6, 0.45),
    "ghost": (0.6, 0.3),
    "slow": (0.5, 0.3),
}

# Cada línea: archivo, personaje, texto, emoción y efecto.
LINES = [
    ("intro_javier_1", "javier", "Llegamos. Doña Rosa ya debe estar dormida, pero nos dejó la luz prendida.",
     "warm", ""),
    ("intro_javier_2", "javier", "Mañana salimos al amanecer, si la lluvia nos deja.", "calm", ""),
    ("intro_lucia_1", "lucia", "Voy a sacar unas fotos. Con el agua, el cielo se ve dos veces.", "warm", ""),
    ("intro_javier_3", "javier", "No te alejes. Con esta agua no se sabe dónde termina el salar.", "firm", ""),
    ("final1_lucia_1", "lucia", "Última foto.", "calm", ""),
    ("final1_javier_1", "javier", "¿Lucía? ¿Qué hago acá? Estaba en el baño, y el espejo...", "uneasy", ""),
    ("final1_lucia_2", "lucia", "Ya pasó. Vámonos, Javier.", "warm", ""),
    ("final2_lucia_1", "lucia", "Llévate el mío. Pero devuélvemelo a él.", "uneasy", ""),
    ("final2_javier_1", "javier", "Una foto para el recuerdo, antes de irnos.", "warm", ""),
    ("final2_lucia_2", "lucia", "Javier. No te quedes mirando el agua.", "fear", "agua"),
    ("final3_javier_1", "javier", "¿Nos vamos, Lucía?", "calm", ""),
    ("final3_lucia_1", "lucia", "Vamos.", "slow", "otra"),
    ("robada_javier_1", "javier", "Lucía... ¿dónde estás?", "ghost", "robada"),
    ("robada_javier_2", "javier", "Lucía, ven. Estoy acá, en el espejo.", "ghost", "robada"),
    ("robada_javier_3", "javier", "No te asustes. Soy yo.", "ghost", "robada"),
    ("robada_rosa_1", "rosa", "Señorita... ¿ya tapó los espejos?", "ghost", "robada"),
    ("robada_rosa_2", "rosa", "Venga a la cocina, que se le enfría el api.", "ghost", "robada"),
    ("celestino_1", "celestino", "Llegaste, hija. Rosa me avisó que vendrías.", "slow", ""),
    ("celestino_2", "celestino",
     "El Quispi no es malo ni bueno. Es el salar mirándose a sí mismo. Cuando alguien se queda mucho "
     "rato mirando el agua, el agua aprende su cara.", "slow", ""),
    ("celestino_3", "celestino",
     "A tu amigo lo tiene en el reflejo. Para devolverlo, hay que darle algo a cambio.", "slow", ""),
    ("celestino_4", "celestino",
     "Las ofrendas en las apachetas, si las dejaste. O algo tuyo... tu propio reflejo, si no te queda "
     "otra.", "slow", ""),
    ("celestino_5", "celestino",
     "Anda al centro del salar antes que amanezca, y llévate la cámara. Lo que la luz muestra, el agua "
     "no se lo puede quedar.", "slow", ""),
    ("lucia_transito_vacio", "lucia", "No me voy a ir sin Javier. Tengo que volver a entrar.", "firm", ""),
    ("lucia_transito_trenes", "lucia", "Tapé todos los espejos... pero afuera, el agua también es un espejo.",
     "uneasy", ""),
    ("lucia_transito_isla", "lucia", "Es el sombrero de Javier. Si alguien sabe qué es esto, está en esa isla.",
     "fear", ""),
    ("lucia_transito_centro", "lucia", "Algo a cambio, dijo Don Celestino. ¿Y si lo único que tengo es mi cara?",
     "uneasy", ""),
]

# Tomas por línea y parecido mínimo entre lo que se oye y el texto para aceptar una toma.
MAX_TAKES = 5
MIN_MATCH = 0.9


def ffmpeg(*args):
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", *map(str, args)], check=True)


def words(text):
    """Las palabras de un texto, sin signos ni mayúsculas, para compararlo con lo transcrito."""
    return re.sub(r"[^a-záéíóúüñ ]", " ", text.lower()).split()


def match(heard, text):
    """Qué tanto se parece lo transcrito al texto, de 0 a 1."""
    return difflib.SequenceMatcher(None, words(heard), words(text)).ratio()


def act(model, listener, text, speaker, emotion, out):
    """Dice el texto con la emoción y el timbre del personaje; pide tomas hasta que se entienda."""
    exaggeration, guidance = emotion
    best_score = -1.0
    best_take = None
    for take in range(MAX_TAKES):
        torch.manual_seed(SEED + take)
        wav = model.generate(text, language_id=LANGUAGE, audio_prompt_path=str(REFS_DIR / f"{speaker}.wav"),
                             exaggeration=exaggeration, cfg_weight=guidance)
        torchaudio.save(str(out), wav, model.sr)
        segments, _ = listener.transcribe(str(out), language=LANGUAGE)
        score = match("".join(s.text for s in segments), text)
        if score > best_score:
            best_score = score
            best_take = wav
        if score >= MIN_MATCH:
            break
    torchaudio.save(str(out), best_take, model.sr)
    return best_score


def volume_db(path):
    """Mide el pico de un audio en dB."""
    result = subprocess.run(["ffmpeg", "-i", str(path), "-af", "volumedetect", "-f", "null", "-"],
                            capture_output=True, text=True, check=True)
    return float(re.search(r"max_volume: (-?[0-9.]+) dB", result.stderr).group(1))


def finish(source, effect, out, tmp):
    """Pone el efecto, iguala el pico, quita el silencio final y guarda en Ogg."""
    placed = tmp / "placed.wav"
    ffmpeg("-i", source, "-af", "aresample=44100,highpass=f=80,lowpass=f=7500," + EFFECTS[effect], "-ar",
           OUTPUT_RATE, placed)
    gain = PEAK_DB - volume_db(placed)
    trim = f"volume={gain:.2f}dB,areverse,silenceremove=start_periods=1:start_threshold=-55dB,areverse"
    ffmpeg("-i", placed, "-af", trim, "-c:a", "libvorbis", "-q:a", "5", out)


def main():
    """Genera todas las voces; con ids, solo esas líneas."""
    only = set(sys.argv[1:])
    model = ChatterboxMultilingualTTS.from_pretrained(device="cpu")
    listener = WhisperModel("small", device="cpu", compute_type="int8")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, speaker, text, emotion, effect in LINES:
        if only and name not in only:
            continue
        with tempfile.TemporaryDirectory() as tmp:
            raw = Path(tmp) / "raw.wav"
            score = act(model, listener, text, speaker, EMOTIONS[emotion], raw)
            finish(raw, effect, OUTPUT_DIR / f"{name}.ogg", Path(tmp))
        print(f"voz {name} (se entiende {score:.0%})", flush=True)


if __name__ == "__main__":
    main()
