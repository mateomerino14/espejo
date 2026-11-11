"""Pinta al Q'ispi: piel de sal con grietas hexagonales, cara humana pálida y cristales de halita.

Uso: python3 qispi_materials.py <entrada.blend> <salida.blend>
"""

import bpy  # noqa: I001
import sys
from mathutils import Vector

src, out = sys.argv[-2], sys.argv[-1]
bpy.ops.wm.open_mainfile(filepath=src)
HEAD = Vector((0.0, 0.2, 2.13))


def new_mat(name):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out_node = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    nt.links.new(bsdf.outputs[0], out_node.inputs[0])
    return m, nt, bsdf


def node(nt, kind, **props):
    n = nt.nodes.new(kind)
    for k, v in props.items():
        if k.startswith("in_"):
            n.inputs[k[3:].replace("_", " ")].default_value = v
        else:
            setattr(n, k, v)
    return n


def socket(sockets, identifier):
    """Busca un zócalo por su identificador, que no se repite como los nombres."""
    return next(sock for sock in sockets if sock.identifier == identifier)


def constant(nt, value):
    """Devuelve la salida de un nodo con un valor fijo, de color o de número."""
    if isinstance(value, tuple):
        n = nt.nodes.new("ShaderNodeRGB")
    else:
        n = nt.nodes.new("ShaderNodeValue")
    n.outputs[0].default_value = value
    return n.outputs[0]


def lerp(nt, a, b, fac, operation):
    """A + (B - A) * factor, armado con nodos de matemática para colores o números."""
    L = nt.links
    a = a if not isinstance(a, (tuple, float)) else constant(nt, a)
    b = b if not isinstance(b, (tuple, float)) else constant(nt, b)
    fac = fac if not isinstance(fac, float) else constant(nt, fac)
    if operation == "VECTOR":
        diff = node(nt, "ShaderNodeVectorMath", operation="SUBTRACT")
        scaled = node(nt, "ShaderNodeVectorMath", operation="SCALE")
        total = node(nt, "ShaderNodeVectorMath", operation="ADD")
        L.new(b, diff.inputs[0])
        L.new(a, diff.inputs[1])
        L.new(diff.outputs[0], scaled.inputs[0])
        L.new(fac, socket(scaled.inputs, "Scale"))
        L.new(a, total.inputs[0])
        L.new(scaled.outputs[0], total.inputs[1])
        return total.outputs[0]
    diff = node(nt, "ShaderNodeMath", operation="SUBTRACT")
    total = node(nt, "ShaderNodeMath", operation="MULTIPLY_ADD")
    L.new(b, diff.inputs[0])
    L.new(a, diff.inputs[1])
    L.new(diff.outputs[0], total.inputs[0])
    L.new(fac, total.inputs[1])
    L.new(a, total.inputs[2])
    return total.outputs[0]


def mix(nt, a, b, fac):
    return lerp(nt, a, b, fac, "VECTOR")


def mix_float(nt, a, b, fac):
    return lerp(nt, a, b, fac, "FLOAT")


def sphere_mask(nt, pos, center, radii, softness):
    """1 dentro de un elipsoide en espacio de objeto, con borde suave."""
    L = nt.links
    sub = node(nt, "ShaderNodeVectorMath", operation="SUBTRACT")
    sub.inputs[1].default_value = center
    L.new(pos, sub.inputs[0])
    div = node(nt, "ShaderNodeVectorMath", operation="DIVIDE")
    div.inputs[1].default_value = radii
    L.new(sub.outputs[0], div.inputs[0])
    length = node(nt, "ShaderNodeVectorMath", operation="LENGTH")
    L.new(div.outputs[0], length.inputs[0])
    mr = node(nt, "ShaderNodeMapRange", in_From_Min=1.0, in_From_Max=1.0 - softness,
              in_To_Min=0.0, in_To_Max=1.0)
    L.new(length.outputs["Value"], mr.inputs["Value"])
    return mr.outputs["Result"]


