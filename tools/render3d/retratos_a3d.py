"""Retrato do chef em 3D (DT-097): a pessoa do MakeHuman (MPFB) fotografada de frente, nas mesmas camadas que o jogo empilha
(scenes/ui/avatar_portrait.gd): a roupa embaixo, a cabeça com o cabelo no meio e o chapéu em cima.

Uso (na pasta do projeto):
    C:/Blender/blender-5.2.3-windows-x64/blender.exe -b -P tools/render3d/retratos_a3d.py -- [cabecas] [roupas] [chapeus] [icone] [folha] [pessoas] [vizinho_ana...] [natal] [rascunho] [prova]

Sem nada, faz tudo e a folha de conferência (out_retratos/retratos_folha.png). "prova" faz só um cabelo por pele.

Como as camadas encaixam:
- todas saem da mesma câmera, com a mesma âncora (o meio do rosto), então qualquer cabeça serve em qualquer roupa e chapéu;
- a cabeça tem a mesma forma nas 4 peles (só a pele muda), para o chapéu servir em todas;
- o corpo é cortado no alto do colarinho, que fica na camada da roupa; o cabelo comprido cai por cima da roupa;
- na roupa e no chapéu, o corpo entra invisível (holdout) para esconder o que fica atrás dele.
Os nomes das fotos são os mesmos (avatar_roupa_*, avatar_cabeca_<pele>_<cabelo>, avatar_chapeu_*): ids, preços e save não mudam.
As fotos têm 4 pixels por unidade do retrato (as outras têm 2): o retrato aparece grande na janela do avatar.
"""
import json
import math
import random
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cena3d  # noqa: E402
from cena3d import linear  # noqa: E402
import moveis3d as M  # noqa: E402
from moveis3d import box, cylinder, emission, solid, sphere, tube  # noqa: E402
import assentos_a3d as AS  # noqa: E402
from enfeites3d import torus  # noqa: E402

from bl_ext.user_default.mpfb.services.humanservice import HumanService  # noqa: E402
from bl_ext.user_default.mpfb.services.targetservice import TargetService  # noqa: E402

WORK = os.path.join(cena3d.ROOT, "tools", "render3d", "out_retratos")
DATA = os.path.join(bpy.utils.user_resource("EXTENSIONS"), ".user", "user_default", "mpfb", "data")
SYSTEM = os.path.join(bpy.utils.user_resource("EXTENSIONS"), "user_default", "mpfb", "data")

PORTRAIT_DENSITY = 4.0            # pixels da foto por unidade do retrato (a caixa do jogo tem 140 × 170 unidades)
UNITS_PER_METER = 300.0           # a cabeça com cabelo (0,2 m) ocupa 60 unidades: o rosto precisa ler no círculo pequeno do HUD
PX_PER_METER = PORTRAIT_DENSITY * UNITS_PER_METER
IMAGE_SIZE = (560, 800)
ICON_SIZE = (132, 132)            # a foto do ícone do botão Chef
ICON_HEIGHT = 0.6                 # metros que a foto do ícone mostra: do busto ao alto do chapéu
CAMERA_TURN = 12.0                # um pouco de lado: o rosto ganha volume
CAMERA_TILT = 4.0
HEAD_CENTER = (0.0, -0.046)       # o meio da cabeça visto de cima (a pessoa olha para -Y)
BUST_HALF = 0.228
BUST_CORNER = 0.06
JACKET_GAP = 0.012                # folga do tecido sobre o corpo
NECK_CENTER = (0.0, -0.036)       # o meio do pescoço na altura do colarinho

# As alturas dependem da pessoa pronta: as formas do MakeHuman (idade, gênero) mudam a altura dela, e os vértices do
# objeto guardam só a forma básica. Por isso fit() mede o alto da cabeça depois de tudo aplicado e põe as outras alturas a
# partir dele (medidas tiradas da pessoa adulta: queixo a 0,215 do alto, pescoço a 0,22, ombros a partir de 0,28).
HEAD_TOP = 1.644
TARGET = Vector((0.0, -0.05, HEAD_TOP - 0.018))
ANCHOR = (0.0, -0.06, HEAD_TOP - 0.105)   # o meio do rosto: a âncora de todas as camadas
COLLAR_TOP = HEAD_TOP - 0.232
NECK_CUT = COLLAR_TOP - 0.004     # o pescoço acaba logo abaixo da borda do colarinho
BUST_BOTTOM = ANCHOR[2] - 0.2     # onde o busto acaba (60 unidades abaixo da âncora, o limite da caixa do jogo)
BAND_Z = HEAD_TOP - 0.08          # a borda de baixo do chapéu: na testa, cobrindo a raiz do cabelo


def fit(basemesh):
    """Mede a pessoa pronta e acerta as alturas e a câmera por ela."""
    global HEAD_TOP, TARGET, ANCHOR, COLLAR_TOP, NECK_CUT, BUST_BOTTOM, BAND_Z
    HEAD_TOP = max(point.z for point in shaped(basemesh))
    TARGET = Vector((0.0, -0.05, HEAD_TOP - 0.018))
    ANCHOR = (0.0, -0.06, HEAD_TOP - 0.105)
    COLLAR_TOP = HEAD_TOP - 0.232
    NECK_CUT = COLLAR_TOP - 0.004
    BUST_BOTTOM = ANCHOR[2] - 0.2
    BAND_Z = HEAD_TOP - 0.08
    cam = bpy.context.scene.camera
    forward = cam.rotation_euler.to_matrix() @ Vector((0.0, 0.0, -1.0))
    cam.location = TARGET - forward * 8.0
    bpy.context.view_layer.update()


def shaped(basemesh):
    """Posição de cada vértice do corpo com as formas aplicadas, na ordem dos vértices do objeto (as máscaras ficam
    desligadas durante a medida, senão a ordem muda)."""
    masks = [m for m in basemesh.modifiers if m.type == "MASK" and m.show_viewport]
    for mask in masks:
        mask.show_viewport = False
    bpy.context.view_layer.update()
    evaluated = basemesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = evaluated.to_mesh()
    points = [evaluated.matrix_world @ v.co for v in mesh.vertices]
    evaluated.to_mesh_clear()
    for mask in masks:
        mask.show_viewport = True
    bpy.context.view_layer.update()
    return points


# Um rosto só, adulto jovem e simpático, igual nas 4 peles (o chapéu precisa servir em todas).
FACE = dict(gender=0.38, age=0.5, muscle=0.5, weight=0.42, race=(0.34, 0.33, 0.33))
SMILE = {"mouth/mouth-angles-up": 1.0, "eyebrows/eyebrows-angle-up": 0.3}

# pele do jogo -> (pele do MakeHuman, tom que multiplica a textura ou None)
SKINS = {
    "clara": ("young_caucasian_female", None),
    "morena_clara": ("young_caucasian_female", "#e2b792"),
    "parda": ("young_asian_female", "#c08e68"),
    "negra": ("young_african_female", None),
}

