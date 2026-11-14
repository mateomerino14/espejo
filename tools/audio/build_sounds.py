"""Arma los sonidos de Espejo a partir de grabaciones CC0 de Freesound.

Recorta pasos, clics de la cámara, papel y puertas; arma los bucles de viento y lámpara; y compone
las tres capas de música (calma, tensión y persecución) y las frases de quena.

Uso:
  1. Descargar las vistas previas de cada id de freesound_ids.json como dl/<id>.ogg
     (https://freesound.org/s/<id>/; todas son CC0).
  2. Pasarlas a WAV mono: ffmpeg -i dl/<id>.ogg -ac 1 -ar 44100 wav/<id>.wav
  3. python3 build_sounds.py  (desde la carpeta que tiene wav/; escribe en out/)
  4. Copiar out/* a assets/audio/.
"""

import os
import subprocess

import numpy as np
import scipy.io.wavfile as w
import scipy.signal as sg

SR = 44100
os.makedirs("out", exist_ok=True)


def load(i):
    """Lee una grabación ya pasada a WAV mono."""
    sr, x = w.read(f"wav/{i}.wav")
    return x.astype(np.float32) / 32768


def env(x, hop=441):
    """Envolvente de energía en ventanas de 10 ms."""
    n = len(x) // hop
    return np.sqrt((x[: n * hop].reshape(n, hop) ** 2).mean(1) + 1e-12)


def save(path, x, peak_db=-3.0):
    """Guarda en WAV normalizando el pico."""
    x = x / (np.abs(x).max() + 1e-9) * 10 ** (peak_db / 20)
    w.write(path, SR, (x * 32767).astype(np.int16))


def fade(x, fi=0.003, fo=0.05):
    """Rampa de entrada y de salida para que no haya clics."""
    x = x.copy()
    a = int(fi * SR)
    b = int(fo * SR)
    x[:a] *= np.linspace(0, 1, a)
    x[-b:] *= np.linspace(1, 0, b)
    return x


def hp(x, f=60):
    """Filtro pasaaltos."""
    b, a = sg.butter(2, f / (SR / 2), "high")
    return sg.lfilter(b, a, x).astype(np.float32)


def onsets(x, min_gap=0.35, count=12, thresh_db=-30):
    """Picos de energía separados al menos min_gap segundos: golpes, pasos o notas."""
    e = env(x)
    peaks, _ = sg.find_peaks(
        e, distance=int(min_gap * 100), height=e.max() * 10 ** (thresh_db / 20)
    )
    order = sorted(peaks, key=lambda p: -e[p])[:count]
    return sorted(order), e


# --- Pasos ---
SRC = {
    "salt": ("559459", 0.4),
    "dirt": ("264469", 0.35),
    "wood": ("331451", 0.35),
    "water": ("106395", 0.3),
}
for k, (name, (i, gap)) in enumerate(SRC.items()):
    x = hp(load(i), 80)
    ons, e = onsets(x, min_gap=gap, count=40, thresh_db=-25)
    ener = np.array([e[p] for p in ons])
    med = np.median(ener)
    pick = sorted(ons, key=lambda p: abs(np.log(e[p] / med)))[:4]
    for j, p in enumerate(sorted(pick)):
        q = p
        while q > p - 25 and e[q - 1] > e[p] * 10 ** (-25 / 20):
            q -= 1
        a = max(0, int((q / 100 - 0.02) * SR))
        b = a + int(0.55 * SR)
        seg = fade(x[a:b], 0.004, 0.15)
        save(f"out/footstep_{name}_{j+1}.wav", seg, -6)

rng = np.random.default_rng(7)


def seg(i, a, b):
    """Recorta una grabación entre dos tiempos."""
    x = load(i)
    return x[int(a * SR) : int(b * SR)]


def lp(x, f):
    """Filtro pasabajos."""
    b, a = sg.butter(2, f / (SR / 2))
    return sg.lfilter(b, a, x).astype(np.float32)


def bp(x, lo, hi):
    """Filtro pasabanda."""
    b, a = sg.butter(2, [lo / (SR / 2), hi / (SR / 2)], "band")
    return sg.lfilter(b, a, x).astype(np.float32)


