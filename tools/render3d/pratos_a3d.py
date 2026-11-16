"""Pratos e panelas em 3D na linguagem da referência A (DT-098): as 39 receitas com o prato pronto e a panela no fogão.

Uso (na pasta do projeto):
    C:/Blender/blender-5.2.3-windows-x64/blender.exe -b -P tools/render3d/pratos_a3d.py -- [pratos] [panelas] [ids...] [rascunho]

Sem nada, faz todos. Com ids de receita (coffee, lasagna...), faz o prato e a panela só delas.

Grava em art/sprites com os mesmos nomes (prato_<receita> e panela_<receita>), então receitas, preços e save não mudam.
Encaixe, igual ao da arte antiga:
- prato: o centro do prato fica 12 px de mundo abaixo da âncora (a âncora é o meio do ícone: o jogo usa a mesma foto na mesa,
  no balcão, na bandeja e nos balões), e o prato tem cerca de 50 px de largura;
- panela: no meio do tampo do fogão, com a âncora no vértice da frente do piso do fogão, como os móveis.
"""
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cena3d  # noqa: E402
from cena3d import aim_camera, linear  # noqa: E402
import moveis3d as M  # noqa: E402
from moveis3d import box, cylinder, solid, sphere, tube  # noqa: E402
import enfeites3d as E  # noqa: E402
import amostra_a3d as A  # noqa: E402
import assentos_a3d as AS  # noqa: E402

WORK = os.path.join(cena3d.ROOT, "tools", "render3d", "out_pratos")
DISH_IMAGE = (260, 260)
POT_IMAGE = (380, 460)
PLATE_R = 0.27                 # o prato tem 0,54 de largura: cerca de 98 px da foto, 49 px de mundo
ANCHOR_LIFT = 0.155            # a âncora fica 12 px de mundo acima do centro do prato
POT_Z = M.STOVE_HEIGHT + 0.046  # em cima das grelhas do fogão
# A câmera olha do canto (+x, -y): "para a direita" na tela é (+x, +y) e "para a frente" é (+x, -y).
RIGHT = Vector((0.707, 0.707, 0.0))
FRONT = Vector((0.707, -0.707, 0.0))


# --- Materiais --------------------------------------------------------------------------------------------------

def food(color, rough=0.6, vary=0.14, grain=60.0, bump=0.25, coat=0.0):
    """Comida: a cor com manchas de tom e um relevo fino, para não parecer plástico."""
    key = ("food", color, rough, vary, grain, bump, coat)
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("Comida_" + color)
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = grain
        noise.inputs["Detail"].default_value = 4.0
        links.new(M._coords(nodes, 1.0), noise.inputs["Vector"])
        links.new(M._ramp(nodes, links, noise.outputs["Fac"], M._shade(color, vary), M._tint(color, vary * 0.5), (0.3, 0.7)),
                  bsdf.inputs["Base Color"])
        relief = nodes.new("ShaderNodeBump")
        relief.inputs["Strength"].default_value = bump
        links.new(noise.outputs["Fac"], relief.inputs["Height"])
        links.new(relief.outputs["Normal"], bsdf.inputs["Normal"])
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Coat Weight"].default_value = coat
        M._materials[key] = mat
    return M._materials[key]


def sauce(color):
    """Molho, calda e caldo: liso e brilhante."""
    return food(color, 0.18, 0.06, 12.0, 0.05, 0.6)


def fried(color="#c98a34"):
    """Fritura: dourada e crocante."""
    return food(color, 0.7, 0.2, 140.0, 0.6)


def ceramic(color="#f1ede4"):
    return solid(color, 0.22, 0.0, 0.6)


def steel():
    return A.brushed_steel("#b9bdc0")


def iron():
    return solid("#25262b", 0.5, 0.6)


def board_wood():
    return A.rich_wood("#a8703a", 6.0, 0.25)


# --- Peças ------------------------------------------------------------------------------------------------------

def lathe(profile, mat, center=(0.0, 0.0)):
    return AS.lathe(profile, mat, center, 64)


def disc(radius, z, mat, center=(0.0, 0.0), thick=0.006):
    return cylinder(radius, z - thick, z, mat, center, bevel=0.002, vertices=64)


def blob(radius, pos, mat, scale=(1.0, 1.0, 1.0), turn=(0.0, 0.0, 0.0)):
    obj = sphere(radius, pos, mat, scale)
    obj.rotation_euler = tuple(math.radians(a) for a in turn)
    return obj


def prism(points, z0, z1, mat, bevel=0.004):
    """Peça de contorno qualquer (visto de cima) entre duas alturas: fatias de bolo, sanduíches, tábuas."""
    count = len(points)
    verts = [(x, y, z0) for x, y in points] + [(x, y, z1) for x, y in points]
    faces = [tuple(range(count - 1, -1, -1)), tuple(range(count, 2 * count))]
    faces += [(i, (i + 1) % count, count + (i + 1) % count, count + i) for i in range(count)]
    mesh = bpy.data.meshes.new("Prisma")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("Prisma", mesh)
    bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    return M._finish(obj, mat, bevel, smooth=False)


def wedge(length=0.3, half_angle=24.0, turn=200.0, tip=(0.12, -0.02)):
    """Contorno de uma fatia de torta, com a ponta em [tip] e virada [turn] graus."""
    points = [tip]
    for step in range(7):
        angle = math.radians(turn - half_angle + 2 * half_angle * step / 6)
        points.append((tip[0] + math.cos(angle) * length, tip[1] + math.sin(angle) * length))
    return points


def layers(points, stack, z=0.0):
    """Empilha camadas [(altura, material)...] no mesmo contorno; devolve as peças e a altura final."""
    parts = []
    for height, mat in stack:
        parts.append(prism(points, z, z + height, mat))
        z += height
    return parts, z


def scatter(count, radius, seed, make, center=(0.0, 0.0), inner=0.0):
    """Espalha [count] peças num círculo: make(x, y, índice, sorteio) devolve a peça (ou uma lista delas)."""
    rnd = random.Random(seed)
    parts = []
    for index in range(count):
        angle = 2 * math.pi * (index + rnd.uniform(-0.3, 0.3)) / count
        dist = inner + (radius - inner) * math.sqrt(rnd.uniform(0.05, 1.0))
        parts.append(make(center[0] + math.cos(angle) * dist, center[1] + math.sin(angle) * dist, index, rnd))
    return parts


def plate(radius=PLATE_R):
    """Prato raso de louça, com a aba levantada."""
    r = radius
    return [lathe([(0.0, 0.0), (r * 0.62, 0.0), (r * 0.7, 0.008), (r * 0.98, 0.03), (r, 0.036), (r * 0.97, 0.04), (r * 0.7, 0.02),
                   (r * 0.6, 0.014), (0.0, 0.014)], ceramic())]


PLATE_TOP = 0.014


def bowl(mat, radius=0.22, height=0.14, foot=0.5):
    """Tigela: o pé, a barriga e a borda."""
    r, h = radius, height
    return [lathe([(0.0, 0.0), (r * foot, 0.0), (r * foot, 0.012), (r * 0.82, h * 0.45), (r, h), (r * 0.94, h), (r * 0.76, h * 0.5),
                   (r * foot * 0.8, 0.03), (0.0, 0.03)], mat)]


