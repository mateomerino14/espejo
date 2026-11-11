"""Pasa captura de movimiento real (CMU, formato BVH) al esqueleto del Q'ispi.

Cada hueso del Q'ispi copia la dirección del hueso equivalente de la captura, cuadro a cuadro;
la cadera copia además su giro. Así no importa que las proporciones ni la pose de descanso sean
distintas. Los ciclos de caminar y correr se recortan a un paso completo y se dejan en el lugar,
porque en el juego el cuerpo lo mueve la física.

Uso: python3 qispi_mocap.py <qispi_rigged.blend> <carpeta_bvh> <carpeta_salida>
Los BVH vienen de github.com/una-dinosauria/cmu-mocap (CMU Graphics Lab, uso libre).
"""

import bpy  # noqa: I001
import addon_utils
import math
import os
import sys
from mathutils import Matrix, Vector

src, bvh_dir, out_dir = sys.argv[-3], sys.argv[-2], sys.argv[-1]
addon_utils.enable("io_scene_gltf2", default_set=True)
addon_utils.enable("io_anim_bvh", default_set=True)
bpy.ops.wm.open_mainfile(filepath=src)
scene = bpy.context.scene
rig = bpy.data.objects["QispiRig"]
mesh = bpy.data.objects["Qispi"]

SOURCE_FPS = 120
TARGET_FPS = 30
STEP = SOURCE_FPS // TARGET_FPS
# Altura del pie sobre su punto más bajo a partir de la cual cuenta como despegado
LIFT_HEIGHT = 0.05
# Por debajo de esta altura el pie cuenta como apoyado
CONTACT_HEIGHT = 0.012
# hueso del Q'ispi: hueso de la captura
DIRECTIONS = {
    "spine": "Spine", "chest": "Spine1", "neck": "Neck", "head": "Head",
    "clavicle.L": "LeftShoulder", "upper_arm.L": "LeftArm", "forearm.L": "LeftForeArm",
    "hand.L": "LeftFingerBase", "thigh.L": "LeftUpLeg", "shin.L": "LeftLeg", "foot.L": "LeftFoot",
    "clavicle.R": "RightShoulder", "upper_arm.R": "RightArm", "forearm.R": "RightForeArm",
    "hand.R": "RightFingerBase", "thigh.R": "RightUpLeg", "shin.R": "RightLeg", "foot.R": "RightFoot",
}
ORDER = ["hips", "spine", "chest", "neck", "head", "clavicle.L", "upper_arm.L", "forearm.L",
         "hand.L", "clavicle.R", "upper_arm.R", "forearm.R", "hand.R", "thigh.L", "shin.L",
         "foot.L", "thigh.R", "shin.R", "foot.R"]
# animación: (archivo, cuadro inicial en la captura, cuadros a 120 fps o "ciclo", en el lugar)
CLIPS = {
    "walk": ("077/77_29.bvh", 240, "ciclo", True),
    "run": ("016/16_35.bvh", 1, "ciclo", True),
    "stunned": ("079/79_73.bvh", 240, 240, True),
}
# Exageración para que el movimiento humano se vea ajeno: la cabeza cae hacia un lado.
HEAD_TILT_DEGREES = 14.0


def world_points(arm, name):
    """Cabeza y cola de un hueso de la captura, en el espacio del mundo."""
    pb = arm.pose.bones[name]
    return arm.matrix_world @ pb.head, arm.matrix_world @ pb.tail


def basis(up, right):
    """Arma una base con el eje Y hacia arriba del hueso y X hacia la derecha."""
    y = up.normalized()
    z = right.cross(y).normalized()
    x = y.cross(z).normalized()
    return Matrix((x, y, z)).transposed()


def facing_alignment(arm):
    """Giro que deja a la persona de la captura mirando hacia +Y, como el Q'ispi."""
    left, _ = world_points(arm, "LeftUpLeg")
    right, _ = world_points(arm, "RightUpLeg")
    side = right - left
    side.z = 0.0
    angle = math.atan2(side.y, side.x)
    return Matrix.Rotation(-angle, 3, "Z")


def travel_alignment(arm, first, last):
    """Giro que deja la dirección en la que avanza la persona apuntando hacia +Y."""
    scene.frame_set(first)
    start = world_points(arm, "Hips")[0]
    scene.frame_set(last)
    travel = world_points(arm, "Hips")[0] - start
    angle = math.atan2(travel.y, travel.x) - math.pi / 2
    return Matrix.Rotation(-angle, 3, "Z")


def foot_cycle(arm, start, limit):
    """Busca un ciclo completo del pie izquierdo: entre dos despegues seguidos del suelo."""
    end = min(start + limit, int(arm.animation_data.action.frame_range[1]))
    heights = []
    for f in range(start, end):
        scene.frame_set(f)
        heights.append(world_points(arm, "LeftFoot")[0].z)
    floor = min(heights)
    lift_offs = []
    grounded = False
    for i, height in enumerate(heights):
        if height < floor + CONTACT_HEIGHT:
            grounded = True
        elif grounded and height > floor + LIFT_HEIGHT:
            lift_offs.append(start + i)
            grounded = False
    return lift_offs[0], lift_offs[1]


