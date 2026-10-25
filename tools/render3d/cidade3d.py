"""A cidade em volta do café em 3D (arte realista, DT-087): os prédios de Nova York (com a camada das janelas acesas à
noite), os enfeites da calçada, os semáforos e os carros, gravados em art/sprites.

Uso (na pasta do projeto):
    C:/Blender/blender-5.2.3-windows-x64/blender.exe -b -P tools/render3d/cidade3d.py -- [grupos ou nomes...] [rascunho]

Grupos: predios, rua, carros (sem nada, faz todos).

Encaixe (o mesmo da arte 2D): o prédio de pegada (w, d) ocupa os pisos (0, 0) a (w, d) do jogo e a âncora é o vértice
da frente (w, d); enfeites e carros têm a âncora no ponto do chão. A camada "_luz" de cada prédio tem só as janelas
acesas: o resto do prédio entra como recorte (holdout), para o prédio da frente continuar cobrindo as luzes de trás.
"""
import math
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cena3d  # noqa: E402
from cena3d import DESIGN_Z as PX, aim_camera, linear  # noqa: E402
import moveis3d as M  # noqa: E402
from moveis3d import box, chrome, cylinder, emission, lacquer, solid, sphere, tube, wood  # noqa: E402
import enfeites3d as E  # noqa: E402

WORK = os.path.join(cena3d.ROOT, "tools", "render3d", "out_cidade")
FONT = os.path.join(cena3d.ROOT, "art", "fonts", "Fredoka-Variable.ttf")
FLOOR_H = 46 * PX           # altura de um andar e do térreo, como na arte 2D
GROUND_H = 58 * PX
DAY_LIT, NIGHT_LIT = 0.18, 0.5
IRON = "#2b2d36"

# id -> (pegada, desenho), com os estilos da arte 2D (city3.BUILDINGS)
STYLES = {
    "predio_brownstone": ((3, 2), dict(floors=3, color="#9a5b45", trim="#d9c3a5", stoop=True, arch=True, seed=4, door="#4a2a1f")),
    "predio_tijolo": ((3, 3), dict(floors=5, color="#b5513d", trim="#e8dccb", brick=True, fire_escape=True, water_tower=True, seed=7)),
    "predio_deli": ((2, 2), dict(floors=3, color="#d8c7a4", trim="#ffffff", shop=("DELI", "#2f9e62"), seed=9)),
    "predio_pizza": ((2, 3), dict(floors=4, color="#7f8fa6", trim="#f1ece2", shop=("PIZZA", "#e8483c"), fire_escape=True, seed=13)),
    "predio_azul": ((3, 2), dict(floors=4, color="#4a6fa5", trim="#f4efe6", brick=True, water_tower=True, seed=17)),
    "predio_vidro": ((3, 3), dict(glass=True, floors=10, seed=41)),
    "predio_deco": ((3, 3), dict(deco=True, seed=43)),
}


def _hash(*values):
    """Número de 0 a 1 sempre igual para os mesmos valores (o sorteio das janelas acesas)."""
    h = 2166136261
    for v in values:
        h = ((h ^ (int(v) & 0xFFFFFFFF)) * 16777619) & 0xFFFFFFFF
    return (h % 10007) / 10007.0


# --- Materiais da cidade --------------------------------------------------------------------------------------

def brick(color):
    return _cached(("brick", color), lambda nodes, links, bsdf: _brick_nodes(nodes, links, bsdf, color))


