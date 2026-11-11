"""Modela el 4x4 de Javier: una vagoneta vieja de las que hacen tours en el salar, con parrilla en
el techo cargada de bultos y la rueda de auxilio atrás. Sin marca.

Uso: python3 build_car.py <salida.gltf>
Mira hacia −Y en Blender (el frente en Godot). Las ruedas son objetos aparte (Wheel*) para que giren,
y los vacíos Headlight* marcan dónde van las luces.
"""

import bpy  # noqa: I001
import addon_utils
import math
import sys

from mathutils import Vector

out_path = sys.argv[-1]
addon_utils.enable("io_scene_gltf2", default_set=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

LENGTH = 4.6
WIDTH = 1.8
WHEEL_RADIUS = 0.4
WHEEL_WIDTH = 0.28
AXLE_FRONT = -1.45
AXLE_BACK = 1.25
FLOOR = 0.55
BELT = 1.15
ROOF = 1.9


def material(name, color, roughness=0.6, metallic=0.0, emission=None):
    """Material simple de color liso."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 2.0
    return mat


PAINT = material("Pintura", (0.78, 0.76, 0.72), 0.45)
GRIME = material("Barro", (0.42, 0.38, 0.33), 0.9)
BLACK = material("Plastico", (0.04, 0.04, 0.04), 0.7)
CHROME = material("Cromo", (0.7, 0.7, 0.72), 0.25, 1.0)
GLASS = material("Vidrio", (0.03, 0.04, 0.05), 0.05, 0.3)
LAMP = material("Faros", (0.9, 0.88, 0.8), 0.1, emission=(1.0, 0.92, 0.75))
TAIL = material("Pilotos", (0.5, 0.03, 0.02), 0.2, emission=(0.6, 0.02, 0.01))
RUBBER = material("Goma", (0.03, 0.03, 0.03), 0.95)
RIM = material("Llanta", (0.35, 0.35, 0.34), 0.5, 0.6)
TARP = material("Lona", (0.18, 0.22, 0.16), 0.9)
AGUAYO = material("Aguayo", (0.55, 0.08, 0.12), 0.85)


def box(name, center, size, mat, bevel=0.03, segments=2):
    """Caja con bordes redondeados."""
    bpy.ops.mesh.primitive_cube_add(location=center)
    ob = bpy.context.object
    ob.name = name
    ob.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    if bevel:
        mod = ob.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = segments
        bpy.ops.object.modifier_apply(modifier="Bevel")
    ob.data.materials.append(mat)
    return ob


def cylinder(name, center, radius, depth, mat, axis="X", vertices=24):
    """Cilindro acostado sobre el eje indicado."""
    rotation = {"X": (0, math.pi / 2, 0), "Y": (math.pi / 2, 0, 0), "Z": (0, 0, 0)}[axis]
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=radius, depth=depth, location=center, rotation=rotation
    )
    ob = bpy.context.object
    ob.name = name
    bpy.ops.object.transform_apply(rotation=True)
    ob.data.materials.append(mat)
    return ob


def taper_top(ob, amount_x, amount_front):
    """Angosta la parte de arriba de una caja: la cabina se inclina hacia adentro y adelante."""
    top = max(v.co.z for v in ob.data.vertices)
    bottom = min(v.co.z for v in ob.data.vertices)
    for v in ob.data.vertices:
        t = (v.co.z - bottom) / (top - bottom)
        v.co.x *= 1.0 - amount_x * t
        if v.co.y < 0:
            v.co.y += amount_front * t


parts = []
# Carrocería baja, capó y cabina
parts.append(box("Body", (0, 0, (FLOOR + BELT) / 2), (WIDTH, LENGTH - 0.3, BELT - FLOOR), PAINT, 0.06))
parts.append(box("Hood", (0, -1.55, BELT + 0.04), (WIDTH - 0.12, 1.2, 0.1), PAINT, 0.04))
cabin = box("Cabin", (0, 0.45, (BELT + ROOF) / 2), (WIDTH - 0.06, 2.9, ROOF - BELT), PAINT, 0.05)
taper_top(cabin, 0.08, 0.25)
parts.append(cabin)
# Franja de barro y sal en la parte baja
parts.append(box("Grime", (0, 0, FLOOR + 0.12), (WIDTH + 0.01, LENGTH - 0.28, 0.24), GRIME, 0.03))
# Guardabarros ensanchados
for x in (-1, 1):
    for y in (AXLE_FRONT, AXLE_BACK):
        parts.append(box("Fender", (x * (WIDTH / 2 + 0.03), y, 0.82), (0.12, 1.05, 0.12), BLACK, 0.04))
# Vidrios: parabrisas, laterales y trasero
windshield = box("Windshield", (0, 0, 0), (WIDTH - 0.24, 0.05, 0.6), GLASS, 0.01)
windshield.rotation_euler.x = -math.atan2(0.25, ROOF - BELT)
windshield.location = (0, -0.9, 1.53)
parts.append(windshield)
for x in (-1, 1):
    for y, length in ((-0.5, 0.75), (0.45, 0.85), (1.35, 0.75)):
        parts.append(box("Side", (x * (WIDTH / 2 - 0.05), y, 1.5), (0.04, length, 0.5), GLASS, 0.01))
parts.append(box("RearGlass", (0, 1.91, 1.5), (WIDTH - 0.3, 0.04, 0.5), GLASS, 0.01))
# Frente: parrilla, parachoques y faros redondos
parts.append(box("Grille", (0, -2.16, 0.9), (1.1, 0.06, 0.36), BLACK, 0.01))
for z in (0.8, 0.88, 0.96, 1.04):
    parts.append(box("Slat", (0, -2.2, z), (1.0, 0.03, 0.025), CHROME, 0.0))
parts.append(box("FrontBumper", (0, -2.25, 0.58), (WIDTH + 0.1, 0.18, 0.18), BLACK, 0.03))
parts.append(box("RearBumper", (0, 2.18, 0.58), (WIDTH + 0.05, 0.18, 0.16), BLACK, 0.03))
for x in (-1, 1):
    parts.append(cylinder("Headlight", (x * 0.7, -2.18, 0.92), 0.11, 0.08, LAMP, "Y"))
    parts.append(cylinder("HeadRing", (x * 0.7, -2.15, 0.92), 0.13, 0.06, CHROME, "Y"))
    parts.append(box("Tail", (x * 0.8, 2.16, 0.95), (0.12, 0.04, 0.24), TAIL, 0.01))
    parts.append(box("Mirror", (x * (WIDTH / 2 + 0.12), -0.85, 1.38), (0.06, 0.12, 0.16), BLACK, 0.02))
# Rueda de auxilio atrás
parts.append(cylinder("Spare", (0.35, 2.32, 1.1), WHEEL_RADIUS * 0.95, WHEEL_WIDTH, RUBBER, "Y"))
parts.append(box("SpareCover", (0.35, 2.47, 1.1), (0.5, 0.02, 0.5), TARP, 0.02))
# Parrilla del techo con bultos: lona y un aguayo atado
for x in (-1, 1):
    parts.append(box("RackRail", (x * 0.78, 0.55, ROOF + 0.08), (0.05, 2.4, 0.05), BLACK, 0.01))
for y in (-0.55, 0.0, 0.55, 1.1, 1.65):
    parts.append(box("RackBar", (0, y, ROOF + 0.06), (1.6, 0.05, 0.05), BLACK, 0.01))
parts.append(box("Tarp", (0, 0.65, ROOF + 0.25), (1.4, 1.7, 0.32), TARP, 0.12, 4))
parts.append(box("Bundle", (0.2, -0.35, ROOF + 0.2), (0.8, 0.5, 0.26), AGUAYO, 0.1, 4))

body = parts[0]
bpy.ops.object.select_all(action="DESELECT")
for ob in parts:
    ob.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.object.join()
body.name = "CarBody"
bpy.ops.object.shade_auto_smooth(angle=math.radians(40))

# Ruedas: goma con llanta, cada una con su origen en el eje para girar
for name, x, y in (
    ("WheelFL", -1, AXLE_FRONT),
    ("WheelFR", 1, AXLE_FRONT),
    ("WheelBL", -1, AXLE_BACK),
    ("WheelBR", 1, AXLE_BACK),
):
    center = Vector((x * (WIDTH / 2 - 0.02), y, WHEEL_RADIUS))
    tire = cylinder(name, center, WHEEL_RADIUS, WHEEL_WIDTH, RUBBER, "X", 28)
    rim = cylinder(name + "Rim", center + Vector((x * 0.02, 0, 0)), 0.24, WHEEL_WIDTH, RIM, "X", 20)
    bpy.ops.object.select_all(action="DESELECT")
    tire.select_set(True)
    rim.select_set(True)
    bpy.context.view_layer.objects.active = tire
    bpy.ops.object.join()
    bpy.context.scene.cursor.location = center
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    bpy.ops.object.shade_auto_smooth(angle=math.radians(40))

for name, x in (("HeadlightL", -0.7), ("HeadlightR", 0.7)):
    empty = bpy.data.objects.new(name, None)
    scene.collection.objects.link(empty)
    empty.location = (x, -2.25, 0.92)

bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=out_path, export_format="GLTF_SEPARATE", use_selection=True)
print("auto exportado")
