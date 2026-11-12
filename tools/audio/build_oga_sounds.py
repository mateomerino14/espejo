"""Arma los sonidos de puertas y escondites con grabaciones CC0 de OpenGameArt.

`oga_sources.json` dice de dónde sale cada paquete. Este script los baja a una carpeta aparte,
los descomprime y mezcla con ffmpeg:

- door_open: el pestillo y la puerta que se abre, con un crujido largo de bisagra encima.
- door_shut: la puerta que golpea el marco y queda cerrada.
- wardrobe_enter / wardrobe_leave: la puerta del ropero que chirría y se cierra, o se abre.
- locker_enter / locker_leave: la puerta de lata del casillero, al entrar con un golpe.

Uso: python3 tools/audio/build_oga_sounds.py <carpeta_de_descarga> assets/audio
Necesita ffmpeg y py7zr.
"""

import json
import os
import subprocess
import sys
import urllib.request
import zipfile

import py7zr

SOURCES = os.path.join(os.path.dirname(__file__), "oga_sources.json")
PEAK_DB = -3.0
# Cola de cada capa, para que el corte no haga clic.
FADE = 0.06
# Cada sonido: lista de capas (archivo, desde, hasta, en qué momento entra, ganancia en dB)
DOOR_SET = "qubodup_door_set/qubodup-DoorSet/ogg/"
WOOD = "wood_metal_sfx/"
HINGE = "creaky_door_hinge/creaky_door_hinge.wav"
MIXES = {
    "door_open": [
        (DOOR_SET + "qubodup-DoorOpen03.ogg", 0.0, 1.0, 0.0, 0.0),
        (HINGE, 0.28, 2.2, 0.3, 4.0),
    ],
    "door_shut": [(DOOR_SET + "qubodup-DoorClose06.ogg", 0.0, 0.9, 0.0, 0.0)],
    "wardrobe_enter": [
        (WOOD + "wood_squeak_02.ogg", 0.0, 0.39, 0.0, 0.0),
        (WOOD + "wood_close_01.ogg", 0.0, 0.4, 0.55, -2.0),
    ],
    "wardrobe_leave": [
        (WOOD + "wood_squeak_01.ogg", 0.0, 0.48, 0.0, 0.0),
        (HINGE, 0.28, 0.9, 0.15, -2.0),
    ],
    "locker_enter": [
        (WOOD + "metal_open_01.ogg", 0.0, 0.8, 0.0, 0.0),
        (WOOD + "metal_slam_01.ogg", 0.0, 0.57, 0.7, -6.0),
    ],
    "locker_leave": [(WOOD + "metal_open_01.ogg", 0.0, 1.15, 0.0, 0.0)],
}


def download(work):
    """Baja y descomprime cada paquete en su propia carpeta."""
    for name, source in json.load(open(SOURCES)).items():
        folder = os.path.join(work, name)
        if os.path.isdir(folder):
            continue
        os.makedirs(folder)
        target = os.path.join(folder, os.path.basename(source["url"]))
        urllib.request.urlretrieve(source["url"], target)
        if target.endswith(".7z"):
            py7zr.SevenZipFile(target).extractall(folder)
        elif target.endswith(".zip"):
            zipfile.ZipFile(target).extractall(folder)


def peak_db(path):
    """Pico del archivo en dB."""
    probe = subprocess.run(
        ["ffmpeg", "-i", path, "-af", "volumedetect", "-f", "null", "-"],
        capture_output=True,
        text=True,
    ).stderr
    return float(probe.split("max_volume: ")[1].split(" dB")[0])


def mix(work, layers, out_path):
    """Recorta cada capa, la corre en el tiempo, las suma y deja el pico en PEAK_DB."""
    inputs, chains = [], []
    for index, (path, start, end, delay, gain) in enumerate(layers):
        inputs += ["-i", os.path.join(work, path)]
        chains.append(
            f"[{index}:a]atrim={start}:{end},asetpts=PTS-STARTPTS,aformat=channel_layouts=mono,"
            f"aresample=44100,volume={gain}dB,afade=t=out:st={end - start - FADE}:d={FADE},"
            f"adelay={int(delay * 1000)}[a{index}]"
        )
    labels = "".join(f"[a{index}]" for index in range(len(layers)))
    graph = ";".join(chains) + f";{labels}amix=inputs={len(layers)}:normalize=0,highpass=f=50"
    raw = out_path + ".wav"
    subprocess.run(
        ["ffmpeg", "-v", "error", "-y", *inputs, "-filter_complex", graph, raw], check=True
    )
    gain = PEAK_DB - peak_db(raw)
    subprocess.run(
        ["ffmpeg", "-v", "error", "-y", "-i", raw, "-af", f"volume={gain}dB"]
        + ["-c:a", "libvorbis", "-q:a", "6", out_path],
        check=True,
    )
    os.remove(raw)


def main():
    """Baja los paquetes y arma cada sonido."""
    work, out_dir = sys.argv[1:3]
    download(work)
    for name, layers in MIXES.items():
        mix(work, layers, os.path.join(out_dir, name + ".ogg"))
        print("listo", name)


main()
