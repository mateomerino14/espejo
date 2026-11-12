"""Modela el cementerio de trenes: vagones de carga, una locomotora a vapor y el altar del Tío.

Los vagones y la locomotora salen como OBJ, una pieza por material y sin UV, porque en Godot usan
materiales triplanares de óxido y chapa. El Tío lleva colores propios y sale como glTF.

Uso: python3 trains.py <carpeta_obj> <archivo_tio.gltf>
"""

import bpy  # noqa: I001
import addon_utils
import math
import os
import random
import sys
from mathutils import Vector, noise

out_dir, tio_path = sys.argv[-2], sys.argv[-1]
os.makedirs(out_dir, exist_ok=True)
addon_utils.enable("io_scene_gltf2", default_set=True)
random.seed(1890)

WAGON_LENGTH = 9.0
WAGON_WIDTH = 2.6
WAGON_HEIGHT = 2.4
FLOOR = 1.05
WALL = 0.06
DOOR_WIDTH = 1.8
WHEEL_RADIUS = 0.42
GAUGE = 1.0


def reset():
    """Empieza una escena vacía."""
    bpy.ops.wm.read_factory_settings(use_empty=True)


def active():
    """El objeto recién creado."""
    return bpy.context.view_layer.objects.active


def box(name, size, loc, bevel=0.01, rot=(0, 0, 0)):
    """Caja con bordes biselados."""
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


def cylinder(name, radius, depth, loc, rot=(0, 0, 0), verts=20):
    """Cilindro con la orientación indicada."""
    bpy.ops.mesh.primitive_cylinder_add(
        radius=radius, depth=depth, location=loc, rotation=rot, vertices=verts
    )
    ob = active()
    ob.name = name
    return ob


def dent(ob, amount, scale):
    """Abolla la chapa con ruido, como metal golpeado y oxidado."""
    for mod in list(ob.modifiers):
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.modifier_apply(modifier=mod.name)
    seed = Vector((random.random() * 50, random.random() * 50, random.random() * 50))
    for v in ob.data.vertices:
        v.co += noise.noise_vector(v.co * scale + seed) * amount


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
    """Exporta un objeto: en Godot +Y de Blender queda mirando a −Z."""
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.ops.wm.obj_export(
        filepath=os.path.join(out_dir, file_name),
        export_selected_objects=True,
        export_materials=False,
        export_uv=False,
        forward_axis="NEGATIVE_Z",
        up_axis="Y",
        apply_modifiers=True,
    )
    print("modelo", file_name, len(ob.data.polygons))


def bogies(length):
    """Dos carretones con sus ejes y ruedas bajo un vagón de [param length] metros."""
    parts = []
    for y in (-length * 0.33, length * 0.33):
        parts.append(box("Bogie", (2.0, 1.7, 0.25), (0, y, 0.55), 0.02))
        for dy in (-0.6, 0.6):
            parts.append(
                cylinder(
                    "Axle", 0.06, GAUGE * 2 + 0.3, (0, y + dy, WHEEL_RADIUS), (0, math.pi / 2, 0)
                )
            )
            for x in (-GAUGE, GAUGE):
                wheel = cylinder(
                    "Wheel", WHEEL_RADIUS, 0.12, (x, y + dy, WHEEL_RADIUS), (0, math.pi / 2, 0), 24
                )
                parts.append(wheel)
    return parts


