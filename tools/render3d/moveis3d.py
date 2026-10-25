"""Móveis em 3D (arte realista, DT-085): as famílias de cadeiras, mesas, fogões e balcões, com os mesmos parâmetros
da arte 2D (tools/art_direction/v3/themes3.py), modeladas e fotografadas no ângulo do jogo, gravadas em art/sprites.

Uso (na pasta do projeto):
    C:/Blender/blender-5.2.3-windows-x64/blender.exe -b -P tools/render3d/moveis3d.py -- [ids...] [rascunho]

Sem ids, faz todos os móveis das quatro famílias. Também refaz os encostos (o que cobre quem senta de costas) e o
forno aceso.

As medidas seguem a arte 2D, para o que o jogo desenha por cima cair no lugar: a altura do tampo das mesas
(table_tops), do tampo dos balcões (pratos), das bocas do fogão (panelas) e do assento (quem senta).
Cada móvel é montado com o centro do piso na origem e a frente virada para -Y (o +y do jogo, rotação 0); a rotação
r gira o móvel em torno do centro do piso.
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "art_direction", "v3"))
import cena3d  # noqa: E402
from cena3d import DESIGN_Z as PX, aim_camera, linear  # noqa: E402

WORK = os.path.join(cena3d.ROOT, "tools", "render3d", "out_moveis")
IMAGE_SIZE = (420, 460)
ROTATION_ANGLE = {0: 0.0, 1: -90.0, 2: 180.0, 3: 90.0}

CHROME = "#d9dee5"
WOOD_M = "#b97a45"
WOOD_D = "#8a5530"
SEAT_FRAME = 23 * PX       # alturas da arte 2D: o estofado do assento termina perto de 0,47
SEAT_TOP = 0.465
SEAT_HALF = 0.25           # o assento ocupa o meio do piso (0,26 a 0,74 na arte 2D)
STOVE_SIZE, STOVE_INSET, STOVE_HEIGHT = 0.9, 0.05, 44 * PX
STOVE_BURNERS = [(0.3, 0.3), (0.72, 0.3), (0.3, 0.72), (0.72, 0.72)]
COUNTER_HEIGHT, COUNTER_TOP = 42 * PX, 5 * PX
SHADOW_MARGIN = 0.08       # a sombra vai só um pouco além da pegada (o móvel não invade o piso do vizinho)

_materials = {}


# --- Materiais -----------------------------------------------------------------------------------------------

def _principled(name):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    return mat, mat.node_tree.nodes, mat.node_tree.links, mat.node_tree.nodes.get("Principled BSDF")


def solid(color, rough=0.45, metal=0.0, coat=0.0):
    key = ("solid", color, rough, metal, coat)
    if key not in _materials:
        mat, _, _, bsdf = _principled("Cor_" + color)
        bsdf.inputs["Base Color"].default_value = linear(color)
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal
        bsdf.inputs["Coat Weight"].default_value = coat
        _materials[key] = mat
    return _materials[key]


def chrome(color=CHROME):
    return solid(color, 0.16, 1.0)


def lacquer(color):
    """Laca ou esmalte brilhante (fogões, assentos estofados de vinil)."""
    return solid(color, 0.3, 0.0, 0.7)


def emission(color, strength=4.0):
    key = ("emission", color, strength)
    if key not in _materials:
        mat, _, _, bsdf = _principled("Luz_" + color)
        bsdf.inputs["Base Color"].default_value = linear(color)
        bsdf.inputs["Emission Color"].default_value = linear(color)
        bsdf.inputs["Emission Strength"].default_value = strength
        _materials[key] = mat
    return _materials[key]


def _ramp(nodes, links, factor, a, b, positions=(0.0, 1.0)):
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position, ramp.color_ramp.elements[1].position = positions
    ramp.color_ramp.elements[0].color = linear(a)
    ramp.color_ramp.elements[1].color = linear(b)
    links.new(factor, ramp.inputs["Fac"])
    return ramp.outputs["Color"]


def _coords(nodes, scale):
    coords = nodes.new("ShaderNodeTexCoord")
    mapping = nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = (scale, scale, scale)
    nodes.id_data.links.new(coords.outputs["Object"], mapping.inputs["Vector"])
    return mapping.outputs["Vector"]


def wood(color):
    """Madeira: veios em faixas onduladas, do tom da cor a um tom mais escuro."""
    key = ("wood", color)
    if key not in _materials:
        mat, nodes, links, bsdf = _principled("Madeira_" + color)
        wave = nodes.new("ShaderNodeTexWave")
        wave.wave_type = "BANDS"
        wave.inputs["Scale"].default_value = 7.0
        wave.inputs["Distortion"].default_value = 4.0
        wave.inputs["Detail"].default_value = 3.0
        links.new(_coords(nodes, 1.0), wave.inputs["Vector"])
        links.new(_ramp(nodes, links, wave.outputs["Fac"], _shade(color, 0.22), color, (0.2, 0.8)), bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.5
        bsdf.inputs["Coat Weight"].default_value = 0.25
        _materials[key] = mat
    return _materials[key]


def marble(color):
    key = ("marble", color)
    if key not in _materials:
        mat, nodes, links, bsdf = _principled("Marmore_" + color)
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 2.5
        noise.inputs["Detail"].default_value = 6.0
        noise.inputs["Distortion"].default_value = 4.0
        links.new(_coords(nodes, 1.0), noise.inputs["Vector"])
        links.new(_ramp(nodes, links, noise.outputs["Fac"], color, _shade(color, 0.25), (0.6, 0.63)), bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.12
        bsdf.inputs["Coat Weight"].default_value = 0.6
        _materials[key] = mat
    return _materials[key]


def fabric(kind, color):
    """Tecidos das toalhas: xadrez (gingham), confete, chita (florido) e liso."""
    key = ("fabric", kind, color)
    if key in _materials:
        return _materials[key]
    mat, nodes, links, bsdf = _principled(f"Tecido_{kind}_{color}")
    bsdf.inputs["Roughness"].default_value = 0.85
    bsdf.inputs["Sheen Weight"].default_value = 0.4
    if kind == "gingham":
        checker = nodes.new("ShaderNodeTexChecker")
        checker.inputs["Scale"].default_value = 22.0
        checker.inputs["Color1"].default_value = linear(color)
        checker.inputs["Color2"].default_value = linear("#fbf7f0")
        links.new(_coords(nodes, 1.0), checker.inputs["Vector"])
        links.new(checker.outputs["Color"], bsdf.inputs["Base Color"])
    elif kind in ("confetti", "chita"):
        voronoi = nodes.new("ShaderNodeTexVoronoi")
        voronoi.inputs["Scale"].default_value = 30.0 if kind == "confetti" else 16.0
        links.new(_coords(nodes, 1.0), voronoi.inputs["Vector"])
        dots = _ramp(nodes, links, voronoi.outputs["Distance"], "#000000", "#ffffff", (0.18, 0.22) if kind == "confetti" else (0.3, 0.36))
        mix = nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        links.new(dots, mix.inputs[0])
        links.new(voronoi.outputs["Color"], mix.inputs[6])
        mix.inputs[7].default_value = linear(color)
        links.new(mix.outputs[2], bsdf.inputs["Base Color"])
    else:
        bsdf.inputs["Base Color"].default_value = linear(color)
    _materials[key] = mat
    return mat


def weave(color):
    """Palhinha (cane) ou vime (wicker): trama em xadrez fino com relevo."""
    key = ("weave", color)
    if key not in _materials:
        mat, nodes, links, bsdf = _principled("Trama_" + color)
        brick = nodes.new("ShaderNodeTexBrick")
        brick.inputs["Scale"].default_value = 26.0
        brick.inputs["Color1"].default_value = linear(color)
        brick.inputs["Color2"].default_value = linear(_shade(color, 0.15))
        brick.inputs["Mortar"].default_value = linear(_shade(color, 0.55))
        brick.inputs["Mortar Size"].default_value = 0.04
        links.new(_coords(nodes, 1.0), brick.inputs["Vector"])
        links.new(brick.outputs["Color"], bsdf.inputs["Base Color"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.5
        links.new(brick.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
        bsdf.inputs["Roughness"].default_value = 0.7
        _materials[key] = mat
    return _materials[key]


def talavera():
    """Azulejo mexicano: branco com o desenho azul em xadrez."""
    key = ("talavera",)
    if key not in _materials:
        mat, nodes, links, bsdf = _principled("Talavera")
        checker = nodes.new("ShaderNodeTexChecker")
        checker.inputs["Scale"].default_value = 12.0
        checker.inputs["Color1"].default_value = linear("#2f6fd9")
        checker.inputs["Color2"].default_value = linear("#f7f3ea")
        links.new(_coords(nodes, 1.0), checker.inputs["Vector"])
        links.new(checker.outputs["Color"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.15
        bsdf.inputs["Coat Weight"].default_value = 0.8
        _materials[key] = mat
    return _materials[key]


def _shade(hex_color, t):
    h = hex_color.lstrip("#")
    return "#" + "".join(f"{int(int(h[i:i + 2], 16) * (1 - t)):02x}" for i in (0, 2, 4))


def _tint(hex_color, t):
    h = hex_color.lstrip("#")
    return "#" + "".join(f"{int(int(h[i:i + 2], 16) + (255 - int(h[i:i + 2], 16)) * t):02x}" for i in (0, 2, 4))


# --- Peças ---------------------------------------------------------------------------------------------------

def _finish(obj, mat, bevel=0.0, segments=3, smooth=True):
    obj.data.materials.append(mat)
    if bevel > 0.0:
        mod = obj.modifiers.new("Chanfro", "BEVEL")
        mod.width = bevel
        mod.segments = segments
        mod.limit_method = "ANGLE"
    if smooth:
        for poly in obj.data.polygons:
            poly.use_smooth = True
    return obj


def box(size, center, mat, bevel=0.008):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=center)
    obj = bpy.context.active_object
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return _finish(obj, mat, bevel)


def cylinder(radius, z0, z1, mat, center=(0.0, 0.0), bevel=0.004, vertices=48):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=z1 - z0, location=(center[0], center[1], (z0 + z1) / 2),
                                        vertices=vertices)
    return _finish(bpy.context.active_object, mat, bevel)


def sphere(radius, center, mat, scale=(1.0, 1.0, 1.0)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=center, segments=32, ring_count=16)
    obj = bpy.context.active_object
    obj.scale = scale
    return _finish(obj, mat)


def tube(a, b, radius, mat):
    a, b = Vector(a), Vector(b)
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=(b - a).length, location=(a + b) / 2, vertices=20)
    obj = bpy.context.active_object
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = (b - a).to_track_quat("Z", "Y")
    return _finish(obj, mat, 0.002)


def half_shell(size, center, mat, keep_back=True, thickness=0.025):
    """Meia casca (encosto ovo e concha): a metade de trás de uma esfera achatada, com espessura."""
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, location=(0, 0, 0), segments=48, ring_count=24)
    obj = bpy.context.active_object
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if (v.co.y < -0.05) == keep_back or v.co.z < -0.6], context="VERTS")
    bm.to_mesh(obj.data)
    bm.free()
    obj.scale = size
    obj.location = center
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    solid_mod = obj.modifiers.new("Espessura", "SOLIDIFY")
    solid_mod.thickness = thickness
    return _finish(obj, mat)


# --- Cadeiras ------------------------------------------------------------------------------------------------

def chair(seat="#ff4d5e", legs="chrome", leg_color=CHROME, back="panel", back_color=None, back_h=30):
    """Cadeira: pés ('chrome', 'wood' ou 'pedestal'), assento estofado e o encosto no lado +Y (o de trás).
    Devolve (peças, peças do encosto)."""
    back_color = back_color or seat
    leg_mat = chrome(leg_color) if legs in ("chrome", "pedestal") and leg_color in (CHROME, "#c9d3de") else (
        wood(leg_color) if legs == "wood" else lacquer(leg_color))
    parts, back_parts = [], []
    s = SEAT_HALF
    if legs == "pedestal":
        parts.append(cylinder(0.17, 0.0, 0.03, leg_mat, bevel=0.01))
        parts.append(cylinder(0.035, 0.03, SEAT_FRAME, leg_mat))
    elif back is None:
        # banqueta de pés: os quatro pés debaixo do assento redondo, um pouco abertos embaixo
        radius = 0.016 if legs == "chrome" else 0.022
        for sx in (-1, 1):
            for sy in (-1, 1):
                parts.append(tube((sx * 0.15, sy * 0.15, 0.0), (sx * 0.11, sy * 0.11, SEAT_FRAME), radius, leg_mat))
        parts.append(_ring(0.15, 0.008, SEAT_FRAME * 0.45, leg_mat))
    else:
        radius = 0.018 if legs == "chrome" else 0.026
        for sx in (-1, 1):
            for sy in (-1, 1):
                if legs == "wood":
                    parts.append(box((radius * 2, radius * 2, SEAT_FRAME), (sx * (s - 0.04), sy * (s - 0.04), SEAT_FRAME / 2),
                                     leg_mat, 0.004))
                else:
                    parts.append(tube((sx * (s - 0.03), sy * (s - 0.03), 0.0), (sx * (s - 0.04), sy * (s - 0.04), SEAT_FRAME),
                                      radius, leg_mat))
    if back is None:
        parts.append(cylinder(0.25, SEAT_FRAME, SEAT_FRAME + 0.035, chrome(), bevel=0.01))
        parts.append(cylinder(0.24, SEAT_FRAME + 0.03, SEAT_TOP, lacquer(seat), bevel=0.03))
        return parts, back_parts
    parts.append(box((2 * s, 2 * s, 0.04), (0.0, 0.0, SEAT_FRAME + 0.02), solid(_shade(seat, 0.3)), 0.006))
    parts.append(box((2 * s - 0.01, 2 * s - 0.01, SEAT_TOP - SEAT_FRAME - 0.035), (0.0, -0.005, (SEAT_FRAME + 0.035 + SEAT_TOP) / 2),
                     lacquer(seat), 0.03))
    height = back_h * PX * 0.66   # um pouco mais baixo que o desenho, para quem senta de costas aparecer
    z0 = SEAT_TOP + 0.02
    bmat = lacquer(back_color)
    y = s - 0.02
    post_mat = leg_mat if legs != "pedestal" else solid(_shade(back_color, 0.2))
    if back not in ("egg", "shell"):
        for sx in (-1, 1):
            back_parts.append(tube((sx * (s - 0.04), y, SEAT_FRAME), (sx * (s - 0.04), y + 0.02, z0 + height), 0.018, post_mat))
    if back == "panel":
        back_parts.append(box((2 * s - 0.04, 0.05, height), (0.0, y + 0.02, z0 + height / 2), bmat, 0.022))
    elif back == "slats":
        back_parts.append(box((2 * s, 0.045, 0.06), (0.0, y + 0.02, z0 + height - 0.03), bmat, 0.01))
        for i in range(3):
            back_parts.append(box((0.05, 0.03, height - 0.06), (-s * 0.56 + i * s * 0.56, y + 0.02, z0 + (height - 0.06) / 2), bmat, 0.006))
    elif back == "ladder":
        for i in range(3):
            back_parts.append(box((2 * s - 0.06, 0.03, 0.05), (0.0, y + 0.02, z0 + height * (0.3 + i * 0.3)), bmat, 0.008))
    elif back == "shell":
        back_parts.append(half_shell((s * 1.05, 0.2, height * 0.9), (0.0, 0.02, z0 + height * 0.05), bmat))
    elif back == "egg":
        back_parts.append(half_shell((s * 1.25, 0.28, height * 1.15), (0.0, 0.0, z0 + height * 0.1), bmat, thickness=0.035))
    elif back in ("wicker", "cane"):
        back_parts.append(box((2 * s - 0.04, 0.03, height), (0.0, y + 0.02, z0 + height / 2), weave(back_color), 0.02 if back == "wicker" else 0.006))
        back_parts.append(box((2 * s, 0.04, 0.04), (0.0, y + 0.02, z0 + height), wood(_shade(back_color, 0.4)), 0.01))
    elif back == "tufted":
        back_parts.append(box((2 * s - 0.02, 0.08, height), (0.0, y + 0.03, z0 + height / 2), bmat, 0.04))
        for (u, v) in [(-0.5, 0.35), (0.0, 0.35), (0.5, 0.35), (-0.25, 0.68), (0.25, 0.68)]:
            back_parts.append(sphere(0.012, (u * s, y - 0.012, z0 + height * v), solid(_shade(back_color, 0.45))))
    elif back == "painted":
        back_parts.append(box((2 * s - 0.04, 0.04, height), (0.0, y + 0.02, z0 + height / 2), bmat, 0.02))
        for (u, v, c) in [(-0.4, 0.45, "#ff4d6d"), (0.4, 0.45, "#e0303a"), (0.0, 0.75, "#ffffff")]:
            for a in range(0, 360, 72):
                back_parts.append(sphere(0.016, (u * s + math.cos(math.radians(a)) * 0.022, y - 0.004,
                                                 z0 + height * v + math.sin(math.radians(a)) * 0.022), solid(c), (1, 0.4, 1)))
            back_parts.append(sphere(0.012, (u * s, y - 0.008, z0 + height * v), solid("#2fae4e"), (1, 0.4, 1)))
    return parts, back_parts


# --- Mesas ---------------------------------------------------------------------------------------------------

def table(shape="square", top=("solid", "#ffffff"), edge="#ff4d5e", base="pedestal", base_color=CHROME, cloth=None,
          height=32, vase=True, candle=False, flower=("#ff4d8d", "#ffd23f"), width=1.0):
    """Mesa: redonda ou quadrada (width 2 = a comprida, ao longo de X), tampo de vários tipos, toalha opcional."""
    h = height * PX
    parts = []
    base_mat = chrome(base_color) if base_color in (CHROME, "#c9d3de") else (wood(base_color) if base_color in (WOOD_D, WOOD_M, "#8a4f26", "#5a3020", "#2a1a12") else lacquer(base_color))
    offsets = [((i - (width - 1) / 2), 0.0) for i in range(int(width))]
    if base == "pedestal":
        for ox, oy in offsets:
            parts.append(cylinder(0.2, 0.0, 0.03, base_mat, (ox, oy), bevel=0.01))
            parts.append(cylinder(0.045, 0.03, h - 0.05, base_mat, (ox, oy)))
    else:
        hx = width / 2 - 0.14
        for sx in (-1, 1):
            for sy in (-1, 1):
                parts.append(box((0.05, 0.05, h - 0.04), (sx * hx, sy * 0.36, (h - 0.04) / 2), base_mat, 0.006))
    kind, color = top
    top_mat = {"solid": solid(color, 0.25, 0.0, 0.5), "wood": wood(color), "marble": marble(color),
               "talavera": talavera()}.get(kind, solid(color, 0.25, 0.0, 0.5))
    if shape == "round":
        if cloth:
            mat = fabric(*cloth)
            parts.append(cylinder(0.41, h - 0.2, h, mat, bevel=0.012, vertices=64))
        else:
            parts.append(cylinder(0.4, h - 0.045, h - 0.012, lacquer(edge) if edge not in (CHROME,) else chrome(), bevel=0.008, vertices=64))
            parts.append(cylinder(0.4, h - 0.014, h, top_mat, bevel=0.006, vertices=64))
            if kind == "memphis":
                for (u, v, c) in [(-0.16, 0.05, "#ff4dd2"), (0.18, -0.06, "#4fe0ff"), (0.02, 0.2, "#2a2d6e"), (-0.05, -0.18, "#ffd23f")]:
                    parts.append(sphere(0.05, (u, v, h + 0.002), solid(c, 0.3), (1, 1, 0.08)))
            elif kind == "glow":
                parts.append(_ring(0.37, 0.01, h + 0.004, emission("#4fe0ff", 6.0)))
                parts.append(_ring(0.405, 0.008, h - 0.03, emission("#ff4dd2", 6.0)))
    else:
        w, d = width - 0.12, 0.88
        if cloth:
            mat = fabric(*cloth)
            parts.append(box((w + 0.03, d + 0.03, 0.22), (0.0, 0.0, h - 0.11), mat, 0.012))
        else:
            parts.append(box((w, d, 0.06), (0.0, 0.0, h - 0.03), lacquer(edge) if edge != CHROME else chrome(), 0.01))
            parts.append(box((w - 0.01, d - 0.01, 0.012), (0.0, 0.0, h - 0.002), top_mat, 0.004))
            if kind == "glow":
                parts.append(_rect_ring(w - 0.06, d - 0.06, h + 0.004, emission("#4fe0ff", 6.0)))
                parts.append(_rect_ring(w - 0.2, d - 0.2, h + 0.004, emission("#ff4dd2", 6.0)))
    if candle:
        parts.append(cylinder(0.045, h, h + 0.13, solid("#2f7a3a", 0.1, 0.0, 1.0)))
        parts.append(cylinder(0.018, h + 0.13, h + 0.22, solid("#fff6d8", 0.6)))
        parts.append(sphere(0.012, (0.0, 0.0, h + 0.245), emission("#ffb13d", 30.0), (1, 1, 1.8)))
    elif vase:
        parts.append(cylinder(0.04, h, h + 0.12, solid("#bfefff", 0.05, 0.0, 1.0), bevel=0.01))
        parts.append(tube((0.0, 0.0, h + 0.1), (0.0, 0.0, h + 0.19), 0.004, solid("#2f8a3a")))
        parts.append(sphere(0.035, (-0.012, 0.0, h + 0.2), solid(flower[0], 0.6)))
        parts.append(sphere(0.03, (0.03, 0.02, h + 0.17), solid(flower[1], 0.6)))
    return parts


def _ring(radius, thickness, z, mat):
    bpy.ops.mesh.primitive_torus_add(major_radius=radius, minor_radius=thickness, location=(0, 0, z), major_segments=64,
                                     minor_segments=8)
    return _finish(bpy.context.active_object, mat)


def _rect_ring(w, d, z, mat, t=0.012):
    return [box((w, t, t), (0.0, d / 2, z), mat, 0.0), box((w, t, t), (0.0, -d / 2, z), mat, 0.0),
            box((t, d, t), (w / 2, 0.0, z), mat, 0.0), box((t, d, t), (-w / 2, 0.0, z), mat, 0.0)]


# --- Fogões --------------------------------------------------------------------------------------------------

def stove(enamel="#e33a42", top_color="#ffffff", panel=None, knob="#1d1e23", door=None, handle="#f4f7fa"):
    """Fogão: corpo esmaltado, tampo de vidro preto com 4 bocas (no lugar das da arte 2D, onde o jogo põe a panela),
    painel com os botões, porta do forno com o visor e o puxador. A frente é o lado -Y."""
    h = STOVE_HEIGHT
    w = STOVE_SIZE
    body = lacquer(enamel)
    parts = [box((w, w, h - 0.03), (0.0, 0.0, (h - 0.03) / 2 + 0.03), body, 0.03)]
    parts.append(box((w - 0.02, w - 0.02, 0.012), (0.0, 0.0, h - 0.004), solid(top_color, 0.3, 0.0, 0.5), 0.004))
    parts.append(box((w - 0.08, w - 0.08, 0.012), (0.0, 0.0, h + 0.004), solid("#15161b", 0.12, 0.0, 0.8), 0.004))
    iron = solid("#2a2b31", 0.5, 0.6)
    for (u, v) in STOVE_BURNERS:
        x, y = (u - 0.5) * w, -(v - 0.5) * w
        parts.append(_burner(x, y, h + 0.012, iron))
    front = -w / 2
    panel_color = (panel or ("#e8edf2", "#c9d3de", "#8f9aa7"))[1]
    parts.append(box((w - 0.05, 0.03, 0.1), (0.0, front - 0.006, h - 0.07), chrome(panel_color) if panel is None else lacquer(panel_color), 0.008))
    for i in range(4):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.026, depth=0.03, location=((i - 1.5) * 0.17, front - 0.03, h - 0.07),
                                            rotation=(math.radians(90), 0, 0), vertices=24)
        parts.append(_finish(bpy.context.active_object, solid(knob, 0.35), 0.004))
    door_color = (door or (enamel, enamel))[0]
    parts.append(box((w - 0.14, 0.02, h * 0.52), (0.0, front - 0.006, h * 0.36), lacquer(door_color), 0.012))
    parts.append(box((w * 0.5, 0.02, h * 0.2), (0.0, front - 0.013, h * 0.4), solid("#141a24", 0.06, 0.0, 1.0), 0.008))
    parts.append(tube((-0.25, front - 0.05, h * 0.6), (0.25, front - 0.05, h * 0.6), 0.011, chrome(handle) if handle in ("#f4f7fa", "#c9d3de") else lacquer(handle)))
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(cylinder(0.022, 0.0, 0.03, chrome(), (sx * 0.38, sy * 0.38)))
    return parts


def _burner(x, y, z, mat):
    bpy.ops.mesh.primitive_torus_add(major_radius=0.075, minor_radius=0.01, location=(x, y, z), major_segments=48, minor_segments=8)
    ring = _finish(bpy.context.active_object, mat)
    return [ring, cylinder(0.045, z - 0.004, z + 0.01, mat, (x, y))]


def oven_window(rotation):
    """O visor do forno aceso (o jogo desenha por cima do fogão que cozinha): só o vidro, brilhando."""
    h = STOVE_HEIGHT
    return [box((STOVE_SIZE * 0.5, 0.004, h * 0.2), (0.0, -STOVE_SIZE / 2 - 0.024, h * 0.4), emission("#ffab40", 3.0), 0.004)]


# --- Balcões -------------------------------------------------------------------------------------------------

def counter(body="#2ec4b6", top="#ffffff", face="panels", rim="#e8edf2", veins=True):
    """Balcão: corpo colorido (frente com frisos, tábuas ou lisa), tampo de mármore ou da cor pedida, borda."""
    h = COUNTER_HEIGHT
    w, d = 0.86, 0.88
    body_mat = wood(body) if face == "planks" else (chrome(body) if body in ("#b9c3cf",) else lacquer(body))
    parts = [box((w, d, h - 0.04), (0.0, 0.0, (h - 0.04) / 2 + 0.04), body_mat, 0.012)]
    parts.append(box((w - 0.04, d - 0.04, 0.04), (0.0, 0.0, 0.02), solid(_shade(body, 0.45), 0.6), 0.004))
    front = -d / 2
    if face == "panels":
        for u in (-0.21, 0.21):
            parts.append(box((0.32, 0.02, h * 0.6), (u, front - 0.006, h * 0.5), lacquer(_tint(body, 0.12)), 0.015))
    elif face == "plain":
        parts.append(box((w - 0.02, 0.012, 0.02), (0.0, front - 0.002, h * 0.6), chrome(), 0.004))
    parts.append(box((w + 0.04, d + 0.04, 0.03), (0.0, 0.0, h + 0.015), lacquer(rim) if rim not in (CHROME, "#c9d3de", "#e8edf2") else chrome(rim), 0.008))
    top_mat = marble(top) if veins else solid(top, 0.2, 0.0, 0.6)
    parts.append(box((w + 0.04, d + 0.04, COUNTER_TOP - 0.03), (0.0, 0.0, h + 0.03 + (COUNTER_TOP - 0.03) / 2), top_mat, 0.006))
    return parts


# --- Catálogo: os parâmetros da arte 2D ----------------------------------------------------------------------

def catalog():
    import themes3
    items = {
        "chair_wood": ("chair", dict(seat="#e0343f", legs="chrome", back="panel")),
        "table_round": ("table", dict(shape="round", cloth=("gingham", "#e2343c"), base="pedestal", height=34)),
        "table_long": ("table", dict(shape="square", top=("solid", "#ffffff"), edge="#e0343f", base="pedestal", height=32,
                                     vase=False, width=2.0)),
        "stove_basic": ("stove", {}),
        "counter_basic": ("counter", {}),
    }
    for item_id, params in themes3.CHAIRS.items():
        items[item_id] = ("chair", {k: (CHROME if v == "#c9d3de" else v) for k, v in params.items()})
    for item_id, (params, height) in themes3.TABLES.items():
        items[item_id] = ("table", dict(params, height=height))
    for item_id, params in themes3.STOVES.items():
        items[item_id] = ("stove", params)
    for item_id, params in themes3.COUNTERS.items():
        items[item_id] = ("counter", params)
    return items


# --- Fotos ---------------------------------------------------------------------------------------------------

def _flatten(parts):
    for part in parts:
        if isinstance(part, list):
            yield from _flatten(part)
        else:
            yield part


def assemble(objects, footprint, rotation):
    """Junta as peças num pai no centro do piso e gira; devolve o vértice da frente (a âncora)."""
    fx, fy = footprint if rotation % 2 == 0 else (footprint[1], footprint[0])
    parent = bpy.data.objects.new("Movel", None)
    bpy.context.scene.collection.objects.link(parent)
    for obj in objects:
        obj.parent = parent
    parent.location = (fx / 2, -fy / 2, 0.0)
    parent.rotation_euler = (0.0, 0.0, math.radians(ROTATION_ANGLE[rotation]))
    bpy.context.view_layer.update()
    return (fx, -fy, 0.0), (fx / 2, -fy / 2)


def render_item(item_id, kind, params, rotations, footprint, samples, anchors):
    for rotation in rotations:
        fx, fy = footprint if rotation % 2 == 0 else (footprint[1], footprint[0])
        cena3d.setup(samples, IMAGE_SIZE, shadow_center=(fx / 2, -fy / 2), shadow_size=(fx + SHADOW_MARGIN, fy + SHADOW_MARGIN))
        if kind == "chair":
            parts, back = chair(**params)
            objects = list(_flatten(parts + back))
        else:
            objects = list(_flatten({"table": table, "stove": stove, "counter": counter}[kind](**params)))
        anchor, center = assemble(objects, footprint, rotation)
        aim_camera((center[0], center[1], 0.42))
        name = f"{item_id}_r{rotation}"
        anchors[name] = cena3d.shoot(name, anchor, WORK)
        if kind == "chair" and rotation in (1, 2):
            render_backrest(item_id, params, rotation, samples, anchors)


def render_backrest(item_id, params, rotation, samples, anchors):
    """O encosto sozinho, para o jogo desenhar por cima de quem senta de costas."""
    cena3d.setup(samples, IMAGE_SIZE, shadow_size=0.01)
    _, back = chair(**params)
    anchor, center = assemble(list(_flatten(back)), (1, 1), rotation)
    aim_camera((center[0], center[1], 0.42))
    name = f"encosto_{item_id}_r{rotation}"
    anchors[name] = cena3d.shoot(name, anchor, WORK)


def render_oven_glow(samples, anchors):
    for rotation in (0, 3):
        cena3d.setup(samples, IMAGE_SIZE, shadow_size=0.01)
        anchor, center = assemble(list(_flatten(oven_window(rotation))), (1, 1), rotation)
        aim_camera((center[0], center[1], 0.42))
        name = f"fogao_aceso_r{rotation}"
        anchors[name] = cena3d.shoot(name, anchor, WORK)


def main():
    import json
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    samples = 24 if "rascunho" in args else 80
    items = catalog()
    wanted = [a for a in args if a in items] or list(items)
    with open(os.path.join(cena3d.SPRITES, "sprites.json"), encoding="utf-8") as source:
        manifest = json.load(source)
    footprints = {"table_long": (2, 1)}
    anchors = {}
    for item_id in wanted:
        kind, params = items[item_id]
        names = sorted(set(manifest["furniture"][item_id].values()))
        rotations = [int(name.rsplit("_r", 1)[1]) for name in names]
        render_item(item_id, kind, params, rotations, footprints.get(item_id, (1, 1)), samples, anchors)
        print("PRONTO", item_id, flush=True)
    if not args or "forno" in args:
        render_oven_glow(samples, anchors)
    cena3d.update_manifest(anchors)
    print("MOVEIS OK", len(anchors), flush=True)


if __name__ == "__main__":
    main()
