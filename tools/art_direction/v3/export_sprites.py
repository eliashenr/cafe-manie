"""Exporta os sprites do jogo a partir da arte v3: SVG -> PNG (pelo Chrome ou Edge, sem janela).

O desenho é feito na escala do canvas (piso de 96x48) e ampliado inteiro para a escala do jogo,
com DENSITY pixels de textura por pixel de mundo; assim os traços engrossam junto com o desenho.
As figuras saem agrupadas em folhas (uma abertura do navegador por folha). Depois,
tools/sprites/crop_sprites.gd recorta cada figura e grava res://art/sprites/.

    python export_sprites.py                 # folhas e manifesto em tools/sprites/raw/
    SPRITES_BROWSER="C:/caminho/chrome.exe" python export_sprites.py

Por que não a Godot: o desenho de SVG dela (ThorVG) deixa vazio o gradiente de formas curvas.

Convenção de rotação dos móveis (FurnitureView): a frente aponta para
0 = sudoeste (+y), 1 = noroeste (-x), 2 = nordeste (-y), 3 = sudeste (+x).
Só +y e +x ficam de frente para a câmera; nas outras duas o móvel aparece de costas.

Personagens: cada pose sai olhando para a direita da tela (sudeste, ou nordeste de costas).
O jogo espelha na horizontal para as outras direções, como o canvas já fazia.
"""
import json
import math
import os
import shutil
import subprocess
import xml.etree.ElementTree as ElementTree

from furniture3 import *  # noqa: F401,F403
from people3 import person, TRAY_EMPTY, TRAY_FOOD, WALK_FRAMES
from food3 import food, mood_face

TILE_W = 96.0
GAME_TILE_W = 128.0  # IsoProjection.TILE_SIZE.x
DENSITY = 2.0
SCALE = GAME_TILE_W / TILE_W * DENSITY  # pixels de textura por unidade do desenho
WORLD = GAME_TILE_W / TILE_W            # pixels de mundo por unidade do desenho
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "sprites", "raw"))
BROWSERS = [
    os.environ.get("SPRITES_BROWSER", ""),
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "google-chrome", "chromium", "chromium-browser", "microsoft-edge",
]
SHEET_MAX_WIDTH = 3600  # px; as folhas crescem para baixo
SHEET_MAX_HEIGHT = 6400  # px; passando disso, o assunto continua numa folha nova (o navegador não fotografa imagem gigante)
GAP = 12                # px entre figuras, para nenhuma invadir a vizinha


# --- Folhas ------------------------------------------------------------------------------

class Sheet:
    """Várias figuras numa imagem só. Cada figura tem um retângulo próprio e uma âncora.
    design_tile: largura do piso na escala em que a folha é desenhada (96 nas peças novas, 84 no canvas)."""

    def __init__(self, name, design_tile=TILE_W):
        self.name = name
        self.scale = GAME_TILE_W / design_tile * DENSITY
        self.D = Defs()
        self.items = []  # (nome, svg, x_px, y_px, w_px, h_px, left, top, anchor, repete)
        self._x = GAP
        self._y = GAP
        self._row_h = 0
        self.width = 0

    def _px(self, bounds):
        return math.ceil(bounds[2] * self.scale - 1e-6), math.ceil(bounds[3] * self.scale - 1e-6)

    def _wraps(self, w_px):
        return self._x + w_px + GAP > SHEET_MAX_WIDTH and self._x > GAP

    def fits(self, bounds, max_height):
        """A figura cabe sem a folha passar de max_height px? (Folha vazia sempre aceita.)"""
        w_px, h_px = self._px(bounds)
        y, row_h = (self._y + self._row_h + GAP, 0) if self._wraps(w_px) else (self._y, self._row_h)
        return not self.items or y + max(row_h, h_px) + GAP <= max_height

    def add(self, sprite_name, svg, bounds, anchor=(0.0, 0.0), tile=False):
        """svg em coordenadas próprias; bounds = (esquerda, topo, largura, altura) que cabem tudo.
        tile: textura de repetir (sai inteira, sem recorte, do tamanho exato de bounds)."""
        left, top, width, height = bounds
        w_px, h_px = self._px(bounds)
        if self._wraps(w_px):
            self._x = GAP
            self._y += self._row_h + GAP
            self._row_h = 0
        self.items.append((sprite_name, svg, self._x, self._y, w_px, h_px, left, top, anchor, tile))
        self._x += w_px + GAP
        self._row_h = max(self._row_h, h_px)
        self.width = max(self.width, self._x)

    def size(self):
        return self.width, self._y + self._row_h + GAP

    def svg(self):
        width, height = self.size()
        parts = []
        for (_, svg, x, y, _, _, left, top, _, _) in self.items:
            parts.append(f'<g transform="translate({f(x / self.scale - left)},{f(y / self.scale - top)})">{svg}</g>')
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
                f'viewBox="0 0 {f(width / self.scale)} {f(height / self.scale)}">{self.D.render()}{"".join(parts)}</svg>')

    def manifest(self):
        out = {}
        for (name, _, x, y, w, h, left, top, anchor, tile) in self.items:
            out[name] = {"sheet": self.name, "rect": [x, y, w, h],
                         "anchor": [round(x + (anchor[0] - left) * self.scale, 2), round(y + (anchor[1] - top) * self.scale, 2)]}
            if tile:
                out[name]["tile"] = True
        return out


