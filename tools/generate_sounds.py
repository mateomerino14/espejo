"""Genera los sonidos de la cámara de Lucía y del ente con síntesis simple.

Uso: python3 tools/generate_sounds.py assets/audio
"""

import sys
import wave
from pathlib import Path

import numpy as np

RATE = 44100
rng = np.random.default_rng(7)


def seconds(length):
    """Devuelve el eje de tiempo para la duración indicada."""
    return np.arange(int(RATE * length)) / RATE


def resonate(signal, frequency, damping):
    """Pasa la señal por un resonador de dos polos, como una pieza de metal que vibra."""
    radius = np.exp(-damping / RATE)
    theta = 2.0 * np.pi * frequency / RATE
    a1, a2 = -2.0 * radius * np.cos(theta), radius * radius
    out = np.zeros_like(signal)
    for i in range(len(signal)):
        out[i] = signal[i] - a1 * out[i - 1] - a2 * out[i - 2]
    return out / (np.abs(out).max() + 1e-9)


def click(length, frequencies, decay):
    """Un golpe mecánico corto: ruido que se apaga rápido y hace sonar unas resonancias."""
    t = seconds(length)
    burst = rng.standard_normal(len(t)) * np.exp(-t * decay)
    body = sum(resonate(burst, f, 900.0) for f in frequencies)
    return 0.6 * burst / np.abs(burst).max() + 0.4 * body / len(frequencies)


def shutter():
    """Obturador: la cortina abre y cierra con dos golpes secos."""
    gap = np.zeros(int(RATE * 0.045))
    tail = np.zeros(int(RATE * 0.12))
    first = click(0.03, (2400.0, 5200.0), 220.0)
    second = click(0.05, (1800.0, 4100.0), 140.0) * 0.8
    return np.concatenate([first, gap, second, tail])


def focus():
    """Motor del enfoque: un zumbido que va y viene y termina con un tic."""
    t = seconds(0.32)
    hum = np.sin(2 * np.pi * (520.0 + 140.0 * np.sin(2 * np.pi * 9.0 * t)) * t)
    grit = rng.standard_normal(len(t)) * 0.25
    envelope = np.minimum(t / 0.03, 1.0) * np.exp(-t * 4.0)
    whirr = (hum + grit) * envelope * 0.35
    return np.concatenate([whirr, click(0.02, (3500.0,), 300.0) * 0.4])


def glass_cracks(length, count):
    """Crujidos secos de vidrio o sal que se quiebra, repartidos al azar."""
    out = np.zeros(int(RATE * length))
    for start in rng.integers(0, len(out) - RATE // 20, count):
        crack = click(0.02, (rng.uniform(3000.0, 7000.0),), 400.0) * rng.uniform(0.3, 1.0)
        out[start:start + len(crack)] += crack
    return out


def shriek(length, base, rise):
    """Chillido vidrioso: varias voces agudas desafinadas que suben y tiemblan."""
    t = seconds(length)
    pitch = base * (1.0 + rise * t / length) * (1.0 + 0.02 * np.sin(2 * np.pi * 7.0 * t))
    phase = 2 * np.pi * np.cumsum(pitch) / RATE
    voices = sum(np.sin(phase * ratio + i) for i, ratio in enumerate((1.0, 1.013, 2.02, 2.97)))
    breath = resonate(rng.standard_normal(len(t)), base * 3.0, 300.0) * 0.5
    envelope = np.minimum(t / 0.08, 1.0) * np.exp(-t * 2.5 / length)
    return (voices / 4.0 + breath) * envelope


def stunned():
    """El ente aturdido: chilla y la sal de su cuerpo cruje."""
    return shriek(1.2, 880.0, -0.4) + glass_cracks(1.2, 14) * 0.6


def scream():
    """Grito al atrapar a Lucía: crece de golpe y se quiebra."""
    body = shriek(1.6, 620.0, 0.9)
    return body + glass_cracks(1.6, 30) * 0.8


def write(path, signal, gain):
    """Normaliza y guarda la señal como WAV mono de 16 bits."""
    signal = signal / (np.abs(signal).max() + 1e-9) * gain
    fade = np.minimum(np.arange(len(signal))[::-1] / (RATE * 0.005), 1.0)
    data = (signal * fade * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(data.tobytes())


def main():
    """Genera cada sonido en la carpeta indicada."""
    folder = Path(sys.argv[1])
    folder.mkdir(parents=True, exist_ok=True)
    write(folder / "shutter.wav", shutter(), 0.8)
    write(folder / "focus.wav", focus(), 0.5)
    write(folder / "qispi_stunned.wav", stunned(), 0.8)
    write(folder / "qispi_scream.wav", scream(), 0.95)
    print("sonidos generados")


if __name__ == "__main__":
    main()
