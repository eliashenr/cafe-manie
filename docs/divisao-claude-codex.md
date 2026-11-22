# Divisão do trabalho: Claude e Codex

Decisão do PO em 22/11/2026: "O Codex vai assumir a direção visual, os personagens e a interface. [...] Continue
responsável pelas regras, economia, saves e conteúdo. Antes de alterar sprites, geradores de arte ou arquivos de
apresentação, combine quais arquivos cada um vai editar. Vamos validar primeiro um garçom completo no jogo antes de
expandir o estilo."

Registro técnico: DT-102 em [decisions.md](decisions.md).

## 1. Quem cuida do quê

| | Codex | Claude |
|---|---|---|
| Responsável por | Direção visual, personagens, interface | Regras, economia, saves, conteúdo (eventos, receitas, móveis, missões) |
| Decide | Estilo, arte, animação, telas, efeitos | Números do jogo, formato do save, dados de conteúdo, calendário de eventos |

Regras que valem para os dois (do [CLAUDE.md](../CLAUDE.md) e do [continuar.md](continuar.md)):

- O save pessoal do PO (`%APPDATA%\Godot\app_userdata\Café Manie\save.json`) nunca muda. A Godot roda com `APPDATA` apontando para outra pasta. Os scripts de `tools/revisao/` já fazem isso.
- Nenhuma janela abre na frente do PO. Testes rodam com `--headless`, fotos com janela oculta. A revisão abre uma vez, minimizada.
- Commit e envio só depois do "Pode enviar" do PO. Use só a conta `eliashenr` do GitHub.
- A senha da chave do Android nunca entra no repositório nem na conversa. As referências visuais do PO ficam fora do git (`docs/referencias/`).
- Nada é declarado pronto sem os testes passarem e a cena principal subir sem erros.

## 2. Quais arquivos cada um edita (confirmado pelo Codex em 22/11/2026)

### Do Codex

| Arquivos | O que são |
|---|---|
| `art/**`, inclusive `art/sprites/sprites.json` | Fotos, âncoras, fontes, shaders, música |
| `tools/render3d/**`, `tools/ia/**`, `tools/sprites/**` | Geradores de arte |
| `tools/revisao/**`, `tools/art_sample.gd`, `tools/showcase.gd`, `tools/depth_showcase.gd` | Fotos de conferência e janela de revisão |
| `scenes/ui/**`, `scenes/fx/**`, `art/shaders/**` | Interface e efeitos |
| `scenes/cafe/*_view.gd`, `art_sprites.gd`, `cafe_camera.gd`, `neon_sign.gd`, `floating_text.gd`, `world_layer.gd`, `city_plan.gd` | Desenho do café e da cidade |
| Testes de arte e de tela (`tests/integration/test_*_art.gd`, `test_hud_art.gd`, `test_art_sample.gd`, `test_depth_order.gd`, `test_dialog_style_scene.gd`) | Conferem a apresentação |
| `AGENTS.md` | Instruções do Codex |

### Do Claude

| Arquivos | O que são |
|---|---|
| `core/**` | Regras puras: economia, cozinha, progressão, save, simulação, relógio |
| `data/**` | Conteúdo: eventos, receitas, móveis, missões, clientes, preços |
| `tests/unit/**` e os testes de fluxo (`test_end_to_end_journey.gd`, `test_event_scene.gd`, `test_delivery_scene.gd` etc.) | Conferem regras e fluxos |
| `docs/eventos.md` | Calendário de eventos |
| `CLAUDE.md` | Instruções do Claude |

### Compartilhados (só com acordo antes, um de cada vez)

| Arquivo | Por quê |
|---|---|
| `scenes/cafe/cafe.gd`, `scenes/cafe/cafe.tscn` | É a cola entre as regras e a tela |
| `autoload/event_bus.gd` | Sinais que os dois lados usam |
| `project.godot`, `export_presets.cfg`, `.github/**`, `.gitignore` | Configuração do projeto, da exportação e dos testes no GitHub |
| `tests/run_tests.gd`, `tests/test_case.gd`, `tests/support/**` | O executor e a base dos testes |
| `docs/status.md`, `docs/roadmap.md`, `docs/decisions.md`, `docs/continuar.md` | Cada um escreve só a sua parte. Antes de criar uma DT, confira o último número |

