"""Modela rocas de coral fósil para la isla: esferas deformadas con ruido, chatas abajo.

Escribe dos variantes en OBJ, sin UV, porque en Godot usan el material triplanar de roca.

Uso: python3 tools/boulder.py <carpeta_salida>
"""

import os
import sys

import numpy as np

SUBDIVISIONS = 3
WAVES = 14
VARIANTS = 2
rng = np.random.default_rng(4100)


def icosphere():
    """Esfera de triángulos parejos."""
    t = (1 + 5**0.5) / 2
    vertices = [
        (-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0),
        (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t),
        (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1),
    ]  # fmt: skip
    vertices = [np.array(v, dtype=float) / np.linalg.norm(v) for v in vertices]
    faces = [
        (0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11),
        (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8),
        (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9),
        (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1),
    ]  # fmt: skip
    for _ in range(SUBDIVISIONS):
        middle = {}

        def split(a, b):
            key = (min(a, b), max(a, b))
            if key not in middle:
                point = vertices[a] + vertices[b]
                vertices.append(point / np.linalg.norm(point))
                middle[key] = len(vertices) - 1
            return middle[key]

        new_faces = []
        for a, b, c in faces:
            ab, bc, ca = split(a, b), split(b, c), split(c, a)
            new_faces += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
        faces = new_faces
    return np.array(vertices), faces


def deform(vertices):
    """Bultos y caras planas con ondas al azar; la base queda chata para apoyarse en el suelo."""
    radius = np.ones(len(vertices))
    for _ in range(WAVES):
        direction = rng.normal(size=3)
        direction /= np.linalg.norm(direction)
        frequency = rng.uniform(1.5, 5.0)
        radius += rng.uniform(0.02, 0.09) * np.sin(
            frequency * vertices @ direction + rng.uniform(0, 6)
        )
    points = vertices * radius[:, None]
    points[:, 1] = np.maximum(points[:, 1], -0.55)
    return points


def normals(points, faces):
    """Normales suaves, promediando las caras de cada vértice."""
    result = np.zeros_like(points)
    for a, b, c in faces:
        n = np.cross(points[b] - points[a], points[c] - points[a])
        result[[a, b, c]] += n
    return result / np.linalg.norm(result, axis=1)[:, None]


def main():
    """Arma las variantes."""
    out_dir = sys.argv[1]
    os.makedirs(out_dir, exist_ok=True)
    base, faces = icosphere()
    for index in range(VARIANTS):
        points = deform(base)
        vertex_normals = normals(points, faces)
        lines = [f"v {p[0]:.3f} {p[1]:.3f} {p[2]:.3f}" for p in points]
        lines += [f"vn {n[0]:.3f} {n[1]:.3f} {n[2]:.3f}" for n in vertex_normals]
        lines += [f"f {a + 1}//{a + 1} {b + 1}//{b + 1} {c + 1}//{c + 1}" for a, b, c in faces]
        open(os.path.join(out_dir, f"boulder_{index}.obj"), "w").write("\n".join(lines) + "\n")
    print("rocas listas")


main()
