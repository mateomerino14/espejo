"""Modela los objetos del hotel de sal y los exporta como OBJ, una pieza por material.

Cada objeto se arma con primitivas, biseles y algo de ruido para que no parezca de caja.
No llevan UV: en Godot usan materiales triplanares (sal, cardón, tela), así que la textura
se adapta sola a cualquier forma.

Uso: python3 props.py <carpeta_salida>
"""

import bpy  # noqa: I001
import math
import os
import random
import sys
from mathutils import Vector, noise

out_dir = sys.argv[-1]
os.makedirs(out_dir, exist_ok=True)
random.seed(1980)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def active():
    return bpy.context.view_layer.objects.active


def box(name, size, loc, bevel=0.01, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    ob = active()
    ob.name = name
    ob.scale = size
    bpy.ops.object.transform_apply(scale=True)
    if bevel:
        mod = ob.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    return ob


def cylinder(name, radius, depth, loc, rot=(0, 0, 0), verts=16, bevel=0.0):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=loc, rotation=rot, vertices=verts)
    ob = active()
    ob.name = name
    if bevel:
        mod = ob.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    return ob


def roughen(ob, amount, scale, subdivide=0):
    """Deforma la malla con ruido para que no tenga caras perfectas."""
    for mod in list(ob.modifiers):
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.modifier_apply(modifier=mod.name)
    if subdivide:
        mod = ob.modifiers.new("Sub", "SUBSURF")
        mod.levels = subdivide
        mod.subdivision_type = "SIMPLE"
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.modifier_apply(modifier="Sub")
    seed = Vector((random.random() * 50, random.random() * 50, random.random() * 50))
    for v in ob.data.vertices:
        n = noise.noise_vector(v.co * scale + seed)
        v.co += n * amount


def join(objects, name):
    """Aplica modificadores y une las piezas en un objeto."""
    for ob in objects:
        bpy.context.view_layer.objects.active = ob
        for mod in list(ob.modifiers):
            bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objects:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    ob = active()
    ob.name = name
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35))
    return ob


def export(ob, file_name):
    """Exporta un objeto: en Godot +Y de Blender queda mirando a -Z."""
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.ops.wm.obj_export(
        filepath=os.path.join(out_dir, file_name), export_selected_objects=True, export_materials=False,
        export_uv=False, forward_axis="NEGATIVE_Z", up_axis="Y", apply_modifiers=True,
    )
    print("modelo", file_name, len(ob.data.polygons))


def salt_blocks(name, rows, size, origin, jitter=0.006):
    """Apila bloques de sal de 40 × 20 × 15 cm, trabados fila por fila, y los deforma un poco."""
    blocks = []
    width, depth, height = size
    block_w, block_h = 0.4, 0.15
    for row in range(rows):
        shift = (row % 2) * block_w / 2
        x = -width / 2 - shift
        while x < width / 2:
            left = max(x, -width / 2)
            right = min(x + block_w, width / 2)
            if right - left > 0.05:
                center = Vector((origin[0] + (left + right) / 2, origin[1], origin[2] + row * block_h + block_h / 2))
                b = box(name, (right - left - 0.008, depth, block_h - 0.008), center, bevel=0.012)
                roughen(b, jitter, 6.0, subdivide=1)
                blocks.append(b)
            x += block_w
    return blocks


def salt_bed():
    """Cama del hotel: base de bloques de sal, colchón y frazada de aguayo."""
    reset()
    base = salt_blocks("Base", 3, (0.95, 1.95, 0.45), (0, 0, 0))
    export(join(base, "BedBase"), "salt_bed_base.obj")
    reset()
    mattress = box("Mattress", (0.92, 1.9, 0.16), (0, 0, 0.53), bevel=0.05)
    roughen(mattress, 0.008, 3.0, subdivide=2)
    pillow = box("Pillow", (0.6, 0.32, 0.12), (0, 0.72, 0.66), bevel=0.05)
    roughen(pillow, 0.012, 4.0, subdivide=2)
    export(join([mattress, pillow], "Bedding"), "salt_bed_bedding.obj")
    reset()
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=40, y_subdivisions=50, size=1, location=(0, -0.2, 0.62))
    blanket = active()
    blanket.scale = (1.15, 1.25, 1)
    bpy.ops.object.transform_apply(scale=True)
    for v in blanket.data.vertices:
        over = max(0.0, abs(v.co.x) - 0.46)
        # Cae por los costados de la cama y se arruga un poco
        v.co.z -= over * 2.2
        v.co.x = math.copysign(min(abs(v.co.x), 0.48 + over * 0.15), v.co.x)
        v.co.z += noise.noise(v.co * 6.0) * 0.015
    mod = blanket.modifiers.new("Thick", "SOLIDIFY")
    mod.thickness = 0.012
    export(join([blanket], "Blanket"), "salt_bed_blanket.obj")