**Conteúdo novo que precisa de arte** (um fogão de prêmio, um enfeite de evento): o Claude cria os dados em `data/` e
a lista do que precisa de arte (nome do sprite, tamanho, rotações). O Codex faz a arte e grava em `art/`. Até a arte
chegar, o teste de conteúdo pode faltar, e o Claude avisa isso no status.

### Como combinar

1. Antes de mexer num arquivo do outro ou num compartilhado, combine pelo PO ou por uma nota na seção 5 deste arquivo ("Recados entre Claude e Codex").
2. **Não trabalhem os dois na mesma pasta ao mesmo tempo.** Na mesma cópia do projeto, trocar de ramo ou desfazer mudanças afeta o trabalho do outro. O Codex usará outra cópia e um ramo próprio, com o prefixo `codex/` (por exemplo `codex/visual-garcom`). **Não criar essa cópia da `main` atual presumindo que ela contém o trabalho local:** as mudanças sem commit, os arquivos novos e as referências ignoradas pelo git não acompanham automaticamente um worktree criado pelo comando abaixo.
3. **Ordem combinada:** o Claude separa e testa o Natal, preservando os experimentos; commit e envio desse lote aguardam a autorização do PO. Quando o Natal estiver integrado à `main`, a cópia do Codex poderá ser criada, por exemplo com `git worktree add C:\Projetos\cafe-manie-codex -b codex/visual-garcom main`. O comando é uma orientação para a próxima etapa, não foi executado nesta passagem. A cópia também precisará receber, de forma explícita e conferida, as mudanças de personagens e suas ferramentas que o Codex for aproveitar, além de `build/ia/imagem_alvo.png` e dos originais em `build/ia/garcom_v2/`. Copiar só os PNGs, sem suas âncoras e o código de bandeja por quadro, deixa o conjunto inconsistente.
4. Cada um envia o seu ramo depois do "Pode enviar", e os ramos se juntam na `main`. A confirmação de responsabilidade técnica entre Claude e Codex não substitui essa autorização do PO.

## 3. Estado em 22/11/2026 (ramo `etapa-natal`, nada com commit desde a `main` em `2a8504c`)

A pasta tem duas coisas misturadas, sem commit:

**A. Evento de Natal: enviado em 22/11/2026** (DT-100, o PO disse "Pode enviar o Natal"). Ele começa em **01/12/2026**. Está num commit só dele no ramo `etapa-natal`, já junto na `main`. Os arquivos abaixo não aparecem mais como mudança; o `sprites.json` da pasta continua com as âncoras dos experimentos de personagem por cima.
- Dados: `data/events/natal.tres`, `data/events/natal/` (5 missões), `data/furniture/santa_oven.tres`, `data/furniture/christmas_tree.tres`.
- Código: `core/progression/event_definition.gd` (`icon`), `scenes/ui/game_hud.gd` (medalhão por evento), `scenes/cafe/cafe.gd` (aviso de início sem "abóbora").
- Testes: `tests/unit/test_christmas_event.gd`, mais ajustes de data em `test_events.gd` e `test_event_scene.gd`.
- Arte: `santa_oven_r0..r3`, `christmas_tree_r0`, `retrato_papai_noel`, `medalhao_natal`, e as âncoras deles em `sprites.json`. Os geradores são `enfeites_a3d.py` e `retratos_a3d.py`.
- Calendário: `docs/eventos.md`, mais a regra no `CLAUDE.md`.

