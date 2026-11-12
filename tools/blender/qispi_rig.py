"""Le pone esqueleto al Q'ispi de juego, pinta los pesos, anima y exporta glTF con animaciones.

Uso: python3 qispi_rig.py <qispi_game.blend> <carpeta_salida>
"""

import bpy  # noqa: I001
import addon_utils
import math
import os
import sys
from mathutils import Euler, Vector

src, out_dir = sys.argv[-2], sys.argv[-1]
addon_utils.enable("io_scene_gltf2", default_set=True)
bpy.ops.wm.open_mainfile(filepath=src)
scene = bpy.context.scene
scene.render.fps = 30
mesh = bpy.data.objects["Qispi"]
HEAD = Vector((0.0, 0.2, 2.13))
MOUTH_Z = 2.04

# Huesos: nombre, cabeza, cola, padre, radio del cuerpo alrededor del hueso
BONES = [
    ("root", (0, 0, 0), (0, 0.3, 0), None, 0.0),
    ("hips", (0, 0.0, 1.1), (0, 0.03, 1.32), "root", 0.15),
    ("spine", (0, 0.03, 1.32), (0, 0.05, 1.55), "hips", 0.13),
    ("chest", (0, 0.05, 1.55), (0, 0.12, 1.88), "spine", 0.18),
    ("neck", (0, 0.12, 1.88), (0, 0.17, 2.0), "chest", 0.06),
    ("head", (0, 0.17, 2.0), (0, 0.2, 2.3), "neck", 0.14),
    ("jaw", (0, 0.2, 2.06), (0, 0.3, 1.98), "head", 0.05),
]
for s, side in ((-1, "L"), (1, "R")):
    BONES += [
        (f"clavicle.{side}", (0.04 * s, 0.1, 1.8), (0.23 * s, 0.07, 1.77), "chest", 0.07),
        (f"upper_arm.{side}", (0.23 * s, 0.07, 1.77), (0.31 * s, 0.11, 1.33), f"clavicle.{side}", 0.05),
        (f"forearm.{side}", (0.31 * s, 0.11, 1.33), (0.34 * s, 0.19, 0.87), f"upper_arm.{side}", 0.045),
        (f"hand.{side}", (0.34 * s, 0.19, 0.87), (0.34 * s, 0.27, 0.55), f"forearm.{side}", 0.04),
        (f"thigh.{side}", (0.09 * s, 0.0, 1.07), (0.12 * s, 0.08, 0.6), "hips", 0.09),
        (f"shin.{side}", (0.12 * s, 0.08, 0.6), (0.12 * s, -0.01, 0.1), f"thigh.{side}", 0.055),
        (f"foot.{side}", (0.12 * s, -0.01, 0.1), (0.12 * s, 0.22, 0.025), f"shin.{side}", 0.04),
    ]

arm_data = bpy.data.armatures.new("QispiRig")
rig = bpy.data.objects.new("QispiRig", arm_data)
scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
for name, head, tail, parent, _ in BONES:
    bone = arm_data.edit_bones.new(name)
    bone.head = head
    bone.tail = tail
    bone.roll = 0.0
    if parent:
        bone.parent = arm_data.edit_bones[parent]
        bone.use_connect = False
bpy.ops.object.mode_set(mode="OBJECT")
arm_data.bones["root"].use_deform = False