# cabelo do jogo -> (cabelo do MakeHuman, tingimento "modo:cor", peça extra)
HAIRS = {
    "curto_castanho": ("short02", "ramp:#3a2212,#b07a44", None),
    "rabo_preto": ("ponytail01", "ramp:#0c0c10,#4d4854", None),
    "chanel_ruivo": ("bob02", "ramp:#6e1f0c,#ee7a3c", None),
    "coque_loiro": ("ponytail01", "ramp:#8a6228,#f3d98c", "bun"),
    "topete_azul": ("short04", "ramp:#12357a,#5aa0ff", "quiff"),
    "longo_rosa": ("long01", "ramp:#b0306e,#ff9ccc", None),
}
EXTRA_COLOR = {"bun": "#d9b45c", "quiff": "#3577dd"}

# roupa do jogo -> (tecido, botões, lenço)
OUTFITS = {
    "branca": ("#efece4", "#b9bcc2", "#c23a3a"),
    "azul": ("#2f5fa8", "#e9e4d6", "#e9e4d6"),
    "preta": ("#26262c", "#c89b48", "#b3262e"),
    "rosa": ("#e58aa8", "#f6efe6", "#f6efe6"),
    "vermelha": ("#b3262e", "#f1e6cf", "#26262c"),
    "dourada": ("#c79a3a", "#7a5a1c", "#8e1a24"),
}
HATS = ("toque", "toque_alto", "bandana", "boina", "coroa")


# --- Cena -------------------------------------------------------------------------------------------------------

def setup(samples):
    """A cena do retrato: a luz quente do salão vindo da frente, um preenchimento do outro lado e um contorno frio."""
    cena3d.setup(samples, IMAGE_SIZE, shadow_size=0.01, tiling=True, rig="a")
    cena3d._light("Rosto", "SUN", 1.7, (1.0, 0.92, 0.84), direction=Vector((0.55, 0.8, -0.2)), angle=35.0)
    cena3d._light("Contorno", "SUN", 1.6, (0.62, 0.74, 1.0), direction=Vector((-0.5, -0.8, -0.25)), angle=20.0)
    scene = bpy.context.scene
    data = bpy.data.cameras.new("Retrato")
    data.type = "ORTHO"
    data.clip_end = 40.0
    data.ortho_scale = max(IMAGE_SIZE) / PX_PER_METER
    cam = bpy.data.objects.new("Retrato", data)
    scene.collection.objects.link(cam)
    cam.rotation_euler = (math.radians(90.0 - CAMERA_TILT), 0.0, math.radians(CAMERA_TURN))
    forward = cam.rotation_euler.to_matrix() @ Vector((0.0, 0.0, -1.0))
    cam.location = TARGET - forward * 8.0
    scene.camera = cam
    bpy.context.view_layer.update()


def shoot(name, anchors):
    anchors[name] = cena3d.shoot(name, ANCHOR, WORK)


# --- A pessoa ---------------------------------------------------------------------------------------------------

def human(skin):
    macro = TargetService.get_default_macro_info_dict()
    for key in ("gender", "age", "muscle", "weight"):
        macro[key] = FACE[key]
    african, asian, caucasian = FACE["race"]
    macro["race"] = {"african": african, "asian": asian, "caucasian": caucasian}
    basemesh = HumanService.create_human(macro_detail_dict=macro)
    skin_name, tone = SKINS[skin]
    HumanService.set_character_skin(os.path.join(DATA, "skins", skin_name, skin_name + ".mhmat"), basemesh)
    HumanService.add_mhclo_asset(os.path.join(DATA, "eyes", "high-poly", "high-poly.mhclo"), basemesh, asset_type="Eyes")
    HumanService.add_mhclo_asset(os.path.join(DATA, "eyebrows", "eyebrow006", "eyebrow006.mhclo"), basemesh, asset_type="Eyebrows")
    HumanService.add_mhclo_asset(os.path.join(DATA, "eyelashes", "eyelashes02", "eyelashes02.mhclo"), basemesh, asset_type="Eyelashes")
    for name, weight in SMILE.items():
        TargetService.load_target(basemesh, os.path.join(SYSTEM, "targets", name + ".target.gz"), weight=weight,
                                  name="expr-" + name.replace("/", "-"))
    HumanService.refit(basemesh)
    if tone:
        tint_skin(basemesh, tone)
    bpy.context.view_layer.update()
    fit(basemesh)
    return basemesh


def tint_skin(basemesh, color):
    """Escurece a pele multiplicando a textura: o material da pele é um grupo, e a cor entra por dentro dele."""
    seen = set()
    for material in basemesh.data.materials:
        for node in material.node_tree.nodes:
            tree = getattr(node, "node_tree", None)
            if tree is None or tree.name in seen:
                continue
            seen.add(tree.name)
            for inner in tree.nodes:
                if inner.bl_idname != "ShaderNodeBsdfPrincipled" or not inner.inputs["Base Color"].links:
                    continue
                source = inner.inputs["Base Color"].links[0].from_socket
                mix = tree.nodes.new("ShaderNodeMix")
                mix.data_type = "RGBA"
                mix.blend_type = "MULTIPLY"
                mix.inputs[0].default_value = 1.0
                tree.links.new(source, mix.inputs[6])
                mix.inputs[7].default_value = linear(color)
                tree.links.new(mix.outputs[2], inner.inputs["Base Color"])


def tint(material, color, mode):
    """Cor do cabelo: multiply (escurece o claro na cor), color (troca o tom guardando a luz) ou ramp ("escuro,claro")."""
    nodes, links = material.node_tree.nodes, material.node_tree.links
    base = nodes.get("Principled BSDF").inputs["Base Color"]
    if not base.links:
        base.default_value = linear(color)
        return
    source = base.links[0].from_socket
    if mode == "ramp":
        dark, light = color.split(",")
        gray = nodes.new("ShaderNodeRGBToBW")
        links.new(source, gray.inputs["Color"])
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.color_ramp.elements[0].color = linear(dark)
        ramp.color_ramp.elements[1].color = linear(light)
        links.new(gray.outputs["Val"], ramp.inputs["Fac"])
        links.new(ramp.outputs["Color"], base)
        return
    mix = nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY" if mode == "multiply" else "COLOR"
    mix.inputs[0].default_value = 1.0
    links.new(source, mix.inputs[6])
    mix.inputs[7].default_value = linear(color)
    out = mix.outputs[2]
    if mode == "color":
        bright = nodes.new("ShaderNodeBrightContrast")
        bright.inputs["Bright"].default_value = 0.18
        links.new(out, bright.inputs["Color"])
        out = bright.outputs["Color"]
    links.new(out, base)


