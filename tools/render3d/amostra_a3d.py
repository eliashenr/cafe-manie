"""Segunda amostra da referência A (DT-091): modelos novos, não variações dos antigos, com a luz quente do salão.

Uso (na pasta do projeto):
    C:/Blender/blender-5.2.3-windows-x64/blender.exe -b -P tools/render3d/amostra_a3d.py -- [nomes...] [rascunho]

Nomes: chair_wood table_round counter_basic stove_basic forno pisos paredes pilares arandela janela quadros prateleira
relogio porta capacho (sem nada, faz todos). Grava em art/sprites com os mesmos nomes de sprite, então os ids, os preços e
o save não mudam.

O que muda em relação ao catálogo antigo:
- formas: encosto curvo estofado, tampo grosso de mesa, balcão de painéis almofadados, fogão com grelhas e espelho;
- proporções: os móveis ocupam a pegada (o assento tem 0,6 do piso, antes 0,5), e a parede ganha viga e pilar;
- materiais: madeira com veio e verniz, couro, ferro fundido e aço escovado;
- luz: a RIG_A de cena3d.py, quente e com contraste.
Continuam as medidas de encaixe: tampo da mesa, tampo do balcão, bocas do fogão e altura da parede.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cena3d  # noqa: E402
from cena3d import DESIGN_Z as PX, aim_camera, linear  # noqa: E402
import moveis3d as M  # noqa: E402
from moveis3d import box, cylinder, emission, solid, sphere, tube  # noqa: E402
import enfeites3d as E  # noqa: E402
import superficies3d as S  # noqa: E402

WORK = os.path.join(cena3d.ROOT, "tools", "render3d", "out_amostra")
IMAGE_SIZE = M.IMAGE_SIZE
WALL_Z = S.WALL_Z
BLEED = S.BLEED
SHADOW_MARGIN = 0.1

WALNUT = "#5d3820"
WALNUT_DARK = "#3a2214"
HONEY = "#8c5526"
BURGUNDY = "#6e1f24"
IRON = "#1e1f24"
STEEL = "#c9cccd"
CREAM = "#f6ecd8"

SEAT_TOP = 0.41            # mais baixo: o personagem novo é mais baixo (ver personagens3d.py)
SEAT_HALF = 0.3
BACK_TOP = SEAT_TOP + 0.3
TABLE_TOP_Z = 34 * PX      # igual ao table_tops do sprites.json: o prato continua caindo no tampo


# --- Materiais ------------------------------------------------------------------------------------------------

def rich_wood(color, scale=6.0, gloss=0.55):
    """Madeira envernizada: veios ondulados, nós e um relevo leve, com brilho de verniz."""
    key = ("rich_wood", color, scale, gloss)
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("Verniz_" + color)
        wave = nodes.new("ShaderNodeTexWave")
        wave.wave_type = "BANDS"
        wave.inputs["Scale"].default_value = scale * 0.45
        wave.inputs["Distortion"].default_value = 2.5
        wave.inputs["Detail"].default_value = 4.0
        wave.inputs["Detail Scale"].default_value = 1.5
        coords = M._coords(nodes, 1.0)
        links.new(coords, wave.inputs["Vector"])
        links.new(M._ramp(nodes, links, wave.outputs["Fac"], M._shade(color, 0.2), M._tint(color, 0.05), (0.1, 0.9)),
                  bsdf.inputs["Base Color"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.18
        links.new(wave.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
        bsdf.inputs["Roughness"].default_value = 0.38
        bsdf.inputs["Coat Weight"].default_value = gloss
        bsdf.inputs["Coat Roughness"].default_value = 0.18
        M._materials[key] = mat
    return M._materials[key]


def grain_wood(color, gloss=0.75):
    """Tampo de madeira: veio fino e comprido, sem as listras regulares que as faixas fazem numa área grande."""
    key = ("grain_wood", color, gloss)
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("Tampo_" + color)
        coords = nodes.new("ShaderNodeTexCoord")
        mapping = nodes.new("ShaderNodeMapping")
        mapping.inputs["Scale"].default_value = (1.2, 22.0, 4.0)
        links.new(coords.outputs["Object"], mapping.inputs["Vector"])
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 1.0
        noise.inputs["Detail"].default_value = 7.0
        noise.inputs["Distortion"].default_value = 0.6
        links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
        links.new(M._ramp(nodes, links, noise.outputs["Fac"], M._shade(color, 0.2), M._tint(color, 0.06), (0.32, 0.68)), bsdf.inputs["Base Color"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.1
        links.new(noise.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
        bsdf.inputs["Roughness"].default_value = 0.36
        bsdf.inputs["Coat Weight"].default_value = gloss
        bsdf.inputs["Coat Roughness"].default_value = 0.18
        M._materials[key] = mat
    return M._materials[key]


def leather(color):
    """Couro estofado: poros finos e brilho macio."""
    key = ("leather", color)
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("Couro_" + color)
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 90.0
        noise.inputs["Detail"].default_value = 6.0
        links.new(M._coords(nodes, 1.0), noise.inputs["Vector"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.15
        links.new(noise.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
        bsdf.inputs["Base Color"].default_value = linear(color)
        bsdf.inputs["Roughness"].default_value = 0.42
        bsdf.inputs["Sheen Weight"].default_value = 0.3
        M._materials[key] = mat
    return M._materials[key]


def brushed_steel(color=STEEL):
    """Aço escovado: riscos finos na horizontal, reflexo largo."""
    key = ("brushed", color)
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("Aco_" + color)
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 6.0
        noise.inputs["Detail"].default_value = 8.0
        coords = nodes.new("ShaderNodeTexCoord")
        mapping = nodes.new("ShaderNodeMapping")
        mapping.inputs["Scale"].default_value = (2.0, 2.0, 120.0)
        links.new(coords.outputs["Object"], mapping.inputs["Vector"])
        links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
        links.new(M._ramp(nodes, links, noise.outputs["Fac"], M._shade(color, 0.1), color, (0.3, 0.7)), bsdf.inputs["Base Color"])
        bsdf.inputs["Metallic"].default_value = 0.55   # totalmente metálico, só refletiria o salão e ficaria marrom
        bsdf.inputs["Roughness"].default_value = 0.36
        M._materials[key] = mat
    return M._materials[key]


def cast_iron(color=IRON):
    return solid(color, 0.55, 0.7)


def stone_top(color=CREAM):
    """Pedra clara polida, com manchas bem suaves: o tampo precisa continuar claro sob a luz quente."""
    key = ("stone_top", color)
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("Pedra_" + color)
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 9.0
        noise.inputs["Detail"].default_value = 7.0
        links.new(M._coords(nodes, 1.0), noise.inputs["Vector"])
        links.new(M._ramp(nodes, links, noise.outputs["Fac"], M._shade(color, 0.06), color, (0.35, 0.65)), bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.24
        bsdf.inputs["Coat Weight"].default_value = 0.45
        M._materials[key] = mat
    return M._materials[key]


# --- Peças ----------------------------------------------------------------------------------------------------

def taper(a, b, radius_a, radius_b, mat):
    """Pé torneado: um cone de [a] até [b]."""
    a, b = Vector(a), Vector(b)
    bpy.ops.mesh.primitive_cone_add(radius1=radius_a, radius2=radius_b, depth=(b - a).length, location=(a + b) / 2, vertices=20)
    obj = bpy.context.active_object
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = (b - a).to_track_quat("Z", "Y")
    return M._finish(obj, mat, 0.003)


def arc_band(radius, thickness, z0, z1, a0, a1, mat, center=(0.0, 0.0), squash=1.0, bevel=0.012, steps=32):
    """Faixa curva (o encosto): um pedaço de anel, de [a0] a [a1] graus, entre as alturas [z0] e [z1]."""
    verts, faces = [], []
    for i in range(steps + 1):
        angle = math.radians(a0 + (a1 - a0) * i / steps)
        for r in (radius, radius - thickness):
            x, y = center[0] + math.cos(angle) * r, center[1] + math.sin(angle) * r * squash
            verts += [(x, y, z0), (x, y, z1)]
    for i in range(steps):
        a, b = i * 4, (i + 1) * 4
        faces += [(a, b, b + 1, a + 1), (a + 2, a + 3, b + 3, b + 2), (a + 1, b + 1, b + 3, a + 3), (a, a + 2, b + 2, b)]
    last = steps * 4
    faces += [(0, 1, 3, 2), (last, last + 2, last + 3, last + 1)]
    mesh = bpy.data.meshes.new("Faixa")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("Faixa", mesh)
    bpy.context.scene.collection.objects.link(obj)
    return M._finish(obj, mat, bevel, segments=4)


def cushion(half, z0, z1, mat, bevel=0.035):
    """Almofada do assento: quadrada com os cantos bem redondos."""
    obj = box((2 * half, 2 * half, z1 - z0), (0.0, 0.0, (z0 + z1) / 2), mat, 0.0)
    mod = obj.modifiers.new("Canto", "BEVEL")
    mod.width = bevel * 2.4
    mod.segments = 6
    mod.limit_method = "ANGLE"
    mod.angle_limit = math.radians(60)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


# --- Móveis ---------------------------------------------------------------------------------------------------

def chair_a():
    """Cadeira de bistrô estofada: pés torneados, assento largo e encosto curvo, com a frente em -Y.
    Devolve (peças, peças do encosto)."""
    legs = rich_wood(WALNUT, 9.0, 0.35)
    seat_z = SEAT_TOP - 0.09
    parts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(taper((sx * (SEAT_HALF - 0.015), sy * (SEAT_HALF - 0.015), 0.0), (sx * (SEAT_HALF - 0.055), sy * (SEAT_HALF - 0.055), seat_z), 0.018, 0.034, legs))
    parts.append(box((2 * SEAT_HALF, 2 * SEAT_HALF, 0.05), (0.0, 0.0, seat_z), legs, 0.012))
    parts.append(cushion(SEAT_HALF - 0.005, seat_z + 0.02, SEAT_TOP, leather(BURGUNDY)))
    # O encosto abraça o assento por trás e pelos lados, e tem a viga de madeira no alto.
    center = (0.0, -0.05)
    radius = SEAT_HALF + 0.04
    back = [arc_band(radius, 0.05, SEAT_TOP - 0.02, BACK_TOP - 0.025, 20, 160, leather(BURGUNDY), center),
            arc_band(radius + 0.006, 0.062, BACK_TOP - 0.03, BACK_TOP, 16, 164, legs, center, bevel=0.012)]
    for angle in (24, 156):
        rad = math.radians(angle)
        x, y = center[0] + math.cos(rad) * (radius - 0.025), center[1] + math.sin(rad) * (radius - 0.025)
        back.append(tube((x, y, seat_z), (x, y, BACK_TOP - 0.02), 0.02, legs))
    return parts, back


def table_a():
    """Mesa redonda de bistrô: tampo grosso de madeira com borda torneada e pé de ferro fundido com três pernas curvas."""
    h = TABLE_TOP_Z
    iron = cast_iron()
    top = grain_wood(HONEY, 0.8)
    parts = [cylinder(0.47, h - 0.05, h, top, bevel=0.016, vertices=72),
             cylinder(0.43, h - 0.085, h - 0.05, rich_wood(WALNUT, 5.0, 0.4), bevel=0.012, vertices=72),
             cylinder(0.05, 0.11, h - 0.08, iron, bevel=0.006),
             cylinder(0.085, h - 0.12, h - 0.085, iron, bevel=0.01),
             cylinder(0.09, 0.09, 0.15, iron, bevel=0.018)]
    for angle in (90, 210, 330):
        rad = math.radians(angle)
        foot = (math.cos(rad) * 0.31, math.sin(rad) * 0.31)
        parts.append(tube((math.cos(rad) * 0.05, math.sin(rad) * 0.05, 0.12), (foot[0], foot[1], 0.025), 0.026, iron))
        parts.append(sphere(0.035, (foot[0], foot[1], 0.025), iron, (1.0, 1.0, 0.6)))
    # Vidrinho com a vela no meio da mesa: a luz da mesa, como na referência.
    parts.append(cylinder(0.04, h, h + 0.075, E.glass("#ffd9a0", 0.25), bevel=0.006))
    parts.append(sphere(0.016, (0.0, 0.0, h + 0.05), emission("#ffb24d", 28.0), (1, 1, 1.5)))
    return parts


def _raised_panel(width, height, center_x, z, front, mat, frame_mat):
    """Painel almofadado: moldura funda e a almofada no meio. [front] é o y da face."""
    return [box((width, 0.022, height), (center_x, front - 0.005, z), frame_mat, 0.004),
            box((width - 0.05, 0.03, height - 0.05), (center_x, front - 0.011, z), mat, 0.012)]


def counter_a():
    """Balcão de madeira: rodapé, painéis almofadados nas quatro faces, pilares nos cantos e tampo largo de pedra."""
    h = M.COUNTER_HEIGHT
    w = 1.0 + 2 * BLEED     # do tamanho do piso: dois balcões lado a lado formam um só
    wood = rich_wood(WALNUT, 7.0, 0.5)
    dark = rich_wood(WALNUT_DARK, 7.0, 0.25)
    light = rich_wood("#74482a", 7.0, 0.6)
    parts = [box((w - 0.05, w - 0.05, h - 0.05), (0.0, 0.0, (h - 0.05) / 2 + 0.05), wood, 0.006),
             box((w - 0.015, w - 0.015, 0.07), (0.0, 0.0, 0.035), dark, 0.006),
             box((w - 0.03, w - 0.03, 0.04), (0.0, 0.0, h - 0.03), dark, 0.006)]
    panel_h = h - 0.2
    z = 0.09 + panel_h / 2
    for angle in (0.0, 90.0, 180.0, -90.0):   # as quatro faces, porque o balcão gira
        rad = math.radians(angle)
        for x in (-0.225, 0.225):
            for obj in _raised_panel(0.4, panel_h, x, z, -(w - 0.05) / 2, light, dark):
                lx, ly = obj.location.x, obj.location.y
                obj.location = (lx * math.cos(rad) - ly * math.sin(rad), lx * math.sin(rad) + ly * math.cos(rad), obj.location.z)
                obj.rotation_euler = (0.0, 0.0, rad)
                parts.append(obj)
    # O tampo: 0,09 de espessura, com sobra e borda arredondada; a altura final é a mesma do catálogo.
    top_z0 = h + M.COUNTER_TOP - 0.09
    parts.append(box((w + 0.04, w + 0.04, 0.09), (0.0, 0.0, top_z0 + 0.045), stone_top(), 0.022))
    return parts


def stove_a():
    """Fogão de ferro e aço: corpo reforçado, grelhas de ferro nas bocas, espelho atrás com o trilho, painel de botões
    grandes e o forno com a janela grande e o puxador. As bocas ficam onde o jogo põe a panela. Frente em -Y."""
    h = M.STOVE_HEIGHT
    w = 0.96
    steel = brushed_steel()
    iron = cast_iron()
    black = solid("#141418", 0.32, 0.4, 0.5)
    parts = [box((w, w - 0.03, h - 0.07), (0.0, 0.0, (h - 0.07) / 2 + 0.07), steel, 0.018),
             box((w - 0.04, w - 0.07, 0.07), (0.0, 0.0, 0.035), solid("#26262b", 0.6), 0.004),
             box((w + 0.02, w + 0.0, 0.03), (0.0, 0.0, h - 0.002), steel, 0.01),
             box((w - 0.09, w - 0.1, 0.012), (0.0, -0.015, h + 0.016), black, 0.004)]
    # O espelho de trás e o trilho (em +Y, a parte mais longe de quem cozinha).
    back_y = w / 2 - 0.03
    parts.append(box((w, 0.05, 0.3), (0.0, back_y, h + 0.15), steel, 0.012))
    parts.append(box((w + 0.03, 0.09, 0.03), (0.0, back_y - 0.01, h + 0.31), iron, 0.008))
    # As grelhas: em cruz, nas quatro bocas.
    for (u, v) in M.STOVE_BURNERS:
        x, y = (u - 0.5) * M.STOVE_SIZE, -(v - 0.5) * M.STOVE_SIZE
        z = h + 0.024
        parts.append(cylinder(0.05, h + 0.012, z + 0.002, solid("#2d2e33", 0.5, 0.6), (x, y)))
        parts.append(box((0.2, 0.018, 0.022), (x, y, z + 0.012), iron, 0.004))
        parts.append(box((0.018, 0.2, 0.022), (x, y, z + 0.012), iron, 0.004))
    front = -(w - 0.03) / 2
    # Painel de botões.
    parts.append(box((w - 0.04, 0.03, 0.12), (0.0, front - 0.01, h - 0.08), solid("#2a2a2f", 0.4, 0.6), 0.008))
    for i in range(4):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.034, depth=0.04, location=((i - 1.5) * 0.2, front - 0.04, h - 0.08),
                                            rotation=(math.radians(90), 0, 0), vertices=24)
        parts.append(M._finish(bpy.context.active_object, brushed_steel("#d7dadb"), 0.008))
    # O forno: porta, janela escura e puxador grosso.
    parts.append(box((w - 0.09, 0.024, h * 0.56), (0.0, front - 0.012, h * 0.37), steel, 0.012))
    parts.append(box((w * 0.56, 0.012, h * 0.24), (0.0, front - 0.026, h * 0.37), solid("#0c0d11", 0.06, 0.0, 1.0), 0.01))
    parts.append(tube((-0.31, front - 0.06, h * 0.63), (0.31, front - 0.06, h * 0.63), 0.016, brushed_steel("#d7dadb")))
    for x in (-0.29, 0.29):
        parts.append(tube((x, front - 0.015, h * 0.63), (x, front - 0.06, h * 0.63), 0.011, iron))
    return parts


# --- Fotos dos móveis -----------------------------------------------------------------------------------------

def shoot_item(name, objects, rotation, samples, anchors):
    M_anchor, center = M.assemble(objects, (1, 1), rotation)
    aim_camera((center[0], center[1], 0.42))
    anchors[name] = cena3d.shoot(name, M_anchor, WORK)


def _setup_item(samples, shadow=True):
    size = (1.0 + SHADOW_MARGIN, 1.0 + SHADOW_MARGIN) if shadow else 0.01
    cena3d.setup(samples, IMAGE_SIZE, shadow_center=(0.5, -0.5) if shadow else (0.0, 0.0), shadow_size=size, rig="a")


def render_chair(samples, anchors):
    for rotation in range(4):
        _setup_item(samples)
        parts, back = chair_a()
        shoot_item(f"chair_wood_r{rotation}", list(M._flatten(parts + back)), rotation, samples, anchors)
        if rotation in (1, 2):
            _setup_item(samples, shadow=False)
            parts, back = chair_a()
            for part in M._flatten(parts):
                bpy.data.objects.remove(part, do_unlink=True)
            shoot_item(f"encosto_chair_wood_r{rotation}", list(M._flatten(back)), rotation, samples, anchors)


def render_furniture(name, build, rotations, samples, anchors):
    for rotation in rotations:
        _setup_item(samples)
        shoot_item(f"{name}_r{rotation}", list(M._flatten(build())), rotation, samples, anchors)


def render_oven_glow(samples, anchors):
    h = M.STOVE_HEIGHT
    front = -(0.96 - 0.03) / 2
    for rotation in (0, 3):
        _setup_item(samples, shadow=False)
        glow = box((0.96 * 0.56, 0.004, h * 0.24), (0.0, front - 0.034, h * 0.37), emission("#ff8a2c", 0.8), 0.008)
        shoot_item(f"fogao_aceso_r{rotation}", [glow], rotation, samples, anchors)


# --- Pisos e paredes ------------------------------------------------------------------------------------------

def wide_planks(variant):
    """Assoalho de tábuas largas e envernizadas, com o tom mudando de tábua para tábua."""
    key = ("wide_planks", variant)

    def build(nodes, links, bsdf):
        vector = S._vector(nodes, (variant * 0.31, 0.0, 0.0))
        brick = nodes.new("ShaderNodeTexBrick")
        brick.offset = 0.5
        brick.inputs["Scale"].default_value = 1.0
        brick.inputs["Brick Width"].default_value = 1.0
        brick.inputs["Row Height"].default_value = 1.0 / 4.0
        brick.inputs["Mortar Size"].default_value = 0.006
        brick.inputs["Mortar Smooth"].default_value = 0.2
        brick.inputs["Color1"].default_value = linear("#a4602a")
        brick.inputs["Color2"].default_value = linear("#6f3c1b")
        brick.inputs["Mortar"].default_value = linear("#1c0f08")
        links.new(vector, brick.inputs["Vector"])
        grain = nodes.new("ShaderNodeTexWave")
        grain.wave_type = "BANDS"
        grain.bands_direction = "Y"
        grain.inputs["Scale"].default_value = 4.0
        grain.inputs["Distortion"].default_value = 0.0
        links.new(vector, grain.inputs["Vector"])
        mix = nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        mix.blend_type = "MULTIPLY"
        mix.inputs[0].default_value = 0.45
        links.new(brick.outputs["Color"], mix.inputs[6])
        links.new(M._ramp(nodes, links, grain.outputs["Fac"], "#9a7a58", "#ffffff"), mix.inputs[7])
        links.new(mix.outputs[2], bsdf.inputs["Base Color"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.5
        links.new(brick.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
        bsdf.inputs["Roughness"].default_value = 0.3
        bsdf.inputs["Coat Weight"].default_value = 0.7
        bsdf.inputs["Coat Roughness"].default_value = 0.2
    return S._mat(key, build)


def stone_slabs(variant):
    """Piso inicial: lajotas simples de cerâmica, com rejunte fundo. Modesto de propósito."""
    colors = ("#c9b189", "#b79b70")
    return S.grid_tiles(colors[variant], "#6f5a40", 2, rough=0.55, variation=0.09, coat=0.12)


def brick_relief():
    """Tijolo aparente em relevo: tijolo escuro, rejunte fundo e variação de queima."""
    def build(nodes, links, bsdf):
        vector = S._vector(nodes)
        sep = nodes.new("ShaderNodeSeparateXYZ")
        comb = nodes.new("ShaderNodeCombineXYZ")
        links.new(vector, sep.inputs["Vector"])
        links.new(sep.outputs["X"], comb.inputs["X"])
        links.new(sep.outputs["Z"], comb.inputs["Y"])
        brick = nodes.new("ShaderNodeTexBrick")
        brick.offset = 0.5
        brick.inputs["Scale"].default_value = 1.0
        brick.inputs["Brick Width"].default_value = 0.25
        brick.inputs["Row Height"].default_value = WALL_Z / 22.0
        brick.inputs["Mortar Size"].default_value = 0.009
        brick.inputs["Mortar Smooth"].default_value = 0.25
        brick.inputs["Color1"].default_value = linear("#8c3c2a")
        brick.inputs["Color2"].default_value = linear("#5e2a20")
        brick.inputs["Mortar"].default_value = linear("#2c2420")
        links.new(comb.outputs["Vector"], brick.inputs["Vector"])
        links.new(brick.outputs["Color"], bsdf.inputs["Base Color"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 1.0
        bump.inputs["Distance"].default_value = 0.03
        links.new(brick.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
        bsdf.inputs["Roughness"].default_value = 0.82
    return S._mat(("brick_relief",), build)


def _wall_common(parts, base_color):
    """Rodapé alto e viga no alto, com volume: dão peso à parede."""
    width = 1.0 + 2 * BLEED
    beam = rich_wood(WALNUT_DARK, 5.0, 0.3)
    parts.append(box((width, 0.09, 0.14), (0.5, -0.03, WALL_Z - 0.07), beam, 0.006))
    parts.append(box((width, 0.08, 0.11), (0.5, -0.02, 0.055), solid(base_color, 0.45), 0.004))
    return parts


def wall_a(surface_id):
    width = 1.0 + 2 * BLEED
    if surface_id == "wall_brick":
        parts = [box((width, 0.04, WALL_Z), (0.5, 0.02, WALL_Z / 2), brick_relief(), 0.0)]
        return _wall_common(parts, "#1f1712")
    # Parede inicial: reboco creme e um lambri simples de madeira, com o friso. Sem pilar nem luz: isso é compra.
    z = S.WAINSCOT_TOP
    wood = rich_wood("#6d4527", 7.0, 0.3)
    parts = [box((width, 0.04, WALL_Z - z), (0.5, 0.02, (WALL_Z + z) / 2), S.plaster("#e7d3ac"), 0.0),
             box((width, 0.06, z), (0.5, 0.01, z / 2), wood, 0.0),
             box((0.82, 0.07, z * 0.62), (0.5, 0.0, z * 0.54), rich_wood("#7c5230", 7.0, 0.4), 0.012),
             box((width, 0.085, 0.045), (0.5, -0.008, z + 0.012), rich_wood(WALNUT, 6.0, 0.4), 0.008)]
    return _wall_common(parts, "#2c1c12")


def pilaster():
    """Pilar de madeira escura: vai na parede a cada dois trechos e marca o ritmo da parede, como na referência."""
    wood = rich_wood(WALNUT_DARK, 5.0, 0.35)
    iron = cast_iron()
    return [box((0.11, 0.1, WALL_Z), (0.0, -0.03, WALL_Z / 2), wood, 0.01),
            box((0.15, 0.13, 0.13), (0.0, -0.035, 0.065), iron, 0.008),
            box((0.15, 0.13, 0.08), (0.0, -0.035, WALL_Z - 0.04), iron, 0.008)]


# --- Itens de parede e porta ----------------------------------------------------------------------------------

def sconce():
    """Arandela: braço de ferro curvo e lanterna de vidro com a lâmpada acesa."""
    cx, cz = S.at(21, -71)
    iron = cast_iron()
    y = -0.16
    parts = [box((0.1, 0.03, 0.2), (cx, -0.015, cz + 0.04), iron, 0.012),
             tube((cx, -0.03, cz + 0.12), (cx, y, cz + 0.2), 0.012, iron),
             cylinder(0.075, cz + 0.17, cz + 0.205, iron, (cx, y), bevel=0.01),
             cylinder(0.06, cz - 0.03, cz + 0.17, E.glass("#ffdca6", 0.2), (cx, y), bevel=0.006),
             cylinder(0.068, cz - 0.05, cz - 0.03, iron, (cx, y), bevel=0.006),
             sphere(0.034, (cx, y, cz + 0.06), emission("#ffc06a", 34.0), (1, 1, 1.3))]
    return parts


def window_a():
    """Janela alta de caixilho escuro, com peitoril de madeira e vidro em cruz."""
    x0, z1 = S.at(9, -88)
    x1, z0 = S.at(33, -42)
    w, h = x1 - x0, z1 - z0
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    frame = rich_wood(WALNUT_DARK, 6.0, 0.4)
    glass = solid("#6d8294", 0.08, 0.0, 1.0)
    parts = [box((w, 0.012, h), (cx, -0.005, cz), glass, 0.0),
             box((w + 0.1, 0.07, 0.06), (cx, -0.035, z1 + 0.02), frame, 0.008),
             box((w + 0.16, 0.13, 0.05), (cx, -0.07, z0 - 0.02), rich_wood(WALNUT, 6.0, 0.5), 0.01),
             box((0.035, 0.05, h), (cx, -0.02, cz), frame, 0.004),
             box((w, 0.05, 0.03), (cx, -0.02, cz + h * 0.14), frame, 0.004)]
    for x in (x0, x1):
        parts.append(box((0.05, 0.07, h + 0.04), (x, -0.03, cz), frame, 0.006))
    return parts


def framed_print(kind):
    """Quadro de moldura escura e passe-partout: o desenho em tons de sépia, que não briga com o salão."""
    x0, z1 = S.at(9, -84)
    x1, z0 = S.at(33, -50)
    w, h = x1 - x0, z1 - z0
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    y = -0.04
    parts = [box((w + 0.08, 0.04, h + 0.08), (cx, -0.02, cz), rich_wood(WALNUT_DARK, 6.0, 0.4), 0.012),
             box((w, 0.01, h), (cx, y - 0.002, cz), solid("#e3d6bb", 0.8), 0.0)]
    if kind == "cupcake":
        parts.append(box((0.17, 0.008, 0.1), (cx, y - 0.008, cz - 0.08), solid("#7a5230", 0.7), 0.02))
        parts.append(sphere(0.1, (cx, y - 0.008, cz + 0.03), solid("#a2553f", 0.6), (1, 0.08, 0.7)))
        parts.append(sphere(0.022, (cx, y - 0.014, cz + 0.12), solid("#4a1c18", 0.4)))
    else:
        for (dx, width, height) in ((-0.2, 0.09, 0.22), (-0.09, 0.11, 0.36), (0.03, 0.09, 0.28), (0.14, 0.11, 0.44), (0.25, 0.07, 0.18)):
            parts.append(box((width, 0.008, height), (cx + dx, y - 0.008, cz - h * 0.36 + height / 2), solid("#3a3631", 0.8), 0.0))
    return parts


def shelf_a():
    """Prateleira grossa de madeira sobre mãos-francesas de ferro, com potes e uma plantinha."""
    x0, z = S.at(3, -58)
    iron = cast_iron()
    parts = [box((0.88, 0.2, 0.05), (0.5, -0.1, z), rich_wood(HONEY, 5.0, 0.6), 0.012)]
    for x in (0.16, 0.84):
        parts.append(box((0.03, 0.03, 0.14), (x, -0.015, z - 0.09), iron, 0.004))
        parts.append(tube((x, -0.02, z - 0.15), (x, -0.16, z - 0.02), 0.009, iron))
    for x, r, tall, color in ((0.2, 0.045, 0.14, "#d8c8a6"), (0.34, 0.04, 0.1, "#8c5a32"), (0.47, 0.05, 0.17, "#d8c8a6")):
        parts.append(cylinder(r, z + 0.025, z + 0.025 + tall, solid(color, 0.35, 0.0, 0.4), (x, -0.1), bevel=0.012))
        parts.append(cylinder(r + 0.004, z + 0.025 + tall, z + 0.04 + tall, rich_wood(WALNUT, 5.0), (x, -0.1), bevel=0.004))
    parts.append(cylinder(0.05, z + 0.025, z + 0.1, solid("#8a4a2c", 0.6), (0.72, -0.1), bevel=0.008))
    parts += E.rosette((0.72, -0.1, z + 0.1), 9, 0.13, 0.024, 70, E.foliage("#3d7a3a"))
    return parts


def clock_a():
    cx, cz = S.at(21, -74)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.2, depth=0.05, location=(cx, -0.025, cz), rotation=(math.radians(90), 0, 0), vertices=48)
    parts = [M._finish(bpy.context.active_object, rich_wood(WALNUT_DARK, 6.0, 0.5), 0.012)]
    bpy.ops.mesh.primitive_cylinder_add(radius=0.165, depth=0.01, location=(cx, -0.052, cz), rotation=(math.radians(90), 0, 0), vertices=48)
    parts.append(M._finish(bpy.context.active_object, solid("#e8dcc0", 0.5), 0))
    parts.append(box((0.014, 0.008, 0.11), (cx, -0.06, cz + 0.05), solid("#1b1b20", 0.4), 0.0))
    parts.append(box((0.08, 0.008, 0.014), (cx + 0.04, -0.06, cz), solid("#1b1b20", 0.4), 0.0))
    return parts


def doorway_a(closed):
    """Entrada: portal grosso de madeira escura com o lintel, a porta de vidro aberta para dentro, o toldo cor de vinho
    e a plaquinha. O vão continua livre: é por ele que os clientes passam."""
    top = 78 / S.DESIGN_H * WALL_Z
    wood = rich_wood(WALNUT_DARK, 6.0, 0.4)
    iron = cast_iron()
    parts = [box((0.12, 0.14, top), (x, -0.02, top / 2), wood, 0.012) for x in (0.05, 0.95)]
    parts.append(box((1.1, 0.16, 0.13), (0.5, -0.02, top + 0.065), wood, 0.012))
    parts.append(box((1.12, 0.05, 0.03), (0.5, -0.06, top + 0.14), iron, 0.006))
    # A folha da porta, aberta contra o batente da direita: moldura de madeira e vidro.
    leaf_w = 0.42
    leaf_x = 0.9
    leaf_y = 0.05 + leaf_w / 2
    parts.append(box((0.03, leaf_w, top - 0.05), (leaf_x, leaf_y, (top - 0.05) / 2 + 0.02), rich_wood(WALNUT, 6.0, 0.5), 0.006))
    parts.append(box((0.036, leaf_w - 0.1, top * 0.58), (leaf_x, leaf_y, top * 0.6), solid("#a8bcc6", 0.06, 0.0, 1.0), 0.002))
    # O toldo em cunha, sem listras de praia.
    canopy = box((1.12, 0.34, 0.025), (0.5, -0.2, top + 0.03), S.pattern("stripes", ["#5e1a1f", "#6f2329"], 7, rough=0.7), 0.006)
    canopy.rotation_euler = (math.radians(-24), 0, 0)
    parts.append(canopy)
    parts.append(box((1.12, 0.014, 0.08), (0.5, -0.355, top - 0.05), solid("#4a1418", 0.7), 0.004))
    # A plaquinha que o jogo troca entre ABERTO e FECHADO.
    sign_z = top - 0.24
    parts.append(tube((0.42, -0.08, top - 0.02), (0.5, -0.08, sign_z + 0.08), 0.004, iron))
    parts.append(tube((0.58, -0.08, top - 0.02), (0.5, -0.08, sign_z + 0.08), 0.004, iron))
    parts.append(box((0.42, 0.024, 0.17), (0.5, -0.08, sign_z), solid("#20170f", 0.5), 0.012))
    bpy.ops.object.text_add(location=(0.5, -0.095, sign_z - 0.04), rotation=(math.radians(90), 0, 0))
    text = bpy.context.active_object
    text.data.body = "FECHADO" if closed else "ABERTO"
    text.data.font = bpy.data.fonts.load(S.FONT, check_existing=True)
    text.data.align_x = "CENTER"
    text.data.size = 0.085 if closed else 0.1
    text.data.extrude = 0.002
    text.data.materials.append(emission("#e0603a" if closed else "#f2c56e", 1.4))
    parts.append(text)
    return parts


def doormat():
    mat = M.fabric("plain", "#3a2a22")
    return [box((0.66, 0.44, 0.014), (0.5, -0.5, 0.007), mat, 0.004)]


# --- Fotos das superfícies ------------------------------------------------------------------------------------

def _setup_surface(samples, size=(300, 480), sun=None):
    kwargs = {"sun": sun} if sun is not None else {}
    cena3d.setup(samples, size, shadow_size=0.01, tiling=True, rig="a", **kwargs)


def shoot_wall_piece(name, objects, side, samples, anchors, catcher=False):
    _setup_surface(samples)
    S.shoot_wall(name, M._flatten(objects()), side, samples, anchors, catcher)


def render_floor(name, material_of, samples, anchors):
    _setup_surface(samples, (300, 220), S.FLOOR_SUN)
    S.floor_cell(material_of)
    aim_camera((0.5, -0.5, 0.0))
    anchors[name] = cena3d.shoot(name, (0.0, 0.0, 0.0), WORK)


def main():
    import json
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    samples = 32 if "rascunho" in args else 96
    wanted = {a for a in args if a != "rascunho"}
    want = lambda name: not wanted or name in wanted  # noqa: E731
    S.WORK = WORK
    anchors = {}
    if want("chair_wood"):
        render_chair(samples, anchors)
    if want("table_round"):
        render_furniture("table_round", table_a, [0], samples, anchors)
    if want("counter_basic"):
        render_furniture("counter_basic", counter_a, range(4), samples, anchors)
    if want("stove_basic"):
        render_furniture("stove_basic", stove_a, range(4), samples, anchors)
    if want("forno"):
        render_oven_glow(samples, anchors)
    if want("pisos"):
        for name, v in (("piso_floor_beige_a", 0), ("piso_floor_beige_b", 1)):
            render_floor(name, stone_slabs(v), samples, anchors)
        for i in range(4):
            render_floor(f"piso_floor_wood_{i}", wide_planks(i), samples, anchors)
    if want("capacho"):
        cena3d.setup(samples, (300, 220), shadow_size=(1.0, 1.0), shadow_center=(0.5, -0.5), tiling=True, sun=S.FLOOR_SUN, rig="a")
        doormat()
        aim_camera((0.5, -0.5, 0.0))
        anchors["piso_entrada"] = cena3d.shoot("piso_entrada", (0.0, 0.0, 0.0), WORK)
    for side in ("R", "L"):
        if want("paredes"):
            for surface_id in ("wall_cream", "wall_brick"):
                shoot_wall_piece(f"parede_{surface_id}_{side}", lambda sid=surface_id: wall_a(sid), side, samples, anchors)
        if want("pilares"):
            shoot_wall_piece(f"parede_pilar_{side}", pilaster, side, samples, anchors)
        if want("arandela"):
            shoot_wall_piece(f"enfeite_arandela_{side}", sconce, side, samples, anchors, catcher=True)
        if want("janela"):
            shoot_wall_piece(f"enfeite_janela_{side}", window_a, side, samples, anchors, catcher=True)
        if want("quadros"):
            shoot_wall_piece(f"enfeite_quadro_cupcake_{side}", lambda: framed_print("cupcake"), side, samples, anchors, catcher=True)
            shoot_wall_piece(f"enfeite_quadro_paisagem_{side}", lambda: framed_print("paisagem"), side, samples, anchors, catcher=True)
        if want("prateleira"):
            shoot_wall_piece(f"enfeite_prateleira_{side}", shelf_a, side, samples, anchors, catcher=True)
        if want("relogio"):
            shoot_wall_piece(f"enfeite_relogio_{side}", clock_a, side, samples, anchors, catcher=True)
        if want("porta"):
            shoot_wall_piece(f"enfeite_porta_{side}", lambda: doorway_a(False), side, samples, anchors)
            shoot_wall_piece(f"enfeite_porta_fechada_{side}", lambda: doorway_a(True), side, samples, anchors)

    def seat_and_pilasters(manifest):
        if "parede_pilar_R" in anchors or "wall_pilaster" in manifest:
            manifest["wall_pilaster"] = {"R": "parede_pilar_R", "L": "parede_pilar_L"}
    cena3d.update_manifest(anchors, seat_and_pilasters)
    print("AMOSTRA OK", len(anchors), flush=True)


if __name__ == "__main__":
    main()
