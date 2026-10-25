"""Personagens em 3D (arte realista, pedido do PO em 25/10/2026): o garçom e os 12 clientes montados com o MakeHuman
(extensão MPFB do Blender, peças CC0), posados e fotografados no ângulo do jogo, gravados direto em art/sprites.

Uso (na pasta do projeto):
    C:/Blender/blender-5.2.3-windows-x64/blender.exe -b -P tools/render3d/personagens3d.py -- [nomes...] [rascunho]

Sem nomes, faz todos (garcom e cliente_01 a cliente_12). "rascunho" renderiza mais rápido (menos amostras).

A cena, a luz, a câmera e a gravação no jogo vêm de cena3d.py.
Direções: a pessoa do MakeHuman nasce olhando para -Y; "frente" olha para o +x do jogo (+X aqui, giro de 90°) e
"costas" para o -y do jogo (+Y aqui, giro de 180°); o jogo espelha esses dois para as outras direções.
Quadros (os mesmos da arte 2D): em pé e 8 passos, de frente e de costas (o garçom também com a bandeja); sentado
de frente com as 4 expressões e sentado de costas nas rotações 1 e 2 da cadeira.
"""
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cena3d  # noqa: E402
from cena3d import DENSITY, aim_camera, linear, pixel_of  # noqa: E402

from bl_ext.user_default.mpfb.services.humanservice import HumanService  # noqa: E402
from bl_ext.user_default.mpfb.services.targetservice import TargetService  # noqa: E402

WORK = os.path.join(cena3d.ROOT, "tools", "render3d", "out_personagens")
DATA = os.path.join(bpy.utils.user_resource("EXTENSIONS"), ".user", "user_default", "mpfb", "data")
SYSTEM = os.path.join(bpy.utils.user_resource("EXTENSIONS"), "user_default", "mpfb", "data")

IMAGE_SIZE = (360, 420)

PERSON_HEIGHT = 1.35        # altura da pessoa (unidades), a mesma da arte 2D
SEAT_Z = 0.44               # altura do assento das cadeiras (23 + 3 px da arte 2D)
SEAT_CENTER = (-0.5, 0.5)   # centro da cadeira do piso (-1, -1) do jogo, cujo vértice da frente é a origem
SEAT_BACK = 0.1             # o quadril fica um pouco atrás do meio do assento
THIGH_THICKNESS = 0.07      # do osso do quadril até a parte de baixo da coxa
FACING = {"frente": 90.0, "costas": 180.0}
SEATED_BACK_FACING = {1: -90.0, 2: 180.0}   # cadeira na rotação 1 olha para -x do jogo; na 2, para -y

# Andar: 8 quadros por passada, como o jogo.
WALK_FRAMES = 8
WALK_THIGH = 20.0
WALK_KNEE_SWING = 42.0
WALK_KNEE_STANCE = 6.0
WALK_FOOT = 12.0
WALK_ARM = 15.0
WALK_ELBOW = 18.0
WALK_HIP_TURN = 5.0
WALK_BOB = 0.012
ELBOW_REST = 8.0           # o cotovelo um pouco dobrado com o braço solto
FINGER_CURL = 22.0
TRAY_PALM = 90.0            # giro da mão da bandeja, no eixo dela, para a palma ficar para cima

# Expressões dos clientes sentados (formas do próprio MakeHuman: cantos da boca e sobrancelhas).
EXPRESSIONS = {
    "feliz": {"mouth/mouth-angles-up": 1.0},
    "esperando": {"eyebrows/eyebrows-angle-up": 0.6},
    "bravo": {"mouth/mouth-angles-down": 1.0, "eyebrows/eyebrows-angle-down": 1.0},
    "comendo": {"mouth/mouth-angles-up": 0.5},
}