class SheetGroup:
    """Folhas de um mesmo assunto: quando uma enche (SHEET_MAX_HEIGHT), as figuras seguem em outra
    (moveis, moveis_2, ...). Todas usam os mesmos gradientes, desenhados antes de saber a folha."""

    def __init__(self, name, design_tile=TILE_W):
        self.name = name
        self.design_tile = design_tile
        self.D = Defs()
        self.sheets = []
        self._open()

    def _open(self):
        sheet = Sheet(self.name if not self.sheets else f"{self.name}_{len(self.sheets) + 1}", self.design_tile)
        sheet.D = self.D
        self.sheets.append(sheet)

    def add(self, sprite_name, svg, bounds, anchor=(0.0, 0.0), tile=False):
        if not self.sheets[-1].fits(bounds, SHEET_MAX_HEIGHT):
            self._open()
        self.sheets[-1].add(sprite_name, svg, bounds, anchor, tile)


# --- Móveis ------------------------------------------------------------------------------

FACING = {0: "+y", 1: "-x", 2: "-y", 3: "+x"}
FACE = {0: "L", 3: "R"}  # face da caixa voltada para a câmera (iso.quad); 1 e 2 não aparecem
MARGIN_X = 40.0
HEADROOM = 160.0
MARGIN_BOTTOM = 24.0


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
    "counter_basic": ((1, 1), counter_sprite, 4),
    "bookshelf": ((2, 1), bookshelf_sprite, 4),
    "plant_pot": ((1, 1), plant_sprite, 1),
    "flower_vase": ((1, 1), flower_vase_sprite, 1),
    "floor_lamp": ((1, 1), floor_lamp_sprite, 1),
}
def chair_wood_back(D, iso, facing):
    return chair(D, iso, 0, 0, facing, "#ff4d5e")[1]


# id da cadeira -> encosto visto de costas (facing "-x" ou "-y"), para desenhar por cima de quem senta.
SEAT_BACKS = {"chair_wood": chair_wood_back}

# Altura do tampo (unidades do desenho), onde o jogo põe o prato de quem está comendo.
TABLE_TOPS = {"table_round": 34.0, "table_long": 32.0}
# Altura do mármore do balcão (corpo de 42 e tampo de 5), onde ficam as pilhas de pratos.
COUNTER_TOP = 47.0

# --- Coleções da loja (themes3): cadeira, mesa e enfeites de cada estilo -----------------

import themes3  # noqa: E402


def _collection_chair(style):
    def draw(D, iso, fp, rotation):
        drawn = themes3.styled_chair(D, iso, 0, 0, FACING[rotation], **style)
        return drawn if isinstance(drawn, str) else drawn[0] + drawn[1]
    return draw


def _collection_back(style):
    return lambda D, iso, facing: themes3.styled_chair(D, iso, 0, 0, facing, **style)[1]


def _collection_table(style, height):
    return lambda D, iso, fp, rotation: themes3.styled_table(D, iso, 0, 0, height=height, **style)


def _collection_decor(draw):
    return lambda D, iso, fp, rotation: draw(D, iso, 0, 0)