def segment_distance(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
    return (p - (a + ab * t)).length


def jaw_weight(co):
    """Mandíbula: lo que queda bajo la boca y al frente de la cabeza."""
    if (co - HEAD).length > 0.22 or co.y < 0.15:
        return 0.0
    return max(0.0, min(1.0, (MOUTH_Z - co.z) / 0.03))


# Pesos: cada vértice sigue a los huesos más cercanos según el grosor del cuerpo
deforming = [(n, Vector(h), Vector(t), r) for n, h, t, _, r in BONES if n not in ("root", "jaw")]
groups = {n: mesh.vertex_groups.new(name=n) for n, *_ in BONES if n != "root"}
for v in mesh.data.vertices:
    co = v.co
    scores = []
    for name, a, b, radius in deforming:
        d = max(segment_distance(co, a, b), 0.01)
        scores.append(((radius / d) ** 6, name))
    scores.sort(reverse=True)
    top = scores[:3]
    total = sum(w for w, _ in top)
    if (co - HEAD).length < 0.17:
        top, total = [(1.0, "head")], 1.0
    jaw = jaw_weight(co)
    for w, name in top:
        weight = w / total * (1.0 - jaw)
        if weight > 0.01:
            groups[name].add([v.index], weight, "REPLACE")
    if jaw > 0.0:
        groups["jaw"].add([v.index], jaw, "REPLACE")

mesh.parent = rig
mod = mesh.modifiers.new("Armature", "ARMATURE")
mod.object = rig

# Animación: rotaciones en ejes del mundo (X lateral, Y al frente, Z arriba) en grados
for pb in rig.pose.bones:
    pb.rotation_mode = "QUATERNION"


def pose(rotations, offsets=None):
    for pb in rig.pose.bones:
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.location = (0, 0, 0)
    for name, (x, y, z) in rotations.items():
        rest = rig.data.bones[name].matrix_local.to_3x3()
        world = Euler((math.radians(x), math.radians(y), math.radians(z)), "XYZ").to_matrix()
        local = rest.inverted() @ world @ rest
        rig.pose.bones[name].rotation_quaternion = local.to_quaternion()
    for name, offset in (offsets or {}).items():
        rest = rig.data.bones[name].matrix_local.to_3x3()
        rig.pose.bones[name].location = rest.inverted() @ Vector(offset)


def key_all(frame):
    for pb in rig.pose.bones:
        pb.keyframe_insert("rotation_quaternion", frame=frame)
        pb.keyframe_insert("location", frame=frame)


def make_action(name, frames, step, builder):
    rig.animation_data_create()
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    rig.animation_data.action = action
    for frame in list(range(0, frames, step)) + [frames]:
        rotations, offsets = builder(frame / frames)
        pose(rotations, offsets)
        key_all(frame)
    track = rig.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, 0, action)
    rig.animation_data.action = None


def legs(t, swing, knee, lift):
    rot = {}
    for side, phase in (("L", 0.0), ("R", math.pi)):
        a = t + phase
        thigh = swing * math.sin(a)
        bend = -(6 + knee * max(0.0, math.cos(a)))
        rot[f"thigh.{side}"] = (thigh + lift, 0, 0)
        rot[f"shin.{side}"] = (bend, 0, 0)
        rot[f"foot.{side}"] = (-(thigh + bend) * 0.5, 0, 0)
    return rot


def arms(t, swing, elbow, raise_deg, spread=4):
    rot = {}
    for side, phase, s in (("L", math.pi, -1), ("R", 0.0, 1)):
        a = t + phase
        rot[f"upper_arm.{side}"] = (swing * math.sin(a) + raise_deg, 0, spread * s)
        rot[f"forearm.{side}"] = (elbow + elbow * 0.4 * max(0.0, math.sin(a)), 0, 0)
        rot[f"hand.{side}"] = (6, 0, 0)
    return rot


def twitch(p, at, width):
    """Sacudida corta alrededor del momento indicado del ciclo."""
    return math.exp(-((p - at) / width) ** 2)


def idle(p):
    """Quieto pero vivo: se mece, ladea la cabeza despacio y la sacude de golpe."""
    t = p * math.tau
    rot = arms(t, 1.5, 6, 0)
    rot.update(legs(0, 0, 0, 0))
    rot["spine"] = (-6 + 1.5 * math.sin(t), 0, 2 * math.sin(t * 0.5))
    rot["chest"] = (-8 + 2 * math.sin(t), 0, 0)
    rot["neck"] = (6, 0, 0)
    roll = 18 * math.sin(t * 0.5) + 14 * twitch(p, 0.62, 0.02)
    rot["head"] = (4, roll, 8 * twitch(p, 0.3, 0.03))
    rot["jaw"] = (-4 - 6 * twitch(p, 0.62, 0.04), 0, 0)
    return rot, {"hips": (0, 0, -0.01 + 0.008 * math.sin(t))}


