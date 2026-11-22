"""DT-106: pisos, revestimentos e janelas; geometria nativa, somente staging.

Blender -b -t 3 -P tools/render3d/superficies_codex.py -- --proof
Sem --proof renderiza 39 pisos (75 variações), 16 paredes, 15 janelas e 2 pilares.
O patch altera somente anchor/density dos IDs existentes; não instala imagens.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cena3d as C
import moveis3d as M
import amostra_a3d as A
import superficies3d as S
import superficies_a3d as B

ROOT = Path(__file__).resolve().parents[2]
WINDOW_IDS = ("janela", "janela_redonda", "janela_diner", "janela_neon", "janela_groovy", "janela_arcade",
              "janela_shoji", "janela_country", "janela_festa", "janela_industrial", "janelao",
              "janelao_italiano", "janelao_mexicano", "janelao_brasileiro", "janelao_frances")
PROOF = ("floor_beige", "floor_wood", "wall_cream", "wall_brick", "janela", "floor_japanese", "floor_hinoki",
         "wall_japanese", "janela_shoji", "floor_brazil", "floor_hydraulic", "wall_brazil", "janelao_brasileiro",
         "floor_french", "wall_french", "janelao_frances", "pilaster")
WALL_Z = S.WALL_Z
WIDTH = 1.0 + 2.0 * S.BLEED
ORIGINAL_PAINTED = B.painted
ORIGINAL_TRIM = B.trim


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.replace(path)


def soften_periodic(values):
    """Retira ruído de um pixel preservando período e desenho nas bordas."""
    return (values * 4 + np.roll(values, 1, 0) + np.roll(values, -1, 0)
            + np.roll(values, 1, 1) + np.roll(values, -1, 1)) / 8.0


def painted(key, build, plane="XY", rough=0.5, coat=0.0, bump=0.4, metal=0.0, distance=0.012, emit=0.0, specular=None):
    def texture():
        values = list(build())
        # Preserva motivos culturais; reduz variação superficial e brilho que competiam com personagens.
        color = soften_periodic(values[0])
        mean = color.mean(axis=(0, 1), keepdims=True)
        values[0] = np.clip(mean + (color - mean) * (0.92 if plane != "XY" else 0.86), 0, 1)
        values[1] = soften_periodic(values[1])
        if len(values) > 2 and values[2] is not None:
            values[2] = np.clip(values[2] * 0.65 + 0.22, 0.36, 0.86)
        return tuple(values)
    return ORIGINAL_PAINTED("codex_" + plane + "_" + str(key), texture, plane=plane, rough=max(rough, 0.36),
                            coat=min(coat, 0.28), bump=bump * 0.50, metal=metal,
                            distance=min(distance, 0.012), emit=min(emit, 1.8),
                            specular=min(specular, 0.4) if specular is not None else 0.30)


def wood(color="#79563b"):
    return A.grain_wood(color, 0.18)


def trim(parts, beam=None, base="#463125", beam_h=0.14, base_h=0.11):
    # Perfis mais finos; o topo continua na mesma altura contratual.
    return ORIGINAL_TRIM(parts, beam or wood("#493427"), base, min(beam_h, 0.085), min(base_h, 0.075))


def tatami_texture(turned):
    """Palha clara e borda de tecido fina, no mesmo padrão alternado do catálogo."""
    u, v = B.coords()
    across, along = (u, v) if turned else (v, u)
    weave = np.sin(across * 2.0 * math.pi * 52) * 0.5 + 0.5
    field = B.blend(np.broadcast_to(B.rgb("#bcb183"), weave.shape + (3,)), B.rgb("#d0c397"), weave * 0.30)
    field = B.stained(field, 42, 0.018)
    edge = np.minimum(across, 1.0 - across)
    ribbon = 1.0 - B.smooth(0.016, 0.021, edge)
    color = B.blend(field, B.rgb("#52624a"), ribbon)
    return color, weave * 0.18 * (1.0-ribbon), np.full(weave.shape, 0.74, dtype=np.float32)

def brazil_texture(seed=37):
    """Calçada portuguesa: ondas reconhecíveis e pedra miúda sem ruído de alto contraste."""
    stones = B.voronoi(48, seed, 0.7)
    wave = np.sin(stones['cx'] * 2.0 * math.pi * 2.0) * 0.1
    dark = (stones['cy'] * 2.0 + wave * 2.0) % 1.0 > 0.5
    color = np.where(dark[..., None], B.rgb('#494a44'), B.rgb('#d8d0bc')).astype(np.float32)
    color = B.tone(color, stones['id'], seed + 1, 0.025, stones['count'])
    mask = B.smooth(0.0007, 0.0018, stones['edge'])
    color = color * (0.96 + 0.04 * mask[..., None])
    return color, mask * 0.12, np.full(mask.shape, 0.78, dtype=np.float32)

def floor_material(item, variant):
    if item == "floor_beige":
        base = ("#e0d1b5", "#d6c5a8")[variant]
        return painted(f"base{variant}", lambda: B.tile_tex(1, base, base, "#aa977a", 220, joint=0.004,
                                                           amount=0.018, stain=0.025), rough=0.64, bump=0.15)
    if item == "floor_wood":
        return painted(f"wood{variant}", lambda: B.planks_tex("#9a704a", 4, 130, variant, gap="#5e4430",
                                                             amount=0.055, grain=0.13, knots=1), rough=0.48, coat=0.20)
    if item == "floor_japanese":
        return painted(f"tatami{variant}", lambda: tatami_texture(variant == 1), rough=0.74, bump=0.16)
    if item == "floor_brazil":
        return painted("brazil", brazil_texture, rough=0.72, bump=0.20, distance=0.004)
    if item == "floor_french":
        return painted("french", lambda: B.herringbone_tex("#ac8057", "#82603e", "#5d4634", k=3),
                       rough=0.48, coat=0.22)
    if item == "floor_hinoki":
        return painted(f"hinoki{variant}", lambda: B.planks_tex("#d7bc8e", 4, 170, variant, gap="#9c835f",
                                                               amount=0.025, grain=0.10), rough=0.56)
    return B.FLOORS[item](variant)


def wall_cream():
    z = S.WAINSCOT_TOP
    plaster = B.painted_wall("cream", lambda: B.plaster_tex("#eaddc1", 305, 0.035), bump=0.10)
    lower, inset = wood("#78553a"), wood("#92704f")
    return trim([B.upper(plaster), *B.wainscot(lower, inset, wood("#64472f"), z, rail_h=0.026)], base="#4f3929")


def wall_brick():
    brick = B.painted_wall("brick", lambda: B.subway_tex("#a46048", "#7d6550", 17, per_cell=3,
                                                        joint=0.004, amount=0.07), bump=0.60, distance=0.010)
    return trim([B.upper(brick)], base="#584034")


def pilaster():
    dark, metal = wood("#49372b"), A.cast_iron("#40382e")
    return [M.box((0.070, 0.068, WALL_Z), (0.0, -0.025, WALL_Z / 2), dark, 0.007),
            M.box((0.094, 0.088, 0.080), (0.0, -0.025, 0.040), metal, 0.006),
            M.box((0.094, 0.088, 0.055), (0.0, -0.025, WALL_Z - 0.0275), metal, 0.005)]


def glass():
    """Vidro opaco ilustrado: azul suave e reflexo diagonal, legível nas duas paredes.

    Não é um buraco para a cidade: a janela permanece um sprite sobre o painel.
    O preenchimento do vidro não gera halo; luz no piso e tintura da noite permanecem no runtime.
    """
    key = ("codex_window_glass",)
    if key in M._materials:
        return M._materials[key]
    mat, nodes, links, bsdf = M._principled("Vidro_Codex")
    coord = nodes.new("ShaderNodeTexCoord")
    sep = nodes.new("ShaderNodeSeparateXYZ")
    links.new(coord.outputs["Object"], sep.inputs["Vector"])
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.225
    ramp.color_ramp.elements[0].color = C.linear("#83a6b3")
    ramp.color_ramp.elements[1].position = 0.86
    ramp.color_ramp.elements[1].color = C.linear("#bad5df")
    normalized = nodes.new("ShaderNodeMath"); normalized.operation = "MULTIPLY"; normalized.inputs[1].default_value = 0.5
    links.new(sep.outputs["Z"], normalized.inputs[0]); links.new(normalized.outputs[0], ramp.inputs["Fac"])
    # Reflexo levemente diagonal, calculado no plano, sem textura raster externa.
    slope = nodes.new("ShaderNodeMath"); slope.operation = "MULTIPLY"; slope.inputs[1].default_value = 0.45
    links.new(sep.outputs["X"], slope.inputs[0])
    add = nodes.new("ShaderNodeMath"); add.operation = "ADD"
    links.new(sep.outputs["Z"], add.inputs[0]); links.new(slope.outputs[0], add.inputs[1])
    reflection = nodes.new("ShaderNodeValToRGB")
    reflection.color_ramp.elements[0].position = 0.575
    reflection.color_ramp.elements[0].color = (0, 0, 0, 1)
    reflection.color_ramp.elements[1].position = 0.615
    reflection.color_ramp.elements[1].color = (0.46, 0.46, 0.46, 1)
    reflection.color_ramp.elements.new(0.655).color = (0, 0, 0, 1)
    half = nodes.new("ShaderNodeMath"); half.operation = "MULTIPLY"; half.inputs[1].default_value = 0.5
    links.new(add.outputs[0], half.inputs[0]); links.new(half.outputs[0], reflection.inputs["Fac"])
    mix = nodes.new("ShaderNodeMixRGB"); mix.blend_type = "MIX"
    links.new(reflection.outputs["Color"], mix.inputs[0]); links.new(ramp.outputs["Color"], mix.inputs[1])
    mix.inputs[2].default_value = C.linear("#eef0d9")
    links.new(mix.outputs[0], bsdf.inputs["Base Color"])
    links.new(mix.outputs[0], bsdf.inputs["Emission Color"])
    bsdf.inputs["Emission Strength"].default_value = 0.28
    bsdf.inputs["Roughness"].default_value = 0.27
    bsdf.inputs["Coat Weight"].default_value = 0.20
    bsdf.inputs["Specular IOR Level"].default_value = 0.28
    M._materials[key] = mat
    return mat


def square_frame(x0, x1, z0, z1, frame, sill, pane=None, nx=1, nz=1, thick=0.05, muntin=0.03):
    w, h = x1 - x0, z1 - z0
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    frame_width = min(thick, 0.038)
    parts = [B.face_panel(x0, x1, z0, z1, -0.012, pane or glass()),
             M.box((w + 0.085, 0.064, 0.040), (cx, -0.033, z1 + 0.015), frame, 0.006),
             M.box((w + 0.12, 0.115, 0.038), (cx, -0.060, z0 - 0.016), sill, 0.008),
             M.box((w, 0.045, 0.024), (cx, -0.025, z0), frame, 0.003)]
    for x in (x0, x1):
        parts.append(M.box((frame_width, 0.060, h + 0.025), (x, -0.030, cz), frame, 0.005))
    for i in range(1, nx):
        parts.append(M.box((min(muntin, 0.021), 0.038, h), (x0 + w * i / nx, -0.024, cz), frame, 0.003))
    for i in range(1, nz):
        parts.append(M.box((w, 0.038, min(muntin, 0.021)), (cx, -0.024, z0 + h * i / nz), frame, 0.003))
    return parts


def round_window(frame, inner, pane, lattice=None, cross=True, rivets=None):
    cx, cz = S.at(21, -68)
    r = 13 / S.DESIGN_W
    parts = [B.ring(cx, cz, r + 0.043, r - 0.008, 0.0, -0.064, frame, bevel=0.008),
             B.ring(cx, cz, r + 0.002, r - 0.020, -0.014, -0.055, inner, bevel=0.003),
             B.disc(cx, cz, r, -0.012, pane)]
    if lattice is not None:
        for i in range(-2, 3):
            offset = i * r / 2.7
            half = math.sqrt(r * r - offset * offset)
            parts += [B.bar(cx + offset, cz - half, cx + offset, cz + half, -0.030, 0.011, 0.019, lattice),
                      B.bar(cx - half, cz + offset, cx + half, cz + offset, -0.030, 0.011, 0.019, lattice)]
    elif cross:
        parts += [B.bar(cx, cz - r, cx, cz + r, -0.030, 0.018, 0.027, inner),
                  B.bar(cx - r, cz, cx + r, cz, -0.030, 0.018, 0.027, inner)]
    if rivets is not None:
        for i in range(8):
            angle = 2 * math.pi * i / 8
            parts.append(M.sphere(0.008, (cx + math.cos(angle) * (r + 0.021), -0.067,
                                         cz + math.sin(angle) * (r + 0.021)), rivets))
    return parts


def arched_window(frame, sill, flowers=None, box_mat=None, shutters=None, balcony=None, tile_sill=False):
    x0, z0 = S.at(9, -30)
    x1, spring = S.at(33, -70)
    w, cx, radius = x1 - x0, (x0 + x1) / 2, (x1 - x0) / 2
    pane = glass()
    parts = [B.face_panel(x0, x1, z0, spring, -0.010, pane),
             B.disc(cx, spring, radius, -0.007, pane, 0, 180),
             B.ring(cx, spring, radius + 0.022, radius - 0.016, 0.0, -0.062, frame, 0, 180, bevel=0.005),
             M.box((0.021, 0.038, spring - z0 + radius), (cx, -0.025, (z0 + spring + radius) / 2), frame, 0.003),
             M.box((w, 0.038, 0.022), (cx, -0.025, spring), frame, 0.003),
             M.box((w, 0.038, 0.020), (cx, -0.025, (z0 + spring) / 2), frame, 0.003),
             M.box((w + 0.12, 0.12, 0.040), (cx, -0.060, z0 - 0.018), sill, 0.008)]
    for x in (x0, x1):
        parts.append(M.box((0.038, 0.062, spring - z0 + 0.020), (x, -0.030, (z0 + spring) / 2), frame, 0.005))
    if tile_sill:
        for i, color in enumerate(("#285b88", "#eee4ce", "#be944f") * 3):
            parts.append(M.box((0.069, 0.012, 0.034), (cx - 0.28 + i * 0.07, -0.122, z0 - 0.018),
                               M.solid(color, 0.42), 0.002))
    if shutters:
        for x in (x0 - 0.093, x1 + 0.093):
            parts += B.shutter(x, z0, spring + 0.025, 0.118, *shutters)
    if flowers:
        parts += B.flower_box(cx, w + 0.055, z0, box_mat or wood("#79604a"), flowers,
                              y=-0.09, leaf_color="#4f7045")
    if balcony:
        rail = z0 + 0.19
        parts += [M.tube((x0 - 0.045, -0.135, rail), (x1 + 0.045, -0.135, rail), 0.009, balcony),
                  M.box((w + 0.12, 0.15, 0.025), (cx, -0.075, z0 - 0.043), balcony, 0.005)]
        for i in range(7):
            x = x0 - 0.035 + i * (w + 0.07) / 6
            parts.append(M.tube((x, -0.135, z0 - 0.033), (x, -0.135, rail), 0.0045, balcony))
    return parts


def classic_window():
    x0, x1, z0, z1 = B.window_box_area()
    frame = wood("#65503c")
    parts = square_frame(x0, x1, z0, z1, frame, wood("#8c6a46"), nx=2, nz=2)
    brass = M.solid("#b99b61", 0.44, 0.45)
    parts += [M.box((0.028, 0.022, 0.065), (0.52, -0.054, z0 + 0.30), brass, 0.006)]
    return parts


def configure_builders():
    # Somente atribuições no processo Blender; fontes compartilhadas permanecem intactas.
    B.painted, B.trim = painted, trim
    B.rich_wood = lambda color, scale=6.0, gloss=0.55: A.grain_wood(color, min(gloss, 0.22))
    B.window_glass, B.square_frame = glass, square_frame
    B.round_window, B.arched_window = round_window, arched_window


def setup(args, floor=False):
    scale = args.density / 2.0
    size = (int(300 * scale), int((220 if floor else 480) * scale))
    C.setup(args.samples, size, shadow_size=0.001, tiling=True, sun=S.FLOOR_SUN if floor else 3.4, rig="a")
    bpy.context.scene.render.threads_mode = "FIXED"
    bpy.context.scene.render.threads = args.threads


def render_item(item, args, manifest, out, patch, physical):
    if item in manifest["floors"]:
        names = manifest["floors"][item]["sprites"]
        for variant, name in enumerate(names):
            if args.proof and variant > (1 if manifest["floors"][item]["mode"] == "xadrez" else 0):
                break
            setup(args, floor=True)
            B.floor_panel(floor_material(item, variant))
            C.aim_camera((0.5, -0.5, 0.0))
            patch["sprites"][name] = {"anchor": C.shoot(name, (0, 0, 0), str(out / "raw")), "density": args.density}
    else:
        for side in ("R", "L"):
            setup(args)
            if item in manifest["walls"]:
                name = manifest["walls"][item][side]
                build = wall_cream if item == "wall_cream" else wall_brick if item == "wall_brick" else B.WALLS[item]
            elif item == "pilaster":
                name, build = manifest["wall_pilaster"][side], pilaster
            else:
                name = f"enfeite_{item}_{side}"
                build = classic_window if item == "janela" else B.WALL_ITEMS[item]
            objects = list(M._flatten(build()))
            if item in WINDOW_IDS:
                objects.append(S.wall_shadow_catcher(side))
            S.place_wall(objects, side)
            center = (0.5, 0) if side == "R" else (0, -0.5)
            C.aim_camera((*center, WALL_Z / 2))
            anchor = (0, 0, 0) if side == "R" else (0, -1, 0)
            patch["sprites"][name] = {"anchor": C.shoot(name, anchor, str(out / "raw")), "density": args.density}
    write_json(out / "manifest_patch.json", patch)
    physical["rendered_items"].append(item)
    write_json(out / "physical_contract.json", physical)
    print("ITEM_READY", item, len(patch["sprites"]), flush=True)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("items", nargs="*")
    parser.add_argument("--out", default="build/visual-cenario/superficies")
    parser.add_argument("--samples", type=int, default=40)
    parser.add_argument("--density", type=float, default=4.0)
    parser.add_argument("--threads", type=int, default=3)
    parser.add_argument("--proof", action="store_true")
    args = parser.parse_args(argv)
    if args.samples < 1 or not 1 <= args.density <= 8 or not 1 <= args.threads <= 4:
        parser.error("samples >= 1, density 1..8 e threads 1..4")
    out = (ROOT / args.out).resolve()
    build_root = (ROOT / "build").resolve()
    if out == build_root or build_root not in out.parents:
        parser.error("Saída deve ser uma subpasta de build; instalação não é permitida")
    manifest_path = ROOT / "art/sprites/sprites.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    all_items = list(manifest["floors"]) + list(manifest["walls"]) + list(WINDOW_IDS) + ["pilaster"]
    items = args.items or (list(PROOF) if args.proof else all_items)
    if set(items) - set(all_items):
        parser.error("IDs desconhecidos: " + ", ".join(sorted(set(items) - set(all_items))))
    C.SPRITES = str(out / "sprites")
    Path(C.SPRITES).mkdir(parents=True, exist_ok=True)
    C.DENSITY, C.PX_PER_UNIT = args.density, 128 / math.sqrt(2) * args.density
    configure_builders()
    patch = {"sprites": {}}
    physical = {"schema": 1, "density": args.density, "tile_world": [128, 64], "wall_height_world": 152.38,
                "bleed_units": S.BLEED, "floor_anchor": "top tile vertex; geometry origin (0,0,0)",
                "wall_anchor": "bottom-left endpoint of existing segment; R along x, L along y",
                "wall_span_units": 1, "window_light": "unchanged runtime lets_light_in / day-night",
                "render": {"samples": args.samples, "threads": args.threads, "rig": "a", "proof": args.proof},
                "source_manifest_sha256": hashlib.sha256(manifest_path.read_bytes()).hexdigest(),
                "source_generator_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                "modules_sha256": {Path(module.__file__).name: hashlib.sha256(Path(module.__file__).read_bytes()).hexdigest()
                                   for module in (C, M, A, S, B)},
                "requested_items": items, "rendered_items": [], "changes": "only existing sprite anchor/density; no data or logic"}
    write_json(out / "manifest_patch.json", patch)
    write_json(out / "physical_contract.json", physical)
    for item in items:
        render_item(item, args, manifest, out, patch, physical)
    allowed = set(manifest["sprites"])
    if set(patch["sprites"]) - allowed:
        raise ValueError("Patch tentou criar um ID de sprite")
    print("STAGING_COMPLETE", out, len(patch["sprites"]), flush=True)


if __name__ == "__main__":
    main(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
