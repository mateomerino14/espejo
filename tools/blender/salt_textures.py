"""Genera la textura repetible de madera de cardón, con los agujeros alargados del cactus seco.

La sal y la madera de tablas vienen de fotos reales: ver tools/download_textures.py.

Hornea materiales procedurales de Blender sobre un plano usando ruido 4D en un toro, así que
los bordes empalman sin costura. Las normales y la oclusión se calculan de la altura con numpy.

Uso: python3 salt_textures.py <carpeta_salida> <tamaño>
"""

import bpy  # noqa: I001
import addon_utils
import math
import os
import sys

import numpy as np

out_dir, size = sys.argv[-2], int(sys.argv[-1])
addon_utils.enable("cycles", default_set=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 1
os.makedirs(out_dir, exist_ok=True)

bpy.ops.mesh.primitive_plane_add(size=2)
plane = bpy.context.active_object


class Graph:
    """Ayuda a armar nodos de material con menos ruido."""

    def __init__(self, name):
        self.mat = bpy.data.materials.new(name)
        self.mat.use_nodes = True
        self.nt = self.mat.node_tree
        self.nt.nodes.clear()
        self.out = self.nt.nodes.new("ShaderNodeOutputMaterial")
        self.emit = self.nt.nodes.new("ShaderNodeEmission")
        self.nt.links.new(self.emit.outputs[0], self.out.inputs[0])
        self.target = self.nt.nodes.new("ShaderNodeTexImage")
        self.nt.nodes.active = self.target
        self._torus()

    def _torus(self):
        """Coordenadas 4D periódicas: (cos u, sin u, cos v) y W = sin v."""
        uv = self.node("ShaderNodeTexCoord").outputs["UV"]
        sep = self.node("ShaderNodeSeparateXYZ")
        self.link(uv, sep.inputs[0])
        parts = []
        for axis, fn in (("X", "COSINE"), ("X", "SINE"), ("Y", "COSINE"), ("Y", "SINE")):
            ang = self.math("MULTIPLY", sep.outputs[axis], math.tau)
            parts.append(self.math(fn, ang))
        comb = self.node("ShaderNodeCombineXYZ")
        for i in range(3):
            self.link(parts[i], comb.inputs[i])
        self.vec = comb.outputs[0]
        self.w = parts[3]

    def node(self, kind, **props):
        n = self.nt.nodes.new(kind)
        for k, v in props.items():
            if k.startswith("in_"):
                n.inputs[k[3:].replace("_", " ")].default_value = v
            else:
                setattr(n, k, v)
        return n

    def link(self, a, b):
        if isinstance(a, (int, float)):
            b.default_value = a
        else:
            self.nt.links.new(a, b)

    def math(self, op, a, b=None, clamp=False):
        n = self.node("ShaderNodeMath", operation=op, use_clamp=clamp)
        self.link(a, n.inputs[0])
        if b is not None:
            self.link(b, n.inputs[1])
        return n.outputs[0]

    def noise(self, scale, detail=6.0, rough=0.55, distortion=0.0, offset=0.0):
        n = self.node("ShaderNodeTexNoise", noise_dimensions="4D", in_Scale=scale, in_Detail=detail,
                      in_Roughness=rough, in_Distortion=distortion)
        self.link(self._shift(offset), n.inputs["Vector"])
        self.link(self.w, n.inputs["W"])
        return n.outputs["Fac"]

    def voronoi(self, scale, feature="F1", output="Distance", offset=0.0, randomness=1.0):
        n = self.node("ShaderNodeTexVoronoi", voronoi_dimensions="4D", feature=feature, in_Scale=scale,
                      in_Randomness=randomness)
        self.link(self._shift(offset), n.inputs["Vector"])
        self.link(self.w, n.inputs["W"])
        return n.outputs[output]

    def _shift(self, offset):
        if not offset:
            return self.vec
        add = self.node("ShaderNodeVectorMath", operation="ADD")
        self.link(self.vec, add.inputs[0])
        add.inputs[1].default_value = (offset, offset * 1.7, offset * 0.6)
        return add.outputs[0]

    def remap(self, value, a, b, c=0.0, d=1.0):
        n = self.node("ShaderNodeMapRange", in_From_Min=a, in_From_Max=b, in_To_Min=c, in_To_Max=d)
        self.link(value, n.inputs["Value"])
        return n.outputs["Result"]

    def ramp(self, value, stops):
        r = self.node("ShaderNodeValToRGB")
        els = r.color_ramp.elements
        els[0].position, els[0].color = stops[0]
        els[1].position, els[1].color = stops[-1]
        for pos, col in stops[1:-1]:
            els.new(pos).color = col
        self.link(value, r.inputs["Fac"])
        return r.outputs["Color"]

    def mix(self, a, b, fac):
        m = self.node("ShaderNodeMix", data_type="RGBA")
        self.link(fac, m.inputs["Factor"])
        for sock, val in ((m.inputs[6], a), (m.inputs[7], b)):
            if isinstance(val, tuple):
                sock.default_value = val
            else:
                self.link(val, sock)
        return m.outputs[2]

    def uv(self):
        """Devuelve U y V del plano, para patrones que deben repetirse en celdas exactas."""
        sep = self.node("ShaderNodeSeparateXYZ")
        self.link(self.node("ShaderNodeTexCoord").outputs["UV"], sep.inputs[0])
        return sep.outputs["X"], sep.outputs["Y"]

    def bake(self, socket, name, is_color):
        """Hornea una salida a una imagen y devuelve sus píxeles como arreglo."""
        img = bpy.data.images.new(name, size, size, alpha=False, float_buffer=True)
        if not is_color:
            img.colorspace_settings.name = "Non-Color"
        self.target.image = img
        self.nt.links.new(socket, self.emit.inputs["Color"])
        plane.data.materials.clear()
        plane.data.materials.append(self.mat)
        bpy.ops.object.select_all(action="DESELECT")
        plane.select_set(True)
        bpy.context.view_layer.objects.active = plane
        bpy.ops.object.bake(type="EMIT", margin=0)
        px = np.empty(size * size * 4, dtype=np.float32)
        img.pixels.foreach_get(px)
        return px.reshape(size, size, 4)[:, :, :3]


def cardon():
    """Madera de cardón: fibras grises con los agujeros alargados del cactus seco."""
    g = Graph("Cardon")
    u, v = g.uv()
    warp = g.noise(2.0, 3.0, 0.5, offset=4.0)
    along = g.math("ADD", g.math("MULTIPLY", u, 18.0), g.math("MULTIPLY", warp, 0.6))
    fibers = g.math("MULTIPLY", g.math("ADD", g.math("SINE", g.math("MULTIPLY", along, math.tau)), 1.0), 0.5)
    fine = g.math("ADD", g.math("MULTIPLY", u, 110.0), g.math("MULTIPLY", g.noise(7.0, 4.0, 0.5, offset=8.0), 1.4))
    grain = g.math("MULTIPLY", g.math("ADD", g.math("SINE", g.math("MULTIPLY", fine, math.tau)), 1.0), 0.5)
    # Agujeros: uno por celda de una grilla de 6 × 2, así la textura se repite sin costura.
    # Cada celda es tres veces más alta que ancha, y el agujero sale estirado a lo largo de la fibra.
    cu = g.math("MULTIPLY", u, 6.0)
    cv = g.math("MULTIPLY", v, 2.0)
    cell = g.node("ShaderNodeCombineXYZ")
    g.link(g.math("FLOOR", cu), cell.inputs[0])
    g.link(g.math("FLOOR", cv), cell.inputs[1])
    jitter = g.node("ShaderNodeTexWhiteNoise", noise_dimensions="3D")
    g.link(cell.outputs[0], jitter.inputs["Vector"])
    rand = g.node("ShaderNodeSeparateColor")
    g.link(jitter.outputs["Color"], rand.inputs[0])
    dx = g.math("SUBTRACT", g.math("FRACT", cu), g.math("ADD", 0.35, g.math("MULTIPLY", rand.outputs[0], 0.3)))
    dy = g.math("SUBTRACT", g.math("FRACT", cv), g.math("ADD", 0.35, g.math("MULTIPLY", rand.outputs[1], 0.3)))
    distance = g.math("SQRT", g.math("ADD", g.math("MULTIPLY", dx, dx), g.math("MULTIPLY", dy, dy)))
    radius = g.math("ADD", 0.07, g.math("MULTIPLY", rand.outputs[2], 0.09))
    holes = g.math("SUBTRACT", 1.0, g.math("DIVIDE", distance, radius), clamp=True)
    holes = g.remap(holes, 0.0, 0.25)
    height = g.math("ADD", g.math("MULTIPLY", fibers, 0.3), g.math("MULTIPLY", grain, 0.3))
    height = g.math("SUBTRACT", height, g.math("MULTIPLY", holes, 0.8))
    tone = g.math("ADD", g.math("MULTIPLY", fibers, 0.5), g.math("MULTIPLY", g.noise(2.5, 5.0, 0.6), 0.5))
    color = g.ramp(tone, [(0.25, (0.2, 0.16, 0.12, 1)), (0.55, (0.38, 0.32, 0.25, 1)),
                          (0.85, (0.52, 0.46, 0.38, 1))])
    color = g.mix(color, (0.08, 0.06, 0.04, 1), g.math("MULTIPLY", holes, 0.85))
    rough = g.math("ADD", 0.72, g.math("MULTIPLY", grain, 0.2))
    return g, height, color, rough


def wrap_gradient(h, axis):
    return (np.roll(h, -1, axis) - np.roll(h, 1, axis)) * 0.5


def normal_map(h, strength):
    dx = wrap_gradient(h, 1) * strength * size / 512
    dy = wrap_gradient(h, 0) * strength * size / 512
    n = np.dstack((-dx, -dy, np.ones_like(h)))
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    return n * 0.5 + 0.5


def occlusion(h):
    """Oclusión barata: qué tan hundido está cada punto respecto a su entorno."""
    blurred = h.copy()
    for radius in (2, 4, 8):
        acc = np.zeros_like(h)
        for dy in (-radius, 0, radius):
            for dx in (-radius, 0, radius):
                acc += np.roll(np.roll(h, dy, 0), dx, 1)
        blurred = acc / 9.0
    return np.clip(1.0 - (blurred - h) * 3.0, 0.35, 1.0)


def to_srgb(linear):
    """Las imágenes de 8 bits guardan el color ya codificado en sRGB."""
    linear = np.clip(linear, 0.0, 1.0)
    return np.where(linear <= 0.0031308, linear * 12.92, 1.055 * np.power(linear, 1 / 2.4) - 0.055)


def save(name, rgb, is_color):
    img = bpy.data.images.new(name, size, size, alpha=False)
    if not is_color:
        img.colorspace_settings.name = "Non-Color"
    rgba = np.dstack((rgb, np.ones(rgb.shape[:2], dtype=np.float32))).astype(np.float32)
    img.pixels.foreach_set(rgba.ravel())
    img.filepath_raw = os.path.join(out_dir, name + ".png")
    img.file_format = "PNG"
    img.save()
    print("textura", name)


for name, builder, strength in (("cardon", cardon, 4.0),):
    graph, height_s, color_s, rough_s = builder()
    height = graph.bake(height_s, name + "_h", False)[:, :, 0]
    color = graph.bake(color_s, name + "_c", True)
    rough = graph.bake(rough_s, name + "_r", False)[:, :, 0]
    ao = occlusion(height)
    save(f"{name}_albedo", to_srgb(color * ao[:, :, None]), True)
    save(f"{name}_normal", normal_map(height, strength), False)
    save(f"{name}_orm", np.dstack((ao, np.clip(rough, 0.0, 1.0), np.zeros_like(ao))), False)
