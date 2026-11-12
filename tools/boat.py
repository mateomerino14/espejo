"""Modela el bote de Don Celestino: un bote de remos de tablas, con proa en punta, popa cortada y
dos bancos. Sale en OBJ, sin UV, para el material triplanar de tablas.

Uso: python3 tools/boat.py <salida.obj>
"""

import math
import sys

import numpy as np

LENGTH = 3.2
WIDTH = 1.15
DEPTH = 0.42
THICKNESS = 0.035
STATIONS = 24
SIDES = 12
TRANSOM = 0.65  # ancho de la popa respecto del ancho máximo
SEATS = ((-0.7, 0.3), (0.45, 0.3))  # posición a lo largo y altura de cada banco


def half_width(t):
    """Medio ancho a lo largo del bote: t va de la popa (0) a la proa (1)."""
    if t < 0.4:
        return WIDTH / 2 * (TRANSOM + (1 - TRANSOM) * math.sin(t / 0.4 * math.pi / 2))
    return WIDTH / 2 * math.cos((t - 0.4) / 0.6 * math.pi / 2) ** 0.8


def shell(scale, lift):
    """Casco como grilla de puntos: cada estación es una U de la quilla a la borda."""
    rings = []
    for i in range(STATIONS + 1):
        t = i / STATIONS
        z = (t - 0.5) * LENGTH
        sheer = DEPTH + 0.08 * (2 * t - 1) ** 2
        w = max(half_width(t), 0.01) * scale
        ring = []
        for k in range(SIDES + 1):
            angle = -math.pi / 2 + math.pi * k / SIDES
            ring.append((w * math.sin(angle), lift + (sheer - lift) * (1 - math.cos(angle)), -z))
        rings.append(ring)
    return np.array(rings)


def grid_faces(offset, flip):
    """Triángulos de una grilla de estaciones por lados."""
    faces = []
    for i in range(STATIONS):
        for k in range(SIDES):
            a = offset + i * (SIDES + 1) + k
            b, c, d = a + 1, a + SIDES + 1, a + SIDES + 2
            if flip:
                faces += [(a, b, c), (b, d, c)]
            else:
                faces += [(a, c, b), (b, c, d)]
    return faces


def box(center, size):
    """Caja simple: vértices y caras."""
    cx, cy, cz = center
    sx, sy, sz = (s / 2 for s in size)
    vertices = [
        (cx + x * sx, cy + y * sy, cz + z * sz) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)
    ]
    faces = [
        (0, 1, 3), (0, 3, 2), (4, 6, 7), (4, 7, 5), (0, 4, 5), (0, 5, 1),
        (2, 3, 7), (2, 7, 6), (0, 2, 6), (0, 6, 4), (1, 5, 7), (1, 7, 3),
    ]  # fmt: skip
    return vertices, faces


def main():
    """Junta el casco por fuera y por dentro, el canto de la borda, la popa y los bancos."""
    outer = shell(1.0, 0.0).reshape(-1, 3)
    inner = shell(1.0 - THICKNESS * 2 / WIDTH, THICKNESS).reshape(-1, 3)
    vertices = list(map(tuple, outer)) + list(map(tuple, inner))
    faces = grid_faces(0, False) + grid_faces(len(outer), True)
    count = len(outer)
    for i in range(STATIONS):
        for k in (0, SIDES):
            a, c = i * (SIDES + 1) + k, (i + 1) * (SIDES + 1) + k
            if k == 0:
                faces += [(a, a + count, c), (c, a + count, c + count)]
            else:
                faces += [(a, c, a + count), (c, c + count, a + count)]
    for k in range(SIDES):
        a, b = k, k + 1
        faces += [(a, a + count, b), (b, a + count, b + count)]
    for z, height in SEATS:
        t = 0.5 - z / LENGTH
        seat_vertices, seat_faces = box((0, height, z), (half_width(t) * 2 - 0.08, 0.04, 0.22))
        base = len(vertices)
        vertices += seat_vertices
        faces += [(a + base, b + base, c + base) for a, b, c in seat_faces]
    lines = [f"v {x:.3f} {y:.3f} {z:.3f}" for x, y, z in vertices]
    lines += [f"f {a + 1} {b + 1} {c + 1}" for a, b, c in faces]
    open(sys.argv[1], "w").write("\n".join(lines) + "\n")
    print("bote listo")


main()
