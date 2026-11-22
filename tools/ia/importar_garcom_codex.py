"""Importa folhas transparentes do garçom sem redesenhar ou remover fundo.

Uso: python tools/ia/importar_garcom_codex.py art/characters/waiter/calibracao.json
     --out build/visual-garcom [--install]

Cada folha tem 3 colunas x 3 linhas: passos 0..7, depois em_pe. A calibração
guarda uma âncora fixa por folha e uma altura de referência do quadro parado.
Todas as poses usam a MESMA escala; o recorte não altera seu registro nem apaga
o movimento vertical original. registration é uma correção explícita da posição
da arte na célula, nunca calculada a partir dos pés de cada pose.

Formato (quatro folhas, frente/costas x carrying false/true):
{
  "version": 1,
  "sheets": [{
    "file": "frente_sem_bandeja.png", "view": "frente", "carrying": false,
    "anchor": [341, 600], "reference_height_px": 520,
    "frames": [{"registration": [0, 0]}, ... nove entradas ...]
  }]
}

file é relativo ao JSON. Opcionalmente cells contém nove [x,y,w,h] de recorte
na folha. Sem cells, a divisão é uma grade regular. anchor, registration e tray
estão em pixels da célula ORIGINAL. Nas folhas com bandeja, cada frame precisa
de tray: [centro_x, superfície_y, largura_do_prato]. Essa medida é conferida
visualmente, não adivinhada por cor. O importador gera uma folha com as marcas.
mirror: true espelha cada célula e suas medidas, sem trocar a ordem das poses.
portrait: {"file": "icone.png", "target_size": 256} importa também o ícone,
recortando apenas as margens transparentes e mantendo sua proporção.

Sem --install, só grava o staging. Instalar exige as 36 poses completas, sem
quadros de caminhada duplicados, e só troca garcom_*, suas entradas no manifesto
e as duas medidas legadas da bandeja. Não gera arquivos .import: a Godot importa
os PNGs depois. Deve existir apenas um escritor de sprites.json por vez.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import tempfile

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
HEIGHT_WORLD = 96.0
DENSITY = 4
POSES = tuple(f"passo_{i}" for i in range(8)) + ("em_pe",)
VIEWS = ("frente", "costas")
ALPHA_MEASURE = 8
EXPECTED = frozenset(
    f"garcom_{view}_{pose}{'_bandeja' if carrying else ''}"
    for view in VIEWS for carrying in (False, True) for pose in POSES
)


def read_json(path: Path) -> dict:
    with path.open(encoding="utf-8-sig") as handle:
        return json.load(handle)


def write_json(path: Path, value: dict, indent: int = 2) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, ensure_ascii=False, indent=indent)
        handle.write("\n")


def pair(value, name: str) -> tuple[float, float]:
    if not isinstance(value, (list, tuple)) or len(value) != 2:
        raise ValueError(f"{name}: use [x, y]")
    result = tuple(float(x) for x in value)
    if not all(math.isfinite(x) for x in result):
        raise ValueError(f"{name}: coordenada não finita")
    return result


def cell_rects(size: tuple[int, int], explicit=None) -> list[tuple[int, int, int, int]]:
    width, height = size
    if explicit is None:
        xs = [round(i * width / 3) for i in range(4)]
        ys = [round(i * height / 3) for i in range(4)]
        return [(xs[col], ys[row], xs[col + 1], ys[row + 1])
                for row in range(3) for col in range(3)]
    if len(explicit) != 9:
        raise ValueError("cells precisa de nove retângulos")
    result = []
    for rect in explicit:
        if len(rect) != 4 or any(int(v) != v for v in rect):
            raise ValueError("cells: use [x, y, largura, altura] inteiros")
        x, y, w, h = map(int, rect)
        if x < 0 or y < 0 or w <= 0 or h <= 0 or x + w > width or y + h > height:
            raise ValueError(f"célula fora da folha: {rect}")
        result.append((x, y, x + w, y + h))
    return result


def measured_box(image: Image.Image) -> tuple[int, int, int, int]:
    # O limiar só mede/valida. O alfa original nunca é substituído por esta máscara.
    box = image.getchannel("A").point(lambda a: 255 if a > ALPHA_MEASURE else 0).getbbox()
    if box is None:
        raise ValueError("célula vazia")
    if box[0] == 0 or box[1] == 0 or box[2] == image.width or box[3] == image.height:
        raise ValueError("arte toca a borda da célula; confira a grade ou gere a folha com margem")
    return box


def pixel_hash(image: Image.Image) -> str:
    return hashlib.sha256(str(image.size).encode() + image.tobytes()).hexdigest()


def import_sheet(spec: dict, source_dir: Path) -> list[dict]:
    view = spec.get("view")
    carrying = spec.get("carrying")
    if view not in VIEWS or not isinstance(carrying, bool):
        raise ValueError("cada folha exige view frente/costas e carrying booleano")
    path = (source_dir / spec["file"]).resolve()
    with Image.open(path) as raw:
        if raw.mode != "RGBA" or raw.getchannel("A").getextrema()[0] != 0:
            raise ValueError(f"{path.name}: exige PNG RGBA com fundo transparente nativo")
        sheet = raw.copy()
    rects = cell_rects(sheet.size, spec.get("cells"))
    cells = [sheet.crop(rect) for rect in rects]
    boxes = [measured_box(cell) for cell in cells]
    reference_height = float(spec.get("reference_height_px") or (boxes[8][3] - boxes[8][1]))
    if not math.isfinite(reference_height) or reference_height <= 0:
        raise ValueError("reference_height_px precisa ser positiva")
    anchor = pair(spec["anchor"], "anchor")
    mirror = spec.get("mirror", False)
    if not isinstance(mirror, bool):
        raise ValueError("mirror precisa ser booleano")
    settings = spec.get("frames", [{} for _ in POSES])
    if len(settings) != 9:
        raise ValueError("frames precisa de nove entradas (passos 0..7, em_pe)")
    # Um canvas comum evita que o arredondamento de cada bbox mude a escala entre poses.
    canvas_size = (max(cell.width for cell in cells), max(cell.height for cell in cells))
    factor = HEIGHT_WORLD * DENSITY / reference_height
    scaled_size = tuple(max(1, round(dimension * factor)) for dimension in canvas_size)
    sx, sy = scaled_size[0] / canvas_size[0], scaled_size[1] / canvas_size[1]
    source_hash = hashlib.sha256(path.read_bytes()).hexdigest()
    result = []
    for index, (cell, box, frame_spec) in enumerate(zip(cells, boxes, settings)):
        registration = pair(frame_spec.get("registration", [0, 0]), "registration")
        ax, ay = anchor[0] - registration[0], anchor[1] - registration[1]
        if not (0 <= ax <= canvas_size[0] and 0 <= ay <= canvas_size[1]):
            raise ValueError(f"{path.name}/{index}: âncora corrigida fora da célula")
        canvas = Image.new("RGBA", canvas_size)
        canvas.paste(cell, (0, 0))
        scaled = canvas.resize(scaled_size, Image.Resampling.LANCZOS)
        scaled_anchor = [ax * sx, ay * sy]
        if mirror:
            scaled = scaled.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            scaled_anchor[0] = scaled.width - scaled_anchor[0]
        crop = scaled.getchannel("A").getbbox()
        if crop is None:
            raise ValueError(f"{path.name}/{index}: quadro vazio depois da redução")
        image = scaled.crop(crop)
        entry = {
            "anchor": [round(scaled_anchor[0] - crop[0], 3), round(scaled_anchor[1] - crop[1], 3)],
            "density": DENSITY,
            "authored_motion": True,
            "external_shadow": True,
        }
        if carrying:
            tray = frame_spec.get("tray")
            if not isinstance(tray, list) or len(tray) != 3:
                raise ValueError(f"{path.name}/{index}: falta tray [x,y,largura] conferido visualmente")
            tx, ty, tw = map(float, tray)
            if not all(math.isfinite(v) for v in (tx, ty, tw)) or tw <= 0:
                raise ValueError(f"{path.name}/{index}: medida de bandeja inválida")
            if not (0 <= tx < cell.width and 0 <= ty < cell.height and tw <= cell.width):
                raise ValueError(f"{path.name}/{index}: bandeja fora da célula")
            entry["tray"] = [round((tx - ax) * sx / DENSITY * (-1 if mirror else 1), 3),
                             round((ty - ay) * sy / DENSITY, 3),
                             round(tw * sx / DENSITY, 3)]
        elif "tray" in frame_spec:
            raise ValueError(f"{path.name}/{index}: folha sem bandeja não pode declarar tray")
        name = f"garcom_{view}_{POSES[index]}{'_bandeja' if carrying else ''}"
        result.append({"name": name, "image": image, "entry": entry, "view": view,
                       "carrying": carrying, "index": index,
                       "source": {"file": str(path), "sha256": source_hash,
                                  "cell": list(rects[index]), "measured_box": list(box),
                                  "reference_height_px": reference_height,
                                  "registration": list(registration), "scale": [sx, sy], "mirror": mirror}})
    validate_unique_walk(result)
    return result


def validate_unique_walk(frames: list[dict]) -> None:
    hashes = [pixel_hash(frame["image"]) for frame in frames if frame["index"] < 8]
    if len(hashes) != 8 or len(set(hashes)) != 8:
        raise ValueError("a caminhada exige oito quadros distintos; não duplicar poses para completar a folha")


def import_portrait(spec: dict, source_dir: Path) -> dict:
    path = (source_dir / spec["file"]).resolve()
    target = spec.get("target_size", 256)
    if not isinstance(target, int) or not 32 <= target <= 2048:
        raise ValueError("portrait.target_size: use um inteiro entre 32 e 2048")
    with Image.open(path) as raw:
        if raw.mode != "RGBA" or raw.getchannel("A").getextrema()[0] != 0:
            raise ValueError("o retrato exige PNG RGBA transparente")
        crop = raw.getchannel("A").getbbox()
        if crop is None:
            raise ValueError("retrato vazio")
        image = raw.crop(crop)
    factor = target / max(image.size)
    image = image.resize(tuple(max(1, round(n * factor)) for n in image.size), Image.Resampling.LANCZOS)
    return {"name": "icone_garcom", "image": image,
            "entry": {"anchor": [image.width / 2, image.height / 2], "density": DENSITY},
            "source": {"file": str(path), "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                       "crop": list(crop), "target_size": target}}


def validate_complete(frames: list[dict]) -> None:
    names = [frame["name"] for frame in frames]
    if len(names) != 36 or set(names) != EXPECTED:
        missing = sorted(EXPECTED - set(names))
        raise ValueError(f"instalação exige exatamente as 36 poses do garçom; faltam: {missing}")
    by_name = {frame["name"]: frame for frame in frames}
    for view in VIEWS:
        for carrying in (False, True):
            validate_unique_walk([frame for frame in frames if frame["view"] == view and frame["carrying"] == carrying])
        for pose in POSES:
            base = f"garcom_{view}_{pose}"
            if pixel_hash(by_name[base]["image"]) == pixel_hash(by_name[base + "_bandeja"]["image"]):
                raise ValueError(f"{base}: com e sem bandeja são a mesma imagem")


def manifest_patch(frames: list[dict], portrait: dict | None = None) -> dict:
    patch = {"sprites": {frame["name"]: frame["entry"] for frame in frames}}
    if portrait is not None:
        if portrait["name"] != "icone_garcom":
            raise ValueError("o único retrato permitido é icone_garcom")
        patch["sprites"]["icone_garcom"] = portrait["entry"]
    legacy = {}
    for frame in frames:
        if frame["carrying"] and frame["index"] == 8:
            key = "tray_food" if frame["view"] == "frente" else "tray_food_back"
            legacy[key] = frame["entry"]["tray"]
    if legacy:
        patch["characters"] = legacy
    return patch


def qa_images(frames: list[dict], out: Path) -> None:
    groups = sorted({(frame["view"], frame["carrying"]) for frame in frames})
    half_width = max(max(frame["entry"]["anchor"][0], frame["image"].width - frame["entry"]["anchor"][0]) for frame in frames)
    above = max(frame["entry"]["anchor"][1] for frame in frames)
    below = max(frame["image"].height - frame["entry"]["anchor"][1] for frame in frames)
    tile_w = max(256, math.ceil(half_width * 2 + 24))
    tile_h = max(448, math.ceil(above + max(24, below + 12) + 24))
    board = Image.new("RGB", (tile_w * 9, tile_h * len(groups)), (66, 59, 52))
    draw = ImageDraw.Draw(board)
    for row, group in enumerate(groups):
        ordered = sorted((f for f in frames if (f["view"], f["carrying"]) == group), key=lambda f: f["index"])
        for frame in ordered:
            x, y = frame["index"] * tile_w, row * tile_h
            ax, ay = frame["entry"]["anchor"]
            ground = (x + tile_w // 2, y + tile_h - 24)
            at = (round(ground[0] - ax), round(ground[1] - ay))
            board.paste(frame["image"], at, frame["image"])
            draw.text((x + 6, y + 5), frame["name"].removeprefix("garcom_"), fill=(245, 239, 222))
            draw.line((ground[0] - 7, ground[1], ground[0] + 7, ground[1]), fill=(255, 90, 90), width=2)
            draw.line((ground[0], ground[1] - 7, ground[0], ground[1] + 7), fill=(255, 90, 90), width=2)
            if "tray" in frame["entry"]:
                tx, ty, tw = frame["entry"]["tray"]
                cx, cy = ground[0] + tx * DENSITY, ground[1] + ty * DENSITY
                draw.line((cx - tw * DENSITY / 2, cy, cx + tw * DENSITY / 2, cy), fill=(80, 210, 255), width=2)
    board.save(out / "contato_marcas.png")
    sequence = []
    for index in range(8):
        page = Image.new("RGB", (tile_w * len(groups), tile_h), (66, 59, 52))
        label = ImageDraw.Draw(page)
        for col, group in enumerate(groups):
            frame = next(f for f in frames if (f["view"], f["carrying"]) == group and f["index"] == index)
            ax, ay = frame["entry"]["anchor"]
            page.paste(frame["image"], (round(col * tile_w + tile_w / 2 - ax), round(tile_h - 24 - ay)), frame["image"])
            label.text((col * tile_w + 6, 5), f"{group[0]} / {'bandeja' if group[1] else 'maos livres'}", fill=(245, 239, 222))
        sequence.append(page)
    sequence[0].save(out / "andar.gif", save_all=True, append_images=sequence[1:], duration=110, loop=0)


def install(frames: list[dict], staging: Path, root: Path = ROOT, portrait: dict | None = None) -> None:
    validate_complete(frames)
    destination = root / "art" / "sprites"
    path = destination / "sprites.json"
    manifest = read_json(path)
    patch = manifest_patch(frames, portrait)
    # Copia apenas nomes previamente enumerados. Não apaga nem reexporta outros assets.
    names = EXPECTED | ({"icone_garcom"} if portrait is not None else set())
    for name in sorted(names):
        shutil.copy2(staging / "sprites" / (name + ".png"), destination / (name + ".png"))
        manifest["sprites"][name] = patch["sprites"][name]
    for key, value in patch.get("characters", {}).items():
        manifest["characters"][key] = value
    fd, temporary = tempfile.mkstemp(prefix="sprites-garcom-", suffix=".tmp", dir=destination)
    os.close(fd)
    try:
        write_json(Path(temporary), manifest, indent=1)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main(argv=None) -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("config", type=Path)
    parser.add_argument("--out", type=Path, default=ROOT / "build" / "visual-garcom")
    parser.add_argument("--install", action="store_true")
    args = parser.parse_args(argv)
    config = read_json(args.config)
    if config.get("version") != 1:
        raise ValueError("calibração exige version: 1")
    frames = []
    seen = set()
    for spec in config["sheets"]:
        group = (spec.get("view"), spec.get("carrying"))
        if group in seen:
            raise ValueError(f"folha repetida: {group}")
        seen.add(group)
        frames.extend(import_sheet(spec, args.config.resolve().parent))
    if not frames:
        raise ValueError("nenhuma folha fornecida")
    if args.install:
        validate_complete(frames)
    portrait = import_portrait(config["portrait"], args.config.resolve().parent) if "portrait" in config else None
    assets = frames + ([portrait] if portrait is not None else [])
    args.out.mkdir(parents=True, exist_ok=True)
    sprite_dir = args.out / "sprites"
    sprite_dir.mkdir(exist_ok=True)
    for frame in assets:
        frame["image"].save(sprite_dir / (frame["name"] + ".png"))
    write_json(args.out / "manifest_patch.json", manifest_patch(frames, portrait))
    write_json(args.out / "proveniencia.json", {frame["name"]: frame["source"] for frame in assets})
    qa_images(frames, args.out)
    if args.install:
        install(frames, args.out, portrait=portrait)
    print(f"{len(frames)} poses validadas, retrato: {portrait is not None}, em {args.out.resolve()}; instalado: {args.install}")


if __name__ == "__main__":
    main()
