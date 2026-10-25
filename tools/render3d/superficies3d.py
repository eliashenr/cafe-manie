"""Pisos, paredes, itens de parede, portas e terraço em 3D (arte realista, DT-086), gravados em art/sprites.

Uso (na pasta do projeto):
    C:/Blender/blender-5.2.3-windows-x64/blender.exe -b -P tools/render3d/superficies3d.py -- [grupos ou nomes...] [rascunho]

Grupos: pisos, paredes, itens, portas, terraco (sem nada, faz todos). Também aceita nomes de sprite.

Encaixe (o mesmo da arte 2D):
- piso: a célula (0, 0); a âncora é o vértice de cima na tela (o canto (0, 0) do jogo, a origem aqui);
- parede: um trecho de uma célula, montado em X de 0 a 1, de frente para -Y; "R" (ao longo de x) fica assim, "L" (ao longo
  de y) é girado 90° e vai do canto (0, 1) do jogo ao (0, 0). A âncora é a ponta de baixo à esquerda na tela (x = 0 aqui).
  Os padrões têm período de uma célula, então o trecho vizinho continua o desenho sem emenda.
- itens de parede e portas: o objeto no mesmo lugar do trecho, sem a parede (o jogo desenha por cima dela); a parede
  invisível só recebe a sombra.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cena3d  # noqa: E402
from cena3d import aim_camera, linear  # noqa: E402
import moveis3d as M  # noqa: E402
from moveis3d import box, chrome, cylinder, emission, lacquer, solid, sphere, tube, wood  # noqa: E402
import enfeites3d as E  # noqa: E402

WORK = os.path.join(cena3d.ROOT, "tools", "render3d", "out_superficies")
FONT = os.path.join(cena3d.ROOT, "art", "fonts", "Fredoka-Variable.ttf")
WALL_Z = 152.38 / (128.0 / math.sqrt(2.0) * math.cos(math.radians(30.0)))   # altura da parede do jogo, em unidades
BLEED = 0.012              # sobra dos lados: o trecho vizinho cobre a emenda
DESIGN_W, DESIGN_H = 42.0, 100.0   # medidas do painel na arte 2D (u para a direita, v para cima)


def at(u, v):
    """Ponto do painel da arte 2D (u de 0 a 42, v de 0 a -100) no trecho de parede 3D (x, z)."""
    return u / DESIGN_W, -v / DESIGN_H * WALL_Z


# --- Materiais dos pisos e paredes ---------------------------------------------------------------------------

def _mat(key, build):
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("_".join(str(k) for k in key))
        build(nodes, links, bsdf)
        M._materials[key] = mat
    return M._materials[key]


def _vector(nodes, offset=(0.0, 0.0, 0.0), rotate=0.0, scale=1.0, uv_plane="XY"):
    coords = nodes.new("ShaderNodeTexCoord")
    mapping = nodes.new("ShaderNodeMapping")
    mapping.inputs["Location"].default_value = offset
    mapping.inputs["Rotation"].default_value = (0.0, 0.0, math.radians(rotate)) if uv_plane == "XY" else (math.radians(90), 0.0, 0.0)
    mapping.inputs["Scale"].default_value = (scale, scale, scale)
    nodes.id_data.links.new(coords.outputs["Object"], mapping.inputs["Vector"])
    return mapping.outputs["Vector"]


def grid_tiles(color, grout, per_cell, rough=0.25, variation=0.08, offset=0.0, plane="XY", brick_w=None, brick_h=None,
               row_offset=0.0, colors2=None, coat=0.5):
    """Lajotas, azulejos ou tábuas: a grade da textura Brick com o período de uma célula (rejunte nas bordas)."""
    def build(nodes, links, bsdf):
        vector = _vector(nodes, (offset, offset * 0.37, 0.0))
        if plane == "XZ":
            sep = nodes.new("ShaderNodeSeparateXYZ")
            comb = nodes.new("ShaderNodeCombineXYZ")
            links.new(vector, sep.inputs["Vector"])
            links.new(sep.outputs["X"], comb.inputs["X"])
            links.new(sep.outputs["Z"], comb.inputs["Y"])
            vector = comb.outputs["Vector"]
        brick = nodes.new("ShaderNodeTexBrick")
        brick.offset = row_offset
        brick.offset_frequency = 2
        brick.inputs["Scale"].default_value = 1.0
        brick.inputs["Brick Width"].default_value = brick_w or 1.0 / per_cell
        brick.inputs["Row Height"].default_value = brick_h or 1.0 / per_cell
        brick.inputs["Mortar Size"].default_value = 0.008
        brick.inputs["Mortar Smooth"].default_value = 0.3
        brick.inputs["Bias"].default_value = 0.0
        brick.inputs["Color1"].default_value = linear(color)
        brick.inputs["Color2"].default_value = linear(colors2 or M._shade(color, variation))
        brick.inputs["Mortar"].default_value = linear(grout)
        links.new(vector, brick.inputs["Vector"])
        links.new(brick.outputs["Color"], bsdf.inputs["Base Color"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.35
        links.new(brick.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Coat Weight"].default_value = coat
    return _mat(("tiles", color, grout, per_cell, offset, plane, brick_w, brick_h, row_offset, colors2), build)


def planks(color, per_cell=6, offset=0.0, long=0.5, dark=0.25, plane="XY"):
    """Assoalho de tábuas ao longo de X: veios só na direção da tábua (continuam na célula vizinha)."""
    def build(nodes, links, bsdf):
        vector = _vector(nodes, (offset, 0.0, 0.0))
        if plane == "XZ":
            sep = nodes.new("ShaderNodeSeparateXYZ")
            comb = nodes.new("ShaderNodeCombineXYZ")
            links.new(vector, sep.inputs["Vector"])
            links.new(sep.outputs["X"], comb.inputs["X"])
            links.new(sep.outputs["Z"], comb.inputs["Y"])
            vector = comb.outputs["Vector"]
        brick = nodes.new("ShaderNodeTexBrick")
        brick.offset = 0.5
        brick.inputs["Scale"].default_value = 1.0
        brick.inputs["Brick Width"].default_value = long
        brick.inputs["Row Height"].default_value = 1.0 / per_cell
        brick.inputs["Mortar Size"].default_value = 0.004
        brick.inputs["Color1"].default_value = linear(color)
        brick.inputs["Color2"].default_value = linear(M._shade(color, 0.12))
        brick.inputs["Mortar"].default_value = linear(M._shade(color, 0.6))
        links.new(vector, brick.inputs["Vector"])
        sep = nodes.new("ShaderNodeSeparateXYZ")
        links.new(vector, sep.inputs["Vector"])
        grain = nodes.new("ShaderNodeTexWave")
        grain.wave_type = "BANDS"
        grain.bands_direction = "Y"
        grain.inputs["Scale"].default_value = per_cell * 1.0
        grain.inputs["Distortion"].default_value = 0.0
        grain.inputs["Detail Scale"].default_value = 0.0
        links.new(vector, grain.inputs["Vector"])
        mix = nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        mix.blend_type = "MULTIPLY"
        mix.inputs[0].default_value = dark
        links.new(brick.outputs["Color"], mix.inputs[6])
        links.new(M._ramp(nodes, links, grain.outputs["Fac"], "#9a8a78", "#ffffff", (0.0, 1.0)), mix.inputs[7])
        links.new(mix.outputs[2], bsdf.inputs["Base Color"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.3
        links.new(brick.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
        bsdf.inputs["Roughness"].default_value = 0.38
        bsdf.inputs["Coat Weight"].default_value = 0.35
    return _mat(("planks", color, per_cell, offset, long, plane), build)


def pattern(kind, colors, scale, extra=0.0, emit=0.0, plane="XY", rough=0.35):
    """Padrões feitos de conta (todos com período de uma célula): círculos, ondas, xadrez, listras, palhinha."""
    def build(nodes, links, bsdf):
        vector = _vector(nodes, (extra, 0.0, 0.0))
        sep = nodes.new("ShaderNodeSeparateXYZ")
        links.new(vector, sep.inputs["Vector"])
        u, v = sep.outputs["X"], (sep.outputs["Z"] if plane == "XZ" else sep.outputs["Y"])

        def math_node(op, a, b=None, value=None):
            node = nodes.new("ShaderNodeMath")
            node.operation = op
            links.new(a, node.inputs[0]) if not isinstance(a, float) else node.inputs[0].__setattr__("default_value", a)
            if b is not None:
                links.new(b, node.inputs[1]) if not isinstance(b, float) else node.inputs[1].__setattr__("default_value", b)
            return node.outputs[0]

        if kind == "circles":         # anos 70: círculos concêntricos no meio de cada célula
            du = math_node("SUBTRACT", math_node("FRACT", math_node("MULTIPLY", u, float(scale))), 0.5)
            dv = math_node("SUBTRACT", math_node("FRACT", math_node("MULTIPLY", v, float(scale))), 0.5)
            dist = math_node("SQRT", math_node("ADD", math_node("MULTIPLY", du, du), math_node("MULTIPLY", dv, dv)))
            fac = math_node("FRACT", math_node("MULTIPLY", dist, 4.0))
        elif kind == "waves":         # calçadão de Copacabana / ondas: faixas senoidais
            wave = math_node("SINE", math_node("MULTIPLY", u, 2.0 * math.pi * scale))
            fac = math_node("FRACT", math_node("MULTIPLY", math_node("ADD", v, math_node("MULTIPLY", wave, 0.12 / scale)), float(scale)))
        elif kind == "stripes":       # listras verticais (paredes) ou na direção de X
            fac = math_node("FRACT", math_node("MULTIPLY", u, float(scale)))
        elif kind == "basket":        # parquê em cesto: xadrez de tábuas em duas direções
            cu = math_node("FLOOR", math_node("MULTIPLY", u, float(scale)))
            cv = math_node("FLOOR", math_node("MULTIPLY", v, float(scale)))
            parity = math_node("FLOORED_MODULO", math_node("ADD", cu, cv), 2.0)
            along_u = math_node("FRACT", math_node("MULTIPLY", v, float(scale * 4)))
            along_v = math_node("FRACT", math_node("MULTIPLY", u, float(scale * 4)))
            mixer = nodes.new("ShaderNodeMix")
            links.new(parity, mixer.inputs[0])
            links.new(along_u, mixer.inputs[2])
            links.new(along_v, mixer.inputs[3])
            fac = mixer.outputs[0]
        elif kind == "zigzag":        # anos 80: zigue-zague
            tri = math_node("ABSOLUTE", math_node("SUBTRACT", math_node("FRACT", math_node("MULTIPLY", u, float(scale))), 0.5))
            fac = math_node("FRACT", math_node("MULTIPLY", math_node("ADD", v, math_node("MULTIPLY", tri, 0.25)), 3.0))
        else:                         # "weave": palhinha de tatame (listras finas na direção de X)
            fac = math_node("FRACT", math_node("MULTIPLY", v, float(scale)))
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.color_ramp.interpolation = "CONSTANT"
        elements = ramp.color_ramp.elements
        for i in range(len(colors) - 2):
            elements.new(0.5)
        for i, color in enumerate(colors):
            elements[i].position = i / len(colors)
            elements[i].color = linear(color)
        links.new(fac, ramp.inputs["Fac"])
        links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
        if emit > 0.0:
            links.new(ramp.outputs["Color"], bsdf.inputs["Emission Color"])
            bsdf.inputs["Emission Strength"].default_value = emit
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Coat Weight"].default_value = 0.3
    return _mat(("pattern", kind, tuple(colors), scale, extra, emit, plane), build)


def speckles(base, dots, scale, extra=0.0, size=(0.16, 0.2), rough=0.3):
    """Pintinhas (granilite, confete, Memphis): manchas de cor sobre a base."""
    def build(nodes, links, bsdf):
        vector = _vector(nodes, (extra, extra * 0.6, 0.0))
        voronoi = nodes.new("ShaderNodeTexVoronoi")
        voronoi.inputs["Scale"].default_value = scale
        links.new(vector, voronoi.inputs["Vector"])
        spot = M._ramp(nodes, links, voronoi.outputs["Distance"], "#000000", "#ffffff", size)
        hue = nodes.new("ShaderNodeValToRGB")
        hue.color_ramp.interpolation = "CONSTANT"
        for i in range(len(dots) - 2):
            hue.color_ramp.elements.new(0.5)
        for i, color in enumerate(dots):
            hue.color_ramp.elements[i].position = i / len(dots)
            hue.color_ramp.elements[i].color = linear(color)
        sep = nodes.new("ShaderNodeSeparateColor")
        links.new(voronoi.outputs["Color"], sep.inputs["Color"])
        links.new(sep.outputs["Red"], hue.inputs["Fac"])
        mix = nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        links.new(spot, mix.inputs[0])
        links.new(hue.outputs["Color"], mix.inputs[6])
        mix.inputs[7].default_value = linear(base)
        links.new(mix.outputs[2], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Coat Weight"].default_value = 0.5
    return _mat(("speckles", base, tuple(dots), scale, extra), build)


def plaster(color):
    """Reboco pintado: a cor com um leve relevo."""
    def build(nodes, links, bsdf):
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 60.0
        links.new(_vector(nodes), noise.inputs["Vector"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.12
        links.new(noise.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
        bsdf.inputs["Base Color"].default_value = linear(color)
        bsdf.inputs["Roughness"].default_value = 0.8
    return _mat(("plaster", color), build)


# --- Pisos ---------------------------------------------------------------------------------------------------

def floor_material(surface_id, variant):
    v = variant if isinstance(variant, int) else (0 if variant == "a" else 1)
    if surface_id == "floor_beige":
        return grid_tiles(("#f7e3bd", "#e8cd98")[v], "#c9ad80", 1)
    if surface_id == "floor_diner":
        return grid_tiles(("#f4f4f2", "#232329")[v], "#9aa0a8", 1, rough=0.15, coat=0.8)
    if surface_id == "floor_bistro":
        return grid_tiles("#f6efe2", "#d9cbb8", 4, colors2="#8f2a37", variation=0.0)
    if surface_id == "floor_blue_tiles":
        return grid_tiles("#8ec9f0", "#f4f8fb", 2, colors2="#5aa8e0", rough=0.12, coat=0.9)
    if surface_id == "floor_marble":
        return marble_tile(v)
    if surface_id == "floor_wood":
        return planks("#c98a52", 6, offset=v * 0.31)
    if surface_id == "floor_70s":
        return pattern("circles", ["#f2d8a6", "#e07a2e", "#9a4a1e", "#f2b33d"], 1)
    if surface_id == "floor_country":
        return planks("#8a5a32", 4, offset=v * 0.27, long=1.0, dark=0.35)
    if surface_id == "floor_party":
        return speckles("#ffe6f2", ["#ff4d6d", "#ffd23f", "#31d7ff", "#b06bff", "#2fae4e"], 12.0, extra=v * 3.1, size=(0.22, 0.27))
    if surface_id == "floor_mexican":
        return grid_tiles(("#c9683a", "#b85a30", "#d4774a")[v], "#e8d8c0", 2, variation=0.1)
    if surface_id == "floor_80s":
        return speckles("#f4f0fa", ["#ff4dd2", "#4fe0ff", "#ffd23f", "#2a2d6e"], 8.0, extra=v * 2.3, size=(0.24, 0.3))
    if surface_id == "floor_italian":
        return speckles("#efe4d2", ["#8a7a6a", "#c9683a", "#5a5a5a", "#b8a890"], 40.0, extra=v * 1.7, size=(0.3, 0.36))
    if surface_id == "floor_japanese":
        return pattern("weave", ["#c8c27a", "#b6b06a"], 24, extra=0.0) if v == 0 else tatami_rotated()
    if surface_id == "floor_french":
        return pattern("basket", ["#d9a066", "#b97a45"], 4)
    if surface_id == "floor_brazil":
        return pattern("waves", ["#f4f0e8", "#1d1d24"], 2)
    if surface_id == "floor_2010s":
        return grid_tiles(("#b9bdc2", "#aeb3b8", "#c3c6ca")[v], "#8f949a", 2, rough=0.4, variation=0.05, coat=0.2)
    if surface_id == "floor_club":
        sets = (("#ff4dd2", "#31d7ff"), ("#ffd23f", "#b06bff"), ("#31d7ff", "#2fae4e"))[v]
        return led_tiles(*sets)
    raise KeyError(surface_id)


def marble_tile(v):
    def build(nodes, links, bsdf):
        vector = _vector(nodes, (v * 1.7, v * 0.9, 0.0))
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 2.5
        noise.inputs["Detail"].default_value = 6.0
        noise.inputs["Distortion"].default_value = 4.0
        links.new(vector, noise.inputs["Vector"])
        veins = M._ramp(nodes, links, noise.outputs["Fac"], "#f4f2ee", "#b8b2a8", (0.6, 0.63))
        brick = nodes.new("ShaderNodeTexBrick")
        brick.offset = 0.0
        brick.inputs["Scale"].default_value = 1.0
        brick.inputs["Brick Width"].default_value = 1.0
        brick.inputs["Row Height"].default_value = 1.0
        brick.inputs["Mortar Size"].default_value = 0.006
        brick.inputs["Mortar"].default_value = linear("#9a948a")
        links.new(_vector(nodes), brick.inputs["Vector"])
        links.new(veins, brick.inputs["Color1"])
        links.new(veins, brick.inputs["Color2"])
        links.new(brick.outputs["Color"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.08
        bsdf.inputs["Coat Weight"].default_value = 0.9
    return _mat(("marble_tile", v), build)


def tatami_rotated():
    def build(nodes, links, bsdf):
        vector = _vector(nodes, rotate=90.0)
        sep = nodes.new("ShaderNodeSeparateXYZ")
        links.new(vector, sep.inputs["Vector"])
        mul = nodes.new("ShaderNodeMath")
        mul.operation = "MULTIPLY"
        mul.inputs[1].default_value = 24.0
        links.new(sep.outputs["Y"], mul.inputs[0])
        frac = nodes.new("ShaderNodeMath")
        frac.operation = "FRACT"
        links.new(mul.outputs[0], frac.inputs[0])
        links.new(M._ramp(nodes, links, frac.outputs[0], "#c8c27a", "#b6b06a", (0.49, 0.51)), bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.6
    return _mat(("tatami_rot",), build)


def led_tiles(a, b):
    def build(nodes, links, bsdf):
        brick = nodes.new("ShaderNodeTexBrick")
        brick.offset = 0.0
        brick.inputs["Scale"].default_value = 1.0
        brick.inputs["Brick Width"].default_value = 0.5
        brick.inputs["Row Height"].default_value = 0.5
        brick.inputs["Mortar Size"].default_value = 0.02
        brick.inputs["Bias"].default_value = 0.0
        brick.inputs["Color1"].default_value = linear(a)
        brick.inputs["Color2"].default_value = linear(b)
        brick.inputs["Mortar"].default_value = linear("#0d0d14")
        links.new(_vector(nodes), brick.inputs["Vector"])
        links.new(brick.outputs["Color"], bsdf.inputs["Base Color"])
        links.new(brick.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 1.6
        bsdf.inputs["Roughness"].default_value = 0.1
    return _mat(("led", a, b), build)


def floor_cell(mat):
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0.5, -0.5, 0.0))
    plane = bpy.context.active_object
    plane.scale = (1.0 + 2 * BLEED, 1.0 + 2 * BLEED, 1.0)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    plane.location = (0.0, 0.0, 0.0)
    for v in plane.data.vertices:
        v.co.x += 0.5
        v.co.y -= 0.5
    plane.data.materials.append(mat)
    return plane


def entrance_mat():
    """Capacho listrado da entrada (o piso do jogo fica embaixo)."""
    mat = pattern("stripes", ["#d6283a", "#f4f0e8"], 8, rough=0.9)
    return [box((0.62, 0.42, 0.012), (0.5, -0.5, 0.006), mat, 0.004)]


# --- Paredes -------------------------------------------------------------------------------------------------

WAINSCOT_TOP = 0.36 * WALL_Z
RAIL = (0.36 * WALL_Z, 0.395 * WALL_Z)
BASE_TOP = 0.05 * WALL_Z


def wall_parts(upper, wainscot="#ffffff", rail="#ffffff", base="#8a5530", panel=True, full=False, lower=None):
    """Trecho de parede de uma célula (X de 0 a 1, de frente para -Y): a parte de cima, o lambri com os frisos, o
    rodameio e o rodapé. full: o material da parte de cima vai até o chão (tijolo, toras, azulejo...)."""
    width = 1.0 + 2 * BLEED
    parts = []
    if full:
        parts.append(box((width, 0.04, WALL_Z), (0.5, 0.02, WALL_Z / 2), upper, 0.0))
        parts.append(box((width, 0.06, BASE_TOP), (0.5, 0.0, BASE_TOP / 2), solid(base, 0.4), 0.004))
        return parts
    parts.append(box((width, 0.04, WALL_Z - WAINSCOT_TOP), (0.5, 0.02, (WALL_Z + WAINSCOT_TOP) / 2), upper, 0.0))
    lower_mat = lower or solid(wainscot, 0.45, 0.0, 0.2)
    parts.append(box((width, 0.06, WAINSCOT_TOP), (0.5, 0.01, WAINSCOT_TOP / 2), lower_mat, 0.0))
    if panel and lower is None:
        parts.append(box((0.78, 0.07, WAINSCOT_TOP * 0.6), (0.5, 0.008, WAINSCOT_TOP * 0.52), solid(M._shade(wainscot, 0.04), 0.4), 0.012))
    parts.append(box((width, 0.08, RAIL[1] - RAIL[0]), (0.5, -0.005, (RAIL[0] + RAIL[1]) / 2), solid(rail, 0.35, 0.0, 0.4), 0.004))
    parts.append(box((width, 0.075, BASE_TOP), (0.5, -0.004, BASE_TOP / 2), solid(base, 0.4, 0.0, 0.3), 0.004))
    return parts


def wall_style(surface_id):
    s = surface_id
    if s == "wall_cream":
        return wall_parts(plaster("#f7e6c4"), "#ffffff", "#ffffff", "#a86d40")
    if s == "wall_mint_stripes":
        return wall_parts(pattern("stripes", ["#bff0dc", "#f4fbf8"], 6, plane="XZ", rough=0.7), "#ffffff", "#ffffff", "#e0303a")
    if s == "wall_brick":
        return wall_parts(grid_tiles("#b5513d", "#e2d6c6", 0, plane="XZ", brick_w=0.25, brick_h=WALL_Z / 26, row_offset=0.5,
                                     variation=0.18, rough=0.85, coat=0.0), full=True, base="#3a2a24")
    if s == "wall_navy":
        return wall_parts(plaster("#1f2f5c"), "#ffffff", "#d9b44a", "#1f2f5c")
    if s == "wall_70s":
        return wall_parts(pattern("waves", ["#fbe6bf", "#e07a2e", "#f2b33d", "#b0532a", "#fbe6bf", "#fbe6bf"], 1, plane="XZ", rough=0.7),
                          lower=wood("#a86d40"), rail="#7a4a2a", base="#5a3520")
    if s == "wall_country":
        return wall_parts(planks("#a8703a", 7, long=1.0, plane="XZ"), full=True, base="#5a3520")
    if s == "wall_party":
        return wall_parts(speckles("#ffd6e8", ["#ff4d6d", "#ffd23f", "#31d7ff", "#2fae4e"], 9.0, size=(0.06, 0.08)),
                          "#ffffff", "#ffffff", "#ff5c8a")
    if s == "wall_diner":
        return wall_parts(grid_tiles("#f4f4f2", "#c9ced4", 0, plane="XZ", brick_w=0.25, brick_h=WALL_Z / 16, rough=0.15, coat=0.8),
                          lower=lacquer("#e0303a"), rail="#1d1d24", base="#1d1d24")
    if s == "wall_mexican":
        return wall_parts(plaster("#f2b83a"), lower=grid_tiles("#c9683a", "#e8d8c0", 0, plane="XZ", brick_w=0.5, brick_h=0.25),
                          rail="#2f6fd9", base="#8a3a1e")
    if s == "wall_80s":
        return wall_parts(pattern("zigzag", ["#2a1440", "#2a1440", "#ff4dd2", "#2a1440", "#31d7ff", "#2a1440"], 2, plane="XZ", emit=0.0),
                          lower=grid_tiles("#1d0f30", "#ff4dd2", 0, plane="XZ", brick_w=0.25, brick_h=0.18), rail="#31d7ff", base="#1d0f30")
    if s == "wall_italian":
        return wall_parts(plaster("#e8c48a"), lower=grid_tiles("#b5513d", "#e2d6c6", 0, plane="XZ", brick_w=0.25, brick_h=WALL_Z / 26,
                                                              row_offset=0.5, variation=0.18, rough=0.85, coat=0.0),
                          rail="#f4ead6", base="#5a3020")
    if s == "wall_japanese":
        parts = wall_parts(emission("#f8f2e2", 0.25), full=True, base="#3a2416")
        frame = wood("#5a3a22")
        for x in (0.0, 0.333, 0.667, 1.0):
            parts.append(box((0.03, 0.05, WALL_Z), (x, -0.01, WALL_Z / 2), frame, 0.004))
        for z in (0.33, 0.66, 0.99, 1.32, 1.65):
            parts.append(box((1.0 + 2 * BLEED, 0.05, 0.03), (0.5, -0.01, z), frame, 0.004))
        return parts
    if s == "wall_french":
        parts = wall_parts(plaster("#b9d0e8"), "#c9dcef", "#d9b44a", "#8aa8c8")
        gold = solid("#d9b44a", 0.25, 0.9)
        for (x0, x1, z0, z1) in ((0.18, 0.82, 0.9, 1.75),):
            parts += [box((x1 - x0, 0.02, 0.02), (0.5, -0.0, z0), gold, 0.004), box((x1 - x0, 0.02, 0.02), (0.5, -0.0, z1), gold, 0.004),
                      box((0.02, 0.02, z1 - z0), (x0, -0.0, (z0 + z1) / 2), gold, 0.004), box((0.02, 0.02, z1 - z0), (x1, -0.0, (z0 + z1) / 2), gold, 0.004)]
        return parts
    if s == "wall_brazil":
        return wall_parts(speckles("#d8f0dc", ["#2f8a3a", "#4fb840", "#7ad070"], 7.0, size=(0.18, 0.24)), "#ffffff", "#ffffff", "#2f8a3a")
    if s == "wall_2010s":
        return wall_parts(grid_tiles("#f4f4f2", "#c3c8ce", 0, plane="XZ", brick_w=0.25, brick_h=WALL_Z / 24, row_offset=0.5, rough=0.1,
                                     coat=0.9), full=True, base="#3a3c46")
    if s == "wall_club":
        parts = wall_parts(plaster("#15121f"), full=True, base="#0d0b16")
        for z, c in ((1.3, "#ff4dd2"), (1.18, "#4fe0ff")):
            parts.append(box((1.0 + 2 * BLEED, 0.03, 0.018), (0.5, -0.005, z), emission(c, 6.0), 0.0))
        parts.append(box((1.0 + 2 * BLEED, 0.03, 0.014), (0.5, -0.005, 0.72), emission("#b04dff", 5.0), 0.0))
        return parts
    raise KeyError(surface_id)


# --- Itens de parede -----------------------------------------------------------------------------------------

def _sky():
    """O céu visto pela janela: azul-claro em degradê, com luz própria."""
    def build(nodes, links, bsdf):
        coords = nodes.new("ShaderNodeTexCoord")
        sep = nodes.new("ShaderNodeSeparateXYZ")
        links.new(coords.outputs["Generated"], sep.inputs["Vector"])
        links.new(M._ramp(nodes, links, sep.outputs["Z"], "#bfe6ff", "#3a9be0", (0.0, 1.0)), bsdf.inputs["Emission Color"])
        bsdf.inputs["Base Color"].default_value = linear("#8fd0f8")
        bsdf.inputs["Emission Strength"].default_value = 0.55
        bsdf.inputs["Roughness"].default_value = 0.05
    return _mat(("sky",), build)


def round_window(frame="#ffffff", sky_colors=None, lattice=False):
    cx, cz = at(21, -68)
    r = 13 / DESIGN_W
    mat = lacquer(frame)
    parts = [E.torus(r + 0.03, 0.04, (cx, -0.02, cz), mat, (math.radians(90), 0, 0))]
    bpy.ops.mesh.primitive_cylinder_add(radius=r + 0.01, depth=0.01, location=(cx, -0.005, cz), rotation=(math.radians(90), 0, 0), vertices=48)
    pane = M._finish(bpy.context.active_object, emission(sky_colors[0], 1.0) if sky_colors else _sky())
    parts.append(pane)
    if lattice:
        for i in range(-2, 3):
            parts.append(box((0.012, 0.02, 2 * r), (cx + i * r / 2.5, -0.02, cz), wood("#8a5a2e"), 0.0))
            parts.append(box((2 * r, 0.02, 0.012), (cx, -0.02, cz + i * r / 2.5), wood("#8a5a2e"), 0.0))
    else:
        parts.append(box((0.012, 0.02, 2 * r), (cx, -0.02, cz), mat, 0.002))
    return parts


def square_window(curtain="#ffd23f"):
    x0, z1 = at(9, -86)
    x1, z0 = at(33, -48)
    w, h = x1 - x0, z1 - z0
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    frame = solid("#ffffff", 0.35, 0.0, 0.4)
    parts = [box((w, 0.01, h), (cx, -0.004, cz), _sky(), 0.0)]
    for z in (z0, z1):
        parts.append(box((w + 0.06, 0.05, 0.035), (cx, -0.02, z), frame, 0.006))
    for x in (x0, x1, cx):
        parts.append(box((0.03, 0.05, h), (x, -0.02, cz), frame, 0.004))
    parts.append(box((w + 0.1, 0.06, 0.03), (cx, -0.04, z0 - 0.02), frame, 0.006))
    cloth = M.fabric("plain", curtain)
    for side in (-1, 1):
        parts.append(box((0.07, 0.03, h + 0.08), (cx + side * (w / 2 + 0.02), -0.05, cz), cloth, 0.02))
    parts.append(tube((x0 - 0.08, -0.06, z1 + 0.05), (x1 + 0.08, -0.06, z1 + 0.05), 0.01, chrome()))
    return parts


def arched_window(frame="#ffffff", box_colors=("#ff4d8d", "#ffd23f")):
    x0, z0 = at(10, -40)
    x1, z1 = at(32, -78)
    w, h = x1 - x0, z1 - z0
    cx = (x0 + x1) / 2
    mat = lacquer(frame)
    parts = [box((w, 0.01, h), (cx, -0.004, (z0 + z1) / 2), _sky(), 0.0)]
    bpy.ops.mesh.primitive_cylinder_add(radius=w / 2, depth=0.01, location=(cx, -0.004, z1), rotation=(math.radians(90), 0, 0), vertices=48)
    parts.append(M._finish(bpy.context.active_object, _sky()))
    for x in (x0, x1):
        parts.append(box((0.035, 0.05, h), (x, -0.02, (z0 + z1) / 2), mat, 0.004))
    bpy.ops.mesh.primitive_torus_add(major_radius=w / 2, minor_radius=0.018, location=(cx, -0.02, z1), rotation=(math.radians(90), 0, 0))
    arch = M._finish(bpy.context.active_object, mat)
    parts.append(arch)
    parts.append(box((0.025, 0.04, h + w / 2), (cx, -0.02, (z0 + z1 + w / 2) / 2), mat, 0.003))
    parts.append(box((w + 0.08, 0.14, 0.08), (cx, -0.08, z0 - 0.02), wood("#8a5a2e"), 0.006))
    for i in range(5):
        parts.append(sphere(0.03, (x0 + 0.03 + i * w / 4.5, -0.1, z0 + 0.04), solid(box_colors[i % 2], 0.6)))
    return parts


def frame_picture(kind):
    x0, z1 = at(9, -82)
    x1, z0 = at(33, -50)
    w, h = x1 - x0, z1 - z0
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    parts = [box((w + 0.06, 0.03, h + 0.06), (cx, -0.015, cz), lacquer("#ff4d8d" if kind == "cupcake" else "#2f6fd9"), 0.008)]
    if kind == "cupcake":
        parts.append(box((w, 0.01, h), (cx, -0.032, cz), solid("#fff3d6", 0.6), 0.0))
        parts.append(box((0.16, 0.012, 0.1), (cx, -0.04, cz - 0.06), solid("#d9a35a", 0.6), 0.02))
        parts.append(sphere(0.1, (cx, -0.04, cz + 0.04), solid("#ff9ec4", 0.5), (1, 0.15, 0.7)))
        parts.append(sphere(0.022, (cx, -0.05, cz + 0.13), solid("#e0303a", 0.3)))
    else:
        parts.append(box((w, 0.01, h * 0.55), (cx, -0.032, cz + h * 0.22), emission("#8fd8ff", 0.4), 0.0))
        parts.append(box((w, 0.01, h * 0.45), (cx, -0.032, cz - h * 0.27), solid("#5ac85a", 0.7), 0.0))
        parts.append(sphere(0.035, (cx + w * 0.25, -0.04, cz + h * 0.3), emission("#ffd23f", 2.0)))
    return parts


def wall_item(name):
    n = name
    if n == "janela":
        return square_window("#ffd23f")
    if n == "janela_redonda":
        return round_window()
    if n == "janelao":
        return arched_window()
    if n.startswith("janela_"):
        style = {"diner": dict(frame="#e0303a"), "neon": dict(frame="#b06bff", sky_colors=("#6a3ab0",)), "groovy": dict(frame="#f07a1a", sky_colors=("#ffb04a",)),
                 "arcade": dict(frame="#3ee0ff", sky_colors=("#ff3d7f",)), "shoji": dict(frame="#8a5a2e", sky_colors=("#fffaf0",), lattice=True)}
        key = n[len("janela_"):]
        if key in style:
            return round_window(**style[key])
        curtain = {"country": "#b8432f", "festa": "#b06bff", "industrial": "#4a4d5a"}[key]
        return square_window(curtain)
    if n.startswith("janelao_"):
        frame, boxes = {"italiano": ("#2f8a3a", ("#c47a3a", "#ff4d5e")), "mexicano": ("#2f6fd9", ("#ffd23f", "#e0303a")),
                        "brasileiro": ("#2fae4e", ("#ffd23f", "#2f6fd9")), "frances": ("#2a2a33", ("#ffe7a0", "#ff8fb1"))}[n[len("janelao_"):]]
        return arched_window(frame, boxes)
    if n == "relogio":
        cx, cz = at(21, -74)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.2, depth=0.04, location=(cx, -0.02, cz), rotation=(math.radians(90), 0, 0), vertices=48)
        parts = [M._finish(bpy.context.active_object, lacquer("#e0303a"), 0.01)]
        bpy.ops.mesh.primitive_cylinder_add(radius=0.17, depth=0.01, location=(cx, -0.042, cz), rotation=(math.radians(90), 0, 0), vertices=48)
        parts.append(M._finish(bpy.context.active_object, solid("#ffffff", 0.3), 0))
        parts.append(box((0.015, 0.01, 0.12), (cx, -0.05, cz + 0.05), solid("#1d1d24", 0.3), 0.0))
        hand = box((0.09, 0.01, 0.015), (cx + 0.04, -0.05, cz), solid("#1d1d24", 0.3), 0.0)
        parts.append(hand)
        return parts
    if n == "prateleira":
        x0, z = at(3, -58)
        parts = [box((0.86, 0.14, 0.03), (0.5, -0.07, z), wood("#c98a52"), 0.004)]
        parts.append(cylinder(0.04, z + 0.015, z + 0.13, lacquer("#e0303a"), (0.25, -0.07)))
        parts.append(cylinder(0.035, z + 0.015, z + 0.08, solid("#ffffff", 0.2, 0.0, 0.6), (0.5, -0.07)))
        parts += E._lifted(E.pot(0.045, 0.06, lacquer("#ffd23f")), z + 0.015)
        for obj in parts[-3:]:
            obj.location.x += 0.75
            obj.location.y -= 0.07
        parts += [l for l in E.rosette((0.75, -0.07, z + 0.075), 7, 0.1, 0.02, 40, E.foliage("#3fae4a"))]
        return parts
    if n == "quadro_cupcake":
        return frame_picture("cupcake")
    if n == "quadro_paisagem":
        return frame_picture("paisagem")
    if n == "tv":
        cx, cz = at(21, -64)
        parts = [box((0.8, 0.04, 0.5), (cx, -0.03, cz), solid("#1d1d24", 0.2, 0.0, 0.8), 0.01)]
        parts.append(box((0.74, 0.01, 0.44), (cx, -0.052, cz), emission("#4fa0ff", 1.4), 0.0))
        parts.append(sphere(0.06, (cx, -0.06, cz), emission("#ffffff", 2.0), (1, 0.1, 0.8)))
        return parts
    if n == "radio":
        x0, z = at(5, -50)
        parts = [box((0.8, 0.12, 0.04), (0.5, -0.06, z), wood("#c98a52"), 0.004)]
        parts.append(box((0.56, 0.12, 0.34), (0.5, -0.07, z + 0.19), wood("#a85a2a"), 0.04))
        parts.append(box((0.26, 0.01, 0.22), (0.42, -0.132, z + 0.19), M.weave("#f3e2c0"), 0.01))
        for dz in (0.1, 0.24):
            parts.append(sphere(0.03, (0.66, -0.135, z + dz), solid("#ffd23f", 0.3, 0.8)))
        return parts
    if n == "lousa":
        cx, cz = at(21, -64)
        parts = [box((0.78, 0.04, 0.62), (cx, -0.02, cz), wood("#8a5a2e"), 0.008), box((0.7, 0.01, 0.54), (cx, -0.042, cz), solid("#2a3a30", 0.9), 0)]
        for i, w in enumerate((0.42, 0.5, 0.36)):
            parts.append(box((w, 0.005, 0.02), (cx - 0.05, -0.048, cz + 0.15 - i * 0.12), solid("#f4f4f4", 0.9), 0))
        return parts
    if n == "espelho":
        cx, cz = at(21, -66)
        parts = [E.torus(0.3, 0.03, (cx, -0.02, cz), solid("#d9b44a", 0.25, 1.0), (math.radians(90), 0, 0))]
        parts[0].scale = (1.0, 1.0, 1.25)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.3, depth=0.01, location=(cx, -0.01, cz), rotation=(math.radians(90), 0, 0), vertices=48)
        mirror = M._finish(bpy.context.active_object, solid("#e8f0f6", 0.02, 1.0))
        mirror.scale = (1.0, 1.25, 1.0)
        parts.append(mirror)
        return parts
    if n == "planta_pendurada":
        cx, _ = at(21, 0)
        top = WALL_Z * 0.96
        parts = [tube((cx, -0.15, top), (cx - 0.1, -0.15, top - 0.42), 0.004, solid("#c9a46a", 0.8)),
                 tube((cx, -0.15, top), (cx + 0.1, -0.15, top - 0.42), 0.004, solid("#c9a46a", 0.8))]
        parts += E._lifted(E.pot(0.1, 0.12, solid("#ffffff", 0.3)), top - 0.52)
        for obj in parts[2:]:
            obj.location.x += cx
            obj.location.y -= 0.15
        parts += E.rosette((cx, -0.15, top - 0.42), 10, 0.3, 0.035, 110, E.foliage("#3fae4a"))
        return parts
    if n == "neon_xicara":
        cx, cz = at(21, -66)
        pink = emission("#ff4da6", 14.0)
        parts = [box((0.62, 0.02, 0.7), (cx, -0.01, cz), solid("#1d1a2b", 0.4), 0.02)]   # a placa escura atrás do neon
        parts.append(E.torus(0.16, 0.02, (cx, -0.03, cz - 0.04), pink, (math.radians(90), 0, 0)))
        parts.append(box((0.38, 0.03, 0.03), (cx, -0.03, cz - 0.26), pink, 0))
        parts.append(E.torus(0.07, 0.02, (cx + 0.21, -0.03, cz - 0.02), pink, (math.radians(90), 0, 0)))
        parts.append(E.torus(0.06, 0.02, (cx, -0.03, cz + 0.24), emission("#4fe0ff", 14.0), (math.radians(90), 0, 0)))
        return parts
    if n == "painel_digital":
        cx, cz = at(21, -70)
        parts = [box((0.86, 0.03, 0.62), (cx, -0.015, cz), solid("#10151f", 0.2), 0.008), box((0.8, 0.01, 0.56), (cx, -0.034, cz), emission("#0f3a63", 1.0), 0)]
        parts.append(box((0.22, 0.005, 0.06), (cx - 0.24, -0.04, cz + 0.2), emission("#31d7ff", 5.0), 0))
        for i in range(3):
            parts.append(box((0.36, 0.005, 0.03), (cx - 0.1, -0.04, cz + 0.06 - i * 0.1), emission("#e8f4ff", 2.0), 0))
            parts.append(box((0.08, 0.005, 0.03), (cx + 0.2, -0.04, cz + 0.06 - i * 0.1), emission("#ffbe55", 3.0), 0))
        return parts
    if n == "arandela":
        cx, cz = at(21, -71)
        iron = solid("#2a2c34", 0.35, 0.6)
        parts = [box((0.09, 0.03, 0.16), (cx - 0.12, -0.015, cz), iron, 0.01),
                 tube((cx - 0.12, -0.03, cz + 0.02), (cx, -0.14, cz + 0.1), 0.012, iron)]
        parts += E.lamp_glow((cx, -0.14, cz), "#ffcf7a", 0.035, 25.0)
        return parts
    raise KeyError(name)


# --- Portas --------------------------------------------------------------------------------------------------

DOOR_STYLES = {
    "": (("#ffffff", "#dfe6ee"), ("#ffffff", "#ff4d5e")), "frances": (("#2a2a33", "#15151b"), ("#ffffff", "#2a2a33")),
    "japones": (("#c98a4b", "#8a5a2e"), ("#2a3f86", "#1d2a5a")), "italiano": (("#2f8a3a", "#1d5a26"), ("#ffffff", "#2f8a3a")),
    "anos70": (("#f07a1a", "#a84a0a"), ("#ffd27a", "#a8522a")), "americano": (("#7fdcc0", "#3aa88a"), ("#ffffff", "#e0303a")),
    "anos2010": (("#c9d4e0", "#8f9aa7"), ("#f4f7fa", "#4a4d5a")), "festa": (("#ffcf3f", "#e0a800"), ("#ff8ab8", "#ffe066")),
    "anos80": (("#8a4fd1", "#4a2a8a"), ("#3ee0ff", "#ff3d7f")), "balada": (("#2a1440", "#120a20"), ("#b06bff", "#2a1440")),
    "brasileiro": (("#2fae3a", "#1d7a26"), ("#ffd23f", "#2fae3a")), "country": (("#a8703a", "#6a4a2a"), ("#f4ead6", "#b8432f")),
    "mexicano": (("#d9734a", "#a84a2a"), ("#ffd23f", "#e0303a")),
}


def doorway(style, closed):
    """Batente da entrada, com o toldo listrado e a plaquinha ABERTO (ou FECHADO): o vão fica livre."""
    frame, awning = DOOR_STYLES[style]
    top = 78 / DESIGN_H * WALL_Z
    mat = lacquer(frame[0])
    parts = [box((0.08, 0.1, top), (x, -0.02, top / 2), mat, 0.008) for x in (0.05, 0.95)]
    parts.append(box((1.04, 0.12, 0.08), (0.5, -0.02, top + 0.04), mat, 0.008))
    stripes = pattern("stripes", list(awning), 7, rough=0.8)
    canopy = box((1.08, 0.3, 0.02), (0.5, -0.17, top + 0.02), stripes, 0.004)
    canopy.rotation_euler = (math.radians(-22), 0, 0)
    parts.append(canopy)
    parts.append(box((1.08, 0.012, 0.09), (0.5, -0.31, top - 0.06), stripes, 0.004))
    sign_z = top - 0.22
    parts.append(tube((0.42, -0.06, top - 0.02), (0.5, -0.06, sign_z + 0.08), 0.004, solid("#6a4a2a", 0.6)))
    parts.append(tube((0.58, -0.06, top - 0.02), (0.5, -0.06, sign_z + 0.08), 0.004, solid("#6a4a2a", 0.6)))
    parts.append(box((0.4, 0.02, 0.16), (0.5, -0.06, sign_z), solid("#ffffff", 0.4), 0.01))
    bpy.ops.object.text_add(location=(0.5, -0.072, sign_z - 0.04), rotation=(math.radians(90), 0, 0))
    text = bpy.context.active_object
    text.data.body = "FECHADO" if closed else "ABERTO"
    text.data.font = bpy.data.fonts.load(FONT, check_existing=True)
    text.data.align_x = "CENTER"
    text.data.size = 0.085 if closed else 0.1
    text.data.extrude = 0.002
    text.data.materials.append(solid("#e0303a" if closed else "#2fae3a", 0.4))
    parts.append(text)
    return parts


# --- Terraço -------------------------------------------------------------------------------------------------

def deck(variant):
    return planks("#b07a4a", 5, offset=0.37 * variant, long=1.0, dark=0.3)


def garden_fence():
    white = solid("#f4f7fa", 0.4)
    parts = []
    for z in (0.2, 0.4):
        parts.append(box((1.0 + 2 * BLEED, 0.03, 0.05), (0.5, -0.02, z), white, 0.006))
    for i in range(6):
        x = 0.06 + i * 0.176
        parts.append(box((0.06, 0.025, 0.5), (x, -0.04, 0.25), white, 0.006))
        parts.append(E.cone(0.045, 0.5, 0.56, white, (x, -0.04), vertices=4))
    parts.append(box((0.94, 0.16, 0.12), (0.5, -0.12, 0.06), wood("#a8703a"), 0.008))
    for i in range(7):
        x = 0.08 + i * 0.14
        parts.append(sphere(0.045, (x, -0.12, 0.14), E.foliage("#3fae4a"), (1, 1, 0.8)))
        parts.append(sphere(0.022, (x + 0.01, -0.15, 0.17), solid(("#ff4d8d", "#ffd23f", "#ffffff", "#b06bff")[i % 4], 0.5)))
    return parts


# --- Fotos ---------------------------------------------------------------------------------------------------

def place_wall(objects, side):
    parent = bpy.data.objects.new("Trecho", None)
    bpy.context.scene.collection.objects.link(parent)
    for obj in objects:
        obj.parent = parent
    if side == "L":
        parent.location = (0.0, -1.0, 0.0)
        parent.rotation_euler = (0.0, 0.0, math.radians(90.0))
    bpy.context.view_layer.update()
    return parent


def wall_shadow_catcher(side):
    """A parede invisível atrás do item: recebe a sombra dele."""
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0.5, 0.0, WALL_Z / 2), rotation=(math.radians(90), 0, 0))
    plane = bpy.context.active_object
    plane.scale = (1.0, WALL_Z, 1.0)
    plane.is_shadow_catcher = True
    return plane


def shoot_wall(name, objects, side, samples, anchors, catcher=False):
    objs = list(objects)
    if catcher:
        objs.append(wall_shadow_catcher(side))
    place_wall(objs, side)
    center = (0.5, 0.0) if side == "R" else (0.0, -0.5)
    aim_camera((center[0], center[1], WALL_Z * 0.5))
    anchor = (0.0, 0.0, 0.0) if side == "R" else (0.0, -1.0, 0.0)
    anchors[name] = cena3d.shoot(name, anchor, WORK)


def render_group(group, wanted, samples, manifest, anchors):
    def want(name):
        return not wanted or name in wanted or group in wanted

    if group == "pisos":
        for surface_id, info in manifest["floors"].items():
            for name in info["sprites"]:
                if want(name):
                    cena3d.setup(samples, (300, 220), shadow_size=0.01, tiling=True)
                    variant = name.rsplit("_", 1)[1]
                    floor_cell(floor_material(surface_id, int(variant) if variant.isdigit() else variant))
                    aim_camera((0.5, -0.5, 0.0))
                    anchors[name] = cena3d.shoot(name, (0.0, 0.0, 0.0), WORK)
        if want(manifest["floor_entrance"]):
            cena3d.setup(samples, (300, 220), shadow_size=(1.0, 1.0), shadow_center=(0.5, -0.5), tiling=True)
            objects = entrance_mat()
            aim_camera((0.5, -0.5, 0.0))
            anchors[manifest["floor_entrance"]] = cena3d.shoot(manifest["floor_entrance"], (0.0, 0.0, 0.0), WORK)
    elif group == "paredes":
        for surface_id, sides in manifest["walls"].items():
            for side, name in sides.items():
                if want(name):
                    cena3d.setup(samples, (300, 480), shadow_size=0.01, tiling=True)
                    shoot_wall(name, M._flatten(wall_style(surface_id)), side, samples, anchors)
    elif group in ("itens", "portas"):
        for name in sorted(n for n in manifest["sprites"] if n.startswith("enfeite_")):
            base, side = name[len("enfeite_"):-2], name[-1]
            is_door = base.startswith("porta")
            if (group == "portas") != is_door or not want(name):
                continue
            cena3d.setup(samples, (300, 480), shadow_size=0.01, tiling=True)
            if is_door:
                closed = base.endswith("_fechada")
                style = base[len("porta"):].removesuffix("_fechada").lstrip("_")
                objects = doorway(style, closed)
            else:
                objects = wall_item(base)
            shoot_wall(name, M._flatten(objects), side, samples, anchors, catcher=not is_door)  # a porta não tem parede atrás
    elif group == "terraco":
        for i, name in enumerate(manifest["terrace"]["floor"]):
            if want(name):
                cena3d.setup(samples, (300, 220), shadow_size=0.01, tiling=True)
                floor_cell(deck(i))
                aim_camera((0.5, -0.5, 0.0))
                anchors[name] = cena3d.shoot(name, (0.0, 0.0, 0.0), WORK)
        for side in ("R", "L"):
            name = f"{manifest['terrace']['fence']}_{side}"
            if want(name):
                cena3d.setup(samples, (300, 480), shadow_size=0.01, tiling=True)
                shoot_wall(name, M._flatten(garden_fence()), side, samples, anchors)


def main():
    import json
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    samples = 24 if "rascunho" in args else 80
    wanted = {a for a in args if a != "rascunho"}
    with open(os.path.join(cena3d.SPRITES, "sprites.json"), encoding="utf-8") as source:
        manifest = json.load(source)
    anchors = {}
    for group in ("pisos", "paredes", "itens", "portas", "terraco"):
        render_group(group, wanted, samples, manifest, anchors)
        print("PRONTO", group, flush=True)
    cena3d.update_manifest(anchors)
    print("SUPERFICIES OK", len(anchors), flush=True)


if __name__ == "__main__":
    main()