def boxcar():
    """Vagón de carga: chasis y ruedas de hierro, paredes de chapa y una puerta corrediza abierta."""
    reset()
    metal = bogies(WAGON_LENGTH)
    metal.append(
        box("Chassis", (WAGON_WIDTH + 0.1, WAGON_LENGTH + 0.4, 0.3), (0, 0, FLOOR - 0.15), 0.02)
    )
    metal.append(
        box(
            "Roof",
            (WAGON_WIDTH + 0.16, WAGON_LENGTH + 0.1, 0.12),
            (0, 0, FLOOR + WAGON_HEIGHT),
            0.03,
        )
    )
    for y in (-WAGON_LENGTH / 2, WAGON_LENGTH / 2):
        for x in (-WAGON_WIDTH / 2, WAGON_WIDTH / 2):
            metal.append(
                box("Post", (0.12, 0.12, WAGON_HEIGHT), (x, y, FLOOR + WAGON_HEIGHT / 2), 0.01)
            )
    # La puerta corrida queda a un lado del hueco
    metal.append(
        box(
            "DoorRail",
            (0.06, WAGON_LENGTH, 0.08),
            (WAGON_WIDTH / 2 + 0.08, 0, FLOOR + WAGON_HEIGHT - 0.1),
            0,
        )
    )
    roof_dent = metal[-1]
    dent(roof_dent, 0.0, 1.0)
    export(join(metal, "WagonMetal"), "boxcar_metal.obj")

    reset()
    walls = []
    half = WAGON_LENGTH / 2
    side = (WAGON_LENGTH - DOOR_WIDTH) / 2
    for x in (-WAGON_WIDTH / 2, WAGON_WIDTH / 2):
        if x > 0:
            for y in (-(DOOR_WIDTH / 2 + side / 2), DOOR_WIDTH / 2 + side / 2):
                walls.append(
                    box("Wall", (WALL, side, WAGON_HEIGHT), (x, y, FLOOR + WAGON_HEIGHT / 2), 0)
                )
        else:
            walls.append(
                box("Wall", (WALL, WAGON_LENGTH, WAGON_HEIGHT), (x, 0, FLOOR + WAGON_HEIGHT / 2), 0)
            )
    for y in (-half, half):
        walls.append(
            box("End", (WAGON_WIDTH, WALL, WAGON_HEIGHT), (0, y, FLOOR + WAGON_HEIGHT / 2), 0)
        )
    door = box(
        "Door",
        (WALL, DOOR_WIDTH, WAGON_HEIGHT - 0.1),
        (WAGON_WIDTH / 2 + 0.14, -half + side / 2 + 0.3, FLOOR + WAGON_HEIGHT / 2),
        0,
    )
    walls.append(door)
    walls.append(box("Floor", (WAGON_WIDTH, WAGON_LENGTH, 0.06), (0, 0, FLOOR + 0.03), 0))
    for ob in walls:
        bpy.context.view_layer.objects.active = ob
        sub = ob.modifiers.new("Sub", "SUBSURF")
        sub.levels = 3
        sub.subdivision_type = "SIMPLE"
        dent(ob, 0.025, 1.6)
    export(join(walls, "WagonWalls"), "boxcar_walls.obj")


def locomotive():
    """Locomotora a vapor: caldera, chimenea, domo, cabina abierta, ruedas motrices y quitapiedras."""
    reset()
    parts = []
    parts.append(box("Frame", (2.4, 10.0, 0.4), (0, 0, 1.0), 0.03))
    boiler = cylinder("Boiler", 0.85, 6.4, (0, -1.4, 2.1), (math.pi / 2, 0, 0), 28)
    parts.append(boiler)
    parts.append(cylinder("SmokeBox", 0.9, 1.0, (0, -4.9, 2.1), (math.pi / 2, 0, 0), 28))
    parts.append(cylinder("Door", 0.7, 0.1, (0, -5.45, 2.1), (math.pi / 2, 0, 0), 24))
    parts.append(cylinder("Chimney", 0.28, 1.2, (0, -4.8, 3.3), (0, 0, 0), 16))
    parts.append(cylinder("ChimneyLip", 0.38, 0.2, (0, -4.8, 3.95), (0, 0, 0), 16))
    parts.append(cylinder("Dome", 0.4, 0.5, (0, -2.0, 3.05), (0, 0, 0), 16))
    parts.append(cylinder("Sand", 0.32, 0.45, (0, -0.4, 3.0), (0, 0, 0), 16))
    # Cabina: piso, techo y paredes con ventanas
    parts.append(box("CabFloor", (2.6, 2.8, 0.1), (0, 3.4, 1.3), 0.02))
    parts.append(box("CabRoof", (2.9, 3.1, 0.12), (0, 3.4, 3.9), 0.03))
    parts.append(box("CabFront", (2.6, 0.1, 1.2), (0, 2.05, 1.9), 0.01))
    parts.append(box("CabFrontTop", (2.6, 0.1, 0.5), (0, 2.05, 3.6), 0.01))
    for x in (-1.3, 1.3):
        parts.append(box("CabSide", (0.1, 2.8, 1.0), (x, 3.4, 1.8), 0.01))
        parts.append(box("CabPillar", (0.1, 0.15, 2.6), (x, 2.05, 2.6), 0.01))
        parts.append(box("CabPillar", (0.1, 0.15, 2.6), (x, 4.75, 2.6), 0.01))
    # Ruedas motrices grandes y ruedas guía chicas
    for y in (-0.6, 0.9, 2.4):
        for x in (-1.0, 1.0):
            parts.append(cylinder("Driver", 0.75, 0.14, (x, y, 0.75), (0, math.pi / 2, 0), 28))
    for y in (-3.8, -2.8):
        for x in (-1.0, 1.0):
            parts.append(cylinder("Pony", 0.42, 0.12, (x, y, 0.42), (0, math.pi / 2, 0), 20))
    for x in (-1.05, 1.05):
        parts.append(box("Rod", (0.06, 3.2, 0.12), (x * 1.08, 0.9, 0.85), 0.01))
    # Quitapiedras en cuña
    plow = box("Pilot", (2.2, 0.8, 0.6), (0, -5.6, 0.45), 0.02)
    for v in plow.data.vertices:
        if v.co.y < 0 and v.co.z < 0:
            v.co.y += 0.5
    parts.append(plow)
    for ob in parts:
        dent(ob, 0.012, 2.0)
    export(join(parts, "Locomotive"), "locomotive.obj")


