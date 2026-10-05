# Sprites do jogo

Os sprites saem do mesmo código que desenhou a direção visual v3 (`tools/art_direction/v3`).
Decisões em [DT-030, DT-031 e DT-038](../../docs/decisions.md).

## Como regenerar

Na pasta do projeto:

```bash
python tools/art_direction/v3/export_sprites.py                  # desenha as folhas em tools/sprites/raw/
godot --headless -s res://tools/sprites/crop_sprites.gd          # recorta cada figura e grava art/sprites/
godot --headless --import                                        # a Godot importa os PNGs novos
```

- O primeiro passo precisa do Chrome ou do Edge (todo Windows tem o Edge). Outro caminho vai em `SPRITES_BROWSER`.
- No Windows, rode o Python com `PYTHONUTF8=1` se aparecer erro de acentuação.
- `tools/sprites/raw/` é descartável e fica fora do git. Os PNGs de `art/sprites/` entram no repositório.
- O recorte reprova figura vazia ou encostada na borda do espaço reservado (sinal de que saiu cortada).

## O que sai

| Folha | Figuras | Âncora |
|---|---|---|
| `moveis`, `moveis_2`… | cada móvel nas 4 rotações (`chair_wood_r0` …); o encosto de cada cadeira visto de costas (`encosto_<cadeira>_r1`/`r2`), desenhado por cima de quem senta; a panela de cada receita (`panela_<receita>`) e o forno aceso (`fogao_aceso_r0`/`r3`), por cima do fogão | vértice da frente da pegada |
| `personagens` | `cliente_01` … `cliente_12` e `garcom`, em `frente`/`costas` × `em_pe`/`passo`/`passo2`; `sentado_<expressão>`; `sentado_costas_r1`/`r2` (só a pessoa: o encosto vem da cadeira); o garçom com `_bandeja` | pés (em pé) ou vértice da frente da cadeira (sentado) |
| `pratos` | `prato_<id da receita>` e as carinhas `humor_feliz`/`esperando`/`bravo` | centro |
| `interface` | `icone_<nome>` (moeda, estrela do chef, flor, sorriso, estrelas, presente, troféu, prancheta, loja, rolo, expandir, cadeado...), `botao_<símbolo>` (os quadrados brilhantes), `medalhao_<nome>`, `fita_<nome>` e as listras das barras | centro (ícones e botões); topo central (fitas) |
| `cenario` | `piso_<revestimento>_<variação>`, `piso_entrada`, `parede_<revestimento>_R`/`L`, `enfeite_<nome>_R`/`L`, `poste`, `canteiro`; as texturas de repetir `gramado` e `asfalto` | vértice de cima do piso; ponta de baixo à esquerda do painel; base do poste e do canteiro |

O `sprites.json` também diz o sprite de cada rotação dos móveis, a altura dos tampos das mesas, os visuais
de cliente, onde fica o prato na bandeja do garçom, o encosto de cada cadeira para quem senta de costas, as
variações de cada piso, a altura da parede, o ciclo de enfeites das paredes e as peças do exterior.

A folha `cenario` é desenhada na escala do canvas (piso de 84) com as funções de `scene3.py`; as outras, na
escala 96. Cada folha tem a sua escala, e o jogo só vê pixels de mundo. Uma folha que passaria de 6.400 px de
altura continua na seguinte (`moveis_2`, `moveis_3`): o navegador não fotografa imagem muito alta.

## Como entra conteúdo novo

- **Móvel de coleção:** a cadeira, a mesa e os enfeites ficam em `themes3.py` (`CHAIRS`, `TABLES` e `DECOR`).
  Cadeira e mesa são só a receita das peças genéricas (pé, assento, encosto, tampo, toalha). O exportador
  registra tudo sozinho, inclusive o encosto da cadeira e a altura do tampo.
- **Outro móvel:** desenhe a função em `furniture3.py` (ou reaproveite uma) e acrescente o id em `FURNITURE`, no
  `export_sprites.py`, com a pegada e quantos desenhos diferentes ele tem (4 se a frente importa, 2 se só muda o
  comprimento, 1 se é simétrico). Mesa nova também entra em `TABLE_TOPS`, e cadeira nova em `SEAT_BACKS`.
- **Receita:** acrescente o id em `FOODS`, apontando para um prato de `../v2/food.py`.
- **Cliente:** acrescente um visual em `CUSTOMERS`.
- **Revestimento:** piso novo entra em `FLOORS` e parede nova em `WALLS`, no `tiles3.py` (os das coleções ficam
  no fim do arquivo). Padrão que atravessa a emenda precisa ter o período de uma célula.

Depois, rode os três comandos acima. Os testes `test_furniture_art.gd`, `test_character_art.gd` e
`test_scene_art.gd` reprovam conteúdo do catálogo sem arte.

## Conferência visual

```bash
godot -s res://tools/screenshot.gd -- <cópia do save.json> foto.png 120 1.8    # a sua cafeteria
godot -s res://tools/showcase.gd -- vitrine.png 1.25                           # gente em cada situação
godot -s res://tools/showcase.gd -- vitrine.png 0.75 floor_wood wall_brick      # com outro piso e outra parede
godot -s res://tools/showcase.gd -- cozinha.png 1.6 floor_beige wall_cream 0.2,0.6   # câmera na cozinha
godot -s res://tools/showcase.gd -- loja.png 1.0 x x - loja:DECOR                    # loja aberta numa aba
godot -s res://tools/collection_showcase.gd -- anos70.png anos70 1.25                 # uma coleção montada
```

Todas abrem uma janela de verdade e gravam a tela. Na primeira, use sempre uma **cópia** do save: o jogo
salva sozinho. A vitrine e a foto da coleção não leem nem gravam save.
