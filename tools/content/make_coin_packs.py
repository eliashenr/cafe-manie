"""Cria os pacotes de Café Ouro por dinheiro de verdade (res://data/coin_packs). Ver DT-043.

A taxa parte do que um jogador ativo ganha: no turno de 30 minutos do robô (níveis 1 a 7), o saldo
sobe cerca de 640 de ouro, já descontados os ingredientes — uns 1.300 por hora. O menor pacote (500)
vale uns 25 minutos de jogo ativo por R$ 4,90, e os maiores dão até 50% a mais por real. Os preços
seguem os degraus de preço da Play Store em reais.

    python tools/content/make_coin_packs.py            # só cria o que falta
    python tools/content/make_coin_packs.py --refazer  # reescreve a partir da tabela
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.normpath(os.path.join(HERE, "..", "..", "data", "coin_packs"))

# id, nome, produto na Play Store, ouro, preço em centavos
PACKS = [
    ("punhado", "Punhado de Ouro", "cafe_ouro_500", 500, 490),
    ("saco", "Saco de Ouro", "cafe_ouro_1200", 1200, 990),
    ("bau", "Baú de Ouro", "cafe_ouro_3300", 3300, 2490),
    ("cofre", "Cofre de Ouro", "cafe_ouro_7000", 7000, 4990),
    ("tesouro", "Tesouro do Café", "cafe_ouro_15000", 15000, 9990),
]


def main(redo=False):
    os.makedirs(DATA, exist_ok=True)
    made = 0
    for order, (pid, name, product, gold, cents) in enumerate(PACKS):
        path = os.path.join(DATA, f"{pid}.tres")
        if os.path.exists(path) and not redo:
            continue
        with open(path, "w", encoding="utf-8", newline="\n") as out:
            out.write(f'''[gd_resource type="Resource" script_class="CoinPack" format=3]

[ext_resource type="Script" path="res://core/economy/coin_pack.gd" id="1_def"]

[resource]
script = ExtResource("1_def")
id = &"{pid}"
display_name = "{name}"
product_id = "{product}"
gold = {gold}
price_cents = {cents}
order = {order}
''')
        made += 1
    print(f"{made} arquivos criados em {DATA}")


if __name__ == "__main__":
    main("--refazer" in sys.argv)
