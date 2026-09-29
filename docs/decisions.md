# Decisões técnicas

Registro no formato da seção 99 do master prompt. As mais recentes ficam no topo.

---

## DT-020 — Entrega para o PC: um .exe só, com checagem automática do build

**Problema:** o PO precisa jogar sem instalar a Godot, e um build exportado pode se comportar diferente do editor (os arquivos de `data/` são convertidos e renomeados na exportação).

**Decisão:**
- `export_presets.cfg` com **Windows** (um `CafeManie.exe` com o conteúdo embutido, sem arquivos soltos) e **Linux** (usado para testar o build na nuvem). Testes e docs ficam fora do pacote.
- `SmokeCheck`: o jogo exportado aceita `-- --smoke-check`. Ele sobe a cafeteria, roda 600 quadros, confere se móveis, receitas, clientes, missões e expansões carregaram e se nenhum erro apareceu, e fecha com 0 ou 1. Não salva nada.
- O conteúdo embutido no `.exe` do Windows é verificado carregando-o com o motor do Linux (`--main-pack CafeManie.exe`). O executável do Windows é o da própria Godot, sem modificação. Um teste com um build sem a pasta de missões confirmou que a checagem reprova.
- **Entrega:** o `.exe` compactado em zip passa de 30 MB, o limite de envio de arquivos na conversa. Por isso, ele vai dentro de um autoextraível do 7-Zip (`CafeManie-Instalar.exe`, ~22 MB), feito com o módulo oficial `7z.sfx`. Testado: a extração gera um `CafeManie.exe` idêntico, byte a byte, ao exportado. Quando o GitHub estiver liberado, o build pode ir para a página de Releases.
- O `.exe` não é assinado (custa um certificado pago). O Windows mostra "O Windows protegeu o computador" na primeira vez; o README explica o que fazer.

---

## DT-019 — Missões iniciais como tutorial, uma de cada vez

**Problema:** seção 143 (6 missões iniciais) e a Vertical Slice (seção 81) pedem um primeiro contato guiado.

**Decisão:** as missões são dados (`data/missions/*.tres`, com tipo, alvo, recompensa e **dica**). O `MissionTracker` mantém **uma missão ativa por vez**, em ordem, e conta só os eventos daquele tipo. A dica fica sempre visível no cartão do canto direito, então as missões *são* o tutorial, sem telas extras. Uma missão de "chegar ao nível N" já cumprida conclui na hora em que fica ativa. A recompensa é paga antes de a próxima começar a contar, e o XP da recompensa já pode contar para ela.

---

## DT-018 — Expansão cresce para a direita e para trás

**Problema:** ampliar o grid não pode quebrar nada que já está posicionado.

**Decisão:** o grid só cresce (nunca diminui), mantendo a origem. Assim nenhum móvel muda de célula. A entrada fica sempre na borda da direita, na mesma linha: quando a largura cresce, ela acompanha a borda. Garçom e clientes saindo passam a usar a nova entrada. As etapas (tamanho, nível e preço) ficam em `data/config/expansions.tres`, e a compra pede confirmação (seção 32).

---

## DT-017 — Loja e inventário: guardar em vez de vender

**Problema:** móveis precisam custar Café Ouro e nível (Fase 3), sem compra acidental e sem o jogador perder o que pagou.

**Decisão:**
- Móvel novo é **cobrado só ao confirmar** a posição. Antes disso, a prévia mostra o preço, e cancelar não custa nada. Posição inválida nunca cobra. A etapa de posicionar já funciona como confirmação da compra (seção 32).
- O botão **Guardar** (antes "Remover") leva o móvel ao **inventário**. Recolocar um móvel guardado é grátis e não exige nível. Não existe venda por enquanto, então nenhum toque destrói ouro.
- Os botões da loja mostram preço, "Nível N" ou "N guardado(s)", e ficam desabilitados quando não dá. Eles são atualizados no lugar a cada quadro, sem serem recriados, para um clique não se perder quando um cliente paga no meio dele.

---

## DT-016 — Quando salvar

**Problema:** salvar a cada frame desgasta o armazenamento; salvar pouco perde progresso. No celular o sistema pode encerrar o jogo minimizado sem aviso.

**Decisão:** o jogo marca "tem mudança" quando layout, cozinha, ouro, XP, popularidade, inventário ou missões mudam, e salva no máximo a cada 5 s (`autosave_min_interval`). Ao minimizar, perder o foco, fechar ou sair da cena, salva na hora. "Recomeçar" apaga o save, desliga o salvamento e recarrega a cena, com confirmação e **Cancelar** como botão já selecionado.

---

## DT-015 — Formato e segurança do save

**Problema:** seções 63–64 (save local versionado com migração) e a regra de nunca perder progresso.

