"""Cria o roteiro de missões diárias (res://data/missions/daily) e semanais (res://data/missions/weekly).
Ver DT-047.

Todo dia as 10 diárias começam do zero, e toda segunda-feira as 20 semanais. As metas e as recompensas
crescem com o nível do jogador (meta + por_nível × (nível - 1), arredondada para um número redondo) e
ficam congeladas quando o período começa. Missão com nível mínimo aparece com o cadeado até lá.

Recompensas: as 10 diárias dão uns 450 de ouro no nível 1, um terço de hora de jogo ativo (DT-043:
cerca de 1.300 por hora), e as 20 semanais uns 4.500. No nível 30 as recompensas são umas 3 vezes maiores.

    python tools/content/make_missions.py            # só cria o que falta
    python tools/content/make_missions.py --refazer  # reescreve a partir da tabela
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.normpath(os.path.join(HERE, "..", "..", "data", "missions"))

# MissionDefinition.Kind
COLLECT_DISHES, SERVE_CUSTOMERS, EARN_GOLD, BUY_FURNITURE, REACH_LEVEL, EXPAND_CAFE = range(6)
(HAPPY_CUSTOMERS, EARN_XP, COOK_DIFFERENT, CLAIM_DAILY_GIFT, MENU_ORDERS, SPEND_INGREDIENTS, PAINT_FLOOR, PAINT_WALL,
 HANG_WALL_ITEMS, COMPLETE_DAILY, COOK_SLOW, REACH_POPULARITY, QUEUE_SEATED) = range(6, 19)
# FurnitureDefinition.Category
TABLE, SEATING, COOKING, COUNTER, DECOR = range(5)

# id, título (%d = meta), dica, tipo, meta, meta por nível, ouro, ouro por nível, XP, XP por nível, extras
DAILY = [
    ("d01_cook", "Cozinhe %d pratos", "Toque num fogão livre e escolha uma receita.", COLLECT_DISHES, 8, 0.5, 40, 2, 10, 0.5, {}),
    ("d02_serve", "Sirva %d clientes", "Cliente servido é cliente que pagou.", SERVE_CUSTOMERS, 12, 0.6, 40, 2, 10, 0.5, {}),
    ("d03_sales", "Ganhe %d de Café Ouro em vendas", "Pratos mais caros rendem mais por cliente.", EARN_GOLD, 250, 40, 50, 3, 10,
     0.5, {}),
    ("d04_happy", "Deixe %d clientes satisfeitos", "Servir rápido e um salão bonito deixam todo mundo feliz.", HAPPY_CUSTOMERS,
     8, 0.4, 45, 2, 10, 0.5, {}),
    ("d05_variety", "Cozinhe %d pratos diferentes", "Cada receita diferente conta uma vez.", COOK_DIFFERENT, 3, 0.15, 45, 2,
     12, 0.5, {"limit_to_unlocked_recipes": "true"}),
    ("d06_xp", "Ganhe %d de XP", "Cozinhar e servir dão XP.", EARN_XP, 40, 8, 40, 2, 0, 0, {}),
    ("d07_gift", "Receba o presente diário", "O presente fica no canto de cima, à direita.", CLAIM_DAILY_GIFT, 1, 0, 30, 1, 5, 0.3,
     {}),
    ("d08_menu", "Atenda %d pedidos do cardápio", "Quando o cliente pede um prato que não está no balcão, cozinhe esse prato.",
     MENU_ORDERS, 3, 0.2, 50, 2, 12, 0.5, {}),
    ("d09_ingredients", "Gaste %d de ouro em ingredientes", "Toda receita no fogão compra os ingredientes.", SPEND_INGREDIENTS,
     60, 12, 35, 2, 8, 0.4, {}),
    ("d10_buy", "Compre 1 móvel ou enfeite", "A Loja fica na faixa de baixo.", BUY_FURNITURE, 1, 0, 45, 2, 10, 0.5, {}),
]

WEEKLY = [
    ("w01_cook", "Cozinhe %d pratos", "Fogões a mais cozinham ao mesmo tempo.", COLLECT_DISHES, 60, 3, 250, 12, 60, 3, {}),
    ("w02_serve", "Sirva %d clientes", "Mais mesas e cadeiras recebem mais gente.", SERVE_CUSTOMERS, 90, 4, 250, 12, 60, 3, {}),
    ("w03_sales", "Ganhe %d de Café Ouro em vendas", "Lasanha e coxinha rendem mais por porção.", EARN_GOLD, 2000, 300, 300, 15,
     60, 3, {}),
    ("w04_happy", "Deixe %d clientes satisfeitos", "Garçons a mais servem mais rápido.", HAPPY_CUSTOMERS, 60, 3, 250, 12, 60, 3,
     {}),
    ("w05_variety", "Cozinhe %d pratos diferentes", "Cada receita diferente conta uma vez.", COOK_DIFFERENT, 6, 0, 250, 12, 60, 3,
     {"limit_to_unlocked_recipes": "true"}),
    ("w06_xp", "Ganhe %d de XP", "Receitas demoradas dão mais XP.", EARN_XP, 400, 60, 250, 12, 0, 0, {}),
    ("w07_gifts", "Receba o presente diário %d vezes", "Um presente por dia: volte amanhã.", CLAIM_DAILY_GIFT, 5, 0, 300, 12, 60,
     3, {}),
    ("w08_menu", "Atenda %d pedidos do cardápio", "O painel do fogão mostra quantos esperam cada prato.", MENU_ORDERS, 25, 1, 250, 12,
     60, 3, {}),
    ("w09_ingredients", "Gaste %d de ouro em ingredientes", "Cozinhar mais é gastar mais e vender mais.", SPEND_INGREDIENTS, 600,
     100, 200, 10, 50, 2, {}),
    ("w10_buy", "Compre %d móveis ou enfeites", "Móvel novo deixa o salão mais bonito.", BUY_FURNITURE, 4, 0, 250, 12, 60, 3, {}),
    ("w11_table", "Compre 1 mesa", "Mesas ficam na aba Salão da Loja.", BUY_FURNITURE, 1, 0, 150, 8, 40, 2,
     {"furniture_category": str(TABLE)}),
    ("w12_chairs", "Compre %d cadeiras", "Cadeira do lado da mesa já vira para ela.", BUY_FURNITURE, 2, 0, 150, 8, 40, 2,
     {"furniture_category": str(SEATING)}),
    ("w13_decor", "Compre %d enfeites", "Enfeites aumentam a beleza.", BUY_FURNITURE, 2, 0, 150, 8, 40, 2,
     {"furniture_category": str(DECOR)}),
    ("w14_floor", "Reforme %d pisos", "Escolha um piso na Loja e toque nos pisos.", PAINT_FLOOR, 10, 0, 200, 10, 50, 2, {}),
    ("w15_walls", "Pinte %d trechos de parede", "Escolha uma parede na Loja e toque nos trechos.", PAINT_WALL, 4, 0, 200, 10, 50,
     2, {}),
    ("w16_hang", "Pendure 1 item de parede", "TV, rádio, janelas: na aba Paredes da Loja.", HANG_WALL_ITEMS, 1, 0, 200, 10, 50, 2,
     {}),
    ("w17_dailies", "Complete %d missões diárias", "As diárias recomeçam todo dia.", COMPLETE_DAILY, 15, 0, 400, 15, 80, 3, {}),
    ("w18_popular", "Chegue a %d%% de popularidade", "Clientes satisfeitos aumentam a popularidade.", REACH_POPULARITY, 80, 0,
     300, 12, 60, 3, {}),
    ("w19_queue", "Sente %d clientes que esperavam na fila", "Com o salão cheio, chega gente na fila da calçada.",
     QUEUE_SEATED, 10, 0.5, 250, 12, 60, 3, {}),
    ("w20_slow", "Cozinhe %d pratos demorados", "Receitas de 3 minutos ou mais: bolo de cenoura, coxinha, lasanha.", COOK_SLOW,
     8, 0, 300, 15, 70, 3, {"min_cook_time": "180.0", "min_level": "3"}),
]


def write(folder, order, row, redo):
    mid, title, hint, kind, target, per_level, gold, gold_level, xp, xp_level, extra = row
    path = os.path.join(folder, f"{mid}.tres")
    if os.path.exists(path) and not redo:
        return 0
    lines = [
        f'id = &"{mid}"',
        f"order = {order}",
        f'title = "{title}"',
        f'hint = "{hint}"',
        f"kind = {kind}",
        f"target = {target}",
        f"target_per_level = {float(per_level)}",
        f"furniture_category = {extra.get('furniture_category', '-1')}",
        f"min_level = {extra.get('min_level', '1')}",
        f"min_cook_time = {extra.get('min_cook_time', '0.0')}",
        f"limit_to_unlocked_recipes = {extra.get('limit_to_unlocked_recipes', 'false')}",
        f"reward_gold = {gold}",
        f"reward_gold_per_level = {float(gold_level)}",
        f"reward_xp = {xp}",
        f"reward_xp_per_level = {float(xp_level)}",
    ]
    with open(path, "w", encoding="utf-8", newline="\n") as out:
        out.write('[gd_resource type="Resource" script_class="MissionDefinition" format=3]\n\n'
                  '[ext_resource type="Script" path="res://core/progression/mission_definition.gd" id="1_mission"]\n\n'
                  '[resource]\nscript = ExtResource("1_mission")\n' + "\n".join(lines) + "\n")
    return 1


def main(redo=False):
    made = 0
    for name, rows in (("daily", DAILY), ("weekly", WEEKLY)):
        folder = os.path.join(DATA, name)
        os.makedirs(folder, exist_ok=True)
        for order, row in enumerate(rows, start=1):
            made += write(folder, order, row, redo)
    print(f"{made} missões criadas em {DATA}")


if __name__ == "__main__":
    main("--refazer" in sys.argv)
