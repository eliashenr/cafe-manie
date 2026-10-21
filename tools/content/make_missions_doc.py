"""Escreve o roteiro de missões (docs/missoes.md) a partir da mesma tabela do make_missions.py, com as
metas e as recompensas nos níveis 1, 10 e 30 (as contas são as do MissionDefinition no jogo).

    python tools/content/make_missions_doc.py
"""
import math
import os

import make_missions as m

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "docs", "missoes.md"))
UNLOCKED = {1: 2, 10: 6, 30: 6}  # receitas liberadas em cada nível (limita "pratos diferentes")


def nice(value):
    step = 1 if value < 20 else (5 if value < 100 else (10 if value < 1000 else 50))
    return int(math.floor(value / step + 0.5) * step)  # como o roundi da Godot (meio para cima)


def thousands(value):
    return f"{value:,}".replace(",", ".")


def target(row, level):
    _, _, _, _, goal, per_level, _, _, _, _, extra = row
    value = nice(goal + per_level * (level - 1))
    if extra.get("limit_to_unlocked_recipes") == "true":
        value = min(value, UNLOCKED[level])
    return max(value, 1)


def reward(row, level):
    gold = nice(row[6] + row[7] * (level - 1))
    xp = nice(row[8] + row[9] * (level - 1))
    return f"{thousands(gold)} ouro" + (f" + {xp} XP" if xp else "")


def table(rows):
    out = ["| # | Missão (nível 1) | Meta no 10 | Meta no 30 | Recompensa no 1 | Recompensa no 30 | Dica |",
           "|---|---|---|---|---|---|---|"]
    for i, row in enumerate(rows, start=1):
        title = row[1].replace("%%", "%")
        first = title.replace("%d", thousands(target(row, 1)))
        level = row[10].get("min_level")
        if level:
            first += f" (a partir do nível {level})"
        out.append(f"| {i} | {first} | {thousands(target(row, 10))} | {thousands(target(row, 30))} | {reward(row, 1)} | "
                   f"{reward(row, 30)} | {row[2]} |")
    return "\n".join(out)


def main():
    text = f"""# Roteiro de missões

Gerado por `tools/content/make_missions_doc.py` a partir da tabela de `tools/content/make_missions.py` (a mesma que cria
os arquivos do jogo). Ver DT-047.

## Como funcionam

- **10 diárias** recomeçam todo dia à meia-noite, e **20 semanais** toda segunda-feira à meia-noite.
- Todas valem ao mesmo tempo. A recompensa entra sozinha quando a missão é concluída, com um aviso na tela.
- A meta e a recompensa crescem com o nível e ficam congeladas no começo do dia (ou da semana).
- Missão com nível mínimo fica com o cadeado até lá.
- Cada diária concluída conta para a semanal "Complete 15 missões diárias".
- Abra pelo medalhão **MISSÕES** ou pelo ícone **Missões** da faixa de baixo. As 6 missões do começo (o tutorial)
  continuam como eram, numa aba própria, até acabarem.

## Diárias

{table(m.DAILY)}

## Semanais

{table(m.WEEKLY)}
"""
    with open(OUT, "w", encoding="utf-8", newline="\n") as out:
        out.write(text)
    print(OUT)


if __name__ == "__main__":
    main()