def chopsticks(z, mat=None, at=(0.16, 0.04), turn=35.0):
    wood = mat or A.rich_wood("#8a5a2e", 8.0, 0.2)
    parts = []
    for shift in (-0.014, 0.014):
        a = Vector((at[0] - 0.2, at[1] + shift, z))
        b = Vector((at[0] + 0.14, at[1] + shift * 1.6, z + 0.03))
        stick = tube(a, b, 0.006, wood)
        stick.rotation_euler.rotate_axis("Z", math.radians(turn)) if False else None
        parts.append(stick)
    return parts


def herb(pos, mat=None, size=0.03):
    return blob(size, pos, mat or food("#3f8a3a", 0.6, 0.2), (1.0, 0.7, 0.25))


def berry(pos, color="#b3202c", size=0.026):
    return blob(size, pos, sauce(color), (1.0, 1.0, 0.95))


def strawberry(pos, size=0.036):
    return [blob(size, pos, food("#c8262e", 0.35, 0.1, 160.0, 0.3, 0.4), (0.85, 0.85, 1.1)),
            blob(size * 0.5, (pos[0], pos[1], pos[2] + size * 0.9), food("#3f8a3a"), (1.0, 1.0, 0.3))]


def cream(pos, size=0.05):
    white = food("#f6f1e6", 0.5, 0.04, 30.0, 0.1)
    return [blob(size, pos, white, (1.0, 1.0, 0.6)), blob(size * 0.62, (pos[0], pos[1], pos[2] + size * 0.5), white, (1.0, 1.0, 0.7)),
            blob(size * 0.3, (pos[0], pos[1], pos[2] + size * 0.95), white, (1.0, 1.0, 1.2))]


def shrimp(pos, turn=0.0, size=1.0):
    """Camarão: um arco de gomos rosados."""
    pink = food("#f08a62", 0.4, 0.12, 80.0, 0.3, 0.3)
    parts = []
    for i in range(5):
        angle = math.radians(turn + i * 34.0)
        r = 0.035 * size
        parts.append(blob(0.022 * size * (1.0 - i * 0.12), (pos[0] + math.cos(angle) * r, pos[1] + math.sin(angle) * r, pos[2]), pink,
                          (1.0, 1.0, 0.8)))
    return parts


# --- Pratos -----------------------------------------------------------------------------------------------------

def coffee():
    china = ceramic()
    parts = [lathe([(0.0, 0.0), (0.15, 0.0), (0.24, 0.022), (0.25, 0.03), (0.15, 0.014), (0.0, 0.014)], china),
             lathe([(0.0, 0.014), (0.075, 0.014), (0.085, 0.03), (0.13, 0.17), (0.14, 0.21), (0.128, 0.21), (0.118, 0.17), (0.07, 0.045),
                    (0.0, 0.045)], china),
             disc(0.126, 0.195, sauce("#3a2112")),
             disc(0.07, 0.197, food("#c9a070", 0.4, 0.1, 20.0, 0.05)),
             disc(0.03, 0.199, food("#efe2c8", 0.4, 0.05, 20.0, 0.05))]
    handle = E.torus(0.055, 0.014, (0.0, 0.0, 0.12), china, (math.radians(90), 0.0, 0.0))
    handle.location = Vector((0.0, 0.0, 0.12)) + RIGHT * 0.16
    handle.rotation_euler = (math.radians(90), 0.0, math.radians(45))
    return parts + [handle]


def cheese_bread():
    dough = food("#e8b84e", 0.62, 0.22, 90.0, 0.5)
    parts = plate()
    for x, y, z, r in ((-0.09, -0.02, 0.0, 0.085), (0.08, -0.05, 0.0, 0.08), (0.02, 0.09, 0.0, 0.082), (-0.005, 0.0, 0.11, 0.078)):
        parts.append(blob(r, (x, y, PLATE_TOP + r * 0.82 + z), dough, (1.0, 1.0, 0.86)))
    return parts


def toasted_sandwich():
    bread = fried("#d9a04e")
    crumb = food("#f1dca6", 0.8, 0.08, 90.0, 0.4)
    ham = food("#e58a8a", 0.5, 0.1)
    cheese = sauce("#f2c232")
    parts = plate()
    for shift, turn in ((-0.115, 20.0), (0.115, 200.0)):
        tri = []
        for px, py in ((-0.09, -0.1), (0.09, -0.1), (0.09, 0.12)):
            a = math.radians(turn)
            tri.append((shift + px * math.cos(a) - py * math.sin(a), px * math.sin(a) + py * math.cos(a)))
        stack, _ = layers(tri, [(0.012, bread), (0.03, crumb), (0.014, ham), (0.012, cheese), (0.03, crumb), (0.012, bread)], PLATE_TOP)
        parts += stack
    return parts


def carrot_cake():
    sponge = food("#e58a2c", 0.8, 0.16, 110.0, 0.6)
    choc = sauce("#3a1f12")
    square = [(-0.15, -0.13), (0.15, -0.13), (0.15, 0.13), (-0.15, 0.13)]
    stack, top = layers(square, [(0.16, sponge), (0.022, choc)], PLATE_TOP)
    parts = plate() + stack
    for x, y, drop in ((0.152, -0.06, 0.07), (0.152, 0.05, 0.05), (-0.02, -0.132, 0.08), (-0.1, -0.132, 0.045), (0.09, -0.132, 0.06)):
        parts.append(blob(0.016, (x, y, top - drop / 2), choc, (0.8, 0.8, drop / 0.032)))
    return parts


def coxinha():
    crust = fried("#c9842c")
    parts = plate()
    for x, y, turn in ((-0.085, -0.02, 10.0), (0.09, 0.03, -14.0)):
        parts.append(blob(0.085, (x, y, PLATE_TOP + 0.075), crust, (1.0, 1.0, 0.95)))
        tip = E.cone(0.07, PLATE_TOP + 0.1, PLATE_TOP + 0.25, crust, (x, y), 0.008)
        tip.rotation_euler = (math.radians(turn), 0.0, 0.0)
        parts.append(tip)
    return parts


def lasagna():
    pasta = food("#f0cf72", 0.6, 0.1)
    meat = food("#a8382a", 0.6, 0.22, 100.0, 0.5)
    white = food("#f4ead2", 0.5, 0.06)
    cheese = food("#e8a83a", 0.45, 0.25, 50.0, 0.4, 0.2)
    square = [(-0.16, -0.11), (0.16, -0.11), (0.16, 0.11), (-0.16, 0.11)]
    stack, top = layers(square, [(0.02, pasta), (0.028, meat), (0.014, white), (0.02, pasta), (0.028, meat), (0.014, white), (0.02, pasta),
                                 (0.02, cheese)], PLATE_TOP)
    parts = plate() + stack + [disc(0.2, PLATE_TOP + 0.004, sauce("#b3382a"))]
    parts.append(herb((0.02, 0.0, top + 0.008)))
    return parts


def brigadeiro():
    choc = food("#3d2113", 0.5, 0.2, 200.0, 0.7)
    paper = solid("#8a5a34", 0.7)
    parts = plate()
    for x, y, z in ((-0.1, -0.04, 0.0), (0.09, -0.06, 0.0), (0.0, 0.09, 0.0), (0.0, -0.005, 0.105)):
        base = PLATE_TOP + z
        parts.append(E.cone(0.062, base, base + 0.045, paper, (x, y), 0.074, 14))
        parts.append(blob(0.066, (x, y, base + 0.075), choc))
    return parts