for _id, _style in themes3.CHAIRS.items():
    FURNITURE[_id] = ((1, 1), _collection_chair(_style), 4)
    SEAT_BACKS[_id] = _collection_back(_style)
for _id, (_style, _height) in themes3.TABLES.items():
    FURNITURE[_id] = ((1, 1), _collection_table(_style, _height), 1)
    TABLE_TOPS[_id] = float(_height)
for _id, _draw in themes3.DECOR.items():
    FURNITURE[_id] = ((1, 1), _collection_decor(_draw), 1)
def _collection_stove(style):
    return lambda D, iso, fp, rotation: stove(D, iso, 0, 0, FACE.get(rotation), **style)


def _collection_counter(style):
    def draw(D, iso, fp, rotation):
        along = "x" if fp[0] > 1 else "y"
        return counter(D, iso, 0, 0, FACE.get(rotation), cells=max(fp), along=along, **style)
    return draw


for _id, _style in themes3.STOVES.items():
    FURNITURE[_id] = ((1, 1), _collection_stove(_style), 4)
for _id, _style in themes3.COUNTERS.items():
    FURNITURE[_id] = ((1, 1), _collection_counter(_style), 4)
# Máquinas de bebida (DT-052): 1 piso, a frente aparece como a dos fogões.
import drinks3  # noqa: E402
import spices3  # noqa: E402


def _machine(draw):
    return lambda D, iso, fp, rotation: draw(D, iso, 0, 0, FACE.get(rotation))


for _id, _draw in drinks3.MACHINES.items():
    FURNITURE[_id] = ((1, 1), _machine(_draw), 4)
# Troféus aceleradores (DT-057): o mesmo desenho nas 4 rotações.
import trophies3  # noqa: E402

for _id, _draw in trophies3.TROPHIES.items():
    FURNITURE[_id] = ((1, 1), _collection_decor(_draw), 1)
# Multifogão Trem (DT-060): os vagões são fogões (a frente aparece nas rotações 0 e 3) e o prêmio é um enfeite.
import trains3  # noqa: E402


def _train(part):
    return lambda D, iso, fp, rotation: trains3.train_stove(D, iso, 0, 0, FACE.get(rotation), part)


for _id, _part in trains3.TRAIN.items():
    FURNITURE[_id] = ((1, 1), _train(_part), 4)
FURNITURE["station_clock"] = ((1, 1), _collection_decor(trains3.station_clock), 1)
# Loja de troca de cupons (DT-062): enfeites exclusivos.
import critic3  # noqa: E402

for _id, _draw in critic3.DECOR.items():
    FURNITURE[_id] = ((1, 1), _collection_decor(_draw), 1)
# Evento de Halloween (DT-063): o Caldeirão da Bruxa (fogão) e a Abóbora Gigante (enfeite).
import halloween3  # noqa: E402

FURNITURE["witch_cauldron"] = ((1, 1), lambda D, iso, fp, rotation: halloween3.cauldron_stove(D, iso, 0, 0, FACE.get(rotation)), 4)
FURNITURE["giant_pumpkin"] = ((1, 1), _collection_decor(halloween3.giant_pumpkin), 1)
# Cabine de DJ 2x1: deitada ao longo de x (rotações 0 e 2) ou de y (1 e 3).
FURNITURE["dj_booth"] = ((2, 1), lambda D, iso, fp, rotation: themes3.dj_booth(D, iso, 0, 0, "x" if fp[0] == 2 else "y"), 2)


def furniture_bounds(iso, fp):
    """Desenho na célula (0, 0); a âncora é o vértice da frente da pegada, como no FurnitureView."""
    left = iso.v(0, fp[1])[0] - MARGIN_X
    right = iso.v(fp[0], 0)[0] + MARGIN_X
    bottom = iso.v(fp[0], fp[1])[1] + MARGIN_BOTTOM
    return (left, -HEADROOM, right - left, bottom + HEADROOM), iso.v(fp[0], fp[1])


