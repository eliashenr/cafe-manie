"""Cria os arquivos de dados dos itens de parede (res://data/wall_items).

Como em make_collections.py: depois de criados, os .tres são a fonte de verdade (dá para ajustar
preço, nível e beleza no inspetor da Godot); o script só cria o que falta. --refazer reescreve tudo.

    python tools/content/make_wall_items.py
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.normpath(os.path.join(HERE, "..", "..", "data", "wall_items"))

# id, nome, desenho (enfeite_<desenho>), coleção, preço, nível, beleza, deixa a luz entrar
# Os enfeites baratos de sempre valem 1 de beleza: o jogo novo já começa com eles, e a beleza inicial
# não pode passar da primeira meta da conquista de beleza.
ITEMS = [
    ("relogio", "Relógio", "relogio", "classico", 35, 1, 1, False),
    ("quadro_cupcake", "Quadro de Cupcake", "quadro_cupcake", "classico", 40, 1, 1, False),
    ("quadro_paisagem", "Quadro de Paisagem", "quadro_paisagem", "classico", 45, 1, 1, False),
    ("prateleira", "Prateleira de Potes", "prateleira", "classico", 50, 1, 1, False),
    ("janela", "Janela com Cortina", "janela", "classico", 60, 1, 1, True),
    ("janela_redonda", "Janela Redonda", "janela_redonda", "classico", 80, 2, 4, True),
    ("lousa", "Lousa de Cardápio", "lousa", "classico", 90, 2, 4, False),
    ("radio", "Rádio Antigo", "radio", "anos70", 120, 3, 5, False),
    ("planta_pendurada", "Planta Pendurada", "planta_pendurada", "brasileiro", 110, 3, 5, False),
    ("espelho", "Espelho Dourado", "espelho", "classico", 140, 4, 6, False),
    ("neon_xicara", "Neon de Xícara", "neon_xicara", "anos80", 180, 4, 7, False),
    ("tv", "TV de Tela Plana", "tv", "anos2010", 220, 5, 7, False),
    ("janelao", "Janelão em Arco", "janelao", "frances", 200, 5, 8, True),
]


def write(path, text, redo):
    if os.path.exists(path) and not redo:
        return False
    with open(path, "w", encoding="utf-8", newline="\n") as out:
        out.write(text)
    return True


def main(redo=False):
    os.makedirs(DATA, exist_ok=True)
    made = 0
    for (iid, name, art, collection, price, level, beauty, light) in ITEMS:
        made += write(os.path.join(DATA, f"{iid}.tres"), f'''[gd_resource type="Resource" script_class="WallItemDefinition" format=3]

[ext_resource type="Script" path="res://core/cafe/wall_item_definition.gd" id="1_def"]

[resource]
script = ExtResource("1_def")
id = &"{iid}"
display_name = "{name}"
art = "{art}"
collection = &"{collection}"
lets_light_in = {"true" if light else "false"}
price = {price}
min_level = {level}
beauty = {beauty}
''', redo)
    print(f"{made} arquivos criados em {DATA}")


if __name__ == "__main__":
    main("--refazer" in sys.argv)