**Decisão:**
- JSON legível em `user://save.json`, com `save_version` e `saved_at`. `SaveCodec` converte; `SaveService` grava e lê.
- Salva: layout (com os ids originais dos móveis), cozinha (receita e **horário de início**, então o preparo continua com o jogo fechado), balcões, ouro, XP e popularidade.
- Não salva personagens: a cafeteria reabre vazia, e as porções que estavam reservadas para pedidos voltam ao balcão.
- **Gravação atômica:** escreve em `.tmp` e só então troca. O save anterior vira `.bak`.
- **Leitura defensiva:** conteúdo desconhecido (um móvel que deixou de existir) é pulado com aviso, e o resto carrega. Save ilegível → usa o `.bak`. Save de versão mais nova que o jogo → guardado à parte, nunca sobrescrito. Nenhum arquivo é apagado automaticamente.
- **Migração:** `SaveCodec.migrations()` guarda um passo por versão. A versão 2 acrescentou inventário e progresso das missões; um save da versão 1 é migrado sozinho (inventário vazio, primeira missão).
- **Ids nunca repetem:** o contador de ids é salvo, e o layout ainda confere se o id gerado já existe (defesa em profundidade; um teste de mutação mostrou que um id repetido sobrescreveria um móvel em silêncio).

---

## DT-014 — Porção reservada no pedido

**Problema:** dois clientes podem pedir a última porção ao mesmo tempo.

**Decisão:** a porção sai do balcão no momento do pedido e fica "reservada" para aquele cliente. Se ele desiste antes de o garçom buscar, a porção volta ao balcão. Se o garçom já estava com o prato na mão, o prato é perdido (demorar tem custo).

---

## DT-013 — Personagens não colidem entre si

**Problema:** o master prompt pede para evitar congestionamentos (seção 16).

**Decisão:** por enquanto clientes e garçom podem se sobrepor ao cruzar o mesmo piso, como na maioria dos jogos casuais do gênero. Evitar colisão entre personagens custa bastante e pode travar corredores estreitos. Reavaliar se o teste do PO mostrar que incomoda visualmente.

---

## DT-012 — Móvel em uso e personagem no caminho

**Problema:** edge cases da seção 87: "mover objeto durante atendimento", "remover um móvel usado", "bloquear o caminho".

**Decisão:** o `CafeLayout` recebe da simulação duas consultas opcionais: se um móvel está em uso (fogão com preparo, balcão com comida ou com prato reservado, cadeira com cliente e a mesa dela) e quais pisos têm alguém andando. Móvel em uso não pode ser movido, girado nem removido; nenhum móvel pode ser posto em cima de alguém. Quando o layout muda, quem está andando recalcula o caminho; se ficou cercado (caso raro), volta para a entrada em vez de ficar preso.

---

## DT-011 — Simulação pura com relógio injetável

**Problema:** testar atendimento, tempos de preparo e jogo fechado sem esperar tempo real.

**Decisão:** `CafeSimulation` é uma classe pura (sem nós) que avança com `tick(delta)`. O preparo usa horários do `GameClock` e, por isso, continua com o jogo fechado; os personagens só andam com o jogo aberto. Nos testes entra um `ManualClock` e uma semente fixa de sorteio, então um turno de 30 minutos roda em ~1 segundo e sempre igual. Quando houver backend, o `GameClock` passa a usar o horário do servidor (seção 66).

---

## DT-010 — Catálogos de conteúdo por composição

**Problema:** móveis, receitas e clientes carregam dados do mesmo jeito; copiar o código violaria a seção 93.

**Decisão:** `DefinitionStore` genérico faz o carregamento e a validação; cada catálogo (`FurnitureCatalog`, `RecipeCatalog`) o usa por dentro e mantém a própria API tipada. Herança foi descartada porque a GDScript não deixa a subclasse mudar o tipo de retorno.

---

## DT-009 — Ordem de desenho dos móveis pelo vértice da frente

**Problema:** no isométrico, móveis mais "à frente" precisam ser desenhados por cima.

**Opção A:** `y_sort` da Godot com cada móvel posicionado no vértice da frente da sua base.
**Opção B:** ordenação topológica própria entre as caixas.

**Impactos:** A é nativo e barato, e funciona para os móveis atuais (conferido em captura com 12 móveis de 1×1 e 2×1). Pode errar em casos raros com móveis longos lado a lado em profundidades cruzadas. B é correto em todos os casos, mas custa código e desempenho.

**Recomendação:** A agora, com revisão quando entrar a arte final e móveis maiores (Fase 8).
**Motivo:** regra de simplicidade; o risco está registrado no roadmap.

---

## DT-008 — Enquadramento inicial da câmera considerando a interface

**Problema:** em 1280×720, a fileira de trás ficava sob o painel de cima e o canto da frente sob a barra de baixo (achado na captura de tela).

**Decisão:** a câmera enquadra o grid (mais uma folga para a altura dos móveis) só na faixa livre entre as barras, sem nunca passar de zoom 1. As alturas das barras e a folga são `@export` na cena da cafeteria.