def keep_above_neck(basemesh):
    """Esconde o corpo abaixo do colarinho (sem apagar vértices: o cabelo e os olhos se encaixam pelos índices deles)."""
    group = basemesh.vertex_groups.new(name="retrato")
    group.add([index for index, point in enumerate(shaped(basemesh)) if point.z >= NECK_CUT], 1.0, "REPLACE")
    mask = basemesh.modifiers.new("Só a cabeça", "MASK")
    mask.vertex_group = "retrato"


def hide_below_collar(basemesh):
    """Na camada da cabeça, a roupa entra invisível (holdout): o pescoço acaba exatamente na borda do colarinho, e o cabelo
    que cai por trás do corpo some atrás dele, como some na pessoa de verdade. O que cai pela frente continua aparecendo."""
    blank = solid("#000000", 1.0)
    coat = jacket(basemesh, blank)
    collar = arc_band(0.064, 0.06, COLLAR_TOP - 0.05, COLLAR_TOP, 0.008, 282.0, 618.0, blank, NECK_CENTER)
    for obj in (coat, collar):
        obj.is_holdout = True
    return [coat, collar]


def add_hair(basemesh, hair):
    asset, tinting, extra = HAIRS[hair]
    before = set(bpy.data.objects)
    HumanService.add_mhclo_asset(os.path.join(DATA, "hair", asset, asset + ".mhclo"), basemesh, asset_type="Hair")
    added = [obj for obj in bpy.data.objects if obj not in before]
    mode, color = tinting.split(":")
    for obj in added:
        if obj.type == "MESH" and obj.active_material is not None:
            obj.active_material = obj.active_material.copy()   # o mesmo cabelo serve a dois estilos: cada um com a sua cor
            tint(obj.active_material, color, mode)
    cx, cy = HEAD_CENTER
    if extra == "bun":
        mat = solid(EXTRA_COLOR["bun"], 0.55)
        added.append(sphere(0.058, (cx, cy + 0.035, HEAD_TOP + 0.035), mat, (1.0, 1.0, 0.92)))
        added.append(sphere(0.03, (cx, cy + 0.03, HEAD_TOP - 0.012), mat, (1.5, 1.5, 0.5)))
    elif extra == "quiff":
        mat = solid(EXTRA_COLOR["quiff"], 0.5)
        for dx, dy, dz, r in ((0.0, -0.085, 0.0, 0.062), (0.03, -0.06, 0.018, 0.058), (-0.03, -0.055, 0.012, 0.055), (0.0, -0.02, 0.022, 0.06)):
            added.append(sphere(r, (cx + dx, cy + dy, HEAD_TOP - 0.01 + dz), mat, (1.0, 1.1, 0.8)))
    return added


def remove(objects):
    for obj in objects:
        bpy.data.objects.remove(obj, do_unlink=True)


# --- Roupa ------------------------------------------------------------------------------------------------------