def _brick_nodes(nodes, links, bsdf, color):
    tex = nodes.new("ShaderNodeTexBrick")
    tex.offset = 0.5
    tex.inputs["Scale"].default_value = 1.0
    tex.inputs["Brick Width"].default_value = 0.16
    tex.inputs["Row Height"].default_value = 0.055
    tex.inputs["Mortar Size"].default_value = 0.006
    tex.inputs["Color1"].default_value = linear(color)
    tex.inputs["Color2"].default_value = linear(M._shade(color, 0.18))
    tex.inputs["Mortar"].default_value = linear("#d9d0c4")
    coords = nodes.new("ShaderNodeTexCoord")
    sep = nodes.new("ShaderNodeSeparateXYZ")
    comb = nodes.new("ShaderNodeCombineXYZ")
    add = nodes.new("ShaderNodeMath")
    links.new(coords.outputs["Object"], sep.inputs["Vector"])
    links.new(sep.outputs["X"], add.inputs[0])
    links.new(sep.outputs["Y"], add.inputs[1])
    links.new(add.outputs[0], comb.inputs["X"])
    links.new(sep.outputs["Z"], comb.inputs["Y"])
    links.new(comb.outputs["Vector"], tex.inputs["Vector"])
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.4
    links.new(tex.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    bsdf.inputs["Roughness"].default_value = 0.85


def stone(color):
    def build(nodes, links, bsdf):
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 30.0
        links.new(M._coords(nodes, 1.0), noise.inputs["Vector"])
        links.new(M._ramp(nodes, links, noise.outputs["Fac"], M._shade(color, 0.06), color, (0.3, 0.7)), bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.8
    return _cached(("stone", color), build)


def window_glass(lit):
    """Vidro da janela: de dia, o reflexo do céu azulado; acesa, a luz quente de dentro."""
    def build(nodes, links, bsdf):
        bsdf.inputs["Base Color"].default_value = linear("#5d7ea0" if not lit else "#ffd998")
        bsdf.inputs["Roughness"].default_value = 0.05
        bsdf.inputs["Metallic"].default_value = 0.0 if lit else 0.6
        bsdf.inputs["Coat Weight"].default_value = 1.0
        if lit:
            bsdf.inputs["Emission Color"].default_value = linear("#ffc46a")
            bsdf.inputs["Emission Strength"].default_value = 1.2
    return _cached(("window", lit), build)


def holdout():
    key = ("holdout",)
    if key not in M._materials:
        mat = bpy.data.materials.new("Recorte")
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        nodes.clear()
        out = nodes.new("ShaderNodeOutputMaterial")
        hold = nodes.new("ShaderNodeHoldout")
        mat.node_tree.links.new(hold.outputs[0], out.inputs["Surface"])
        M._materials[key] = mat
    return M._materials[key]


def _cached(key, build):
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("_".join(str(k) for k in key))
        build(nodes, links, bsdf)
        M._materials[key] = mat
    return M._materials[key]


# --- Prédios -------------------------------------------------------------------------------------------------
# O prédio ocupa X de 0 a w e Y de -d a 0; aparecem a face da frente esquerda (Y = -d, o +y do jogo) e a da
# direita (X = w, o +x do jogo).

class Building:
    def __init__(self, w, d):
        self.w, self.d = w, d
        self.parts = []
        self.lit_night = []      # vidros que acendem à noite

    def add(self, *objs):
        for obj in M._flatten(objs):
            self.parts.append(obj)

    def window(self, face, u, z, width, height, frame, seed, index, arch=False):
        """Janela na face ('L' = Y -d, 'R' = X w), com o centro em u (0 a 1 ao longo da face) e a base em z."""
        h = _hash(seed, index)
        lit_day, lit_night = h < DAY_LIT, h < NIGHT_LIT
        t = 0.03
        if face == "L":
            x, y = u * self.w, -self.d
            # o vidro fica um pouco à frente da fachada, com o fundo escuro (o vão) logo atrás dele
            recess = box((width + 0.01, 0.003, height + 0.01), (x, y - 0.002, z + height / 2), solid("#2a2a30", 0.8), 0.0)
            glass = box((width - 0.02, 0.004, height - 0.02), (x, y - 0.006, z + height / 2), window_glass(lit_day), 0.0)
            frames = [box((width + 0.04, 0.03, t), (x, y - 0.014, z + height), solid(frame, 0.4), 0.004),
                      box((width + 0.08, 0.06, t), (x, y - 0.025, z - 0.005), solid(frame, 0.4), 0.004),
                      box((t * 0.6, 0.02, height), (x, y - 0.012, z + height / 2), solid(frame, 0.4), 0.0)]
        else:
            x, y = self.w, -u * self.d
            recess = box((0.003, width + 0.01, height + 0.01), (x + 0.002, y, z + height / 2), solid("#2a2a30", 0.8), 0.0)
            glass = box((0.004, width - 0.02, height - 0.02), (x + 0.006, y, z + height / 2), window_glass(lit_day), 0.0)
            frames = [box((0.03, width + 0.04, t), (x + 0.014, y, z + height), solid(frame, 0.4), 0.004),
                      box((0.06, width + 0.08, t), (x + 0.025, y, z - 0.005), solid(frame, 0.4), 0.004),
                      box((0.02, t * 0.6, height), (x + 0.012, y, z + height / 2), solid(frame, 0.4), 0.0)]
        self.add(recess, glass, frames)
        if lit_night:
            self.lit_night.append(glass)
        if arch:
            cap = sphere(width / 2, (x, y, z + height), solid(frame, 0.4), (1.0, 0.25, 0.45) if face == "L" else (0.25, 1.0, 0.45))
            self.add(cap)

    def windows(self, z0, floors, floor_h, frame, seed, arch=False, per_unit=1.5, wide=0.56):
        index = 0
        for face, length in (("L", self.w), ("R", self.d)):
            cols = max(1, round(length * per_unit))
            for fl in range(floors):
                for c in range(cols):
                    u = (c + 0.5) / cols
                    self.window(face, u, z0 + fl * floor_h + floor_h * 0.22, wide / cols * length, floor_h * 0.6, frame, seed, index, arch)
                    index += 1


def classic_building(w, d, style):
    b = Building(w, d)
    floors = style["floors"]
    top = GROUND_H + floors * FLOOR_H
    body = brick(style["color"]) if style.get("brick") else stone(style["color"])
    b.add(box((w, d, top), (w / 2, -d / 2, top / 2), body, 0.0))
    trim = solid(style["trim"], 0.6)
    b.add(box((w + 0.04, d + 0.04, 0.1), (w / 2, -d / 2, GROUND_H - 0.05), trim, 0.006))
    for fl in range(1, floors):
        b.add(box((w + 0.02, d + 0.02, 0.03), (w / 2, -d / 2, GROUND_H + fl * FLOOR_H), trim, 0.0))
    b.add(box((w + 0.12, d + 0.12, 0.12), (w / 2, -d / 2, top + 0.06), trim, 0.01))
    b.add(box((w + 0.06, d + 0.06, 0.05), (w / 2, -d / 2, top - 0.05), solid(M._shade(style["trim"], 0.15), 0.6), 0.004))
    frame = style.get("frame", "#ffffff")
    shop = style.get("shop")
    if shop:
        text, color = shop
        fronts = [box((w * 0.84, 0.02, GROUND_H * 0.62), (w * 0.5, -d - 0.005, GROUND_H * 0.38), window_glass(True), 0.004),
                  box((0.02, d * 0.7, GROUND_H * 0.62), (w + 0.005, -d * 0.5, GROUND_H * 0.38), window_glass(True), 0.004)]
        b.add(fronts)
        b.lit_night.extend(fronts)   # as vitrines ficam acesas à noite
        b.add(box((0.24, 0.03, GROUND_H * 0.62), (w * 0.85, -d - 0.012, GROUND_H * 0.31), solid("#2a3b4a", 0.4), 0.006))
        awning = M.fabric("plain", color)
        canopy = box((w * 0.9, 0.36, 0.03), (w * 0.5, -d - 0.17, GROUND_H - 0.12), awning, 0.01)
        canopy.rotation_euler = (math.radians(-24), 0, 0)
        b.add(canopy, box((w * 0.9, 0.012, 0.1), (w * 0.5, -d - 0.33, GROUND_H - 0.24), awning, 0.004))
        b.add(box((0.62, 0.04, 0.16), (w * 0.42, -d - 0.03, GROUND_H * 0.86), lacquer(M._shade(color, 0.2)), 0.01))
        bpy.ops.object.text_add(location=(w * 0.42, -d - 0.052, GROUND_H * 0.86 - 0.045), rotation=(math.radians(90), 0, 0))
        sign = bpy.context.active_object
        sign.data.body = text
        sign.data.font = bpy.data.fonts.load(FONT, check_existing=True)
        sign.data.align_x = "CENTER"
        sign.data.size = 0.12
        sign.data.materials.append(emission("#ffffff", 2.0))
        b.add(sign)
    else:
        b.windows(0.06, 1, GROUND_H - 0.18, frame, style["seed"] + 11, per_unit=1.2)
        door_color = lacquer(style.get("door", "#5a2f22"))
        if style.get("stoop"):
            for i in range(4):
                b.add(box((0.36, 0.08 * (i + 1), 0.07), (w * 0.5, -d - 0.04 * (i + 1), 0.07 * (3 - i) + 0.035), stone("#b9a68e"), 0.004))
            b.add(box((0.26, 0.03, 0.52), (w * 0.5, -d - 0.012, 0.28 + 0.26), door_color, 0.008))
        else:
            b.add(box((0.26, 0.03, 0.58), (w * 0.5, -d - 0.012, 0.29), door_color, 0.008))
    b.windows(GROUND_H, floors, FLOOR_H, frame, style["seed"], style.get("arch", False))
    if style.get("fire_escape"):
        iron = solid(IRON, 0.5, 0.6)
        for fl in range(floors):
            z = GROUND_H + fl * FLOOR_H + 0.02
            b.add(box((w * 0.44, 0.28, 0.02), (w * 0.41, -d - 0.14, z), iron, 0.0))
            b.add(box((w * 0.44, 0.012, 0.012), (w * 0.41, -d - 0.28, z + 0.2), iron, 0.0))
            for i in range(7):
                b.add(box((0.008, 0.008, 0.2), (w * 0.19 + i * w * 0.44 / 6, -d - 0.28, z + 0.1), iron, 0.0))
            if fl + 1 < floors:
                b.add(tube((w * 0.25, -d - 0.14, z), (w * 0.57, -d - 0.14, z + FLOOR_H), 0.012, iron))
    if style.get("water_tower"):
        x, y, z = w * 0.35, -d * 0.35, top + 0.12
        legs = solid("#6b4a35", 0.7)
        for lx, ly in ((-0.18, -0.18), (0.18, -0.18), (-0.18, 0.18), (0.18, 0.18)):
            b.add(tube((x + lx, y + ly, z), (x + lx * 0.8, y + ly * 0.8, z + 0.28), 0.015, legs))
        b.add(cylinder(0.26, z + 0.28, z + 0.78, wood("#9a6a45"), (x, y), bevel=0.01, vertices=24))
        for zz in (z + 0.38, z + 0.53, z + 0.68):
            b.add(E.torus(0.262, 0.008, (x, y, zz), solid(IRON, 0.5, 0.6)))
        b.add(E.cone(0.29, z + 0.78, z + 1.0, wood("#7a5236"), (x, y)))
    return b


def glass_tower(w, d, floors, seed):
    b = Building(w, d)
    fh = 30 * PX
    body = floors * fh
    curtain = window_glass(False)
    b.add(box((w, d, body), (w / 2, -d / 2, body / 2), curtain, 0.0))
    mullion = solid("#cfd8e2", 0.3, 0.8)
    for fl in range(floors + 1):
        b.add(box((w + 0.02, d + 0.02, 0.025), (w / 2, -d / 2, fl * fh), mullion, 0.0))
    for face, length in (("L", w), ("R", d)):
        cols = round(length * 3)
        for c in range(cols + 1):
            if face == "L":
                b.add(box((0.02, 0.02, body), (c / cols * w, -d - 0.006, body / 2), mullion, 0.0))
            else:
                b.add(box((0.02, 0.02, body), (w + 0.006, -c / cols * d, body / 2), mullion, 0.0))
        for fl in range(floors):
            for c in range(cols):
                if _hash(seed, fl, c, ord(face)) < 0.42:
                    if face == "L":
                        pane = box((length / cols - 0.03, 0.006, fh - 0.04), ((c + 0.5) / cols * w, -d - 0.004, fl * fh + fh / 2), window_glass(False), 0.0)
                    else:
                        pane = box((0.006, length / cols - 0.03, fh - 0.04), (w + 0.004, -(c + 0.5) / cols * d, fl * fh + fh / 2), window_glass(False), 0.0)
                    b.add(pane)
                    b.lit_night.append(pane)
    b.add(box((w * 0.6, d * 0.6, 26 * PX), (w / 2, -d / 2, body + 13 * PX), solid("#4a8ac0", 0.2, 0.5), 0.0))
    b.add(tube((w / 2, -d / 2, body + 26 * PX), (w / 2, -d / 2, body + 60 * PX), 0.012, mullion))
    return b


def deco_tower(w, d, seed):
    b = Building(w, d)
    z = 0.0
    stone_mat = stone("#e7d8b8")
    for i, (inset, floors) in enumerate(((0.0, 7), (0.15, 3), (0.28, 2))):
        x0, y0 = w * inset, d * inset
        ww, dd = w * (1 - 2 * inset), d * (1 - 2 * inset)
        h = floors * FLOOR_H
        b.add(box((ww, dd, h), (x0 + ww / 2, -(y0 + dd / 2), z + h / 2), stone_mat, 0.0))
        for face, length in (("L", ww), ("R", dd)):
            cols = max(2, round(length * 2))
            for c in range(cols):
                for fl in range(floors):
                    lit = _hash(seed, i, c, fl, ord(face)) < NIGHT_LIT
                    zc = z + fl * FLOOR_H + FLOOR_H * 0.5
                    if face == "L":
                        pane = box((length / cols * 0.4, 0.01, FLOOR_H * 0.7), (x0 + (c + 0.5) / cols * ww, -(y0 + dd) - 0.004, zc), window_glass(False), 0.0)
                    else:
                        pane = box((0.01, length / cols * 0.4, FLOOR_H * 0.7), (x0 + ww + 0.004, -(y0 + (c + 0.5) / cols * dd), zc), window_glass(False), 0.0)
                    b.add(pane)
                    if lit:
                        b.lit_night.append(pane)
        z += h
    b.add(cylinder(0.06, z, z + 30 * PX, solid("#d8c58f", 0.3, 0.8), (w / 2, -d / 2)))
    b.add(E.cone(0.05, z + 30 * PX, z + 70 * PX, solid("#e9dcae", 0.3, 0.8), (w / 2, -d / 2)))
    return b


def build(name):
    (w, d), style = STYLES[name]
    if style.get("glass"):
        return glass_tower(w, d, style["floors"], style["seed"])
    if style.get("deco"):
        return deco_tower(w, d, style["seed"])
    return classic_building(w, d, style)


def building_top(style):
    """Altura do topo (com a caixa d'água ou a ponta), para o tamanho da foto."""
    if style.get("glass"):
        return style["floors"] * 30 * PX + 60 * PX
    if style.get("deco"):
        return 12 * FLOOR_H + 70 * PX
    return GROUND_H + style["floors"] * FLOOR_H + (1.1 if style.get("water_tower") else 0.2)


def shoot_building(name, samples, anchors):
    (w, d), style = STYLES[name]
    top = building_top(style)
    width = int(128 * (w + d) + 200)
    height = int((top * math.cos(math.radians(30.0)) + (w + d) * 0.36) * cena3d.PX_PER_UNIT + 240)
    cena3d.setup(samples, (width, height), shadow_center=(w / 2, -d / 2), shadow_size=(w + 0.3, d + 0.3))
    b = build(name)
    aim_camera((w / 2, -d / 2, top / 2))
    anchors[name] = cena3d.shoot(name, (w, -d, 0.0), WORK)
    # a camada da noite: só os vidros acesos; o resto é recorte
    for obj in b.parts:
        if obj.type in ("MESH", "FONT"):
            obj.data.materials.clear()
            obj.data.materials.append(emission("#ffc46a", 2.2) if obj in b.lit_night else holdout())
    for obj in bpy.data.objects:
        if obj.type == "MESH" and getattr(obj, "is_shadow_catcher", False):
            obj.hide_render = True
    anchors[name + "_luz"] = cena3d.shoot(name + "_luz", (w, -d, 0.0), WORK)


# --- Rua -----------------------------------------------------------------------------------------------------

LAMP_HEAD = (0.36, 0.0, 1.95)


def street_lamp():
    iron = solid("#2f5444", 0.4, 0.5)
    parts = [cylinder(0.07, 0.0, 0.14, iron, bevel=0.01), cylinder(0.03, 0.14, 1.95, iron)]
    parts.append(tube((0.0, 0.0, 1.9), (0.12, 0.0, 2.1), 0.022, iron))
    parts.append(tube((0.12, 0.0, 2.1), (0.36, 0.0, 2.1), 0.022, iron))
    parts.append(E.cone(0.09, 1.92, 2.08, E.glass("#fff4c8", 0.5), LAMP_HEAD[:2], top_radius=0.06))
    parts.append(E.cone(0.1, 2.06, 2.14, iron, LAMP_HEAD[:2], top_radius=0.0))
    parts.append(sphere(0.035, (LAMP_HEAD[0], 0.0, 2.0), emission("#ffe6a0", 8.0)))
    return parts


def hydrant():
    red = lacquer("#d6283a")
    return [cylinder(0.1, 0.0, 0.05, red, bevel=0.01), cylinder(0.065, 0.05, 0.28, red), sphere(0.068, (0, 0, 0.28), red, (1, 1, 0.8)),
            tube((-0.11, 0, 0.2), (0.11, 0, 0.2), 0.025, red), cylinder(0.02, 0.34, 0.37, red)]


def street_tree():
    parts = [box((0.6, 0.6, 0.02), (0, 0, 0.01), solid("#4a3a2a", 0.9), 0.0)]
    for i in range(6):
        parts.append(box((0.6, 0.015, 0.025), (0, -0.25 + i * 0.1, 0.022), solid(IRON, 0.5, 0.6), 0.0))
    parts.append(cylinder(0.045, 0.0, 0.9, wood("#5c3f2b"), bevel=0.01))
    leaves = E.foliage("#4a9a3a")
    for (x, y, z, r) in ((0, 0, 1.15, 0.36), (-0.22, 0.08, 1.02, 0.24), (0.22, -0.08, 1.05, 0.25), (0.05, 0.2, 1.3, 0.22), (-0.06, -0.2, 1.32, 0.22)):
        parts.append(sphere(r, (x, y, z), leaves))
    return parts


def bench():
    iron = solid(IRON, 0.5, 0.6)
    parts = [box((0.06, 0.26, 0.2), (x, 0, 0.1), iron, 0.006) for x in (-0.36, 0.36)]
    for i in range(3):
        parts.append(box((0.86, 0.07, 0.03), (0, -0.09 + i * 0.085, 0.21), wood("#b8763f"), 0.006))
    for i in range(2):
        parts.append(box((0.86, 0.03, 0.06), (0, 0.13, 0.32 + i * 0.1), wood("#a8682f"), 0.006))
    return parts


def hotdog_cart():
    parts = [box((0.8, 0.44, 0.38), (0, 0, 0.29), solid("#d6dde6", 0.25, 0.8), 0.02)]
    parts.append(box((0.62, 0.01, 0.2), (0, -0.225, 0.3), lacquer("#e8483c"), 0.006))
    for x in (-0.28, 0.28):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.1, depth=0.04, location=(x, 0.24, 0.1), rotation=(math.radians(90), 0, 0))
        parts.append(M._finish(bpy.context.active_object, solid(IRON, 0.4), 0.006))
    parts.append(cylinder(0.015, 0.48, 1.12, chrome()))
    parts.append(E.cone(0.5, 1.04, 1.2, M.fabric("plain", "#ffd23f"), (0, 0), vertices=12))   # o guarda-sol
    parts.append(E.cone(0.505, 1.035, 1.06, M.fabric("plain", "#2f6fd9"), (0, 0), top_radius=0.44, vertices=12))
    return parts


def trash_bin():
    green = solid("#2f6b4a", 0.4, 0.4)
    parts = [cylinder(0.12, 0.0, 0.41, green, bevel=0.01)]
    for z in (0.1, 0.2, 0.3):
        parts.append(E.torus(0.122, 0.006, (0, 0, z), solid("#1d4a32", 0.4, 0.4)))
    return parts


def mailbox():
    blue = lacquer("#2f5fbf")
    parts = [box((0.02, 0.02, 0.14), (x, y, 0.07), solid(IRON, 0.5), 0.0) for x in (-0.1, 0.1) for y in (-0.08, 0.08)]
    parts.append(box((0.26, 0.22, 0.38), (0, 0, 0.33), blue, 0.03))
    parts.append(sphere(0.13, (0, 0, 0.52), blue, (1.0, 0.85, 0.35)))
    parts.append(box((0.14, 0.01, 0.03), (0, -0.112, 0.42), solid("#1d3f86", 0.4), 0.004))
    return parts


def planter():
    parts = [box((0.64, 0.36, 0.2), (0, 0, 0.1), stone("#c8c3b8"), 0.01)]
    for (x, r) in ((-0.18, 0.13), (0.0, 0.15), (0.18, 0.13)):
        parts.append(sphere(r, (x, 0, 0.26), E.foliage("#4fb840"), (1, 1, 0.8)))
    for (x, c) in ((-0.2, "#ff4d8d"), (0.05, "#ffd23f"), (0.2, "#ffffff")):
        parts.append(sphere(0.03, (x, -0.06, 0.36), solid(c, 0.5)))
    return parts


def manhole():
    return [cylinder(0.2, 0.0, 0.008, solid("#4a4f5a", 0.5, 0.6), bevel=0.003), E.torus(0.14, 0.006, (0, 0, 0.008), solid("#6a707c", 0.5, 0.6))]


def traffic_light(state):
    iron = solid("#3a3f4a", 0.45, 0.5)
    parts = [cylinder(0.05, 0.0, 0.06, iron), cylinder(0.035, 0.06, 1.63, iron)]
    parts.append(box((0.18, 0.16, 0.6), (0, 0, 1.95), solid("#2b2d36", 0.4), 0.03))
    colors = {"vermelho": "#ff3b3b", "amarelo": "#ffc21f", "verde": "#33d26b"}
    for i, name in enumerate(("vermelho", "amarelo", "verde")):
        z = 2.14 - i * 0.19
        mat = emission(colors[name], 6.0) if name == state else solid(M._shade(colors[name], 0.7), 0.3)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.05, depth=0.02, location=(0.055, -0.055, z), rotation=(math.radians(90), 0, math.radians(45)))
        parts.append(M._finish(bpy.context.active_object, mat, 0.004))
    return parts


