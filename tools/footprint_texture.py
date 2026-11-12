"""Dibuja la huella mojada del Q'ispi: un pie descalzo, largo y angosto, con dedos separados.

Uso: python3 tools/footprint_texture.py assets/textures/footprint.png
"""

import sys

import numpy as np
from PIL import Image, ImageFilter

WIDTH, HEIGHT = 128, 256


def ellipse(mask, cx, cy, rx, ry, value=1.0):
    """Pinta una elipse llena en la máscara."""
    y, x = np.mgrid[0:HEIGHT, 0:WIDTH]
    inside = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0
    mask[inside] = np.maximum(mask[inside], value)


def main():
    """Arma la huella con elipses, la difumina y la guarda con transparencia."""
    rng = np.random.default_rng(3)
    mask = np.zeros((HEIGHT, WIDTH))
    ellipse(mask, 64, 190, 30, 50)  # talón y planta
    ellipse(mask, 60, 120, 34, 46)
    ellipse(mask, 70, 150, 22, 30)
    for i, (dx, dy, r) in enumerate(
        ((-26, 52, 11), (-8, 40, 10), (8, 38, 9), (22, 44, 8), (34, 54, 7))
    ):
        ellipse(mask, 64 + dx, dy, r, r * 1.5)
    mask *= 0.75 + 0.25 * rng.random(mask.shape)
    image = Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2.5))
    alpha = np.asarray(image).astype(np.float32) / 255.0
    rgba = np.zeros((HEIGHT, WIDTH, 4), np.uint8)
    rgba[..., :3] = (18, 20, 22)
    rgba[..., 3] = (np.clip(alpha * 1.2, 0, 1) * 220).astype(np.uint8)
    Image.fromarray(rgba, "RGBA").save(sys.argv[-1])


main()