---

## DT-007 — Acesso aos móveis garantido já no posicionamento

**Problema:** o master prompt pede que garçons e clientes nunca fiquem presos (seção 16) e que o jogador não consiga travar a cafeteria (edge case "bloquear o caminho", seção 87).

**Opção A:** deixar posicionar livremente e resolver no pathfinding (NPC fica parado quando não há caminho).
**Opção B:** recusar no posicionamento qualquer layout em que um móvel funcional fique sem caminho até a entrada.

**Impactos:** A cria estados quebrados que o jogador não entende. B explica na hora ("Isso deixaria outro móvel sem acesso") e garante que a Fase 2 sempre encontre caminho.

**Recomendação:** B, com busca em largura sobre o grid lógico (mesma malha do futuro `AStarGrid2D`). Decoração (`needs_access = false`) pode ficar em cantos fechados.
**Motivo:** layout estratégico continua possível (seção 16), só o layout impossível é barrado.

---

## DT-006 — Entrada de toque sem emulação de mouse

**Problema:** por padrão a Godot gera um evento de mouse para cada toque. A câmera trata mouse e toque separadamente, então cada gesto seria processado duas vezes.

**Opção A:** manter a emulação e tratar só eventos de mouse.
**Opção B:** desligar a emulação (`input_devices/pointing/emulate_mouse_from_touch=false`) e tratar mouse e toque cada um no seu caminho.

**Impactos:** A perde a pinça com dois dedos, porque mouse só tem um ponteiro. B exige tratar os dois tipos de evento.

**Recomendação:** B.
**Motivo:** a pinça é essencial no celular (seção 41), e o tratamento duplo é pequeno e coberto por testes.

---

## DT-005 — Executor de testes próprio em vez de GUT

**Problema:** o discovery previa usar GUT (Godot Unit Test) para testes automatizados.

**Opção A:** instalar o GUT como addon.
**Opção B:** manter um executor próprio e mínimo (`tests/run_tests.gd`, cerca de 100 linhas).

**Impactos:** o GUT traz relatórios e mocks, mas é uma dependência externa que precisa acompanhar cada versão da Godot. O executor próprio não tem dependência, roda sem interface e reprova o teste quando ocorre um erro de script (verificado com um teste de sanidade propositalmente quebrado).

**Recomendação:** B por enquanto.
**Motivo:** regra de simplicidade (seção 94). Se precisarmos de mocks ou relatórios em CI, migrar para GUT é barato, porque os testes já seguem o mesmo formato (`test_*`).

---

## DT-004 — Piso desenhado por código no protótipo

**Problema:** como desenhar o piso isométrico antes de existir arte.

**Opção A:** `TileMapLayer` isométrico com um tileset placeholder.
**Opção B:** desenhar os losangos por código (`FloorView._draw`).

**Impactos:** A exige criar e manter um arquivo de tileset só para placeholder. B não usa nenhum asset e depende do mesmo `IsoProjection` que a lógica de clique usa, então visual e clique nunca divergem.

**Recomendação:** B agora. Reavaliar `TileMapLayer` quando chegar a arte final de pisos (Fase 8).
**Motivo:** o que importa no protótipo é o clique cair no piso certo, e isso fica garantido por construção.

---

## DT-003 — Grid lógico cartesiano com projeção isométrica separada

**Problema:** onde vive a "verdade" sobre posições de objetos.

**Opção A:** usar coordenadas do `TileMap` como verdade.
**Opção B:** grid lógico próprio (`CafeGrid`) em coordenadas inteiras, com conversão para tela em `IsoProjection`.

**Impactos:** B é testável sem tela, serve de base direta para `AStarGrid2D` no pathfinding e pode ser validado no servidor.

**Recomendação:** B.
**Motivo:** seções 15, 16, 62 e 152.

---

## DT-002 — Formato de dados de conteúdo

**Problema:** formato de receitas, móveis e níveis.

**Opção A:** JSON.
**Opção B:** Custom Resources da Godot (`.tres`).

**Impactos:** Resources são tipados, editáveis no inspetor e acusam erro de campo claramente. JSON é melhor para trafegar pela rede.

**Recomendação:** Resources para conteúdo e JSON para save e sincronização.
**Motivo:** o PO consegue balancear preços e tempos direto no editor, sem abrir código. *Aplicação a partir da Fase 1 (móveis).*

---

## DT-001 — Código no GitHub, testes na nuvem, teste visual no PC do PO

**Problema:** onde o código vive e como o PO testa.

**Decisão do PO:** repositório `eliashenr/cafe-manie` no GitHub.

**Como funciona:** o Claude desenvolve e roda os testes automatizados num ambiente próprio, com Godot 4.7.2 sem interface, e envia os commits ao GitHub. O PO baixa o projeto e roda na Godot do próprio PC para o teste visual e de sensação.
