"""Cadeiras e mesas da loja na linguagem da referência A (DT-093): cada item mantém o nome, a coleção e o caráter, com
modelo novo, proporção da cadeira e da mesa da amostra e a luz quente do salão.

Uso (na pasta do projeto):
    C:/Blender/blender-5.2.3-windows-x64/blender.exe -b -P tools/render3d/assentos_a3d.py -- [ids...] [rascunho] [prova]

Sem ids, faz todas (menos chair_wood e table_round, que são de amostra_a3d.py). "prova" faz só duas vistas da cadeira
(de frente e de costas) e uma da mesa, sem os encostos, para conferir a forma antes de fazer todos os quadros.

Grava em art/sprites com os mesmos nomes de sprite, então os ids, os preços e o save não mudam. Continuam as medidas de
encaixe: a altura do tampo de cada mesa (table_tops do sprites.json) e o assento de quem senta (amostra_a3d.SEAT_TOP).
"""
import json
import math
import os
import sys

import bmesh
import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cena3d  # noqa: E402
from cena3d import aim_camera  # noqa: E402
import moveis3d as M  # noqa: E402
from moveis3d import box, cylinder, emission, solid, sphere, tube  # noqa: E402
import enfeites3d as E  # noqa: E402
import amostra_a3d as A  # noqa: E402
from amostra_a3d import arc_band, cast_iron, cushion, grain_wood, leather, rich_wood, taper  # noqa: E402

WORK = os.path.join(cena3d.ROOT, "tools", "render3d", "out_assentos")

SEAT_TOP = A.SEAT_TOP
HALF = 0.27                # mais estreito que a poltrona inicial: as cadeiras da loja são mais leves que ela
SEAT_Z = SEAT_TOP - 0.09
BACK_TOP = A.BACK_TOP
BACK_CENTER = (0.0, -0.03)
BACK_RADIUS = HALF + 0.04
SHELL_TILT = 0.55
BACK_WRAP = 0.88            # o quanto o encosto reto abraça: os postes ficam no fundo do assento, não no meio do lado
ROUND_SEAT = 0.25
STOOL_SEAT = 0.19           # a banqueta é estreita: larga demais, parece uma mesinha
TABLE_RADIUS = 0.47
TABLE_SIDE = 0.94
TABLE_THICK = 0.05
SHADOW_MARGIN = 0.1

OAK = "#c79a63"
WALNUT = A.WALNUT
ROSEWOOD = "#3f2115"
HONEY = A.HONEY
GOLD = "#c89b48"
CHROME_A = "#d7dadb"


# --- Materiais ------------------------------------------------------------------------------------------------

def velvet(color):
    key = ("velvet", color)
    if key not in M._materials:
        mat, _, _, bsdf = M._principled("Veludo_" + color)
        bsdf.inputs["Base Color"].default_value = cena3d.linear(color)
        bsdf.inputs["Roughness"].default_value = 0.85
        bsdf.inputs["Sheen Weight"].default_value = 0.4
        M._materials[key] = mat
    return M._materials[key]


def vinyl(color):
    return solid(color, 0.3, 0.0, 0.3)


def painted(color):
    return solid(color, 0.42, 0.0, 0.2)


def chrome_a():
    """Cromo que não vira espelho do salão: totalmente metálico, só refletiria o marrom da luz quente."""
    return solid(CHROME_A, 0.5, 0.5)


def gold():
    return solid(GOLD, 0.55, 0.6)


def upholstery(color):
    """Tecido de estofado, fosco: em couro brilhante, as cores fortes parecem plástico."""
    return M.fabric("plain", color)