def export_furniture(sheet, manifest):
    iso = Iso(0, 0, TILE_W, TILE_W / 2)
    for item_id, (base, draw, variants) in FURNITURE.items():
        entry = {}
        for rotation in range(4):
            source = rotation % variants
            name = f"{item_id}_r{source}"
            if source == rotation:
                fp = footprint(base, rotation)
                bounds, anchor = furniture_bounds(iso, fp)
                sheet.add(name, draw(sheet.D, iso, fp, rotation), bounds, anchor)
            entry[str(rotation)] = name
        manifest["furniture"][item_id] = entry
    manifest["table_tops"] = {k: round(v * WORLD, 2) for k, v in TABLE_TOPS.items()}
    # Encosto de cada cadeira nas rotações 1 e 2 (de costas): o jogo desenha por cima de quem senta.
    # Banqueta sem encosto fica com "" (nada por cima).
    backrests = {}
    for item_id, back_of in SEAT_BACKS.items():
        backrests[item_id] = {}
        bounds, anchor = furniture_bounds(iso, (1, 1))
        for rotation in (1, 2):
            back = back_of(sheet.D, iso, FACING[rotation])
            name = f"encosto_{item_id}_r{rotation}" if back else ""
            if back:
                sheet.add(name, back, bounds, anchor)
            backrests[item_id][str(rotation)] = name
    manifest["chair_backrests"] = backrests
    # Fogão cozinhando: a panela de cada receita (com a chama) e o forno aceso, por cima do fogão apagado.
    bounds, anchor = furniture_bounds(iso, (1, 1))
    for recipe_id, kind in FOODS.items():
        sheet.add(f"panela_{recipe_id}", stove_pot(sheet.D, iso, 0, 0, kind), bounds, anchor)
    for rotation, face in FACE.items():
        sheet.add(f"fogao_aceso_r{rotation}", stove_glow(sheet.D, iso, 0, 0, face), bounds, anchor)
    manifest["cookware"] = {recipe_id: f"panela_{recipe_id}" for recipe_id in FOODS}
    manifest["stove_glow"] = {str(rotation): f"fogao_aceso_r{rotation}" for rotation in FACE}
    manifest["counter_top"] = round(COUNTER_TOP * WORLD, 2)


# --- Personagens -------------------------------------------------------------------------

# Escala do canvas (0,6 num piso de 84) levada para o piso de 96: mesma proporção pessoa/piso.
PERSON_SCALE = 0.6 * TILE_W / 84.0
# Do vértice da frente da cadeira até os pés de quem senta: assento (seat_point) + 4, como no canvas.
SEAT_DROP = 4.0
EXPRESSIONS = ("feliz", "esperando", "bravo", "comendo")
WALK = ("em_pe",) + tuple(f"passo_{i}" for i in range(WALK_FRAMES))

# Clientes: os mesmos tipos de gente das pranchas aprovadas.
CUSTOMERS = {
    "cliente_01": dict(skin="clara", hair=("rabo", "castanho"), top=("blusa", "#ff4d6d"), bottom=("calca", "#3b6fd6"),
                       lash=True, iris="#3b7fd9"),
    "cliente_02": dict(skin="morena", hair=("curto", "preto"), top=("camiseta", "#2fae4e"), bottom=("calca", "#34495e")),
    "cliente_03": dict(skin="negra", hair=("black", "preto"), top=("camiseta", "#ffc928"), bottom=("calca", "#2fae4e"),
                       lash=True, earrings="#ffc928"),
    "cliente_04": dict(skin="clara", hair=("chanel", "ruivo"), top=("blusa", "#9b5cff"), bottom=("calca", "#34495e"), lash=True),
    "cliente_05": dict(skin="parda", hair=("bone", "preto"), top=("moletom", "#ff7a2f"), bottom=("calca", "#2b2b33"),
                       cap="#2f7bff"),
    "cliente_06": dict(skin="rosada", hair=("longo", "loiro"), top=("blusa", "#2fd1b5"), bottom=("calca", "#3d5a80")),
    "cliente_07": dict(skin="morena_clara", hair=("topete", "castanho_escuro"), top=("camisa", "#35b8ff"),
                       bottom=("calca", "#34495e")),
    "cliente_08": dict(skin="clara", hair=("coque", "grisalho"), top=("blusa", "#ff5fa2"), bottom=("saia", "#6b4b8a"),
                       lash=True, glasses="#7a4bd6"),
    "cliente_09": dict(skin="morena", hair=("careca", "castanho_escuro"), top=("camisa", "#ffffff"), bottom=("calca", "#6b4423"),
                       beard="castanho_escuro"),
    "cliente_10": dict(skin="parda", hair=("moicano", "verde"), top=("camiseta", "#1d1d2b"), bottom=("calca", "#4a4a5e")),
    "cliente_11": dict(skin="morena_clara", hair=("longo", "castanho"), top=("vestido", "#ffd23f"), bottom=("saia", "#ffd23f"),
                       lash=True, iris="#2f9e62"),
    "cliente_12": dict(skin="clara", hair=("curto", "loiro"), top=("camiseta", "#4d8dff"), bottom=("calca", "#34495e")),
}
# O garçom Léo, do canvas.
WAITER = dict(skin="morena_clara", hair=("curto", "preto"), top=("garcom", "#ffffff"), bottom=("calca", "#23232b"),
              shoes="#2b2b33")

