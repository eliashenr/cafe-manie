"""Pisos, paredes, itens de parede, portas e terraço na linguagem da referência A (DT-096): cada item mantém o nome, a coleção
e o caráter, com material novo e a luz quente do salão.

Uso (na pasta do projeto):
    C:/Blender/blender-5.2.3-windows-x64/blender.exe -b -P tools/render3d/superficies_a3d.py -- [grupos ou nomes...] [rascunho] [prova]

Grupos: pisos, paredes, itens, portas, terraco (sem nada, faz todos). Também aceita nomes de sprite. "prova" faz só um lado
das paredes, dos itens e das portas, e só a primeira variação dos pisos.

Grava em art/sprites com os mesmos nomes de sprite, então os ids, os preços e o save não mudam. Os itens da amostra (DT-091)
ficam em amostra_a3d.py e não passam por aqui: piso bege, assoalho, parede creme, tijolinho, janela, quadros, prateleira,
relógio, arandela e a porta clássica.

As texturas são pintadas com numpy, com período exato de uma célula: o ruído é filtrado na frequência e, por isso, dá a volta
na borda. Assim o piso vizinho continua o desenho sem emenda, inclusive o de pedra e o de granilite. Nos pisos em que a
variação muda a textura, o que cruza a borda da célula é igual em todas as variações.
"""
import json
import math
import os
import sys

import bpy
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cena3d  # noqa: E402
from cena3d import aim_camera  # noqa: E402
import moveis3d as M  # noqa: E402
from moveis3d import box, cylinder, emission, solid, sphere, tube  # noqa: E402
import enfeites3d as E  # noqa: E402
import superficies3d as S  # noqa: E402
import amostra_a3d as A  # noqa: E402
import assentos_a3d as AS  # noqa: E402
import enfeites_a3d as EA  # noqa: E402
from amostra_a3d import brushed_steel, cast_iron, rich_wood  # noqa: E402

WORK = os.path.join(cena3d.ROOT, "tools", "render3d", "out_superficies_a")
WALL_Z = S.WALL_Z
BLEED = S.BLEED
WIDTH = 1.0 + 2 * BLEED
SIZE = 512
WALL_H = int(round(SIZE * WALL_Z))
# Itens que a amostra já refez: não são fotografados aqui.
SAMPLE_FLOORS = {"floor_beige", "floor_wood"}
SAMPLE_WALLS = {"wall_cream", "wall_brick"}
SAMPLE_ITEMS = {"arandela", "janela", "quadro_cupcake", "quadro_paisagem", "prateleira", "relogio"}


# --- Pintura das texturas -------------------------------------------------------------------------------------

def rgb(color):
    color = color.lstrip("#")
    return np.array([int(color[i:i + 2], 16) / 255.0 for i in (0, 2, 4)], dtype=np.float32)


def coords(w=SIZE, h=SIZE):
    return np.meshgrid((np.arange(w, dtype=np.float32) + 0.5) / w, (np.arange(h, dtype=np.float32) + 0.5) / h)


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def blend(a, b, t):
    """De [a] para [b]: cores (um array de cores ou uma cor só) por uma máscara."""
    t = t[..., None]
    return a * (1.0 - t) + b * t


def noise(seed, w=SIZE, h=SIZE, beta=1.8, along_u=1.0, along_v=1.0, low=1.0):
    """Ruído de 0 a 1, com período exato no tamanho da imagem. [along_u] > 1 estica o desenho na direção de U (o veio)."""
    rng = np.random.default_rng(seed)
    spectrum = np.fft.fft2(rng.standard_normal((h, w)))
    fy = np.fft.fftfreq(h) * h * along_v
    fx = np.fft.fftfreq(w) * w * along_u
    radius = np.sqrt(fy[:, None] ** 2 + fx[None, :] ** 2)
    radius[0, 0] = 1.0
    amp = np.where(radius < low, 0.0, radius ** (-beta))
    amp[0, 0] = 0.0
    out = np.fft.ifft2(spectrum * amp).real
    lo, hi = np.percentile(out, (1.0, 99.0))
    return np.clip((out - lo) / (hi - lo), 0.0, 1.0).astype(np.float32)


def table(seed, size, lo=-1.0, hi=1.0):
    return np.random.default_rng(seed).uniform(lo, hi, size).astype(np.float32)


def layout(nx, ny, offset=0.0, joint=0.008, w=SIZE, h=SIZE):
    """Grade de lajotas com a junta nas bordas da célula: devolve o número da peça, a máscara (0 na junta), o relevo da
    quina e a posição dentro da peça (de 0 a 1)."""
    u, v = coords(w, h)
    row = np.floor(v * ny).astype(np.int32)
    x = (u + offset * (row % 2) / nx) % 1.0
    col = np.floor(x * nx).astype(np.int32)
    fu, fv = x * nx - col, v * ny - row
    dist = np.minimum(np.minimum(fu, 1.0 - fu) / nx, np.minimum(fv, 1.0 - fv) * (h / w) / ny if h != w else np.minimum(fv, 1.0 - fv) / ny)
    return dict(id=col + row * nx, count=nx * ny, col=col, row=row, fu=fu, fv=fv, dist=dist,
                mask=smooth(joint * 0.6, joint * 1.15, dist), relief=smooth(joint * 0.6, joint * 3.2, dist))


def voronoi(n, seed, jitter=0.85, w=SIZE, h=SIZE):
    """Pedras: o número da pedra, a distância até a borda (aproximada, em células) e o centro de cada uma."""
    rng = np.random.default_rng(seed)
    jx, jy = rng.uniform(0.5 - jitter / 2, 0.5 + jitter / 2, (2, n, n))
    u, v = coords(w, h)
    x, y = u * n, v * (n * h / w)
    rows = int(round(n * h / w))
    cx, cy = np.floor(x).astype(np.int32), np.floor(y).astype(np.int32)
    first = np.full(x.shape, 1e9, dtype=np.float32)
    second = np.full(x.shape, 1e9, dtype=np.float32)
    ids = np.zeros(x.shape, dtype=np.int32)
    center_x, center_y = np.zeros(x.shape, dtype=np.float32), np.zeros(x.shape, dtype=np.float32)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            gx, gy = cx + dx, cy + dy
            wx, wy = gx % n, gy % rows
            px, py = gx + jx[wy % n, wx], gy + jy[wy % n, wx]
            dist = np.sqrt((x - px) ** 2 + (y - py) ** 2)
            closer = dist < first
            second = np.where(closer, first, np.minimum(second, dist))
            first = np.where(closer, dist, first)
            ids = np.where(closer, wx + wy * n, ids)
            center_x = np.where(closer, px, center_x)
            center_y = np.where(closer, py, center_y)
    return dict(id=ids, count=n * rows, edge=(second - first) / n, first=first / n, cx=(center_x / n) % 1.0, cy=(center_y * w / (n * h)) % 1.0)


def tone(color, ids, seed, amount, count):
    """Cada peça com o seu tom: um pouco mais clara ou mais escura."""
    values = table(seed, count, -amount, amount)[ids]
    return np.clip(color * (1.0 + values[..., None]), 0.0, 1.0)


def stained(color, seed, amount=0.1, w=SIZE, h=SIZE, beta=1.7):
    """Manchas largas, do uso e do material."""
    values = noise(seed, w, h, beta) - 0.5
    return np.clip(color * (1.0 + values[..., None] * 2.0 * amount), 0.0, 1.0)


def fill(color, w=SIZE, h=SIZE):
    return np.broadcast_to(rgb(color), (h, w, 3)).copy()


# --- Materiais a partir das texturas ---------------------------------------------------------------------------

def _image(name, pixels, is_color):
    h, w = pixels.shape[:2]
    image = bpy.data.images.new(name, w, h, alpha=False)
    # O espaço de cor vem antes dos pixels: mudar depois faz o Blender recriar a imagem vazia (tudo preto).
    image.colorspace_settings.name = "sRGB" if is_color else "Non-Color"
    rgba = np.ones((h, w, 4), dtype=np.float32)
    if pixels.ndim == 2:
        rgba[..., 0] = rgba[..., 1] = rgba[..., 2] = pixels
    else:
        rgba[..., :3] = pixels
    image.pixels.foreach_set(rgba.ravel())
    image.update()
    image.pack()
    return image