def ir(t60, seed):
    """Respuesta de una sala: ruido que se apaga en t60 segundos."""
    r = np.random.default_rng(seed)
    n = int(t60 * SR)
    t = np.arange(n) / SR
    h = r.standard_normal(n) * np.exp(-6.9 * t / t60)
    h = lp(h.astype(np.float32), 5000)
    h[: int(0.02 * SR)] *= np.linspace(0, 1, int(0.02 * SR))
    return h / np.sqrt((h**2).sum())


def reverb(x, t60=3.0, wet=0.5, stereo=False):
    """Agrega la cola de la sala, en mono o estéreo."""
    tail = int(t60 * SR)
    xx = np.concatenate([x, np.zeros(tail, np.float32)])
    outs = []
    for s in ([1, 2] if stereo else [1]):
        r = sg.fftconvolve(xx, ir(t60, s))[: len(xx)]
        outs.append((1 - wet) * xx + wet * r * 0.5)
    return np.stack(outs, 1) if stereo else outs[0]


def save_ogg(name, x, peak_db=-3.0, q=6):
    """Guarda en Ogg Vorbis normalizando el pico."""
    x = x / (np.abs(x).max() + 1e-9) * 10 ** (peak_db / 20)
    w.write("tmp.wav", SR, (x * 32767).astype(np.int16))
    subprocess.run(
        [
            "ffmpeg",
            "-v",
            "error",
            "-y",
            "-i",
            "tmp.wav",
            "-c:a",
            "libvorbis",
            "-q:a",
            str(q),
            f"out/{name}.ogg",
        ],
        check=True,
    )


def save_wav(name, x, peak_db=-3.0):
    """Guarda un efecto en out/."""
    save(f"out/{name}.wav", x, peak_db)


def loop(x, length, xf=2.0):
    """Une el final con el principio para que el bucle no tenga costura."""
    n = int(length * SR)
    m = int(xf * SR)
    x = x[: n + m].copy()
    if x.ndim == 1:
        r = np.linspace(0, 1, m)
    else:
        r = np.linspace(0, 1, m)[:, None]
    head = x[:m] * r + x[n : n + m] * (1 - r)
    y = x[:n].copy()
    y[:m] = head
    return y


def trim(x, db=-40, tail=0.05):
    """Quita el silencio de los extremos."""
    e = env(x, 44)
    idx = np.where(e > e.max() * 10 ** (db / 20))[0]
    a = max(0, idx[0] * 44 - 100)
    b = min(len(x), (idx[-1] + 1) * 44 + int(tail * SR))
    return fade(x[a:b], 0.002, min(0.05, (b - a) / SR / 4))


# --- Cámara ---
sh = seg("734819", 0.04, 0.55)
save_wav("camera_shutter", fade(hp(sh, 80), 0.002, 0.08), -1)
adv = seg("734819", 1.1, 1.5)
save_wav("camera_advance", trim(hp(adv, 150)), -6)
h = load("516487")
ons, e = onsets(h, min_gap=0.3, count=8, thresh_db=-20)
clicks = []
for p in ons:
    a = int(p / 100 * SR) - int(0.01 * SR)
    clicks.append(fade(hp(h[a : a + int(0.12 * SR)], 300), 0.001, 0.05))
clicks.sort(key=lambda c: -np.abs(c).max())
rus = load("235243")
r_ons, re_ = onsets(rus, min_gap=0.4, count=6, thresh_db=-15)


def rustle(k, length):
    """Roce de la correa sacado de la chaqueta."""
    a = int(r_ons[k] / 100 * SR) - int(0.05 * SR)
    y = lp(rus[a : a + int(length * SR)], 6000)
    return fade(y, 0.02, length * 0.6)


raise_ = rustle(0, 0.35) * 0.5
c = clicks[0]
o = int(0.22 * SR)
raise_[o : o + len(c)] += c * 0.9
save_wav("camera_raise", raise_, -8)
lower = rustle(1, 0.3) * 0.5
c = clicks[1]
o = int(0.05 * SR)
lower[o : o + len(c)] += c * 0.6
save_wav("camera_lower", lower, -12)
save_wav("camera_dry_fire", clicks[2] + 0, -8)
t = np.arange(int(1.4 * SR)) / SR
f = 1800 + 5200 * (1 - np.exp(-t / 0.45))
ph = 2 * np.pi * np.cumsum(f) / SR
whine = (
    (np.sin(ph) + 0.3 * np.sin(2 * ph))
    * np.minimum(1, t / 0.05)
    * np.exp(-np.maximum(0, t - 1.0) / 0.12)
)
whine += rng.standard_normal(len(t)) * 0.02
save_wav("camera_flash_charge", fade(whine.astype(np.float32), 0.01, 0.2), -22)

