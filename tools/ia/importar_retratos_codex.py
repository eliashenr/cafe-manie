"""Recorta/registra retratos RGBA gerados; não pinta, mascara ou instala assets.

python tools/ia/importar_retratos_codex.py [art/portraits/calibracao.json]
    --out build/visual-reformulacao/retratos [--analyze]

As camadas usam a caixa UI 140x170, origem (70,110), densidade4. Cada entrada
declara um ponto na célula e seu destino na caixa, mais escala uniforme. Roupas
podem ter enquadramento retangular explícito; nenhuma máscara é criada. As
cabeças de todas as peles compartilham a mesma escala e registro por cabelo.
O ícone é composição das mesmas três camadas usadas por AvatarPortrait.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
DENSITY = 4
BOX = (140, 170)
ANCHOR = (70, 110)
SKINS = ("clara", "morena_clara", "parda", "negra")
HAIRS = ("curto_castanho", "rabo_preto", "chanel_ruivo", "coque_loiro", "topete_azul", "longo_rosa")
OUTFITS = ("branca", "azul", "vermelha", "rosa", "preta", "dourada")
HATS = ("toque", "toque_alto", "bandana", "boina", "coroa")
PEOPLE = ("vizinho_ana", "vizinho_beto", "vizinho_caio", "vizinho_duda", "vizinho_lia", "vizinho_rafa", "vizinho_vo_cida", "retrato_bruxa", "retrato_papai_noel")
EXPECTED = ({f"avatar_cabeca_{skin}_{hair}" for skin in SKINS for hair in HAIRS}
            | {f"avatar_roupa_{name}" for name in OUTFITS}
            | {f"avatar_chapeu_{name}" for name in HATS} | set(PEOPLE))


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def default_config():
    neck_x = (134, 149, 135, 135, 135, 152)
    heads = [{"name": f"avatar_cabeca_{skin}_{hair}", "cell": row * 6 + col,
              "point_px": [neck_x[col], 244], "target_ui": [70, 127], "scale_ui": 0.31}
             for row, skin in enumerate(SKINS) for col, hair in enumerate(HAIRS)]
    clothes = [{"name": f"avatar_roupa_{name}", "cell": i, "point_px": [185 if i == 0 else 181, 144],
                "target_ui": [70, 120], "scale_ui": 0.34, "clip_ui": [0, 0, 140, 169]}
               for i, name in enumerate(OUTFITS)]
    hat_data = [("toque", 6, [187, 320], 0.29, [70, 79]),
                ("toque_alto", 7, [181, 323], 0.25, [70, 82]),
                ("bandana", 8, [174, 245], 0.29, [78, 76]),
                ("boina", 9, [190, 269], 0.29, [70, 80]),
                ("coroa", 10, [181, 262], 0.27, [70, 78])]
    hats = [{"name": f"avatar_chapeu_{name}", "cell": cell, "point_px": point,
             "target_ui": target, "scale_ui": scale} for name, cell, point, scale, target in hat_data]
    neighbors = [{"name": name, "cell": i, "fit_px": [384, 384]} for i, name in enumerate(PEOPLE)]
    return {"version": 1, "atlases": [
        {"file": "cabecas.png", "grid": [6, 4], "entries": heads},
        {"file": "camadas.png", "grid": [3, 4], "entries": clothes + hats},
        {"file": "vizinhos_limpos.png", "grid": [3, 3], "entries": neighbors}],
        "default_avatar": {"skin": "clara", "hair": "curto_castanho", "outfit": "branca", "hat": "toque"}}


def finite_pair(value, name):
    if not isinstance(value, (tuple, list)) or len(value) != 2 or not all(math.isfinite(float(v)) for v in value):
        raise ValueError(f"{name}: esperado par finito")
    return tuple(float(v) for v in value)


def rectangles(size, grid):
    cols, rows = map(int, grid)
    if cols < 1 or rows < 1:
        raise ValueError("Grade inválida")
    xs = [round(i * size[0] / cols) for i in range(cols + 1)]
    ys = [round(i * size[1] / rows) for i in range(rows + 1)]
    return [(xs[x], ys[y], xs[x + 1], ys[y + 1]) for y in range(rows) for x in range(cols)]


def alpha_report(image):
    alpha = np.asarray(image.getchannel("A"))
    boxes = {}
    for threshold in (0, 8, 128):
        ys, xs = np.where(alpha > threshold)
        boxes[str(threshold)] = [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1] if len(xs) else None
    return {"bbox_above_alpha": boxes, "alpha_min": int(alpha.min()), "alpha_max": int(alpha.max()),
            "zero_fraction": float((alpha == 0).mean()), "low_alpha_fraction": float(((alpha > 0) & (alpha < 128)).mean())}


def registered_layer(cell, spec):
    """Ponto-fonte é mantido após resize/crop; alfa só muda pela reamostragem."""
    point = finite_pair(spec["point_px"], "point_px")
    target = finite_pair(spec["target_ui"], "target_ui")
    scale = float(spec["scale_ui"]) * DENSITY
    if not math.isfinite(scale) or scale <= 0:
        raise ValueError("scale_ui inválida")
    size = (max(1, round(cell.width * scale)), max(1, round(cell.height * scale)))
    resized = cell.resize(size, Image.Resampling.LANCZOS)
    sx, sy = size[0] / cell.width, size[1] / cell.height
    # Offset is the canvas coordinate of the original cell's top-left corner.
    offset = [target[0] * DENSITY - point[0] * sx, target[1] * DENSITY - point[1] * sy]
    crop = resized.getchannel("A").getbbox()
    if crop is None:
        raise ValueError("Camada vazia")
    if "clip_ui" in spec:
        clip = spec["clip_ui"]
        if len(clip) != 4 or clip[2] <= clip[0] or clip[3] <= clip[1]:
            raise ValueError("clip_ui: use [x0,y0,x1,y1]")
        crop = (max(crop[0], math.ceil(clip[0] * DENSITY - offset[0])),
                max(crop[1], math.ceil(clip[1] * DENSITY - offset[1])),
                min(crop[2], math.floor(clip[2] * DENSITY - offset[0])),
                min(crop[3], math.floor(clip[3] * DENSITY - offset[1])))
    if crop[2] <= crop[0] or crop[3] <= crop[1]:
        raise ValueError("Recorte não contém arte")
    image = resized.crop(crop)
    anchor = [ANCHOR[0] * DENSITY - offset[0] - crop[0], ANCHOR[1] * DENSITY - offset[1] - crop[1]]
    return image, {"anchor": [round(v, 4) for v in anchor], "density": DENSITY}, {"scale_px": [sx, sy], "crop_px": list(crop), "cell_offset_canvas_px": offset}


def fitted_portrait(cell, spec):
    bbox = cell.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("Retrato vazio")
    cropped = cell.crop(bbox)
    size = finite_pair(spec["fit_px"], "fit_px")
    factor = min(size[0] / cropped.width, size[1] / cropped.height)
    image = cropped.resize((round(cropped.width * factor), round(cropped.height * factor)), Image.Resampling.LANCZOS)
    return image, {"anchor": [image.width / 2, image.height / 2], "density": DENSITY}, {"source_crop_px": list(bbox), "scale_px": [image.width / cropped.width, image.height / cropped.height]}


def import_atlases(config, config_dir):
    frames = {}
    for atlas in config["atlases"]:
        source = (config_dir / atlas["file"]).resolve()
        raw = source.read_bytes()
        sheet = Image.open(source).convert("RGBA")
        rects = rectangles(sheet.size, atlas["grid"])
        digest = hashlib.sha256(raw).hexdigest()
        for spec in atlas["entries"]:
            name = spec["name"]
            if name not in EXPECTED or name in frames:
                raise ValueError(f"Nome desconhecido/duplicado: {name}")
            index = spec["cell"]
            if not isinstance(index, int) or not 0 <= index < len(rects):
                raise ValueError("Índice da célula inválido")
            rect = rects[index]
            cell = sheet.crop(rect)
            image, entry, transform = fitted_portrait(cell, spec) if "fit_px" in spec else registered_layer(cell, spec)
            frames[name] = {"image": image, "entry": entry,
                            "source": {"file": atlas["file"], "sha256": digest, "cell": index, "rect_px": list(rect),
                                       "calibration": spec, "alpha": alpha_report(cell), **transform}}
    return frames


def layer_names(avatar):
    result = ["avatar_roupa_" + avatar["outfit"], f"avatar_cabeca_{avatar['skin']}_{avatar['hair']}"]
    if avatar.get("hat"):
        result.append("avatar_chapeu_" + avatar["hat"])
    return result


def compose(frames, avatar):
    image = Image.new("RGBA", (BOX[0] * DENSITY, BOX[1] * DENSITY))
    for name in layer_names(avatar):
        frame = frames[name]
        ax, ay = frame["entry"]["anchor"]
        image.alpha_composite(frame["image"], (round(ANCHOR[0] * DENSITY - ax), round(ANCHOR[1] * DENSITY - ay)))
    return image


def add_icon(frames, avatar):
    image = compose(frames, avatar)
    bbox = image.getchannel("A").getbbox()
    image = image.crop(bbox)
    factor = 320 / max(image.size)
    image = image.resize((round(image.width * factor), round(image.height * factor)), Image.Resampling.LANCZOS)
    frames["icone_chef"] = {"image": image, "entry": {"anchor": [image.width / 2, image.height / 2], "density": DENSITY},
                            "source": {"composed_from": layer_names(avatar), "avatar": avatar, "canvas_crop_px": list(bbox)}}


def contact_sheets(frames, out):
    font = ImageFont.load_default()
    # All hair/hat combinations; rows also exercise every outfit and skin.
    sheet = Image.new("RGB", (1680, 2160), "#44382e")
    draw = ImageDraw.Draw(sheet)
    hats = (None,) + HATS
    for row, hat in enumerate(hats):
        for col, hair in enumerate(HAIRS):
            avatar = {"skin": SKINS[(row + col) % 4], "hair": hair, "outfit": OUTFITS[row], "hat": hat}
            tile = compose(frames, avatar).resize((280, 340), Image.Resampling.LANCZOS)
            sheet.paste(tile, (col * 280, row * 360 + 20), tile)
            draw.text((col * 280 + 8, row * 360 + 4), f"{hair} / {hat or 'sem chapeu'}", fill="#ead8b9", font=font)
    sheet.save(out / "combinacoes.png")
    neighbors = Image.new("RGB", (1152, 1200), "#44382e")
    draw = ImageDraw.Draw(neighbors)
    for i, name in enumerate(PEOPLE):
        image = frames[name]["image"]
        x, y = i % 3 * 384, i // 3 * 400
        neighbors.paste(image, (x + (384 - image.width) // 2, y + 16), image)
        draw.text((x + 8, y + 3), name, fill="#ead8b9", font=font)
    neighbors.save(out / "vizinhos_conferencia.png")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("config", nargs="?", default="art/portraits/calibracao.json")
    parser.add_argument("--out", default="build/visual-reformulacao/retratos")
    parser.add_argument("--analyze", action="store_true")
    parser.add_argument("--write-default-config", action="store_true")
    args = parser.parse_args()
    path = (ROOT / args.config).resolve()
    if args.write_default_config:
        if path.exists():
            parser.error("Não sobrescreve calibração existente")
        if (ROOT / "art/portraits").resolve() not in path.parents:
            parser.error("Configuração precisa ficar em art/portraits")
        write_json(path, default_config())
    config = json.loads(path.read_text(encoding="utf-8-sig"))
    frames = import_atlases(config, path.parent)
    if set(frames) != EXPECTED:
        raise ValueError(f"Retratos incompletos: {sorted(EXPECTED - set(frames))}")
    out = (ROOT / args.out).resolve()
    if (ROOT / "build").resolve() not in out.parents:
        parser.error("A saída precisa ser uma subpasta de build; sem instalação")
    out.mkdir(parents=True, exist_ok=True)
    if args.analyze:
        write_json(out / "analise.json", {name: frame["source"] for name, frame in frames.items()})
        print(out / "analise.json")
        return
    add_icon(frames, config["default_avatar"])
    (out / "sprites").mkdir(exist_ok=True)
    for name, frame in frames.items():
        frame["image"].save(out / "sprites" / (name + ".png"))
    write_json(out / "manifest_patch.json", {"sprites": {name: frame["entry"] for name, frame in frames.items()}})
    write_json(out / "proveniencia.json", {"config_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
               "box_ui": BOX, "anchor_ui": ANCHOR, "layers_order": ["outfit", "head", "hat"],
               "sprites": {name: frame["source"] for name, frame in frames.items()}})
    contact_sheets(frames, out)
    print(f"{len(frames)} retratos/camadas preparados em {out}; nenhum sprite instalado")


if __name__ == "__main__":
    main()