def pastel():
    crust = fried("#e0a84a")
    parts = plate()
    for x, y, turn in ((-0.06, 0.03, 20.0), (0.07, -0.05, -10.0)):
        half = [(math.cos(math.radians(a)) * 0.17, math.sin(math.radians(a)) * 0.13) for a in range(0, 181, 15)]
        rad = math.radians(turn)
        outline = [(x + px * math.cos(rad) - py * math.sin(rad), y - 0.05 + px * math.sin(rad) + py * math.cos(rad)) for px, py in half]
        parts.append(prism(outline, PLATE_TOP, PLATE_TOP + 0.045, crust, 0.016))
        parts.append(blob(0.1, (x, y, PLATE_TOP + 0.04), crust, (1.2, 0.8, 0.32), (0.0, 0.0, turn)))
    return parts


def burger():
    bun = food("#d9963c", 0.45, 0.14, 60.0, 0.2, 0.3)
    z = PLATE_TOP
    parts = plate() + [cylinder(0.17, z, z + 0.045, bun, bevel=0.016),
                       cylinder(0.185, z + 0.045, z + 0.06, food("#4f9a3a", 0.5, 0.2), bevel=0.004),
                       cylinder(0.172, z + 0.06, z + 0.1, food("#5a3220", 0.7, 0.2, 120.0, 0.6), bevel=0.012),
                       box((0.33, 0.33, 0.012), (0.0, 0.0, z + 0.106), sauce("#f2b72c"), 0.004),
                       cylinder(0.165, z + 0.112, z + 0.128, food("#c9342c", 0.4, 0.1), bevel=0.004),
                       blob(0.175, (0.0, 0.0, z + 0.128), bun, (1.0, 1.0, 0.62))]
    parts[-3].rotation_euler = (0.0, 0.0, math.radians(20))
    parts += scatter(11, 0.11, 3, lambda x, y, i, rnd: blob(0.01, (x, y, z + 0.128 + 0.105 * math.sqrt(max(0.0, 1 - (x * x + y * y) / 0.031))),
                                                              solid("#f4e6c0", 0.5), (1.0, 0.6, 0.4)))
    return parts


def pizza():
    parts = [disc(0.3, 0.012, board_wood(), thick=0.012),
             cylinder(0.27, 0.012, 0.03, fried("#d9a55a"), bevel=0.008),
             disc(0.24, 0.034, sauce("#b3342a")),
             disc(0.225, 0.037, food("#f2d27a", 0.4, 0.2, 30.0, 0.3, 0.3))]
    parts += scatter(7, 0.17, 5, lambda x, y, i, rnd: disc(0.036, 0.042, food("#a8262a", 0.45, 0.2, 90.0, 0.3), (x, y)), inner=0.05)
    parts += scatter(5, 0.15, 9, lambda x, y, i, rnd: herb((x, y, 0.046), size=0.026), inner=0.02)
    return parts


def croissant():
    dough = food("#d9953a", 0.45, 0.2, 90.0, 0.4, 0.35)
    parts = plate()
    for i in range(7):
        t = (i - 3) / 3.0
        angle = math.radians(90 + t * 62)
        r = 0.13
        size = 0.062 * (1.0 - abs(t) * 0.45)
        parts.append(blob(size, (math.cos(angle) * r, math.sin(angle) * r - 0.13, PLATE_TOP + size * 0.9), dough, (1.25, 0.8, 0.9),
                          (0.0, 0.0, math.degrees(angle) + 90)))
    return parts


def pancakes():
    cake = food("#e0a04a", 0.55, 0.16, 70.0, 0.3)
    z = PLATE_TOP
    parts = plate()
    for i in range(4):
        parts.append(cylinder(0.185 - i * 0.004, z, z + 0.034, cake, ((i % 2) * 0.008 - 0.004, 0.0), bevel=0.014))
        z += 0.034
    parts += [disc(0.14, z + 0.003, sauce("#b3661c")), box((0.06, 0.06, 0.028), (0.0, 0.0, z + 0.018), food("#f6e08a", 0.4, 0.05), 0.008)]
    for x, y, drop in ((0.186, 0.0, 0.07), (0.0, -0.186, 0.09), (0.13, -0.13, 0.05)):
        parts.append(blob(0.016, (x, y, z - drop / 2), sauce("#b3661c"), (0.8, 0.8, drop / 0.032)))
    return parts


def waffles():
    dough = fried("#dba04a")
    parts = plate()
    for x, y, z, turn in ((-0.04, 0.02, 0.0, 12.0), (0.05, -0.03, 0.04, -20.0)):
        base = box((0.24, 0.24, 0.035), (x, y, PLATE_TOP + z + 0.018), dough, 0.008)
        base.rotation_euler = (0.0, 0.0, math.radians(turn))
        parts.append(base)
        for i in range(4):
            for axis in (0, 1):
                size = (0.24, 0.012, 0.014) if axis == 0 else (0.012, 0.24, 0.014)
                offset = (i - 1.5) * 0.06
                rad = math.radians(turn)
                lx, ly = (0.0, offset) if axis == 0 else (offset, 0.0)
                rib = box(size, (x + lx * math.cos(rad) - ly * math.sin(rad), y + lx * math.sin(rad) + ly * math.cos(rad), PLATE_TOP + z + 0.042),
                          dough, 0.003)
                rib.rotation_euler = (0.0, 0.0, rad)
                parts.append(rib)
    parts += cream((0.05, -0.03, PLATE_TOP + 0.1), 0.055)
    parts += strawberry((-0.07, -0.09, PLATE_TOP + 0.075)) + strawberry((0.13, 0.05, PLATE_TOP + 0.105), 0.03)
    return parts


def eggs_benedict():
    parts = plate()
    for x, y in ((-0.1, 0.0), (0.1, -0.02)):
        z = PLATE_TOP
        parts += [cylinder(0.09, z, z + 0.035, fried("#d9a55a"), (x, y), bevel=0.012),
                  cylinder(0.094, z + 0.035, z + 0.05, food("#e58a8a", 0.5, 0.1), (x, y), bevel=0.004),
                  blob(0.078, (x, y, z + 0.07), food("#f6f1e6", 0.35, 0.03, 20.0, 0.05, 0.3), (1.0, 1.0, 0.55)),
                  blob(0.07, (x, y, z + 0.098), sauce("#f2c232"), (1.0, 1.0, 0.3)),
                  herb((x + 0.01, y, z + 0.118), size=0.016)]
    return parts


def acai():
    parts = bowl(ceramic("#6a3a9a"), 0.24, 0.17) + [disc(0.215, 0.16, food("#3a1a4a", 0.5, 0.15, 90.0, 0.4, 0.2))]
    parts += scatter(5, 0.12, 2, lambda x, y, i, rnd: disc(0.036, 0.168, food("#f2dc8a", 0.5, 0.08), (x - 0.04, y)), inner=0.03)
    parts += scatter(9, 0.1, 6, lambda x, y, i, rnd: blob(0.014, (x + 0.07, y + 0.03, 0.17), food("#b3803a", 0.8, 0.2)), inner=0.0)
    return parts + strawberry((0.1, -0.1, 0.19), 0.04)


def pudding():
    flan = food("#e0a23c", 0.25, 0.08, 20.0, 0.08, 0.5)
    caramel = sauce("#8a4212")
    parts = plate() + [disc(0.22, PLATE_TOP + 0.005, caramel),
                       lathe([(0.0, PLATE_TOP), (0.17, PLATE_TOP), (0.165, PLATE_TOP + 0.03), (0.125, PLATE_TOP + 0.16), (0.11, PLATE_TOP + 0.172),
                              (0.0, PLATE_TOP + 0.172)], flan),
                       disc(0.115, PLATE_TOP + 0.176, caramel)]
    return parts