STANDING_BOUNDS = (-48.0, -140.0, 110.0, 156.0)   # pés em (0, 0); cabe a bandeja à direita
SEATED_BOUNDS = (-60.0, -150.0, 120.0, 166.0)     # vértice da frente da cadeira em (0, 0)


def _walker(D, spec, pose, back=False, tray=None, expr="feliz"):
    return person(D, 0, 0, PERSON_SCALE, 1, pose, expr=expr, back=back, tray=tray, **spec)


def _seated(D, iso, spec, expr, chair_rotation=None):
    """Sentado na cadeira cuja frente é o vértice (0, 0). De frente (chair_rotation None) olha para +x.
    De costas (rotações 1 e 2 da cadeira), só a pessoa: o jogo desenha por cima o encosto da cadeira
    em que ela sentou (encosto_<cadeira>_r1/r2), como no canvas."""
    cell = (-1.0, -1.0)  # a célula da cadeira, para o vértice da frente cair em (0, 0)
    sx, sy = seat_point(iso, *cell)
    sy += SEAT_DROP * K(iso)
    if chair_rotation is None:
        return person(D, sx, sy, PERSON_SCALE, 1, "sentado", expr=expr, **spec)
    mirror = {"-x": -1, "-y": 1}[FACING[chair_rotation]]
    return person(D, sx, sy, PERSON_SCALE, mirror, "sentado", expr=expr, back=True, **spec)


def export_people(sheet, manifest):
    iso = Iso(0, 0, TILE_W, TILE_W / 2)
    for look, spec in list(CUSTOMERS.items()) + [("garcom", WAITER)]:
        for view, back in (("frente", False), ("costas", True)):
            for pose in WALK:
                sheet.add(f"{look}_{view}_{pose}", _walker(sheet.D, spec, pose, back), STANDING_BOUNDS)
                if look == "garcom":
                    sheet.add(f"{look}_{view}_{pose}_bandeja", _walker(sheet.D, spec, pose, back, TRAY_EMPTY), STANDING_BOUNDS)
        if look == "garcom":
            continue
        for expr in EXPRESSIONS:
            sheet.add(f"{look}_sentado_{expr}", _seated(sheet.D, iso, spec, expr), SEATED_BOUNDS)
        for rotation in (1, 2):
            sheet.add(f"{look}_sentado_costas_r{rotation}", _seated(sheet.D, iso, spec, "feliz", rotation), SEATED_BOUNDS)
    tray_x, tray_y, tray_w = TRAY_FOOD
    manifest["characters"] = {
        "customers": list(CUSTOMERS),
        "waiter": "garcom",
        # Centro e largura do prato na bandeja, em pixels de mundo, com os pés em (0, 0), olhando para a direita.
        "tray_food": [round(tray_x * PERSON_SCALE * WORLD, 2), round(tray_y * PERSON_SCALE * WORLD, 2),
                      round(tray_w * PERSON_SCALE * WORLD, 2)],
    }


# --- Pratos e carinhas -------------------------------------------------------------------