# Quem é quem (roupas do pacote do sistema e dos pacotes livres suits01 e glasses01). gender 1 = homem; race = mistura (africana, asiática, europeia); tint = cor do cabelo
# ("tipo:cor", tipo multiply para cabelo claro ou color para trocar o tom guardando a luz).
MALE_BROWS, FEMALE_BROWS = "eyebrow001", "eyebrow006"
CHARACTERS = {
    "garcom": dict(gender=1.0, age=0.45, muscle=0.6, weight=0.45, race=(0.3, 0.25, 0.45), skin="young_caucasian_male2",
                   hair="short02", outfit=["toigo_suit_with_jacket_and_bowtie", "shoes03"], height=1.0, tray=True),
    "cliente_01": dict(top="#ff4d6d", gender=0.0, age=0.4, weight=0.45, race=(0.0, 0.1, 0.9), skin="young_caucasian_female",
                       hair="ponytail01", outfit=["female_casualsuit01", "shoes06"], height=0.96),
    "cliente_02": dict(top="#2fae4e", gender=1.0, age=0.42, muscle=0.55, weight=0.5, race=(0.55, 0.1, 0.35), skin="young_african_male",
                       hair="short02", outfit=["male_casualsuit06", "shoes05"], height=1.0),
    "cliente_03": dict(top="#ffc928", gender=0.0, age=0.4, weight=0.5, race=(0.9, 0.0, 0.1), skin="young_african_female",
                       hair="afro01", outfit=["female_casualsuit02", "shoes06"], height=0.96),
    "cliente_04": dict(gender=0.0, age=0.45, weight=0.4, race=(0.0, 0.05, 0.95), skin="young_caucasian_female2",
                       hair="bob02", hair_tint="multiply:#c9562a", outfit=["female_elegantsuit01", "shoes03"], height=0.95),
    "cliente_05": dict(top="#ff7a2f", gender=1.0, age=0.38, muscle=0.5, weight=0.55, race=(0.25, 0.45, 0.3), skin="young_asian_male",
                       hair="short04", outfit=["male_casualsuit02", "shoes02"], height=0.98),
    "cliente_06": dict(top="#2fd1b5", gender=0.0, age=0.38, weight=0.45, race=(0.0, 0.0, 1.0), skin="young_caucasian_female",
                       hair="long01", hair_tint="ramp:#7a5528,#f7e0a3", outfit=["female_sportsuit01", "shoes05"], height=0.97),
    "cliente_07": dict(gender=1.0, age=0.6, muscle=0.5, weight=0.6, race=(0.15, 0.1, 0.75), skin="middleage_caucasian_male",
                       hair="short03", outfit=["male_casualsuit03", "shoes01"], height=1.0),
    "cliente_08": dict(gender=0.0, age=0.92, weight=0.55, race=(0.0, 0.0, 1.0), skin="old_caucasian_female",
                       hair="bob02", hair_tint="multiply:#b9b6b2",
                       outfit=["female_elegantsuit01", "shoes04", "spamrakuen_tbm_glasses_frames_01"], height=0.93),
    "cliente_09": dict(gender=1.0, age=0.66, muscle=0.55, weight=0.65, race=(0.85, 0.0, 0.15), skin="middleage_african_male",
                       hair=None, outfit=["male_casualsuit05", "shoes01"], height=1.0),
    "cliente_10": dict(top="#2b2b38", gender=1.0, age=0.36, muscle=0.6, weight=0.4, race=(0.0, 0.05, 0.95), skin="young_caucasian_male",
                       hair="short01", outfit=["male_casualsuit04", "shoes06"], height=1.0),
    "cliente_11": dict(top="#ffd23f", gender=0.0, age=0.4, weight=0.45, race=(0.05, 0.9, 0.05), skin="young_asian_female",
                       hair="braid01", outfit=["female_casualsuit02", "shoes02"], height=0.95),
    "cliente_12": dict(gender=1.0, age=0.4, muscle=0.5, weight=0.5, race=(0.05, 0.85, 0.1), skin="young_asian_male",
                       hair="short02", outfit=["male_casualsuit01", "shoes02"], height=0.99),
}


# --- A pessoa -------------------------------------------------------------------------------------------------

def _asset(kind, name):
    return os.path.join(DATA, kind, name, name + ".mhclo")