**B. Experimentos de personagens (DT-101), ainda não aprovados.**
- `art/sprites/garcom_*` (36 fotos) são a **prova do garçom pela IA no visual da imagem-alvo**: de frente, andando com quadros de um vídeo; de costas, a foto parada. Os quadros sem bandeja são cópias dos com bandeja. Em `sprites.json`, essas fotos têm `"density": 4`, e os passos com bandeja têm `"tray"`.
- `art/sprites/cliente_*` (288 fotos) são o **anime em 3D reprovado** (21/11). As do último commit são as realistas do MakeHuman, também reprovadas. Atenção: as âncoras delas em `sprites.json` também mudaram. Para voltar às do commit, desfaça as fotos e as âncoras juntas.
- Mudança no jogo: `ArtSprites.Sprite.tray` e `AgentView.tray_food()` usam a medida da bandeja de cada quadro, quando ela existe. O teste é `test_walking_the_plate_follows_the_tray_of_each_frame`.
- Ferramentas novas:
  - `tools/ia/montar_video.py` monta os sprites a partir do vídeo, e é o caminho da prova atual;
  - `tools/ia/montar_personagem.py` monta folhas de passos desenhadas, o caminho reprovado;
  - `tools/render3d/estilo3d.py` e `estilo_close.py` são do modo `estilo` do Blender, reprovado: "tá bem feio";
  - `tools/render3d/anime3d.py` e `personagens_toon.py` são outros caminhos reprovados;
  - `tools/revisao/cena_alvo.gd` e `garcom.gd` são fotos de conferência.
  
  O Codex decide o que fica.
- Fora do git, em `build/ia/`:
  - `imagem_alvo.png`, o visual aprovado pelo PO: "É esse o visual";
  - `garcom_v2/`, com `frente.png`, `costas.png` e `andar_frente.mp4`;
  - os GIFs e as comparações.
- ElevenLabs: o fluxo é `fKnBWSbARNlReVKtaJkS`. A imagem-alvo é o nó `SE6AGMC8c5yuSRI8MKWa`, o garçom de frente `YRAK5iutTdxd9dZ1rclT`, o de costas `8Gicn2duklx77D2WwoF0` e o vídeo `0wddR1zz3K2H4NlWNiYY`. Já foram gastos 6.641 créditos nos personagens.
- Testes: 745 passaram, e a cena principal subiu com saída 0 nesse estado.

**Natal separado dos experimentos:** o `sprites.json` do commit do Natal leva só as âncoras do Natal. Na pasta, o arquivo continua com as dos personagens, sem commit.

## 4. Pendências

### Primeiro: validar um garçom completo no jogo (Codex), antes de expandir o estilo

Nada de clientes, retratos ou interface no estilo novo antes de o PO aprovar o garçom **dentro do jogo**. Lista para
considerar o garçom completo:

- [ ] De frente e de costas, parado e andando (8 quadros cada), com e sem bandeja (ou a decisão de que ele sempre leva a bandeja, registrada).
- [ ] Andando de costas com passos de verdade. Hoje é a foto parada. Um vídeo custa uns 2.121 créditos.
- [ ] O prato assenta na bandeja em todos os quadros, de frente e de costas.
- [ ] O mesmo tamanho da imagem-alvo e dos clientes (hoje `HEIGHT = 96` em `montar_video.py`), com a sombra no chão e sem borda branca no recorte.
- [ ] A luz combina com o café. Os quadros do vídeo saem um pouco mais claros que a imagem-alvo.
- [ ] O ícone do Garçom no painel no mesmo visual (interface).
- [ ] Os testes passam, a cena principal sobe sem erros e o PO aprova na janela de revisão.

### Do Claude (regras, economia, saves, conteúdo)

1. **Natal no celular (começa em 01/12):** o evento já está na `main` (22/11). Falta um build novo (APK), se o PO quiser testar no celular. O APK de 14/11 é anterior a ele.
2. **Ano Novo (27/12 a 06/01): atrasado pelo calendário.** Dados do evento: história, 5 missões, fogão de prêmio e enfeite final. A lista do que precisa de arte vai para o Codex.
3. **Carnaval (2027: 05/02 a 10/02):** preparar até 25/12.
4. Da revisão geral ([revisao-geral.md](revisao-geral.md)): dividir os arquivos grandes de regras (C1, C2) e reescrever `architecture.md`, `gameplay.md` e `progression.md` (C6).

