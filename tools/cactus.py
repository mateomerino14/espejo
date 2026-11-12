"""Modela los cardones de la isla: columnas con costillas y brazos que suben, como los de Incahuasi.

Escribe tres variantes en OBJ (alto con tres brazos, mediano con dos y uno joven sin brazos), sin UV,
porque en Godot usan un material triplanar.

Uso: python3 tools/cactus.py <carpeta_salida>
"""

import math
import os
import sys

import numpy as np

RIBS = 12
RIB_DEPTH = 0.09
SIDES = RIBS * 2
TIP_ROUNDING = 4  # anillos que se cierran en la punta
# Cada variante: alto del tronco, radio y brazos como (altura de salida, ángulo, alcance, alto final)
VARIANTS = [
    (5.6, 0.3, [(1.8, 20.0, 0.75, 4.4), (2.4, 150.0, 0.7, 4.9), (3.0, 260.0, 0.6, 4.6)]),
    (4.2, 0.27, [(1.5, 80.0, 0.7, 3.4), (2.1, 230.0, 0.6, 3.7)]),
    (2.6, 0.24, []),
]


def frames(points):
    """Tangente y normales que viajan por la curva sin girar de golpe."""
    tangents = np.gradient(points, axis=0)
    tangents /= np.linalg.norm(tangents, axis=1)[:, None]
    normal = np.cross(tangents[0], [0.0, 0.0, 1.0])
    if np.linalg.norm(normal) < 1e-3:
        normal = np.cross(tangents[0], [1.0, 0.0, 0.0])
    normal /= np.linalg.norm(normal)
    normals = []
    for t in tangents:
        normal = normal - t * np.dot(normal, t)
        normal /= np.linalg.norm(normal)
        normals.append(normal)
    normals = np.array(normals)
    return tangents, normals, np.cross(tangents, normals)


def tube(points, radius):
    """Tubo con costillas a lo largo de la curva, con la punta redondeada."""
    points = np.array(points, dtype=float)
    tangents, normals, binormals = frames(points)
    angles = np.linspace(0, 2 * math.pi, SIDES, endpoint=False)
    rib = 1 + RIB_DEPTH * np.cos(angles * RIBS)
    vertices, vertex_normals = [], []
    count = len(points)
    for i in range(count):
        left = count - 1 - i
        scale = 1.0
        if left < TIP_ROUNDING:
            scale = math.sqrt(max(0.0, 1 - ((TIP_ROUNDING - left) / TIP_ROUNDING) ** 2))
        for a, r in zip(angles, rib):
            radial = math.cos(a) * normals[i] + math.sin(a) * binormals[i]
            vertices.append(points[i] + radial * radius * r * max(scale, 0.05))
            bend = radial + tangents[i] * (1 - scale)
            vertex_normals.append(bend / np.linalg.norm(bend))
    faces = []
    for i in range(count - 1):
        for j in range(SIDES):
            a = i * SIDES + j
            b = i * SIDES + (j + 1) % SIDES
            faces.append((a, b, a + SIDES))
            faces.append((b, b + SIDES, a + SIDES))
    tip = len(vertices)
    vertices.append(points[-1] + tangents[-1] * radius * 0.05)
    vertex_normals.append(tangents[-1])
    last = (count - 1) * SIDES
    for j in range(SIDES):
        faces.append((last + j, last + (j + 1) % SIDES, tip))
    return np.array(vertices), np.array(vertex_normals), faces


def arm_path(trunk_radius, start, angle, reach, top):
    """Brazo: sale del centro del tronco, se abre de costado y sube en curva."""
    direction = np.array([math.cos(math.radians(angle)), 0.0, math.sin(math.radians(angle))])
    base = np.array([0.0, start, 0.0])
    elbow = base + direction * (reach + trunk_radius) + np.array([0.0, 0.15, 0.0])
    rise = elbow + np.array([0.0, 0.7, 0.0])
    points = []
    for t in np.linspace(0, 1, 10):
        points.append((1 - t) ** 2 * base + 2 * (1 - t) * t * elbow + t**2 * rise)
    for y in np.linspace(rise[1] + 0.25, top, max(3, int((top - rise[1]) / 0.3))):
        points.append(np.array([rise[0], y, rise[2]]))
    return points


def write_obj(path, parts):
    """Junta las piezas en un solo OBJ con normales."""
    lines, offset = [], 0
    for vertices, normals, faces in parts:
        lines += [f"v {v[0]:.3f} {v[1]:.3f} {v[2]:.3f}" for v in vertices]
        lines += [f"vn {n[0]:.3f} {n[1]:.3f} {n[2]:.3f}" for n in normals]
        for face in faces:
            ids = [str(i + offset + 1) for i in face]
            lines.append("f " + " ".join(f"{i}//{i}" for i in ids))
        offset += len(vertices)
    open(path, "w").write("\n".join(lines) + "\n")


def main():
    """Arma las tres variantes."""
    out_dir = sys.argv[1]
    os.makedirs(out_dir, exist_ok=True)
    for index, (height, radius, arms) in enumerate(VARIANTS):
        trunk = [np.array([0.0, y, 0.0]) for y in np.linspace(-0.3, height, int(height / 0.25))]
        parts = [tube(trunk, radius)]
        for start, angle, reach, top in arms:
            parts.append(tube(arm_path(radius, start, angle, reach, top), radius * 0.72))
        write_obj(os.path.join(out_dir, f"cactus_{index}.obj"), parts)
    print("cardones listos")


main()
