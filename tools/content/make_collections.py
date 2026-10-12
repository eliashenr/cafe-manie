"""Cria os arquivos de dados das coleções da loja (estilos e culturas) e dos itens delas.

A tabela abaixo é o ponto de partida. Depois de criados, os .tres de res://data são a fonte de verdade:
preços, níveis e beleza podem ser ajustados no inspetor da Godot. Por isso o script só cria o que falta;
para reescrever tudo a partir da tabela, use --refazer.

    python tools/content/make_collections.py
    python tools/content/make_collections.py --refazer
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.normpath(os.path.join(HERE, "..", "..", "data"))

# id, nome, cor, ordem
COLLECTIONS = [
    ("classico", "Clássico", "8a6a4a", 0),
    ("anos70", "Anos 70", "e07a2e", 1),
    ("country", "Country", "a8662e", 2),
    ("festa", "Festa", "ff5fa2", 3),
    ("americano", "Americano", "e0303a", 4),
    ("mexicano", "Mexicano", "11998e", 5),
    ("anos80", "Anos 80", "b04dff", 6),
    ("italiano", "Italiano", "2f9e44", 7),
    ("japones", "Japonês", "c2185b", 8),
    ("frances", "Francês", "4a7bd9", 9),
    ("brasileiro", "Brasileiro", "f2b600", 10),
    ("anos2010", "Anos 2010", "6b8c9e", 11),
    ("balada", "Balada", "7a2fd0", 12),
]

TABLE, SEATING, COOKING, COUNTER, DECOR = 0, 1, 2, 3, 4
# Eficiência dos móveis de cozinha (a mesma do fogão e do balcão clássicos).
EFFICIENCY = {COOKING: 20, COUNTER: 10}

# coleção, id, nome, categoria, pegada, preço, nível, beleza, conforto, cor provisória, altura provisória
FURNITURE = [
    ("anos70", "chair_70s", "Cadeira Ovo", SEATING, (1, 1), 50, 2, 6, 12, "e07a2e", 22),
    ("anos70", "table_70s", "Mesa Tulipa", TABLE, (1, 1), 85, 2, 8, 10, "f2f0e8", 26),
    ("anos70", "lava_lamp", "Luminária de Lava", DECOR, (1, 1), 95, 2, 20, 0, "ff6a3d", 50),
    ("anos70", "macrame_plant", "Planta no Macramê", DECOR, (1, 1), 110, 3, 24, 0, "c9a46a", 60),
    ("country", "chair_country", "Cadeira Rústica", SEATING, (1, 1), 45, 2, 5, 11, "a8662e", 20),
    ("country", "table_country", "Mesa Xadrez Country", TABLE, (1, 1), 80, 2, 7, 10, "d94040", 26),
    ("country", "hay_bale", "Fardo de Feno", DECOR, (1, 1), 70, 2, 16, 0, "e8c25a", 30),
    ("country", "wagon_wheel", "Roda de Carroça", DECOR, (1, 1), 100, 3, 22, 0, "8a5a2a", 50),
    ("festa", "chair_party", "Cadeira de Festa", SEATING, (1, 1), 55, 3, 6, 11, "ff8fb1", 20),
    ("festa", "table_party", "Mesa de Confete", TABLE, (1, 1), 95, 3, 9, 10, "ffd6e7", 26),
    ("festa", "balloons", "Balões", DECOR, (1, 1), 80, 3, 20, 0, "ff4d6d", 70),
    ("festa", "party_cake", "Bolo de Festa", DECOR, (1, 1), 140, 4, 28, 0, "ffb3cf", 40),
    ("americano", "stool_diner", "Banqueta de Lanchonete", SEATING, (1, 1), 50, 3, 5, 9, "e0303a", 20),
    ("americano", "table_diner", "Mesa de Lanchonete", TABLE, (1, 1), 90, 3, 8, 10, "4fd1c5", 26),
    ("americano", "jukebox", "Jukebox", DECOR, (1, 1), 180, 4, 32, 0, "ff3d7f", 60),
    ("americano", "neon_diner", "Placa Neon", DECOR, (1, 1), 130, 4, 26, 0, "ff4da6", 60),
    ("mexicano", "chair_mexican", "Cadeira Pintada", SEATING, (1, 1), 60, 4, 7, 12, "2ea86b", 20),
    ("mexicano", "table_mexican", "Mesa de Talavera", TABLE, (1, 1), 110, 4, 10, 11, "2f6fd9", 26),
    ("mexicano", "cactus", "Cacto", DECOR, (1, 1), 75, 4, 18, 0, "3fae4a", 50),
    ("mexicano", "pinata", "Piñata", DECOR, (1, 1), 120, 5, 25, 0, "ff7a2f", 60),
    ("anos80", "chair_80s", "Cadeira Neon", SEATING, (1, 1), 65, 4, 7, 11, "ff4dd2", 20),
    ("anos80", "table_80s", "Mesa Memphis", TABLE, (1, 1), 115, 4, 10, 10, "ffffff", 26),
    ("anos80", "arcade", "Fliperama", DECOR, (1, 1), 200, 5, 34, 0, "2a2d6e", 70),
    ("anos80", "boombox", "Rádio Boombox", DECOR, (1, 1), 110, 5, 22, 0, "3a3c46", 40),
    ("italiano", "chair_italian", "Cadeira da Cantina", SEATING, (1, 1), 70, 5, 7, 12, "6b3a1e", 20),
    ("italiano", "table_italian", "Mesa da Cantina", TABLE, (1, 1), 120, 5, 11, 11, "e04040", 26),
    ("italiano", "wine_barrel", "Barril de Vinho", DECOR, (1, 1), 130, 5, 24, 0, "8a4a24", 40),
    ("italiano", "olive_tree", "Oliveira", DECOR, (1, 1), 160, 6, 30, 0, "7a9a4a", 70),
    ("japones", "chair_japanese", "Cadeira de Bambu", SEATING, (1, 1), 70, 5, 8, 11, "c9a46a", 20),
    ("japones", "table_japanese", "Mesa de Madeira Escura", TABLE, (1, 1), 125, 5, 11, 10, "4a2a1e", 24),
    ("japones", "bonsai", "Bonsai", DECOR, (1, 1), 150, 6, 30, 0, "3f8a3f", 45),
    ("japones", "paper_lantern", "Lanterna de Papel", DECOR, (1, 1), 120, 6, 24, 0, "ff5a4a", 60),
    ("frances", "chair_french", "Cadeira de Vime", SEATING, (1, 1), 80, 6, 8, 13, "d9b77e", 20),
    ("frances", "table_french", "Mesa de Mármore", TABLE, (1, 1), 140, 6, 12, 11, "eeeeee", 26),
    ("frances", "eiffel", "Torre Eiffel", DECOR, (1, 1), 170, 6, 30, 0, "8a7a6a", 70),
    ("frances", "paris_lamp", "Poste Parisiense", DECOR, (1, 1), 150, 7, 28, 0, "2a3a3a", 80),
    ("brasileiro", "chair_brazil", "Cadeira de Palhinha", SEATING, (1, 1), 75, 6, 8, 12, "c98a4a", 20),
    ("brasileiro", "table_brazil", "Mesa de Chita", TABLE, (1, 1), 135, 6, 12, 11, "ff5a5a", 26),
    ("brasileiro", "banana_tree", "Bananeira", DECOR, (1, 1), 140, 6, 27, 0, "4fbf4a", 80),
    ("brasileiro", "parrot", "Papagaio no Poleiro", DECOR, (1, 1), 190, 7, 33, 0, "3fbf4a", 60),
    ("anos2010", "chair_2010s", "Cadeira Escandinava", SEATING, (1, 1), 90, 7, 8, 13, "f2f2f2", 20),
    ("anos2010", "table_2010s", "Mesa de Carvalho", TABLE, (1, 1), 150, 7, 12, 11, "e0c49a", 26),
    ("anos2010", "edison_lamp", "Luminária Edison", DECOR, (1, 1), 140, 7, 26, 0, "3a3c46", 70),
    ("anos2010", "succulents", "Suculentas", DECOR, (1, 1), 120, 7, 24, 0, "8fd18a", 40),
    ("balada", "chair_club", "Poltrona de Veludo", SEATING, (1, 1), 110, 8, 10, 15, "7a2fd0", 22),
    ("balada", "table_club", "Mesa Neon", TABLE, (1, 1), 170, 8, 13, 11, "1d1d2b", 28),
    ("balada", "disco_ball", "Globo de Espelhos", DECOR, (1, 1), 220, 8, 36, 0, "c9d3de", 80),
    ("balada", "dj_booth", "Cabine de DJ", DECOR, (2, 1), 300, 9, 40, 0, "2a2d3e", 40),
    # Mais uma cadeira e uma mesa por coleção, e fogões e balcões modernos (pedido do PO em 12/10).
    ("anos70", "chair_tulip", "Cadeira Tulipa", SEATING, (1, 1), 55, 2, 6, 11, "ff8a3d", 22),
    ("anos70", "table_70s_square", "Mesa de Fórmica", TABLE, (1, 1), 90, 3, 8, 10, "f2b33d", 26),
    ("country", "bench_country", "Cadeira de Ripas", SEATING, (1, 1), 50, 2, 5, 11, "d9a066", 20),
    ("country", "table_country_round", "Mesa Xadrez Azul", TABLE, (1, 1), 85, 3, 7, 10, "3a6ad9", 26),
    ("festa", "chair_party_blue", "Cadeira de Laço Azul", SEATING, (1, 1), 60, 3, 6, 11, "8fd0ff", 20),
    ("festa", "table_party_square", "Mesa Quadrada de Confete", TABLE, (1, 1), 100, 4, 9, 10, "e8f6ff", 26),
    ("americano", "chair_diner", "Cadeira de Lanchonete", SEATING, (1, 1), 60, 3, 6, 11, "e0303a", 20),
    ("americano", "table_diner_round", "Mesa Redonda Cromada", TABLE, (1, 1), 95, 4, 8, 10, "e0303a", 26),
    ("mexicano", "chair_equipal", "Cadeira Equipal", SEATING, (1, 1), 65, 4, 7, 12, "c98a52", 20),
    ("mexicano", "table_mexican_round", "Mesa com Toalha Laranja", TABLE, (1, 1), 115, 5, 10, 10, "ff7a2f", 26),
    ("anos80", "chair_80s_pink", "Cadeira Neon Rosa", SEATING, (1, 1), 70, 4, 7, 11, "ff4dd2", 20),
    ("anos80", "table_80s_square", "Mesa de Neon", TABLE, (1, 1), 125, 5, 11, 10, "1d1d2b", 26),
    ("italiano", "chair_tuscan", "Cadeira Toscana", SEATING, (1, 1), 75, 5, 8, 12, "2f9e44", 20),
    ("italiano", "table_italian_round", "Mesa à Luz de Velas", TABLE, (1, 1), 135, 6, 12, 10, "ffffff", 26),
    ("japones", "stool_zen", "Banquinho Zen", SEATING, (1, 1), 70, 5, 7, 9, "d9433b", 18),
    ("japones", "table_japanese_round", "Mesa Redonda de Madeira", TABLE, (1, 1), 130, 6, 11, 10, "8a5a34", 24),
    ("frances", "chair_french_red", "Poltrona Bistrô Vermelha", SEATING, (1, 1), 90, 6, 9, 13, "c81e3a", 22),
    ("frances", "table_french_square", "Mesa de Mármore Quadrada", TABLE, (1, 1), 160, 7, 13, 10, "f2f1ee", 26),
    ("brasileiro", "chair_brazil_flag", "Cadeira Verde e Amarela", SEATING, (1, 1), 85, 6, 9, 12, "2fae4e", 20),
    ("brasileiro", "table_brazil_round", "Mesa Redonda de Chita", TABLE, (1, 1), 150, 7, 12, 10, "2f6fd9", 26),
    ("anos2010", "stool_industrial", "Banqueta Industrial", SEATING, (1, 1), 90, 7, 9, 9, "c98a52", 20),
    ("anos2010", "table_2010s_round", "Mesa Escandinava", TABLE, (1, 1), 170, 8, 13, 10, "e8cfa4", 26),
    ("balada", "stool_club", "Banqueta Neon", SEATING, (1, 1), 110, 8, 10, 9, "7a2fd0", 20),
    ("balada", "table_club_square", "Mesa Espelhada", TABLE, (1, 1), 210, 9, 15, 10, "1d1d2b", 28),
    ("americano", "stove_mint", "Fogão Retrô Menta", COOKING, (1, 1), 300, 3, 6, 0, "7fdcc0", 38),
    ("anos2010", "stove_steel", "Fogão Inox Industrial", COOKING, (1, 1), 400, 5, 8, 0, "b9c3cf", 38),
    ("frances", "stove_black", "Fogão Preto e Dourado", COOKING, (1, 1), 520, 7, 12, 0, "2a2a33", 38),
    ("country", "counter_wood", "Balcão de Madeira", COUNTER, (2, 1), 260, 3, 6, 0, "a86d40", 34),
    ("festa", "counter_pastel", "Balcão de Confeitaria", COUNTER, (2, 1), 280, 4, 7, 0, "ff9ec4", 34),
    ("anos2010", "counter_steel", "Balcão Inox", COUNTER, (2, 1), 320, 5, 8, 0, "b9c3cf", 34),
]

FLOOR, WALL = 0, 1
CHECKER, PLANKS, TILES, PLAIN, BRICK, STRIPES = range(6)

# coleção, id, nome, tipo, preço, nível, beleza, padrão provisório, cor a, cor b
SURFACES = [
    ("anos70", "floor_70s", "Piso Retrô 70", FLOOR, 150, 2, 15, TILES, "e07a2e", "8a4a1e"),
    ("anos70", "wall_70s", "Papel Ondas 70", WALL, 140, 2, 15, STRIPES, "f2c25a", "e07a2e"),
    ("country", "floor_country", "Tábuas Rústicas", FLOOR, 140, 2, 14, PLANKS, "9a6a3e", "6b4423"),
    ("country", "wall_country", "Parede de Toras", WALL, 160, 3, 16, PLAIN, "a8662e", "6b4423"),
    ("festa", "floor_party", "Piso de Confete", FLOOR, 180, 3, 18, TILES, "ffe0ec", "ff8fb1"),
    ("festa", "wall_party", "Bolinhas de Festa", WALL, 170, 3, 18, PLAIN, "fff0f6", "ff5fa2"),
    ("americano", "floor_diner", "Xadrez da Lanchonete", FLOOR, 190, 3, 18, CHECKER, "f6f6f6", "1d1d26"),
    ("americano", "wall_diner", "Faixa Cromada", WALL, 200, 4, 20, STRIPES, "ffffff", "e0303a"),
    ("mexicano", "floor_mexican", "Lajota de Barro", FLOOR, 220, 4, 20, TILES, "d9824a", "a8582e"),
    ("mexicano", "wall_mexican", "Estuque com Talavera", WALL, 210, 4, 20, PLAIN, "ffd166", "2f6fd9"),
    ("anos80", "floor_80s", "Piso Memphis", FLOOR, 240, 5, 22, TILES, "ffffff", "ff4dd2"),
    ("anos80", "wall_80s", "Grade Neon", WALL, 230, 5, 22, PLAIN, "2a1d4e", "4fe0ff"),
    ("italiano", "floor_italian", "Granilite", FLOOR, 260, 5, 23, TILES, "efe6d8", "b8a890"),
    ("italiano", "wall_italian", "Reboco Toscano", WALL, 240, 5, 22, PLAIN, "e8b46a", "b8582e"),
    ("japones", "floor_japanese", "Tatame", FLOOR, 280, 6, 25, TILES, "c9c27a", "4a6a3a"),
    ("japones", "wall_japanese", "Painel Shoji", WALL, 270, 6, 25, PLAIN, "fbf6ea", "6b4423"),
    ("frances", "floor_french", "Parquê Espinha de Peixe", FLOOR, 320, 6, 27, PLANKS, "d9a86a", "a8743e"),
    ("frances", "wall_french", "Boiserie Azul", WALL, 300, 7, 26, PLAIN, "bcd7f2", "d9b25a"),
    ("brasileiro", "floor_brazil", "Calçadão de Copacabana", FLOOR, 300, 6, 26, STRIPES, "f6f6f6", "1d1d26"),
    ("brasileiro", "wall_brazil", "Folhagem Tropical", WALL, 290, 7, 26, PLAIN, "fff6e0", "3fae4a"),
    ("anos2010", "floor_2010s", "Cimento Queimado", FLOOR, 340, 7, 27, TILES, "b8bcc2", "8a8f96"),
    ("anos2010", "wall_2010s", "Azulejo de Metrô", WALL, 320, 7, 27, BRICK, "ffffff", "d8dde3"),
    ("balada", "floor_club", "Pista de LED", FLOOR, 450, 8, 32, CHECKER, "ff4dd2", "4fe0ff"),
    ("balada", "wall_club", "Luz Neon", WALL, 420, 8, 32, STRIPES, "1d1d2b", "ff4da6"),
]


def color(hex_code):
    r, g, b = (int(hex_code[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return f"Color({r:.3f}, {g:.3f}, {b:.3f}, 1)"


def write(path, text, redo):
    if os.path.exists(path) and not redo:
        return False
    with open(path, "w", encoding="utf-8", newline="\n") as out:
        out.write(text)
    return True


def main(redo=False):
    made = 0
    for cid, name, hex_code, order in COLLECTIONS:
        made += write(os.path.join(DATA, "collections", f"{cid}.tres"), f'''[gd_resource type="Resource" script_class="CollectionDefinition" format=3]

[ext_resource type="Script" path="res://core/content/collection_definition.gd" id="1_def"]

[resource]
script = ExtResource("1_def")
id = &"{cid}"
display_name = "{name}"
color = {color(hex_code)}
order = {order}
''', redo)
    for (cid, fid, name, category, fp, price, level, beauty, comfort, hex_code, height) in FURNITURE:
        made += write(os.path.join(DATA, "furniture", f"{fid}.tres"), f'''[gd_resource type="Resource" script_class="FurnitureDefinition" format=3]

[ext_resource type="Script" path="res://core/furniture/furniture_definition.gd" id="1_def"]

[resource]
script = ExtResource("1_def")
id = &"{fid}"
display_name = "{name}"
category = {category}
footprint = Vector2i({fp[0]}, {fp[1]})
needs_access = {"true" if category in (TABLE, SEATING, COOKING, COUNTER) else "false"}
collection = &"{cid}"
price = {price}
min_level = {level}
beauty = {beauty}
efficiency = {EFFICIENCY.get(category, 0)}
comfort = {comfort}
placeholder_color = {color(hex_code)}
placeholder_height = {float(height)}
''', redo)
    for (cid, sid, name, kind, price, level, beauty, pattern, a, b) in SURFACES:
        made += write(os.path.join(DATA, "surfaces", f"{sid}.tres"), f'''[gd_resource type="Resource" script_class="SurfaceDefinition" format=3]

[ext_resource type="Script" path="res://core/cafe/surface_definition.gd" id="1_def"]

[resource]
script = ExtResource("1_def")
id = &"{sid}"
display_name = "{name}"
kind = {kind}
is_default = false
collection = &"{cid}"
price = {price}
min_level = {level}
beauty = {beauty}
pattern = {pattern}
color_a = {color(a)}
color_b = {color(b)}
''', redo)
    print(f"{made} arquivos criados em {DATA}")


if __name__ == "__main__":
    main("--refazer" in sys.argv)