def build(spec):
    macro = TargetService.get_default_macro_info_dict()
    for key in ("gender", "age", "muscle", "weight"):
        if key in spec:
            macro[key] = spec[key]
    african, asian, caucasian = spec["race"]
    macro["race"] = {"african": african, "asian": asian, "caucasian": caucasian}
    basemesh = HumanService.create_human(macro_detail_dict=macro)
    HumanService.add_builtin_rig(basemesh, "game_engine")
    rig = basemesh.parent
    HumanService.set_character_skin(os.path.join(DATA, "skins", spec["skin"], spec["skin"] + ".mhmat"), basemesh)
    HumanService.add_mhclo_asset(os.path.join(DATA, "eyes", "high-poly", "high-poly.mhclo"), basemesh, asset_type="Eyes")
    brows = MALE_BROWS if spec["gender"] > 0.5 else FEMALE_BROWS
    HumanService.add_mhclo_asset(_asset("eyebrows", brows), basemesh, asset_type="Eyebrows")
    HumanService.add_mhclo_asset(_asset("eyelashes", "eyelashes01" if spec["gender"] > 0.5 else "eyelashes02"), basemesh,
                                 asset_type="Eyelashes")
    if spec.get("hair"):
        HumanService.add_mhclo_asset(_asset("hair", spec["hair"]), basemesh, asset_type="Hair")
        if spec.get("hair_tint"):
            mode, color = spec["hair_tint"].split(":")
            for obj in bpy.data.objects:
                if obj.type == "MESH" and obj.name.endswith("." + spec["hair"]):
                    tint(obj.active_material, color, mode)
    for item in spec["outfit"]:
        HumanService.add_mhclo_asset(_asset("clothes", item), basemesh, asset_type="Clothes")
        if item in TOP_REGIONS and spec.get("top"):
            for obj in bpy.data.objects:
                if obj.type == "MESH" and obj.name.endswith("." + item):
                    recolor_top(obj.active_material, item, spec["top"])
    zs = [(basemesh.matrix_world @ Vector(c)).z for c in basemesh.bound_box]
    rig.scale = (PERSON_HEIGHT * spec.get("height", 1.0) / (max(zs) - min(zs)),) * 3
    bpy.context.view_layer.update()
    return basemesh, rig


# Onde fica a camiseta no mapa de textura de cada roupa (frações da imagem: x0, y0, x1, y1, com y de cima para
# baixo): a frente e as costas no alto e as mangas à direita. O resto (a calça, o short) não muda de cor.
TOP_REGIONS = {
    "female_casualsuit01": [(0.0, 0.0, 1.0, 0.43), (0.72, 0.43, 1.0, 0.82)],
    "female_casualsuit02": [(0.0, 0.0, 1.0, 0.43), (0.72, 0.43, 1.0, 0.82)],
    "female_sportsuit01": [(0.0, 0.0, 1.0, 0.43), (0.72, 0.43, 1.0, 0.82)],
    "male_casualsuit02": [(0.0, 0.0, 0.7, 0.43), (0.7, 0.0, 1.0, 1.0)],
    "male_casualsuit04": [(0.0, 0.0, 1.0, 0.43)],
    "male_casualsuit06": [(0.0, 0.0, 1.0, 0.43)],
}
TOP_FLATTEN = 0.05     # o quanto o tom da camiseta pode variar (apaga o logotipo e as listras, guarda o tecido)


def recolor_top(material, outfit, color):
    """Pinta a camiseta da roupa na [color], apagando o logotipo: uma cópia da textura, só na memória."""
    image_node = next(n for n in material.node_tree.nodes if n.type == "TEX_IMAGE" and n.name == "diffuseTexture")
    source = image_node.image
    width, height = source.size
    pixels = np.array(source.pixels[:], dtype=np.float32).reshape(height, width, 4)[::-1].copy()
    target = np.array([int(color[i:i + 2], 16) / 255.0 for i in (1, 3, 5)], dtype=np.float32)
    for x0, y0, x1, y1 in TOP_REGIONS[outfit]:
        region = pixels[int(y0 * height):int(y1 * height), int(x0 * width):int(x1 * width), :3]
        light = region @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
        middle = float(np.median(light))
        shade = np.clip(light, middle - TOP_FLATTEN, middle + TOP_FLATTEN) / max(middle, 0.05)
        region[:] = np.clip(target[None, None, :] * shade[:, :, None], 0.0, 1.0)
    copy = bpy.data.images.new(source.name + "_cor", width, height, alpha=True)
    copy.pixels = pixels[::-1].ravel()
    copy.pack()
    image_node.image = copy


def tint(material, color, mode):
    """Muda a cor do material: multiply (escurece o branco na cor), color (troca o tom e clareia um pouco) ou
    ramp ("escuro:claro", a luz da textura vira uma escala entre as duas cores, bom para loiro)."""
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    base = bsdf.inputs["Base Color"]
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


