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
| Cena Cafe | `scenes/cafe/cafe.gd` | Dona do grid; liga câmera, piso e seleção |
| CafeCamera | `scenes/cafe/cafe_camera.gd` | Pan, zoom (roda e pinça) e detecção de tap |
| FloorView | `scenes/cafe/floor_view.gd` | Desenha o piso (placeholder) e o destaque da seleção |
| DebugHud | `scenes/ui/debug_hud.gd` | HUD de protótipo (placeholder) |

## Grid e projeção

- O grid lógico é **cartesiano**: células `Vector2i(x, y)` de `(0,0)` até `size - 1`.
- A projeção é **isométrica 2:1**, com piso de 128×64 px de mundo (`IsoProjection.TILE_SIZE`).
- O eixo x do grid desce para a direita na tela e o eixo y desce para a esquerda.
- Objetos ocupam um retângulo de células (`footprint`). O grid recusa colocação fora dos limites, sobreposta, com id repetido ou com tamanho inválido, sempre sem efeito colateral.
- Expansão (`resize`) nunca corta objetos já posicionados.

## Módulos planejados (próximas fases)

Criados apenas quando a fase precisar deles:

| Fase | Módulos |
|---|---|
| 1 | Sistema genérico de móveis (definição de dados + instância no grid), validação de caminho |
| 2 | `Clock` (tempo), cozinha e estações, balcão, clientes (máquina de estados), garçom (pathfinding com `AStarGrid2D`), `Economy` (transações com registro), XP |
| 3 | Loja, inventário, decoração, expansão na interface |
| 4 | Níveis 1–10, missões, conquistas, tutorial, `SaveService` versionado |

A lista completa de sistemas alvo está na seção 10 do master prompt.
