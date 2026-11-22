"""DT-106: cozinha remodelada em 3D, com saída exclusiva em staging.

Blender -b -t 3 -P tools/render3d/cozinha_codex.py -- --proof
Blender -b -t 3 -P tools/render3d/cozinha_codex.py -- --out build/visual-cenario/cozinha

Os módulos históricos fornecem materiais, ornamentos e primitivas. A estrutura
nova fica aqui; nenhuma fonte antiga ou imagem de produção é modificada.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Quaternion

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cena3d as C
import moveis3d as M
import amostra_a3d as A
import cozinha_a3d as K
import enfeites_a3d as E
import assentos_a3d as S
from moveis_codex import bounds, reshape_meshes, write_json

ROOT = Path(__file__).resolve().parents[2]
Z_WORLD = 128 / math.sqrt(2) * math.sin(math.radians(60))
# Referências geométricas explícitas. Não dependem de valores do manifesto.
DESIGN_Z = (1 / 96) * math.sqrt(2) / math.cos(math.radians(30))
H = 44 * DESIGN_Z
POT_Z = H + 0.046
FRONT = -0.465
BACK_Y = 0.45
WINDOW_W, WINDOW_H, WINDOW_Z = 0.5376, H * 0.24, H * 0.37
COUNTER_TOP = 47 * DESIGN_Z
COUNTER_WIDTH = 1.064
CAB_TOP = 0.445
SPECIAL_STOVES = ("train_locomotive", "train_wagon", "train_dining", "witch_cauldron", "santa_oven")
STOVES = ("stove_basic", *K.STOVES, *SPECIAL_STOVES)
COUNTERS = ("counter_basic", *K.COUNTERS)
MACHINES = ("machine_coffee", "machine_coffee_smart", "machine_juice", "machine_frozen")
ITEMS = (*STOVES, *COUNTERS, *MACHINES, "delivery_counter")
PROOF = ("stove_basic", "stove_blue", "stove_samba", "santa_oven", "counter_basic", "counter_bamboo", "counter_samba", "machine_coffee_smart")


def feet(width, depth, top, material, radius=0.025):
    return [A.taper((sx * width / 2, sy * depth / 2, 0),
                    (sx * (width / 2 - 0.012), sy * (depth / 2 - 0.012), top),
                    radius * 0.7, radius, material)
            for sx in (-1, 1) for sy in (-1, 1)]


def range_stove(body, trim, knob, handle, door=None, hob=None, back=None,
                panel=None, base=None, rounded=0.018, chrome_legs=None,
                back_h=0.3, knob_radius=0.034):
    """Estrutura nova, preservando a posição exata da janela e das grelhas.

    Frente com cantos contínuos, rodapé recuado, pernas visíveis, porta em
    relevo e comandos separados. O espelho continua recebendo o tema original.
    """
    iron = A.cast_iron("#29292b")
    steel = A.brushed_steel("#ddd5c6")
    dark = M.solid("#1c2221", 0.4, 0.2)
    width, depth = 0.91, 0.90
    body_y = FRONT + depth / 2
    parts = feet(0.79, 0.79, 0.102, chrome_legs or trim, 0.028)
    parts += [M.box((0.82, 0.80, 0.035), (0, body_y, 0.10), base or iron, 0.012),
              M.box((width, depth, H - 0.13), (0, body_y, (H + 0.13) / 2), body, max(rounded, 0.038)),
              M.box((0.966, 0.958, 0.034), (0, -0.001, H - 0.005), trim, 0.014),
              M.box((0.852, 0.84, 0.016), (0, -0.015, H + 0.016), hob or dark, 0.018),
              M.box((0.94, 0.048, back_h), (0, BACK_Y, H + back_h / 2), back or body, 0.024),
              M.box((0.976, 0.064, 0.021), (0, BACK_Y, H + back_h + 0.0105), trim, 0.01)]
    # Círculo de queimador legível, com quatro apoios curtos na altura original.
    for u, v in M.STOVE_BURNERS:
        x, y = (u - 0.5) * 0.9, -(v - 0.5) * 0.9
        parts += [M.cylinder(0.068, H + 0.022, H + 0.034, iron, (x, y), bevel=0.004),
                  M.cylinder(0.040, H + 0.034, H + 0.042, steel, (x, y), bevel=0.002)]
        for angle in range(4):
            t = angle * math.pi / 2
            p = M.box((0.068, 0.016, 0.012), (x + math.cos(t) * 0.073, y + math.sin(t) * 0.073, H + 0.040), iron, 0.004)
            p.rotation_euler.z = t
            parts.append(p)
    parts += [M.box((0.87, 0.025, 0.104), (0, FRONT - 0.007, H - 0.079), panel or body, 0.022),
              M.box((0.79, 0.034, H * 0.535), (0, FRONT - 0.009, WINDOW_Z), door or body, 0.028),
              M.box((WINDOW_W + 0.032, 0.008, WINDOW_H + 0.029), (0, FRONT - 0.026, WINDOW_Z), trim, 0.011),
              M.box((WINDOW_W, 0.012, WINDOW_H), (0, FRONT - 0.026, WINDOW_Z), M.solid("#101a1c", 0.17, 0.35, 0.5), 0.008)]
    for x in (-0.30, -0.10, 0.10, 0.30):
        parts += [K.disc(knob_radius * 0.9 + 0.006, x, FRONT - 0.027, H - 0.079, trim, 0.010),
                  K.disc(knob_radius * 0.85, x, FRONT - 0.041, H - 0.079, knob, 0.021),
                  M.box((0.005, 0.004, 0.018), (x, FRONT - 0.054, H - 0.069), steel, 0.001)]
    for x in (-0.28, 0.28):
        parts.append(M.tube((x, FRONT - 0.02, H * 0.63), (x, FRONT - 0.063, H * 0.63), 0.008, trim))
    parts.append(M.tube((-0.29, FRONT - 0.063, H * 0.63), (0.29, FRONT - 0.063, H * 0.63), 0.012, handle))
    # Frisos laterais verticais: dão leitura de chapa sem riscar a silhueta.
    for x in (-0.456, 0.456):
        parts.append(M.box((0.006, 0.64, 0.018), (x, body_y, 0.145), trim, 0.003))
    return parts


def build_stove(item):
    if item == "stove_basic":
        return range_stove(K.enamel("#e1d9c7"), A.brushed_steel("#cac6bc"), A.cast_iron(), A.rich_wood("#70503c"),
                           back=K.enamel("#e1d9c7"), panel=K.enamel("#e1d9c7"), back_h=0.22)
    # Substituição local de função, só neste processo: os ornamentos culturais
    # existentes são montados sobre a nova estrutura; nenhum módulo é regravado.
    if item in K.STOVES:
        original = K.range_stove
        K.range_stove = range_stove
        try:
            return K.STOVES[item]()
        finally:
            K.range_stove = original
    original = E.range_stove
    E.range_stove = range_stove
    try:
        return E.ITEMS[item]()
    finally:
        E.range_stove = original


def counter_materials(item):
    palette = {
        "counter_basic": ("#795039", "#473020", "wood"),
        "counter_wood": ("#a0784b", "#573c2c", "country"),
        "counter_bamboo": ("#b69a68", "#61503c", "japan"),
        "counter_samba": ("#376d4e", "#bb9354", "brazil"),
        "counter_bistro": ("#303b35", "#b79559", "fluted"),
        "counter_marble": ("#ddd2bc", "#b08c50", "fluted"),
        "counter_steel": ("#b8c2ba", "#5b6865", "steel"),
        "counter_pastel": ("#c991a2", "#9d6d6e", "fluted"),
        "counter_red": ("#ae3f44", "#bdc4bc", "diner"),
        "counter_groovy": ("#b3763e", "#6a4d35", "groovy"),
        "counter_arcade": ("#493860", "#b65f8b", "arcade"),
        "counter_neon": ("#302f3b", "#a273ac", "club"),
        "counter_tile": ("#9e653f", "#644432", "tile"),
    }
    color, accent, kind = palette[item]
    body = A.rich_wood(color, 7, 0.3) if kind in ("wood", "country", "japan", "groovy", "tile") else K.enamel(color)
    band = A.rich_wood(accent, 8, 0.25) if kind in ("wood", "country", "japan", "groovy", "tile") else M.solid(accent, 0.38, 0.4)
    top = A.grain_wood("#c3a273", 0.4) if kind in ("country", "japan", "groovy") else S.veined_marble("#ede2cc") if item in ("counter_marble", "counter_bistro") else A.stone_top("#e6ddc9")
    if kind in ("arcade", "club"):
        top = M.solid("#36343e", 0.28, 0.2, 0.4)
    return body, band, top, kind


def counter_structure(body, band, top, height=COUNTER_TOP, width=COUNTER_WIDTH):
    # Tampo contínuo, gabinete recuado e pés finos: a pegada permanece1×1.
    parts = feet(0.85, 0.85, 0.12, band, 0.026)
    parts += [M.box((0.916, 0.916, height - 0.125), (0, 0, (height + 0.035) / 2), body, 0.025),
              M.box((0.925, 0.925, 0.030), (0, 0, 0.113), band, 0.012),
              M.box((0.97, 0.97, 0.018), (0, 0, height - 0.060), band, 0.006),
              M.box((width, width, 0.045), (0, 0, height - 0.0225), top, 0.016)]
    return parts


def counter_face(body, band, kind, height=COUNTER_TOP):
    y, low, high = -0.466, 0.15, height - 0.105
    z, h = (low + high) / 2, high - low
    parts = []
    if kind in ("fluted", "diner", "brazil", "japan"):
        # Ritmo de marcenaria em relevo, não um bloco de bambus gigantes.
        for i in range(15):
            x = (i - 7) * 0.057
            parts.append(M.box((0.024 if kind != "japan" else 0.018, 0.016, h), (x, y, z), body if kind != "japan" else band, 0.007))
        if kind == "japan":
            for zz in (low + 0.055, high - 0.055):
                parts.append(M.box((0.84, 0.017, 0.016), (0, y - 0.006, zz), band, 0.004))
        if kind in ("brazil", "diner"):
            parts.append(M.box((0.85, 0.020, 0.021), (0, y - 0.008, high + 0.015), band, 0.006))
    elif kind in ("arcade", "club"):
        parts.append(M.box((0.80, 0.018, h - 0.05), (0, y, z), M.solid("#25242e", 0.4), 0.025))
        for zz in (low + 0.04, high - 0.04):
            parts.append(M.box((0.72, 0.007, 0.009), (0, y - 0.013, zz), M.emission("#bd87b6" if kind == "club" else "#78b9b0", 1.2), 0.004))
        if kind == "arcade":
            for x, rise in ((-0.18, 0.01), (-0.06, 0.06), (0.06, -0.01), (0.18, 0.035)):
                parts.append(M.box((0.04, 0.012, 0.07 + rise), (x, y - 0.014, z), band, 0.004))
    elif kind == "tile":
        parts += K.tile_panel(0.78, h - 0.03, 0, z, y - 0.01, 0.12)
    else:
        for x in (-0.215, 0.215):
            parts += [M.box((0.39, 0.020, h), (x, y, z), band, 0.014),
                      M.box((0.338, 0.026, h - 0.048), (x, y - 0.008, z), body, 0.015)]
            if kind in ("wood", "steel", "groovy"):
                parts.append(M.tube((x - 0.045, y - 0.032, high - 0.08), (x + 0.045, y - 0.032, high - 0.08), 0.007, band))
            if kind == "country":
                parts.append(M.tube((x - 0.13, y - 0.023, low + 0.05), (x + 0.13, y - 0.023, high - 0.05), 0.013, band))
    return parts


def four_faces(builder):
    parts = []
    for angle in range(4):
        rad = math.pi * angle / 2
        for obj in builder():
            x, y = obj.location.x, obj.location.y
            obj.location.x, obj.location.y = x * math.cos(rad) - y * math.sin(rad), x * math.sin(rad) + y * math.cos(rad)
            if obj.rotation_mode == "QUATERNION":
                obj.rotation_quaternion = Quaternion((0, 0, 1), rad) @ obj.rotation_quaternion
            else:
                obj.rotation_euler.z += rad
            parts.append(obj)
    return parts


def build_counter(item):
    body, band, top, kind = counter_materials(item)
    return counter_structure(body, band, top) + four_faces(lambda: counter_face(body, band, kind))


def machine_cabinet(color):
    body, band = A.rich_wood(color, 8, 0.35), A.rich_wood("#4e3a2c", 7, 0.25)
    parts = feet(0.70, 0.70, 0.095, band, 0.022)
    parts += [M.box((0.78, 0.78, 0.31), (0, 0, 0.237), body, 0.026),
              M.box((0.88, 0.88, 0.04), (0, 0, CAB_TOP - 0.02), A.stone_top("#e7ddc6"), 0.017)]
    for x in (-0.18, 0.18):
        parts += [M.box((0.33, 0.018, 0.22), (x, -0.398, 0.25), band, 0.009),
                  M.box((0.29, 0.024, 0.18), (x, -0.408, 0.25), body, 0.012),
                  M.tube((x - 0.045, -0.431, 0.30), (x + 0.045, -0.431, 0.30), 0.007, S.gold())]
    return parts


def smart_machine():
    z = CAB_TOP
    green, iron, brass = K.enamel("#37594d"), A.cast_iron("#272d2b"), S.gold()
    parts = machine_cabinet("#6d4c35")
    parts += [M.box((0.51, 0.51, 0.58), (0, 0.035, z + 0.29), green, 0.045),
              M.box((0.39, 0.025, 0.23), (0, -0.232, z + 0.42), iron, 0.025),
              M.box((0.31, 0.008, 0.145), (0, -0.249, z + 0.445), M.emission("#82aaa2", 0.65), 0.012),
              M.box((0.30, 0.024, 0.185), (0, -0.234, z + 0.16), iron, 0.025),
              M.box((0.43, 0.19, 0.025), (0, -0.244, z + 0.025), A.brushed_steel(), 0.009)]
    for i in range(5):
        parts.append(M.box((0.31, 0.008, 0.006), (0, -0.29 + i * 0.023, z + 0.041), iron, 0.001))
    for x in (-0.075, 0.075):
        parts.append(K.disc(0.025, x, -0.258, z + 0.435, brass, 0.008))
    parts += [M.cylinder(0.022, z + 0.20, z + 0.26, A.brushed_steel(), (0, -0.23)),
              E._cup(0, -0.255, z + 0.042),
              S.lathe([(0, z + 0.58), (0.125, z + 0.58), (0.14, z + 0.74), (0.13, z + 0.76), (0, z + 0.76)], E.glass("#d1e0d5", 0.18), (0, 0.09)),
              M.cylinder(0.118, z + 0.59, z + 0.69, M.solid("#60432d", 0.7), (0, 0.09)),
              M.cylinder(0.145, z + 0.75, z + 0.78, iron, (0, 0.09), bevel=0.012)]
    return parts


def build_machine(item):
    if item == "machine_coffee_smart":
        return smart_machine()
    # Mantém as peças funcionais reconhecíveis, sobre gabinete redesenhado.
    # A escala é aplicada à malha 3D dos aparelhos, antes da fotografia.
    cabinet = []
    original = E.machine_cabinet
    def replacement(color):
        cabinet.extend(machine_cabinet(color))
        return list(cabinet)  # o builder acrescenta aparelho à lista que recebe
    E.machine_cabinet = replacement
    try:
        parts = E.ITEMS[item]()
    finally:
        E.machine_cabinet = original
    appliance = [obj for obj in parts if obj not in cabinet]
    reshape_meshes(appliance, 0.88, 0.88, lambda z: CAB_TOP + (z - CAB_TOP) * 0.86)
    return parts


def build_delivery():
    # Caixas e placa existentes mantêm seu significado; o balcão é o novo.
    original_core, original_around = K.counter_core, K.around
    K.counter_core = lambda *args, **kwargs: build_counter("counter_basic")
    K.around = lambda face: []  # raised_panels retorna fábrica; não cria malhas aqui.
    try:
        return E.delivery_counter()
    finally:
        K.counter_core, K.around = original_core, original_around


def build(item):
    if item in STOVES:
        return build_stove(item)
    if item in COUNTERS:
        return build_counter(item)
    if item in MACHINES:
        return build_machine(item)
    return build_delivery()


def source_info():
    modules = [Path(__file__), Path(__file__).with_name("moveis_codex.py"), *(Path(m.__file__) for m in (C, M, A, K, E, S))]
    return {str(p.relative_to(ROOT)).replace("\\", "/"): hashlib.sha256(p.read_bytes()).hexdigest() for p in modules}


def contract(items, args):
    return {"schema": 1, "density": args.density, "samples": args.samples,
            "blender": bpy.app.version_string, "threads": args.threads,
            "source_sha256": source_info(), "anchor": "front tile vertex; M.assemble(1,1)",
            "shadow": "native radial transparent material; no alpha threshold or bitmap cleanup",
            "floor_center_world": [0, -32], "vertical_world_pixels_per_unit": Z_WORLD,
            "stove": {"hob_z": H, "pot_support_z": POT_Z, "pot_support_world": POT_Z * Z_WORLD,
                      "burners_uv": M.STOVE_BURNERS, "burner_size": 0.9,
                      "window_center": [0, FRONT - 0.026, WINDOW_Z], "window_size": [WINDOW_W, 0.012, WINDOW_H],
                      "glow_center": [0, FRONT - 0.034, WINDOW_Z], "glow_rotations": [0, 3]},
            "counter": {"top_z": COUNTER_TOP, "top_world": 62.67, "top_width": COUNTER_WIDTH,
                        "body_width": 0.916, "continuous_neighbor_tops": True},
            "machine": {"cabinet_top_z": CAB_TOP, "cabinet_width": 0.78, "top_width": 0.88},
            "items": {item: {"kind": "stove" if item in STOVES else "counter" if item in COUNTERS or item == "delivery_counter" else "machine",
                             "footprint": [1, 1], "rotations": [0, 1, 2, 3]} for item in items},
            "rendered_geometry": {}}


def setup(args, shadow=True):
    C.setup(args.samples, (round(640 * args.density / 4), round(900 * args.density / 4)),
            shadow_center=(0.5, -0.5), shadow_size=(1.14, 1.14), rig="a")
    bpy.context.scene.render.threads_mode = "FIXED"
    bpy.context.scene.render.threads = args.threads
    # Cycles shadow catcher produz alfa1 espalhado pelo fundo, inclusive fora
    # da própria malha. O material abaixo desenha a sombra em3D e chega a alfa0
    # antes da borda. O PNG mantém integralmente o alfa nativo renderizado.
    for obj in list(bpy.data.objects):
        if obj.is_shadow_catcher:
            if shadow:
                obj.is_shadow_catcher = False
                obj.visible_camera = False  # mantém o rebatimento original do piso claro
            else:
                bpy.data.objects.remove(obj, do_unlink=True)
    if shadow:
        mat = bpy.data.materials.get("CodexKitchenShadow")
        if mat is None:
            mat = bpy.data.materials.new("CodexKitchenShadow")
            mat.use_nodes = True
            n, links = mat.node_tree.nodes, mat.node_tree.links
            n.clear()
            coords = n.new("ShaderNodeTexCoord")
            center = n.new("ShaderNodeVectorMath")
            center.operation = "SUBTRACT"
            center.inputs[1].default_value = (0.5, 0.5, 0)
            length = n.new("ShaderNodeVectorMath")
            length.operation = "LENGTH"
            fade = n.new("ShaderNodeMapRange")
            fade.interpolation_type = "SMOOTHERSTEP"
            for key, value in (("From Min", 0.18), ("From Max", 0.5), ("To Min", 0.25), ("To Max", 0)):
                fade.inputs[key].default_value = value
            clear = n.new("ShaderNodeBsdfTransparent")
            dark = n.new("ShaderNodeEmission")
            dark.inputs["Color"].default_value = (0.022, 0.016, 0.012, 1)
            mix = n.new("ShaderNodeMixShader")
            output = n.new("ShaderNodeOutputMaterial")
            links.new(coords.outputs["UV"], center.inputs[0])
            links.new(center.outputs["Vector"], length.inputs[0])
            links.new(length.outputs["Value"], fade.inputs["Value"])
            links.new(fade.outputs["Result"], mix.inputs[0])
            links.new(clear.outputs[0], mix.inputs[1])
            links.new(dark.outputs[0], mix.inputs[2])
            links.new(mix.outputs[0], output.inputs["Surface"])
        bpy.ops.mesh.primitive_plane_add(size=1.18, location=(0.5, -0.5, 0.001))
        plane = bpy.context.object
        plane.data.materials.append(mat)
        plane.visible_diffuse = False
        plane.visible_glossy = False
        plane.visible_shadow = False


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("items", nargs="*")
    parser.add_argument("--out", default="build/visual-cenario/cozinha")
    parser.add_argument("--samples", type=int, default=32)
    parser.add_argument("--density", type=float, default=4)
    parser.add_argument("--threads", type=int, default=3)
    parser.add_argument("--proof", action="store_true")
    parser.add_argument("--geometry-only", action="store_true")
    parser.add_argument("--resume", action="store_true")
    args = parser.parse_args(argv)
    out, build_root = (ROOT / args.out).resolve(), (ROOT / "build").resolve()
    if build_root not in out.parents:
        parser.error("Saída deve ficar dentro de build; instalação não é permitida")
    if args.samples < 1 or not 1 <= args.density <= 8 or not 1 <= args.threads <= 4:
        parser.error("samples>=1, density1..8, threads1..4")
    items = list(args.items or (PROOF if args.proof else ITEMS))
    if set(items) - set(ITEMS):
        parser.error("IDs desconhecidos: " + str(sorted(set(items) - set(ITEMS))))
    production = json.loads((ROOT / "art/sprites/sprites.json").read_text(encoding="utf-8"))
    expected = {name for item in items for name in production["furniture"][item].values()}
    expected.update(production["stove_glow"].values())
    C.SPRITES = str(out / "sprites")
    Path(C.SPRITES).mkdir(parents=True, exist_ok=True)
    C.DENSITY, C.PX_PER_UNIT, C.MIN_ALPHA = args.density, 128 / math.sqrt(2) * args.density, 0.0
    physical = contract(items, args)
    patch = {"sprites": {}}
    if args.resume and (out / "manifest_patch.json").exists():
        prior = json.loads((out / "physical_contract.json").read_text())
        if prior["source_sha256"] != physical["source_sha256"] or prior["density"] != args.density or prior["samples"] != args.samples:
            raise ValueError("Não retomar geração com fontes/parâmetros diferentes")
        patch = json.loads((out / "manifest_patch.json").read_text())
        physical["rendered_geometry"] = prior["rendered_geometry"]
    def save(name, objects, rotation):
        if name not in expected:
            raise ValueError("Sprite novo fora do contrato: " + name)
        geo = bounds(objects)
        if not all(math.isfinite(v) for p in geo.values() for v in p):
            raise ValueError("Geometria inválida: " + name)
        physical["rendered_geometry"][name] = geo
        if not args.geometry_only:
            anchor, center = M.assemble(objects, (1, 1), rotation)
            C.aim_camera((center[0], center[1], 0.60))
            patch["sprites"][name] = {"anchor": C.shoot(name, anchor, str(out / "raw")), "density": args.density}
        write_json(out / "physical_contract.json", physical)
        write_json(out / "manifest_patch.json", patch)
        print("READY", name, flush=True)
    for item in items:
        for rotation in ([0] if args.proof or args.geometry_only else range(4)):
            name = production["furniture"][item][str(rotation)]
            if args.resume and name in patch["sprites"] and (out / "sprites" / (name + ".png")).exists():
                continue
            setup(args)
            save(name, list(M._flatten(build(item))), rotation)
    if not args.proof and not args.geometry_only:
        for rotation in (0, 3):
            name = production["stove_glow"][str(rotation)]
            if args.resume and name in patch["sprites"] and (out / "sprites" / (name + ".png")).exists():
                continue
            setup(args, shadow=False)
            glow = M.box((WINDOW_W, 0.004, WINDOW_H), (0, FRONT - 0.034, WINDOW_Z), M.emission("#ff8a2c", 0.8), 0.008)
            save(name, [glow], rotation)
    print("STAGING_COMPLETE", len(patch["sprites"]), out, flush=True)


if __name__ == "__main__":
    main(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
