# Direção de arte v3 — gerador

Gera, em SVG, as pranchas do canvas **"Café Manie — Direção Visual"** (Claude Design): tela do jogo, loja,
cardápio, personagens, guia de estilo e o cenário sem interface. Tudo é desenho próprio, feito por código.
Nenhum sprite, logo, personagem ou ícone do Café Mania é usado (seção 5 do master prompt).

Usa a base da v2 (`../v2/core.py` e `../v2/food.py`).

## Arquivos

| Arquivo | O que desenha |
|---|---|
| `core3.py` | Cores vivas (`shade`/`tint`), caixas e cilindros isométricos, sombras de contato, recortes |
| `people3.py` | Personagens: cabeça, olhos, 12 penteados, roupas, poses (em pé, andando, sentado, de costas) |
| `furniture3.py` | Móveis: cadeiras, mesas, fogão retrô, balcão, vitrine, expresso, geladeira, pia, plantas, jukebox, aquário |
| `food3.py` | Balões de pedido, carinhas de humor e selos de fogão (os pratos vêm da v2) |
| `scene3.py` | O salão 12×12 com cozinha, paredes, piso, gramado, rua e calçada |
| `icons3.py` | Ícones e botões quadrados da interface |
| `hud3.py` | Interface: contadores, barra de XP, missões na lateral, barra de ícones e vizinhos |
| `shop3.py` | Loja: abas, categorias, quadradinhos com preço, prévia e móvel sendo posicionado |
| `boards_extra.py` | Pranchas de personagens, cardápio e guia de estilo |
| `build3.py` | Monta as pranchas `.dc.html` do canvas e as prévias locais |
| `s3_*.py` | Folhas de conferência (rostos, poses, móveis, ícones) |

## Como gerar

```bash
cd tools/art_direction/v3
CANVAS_DIR=/tmp/canvas/project python3 build3.py canvas           # pranchas do canvas
PREVIEW_DIR=/tmp/previa python3 build3.py main loja personagens    # prévias em HTML
```

As prévias usam as fontes Fredoka e Nunito de `node_modules/@fontsource` dentro da pasta de prévia
(`npm install @fontsource/fredoka @fontsource/nunito`). Sem elas, o navegador troca a letra.

O mesmo código vai servir para exportar os sprites do jogo quando a direção for aprovada.
