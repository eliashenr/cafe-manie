"""Ícones vetoriais creme/café/verde; produz somente um staging revisável.

Uso: python tools/ia/gerar_icones_ui.py
Saídas: build/visual-reformulacao/icones/{png,svg}, contato.png e verificacao.json.
Mantém tamanho e âncora dos sprites existentes; não escreve em art/sprites.
Requer Pillow. As mesmas primitivas geram o SVG editável e o PNG supersampled.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from xml.sax.saxutils import escape

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUTPUT = ROOT / "build/visual-reformulacao/icones"
CREAM = "#fff8eb"
CARD = "#fffdf7"
SAND = "#f2e8d6"
BORDER = "#d9cbb7"
COFFEE = "#382a23"
MUTED = "#786653"
TEAL = "#245e50"
LEAF = "#347560"
TERRA = "#a85b3d"
GOLD = "#91601c"
UTILITY = (
    "door_close", "door_open", "zoom_in", "zoom_out", "sound", "mute",
    "music", "music_off", "pause", "play", "gear",
    "close", "left", "right", "move", "rotate", "store", "sell", "serve", "trash", "check",
)
NAVIGATION = ("loja", "rolo", "expandir", "cidade")
LABELS = {
    "door_close": "Fechar café", "door_open": "Abrir café", "zoom_in": "Aproximar",
    "zoom_out": "Afastar", "sound": "Som", "mute": "Sem som", "music": "Música",
    "music_off": "Sem música", "pause": "Pausar", "play": "Continuar", "gear": "Recomeçar",
    "loja": "Loja", "rolo": "Reformar", "expandir": "Expandir", "cidade": "Cidade",
    "close": "Fechar", "left": "Anterior", "right": "Próxima", "move": "Mover",
    "rotate": "Girar", "store": "Guardar", "sell": "Vender", "serve": "Servir",
    "trash": "Descartar", "check": "Confirmar",
}


class VectorIcon:
    """Geometria em 64×64, rasterizada a 8×, mantendo a proporção do desenho."""

    def __init__(self, size: tuple[int, int]):
        self.size = size
        self.supersample = 8
        self.scale = min(size) / 64
        self.dx = (size[0] - 64 * self.scale) / 2
        self.dy = (size[1] - 64 * self.scale) / 2
        self.image = Image.new("RGBA", (size[0] * 8, size[1] * 8))
        self.draw = ImageDraw.Draw(self.image)
        self.elements: list[str] = []

    def point(self, xy):
        return ((xy[0] * self.scale + self.dx) * 8, (xy[1] * self.scale + self.dy) * 8)

    def box(self, xy):
        return (*self.point(xy[:2]), *self.point(xy[2:]))

    def width(self, width):
        return max(1, round(width * self.scale * 8))

    def rounded(self, xy, radius, fill, stroke=None, width=1.5):
        x0, y0, x1, y1 = xy
        self.draw.rounded_rectangle(self.box(xy), radius * self.scale * 8,
                                    fill=fill, outline=stroke, width=self.width(width))
        outline = f' stroke="{stroke}" stroke-width="{width}"' if stroke else ""
        self.elements.append(f'<rect x="{x0}" y="{y0}" width="{x1-x0}" height="{y1-y0}" '
                             f'rx="{radius}" fill="{fill}"{outline}/>')

    def ellipse(self, xy, fill, stroke=None, width=1.5):
        x0, y0, x1, y1 = xy
        self.draw.ellipse(self.box(xy), fill=fill, outline=stroke, width=self.width(width))
        outline = f' stroke="{stroke}" stroke-width="{width}"' if stroke else ""
        self.elements.append(f'<ellipse cx="{(x0+x1)/2}" cy="{(y0+y1)/2}" '
                             f'rx="{(x1-x0)/2}" ry="{(y1-y0)/2}" fill="{fill}"{outline}/>')

    def line(self, points, fill=TEAL, width=3, closed=False):
        points = list(points)
        raster = points + points[:1] if closed else points
        self.draw.line([self.point(p) for p in raster], fill, self.width(width), joint="curve")
        for x, y in points:
            self.draw.ellipse(self.box((x-width/2, y-width/2, x+width/2, y+width/2)), fill)
        tag = "polygon" if closed else "polyline"
        coords = " ".join(f"{x:.3f},{y:.3f}" for x, y in points)
        self.elements.append(f'<{tag} points="{coords}" fill="none" stroke="{fill}" '
                             f'stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round"/>')

    def polygon(self, points, fill, stroke=None, width=1.5):
        self.draw.polygon([self.point(p) for p in points], fill)
        coords = " ".join(f"{x:.3f},{y:.3f}" for x, y in points)
        self.elements.append(f'<polygon points="{coords}" fill="{fill}"/>')
        if stroke:
            self.line(points, stroke, width, closed=True)

    def arc(self, center, radius, start, end, fill=TEAL, width=3):
        points = [(center[0] + radius * math.cos(math.radians(t)),
                   center[1] + radius * math.sin(math.radians(t)))
                  for t in (start + (end-start)*i/32 for i in range(33))]
        self.line(points, fill, width)

    def write(self, folder: Path, name: str):
        png = self.image.resize(self.size, Image.Resampling.LANCZOS)
        png.save(folder / "png" / f"{name}.png", optimize=True)
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.size[0]}" height="{self.size[1]}" '
               f'viewBox="0 0 {self.size[0]} {self.size[1]}"><title>{escape(name)}</title>'
               f'<g transform="translate({self.dx} {self.dy}) scale({self.scale})">'
               + "".join(self.elements) + "</g></svg>\n")
        (folder / "svg" / f"{name}.svg").write_text(svg, encoding="utf-8")
        return png


def button_background(v):
    v.rounded((3, 6, 61, 63), 15, BORDER)
    v.rounded((3, 3, 61, 60), 15, CREAM, BORDER, 1.3)
    v.rounded((6, 6, 58, 28), 11, CARD)


def utility(v, kind):
    button_background(v)
    if kind.startswith("zoom_"):
        v.ellipse((15, 14, 40, 39), SAND, TEAL, 3)
        v.line([(37, 36), (48, 47)], TEAL, 5)
        v.line([(22, 26.5), (33, 26.5)], TEAL, 3)
        if kind == "zoom_in":
            v.line([(27.5, 21), (27.5, 32)], TEAL, 3)
    elif kind in ("sound", "mute"):
        v.polygon([(15, 26), (22, 26), (31, 19), (31, 45), (22, 38), (15, 38)], TEAL, TEAL, 1.5)
        if kind == "sound":
            v.arc((31, 32), 9, -52, 52, width=2.8)
            v.arc((31, 32), 16, -52, 52, width=2.8)
        else:
            v.line([(39, 26), (48, 38)], TERRA, 3.5)
            v.line([(48, 26), (39, 38)], TERRA, 3.5)
    elif kind in ("music", "music_off"):
        v.line([(25, 43), (25, 20), (44, 16), (44, 39)], TEAL, 3.8)
        v.line([(25, 25), (44, 21)], TEAL, 3.3)
        v.ellipse((14, 37, 26, 47), TEAL)
        v.ellipse((33, 33, 45, 43), TEAL)
        if kind == "music_off":
            v.line([(15, 16), (48, 48)], CREAM, 7)
            v.line([(15, 16), (48, 48)], TERRA, 3)
    elif kind == "pause":
        v.rounded((21, 17, 29, 46), 2.5, TEAL)
        v.rounded((35, 17, 43, 46), 2.5, TEAL)
    elif kind == "play":
        v.polygon([(24, 18), (46, 32), (24, 46)], TEAL, TEAL, 2.3)
    elif kind in ("door_open", "door_close"):
        v.rounded((20, 13, 45, 50), 2, SAND, TEAL, 2.6)
        if kind == "door_close":
            v.rounded((25, 18, 40, 44), 1.2, CREAM, BORDER, 1.2)
            v.ellipse((36, 30, 40, 34), GOLD)
        else:
            v.rounded((25, 18, 41, 47), 1, TEAL)
            v.polygon([(21, 14), (10, 19), (10, 51), (21, 49)], CREAM, TEAL, 2.5)
            v.ellipse((14, 31, 17, 34), GOLD)
        v.line([(14, 51), (49, 51)], TEAL, 2.5)
    elif kind == "gear":
        pts = []
        for i in range(8):
            for offset, radius in ((-18, 14), (-13, 19), (13, 19), (18, 14)):
                angle = math.radians(i * 45 + offset)
                pts.append((32 + radius*math.cos(angle), 32 + radius*math.sin(angle)))
        v.polygon(pts, TEAL, TEAL, 1)
        v.ellipse((25, 25, 39, 39), CREAM)
    elif kind == "close":
        v.line([(22, 22), (42, 42)], TERRA, 4)
        v.line([(42, 22), (22, 42)], TERRA, 4)
    elif kind in ("left", "right"):
        xs = (37, 25, 37) if kind == "left" else (27, 39, 27)
        v.line([(xs[0], 21), (xs[1], 32), (xs[2], 43)], TEAL, 4)
    elif kind == "move":
        v.line([(32, 15), (32, 49)], TEAL, 3)
        v.line([(15, 32), (49, 32)], TEAL, 3)
        for points in (
            [(25, 22), (32, 15), (39, 22)], [(25, 42), (32, 49), (39, 42)],
            [(22, 25), (15, 32), (22, 39)], [(42, 25), (49, 32), (42, 39)],
        ):
            v.line(points, TEAL, 3)
    elif kind == "rotate":
        v.arc((32, 32), 16, -135, 160, TEAL, 3.5)
        v.line([(15, 28), (17, 39), (28, 36)], TEAL, 3.5)
    elif kind == "store":
        v.rounded((17, 25, 47, 48), 2, SAND, TEAL, 2.5)
        v.rounded((14, 18, 50, 27), 2, CREAM, TEAL, 2.5)
        v.line([(27, 35), (37, 35)], TEAL, 3)
    elif kind == "sell":
        v.ellipse((14, 14, 50, 50), SAND, GOLD, 2.5)
        v.arc((32, 32), 14, 150, 265, "#c09a5d", 1.5)
        v.line([(38, 23), (34, 21), (28, 22), (25, 26), (27, 30),
                (37, 34), (39, 38), (36, 42), (30, 43), (25, 41)], GOLD, 2.8)
        v.line([(32, 18), (32, 46)], GOLD, 2.4)
    elif kind == "serve":
        v.ellipse((29.5, 16, 34.5, 21), GOLD)
        v.arc((32, 38), 16, 180, 360, TEAL, 3)
        v.line([(16, 38), (48, 38)], TEAL, 3)
        v.line([(12, 44), (52, 44)], TEAL, 3)
    elif kind == "trash":
        v.polygon([(20, 24), (44, 24), (42, 48), (22, 48)], SAND, TERRA, 2.5)
        v.rounded((26, 14, 38, 21), 2, CREAM, TERRA, 2.5)
        v.line([(16, 21), (48, 21)], TERRA, 3)
        v.line([(28, 30), (28, 41)], TERRA, 2.5)
        v.line([(36, 30), (36, 41)], TERRA, 2.5)
    elif kind == "check":
        v.line([(19, 32), (28, 41), (46, 23)], TEAL, 4.5)


def navigation(v, kind):
    if kind == "loja":
        v.rounded((12, 25, 52, 53), 2, CREAM, COFFEE, 2.3)
        v.rounded((18, 35, 30, 46), 1, SAND, COFFEE, 1.8)
        v.rounded((37, 35, 46, 53), 1, TEAL)
        v.line([(9, 54), (55, 54)], COFFEE, 2.5)
        v.polygon([(15, 13), (49, 13), (55, 27), (9, 27)], TERRA, COFFEE, 2)
        for x in (19, 33, 47):
            v.polygon([(x-1, 14), (x+5, 14), (x+7, 26), (x-2, 26)], CREAM)
        for x in (9, 20.5, 32, 43.5):
            v.rounded((x, 25, x+11.5, 32), 3, TERRA if x in (9, 32) else CREAM, COFFEE, 1.6)
    elif kind == "rolo":
        v.line([(43, 18), (51, 18), (51, 32), (32, 38), (32, 43)], COFFEE, 3.5)
        v.rounded((10, 13, 44, 28), 4, LEAF, COFFEE, 2.2)
        v.line([(16, 17), (37, 17)], "#74a08b", 2)
        v.rounded((27, 39, 37, 57), 3, TERRA, COFFEE, 2)
        v.ellipse((30.5, 49.5, 33.5, 52.5), CREAM)
    elif kind == "expandir":
        v.rounded((18, 18, 46, 46), 4, SAND, BORDER, 1.5)
        # Quatro cantos deixam o gesto de expansão distinto da reforma.
        for sx, sy in ((-1,-1), (1,-1), (-1,1), (1,1)):
            tip = (32+sx*22, 32+sy*22)
            v.line([(32+sx*10, 32+sy*10), tip], TEAL, 3.4)
            v.line([(tip[0]-sx*9, tip[1]), tip, (tip[0], tip[1]-sy*9)], TEAL, 3.4)
    elif kind == "cidade":
        v.rounded((9, 28, 26, 53), 1.5, SAND, COFFEE, 2)
        v.polygon([(7, 29), (17.5, 19), (28, 29)], TERRA, COFFEE, 1.8)
        v.rounded((26, 14, 43, 53), 1.5, CREAM, COFFEE, 2)
        v.rounded((40, 32, 55, 53), 1.5, SAND, COFFEE, 2)
        v.polygon([(38, 33), (47.5, 24), (57, 33)], TERRA, COFFEE, 1.8)
        for x, y in ((15,34),(15,43),(30,20),(36,20),(30,29),(36,29),(45,38)):
            v.rounded((x,y,x+4,y+5), .6, TEAL)
        v.rounded((31, 41, 38, 53), 1, TEAL)
        v.line([(7, 54), (57, 54)], COFFEE, 2.5)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def contact_sheet(output, images):
    rows = math.ceil(len(images)/5)
    sheet = Image.new("RGB", (800, 92+rows*156), CREAM)
    draw = ImageDraw.Draw(sheet)
    font_path = Path("C:/Windows/Fonts/segoeui.ttf")
    font = ImageFont.truetype(str(font_path), 14) if font_path.exists() else ImageFont.load_default()
    heading = ImageFont.truetype(str(font_path), 20) if font_path.exists() else font
    draw.text((22, 15), "CAFÉ MANIE · Ícones da interface", COFFEE, font=heading)
    draw.text((22, 46), "Símbolos sem texto · ampliados e no tamanho de uso (44 / 36 px)", MUTED, font=font)
    for i, (name, img) in enumerate(images.items()):
        col, row = i % 5, i // 5
        x, y = 15 + col*156, 80 + row*156
        draw.rounded_rectangle((x, y, x+146, y+146), 12, fill=CARD, outline=BORDER)
        large = img.copy()
        large.thumbnail((73, 73), Image.Resampling.LANCZOS)
        sheet.paste(large, (x+(146-large.width)//2, y+8), large)
        is_utility = name.startswith("botao_")
        width = 44 if is_utility else 36
        if is_utility:
            small = img.resize((width, round(width*img.height/img.width)), Image.Resampling.LANCZOS)
        else:
            small = img.copy()
            small.thumbnail((width, width), Image.Resampling.LANCZOS)
        sheet.paste(small, (x+(146-small.width)//2, y+81), small)
        label = LABELS[name.split("_", 1)[1]]
        draw.text((x+73, y+129), label, COFFEE, font=font, anchor="mt")
    sheet.save(output / "contato.png")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    output = args.output.resolve()
    # O gerador não deve ser usado como instalador por engano.
    if output == ROOT / "art" or (ROOT / "art") in output.parents:
        parser.error("Use um staging fora de art/. A instalação é uma etapa separada.")
    for sub in ("png", "svg"):
        (output / sub).mkdir(parents=True, exist_ok=True)
    manifest_path = ROOT / "art/sprites/sprites.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    names = [f"botao_{x}" for x in UTILITY] + [f"icone_{x}" for x in NAVIGATION]
    source_paths = [manifest_path] + [ROOT / "art/sprites" / f"{name}.png" for name in names]
    before = {str(p.relative_to(ROOT)): digest(p) for p in source_paths}
    images, entries = {}, {}
    for name in names:
        source = ROOT / "art/sprites" / f"{name}.png"
        with Image.open(source) as image:
            size = image.size
        v = VectorIcon(size)
        kind = name.split("_", 1)[1]
        (utility if name.startswith("botao_") else navigation)(v, kind)
        images[name] = v.write(output, name)
        alpha = images[name].getchannel("A")
        assert alpha.getextrema() == (0, 255), f"Alpha inválido: {name}"
        assert images[name].mode == "RGBA"
        assert images[name].getpixel((0,0))[3] == 0, name
        entries[name] = {"size": list(size), **manifest["sprites"][name]}
    # Nome solicitado pelo PO; o contrato atual do BuildBar continua icone_rolo.
    for sub, ext in (("png", "png"), ("svg", "svg")):
        (output / sub / f"icone_reformar.{ext}").write_bytes((output / sub / f"icone_rolo.{ext}").read_bytes())
    entries["icone_reformar"] = {**entries["icone_rolo"], "alias_of": "icone_rolo", "production_id": False}
    after = {str(p.relative_to(ROOT)): digest(p) for p in source_paths}
    assert before == after, "Os arquivos de produção mudaram durante a geração."
    contact_sheet(output, images)
    report = {
        "generated": len(entries), "production_replacements": len(names),
        "density": manifest.get("density"), "production_unchanged": before == after,
        "alpha": "RGBA com cantos transparentes", "entries": entries,
        "production_sha256_before_and_after": before,
        "installation": f"Copiar somente os {len(names)} PNGs dos IDs existentes; manifesto e âncoras preservados. icone_reformar é alias de staging.",
    }
    (output / "verificacao.json").write_text(json.dumps(report, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print(json.dumps({"output": str(output), "generated": len(entries), "production_unchanged": True}, ensure_ascii=False))


if __name__ == "__main__":
    main()
