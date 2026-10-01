"""Exporta os sprites do jogo a partir da arte v3: SVG -> PNG (pelo Chrome ou Edge, sem janela).

O desenho é feito na escala do canvas (piso de 96x48) e ampliado inteiro para a escala do jogo,
com DENSITY pixels de textura por pixel de mundo; assim os traços engrossam junto com o desenho.
Depois, tools/sprites/crop_sprites.gd recorta as sobras e grava res://art/furniture/.

    python export_sprites.py                 # SVGs e PNGs crus em tools/sprites/raw/
    SPRITES_BROWSER="C:/caminho/chrome.exe" python export_sprites.py

Por que não a Godot: o desenho de SVG dela (ThorVG) deixa vazio o gradiente de formas curvas.

Convenção de rotação do jogo (FurnitureView): a frente do móvel aponta para
0 = sudoeste (+y), 1 = noroeste (-x), 2 = nordeste (-y), 3 = sudeste (+x).
Só +y e +x ficam de frente para a câmera; nas outras duas o móvel aparece de costas.
"""
import json
import os
import shutil
import subprocess

from furniture3 import *  # noqa: F401,F403

TILE_W = 96.0
GAME_TILE_W = 128.0  # IsoProjection.TILE_SIZE.x
DENSITY = 2.0
SCALE = GAME_TILE_W / TILE_W * DENSITY
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "sprites", "raw"))
BROWSERS = [
    os.environ.get("SPRITES_BROWSER", ""),
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "google-chrome", "chromium", "chromium-browser", "microsoft-edge",
]
# Folga acima e em volta do piso: o rasterizador recorta o que sobrar.
MARGIN_X = 40.0
HEADROOM = 160.0
MARGIN_BOTTOM = 24.0

FACING = {0: "+y", 1: "-x", 2: "-y", 3: "+x"}
FACE = {0: "L", 3: "R"}  # face da caixa voltada para a câmera (iso.quad); 1 e 2 não aparecem


def footprint(base, rotation):
    return base if rotation % 2 == 0 else (base[1], base[0])


def chair_sprite(D, iso, fp, rotation):
    drawn = chair(D, iso, 0, 0, FACING[rotation], "#ff4d5e")
    return drawn if isinstance(drawn, str) else drawn[0] + drawn[1]


def table_round_sprite(D, iso, fp, rotation):
    return table_round(D, iso, 0, 0, "#ff4d5e")


def table_long_sprite(D, iso, fp, rotation):
    if fp[0] == 2:
        return table_square(D, iso, 0, 0, joined="+x", vase=False) + table_square(D, iso, 1, 0, joined="-x")
    return table_square(D, iso, 0, 0, joined="+y", vase=False) + table_square(D, iso, 0, 1, joined="-y")


def stove_sprite(D, iso, fp, rotation):
    return stove(D, iso, 0, 0, FACE.get(rotation))


def counter_sprite(D, iso, fp, rotation):
    along = "x" if fp[0] > 1 else "y"
    return counter(D, iso, 0, 0, FACE.get(rotation), cells=max(fp), along=along)


def bookshelf_sprite(D, iso, fp, rotation):
    return bookshelf(D, iso, 0, 0, front=FACING[rotation])


def plant_sprite(D, iso, fp, rotation):
    return plant(D, iso, 0, 0)


def flower_vase_sprite(D, iso, fp, rotation):
    return flower_vase(D, iso, 0, 0)


def floor_lamp_sprite(D, iso, fp, rotation):
    return floor_lamp(D, iso, 0, 0)


# id do móvel no jogo -> (pegada na rotação 0, desenho, quantos desenhos diferentes: 4, 2 ou 1)
FURNITURE = {
    "chair_wood": ((1, 1), chair_sprite, 4),
    "table_round": ((1, 1), table_round_sprite, 1),
    "table_long": ((2, 1), table_long_sprite, 2),
    "stove_basic": ((1, 1), stove_sprite, 4),
    "counter_basic": ((2, 1), counter_sprite, 4),
    "bookshelf": ((2, 1), bookshelf_sprite, 4),
    "plant_pot": ((1, 1), plant_sprite, 1),
    "flower_vase": ((1, 1), flower_vase_sprite, 1),
    "floor_lamp": ((1, 1), floor_lamp_sprite, 1),
}


def svg_document(body, defs, fp):
    """Desenho na célula (0, 0); a âncora é o vértice da frente da pegada, como no FurnitureView."""
    iso = Iso(0, 0, TILE_W, TILE_W / 2)
    left = iso.v(0, fp[1])[0] - MARGIN_X
    right = iso.v(fp[0], 0)[0] + MARGIN_X
    top = -HEADROOM
    bottom = iso.v(fp[0], fp[1])[1] + MARGIN_BOTTOM
    width, height = right - left, bottom - top
    anchor = iso.v(fp[0], fp[1])
    size = (round(width * SCALE), round(height * SCALE))
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{size[0]}" height="{size[1]}" '
           f'viewBox="{f(left)} {f(top)} {f(width)} {f(height)}">{defs}{body}</svg>')
    return svg, size, [(anchor[0] - left) * SCALE, (anchor[1] - top) * SCALE]


def find_browser():
    for candidate in BROWSERS:
        if candidate and (os.path.isfile(candidate) or shutil.which(candidate)):
            return shutil.which(candidate) or candidate
    raise SystemExit("Chrome ou Edge não encontrado. Indique o caminho em SPRITES_BROWSER.")


def rasterize(browser, svg_path, png_path, size):
    """Fundo transparente, sem barras e sem ampliação do Windows: 1 px de SVG = 1 px de PNG."""
    subprocess.run([browser, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                    "--default-background-color=00000000", f"--window-size={size[0]},{size[1]}",
                    f"--screenshot={png_path}", "file:///" + svg_path.replace(os.sep, "/")],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def export(out_dir=OUT):
    os.makedirs(out_dir, exist_ok=True)
    browser = find_browser()
    manifest = {"density": DENSITY, "furniture": {}}
    for item_id, (base, draw, variants) in FURNITURE.items():
        entry = {}
        for rotation in range(4):
            source = rotation % variants
            name = f"{item_id}_r{source}"
            if source == rotation:
                fp = footprint(base, rotation)
                D = Defs()
                iso = Iso(0, 0, TILE_W, TILE_W / 2)
                body = draw(D, iso, fp, rotation)
                svg, size, anchor = svg_document(body, D.render(), fp)
                svg_path = os.path.join(out_dir, name + ".svg")
                with open(svg_path, "w", encoding="utf-8", newline="\n") as fh:
                    fh.write(svg)
                rasterize(browser, svg_path, os.path.join(out_dir, name + ".png"), size)
                manifest.setdefault("sprites", {})[name] = {"anchor": [round(anchor[0], 2), round(anchor[1], 2)]}
            entry[str(rotation)] = name
        manifest["furniture"][item_id] = entry
    with open(os.path.join(out_dir, "sprites.json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump(manifest, fh, indent=1, ensure_ascii=False)
        fh.write("\n")
    return manifest


if __name__ == "__main__":
    result = export()
    print(f"{len(result['sprites'])} sprites em {OUT}")