def _pie_slice(crust_color, stack, top_parts):
    outline = wedge()
    crust = fried(crust_color)
    parts, top = layers(outline, [(0.022, crust)] + stack, PLATE_TOP)
    back = outline[1:]
    rim = [(x * 1.0, y * 1.0) for x, y in back] + [(outline[0][0] + (x - outline[0][0]) * 0.9, outline[0][1] + (y - outline[0][1]) * 0.9)
                                                 for x, y in reversed(back)]
    parts.append(prism(rim, PLATE_TOP, top + 0.008, crust, 0.006))
    return plate() + parts + top_parts(top)


def lemon_pie():
    return _pie_slice("#d9a55a", [(0.075, food("#c8d94a", 0.3, 0.08, 20.0, 0.05, 0.4)), (0.05, food("#f6f1e6", 0.5, 0.05, 40.0, 0.2))],
                      lambda top: [blob(0.04, (-0.03, 0.02, top + 0.02), food("#f6f1e6", 0.5, 0.05), (1.0, 1.0, 0.7)),
                                   blob(0.035, (-0.1, 0.0, top + 0.018), food("#f6f1e6", 0.5, 0.05), (1.0, 1.0, 0.7)),
                                   disc(0.05, top + 0.05, food("#9ac83a", 0.4, 0.1), (-0.14, 0.06))])


def cheesecake():
    red = sauce("#a81c2c")
    return _pie_slice("#b3803a", [(0.11, food("#f4e6c0", 0.45, 0.05, 30.0, 0.1)), (0.014, red)],
                      lambda top: [berry((-0.04, 0.0, top + 0.016)), berry((-0.11, 0.04, top + 0.016)), berry((-0.13, -0.05, top + 0.016)),
                                   berry((0.02, -0.01, top + 0.014), size=0.02)])


def black_forest():
    sponge = food("#3a2014", 0.8, 0.2, 120.0, 0.6)
    white = food("#f6f1e6", 0.5, 0.04, 30.0, 0.1)
    return _pie_slice("#3a2014", [(0.045, sponge), (0.025, white), (0.045, sponge), (0.025, white), (0.04, sponge), (0.022, white)],
                      lambda top: cream((-0.05, 0.01, top + 0.01), 0.035) + cream((-0.13, 0.0, top + 0.01), 0.035)
                      + [berry((-0.05, 0.01, top + 0.06), "#8e1422", 0.03), berry((-0.13, 0.0, top + 0.06), "#8e1422", 0.03)])


def petit_gateau():
    choc = food("#3d2113", 0.6, 0.2, 110.0, 0.5)
    z = PLATE_TOP
    parts = plate() + [lathe([(0.0, z), (0.1, z), (0.115, z + 0.03), (0.105, z + 0.13), (0.07, z + 0.15), (0.0, z + 0.152)], choc, (-0.08, 0.0)),
                       disc(0.12, z + 0.004, sauce("#2c160c"), (-0.02, -0.07)),
                       blob(0.075, (0.1, 0.02, z + 0.07), food("#f6ecd2", 0.45, 0.06, 40.0, 0.2))]
    return parts + strawberry((0.02, -0.12, z + 0.035), 0.034)


def caldo_verde():
    parts = bowl(ceramic(), 0.23, 0.15) + [disc(0.205, 0.14, sauce("#7a9a3a"))]
    parts += scatter(5, 0.12, 4, lambda x, y, i, rnd: disc(0.034, 0.146, food("#8e2a22", 0.5, 0.2, 90.0, 0.3), (x, y)), inner=0.03)
    parts += scatter(7, 0.15, 8, lambda x, y, i, rnd: herb((x, y, 0.146), food("#2f6a2c", 0.6, 0.2), 0.024))
    return parts


def feijoada():
    parts = plate() + [p for p in bowl(E.foliage("#000000") if False else solid("#8a4a2c", 0.6), 0.2, 0.14)]
    for p in parts[1:]:
        p.location.z += PLATE_TOP
    z = PLATE_TOP + 0.13
    parts.append(disc(0.178, z, sauce("#2a1410")))
    parts += scatter(12, 0.13, 3, lambda x, y, i, rnd: blob(0.02, (x, y, z + 0.006), food("#3a1c14", 0.3, 0.15, 60.0, 0.1, 0.5), (1.3, 0.9, 0.6),
                                                             (0.0, 0.0, rnd.uniform(0, 180))))
    parts += scatter(3, 0.09, 7, lambda x, y, i, rnd: disc(0.03, z + 0.012, food("#a8382a", 0.5, 0.2), (x, y)), inner=0.02)
    half = [(math.cos(math.radians(a)) * 0.075, math.sin(math.radians(a)) * 0.075) for a in range(0, 181, 15)]
    parts.append(prism([(0.19 + x * 0.6 - y * 0.8, -0.14 + x * 0.8 + y * 0.6) for x, y in half], PLATE_TOP + 0.01, PLATE_TOP + 0.03,
                       food("#f08a1c", 0.4, 0.1), 0.004))
    return parts


def _clay_pot(color, liquid, handles=True):
    clay = solid(color, 0.55)
    parts = [lathe([(0.0, 0.0), (0.13, 0.0), (0.2, 0.03), (0.245, 0.1), (0.235, 0.16), (0.215, 0.16), (0.215, 0.11), (0.18, 0.05), (0.0, 0.04)], clay),
             disc(0.212, 0.145, liquid)]
    if handles:
        for side in (-1, 1):
            at = RIGHT * (0.26 * side)
            parts.append(blob(0.04, (at.x, at.y, 0.135), clay, (1.3, 0.7, 0.4), (0.0, 0.0, 45.0)))
    return parts


def moqueca():
    parts = _clay_pot("#2c2420", sauce("#e0702a"))
    parts += [p for group in ((shrimp((-0.07, 0.04, 0.155), 30.0), shrimp((0.08, -0.03, 0.155), 200.0))) for p in group]
    parts += [box((0.09, 0.05, 0.02), (0.0, -0.09, 0.156), food("#f6ecd2", 0.5, 0.06), 0.008), herb((0.03, 0.08, 0.158)),
              herb((-0.1, -0.05, 0.158)), disc(0.03, 0.156, food("#c9342c", 0.4, 0.1), (0.11, 0.07))]
    return parts


def bobo():
    parts = plate() + bowl(solid("#b3562c", 0.5), 0.2, 0.13)
    for p in parts[1:]:
        p.location.z += PLATE_TOP
    z = PLATE_TOP + 0.122
    parts.append(disc(0.178, z, sauce("#f2a83a")))
    parts += [p for group in (shrimp((-0.05, 0.03, z + 0.012), 20.0), shrimp((0.07, -0.03, z + 0.012), 190.0)) for p in group]
    parts += [herb((0.0, -0.09, z + 0.012)), herb((0.04, 0.09, z + 0.012))]
    return parts


def escondidinho():
    white = ceramic()
    parts = [box((0.5, 0.36, 0.13), (0.0, 0.0, 0.065), white, 0.02),
             box((0.45, 0.31, 0.02), (0.0, 0.0, 0.127), food("#e8c05a", 0.5, 0.25, 30.0, 0.5, 0.2), 0.008)]
    parts += scatter(9, 0.16, 5, lambda x, y, i, rnd: blob(0.035, (x * 1.2, y * 0.8, 0.136), food("#a8641c", 0.5, 0.2, 60.0, 0.4), (1.2, 1.0, 0.18)))
    return parts