def salt_table():
    """Mesa de sal: pie de bloques y tablero de sal tallado."""
    reset()
    leg = salt_blocks("Leg", 4, (0.4, 0.4, 0.6), (0, 0, 0))
    top = box("Top", (1.2, 0.8, 0.08), (0, 0, 0.64), bevel=0.02)
    roughen(top, 0.004, 5.0, subdivide=2)
    export(join([*leg, top], "SaltTable"), "salt_table.obj")


def salt_stool():
    """Banco de sal: un bloque redondeado, gastado por el uso."""
    reset()
    seat = cylinder("Seat", 0.2, 0.45, (0, 0, 0.225), verts=20, bevel=0.03)
    roughen(seat, 0.01, 5.0, subdivide=1)
    export(join([seat], "SaltStool"), "salt_stool.obj")


def cardon_door():
    """Puerta de tablas de cardón con su marco; mide 0,9 × 2,1 m y gira desde el borde izquierdo."""
    reset()
    planks = []
    count = 5
    for i in range(count):
        x = 0.09 + i * 0.18
        plank = box("Plank", (0.17, 0.045, 2.05), (x, 0, 1.03), bevel=0.01)
        roughen(plank, 0.004, 4.0, subdivide=1)
        planks.append(plank)
    for z in (0.35, 1.7):
        planks.append(box("Brace", (0.86, 0.035, 0.12), (0.45, -0.04, z), bevel=0.008))
    export(join(planks, "Door"), "cardon_door.obj")
    reset()
    frame = []
    for x in (-0.06, 0.96):
        frame.append(box("Jamb", (0.1, 0.16, 2.2), (x, 0, 1.1), bevel=0.01))
    frame.append(box("Lintel", (1.12, 0.16, 0.12), (0.45, 0, 2.16), bevel=0.01))
    for piece in frame:
        roughen(piece, 0.003, 4.0, subdivide=1)
    export(join(frame, "DoorFrame"), "cardon_door_frame.obj")


def kerosene_lamp():
    """Lámpara de kerosene: base de lata, tubo de vidrio y asa de alambre."""
    reset()
    base = cylinder("Tank", 0.07, 0.07, (0, 0, 0.035), verts=24, bevel=0.01)
    collar = cylinder("Collar", 0.035, 0.03, (0, 0, 0.085), verts=16)
    handle = []
    bpy.ops.mesh.primitive_torus_add(major_radius=0.08, minor_radius=0.004, location=(0, 0, 0.17),
                                     rotation=(math.pi / 2, 0, 0))
    handle.append(active())
    export(join([base, collar, *handle], "LampMetal"), "kerosene_lamp_metal.obj")
    reset()
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=0.05, location=(0, 0, 0.15))
    glass = active()
    glass.scale = (1.0, 1.0, 1.6)
    bpy.ops.object.transform_apply(scale=True)
    export(join([glass], "LampGlass"), "kerosene_lamp_glass.obj")


def suitcase():
    """Maleta vieja de cuero con esquinas reforzadas y correa."""
    reset()
    body = box("Body", (0.62, 0.2, 0.42), (0, 0, 0.21), bevel=0.03)
    roughen(body, 0.004, 3.0, subdivide=2)
    strap = box("Strap", (0.05, 0.215, 0.44), (0.15, 0, 0.21), bevel=0.004)
    handle = box("Handle", (0.14, 0.03, 0.03), (0, 0, 0.45), bevel=0.012)
    export(join([body, strap, handle], "Suitcase"), "suitcase.obj")


def reception_desk():
    """Mostrador de la recepción: frente de bloques de sal y cubierta de cardón."""
    reset()
    front = salt_blocks("Front", 7, (2.4, 0.5, 1.05), (0, 0, 0))
    export(join(front, "DeskSalt"), "reception_desk_salt.obj")
    reset()
    top = box("Counter", (2.6, 0.7, 0.06), (0, -0.05, 1.08), bevel=0.01)
    roughen(top, 0.003, 4.0, subdivide=1)
    export(join([top], "DeskWood"), "reception_desk_wood.obj")


for build in (salt_bed, salt_table, salt_stool, cardon_door, kerosene_lamp, suitcase, reception_desk):
    build()