# --- Notas y puertas ---
save_wav("paper_pick", trim(hp(seg("151231", 0.0, 0.9), 120)), -6)
save_wav("paper_open", trim(hp(seg("136778", 0.08, 1.75), 120)), -6)
save_wav("paper_fold", trim(hp(seg("197179", 0.35, 1.1), 120)), -8)
save_wav("door_locked", trim(hp(load("321087"), 80), -45), -6)

# --- Ambiente ---
wind = hp(load("156414"), 40)
wind2 = hp(load("104320"), 40)
n = min(len(wind), len(wind2))
mix = wind[:n] / np.sqrt((wind**2).mean()) + 0.6 * wind2[:n] / np.sqrt((wind2**2).mean())
save_ogg("amb_wind", loop(lp(mix, 9000), 40, 3), -8)
fire = lp(hp(load("483311"), 200), 5000)
save_ogg("amb_lamp", loop(fire, 24, 2), -10)
cr = hp(load("342546"), 200)
ons, e = onsets(cr, min_gap=0.5, count=6, thresh_db=-25)
for k, p in enumerate(sorted(ons)[:5]):
    a = int(p / 100 * SR) - int(0.02 * SR)
    y = fade(cr[a : a + int(0.6 * SR)], 0.003, 0.3)
    save_wav(f"salt_crack_{k+1}", reverb(y, 1.8, 0.35), -6)
dr = hp(load("177958"), 300)
ons, e = onsets(dr, min_gap=0.8, count=30, thresh_db=-15)
for k, p in enumerate(sorted(ons, key=lambda p: -e[p])[:4]):
    a = int(p / 100 * SR) - int(0.01 * SR)
    y = fade(dr[a : a + int(0.5 * SR)], 0.002, 0.3)
    save_wav(f"drip_{k+1}", y, -6)
print("efectos listos")


# --- Música ---
def tone(f, dur, saw=True):
    """Diente de sierra o seno de frecuencia fija."""
    t = np.arange(int(dur * SR)) / SR
    ph = (f * t + rng.random()) % 1
    return (2 * ph - 1).astype(np.float32) if saw else np.sin(2 * np.pi * ph).astype(np.float32)


def drone(dur, notes, cut=300, lfo=0.05):
    """Bordón grave con un filtro que respira despacio."""
    x = sum(tone(f * (1 + d), dur) for f in notes for d in (-0.003, 0.003))
    t = np.arange(len(x)) / SR
    # filtro que respira: mezcla dos pasabajos según un LFO lento
    a = lp(x, cut * 0.5)
    b = lp(x, cut * 2)
    m = 0.5 + 0.5 * np.sin(2 * np.pi * lfo * t)
    return (a * (1 - m) + b * m).astype(np.float32)


def norm(x):
    """Lleva la señal a energía 1."""
    return x / np.sqrt((x**2).mean() + 1e-12)


def place(buf, x, at, gain=1.0):
    """Suma un sonido dentro de otro en un tiempo dado."""
    a = int(at * SR)
    b = min(len(buf), a + len(x))
    buf[a:b] += x[: b - a] * gain


def shift(x, cents):
    """Desafina unos centésimos de semitono."""
    r = 2 ** (cents / 1200)
    idx = np.arange(0, len(x) - 1, r)
    return np.interp(idx, np.arange(len(x)), x).astype(np.float32)


E1, B1, E2, F2, B2 = 41.2, 61.74, 82.41, 87.31, 123.47
L = 48.0
# Calma: bordón grave y viento tonal
calm = norm(drone(L + 3, [E1, B1, E2], 260, 1 / 16)) * 0.6
tw = hp(load("397091"), 60)
calm += norm(np.resize(tw, len(calm))) * 0.35
save_ogg("music_calm", loop(calm, L, 3), -10)
# Quena lejana: frases de la escala de MarleneAyni con caída de afinación
q = load("569392")
qn = {"E5": 22.57, "G5": 30.25, "A5": 35.67, "B5": 37.37, "D6": 44.36, "E6": 48.36}


