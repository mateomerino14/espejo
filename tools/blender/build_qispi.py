"""Modela al Q'ispi en alta resolución: un cuerpo largo y flaco de sal, con cara humana y cristales.

Cuerpo: esqueleto de vértices con el modificador Skin, más volúmenes que se funden con remallado
por vóxeles. La cara lleva cuencas y una boca abierta talladas con booleanos. Los cristales de sal
(cubos de halita) van aparte, con su propio material.

Uso: python3 build_qispi.py <salida.blend>
El Q'ispi mira hacia +Y y mide unos 2,35 m con los pies en z = 0.
"""

import bpy  # noqa: I001  (bpy primero: registra bmesh y mathutils)
import math
import random
import sys
from mathutils import Euler, Vector

OUT = sys.argv[-1]
HEAD = Vector((0.0, 0.2, 2.13))
random.seed(11)


def link(ob):
    bpy.context.collection.objects.link(ob)
    return ob


def select_only(objs, active=None):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = active or objs[0]


def apply_all(ob):
    select_only([ob])
    for m in list(ob.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)


def blob(name, center, scale, rot=(0, 0, 0), segs=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segs, ring_count=segs // 2, radius=1.0,
                                         location=center, rotation=rot)
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return ob


def build_body():
    """Esqueleto flaco con brazos que llegan a las rodillas y dedos largos."""
    joints, radii, edges = {}, {}, []

    def j(name, co, r):
        joints[name] = Vector(co)
        radii[name] = r if isinstance(r, tuple) else (r, r)

    def chain(*names):
        edges.extend(zip(names, names[1:]))

    j("pelvis", (0, 0.0, 1.12), (0.14, 0.1))
    j("belly", (0, 0.03, 1.32), (0.105, 0.08))
    j("chest", (0, 0.05, 1.55), (0.16, 0.1))
    j("upper", (0, 0.08, 1.76), (0.19, 0.095))
    j("neck", (0, 0.15, 1.92), 0.05)
    j("nape", (0, 0.18, 2.02), 0.055)
    chain("pelvis", "belly", "chest", "upper", "neck", "nape")
    for s, side in ((-1, "L"), (1, "R")):
        j(f"shoulder{side}", (0.23 * s, 0.07, 1.77), 0.065)
        j(f"bicep{side}", (0.28 * s, 0.09, 1.56), 0.045)
        j(f"elbow{side}", (0.31 * s, 0.11, 1.33), 0.04)
        j(f"forearm{side}", (0.33 * s, 0.15, 1.1), 0.038)
        j(f"wrist{side}", (0.34 * s, 0.19, 0.87), 0.027)
        j(f"palm{side}", (0.34 * s, 0.21, 0.79), (0.045, 0.02))
        chain("upper", f"shoulder{side}", f"bicep{side}", f"elbow{side}", f"forearm{side}",
              f"wrist{side}", f"palm{side}")
        for i, off in enumerate((-0.03, -0.01, 0.01, 0.03)):
            length = 0.075 + (0.012 if i in (1, 2) else 0.0)
            a = Vector((0.34 * s + off * s, 0.22, 0.75))
            b = a + Vector((off * 0.4 * s, 0.012, -length))
            c = b + Vector((off * 0.3 * s, 0.02, -length))
            d = c + Vector((0.0, 0.03, -length * 0.8))
            j(f"f{i}a{side}", a, 0.012)
            j(f"f{i}b{side}", b, 0.011)
            j(f"f{i}c{side}", c, 0.0095)
            j(f"f{i}d{side}", d, 0.006)
            chain(f"palm{side}", f"f{i}a{side}", f"f{i}b{side}", f"f{i}c{side}", f"f{i}d{side}")
        j(f"thumb_a{side}", (0.31 * s, 0.24, 0.79), 0.012)
        j(f"thumb_b{side}", (0.29 * s, 0.29, 0.72), 0.009)
        chain(f"palm{side}", f"thumb_a{side}", f"thumb_b{side}")
        j(f"hip{side}", (0.09 * s, 0.0, 1.07), 0.085)
        j(f"thigh{side}", (0.11 * s, 0.05, 0.84), 0.07)
        j(f"knee{side}", (0.12 * s, 0.08, 0.6), 0.05)
        j(f"shin{side}", (0.12 * s, 0.03, 0.35), 0.042)
        j(f"ankle{side}", (0.12 * s, -0.01, 0.1), 0.032)
        j(f"foot{side}", (0.12 * s, 0.1, 0.04), (0.04, 0.025))
        j(f"toe{side}", (0.12 * s, 0.22, 0.025), (0.035, 0.016))
        chain("pelvis", f"hip{side}", f"thigh{side}", f"knee{side}", f"shin{side}",
              f"ankle{side}", f"foot{side}", f"toe{side}")

    names = list(joints)
    me = bpy.data.meshes.new("QispiSkeleton")
    me.from_pydata([joints[n] for n in names],
                   [(names.index(a), names.index(b)) for a, b in edges], [])
    ob = link(bpy.data.objects.new("QispiBody", me))
    skin = ob.modifiers.new("Skin", "SKIN")
    skin.use_smooth_shade = True
    skin.branch_smoothing = 0.5
    for i, n in enumerate(names):
        sv = me.skin_vertices[0].data[i]
        sv.radius = radii[n]
        sv.use_root = n == "pelvis"
    sub = ob.modifiers.new("Subsurf", "SUBSURF")
    sub.levels = 2
    apply_all(ob)
    return ob