PROPS = {"rua_poste": street_lamp, "rua_hidrante": hydrant, "rua_arvore": street_tree, "rua_banco": bench, "rua_carrinho": hotdog_cart,
         "rua_lixeira": trash_bin, "rua_correio": mailbox, "rua_vaso": planter, "rua_bueiro": manhole}
for _state in ("verde", "amarelo", "vermelho"):
    PROPS[f"rua_semaforo_{_state}"] = (lambda s: lambda: traffic_light(s))(_state)


# --- Carros --------------------------------------------------------------------------------------------------

CAR_LENGTH, CAR_WIDTH = 1.15, 0.54
CARS = {"taxi": ("#ffc61a", True), "carro_vermelho": ("#d93a30", False), "carro_branco": ("#eef1f4", False), "carro_azul": ("#3a6fcf", False)}
HEADING = {"+x": 0.0, "-x": 180.0, "+y": -90.0, "-y": 90.0}


def car(body_color, taxi):
    """Carro olhando para +X (a frente), com rodas, vidros, faróis e lanternas; o táxi tem a placa no teto."""
    l, w = CAR_LENGTH, CAR_WIDTH
    paint = lacquer(body_color)
    parts = [box((l, w, 0.2), (0, 0, 0.17), paint, 0.05)]
    cabin = box((l * 0.5, w * 0.86, 0.17), (-l * 0.04, 0, 0.35), solid("#6a8aa8", 0.05, 0.4, 1.0), 0.04)
    parts.append(cabin)
    parts.append(box((l * 0.42, w * 0.88, 0.02), (-l * 0.04, 0, 0.44), paint, 0.01))
    for x in (-l * 0.32, l * 0.32):
        for y in (-w / 2, w / 2):
            bpy.ops.mesh.primitive_cylinder_add(radius=0.1, depth=0.08, location=(x, y, 0.1), rotation=(math.radians(90), 0, 0))
            parts.append(M._finish(bpy.context.active_object, solid("#1d1d22", 0.6), 0.01))
            parts.append(E.torus(0.05, 0.012, (x, y + (0.042 if y > 0 else -0.042), 0.1), chrome(), (math.radians(90), 0, 0)))
    for y in (-w * 0.32, w * 0.32):
        parts.append(sphere(0.035, (l / 2, y, 0.2), emission("#fff6d0", 3.0), (0.4, 1.0, 0.7)))
        parts.append(box((0.01, 0.08, 0.04), (-l / 2 - 0.003, y, 0.2), emission("#ff3030", 2.0), 0.0))
    parts.append(box((0.02, w * 0.7, 0.05), (l / 2 + 0.005, 0, 0.12), chrome(), 0.01))
    if taxi:
        parts.append(box((0.16, 0.08, 0.06), (-l * 0.04, 0, 0.48), emission("#fff4b0", 1.5), 0.01))
        parts.append(box((l * 0.8, 0.005, 0.03), (0, -w / 2 - 0.003, 0.2), solid("#1d1d22", 0.5), 0.0))
        parts.append(box((l * 0.8, 0.005, 0.03), (0, w / 2 + 0.003, 0.2), solid("#1d1d22", 0.5), 0.0))
    return parts