def set_expression(basemesh, expression):
    """Formas do rosto da expressão (as outras voltam a zero) e o reencaixe das sobrancelhas e cílios."""
    for name in {t for values in EXPRESSIONS.values() for t in values}:
        key = "expr-" + name.replace("/", "-")
        weight = expression.get(name, 0.0)
        blocks = basemesh.data.shape_keys.key_blocks if basemesh.data.shape_keys else {}
        if key in blocks:
            blocks[key].value = weight
        elif weight > 0.0:
            TargetService.load_target(basemesh, os.path.join(SYSTEM, "targets", name + ".target.gz"), weight=weight, name=key)
    HumanService.refit(basemesh)


# --- Poses ----------------------------------------------------------------------------------------------------

def rotate(rig, bone, axis, degrees):
    """Gira o osso, na pose em que ele já está (depois do pai), em torno de um eixo do esqueleto que passa pela
    junta: X = de um lado ao outro do corpo, Y = da frente para trás (a pessoa olha para -Y), Z = vertical."""
    pose_bone = rig.pose.bones[bone]
    pose_bone.rotation_mode = "QUATERNION"
    bpy.context.view_layer.update()
    current = pose_bone.matrix.copy()
    head = current.to_translation()
    turn = Matrix.Rotation(math.radians(degrees), 4, Vector(axis))
    pose_bone.matrix = Matrix.Translation(head) @ turn @ Matrix.Translation(-head) @ current
    bpy.context.view_layer.update()


def curl(rig, bone, degrees):
    """Dobra o dedo no eixo dele mesmo (fecha a mão)."""
    pose_bone = rig.pose.bones[bone]
    pose_bone.rotation_mode = "QUATERNION"
    pose_bone.rotation_quaternion = Quaternion((1.0, 0.0, 0.0), math.radians(degrees)) @ pose_bone.rotation_quaternion


def point(rig, bone, direction):
    """Aponta o osso (da junta até a ponta) para a [direction] do esqueleto, pelo menor giro."""
    bpy.context.view_layer.update()
    pose_bone = rig.pose.bones[bone]
    current = (pose_bone.tail - pose_bone.head).normalized()
    turn = current.rotation_difference(Vector(direction).normalized())
    angle = math.degrees(turn.angle)
    if angle > 0.01:
        rotate(rig, bone, turn.axis, angle)


def tilt(direction, degrees):
    """A direção girada em torno de X (positivo = para trás, já que a pessoa olha para -Y)."""
    return Matrix.Rotation(math.radians(degrees), 3, "X") @ Vector(direction)


def side_of(rig, bone):
    """+1 para o osso do lado +X do esqueleto, -1 para o do lado -X."""
    return 1.0 if rig.data.bones[bone].head_local.x > 0.0 else -1.0


def rest_direction(rig, bone):
    data = rig.data.bones[bone]
    return (data.tail_local - data.head_local).normalized()


def reset(rig):
    for pose_bone in rig.pose.bones:
        pose_bone.rotation_mode = "QUATERNION"
        pose_bone.rotation_quaternion = Quaternion()
        pose_bone.location = (0.0, 0.0, 0.0)


def relax_hands(rig, skip=()):
    for side in ("l", "r"):
        if side in skip:
            continue
        for finger in ("index", "middle", "ring", "pinky"):
            for joint in ("01", "02", "03"):
                curl(rig, f"{finger}_{joint}_{side}", FINGER_CURL)


def arms_down(rig, swing=(0.0, 0.0), skip=()):
    """Braços soltos junto do corpo, o cotovelo um pouco dobrado; [swing] balança cada um (graus, + = para trás)."""
    for side, angle in zip(("l", "r"), swing):
        if side in skip:
            continue
        out = side_of(rig, f"upperarm_{side}")
        point(rig, f"upperarm_{side}", tilt((out * 0.16, 0.0, -1.0), angle))
        elbow = ELBOW_REST + WALK_ELBOW * max(0.0, -angle) / WALK_ARM
        point(rig, f"lowerarm_{side}", tilt((out * 0.06, 0.0, -1.0), angle - elbow))
        point(rig, f"hand_{side}", tilt((out * 0.03, 0.0, -1.0), angle - elbow))