def build_volumes():
    """Cabeza humana alargada, costillas apenas marcadas, omóplatos y vértebras salientes."""
    h = HEAD
    parts = [
        blob("Skull", h + Vector((0, -0.02, 0.05)), (0.1, 0.12, 0.15)),
        blob("Face", h + Vector((0, 0.05, -0.03)), (0.085, 0.07, 0.13)),
        blob("Brow", h + Vector((0, 0.085, 0.05)), (0.08, 0.035, 0.026)),
        blob("Nose", h + Vector((0, 0.115, -0.015)), (0.016, 0.025, 0.04), rot=(math.radians(12), 0, 0)),
        blob("Chin", h + Vector((0, 0.075, -0.15)), (0.04, 0.035, 0.04)),
        blob("Hunch", Vector((0, -0.01, 1.74)), (0.17, 0.07, 0.09)),
    ]
    for s, side in ((-1, "L"), (1, "R")):
        parts += [
            blob(f"Cheek{side}", h + Vector((0.05 * s, 0.075, -0.045)), (0.03, 0.03, 0.035)),
            blob(f"Blade{side}", Vector((0.11 * s, -0.03, 1.66)), (0.08, 0.03, 0.1),
                 rot=(0, math.radians(15 * s), 0)),
            blob(f"Collar{side}", Vector((0.1 * s, 0.12, 1.82)), (0.1, 0.02, 0.018),
                 rot=(0, math.radians(-12 * s), 0)),
            blob(f"Calf{side}", Vector((0.12 * s, 0.0, 0.42)), (0.045, 0.045, 0.1)),
        ]
        for k in range(5):
            z = 1.66 - k * 0.065
            parts.append(blob(f"Rib{side}{k}", Vector((0.065 * s, 0.11, z)), (0.075, 0.045, 0.012),
                              rot=(0, math.radians(-16 * s), 0)))
    for k in range(10):
        z = 1.95 - k * 0.085
        parts.append(blob(f"Vertebra{k}", Vector((0, -0.055, z)), (0.022, 0.03, 0.02), segs=12))
    return parts


def surface_front(ob, x, z):
    """Devuelve el punto de la piel que se ve de frente en (x, z), mirando hacia -Y."""
    hit, location, _normal, _index = ob.ray_cast(Vector((x, 2.0, z)), Vector((0, -1, 0)))
    if not hit:
        raise RuntimeError(f"No hay piel al frente en x={x}, z={z}")
    return location


def carve(target, cutters):
    for c in cutters:
        mod = target.modifiers.new("Carve", "BOOLEAN")
        mod.operation = "DIFFERENCE"
        mod.solver = "MANIFOLD"
        mod.object = c
        select_only([target])
        bpy.ops.object.modifier_apply(modifier=mod.name)
        bpy.data.objects.remove(c)