def mirror_glass():
    """Espelho: faixas claras em diagonal, porque de verdade ele só refletiria o marrom do salão."""
    key = ("mirror_glass",)
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("Espelho")
        wave = nodes.new("ShaderNodeTexWave")
        wave.bands_direction = "DIAGONAL"
        wave.inputs["Scale"].default_value = 0.9
        wave.inputs["Distortion"].default_value = 0.3
        links.new(M._coords(nodes, 1.0), wave.inputs["Vector"])
        links.new(M._ramp(nodes, links, wave.outputs["Fac"], "#b4c8d3", "#eff6f9", (0.3, 0.7)), bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.06
        bsdf.inputs["Metallic"].default_value = 0.35
        bsdf.inputs["Coat Weight"].default_value = 1.0
        M._materials[key] = mat
    return M._materials[key]


def laminate(color):
    return solid(color, 0.3, 0.0, 0.4)


def veined_marble(color):
    """Mármore polido de veios finos: o claro continua claro sob a luz quente."""
    key = ("veined_marble", color)
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("Veios_" + color)
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 3.2
        noise.inputs["Detail"].default_value = 6.0
        noise.inputs["Distortion"].default_value = 1.6
        links.new(M._coords(nodes, 1.0), noise.inputs["Vector"])
        # O veio é a linha onde o ruído passa pelo meio: |ruído - 0,5| perto de zero.
        offset = nodes.new("ShaderNodeMath")
        offset.operation = "SUBTRACT"
        offset.inputs[1].default_value = 0.5
        links.new(noise.outputs["Fac"], offset.inputs[0])
        absolute = nodes.new("ShaderNodeMath")
        absolute.operation = "ABSOLUTE"
        links.new(offset.outputs[0], absolute.inputs[0])
        links.new(M._ramp(nodes, links, absolute.outputs[0], M._shade(color, 0.3), color, (0.0, 0.018)), bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.14
        bsdf.inputs["Coat Weight"].default_value = 0.6
        M._materials[key] = mat
    return M._materials[key]


# --- Peças ----------------------------------------------------------------------------------------------------

def lathe(profile, mat, center=(0.0, 0.0), vertices=48):
    """Peça torneada: gira o perfil [(raio, altura)...] em torno do eixo vertical. Raio 0 fecha a peça."""
    bm = bmesh.new()
    rings = []
    for radius, z in profile:
        if radius <= 0.0:
            rings.append([bm.verts.new((center[0], center[1], z))])
            continue
        rings.append([bm.verts.new((center[0] + math.cos(2 * math.pi * i / vertices) * radius,
                                    center[1] + math.sin(2 * math.pi * i / vertices) * radius, z)) for i in range(vertices)])
    for low, high in zip(rings, rings[1:]):
        for i in range(vertices):
            a, b = i, (i + 1) % vertices
            if len(low) == 1:
                bm.faces.new((low[0], high[a], high[b]))
            elif len(high) == 1:
                bm.faces.new((low[a], low[b], high[0]))
            else:
                bm.faces.new((low[a], low[b], high[b], high[a]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("Torneada")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Torneada", mesh)
    bpy.context.scene.collection.objects.link(obj)
    return M._finish(obj, mat)


def trumpet(z_top, base_radius, neck, mat, center=(0.0, 0.0)):
    """Pé de tulipa: a base larga sobe numa curva até o pescoço fino."""
    profile = [(0.0, 0.0), (base_radius, 0.0), (base_radius, 0.012)]
    for i in range(1, 11):
        t = i / 10
        profile.append((neck + (base_radius - neck) * (1 - t) ** 3, 0.012 + (z_top - 0.012) * t))
    profile.append((0.0, z_top))
    return lathe(profile, mat, center)


def draped(outline, z_top, drop, mat, flare=0.035, folds=14, fold_depth=0.016):
    """Toalha caindo: o [outline](ângulo) dá a borda do tampo; a saia abre e faz dobras cada vez mais fundas."""
    steps, rows = 112, 8
    bm = bmesh.new()
    middle = bm.verts.new((0.0, 0.0, z_top))
    rings = []
    for j in range(rows + 1):
        t = j / rows
        ring = []
        for i in range(steps):
            angle = 2 * math.pi * i / steps
            radius = outline(angle) + flare * t + fold_depth * t * math.sin(folds * angle)
            z = z_top - 0.008 - drop * t
            ring.append(bm.verts.new((math.cos(angle) * radius, math.sin(angle) * radius, z)))
        rings.append(ring)
    for i in range(steps):
        bm.faces.new((middle, rings[0][i], rings[0][(i + 1) % steps]))
    for low, high in zip(rings, rings[1:]):
        for i in range(steps):
            b = (i + 1) % steps
            bm.faces.new((low[i], low[b], high[b], high[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("Toalha")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Toalha", mesh)
    bpy.context.scene.collection.objects.link(obj)
    solid_mod = obj.modifiers.new("Espessura", "SOLIDIFY")
    solid_mod.thickness = 0.008
    return M._finish(obj, mat)


def round_outline(radius):
    return lambda angle: radius


def square_outline(half):
    """Quadrado de cantos arredondados, visto do centro."""
    return lambda angle: half / (abs(math.cos(angle)) ** 8 + abs(math.sin(angle)) ** 8) ** 0.125


def shell(size, center, mat, cut=-0.05, thickness=0.03):
    """Casca moldada (ovo, tulipa, escandinava): cortada por um plano inclinado, que recua em cima e avança embaixo do
    assento, com a borda limpa."""
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, location=(0, 0, 0), rotation=(math.radians(90), 0, 0), segments=64, ring_count=32)
    obj = bpy.context.active_object
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(0.0, cut, 0.0), plane_no=(0.0, 1.0, -SHELL_TILT), clear_inner=True)
    bm.to_mesh(obj.data)
    bm.free()
    obj.scale = size
    obj.location = center
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    solid_mod = obj.modifiers.new("Espessura", "SOLIDIFY")
    solid_mod.thickness = thickness
    return M._finish(obj, mat)


def _wrapped(angle, wrap=BACK_WRAP):
    return 90.0 + (angle - 90.0) * wrap


def _arc_point(angle, radius=BACK_RADIUS, wrap=BACK_WRAP):
    rad = math.radians(_wrapped(angle, wrap))
    return BACK_CENTER[0] + math.cos(rad) * radius, BACK_CENTER[1] + math.sin(rad) * radius


def rail(mat, z0, z1, a0=30, a1=150, thick=0.045, radius=BACK_RADIUS, bevel=0.012, wrap=BACK_WRAP):
    return arc_band(radius, thick, z0, z1, _wrapped(a0, wrap), _wrapped(a1, wrap), mat, BACK_CENTER, bevel=bevel)


def posts(mat, top=BACK_TOP, angles=(30, 150), radius=0.02, wrap=BACK_WRAP):
    pieces = []
    for angle in angles:
        x, y = _arc_point(angle, BACK_RADIUS - 0.02, wrap)
        pieces.append(tube((x, y, SEAT_Z), (x, y, top), radius, mat))
    return pieces


def spindles(mat, count, z0, z1, a0=48, a1=132, radius=0.012):
    pieces = []
    for i in range(count):
        x, y = _arc_point(a0 + (a1 - a0) * i / (count - 1), BACK_RADIUS - 0.02)
        pieces.append(tube((x, y, z0), (x, y, z1), radius, mat))
    return pieces


def wood_frame(mat):
    """Pés torneados, mais finos embaixo, e a caixa do assento."""
    parts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(taper((sx * (HALF - 0.015), sy * (HALF - 0.015), 0.0), (sx * (HALF - 0.055), sy * (HALF - 0.055), SEAT_Z),
                               0.018, 0.034, mat))
    parts.append(box((2 * HALF, 2 * HALF, 0.05), (0.0, 0.0, SEAT_Z), mat, 0.012))
    return parts


def tube_frame(mat, radius=0.017, plate=None):
    """Tubo de metal: pés abertos embaixo, travessa e a chapa do assento."""
    parts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(tube((sx * (HALF + 0.005), sy * (HALF + 0.005), 0.012), (sx * (HALF - 0.06), sy * (HALF - 0.06), SEAT_Z),
                              radius, mat))
            parts.append(sphere(radius * 1.25, (sx * (HALF + 0.005), sy * (HALF + 0.005), 0.012), mat, (1, 1, 0.7)))
    for sy in (-1, 1):
        parts.append(tube((-(HALF - 0.025), sy * (HALF - 0.025), 0.16), (HALF - 0.025, sy * (HALF - 0.025), 0.16), radius * 0.7, mat))
    parts.append(box((2 * HALF - 0.03, 2 * HALF - 0.03, 0.035), (0.0, 0.0, SEAT_Z), plate or mat, 0.01))
    return parts


def dowel_frame(mat, brace):
    """Pés de madeira bem abertos, com a cruz de metal embaixo do assento (cadeira escandinava)."""
    parts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(taper((sx * (HALF + 0.015), sy * (HALF + 0.015), 0.0), (sx * 0.1, sy * 0.1, SEAT_Z), 0.017, 0.028, mat))
            parts.append(tube((sx * 0.21, sy * 0.21, 0.13), (-sx * 0.21, -sy * 0.21, 0.13), 0.006, brace))
    parts.append(box((0.3, 0.3, 0.03), (0.0, 0.0, SEAT_Z + 0.01), mat, 0.01))
    return parts


def round_seat(mat, z0=SEAT_Z, band=None, radius=ROUND_SEAT):
    """Assento redondo fofo, com a cinta de metal opcional."""
    top = SEAT_TOP
    pieces = [lathe([(0.0, z0), (radius - 0.01, z0), (radius, z0 + 0.03), (radius, top - 0.04), (radius - 0.025, top - 0.012),
                     (radius - 0.08, top), (0.0, top + 0.002)], mat)]
    if band is not None:
        pieces.append(lathe([(radius + 0.006, z0 + 0.012), (radius + 0.006, z0 + 0.055)], band))
    return pieces


def square_seat(mat):
    return cushion(HALF - 0.005, SEAT_Z + 0.02, SEAT_TOP, mat)


def bow(color):
    """Laço de festa nas costas da cadeira."""
    mat = solid(color, 0.55)
    x, y = _arc_point(90, BACK_RADIUS + 0.012)
    z = BACK_TOP - 0.08
    return [sphere(0.05, (x - 0.058, y, z), mat, (1.25, 0.35, 0.8)), sphere(0.05, (x + 0.058, y, z), mat, (1.25, 0.35, 0.8)),
            sphere(0.02, (x, y + 0.004, z), mat), box((0.028, 0.008, 0.12), (x - 0.03, y, z - 0.08), mat, 0.003),
            box((0.028, 0.008, 0.12), (x + 0.03, y, z - 0.08), mat, 0.003)]


def painted_flowers(y_sign):
    """Flores pintadas no encosto: três de cada lado, para aparecerem de frente e de costas."""
    pieces = []
    for angle, z, color in [(68, 0.56, "#d8344a"), (112, 0.56, "#d8344a"), (90, 0.635, "#f8f1e4")]:
        radius = BACK_RADIUS + 0.003 if y_sign > 0 else BACK_RADIUS - 0.048
        x, y = _arc_point(angle, radius)
        for petal in range(0, 360, 72):
            pieces.append(sphere(0.017, (x + math.cos(math.radians(petal)) * 0.024, y, z + math.sin(math.radians(petal)) * 0.024),
                                 solid(color, 0.45), (1, 0.35, 1)))
        pieces.append(sphere(0.012, (x, y, z), solid("#e7b63a", 0.45), (1, 0.35, 1)))
    return pieces


def bamboo(a, b, radius, mat, node_mat):
    """Vara de bambu: o tubo com os nós."""
    pieces = [tube(a, b, radius, mat)]
    for t in (0.33, 0.66):
        center = tuple(a[i] + (b[i] - a[i]) * t for i in range(3))
        pieces.append(sphere(radius * 1.2, center, node_mat, (1, 1, 0.42)))
    return pieces


# --- Cadeiras: cada uma devolve (peças, peças do encosto) --------------------------------------------------------

def egg_chair():
    egg = solid("#d9702b", 0.35, 0.0, 0.5)
    parts = [trumpet(SEAT_Z, 0.2, 0.035, painted("#efe8d6"))] + round_seat(leather("#e98a3c"))
    return parts, [shell((0.33, 0.31, 0.29), (0.0, -0.03, 0.46), egg, cut=-0.3, thickness=0.035)]


def tulip_chair():
    parts = [trumpet(SEAT_Z, 0.19, 0.03, painted("#f4efe4"))] + round_seat(leather("#f1e8d8"))
    return parts, [shell((0.27, 0.25, 0.2), (0.0, -0.02, 0.44), solid("#e27d33", 0.35, 0.0, 0.5), cut=-0.05)]


def ladder_chair(frame_color, seat_color):
    wood = rich_wood(frame_color, 9.0, 0.3)
    back = posts(wood, BACK_TOP + 0.01, radius=0.022)
    for i, z in enumerate((0.5, 0.58, 0.66)):
        back.append(rail(wood, z, z + 0.05 + i * 0.006, 34, 146, 0.03))
    for x_angle in (30, 150):
        x, y = _arc_point(x_angle, BACK_RADIUS - 0.02)
        back.append(sphere(0.026, (x, y, BACK_TOP + 0.02), wood))
    return wood_frame(wood) + [square_seat(M.weave(seat_color))], back


def plank_chair(frame_color, seat_color):
    """Cadeira de ripas: assento de tábuas e ripas largas no encosto."""
    wood = rich_wood(frame_color, 9.0, 0.3)
    seat = rich_wood(seat_color, 8.0, 0.3)
    parts = wood_frame(wood)
    for i in range(4):
        parts.append(box((2 * HALF - 0.01, (2 * HALF - 0.03) / 4, SEAT_TOP - SEAT_Z - 0.02),
                         (0.0, -HALF + 0.01 + (i + 0.5) * (2 * HALF - 0.02) / 4, (SEAT_TOP + SEAT_Z + 0.03) / 2), seat, 0.009))
    back = posts(wood, BACK_TOP, radius=0.024) + [rail(wood, BACK_TOP - 0.055, BACK_TOP, 26, 154, 0.05)]
    for angle in (58, 90, 122):
        back.append(rail(wood, SEAT_TOP + 0.04, BACK_TOP - 0.05, angle - 8, angle + 8, 0.028, bevel=0.006))
    back.append(rail(wood, SEAT_TOP + 0.02, SEAT_TOP + 0.06, 30, 150, 0.04))
    return parts, back


def party_chair(frame_color, pad_color, bow_color=None):
    """Cadeira de festa: armação fina pintada, varetas e almofada."""
    frame = painted(frame_color)
    parts = wood_frame(frame) + [cushion(HALF - 0.012, SEAT_Z + 0.02, SEAT_TOP, solid(pad_color, 0.7))]
    back = posts(frame, BACK_TOP, radius=0.016) + [rail(frame, BACK_TOP - 0.04, BACK_TOP, 28, 152, 0.035),
                                                   rail(frame, SEAT_TOP + 0.07, SEAT_TOP + 0.1, 30, 150, 0.03)]
    back += spindles(frame, 5, SEAT_TOP + 0.09, BACK_TOP - 0.03)
    if bow_color:
        back += bow(bow_color)
    return parts, back


def mexican_chair():
    frame = painted("#2b63c2")
    panel = painted("#e9b533")
    parts = wood_frame(frame) + [square_seat(M.weave("#2d9a63"))]
    back = posts(frame, BACK_TOP, radius=0.022) + [rail(panel, 0.5, BACK_TOP - 0.018, 34, 146, 0.05),
                                                  rail(frame, BACK_TOP - 0.03, BACK_TOP, 30, 150, 0.06)]
    return parts, back + painted_flowers(1) + painted_flowers(-1)


def neon_chair(frame_color, shell_color, seat_color):
    """Cadeira dos anos 80: casca colorida e brilhante sobre tubos da outra cor."""
    frame = solid(frame_color, 0.22, 0.0, 0.7)
    parts = dowel_frame(frame, frame) + round_seat(solid(seat_color, 0.22, 0.0, 0.7), SEAT_Z + 0.02)
    return parts, [shell((0.27, 0.25, 0.2), (0.0, -0.02, 0.44), solid(shell_color, 0.22, 0.0, 0.7), cut=-0.05)]


def cantina_chair(frame_color, seat_color):
    wood = rich_wood(frame_color, 9.0, 0.45)
    parts = wood_frame(wood) + [square_seat(leather(seat_color))]
    back = posts(wood, BACK_TOP, radius=0.022) + [rail(wood, BACK_TOP - 0.07, BACK_TOP, 26, 154, 0.05),
                                                  rail(wood, SEAT_TOP + 0.05, SEAT_TOP + 0.09, 30, 150, 0.035)]
    return parts, back + spindles(wood, 5, SEAT_TOP + 0.08, BACK_TOP - 0.06, radius=0.014)


def cane_chair(frame_color, cane_color, seat):
    """Cadeira de palhinha: a armação de madeira com a tela de palha no encosto."""
    wood = rich_wood(frame_color, 9.0, 0.45)
    parts = wood_frame(wood) + [square_seat(seat)]
    back = posts(wood, BACK_TOP, radius=0.021) + [rail(wood, BACK_TOP - 0.04, BACK_TOP, 28, 152, 0.05),
                                                  rail(wood, SEAT_TOP + 0.05, SEAT_TOP + 0.085, 30, 150, 0.04),
                                                  rail(M.weave(cane_color), SEAT_TOP + 0.08, BACK_TOP - 0.035, 36, 144, 0.018, bevel=0.002)]
    return parts, back


def bamboo_chair():
    stalk = solid("#c9a968", 0.4, 0.0, 0.35)
    node = solid("#8f7238", 0.5)
    parts = [box((2 * HALF - 0.02, 2 * HALF - 0.02, 0.04), (0.0, 0.0, SEAT_Z), stalk, 0.012), square_seat(upholstery("#a93a30"))]
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts += bamboo((sx * (HALF - 0.025), sy * (HALF - 0.025), 0.0), (sx * (HALF - 0.04), sy * (HALF - 0.04), SEAT_Z), 0.024, stalk, node)
    back = []
    for angle in (30, 150):
        x, y = _arc_point(angle, BACK_RADIUS - 0.02)
        back += bamboo((x, y, SEAT_Z), (x, y, BACK_TOP), 0.022, stalk, node)
    back += [rail(stalk, BACK_TOP - 0.035, BACK_TOP, 28, 152, 0.04),
             rail(M.weave("#d9bd80"), SEAT_TOP + 0.06, BACK_TOP - 0.03, 36, 144, 0.018, bevel=0.002)]
    return parts, back


def rattan_chair(leg_color, weave_color, seat_color, arms=False):
    """Cadeira de bistrô de Paris: o rattan abraça quem senta e o assento é trançado."""
    rattan = M.weave(weave_color)
    trim = rich_wood(M._shade(weave_color, 0.25), 8.0, 0.4)
    legs = rich_wood(leg_color, 9.0, 0.4)
    parts = wood_frame(legs) + [square_seat(M.weave(seat_color))]
    a0, a1 = (6, 174) if arms else (24, 156)
    back = [rail(rattan, SEAT_TOP - 0.02, BACK_TOP - 0.02, a0, a1, 0.04, wrap=1.0),
            rail(trim, BACK_TOP - 0.03, BACK_TOP + 0.008, a0 - 2, a1 + 2, 0.052, bevel=0.018, wrap=1.0)]
    back += posts(trim, BACK_TOP, (a0 + 2, a1 - 2), 0.018, wrap=1.0)
    return parts, back


def panel_chair(frame_color, panel_color, seat_color):
    """Madeira e encosto curvo pintado."""
    wood = rich_wood(frame_color, 9.0, 0.4)
    panel = painted(panel_color)
    parts = wood_frame(wood) + [square_seat(upholstery(seat_color))]
    back = posts(wood, BACK_TOP - 0.03, radius=0.021) + [rail(panel, SEAT_TOP + 0.08, BACK_TOP, 34, 146, 0.05, bevel=0.018)]
    return parts, back


def scandi_chair():
    oak = rich_wood(OAK, 9.0, 0.25)
    cover = solid("#f2eee6", 0.42, 0.0, 0.2)
    parts = dowel_frame(oak, cast_iron("#2a2b30")) + round_seat(cover, SEAT_Z + 0.02)
    return parts, [shell((0.27, 0.25, 0.2), (0.0, -0.02, 0.44), cover, cut=-0.05)]


def diner_chair():
    chrome = chrome_a()
    parts = tube_frame(chrome, plate=chrome) + [square_seat(vinyl("#c8283a"))]
    parts.append(box((2 * HALF + 0.006, 2 * HALF + 0.006, 0.024), (0.0, 0.0, SEAT_Z + 0.03), chrome, 0.006))
    back = posts(chrome, BACK_TOP - 0.02) + [rail(vinyl("#f4efe6"), SEAT_TOP + 0.1, BACK_TOP, 38, 142, 0.06, bevel=0.024)]
    return parts, back


def equipal_chair():
    """Equipal mexicana: o tambor de ripas cruzadas embaixo e o couro cru em barril."""
    hide = leather("#b77a42")
    lath = M.weave("#a3703e")
    parts = [lathe([(0.0, 0.0), (0.28, 0.0), (0.24, 0.1), (0.24, SEAT_Z - 0.03), (0.28, SEAT_Z), (0.0, SEAT_Z)], lath),
             lathe([(0.295, 0.0), (0.295, 0.035), (0.0, 0.035)], rich_wood("#6f4426", 7.0, 0.3))]
    parts += round_seat(hide, radius=0.285)
    back = [rail(hide, SEAT_TOP - 0.03, BACK_TOP - 0.02, 10, 170, 0.05, wrap=1.0),
            rail(rich_wood("#6f4426", 7.0, 0.3), BACK_TOP - 0.03, BACK_TOP + 0.01, 8, 172, 0.06, bevel=0.018, wrap=1.0)]
    return parts, back


def club_chair():
    """Poltrona de veludo: cuba capitonê sobre pés de metal dourado."""
    cover = velvet("#5e2aa3")
    metal = gold()
    parts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(taper((sx * (HALF - 0.03), sy * (HALF - 0.03), 0.0), (sx * (HALF - 0.08), sy * (HALF - 0.08), SEAT_Z - 0.02), 0.012, 0.024, metal))
    parts.append(box((2 * HALF, 2 * HALF, 0.06), (0.0, 0.0, SEAT_Z), velvet("#44207a"), 0.016))
    parts.append(square_seat(cover))
    back = [rail(cover, SEAT_TOP - 0.03, BACK_TOP - 0.01, 2, 178, 0.075, bevel=0.03, wrap=1.0)]
    for angle, z in [(62, 0.52), (90, 0.52), (118, 0.52), (76, 0.62), (104, 0.62)]:
        x, y = _arc_point(angle, BACK_RADIUS - 0.078)
        back.append(sphere(0.012, (x, y, z), velvet("#34165e")))
    return parts, back


def pedestal_stool(column, seat, band=None):
    parts = [lathe([(0.0, 0.0), (0.14, 0.0), (0.14, 0.014), (0.055, 0.036), (0.024, 0.08), (0.024, SEAT_Z), (0.0, SEAT_Z)], column)]
    return parts + round_seat(seat, band=band, radius=STOOL_SEAT), []


def diner_stool():
    chrome = chrome_a()
    parts, back = pedestal_stool(chrome, vinyl("#c8283a"), chrome)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.11, minor_radius=0.008, location=(0.0, 0.0, 0.17), major_segments=48, minor_segments=8)
    parts.append(M._finish(bpy.context.active_object, chrome))
    for angle in (45, 135, 225, 315):
        rad = math.radians(angle)
        parts.append(tube((0.0, 0.0, 0.17), (math.cos(rad) * 0.11, math.sin(rad) * 0.11, 0.17), 0.005, chrome))
    return parts, back


def zen_stool():
    wood = rich_wood("#b98f58", 8.0, 0.25)
    parts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(box((0.045, 0.045, SEAT_Z), (sx * 0.15, sy * 0.15, SEAT_Z / 2), wood, 0.008))
    parts.append(box((0.38, 0.38, 0.05), (0.0, 0.0, SEAT_Z), wood, 0.012))
    parts.append(cushion(0.18, SEAT_Z + 0.02, SEAT_TOP, solid("#b93a32", 0.75), 0.022))
    for sx, sy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        parts.append(box((0.3 if sy != 0 else 0.024, 0.024 if sy != 0 else 0.3, 0.024), (sx * 0.15, sy * 0.15, 0.12), wood, 0.004))
    return parts, []


def industrial_stool():
    iron = cast_iron("#35373f")
    parts = []
    for angle in (90, 210, 330):
        rad = math.radians(angle)
        parts.append(tube((math.cos(rad) * 0.22, math.sin(rad) * 0.22, 0.0), (math.cos(rad) * 0.08, math.sin(rad) * 0.08, SEAT_Z), 0.016, iron))
    bpy.ops.mesh.primitive_torus_add(major_radius=0.155, minor_radius=0.008, location=(0.0, 0.0, 0.15), major_segments=48, minor_segments=8)
    parts.append(M._finish(bpy.context.active_object, iron))
    parts.append(cylinder(STOOL_SEAT, SEAT_TOP - 0.055, SEAT_TOP, grain_wood("#a56c3a", 0.4), bevel=0.012))
    parts.append(cylinder(0.1, SEAT_TOP - 0.08, SEAT_TOP - 0.05, iron, bevel=0.006))
    return parts, []


CHAIRS = {
    "chair_70s": egg_chair,
    "chair_tulip": tulip_chair,
    "chair_country": lambda: ladder_chair("#9b6535", "#c79a5d"),
    "bench_country": lambda: plank_chair("#6e4324", "#b98450"),
    "chair_party": lambda: party_chair("#f6f0ea", "#d98aa5"),
    "chair_party_blue": lambda: party_chair("#f6f0ea", "#86b3d3", "#5a8fc0"),
    "stool_diner": diner_stool,
    "chair_diner": diner_chair,
    "chair_mexican": mexican_chair,
    "chair_equipal": equipal_chair,
    "chair_80s": lambda: neon_chair("#34c2e0", "#34c2e0", "#e23bb8"),
    "chair_80s_pink": lambda: neon_chair("#e23bb8", "#e23bb8", "#34c2e0"),
    "chair_italian": lambda: cantina_chair("#54301c", "#a2342b"),
    "chair_tuscan": lambda: cane_chair("#5e3519", "#d3b377", upholstery("#34683f")),
    "chair_japanese": bamboo_chair,
    "stool_zen": zen_stool,
    "chair_french": lambda: rattan_chair("#8d6236", "#cfad74", "#3760c4"),
    "chair_french_red": lambda: rattan_chair("#2c2a33", "#c2a06a", "#b81f36", arms=True),
    "chair_brazil": lambda: cane_chair(ROSEWOOD, "#e2c48a", upholstery("#c99a2e")),
    "chair_brazil_flag": lambda: panel_chair("#8a5a30", "#cf9f2f", "#2f7d45"),
    "chair_2010s": scandi_chair,
    "stool_industrial": industrial_stool,
    "chair_club": club_chair,
    "stool_club": lambda: pedestal_stool(gold(), velvet("#5e2aa3"), gold()),
}


# --- Mesas ----------------------------------------------------------------------------------------------------

def _top_material(kind, color):
    return {"wood": lambda: grain_wood(color), "marble": lambda: veined_marble(color), "laminate": lambda: laminate(color),
            "dark": lambda: solid(color, 0.1, 0.0, 1.0), "mirror": mirror_glass}[kind]()


def _edge_material(edge):
    kind, color = edge
    return {"wood": lambda: rich_wood(color, 5.0, 0.4), "paint": lambda: solid(color, 0.35, 0.0, 0.4), "chrome": chrome_a,
            "gold": gold, "iron": lambda: cast_iron(color)}[kind]()


def round_top(h, kind, color, edge, ribbed=False):
    """Tampo redondo grosso, com a borda torneada por baixo."""
    r = TABLE_RADIUS
    t = TABLE_THICK
    parts = [cylinder(r, h - t, h, _top_material(kind, color), bevel=0.012, vertices=72),
             cylinder(r - 0.04, h - t - 0.035, h - t, _edge_material(edge), bevel=0.012, vertices=72)]
    if ribbed:   # a cinta canelada do cromo de lanchonete
        for z in (h - 0.012, h - 0.024, h - 0.036):
            parts.append(lathe([(r + 0.003, z - 0.004), (r + 0.006, z), (r + 0.003, z + 0.004)], _edge_material(edge), vertices=72))
    return parts


def square_top(h, kind, color, edge, width=1.0, ribbed=False):
    """Tampo quadrado grosso sobre a saia de madeira ou metal."""
    w, d = width * TABLE_SIDE + (width - 1) * 0.06, TABLE_SIDE
    t = TABLE_THICK
    parts = [box((w, d, t), (0.0, 0.0, h - t / 2), _top_material(kind, color), 0.012),
             box((w - 0.08, d - 0.08, 0.05), (0.0, 0.0, h - t - 0.025), _edge_material(edge), 0.008)]
    if ribbed:
        parts.append(box((w + 0.012, d + 0.012, 0.03), (0.0, 0.0, h - 0.024), _edge_material(edge), 0.006))
        parts.append(box((w + 0.004, d + 0.004, 0.012), (0.0, 0.0, h - 0.005), _top_material(kind, color), 0.003))   # 1 mm acima: faces na mesma altura saem pretas
    return parts


def tripod_base(h, mat):
    """O pé de ferro de três pernas, da mesa da amostra."""
    parts = [cylinder(0.05, 0.11, h - 0.08, mat, bevel=0.006), cylinder(0.085, h - 0.12, h - 0.085, mat, bevel=0.01),
             cylinder(0.09, 0.09, 0.15, mat, bevel=0.018)]
    for angle in (90, 210, 330):
        rad = math.radians(angle)
        foot = (math.cos(rad) * 0.31, math.sin(rad) * 0.31)
        parts.append(tube((math.cos(rad) * 0.05, math.sin(rad) * 0.05, 0.12), (foot[0], foot[1], 0.025), 0.026, mat))
        parts.append(sphere(0.035, (foot[0], foot[1], 0.025), mat, (1.0, 1.0, 0.6)))
    return parts


def trumpet_base(h, mat):
    return [trumpet(h - TABLE_THICK - 0.03, 0.25, 0.04, mat)]


def column_base(h, mat):
    """Coluna de lanchonete: o disco no chão, o cone e o tubo."""
    z = h - TABLE_THICK - 0.03
    return [lathe([(0.0, 0.0), (0.23, 0.0), (0.23, 0.016), (0.1, 0.045), (0.05, 0.09), (0.045, z - 0.02), (0.09, z), (0.0, z)], mat)]


def turned_legs(h, mat, spread=0.38):
    parts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(taper((sx * spread, sy * spread, 0.0), (sx * spread, sy * spread, h - TABLE_THICK - 0.02), 0.022, 0.042, mat))
    return parts


def block_legs(h, mat, spread=0.36):
    """Pernas retas e largas, de marcenaria japonesa."""
    parts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(box((0.085, 0.085, h - TABLE_THICK), (sx * spread, sy * spread, (h - TABLE_THICK) / 2), mat, 0.008))
    return parts


def hairpin_legs(h, mat, spread=0.38):
    """Pernas de grampo, de ferro fino."""
    parts = []
    z = h - TABLE_THICK - 0.02
    for sx in (-1, 1):
        for sy in (-1, 1):
            for dx, dy in ((0.07, 0.0), (0.0, 0.07)):
                parts.append(tube((sx * spread, sy * spread, 0.0), (sx * (spread - dx), sy * (spread - dy), z), 0.012, mat))
    return parts


def bud_vase(h, flowers):
    """Vasinho de cerâmica com duas flores, no meio da mesa (o prato cai ao lado)."""
    z = h
    pieces = [lathe([(0.0, z), (0.026, z), (0.036, z + 0.03), (0.03, z + 0.07), (0.014, z + 0.09), (0.018, z + 0.105), (0.0, z + 0.1)], solid("#ece4d4", 0.3, 0.0, 0.5)),
              tube((0.0, 0.0, z + 0.09), (-0.012, 0.0, z + 0.165), 0.0035, solid("#3f7a3c", 0.6)),
              tube((0.0, 0.0, z + 0.09), (0.022, 0.012, z + 0.14), 0.0035, solid("#3f7a3c", 0.6)),
              sphere(0.03, (-0.012, 0.0, z + 0.175), solid(flowers[0], 0.6)),
              sphere(0.024, (0.024, 0.014, z + 0.148), solid(flowers[1], 0.6))]
    return pieces


def candle_jar(h):
    return [cylinder(0.04, h, h + 0.075, E.glass("#ffd9a0", 0.25), bevel=0.006),
            sphere(0.016, (0.0, 0.0, h + 0.05), emission("#ffb24d", 16.0), (1, 1, 1.5))]


def wine_candle(h):
    """A garrafa de cantina com a vela."""
    z = h
    bottle = solid("#24512c", 0.12, 0.0, 1.0)
    return [lathe([(0.0, z), (0.04, z), (0.046, z + 0.015), (0.046, z + 0.075), (0.016, z + 0.115), (0.015, z + 0.15), (0.0, z + 0.15)], bottle),
            lathe([(0.048, z + 0.002), (0.05, z + 0.03), (0.042, z + 0.052)], M.weave("#c79a5d")),
            cylinder(0.012, z + 0.15, z + 0.21, solid("#f8efd5", 0.6)),
            sphere(0.012, (0.0, 0.0, z + 0.23), emission("#ffb13d", 30.0), (1, 1, 1.8))]


def memphis_marks(h):
    return [sphere(0.05, (u, v, h + 0.001), solid(color, 0.3), (1, 1, 0.05)) for u, v, color in
            [(-0.2, 0.08, "#e23bb8"), (0.22, -0.08, "#34c2e0"), (0.05, 0.27, "#2a2d6e"), (-0.08, -0.26, "#e8bd38"), (0.28, 0.17, "#e8bd38")]]


def talavera_inlay(h):
    """Azulejos de Talavera, um a um: branco vitrificado, losango azul e miolo amarelo."""
    glaze = solid("#f4eee0", 0.14, 0.0, 0.8)
    cobalt = solid("#234fa8", 0.2, 0.0, 0.6)
    yolk = solid("#e0a92e", 0.25, 0.0, 0.5)
    count = 5
    side = (TABLE_SIDE - 0.1) / count
    pieces = [box((TABLE_SIDE - 0.08, TABLE_SIDE - 0.08, 0.004), (0.0, 0.0, h + 0.0015), solid("#3c2a1c", 0.7), 0.0)]
    for i in range(count):
        for j in range(count):
            x, y = (i - (count - 1) / 2) * side, (j - (count - 1) / 2) * side
            pieces.append(box((side - 0.007, side - 0.007, 0.006), (x, y, h + 0.005), glaze, 0.001))
            diamond = box((side * 0.5, side * 0.5, 0.002), (x, y, h + 0.0085), cobalt, 0.0)
            diamond.rotation_euler = (0.0, 0.0, math.radians(45))
            pieces.append(diamond)
            pieces.append(sphere(side * 0.13, (x, y, h + 0.0095), yolk, (1, 1, 0.1)))
    return pieces


def gingham_runner(h, color):
    """Caminho de xadrez sobre a madeira."""
    return [box((TABLE_SIDE + 0.016, 0.34, 0.006), (0.0, 0.0, h + 0.001), M.fabric("gingham", color), 0.002)]


def neon_round(h):
    return [M._ring(TABLE_RADIUS - 0.04, 0.008, h + 0.002, emission("#34c2e0", 6.0)),
            M._ring(TABLE_RADIUS - 0.012, 0.008, h - 0.046, emission("#e23bb8", 6.0))]


def neon_square(h, inner=True):
    side = TABLE_SIDE - 0.08
    rings = M._rect_ring(side, side, h + 0.003, emission("#34c2e0", 6.0))
    if inner:
        rings += M._rect_ring(side - 0.16, side - 0.16, h + 0.003, emission("#e23bb8", 6.0))
    return rings


def mirror_grid(h):
    """As juntas douradas entre os espelhos."""
    side = TABLE_SIDE - 0.06
    return [box((side, 0.008, 0.004), (0.0, 0.0, h + 0.001), gold(), 0.0), box((0.008, side, 0.004), (0.0, 0.0, h + 0.001), gold(), 0.0)]


def cloth_table(h, shape, kind, color, legs):
    outline = round_outline(TABLE_RADIUS) if shape == "round" else square_outline(TABLE_SIDE / 2)
    drop = h * 0.5
    mat = M.fabric(kind, color)
    return [draped(outline, h, drop, mat), legs]


def long_table(h):
    """Mesa longa: tábua grossa e dois pés de ferro."""
    iron = cast_iron()
    parts = square_top(h, "wood", HONEY, ("wood", WALNUT), width=2.0)
    for x in (-0.5, 0.5):
        parts.append(_offset(tripod_base(h, iron), x))
    parts.append(tube((-0.5, 0.0, 0.22), (0.5, 0.0, 0.22), 0.016, iron))
    return parts + candle_jar(h)


def _offset(objects, x):
    for obj in M._flatten(objects):
        obj.location.x += x
    return objects


def wood_mat(color):
    return rich_wood(color, 8.0, 0.35)


def paint_mat(color):
    return solid(color, 0.3, 0.0, 0.5)


TABLES = {
    "table_long": long_table,
    "table_70s": lambda h: round_top(h, "laminate", "#e8792e", ("paint", "#b85a1e")) + trumpet_base(h, paint_mat("#efe8d6")) + bud_vase(h, ("#efe2bd", "#e7b63a")),
    "table_70s_square": lambda h: square_top(h, "laminate", "#e3a634", ("chrome", ""), ribbed=True) + hairpin_legs(h, chrome_a()) + bud_vase(h, ("#d8344a", "#efe2bd")),
    "table_country": lambda h: square_top(h, "wood", "#a96c38", ("wood", "#744725")) + turned_legs(h, wood_mat("#744725")) + gingham_runner(h, "#c8343a") + bud_vase(h, ("#e8bd38", "#f8f1e4")),
    "table_country_round": lambda h: cloth_table(h, "round", "gingham", "#3760c4", tripod_base(h, wood_mat(WALNUT))) + bud_vase(h, ("#e8bd38", "#f8f1e4")),
    "table_party": lambda h: cloth_table(h, "round", "confetti", "#fff0f6", trumpet_base(h, paint_mat("#f6f0ea"))) + bud_vase(h, ("#e23f63", "#4aa9e8")),
    "table_party_square": lambda h: cloth_table(h, "square", "confetti", "#e8f6ff", turned_legs(h, paint_mat("#f6f0ea"))) + bud_vase(h, ("#e23f63", "#e8bd38")),
    "table_diner": lambda h: square_top(h, "laminate", "#f5f1e8", ("paint", "#3fb8ad"), ribbed=True) + column_base(h, chrome_a()) + bud_vase(h, ("#d8344a", "#e8bd38")),
    "table_diner_round": lambda h: round_top(h, "laminate", "#c8283a", ("chrome", ""), ribbed=True) + column_base(h, chrome_a()) + bud_vase(h, ("#f8f1e4", "#e8bd38")),
    "table_mexican": lambda h: square_top(h, "wood", "#6e4426", ("wood", "#4c2d18")) + turned_legs(h, wood_mat("#4c2d18")) + talavera_inlay(h),
    "table_mexican_round": lambda h: cloth_table(h, "round", "plain", "#e56a24", tripod_base(h, wood_mat(WALNUT))) + bud_vase(h, ("#e23f83", "#e8bd38")),
    "table_80s": lambda h: round_top(h, "laminate", "#f5f1e8", ("paint", "#2a2d6e")) + column_base(h, paint_mat("#e23bb8")) + memphis_marks(h),
    "table_80s_square": lambda h: square_top(h, "dark", "#17172a", ("paint", "#e23bb8")) + hairpin_legs(h, paint_mat("#34c2e0")) + neon_square(h),
    "table_italian": lambda h: cloth_table(h, "square", "gingham", "#c8343a", turned_legs(h, wood_mat("#54301c"))) + wine_candle(h),
    "table_italian_round": lambda h: cloth_table(h, "round", "plain", "#f4efe4", tripod_base(h, wood_mat("#54301c"))) + wine_candle(h),
    "table_japanese": lambda h: square_top(h, "wood", "#5f3b1f", ("wood", "#3c2213")) + block_legs(h, wood_mat("#2c1a10")) + bud_vase(h, ("#f0a0b8", "#f8f1e4")),
    "table_japanese_round": lambda h: round_top(h, "wood", "#7a4e2c", ("wood", "#3c2213")) + block_legs(h, wood_mat("#2c1a10"), 0.27) + bud_vase(h, ("#f0a0b8", "#f8f1e4")),
    "table_french": lambda h: round_top(h, "marble", "#efece6", ("iron", "#26272c")) + tripod_base(h, cast_iron()) + candle_jar(h),
    "table_french_square": lambda h: square_top(h, "marble", "#efece6", ("gold", "")) + turned_legs(h, cast_iron("#2a2d3e")) + bud_vase(h, ("#efe2bd", "#d8344a")),
    "table_brazil": lambda h: cloth_table(h, "square", "chita", "#e64f4f", turned_legs(h, wood_mat(WALNUT))) + bud_vase(h, ("#e8bd38", "#e23f83")),
    "table_brazil_round": lambda h: cloth_table(h, "round", "chita", "#2b63c2", tripod_base(h, wood_mat(WALNUT))) + bud_vase(h, ("#e8bd38", "#e23f83")),
    "table_2010s": lambda h: square_top(h, "wood", "#d6b07c", ("wood", "#b48a58")) + hairpin_legs(h, cast_iron("#25262b")) + bud_vase(h, ("#f8f1e4", "#7fbf7a")),
    "table_2010s_round": lambda h: round_top(h, "wood", "#d6b07c", ("paint", "#f2eee6")) + trumpet_base(h, cast_iron("#25262b")) + bud_vase(h, ("#f8f1e4", "#7fbf7a")),
    "table_club": lambda h: round_top(h, "dark", "#17172a", ("iron", "#101016")) + column_base(h, gold()) + neon_round(h) + candle_jar(h),
    "table_club_square": lambda h: square_top(h, "mirror", "", ("gold", "")) + block_legs(h, solid("#17172a", 0.2, 0.0, 0.7), 0.34) + mirror_grid(h) + candle_jar(h),
}


# --- Fotos ----------------------------------------------------------------------------------------------------

def _setup(samples, footprint=(1, 1), shadow=True):
    size = (footprint[0] + SHADOW_MARGIN, footprint[1] + SHADOW_MARGIN) if shadow else 0.01
    center = (footprint[0] / 2, -footprint[1] / 2) if shadow else (0.0, 0.0)
    cena3d.setup(samples, M.IMAGE_SIZE, shadow_center=center, shadow_size=size, rig="a")


def _shoot(name, objects, footprint, rotation, anchors):
    anchor, center = M.assemble(objects, footprint, rotation)
    aim_camera((center[0], center[1], 0.42))
    anchors[name] = cena3d.shoot(name, anchor, WORK)


def render_chair(item_id, manifest, samples, proof, anchors):
    rotations = sorted({int(name.rsplit("_r", 1)[1]) for name in manifest["furniture"][item_id].values()})
    for rotation in ([r for r in rotations if r in (1, 3)] if proof else rotations):
        _setup(samples)
        parts, back = CHAIRS[item_id]()
        _shoot(f"{item_id}_r{rotation}", list(M._flatten(parts + back)), (1, 1), rotation, anchors)
        name = manifest["chair_backrests"][item_id].get(str(rotation), "")
        if name and not proof:
            _setup(samples, shadow=False)
            parts, back = CHAIRS[item_id]()
            for part in M._flatten(parts):   # só o encosto: o assento cobriria quem senta de costas (DT-090)
                bpy.data.objects.remove(part, do_unlink=True)
            _shoot(name, list(M._flatten(back)), (1, 1), rotation, anchors)


def render_table(item_id, manifest, samples, proof, anchors):
    h = _table_height(item_id, manifest)
    footprint = (2, 1) if item_id == "table_long" else (1, 1)
    rotations = sorted({int(name.rsplit("_r", 1)[1]) for name in manifest["furniture"][item_id].values()})
    for rotation in rotations[:1] if proof else rotations:
        _setup(samples, footprint)
        _shoot(f"{item_id}_r{rotation}", list(M._flatten(TABLES[item_id](h))), footprint, rotation, anchors)


def _table_height(item_id, manifest):
    """A altura do tampo vem do manifesto, na proporção da mesa da amostra: o prato continua caindo no tampo."""
    return manifest["table_tops"][item_id] / manifest["table_tops"]["table_round"] * A.TABLE_TOP_Z


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    samples = 24 if "rascunho" in args else 80
    proof = "prova" in args
    wanted = [a for a in args if a in CHAIRS or a in TABLES] or list(CHAIRS) + list(TABLES)
    with open(os.path.join(cena3d.SPRITES, "sprites.json"), encoding="utf-8") as source:
        manifest = json.load(source)
    anchors = {}
    for item_id in wanted:
        (render_chair if item_id in CHAIRS else render_table)(item_id, manifest, samples, proof, anchors)
        cena3d.update_manifest(anchors)   # a cada item: se o próximo falhar, as fotos prontas não perdem a âncora
        print("PRONTO", item_id, flush=True)
    print("ASSENTOS OK", len(anchors), flush=True)


if __name__ == "__main__":
    main()
