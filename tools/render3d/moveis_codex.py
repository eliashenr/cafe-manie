"""Móveis proporcionais à arte Codex: geometria nativa, saída apenas em staging.

Blender -b -P tools/render3d/moveis_codex.py -- --proof chair_wood table_round
O JSON produzido é uma proposta de merge; este programa nunca instala sprites.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Matrix

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cena3d as C
import moveis3d as M
import amostra_a3d as A
import assentos_a3d as S

ROOT = Path(__file__).resolve().parents[2]
Z_WORLD = 128 / math.sqrt(2) * math.sin(math.radians(60))
SEAT_TOP = 0.28
SEAT_CONTACT = 0.265
SEAT_SETBACK = 0.06
DEFAULT_PROOF = ["chair_wood", "table_round", "chair_japanese", "table_japanese", "chair_brazil", "table_brazil"]
CHAIRS = {"chair_wood": None, **S.CHAIRS}
TABLES = {"table_round": None, **S.TABLES}
# Medidas da geometria anterior à reformulação. Nunca ler table_tops instalado:
# o novo manifesto contém o resultado da transformação, não sua referência.
LEGACY_MANIFEST_SHA256 = "cfa889902be2629357907af11f5a3cdf3b24c26450bd4f7a526053cd841c8f4f"
LEGACY_TABLE_TOP_Z = 34 * ((1.0 / 96.0) * math.sqrt(2.0) / math.cos(math.radians(30.0)))
LEGACY_TABLE_TOP_WORLD = {
    "table_round": 45.33, "table_long": 42.67,
    "table_70s": 45.33, "table_70s_square": 42.67,
    "table_country": 42.67, "table_country_round": 45.33,
    "table_party": 45.33, "table_party_square": 42.67,
    "table_diner": 42.67, "table_diner_round": 45.33,
    "table_mexican": 42.67, "table_mexican_round": 45.33,
    "table_80s": 45.33, "table_80s_square": 42.67,
    "table_italian": 42.67, "table_italian_round": 45.33,
    "table_japanese": 40.0, "table_japanese_round": 40.0,
    "table_french": 45.33, "table_french_square": 42.67,
    "table_brazil": 42.67, "table_brazil_round": 45.33,
    "table_2010s": 42.67, "table_2010s_round": 45.33,
    "table_club": 48.0, "table_club_square": 48.0,
}


def chair_profile(item):
    """Largura útil do assento, largura original e altura do encosto, em pisos."""
    if item == "chair_wood":
        return 0.41, 0.60, 0.56
    if item.startswith("stool_"):
        return 0.34, 0.38, SEAT_TOP
    width = 0.40 if item == "chair_japanese" else 0.41
    if item in ("chair_2010s", "chair_french", "chair_french_red"):
        width = 0.39
    if item in ("chair_70s", "chair_equipal", "chair_club"):
        width = 0.42
    original = 0.57 if item == "chair_equipal" else 0.54
    return width, original, 0.54 if item == "chair_japanese" else 0.56


def table_profile(item):
    height = 0.43 if "japanese" in item else 0.48 if "club" in item else 0.46
    return (1.54 if item == "table_long" else 0.74), 0.74, height


def seated_target(rotation):
    # Same front tile vertex as M.assemble and AgentView._place.
    forward = {0: (0, -1), 1: (-1, 0), 2: (0, 1), 3: (1, 0)}[rotation]
    x = -0.5 - forward[0] * SEAT_SETBACK
    y = 0.5 - forward[1] * SEAT_SETBACK
    return [round(64 * (x + y), 6), round(32 * (x - y) - Z_WORLD * SEAT_CONTACT, 6)]


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.replace(path)


def contract(items, density, samples):
    result = {
        "schema": 1,
        "units": "1 Blender unit = 1 tile side; world pixels are texture pixels / density",
        "density": density,
        "render": {"blender": bpy.app.version_string, "samples": samples, "rig": "a"},
        "source_geometry": {
            "manifest_snapshot": "build/visual-reformulacao/moveis-completo/antes_instalacao/sprites.json",
            "manifest_snapshot_sha256": LEGACY_MANIFEST_SHA256,
            "table_tops_world": LEGACY_TABLE_TOP_WORLD,
            "round_top_z": LEGACY_TABLE_TOP_Z,
            "note": "Valores incorporados ao gerador; não dependem do backup nem do manifesto instalado.",
            "generator_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            "modules_sha256": {Path(module.__file__).name: hashlib.sha256(Path(module.__file__).read_bytes()).hexdigest()
                               for module in (C, M, A, S)},
        },
        "anchor": "front vertex of occupied tile, unchanged from production",
        "vertical_world_pixels_per_unit": Z_WORLD,
        "chair": {
            "seat_top_z": SEAT_TOP, "seat_contact_z": SEAT_CONTACT,
            "seat_setback": SEAT_SETBACK,
            "seat_top_world": round(SEAT_TOP * Z_WORLD, 6),
            "seat_target_world": {str(r): seated_target(r) for r in range(4)},
            "floor_center_world": [0, -32],
        },
        "items": {},
    }
    for item in items:
        if item in CHAIRS:
            width, previous, back = chair_profile(item)
            result["items"][item] = {
                "kind": "chair", "seat_width": width, "seat_depth": width,
                "previous_seat_width": previous, "linear_width_ratio": width / previous,
                "seat_diamond_screen_width_world": 128 * width,
                "back_top_z": back, "footprint": [1, 1],
            }
        else:
            width, depth, top = table_profile(item)
            result["items"][item] = {
                "kind": "table", "top_width": width, "top_depth": depth,
                "top_z": top, "top_world": round(top * Z_WORLD, 6),
                "footprint": [2, 1] if item == "table_long" else [1, 1],
            }
    return result


def chair_wood():
    """Bistrô leve: encosto separado, pés afinados e moldura estreita."""
    wood = A.rich_wood(A.WALNUT, 9, 0.35)
    leather = A.leather(A.BURGUNDY)
    parts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(A.taper((sx * 0.185, sy * 0.185, 0), (sx * 0.163, sy * 0.163, 0.228), 0.010, 0.017, wood))
    parts += [M.box((0.41, 0.41, 0.028), (0, 0, 0.235), wood, 0.008),
              A.cushion(0.20, 0.246, SEAT_TOP, leather, 0.014)]
    back = [A.arc_band(0.218, 0.025, 0.345, 0.54, 30, 150, leather, (0, -0.035), bevel=0.008),
            A.arc_band(0.222, 0.031, 0.536, 0.56, 27, 153, wood, (0, -0.035), bevel=0.007)]
    for angle in (32, 148):
        theta = math.radians(angle)
        x, y = math.cos(theta) * 0.205, -0.035 + math.sin(theta) * 0.205
        back.append(M.tube((x, y, 0.235), (x, y, 0.545), 0.012, wood))
    return parts, back


def table_round():
    """Tampo fino e pedestal de ferro, conservando a vela do bistrô."""
    h = table_profile("table_round")[2]
    iron = A.cast_iron()
    parts = [M.cylinder(0.37, h - 0.03, h, A.grain_wood(A.HONEY, 0.65), bevel=0.009, vertices=80),
             M.cylinder(0.342, h - 0.05, h - 0.03, A.rich_wood(A.WALNUT, 5, 0.35), bevel=0.006, vertices=80),
             M.cylinder(0.027, 0.085, h - 0.045, iron, bevel=0.004),
             M.cylinder(0.045, h - 0.072, h - 0.045, iron, bevel=0.006),
             M.cylinder(0.047, 0.065, 0.105, iron, bevel=0.010)]
    for angle in (90, 210, 330):
        theta = math.radians(angle)
        foot = math.cos(theta) * 0.245, math.sin(theta) * 0.245
        parts += [M.tube((math.cos(theta) * 0.032, math.sin(theta) * 0.032, 0.085), (*foot, 0.015), 0.015, iron),
                  M.sphere(0.021, (*foot, 0.015), iron, (1, 1, 0.6))]
    parts += [M.cylinder(0.027, h, h + 0.055, A.E.glass("#ffd9a0", 0.25), bevel=0.004),
              M.sphere(0.011, (0, 0, h + 0.037), M.emission("#ffb24d", 28), (1, 1, 1.5))]
    return parts


def reshape_meshes(objects, scale_x, scale_y, z_map):
    """Bake bevels, then reshape source 3D geometry before rendering, never PNGs."""
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    for obj in objects:
        evaluated = obj.evaluated_get(depsgraph)
        mesh = bpy.data.meshes.new_from_object(evaluated, preserve_all_data_layers=True, depsgraph=depsgraph)
        matrix = obj.matrix_world.copy()
        for vertex in mesh.vertices:
            point = matrix @ vertex.co
            vertex.co = (point.x * scale_x, point.y * scale_y, z_map(point.z))
        old_mesh = obj.data
        obj.modifiers.clear()
        obj.data = mesh
        obj.matrix_world = Matrix.Identity(4)
        mesh.update()
        if old_mesh.users == 0:
            bpy.data.meshes.remove(old_mesh)
    bpy.context.view_layer.update()


def build_chair(item):
    if item == "chair_wood":
        return chair_wood()
    parts, back = S.CHAIRS[item]()
    parts, back = list(M._flatten(parts)), list(M._flatten(back))
    width, original, back_top = chair_profile(item)
    def height(z):
        if z <= A.SEAT_TOP:
            return z * SEAT_TOP / A.SEAT_TOP
        return SEAT_TOP + (z - A.SEAT_TOP) * (back_top - SEAT_TOP) / (A.BACK_TOP - A.SEAT_TOP)
    reshape_meshes(parts + back, width / original, width / original, height)
    return parts, back


def build_table(item):
    if item == "table_round":
        return table_round()
    old_top = LEGACY_TABLE_TOP_WORLD[item] / LEGACY_TABLE_TOP_WORLD["table_round"] * LEGACY_TABLE_TOP_Z
    width, depth, top = table_profile(item)
    objects = list(M._flatten(S.TABLES[item](old_top)))
    old_width = 1.94 if item == "table_long" else 0.94
    def height(z):
        if z < old_top - 0.085:
            return z * (top - 0.055) / (old_top - 0.085)
        if z <= old_top:
            return top + (z - old_top) * 0.055 / 0.085
        return top + (z - old_top) * 0.80
    reshape_meshes(objects, width / old_width, depth / 0.94, height)
    return objects


def bounds(objects):
    bpy.context.view_layer.update()
    points = [obj.matrix_world @ vertex.co for obj in objects for vertex in obj.data.vertices]
    return {"min": [round(min(p[axis] for p in points), 6) for axis in range(3)],
            "max": [round(max(p[axis] for p in points), 6) for axis in range(3)]}


def setup(args, footprint, rotation, shadow=True):
    fx, fy = footprint if rotation % 2 == 0 else footprint[::-1]
    # A mesa longa ocupa mais largura de tela nas duas rotações isométricas.
    image_size = (int((1040 if max(fx, fy) > 1 else 640) * args.density / 4), int(720 * args.density / 4))
    C.setup(args.samples, image_size, shadow_center=(fx / 2, -fy / 2),
            shadow_size=(fx + 0.2, fy + 0.2) if shadow else 0.001, rig="a")


def shoot(name, objects, footprint, rotation, out, patch, physical):
    geometry = bounds(objects)
    anchor, center = M.assemble(objects, footprint, rotation)
    C.aim_camera((center[0], center[1], 0.30))
    patch["sprites"][name] = {"anchor": C.shoot(name, anchor, str(out / "raw")), "density": C.DENSITY}
    physical.setdefault("rendered_geometry", {})[name] = geometry
    write_json(out / "manifest_patch.json", patch)
    write_json(out / "physical_contract.json", physical)
    print("SPRITE_READY", name, flush=True)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("items", nargs="*")
    parser.add_argument("--out", default="build/visual-reformulacao/moveis")
    parser.add_argument("--samples", type=int, default=48)
    parser.add_argument("--density", type=float, default=4.0)
    parser.add_argument("--proof", action="store_true", help="Cadeiras r1/r3, com encosto r1; primeira rotação das mesas")
    parser.add_argument("--geometry-only", action="store_true", help="Verifica as malhas e exporta o contrato, sem renderizar")
    args = parser.parse_args(argv)
    if args.samples < 1 or not 1 <= args.density <= 8:
        parser.error("samples >= 1 e density entre 1 e 8")
    out = (ROOT / args.out).resolve()
    build_root = (ROOT / "build").resolve()
    if out == build_root or build_root not in out.parents:
        parser.error("A saída precisa ser uma subpasta de build; instalação não é permitida")
    items = args.items or (DEFAULT_PROOF if args.proof else list(CHAIRS) + list(TABLES))
    unknown = set(items) - set(CHAIRS) - set(TABLES)
    if unknown:
        parser.error("Itens desconhecidos: " + ", ".join(sorted(unknown)))
    manifest = json.loads((ROOT / "art/sprites/sprites.json").read_text(encoding="utf-8"))
    C.SPRITES = str(out / "sprites")
    Path(C.SPRITES).mkdir(parents=True, exist_ok=True)
    C.DENSITY = args.density
    C.PX_PER_UNIT = 128 / math.sqrt(2) * args.density
    physical = contract(items, args.density, args.samples)
    patch = {"sprites": {}, "table_tops": {item: round(table_profile(item)[2] * Z_WORLD, 6) for item in items if item in TABLES}}
    write_json(out / "physical_contract.json", physical)
    write_json(out / "manifest_patch.json", patch)
    if args.geometry_only:
        for item in items:
            footprint = (2, 1) if item == "table_long" else (1, 1)
            setup(args, footprint, 0)
            if item in CHAIRS:
                parts, back = build_chair(item)
                objects = parts + back
            else:
                objects = build_table(item)
            box = bounds(objects)
            if not all(math.isfinite(v) for point in box.values() for v in point):
                raise ValueError("Coordenada inválida: " + item)
            physical["items"][item]["geometry_bounds"] = box
            print("GEOMETRY_READY", item, box, flush=True)
        write_json(out / "physical_contract.json", physical)
        return
    for item in items:
        rotations = sorted({int(name.rsplit("_r", 1)[1]) for name in manifest["furniture"][item].values()})
        if args.proof:
            rotations = [r for r in rotations if r in (1, 3)] if item in CHAIRS else rotations[:1]
        footprint = (2, 1) if item == "table_long" else (1, 1)
        for rotation in rotations:
            setup(args, footprint, rotation)
            if item in CHAIRS:
                parts, back = build_chair(item)
                objects = parts + back
            else:
                objects = build_table(item)
            shoot(f"{item}_r{rotation}", objects, footprint, rotation, out, patch, physical)
            back_name = manifest.get("chair_backrests", {}).get(item, {}).get(str(rotation), "")
            if back_name:
                setup(args, footprint, rotation, shadow=False)
                parts, back = build_chair(item)
                for obj in parts:
                    bpy.data.objects.remove(obj, do_unlink=True)
                shoot(back_name, back, footprint, rotation, out, patch, physical)
        print("ITEM_READY", item, flush=True)
    print("STAGING_COMPLETE", out, len(patch["sprites"]), flush=True)


if __name__ == "__main__":
    main(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