def fuse_and_sculpt(body, parts):
    """Funde todo en una piel, talla la cara y le pone grietas de sal."""
    select_only([body, *parts], body)
    bpy.ops.object.join()
    ob = bpy.context.active_object
    ob.name = "QispiHigh"
    ob.data.remesh_voxel_size = 0.008
    bpy.ops.object.voxel_remesh()
    smooth = ob.modifiers.new("Blend", "CORRECTIVE_SMOOTH")
    smooth.iterations = 8
    smooth.factor = 0.7
    apply_all(ob)
    h = HEAD
    mouth_at = surface_front(ob, 0.0, h.z - 0.1)
    socket_at = [surface_front(ob, 0.036 * s, h.z + 0.005) for s in (-1, 1)]
    # La boca abierta, larga y vertical, y las cuencas hondas; el pintado lee dónde quedaron.
    mouth = blob("MouthCut", mouth_at + Vector((0, 0.005, -0.01)), (0.018, 0.035, 0.045))
    sockets = [blob(f"Socket{i}", at + Vector((0, 0.008, 0)), (0.022, 0.03, 0.017))
               for i, at in enumerate(socket_at)]
    ob["mouth"] = mouth_at
    ob["socket_l"] = socket_at[0]
    ob["socket_r"] = socket_at[1]
    carve(ob, [mouth, *sockets])
    ob.data.remesh_voxel_size = 0.005
    select_only([ob])
    bpy.ops.object.voxel_remesh()
    smooth = ob.modifiers.new("Smooth", "CORRECTIVE_SMOOTH")
    smooth.iterations = 4
    smooth.factor = 0.5
    cells = bpy.data.textures.new("SaltCells", "VORONOI")
    cells.noise_scale = 0.045
    cells.distance_metric = "DISTANCE"
    crack = ob.modifiers.new("Cracks", "DISPLACE")
    crack.texture = cells
    crack.texture_coords = "OBJECT"
    crack.strength = 0.004
    grain = bpy.data.textures.new("SaltGrain", "CLOUDS")
    grain.noise_scale = 0.012
    rough = ob.modifiers.new("Grain", "DISPLACE")
    rough.texture = grain
    rough.texture_coords = "OBJECT"
    rough.strength = 0.0015
    apply_all(ob)
    select_only([ob])
    bpy.ops.object.shade_smooth()
    return ob


def surface_points(ob, count, region):
    """Puntos al azar sobre la piel dentro de una región, con su normal."""
    picks = []
    verts = [v for v in ob.data.vertices if region(v.co)]
    for v in random.sample(verts, min(count, len(verts))):
        picks.append((v.co.copy(), v.normal.copy()))
    return picks


def build_crystals(skin):
    """Cubos de halita que le brotan de hombros, espalda y antebrazos."""
    def region(co):
        on_back = co.y < -0.02 and 1.45 < co.z < 1.95
        on_shoulder = abs(co.x) > 0.17 and 1.7 < co.z < 1.86
        on_forearm = abs(co.x) > 0.3 and 1.0 < co.z < 1.25 and co.y < 0.12
        return on_back or on_shoulder or on_forearm

    cubes = []
    for co, normal in surface_points(skin, 70, region):
        size = random.uniform(0.02, 0.065)
        cluster = random.randint(1, 3)
        for k in range(cluster):
            s = size * random.uniform(0.5, 1.0)
            offset = Vector([random.uniform(-0.02, 0.02) for _ in range(3)])
            bpy.ops.mesh.primitive_cube_add(size=s, location=co + normal * s * 0.35 + offset * k)
            cube = bpy.context.active_object
            tilt = normal.to_track_quat("Z", "Y").to_euler()
            jitter = Euler([random.uniform(-0.6, 0.6) for _ in range(3)])
            cube.rotation_euler = (tilt.to_matrix() @ jitter.to_matrix()).to_euler()
            bevel = cube.modifiers.new("Bevel", "BEVEL")
            bevel.width = s * 0.06
            bevel.segments = 1
            cubes.append(cube)
    for c in cubes:
        apply_all(c)
    select_only(cubes)
    bpy.ops.object.join()
    ob = bpy.context.active_object
    ob.name = "Crystals"
    return ob


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    skin = fuse_and_sculpt(build_body(), build_volumes())
    crystals = build_crystals(skin)
    print("QispiHigh", len(skin.data.polygons), "caras;", "Crystals", len(crystals.data.polygons))
    bpy.ops.wm.save_as_mainfile(filepath=OUT)


main()