# id da receita no jogo -> prato do gerador
FOODS = {"coffee": "cafe", "cheese_bread": "pao", "toasted_sandwich": "misto", "carrot_cake": "bolo",
         "coxinha": "coxinha", "lasagna": "lasanha",
         # livro de receitas (DT-053)
         "brigadeiro": "brigadeiro", "pastel": "pastel", "pizza": "pizza", "pancakes": "panqueca",
         "feijoada": "feijoada", "sushi": "sushi", "cheesecake": "cheesecake", "moqueca": "moqueca",
         "burger": "hamburguer", "croissant": "croissant", "escondidinho": "escondidinho", "tacos": "tacos",
         # receitas do nível 18 ao 30 (DT-054)
         "acai": "acai", "ramen": "ramen", "pudding": "pudim", "bobo": "bobo",
         "waffles": "waffle", "paella": "paella", "lemon_pie": "torta_limao", "picanha": "picanha",
         "eggs_benedict": "benedict", "curry": "curry", "black_forest": "floresta", "barbecue": "churrasco",
         "lobster": "lagosta",
         # Fogão Japonês (DT-059)
         "mochi": "mochi", "misso_soup": "misso", "yakisoba": "yakisoba", "tempura": "tempura"}
FOOD_SIZE = 48.0
# id da bebida no jogo -> desenho em drinks3
DRINKS = {"espresso": "expresso", "cappuccino": "cappuccino", "hot_chocolate": "chocolate",
          "orange_juice": "laranja", "lemonade": "limonada", "strawberry_smoothie": "morango"}
# id do tempero no jogo -> desenho em spices3 (DT-056)
SPICES = {"salt": "sal", "pepper": "pimenta", "paprika": "paprica", "instant": "instantaneo", "herbs": "ervas"}
MOODS = ("feliz", "esperando", "bravo")
MOOD_RADIUS = 11.0


def export_food(sheet, manifest):
    for recipe_id, kind in FOODS.items():
        bounds = (-FOOD_SIZE * 0.6, -FOOD_SIZE * 0.66, FOOD_SIZE * 1.2, FOOD_SIZE * 1.2)
        sheet.add(f"prato_{recipe_id}", food(sheet.D, kind, 0, 0, FOOD_SIZE), bounds)
    for mood in MOODS:
        r = MOOD_RADIUS * 1.4
        sheet.add(f"humor_{mood}", mood_face(sheet.D, 0, 0, mood, MOOD_RADIUS), (-r, -r, 2 * r, 2 * r))
    for drink_id, kind in DRINKS.items():
        bounds = (-FOOD_SIZE * 0.6, -FOOD_SIZE * 0.66, FOOD_SIZE * 1.2, FOOD_SIZE * 1.2)
        sheet.add(f"bebida_{drink_id}", drinks3.drink(sheet.D, kind, 0, 0, FOOD_SIZE), bounds)
    for spice_id, kind in SPICES.items():
        bounds = (-FOOD_SIZE * 0.6, -FOOD_SIZE * 0.66, FOOD_SIZE * 1.2, FOOD_SIZE * 1.2)
        sheet.add(f"tempero_{spice_id}", spices3.spice(sheet.D, kind, 0, 0, FOOD_SIZE), bounds)
    manifest["food"] = {recipe_id: f"prato_{recipe_id}" for recipe_id in FOODS}
    manifest["drinks"] = {drink_id: f"bebida_{drink_id}" for drink_id in DRINKS}
    manifest["spices"] = {spice_id: f"tempero_{spice_id}" for spice_id in SPICES}
    # Largura de cada prato, em pixels de mundo, quando desenhado em tamanho natural.
    manifest["food_width"] = round(FOOD_SIZE * WORLD, 2)


# --- Piso, paredes e exterior --------------------------------------------------------------

import tiles3  # noqa: E402

# Enfeites ao longo de cada parede, a partir do canto do fundo; o jogo repete o ciclo se ela crescer.
WALL_DECORATIONS = {
    "R": ["relogio", "", "janela", "prateleira", "quadro_cupcake", "", "janela", ""],
    "L": ["", "quadro_paisagem", "janela", "", "prateleira", "janela", "", "quadro_cupcake"],
}
TILE_BOUNDS = (-46.0, -4.0, 92.0, 50.0)  # um piso de 84x42 com sobra; âncora no vértice de cima
# Com folga dos lados: o varão da cortina e as folhas da prateleira passam um pouco da largura do piso.
WALL_BOUNDS = {"R": (-10.0, -110.0, 62.0, 142.0), "L": (-10.0, -133.0, 62.0, 142.0)}
# Lado das texturas de repetir: 42 unidades = 128 px de textura = 64 px de mundo. A grama usa o dobro,
# para os tufos não formarem um desenho repetido.
TEXTURE = 42.0
LAWN_TEXTURE = 84.0


