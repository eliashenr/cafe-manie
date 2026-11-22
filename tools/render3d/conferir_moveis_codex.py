"""Compara sprites nativos antigos/novos na mesma escala e mesma âncora."""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--staging", default="build/visual-reformulacao/moveis")
    parser.add_argument("--complete", action="store_true", help="Exige todas as rotações e encostos dos itens renderizados")
    args = parser.parse_args()
    staging = (ROOT / args.staging).resolve()
    if (ROOT / "build").resolve() not in staging.parents:
        parser.error("staging deve ser subpasta de build")
    old = json.loads((ROOT / "art/sprites/sprites.json").read_text(encoding="utf-8"))
    new = json.loads((staging / "manifest_patch.json").read_text(encoding="utf-8"))
    contract = json.loads((staging / "physical_contract.json").read_text(encoding="utf-8"))
    items = list(contract["items"])
    if args.complete:
        expected = set()
        for item in items:
            expected.update(old["furniture"][item].values())
            expected.update(name for name in old.get("chair_backrests", {}).get(item, {}).values() if name)
        if expected != set(new["sprites"]):
            raise ValueError(f"Catálogo divergente; faltam {sorted(expected - set(new['sprites']))}; extras {sorted(set(new['sprites']) - expected)}")
    canvas = Image.new("RGBA", (1120, 360 * len(items)), "#322b26")
    draw = ImageDraw.Draw(canvas)
    try:
        font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 20)
    except OSError:
        font = ImageFont.load_default()
    zoom = 2.8
    checks = {}
    for name, entry in new["sprites"].items():
        sprite = Image.open(staging / "sprites" / (name + ".png")).convert("RGBA")
        density = entry.get("density", new.get("density", 2))
        alpha = sprite.getchannel("A")
        bbox = alpha.getbbox()
        if not bbox or bbox[0] == 0 or bbox[1] == 0 or bbox[2] == sprite.width or bbox[3] == sprite.height:
            raise ValueError(f"Sprite vazio ou encostando na borda: {name}")
        checks[name] = {"image_px": list(sprite.size), "visible_world_bbox": [v / density for v in bbox], "density": density}
    for row, item in enumerate(items):
        candidates = [name for name in new["sprites"] if name.startswith(item + "_r")]
        preferred = item + ("_r3" if contract["items"][item]["kind"] == "chair" else "_r0")
        name = preferred if preferred in candidates else candidates[0]
        draw.text((20, row * 360 + 10), item, fill="#f5e9d4", font=font)
        for column, (manifest, directory, label) in enumerate(((old, ROOT / "art/sprites", "Atual"), (new, staging / "sprites", "Prova 3D"))):
            entry = manifest["sprites"][name]
            sprite = Image.open(directory / (name + ".png")).convert("RGBA")
            density = entry.get("density", manifest.get("density", 2))
            origin = (column * 560 + 280, row * 360 + 320)
            factor = zoom / density
            resized = sprite.resize((round(sprite.width * factor), round(sprite.height * factor)), Image.Resampling.LANCZOS)
            canvas.alpha_composite(resized, (round(origin[0] - entry["anchor"][0] * factor), round(origin[1] - entry["anchor"][1] * factor)))
            draw.text((column * 560 + 20, row * 360 + 42), label, fill="#d9cab5", font=font)
            draw.line((origin[0] - 5, origin[1], origin[0] + 5, origin[1]), fill="#c6a872")
            draw.line((origin[0], origin[1] - 5, origin[0], origin[1] + 5), fill="#c6a872")
        draw.line((10, (row + 1) * 360 - 1, 1110, (row + 1) * 360 - 1), fill="#59483c")
    path = staging / "comparacao_moveis.png"
    canvas.convert("RGB").save(path)
    if len(items) > 6:
        for page, first in enumerate(range(0, len(items), 6), 1):
            canvas.crop((0, first * 360, 1120, min(first + 6, len(items)) * 360)).convert("RGB").save(staging / f"comparacao_moveis_{page:02d}.png")
    (staging / "qa_sprites.json").write_text(json.dumps(checks, indent=2) + "\n", encoding="utf-8")
    print(path)
    print(f"{len(items)} comparações na mesma densidade de mundo; {len(checks)} sprites com margens transparentes preservadas")


if __name__ == "__main__":
    main()