def note(n, dur):
    """Una nota de la quena, recortada de la escala."""
    a = int((qn[n] - 0.03) * SR)
    y = hp(q[a : a + int(0.45 * SR)], 250)
    y = fade(y, 0.03, 0.15)
    y = norm(y)
    return y[: int(dur * SR)] if dur < 0.45 else y


phrases = [
    ["B5", "A5", "G5", "E5"],
    ["E5", "G5", "A5", "G5", "E5"],
    ["D6", "B5", "A5"],
    ["E6", "D6", "B5", "G5", "A5"],
]
for k, ph in enumerate(phrases):
    buf = np.zeros(int((0.42 * len(ph) + 0.6) * SR), np.float32)
    for j, n in enumerate(ph):
        place(buf, note(n, 0.45), j * 0.42)
    buf = shift(buf, -15 - 10 * k)
    buf = lp(buf, 3500)
    save_ogg(f"quena_{k+1}", reverb(buf, 4.5, 0.75, stereo=True), -9)
# Bombo: golpes sueltos
bo = hp(load("754166"), 30)
ons, e = onsets(bo, min_gap=0.2, count=20, thresh_db=-12)
hits = []
for p in sorted(ons):
    a = max(0, int(p / 100 * SR) - int(0.03 * SR))
    hits.append(fade(bo[a : a + int(0.45 * SR)], 0.001, 0.2))
hits.sort(key=lambda h: -np.abs(h).max())
boom, rim = norm(hits[0]), norm(hits[-1])
# Tensión: bordón con segunda menor, raspado grave de chelo y latido
LT = 32.0
ten = norm(drone(LT + 3, [E1, E2, F2], 380, 1 / 8)) * 0.5
sc = bp(load("571173"), 80, 2500)
ten += norm(np.resize(sc, len(ten))) * 0.45
for t in np.arange(0, LT + 2, 1.6):
    place(ten, lp(boom, 400), t, 0.5)
    place(ten, lp(boom, 400), t + 0.32, 0.3)
save_ogg("music_tension", loop(ten, LT, 2), -8)
# Persecución: 6/8 de bombo legüero a 150, violín raspado y bordón fuerte
eighth = 0.2
bar = 6 * eighth
LC = bar * 12
ch = norm(drone(LC + 2, [E1, E2, F2, B2], 700, 1 / 2.4)) * 0.45
pattern = [(0, boom, 1.0), (2 * eighth, rim, 0.5), (3 * eighth, boom, 0.8), (5 * eighth, rim, 0.6)]
for b in range(12):
    for off, h, g in pattern:
        place(ch, h, b * bar + off, g * 1.2)
vs = hp(load("159161"), 200)
vo, ve = onsets(vs, min_gap=1.0, count=12, thresh_db=-15)
for k, b in enumerate(range(0, 12, 2)):
    p = sorted(vo)[k % len(vo)]
    a = int(p / 100 * SR)
    y = fade(vs[a : a + int(bar * 1.4 * SR)], 0.02, 0.4)
    place(ch, norm(y), b * bar + eighth * 3, 0.35)
save_ogg("music_chase", loop(reverb(ch, 1.2, 0.25), LC, 0.3), -3)
print("musica lista", LC)

# --- Cinemática de inicio ---
rain = hp(load("704395"), 80)
heavy = hp(load("624645"), 80)
n = min(len(rain), int(42 * SR))
rain_mix = norm(rain[:n]) + 0.5 * norm(np.resize(heavy, n))
save_ogg("amb_rain", loop(rain_mix, 40, 2), -6)
save_ogg("thunder_far", fade(hp(load("267550"), 30)[: int(30 * SR)], 0.05, 4.0), -3)
save_ogg("thunder_near", fade(hp(load("534023"), 30), 0.01, 3.0), -1)
save_ogg("car_arrive", fade(hp(load("249916"), 30)[: int(13 * SR)], 0.05, 2.0), -3)
save_wav("car_door", trim(hp(load("208695"), 60), -45), -2)
print("cinemática lista")