def export_scene(sheet, manifest):
    """Peças na escala do canvas (piso de 84): o jogo converte com o 'scale' da folha."""
    iso = Iso(0, 0, tiles3.TW, tiles3.TH)
    D = sheet.D
    floors = {}
    for surface_id, (variants, draw) in tiles3.FLOORS.items():
        keys = ["a", "b"] if variants == "xadrez" else list(range(variants))
        names = []
        for key in keys:
            name = f"piso_{surface_id}_{key}"
            sheet.add(name, draw(D, iso, key), TILE_BOUNDS)
            names.append(name)
        floors[surface_id] = {"mode": "xadrez" if variants == "xadrez" else "variantes", "sprites": names}
    sheet.add("piso_entrada", tiles3.entrance_mat(D, iso), TILE_BOUNDS)
    walls = {}
    for surface_id, draw in tiles3.WALLS.items():
        walls[surface_id] = {}
        for side in ("R", "L"):
            name = f"parede_{surface_id}_{side}"
            dark = tiles3.LEFT_DARK if side == "L" else 0.0
            sheet.add(name, tiles3.wall_piece(side, draw(D, dark)), WALL_BOUNDS[side])
            walls[surface_id][side] = name
    for deco, draw in tiles3.DECORATIONS.items():
        for side in ("R", "L"):
            sheet.add(f"enfeite_{deco}_{side}", tiles3.wall_piece(side, draw(D, side)), WALL_BOUNDS[side])
    sheet.add("gramado", tiles3.lawn_tile(D, LAWN_TEXTURE), (0.0, 0.0, LAWN_TEXTURE, LAWN_TEXTURE), tile=True)
    sheet.add("asfalto", tiles3.asphalt_tile(D, TEXTURE), (0.0, 0.0, TEXTURE, TEXTURE), tile=True)
    sheet.add("poste", tiles3.lamp_post(D, 0, 0, 0.85), (-34.0, -134.0, 68.0, 142.0))
    sheet.add("canteiro", tiles3.flower_bed(D, 0, 0, 0.9), (-38.0, -36.0, 76.0, 54.0))
    world = GAME_TILE_W / tiles3.TW  # pixels de mundo por unidade desta folha
    manifest["floors"] = floors
    manifest["floor_entrance"] = "piso_entrada"
    manifest["walls"] = walls
    manifest["wall_height"] = round(tiles3.WALL_H * world, 2)
    manifest["wall_decorations"] = WALL_DECORATIONS
    manifest["exterior"] = {"lawn": "gramado", "lawn_world": round(LAWN_TEXTURE * world, 2),
                            "asphalt": "asfalto", "asphalt_world": round(TEXTURE * world, 2),
                            "lamp": "poste", "flower_bed": "canteiro"}


# --- Cidade em volta do café (city3) ------------------------------------------------------

import city3  # noqa: E402

CITY_TEXTURE = 48.0  # lado da textura do concreto: 64 px de mundo
CAR_DIRECTIONS = {"+x": "xp", "-x": "xn", "+y": "yp", "-y": "yn"}


def export_city(sheet, manifest):
    """Prédios (âncora no vértice da frente da pegada), enfeites e carros (âncora no chão) e o concreto."""
    iso = Iso(0, 0, TILE_W, TILE_W / 2)
    D = sheet.D
    buildings = {}
    for name, (fp, height, draw) in city3.BUILDINGS.items():
        left = iso.v(0, fp[1])[0] - MARGIN_X
        right = iso.v(fp[0], 0)[0] + MARGIN_X
        bottom = iso.v(fp[0], fp[1])[1] + MARGIN_BOTTOM
        top = -height - 40.0
        sheet.add(name, draw(D, iso), (left, top, right - left, bottom - top), iso.v(fp[0], fp[1]))
        buildings[name] = [fp[0], fp[1]]
    for name, (draw, bounds) in city3.PROPS.items():
        sheet.add(name, draw(D, iso), bounds)
    cars = {}
    for car_id, (body, taxi) in city3.CARS.items():
        cars[car_id] = {}
        for direction, suffix in CAR_DIRECTIONS.items():
            name = f"{car_id}_{suffix}"
            sheet.add(name, city3.car(D, iso, direction, body, taxi), city3.CAR_BOUNDS)
            cars[car_id][direction] = name
    sheet.add("concreto", city3.concrete_tile(D, CITY_TEXTURE), (0.0, 0.0, CITY_TEXTURE, CITY_TEXTURE), tile=True)
    manifest["city"] = {"buildings": buildings, "props": list(city3.PROPS), "cars": cars, "concrete": "concreto",
                        "concrete_world": round(CITY_TEXTURE * WORLD, 2)}