def legs(rig, side, thigh_deg, knee_deg, foot_deg=0.0, spread=0.06):
    """Perna: a coxa [thigh_deg] graus à frente da vertical, o joelho dobrado [knee_deg], o pé levantado [foot_deg]."""
    out = side_of(rig, f"thigh_{side}")
    point(rig, f"thigh_{side}", tilt((out * spread, 0.0, -1.0), -thigh_deg))
    point(rig, f"calf_{side}", tilt((out * spread * 0.5, 0.0, -1.0), knee_deg - thigh_deg))
    point(rig, f"foot_{side}", tilt(rest_direction(rig, f"foot_{side}"), -foot_deg))


def pose_stand(rig, tray=False):
    reset(rig)
    legs(rig, "l", 0.0, 0.0)
    legs(rig, "r", 0.0, 0.0)
    if tray:
        # a mão direita espalmada para cima, na altura do peito, o antebraço à frente
        arms_down(rig, skip=("r",))
        out = side_of(rig, "upperarm_r")
        point(rig, "upperarm_r", (out * 0.12, -0.3, -1.0))
        point(rig, "lowerarm_r", (out * -0.08, -1.0, 0.04))
        point(rig, "hand_r", (out * -0.05, -1.0, 0.0))
        rotate(rig, "hand_r", rig.pose.bones["hand_r"].tail - rig.pose.bones["hand_r"].head, TRAY_PALM * out)
        relax_hands(rig, skip=("r",))
    else:
        arms_down(rig)
        relax_hands(rig)


def pose_walk(rig, frame, tray=False):
    """Quadro do passo: as pernas em fases opostas, o joelho dobrando na volta, o pé subindo, o quadril girando um
    pouco e os braços ao contrário das pernas."""
    reset(rig)
    phase = 2.0 * math.pi * frame / WALK_FRAMES
    rotate(rig, "pelvis", (0, 0, 1), WALK_HIP_TURN * math.sin(phase))
    rotate(rig, "spine_02", (0, 0, 1), -WALK_HIP_TURN * math.sin(phase))
    swings = []
    for side, offset in (("l", 0.0), ("r", math.pi)):
        local = (phase + offset) % (2.0 * math.pi)
        swing = math.sin(local)                               # 1 = perna toda à frente, -1 = toda atrás
        lift = max(0.0, math.sin(local - math.pi * 0.5))       # a perna que volta para a frente sobe
        legs(rig, side, WALK_THIGH * swing, WALK_KNEE_STANCE + WALK_KNEE_SWING * lift, WALK_FOOT * lift)
        swings.append(WALK_ARM * swing)                        # o braço vai para trás quando a perna vai à frente
    if tray:
        arms_down(rig, (swings[0], 0.0), skip=("r",))
        out = side_of(rig, "upperarm_r")
        point(rig, "upperarm_r", (out * 0.12, -0.3, -1.0))
        point(rig, "lowerarm_r", (out * -0.08, -1.0, 0.04))
        point(rig, "hand_r", (out * -0.05, -1.0, 0.0))
        rotate(rig, "hand_r", rig.pose.bones["hand_r"].tail - rig.pose.bones["hand_r"].head, TRAY_PALM * out)
        relax_hands(rig, skip=("r",))
    else:
        arms_down(rig, swings)
        relax_hands(rig)
    return -WALK_BOB * abs(math.cos(phase))   # o corpo desce um pouco quando os dois pés tocam o chão


def pose_sit(rig):
    reset(rig)
    rotate(rig, "spine_01", (1, 0, 0), -5.0)
    for side in ("l", "r"):
        out = side_of(rig, f"thigh_{side}")
        point(rig, f"thigh_{side}", (out * 0.12, -1.0, -0.02))
        point(rig, f"calf_{side}", (out * 0.04, -0.18, -1.0))
        point(rig, f"foot_{side}", rest_direction(rig, f"foot_{side}"))
        point(rig, f"upperarm_{side}", (out * 0.12, -0.32, -1.0))
        point(rig, f"lowerarm_{side}", (out * -0.25, -1.0, -0.35))
        point(rig, f"hand_{side}", (out * -0.2, -1.0, -0.5))
    relax_hands(rig)