def painted(key, build, plane="XY", rough=0.5, coat=0.0, bump=0.4, metal=0.0, distance=0.012, emit=0.0, specular=None):
    """Material com a textura pintada por [build], que devolve cor e relevo, e também pode devolver a rugosidade e a luz
    própria. As coordenadas são as do objeto: as faces têm de vir com a origem no canto (ver face_panel e floor_panel)."""
    full_key = ("painted", key)
    if full_key in M._materials:
        return M._materials[full_key]
    result = build()
    color, height = result[0], result[1]
    roughness = result[2] if len(result) > 2 else None
    glow = result[3] if len(result) > 3 else None
    mat, nodes, links, bsdf = M._principled("Pintado_" + str(key))
    source = nodes.new("ShaderNodeTexCoord")
    sep = nodes.new("ShaderNodeSeparateXYZ")
    links.new(source.outputs["Object"], sep.inputs["Vector"])
    comb = nodes.new("ShaderNodeCombineXYZ")
    links.new(sep.outputs["X"], comb.inputs["X"])
    if plane == "XZ_UNIT":          # uma tela: a imagem inteira numa face de 1 por 1, reduzida pela escala do objeto
        links.new(sep.outputs["Z"], comb.inputs["Y"])
    elif plane == "XZ":
        scale = nodes.new("ShaderNodeMath")
        scale.operation = "DIVIDE"
        scale.inputs[1].default_value = WALL_Z
        links.new(sep.outputs["Z"], scale.inputs[0])
        links.new(scale.outputs[0], comb.inputs["Y"])
    else:
        links.new(sep.outputs["Y"], comb.inputs["Y"])

    def texture(pixels, is_color, name):
        node = nodes.new("ShaderNodeTexImage")
        node.image = _image(f"{name}_{key}", pixels, is_color)
        node.extension = "REPEAT"
        node.interpolation = "Linear"
        links.new(comb.outputs["Vector"], node.inputs["Vector"])
        return node.outputs["Color"]

    links.new(texture(color, True, "cor"), bsdf.inputs["Base Color"])
    relief = nodes.new("ShaderNodeBump")
    relief.inputs["Strength"].default_value = bump
    relief.inputs["Distance"].default_value = distance
    links.new(texture(height, False, "relevo"), relief.inputs["Height"])
    links.new(relief.outputs["Normal"], bsdf.inputs["Normal"])
    if roughness is not None:
        links.new(texture(roughness, False, "aspero"), bsdf.inputs["Roughness"])
    else:
        bsdf.inputs["Roughness"].default_value = rough
    if glow is not None:
        links.new(texture(glow, True, "luz"), bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = emit
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Coat Weight"].default_value = coat
    bsdf.inputs["Coat Roughness"].default_value = 0.2
    if specular is not None:
        bsdf.inputs["Specular IOR Level"].default_value = specular
    M._materials[full_key] = mat
    return mat


def face_panel(x0, x1, z0, z1, y, mat):
    """Uma face de parede de frente para -Y, com a origem do objeto no canto: a textura cai no lugar certo."""
    mesh = bpy.data.meshes.new("Face")
    mesh.from_pydata([(x0, y, z0), (x1, y, z0), (x1, y, z1), (x0, y, z1)], [], [(0, 1, 2, 3)])
    mesh.update()
    obj = bpy.data.objects.new("Face", mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


# --- Pisos: peças ---------------------------------------------------------------------------------------------

def planks_tex(base, rows, seed, variant=0, gap="#1c0f08", amount=0.13, grain=0.3, knots=0, scale=1.0, weathered=0.0, nails=False):
    """Tábuas ao longo de U. Cada fileira tem duas emendas: a peça que cruza a borda da célula é igual em todas as variações,
    então o vizinho a continua, e só a peça de dentro muda de tom e de veio."""
    u, v = coords()
    row = np.floor(v * rows).astype(np.int32)
    starts = (table(seed + 1, rows, 0.08, 0.42))[row]
    rel = (u - starts) % 1.0
    inner = rel < 0.5
    dist_u = np.minimum(np.minimum(rel, 1.0 - rel), np.abs(rel - 0.5))
    fv = v * rows - row
    dist_v = np.minimum(fv, 1.0 - fv) / rows
    outer_tone = table(seed + 2, rows, -amount, amount)[row]
    inner_tone = table(seed + 3 + variant * 17, rows, -amount, amount)[row]
    shade = np.where(inner, inner_tone, outer_tone)
    # O veio: o mesmo ruído comprido, deslocado em cada fileira para as tábuas não continuarem umas nas outras.
    lines = noise(seed + 4, beta=1.25, along_u=26.0)
    lines2 = noise(seed + 5 + variant * 13, beta=1.25, along_u=26.0)
    shift_u = (table(seed + 6, rows, 0.0, SIZE)[row]).astype(np.int32)
    shift_v = (table(seed + 7, rows, 0.0, SIZE)[row]).astype(np.int32)
    yy, xx = np.indices(lines.shape)
    outer_grain = lines[(yy + shift_v) % SIZE, (xx + shift_u) % SIZE]
    inner_grain = lines2[(yy + shift_v) % SIZE, (xx + shift_u) % SIZE]
    fibers = np.where(inner, inner_grain, outer_grain)
    color = rgb(base) * (1.0 + (shade + (fibers - 0.5) * grain * 2.0))[..., None] * scale
    if knots:
        spots = voronoi(max(2, knots), seed + 8 + variant, 0.9)
        keep = table(seed + 9, spots["count"], 0.0, 1.0)[spots["id"]] > 0.5
        knot = (1.0 - smooth(0.012, 0.045, spots["first"])) * keep * inner
        color = blend(color, rgb(base) * 0.42, knot)
        fibers = fibers - knot * 0.4
    if weathered > 0.0:
        wear = smooth(0.55, 0.8, noise(seed + 11 + variant, beta=1.5))
        color = blend(color, np.clip(rgb(base) * 1.25 + 0.05, 0, 1), wear * weathered)
    joint = 0.0035
    mask = smooth(joint * 0.5, joint * 1.2, np.minimum(dist_u, dist_v))
    color = blend(np.broadcast_to(rgb(gap), color.shape), np.clip(color, 0.0, 1.0), mask)
    height = smooth(joint * 0.5, joint * 3.0, np.minimum(dist_u, dist_v)) * 0.8 + fibers * 0.2
    if nails:
        spots = voronoi(6, seed + 12, 0.7)
        nail = 1.0 - smooth(0.004, 0.008, spots["first"])
        color = blend(color, rgb("#1a1512"), nail)
    return color, height, np.clip(0.42 + (fibers - 0.5) * 0.25, 0.0, 1.0)


def strips_color(base, dark, value):
    """O veio numa peça: do tom escuro ao claro."""
    return blend(np.broadcast_to(rgb(dark), value.shape + (3,)), rgb(base), value)


def herringbone_tex(a, b, gap, k=4, seed=3):
    """Espinha de peixe de verdade: cada peça tem [k] larguras de comprimento, e o desenho se repete em 2k larguras."""
    cells = 2 * k
    u, v = coords()
    gx, gy = u * cells, v * cells
    i, j = np.floor(gx).astype(np.int32), np.floor(gy).astype(np.int32)
    fx, fy = gx - i, gy - j
    t = (i + j) % cells
    flat = t < k
    # Número da peça: início dela e a fileira ou coluna.
    pid = np.where(flat, ((i - t) % cells) + j * cells, ((j - (t - k)) % cells) + i * cells + cells * cells)
    at_start = np.where(flat, (t == 0) * fx, (t == k) * fy) + np.where(flat, t != 0, t != k)
    at_end = np.where(flat, (t == k - 1) * (1.0 - fx), (t == 2 * k - 1) * (1.0 - fy)) + np.where(flat, t != k - 1, t != 2 * k - 1)
    across = np.where(flat, np.minimum(fy, 1.0 - fy), np.minimum(fx, 1.0 - fx))
    dist = np.minimum(np.minimum(at_start, at_end), across) / cells
    tones = table(seed, 2 * cells * cells, -0.14, 0.14)[pid]
    along = noise(seed + 1, beta=1.2, along_u=20.0)
    across_grain = noise(seed + 2, beta=1.2, along_v=20.0)
    fibers = np.where(flat, along, across_grain)
    color = strips_color(a, b, fibers) * (1.0 + tones[..., None])
    mask = smooth(0.002, 0.0045, dist)
    color = blend(np.broadcast_to(rgb(gap), color.shape), np.clip(color, 0, 1), mask)
    return color, smooth(0.002, 0.009, dist) * 0.85 + fibers * 0.15, np.clip(0.34 + (fibers - 0.5) * 0.2, 0, 1)


def basket_tex(a, b, gap, blocks=4, slats=3, seed=5):
    """Parquê em cesto: quadrados de tábuas, um deitado, outro em pé."""
    u, v = coords()
    bx, by = np.floor(u * blocks).astype(np.int32), np.floor(v * blocks).astype(np.int32)
    fx, fy = u * blocks - bx, v * blocks - by
    flat = (bx + by) % 2 == 0
    across = np.where(flat, fy, fx) * slats
    index = np.floor(across).astype(np.int32)
    part = across - index
    dist_slat = np.minimum(part, 1.0 - part) / slats / blocks
    dist_block = np.minimum(np.minimum(fx, 1.0 - fx), np.minimum(fy, 1.0 - fy)) / blocks
    dist = np.minimum(dist_slat, dist_block)
    pid = (bx + by * blocks) * slats + index
    tones = table(seed, blocks * blocks * slats, -0.16, 0.16)[pid]
    fibers = np.where(flat, noise(seed + 1, beta=1.2, along_u=20.0), noise(seed + 2, beta=1.2, along_v=20.0))
    color = strips_color(a, b, fibers) * (1.0 + tones[..., None])
    color = blend(np.broadcast_to(rgb(gap), color.shape), np.clip(color, 0, 1), smooth(0.0015, 0.004, dist))
    return color, smooth(0.0015, 0.008, dist) * 0.85 + fibers * 0.15, np.clip(0.32 + (fibers - 0.5) * 0.2, 0, 1)


def chevron_tex(a, b, gap, columns=2, rows=4, seed=7):
    """Chevron: tábuas em V com a emenda em meia-esquadria, alternando as duas cores."""
    u, v = coords()
    cu = u * columns
    col = np.floor(cu)
    tri = np.abs((cu - col) - 0.5)                 # 0,5 na emenda, 0 no bico
    level = v * rows + tri * 2.0
    row = np.floor(level).astype(np.int32)
    part = level - row
    white = row % 2 == 0
    miter = np.minimum(np.minimum(cu - col, 1.0 - (cu - col)), tri) / columns
    dist = np.minimum(np.minimum(part, 1.0 - part) / rows * 0.8, miter)
    color = np.where(white[..., None], rgb(a), rgb(b)).astype(np.float32)
    color = np.clip(color * (1.0 + (noise(seed, beta=1.4, along_u=10.0) - 0.5)[..., None] * 0.16), 0, 1)
    color = blend(np.broadcast_to(rgb(gap), color.shape), color, smooth(0.0015, 0.004, dist))
    return color, smooth(0.0015, 0.008, dist), np.full(dist.shape, 0.2, dtype=np.float32)


def checker_tex(n, a, b, grout, seed=11, joint=0.005, amount=0.03):
    """Xadrez de lajotas: as duas cores se alternam de verdade, com o rejunte fundo e o tom variando um pouco."""
    grid = layout(n, n, joint=joint)
    white = (grid["col"] + grid["row"]) % 2 == 0
    color = np.where(white[..., None], rgb(a), rgb(b)).astype(np.float32)
    color = tone(color, grid["id"], seed, amount, grid["count"])
    color = stained(color, seed + 1, 0.05)
    color = blend(np.broadcast_to(rgb(grout), color.shape), color, grid["mask"])
    return color, grid["relief"], None


def tile_tex(n, a, b, grout, seed=13, joint=0.005, amount=0.08, stain=0.05, ny=None, offset=0.0, pits=0.0):
    """Lajotas ou azulejos de uma cor, cada peça com o seu tom."""
    grid = layout(n, ny or n, offset, joint)
    pick = table(seed, grid["count"], 0.0, 1.0)[grid["id"]] > 0.5
    color = np.where(pick[..., None], rgb(a), rgb(b)).astype(np.float32)
    color = tone(color, grid["id"], seed + 1, amount, grid["count"])
    color = stained(color, seed + 2, stain)
    height = grid["relief"].copy()
    if pits > 0.0:
        pit = smooth(0.72, 0.9, noise(seed + 3, beta=1.0))
        color = np.clip(color * (1.0 - pit[..., None] * pits), 0, 1)
        height = height - pit * 0.15
    color = blend(np.broadcast_to(rgb(grout), color.shape), color, grid["mask"])
    return color, height, None


def marble_tex(light, vein, grout, seed, cloud="#000000", cloud_amount=0.0, band=False):
    """Mármore polido: veios finos e tortos, do ruído passando pelo meio, numa placa por célula."""
    n1 = noise(seed, beta=2.2)
    n2 = noise(seed + 1, beta=2.0)
    v1 = np.abs(n1 - 0.5)
    v2 = np.abs(n2 - 0.5)
    fade = smooth(0.25, 0.7, noise(seed + 2, beta=2.0))
    lines = (1.0 - smooth(0.0, 0.012, v1)) * fade + (1.0 - smooth(0.0, 0.006, v2)) * 0.55
    color = fill(light)
    if cloud_amount > 0.0:
        soft = smooth(0.35, 0.7, noise(seed + 3, beta=2.3))
        color = blend(color, rgb(cloud), soft * cloud_amount)
    if band:                                   # ônix: faixas onduladas
        u, v = coords()
        wave = np.sin((u + v + (n1 - 0.5) * 0.9) * 2.0 * math.pi * 3.0) * 0.5 + 0.5
        color = blend(color, rgb(cloud), smooth(0.45, 0.85, wave) * 0.65)
    color = blend(color, rgb(vein), np.clip(lines, 0.0, 1.0))
    grid = layout(1, 1, joint=0.003)
    color = blend(np.broadcast_to(rgb(grout), color.shape), color, grid["mask"])
    return color, grid["relief"], None


def terrazzo_tex(base, chips, seed, variant=0, strip="#b98f45", sizes=((14, 0.2), (26, 0.3)), base_noise=0.04, fine=True):
    """Granilite: lascas angulosas de pedra em várias medidas, e o friso de latão na borda da célula."""
    color = stained(fill(base), seed, base_noise)
    height = np.zeros((SIZE, SIZE), dtype=np.float32)
    palette = np.array([rgb(c) for c in chips], dtype=np.float32)
    for index, (n, chance) in enumerate(sizes):
        cells = voronoi(n, seed + 10 + index * 7 + variant * 31, 0.9)
        keep = table(seed + 20 + index + variant, cells["count"], 0.0, 1.0)[cells["id"]] < chance
        pick = (table(seed + 30 + index, cells["count"], 0.0, len(chips) - 0.01)[cells["id"]]).astype(np.int32)
        mask = smooth(0.012 * 14 / n, 0.02 * 14 / n, cells["edge"]) * keep
        color = blend(color, palette[pick], mask)
    if fine:
        cells = voronoi(70, seed + 50, 0.9)
        keep = table(seed + 51, cells["count"], 0.0, 1.0)[cells["id"]] < 0.3
        pick = (table(seed + 52, cells["count"], 0.0, len(chips) - 0.01)[cells["id"]]).astype(np.int32)
        color = blend(color, palette[pick], smooth(0.001, 0.003, cells["edge"]) * keep * 0.8)
    grid = layout(1, 1, joint=0.0045)
    color = blend(np.broadcast_to(rgb(strip), color.shape), color, grid["mask"])
    return color, height + grid["relief"] * 0.3, None


def stone_tex(a, b, grout, seed, variant=0, n=5):
    """Pedra de fazenda: pedras irregulares e arredondadas. O desenho é o mesmo nas variações; só as de dentro mudam de tom."""
    cells = voronoi(n, seed, 0.8)
    margin = np.minimum(np.minimum(cells["cx"], 1.0 - cells["cx"]), np.minimum(cells["cy"], 1.0 - cells["cy"]))
    fixed = table(seed + 1, cells["count"], 0.0, 1.0)[cells["id"]]
    moved = table(seed + 2 + variant * 5, cells["count"], 0.0, 1.0)[cells["id"]]
    pick = np.where(margin > 0.22, moved, fixed)
    color = blend(np.broadcast_to(rgb(b), pick.shape + (3,)), rgb(a), pick)
    grain = noise(seed + 3, beta=1.3)
    color = np.clip(color * (0.86 + grain[..., None] * 0.28), 0, 1)
    mask = smooth(0.006, 0.014, cells["edge"])
    color = blend(np.broadcast_to(rgb(grout), color.shape), color, mask)
    height = smooth(0.006, 0.05, cells["edge"]) * 0.85 + grain * 0.15
    return color, height, np.full(mask.shape, 0.82, dtype=np.float32)


def circles_tex(colors, seed=17):
    """Vinil dos anos 70: círculos concêntricos em duas lajotas por célula, com o traço de quem imprimiu de verdade."""
    grid = layout(2, 2, joint=0.003)
    r = np.sqrt((grid["fu"] - 0.5) ** 2 + (grid["fv"] - 0.5) ** 2) * 2.0
    band = np.minimum((r * len(colors)).astype(np.int32), len(colors) - 1)
    palette = np.array([rgb(c) for c in colors], dtype=np.float32)
    color = stained(palette[band], seed, 0.06)
    ring = np.abs((r * len(colors)) % 1.0 - 0.5)
    color = np.clip(color * (0.94 + smooth(0.32, 0.5, ring)[..., None] * -0.1 + 0.1), 0, 1)
    color = blend(np.broadcast_to(rgb("#5a3218"), color.shape), color, grid["mask"])
    return color, grid["relief"], None


def carpet_tex(a, b, seed=19):
    """Carpete felpudo: fios curtos em relevo forte e os círculos do desenho bem discretos, de uma cor a outra."""
    fibers = noise(seed, beta=0.45)
    tufts = noise(seed + 1, beta=1.0)
    u, v = coords()
    r = np.sqrt(((u * 2) % 1.0 - 0.5) ** 2 + ((v * 2) % 1.0 - 0.5) ** 2) * 2.0
    rings = smooth(0.35, 0.65, np.abs((r * 3.0) % 1.0 - 0.5) * 2.0)
    color = blend(np.broadcast_to(rgb(a), rings.shape + (3,)), rgb(b), rings)
    color = np.clip(color * (0.72 + fibers[..., None] * 0.34 + tufts[..., None] * 0.18), 0, 1)
    return color, fibers * 0.7 + tufts * 0.3, np.full(fibers.shape, 0.96, dtype=np.float32)


def cabochon_tex(tile, dot, grout, seed=23, n=2):
    """Ladrilho de cantos cortados: o octógono claro e o quadradinho escuro onde os cantos se encontram."""
    grid = layout(n, n, joint=0.0035)
    corner = np.abs(grid["fu"] - 0.5) + np.abs(grid["fv"] - 0.5)
    dark = smooth(0.78, 0.785, corner)
    color = tone(np.broadcast_to(rgb(tile), corner.shape + (3,)).copy(), grid["id"], seed, 0.03, grid["count"])
    color = stained(color, seed + 1, 0.04)
    color = blend(color, rgb(dot), dark)
    dist = np.minimum(grid["dist"], np.abs(corner - 0.78) / n * 0.7)
    mask = smooth(0.002, 0.0045, dist)
    color = blend(np.broadcast_to(rgb(grout), color.shape), color, mask)
    return color, smooth(0.002, 0.012, dist), None


def hydraulic_tex(field, star, leaf, grout, seed=29, n=2):
    """Ladrilho hidráulico: estrela de oito pontas no centro, quartos de círculo nos cantos e o fosco do cimento colorido."""
    grid = layout(n, n, joint=0.0035)
    dx, dy = grid["fu"] - 0.5, grid["fv"] - 0.5
    angle = np.arctan2(dy, dx)
    r = np.sqrt(dx * dx + dy * dy)
    points = 0.2 + 0.1 * np.abs(np.cos(angle * 4.0))
    color = fill(field)
    color = blend(color, rgb(leaf), 1.0 - smooth(points, points + 0.008, r))
    color = blend(color, rgb(star), 1.0 - smooth(0.1, 0.108, r))
    corner = np.sqrt(np.minimum(grid["fu"], 1.0 - grid["fu"]) ** 2 + np.minimum(grid["fv"], 1.0 - grid["fv"]) ** 2)
    color = blend(color, rgb(star), 1.0 - smooth(0.2, 0.208, corner))
    color = blend(color, rgb(field), 1.0 - smooth(0.13, 0.138, corner))
    color = blend(color, rgb(leaf), 1.0 - smooth(0.07, 0.078, corner))
    color = stained(color, seed, 0.08)
    color = blend(np.broadcast_to(rgb(grout), color.shape), color, grid["mask"])
    return color, grid["relief"], np.full(r.shape, 0.5, dtype=np.float32)


def talavera_tex(seed=31, n=2):
    """Talavera: esmalte branco com a pintura à mão em azul e amarelo, e o traço levemente torto."""
    grid = layout(n, n, joint=0.0035)
    wobble = (noise(seed, beta=1.8) - 0.5) * 0.03
    dx, dy = grid["fu"] - 0.5, grid["fv"] - 0.5
    angle = np.arctan2(dy, dx)
    r = np.sqrt(dx * dx + dy * dy) + wobble
    petal = 0.17 + 0.13 * np.abs(np.cos(angle * 4.0)) ** 1.5
    color = fill("#efe7d4")
    color = blend(color, rgb("#21508f"), 1.0 - smooth(petal, petal + 0.01, r))
    color = blend(color, rgb("#efe7d4"), 1.0 - smooth(petal * 0.62, petal * 0.62 + 0.01, r))
    color = blend(color, rgb("#d9962c"), 1.0 - smooth(0.075, 0.085, r))
    corner = np.sqrt(np.minimum(grid["fu"], 1.0 - grid["fu"]) ** 2 + np.minimum(grid["fv"], 1.0 - grid["fv"]) ** 2) + wobble
    color = blend(color, rgb("#21508f"), 1.0 - smooth(0.19, 0.2, corner))
    color = blend(color, rgb("#d9962c"), 1.0 - smooth(0.11, 0.12, corner))
    color = stained(color, seed + 1, 0.04)
    color = blend(np.broadcast_to(rgb("#b6ad98"), color.shape), color, grid["mask"])
    return color, grid["relief"], None


def tatami_tex(turned):
    """Tatame: a palha trançada bem fina e a faixa de tecido escuro nos dois lados compridos. A vizinha vem deitada."""
    u, v = coords()
    across, along = (u, v) if turned else (v, u)
    lines = np.sin(across * 2.0 * math.pi * 44.0) * 0.5 + 0.5
    wiggle = noise(41, beta=1.0, along_u=1.0 if turned else 16.0, along_v=16.0 if turned else 1.0)
    straw = blend(np.broadcast_to(rgb("#a39a54"), lines.shape + (3,)), rgb("#c6bd78"), lines * 0.6 + wiggle * 0.4)
    straw = stained(straw, 42, 0.06)
    edge = np.minimum(across, 1.0 - across)
    ribbon = 1.0 - smooth(0.05, 0.054, edge)
    stitches = smooth(0.4, 0.6, np.abs(np.sin(along * 2.0 * math.pi * 16.0)))
    color = blend(straw, rgb("#20392c") * (0.9 + 0.1 * stitches[..., None]), ribbon)
    height = lines * (1.0 - ribbon) * 0.7 + smooth(0.05, 0.06, edge) * 0.3
    return color, height, np.full(lines.shape, 0.72, dtype=np.float32)


def waves_tex(seed=37):
    """Calçadão de Copacabana: pedrinhas portuguesas, cada uma inteira de uma cor, formando as ondas."""
    stones = voronoi(34, seed, 0.7)
    wave = np.sin(stones["cx"] * 2.0 * math.pi * 2.0) * 0.1
    level = (stones["cy"] * 2.0 + wave * 2.0) % 1.0
    dark = level > 0.5
    light_c, dark_c = rgb("#d8d2c4"), rgb("#2a2826")
    color = np.where(dark[..., None], dark_c, light_c).astype(np.float32)
    color = tone(color, stones["id"], seed + 1, 0.11, stones["count"])
    mask = smooth(0.0012, 0.0035, stones["edge"])
    color = blend(np.broadcast_to(rgb("#6f6a60"), color.shape), color, mask)
    return color, smooth(0.0012, 0.009, stones["edge"]), np.full(mask.shape, 0.74, dtype=np.float32)


def cement_tex(seed, variant):
    """Cimento queimado: nuvens de espátula, brilho irregular e a junta serrada na borda da célula."""
    clouds = noise(seed + variant, beta=2.3)
    trowel = noise(seed + 9 + variant, beta=1.3, along_u=5.0, along_v=1.0)
    color = blend(np.broadcast_to(rgb("#5f666e"), clouds.shape + (3,)), rgb("#8b9299"), clouds)
    color = np.clip(color * (0.94 + trowel[..., None] * 0.12), 0, 1)
    grid = layout(1, 1, joint=0.003)
    color = blend(np.broadcast_to(rgb("#3b3c3e"), color.shape), color, grid["mask"])
    return color, grid["relief"], np.clip(0.3 + trowel * 0.3, 0, 1)


def grid_glow_tex(tile, line, seed=43, n=2):
    """Grade neon: lajotas escuras e o rejunte aceso. O brilho sai pelo mapa de luz."""
    grid = layout(n, n, joint=0.006)
    color = stained(fill(tile), seed, 0.1)
    line_mask = 1.0 - grid["mask"]
    color = blend(color, rgb(line), line_mask)
    return color, grid["relief"], np.full(line_mask.shape, 0.26, dtype=np.float32), blend(np.zeros_like(color), rgb(line), line_mask)


def led_tex(a, b, seed=47):
    """Pista de LED: quatro placas de acrílico por célula, com a luz mais forte no meio e a moldura preta."""
    grid = layout(2, 2, joint=0.012)
    first = (grid["col"] + grid["row"]) % 2 == 0
    base = np.where(first[..., None], rgb(a), rgb(b)).astype(np.float32)
    r = np.maximum(np.abs(grid["fu"] - 0.5), np.abs(grid["fv"] - 0.5)) * 2.0
    glow = 1.0 - 0.72 * smooth(0.0, 1.0, r)
    lit = base * glow[..., None]
    color = blend(np.broadcast_to(rgb("#0b0a11"), lit.shape), lit * 0.75, grid["mask"])
    return color, grid["relief"], np.full(r.shape, 0.14, dtype=np.float32), lit * grid["mask"][..., None]


def galaxy_tex(seed, variant):
    """Pista Galáxia: nebulosa em placas de vidro preto, com as estrelas pequenas e as juntas finas."""
    n1 = noise(seed, beta=2.3)
    n2 = noise(seed + 1, beta=2.1)
    color = fill("#0c0820")
    color = blend(color, rgb("#3e1e7a"), smooth(0.45, 0.9, n1) * 0.8)
    color = blend(color, rgb("#10507a"), smooth(0.55, 0.95, n2) * 0.7)
    stars = voronoi(26, seed + 2 + variant, 0.9)
    size = table(seed + 3 + variant, stars["count"], 0.0012, 0.0065)[stars["id"]]
    dots = (1.0 - smooth(size * 0.5, size, stars["first"])) * (table(seed + 4, stars["count"], 0.0, 1.0)[stars["id"]] > 0.35)
    glow = blend(color * 0.45, rgb("#f4f2ff"), dots)
    color = blend(color, rgb("#ffffff"), dots)
    grid = layout(1, 1, joint=0.0025)
    color = blend(np.broadcast_to(rgb("#050409"), color.shape), color, grid["mask"])
    return color, grid["relief"], np.full(dots.shape, 0.18, dtype=np.float32), glow * grid["mask"][..., None]


def mirror_tex(seed=53):
    """Piso espelhado: placas de vidro fumê, com a chanfradura violeta e o reflexo em faixa diagonal."""
    grid = layout(2, 2, joint=0.004)
    u, v = coords()
    streak = smooth(0.7, 1.0, np.sin((u + v) * 2.0 * math.pi * 2.0) * 0.5 + 0.5)
    color = blend(np.broadcast_to(rgb("#17141f"), streak.shape + (3,)), rgb("#433e58"), streak * 0.65)
    bevel = (1.0 - smooth(0.004, 0.018, grid["dist"]))
    color = blend(color, rgb("#8a6cc2"), bevel)
    color = blend(np.broadcast_to(rgb("#07060c"), color.shape), color, grid["mask"])
    return color, grid["relief"], np.full(streak.shape, 0.1, dtype=np.float32)


def mosaic_tex(seed=59):
    """Mosaico dourado: pastilhas pequenas de vidro com folha de ouro, cada uma com o seu brilho."""
    grid = layout(10, 10, joint=0.0035)
    pick = table(seed, grid["count"], 0.0, 1.0)[grid["id"]]
    color = blend(np.broadcast_to(rgb("#a2772a"), pick.shape + (3,)), rgb("#e6be62"), pick)
    color = blend(np.broadcast_to(rgb("#3a2a18"), color.shape), color, grid["mask"])
    roughness = table(seed + 1, grid["count"], 0.16, 0.42)[grid["id"]]
    return color, grid["relief"], roughness


def _floor_mat(key, build, **kwargs):
    return painted(key, build, **kwargs)


# Pisos: id -> função(variação) que devolve o material. Cada um mantém o caráter do nome.
FLOORS = {
    "floor_bistro": lambda v: _floor_mat("bistro", lambda: checker_tex(4, "#e9dcc4", "#6a2029", "#3e2e28"), coat=0.35, rough=0.3),
    "floor_blue_tiles": lambda v: _floor_mat("blue_tiles", lambda: tile_tex(2, "#3f84c4", "#2f72b4", "#dcd8cc", amount=0.07), coat=0.7, rough=0.16),
    "floor_marble": lambda v: _floor_mat(f"marble{v}", lambda: marble_tex("#e4ddd0", "#8f8a80", "#8d877c", 60 + v * 7, "#c9c0ad", 0.4), coat=0.75, rough=0.1),
    "floor_70s": lambda v: _floor_mat("r70", lambda: circles_tex(["#6d3a1c", "#b45a22", "#d98a35", "#ecc98c"]), coat=0.2, rough=0.4),
    "floor_country": lambda v: _floor_mat(f"country{v}", lambda: planks_tex("#7d5230", 4, 70, v, knots=7, amount=0.18, grain=0.42, nails=True), bump=0.7, coat=0.08, distance=0.02),
    "floor_party": lambda v: _floor_mat(f"party{v}", lambda: terrazzo_tex("#ecdcd2", ["#cf4d6a", "#d9a92e", "#3f9fb8", "#7f58b8", "#4f9a55"], 80, v, strip="#c9b8a8", sizes=((11, 0.3), (20, 0.26)), fine=False), coat=0.4, rough=0.24),
    "floor_diner": lambda v: _floor_mat(f"diner{v}", lambda: checker_tex(2, ("#e6e4dd", "#1d1d22")[v], ("#e6e4dd", "#1d1d22")[v], "#0d0d10", joint=0.004, amount=0.015), coat=0.8, rough=0.16),
    "floor_mexican": lambda v: _floor_mat(f"mexican{v}", lambda: tile_tex(2, ("#a4532a", "#9a4a24", "#ad5c30")[v], ("#8f4322", "#a65a33", "#93482a")[v], "#c7b190", 90 + v, joint=0.009, amount=0.13, stain=0.14, pits=0.25), rough=0.62, coat=0.12, bump=0.7, distance=0.02),
    "floor_80s": lambda v: _floor_mat(f"m80{v}", lambda: terrazzo_tex("#ece6f0", ["#d94aa8", "#35b5c9", "#e0b12e", "#2a2d5e"], 100, v, strip="#2a2d5e", sizes=((9, 0.34), (18, 0.26)), fine=False), coat=0.4, rough=0.26),
    "floor_italian": lambda v: _floor_mat(f"italian{v}", lambda: terrazzo_tex("#ded2bd", ["#8a7b6c", "#a8705a", "#6a6866", "#b3a48c", "#efe8da"], 110, v, sizes=((14, 0.12), (26, 0.2))), coat=0.55, rough=0.2),
    "floor_japanese": lambda v: _floor_mat(f"tatami{v}", lambda: tatami_tex(v == 1), bump=0.55, specular=0.15),
    "floor_french": lambda v: _floor_mat("french", lambda: herringbone_tex("#b67d48", "#7a4c26", "#2c1a0e"), coat=0.65),
    "floor_brazil": lambda v: _floor_mat("brazil", waves_tex, bump=0.7, distance=0.014, specular=0.25),
    "floor_2010s": lambda v: _floor_mat(f"cement{v}", lambda: cement_tex(120, v), coat=0.15),
    "floor_club": lambda v: _floor_mat(f"club{v}", lambda: led_tex(*(("#c8309c", "#1f9fc4"), ("#d9a21e", "#7a3ac4"), ("#1f9fc4", "#2a9a4a"))[v]), emit=1.15, coat=0.6),
    "floor_oak_light": lambda v: _floor_mat(f"oak{v}", lambda: planks_tex("#c79a63", 6, 130, v, gap="#57402a", amount=0.08, grain=0.22), coat=0.5),
    "floor_70s_carpet": lambda v: _floor_mat("carpet", lambda: carpet_tex("#b35a1c", "#8e4315"), bump=1.0, distance=0.03, specular=0.1),
    "floor_party_pastel": lambda v: _floor_mat("pastel", lambda: checker_tex(2, "#e6a5bd", "#a0c8d8", "#f2ece2"), coat=0.45, rough=0.26),
    "floor_diner_red": lambda v: _floor_mat("diner_red", lambda: checker_tex(2, "#9c1f2a", "#e2ddd0", "#1a1414"), coat=0.7, rough=0.18),
    "floor_country_stone": lambda v: _floor_mat(f"stone{v}", lambda: stone_tex("#a6957a", "#7b6c58", "#3f352a", 140, v), bump=1.0, distance=0.03, specular=0.3),
    "floor_cabochon": lambda v: _floor_mat("cabochon", lambda: cabochon_tex("#e6e0d3", "#232328", "#8d877b"), coat=0.6, rough=0.18),
    "floor_italian_cotto": lambda v: _floor_mat(f"cotto{v}", lambda: tile_tex(2, ("#a85a33", "#a0522e")[v], ("#94482a", "#ad6339")[v], "#cdb596", 150 + v, ny=4, offset=0.5, joint=0.006, amount=0.14, stain=0.1, pits=0.2), rough=0.6, coat=0.12, bump=0.6, distance=0.02),
    "floor_porcelain": lambda v: _floor_mat("porcelain", lambda: marble_tex("#dad5ca", "#c5bfb1", "#8f8c84", 160, "#cdc7ba", 0.2), coat=0.75, rough=0.1),
    "floor_talavera": lambda v: _floor_mat("talavera", talavera_tex, coat=0.7, rough=0.14),
    "floor_dark_parquet": lambda v: _floor_mat("dark_parquet", lambda: basket_tex("#6c4326", "#3f2413", "#160c06"), coat=0.7),
    "floor_80s_grid": lambda v: _floor_mat("grid80", lambda: grid_glow_tex("#180c2a", "#e23fb6"), emit=2.2, coat=0.35),
    "floor_hinoki": lambda v: _floor_mat(f"hinoki{v}", lambda: planks_tex("#d8bd88", 5, 170, v, gap="#7d6641", amount=0.05, grain=0.16), coat=0.18),
    "floor_hydraulic": lambda v: _floor_mat("hydraulic", lambda: hydraulic_tex("#dfd2b0", "#2c6a3a", "#c9862c", "#7c705a")),
    "floor_paris_cabochon": lambda v: _floor_mat("paris", lambda: cabochon_tex("#e2dccd", "#255247", "#8a8474"), coat=0.65, rough=0.16),
    "floor_reclaimed_wood": lambda v: _floor_mat(f"reclaimed{v}", lambda: planks_tex(("#7a5c40", "#6d5136", "#866a4c")[v], 7, 180, v, gap="#1d140d", amount=0.24, grain=0.42, knots=9, weathered=0.5, nails=True), bump=0.8, coat=0.1, distance=0.02),
    "floor_black_marble": lambda v: _floor_mat(f"black_marble{v}", lambda: marble_tex("#191a1f", "#b5ae9e", "#08080a", 190 + v * 5, "#2c2d33", 0.6), coat=0.8, rough=0.12, specular=0.3),
    "floor_mirror": lambda v: _floor_mat("mirror", mirror_tex, coat=0.9, specular=0.8),
    "floor_rose_terrazzo": lambda v: _floor_mat(f"rose{v}", lambda: terrazzo_tex("#cf9d94", ["#8a4e44", "#ecdcd6", "#6d3d35", "#b9705f", "#f2e2c6"], 200, v), coat=0.55, rough=0.2),
    "floor_gold_mosaic": lambda v: _floor_mat("mosaic", mosaic_tex, metal=0.55, coat=0.4),
    "floor_chevron": lambda v: _floor_mat("chevron", lambda: chevron_tex("#e6e2d8", "#1f1f24", "#0c0c0e"), coat=0.65),
    "floor_onyx": lambda v: _floor_mat(f"onyx{v}", lambda: marble_tex("#20503c", "#b7d2bf", "#0f261c", 210 + v * 5, "#143428", 0.8, band=True), coat=0.8, rough=0.12, specular=0.3),
    "floor_galaxy": lambda v: _floor_mat(f"galaxy{v}", lambda: galaxy_tex(220, v), emit=1.3, coat=0.8, specular=0.25),
}


def floor_panel(mat):
    """A célula com a sobra dos lados, com a origem no canto (0, 0) do jogo: a textura cai no lugar certo."""
    b = BLEED
    mesh = bpy.data.meshes.new("Piso")
    mesh.from_pydata([(-b, -1.0 - b, 0.0), (1.0 + b, -1.0 - b, 0.0), (1.0 + b, b, 0.0), (-b, b, 0.0)], [], [(0, 1, 2, 3)])
    mesh.update()
    obj = bpy.data.objects.new("Piso", mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


# --- Paredes: texturas ------------------------------------------------------------------------------------------

def wall_coords():
    return coords(SIZE, WALL_H)


def painted_wall(key, build, **kwargs):
    return painted(key, build, plane="XZ", **kwargs)


def plaster_tex(color, seed, amount=0.1, beta=2.1, lime=False):
    """Reboco pintado: a parede levemente ondulada, com manchas se for caiação."""
    color_map = stained(fill(color, SIZE, WALL_H), seed, amount, SIZE, WALL_H, beta)
    if lime:
        color_map = stained(color_map, seed + 1, 0.08, SIZE, WALL_H, 1.0)
    height = noise(seed + 2, SIZE, WALL_H, beta=1.2)
    return color_map, height, np.full(height.shape, 0.82, dtype=np.float32)


def stripes_tex(a, b, count, seed=3):
    """Papel de parede listrado, com o relevo fino do acetinado na listra."""
    u, _ = wall_coords()
    band = np.floor(u * count * 2).astype(np.int32) % 2
    color = np.where(band[..., None] == 0, rgb(a), rgb(b)).astype(np.float32)
    color = stained(color, seed, 0.03, SIZE, WALL_H)
    return color, band.astype(np.float32) * 0.5, np.where(band == 0, 0.62, 0.44).astype(np.float32)


def waves70_tex(seed=5):
    """Papel de parede dos anos 70: faixas onduladas largas em laranja, mostarda e marrom, sobre o creme, em tom envelhecido."""
    u, v = wall_coords()
    waved = v * 6.0 + np.sin(u * 2.0 * math.pi) * 0.7
    band = np.floor(waved).astype(np.int32) % 4
    palette = np.array([rgb("#dcc491"), rgb("#ad5c26"), rgb("#c69230"), rgb("#6d3d1e")], dtype=np.float32)
    color = stained(palette[band], seed, 0.05, SIZE, WALL_H)
    part = waved - np.floor(waved)
    color = blend(rgb("#3f2412") * np.ones_like(color), color, smooth(0.0, 0.03, np.minimum(part, 1.0 - part)))
    return color, smooth(0.0, 0.05, np.minimum(part, 1.0 - part)), np.full(u.shape, 0.65, dtype=np.float32)


def dots_tex(base, dots, seed=7):
    """Bolinhas de festa: bolas de tamanho igual, em fileiras alternadas e de cores que se revezam."""
    u, v = wall_coords()
    nx, ny = 3, 6
    row = np.floor(v * ny).astype(np.int32)
    x = (u + (row % 2) * 0.5 / nx) % 1.0
    col = np.floor(x * nx).astype(np.int32)
    fx, fy = x * nx - col - 0.5, (v * ny - row - 0.5) * (ny / nx) * (SIZE / WALL_H)
    r = np.sqrt(fx * fx + fy * fy)
    palette = np.array([rgb(c) for c in dots], dtype=np.float32)
    pick = palette[(col + row * 2) % len(dots)]
    color = blend(fill(base, SIZE, WALL_H), pick, 1.0 - smooth(0.2, 0.215, r))
    return stained(color, seed, 0.03, SIZE, WALL_H), 1.0 - smooth(0.2, 0.23, r), np.full(r.shape, 0.6, dtype=np.float32)


def subway_tex(tile, grout, rows, seed=9, per_cell=4, joint=0.0045, amount=0.04):
    """Azulejo de metrô: tijolinhos esmaltados com a quina chanfrada, em amarração."""
    grid = layout(per_cell, rows, 0.5, joint, SIZE, WALL_H)
    color = tone(fill(tile, SIZE, WALL_H), grid["id"], seed, amount, grid["count"])
    color = blend(np.broadcast_to(rgb(grout), color.shape), color, grid["mask"])
    return color, grid["relief"], np.full(grid["mask"].shape, 0.14, dtype=np.float32)


def talavera_band_tex(seed=11):
    """A faixa de azulejos do estuque mexicano: duas fileiras de Talavera, na mesma pintura do piso."""
    n, rows = 3, 6
    grid = layout(n, rows, joint=0.0035, w=SIZE, h=WALL_H)
    wobble = (noise(seed, SIZE, WALL_H, 1.8) - 0.5) * 0.03
    dx, dy = grid["fu"] - 0.5, grid["fv"] - 0.5
    r = np.sqrt(dx * dx + dy * dy) + wobble
    angle = np.arctan2(dy, dx)
    petal = 0.17 + 0.13 * np.abs(np.cos(angle * 4.0)) ** 1.5
    color = fill("#efe7d4", SIZE, WALL_H)
    color = blend(color, rgb("#21508f"), 1.0 - smooth(petal, petal + 0.012, r))
    color = blend(color, rgb("#efe7d4"), 1.0 - smooth(petal * 0.62, petal * 0.62 + 0.012, r))
    color = blend(color, rgb("#d9962c"), 1.0 - smooth(0.075, 0.087, r))
    color = blend(np.broadcast_to(rgb("#b6ad98"), color.shape), color, grid["mask"])
    return color, grid["relief"], np.full(r.shape, 0.18, dtype=np.float32)


def leaves_tex(seed=13):
    """Folhagem tropical: folhas largas e nervuradas sobre o verde-escuro, em repetição de uma célula."""
    u, v = wall_coords()
    color = stained(fill("#23402f", SIZE, WALL_H), seed, 0.1, SIZE, WALL_H)
    height = np.zeros(u.shape, dtype=np.float32)
    rng = np.random.default_rng(seed + 1)
    colors = ["#3e7a47", "#4f9255", "#2f6a3f", "#6aa45c", "#35754a"]
    aspect = WALL_Z
    for i in range(16):
        cx, cy = rng.uniform(0.0, 1.0), rng.uniform(0.0, 1.0)
        angle = rng.uniform(0.0, 2.0 * math.pi)
        length = rng.uniform(0.24, 0.36)
        width = length * rng.uniform(0.3, 0.42)
        for ox in (-1.0, 0.0, 1.0):       # a folha que sai por um lado volta pelo outro
            for oy in (-1.0, 0.0, 1.0):
                dx = (u - cx - ox)
                dy = (v - cy - oy) * aspect
                along = dx * math.cos(angle) + dy * math.sin(angle)
                side = -dx * math.sin(angle) + dy * math.cos(angle)
                t = along / length
                edge = width * np.sqrt(np.clip(1.0 - t * t, 0.0, 1.0)) * (1.0 + 0.1 * np.sin(t * 22.0))
                body = (np.abs(side) < edge) & (np.abs(t) < 1.0)
                if not body.any():
                    continue
                shade = rgb(colors[i % len(colors)])
                veins = np.abs(np.sin((along + np.abs(side) * 0.8) * 110.0))
                leaf = shade[None, None, :] * (0.82 + 0.26 * (np.abs(side) / np.maximum(edge, 1e-4)))[..., None] * (0.92 + 0.08 * veins[..., None])
                rib = np.abs(side) < 0.0035
                leaf = np.where(rib[..., None], np.clip(shade * 1.45, 0, 1), leaf)
                color = np.where(body[..., None], np.clip(leaf, 0, 1), color)
                height = np.where(body, 0.5 + 0.4 * (1.0 - np.abs(side) / np.maximum(edge, 1e-4)), height)
    return color.astype(np.float32), height.astype(np.float32), np.full(u.shape, 0.55, dtype=np.float32)


def log_material(color, seed):
    """Tora: a casca lisa, com o veio correndo ao longo da peça."""
    def build():
        grain = noise(seed, beta=1.3, along_u=18.0)
        dark = noise(seed + 1, beta=1.2, along_u=8.0)
        tint = blend(np.broadcast_to(rgb(color) * 0.62, grain.shape + (3,)), rgb(color), grain)
        tint = np.clip(tint * (0.88 + 0.2 * dark[..., None]), 0, 1)
        return tint, grain, np.full(grain.shape, 0.66, dtype=np.float32)
    return painted(f"log{color}{seed}", build, bump=0.8, distance=0.018)


def washi_tex(seed=17):
    """Papel de arroz: fibras soltas, acesas de leve por trás."""
    fibers = noise(seed, SIZE, WALL_H, beta=0.9)
    long = noise(seed + 1, SIZE, WALL_H, beta=1.1, along_u=10.0)
    tint = np.clip(rgb("#e8dcc2") * (0.92 + fibers[..., None] * 0.08 + long[..., None] * 0.06), 0, 1)
    return tint, fibers, np.full(fibers.shape, 0.9, dtype=np.float32), tint * 0.9


def acoustic_tex(seed=19):
    """Espuma acústica da balada: pirâmides escuras em relevo, que pegam a luz do neon."""
    u, v = wall_coords()
    nx, ny = 5, 10
    fu, fv = (u * nx) % 1.0, (v * ny) % 1.0
    wedge = 1.0 - 2.0 * np.maximum(np.abs(fu - 0.5), np.abs(fv - 0.5))
    color = stained(fill("#1b1826", SIZE, WALL_H), seed, 0.1, SIZE, WALL_H)
    color = np.clip(color * (0.72 + 0.6 * wedge[..., None]), 0, 1)
    return color, wedge, np.full(u.shape, 0.9, dtype=np.float32)


def concrete_tex(seed=23):
    """Concreto aparente da balada, escuro, com poros."""
    clouds = noise(seed, SIZE, WALL_H, beta=2.1)
    color = blend(np.broadcast_to(rgb("#17151e"), clouds.shape + (3,)), rgb("#2b2733"), clouds)
    return color, clouds, np.full(clouds.shape, 0.75, dtype=np.float32)


# --- Paredes: peças ---------------------------------------------------------------------------------------------

def trim(parts, beam=None, base="#2c1c12", beam_h=0.14, base_h=0.11):
    """Rodapé alto e viga no alto, como nas paredes da amostra: dão peso à parede e a mesma altura em todos os estilos."""
    parts.append(box((WIDTH, 0.09, beam_h), (0.5, -0.03, WALL_Z - beam_h / 2), beam or rich_wood(A.WALNUT_DARK, 5.0, 0.3), 0.006))
    parts.append(box((WIDTH, 0.08, base_h), (0.5, -0.02, base_h / 2), base if not isinstance(base, str) else solid(base, 0.45), 0.004))
    return parts


def wainscot(mat, panel, rail_mat, z=S.WAINSCOT_TOP, rail_h=0.045, inset=0.82):
    """Lambri: a faixa baixa, a almofada e o friso."""
    return [box((WIDTH, 0.06, z), (0.5, 0.01, z / 2), mat, 0.0),
            box((inset, 0.07, z * 0.62), (0.5, 0.0, z * 0.54), panel, 0.012),
            box((WIDTH, 0.085, rail_h), (0.5, -0.008, z + 0.012), rail_mat, 0.008)]


def upper(mat, z0=0.0):
    return face_panel(-BLEED, 1.0 + BLEED, z0, WALL_Z, 0.0, mat)


def moulding(x0, x1, z0, z1, mat, thick=0.02, y=-0.008, depth=0.024):
    """Moldura em quadro, em relevo na parede."""
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    return [box((x1 - x0 + thick, depth, thick), (cx, y, z0), mat, 0.005), box((x1 - x0 + thick, depth, thick), (cx, y, z1), mat, 0.005),
            box((thick, depth, z1 - z0), (x0, y, cz), mat, 0.005), box((thick, depth, z1 - z0), (x1, y, cz), mat, 0.005)]


def wall_mint():
    tex = painted_wall("mint", lambda: stripes_tex("#a8d3c0", "#e6ece0", 4), bump=0.12)
    white = solid("#e9e3d6", 0.42, 0.0, 0.25)
    return trim([upper(tex), *wainscot(white, solid("#efe9dc", 0.4, 0.0, 0.25), solid("#efe9dc", 0.35, 0.0, 0.3))], rich_wood("#5d3820", 5.0, 0.3), "#2c1c12")


def wall_navy():
    tex = painted_wall("navy", lambda: plaster_tex("#20304f", 31, 0.08), bump=0.15)
    white = solid("#dfd9cb", 0.42, 0.0, 0.25)
    gold = AS.gold()
    return trim([upper(tex), *wainscot(white, solid("#e7e1d4", 0.4, 0.0, 0.25), gold, rail_h=0.03),
                 *moulding(0.14, 0.86, S.WAINSCOT_TOP + 0.2, WALL_Z - 0.28, gold, 0.012)], rich_wood(A.WALNUT_DARK, 5.0, 0.3), "#141c30")


def wall_70s():
    tex = painted_wall("w70", waves70_tex, bump=0.12)
    # Lambri de ripas verticais, a marca da sala de 1970.
    wood = rich_wood("#8a5a32", 6.0, 0.35)
    parts = [upper(tex), box((WIDTH, 0.06, S.WAINSCOT_TOP), (0.5, 0.01, S.WAINSCOT_TOP / 2), rich_wood("#4b2c17", 5.0, 0.2), 0.0),
             box((WIDTH, 0.085, 0.045), (0.5, -0.008, S.WAINSCOT_TOP + 0.012), wood, 0.008)]
    for i in range(6):
        parts.append(box((0.145, 0.07, S.WAINSCOT_TOP), (0.083 + i * 0.1667, 0.0, S.WAINSCOT_TOP / 2), wood, 0.008))
    return trim(parts, rich_wood("#4b2c17", 5.0, 0.3), "#2c1a0e")


def wall_country():
    """Parede de toras: toras inteiras empilhadas, com a argamassa clara entre elas."""
    logs = 8
    step = (WALL_Z - 0.1) / logs
    parts = [face_panel(-BLEED, 1.0 + BLEED, 0.0, WALL_Z, 0.02, solid("#a89274", 0.9))]
    for i in range(logs):
        z = 0.06 + step * (i + 0.5)
        mat = log_material(("#8a5a30", "#7b4f29", "#93623a", "#815329")[i % 4], 300 + i)
        bpy.ops.mesh.primitive_cylinder_add(radius=step * 0.53, depth=WIDTH, location=(0.0, 0.0, 0.0), rotation=(0.0, math.radians(90), 0.0), vertices=32)
        log = bpy.context.active_object
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        for vert in log.data.vertices:
            vert.co.x += 0.5
            vert.co.y += 0.0
            vert.co.z += z
        for poly in log.data.polygons:
            poly.use_smooth = True
        log.data.materials.append(mat)
        parts.append(log)
    return trim(parts, rich_wood("#4e3019", 5.0, 0.15), "#2a1b10", beam_h=0.1, base_h=0.08)


def wall_party():
    tex = painted_wall("party", lambda: dots_tex("#ecd3d6", ["#c9506a", "#d8a32f", "#3f9fb8", "#55a05a"]), bump=0.18)
    white = solid("#ece6da", 0.42, 0.0, 0.25)
    return trim([upper(tex), *wainscot(white, solid("#f0eadf", 0.4, 0.0, 0.25), solid("#bf4661", 0.36, 0.0, 0.5))], rich_wood(A.WALNUT, 5.0, 0.3), "#6d2a3a")


def wall_diner():
    """Faixa cromada: azulejo branco em cima, laca vermelha embaixo e as tiras de cromo na divisa."""
    tex = painted_wall("diner", lambda: subway_tex("#e7e5dd", "#7d8086", 12, joint=0.004), coat=0.7, bump=0.5, distance=0.008)
    chrome = AS.chrome_a()
    z = S.WAINSCOT_TOP
    parts = [upper(tex), box((WIDTH, 0.06, z), (0.5, 0.01, z / 2), solid("#8e1a24", 0.3, 0.0, 0.8), 0.0)]
    for dz in (z - 0.02, z + 0.03, z * 0.5):
        parts.append(box((WIDTH, 0.08, 0.026), (0.5, -0.004, dz), chrome, 0.008))
    return trim(parts, solid("#1b1b20", 0.4, 0.0, 0.5), chrome, beam_h=0.12)


def wall_mexican():
    stucco = painted_wall("mex_stucco", lambda: plaster_tex("#d59a3a", 41, 0.14, lime=True), bump=0.6, distance=0.02)
    tiles = painted_wall("mex_tile", talavera_band_tex, coat=0.7, bump=0.5, distance=0.008)
    z = S.WAINSCOT_TOP
    parts = [upper(stucco, z), face_panel(-BLEED, 1.0 + BLEED, 0.0, z, -0.005, tiles),
             box((WIDTH, 0.085, 0.04), (0.5, -0.012, z + 0.012), solid("#1f4c8c", 0.35, 0.0, 0.6), 0.008)]
    return trim(parts, rich_wood("#5a3518", 5.0, 0.2), "#6e2f18")


def wall_80s():
    """Grade neon: parede roxa-escura com a grade de tubos acesos e o lambri preto."""
    tex = painted_wall("w80", lambda: plaster_tex("#231237", 43, 0.14), bump=0.12)
    z = S.WAINSCOT_TOP
    parts = [upper(tex), box((WIDTH, 0.06, z), (0.5, 0.01, z / 2), solid("#100a1c", 0.3, 0.0, 0.7), 0.0),
             box((WIDTH, 0.03, 0.022), (0.5, -0.03, z + 0.012), emission("#3fdfff", 4.0), 0.004)]
    pink = emission("#ef49c0", 3.2)
    for x in (0.25, 0.75):
        parts.append(box((0.012, 0.022, WALL_Z - z - 0.18), (x, -0.012, (WALL_Z + z - 0.12) / 2), pink, 0.002))
    for i in range(1, 5):
        parts.append(box((WIDTH, 0.022, 0.012), (0.5, -0.012, z + i * 0.21), pink, 0.002))
    return trim(parts, solid("#120b1f", 0.35, 0.0, 0.6), "#0c0816")


def wall_italian():
    """Reboco toscano: caiação manchada, com o reboco caído mostrando o tijolo na parte de baixo."""
    tex = painted_wall("italian", lambda: plaster_tex("#cda169", 47, 0.16, lime=True), bump=0.7, distance=0.02)
    bricks = painted_wall("italian_brick", lambda: subway_tex("#92452f", "#b7a68c", 22, per_cell=4, joint=0.0045, amount=0.18), bump=0.9, distance=0.018)
    z = S.WAINSCOT_TOP
    parts = [upper(tex, z), face_panel(-BLEED, 1.0 + BLEED, 0.0, z, -0.004, bricks),
             box((WIDTH, 0.08, 0.04), (0.5, -0.008, z + 0.012), solid("#d6c7a9", 0.7), 0.008)]
    return trim(parts, rich_wood("#4e2f1a", 5.0, 0.25), "#3f2316")


def wall_japanese():
    """Shoji: o papel aceso atrás da treliça de madeira e o rodapé alto de tábua, como numa casa de verdade."""
    paper = painted_wall("shoji", washi_tex, emit=0.28, bump=0.1)
    frame = rich_wood("#4d311c", 6.0, 0.25)
    z = 0.3
    parts = [upper(paper, z), box((WIDTH, 0.06, z), (0.5, 0.0, z / 2), rich_wood("#6a4526", 6.0, 0.25), 0.004)]
    for x in (0.0, 0.333, 0.667, 1.0):
        parts.append(box((0.034 if x in (0.0, 1.0) else 0.018, 0.04, WALL_Z - z), (x, -0.012, (WALL_Z + z) / 2), frame, 0.003))
    rows = 5
    for i in range(rows + 1):
        parts.append(box((WIDTH, 0.04, 0.018 if 0 < i < rows else 0.034), (0.5, -0.012, z + i * (WALL_Z - z) / rows), frame, 0.003))
    return trim(parts, rich_wood("#3a2415", 5.0, 0.2), "#24160c", beam_h=0.1, base_h=0.08)


def wall_french():
    """Boiserie azul: os painéis de moldura em relevo, com o filete dourado, em cima e embaixo."""
    blue = solid("#7f9db8", 0.5, 0.0, 0.25)
    light = solid("#8aa8c2", 0.45, 0.0, 0.25)
    gold = AS.gold()
    z = S.WAINSCOT_TOP
    parts = [box((WIDTH, 0.03, WALL_Z), (0.5, 0.02, WALL_Z / 2), blue, 0.0),
             box((WIDTH, 0.08, 0.05), (0.5, -0.006, z + 0.012), light, 0.012)]
    parts += moulding(0.13, 0.87, z + 0.2, WALL_Z - 0.28, light, 0.034, depth=0.03)
    parts += moulding(0.17, 0.83, z + 0.24, WALL_Z - 0.32, gold, 0.009, depth=0.016)
    parts += moulding(0.13, 0.87, 0.2, z - 0.1, light, 0.03, depth=0.03)
    return trim(parts, light, "#4f6a84", beam_h=0.12)


def wall_brazil():
    tex = painted_wall("brazil", leaves_tex, bump=0.3)
    white = solid("#ece6d6", 0.42, 0.0, 0.25)
    return trim([upper(tex), *wainscot(white, solid("#f1ebdc", 0.4, 0.0, 0.25), rich_wood("#6d4527", 6.0, 0.4))], rich_wood(A.WALNUT_DARK, 5.0, 0.3), "#1f4a2e")


def wall_2010s():
    """Azulejo de metrô do chão ao teto, branco, de rejunte escuro, com a viga de ferro."""
    tex = painted_wall("w2010", lambda: subway_tex("#e6e4dc", "#35373c", 15, joint=0.0045, amount=0.035), coat=0.75, bump=0.6, distance=0.01)
    return trim([upper(tex)], cast_iron("#24252b"), "#1a1b20", beam_h=0.11)


def wall_club():
    """Luz neon: espuma escura e as três fitas de luz, que são a graça dessa parede."""
    tex = painted_wall("club", acoustic_tex, bump=1.0, distance=0.04)
    parts = [upper(tex)]
    for z, color, power in ((1.34, "#ef49c0", 7.0), (1.2, "#3fdfff", 7.0), (0.64, "#9a4dff", 6.0)):
        parts.append(box((WIDTH, 0.03, 0.022), (0.5, -0.012, z), emission(color, power), 0.004))
    return trim(parts, solid("#0d0b14", 0.4, 0.0, 0.3), "#08060c")


WALLS = {
    "wall_mint_stripes": wall_mint, "wall_navy": wall_navy, "wall_70s": wall_70s, "wall_country": wall_country, "wall_party": wall_party,
    "wall_diner": wall_diner, "wall_mexican": wall_mexican, "wall_80s": wall_80s, "wall_italian": wall_italian, "wall_japanese": wall_japanese,
    "wall_french": wall_french, "wall_brazil": wall_brazil, "wall_2010s": wall_2010s, "wall_club": wall_club,
}


# --- Itens de parede: peças ---------------------------------------------------------------------------------------

def window_glass():
    return solid("#6d8294", 0.08, 0.0, 1.0)     # o mesmo vidro da janela da amostra


def washi_pane():
    return emission("#f3e6c8", 0.9)


def ring(cx, cz, r_out, r_in, y0, y1, mat, a0=0.0, a1=360.0, squash=1.0, bevel=0.006, steps=64):
    """Anel (moldura redonda ou arco), de frente para -Y, de [a0] a [a1] graus. [squash] alonga na altura."""
    verts, faces = [], []
    for i in range(steps + 1):
        angle = math.radians(a0 + (a1 - a0) * i / steps)
        for r in (r_out, r_in):
            x, z = cx + math.cos(angle) * r, cz + math.sin(angle) * r * squash
            verts += [(x, y0, z), (x, y1, z)]
    for i in range(steps):
        a, b = i * 4, (i + 1) * 4
        faces += [(a, b, b + 1, a + 1), (a + 2, a + 3, b + 3, b + 2), (a + 1, b + 1, b + 3, a + 3), (a, a + 2, b + 2, b)]
    if a1 - a0 < 360.0:
        last = steps * 4
        faces += [(0, 1, 3, 2), (last, last + 2, last + 3, last + 1)]
    mesh = bpy.data.meshes.new("Anel")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("Anel", mesh)
    bpy.context.scene.collection.objects.link(obj)
    return M._finish(obj, mat, bevel, segments=3)


def disc(cx, cz, r, y, mat, a0=0.0, a1=360.0, squash=1.0, steps=64):
    """Vidro redondo ou em arco, de frente para -Y."""
    verts = [(cx, y, cz)]
    for i in range(steps + 1):
        angle = math.radians(a0 + (a1 - a0) * i / steps)
        verts.append((cx + math.cos(angle) * r, y, cz + math.sin(angle) * r * squash))
    faces = [(0, i + 1, i + 2) for i in range(steps)]
    mesh = bpy.data.meshes.new("Disco")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("Disco", mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def bar(x0, z0, x1, z1, y, width, depth, mat, bevel=0.003):
    """Barra de caixilho entre dois pontos do plano da parede."""
    length = math.hypot(x1 - x0, z1 - z0)
    obj = box((length + width * 0.2, depth, width), ((x0 + x1) / 2, y, (z0 + z1) / 2), mat, bevel)
    obj.rotation_euler = (0.0, -math.atan2(z1 - z0, x1 - x0), 0.0)
    return obj


def curtain(x0, x1, z0, z1, y, mat, folds=5, depth=0.022):
    """Cortina caindo em dobras: uma tira ondulada de frente para a sala."""
    steps = folds * 8
    verts, faces = [], []
    for i in range(steps + 1):
        t = i / steps
        x = x0 + (x1 - x0) * t
        wave = math.sin(t * folds * 2.0 * math.pi) * depth
        verts += [(x, y + wave * 0.6, z0), (x, y + wave, z1)]
    for i in range(steps):
        a = i * 2
        faces.append((a, a + 2, a + 3, a + 1))
    mesh = bpy.data.meshes.new("Cortina")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("Cortina", mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def shutter(cx, z0, z1, width, mat, slat_mat):
    """Veneziana aberta contra a parede: a moldura e as palhetas."""
    h = z1 - z0
    parts = [box((width, 0.022, h), (cx, -0.014, (z0 + z1) / 2), mat, 0.004)]
    count = int(h / 0.042)
    for i in range(count):
        parts.append(box((width - 0.03, 0.018, 0.026), (cx, -0.028, z0 + 0.04 + i * (h - 0.08) / max(count - 1, 1)), slat_mat, 0.002))
    return parts


def flower_box(cx, width, z, box_mat, flowers, y=-0.1, leaf_color="#3d7a3a"):
    """Floreira no peitoril: folhas cheias e as flores por cima."""
    parts = [box((width, 0.12, 0.09), (cx, y, z + 0.045), box_mat, 0.01)]
    foliage = E.foliage(leaf_color)
    count = int(width / 0.05)
    for i in range(count):
        x = cx - width / 2 + 0.03 + i * (width - 0.06) / max(count - 1, 1)
        parts.append(sphere(0.042, (x, y - 0.005, z + 0.095 + (i % 2) * 0.018), foliage, (1, 0.9, 0.85)))
        if i % 2 == 0:
            color = flowers[(i // 2) % len(flowers)]
            parts.append(sphere(0.021, (x + 0.01, y - 0.04, z + 0.125 + (i % 3) * 0.012), solid(color, 0.6)))
    return parts


def label(body, x, y, z, size, mat, font_extrude=0.002):
    """Texto de frente para -Y, centrado em x, com a letra do jogo."""
    bpy.ops.object.text_add(location=(x, y, z), rotation=(math.radians(90), 0, 0))
    text = bpy.context.active_object
    text.data.body = body
    text.data.font = bpy.data.fonts.load(S.FONT, check_existing=True)
    text.data.align_x = "CENTER"
    text.data.size = size
    text.data.extrude = font_extrude
    text.data.materials.append(mat)
    return text


def round_window(frame, inner, pane, lattice=None, cross=True, rivets=None):
    """Janela redonda: anel fundo, o filete de dentro e o vidro, com a cruz ou a treliça."""
    cx, cz = S.at(21, -68)
    r = 13 / S.DESIGN_W
    parts = [ring(cx, cz, r + 0.06, r - 0.004, 0.0, -0.075, frame, bevel=0.012),
             ring(cx, cz, r + 0.002, r - 0.024, -0.012, -0.06, inner, bevel=0.004),
             disc(cx, cz, r, -0.012, pane)]
    if lattice is not None:
        for i in range(-3, 4):
            half = math.sqrt(max(r * r - (i * r / 3.5) ** 2, 0.0))
            parts.append(bar(cx + i * r / 3.5, cz - half, cx + i * r / 3.5, cz + half, -0.03, 0.012, 0.018, lattice))
            parts.append(bar(cx - half, cz + i * r / 3.5, cx + half, cz + i * r / 3.5, -0.03, 0.012, 0.018, lattice))
    elif cross:
        parts.append(bar(cx, cz - r, cx, cz + r, -0.03, 0.022, 0.03, inner))
        parts.append(bar(cx - r, cz, cx + r, cz, -0.03, 0.022, 0.03, inner))
    if rivets is not None:
        for i in range(12):
            angle = 2.0 * math.pi * i / 12
            parts.append(sphere(0.011, (cx + math.cos(angle) * (r + 0.03), -0.077, cz + math.sin(angle) * (r + 0.03)), rivets))
    return parts


def square_frame(x0, x1, z0, z1, frame, sill, pane=None, nx=1, nz=1, thick=0.05, muntin=0.03):
    """Janela reta como a da amostra: caixilho fundo, vidro em divisões e peitoril."""
    w, h = x1 - x0, z1 - z0
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    parts = [box((w, 0.012, h), (cx, -0.005, cz), pane or window_glass(), 0.0),
             box((w + 0.1, 0.07, 0.06), (cx, -0.035, z1 + 0.02), frame, 0.008),
             box((w + 0.16, 0.13, 0.05), (cx, -0.07, z0 - 0.02), sill, 0.01)]
    for x in (x0, x1):
        parts.append(box((thick, 0.07, h + 0.04), (x, -0.03, cz), frame, 0.006))
    for i in range(1, nx):
        parts.append(box((muntin, 0.04, h), (x0 + w * i / nx, -0.02, cz), frame, 0.003))
    for i in range(1, nz):
        parts.append(box((w, 0.04, muntin), (cx, -0.02, z0 + h * i / nz), frame, 0.003))
    return parts


def window_box_area():
    x0, z1 = S.at(9, -88)
    x1, z0 = S.at(33, -42)
    return x0, x1, z0, z1


def window_country():
    """Janela de fazenda: venezianas de tábua abertas, cortina xadrez e madeira crua."""
    x0, x1, z0, z1 = window_box_area()
    frame = rich_wood("#6a4526", 6.0, 0.15)
    parts = square_frame(x0 + 0.05, x1 - 0.05, z0, z1, frame, rich_wood("#7d5230", 6.0, 0.2), nx=2, nz=2)
    red = M.fabric("gingham", "#963228")
    parts.append(curtain(x0 + 0.04, x0 + 0.26, z1 - 0.42, z1 - 0.02, -0.06, red, 3))
    parts.append(curtain(x1 - 0.26, x1 - 0.04, z1 - 0.42, z1 - 0.02, -0.06, red, 3))
    parts.append(tube((x0, -0.075, z1 - 0.02), (x1, -0.075, z1 - 0.02), 0.009, cast_iron()))
    return parts


def window_party():
    """Janela de festa: caixilho claro, cortina de voal e o varal de bandeirinhas."""
    x0, x1, z0, z1 = window_box_area()
    frame = solid("#e6dfd2", 0.4, 0.0, 0.3)
    parts = square_frame(x0 + 0.03, x1 - 0.03, z0, z1, frame, solid("#b9486a", 0.36, 0.0, 0.5), nx=2)
    violet = M.fabric("plain", "#7d55a8")
    parts.append(curtain(x0 - 0.07, x0 + 0.12, z0 + 0.02, z1, -0.07, violet, 3))
    parts.append(curtain(x1 - 0.12, x1 + 0.07, z0 + 0.02, z1, -0.07, violet, 3))
    colors = ("#c9506a", "#d8a32f", "#3f9fb8", "#55a05a", "#7f58b8")
    count = 7
    for i in range(count):
        t = (i + 0.5) / count
        x = x0 - 0.02 + (x1 - x0 + 0.04) * t
        sag = 0.09 * (1.0 - (2.0 * t - 1.0) ** 2)
        z = z1 + 0.0 - sag
        verts = [(x - 0.038, -0.095, z), (x + 0.038, -0.095, z), (x, -0.095, z - 0.1)]
        mesh = bpy.data.meshes.new("Bandeira")
        mesh.from_pydata(verts, [], [(0, 1, 2)])
        mesh.update()
        flag = bpy.data.objects.new("Bandeira", mesh)
        bpy.context.scene.collection.objects.link(flag)
        flag.data.materials.append(solid(colors[i % len(colors)], 0.7))
        parts.append(flag)
    return parts


def window_industrial():
    """Janela industrial: ferro preto em muitas divisões pequenas, sem cortina."""
    x0, x1, z0, z1 = window_box_area()
    iron = cast_iron("#25262b")
    return square_frame(x0 - 0.02, x1 + 0.02, z0, z1, iron, cast_iron("#34353b"), nx=3, nz=5, thick=0.04, muntin=0.016)


def arched_window(frame, sill, flowers=None, box_mat=None, shutters=None, balcony=None, tile_sill=False):
    """Janelão em arco: vidro em arco com o caixilho fundo, travessas e, conforme o estilo, floreira, venezianas ou sacada."""
    x0, z0 = S.at(9, -30)
    x1, spring = S.at(33, -70)
    w = x1 - x0
    cx = (x0 + x1) / 2
    radius = w / 2
    glass = window_glass()
    parts = [box((w, 0.012, spring - z0), (cx, -0.005, (z0 + spring) / 2), glass, 0.0), disc(cx, spring, radius, -0.005, glass, 0.0, 180.0)]
    for x in (x0, x1):
        parts.append(box((0.055, 0.075, spring - z0 + 0.02), (x, -0.03, (z0 + spring) / 2), frame, 0.006))
    parts.append(ring(cx, spring, radius + 0.03, radius - 0.025, 0.0, -0.075, frame, 0.0, 180.0, bevel=0.006))
    parts.append(box((0.03, 0.045, spring - z0 + radius), (cx, -0.02, (z0 + spring + radius) / 2), frame, 0.003))
    parts.append(box((w, 0.045, 0.03), (cx, -0.02, spring), frame, 0.003))
    parts.append(box((w, 0.045, 0.024), (cx, -0.02, (z0 + spring) / 2), frame, 0.003))
    parts.append(box((w + 0.14, 0.14, 0.05), (cx, -0.07, z0 - 0.02), sill, 0.01))
    if tile_sill:
        tiles = ("#21508f", "#efe7d4", "#d9962c")
        for i in range(8):
            parts.append(box((0.085, 0.012, 0.042), (x0 - 0.04 + 0.0143 + i * (w + 0.06) / 8 + 0.03, -0.144, z0 - 0.02), solid(tiles[i % 3], 0.2, 0.0, 0.8), 0.002))
    if shutters is not None:
        slat = shutters[1]
        parts += shutter(x0 - 0.1, z0, spring + 0.04, 0.13, shutters[0], slat)
        parts += shutter(x1 + 0.1, z0, spring + 0.04, 0.13, shutters[0], slat)
    if flowers is not None:
        parts += flower_box(cx, w + 0.08, z0 + 0.0, box_mat or rich_wood(A.WALNUT, 6.0, 0.3), flowers)
    if balcony is not None:
        rail_z = z0 + 0.2
        parts.append(tube((x0 - 0.06, -0.15, rail_z), (x1 + 0.06, -0.15, rail_z), 0.011, balcony))
        parts.append(box((w + 0.16, 0.17, 0.03), (cx, -0.085, z0 - 0.055), balcony, 0.006))
        for i in range(9):
            x = x0 - 0.05 + i * (w + 0.1) / 8
            parts.append(tube((x, -0.15, z0 - 0.04), (x, -0.15, rail_z), 0.005, balcony))
            if 0 < i < 8 and i % 2 == 0:
                parts.append(sphere(0.016, (x, -0.15, z0 + 0.08), balcony))
    return parts


def oval_mirror():
    """Espelho dourado: oval, de moldura grossa torneada, com o filete e a coroa em cima."""
    cx, cz = S.at(21, -66)
    r = 0.26
    tall = 1.28
    gold = AS.gold()
    parts = [disc(cx, cz, r, -0.012, AS.mirror_glass(), squash=tall),
             ring(cx, cz, r + 0.052, r - 0.004, 0.0, -0.05, gold, squash=tall, bevel=0.012),
             ring(cx, cz, r + 0.002, r - 0.016, -0.012, -0.03, rich_wood(A.WALNUT_DARK, 6.0, 0.4), squash=tall, bevel=0.003),
             ring(cx, cz, r + 0.076, r + 0.056, 0.0, -0.03, gold, squash=tall, bevel=0.006)]
    top = cz + (r + 0.07) * tall
    parts.append(sphere(0.04, (cx, -0.03, top + 0.012), gold, (1.0, 0.6, 1.0)))
    for side in (-1, 1):
        parts.append(sphere(0.03, (cx + side * 0.058, -0.028, top - 0.006), gold, (1.0, 0.6, 0.6)))
    parts.append(sphere(0.022, (cx, -0.03, cz - (r + 0.07) * tall - 0.008), gold, (1.0, 0.6, 1.0)))
    return parts


def chalkboard():
    """Lousa de cardápio: moldura de madeira, ardósia manchada de giz e o cardápio escrito à mão."""
    cx, cz = S.at(21, -64)
    frame = rich_wood(A.WALNUT, 6.0, 0.4)
    def slate():
        wiped = noise(61, beta=1.6, along_u=3.0)
        color = blend(np.broadcast_to(rgb("#1f2925"), wiped.shape + (3,)), rgb("#3c4842"), smooth(0.45, 0.95, wiped))
        return color, wiped * 0.2, np.full(wiped.shape, 0.9, dtype=np.float32)
    w, h = 0.72, 0.6
    board = painted("lousa", slate)
    parts = [box((w + 0.1, 0.045, h + 0.1), (cx, -0.022, cz), frame, 0.012),
             face_panel(cx - w / 2, cx + w / 2, cz - h / 2, cz + h / 2, -0.046, board),
             box((w + 0.02, 0.05, 0.02), (cx, -0.06, cz - h / 2 - 0.03), frame, 0.004)]
    chalk = solid("#e7e3d6", 0.95)
    parts.append(label("Cardápio", cx, -0.05, cz + 0.14, 0.11, chalk, 0.0006))
    parts.append(box((0.42, 0.003, 0.006), (cx, -0.049, cz + 0.11), chalk, 0.0))
    for i, (x, width) in enumerate(((-0.1, 0.34), (-0.13, 0.28), (-0.09, 0.36))):
        z = cz + 0.04 - i * 0.1
        parts.append(box((width, 0.003, 0.012), (cx + x, -0.049, z), chalk, 0.0))
        parts.append(box((0.07, 0.003, 0.012), (cx + 0.25, -0.049, z), solid("#d9b75c", 0.95), 0.0))
    parts.append(box((0.08, 0.016, 0.016), (cx + 0.2, -0.066, cz - h / 2 - 0.016), chalk, 0.004))
    return parts


def neon_cup():
    """Neon de xícara: tubos acesos presos por espaçadores a uma placa escura com as bordas boleadas."""
    cx, cz = S.at(21, -66)
    plate = solid("#14121d", 0.35, 0.0, 0.7)
    pink = emission("#ff4da6", 12.0)
    cyan = emission("#4fe0ff", 11.0)
    parts = [box((0.66, 0.026, 0.74), (cx, -0.014, cz), plate, 0.026)]
    bx = cx - 0.03
    bz = cz - 0.06
    parts.append(ring(bx, bz, 0.19, 0.165, -0.04, -0.066, pink, 180.0, 360.0, bevel=0.006))
    parts.append(bar(bx - 0.178, bz + 0.002, bx + 0.178, bz + 0.002, -0.052, 0.024, 0.026, pink))
    parts.append(ring(bx + 0.21, bz - 0.05, 0.075, 0.052, -0.04, -0.066, pink, -100.0, 110.0, bevel=0.006))
    parts.append(bar(bx - 0.17, bz - 0.215, bx + 0.17, bz - 0.215, -0.052, 0.024, 0.026, pink))
    for dx, phase in ((-0.075, 0.0), (0.06, 1.0)):       # vapor: dois S de neon azul
        points = [(bx + dx + math.sin(t * 0.8 + phase) * 0.026, bz + 0.06 + t * 0.055) for t in range(5)]
        for a, b in zip(points, points[1:]):
            parts.append(bar(a[0], a[1], b[0], b[1], -0.052, 0.02, 0.024, cyan))
    for x, z in ((-0.26, 0.31), (0.26, 0.31), (-0.26, -0.31), (0.26, -0.31)):
        parts.append(sphere(0.012, (cx + x, -0.03, cz + z), AS.chrome_a()))
    return parts


def digital_panel():
    """Painel digital: a tela de cardápio em moldura fina, com os itens e os preços, presa por um suporte."""
    cx, cz = S.at(21, -70)
    w, h = 0.82, 0.58
    def screen():
        u, v = coords()
        color = blend(np.broadcast_to(rgb("#071a30"), u.shape + (3,)), rgb("#0f3a63"), v)
        for i in range(3):
            z0 = 0.46 - i * 0.17
            row = (v > z0) & (v < z0 + 0.09)
            color = np.where((row & (u > 0.07) & (u < 0.6))[..., None], rgb("#dfeeff"), color)
            color = np.where((row & (u > 0.72) & (u < 0.92))[..., None], rgb("#ffbe55"), color)
        head = (v > 0.74) & (v < 0.88) & (u > 0.07) & (u < 0.45)
        color = np.where(head[..., None], rgb("#31d7ff"), color).astype(np.float32)
        return color, np.zeros(u.shape, dtype=np.float32), np.full(u.shape, 0.12, dtype=np.float32), color
    def uv_panel():
        # A tela tem as coordenadas próprias: de 0 a 1 em largura e altura.
        mesh = bpy.data.meshes.new("Tela")
        mesh.from_pydata([(0.0, -0.034, 0.0), (1.0, -0.034, 0.0), (1.0, -0.034, 1.0), (0.0, -0.034, 1.0)], [], [(0, 1, 2, 3)])
        mesh.update()
        obj = bpy.data.objects.new("Tela", mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj.data.materials.append(painted("painel", screen, emit=1.0, plane="XZ_UNIT"))
        obj.location = (cx - w / 2, 0.0, cz - h / 2)
        obj.scale = (w, 1.0, h)
        return obj
    parts = [box((w + 0.05, 0.03, h + 0.05), (cx, -0.015, cz), solid("#10121a", 0.25, 0.3, 0.6), 0.008), uv_panel()]
    parts.append(box((w + 0.012, 0.004, 0.006), (cx, -0.033, cz - h / 2 - 0.012), brushed_steel(), 0.0))
    return parts


def hanging_plant():
    """Planta pendurada: vaso de barro no suporte de corda, com os ramos caindo em cascata."""
    cx, _ = S.at(21, 0)
    y = -0.16
    top = WALL_Z * 0.94
    rope = solid("#c9b48a", 0.85)
    iron = cast_iron()
    pot_z = top - 0.62
    parts = [box((0.05, 0.03, 0.1), (cx, -0.015, top + 0.02), iron, 0.006), tube((cx, -0.02, top + 0.04), (cx, y, top + 0.05), 0.008, iron)]
    for angle in (90, 210, 330):
        rad = math.radians(angle)
        parts.append(tube((cx, y, top + 0.04), (cx + math.cos(rad) * 0.13, y + math.sin(rad) * 0.13, pot_z + 0.1), 0.004, rope))
    for p in EA.pot(0.13, 0.15, EA.terracotta()):
        p.location.x += cx
        p.location.y += y
        p.location.z += pot_z
        parts.append(p)
    leaf_mat = E.foliage("#3f7f3c")
    parts += E.rosette((cx, y, pot_z + 0.13), 8, 0.2, 0.05, 30, leaf_mat, phase=0.3)
    parts += E.rosette((cx, y, pot_z + 0.13), 12, 0.3, 0.05, 74, leaf_mat, droop=0.6)
    for side, length in ((-1, 0.42), (1, 0.3), (-0.35, 0.34), (0.5, 0.48)):
        x0, y0 = cx + side * 0.13, y - 0.05
        steps = int(length / 0.05)
        for i in range(steps):
            z = pot_z + 0.12 - i * 0.05
            drift = math.sin(i * 0.9 + side) * 0.012
            parts.append(sphere(0.006, (x0 + drift, y0, z), solid("#3a6a34", 0.7)))
            parts.append(E.leaf((x0 + drift, y0, z), (0.7 if i % 2 else -0.7, -0.5, -0.45), 0.08, 0.028, leaf_mat))
    return parts


def old_radio():
    """Rádio antigo: gabinete de madeira em arco na prateleira de mão-francesa, com a tela de pano e o dial aceso."""
    _, z = S.at(5, -50)
    iron = cast_iron()
    wood = rich_wood("#6f3f1e", 6.0, 0.7)
    dark = rich_wood(A.WALNUT_DARK, 6.0, 0.5)
    cx = 0.5
    y = -0.1
    parts = [box((0.82, 0.2, 0.045), (0.5, -0.1, z), rich_wood(A.HONEY, 5.0, 0.5), 0.01)]
    for x in (0.16, 0.84):
        parts.append(box((0.028, 0.03, 0.13), (x, -0.015, z - 0.085), iron, 0.004))
        parts.append(tube((x, -0.02, z - 0.14), (x, -0.16, z - 0.02), 0.008, iron))
    base = z + 0.022
    w, h = 0.5, 0.26
    front = y - 0.07
    parts.append(box((w, 0.14, h), (cx, y, base + h / 2), wood, 0.012))
    parts.append(sphere(1.0, (cx, y, base + h), wood, (w / 2, 0.07, 0.13)))     # o arco de cima
    grille = M.weave("#c9b184")
    parts.append(box((w - 0.22, 0.008, h - 0.1), (cx - 0.07, front - 0.002, base + h / 2 + 0.02), grille, 0.003))
    for i in range(4):
        parts.append(box((0.012, 0.012, h - 0.09), (cx - 0.16 + i * 0.06, front - 0.008, base + h / 2 + 0.02), dark, 0.002))
    parts.append(box((0.13, 0.008, 0.07), (cx + 0.15, front - 0.002, base + h / 2 + 0.08), emission("#f2c56e", 1.6), 0.003))
    parts.append(box((0.003, 0.01, 0.07), (cx + 0.15, front - 0.006, base + h / 2 + 0.08), solid("#a03020", 0.5), 0.0))
    for dx, dz in ((0.1, -0.03), (0.2, -0.03)):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.026, depth=0.024, location=(cx + dx, front - 0.012, base + h / 2 + dz), rotation=(math.radians(90), 0, 0), vertices=24)
        parts.append(M._finish(bpy.context.active_object, AS.gold(), 0.005))
    parts.append(box((w + 0.02, 0.15, 0.022), (cx, y, base + 0.011), dark, 0.006))
    return parts


def flat_tv():
    """TV de tela plana: bem fina, com o suporte de parede e uma imagem de vitrine de café."""
    cx, cz = S.at(21, -64)
    w, h = 0.82, 0.48
    def picture():
        u, v = coords()
        color = blend(np.broadcast_to(rgb("#2b1a12"), u.shape + (3,)), rgb("#8d5a30"), v)
        glow = np.exp(-(((u - 0.32) * 4.0) ** 2 + ((v - 0.62) * 5.0) ** 2))
        color = np.clip(color + glow[..., None] * rgb("#ffc070") * 0.6, 0, 1)
        cup = ((u - 0.62) * 3.2) ** 2 + ((v - 0.38) * 5.0) ** 2 < 0.5
        color = np.where(cup[..., None], rgb("#efe5d3"), color)
        coffee = ((u - 0.62) * 3.8) ** 2 + ((v - 0.47) * 12.0) ** 2 < 0.45
        color = np.where(coffee[..., None], rgb("#3a2112"), color).astype(np.float32)
        return color, np.zeros(u.shape, dtype=np.float32), np.full(u.shape, 0.1, dtype=np.float32), color
    mesh = bpy.data.meshes.new("Tela")
    mesh.from_pydata([(0.0, -0.052, 0.0), (1.0, -0.052, 0.0), (1.0, -0.052, 1.0), (0.0, -0.052, 1.0)], [], [(0, 1, 2, 3)])
    mesh.update()
    screen = bpy.data.objects.new("Tela", mesh)
    bpy.context.scene.collection.objects.link(screen)
    screen.data.materials.append(painted("tv", picture, emit=0.85, plane="XZ_UNIT"))
    screen.location = (cx - w / 2, 0.0, cz - h / 2)
    screen.scale = (w, 1.0, h)
    return [box((0.2, 0.03, 0.14), (cx, -0.015, cz), cast_iron(), 0.004),
            box((w + 0.03, 0.022, h + 0.03), (cx, -0.04, cz), solid("#121318", 0.28, 0.2, 0.7), 0.006),
            screen,
            box((0.05, 0.004, 0.008), (cx, -0.053, cz - h / 2 - 0.006), emission("#d9e6f2", 2.0), 0.0)]


WALL_ITEMS = {
    "janela_redonda": lambda: round_window(rich_wood(A.WALNUT, 6.0, 0.5), rich_wood(A.WALNUT_DARK, 6.0, 0.4), window_glass()),
    "janela_diner": lambda: round_window(solid("#8e1a24", 0.3, 0.0, 0.8), AS.chrome_a(), window_glass(), rivets=AS.chrome_a()),
    "janela_neon": lambda: round_window(solid("#17121f", 0.35, 0.0, 0.6), emission("#a95cff", 5.0), solid("#2a1b4a", 0.08, 0.0, 1.0), cross=False),
    "janela_groovy": lambda: round_window(solid("#b45a22", 0.36, 0.0, 0.6), solid("#d9a22c", 0.4, 0.0, 0.5), emission("#e59a45", 0.7), cross=False),
    "janela_arcade": lambda: round_window(solid("#14141c", 0.35, 0.0, 0.6), emission("#3fdfff", 4.0), solid("#5a1d4a", 0.08, 0.0, 1.0)),
    "janela_shoji": lambda: round_window(rich_wood("#4d311c", 6.0, 0.25), rich_wood("#3a2415", 6.0, 0.2), washi_pane(), lattice=rich_wood("#4d311c", 6.0, 0.2)),
    "janela_country": window_country,
    "janela_festa": window_party,
    "janela_industrial": window_industrial,
    "janelao": lambda: arched_window(solid("#e2dbcc", 0.42, 0.0, 0.3), rich_wood(A.WALNUT, 6.0, 0.4), ("#c9506a", "#e8c96a")),
    "janelao_italiano": lambda: arched_window(solid("#2c5a38", 0.42, 0.0, 0.4), solid("#c9b693", 0.7), ("#b6402f", "#e2c9a0"), EA.terracotta(), shutters=(solid("#2c5a38", 0.45, 0.0, 0.3), solid("#366b44", 0.45, 0.0, 0.3))),
    "janelao_mexicano": lambda: arched_window(solid("#1f4c8c", 0.4, 0.0, 0.4), solid("#a4532a", 0.7), ("#d9962c", "#b6302f"), EA.terracotta(), tile_sill=True),
    "janelao_brasileiro": lambda: arched_window(solid("#2c7040", 0.4, 0.0, 0.4), rich_wood(A.WALNUT, 6.0, 0.4), ("#e2b52e", "#ffffff"), shutters=(solid("#2c7040", 0.45, 0.0, 0.3), solid("#378a50", 0.45, 0.0, 0.3))),
    "janelao_frances": lambda: arched_window(solid("#1e1f26", 0.34, 0.0, 0.6), solid("#c9c0ad", 0.3, 0.0, 0.5), balcony=cast_iron("#1b1c22")),
    "espelho": oval_mirror,
    "lousa": chalkboard,
    "neon_xicara": neon_cup,
    "painel_digital": digital_panel,
    "planta_pendurada": hanging_plant,
    "radio": old_radio,
    "tv": flat_tv,
}


# --- Portas: o mesmo vão da amostra, com o caráter de cada coleção ---------------------------------------------------

def scallops(z, color_a, color_b, y=-0.36, count=8):
    """Sanefa de meia-lua na ponta do toldo."""
    parts = []
    w = 1.12 / count
    for i in range(count):
        parts.append(disc(-0.06 + w * (i + 0.5), z, w / 2, y, solid((color_a, color_b)[i % 2], 0.7), 180.0, 360.0, steps=16))
    return parts


def tile_roof(top, mat, y=-0.2):
    """Telhadinho de telhas: as fileiras de cano partido, descendo para a frente."""
    parts = []
    for row in range(3):
        z = top + 0.17 - row * 0.05
        dy = -0.08 - row * 0.08
        for i in range(11):
            x = -0.04 + i * 0.108
            bpy.ops.mesh.primitive_cylinder_add(radius=0.056, depth=0.13, location=(x, dy, z), rotation=(math.radians(68), 0, 0), vertices=14)
            parts.append(M._finish(bpy.context.active_object, mat, 0.002))
    return parts


def door_leaf(top, leaf_mat, glass, panes=1, x=0.9, leaf_w=0.42):
    """A folha aberta contra o batente da direita: moldura e vidro, em uma ou mais divisões."""
    y = 0.05 + leaf_w / 2
    parts = [box((0.03, leaf_w, top - 0.05), (x, y, (top - 0.05) / 2 + 0.02), leaf_mat, 0.006),
             box((0.036, leaf_w - 0.1, top * 0.58), (x, y, top * 0.6), glass, 0.002)]
    for i in range(1, panes):
        parts.append(box((0.04, 0.012, top * 0.58), (x, y - (leaf_w - 0.1) / 2 + i * (leaf_w - 0.1) / panes, top * 0.6), leaf_mat, 0.001))
    return parts


def wedge(top, stripes):
    canopy = box((1.12, 0.34, 0.025), (0.5, -0.2, top + 0.03), S.pattern("stripes", list(stripes), 7, rough=0.7), 0.006)
    canopy.rotation_euler = (math.radians(-24), 0, 0)
    return [canopy, box((1.12, 0.014, 0.08), (0.5, -0.355, top - 0.05), S.pattern("stripes", list(stripes), 7, rough=0.7), 0.004)]


def door_a(style, closed):
    """Entrada: batente, lintel, a folha aberta, o que cobre a porta e a plaquinha. O vão continua livre, e a plaquinha fica
    no mesmo lugar em todas, porque é o que o jogador olha para saber se o café está aberto."""
    top = 78 / S.DESIGN_H * WALL_Z
    glass = solid("#a8bcc6", 0.06, 0.0, 1.0)
    extras = []
    sign_plate, sign_text = solid("#20170f", 0.5), emission("#e0603a" if closed else "#f2c56e", 1.4)
    iron = cast_iron()
    panes = 1
    if style == "frances":
        post = solid("#1e1f26", 0.32, 0.0, 0.7)
        leaf = solid("#272831", 0.34, 0.0, 0.6)
        gold = AS.gold()
        panes = 3
        extras += wedge(top, ("#1e1f26", "#d9d0bc"))
        extras += scallops(top - 0.09, "#1e1f26", "#d9d0bc")
        extras += [box((1.13, 0.02, 0.016), (0.5, -0.1, top + 0.11), gold, 0.003)]
        for x in (0.05, 0.95):
            extras += [box((0.02, 0.15, top * 0.82), (x, -0.024, top * 0.47), gold, 0.002)]
    elif style == "japones":
        post = rich_wood("#5a3a22", 6.0, 0.2)
        leaf = rich_wood("#6a4526", 6.0, 0.2)
        glass = washi_pane()
        extras += tile_roof(top, solid("#2d3036", 0.55, 0.3))
        indigo = solid("#1f2d58", 0.85)
        for x in (0.2, 0.4, 0.6, 0.8):            # noren: só no alto, para não fechar o vão
            extras.append(curtain(x - 0.095, x + 0.095, top - 0.26, top - 0.01, -0.05, indigo, 2, 0.008))
    elif style == "italiano":
        post = solid("#2c5a38", 0.42, 0.0, 0.5)
        leaf = rich_wood(A.WALNUT, 6.0, 0.5)
        panes = 2
        extras += wedge(top, ("#2c5a38", "#e2dac6"))
        for x in (-0.03, 1.03):
            for p in EA.pot(0.075, 0.1, EA.terracotta()):
                p.location = (x, -0.12, p.location.z)
                extras.append(p)
            extras += E.rosette((x, -0.12, 0.1), 9, 0.16, 0.03, 40, E.foliage("#3d7a3a"))
    elif style == "anos70":
        post = solid("#8e4a1a", 0.36, 0.0, 0.6)
        leaf = rich_wood("#6f3f1e", 6.0, 0.5)
        glass = solid("#c67a2c", 0.14, 0.0, 1.0)
        extras += wedge(top, ("#b45a22", "#e2bf74"))
        extras += [box((1.13, 0.04, 0.03), (0.5, -0.09, top + 0.02), solid("#d9a22c", 0.4, 0.0, 0.5), 0.006)]
    elif style == "americano":
        post = solid("#5fa893", 0.34, 0.0, 0.7)
        leaf = solid("#5fa893", 0.34, 0.0, 0.6)
        chrome = AS.chrome_a()
        extras += wedge(top, ("#a6222d", "#e6dfd0"))
        extras += scallops(top - 0.09, "#a6222d", "#e6dfd0")
        extras += [box((1.13, 0.02, 0.022), (0.5, -0.1, top + 0.06), chrome, 0.004)]
        for x in (0.05, 0.95):
            extras.append(box((0.03, 0.15, top), (x, -0.024, top / 2), chrome, 0.004))
    elif style == "anos2010":
        post = cast_iron("#25262b")
        leaf = cast_iron("#2d2e34")
        panes = 2
        extras += [box((1.14, 0.42, 0.03), (0.5, -0.2, top + 0.09), brushed_steel(), 0.005)]
        extras += [tube((0.1, -0.02, top + 0.34), (0.1, -0.38, top + 0.1), 0.006, iron), tube((0.9, -0.02, top + 0.34), (0.9, -0.38, top + 0.1), 0.006, iron)]
        sign_plate = cast_iron("#1a1b20")
    elif style == "festa":
        post = solid("#d9a22c", 0.4, 0.0, 0.5)
        leaf = solid("#c9506a", 0.4, 0.0, 0.5)
        extras += wedge(top, ("#c9506a", "#efd98d"))
        extras += scallops(top - 0.09, "#c9506a", "#efd98d")
        for x, color in ((-0.06, "#c9506a"), (-0.1, "#3f9fb8"), (1.06, "#d8a32f"), (1.1, "#7f58b8")):
            extras.append(sphere(0.06, (x, -0.1, top - 0.04 + (x % 0.07)), solid(color, 0.25, 0.0, 0.7), (1, 1, 1.2)))
    elif style == "anos80":
        post = solid("#3a2069", 0.36, 0.0, 0.6)
        leaf = solid("#1d0f30", 0.3, 0.0, 0.7)
        glass = solid("#54206a", 0.08, 0.0, 1.0)
        cyan, pink = emission("#3fdfff", 5.0), emission("#ef49c0", 5.0)
        extras += [box((1.14, 0.42, 0.03), (0.5, -0.2, top + 0.09), solid("#120b1f", 0.36, 0.0, 0.6), 0.005),
                   box((1.14, 0.02, 0.018), (0.5, -0.41, top + 0.09), pink, 0.002)]
        for x in (-0.012, 1.012):
            extras.append(box((0.016, 0.02, top), (x, -0.095, top / 2), cyan, 0.003))
        extras.append(box((1.06, 0.02, 0.016), (0.5, -0.105, top + 0.0), cyan, 0.003))
        sign_plate = solid("#120b1f", 0.4)
        sign_text = emission("#ef49c0" if closed else "#3fdfff", 3.0)
    elif style == "balada":
        post = solid("#14121c", 0.36, 0.0, 0.6)
        leaf = M.fabric("plain", "#2d1a44")
        glass = solid("#191426", 0.1, 0.0, 1.0)
        neon = emission("#9a4dff", 6.0)
        for x in (-0.014, 1.014):
            extras.append(box((0.018, 0.022, top + 0.06), (x, -0.095, top / 2 + 0.03), neon, 0.003))
        extras += [box((1.08, 0.022, 0.018), (0.5, -0.105, top + 0.145), neon, 0.003),
                   box((1.14, 0.2, 0.05), (0.5, -0.12, top + 0.1), solid("#0d0b14", 0.4, 0.0, 0.4), 0.008)]
        sign_plate = solid("#0d0b14", 0.4)
        sign_text = emission("#ef49c0" if closed else "#c79aff", 3.0)
    elif style == "brasileiro":
        post = solid("#2c7040", 0.42, 0.0, 0.4)
        leaf = rich_wood(A.WALNUT, 6.0, 0.4)
        panes = 2
        extras += wedge(top, ("#2c7040", "#e2b52e"))
        for x in (-0.05, 1.05):
            extras += E.rosette((x, -0.09, 0.02), 10, 0.42, 0.04, 26, E.foliage("#3f8a44"))
    elif style == "country":
        post = log_material("#7d5230", 340)
        leaf = rich_wood("#6a4526", 6.0, 0.12)
        glass = window_glass()
        # O alpendre de tábuas, escorado em dois braços de madeira.
        board = rich_wood("#815329", 6.0, 0.12)
        for i in range(10):
            plank = box((0.115, 0.42, 0.018), (-0.03 + i * 0.118, -0.2, top + 0.09), board, 0.003)
            plank.rotation_euler = (math.radians(-18), 0, 0)
            extras.append(plank)
        extras += [tube((0.08, -0.03, top - 0.1), (0.08, -0.34, top + 0.02), 0.014, board), tube((0.92, -0.03, top - 0.1), (0.92, -0.34, top + 0.02), 0.014, board)]
        extras += [tube((1.05, -0.04, top - 0.05), (1.05, -0.12, top - 0.05), 0.006, iron), cylinder(0.04, top - 0.2, top - 0.1, E.glass("#ffdca6", 0.2), (1.05, -0.12)),
                   sphere(0.02, (1.05, -0.12, top - 0.15), emission("#ffc06a", 26.0))]
    elif style == "mexicano":
        post = S.plaster("#a4532a")
        leaf = rich_wood("#5a3518", 6.0, 0.25)
        blue = solid("#1f4c8c", 0.38, 0.0, 0.5)
        extras += tile_roof(top, solid("#99502c", 0.6))
        extras += [box((1.13, 0.17, 0.03), (0.5, -0.03, top + 0.0), blue, 0.005)]
        for i, (x, color) in enumerate(((0.05, "#21508f"), (0.95, "#21508f"))):
            for row in range(5):
                extras.append(box((0.1, 0.012, 0.09), (x, -0.094, 0.14 + row * 0.1), solid(("#21508f", "#efe7d4", "#d9962c")[row % 3], 0.2, 0.0, 0.8), 0.002))
    else:
        raise KeyError(style)
    parts = [box((0.12, 0.14, top), (x, -0.02, top / 2), post, 0.012) for x in (0.05, 0.95)]
    parts.append(box((1.1, 0.16, 0.13), (0.5, -0.02, top + 0.065), post, 0.012))
    parts += door_leaf(top, leaf, glass, panes)
    sign_z = top - 0.24
    parts.append(tube((0.42, -0.08, top - 0.02), (0.5, -0.08, sign_z + 0.08), 0.004, iron))
    parts.append(tube((0.58, -0.08, top - 0.02), (0.5, -0.08, sign_z + 0.08), 0.004, iron))
    parts.append(box((0.42, 0.024, 0.17), (0.5, -0.08, sign_z), sign_plate, 0.012))
    parts.append(label("FECHADO" if closed else "ABERTO", 0.5, -0.095, sign_z - 0.04, 0.085 if closed else 0.1, sign_text))
    return parts + extras


DOOR_STYLES = ("frances", "japones", "italiano", "anos70", "americano", "anos2010", "festa", "anos80", "balada", "brasileiro", "country", "mexicano")


# --- Terraço --------------------------------------------------------------------------------------------------------

def terrace_deck(variant):
    return painted(f"deck{variant}", lambda: planks_tex("#8c6340", 6, 400, variant, gap="#120b06", amount=0.12, grain=0.34, weathered=0.25, nails=True),
                   bump=0.8, distance=0.02, coat=0.05)


def garden_fence():
    """Cerca do terraço: ripas de ponta pintadas, gastas de sol, e a floreira na frente."""
    paint = solid("#d9d3c4", 0.62)
    parts = []
    for z in (0.2, 0.4):
        parts.append(box((WIDTH, 0.03, 0.05), (0.5, -0.02, z), paint, 0.006))
    for i in range(6):
        x = 0.06 + i * 0.176
        parts.append(box((0.07, 0.025, 0.5), (x, -0.04, 0.25), paint, 0.008))
        parts.append(E.cone(0.05, 0.5, 0.56, paint, (x, -0.04), vertices=4))
    parts += flower_box(0.5, 0.94, 0.0, rich_wood(A.WALNUT, 6.0, 0.2), ("#c9506a", "#e2c04e", "#f0eadf", "#7f58b8"), y=-0.12)
    return parts


# --- Fotos --------------------------------------------------------------------------------------------------------

def _setup_surface(samples, size=(300, 480), sun=None):
    kwargs = {"sun": sun} if sun is not None else {}
    cena3d.setup(samples, size, shadow_size=0.01, tiling=True, rig="a", **kwargs)


def render_floor(name, material, samples, anchors):
    _setup_surface(samples, (300, 220), S.FLOOR_SUN)
    floor_panel(material)
    aim_camera((0.5, -0.5, 0.0))
    anchors[name] = cena3d.shoot(name, (0.0, 0.0, 0.0), WORK)


def render_wall_piece(name, build, side, samples, anchors, catcher=False):
    _setup_surface(samples)
    S.shoot_wall(name, M._flatten(build()), side, samples, anchors, catcher)


def render_groups(wanted, samples, prove, manifest, anchors):
    def want(group, name):
        return not wanted or name in wanted or group in wanted

    for surface_id, build in FLOORS.items():
        names = manifest["floors"][surface_id]["sprites"]
        for index, name in enumerate(names[:1] if prove else names):
            if want("pisos", name):
                render_floor(name, build(index), samples, anchors)
                cena3d.update_manifest(anchors)
                print("PRONTO", name, flush=True)
    for surface_id, build in WALLS.items():
        for side, name in manifest["walls"][surface_id].items():
            if prove and side == "L":
                continue
            if want("paredes", name):
                render_wall_piece(name, build, side, samples, anchors)
                cena3d.update_manifest(anchors)
                print("PRONTO", name, flush=True)
    for side in ("R",) if prove else ("R", "L"):
        for item_id, build in WALL_ITEMS.items():
            name = f"enfeite_{item_id}_{side}"
            if want("itens", name):
                render_wall_piece(name, build, side, samples, anchors, catcher=True)
                cena3d.update_manifest(anchors)
                print("PRONTO", name, flush=True)
        for style in DOOR_STYLES:
            for closed in (False,) if prove else (False, True):
                name = f"enfeite_porta_{style}{'_fechada' if closed else ''}_{side}"
                if want("portas", name):
                    render_wall_piece(name, lambda: door_a(style, closed), side, samples, anchors)
                    cena3d.update_manifest(anchors)
                    print("PRONTO", name, flush=True)
    for index, name in enumerate(manifest["terrace"]["floor"]):
        if want("terraco", name):
            render_floor(name, terrace_deck(index), samples, anchors)
            cena3d.update_manifest(anchors)
    for side in ("R",) if prove else ("R", "L"):
        name = f"{manifest['terrace']['fence']}_{side}"
        if want("terraco", name):
            render_wall_piece(name, garden_fence, side, samples, anchors)
            cena3d.update_manifest(anchors)


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    samples = 24 if "rascunho" in args else 80
    prove = "prova" in args
    wanted = {a for a in args if a not in ("rascunho", "prova")}
    S.WORK = WORK
    with open(os.path.join(cena3d.SPRITES, "sprites.json"), encoding="utf-8") as source:
        manifest = json.load(source)
    anchors = {}
    render_groups(wanted, samples, prove, manifest, anchors)
    print("SUPERFICIES OK", len(anchors), flush=True)


if __name__ == "__main__":
    main()
