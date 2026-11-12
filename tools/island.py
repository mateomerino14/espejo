"""Arma la isla Incahuasi: un cerro de coral fósil que sale del salar inundado.

Genera el relieve con ruido suave sobre una cúpula, cuida que se pueda caminar (sin pendientes de
más de 35°) y deja una explanada en la cima. Escribe la malla visible (OBJ, sin UV, para el material
triplanar), la forma de colisión de Godot y dónde van los cardones.

Uso: python3 tools/island.py assets/models/island/island.obj src/world/level_04/island_shape.tres \
    src/world/level_04/cactus_spots.json
"""

import json
import math
import sys

import numpy as np

SIZE = 97  # puntos por lado, a un metro
HALF = (SIZE - 1) / 2
PEAK = 11.0
RADIUS = 36.0
BASE = -0.15  # el salar inundado, bajo unos centímetros de agua
MAX_SLOPE_DEGREES = 33.0
SUMMIT = (4.0, -10.0)  # x, z de la explanada
SUMMIT_RADIUS = 4.0
CACTI = 110
rng = np.random.default_rng(1957)


def value_noise(scale, octaves):
    """Ruido fractal liso hecho con grillas al azar interpoladas."""
    total = np.zeros((SIZE, SIZE))
    amplitude = 1.0
    for octave in range(octaves):
        cells = int(scale * 2**octave) + 2
        grid = rng.random((cells, cells))
        coords = np.linspace(0, cells - 1.001, SIZE)
        i = coords.astype(int)
        f = coords - i
        f = f * f * (3 - 2 * f)
        a = grid[np.ix_(i, i)]
        b = grid[np.ix_(i, i + 1)]
        c = grid[np.ix_(i + 1, i)]
        d = grid[np.ix_(i + 1, i + 1)]
        fx, fz = f[None, :], f[:, None]
        total += amplitude * ((a * (1 - fx) + b * fx) * (1 - fz) + (c * (1 - fx) + d * fx) * fz)
        amplitude *= 0.5
    return total / total.max()


def heights():
    """Cúpula con ruido, explanada en la cima y pendientes suavizadas hasta poder caminarlas."""
    z, x = np.mgrid[0:SIZE, 0:SIZE] - HALF
    offset = np.hypot(x - SUMMIT[0], z - SUMMIT[1])
    dome = np.clip(1 - offset / RADIUS, 0, 1) ** 1.4
    h = BASE + (PEAK - BASE) * dome * (0.75 + 0.5 * value_noise(3, 4))
    flat = offset < SUMMIT_RADIUS
    h[flat] = h[flat].mean()
    limit = math.tan(math.radians(MAX_SLOPE_DEGREES))
    for _ in range(200):
        smooth = (np.roll(h, 1, 0) + np.roll(h, -1, 0) + np.roll(h, 1, 1) + np.roll(h, -1, 1)) / 4
        gz, gx = np.gradient(h)
        steep = np.hypot(gx, gz) > limit
        if not steep.any():
            break
        h[steep] = 0.5 * h[steep] + 0.5 * smooth[steep]
    return h


def write_obj(path, h):
    """Malla de triángulos con normales, en las mismas coordenadas que Godot."""
    lines = []
    for r in range(SIZE):
        for c in range(SIZE):
            lines.append(f"v {c - HALF:.2f} {h[r, c]:.3f} {r - HALF:.2f}")
    gz, gx = np.gradient(h)
    for r in range(SIZE):
        for c in range(SIZE):
            n = np.array([-gx[r, c], 1.0, -gz[r, c]])
            n /= np.linalg.norm(n)
            lines.append(f"vn {n[0]:.4f} {n[1]:.4f} {n[2]:.4f}")
    for r in range(SIZE - 1):
        for c in range(SIZE - 1):
            a = r * SIZE + c + 1
            b, d, e = a + 1, a + SIZE, a + SIZE + 1
            lines.append(f"f {a}//{a} {d}//{d} {b}//{b}")
            lines.append(f"f {b}//{b} {d}//{d} {e}//{e}")
    open(path, "w").write("\n".join(lines) + "\n")


def write_shape(path, h):
    """Forma de colisión de alturas para Godot, centrada como la malla."""
    data = ", ".join(f"{v:.3f}" for v in h.ravel())
    open(path, "w").write(
        '[gd_resource type="HeightMapShape3D" format=3]\n\n[resource]\n'
        f"map_width = {SIZE}\nmap_depth = {SIZE}\nmap_data = PackedFloat32Array({data})\n"
    )


def cactus_spots(h):
    """Lugares para los cardones: en tierra firme, no muy empinados y fuera de la cima."""
    gz, gx = np.gradient(h)
    spots = []
    tries = 0
    while len(spots) < CACTI and tries < 20000:
        tries += 1
        r, c = rng.integers(2, SIZE - 2, 2)
        x, z = c - HALF, r - HALF
        if h[r, c] < 0.8 or np.hypot(gx[r, c], gz[r, c]) > 0.5:
            continue
        if math.hypot(x - SUMMIT[0], z - SUMMIT[1]) < SUMMIT_RADIUS + 2:
            continue
        if any(math.hypot(x - sx, z - sz) < 3.0 for sx, _, sz, _ in spots):
            continue
        spots.append((float(x), float(h[r, c]), float(z), int(rng.integers(0, 3))))
    return spots


def main():
    """Genera la isla y escribe sus tres archivos."""
    obj_path, shape_path, spots_path = sys.argv[1:4]
    h = heights()
    write_obj(obj_path, h)
    write_shape(shape_path, h)
    summit_r, summit_c = int(SUMMIT[1] + HALF), int(SUMMIT[0] + HALF)
    info = {
        "summit": [SUMMIT[0], float(h[summit_r, summit_c]), SUMMIT[1]],
        "cacti": cactus_spots(h),
    }
    json.dump(info, open(spots_path, "w"), indent=1)
    print("isla lista: cima a", round(float(h.max()), 2), "m,", len(info["cacti"]), "cardones")


main()