def _board(size=(0.6, 0.4)):
    return [box((size[0], size[1], 0.03), (0.0, 0.0, 0.015), board_wood(), 0.01)]


def picanha():
    meat = food("#7a3222", 0.55, 0.2, 110.0, 0.5)
    pink = food("#d9706a", 0.45, 0.1, 60.0, 0.2, 0.2)
    fat = food("#f1dca6", 0.45, 0.08)
    parts = _board()
    for i in range(5):
        x = -0.19 + i * 0.085
        parts += [box((0.03, 0.2, 0.11), (x, 0.0, 0.09), pink, 0.008), box((0.034, 0.204, 0.03), (x, 0.0, 0.142), fat, 0.008),
                  box((0.034, 0.206, 0.014), (x, 0.0, 0.035), meat, 0.004)]
        for p in parts[-3:]:
            p.rotation_euler = (0.0, math.radians(22), 0.0)
    parts += [herb((0.24, -0.1, 0.045), size=0.04), herb((0.25, 0.02, 0.045), size=0.035), blob(0.02, (0.2, 0.13, 0.05), solid("#f1ede4", 0.5))]
    return parts


def barbecue():
    stick = A.rich_wood("#c9a066", 8.0, 0.1)
    parts = _board()
    kinds = ((food("#7a3222", 0.6, 0.2, 110.0, 0.5), 0.05), (food("#a8382a", 0.5, 0.2, 90.0, 0.4), 0.045), (food("#c98a34", 0.6, 0.2, 90.0, 0.4), 0.048))
    for row, y in enumerate((-0.11, 0.0, 0.11)):
        parts.append(tube((-0.3, y, 0.06), (0.32, y, 0.06), 0.006, stick))
        for i in range(5):
            mat, size = kinds[(row + i) % 3]
            parts.append(blob(size, (-0.2 + i * 0.095, y, 0.062), mat, (1.0, 1.0, 0.9)))
    return parts


def curry():
    z = PLATE_TOP
    parts = plate() + [blob(0.1, (-0.09, 0.02, z + 0.035), food("#f6f1e6", 0.7, 0.06, 200.0, 0.6), (1.0, 1.0, 0.75)),
                       blob(0.14, (0.07, -0.02, z + 0.01), sauce("#d9862c"), (1.0, 1.1, 0.28))]
    parts += scatter(5, 0.08, 4, lambda x, y, i, rnd: blob(0.026, (x + 0.07, y - 0.02, z + 0.04), food(("#f2c232", "#c9342c", "#8a5a2c")[i % 3], 0.5, 0.15)))
    return parts + [herb((0.05, -0.04, z + 0.06), size=0.02)]


def paella():
    pan = iron()
    parts = [lathe([(0.0, 0.0), (0.24, 0.0), (0.29, 0.05), (0.3, 0.06), (0.27, 0.06), (0.23, 0.02), (0.0, 0.02)], pan),
             disc(0.262, 0.05, food("#f2c232", 0.6, 0.18, 220.0, 0.6))]
    for side in (-1, 1):
        at = RIGHT * (0.32 * side)
        ring = E.torus(0.04, 0.01, (at.x, at.y, 0.055), pan)
        ring.scale = (1.0, 0.6, 1.0)
        ring.rotation_euler = (0.0, 0.0, math.radians(-45))
        parts.append(ring)
    parts += [p for group in (shrimp((-0.1, 0.06, 0.065), 20.0), shrimp((0.1, -0.02, 0.065), 180.0), shrimp((0.0, -0.13, 0.065), 90.0)) for p in group]
    parts += scatter(4, 0.17, 6, lambda x, y, i, rnd: blob(0.034, (x, y, 0.064), solid("#1d1d24", 0.3, 0.3), (1.3, 0.7, 0.5), (0.0, 0.0, rnd.uniform(0, 180))), inner=0.08)
    parts += scatter(8, 0.18, 9, lambda x, y, i, rnd: blob(0.012, (x, y, 0.06), food("#4f9a3a", 0.5, 0.1)))
    parts.append(prism([(0.06 + x * 0.05, 0.12 + y * 0.05) for x, y in ((-1, -0.5), (1, -0.5), (0, 1))], 0.052, 0.085, food("#f2dc3a", 0.4, 0.1), 0.006))
    return parts


def mushroom_risotto():
    z = PLATE_TOP
    parts = plate() + [blob(0.19, (0.0, 0.0, z + 0.006), food("#f1e6c6", 0.6, 0.1, 240.0, 0.6), (1.0, 1.0, 0.24))]
    def mushroom(x, y, i, rnd):
        cap = food("#a8825a", 0.6, 0.15)
        return [blob(0.036, (x, y, z + 0.055), cap, (1.0, 0.7, 0.45), (0.0, 0.0, rnd.uniform(0, 180))),
                box((0.016, 0.014, 0.012), (x, y, z + 0.046), food("#f1e6c6", 0.6, 0.05), 0.004)]
    parts += scatter(5, 0.11, 2, mushroom, inner=0.02)
    parts += scatter(6, 0.13, 5, lambda x, y, i, rnd: herb((x, y, z + 0.05), size=0.016))
    return parts


def lobster():
    red = food("#c8282a", 0.35, 0.14, 60.0, 0.3, 0.4)
    z = PLATE_TOP + 0.045
    parts = plate()
    for i in range(6):
        size = 0.06 - i * 0.006
        pos = RIGHT * (0.13 - i * 0.055)
        parts.append(blob(size, (pos.x, pos.y, z), red, (1.1, 1.0, 0.8), (0.0, 0.0, 45.0)))
    tail = RIGHT * -0.2
    parts.append(blob(0.06, (tail.x, tail.y, z - 0.015), red, (1.4, 0.8, 0.25), (0.0, 0.0, 45.0)))
    for side in (-1, 1):
        claw = RIGHT * 0.2 + FRONT * (0.11 * side)
        arm = RIGHT * 0.14 + FRONT * (0.06 * side)
        parts.append(tube((arm.x, arm.y, z), (claw.x, claw.y, z), 0.016, red))
        parts.append(blob(0.05, (claw.x + 0.03, claw.y + 0.03, z), red, (1.4, 0.8, 0.6), (0.0, 0.0, 45.0 + side * 20.0)))
        for k in range(3):
            leg = RIGHT * (0.06 - k * 0.05) + FRONT * (0.1 * side)
            root = RIGHT * (0.06 - k * 0.05)
            parts.append(tube((root.x, root.y, z), (leg.x, leg.y, z - 0.03), 0.007, red))
    front = FRONT * 0.17 + RIGHT * -0.1
    parts.append(prism([(front.x + x * 0.06, front.y + y * 0.06) for x, y in ((-1, -0.4), (1, -0.4), (0, 1))], PLATE_TOP + 0.012, PLATE_TOP + 0.05,
                       food("#f2dc3a", 0.4, 0.1), 0.006))
    return parts


