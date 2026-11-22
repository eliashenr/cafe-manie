"""Importa clientes de folhas RGBA 4x6, preservando poses, alfa e registro.

Uso: python tools/ia/importar_clientes_codex.py calibracao.json --out build/visual-clientes
     Acrescente --install somente depois da revisão do staging.
     python tools/ia/importar_clientes_codex.py --analyze cliente_01.png

Ordem: 0..7 andar de frente, 8..15 andar de costas, 16/17 parados frente/costas,
18..21 sentado feliz/esperando/bravo/comendo, 22/23 sentado de costas r1/r2.

Config version:1, customers:[{look:"cliente_01", file:"cliente_01.png",
height_world:96, groups:{...}}]. file é relativo ao JSON; cells, opcional, contém
24 retângulos [x,y,w,h] na folha. Os grupos obrigatórios são frente, costas,
sentado_frente, sentado_costas_r1 e sentado_costas_r2.

frente/costas: anchor:[x,y] em pixels da célula original. reference_height_px
é a altura do personagem PARADO; frente usa a célula16 se omitida. Costas
herda a referência frontal, a menos que declare uma referência própria.

Sentados: anchor explícita OU seat_point_px:[x,y] no apoio sob os glúteos.
O ponto de apoio corresponde a seat_target_world relativo ao VÉRTICE FRONTAL
do piso da cadeira, nunca aos pés. Há padrões derivados do modelo existente.
A escala sentada herda a frontal; scale_multiplier permite uma calibração
explícita por grupo (por exemplo, comparando a largura da cabeça), sem ajustar
automaticamente a escala pela altura de cada pose sentada.

Todos os grupos aceitam file para uma folha alternativa RGBA, relativo ao JSON,
e cells para substituir o mapeamento do cliente. Cada mapeamento mantém os 24
índices; entradas que o grupo não usa podem repetir um retângulo válido. Assim,
os três grupos sentados podem usar uma folha própria 3x2 com seis poses maiores,
preservando os 18 quadros em pé. A referência frontal continua definindo a escala
herdada pelas poses sentadas, ajustável pelo scale_multiplier explícito do grupo.

Todos os grupos aceitam mirror e scale_multiplier; frames é uma lista opcional
de 24 objetos com registration:[dx,dy], uma correção explícita por célula. Não
há nivelamento automático dos pés. --analyze só informa caixas de alfa e a faixa
superior de cada figura; essa faixa NÃO é uma segmentação semântica da cabeça.

Sem --install, nada em art/sprites é alterado. A instalação aceita apenas os
24 nomes completos de cada cliente_01..12 solicitado; preserva garçom, móveis,
eventos e todo o resto do manifesto. Um único processo deve instalar por vez.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shutil
import sys
import tempfile

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from importar_garcom_codex import measured_box, pair, pixel_hash, read_json, write_json


ROOT = Path(__file__).resolve().parents[2]
DENSITY = 4
SUFFIXES = tuple(f"frente_passo_{i}" for i in range(8)) + tuple(f"costas_passo_{i}" for i in range(8)) + (
    "frente_em_pe", "costas_em_pe", "sentado_feliz", "sentado_esperando",
    "sentado_bravo", "sentado_comendo", "sentado_costas_r1", "sentado_costas_r2")
GROUPS = {"frente": tuple(range(8)) + (16,), "costas": tuple(range(8, 16)) + (17,),
          "sentado_frente": (18, 19, 20, 21), "sentado_costas_r1": (22,), "sentado_costas_r2": (23,)}
# Mesmo contato do gerador 3D: SEAT_CENTER=(-.5,.5), z=.385, recuo=.1.
# Projeção: x=64*(X+Y), y=32*(X-Y)-z*(128/sqrt(2))*sin(60°).
SEAT_TARGETS = {"sentado_frente": (-6.4, -65.378),
                "sentado_costas_r1": (6.4, -58.978), "sentado_costas_r2": (-6.4, -58.978)}


def expected_names(look: str) -> set[str]:
    if not isinstance(look, str) or re.fullmatch(r"cliente_(0[1-9]|1[0-2])", look) is None:
        raise ValueError("look precisa ser cliente_01 a cliente_12")
    return {f"{look}_{suffix}" for suffix in SUFFIXES}


def positive(value, label: str) -> float:
    value = float(value)
    if not math.isfinite(value) or value <= 0:
        raise ValueError(f"{label} precisa ser positivo e finito")
    return value


def rectangles(size, explicit=None):
    width, height = size
    if explicit is None:
        xs = [round(i * width / 4) for i in range(5)]
        ys = [round(i * height / 6) for i in range(7)]
        return [(xs[c], ys[r], xs[c + 1], ys[r + 1]) for r in range(6) for c in range(4)]
    if len(explicit) != 24:
        raise ValueError("cells precisa de 24 retângulos [x,y,w,h]")
    result = []
    for rect in explicit:
        if len(rect) != 4 or any(int(v) != v for v in rect):
            raise ValueError("cells exige coordenadas inteiras")
        x, y, w, h = map(int, rect)
        if x < 0 or y < 0 or w <= 0 or h <= 0 or x + w > width or y + h > height:
            raise ValueError(f"célula fora da folha: {rect}")
        result.append((x, y, x + w, y + h))
    return result


def load_sheet(path: Path, explicit=None):
    with Image.open(path) as raw:
        if raw.mode != "RGBA" or raw.getchannel("A").getextrema()[0] != 0:
            raise ValueError(f"{path.name}: exige RGBA com transparência nativa")
        sheet = raw.copy()
    rects = rectangles(sheet.size, explicit)
    cells = [sheet.crop(rect) for rect in rects]
    boxes = []
    for index, cell in enumerate(cells):
        try:
            boxes.append(measured_box(cell))
        except ValueError as error:
            raise ValueError(f"{path.name}, célula {index} ({SUFFIXES[index]}): {error}") from error
    return sheet, rects, cells, boxes


def analyze(path: Path, explicit=None) -> dict:
    sheet, rects, cells, boxes = load_sheet(path, explicit)
    band_height = max(1, round((boxes[16][3] - boxes[16][1]) * 0.22))
    report = {"file": str(path.resolve()), "size": list(sheet.size), "grid": [4, 6],
              "upper_band_height_px": band_height,
              "note": "Faixa superior de alfa; mede consistência, não identifica a cabeça automaticamente.", "frames": []}
    for index, (cell, box) in enumerate(zip(cells, boxes)):
        band = cell.getchannel("A").crop((0, box[1], cell.width, min(cell.height, box[1] + band_height)))
        extent = band.point(lambda a: 255 if a > 8 else 0).getbbox()
        upper = [extent[0], extent[1] + box[1], extent[2], extent[3] + box[1]] if extent else None
        report["frames"].append({"index": index, "pose": SUFFIXES[index], "cell": list(rects[index]),
                                 "bbox": list(box), "height_px": box[3] - box[1],
                                 "upper_band_box": upper, "upper_band_width_px": extent[2] - extent[0] if extent else 0})
    return report


def import_customer(spec: dict, source_dir: Path) -> list[dict]:
    look = spec.get("look")
    expected_names(look)
    settings = spec["groups"]
    if set(settings) != set(GROUPS):
        raise ValueError(f"{look}: groups exige exatamente {list(GROUPS)}")
    sources = {}

    def group_source(group_spec):
        path = (source_dir / group_spec.get("file", spec["file"])).resolve()
        mapping = group_spec.get("cells", spec.get("cells"))
        key = (path, json.dumps(mapping, separators=(",", ":")))
        if key not in sources:
            _, rects, cells, boxes = load_sheet(path, mapping)
            sources[key] = (rects, cells, boxes, hashlib.sha256(path.read_bytes()).hexdigest())
        return path, sources[key]

    _, (_, _, front_boxes, _) = group_source(settings["frente"])
    height = positive(spec.get("height_world", 96), "height_world")
    front_ref = positive(settings["frente"].get("reference_height_px", front_boxes[16][3] - front_boxes[16][1]), "referência frontal")
    front_multiplier = positive(settings["frente"].get("scale_multiplier", 1), "scale_multiplier frontal")
    frame_settings = spec.get("frames", [{} for _ in range(24)])
    if len(frame_settings) != 24:
        raise ValueError("frames precisa de 24 objetos")
    result = []
    for group, indices in GROUPS.items():
        group_spec = settings[group]
        path, (rects, cells, boxes, source_hash) = group_source(group_spec)
        seated = group.startswith("sentado_")
        if seated and "reference_height_px" in group_spec:
            raise ValueError("sentados herdam a escala frontal; use scale_multiplier explícito, não altura sentada")
        reference = positive(group_spec.get("reference_height_px", front_ref), "reference_height_px")
        relative_multiplier = 1.0 if group == "frente" else positive(group_spec.get("scale_multiplier", 1), "scale_multiplier")
        factor = height * DENSITY / reference * front_multiplier * relative_multiplier
        mirror = group_spec.get("mirror", False)
        if not isinstance(mirror, bool):
            raise ValueError("mirror precisa ser booleano")
        has_anchor, has_seat = "anchor" in group_spec, "seat_point_px" in group_spec
        if has_anchor == has_seat or (has_seat and not seated):
            raise ValueError(f"{look}/{group}: declare anchor OU, para sentados, seat_point_px")
        anchor = pair(group_spec["anchor"], "anchor") if has_anchor else None
        seat = pair(group_spec["seat_point_px"], "seat_point_px") if has_seat else None
        target = pair(group_spec.get("seat_target_world", SEAT_TARGETS.get(group)), "seat_target_world") if has_seat else None
        canvas_size = (max(cells[i].width for i in indices), max(cells[i].height for i in indices))
        scaled_size = tuple(max(1, round(n * factor)) for n in canvas_size)
        if max(scaled_size) > 8192:
            raise ValueError("escala produziria uma célula acima de 8192 px; confira a calibração")
        sx, sy = scaled_size[0] / canvas_size[0], scaled_size[1] / canvas_size[1]
        for index in indices:
            reg = pair(frame_settings[index].get("registration", [0, 0]), "registration")
            canvas = Image.new("RGBA", canvas_size)
            canvas.paste(cells[index], (0, 0))
            scaled = canvas.resize(scaled_size, Image.Resampling.LANCZOS)
            if anchor is not None:
                ax, ay = (anchor[0] - reg[0]) * sx, (anchor[1] - reg[1]) * sy
                if mirror:
                    ax = scaled_size[0] - ax
            else:
                # O alvo permanece nas coordenadas da cadeira após o espelho.
                point_x = scaled_size[0] - seat[0] * sx if mirror else seat[0] * sx
                ax = point_x - target[0] * DENSITY - reg[0] * sx * (-1 if mirror else 1)
                ay = seat[1] * sy - target[1] * DENSITY - reg[1] * sy
            if mirror:
                scaled = scaled.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            crop = scaled.getchannel("A").getbbox()
            if crop is None:
                raise ValueError(f"{look}/{index}: quadro vazio após redução")
            entry = {"anchor": [round(ax - crop[0], 3), round(ay - crop[1], 3)], "density": DENSITY,
                     "authored_motion": True, "external_shadow": not seated}
            provenance = {"file": str(path), "sha256": source_hash, "cell": list(rects[index]),
                          "bbox": list(boxes[index]), "group": group, "reference_height_px": reference,
                          "height_world": height, "scale": [sx, sy], "mirror": mirror, "registration": list(reg)}
            if seat is not None:
                provenance.update(seat_point_px=list(seat), seat_target_world=list(target))
            result.append({"name": f"{look}_{SUFFIXES[index]}", "look": look, "index": index,
                           "group": group, "image": scaled.crop(crop), "entry": entry, "source": provenance})
    result.sort(key=lambda frame: frame["index"])
    validate(result)
    return result


def validate(frames: list[dict]) -> set[str]:
    looks = {frame["look"] for frame in frames}
    if not looks:
        raise ValueError("nenhum cliente fornecido")
    for look in looks:
        group = [frame for frame in frames if frame["look"] == look]
        if len(group) != 24 or {frame["name"] for frame in group} != expected_names(look):
            raise ValueError(f"{look}: exige as 24 poses completas, sem nomes extras ou repetidos")
        for indices in (range(8), range(8, 16)):
            hashes = [pixel_hash(frame["image"]) for frame in group if frame["index"] in indices]
            if len(hashes) != 8 or len(set(hashes)) != 8:
                raise ValueError(f"{look}: cada direção exige oito passos distintos")
    return looks


def contact_sheet(frames: list[dict], path: Path) -> None:
    left = max(frame["entry"]["anchor"][0] for frame in frames)
    right = max(frame["image"].width - frame["entry"]["anchor"][0] for frame in frames)
    above = max(frame["entry"]["anchor"][1] for frame in frames)
    below = max(frame["image"].height - frame["entry"]["anchor"][1] for frame in frames)
    tile = (max(256, math.ceil(left + right + 32)), max(448, math.ceil(above + below + 56)))
    origin = (math.ceil(left + 16), math.ceil(above + 28))
    board = Image.new("RGB", (tile[0] * 4, tile[1] * 6), (66, 59, 52))
    draw = ImageDraw.Draw(board)
    for frame in frames:
        index = frame["index"]
        x, y = (index % 4) * tile[0], (index // 4) * tile[1]
        ax, ay = frame["entry"]["anchor"]
        gx, gy = x + origin[0], y + origin[1]
        board.paste(frame["image"], (round(gx - ax), round(gy - ay)), frame["image"])
        draw.text((x + 5, y + 5), f"{index}: {SUFFIXES[index]}", fill=(245, 239, 222))
        draw.line((gx - 6, gy, gx + 6, gy), fill=(255, 90, 90), width=2)
        draw.line((gx, gy - 6, gx, gy + 6), fill=(255, 90, 90), width=2)
        if "seat_target_world" in frame["source"]:
            tx, ty = frame["source"]["seat_target_world"]
            cx, cy = gx + tx * DENSITY, gy + ty * DENSITY
            draw.line((cx - 8, cy, cx + 8, cy), fill=(80, 210, 255), width=2)
    path.parent.mkdir(parents=True, exist_ok=True)
    board.save(path)


def install(frames: list[dict], staging: Path, root: Path = ROOT) -> None:
    looks = validate(frames)
    path = root / "art" / "sprites" / "sprites.json"
    manifest = read_json(path)
    registered = set(manifest.get("characters", {}).get("customers", []))
    if not looks <= registered:
        raise ValueError(f"clientes não registrados no jogo: {sorted(looks - registered)}")
    # Valida o staging inteiro antes da primeira cópia; não instala PNG antigo por engano.
    for frame in frames:
        with Image.open(staging / "sprites" / (frame["name"] + ".png")) as actual:
            if actual.mode != "RGBA" or pixel_hash(actual) != pixel_hash(frame["image"]):
                raise ValueError(f"staging diverge da importação: {frame['name']}")
    for frame in frames:
        shutil.copy2(staging / "sprites" / (frame["name"] + ".png"), path.parent / (frame["name"] + ".png"))
        manifest["sprites"][frame["name"]] = frame["entry"]
    fd, temporary = tempfile.mkstemp(prefix="sprites-clientes-", suffix=".tmp", dir=path.parent)
    os.close(fd)
    try:
        write_json(Path(temporary), manifest, indent=1)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main(argv=None) -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("config", type=Path, nargs="?")
    parser.add_argument("--analyze", type=Path)
    parser.add_argument("--out", type=Path, default=ROOT / "build" / "visual-clientes")
    parser.add_argument("--install", action="store_true")
    args = parser.parse_args(argv)
    if args.analyze:
        if args.config or args.install:
            parser.error("--analyze não aceita config nem --install")
        print(json.dumps(analyze(args.analyze), ensure_ascii=False, indent=2))
        return
    if args.config is None:
        parser.error("informe config ou --analyze")
    config = read_json(args.config)
    if config.get("version") != 1:
        raise ValueError("calibração exige version:1")
    frames, seen = [], set()
    for spec in config["customers"]:
        if spec["look"] in seen:
            raise ValueError(f"cliente repetido: {spec['look']}")
        seen.add(spec["look"])
        frames.extend(import_customer(spec, args.config.resolve().parent))
    validate(frames)
    sprite_dir = args.out / "sprites"
    sprite_dir.mkdir(parents=True, exist_ok=True)
    for frame in frames:
        frame["image"].save(sprite_dir / (frame["name"] + ".png"))
    write_json(args.out / "manifest_patch.json", {"sprites": {frame["name"]: frame["entry"] for frame in frames}})
    write_json(args.out / "proveniencia.json", {frame["name"]: frame["source"] for frame in frames})
    for look in sorted(seen):
        contact_sheet([frame for frame in frames if frame["look"] == look], args.out / "contatos" / (look + ".png"))
    if args.install:
        install(frames, args.out)
    print(f"{len(frames)} poses de {len(seen)} clientes validadas; instalado: {args.install}; staging: {args.out.resolve()}")


if __name__ == "__main__":
    main()
