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

- [x] Candidato DT-103: frente/costas, parado/andando (8 passos cada), com/sem bandeja, 36 poses próprias.
- [x] Costas com oito passos distintos; prato calibrado por quadro; sombra separada no chão.
- [x] Ícone do Garçom no visual do candidato.
- [x] Validação técnica: 750 testes Godot, 7 testes do importador, importação e cena principal com saída 0; capturas reais do café.
- [x] PO aprovou o visual dentro do jogo em 22/11/2026: "ficou bom [...] se for só isso, tá aprovado, pode seguir". Altura de referência: 96 pixels de mundo. A revisão foi corrigida para usar navegação real, contornando mesas a 3,2 células/s; dois testes focados passaram.

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

   Em pé, a âncora referencia os pés; sentado, o ponto sob os glúteos deve coincidir com o assento e é convertido para a âncora esperada pelo jogo. A lista dos visuais está em `"characters"` no `sprites.json`, e o teste é `tests/integration/test_character_art.gd`.
2. Os retratos no estilo novo: chef, vizinhos, bruxa, Papai Noel e o ícone do Garçom.
3. A arte dos eventos que o Claude preparar (Ano Novo, Carnaval).
4. Decidir o que fazer com as ferramentas e fotos dos caminhos reprovados.

## 5. Recados entre Claude e Codex

### 22/11/2026 — PO aprova cenário e autoriza a DT-107

- **Autorização expressa:** “Ficou muito bom! Pode enviar esse novo cenário e integrar à main. Deixa tudo registrado pro Claude saber o que mudou e continuar alinhado com você.” A publicação DT-106 usa `eliashenr`; novos ajustes de avatar/loja ficam em etapa separada.
- **Próxima intervenção:** continuidade da identidade ao personalizar o chef, movimento e resposta visual do retrato; reunir Loja/Reforma, hoje dois acessos ao mesmo catálogo. Codex assume `avatar_portrait.gd`, `avatar_dialog.gd`, `build_bar.gd`, arte necessária e testes de apresentação correspondentes. Se precisar ajustar a ligação de abertura em `cafe.gd`, apenas essa ligação visual fica reservada ao Codex nesta etapa; regras, preços e saves continuam com Claude.
- **Passagem:** preservar contratos da DT-106 e os experimentos herdados locais. Ano Novo e conteúdo/calendário continuam com Claude, conforme a divisão anterior. Sem alterações na pasta original dele.

### 22/11/2026 — Codex: cenário DT-106 instalado para revisão local

- Ramo `codex/visual-cenario`, base `94474fc`. Instalados 413 sprites: cozinha 150, revestimentos/janelas 139, decorações/portas 124. Os outros 754 sprites e todos os mapeamentos/apoios do manifesto foram preservados. A pasta do Claude segue intocada.
- Fontes novas e conferidores em `tools/render3d/`; revisão `Revisar Cenario.cmd` e catálogo de itens em `tools/revisao/`. Única alteração de teste existente: densidade visual do fogão/balcão básico agora 4, acompanhando o restante; regras e valores lógicos não mudaram.
- Validação encerrada: 764 testes Godot, 27 Python, 13 verificações focadas de controle de geração, cena principal 120 quadros e 70 capturas reais conferidas. Janela “Revisão do Cenário” aberta minimizada e confirmada no desktop (processo 23204), com dados isolados. Detalhes no topo de `status.md`; reprodução e contratos em `passagem-visual-codex.md`. Não regenerar o manifesto inteiro com fontes históricas. O novo cenário aguarda avaliação do PO e não foi enviado; a entrega anterior continua publicada na `main`.

### 22/11/2026 — Codex: envio e integração confirmados

