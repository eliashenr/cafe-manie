"""Fogões e balcões da loja na linguagem da referência A (DT-094): cada item mantém o nome, a coleção e o caráter, com
modelo novo, a proporção do fogão e do balcão da amostra e a luz quente do salão.

Uso (na pasta do projeto):
    C:/Blender/blender-5.2.3-windows-x64/blender.exe -b -P tools/render3d/cozinha_a3d.py -- [ids...] [rascunho] [prova]

Sem ids, faz todos (menos stove_basic e counter_basic, que são de amostra_a3d.py). "prova" faz só uma vista de cada, para
conferir a forma antes de fazer todos os quadros.

Grava em art/sprites com os mesmos nomes de sprite, então os ids, os preços e o save não mudam. Continuam as medidas de
encaixe: a altura e as bocas do fogão (panela), a janela do forno (o forno aceso é uma foto só, igual para todos) e a
altura e a largura do balcão (pilha de pratos; dois balcões lado a lado formam um só).
"""
import json
import math
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cena3d  # noqa: E402
from cena3d import aim_camera  # noqa: E402
import moveis3d as M  # noqa: E402
from moveis3d import box, cylinder, emission, solid, sphere, tube  # noqa: E402
import amostra_a3d as A  # noqa: E402
from amostra_a3d import brushed_steel, cast_iron, grain_wood, rich_wood, stone_top  # noqa: E402
from assentos_a3d import chrome_a, gold, lathe, mirror_glass, veined_marble  # noqa: E402

WORK = os.path.join(cena3d.ROOT, "tools", "render3d", "out_cozinha")

H = M.STOVE_HEIGHT
W = 0.96                       # as medidas de amostra_a3d.stove_a: o forno aceso e a panela caem no lugar
BODY_D = W - 0.03
FRONT = -BODY_D / 2
BACK_Y = W / 2 - 0.03
WINDOW_W, WINDOW_H, WINDOW_Z = W * 0.56, H * 0.24, H * 0.37
COUNTER_H = M.COUNTER_HEIGHT
COUNTER_W = 1.0 + 2 * A.BLEED  # do tamanho do piso: dois balcões lado a lado formam um só
COUNTER_BODY = COUNTER_W - 0.05
SHADOW_MARGIN = 0.1
TILE_SIDE = 0.15


# --- Materiais ------------------------------------------------------------------------------------------------

def enamel(color):
    """Esmalte de fogão: cor cheia, brilho largo. O verniz fino evita o aspecto de plástico."""
    return solid(color, 0.34, 0.0, 0.45)