def fondue():
    red = solid("#b3262e", 0.3, 0.0, 0.6)
    metal = iron()
    parts = [lathe([(0.0, 0.14), (0.12, 0.14), (0.2, 0.18), (0.215, 0.27), (0.2, 0.3), (0.185, 0.3), (0.19, 0.26), (0.17, 0.2), (0.0, 0.19)], red),
             disc(0.186, 0.285, sauce("#f2c84a")),
             cylinder(0.06, 0.03, 0.07, metal, bevel=0.01), disc(0.17, 0.012, metal, thick=0.012)]
    for a in (30, 150, 270):
        rad = math.radians(a)
        parts.append(tube((math.cos(rad) * 0.15, math.sin(rad) * 0.15, 0.01), (math.cos(rad) * 0.11, math.sin(rad) * 0.11, 0.16), 0.009, metal))
    for side in (-1, 1):
        base = RIGHT * (0.07 * side)
        tip = RIGHT * (0.3 * side) + Vector((0.0, 0.0, 0.62))
        parts.append(tube((base.x, base.y, 0.3), (tip.x, tip.y, tip.z), 0.006, steel()))
        parts.append(box((0.055, 0.055, 0.055), (base.x, base.y, 0.31), fried("#e0b86a"), 0.01))
    return parts


def tacos():
    shell = fried("#e0b040")
    parts = plate()
    for x, turn in ((-0.1, 8.0), (0.1, -8.0)):
        for side in (-1, 1):
            half = disc(0.13, 0.0, shell, thick=0.008)
            half.location = (x + side * 0.03, 0.0, PLATE_TOP + 0.1)
            half.rotation_euler = (0.0, math.radians(90 - side * 24), math.radians(90 + turn))
            parts.append(half)
        parts += [blob(0.07, (x, 0.0, PLATE_TOP + 0.11), food("#6a3a22", 0.7, 0.2, 140.0, 0.6), (0.4, 1.4, 0.8), (0.0, 0.0, turn)),
                  blob(0.06, (x, -0.03, PLATE_TOP + 0.165), food("#4f9a3a", 0.5, 0.2, 90.0, 0.5), (0.5, 1.3, 0.5), (0.0, 0.0, turn)),
                  blob(0.03, (x, 0.07, PLATE_TOP + 0.17), food("#c9342c", 0.4, 0.1)), blob(0.028, (x, -0.09, PLATE_TOP + 0.168), food("#f2c232", 0.4, 0.1))]
    return parts


def sushi():
    slate = solid("#2a2c30", 0.6)
    rice = food("#f6f1e6", 0.7, 0.06, 240.0, 0.6)
    nori = solid("#1c2a22", 0.6)
    parts = [box((0.6, 0.36, 0.028), (0.0, 0.0, 0.014), slate, 0.008)]
    for i, color in enumerate(("#f08a62", "#4f9a3a", "#f2c232")):
        x = -0.2 + i * 0.105
        parts += [cylinder(0.05, 0.028, 0.1, nori, (x, 0.07), bevel=0.004), disc(0.043, 0.102, rice, (x, 0.07)),
                  disc(0.018, 0.104, food(color, 0.4, 0.1), (x, 0.07))]
    for i in range(2):
        x = -0.02 + i * 0.16
        parts += [blob(0.06, (x, -0.08, 0.055), rice, (1.3, 0.75, 0.6)),
                  blob(0.062, (x, -0.08, 0.086), food("#f0703a", 0.35, 0.12, 30.0, 0.15, 0.4), (1.35, 0.8, 0.28))]
    parts += [blob(0.03, (0.22, 0.09, 0.05), food("#8ac84a", 0.6, 0.1)), blob(0.035, (0.23, 0.0, 0.04), food("#f2b0a0", 0.5, 0.1), (1.0, 1.0, 0.5))]
    return parts


def ramen():
    parts = bowl(solid("#b3262e", 0.3, 0.0, 0.6), 0.25, 0.18) + [disc(0.222, 0.165, sauce("#c98a3a"))]
    noodle = food("#f2dc8a", 0.5, 0.06)
    rnd = random.Random(4)
    for i in range(9):
        ring = E.torus(rnd.uniform(0.04, 0.085), 0.008, (rnd.uniform(-0.06, 0.03), rnd.uniform(-0.05, 0.06), 0.17), noodle,
                       (rnd.uniform(-0.3, 0.3), rnd.uniform(-0.3, 0.3), 0.0))
        parts.append(ring)
    parts += [blob(0.045, (0.1, -0.06, 0.178), food("#f6f1e6", 0.4, 0.03), (1.0, 0.75, 0.5)),
              blob(0.022, (0.1, -0.06, 0.19), sauce("#f2a81c"), (1.0, 1.0, 0.5)),
              disc(0.04, 0.178, food("#f6f1e6", 0.5, 0.03), (-0.1, -0.09)), disc(0.02, 0.18, food("#f08ab0", 0.5, 0.05), (-0.1, -0.09)),
              box((0.012, 0.11, 0.12), (0.03, 0.15, 0.2), solid("#1c2a22", 0.6), 0.002), herb((-0.02, 0.0, 0.185), size=0.018),
              herb((0.02, 0.07, 0.185), size=0.018)]
    return parts + chopsticks(0.2)


def misso_soup():
    parts = bowl(solid("#1d1d22", 0.3, 0.0, 0.6), 0.22, 0.17) + [disc(0.195, 0.155, sauce("#b3803a"))]
    parts += scatter(5, 0.1, 3, lambda x, y, i, rnd: box((0.045, 0.045, 0.035), (x, y, 0.158), food("#f6f1e6", 0.5, 0.03), 0.008), inner=0.02)
    parts += scatter(7, 0.13, 8, lambda x, y, i, rnd: disc(0.014, 0.162, food("#4f9a3a", 0.5, 0.1), (x, y)))
    return parts


def mochi():
    z = PLATE_TOP + 0.06
    parts = plate()
    for i, color in enumerate(("#f2a8c0", "#f6f1e6", "#9ac86a")):
        pos = RIGHT * (-0.11 + i * 0.11)
        parts.append(blob(0.058, (pos.x, pos.y, z), food(color, 0.5, 0.05, 30.0, 0.08)))
    a, b = RIGHT * -0.24, RIGHT * 0.26
    parts.append(tube((a.x, a.y, z), (b.x, b.y, z), 0.007, A.rich_wood("#c9a066", 8.0, 0.1)))
    return parts


def tempura():
    crust = fried("#e8b84e")
    z = PLATE_TOP
    parts = plate()
    for i, (x, y, lean) in enumerate(((-0.09, 0.03, -8.0), (0.0, 0.05, 0.0), (0.09, 0.03, 8.0))):
        piece = blob(0.055, (x, y, z + 0.13), crust, (0.75, 0.7, 2.2))
        piece.rotation_euler = (math.radians(18), math.radians(lean), 0.0)
        parts.append(piece)
        parts.append(blob(0.03, (x + lean * 0.002, y + 0.035, z + 0.255), food("#e0562c", 0.4, 0.1), (0.9, 0.5, 0.9)))
    parts += [cylinder(0.065, z, z + 0.05, ceramic(), (0.13, -0.12), bevel=0.01), disc(0.055, z + 0.047, sauce("#3a2112"), (0.13, -0.12))]
    return parts