- Entrega DT-103/104/105: commit `a09f8e9`, [PR #1](https://github.com/eliashenr/cafe-manie/pull/1), integrada à `main` em `449e755` com a conta `eliashenr`. O PO confirmou expressamente: “Sim, pode integrar à main”. CI de push e PR aprovados antes da integração.
- Claude: ler primeiro [passagem-visual-codex.md](passagem-visual-codex.md). Sua pasta foi apenas consultada; continua no ramo `etapa-natal`, com experimentos locais preservados. Não atualizar essa pasta descartando alterações. A integração dos arquivos deve preservar o trabalho local e tratar o manifesto junto com os PNGs correspondentes.
- Codex já começou a extensão DT-106 em arquivos novos e pastas de saída separadas, sem modificar a arte instalada durante a geração. Essa arte nova ainda não foi enviada nem aprovada. Regras, conteúdo, calendário e save seguem com o Claude.

### 22/11/2026 — PO aprova a DT-105, autoriza envio e amplia o cenário

- **Aceite e autorização:** “Ficou muito bom! Pode enviar e deixa tudo registrado pro Claude saber o que mudou e continuar alinhado com você.” A aprovação abrange a reformulação apresentada na DT-105, além do garçom aprovado anteriormente. Envio com a conta `eliashenr`.
- **Passagem:** [passagem-visual-codex.md](passagem-visual-codex.md) concentra as mudanças, os contratos de arte, os testes e as instruções de integração. Os experimentos antigos herdados que não participam do jogo aprovado ficam fora deste envio, preservados localmente.
- **Próxima frente autorizada (DT-106):** fogões, balcões/máquinas de cozinha, janelas, pisos/revestimentos e decorações existentes, mantendo IDs e temas. Codex continua com `art/**`, geradores e apresentação; Claude com regras, conteúdo, calendário e save. Um único escritor integra `sprites.json`; fontes e propostas são preparadas separadamente.
- **Coordenação:** Codex principal integra e registra; arte cuida da cozinha; interface cuida de pisos/paredes/janelas; QA audita a entrega e depois cuida dos enfeites. Sem mudanças em `core/**`/`data/**`; contratos de sobreposição e suporte de panelas/pratos devem ser mantidos. Ajustes de apresentação compartilhados, se necessários, serão registrados aqui antes de editar.

### 22/11/2026 — Codex: reformulação integrada e revisão aberta (DT-105)

- Implementados clientes/assentos mais proporcionais, 25 assentos e 26 mesas por coleção, HUD, central, telas, retratos e ícones. Garçom aprovado e 216 poses em pé/andando preservados. Pratos e indicadores acompanham o novo tamanho e a nova paleta.
- Não foi necessário alterar `cafe.gd`, `cafe.tscn`, autoloads, configuração, `core/**` ou `data/**`. Mantida a divisão de conteúdo, regras, economia e save com o Claude. A pasta original do Claude não foi modificada.
- 764 testes Godot e 27 testes Python passaram; cena principal sem erros. Conferência visual dos 12 clientes e do conjunto concluída; evidências e limites na seção DT-105 de `status.md`. Importador, gerador de móveis e instalador têm fontes/calibração reproduzíveis.
- Revisão aberta uma vez, minimizada, com dados isolados: `Revisar Visual.cmd`. C alterna coleções e N dia/noite. Aguardando avaliação visual do PO; nenhuma aprovação presumida para o conjunto novo. Sem commit/envio.
- Antes de integrar esta cópia após o “Pode enviar”, combinar novamente o escritor de `sprites.json` e dos documentos compartilhados; conferir alterações de conteúdo que o Claude tenha feito na outra pasta. Não copiar o manifesto inteiro sobre trabalho novo de terceiros.

### 22/11/2026 — PO autoriza a reformulação visual ampla pelo Codex

- **Pedido:** ajustar proporções e pés dos clientes; redesenhar mesas e cadeiras por coleção (Japão, Brasil e demais estilos), reduzindo cadeiras largas; renovar o HUD, a central e quase todo o front-end. O PO pediu execução autônoma, consultando apenas quando houver autorização realmente necessária.
- **Escopo Codex:** personagens, móveis e seus geradores, retratos, interface, apresentação do café/cidade, ferramentas de revisão e testes de apresentação. Preservar os temas e ids de conteúdo existentes. O aceite anterior do garçom continua válido.
- **Coordenação desta cópia:** um único escritor instala lotes e altera `sprites.json`. Trabalho dividido entre clientes/integração (Codex principal), modelos de mesas/cadeiras (arte), `scenes/ui/**` (interface) e auditoria/capturas (QA). Cada frente prepara resultados locais para integração, sem mexer na pasta do Claude.
- **Arquivos compartilhados:** o pedido do PO autoriza as ligações de apresentação necessárias em `cafe.gd`/`cafe.tscn` nesta cópia; se forem usadas, registrar o trecho e manter regras, persistência e sinais de domínio intactos. Novas ferramentas de QA e apoio a testes ficam separadas; executor comum não precisa mudar. Documentos compartilhados recebem somente a etapa visual do Codex.
- **Limites mantidos:** `core/**`, `data/**`, economia, calendário e saves continuam com o Claude. O Ano Novo permanece pendente dele. APPDATA/LOCALAPPDATA isolados; capturas ocultas e revisão final minimizada. A autorização de reformular não inclui commit/push: continuam dependendo de “Pode enviar”.

### 22/11/2026 — Codex: divisão confirmada e passagem do Natal

- **Confirmo a divisão da seção 2.** Minha primeira entrega visual será o garçom completo, conforme os critérios da seção 4 e a imagem-alvo já aprovada. A implementação visual ainda não começou; esta rodada altera somente este documento.
- **Exceção de responsabilidade combinada para o Claude concluir o Natal:** os sete sprites `santa_oven_r0..r3`, `christmas_tree_r0`, `retrato_papai_noel` e `medalhao_natal`, suas entradas no manifesto, os trechos de Natal em `enfeites_a3d.py` e `retratos_a3d.py`, o suporte ao ícone do evento em `game_hud.gd`, a mensagem do evento em `cafe.gd` e as ferramentas de conferência necessárias ao Natal. Vou manter esses arquivos sem edições visuais até a passagem desse lote. Esta exceção serve para separar o trabalho existente; não autoriza publicar nem regenerar o catálogo inteiro.
- **Preservação:** separar o que entra no lote de Natal sem restaurar ou substituir os sprites e as âncoras locais dos personagens. O manifesto do lote deve partir da versão base e receber somente as entradas do Natal; não usar o manifesto inteiro da pasta atual. `agent_view.gd`, `art_sprites.gd` e o teste de bandeja por quadro pertencem ao trabalho de personagens e ficam fora desse lote.
- **Recorte conferido do manifesto:** o Natal adiciona somente as sete entradas em `sprites` citadas acima e os dois mapeamentos de `furniture`, `santa_oven` e `christmas_tree`. Os outros 324 sprites alterados e `characters.tray_food` / `characters.tray_food_back` são dos personagens. Pela contagem das funções, o Natal isolado deve ter 744 testes (739 da base + 5 de Natal); o teste adicional da bandeja por quadro leva o conjunto combinado a 745. Isso é uma expectativa de contagem, não uma execução do lote isolado.
- **Validação do lote:** os 745 testes aprovados pelo Codex na rodada de diagnóstico pertencem ao estado combinado de Natal e personagens. O Claude deve testar o conjunto exato que vai enviar, incluindo importação, testes e inicialização da cena, com dados isolados do save pessoal. Não reutilizar o resultado do conjunto misturado como validação do Natal separado.
- **Ambiente:** além de `APPDATA`, a execução de diagnóstico precisou apontar `LOCALAPPDATA` para uma pasta de teste gravável para a Godot importar sem erros de cache do editor. Isso foi feito apenas no processo dos comandos; nenhuma configuração do usuário foi alterada.
- **Passagem de volta:** registrar aqui o commit/base do Natal quando autorizado e integrado, a lista de alterações de personagens preservadas e que os arquivos da exceção estão livres. Aí preparo a cópia visual sem perder as referências locais.

### 22/11/2026 — Codex: registro da própria etapa visual (DT-103)

- **Escopo desta atualização:** nesta cópia de trabalho, o Codex atualiza somente suas etapas visuais de garçom e clientes em `status.md`, `continuar.md`, `roadmap.md`, `decisions.md` e `art-direction.md`. O histórico e as pendências de conteúdo do Claude ficam preservados.
- **Base recebida:** `737f73e`, depois da integração do Natal (`2c72ce6`). Os experimentos locais de personagens e suas referências foram preservados na passagem; a prova nova substitui apenas o garçom nesta cópia visual.
- **Candidato à revisão:** 36 poses próprias (frente/costas, com/sem bandeja, 8 passos e uma pose parada por combinação), retrato do Garçom, âncoras calibradas e sombra separada no piso. Fontes e calibração em `art/characters/waiter/`; importador em `tools/ia/importar_garcom_codex.py`.
- **Origem da nova arte:** geração de imagens da OpenAI disponível no Codex. Esta etapa não usa créditos do ElevenLabs; os números registrados na DT-101 pertencem à experiência anterior.
- **Validação da rodada do garçom:** 750 testes Godot e 7 testes do importador passaram; importação e cena principal por 120 quadros com saída 0. Captura final de 37 PNGs e foto noturna individual sem erros. O PO aprovou o visual na sequência, conforme o recado abaixo; commit/envio continuam pendentes.
- **Retomada:** cópia visual ativa em `C:\Users\Elias\.codex\worktrees\visual-garcom\cafe-manie`, ramo `codex/visual-garcom`; 804 arquivos copiados e conferidos por hash. A cópia aninhada permanece como backup com HEAD destacado. Usar as instruções da seção mais recente de `continuar.md`; caminhos de ferramentas e arte são relativos ao repositório.

### 22/11/2026 — Codex: garçom aprovado, início dos clientes

- **Aceite do PO:** "ficou bom [...] se for só isso, tá aprovado, pode seguir". O garçom foi aprovado no jogo. A crítica à lentidão e a atravessar mesas se referia ao corredor artificial da ferramenta de revisão.
- **Revisão corrigida:** a amostra do garçom usa caminhos da navegação real e `Agent.follow`/`advance`, a 3,2 células/s, contornando móveis. Os dois testes focados passaram. O antigo 0,4 fica apenas nas capturas determinísticas; nenhuma regra de produção mudou.
- **Etapa autorizada, primeiro lote candidato v2 (DT-104):** 12 folhas originais de 24 poses e 12 folhas separadas de seis poses sentadas, selecionadas por `group.file`/`group.cells`; as 216 poses em pé/andando ficam intactas e o catálogo mantém 288 sprites. Fontes RGBA e calibração em `art/characters/customers/`, prompts v2 em `ajuste-assentos-v2.json`. A aprovação do garçom não aprova automaticamente os clientes.
- **Arquivos desta etapa:** fontes em `art/characters/customers/`, `cliente_*` e suas entradas em `sprites.json`, importador em `tools/ia/`, revisão em `tools/revisao/` e testes de apresentação. O Codex atualiza só sua parte nos documentos compartilhados. `core/`, `data/` e o conteúdo do Claude permanecem fora da etapa.
- **Apoio aos testes combinado nesta cópia:** adicionar `tests/support/legacy_character_art.gd`, helper exclusivo para simular metadados antigos e continuar verificando quique/esticamento legado. Não alterar executor, base comum nem testes de regras.
- **Validação dos clientes:** 758 testes Godot e 15 Python passaram (8 do importador de clientes e 7 do garçom). Os lotes 01–06 e 07–12 estão calibrados e instalados: 288 sprites, incluindo 72 sentados v2; nenhuma pose falta gerar para este primeiro candidato. Após instalação: importação e cena por 120 quadros com saída 0, 6 testes focados aprovados e 111 capturas de dia + 1 à noite sem erros; 108 detalhes em 13 montagens. Escopo e preservação verificados em `final-verificacao.json`, com resultado consolidado em `status.md`. Revisão com amostra em memória, sem save pessoal; a janela minimizada precisa ser iniciada fora do sandbox para aparecer na área de trabalho do PO.
- **Refinamento a apresentar ao PO:** pés elevados em algumas poses, chegando a cerca de 12 pixels de mundo no 05 (03 ~9,4; 02 ~7). No lote 07–12, os pés ficam 4,8–8,1 pixels elevados e a cabeça varia 13–32% entre frente/costas, mais evidente no 09. Entregar o primeiro candidato para avaliação com essas limitações, sem declarar encaixe e proporções resolvidos. A aprovação visual dos clientes segue pendente.
- **Publicação:** aprovação visual e "pode seguir" autorizam continuar o trabalho; commit/envio seguem aguardando "Pode enviar".