# --- Interface -----------------------------------------------------------------------------

import ui3  # noqa: E402

STRIPE_TILE = 32.0  # lado da textura das listras das barras (em px da interface)


def export_ui(sheet, manifest):
    """Peças da interface, em px da tela de 1280x720 (a folha sai com 2 px de textura por px)."""
    D = sheet.D
    box = (-2.0, -2.0, 68.0, 70.0)
    for name, draw in ui3.ICONS.items():
        sheet.add(f"icone_{name}", draw(D), box, (32.0, 32.0))
    for kind, color in ui3.BUTTONS:
        sheet.add(f"botao_{kind}", ui3.square_button(D, kind, color), (0.0, 0.0, 64.0, 66.0), (32.0, 32.0))
    for name, draw in ui3.MEDALLIONS.items():
        sheet.add(f"medalhao_{name}", draw(D), (-4.0, -4.0, 74.0, 76.0), (32.0, 32.0))
    # retrato de quem conta a historinha do evento (DT-063)
    sheet.add("retrato_bruxa", halloween3.witch_portrait(D), (-70.0, -110.0, 140.0, 170.0), (0.0, 0.0))
    for name, (width, color) in ui3.RIBBONS.items():
        sheet.add(f"fita_{name}", ui3.ribbon_band(D, width, color), (-width / 2 - 10, -2.0, width + 20, 26.0), (0.0, 0.0))
    for name, (light, dark) in ui3.STRIPES.items():
        sheet.add(f"listras_{name}", ui3.stripes_tile(STRIPE_TILE, light, dark), (0.0, 0.0, STRIPE_TILE, STRIPE_TILE), tile=True)
    manifest["ui"] = {"density": DENSITY, "stripes_size": STRIPE_TILE}


# --- Saída -------------------------------------------------------------------------------

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
    manifest = {"density": DENSITY, "sheets": {}, "sprites": {}, "furniture": {}}
    # A interface usa px da tela: design_tile = GAME_TILE_W dá 2 px de textura por px.
    furniture = SheetGroup("moveis")
    people = SheetGroup("personagens")
    city = SheetGroup("cidade")
    sheets = [Sheet("pratos"), Sheet("cenario", tiles3.TW), Sheet("interface", GAME_TILE_W)]
    export_furniture(furniture, manifest)
    export_people(people, manifest)
    export_city(city, manifest)
    export_food(sheets[0], manifest)
    export_scene(sheets[1], manifest)
    export_ui(sheets[2], manifest)
    for sheet in furniture.sheets + people.sheets + city.sheets + sheets:
        svg_path = os.path.join(out_dir, sheet.name + ".svg")
        markup = sheet.svg()
        try:
            ElementTree.fromstring(markup)
        except ElementTree.ParseError as error:
            # O navegador desenharia uma página de erro no lugar das figuras.
            raise SystemExit(f"SVG inválido na folha {sheet.name}: {error}")
        with open(svg_path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(markup)
        rasterize(browser, svg_path, os.path.join(out_dir, sheet.name + ".png"), sheet.size())
        manifest["sheets"][sheet.name] = sheet.name + ".png"
        manifest["sprites"].update(sheet.manifest())
    with open(os.path.join(out_dir, "sprites.json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump(manifest, fh, indent=1, ensure_ascii=False)
        fh.write("\n")
    return manifest


if __name__ == "__main__":
    result = export()
    print(f"{len(result['sprites'])} sprites em {len(result['sheets'])} folhas, em {OUT}")