def walk(p):
    """Acecho: pasos largos y lentos, inclinado hacia adelante, brazos colgando."""
    t = p * math.tau
    rot = legs(t, 26, 40, 0)
    rot.update(arms(t, 8, 8, -4))
    rot["hips"] = (0, 4 * math.sin(t), 6 * math.sin(t))
    rot["spine"] = (-10, 0, -3 * math.sin(t))
    rot["chest"] = (-10, -3 * math.sin(t), -4 * math.sin(t))
    rot["neck"] = (12, 0, 0)
    rot["head"] = (8, 10, 3 * math.sin(t))
    rot["jaw"] = (-6, 0, 0)
    return rot, {"hips": (0, 0, -0.03 - 0.04 * abs(math.sin(t)))}


def run(p):
    """Carrera torcida: el torso casi horizontal, los brazos atrás y la boca abierta."""
    t = p * math.tau
    rot = legs(t, 44, 90, 14)
    rot.update(arms(t, 14, 20, -35, spread=14))
    rot["hips"] = (-10, 6 * math.sin(t), 10 * math.sin(t))
    rot["spine"] = (-24, 0, -6 * math.sin(t))
    rot["chest"] = (-18, -4 * math.sin(t), -8 * math.sin(t))
    rot["neck"] = (30, 0, 0)
    rot["head"] = (20, 6 * math.sin(t * 2), 0)
    rot["jaw"] = (-28, 0, 0)
    return rot, {"hips": (0, 0.06, -0.12 - 0.06 * abs(math.sin(t)))}


def stunned(p):
    """Aturdido por el flash: se tapa la cara, se arquea y tiembla."""
    t = p * math.tau
    shake = math.sin(t * 9) * 4
    rot = legs(0, 0, 0, 0)
    rot["thigh.L"] = (12, 0, 0)
    rot["shin.L"] = (-25, 0, 0)
    for side, s in (("L", -1), ("R", 1)):
        rot[f"upper_arm.{side}"] = (125 + shake, 0, -22 * s)
        rot[f"forearm.{side}"] = (95, 0, 0)
        rot[f"hand.{side}"] = (-20, 0, 0)
    rot["spine"] = (10 + shake * 0.5, 0, 0)
    rot["chest"] = (12, 0, shake)
    rot["neck"] = (-14, 0, 0)
    rot["head"] = (-18 + shake, 12 * math.sin(t * 3), 0)
    rot["jaw"] = (-38, 0, 0)
    return rot, {"hips": (0, -0.04, -0.05)}


def catch(p):
    """Embestida: se abalanza con los brazos largos y abre la boca de golpe."""
    lunge = min(1.0, p / 0.25)
    ease = 1 - (1 - lunge) ** 3
    shake = math.sin(p * 70) * 3 * min(1.0, p * 3)
    rot = legs(0, 0, 0, 0)
    rot["thigh.L"] = (28 * ease, 0, 0)
    rot["shin.L"] = (-40 * ease, 0, 0)
    rot["thigh.R"] = (-12 * ease, 0, 0)
    for side, s in (("L", -1), ("R", 1)):
        rot[f"upper_arm.{side}"] = (100 * ease, 0, -14 * s * ease)
        rot[f"forearm.{side}"] = (15 * ease, 0, 0)
        rot[f"hand.{side}"] = (-30 * ease, 0, 0)
    # Se dobla sobre Lucía, que es más baja, para que la cara le quede de frente.
    rot["spine"] = (-10 * ease, 0, 0)
    rot["chest"] = (-8 * ease + shake, 0, 0)
    rot["neck"] = (-12 * ease, 0, 0)
    rot["head"] = (-24 * ease, 14 * ease + shake, shake)
    rot["jaw"] = (-45 * ease, 0, 0)
    return rot, {"hips": (0, -0.05 * ease, -0.14 * ease)}


make_action("idle", 120, 2, idle)
make_action("walk", 40, 2, walk)
make_action("run", 22, 1, run)
make_action("stunned", 30, 1, stunned)
make_action("catch", 36, 1, catch)
pose({}, {})

os.makedirs(out_dir, exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out_dir, "qispi_rigged.blend"))
bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True)
rig.select_set(True)
bpy.ops.export_scene.gltf(
    filepath=os.path.join(out_dir, "qispi.gltf"),
    use_selection=True,
    export_format="GLTF_SEPARATE",
    export_image_format="AUTO",
    export_animations=True,
    export_animation_mode="ACTIONS",
    export_force_sampling=True,
)
print("rig exportado")