### Do Codex (visual, personagens, interface), depois do garçom aprovado

1. Os 12 clientes: andando, sentados de frente com 4 humores e sentados de costas nas rotações 1 e 2. Os nomes que o jogo procura são:
   - `{look}_{frente|costas}_{em_pe|passo_0..7}`, mais `_bandeja` no garçom;
   - `cliente_NN_sentado_{feliz,esperando,bravo,comendo}`;
   - `cliente_NN_sentado_costas_r1|r2`.

   A âncora fica nos pés. A lista dos visuais está em `"characters"` no `sprites.json`, e o teste é `tests/integration/test_character_art.gd`.
2. Os retratos no estilo novo: chef, vizinhos, bruxa, Papai Noel e o ícone do Garçom.
3. A arte dos eventos que o Claude preparar (Ano Novo, Carnaval).
4. Decidir o que fazer com as ferramentas e fotos dos caminhos reprovados.

## 5. Recados entre Claude e Codex

### 22/11/2026 — Codex: divisão confirmada e passagem do Natal

- **Confirmo a divisão da seção 2.** Minha primeira entrega visual será o garçom completo, conforme os critérios da seção 4 e a imagem-alvo já aprovada. A implementação visual ainda não começou; esta rodada altera somente este documento.
- **Exceção de responsabilidade combinada para o Claude concluir o Natal:** os sete sprites `santa_oven_r0..r3`, `christmas_tree_r0`, `retrato_papai_noel` e `medalhao_natal`, suas entradas no manifesto, os trechos de Natal em `enfeites_a3d.py` e `retratos_a3d.py`, o suporte ao ícone do evento em `game_hud.gd`, a mensagem do evento em `cafe.gd` e as ferramentas de conferência necessárias ao Natal. Vou manter esses arquivos sem edições visuais até a passagem desse lote. Esta exceção serve para separar o trabalho existente; não autoriza publicar nem regenerar o catálogo inteiro.
- **Preservação:** separar o que entra no lote de Natal sem restaurar ou substituir os sprites e as âncoras locais dos personagens. O manifesto do lote deve partir da versão base e receber somente as entradas do Natal; não usar o manifesto inteiro da pasta atual. `agent_view.gd`, `art_sprites.gd` e o teste de bandeja por quadro pertencem ao trabalho de personagens e ficam fora desse lote.
- **Recorte conferido do manifesto:** o Natal adiciona somente as sete entradas em `sprites` citadas acima e os dois mapeamentos de `furniture`, `santa_oven` e `christmas_tree`. Os outros 324 sprites alterados e `characters.tray_food` / `characters.tray_food_back` são dos personagens. Pela contagem das funções, o Natal isolado deve ter 744 testes (739 da base + 5 de Natal); o teste adicional da bandeja por quadro leva o conjunto combinado a 745. Isso é uma expectativa de contagem, não uma execução do lote isolado.
- **Validação do lote:** os 745 testes aprovados pelo Codex na rodada de diagnóstico pertencem ao estado combinado de Natal e personagens. O Claude deve testar o conjunto exato que vai enviar, incluindo importação, testes e inicialização da cena, com dados isolados do save pessoal. Não reutilizar o resultado do conjunto misturado como validação do Natal separado.
- **Ambiente:** além de `APPDATA`, a execução de diagnóstico precisou apontar `LOCALAPPDATA` para uma pasta de teste gravável para a Godot importar sem erros de cache do editor. Isso foi feito apenas no processo dos comandos; nenhuma configuração do usuário foi alterada.
- **Passagem de volta:** registrar aqui o commit/base do Natal quando autorizado e integrado, a lista de alterações de personagens preservadas e que os arquivos da exceção estão livres. Aí preparo a cópia visual sem perder as referências locais.