# --- Fotos ---------------------------------------------------------------------------------------------------

def shoot_figure(name, build_parts, samples, anchors, size=(420, 620), target_z=0.8, yaw=0.0, shadow=(1.2, 1.2)):
    """Monta a figura (depois de limpar a cena), gira e fotografa com a âncora no chão."""
    cena3d.setup(samples, size, shadow_size=shadow)
    objects = build_parts()
    parent = bpy.data.objects.new("Figura", None)
    bpy.context.scene.collection.objects.link(parent)
    for obj in M._flatten(objects):
        if obj is not None:
            obj.parent = parent
    parent.rotation_euler = (0.0, 0.0, math.radians(yaw))
    bpy.context.view_layer.update()
    aim_camera((0.0, 0.0, target_z))
    anchors[name] = cena3d.shoot(name, (0.0, 0.0, 0.0), WORK)


def main():
    import json
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    samples = 24 if "rascunho" in args else 64
    wanted = {a for a in args if a != "rascunho"}
    anchors = {}
    lamp_head = None

    def want(group, name):
        return not wanted or group in wanted or name in wanted

    for name in STYLES:
        if want("predios", name):
            shoot_building(name, samples, anchors)
            print("PRONTO", name, flush=True)
    for name, draw in PROPS.items():
        if want("rua", name):
            tall = name in ("rua_poste",) or name.startswith("rua_semaforo")
            shoot_figure(name, draw, samples, anchors, size=(420, 760 if tall else 520), target_z=1.1 if tall else 0.5)
            if name == "rua_poste":
                head = cena3d.pixel_of(LAMP_HEAD)
                foot = cena3d.pixel_of((0.0, 0.0, 0.0))
                lamp_head = [round((head[0] - foot[0]) / cena3d.DENSITY, 2), round((head[1] - foot[1]) / cena3d.DENSITY, 2)]
            print("PRONTO", name, flush=True)
    for car_id, (color, taxi) in CARS.items():
        for heading, suffix in (("+x", "xp"), ("-x", "xn"), ("+y", "yp"), ("-y", "yn")):
            name = f"{car_id}_{suffix}"
            if want("carros", name):
                shoot_figure(name, lambda: car(color, taxi), samples, anchors, size=(460, 360), target_z=0.2, yaw=HEADING[heading],
                             shadow=(1.6, 1.6))
        print("PRONTO", car_id, flush=True)

    def lamp(manifest):
        if lamp_head is not None:
            manifest["city"]["lamp_head"] = lamp_head
    cena3d.update_manifest(anchors, lamp)
    print("CIDADE OK", len(anchors), flush=True)


if __name__ == "__main__":
    main()
