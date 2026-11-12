"""Descarga texturas escaneadas de Poly Haven (CC0) y las deja listas para los materiales.

Cada textura trae color, normales (convención OpenGL, la de Godot) y ARM (oclusión, rugosidad,
metal), que en Godot se usa como ORM. Las que llevan paleta se recolorean por luminancia: se
conserva todo el detalle real de la foto, pero con los tonos de la sal.

Uso: python3 tools/download_textures.py assets/textures/salar 2k [nombres...]
"""

import io
import json
import sys
import urllib.request
from pathlib import Path

import numpy as np
from PIL import Image

API = "https://api.polyhaven.com/files/"
# Poly Haven rechaza pedidos sin un agente identificable.
HEADERS = {"User-Agent": "espejo-texturas/1.0 (github.com/mateomerino14/espejo)"}

# nombre en el juego: (asset de Poly Haven, paleta oscura y clara en sRGB o None, autor)
TEXTURES = {
    "salt_block": ("concrete_block_wall_03", ((0.5, 0.48, 0.44), (0.93, 0.92, 0.89)), "Charlotte Baglioni"),
    "salt_crust": ("dry_ground_01", ((0.55, 0.54, 0.51), (0.96, 0.96, 0.95)), "Rob Tuytel"),
    "planks": ("dark_wooden_planks", None, "Amal Kumar"),
    "rusty_metal": ("rusty_metal_02", None, "Rob Tuytel"),
    "corrugated": ("rusty_corrugated_iron", None, "Charlotte Baglioni"),
    "dry_mud": ("brown_mud_dry", ((0.3, 0.27, 0.24), (0.72, 0.68, 0.62)), "Rob Tuytel"),
}
# Recortes de luminancia para normalizar antes de aplicar la paleta
LOW_PERCENTILE, HIGH_PERCENTILE = 2, 98
JPEG_QUALITY = 92


def get(url):
    """Descarga una dirección y devuelve sus bytes."""
    with urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS)) as response:
        return response.read()


def fetch(url):
    """Descarga un archivo y lo devuelve como imagen RGB."""
    return Image.open(io.BytesIO(get(url))).convert("RGB")


def recolor(image, palette):
    """Pasa la foto a la paleta indicada según su luminancia, sin perder el detalle."""
    rgb = np.asarray(image, dtype=np.float32) / 255.0
    lum = rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    low, high = np.percentile(lum, [LOW_PERCENTILE, HIGH_PERCENTILE])
    t = np.clip((lum - low) / max(high - low, 1e-6), 0.0, 1.0)[:, :, None]
    dark, light = (np.array(c, dtype=np.float32) for c in palette)
    out = dark + (light - dark) * t
    return Image.fromarray((out * 255.0 + 0.5).astype(np.uint8))


def main():
    """Baja las texturas pedidas (o todas) en la resolución indicada con el nombre del juego."""
    folder, resolution = Path(sys.argv[1]), sys.argv[2]
    wanted = sys.argv[3:] or list(TEXTURES)
    folder.mkdir(parents=True, exist_ok=True)
    for name in wanted:
        asset, palette, author = TEXTURES[name]
        files = json.loads(get(API + asset))
        diffuse = fetch(files["Diffuse"][resolution]["jpg"]["url"])
        if palette:
            diffuse = recolor(diffuse, palette)
        diffuse.save(folder / f"{name}_albedo.jpg", quality=JPEG_QUALITY)
        # Normales y ARM se guardan tal como vienen, sin volver a comprimir.
        (folder / f"{name}_normal.jpg").write_bytes(get(files["nor_gl"][resolution]["jpg"]["url"]))
        (folder / f"{name}_orm.jpg").write_bytes(get(files["arm"][resolution]["jpg"]["url"]))
        print(f"{name}: {asset} de {author} (Poly Haven, CC0)")


if __name__ == "__main__":
    main()
