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
| EventBus | `autoload/event_bus.gd` | Sinais compartilhados entre sistemas (`message_posted` → aviso no HUD) |
| DefinitionStore | `core/content/definition_store.gd` | Carregamento e validação genéricos de conteúdo em `data/` |
| GameClock / ManualClock | `core/time/` | Fonte de tempo do jogo; relógio manual para testes |
| RecipeDefinition / RecipeCatalog | `core/cooking/` | Receitas como dado |
| Kitchen | `core/cooking/kitchen.gd` | Fogões por horário (pronto mesmo com o jogo fechado) e porções nos balcões |
| Wallet | `core/economy/wallet.gd` | Saldos por moeda com registro de transações |
| Inventory | `core/economy/inventory.gd` | Móveis guardados (quantidade por tipo) |
| LevelTable / PlayerProgression | `core/progression/` | Curva de níveis em dado; XP e nível do jogador |
| MissionDefinition / MissionTracker | `core/progression/` | Missões como dado; uma ativa por vez, contando só os eventos do seu tipo (DT-019) |
| ExpansionPlan | `core/cafe/expansion_plan.gd` | Etapas de expansão (tamanho, nível, preço) em dado |
| SurfaceDefinition / SurfaceCatalog / CafeStyle | `core/cafe/` | Revestimentos de piso e parede: dados, catálogo, comprados e aplicados |
| EconomyConfig | `core/economy/economy_config.gd` | Parâmetros da loja (fração da venda, categorias essenciais) |
| PlayerStats | `core/progression/player_stats.gd` | Contadores do que o jogador já fez (base das conquistas) |
| AchievementDefinition / AchievementTracker | `core/progression/` | Conquistas progressivas em dados e o acompanhamento delas |
| DailyRewardCalendar / DailyRewards | `core/progression/` | Calendário da recompensa diária e a sequência do jogador |
| SoundCue / SoundSynth | `core/audio/` | Sons de feedback como dados, gerados em áudio por código |
| ServiceConfig / CustomerType / NewGameConfig | `core/service/` | Parâmetros do atendimento, tipos de cliente e jogo novo (todos em `data/`) |
| Navigation | `core/service/navigation.gd` | A* (4 direções) sobre a mesma malha da validação de acesso |
| Agent / Customer / Waiter | `core/service/` | Personagens e suas máquinas de estado |
| SaveCodec | `core/save/save_codec.gd` | Estado do jogo ↔ dados simples (JSON), com versão e migração |
| SaveService | `core/save/save_service.gd` | Save em disco: gravação atômica, `.bak`, recuperação e quarentena |
| CafeSimulation | `core/service/cafe_simulation.gd` | Orquestra tudo: chegadas, pedidos, garçom, pagamento, XP, popularidade, missões, e as ações do jogador (cozinhar, comprar, guardar, expandir) |
| CafeGrid | `core/grid/cafe_grid.gd` | Fonte da verdade do grid: limites, ocupação, colisão, expansão |
| IsoProjection | `core/grid/iso_projection.gd` | Conversão grid ↔ mundo isométrico 2:1 |
| FurnitureDefinition | `core/furniture/furniture_definition.gd` | Tipo de móvel como dado (Resource): tamanho, categoria, preço, nível, atributos |
| FurnitureCatalog | `core/furniture/furniture_catalog.gd` | Carrega e valida os `.tres` de `data/furniture/` |
| CafeLayout | `core/cafe/cafe_layout.gd` | Móveis posicionados e as regras de onde podem ficar (inclui validação de acesso) |
| PlacementSession | `core/cafe/placement_session.gd` | Estado do modo de construção (móvel novo ou movido); nada muda até confirmar |
| Cena Cafe (`Cafe`) | `scenes/cafe/cafe.gd` | Dona do layout e do catálogo; modos VIEW e BUILD; traduz entrada em ações |
| CafeCamera | `scenes/cafe/cafe_camera.gd` | Pan, zoom (roda e pinça), tap, hover e enquadramento inicial |
| FloorView | `scenes/cafe/floor_view.gd` | Desenha piso, entrada, seleção e prévia verde/vermelha (placeholder) |
| WorldLayer / FurnitureView / AgentView | `scenes/cafe/` | Móveis, etiquetas de fogão e balcão, personagens com balão de pedido, tudo em y-sort (placeholders) |
| FloatingText | `scenes/cafe/floating_text.gd` | "+3", "+6 Café", "+2 XP" subindo e sumindo |
| GameHud | `scenes/ui/game_hud.gd` | Nível, barra de XP, Café Ouro, popularidade, cartão da missão, avisos e Recomeçar |
| BuildBar | `scenes/ui/build_bar.gd` | Loja (preço, nível, guardados), Expandir com confirmação, painel do fogão, ações do móvel, controles de construção |
| SmokeCheck | `scenes/debug/smoke_check.gd` | Checagem do jogo exportado com `-- --smoke-check` (DT-020) |
| WallView | `scenes/cafe/wall_view.gd` | Paredes do fundo com o revestimento aplicado (placeholder) |
| SoundBoard | `scenes/audio/sound_board.gd` | Toca os sons e guarda a preferência de som do aparelho |

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

## Atendimento (CafeSimulation)

```text
chegada (intervalo ÷ popularidade) → reserva uma cadeira livre ao lado de mesa
→ anda até ela → senta → pede o que houver no balcão (a porção fica reservada)
→ garçom: busca no balcão → leva à mesa → cliente come → paga (ouro + XP + popularidade)
→ vai embora

paciência acaba antes de ser servido → vai embora irritado (−popularidade, porção volta ao balcão)
```

- A cena chama `simulation.tick(delta)` a cada frame e só desenha o resultado.
- Ações do jogador passam pela simulação: `start_cooking` (cobra ingredientes) e `collect` (dá XP).
- Tudo o que a simulação precisa vem de `data/`: receitas, clientes, níveis, parâmetros e o jogo novo.

## Save

```text
abrir o jogo → SaveService.load_game
   ok ─────────────► simulação restaurada + "Bem-vindo de volta"
   sem save ───────► jogo novo (data/config/new_game.tres)
   save danificado ► usa o .bak (e guarda o ruim à parte)
   versão mais nova► jogo novo (e guarda o save à parte)

durante o jogo: algo mudou → salva (no máximo a cada 5 s)
minimizar / fechar → salva na hora
```

O arquivo fica em `user://save.json`. No Windows: `%APPDATA%\Godot\app_userdata\Café Manie\`.

## Módulos planejados (próximas fases)

Criados apenas quando a fase precisar deles:

| Fase | Módulos |
|---|---|
| 5 | Amigos, visitas, mapa, rankings (depende do backend da Fase 6) |
| 8 | Arte final, animações, música |

A lista completa de sistemas alvo está na seção 10 do master prompt.