def copper():
    key = ("copper",)
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("Cobre")
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 60.0
        noise.inputs["Detail"].default_value = 2.0
        links.new(M._coords(nodes, 1.0), noise.inputs["Vector"])
        links.new(M._ramp(nodes, links, noise.outputs["Fac"], "#bb6f3e", "#cf8449", (0.35, 0.65)), bsdf.inputs["Base Color"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.12   # martelado
        links.new(noise.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
        bsdf.inputs["Metallic"].default_value = 0.65
        bsdf.inputs["Roughness"].default_value = 0.36
        M._materials[key] = mat
    return M._materials[key]


def brick():
    key = ("brick",)
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("TijoloBase")
        tex = nodes.new("ShaderNodeTexBrick")
        tex.inputs["Scale"].default_value = 9.0
        tex.inputs["Color1"].default_value = cena3d.linear("#8f4a2f")
        tex.inputs["Color2"].default_value = cena3d.linear("#a75c3a")
        tex.inputs["Mortar"].default_value = cena3d.linear("#c6b49a")
        tex.inputs["Mortar Size"].default_value = 0.03
        links.new(M._coords(nodes, 1.0), tex.inputs["Vector"])
        links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.8
        M._materials[key] = mat
    return M._materials[key]


# --- Peças ----------------------------------------------------------------------------------------------------

def disc(radius, x, y, z, mat, depth=0.02):
    """Disco de pé, virado para a frente (-Y): botão, relógio, sol."""
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=(x, y, z), rotation=(math.radians(90), 0, 0), vertices=48)
    return M._finish(bpy.context.active_object, mat, min(0.008, depth * 0.3))


def tile_panel(width, height, center_x, z, y, side=TILE_SIDE, cobalt="#234fa8"):
    """Painel de azulejos virado para a frente (-Y): branco vitrificado, com o losango azul."""
    glaze = solid("#f4eee0", 0.14, 0.0, 0.8)
    blue = solid(cobalt, 0.2, 0.0, 0.6)
    pieces = [box((width, 0.008, height), (center_x, y + 0.004, z), solid("#3c2a1c", 0.7), 0.0)]
    columns, rows = max(1, round(width / side)), max(1, round(height / side))
    w, h = width / columns, height / rows
    for i in range(columns):
        for j in range(rows):
            x, tile_z = center_x + (i - (columns - 1) / 2) * w, z + (j - (rows - 1) / 2) * h
            pieces.append(box((w - 0.006, 0.008, h - 0.006), (x, y - 0.002, tile_z), glaze, 0.001))
            diamond = box((min(w, h) * 0.42, 0.003, min(w, h) * 0.42), (x, y - 0.007, tile_z), blue, 0.0)
            diamond.rotation_euler = (0.0, math.radians(45), 0.0)
            pieces.append(diamond)
    return pieces


def grates(iron, ring):
    """As grelhas em cruz, nas bocas onde o jogo põe a panela."""
    parts = []
    for (u, v) in M.STOVE_BURNERS:
        x, y = (u - 0.5) * M.STOVE_SIZE, -(v - 0.5) * M.STOVE_SIZE
        z = H + 0.024
        parts.append(cylinder(0.05, H + 0.012, z + 0.002, ring, (x, y)))
        parts.append(box((0.2, 0.018, 0.022), (x, y, z + 0.012), iron, 0.004))
        parts.append(box((0.018, 0.2, 0.022), (x, y, z + 0.012), iron, 0.004))
    return parts


def range_stove(body, trim, knob, handle, door=None, hob=None, back=None, panel=None, base=None, rounded=0.018, chrome_legs=None,
                back_h=0.3, knob_radius=0.034):
    """O fogão: corpo, tampo, grelhas, espelho de trás, painel de botões e o forno com a janela no lugar de sempre.
    [rounded] arredonda o corpo (retrô); [chrome_legs] troca o rodapé por pés de metal."""
    iron = cast_iron()
    parts = [box((W, BODY_D, H - 0.07), (0.0, 0.0, (H - 0.07) / 2 + 0.07), body, rounded),
             box((W + 0.02, W, 0.03), (0.0, 0.0, H - 0.002), trim, min(rounded, 0.012)),
             box((W - 0.09, W - 0.1, 0.012), (0.0, -0.015, H + 0.016), hob or solid("#141418", 0.32, 0.4, 0.5), 0.004)]
    if chrome_legs is not None:
        parts.append(box((W - 0.03, BODY_D - 0.03, 0.03), (0.0, 0.0, 0.07), solid("#26262b", 0.6), 0.004))
        for sx in (-1, 1):
            for sy in (-1, 1):
                parts.append(lathe([(0.0, 0.0), (0.024, 0.0), (0.03, 0.03), (0.042, 0.07), (0.0, 0.07)], chrome_legs, (sx * (W / 2 - 0.08), sy * (BODY_D / 2 - 0.08))))
    else:
        parts.append(box((W - 0.04, W - 0.07, 0.07), (0.0, 0.0, 0.035), base or solid("#26262b", 0.6), 0.004))
    parts.append(box((W, 0.05, back_h), (0.0, BACK_Y, H + back_h / 2), back or body, min(rounded, 0.022)))
    parts.append(box((W + 0.03, 0.09, 0.03), (0.0, BACK_Y - 0.01, H + back_h + 0.01), trim, 0.008))
    parts += grates(iron, solid("#2d2e33", 0.5, 0.6))
    parts.append(box((W - 0.04, 0.03, 0.12), (0.0, FRONT - 0.01, H - 0.08), panel or solid("#2a2a2f", 0.4, 0.6), 0.008))
    for i in range(4):
        parts.append(disc(knob_radius, (i - 1.5) * 0.2, FRONT - 0.04, H - 0.08, knob, 0.04))
    parts.append(box((W - 0.09, 0.024, H * 0.56), (0.0, FRONT - 0.012, WINDOW_Z), door or body, 0.012))
    parts.append(box((WINDOW_W + 0.03, 0.006, WINDOW_H + 0.03), (0.0, FRONT - 0.025, WINDOW_Z), trim, 0.002))
    parts.append(box((WINDOW_W, 0.012, WINDOW_H), (0.0, FRONT - 0.026, WINDOW_Z), solid("#0c0d11", 0.06, 0.0, 1.0), 0.008))
    parts.append(tube((-0.31, FRONT - 0.06, H * 0.63), (0.31, FRONT - 0.06, H * 0.63), 0.016, handle))
    for x in (-0.29, 0.29):
        parts.append(tube((x, FRONT - 0.015, H * 0.63), (x, FRONT - 0.06, H * 0.63), 0.011, iron))
    return parts


def hanging_pan(x, z, mat, radius=0.07):
    """Panelinha pendurada no trilho do espelho."""
    y = BACK_Y - 0.05
    return [disc(radius, x, y, z, mat, 0.02), box((0.018, 0.01, 0.1), (x, y, z + radius + 0.04), mat, 0.003)]


def clock_on_back(z, face, rim):
    return [disc(0.075, 0.0, BACK_Y - 0.03, z, rim, 0.018), disc(0.06, 0.0, BACK_Y - 0.04, z, face, 0.006),
            box((0.006, 0.004, 0.044), (0.0, BACK_Y - 0.045, z + 0.018), solid("#222226", 0.5), 0.0),
            box((0.032, 0.004, 0.006), (0.014, BACK_Y - 0.045, z), solid("#222226", 0.5), 0.0)]


# --- Fogões ---------------------------------------------------------------------------------------------------

def stove_steel():
    """Inox industrial: botões pretos, prateleira no alto e panelas no trilho."""
    steel = brushed_steel()
    parts = range_stove(steel, cast_iron("#34353a"), solid("#1b1b1f", 0.42), brushed_steel("#d7dadb"), panel=brushed_steel("#a9acad"))
    parts.append(box((W + 0.04, 0.17, 0.026), (0.0, BACK_Y - 0.08, H + 0.34), steel, 0.006))
    return parts + hanging_pan(-0.24, H + 0.15, brushed_steel("#d7dadb")) + hanging_pan(0.24, H + 0.15, cast_iron("#2d2e33"))


def retro_stove(color, knob, handle, hob=None):
    """Retrô dos anos 50 a 70: corpo bem arredondado, frisos de metal, pés e relógio redondo no espelho."""
    chrome = chrome_a()
    parts = range_stove(enamel(color), chrome, knob, handle, door=enamel(M._tint(color, 0.14)), rounded=0.05, chrome_legs=chrome,
                        panel=enamel(M._shade(color, 0.12)), hob=hob)
    parts.append(box((W + 0.006, BODY_D + 0.006, 0.014), (0.0, 0.0, H * 0.72), chrome, 0.004))
    return parts + clock_on_back(H + 0.16, solid("#f7f3e8", 0.4), chrome)


def stove_black():
    """Fogão de bistrô francês: esmalte preto, latão nos trilhos e botões grandes, com pés torneados."""
    brass = gold()
    black = solid("#17171c", 0.2, 0.0, 0.9)
    parts = range_stove(black, brass, brass, brass, panel=solid("#212127", 0.25, 0.0, 0.8), chrome_legs=brass, knob_radius=0.04, back_h=0.24)
    parts.append(tube((-0.4, FRONT - 0.09, H * 0.82), (0.4, FRONT - 0.09, H * 0.82), 0.009, brass))
    for x in (-0.38, 0.38):
        parts.append(tube((x, FRONT - 0.02, H * 0.82), (x, FRONT - 0.09, H * 0.82), 0.007, brass))
    return parts


def stove_copper():
    """Fogão italiano de cobre martelado, com ferro escuro e uma panela de cobre no trilho."""
    metal = copper()
    iron = cast_iron("#2b2622")
    parts = range_stove(metal, iron, cast_iron("#26211d"), iron, panel=iron, door=metal)
    return parts + hanging_pan(-0.24, H + 0.15, metal) + hanging_pan(0.22, H + 0.16, metal, 0.055)


def stove_blue():
    """Fogão japonês: índigo com dourado, rodapé de madeira e treliça kumiko no espelho."""
    wood = rich_wood("#a57a48", 8.0, 0.3)
    parts = range_stove(enamel("#23457f"), wood, gold(), gold(), base=wood, panel=enamel("#1a3462"), back=enamel("#1a3462"))
    for i in range(7):
        parts.append(box((0.016, 0.012, 0.26), (-0.42 + i * 0.14, BACK_Y - 0.03, H + 0.14), wood, 0.002))
    for z in (H + 0.07, H + 0.14, H + 0.21):
        parts.append(box((W - 0.06, 0.012, 0.016), (0.0, BACK_Y - 0.032, z), wood, 0.002))
    return parts


def stove_arcade():
    """Fogão Fliperama: roxo, botões de fliperama, tiras de luz e a tela com os bichinhos no espelho."""
    purple = enamel("#5f3299")
    parts = range_stove(purple, solid("#1b1b24", 0.3, 0.0, 0.6), solid("#d8326e", 0.25, 0.0, 0.7), solid("#2bb8d6", 0.3, 0.0, 0.7),
                        panel=solid("#1b1b24", 0.3, 0.0, 0.6), back=solid("#131319", 0.3))
    parts.append(box((W - 0.14, 0.01, 0.2), (0.0, BACK_Y - 0.03, H + 0.15), solid("#080a14", 0.2), 0.002))
    cyan, pink = emission("#3ee0ff", 4.0), emission("#ff3d7f", 4.0)
    for row, pattern in enumerate(("0110110", "1111111", "1011101", "0100010")):
        for col, pixel in enumerate(pattern):
            if pixel == "1":
                parts.append(box((0.03, 0.006, 0.03), ((col - 3) * 0.05 - 0.14, BACK_Y - 0.038, H + 0.22 - row * 0.042), cyan, 0.0))
                parts.append(box((0.03, 0.006, 0.03), ((col - 3) * 0.05 + 0.14, BACK_Y - 0.038, H + 0.22 - row * 0.042), pink, 0.0))
    for x in (-W / 2 - 0.002, W / 2 + 0.002):
        parts.append(box((0.006, BODY_D - 0.08, 0.018), (x, 0.0, H * 0.2), cyan, 0.0))
    parts.append(box((W - 0.1, 0.006, 0.018), (0.0, FRONT - 0.004, 0.11), pink, 0.0))
    return parts


def stove_disco():
    """Fogão Discoteca: preto brilhante, frisos de neon e o globo espelhado sobre o espelho."""
    black = solid("#15151f", 0.18, 0.0, 0.9)
    neon = emission("#ff4dd2", 5.0)
    parts = range_stove(black, chrome_a(), solid("#c24bd0", 0.25, 0.0, 0.7), chrome_a(), panel=brushed_steel("#a9acad"))
    parts.append(box((W - 0.08, 0.006, 0.014), (0.0, BACK_Y - 0.03, H + 0.26), neon, 0.0))
    parts.append(box((W - 0.08, 0.006, 0.014), (0.0, BACK_Y - 0.03, H + 0.06), emission("#a06bff", 5.0), 0.0))
    parts.append(box((W - 0.1, 0.006, 0.016), (0.0, FRONT - 0.004, 0.11), neon, 0.0))
    parts.append(tube((0.0, BACK_Y - 0.05, H + 0.31), (0.0, BACK_Y - 0.13, H + 0.31), 0.006, chrome_a()))
    parts.append(tube((0.0, BACK_Y - 0.13, H + 0.31), (0.0, BACK_Y - 0.13, H + 0.27), 0.004, chrome_a()))
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.075, location=(0.0, BACK_Y - 0.13, H + 0.2))
    ball = M._finish(bpy.context.active_object, mirror_glass(), smooth=False)   # faces planas: as plaquinhas do globo
    parts.append(ball)
    return parts


def stove_samba():
    """Fogão verde e amarelo, com calçadão de ondas no espelho."""
    yellow = enamel("#d9a92e")
    green = enamel("#2a7f42")
    parts = range_stove(green, yellow, solid("#23479a", 0.3, 0.0, 0.5), yellow, panel=enamel("#1f6535"), back=solid("#f2ecdf", 0.35, 0.0, 0.3))
    for i in range(8):
        parts.append(sphere(0.06, (-0.42 + i * 0.12, BACK_Y - 0.026, H + 0.15 + (0.03 if i % 2 else -0.03)), solid("#26262b", 0.4), (1.0, 0.1, 0.32)))
    return parts


def stove_wood():
    """Fogão a lenha: ferro e esmalte vermelho sobre base de tijolo, com a chaminé atrás."""
    iron = cast_iron("#28262a")
    parts = range_stove(enamel("#8e3324"), iron, iron, brushed_steel("#d7dadb"), panel=iron, door=iron, base=brick())
    parts.append(lathe([(0.075, H + 0.02), (0.075, H + 0.74), (0.095, H + 0.76), (0.095, H + 0.79), (0.0, H + 0.79)], iron, (0.28, BACK_Y - 0.06)))
    parts.append(lathe([(0.095, H + 0.3), (0.095, H + 0.33)], iron, (0.28, BACK_Y - 0.06)))
    return parts


def stove_talavera():
    """Fogão Talavera: esmalte creme, azulejos no espelho e nas laterais do forno, botões vermelhos."""
    cream = enamel("#ece4d3")
    blue = enamel("#234fa8")
    parts = range_stove(cream, blue, solid("#c02d36", 0.3, 0.0, 0.5), solid("#d6a838", 0.4, 0.3), panel=blue, door=cream, back=cream)
    parts += tile_panel(W - 0.08, 0.26, 0.0, H + 0.15, BACK_Y - 0.03, 0.13)
    return parts


def stove_moon():
    """Fogão Lua Cheia, do evento: noite azul com latão e, no espelho, a lua e as estrelas que acendem."""
    night = enamel("#1b2a5c")
    brass = gold()
    parts = range_stove(night, brass, brass, brass, panel=enamel("#121d42"), door=enamel("#24376f"), back=enamel("#121d42"))
    y = BACK_Y - 0.03
    parts.append(disc(0.1, 0.2, y, H + 0.16, solid("#ffd76a", 0.4), 0.018))
    parts.append(disc(0.088, 0.24, y - 0.012, H + 0.18, enamel("#121d42"), 0.012))
    for x, z in ((-0.34, 0.22), (-0.2, 0.12), (-0.08, 0.24), (-0.28, 0.07), (0.38, 0.24)):
        parts.append(sphere(0.014, (x, y - 0.01, H + z), emission("#fff6c2", 8.0)))
    return parts


STOVES = {
    "stove_steel": stove_steel,
    "stove_mint": lambda: retro_stove("#74c7ae", solid("#c43a44", 0.3, 0.0, 0.5), chrome_a()),
    "stove_cream": lambda: retro_stove("#e9dcc2", rich_wood("#6f4426", 6.0, 0.4), rich_wood("#8c5526", 6.0, 0.4)),
    "stove_yellow": lambda: retro_stove("#e7b832", solid("#26272e", 0.35), chrome_a()),
    "stove_black": stove_black,
    "stove_copper": stove_copper,
    "stove_blue": stove_blue,
    "stove_arcade": stove_arcade,
    "stove_disco": stove_disco,
    "stove_samba": stove_samba,
    "stove_wood": stove_wood,
    "stove_talavera": stove_talavera,
    "stove_moon": stove_moon,
}


# --- Balcões --------------------------------------------------------------------------------------------------

def around(face):
    """Repete a face (feita virada para -Y) nos quatro lados, porque o balcão gira."""
    parts = []
    for angle in (0.0, 90.0, 180.0, -90.0):
        rad = math.radians(angle)
        for obj in M._flatten(face()):
            lx, ly = obj.location.x, obj.location.y
            obj.location = (lx * math.cos(rad) - ly * math.sin(rad), lx * math.sin(rad) + ly * math.cos(rad), obj.location.z)
            if obj.rotation_mode == "QUATERNION":
                turned = obj.rotation_quaternion.to_matrix()
                from mathutils import Matrix
                obj.rotation_quaternion = (Matrix.Rotation(rad, 3, "Z") @ turned).to_quaternion()
            else:
                x, y, z = obj.rotation_euler
                obj.rotation_euler = (x, y, z + rad)
            parts.append(obj)
    return parts


def counter_core(body, plinth, band, top, top_h=0.09):
    """Miolo, rodapé, faixa sob o tampo e o tampo largo; a altura final é a mesma do catálogo."""
    w = COUNTER_W
    z0 = COUNTER_H + M.COUNTER_TOP - top_h
    return [box((COUNTER_BODY, COUNTER_BODY, COUNTER_H - 0.05), (0.0, 0.0, (COUNTER_H - 0.05) / 2 + 0.05), body, 0.006),
            box((w - 0.015, w - 0.015, 0.07), (0.0, 0.0, 0.035), plinth, 0.006),
            box((w - 0.03, w - 0.03, 0.04), (0.0, 0.0, COUNTER_H - 0.03), band, 0.006),
            box((w + 0.04, w + 0.04, top_h), (0.0, 0.0, z0 + top_h / 2), top, 0.02)]


FACE_Y = -COUNTER_BODY / 2
PANEL_H = COUNTER_H - 0.2
PANEL_Z = 0.09 + PANEL_H / 2


def raised_panels(light, dark):
    return lambda: A._raised_panel(0.4, PANEL_H, -0.225, PANEL_Z, FACE_Y, light, dark) + A._raised_panel(0.4, PANEL_H, 0.225, PANEL_Z, FACE_Y, light, dark)


def steel_doors():
    steel = brushed_steel()
    handle = brushed_steel("#e2e4e5")

    def face():
        pieces = []
        for x in (-0.225, 0.225):
            pieces.append(box((0.41, 0.018, PANEL_H), (x, FACE_Y - 0.005, PANEL_Z), steel, 0.004))
            pieces.append(box((0.3, 0.02, 0.016), (x, FACE_Y - 0.03, PANEL_Z + PANEL_H / 2 - 0.05), handle, 0.004))
        return pieces
    return face


def planks(wood_color, count=7):
    def face():
        width = (COUNTER_BODY - 0.02) / count
        return [box((width - 0.006, 0.018, COUNTER_H - 0.1), (-(COUNTER_BODY - 0.02) / 2 + (i + 0.5) * width, FACE_Y - 0.005, 0.07 + (COUNTER_H - 0.1) / 2),
                    rich_wood(M._shade(wood_color, 0.04 * (i % 3)), 9.0, 0.3), 0.004) for i in range(count)]
    return face


def bamboo_poles():
    stalk = solid("#c9a968", 0.4, 0.0, 0.35)
    node = solid("#8f7238", 0.5)

    def face():
        pieces = []
        count = 13
        step = (COUNTER_BODY - 0.02) / count
        for i in range(count):
            x = -(COUNTER_BODY - 0.02) / 2 + (i + 0.5) * step
            pieces.append(cylinder(step * 0.48, 0.07, COUNTER_H - 0.05, stalk, (x, FACE_Y - 0.01), vertices=16))
            for z in (0.25 + (i % 3) * 0.03, 0.46 + (i % 3) * 0.03):
                pieces.append(cylinder(step * 0.52, z - 0.008, z + 0.008, node, (x, FACE_Y - 0.01), vertices=16))
        return pieces
    return face


def ribbed_face(color):
    """Lanchonete: vinil vermelho em painel inteiro, com as cintas de cromo."""
    vinyl = solid(color, 0.32, 0.0, 0.35)
    chrome = chrome_a()

    def face():
        pieces = [box((COUNTER_BODY, 0.02, PANEL_H + 0.05), (0.0, FACE_Y - 0.005, PANEL_Z), vinyl, 0.006)]
        for z in (PANEL_Z - PANEL_H * 0.32, PANEL_Z, PANEL_Z + PANEL_H * 0.32):
            for dz in (-0.018, 0.018):
                pieces.append(box((COUNTER_BODY + 0.002, 0.012, 0.014), (0.0, FACE_Y - 0.017, z + dz), chrome, 0.003))
        return pieces
    return face


def marble_face(trim):
    stone = veined_marble("#ece6dc")
    metal = trim

    def face():
        pieces = []
        for x in (-0.225, 0.225):
            pieces.append(box((0.41, 0.018, PANEL_H), (x, FACE_Y - 0.005, PANEL_Z), stone, 0.004))
            pieces.append(box((0.41, 0.006, 0.012), (x, FACE_Y - 0.016, PANEL_Z + PANEL_H / 2 - 0.016), metal, 0.002))
            pieces.append(box((0.41, 0.006, 0.012), (x, FACE_Y - 0.016, PANEL_Z - PANEL_H / 2 + 0.016), metal, 0.002))
        return pieces
    return face


def tile_face():
    return lambda: tile_panel(COUNTER_BODY - 0.02, PANEL_H + 0.06, 0.0, PANEL_Z, FACE_Y - 0.012, 0.135)


def neon_face(glow_a, glow_b, base="#15151f"):
    dark = solid(base, 0.16, 0.0, 0.9)

    def face():
        return [box((COUNTER_BODY, 0.018, PANEL_H + 0.04), (0.0, FACE_Y - 0.005, PANEL_Z), dark, 0.004),
                box((COUNTER_BODY - 0.08, 0.006, 0.016), (0.0, FACE_Y - 0.016, PANEL_Z + PANEL_H * 0.3), emission(glow_a, 5.0), 0.0),
                box((COUNTER_BODY - 0.08, 0.006, 0.016), (0.0, FACE_Y - 0.016, PANEL_Z - PANEL_H * 0.3), emission(glow_b, 5.0), 0.0)]
    return face


def pixel_face():
    """Fliperama: o painel escuro com os pixels acesos, sem repetir a mesma fileira."""
    dark = solid("#2a1856", 0.28, 0.0, 0.6)
    colors = ["#3ee0ff", "#ff3d7f", "#ffd23f"]

    def face():
        pieces = [box((COUNTER_BODY, 0.018, PANEL_H + 0.04), (0.0, FACE_Y - 0.005, PANEL_Z), dark, 0.004)]
        for row in range(5):
            for col in range(11):
                if (col * 3 + row * 5) % 4 == 0:
                    pieces.append(box((0.045, 0.006, 0.045), (-0.4 + col * 0.08, FACE_Y - 0.016, PANEL_Z - 0.2 + row * 0.1),
                                      emission(colors[(col + row) % 3], 3.5), 0.0))
        return pieces
    return face


def groovy_face():
    """Anos 70: painéis laranja com o sol de arcos no meio."""
    orange = enamel("#d9691a")

    def face():
        pieces = [box((COUNTER_BODY, 0.018, PANEL_H + 0.04), (0.0, FACE_Y - 0.005, PANEL_Z), orange, 0.006)]
        for radius, color, y in ((0.2, "#a8481a", 0.016), (0.145, "#ecb04a", 0.022), (0.09, "#f4e1b0", 0.028)):
            pieces.append(disc(radius, 0.0, FACE_Y - y, PANEL_Z, enamel(color), 0.006))
        return pieces
    return face


def pastel_face():
    """Confeitaria: painéis rosados, com o babado de madeira pintada sob o tampo."""
    light, dark = enamel("#e7a6bd"), enamel("#c97f9b")
    white = solid("#f7f1e8", 0.4, 0.0, 0.3)

    def face():
        pieces = raised_panels(light, dark)()
        for i in range(10):
            pieces.append(sphere(0.052, (-0.46 + i * 0.102, FACE_Y - 0.012, COUNTER_H - 0.05), white, (1.0, 0.25, 0.62)))
        return pieces
    return face


def samba_face():
    green, dark = enamel("#2a7f42"), enamel("#1f6535")
    yellow = enamel("#d9a92e")

    def face():
        return raised_panels(green, dark)() + [box((COUNTER_BODY + 0.002, 0.012, 0.03), (0.0, FACE_Y - 0.012, COUNTER_H - 0.075), yellow, 0.003)]
    return face


def bistro_face():
    black, dark = solid("#25252c", 0.22, 0.0, 0.85), solid("#17171c", 0.3, 0.0, 0.7)
    brass = gold()

    def face():
        return raised_panels(black, dark)() + [box((0.42, 0.005, 0.01), (x, FACE_Y - 0.03, PANEL_Z + z), brass, 0.0) for x in (-0.225, 0.225) for z in (-0.13, 0.13)]
    return face


def _dark(color):
    return rich_wood(color, 7.0, 0.25)


COUNTERS = {
    "counter_steel": lambda: counter_core(brushed_steel("#a9acad"), cast_iron("#2d2e33"), brushed_steel(), solid("#d9dcdd", 0.34, 0.3, 0.2), 0.05) + around(steel_doors()),
    "counter_wood": lambda: counter_core(_dark("#6e4324"), _dark(A.WALNUT_DARK), _dark("#5a3820"), grain_wood("#b0783f", 0.5)) + around(planks("#9b6535")),
    "counter_pastel": lambda: counter_core(enamel("#c97f9b"), enamel("#a9627e"), enamel("#c97f9b"), stone_top("#f7efe6")) + around(pastel_face()),
    "counter_marble": lambda: counter_core(solid("#bdb6aa", 0.4), rich_wood("#5a3820", 7.0, 0.5), gold(), veined_marble("#f1eee8")) + around(marble_face(gold())),
    "counter_tile": lambda: counter_core(_dark("#4c2d18"), _dark("#3a2214"), _dark("#4c2d18"), grain_wood("#6e4426", 0.6)) + around(tile_face()),
    "counter_neon": lambda: counter_core(solid("#101018", 0.3), solid("#0b0b12", 0.3), solid("#101018", 0.3), solid("#22222e", 0.08, 0.0, 1.0), 0.06) + around(neon_face("#ff4dd2", "#3ee0ff")),
    "counter_red": lambda: counter_core(solid("#7d1c24", 0.4), chrome_a(), chrome_a(), solid("#f4efe6", 0.28, 0.0, 0.45), 0.06) + around(ribbed_face("#b8283a")),
    "counter_groovy": lambda: counter_core(enamel("#a8481a"), _dark("#5a3820"), _dark("#7a4a26"), grain_wood("#c88f4e", 0.45), 0.07) + around(groovy_face()),
    "counter_arcade": lambda: counter_core(solid("#1b1036", 0.4), solid("#101018", 0.4), emission("#3ee0ff", 3.0), solid("#20202c", 0.1, 0.0, 1.0), 0.06) + around(pixel_face()),
    "counter_samba": lambda: counter_core(enamel("#1f6535"), enamel("#174d28"), enamel("#d9a92e"), stone_top("#f4efe6")) + around(samba_face()),
    "counter_bistro": lambda: counter_core(solid("#17171c", 0.35), gold(), gold(), veined_marble("#f1eee8")) + around(bistro_face()),
    "counter_bamboo": lambda: counter_core(_dark("#7f5a30"), _dark("#4c2d18"), _dark("#7f5a30"), grain_wood("#c9a772", 0.35), 0.07) + around(bamboo_poles()),
}


# --- Fotos ----------------------------------------------------------------------------------------------------

def render_item(item_id, build, manifest, samples, proof, anchors):
    rotations = sorted({int(name.rsplit("_r", 1)[1]) for name in manifest["furniture"][item_id].values()})
    for rotation in rotations[:1] if proof else rotations:
        cena3d.setup(samples, M.IMAGE_SIZE, shadow_center=(0.5, -0.5), shadow_size=(1.0 + SHADOW_MARGIN, 1.0 + SHADOW_MARGIN), rig="a")
        anchor, center = M.assemble(list(M._flatten(build())), (1, 1), rotation)
        aim_camera((center[0], center[1], 0.42))
        name = f"{item_id}_r{rotation}"
        anchors[name] = cena3d.shoot(name, anchor, WORK)


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    samples = 24 if "rascunho" in args else 80
    items = {**STOVES, **COUNTERS}
    wanted = [a for a in args if a in items] or list(items)
    with open(os.path.join(cena3d.SPRITES, "sprites.json"), encoding="utf-8") as source:
        manifest = json.load(source)
    anchors = {}
    for item_id in wanted:
        render_item(item_id, items[item_id], manifest, samples, "prova" in args, anchors)
        cena3d.update_manifest(anchors)   # a cada item: se o próximo falhar, as fotos prontas não perdem a âncora
        print("PRONTO", item_id, flush=True)
    print("COZINHA OK", len(anchors), flush=True)


if __name__ == "__main__":
    main()