def cloth(color, gloss=0.0):
    """Tecido do dólmã: trama fina em relevo; com brilho, vira cetim."""
    key = ("retrato_tecido", color, gloss)
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("Dolma_" + color)
        weave = nodes.new("ShaderNodeTexNoise")
        weave.inputs["Scale"].default_value = 260.0
        weave.inputs["Detail"].default_value = 2.0
        links.new(M._coords(nodes, 1.0), weave.inputs["Vector"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.12
        links.new(weave.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
        bsdf.inputs["Base Color"].default_value = linear(color)
        bsdf.inputs["Roughness"].default_value = 0.78 - 0.4 * gloss
        bsdf.inputs["Sheen Weight"].default_value = 0.35
        bsdf.inputs["Metallic"].default_value = 0.35 * gloss
        M._materials[key] = mat
    return M._materials[key]


def jacket(basemesh, mat):
    """O dólmã: a própria forma do tronco e dos braços, com a folga do tecido, do peito até o colarinho."""
    deps = bpy.context.evaluated_depsgraph_get()
    mesh = bpy.data.meshes.new_from_object(basemesh.evaluated_get(deps))
    obj = bpy.data.objects.new("Dolma", mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.matrix_world = basemesh.matrix_world
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.normal_update()
    drop = [v for v in bm.verts if v.co.z > COLLAR_TOP - 0.018 or v.co.z < BUST_BOTTOM - 0.25]
    bmesh.ops.delete(bm, geom=drop, context="VERTS")
    bm.normal_update()
    for v in bm.verts:
        v.co += v.normal * JACKET_GAP
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.clear()
    mesh.materials.append(mat)
    for poly in mesh.polygons:
        poly.use_smooth = True
        poly.material_index = 0
    smooth = obj.modifiers.new("Liso", "SUBSURF")
    smooth.levels = smooth.render_levels = 1
    return obj


def arc_band(rx, ry, z0, z1, thick, a0, a1, mat, center=HEAD_CENTER, steps=72, bevel=0.003):
    """Faixa em volta do pescoço ou da cabeça (elipse), de [a0] a [a1] graus (270° é a frente, em -Y)."""
    verts, faces = [], []
    for i in range(steps + 1):
        angle = math.radians(a0 + (a1 - a0) * i / steps)
        for grow in (0.0, -thick):
            x, y = center[0] + math.cos(angle) * (rx + grow), center[1] + math.sin(angle) * (ry + grow)
            verts += [(x, y, z0), (x, y, z1)]
    for i in range(steps):
        a, b = i * 4, (i + 1) * 4
        faces += [(a, b, b + 1, a + 1), (a + 2, a + 3, b + 3, b + 2), (a + 1, b + 1, b + 3, a + 3), (a, a + 2, b + 2, b)]
    if abs(a1 - a0) < 360.0:
        last = steps * 4
        faces += [(0, 1, 3, 2), (last, last + 2, last + 3, last + 1)]
    mesh = bpy.data.meshes.new("Faixa")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("Faixa", mesh)
    bpy.context.scene.collection.objects.link(obj)
    return M._finish(obj, mat, bevel)


def front_of(obj, x, z):
    """Onde a frente da roupa fica neste ponto (para pregar botões)."""
    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    hit, location, _normal, _index = obj.evaluated_get(deps).ray_cast(Vector((x, -1.0, z)), Vector((0.0, 1.0, 0.0)))
    return location.y if hit else -0.1


def bust_frame():
    """Moldura invisível que corta o busto: reto embaixo, com os cantos arredondados, como um medalhão."""
    y = -1.5
    big = 3.0
    pieces = [[(-big, BUST_BOTTOM - big), (big, BUST_BOTTOM - big), (big, BUST_BOTTOM), (-big, BUST_BOTTOM)],
              [(-big, BUST_BOTTOM), (-BUST_HALF, BUST_BOTTOM), (-BUST_HALF, big), (-big, big)],
              [(BUST_HALF, BUST_BOTTOM), (big, BUST_BOTTOM), (big, big), (BUST_HALF, big)]]
    for side in (-1, 1):
        corner = (side * BUST_HALF, BUST_BOTTOM)
        cx, cz = side * (BUST_HALF - BUST_CORNER), BUST_BOTTOM + BUST_CORNER
        arc = [(cx + side * math.cos(math.radians(a)) * BUST_CORNER, cz - math.sin(math.radians(a)) * BUST_CORNER) for a in range(0, 91, 6)]
        pieces += [[corner, arc[i], arc[i + 1]] for i in range(len(arc) - 1)]
    verts, faces = [], []
    for piece in pieces:
        start = len(verts)
        verts += [(x, y, z) for x, z in piece]
        faces.append(tuple(range(start, start + len(piece))))
    mesh = bpy.data.meshes.new("Moldura")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("Moldura", mesh)
    bpy.context.scene.collection.objects.link(obj)
    # A moldura fica de frente para a câmera, que olha um pouco de lado e de cima.
    obj.rotation_euler = (math.radians(-CAMERA_TILT), 0.0, math.radians(CAMERA_TURN))
    obj.is_holdout = True
    return obj


def outfit(basemesh, name):
    fabric_color, button_color, scarf_color = OUTFITS[name]
    fabric = cloth(fabric_color, 1.0 if name == "dourada" else 0.0)
    coat = jacket(basemesh, fabric)
    neck = NECK_CENTER
    parts = [coat,
             arc_band(0.064, 0.06, COLLAR_TOP - 0.05, COLLAR_TOP, 0.008, 282.0, 618.0, fabric, neck),
             arc_band(0.0655, 0.0615, COLLAR_TOP - 0.006, COLLAR_TOP + 0.001, 0.011, 282.0, 618.0, cloth(button_color), neck)]
    # A aba do dólmã: a costura que desce do colarinho, de um lado do peito.
    for z0, z1 in ((HEAD_TOP - 0.272, HEAD_TOP - 0.3), (HEAD_TOP - 0.3, HEAD_TOP - 0.33), (HEAD_TOP - 0.33, HEAD_TOP - 0.36)):
        y0, y1 = front_of(coat, 0.052, z0), front_of(coat, 0.052, z1)
        parts.append(tube((0.052, y0 - 0.002, z0), (0.052, y1 - 0.002, z1), 0.0022, cloth(M._shade(fabric_color, 0.25))))
    button = solid(button_color, 0.3, 0.2, 0.6)
    for x in (-0.032, 0.032):
        for z in (HEAD_TOP - 0.288, HEAD_TOP - 0.316, HEAD_TOP - 0.344):
            parts.append(sphere(0.0085, (x, front_of(coat, x, z) - 0.003, z), button, (1.0, 0.55, 1.0)))
    # O lenço no colarinho: o nó e as duas pontas.
    scarf = cloth(scarf_color)
    front = front_of(coat, 0.0, COLLAR_TOP - 0.035)
    parts.append(sphere(0.017, (0.0, front - 0.012, COLLAR_TOP - 0.03), scarf, (1.1, 0.8, 0.9)))
    for side in (-1, 1):
        tip = sphere(0.02, (side * 0.014, front - 0.008, COLLAR_TOP - 0.062), scarf, (0.75, 0.4, 1.7))
        tip.rotation_euler = (0.0, math.radians(side * -16.0), 0.0)
        parts.append(tip)
    parts.append(bust_frame())
    return parts


# --- Chapéus ----------------------------------------------------------------------------------------------------

def pleated(profile, mat, ribs=14, depth=0.03, center=HEAD_CENTER, squash=(1.0, 1.0), steps=112):
    """Peça torneada com pregas (o alto do chapéu de chef): o raio sobe e desce em volta. [squash]: elipse (x, y)."""
    bm = bmesh.new()
    rings = []
    for radius, z, pleat in profile:
        if radius <= 0.0:
            rings.append([bm.verts.new((center[0], center[1], z))])
            continue
        ring = []
        for i in range(steps):
            angle = 2.0 * math.pi * i / steps
            r = radius * (1.0 - depth * pleat * (0.5 - 0.5 * math.cos(ribs * angle)))
            ring.append(bm.verts.new((center[0] + math.cos(angle) * r * squash[0], center[1] + math.sin(angle) * r * squash[1], z)))
        rings.append(ring)
    for low, high in zip(rings, rings[1:]):
        for i in range(steps):
            a, b = i, (i + 1) % steps
            if len(low) == 1:
                bm.faces.new((low[0], high[a], high[b]))
            elif len(high) == 1:
                bm.faces.new((low[a], low[b], high[0]))
            else:
                bm.faces.new((low[a], low[b], high[b], high[a]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("Pregas")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Pregas", mesh)
    bpy.context.scene.collection.objects.link(obj)
    for poly in mesh.polygons:
        poly.use_smooth = True
    mesh.materials.append(mat)
    return obj


BAND = (0.088, 0.108)             # a faixa do chapéu em volta da cabeça (meia largura, meio fundo), por cima do cabelo


def chef_hat(tall):
    white = cloth("#f1eee6")
    rx, ry = BAND
    band_top = BAND_Z + (0.075 if tall else 0.06)
    parts = [arc_band(rx, ry, BAND_Z, band_top, 0.012, 0.0, 360.0, white, bevel=0.004)]
    ratio = (1.0, ry / rx)
    if tall:
        top = band_top + 0.19
        profile = [(rx * 0.97, band_top - 0.01, 0.0), (rx * 1.0, band_top + 0.02, 1.0), (rx * 1.06, band_top + 0.12, 1.0),
                   (rx * 1.16, top - 0.06, 1.0), (rx * 1.14, top - 0.02, 0.8), (rx * 0.9, top + 0.012, 0.5), (rx * 0.45, top + 0.03, 0.2),
                   (0.0, top + 0.034, 0.0)]
        parts.append(pleated(profile, white, 16, 0.07, squash=ratio))
    else:
        top = band_top + 0.13
        profile = [(rx * 0.96, band_top - 0.01, 0.0), (rx * 1.12, band_top + 0.015, 1.0), (rx * 1.3, band_top + 0.055, 1.0),
                   (rx * 1.36, band_top + 0.09, 1.0), (rx * 1.2, top, 0.8), (rx * 0.8, top + 0.03, 0.5), (rx * 0.3, top + 0.04, 0.2),
                   (0.0, top + 0.042, 0.0)]
        parts.append(pleated(profile, white, 9, 0.13, squash=ratio))
    return parts


def bandana():
    red = cloth("#b3262e")
    rx, ry = BAND
    cx, cy = HEAD_CENTER
    cap_profile = [(rx * 1.0, BAND_Z + 0.03, 0.0), (rx * 0.99, BAND_Z + 0.06, 0.3), (rx * 0.9, HEAD_TOP - 0.015, 0.6),
                   (rx * 0.6, HEAD_TOP + 0.022, 0.6), (rx * 0.25, HEAD_TOP + 0.034, 0.3), (0.0, HEAD_TOP + 0.036, 0.0)]
    parts = [pleated(cap_profile, red, 7, 0.03, squash=(1.0, ry / rx)),
             arc_band(rx + 0.004, ry + 0.004, BAND_Z, BAND_Z + 0.038, 0.014, 0.0, 360.0, red, bevel=0.012)]
    dot = solid("#f3ede0", 0.6)
    for a in range(200, 345, 24):                      # bolinhas brancas na faixa, na parte da frente
        rad = math.radians(a)
        parts.append(sphere(0.0065, (cx + math.cos(rad) * (rx + 0.004), cy + math.sin(rad) * (ry + 0.004), BAND_Z + 0.019), dot, (1.0, 1.0, 1.0)))
    # O nó de lado, com as duas pontas.
    knot = (cx + rx + 0.012, cy + 0.03, BAND_Z + 0.02)
    parts.append(sphere(0.02, knot, red, (1.0, 1.0, 0.9)))
    for dz, tilt in ((0.03, 28.0), (-0.035, -24.0)):
        tail = sphere(0.02, (knot[0] + 0.04, knot[1] + 0.005, knot[2] + dz), red, (2.2, 0.45, 0.8))
        tail.rotation_euler = (0.0, math.radians(-tilt), 0.0)
        parts.append(tail)
    return parts


def beret():
    felt = cloth("#b3262e")
    rx, ry = BAND
    cx, cy = HEAD_CENTER
    top = sphere(1.0, (cx + 0.022, cy - 0.005, BAND_Z + 0.07), felt, (rx * 1.42, ry * 1.3, 0.05))
    top.rotation_euler = (math.radians(4.0), math.radians(-11.0), 0.0)
    return [top,
            arc_band(rx + 0.002, ry + 0.002, BAND_Z + 0.012, BAND_Z + 0.045, 0.012, 0.0, 360.0, cloth("#8e1a24"), bevel=0.008),
            sphere(0.008, (cx + 0.03, cy, BAND_Z + 0.123), felt, (1.0, 1.0, 2.0))]


def crown():
    gold = solid("#d9a93a", 0.3, 0.75)
    rx, ry = BAND
    cx, cy = HEAD_CENTER
    parts = [arc_band(rx, ry, BAND_Z + 0.02, BAND_Z + 0.07, 0.008, 0.0, 360.0, gold, bevel=0.004),
             arc_band(rx + 0.004, ry + 0.004, BAND_Z + 0.02, BAND_Z + 0.032, 0.012, 0.0, 360.0, gold, bevel=0.005)]
    points = 8
    for i in range(points):
        rad = 2.0 * math.pi * (i + 0.5) / points
        x, y = cx + math.cos(rad) * (rx - 0.004), cy + math.sin(rad) * (ry - 0.004)
        tall = 0.1 if i % 2 == 0 else 0.07
        bpy.ops.mesh.primitive_cone_add(radius1=0.04, radius2=0.004, depth=tall, vertices=4, location=(x, y, BAND_Z + 0.07 + tall / 2 - 0.004))
        spike = bpy.context.active_object
        spike.rotation_euler = (0.0, 0.0, rad + math.radians(45.0))
        spike.scale = (1.0, 0.22, 1.0)
        parts.append(M._finish(spike, gold, 0.002))
        parts.append(sphere(0.011, (x, y, BAND_Z + 0.07 + tall), solid("#f6efe0", 0.2, 0.0, 0.8)))
    gems = ("#c23a3a", "#2f6fd9", "#2f9a4e")
    for i, a in enumerate(range(215, 330, 28)):
        rad = math.radians(a)
        parts.append(sphere(0.0095, (cx + math.cos(rad) * (rx + 0.004), cy + math.sin(rad) * (ry + 0.004), BAND_Z + 0.047),
                            solid(gems[i % 3], 0.1, 0.0, 1.0), (1.0, 1.0, 1.0)))
    return parts


def hat(name):
    return {"toque": lambda: chef_hat(False), "toque_alto": lambda: chef_hat(True), "bandana": bandana, "boina": beret, "coroa": crown}[name]()


# --- Folha de conferência ------------------------------------------------------------------------------------------

def _load(name):
    image = bpy.data.images.load(os.path.join(cena3d.SPRITES, name + ".png"), check_existing=False)
    w, h = image.size
    pixels = np.array(image.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    bpy.data.images.remove(image)
    return pixels


def sheet(manifest):
    """Monta os retratos como o jogo monta (roupa, cabeça, chapéu pela âncora) e grava uma folha para conferir."""
    combos = [("branca", "clara", "curto_castanho", "toque"), ("azul", "morena_clara", "rabo_preto", "toque_alto"),
              ("preta", "parda", "chanel_ruivo", "bandana"), ("rosa", "negra", "coque_loiro", "boina"),
              ("vermelha", "clara", "topete_azul", "coroa"), ("dourada", "negra", "longo_rosa", "toque"),
              ("branca", "parda", "curto_castanho", "toque"), ("azul", "negra", "rabo_preto", "boina"),
              ("rosa", "morena_clara", "longo_rosa", "coroa"), ("preta", "clara", "chanel_ruivo", "toque_alto"),
              ("vermelha", "parda", "coque_loiro", "toque"), ("dourada", "morena_clara", "topete_azul", "bandana")]
    cell_w, cell_h = int(140 * PORTRAIT_DENSITY), int(170 * PORTRAIT_DENSITY)
    cols = 6
    rows = (len(combos) + cols - 1) // cols
    canvas = np.zeros((rows * cell_h, cols * cell_w, 4), dtype=np.float32)
    canvas[..., :3] = (0.09, 0.13, 0.2)
    canvas[..., 3] = 1.0
    for index, (cloth_name, skin, hair, hat_name) in enumerate(combos):
        ox = (index % cols) * cell_w + int(70 * PORTRAIT_DENSITY)
        oy = (index // cols) * cell_h + int(110 * PORTRAIT_DENSITY)
        for name in (f"avatar_roupa_{cloth_name}", f"avatar_cabeca_{skin}_{hair}", f"avatar_chapeu_{hat_name}"):
            path = os.path.join(cena3d.SPRITES, name + ".png")
            info = manifest["sprites"].get(name, {})
            if not os.path.exists(path) or info.get("density") != PORTRAIT_DENSITY:
                continue
            layer = _load(name)
            ax, ay = info["anchor"]
            x0, y0 = int(round(ox - ax)), int(round(oy - ay))
            h, w = layer.shape[:2]
            sx0, sy0 = max(0, -x0), max(0, -y0)
            x1, y1 = min(x0 + w, canvas.shape[1]), min(y0 + h, canvas.shape[0])
            if x1 <= max(x0, 0) or y1 <= max(y0, 0):
                continue
            src = layer[sy0:sy0 + (y1 - max(y0, 0)), sx0:sx0 + (x1 - max(x0, 0))]
            dst = canvas[max(y0, 0):y1, max(x0, 0):x1]
            alpha = src[..., 3:4]
            dst[..., :3] = src[..., :3] * alpha + dst[..., :3] * (1.0 - alpha)
    out = bpy.data.images.new("folha", canvas.shape[1], canvas.shape[0], alpha=True)
    out.pixels = canvas[::-1].ravel()
    out.filepath_raw = os.path.join(WORK, "retratos_folha.png")
    out.file_format = "PNG"
    out.save()
    bpy.data.images.remove(out)


# --- Fotos ------------------------------------------------------------------------------------------------------

def save(anchors):
    def density(manifest):
        for name in anchors:
            manifest["sprites"][name]["density"] = PORTRAIT_DENSITY
    cena3d.update_manifest(anchors, density)


# --- Vizinhos, a bruxa e o ícone do garçom: uma foto só cada, em busto (DT-099) ---------------------------------------

# Cada pessoa mantém os traços do desenho antigo. gender 1 = homem; race = (africana, asiática, europeia); skin = pele do
# MakeHuman; tone = tom que multiplica a pele; hair = (cabelo, tingimento); clothes = roupas do MakeHuman.
PEOPLE = {
    "vizinho_ana": dict(gender=0.0, age=0.4, weight=0.45, race=(0.0, 0.1, 0.9), skin="young_caucasian_female",
                        hair=("ponytail01", "ramp:#3a2212,#b07a44"), clothes=["female_casualsuit01"]),
    "vizinho_beto": dict(gender=1.0, age=0.42, muscle=0.55, weight=0.5, race=(0.9, 0.0, 0.1), skin="young_african_male",
                         hair=("short02", "ramp:#0c0c10,#3a3640"), clothes=["male_casualsuit06"]),
    "vizinho_caio": dict(gender=1.0, age=0.38, muscle=0.5, weight=0.5, race=(0.7, 0.1, 0.2), skin="young_african_male",
                         hair=None, clothes=["male_casualsuit02"], extra="cap"),
    "vizinho_duda": dict(gender=0.0, age=0.38, weight=0.45, race=(0.0, 0.05, 0.95), skin="young_caucasian_female2",
                         hair=("bob02", "ramp:#6e1f0c,#ee7a3c"), clothes=["female_casualsuit02"]),
    "vizinho_lia": dict(gender=0.0, age=0.4, weight=0.42, race=(0.2, 0.4, 0.4), skin="young_asian_female", tone="#d9a882",
                        hair=("long01", "ramp:#0c0c10,#4d4854"), clothes=["female_elegantsuit01"]),
    "vizinho_rafa": dict(gender=1.0, age=0.4, muscle=0.55, weight=0.45, race=(0.0, 0.05, 0.95), skin="young_caucasian_male",
                         hair=("short04", "ramp:#c49a4a,#fff0b8"), clothes=["male_casualsuit04"]),
    "vizinho_vo_cida": dict(gender=0.0, age=0.92, weight=0.55, race=(0.0, 0.0, 1.0), skin="old_caucasian_female",
                            hair=("ponytail01", "ramp:#77747a,#e6e3e8"),
                            clothes=["female_elegantsuit01", "spamrakuen_tbm_glasses_frames_01"], extra="gray_bun"),
    "retrato_bruxa": dict(gender=0.0, age=0.42, weight=0.42, race=(0.0, 0.05, 0.95), skin="young_caucasian_female",
                          hair=("long01", "ramp:#7a2408,#f07a30"), clothes=["female_elegantsuit01"], extra="witch_hat",
                          size=(440, 760), px_per_meter=980.0, up=0.08),
    "icone_garcom": dict(gender=1.0, age=0.45, muscle=0.6, weight=0.45, race=(0.3, 0.25, 0.45), skin="young_caucasian_male2",
                         hair=("short02", None), clothes=["toigo_suit_with_jacket_and_bowtie"], size=ICON_SIZE,
                         px_per_meter=132 / 0.6, up=-0.02),
}
PERSON_SIZE = (300, 380)          # a janela da Cidade mostra o vizinho com 66 × 70: 300 px já sobram
PERSON_PX_PER_METER = 620.0


def person(spec):
    """Uma pessoa inteira (corpo, olhos, sobrancelhas, cabelo, roupa e acessório), sorrindo."""
    macro = TargetService.get_default_macro_info_dict()
    for key in ("gender", "age", "muscle", "weight"):
        if key in spec:
            macro[key] = spec[key]
    african, asian, caucasian = spec["race"]
    macro["race"] = {"african": african, "asian": asian, "caucasian": caucasian}
    basemesh = HumanService.create_human(macro_detail_dict=macro)
    HumanService.set_character_skin(os.path.join(DATA, "skins", spec["skin"], spec["skin"] + ".mhmat"), basemesh)
    male = spec["gender"] > 0.5
    HumanService.add_mhclo_asset(os.path.join(DATA, "eyes", "high-poly", "high-poly.mhclo"), basemesh, asset_type="Eyes")
    brows = "eyebrow001" if male else "eyebrow006"
    lashes = "eyelashes01" if male else "eyelashes02"
    HumanService.add_mhclo_asset(os.path.join(DATA, "eyebrows", brows, brows + ".mhclo"), basemesh, asset_type="Eyebrows")
    HumanService.add_mhclo_asset(os.path.join(DATA, "eyelashes", lashes, lashes + ".mhclo"), basemesh, asset_type="Eyelashes")
    for name, weight in SMILE.items():
        TargetService.load_target(basemesh, os.path.join(SYSTEM, "targets", name + ".target.gz"), weight=weight,
                                  name="expr-" + name.replace("/", "-"))
    HumanService.refit(basemesh)
    if spec.get("tone"):
        tint_skin(basemesh, spec["tone"])
    if spec.get("hair"):
        asset, tinting = spec["hair"]
        before = set(bpy.data.objects)
        HumanService.add_mhclo_asset(os.path.join(DATA, "hair", asset, asset + ".mhclo"), basemesh, asset_type="Hair")
        if tinting:
            mode, color = tinting.split(":")
            for obj in bpy.data.objects:
                if obj not in before and obj.type == "MESH" and obj.active_material is not None:
                    tint(obj.active_material, color, mode)
    for item in spec["clothes"]:
        HumanService.add_mhclo_asset(os.path.join(DATA, "clothes", item, item + ".mhclo"), basemesh, asset_type="Clothes")
    bpy.context.view_layer.update()
    fit(basemesh)
    return basemesh


def baseball_cap():
    """O boné do Caio: a copa azul, a aba para a frente e a estrela branca."""
    blue = cloth("#2f6fd9")
    rx, ry = BAND
    cx, cy = HEAD_CENTER
    crown_profile = [(rx * 1.02, BAND_Z, 0.0), (rx * 1.03, BAND_Z + 0.04, 0.2), (rx * 0.92, HEAD_TOP - 0.01, 0.4),
                     (rx * 0.6, HEAD_TOP + 0.026, 0.4), (rx * 0.25, HEAD_TOP + 0.04, 0.2), (0.0, HEAD_TOP + 0.042, 0.0)]
    parts = [pleated(crown_profile, blue, 6, 0.02, squash=(1.0, ry / rx)),
             sphere(0.011, (cx, cy, HEAD_TOP + 0.045), blue, (1.0, 1.0, 0.6))]
    brim = sphere(1.0, (cx, cy - ry - 0.045, BAND_Z + 0.012), cloth("#2a62c4"), (rx * 0.98, 0.085, 0.01))
    brim.rotation_euler = (math.radians(-8.0), 0.0, 0.0)
    parts.append(brim)
    points = []
    for i in range(10):
        angle = math.radians(90 + i * 36)
        r = 0.026 if i % 2 == 0 else 0.011
        points.append((math.cos(angle) * r, math.sin(angle) * r))
    star_mesh = bpy.data.meshes.new("Estrela")
    y = cy - ry - 0.012
    star_mesh.from_pydata([(cx + px, y, BAND_Z + 0.062 + pz) for px, pz in points], [], [tuple(range(10))])
    star_mesh.update()
    star = bpy.data.objects.new("Estrela", star_mesh)
    bpy.context.scene.collection.objects.link(star)
    star.data.materials.append(solid("#f6f1e6", 0.5))
    parts.append(star)
    return parts


def witch_hat():
    """O chapéu da bruxa Morgana: aba larga, cone alto com a ponta caída, faixa laranja e fivela."""
    purple = cloth("#4a2a7a")
    rx, ry = BAND
    cx, cy = HEAD_CENTER
    z = BAND_Z + 0.01
    brim = sphere(1.0, (cx, cy, z), purple, (rx * 2.0, ry * 1.9, 0.012))
    cone_profile = [(rx * 1.03, z, 0.0), (rx * 1.0, z + 0.05, 0.3), (rx * 0.72, z + 0.13, 0.5), (rx * 0.42, z + 0.21, 0.5),
                    (rx * 0.16, z + 0.27, 0.3), (0.0, z + 0.29, 0.0)]
    cone = pleated(cone_profile, purple, 5, 0.04, squash=(1.0, ry / rx))
    tip = sphere(0.026, (cx + 0.03, cy, z + 0.29), purple, (1.4, 0.8, 0.7))
    tip.rotation_euler = (0.0, math.radians(35.0), 0.0)
    band = arc_band(rx * 1.04, ry * 1.04, z + 0.012, z + 0.05, 0.01, 0.0, 360.0, cloth("#e0862c"), bevel=0.004)
    buckle = box((0.04, 0.012, 0.046), (cx, cy - ry * 1.04 - 0.004, z + 0.031), solid("#d9a93a", 0.3, 0.75), 0.004)
    return [brim, cone, tip, band, buckle]


def render_person(name, samples):
    spec = PEOPLE[name]
    setup(samples)
    scene = bpy.context.scene
    size = spec.get("size", PERSON_SIZE)
    scene.render.resolution_x, scene.render.resolution_y = size
    scene.camera.data.ortho_scale = max(size) / spec.get("px_per_meter", PERSON_PX_PER_METER)
    person(spec)
    extra = spec.get("extra")
    cx, cy = HEAD_CENTER
    if extra == "cap":
        baseball_cap()
    elif extra == "witch_hat":
        witch_hat()
    elif extra == "gray_bun":
        gray = solid("#c9c6cc", 0.6)
        sphere(0.05, (cx, cy + 0.075, HEAD_TOP - 0.045), gray, (1.0, 1.0, 0.9))
        arc_band(0.03, 0.03, HEAD_TOP - 0.085, HEAD_TOP - 0.072, 0.008, 0.0, 360.0, cloth("#e58aa8"), (cx, cy + 0.07))
    bust_frame()
    # A câmera sobe ou desce um pouco para o chapéu alto caber (ou para o ícone ficar centrado).
    scene.camera.location.z += spec.get("up", -0.06)
    bpy.context.view_layer.update()
    anchors = {}
    shoot(name, anchors)
    cena3d.update_manifest(anchors)
    print("PRONTO", name, flush=True)


# --- Natal (DT-100): o Papai Noel e o medalhão do evento --------------------------------------------------------------

def santa_extras(basemesh):
    """O Papai Noel: o casaco vermelho com a gola de pelo, a barba e o bigode brancos e o gorro com o pompom."""
    red = cloth("#b3202a")
    fur = food_fur()
    parts = [jacket(basemesh, red),
             arc_band(0.08, 0.075, COLLAR_TOP - 0.06, COLLAR_TOP + 0.005, 0.03, 0.0, 360.0, fur, NECK_CENTER, bevel=0.02)]
    cx, cy = HEAD_CENTER
    chin = HEAD_TOP - 0.215
    # A barba: tufos em volta do queixo e das bochechas, mais cheios embaixo.
    rnd = random.Random(5)
    for i in range(26):
        angle = math.radians(200 + 140 * i / 25)
        drop = 0.03 + 0.05 * math.sin(math.radians(180 * i / 25))
        x = cx + math.cos(angle) * 0.07
        y = cy + math.sin(angle) * 0.085
        parts.append(sphere(0.032 + rnd.uniform(-0.004, 0.006), (x, y, chin + 0.05 - drop), fur, (1.0, 0.9, 1.25)))
    for i in range(9):
        parts.append(sphere(0.03, (cx + rnd.uniform(-0.04, 0.04), cy - 0.095 + rnd.uniform(-0.01, 0.01), chin - 0.03 - i * 0.008), fur))
    for side in (-1, 1):
        mustache = sphere(0.022, (cx + side * 0.024, cy - 0.118, chin + 0.058), fur, (1.6, 0.8, 0.7))
        mustache.rotation_euler = (0.0, math.radians(side * 18.0), 0.0)
        parts.append(mustache)
    # O gorro: a faixa de pelo, o cone vermelho caído para o lado e o pompom.
    rx, ry = BAND
    z = BAND_Z + 0.035
    parts.append(arc_band(rx * 1.06, ry * 1.06, z, z + 0.045, 0.02, 0.0, 360.0, fur, bevel=0.016))
    profile = [(rx * 1.02, z + 0.03, 0.0), (rx * 0.95, z + 0.07, 0.4), (rx * 0.72, z + 0.12, 0.5), (rx * 0.42, z + 0.15, 0.4), (0.0, z + 0.165, 0.0)]
    hat = pleated(profile, red, 5, 0.03, squash=(1.0, ry / rx))
    parts.append(hat)
    tip = sphere(0.03, (cx + 0.06, cy + 0.02, z + 0.145), red, (1.7, 0.9, 0.8))
    tip.rotation_euler = (0.0, math.radians(30.0), 0.0)
    parts += [tip, sphere(0.032, (cx + 0.11, cy + 0.02, z + 0.115), fur)]
    return parts


def food_fur():
    """Pelo branco do gorro e da barba: fosco e macio."""
    key = ("retrato_pelo",)
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("Pelo")
        fibers = nodes.new("ShaderNodeTexNoise")
        fibers.inputs["Scale"].default_value = 220.0
        fibers.inputs["Detail"].default_value = 6.0
        links.new(M._coords(nodes, 1.0), fibers.inputs["Vector"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.5
        links.new(fibers.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
        bsdf.inputs["Base Color"].default_value = linear("#f4f1ea")
        bsdf.inputs["Roughness"].default_value = 0.95
        bsdf.inputs["Sheen Weight"].default_value = 0.6
        M._materials[key] = mat
    return M._materials[key]


def render_santa(samples):
    """O retrato do Papai Noel: uma foto só, em busto, no mesmo tamanho do retrato da bruxa."""
    setup(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = (440, 640)
    scene.camera.data.ortho_scale = 640 / 820.0
    basemesh = person(dict(gender=1.0, age=0.88, muscle=0.45, weight=0.75, race=(0.0, 0.0, 1.0), skin="old_caucasian_male",
                           tone="#f2c6b4", hair=("short02", "ramp:#c9c6c2,#ffffff"), clothes=[]))
    santa_extras(basemesh)
    bust_frame()
    scene.camera.location.z -= 0.01
    bpy.context.view_layer.update()
    anchors = {}
    shoot("retrato_papai_noel", anchors)
    cena3d.update_manifest(anchors)
    print("PRONTO retrato_papai_noel", flush=True)


def render_christmas_medal(samples):
    """O medalhão do Natal no HUD: uma bola de árvore vermelha com o pino dourado e os ramos, de frente."""
    setup(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = (136, 136)
    scene.camera.data.ortho_scale = 0.3
    center = Vector(TARGET)
    ball = solid("#c01e2a", 0.12, 0.3, 0.9)
    gold_mat = solid("#d9a93a", 0.25, 0.85)
    sphere(0.1, center, ball)
    for dz in (-0.03, 0.03):
        arc_band(0.1, 0.1, center.z + dz - 0.006, center.z + dz + 0.006, 0.004, 0.0, 360.0, gold_mat, (center.x, center.y), bevel=0.002)
    cylinder(0.026, center.z + 0.092, center.z + 0.122, gold_mat, (center.x, center.y), bevel=0.004)
    torus(0.016, 0.004, (center.x, center.y, center.z + 0.13), gold_mat, (math.radians(90), 0.0, math.radians(CAMERA_TURN)))
    holly = solid("#2a6a34", 0.4, 0.0, 0.5)
    for side in (-1, 1):
        leaf_obj = sphere(1.0, (center.x + side * 0.045, center.y - 0.02, center.z + 0.112), holly, (0.045, 0.012, 0.018))
        leaf_obj.rotation_euler = (0.0, math.radians(side * -25.0), math.radians(CAMERA_TURN))
    for dx in (-0.012, 0.012):
        sphere(0.012, (center.x + dx, center.y - 0.03, center.z + 0.118), solid("#d81e2a", 0.2, 0.0, 0.8))
    bpy.context.view_layer.update()
    anchors = {}
    anchors["medalhao_natal"] = cena3d.shoot("medalhao_natal", tuple(center), WORK)
    cena3d.update_manifest(anchors)
    print("PRONTO medalhao_natal", flush=True)


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    samples = 24 if "rascunho" in args else 96
    proof = "prova" in args
    names = ("cabecas", "roupas", "chapeus", "icone", "folha")
    people_only = bool([a for a in args if a in ("pessoas", "natal") or a in PEOPLE])
    everything = not [a for a in args if a not in ("rascunho", "prova")]
    groups = [a for a in args if a in names] or ([] if people_only else list(names))
    os.makedirs(WORK, exist_ok=True)
    anchors = {}
    if "cabecas" in groups:
        for index, skin in enumerate(SKINS):
            setup(samples)
            basemesh = human(skin)
            hide_below_collar(basemesh)
            hairs = list(HAIRS)
            for hair in ([hairs[index % len(hairs)], hairs[(index + 4) % len(hairs)]] if proof else hairs):
                added = add_hair(basemesh, hair)
                shoot(f"avatar_cabeca_{skin}_{hair}", anchors)
                remove(added)
            save(anchors)
            print("PRONTO", skin, flush=True)
    if "roupas" in groups:
        for name in OUTFITS:
            setup(samples)
            basemesh = human("clara")
            parts = outfit(basemesh, name)
            basemesh.is_holdout = True
            for obj in bpy.data.objects:        # olhos e sobrancelhas não entram na camada da roupa
                if obj.type == "MESH" and obj not in parts and obj is not basemesh and not obj.is_shadow_catcher:
                    obj.hide_render = True
            shoot(f"avatar_roupa_{name}", anchors)
            save(anchors)
            print("PRONTO", name, flush=True)
    if "chapeus" in groups:
        for name in HATS:
            setup(samples)
            basemesh = human("clara")
            parts = list(M._flatten(hat(name)))
            basemesh.is_holdout = True
            for obj in bpy.data.objects:
                if obj.type == "MESH" and obj not in parts and obj is not basemesh and not obj.is_shadow_catcher:
                    obj.hide_render = True
            shoot(f"avatar_chapeu_{name}", anchors)
            save(anchors)
            print("PRONTO", name, flush=True)
    if "icone" in groups:
        # O ícone do botão Chef: o chef inicial inteiro numa foto só, pequena (o botão mostra com 44 px de largura).
        setup(samples)
        scene = bpy.context.scene
        scene.render.resolution_x, scene.render.resolution_y = ICON_SIZE
        scene.camera.data.ortho_scale = ICON_HEIGHT
        basemesh = human("clara")
        add_hair(basemesh, "curto_castanho")
        outfit(basemesh, "branca")
        hat("toque")
        icon = {}
        shoot("icone_chef", icon)
        cena3d.update_manifest(icon)
        print("PRONTO icone_chef", flush=True)
    for name in PEOPLE:
        if name in args or "pessoas" in args or everything:
            render_person(name, samples)
    if "natal" in args or everything:
        render_santa(samples)
        render_christmas_medal(samples)
    if "folha" in groups:
        with open(os.path.join(cena3d.SPRITES, "sprites.json"), encoding="utf-8") as source:
            sheet(json.load(source))
    print("RETRATOS OK", len(anchors), flush=True)


if __name__ == "__main__":
    main()