def material(name, color, roughness=0.8, metallic=0.0, emission=None):
    """Material liso para el Tío y sus ofrendas."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 3.0
    return mat


def tio():
    """El Tío de la mina sentado en su altar de piedra, con cuernos, ojos de vidrio, serpentinas y
    sus ofrendas: coca, cigarros y botellas."""
    reset()
    clay = material("Barro", (0.36, 0.1, 0.06), 0.75)
    horn = material("Cuerno", (0.85, 0.8, 0.68), 0.5)
    eye = material("Vidrio", (0.9, 0.85, 0.3), 0.05, emission=(0.6, 0.45, 0.05))
    stone = material("Piedra", (0.32, 0.3, 0.28), 0.95)
    glass = material("Botella", (0.12, 0.3, 0.15), 0.1)
    coca = material("Coca", (0.2, 0.34, 0.12), 0.7)
    paper = [
        material(f"Serpentina{i}", c, 0.6)
        for i, c in enumerate(
            ((0.9, 0.2, 0.3), (0.2, 0.5, 0.9), (0.95, 0.8, 0.15), (0.3, 0.8, 0.4))
        )
    ]

    def add(ob, mat):
        ob.data.materials.append(mat)
        return ob

    pieces = [add(box("Altar", (1.4, 1.0, 0.6), (0, 0, 0.3), 0.04), stone)]
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.38, location=(0, 0, 0.95))
    body = active()
    body.scale = (1.0, 0.8, 1.15)
    pieces.append(add(body, clay))
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.26, location=(0, -0.05, 1.55))
    head = active()
    head.scale = (1.0, 0.95, 1.1)
    pieces.append(add(head, clay))
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.07, location=(0, -0.3, 1.5))
    pieces.append(add(active(), clay))  # nariz
    for x in (-1, 1):
        bpy.ops.mesh.primitive_cone_add(
            radius1=0.06, depth=0.32, location=(x * 0.16, 0.0, 1.85), rotation=(0, x * 0.5, 0)
        )
        pieces.append(add(active(), horn))
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.05, location=(x * 0.1, -0.24, 1.6))
        pieces.append(add(active(), eye))
        arm = cylinder("Arm", 0.08, 0.55, (x * 0.42, -0.15, 0.95), (0.9, x * 0.4, 0))
        pieces.append(add(arm, clay))
        leg = cylinder("Leg", 0.1, 0.55, (x * 0.2, -0.35, 0.68), (math.pi / 2, 0, 0))
        pieces.append(add(leg, clay))
    # Serpentinas cruzadas sobre los hombros
    for i in range(10):
        a = i * 0.6
        strip = box(
            "Strip",
            (0.02, 0.012, 0.5),
            (math.cos(a) * 0.36, math.sin(a) * 0.28 - 0.05, 1.05),
            0,
            (0.3, 0.4 * math.sin(a), a),
        )
        pieces.append(add(strip, paper[i % len(paper)]))
    for i in range(3):
        bottle = cylinder("Bottle", 0.045, 0.28, (-0.5 + i * 0.12, -0.35, 0.74), (0, 0, 0), 12)
        pieces.append(add(bottle, glass))
    for i in range(14):
        leaf = box(
            "Leaf",
            (0.05, 0.03, 0.004),
            (
                0.3 + random.uniform(-0.15, 0.15),
                -0.32 + random.uniform(-0.08, 0.08),
                0.61 + i * 0.002,
            ),
            0,
            (0, 0, random.uniform(0, 3)),
        )
        pieces.append(add(leaf, coca))
    cigar = cylinder("Cigar", 0.012, 0.12, (0.0, -0.35, 1.42), (math.pi / 2, 0, 0.3), 8)
    pieces.append(add(cigar, horn))
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=tio_path, export_format="GLTF_SEPARATE", use_selection=True)
    print("tío exportado")


boxcar()
locomotive()
tio()
