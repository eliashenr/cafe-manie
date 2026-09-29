# Arquitetura

## Princípios

1. **Regra separada da apresentação.** As regras do jogo (grid, economia, receitas, XP, estados dos clientes) são classes GDScript puras em `core/`. Elas não dependem de nós nem de tela. Isso permite:
   - testar sem abrir o jogo;
   - reaproveitar as mesmas regras na validação do servidor (Fase 6, seção 62).
2. **Poucos serviços globais.** Um autoload só é criado quando existe um uso real (seção 94).
3. **Data-driven.** Conteúdo e balanceamento ficam em dados, não em `if` espalhado pelo código (seções 83–85).
4. **Tempo por timestamp.** Timers guardam "início + duração", não contam frames. Assim o preparo continua com o jogo fechado e, depois, o horário pode vir do servidor (seção 66).
5. **Dados atrás de interface.** `LocalDataProvider` agora; `RemoteDataProvider` quando houver backend (seção 151).

## Camadas

```text
Entrada (toque/mouse)
      │
      ▼
scenes/  ── cenas e visualização ──►  EventBus  ◄── outros sistemas escutam
      │
      ▼
core/    ── regras puras (testáveis)
      │
      ▼
dados    ── Resources de conteúdo / save em JSON (a implementar)
```

## Módulos existentes

| Módulo | Arquivo | Papel |
|---|---|---|
| EventBus | `autoload/event_bus.gd` | Sinais compartilhados entre sistemas (`cell_selected`) |
| CafeGrid | `core/grid/cafe_grid.gd` | Fonte da verdade do grid: limites, ocupação, colisão, expansão |
| IsoProjection | `core/grid/iso_projection.gd` | Conversão grid ↔ mundo isométrico 2:1 |
| FurnitureDefinition | `core/furniture/furniture_definition.gd` | Tipo de móvel como dado (Resource): tamanho, categoria, preço, nível, atributos |
| FurnitureCatalog | `core/furniture/furniture_catalog.gd` | Carrega e valida os `.tres` de `data/furniture/` |
| CafeLayout | `core/cafe/cafe_layout.gd` | Móveis posicionados e as regras de onde podem ficar (inclui validação de acesso) |
| PlacementSession | `core/cafe/placement_session.gd` | Estado do modo de construção (móvel novo ou movido); nada muda até confirmar |
| Cena Cafe (`Cafe`) | `scenes/cafe/cafe.gd` | Dona do layout e do catálogo; modos VIEW e BUILD; traduz entrada em ações |
| CafeCamera | `scenes/cafe/cafe_camera.gd` | Pan, zoom (roda e pinça), tap, hover e enquadramento inicial |
| FloorView | `scenes/cafe/floor_view.gd` | Desenha piso, entrada, seleção e prévia verde/vermelha (placeholder) |
| FurnitureLayer / FurnitureView | `scenes/cafe/furniture_layer.gd`, `furniture_view.gd` | Móveis em ordem de profundidade (y-sort) e a prévia "fantasma" (placeholder) |
| BuildBar | `scenes/ui/build_bar.gd` | Barra de construção: catálogo, ações do móvel selecionado, confirmar/cancelar |
| DebugHud | `scenes/ui/debug_hud.gd` | Painel de protótipo com o piso selecionado (placeholder) |

## Grid e projeção

- O grid lógico é **cartesiano**: células `Vector2i(x, y)` de `(0,0)` até `size - 1`.
- A projeção é **isométrica 2:1**, com piso de 128×64 px de mundo (`IsoProjection.TILE_SIZE`).
- O eixo x do grid desce para a direita na tela e o eixo y desce para a esquerda.
- Objetos ocupam um retângulo de células (`footprint`). O grid recusa colocação fora dos limites, sobreposta, com id repetido ou com tamanho inválido, sempre sem efeito colateral.
- Expansão (`resize`) nunca corta objetos já posicionados.

## Regras de posicionamento (CafeLayout)

Checadas nesta ordem; a primeira que falhar é o motivo mostrado ao jogador:

1. `OUT_OF_BOUNDS` — o móvel inteiro precisa caber no grid.
2. `OCCUPIED` — não pode sobrepor outro móvel (o próprio móvel, quando está sendo movido, não conta).
3. `BLOCKS_ENTRANCE` — a entrada fica sempre livre.
4. `NO_ACCESS` — se o móvel precisa de acesso (`needs_access`), algum vizinho dele tem que ser alcançável a partir da entrada.
5. `BLOCKS_ACCESS` — depois de posicioná-lo, todo outro móvel que precisa de acesso continua tendo.

O alcance é uma busca em largura em 4 direções pelos pisos livres, partindo da entrada. É a mesma malha que o pathfinding dos garçons e clientes vai usar na Fase 2, então o que passa aqui é garantidamente navegável.

## Modo de construção

`PlacementSession` guarda definição, rotação, alvo e — se for mover — o id do móvel. O layout só muda em `confirm()`; cancelar é descartar a sessão, sem estado para restaurar. Durante o movimento o original fica escondido na tela, mas continua no layout, e a checagem ignora as células dele.

## Módulos planejados (próximas fases)

Criados apenas quando a fase precisar deles:

| Fase | Módulos |
|---|---|
| 2 | `Clock` (tempo), cozinha e estações, balcão, clientes (máquina de estados), garçom (pathfinding com `AStarGrid2D`), `Economy` (transações com registro), XP |
| 3 | Loja, inventário, decoração, expansão na interface |
| 4 | Níveis 1–10, missões, conquistas, tutorial, `SaveService` versionado |

A lista completa de sistemas alvo está na seção 10 do master prompt.
