"""Confere catálogo, recorte e encaixes; compara cozinha antiga/nova em escala real."""
import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--staging", default="build/visual-cenario/cozinha")
    parser.add_argument("--complete", action="store_true")
    args = parser.parse_args()
    staging = (ROOT / args.staging).resolve()
    if (ROOT / "build").resolve() not in staging.parents:
        parser.error("Saída de QA precisa estar dentro de build")
    old = json.loads((ROOT / "art/sprites/sprites.json").read_text(encoding="utf-8"))
    new = json.loads((staging / "manifest_patch.json").read_text())
    physical = json.loads((staging / "physical_contract.json").read_text())
    items = list(physical["items"])
    allowed = {name for item in items for name in old["furniture"][item].values()} | set(old["stove_glow"].values())
    if set(new) != {"sprites"} or not set(new["sprites"]) <= allowed:
        raise ValueError("Patch altera um contrato ou ID fora da cozinha")
    if args.complete and set(new["sprites"]) != allowed:
        raise ValueError("Faltam imagens: " + str(sorted(allowed - set(new["sprites"]))))
    for path, expected_hash in physical["source_sha256"].items():
        if hashlib.sha256((ROOT / path).read_bytes()).hexdigest() != expected_hash:
            raise ValueError("Fonte mudou após render: " + path)
    if "render_batches" in physical:
        batches = physical["render_batches"]
        assigned = [name for batch in batches for name in batch["sprites"]]
        if len(assigned) != len(set(assigned)) or set(assigned) != set(new["sprites"]):
            raise ValueError("Proveniência não cobre exatamente o lote consolidado")
        for batch in batches:
            snapshot = staging / batch["generator_snapshot"]
            if hashlib.sha256(snapshot.read_bytes()).hexdigest() != batch["generator_sha256"]:
                raise ValueError("Snapshot da fonte diverge da proveniência")
    if abs(physical["counter"]["top_world"] - old["counter_top"]) > 0.005:
        raise ValueError("Pilhas de pratos mudariam de altura")
    z = (1 / 96) * math.sqrt(2) / math.cos(math.radians(30))
    if abs(physical["stove"]["pot_support_z"] - (44 * z + 0.046)) > 1e-9:
        raise ValueError("Panelas perderiam o registro no fogão")
    checks = {}
    for name, entry in new["sprites"].items():
        if name.startswith("counter_") or name.startswith("delivery_counter_"):
            geo = physical["rendered_geometry"][name]
            # Puxadores/travessas precisam ficar contidos sob a projeção do
            # tampo: captura tubos que giraram a posição sem girar seu eixo.
            half_top = physical["counter"]["top_width"] / 2
            if any(abs(geo[side][axis]) > half_top + 0.0001 for side in ("min", "max") for axis in (0, 1)):
                raise ValueError("Peça do gabinete ultrapassa o tampo: " + name)
        raw_path = staging / "raw" / (name + ".png")
        with Image.open(raw_path) as raw:
            raw_alpha = raw.getchannel("A")
            raw_bbox = raw_alpha.point(lambda a: 255 if a > 22 else 0).getbbox()
            if not raw_bbox or raw_bbox[0] == 0 or raw_bbox[1] == 0 or raw_bbox[2] == raw.width or raw_bbox[3] == raw.height:
                raise ValueError("Render bruto vazio ou cortado: " + name)
        with Image.open(staging / "sprites" / (name + ".png")) as im:
            if im.mode != "RGBA":
                raise ValueError("Sem alfa nativo: " + name)
            alpha = im.getchannel("A")
            bbox = alpha.getbbox()
            if not bbox or bbox[0] == 0 or bbox[1] == 0 or bbox[2] == im.width or bbox[3] == im.height:
                raise ValueError("Imagem vazia ou recorte sem margem: " + name)
            native_bbox = raw_alpha.getbbox()
            offset = (native_bbox[0] - bbox[0], native_bbox[1] - bbox[1])
            native_crop = raw_alpha.crop((*offset, offset[0] + im.width, offset[1] + im.height))
            if ImageChops.difference(native_crop, alpha).getbbox() is not None:
                raise ValueError("Alfa foi alterado depois do render nativo: " + name)
            if entry["density"] != 4:
                raise ValueError("Densidade não é4: " + name)
            if not all(math.isfinite(n) for n in entry["anchor"]):
                raise ValueError("Âncora não finita: " + name)
            checks[name] = {"size": list(im.size), "alpha_bbox": bbox, "raw_significant_bbox": raw_bbox, "native_alpha_exact": True, "density": entry["density"],
                            "sha256": hashlib.sha256((staging / "sprites" / (name + ".png")).read_bytes()).hexdigest()}
    zoom, width, row_height = 2.7, 1120, 580
    try:
        font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 19)
    except OSError:
        font = ImageFont.load_default()
    def sprite(canvas, name, origin, candidate, factor=1):
        entry = new["sprites"].get(name) if candidate else None
        directory = staging / "sprites" if entry else ROOT / "art/sprites"
        entry = entry or old["sprites"][name]
        density = entry.get("density", old["density"])
        im = Image.open(directory / (name + ".png")).convert("RGBA")
        scale = zoom * factor / density
        im = im.resize((round(im.width * scale), round(im.height * scale)), Image.Resampling.LANCZOS)
        canvas.alpha_composite(im, (round(origin[0] - entry["anchor"][0] * scale), round(origin[1] - entry["anchor"][1] * scale)))
    for page, first in enumerate(range(0, len(items), 4), 1):
        batch = items[first:first + 4]
        canvas = Image.new("RGBA", (width, row_height * len(batch)), "#40342c")
        draw = ImageDraw.Draw(canvas)
        for row, item in enumerate(batch):
            name = old["furniture"][item]["0"]
            if name not in new["sprites"]:
                continue
            draw.text((20, row * row_height + 10), item, font=font, fill="#f3e9d5")
            for column in range(2):
                origin = (column * 560 + 280, row * row_height + row_height - 45)
                draw.text((column * 560 + 20, row * row_height + 38), "Prova3D" if column else "Anterior", font=font, fill="#c9b99c")
                sprite(canvas, name, origin, bool(column))
                if physical["items"][item]["kind"] == "stove":
                    sprite(canvas, old["cookware"]["lasagna"], origin, False)
                    sprite(canvas, old["stove_glow"]["0"], origin, bool(column))
                elif item.startswith("counter_"):
                    center = (origin[0], origin[1] - (32 + old["counter_top"]) * zoom)
                    for plate in range(3):
                        cy = center[1] + (1.3 - plate * 2.9) * zoom
                        draw.ellipse((center[0] - 20 * zoom, cy - 7.2 * zoom, center[0] + 20 * zoom, cy + 7.2 * zoom), fill="#f4ecdc", outline="#6e5c47", width=2)
                    sprite(canvas, old["food"]["coxinha"], (center[0], center[1] - 16.1 * zoom), False, 40 / old["food_width"])
                draw.line((origin[0] - 6, origin[1], origin[0] + 6, origin[1]), fill="#bcad8c")
            draw.line((10, (row + 1) * row_height - 2, width - 10, (row + 1) * row_height - 2), fill="#75604b")
        canvas.convert("RGB").save(staging / f"comparacao_cozinha_{page:02d}.png")
    # O mosaico sem comida expõe todas as faces, detalhes e sombras que a
    # comparação frontal com sobreposições pode esconder.
    zoom = 2.0
    for page, first in enumerate(range(0, len(items), 4), 1):
        batch = items[first:first + 4]
        canvas = Image.new("RGBA", (1120, 420 * len(batch)), "#ded0b6")
        draw = ImageDraw.Draw(canvas)
        for row, item in enumerate(batch):
            draw.text((12, row * 420 + 8), item, font=font, fill="#46372b")
            for rotation in range(4):
                name = old["furniture"][item][str(rotation)]
                if name in new["sprites"]:
                    sprite(canvas, name, (rotation * 280 + 140, row * 420 + 400), True)
                    draw.text((rotation * 280 + 12, row * 420 + 35), "r" + str(rotation), font=font, fill="#69513c")
        canvas.convert("RGB").save(staging / f"rotacoes_cozinha_{page:02d}.png")
    (staging / "qa_sprites.json").write_text(json.dumps({"checked_sprites": len(checks), "items": len(items), "complete": args.complete, "checks": checks}, indent=2) + "\n", encoding="utf-8")
    print(f"QA_OK {len(items)} itens; {len(checks)} imagens, recorte/contratos válidos; comparações com panela e pratos no staging")


if __name__ == "__main__":
    main()