def yakisoba():
    z = PLATE_TOP
    noodle = food("#e0b85a", 0.45, 0.1, 30.0, 0.1, 0.3)
    parts = plate()
    rnd = random.Random(7)
    for i in range(16):
        ring = E.torus(rnd.uniform(0.05, 0.11), 0.009, (rnd.uniform(-0.07, 0.07), rnd.uniform(-0.06, 0.06), z + 0.02 + i * 0.004), noodle,
                       (rnd.uniform(-0.5, 0.5), rnd.uniform(-0.5, 0.5), 0.0))
        parts.append(ring)
    parts += scatter(8, 0.12, 5, lambda x, y, i, rnd2: blob(0.024, (x, y, z + 0.09), food(("#c9342c", "#4f9a3a", "#f08a1c", "#7a3222")[i % 4], 0.5, 0.15),
                                                             (1.3, 0.7, 0.5), (0.0, 0.0, rnd2.uniform(0, 180))))
    return parts + chopsticks(z + 0.1)


DISHES = {
    "coffee": coffee, "cheese_bread": cheese_bread, "toasted_sandwich": toasted_sandwich, "carrot_cake": carrot_cake, "coxinha": coxinha,
    "lasagna": lasagna, "brigadeiro": brigadeiro, "pastel": pastel, "burger": burger, "pizza": pizza, "croissant": croissant,
    "pancakes": pancakes, "waffles": waffles, "eggs_benedict": eggs_benedict, "acai": acai, "pudding": pudding, "lemon_pie": lemon_pie,
    "cheesecake": cheesecake, "black_forest": black_forest, "petit_gateau": petit_gateau, "caldo_verde": caldo_verde, "feijoada": feijoada,
    "moqueca": moqueca, "bobo": bobo, "escondidinho": escondidinho, "picanha": picanha, "barbecue": barbecue, "curry": curry,
    "paella": paella, "mushroom_risotto": mushroom_risotto, "lobster": lobster, "fondue": fondue, "tacos": tacos, "sushi": sushi,
    "ramen": ramen, "misso_soup": misso_soup, "mochi": mochi, "tempura": tempura, "yakisoba": yakisoba,
}


# --- Panelas ----------------------------------------------------------------------------------------------------

def bits(colors, count, radius, z, seed, size=0.03):
    """Pedaços boiando ou fritando: bolinhas achatadas nas cores da receita."""
    return scatter(count, radius, seed, lambda x, y, i, rnd: blob(size * rnd.uniform(0.8, 1.2), (x, y, z), food(colors[i % len(colors)], 0.5, 0.15),
                                                                   (1.2, 1.0, 0.5), (0.0, 0.0, rnd.uniform(0, 180))))


def saucepan(liquid, colors, seed, count=6):
    """Panela funda de aço com duas alças, cheia até perto da borda."""
    metal = steel()
    parts = [lathe([(0.0, 0.0), (0.24, 0.0), (0.255, 0.012), (0.26, 0.24), (0.268, 0.25), (0.25, 0.25), (0.245, 0.03), (0.0, 0.025)], metal),
             disc(0.246, 0.215, sauce(liquid))]
    for side in (-1, 1):
        at = RIGHT * (0.3 * side)
        grip = E.torus(0.045, 0.011, (at.x, at.y, 0.2), iron())
        grip.scale = (1.0, 0.55, 1.0)
        grip.rotation_euler = (0.0, 0.0, math.radians(-45))
        parts.append(grip)
    return parts + bits(colors, count, 0.17, 0.222, seed)


def frying_pan(colors, seed, count=4, oil="#3a2a1c", size=0.06):
    """Frigideira de ferro com o cabo para a direita."""
    pan = iron()
    parts = [lathe([(0.0, 0.0), (0.22, 0.0), (0.28, 0.06), (0.292, 0.066), (0.27, 0.066), (0.215, 0.02), (0.0, 0.02)], pan),
             disc(0.22, 0.026, sauce(oil))]
    a, b = RIGHT * 0.27 + FRONT * 0.03, RIGHT * 0.62 + FRONT * 0.1
    parts.append(tube((a.x, a.y, 0.06), (b.x, b.y, 0.09), 0.02, solid("#1a1a1e", 0.6)))
    return parts + scatter(count, 0.14, seed, lambda x, y, i, rnd: blob(size * rnd.uniform(0.85, 1.1), (x, y, 0.045),
                                                                         food(colors[i % len(colors)], 0.55, 0.18, 90.0, 0.4), (1.2, 1.0, 0.4),
                                                                         (0.0, 0.0, rnd.uniform(0, 180))), inner=0.03)


def baking_dish(top, colors, seed, count=5):
    """Travessa de louça que vai ao forno, com a comida gratinando."""
    parts = [box((0.56, 0.42, 0.13), (0.0, 0.0, 0.065), ceramic(), 0.024),
             box((0.5, 0.36, 0.02), (0.0, 0.0, 0.126), food(top, 0.5, 0.22, 30.0, 0.5, 0.2), 0.008)]
    return parts + scatter(count, 0.16, seed, lambda x, y, i, rnd: blob(0.04, (x * 1.2, y * 0.85, 0.136), food(colors[i % len(colors)], 0.5, 0.2),
                                                                         (1.2, 1.0, 0.2), (0.0, 0.0, rnd.uniform(0, 180))))


def tin(filling, colors, seed, count=5, tall=0.09):
    """Forma redonda de alumínio (tortas, pudim, pizza)."""
    parts = [lathe([(0.0, 0.0), (0.25, 0.0), (0.27, tall), (0.28, tall + 0.006), (0.262, tall + 0.006), (0.245, 0.02), (0.0, 0.02)], steel()),
             disc(0.258, tall - 0.012, food(filling, 0.4, 0.14, 30.0, 0.2, 0.3))]
    return parts + bits(colors, count, 0.17, tall - 0.004, seed, 0.028)


def sheet_tray(make):
    """Assadeira baixa de ferro."""
    return [box((0.6, 0.44, 0.03), (0.0, 0.0, 0.015), iron(), 0.008)] + make(0.03)


def cutting_board(make):
    return [box((0.6, 0.4, 0.035), (0.0, 0.0, 0.0175), board_wood(), 0.01)] + make(0.035)


def moka():
    """Cafeteira italiana: as duas metades facetadas, a tampa, o bico e o cabo."""
    metal = steel()
    parts = [E.cone(0.13, 0.0, 0.16, metal, (0.0, 0.0), 0.085, 8), E.cone(0.085, 0.16, 0.34, metal, (0.0, 0.0), 0.125, 8),
             cylinder(0.092, 0.15, 0.17, metal, bevel=0.004), E.cone(0.125, 0.34, 0.37, metal, (0.0, 0.0), 0.03, 8),
             blob(0.02, (0.0, 0.0, 0.385), solid("#1a1a1e", 0.5))]
    at = RIGHT * 0.16
    parts.append(tube((at.x * 0.6, at.y * 0.6, 0.32), (at.x, at.y, 0.3), 0.012, solid("#1a1a1e", 0.5)))
    parts.append(tube((at.x, at.y, 0.3), (at.x * 0.95, at.y * 0.95, 0.19), 0.012, solid("#1a1a1e", 0.5)))
    spout = RIGHT * -0.14
    parts.append(tube((spout.x * 0.6, spout.y * 0.6, 0.31), (spout.x, spout.y, 0.335), 0.014, metal))
    return parts


def _balls(color, count, size):
    return lambda z: scatter(count, 0.19, 3, lambda x, y, i, rnd: blob(size, (x * 1.2, y * 0.85, z + size * 0.8), food(color, 0.6, 0.2, 90.0, 0.5),
                                                                        (1.0, 1.0, 0.86)), inner=0.02)