def place_seated(rig, facing_deg):
    """Põe o quadril sobre o assento da cadeira, um pouco atrás do meio, virado para [facing_deg]."""
    rig.rotation_euler = (0.0, 0.0, math.radians(facing_deg))
    rig.location = (0.0, 0.0, 0.0)
    bpy.context.view_layer.update()
    thigh_l = rig.matrix_world @ rig.pose.bones["thigh_l"].head
    thigh_r = rig.matrix_world @ rig.pose.bones["thigh_r"].head
    hip = (thigh_l + thigh_r) / 2.0
    forward = Vector((math.cos(math.radians(facing_deg - 90.0)), math.sin(math.radians(facing_deg - 90.0)), 0.0))
    target = Vector((SEAT_CENTER[0], SEAT_CENTER[1], SEAT_Z + THIGH_THICKNESS)) - forward * SEAT_BACK
    rig.location = target - hip
    bpy.context.view_layer.update()


# --- Fotos e gravação no jogo ---------------------------------------------------------------------------------

def shoot(name, anchor_point):
    return cena3d.shoot(name, anchor_point, WORK)


def render_character(look, spec, anchors, extras):
    basemesh, rig = build(spec)
    aim_camera((0.0, 0.0, PERSON_HEIGHT * 0.48))
    tray_obj = make_tray() if spec.get("tray") else None
    for view, facing in FACING.items():
        for pose in ["em_pe"] + [f"passo_{i}" for i in range(WALK_FRAMES)]:
            for tray in ((False, True) if tray_obj else (False,)):
                drop = pose_walk(rig, int(pose[6:]), tray) if pose != "em_pe" else (pose_stand(rig, tray) or 0.0)
                rig.rotation_euler = (0.0, 0.0, math.radians(facing))
                rig.location = (0.0, 0.0, drop)
                bpy.context.view_layer.update()
                if tray_obj:
                    hold_tray(rig, tray_obj, tray)
                name = f"{look}_{view}_{pose}" + ("_bandeja" if tray else "")
                anchors[name] = shoot(name, (0.0, 0.0, 0.0))
                if tray and pose == "em_pe":
                    feet = pixel_of((0.0, 0.0, 0.0))
                    center = pixel_of(tray_obj.location)
                    key = "tray_food" if view == "frente" else "tray_food_back"
                    extras[key] = [round((center[0] - feet[0]) / DENSITY, 2), round((center[1] - feet[1]) / DENSITY, 2)]
    if tray_obj:
        tray_obj.hide_render = True
    if look.startswith("cliente"):
        pose_sit(rig)
        aim_camera((SEAT_CENTER[0], SEAT_CENTER[1], 0.62))
        for expression, values in EXPRESSIONS.items():
            set_expression(basemesh, values)
            place_seated(rig, FACING["frente"])
            name = f"{look}_sentado_{expression}"
            anchors[name] = shoot(name, (0.0, 0.0, 0.0))
        set_expression(basemesh, EXPRESSIONS["feliz"])
        for rotation, facing in SEATED_BACK_FACING.items():
            place_seated(rig, facing)
            name = f"{look}_sentado_costas_r{rotation}"
            anchors[name] = shoot(name, (0.0, 0.0, 0.0))


def make_tray():
    bpy.ops.mesh.primitive_cylinder_add(radius=0.2, depth=0.014, vertices=64)
    tray = bpy.context.active_object
    mat = bpy.data.materials.new("Bandeja")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (0.82, 0.85, 0.89, 1.0)
    bsdf.inputs["Metallic"].default_value = 0.9
    bsdf.inputs["Roughness"].default_value = 0.2
    tray.data.materials.append(mat)
    bevel = tray.modifiers.new("Chanfro", "BEVEL")
    bevel.width = 0.006
    bevel.segments = 2
    return tray


def hold_tray(rig, tray, show):
    tray.hide_render = not show
    if show:
        hand = rig.pose.bones["hand_r"]
        palm = rig.matrix_world @ ((hand.head + hand.tail) / 2.0)
        tray.location = palm + Vector((0.0, 0.0, 0.05))
        bpy.context.view_layer.update()


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    draft = "rascunho" in args
    looks = [a for a in args if a in CHARACTERS] or list(CHARACTERS)
    os.makedirs(WORK, exist_ok=True)
    anchors, extras = {}, {}
    for look in looks:
        cena3d.setup(32 if draft else 96, IMAGE_SIZE)
        render_character(look, CHARACTERS[look], anchors, extras)
        print("PRONTO", look, flush=True)

    def tray(manifest):
        width = manifest["characters"]["tray_food"][2]
        for key, offset in extras.items():
            manifest["characters"][key] = offset + [width]
    cena3d.update_manifest(anchors, tray)
    print("PERSONAGENS OK", len(anchors), flush=True)


main()