def maximum(nt, a, b):
    m = node(nt, "ShaderNodeMath", operation="MAXIMUM")
    nt.links.new(a, m.inputs[0])
    nt.links.new(b, m.inputs[1])
    return m.outputs[0]


def salt_skin(skin_ob):
    m, nt, bsdf = new_mat("QispiSalt")
    L = nt.links
    coords = node(nt, "ShaderNodeTexCoord")
    pos = coords.outputs["Object"]
    cells = node(nt, "ShaderNodeTexVoronoi", feature="DISTANCE_TO_EDGE", in_Scale=22.0)
    L.new(pos, cells.inputs["Vector"])
    crack = node(nt, "ShaderNodeMapRange", in_From_Min=0.035, in_From_Max=0.0,
                 in_To_Min=0.0, in_To_Max=1.0)
    L.new(cells.outputs["Distance"], crack.inputs["Value"])
    fine = node(nt, "ShaderNodeTexVoronoi", feature="DISTANCE_TO_EDGE", in_Scale=70.0)
    L.new(pos, fine.inputs["Vector"])
    fine_crack = node(nt, "ShaderNodeMapRange", in_From_Min=0.03, in_From_Max=0.0,
                      in_To_Min=0.0, in_To_Max=0.5)
    L.new(fine.outputs["Distance"], fine_crack.inputs["Value"])
    cracks = maximum(nt, crack.outputs["Result"], fine_crack.outputs["Result"])
    stains = node(nt, "ShaderNodeTexNoise", in_Scale=6.0, in_Detail=6.0)
    L.new(pos, stains.inputs["Vector"])
    base = mix(nt, (0.86, 0.85, 0.81, 1), (0.74, 0.71, 0.64, 1), stains.outputs["Fac"])
    face = sphere_mask(nt, pos, HEAD + Vector((0, 0.08, -0.04)), (0.09, 0.07, 0.14), 0.5)
    skin = mix(nt, base, (0.8, 0.69, 0.63, 1), face)
    hollows = [sphere_mask(nt, pos, Vector(skin_ob[key]), radii, 0.6) for key, radii in (
        ("socket_l", (0.026, 0.03, 0.022)),
        ("socket_r", (0.026, 0.03, 0.022)),
        ("mouth", (0.022, 0.035, 0.05)),
    )]
    dark = maximum(nt, maximum(nt, hollows[0], hollows[1]), hollows[2])
    skin = mix(nt, skin, (0.06, 0.05, 0.05, 1), dark)
    color = mix(nt, skin, (0.32, 0.29, 0.25, 1), cracks)
    L.new(color, bsdf.inputs["Base Color"])
    L.new(mix_float(nt, 0.72, 0.95, cracks), bsdf.inputs["Roughness"])
    bump = node(nt, "ShaderNodeBump", in_Strength=0.6, in_Distance=0.004)
    inverted = node(nt, "ShaderNodeMath", operation="SUBTRACT", in_Value=1.0)
    inverted.inputs[0].default_value = 1.0
    L.new(cracks, inverted.inputs[1])
    L.new(inverted.outputs[0], bump.inputs["Height"])
    L.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return m


def halite():
    m, nt, bsdf = new_mat("QispiCrystal")
    bsdf.inputs["Base Color"].default_value = (0.9, 0.93, 0.96, 1)
    bsdf.inputs["Roughness"].default_value = 0.18
    bsdf.inputs["Coat Weight"].default_value = 0.5
    return m


for ob in bpy.data.objects:
    if ob.type != "MESH":
        continue
    ob.data.materials.clear()
    if ob.name == "QispiHigh":
        ob.data.materials.append(salt_skin(ob))
    elif ob.name == "Crystals":
        ob.data.materials.append(halite())
        # Material liso: no gasta espacio de la textura horneada.
        ob["keep_material"] = True

bpy.ops.wm.save_as_mainfile(filepath=out)
print("materiales listos")