def target_rest():
    """Base de la cadera y alturas del Q'ispi en descanso."""
    bones = rig.data.bones
    up = (bones["hips"].tail_local - bones["hips"].head_local)
    right = bones["thigh.R"].head_local - bones["thigh.L"].head_local
    return basis(up, right), bones["hips"].head_local.z


def pose_frame(arm, align, rest_basis, hip_height, source_hip_height, base_xy, in_place):
    """Copia un cuadro de la captura al esqueleto del Q'ispi."""
    hip_head, _ = world_points(arm, "Hips")
    lower, lower_tail = world_points(arm, "LowerBack")
    left, _ = world_points(arm, "LeftUpLeg")
    right, _ = world_points(arm, "RightUpLeg")
    source_basis = align @ basis(lower_tail - lower, right - left)
    for pb in rig.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()
    hips = rig.pose.bones["hips"]
    rest = hips.bone.matrix_local
    rotation = source_basis @ rest_basis.inverted() @ rest.to_3x3()
    offset = align @ (hip_head - base_xy)
    if in_place:
        offset.x = offset.y = 0.0
    scale = hip_height / source_hip_height
    position = Vector((offset.x * scale, offset.y * scale, (hip_head.z) * scale))
    position.z = rest.translation.z + (hip_head.z - source_hip_height) * scale
    hips.matrix = Matrix.Translation(position + Vector((rest.translation.x, rest.translation.y, 0))) @ rotation.to_4x4()
    bpy.context.view_layer.update()
    for name in ORDER[1:]:
        pb = rig.pose.bones[name]
        head, tail = world_points(arm, DIRECTIONS[name])
        wanted = align @ (tail - head)
        current = pb.matrix
        turn = (current.to_3x3() @ Vector((0, 1, 0))).rotation_difference(wanted)
        new = turn.to_matrix() @ current.to_3x3()
        if name == "head":
            new = Matrix.Rotation(math.radians(HEAD_TILT_DEGREES), 3, new @ Vector((0, 1, 0))) @ new
        pb.matrix = Matrix.Translation(current.translation) @ new.to_4x4()
        bpy.context.view_layer.update()


def retarget(action_name, path, start, length, in_place):
    """Importa un BVH, copia sus cuadros al Q'ispi y guarda la acción."""
    bpy.ops.import_anim.bvh(filepath=path, axis_forward="-Z", axis_up="Y", global_scale=0.056,
                            update_scene_fps=False, use_fps_scale=False, rotate_mode="NATIVE")
    arm = bpy.context.active_object
    scene.frame_end = int(arm.animation_data.action.frame_range[1])
    if length == "ciclo":
        first, last = foot_cycle(arm, start, SOURCE_FPS * 6)
    else:
        first, last = start, start + length
    if length == "ciclo":
        align = travel_alignment(arm, first, last)
    else:
        scene.frame_set(first)
        align = facing_alignment(arm)
    base = world_points(arm, "Hips")[0]
    heights = []
    for f in range(first, last + 1, STEP):
        scene.frame_set(f)
        heights.append(world_points(arm, "Hips")[0].z)
    source_hip_height = sum(heights) / len(heights)
    rest_basis, hip_height = target_rest()
    old = bpy.data.actions.get(action_name)
    if old:
        bpy.data.actions.remove(old)
    rig.animation_data_create()
    action = bpy.data.actions.new(action_name)
    action.use_fake_user = True
    rig.animation_data.action = action
    frames = list(range(first, last + 1, STEP))
    for i, f in enumerate(frames):
        scene.frame_set(f)
        pose_frame(arm, align, rest_basis, hip_height, source_hip_height, base, in_place)
        for pb in rig.pose.bones:
            pb.keyframe_insert("rotation_quaternion", frame=i)
            pb.keyframe_insert("location", frame=i)
    for track in list(rig.animation_data.nla_tracks):
        if track.name == action_name:
            rig.animation_data.nla_tracks.remove(track)
    track = rig.animation_data.nla_tracks.new()
    track.name = action_name
    track.strips.new(action_name, 0, action)
    rig.animation_data.action = None
    bpy.data.objects.remove(arm)
    print(f"{action_name}: {len(frames)} cuadros desde {os.path.basename(path)} [{first}-{last}]")


for name, (file, start, length, in_place) in CLIPS.items():
    retarget(name, os.path.join(bvh_dir, file), start, length, in_place)
for pb in rig.pose.bones:
    pb.matrix_basis = Matrix.Identity(4)

os.makedirs(out_dir, exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out_dir, "qispi_mocap.blend"))
bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True)
rig.select_set(True)
bpy.ops.export_scene.gltf(
    filepath=os.path.join(out_dir, "qispi.gltf"),
    use_selection=True,
    export_format="GLTF_SEPARATE",
    export_image_format="AUTO",
    export_animations=True,
    export_animation_mode="NLA_TRACKS",
    export_force_sampling=True,
)
print("captura exportada")