def _rolls(colors):
    def make(z):
        parts = []
        for i, color in enumerate(colors):
            x = -0.16 + i * 0.16
            parts += [cylinder(0.055, z, z + 0.075, solid("#1c2a22", 0.6), (x, 0.0), bevel=0.004),
                      disc(0.047, z + 0.077, food("#f6f1e6", 0.7, 0.06, 240.0, 0.6), (x, 0.0)), disc(0.02, z + 0.079, food(color, 0.4, 0.1), (x, 0.0))]
        return parts
    return make


COOKWARE = {
    "coffee": moka,
    "cheese_bread": lambda: sheet_tray(_balls("#e8b84e", 8, 0.06)),
    "toasted_sandwich": lambda: sheet_tray(lambda z: [box((0.2, 0.2, 0.06), (x, y, z + 0.03), fried("#d9a04e"), 0.012) for x, y in ((-0.13, 0.03), (0.13, -0.03))]),
    "carrot_cake": lambda: tin("#e58a2c", ["#f2a84a"], 2, 3, 0.16),
    "coxinha": lambda: saucepan("#c98a1c", ["#c9842c", "#d99a3a"], 3, 5),
    "lasagna": lambda: baking_dish("#e8a83a", ["#a8382a", "#f2d27a"], 4),
    "brigadeiro": lambda: saucepan("#3d2113", ["#5a3220"], 5, 4),
    "pastel": lambda: frying_pan(["#e0a84a"], 6, 3, "#c98a1c", 0.08),
    "burger": lambda: frying_pan(["#5a3220", "#5a3220", "#f2b72c"], 7, 3, size=0.075),
    "pizza": lambda: tin("#b3342a", ["#f2d27a", "#a8262a", "#f2d27a"], 8, 7, 0.04),
    "croissant": lambda: baking_dish("#e8c890", ["#d9953a"], 9, 4),
    "pancakes": lambda: frying_pan(["#e0a04a"], 10, 2, size=0.1),
    "waffles": lambda: baking_dish("#e8c890", ["#dba04a"], 11, 4),
    "eggs_benedict": lambda: frying_pan(["#f6f1e6", "#f2c232", "#f6f1e6"], 12, 3, size=0.075),
    "acai": lambda: tin("#3a1a4a", ["#5a2a6a", "#f2dc8a"], 13, 5, 0.07),
    "pudding": lambda: tin("#e0a23c", ["#8a4212"], 14, 4, 0.11),
    "lemon_pie": lambda: tin("#c8d94a", ["#f6f1e6"], 15, 5, 0.07),
    "cheesecake": lambda: tin("#f4e6c0", ["#a81c2c"], 16, 5, 0.08),
    "black_forest": lambda: tin("#3a2014", ["#8e1422", "#f6f1e6"], 17, 6, 0.1),
    "petit_gateau": lambda: baking_dish("#4a2a1a", ["#3d2113"], 18, 4),
    "caldo_verde": lambda: saucepan("#7a9a3a", ["#8e2a22", "#2f6a2c"], 19),
    "feijoada": lambda: saucepan("#2a1410", ["#a8382a", "#3a1c14"], 20),
    "moqueca": lambda: saucepan("#e0702a", ["#f08a62", "#3f8a3a", "#f6ecd2"], 21),
    "bobo": lambda: saucepan("#f2a83a", ["#f08a62", "#3f8a3a"], 22),
    "escondidinho": lambda: baking_dish("#e8c05a", ["#a8641c"], 23, 6),
    "picanha": lambda: frying_pan(["#7a3222", "#8e3a2a"], 24, 3, size=0.085),
    "barbecue": lambda: frying_pan(["#7a3222", "#a8382a", "#c98a34"], 25, 5, size=0.06),
    "curry": lambda: saucepan("#d9862c", ["#f2c232", "#c9342c", "#8a5a2c"], 26),
    "paella": lambda: frying_pan(["#f08a62", "#1d1d24", "#4f9a3a"], 27, 6, "#f2c232", 0.05),
    "mushroom_risotto": lambda: frying_pan(["#a8825a", "#f1e6c6"], 28, 5, "#f1e6c6", 0.05),
    "lobster": lambda: saucepan("#c9d9e0", ["#c8282a"], 29, 3),
    "fondue": lambda: saucepan("#f2c84a", ["#f6e08a"], 30, 3),
    "tacos": lambda: frying_pan(["#6a3a22", "#4f9a3a", "#c9342c"], 31, 5, size=0.055),
    "sushi": lambda: cutting_board(_rolls(("#f08a62", "#4f9a3a", "#f2c232"))),
    "ramen": lambda: saucepan("#c98a3a", ["#f2dc8a", "#f6f1e6"], 32),
    "misso_soup": lambda: saucepan("#b3803a", ["#f6f1e6", "#4f9a3a"], 33),
    "mochi": lambda: cutting_board(lambda z: [blob(0.06, (x, 0.0, z + 0.05), food(c, 0.5, 0.05, 30.0, 0.08)) for x, c in ((-0.15, "#f2a8c0"), (0.0, "#f6f1e6"), (0.15, "#9ac86a"))]),
    "tempura": lambda: saucepan("#c98a1c", ["#e8b84e", "#e0b040"], 34, 4),
    "yakisoba": lambda: frying_pan(["#e0b85a", "#c9342c", "#4f9a3a", "#e0b85a"], 35, 7, size=0.055),
}


# --- Fotos ------------------------------------------------------------------------------------------------------

def no_floor():
    """Deixa o chão que recebe a sombra fora da foto, mas ainda rebatendo luz: o prato vai para mesas, bandejas e balões, e a
    panela para cima do fogão. Esconder o chão de vez escurece a comida, porque a luz que ele rebate some junto."""
    for obj in bpy.data.objects:
        if obj.is_shadow_catcher:
            obj.visible_camera = False


def render_dish(recipe, samples, anchors):
    cena3d.setup(samples, DISH_IMAGE, shadow_center=(0.0, 0.0), shadow_size=(0.9, 0.9), rig="a")
    no_floor()
    list(M._flatten(DISHES[recipe]()))
    aim_camera((0.0, 0.0, ANCHOR_LIFT))
    name = f"prato_{recipe}"
    anchors[name] = cena3d.shoot(name, (0.0, 0.0, ANCHOR_LIFT), WORK)


def render_pot(recipe, samples, anchors):
    cena3d.setup(samples, POT_IMAGE, shadow_size=0.01, rig="a")
    no_floor()
    objects = list(M._flatten(COOKWARE[recipe]()))
    for obj in objects:
        obj.location.z += POT_Z
    anchor, center = M.assemble(objects, (1, 1), 0)
    aim_camera((center[0], center[1], POT_Z + 0.1))
    name = f"panela_{recipe}"
    anchors[name] = cena3d.shoot(name, anchor, WORK)


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    samples = 24 if "rascunho" in args else 96
    recipes = [a for a in args if a in DISHES] or list(DISHES)
    kinds = [a for a in args if a in ("pratos", "panelas")] or ["pratos", "panelas"]
    os.makedirs(WORK, exist_ok=True)
    anchors = {}
    for recipe in recipes:
        if "pratos" in kinds:
            render_dish(recipe, samples, anchors)
        if "panelas" in kinds:
            render_pot(recipe, samples, anchors)
        cena3d.update_manifest(anchors)   # a cada receita: se a próxima falhar, as fotos prontas não perdem a âncora
        print("PRONTO", recipe, flush=True)
    print("PRATOS OK", len(anchors), flush=True)


if __name__ == "__main__":
    main()
