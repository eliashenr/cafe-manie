# Decisões técnicas

Registro no formato da seção 99 do master prompt. As mais recentes ficam no topo.

---

## DT-079 — Redesign, etapa 3: as janelas no mesmo padrão

**Problema:**
- Depois das etapas 1 e 2, as janelas já estavam escuras, mas cada uma tinha um jeito: todos os botões azuis (Fechar e Comprar iguais), abas como botões comuns, o presente diário com o dia de hoje amarelo-claro, conquistas em texto corrido e pacotes de ouro como botões azuis.

**Decisão:**
- **Papéis dos botões** no tema (`UiTheme`), como variações do tema do Godot:
  - **azul tecnológico** (o padrão): a ação principal, como Próximo e Melhorar;
  - **verde** (`SuccessButton`): receber, comprar e confirmar;
  - **fantasma** (`GhostButton`): Fechar, Cancelar e Depois, em vidro com borda que acende em ciano;
  - **vermelho** (`DangerButton`): só o "Apagar e recomeçar";
  - **aba** (`TabButton`): a escolhida em azul com brilho ciano, as outras transparentes. Vale para a loja, o avatar e a cidade; as abas das missões seguem o mesmo visual.
  - O botão com foco (como o Cancelar já selecionado nas perguntas) ganha um anel ciano.
- **Fundo escurecido** atrás de qualquer janela aberta, numa camada acima do HUD e da barra.
  - Os avisos ficam por cima do escuro e descem para baixo da tela enquanto a janela está aberta (no alto, a janela cobriria).
- **Perguntas** com o texto quebrado em linhas (500 px de largura), com os botões perto um do outro.
- **Cada janela:**
  - **Presente diário:** cartões com "Hoje" em ciano e brilho, os dias recebidos apagados com o visto, e o desenho do prêmio (moeda, estrela do XP, o móvel ou o presente).
  - **Conquistas:** um cartão por conquista, com o troféu (apagado antes do primeiro degrau), uma estrela por degrau, a barra do próximo degrau e o prêmio com a moeda; a completa ganha a borda dourada.
  - **Pacotes de Café Ouro:** cartões com a pilha de moedas maior a cada pacote, o ouro em dourado, o preço e o selo do bônus; o que rende mais por real ganha o selo "Melhor valor" e a borda dourada.
  - **Missões:** barras em ciano (verde quando conclui) e o prêmio em dourado com a moeda.
  - **Avatar e evento:** o retrato num palco de vidro com brilho ciano.
  - **Cidade:** a arte da filial emoldurada e os vizinhos em cartões deitados, 3 por linha. Trocar de aba ajusta o tamanho da janela e a centraliza.
- **Barra de progresso** do tema em ciano; concluído, em verde.

---

## DT-078 — Redesign, etapa 2: a loja nova

**Problema:**
- A loja antiga era uma faixa clara embaixo da tela: 6 itens por página, abas coloridas no alto e nenhuma explicação do item.
- A referência do PO mostra uma loja grande, escura, com as categorias à esquerda, as coleções no alto, uma grade de itens e um painel de detalhes com o botão "Comprar".

**Decisão:**
- **Painel de vidro** que ocupa a tela abaixo do perfil e dos contadores (que continuam à vista).
  - O menu lateral, os botões da direita, a missão e a satisfação saem enquanto a loja está aberta e voltam quando ela fecha (`GameHud.set_shop_open`).
- **Coluna das categorias** à esquerda, com o ícone de cada uma: Salão, Cozinha, Decoração, Pisos, Paredes e Cupons. A ativa fica em azul tecnológico, com brilho ciano.
- **Coleções no alto**, em pílulas escuras com a borda na cor da coleção; a escolhida fica cheia. A fileira rola para o lado (dedo ou roda do mouse).
- **Grade de 5 × 3 cartões** (15 por página, antes eram 6).
  - O cartão é escuro, com o desenho, o nome, o preço em dourado (vermelho sem ouro) e o selo da coleção embaixo.
  - Bloqueado, mostra o cadeado e "Nível N".
- **Painel de detalhes** do cartão escolhido:
  - desenho grande, nome, coleção, para que serve, preço e o botão (Comprar, Colocar no café, Usar ou Nível N);
  - **benefícios tirados dos dados do item, nada inventado:** beleza, perfil do fogão (tempo, porções, XP, limite de tempo), troféu (quanto acelera e por quantos pratos), atração (ouro por brincadeira e quanto guarda), pé de fruta, luz à noite, limite por café, janela que deixa a luz entrar e o bônus do terraço;
  - conforto e eficiência ficam de fora: estão nos dados, mas não mudam nada no jogo.
- **Como comprar:** o primeiro toque escolhe e mostra os detalhes; tocar de novo no mesmo cartão, ou em "Comprar", faz a mesma ação de antes.
  - As confirmações continuam as mesmas (porta, terraço, item de parede e troca por cupons).
  - Ao abrir a loja, o primeiro item já aparece no painel.
- **Avisos da loja** (cupons, falta de ouro) aparecem dentro do painel, embaixo das coleções.
- **Testes:** a ajuda `buy_in_shop` (tocar no cartão e em Comprar) nos testes que compram pela loja, e testes novos do painel, do segundo toque, do bloqueio e do menu lateral.

---

## DT-077 — Redesign "Nova York Futurista": sistema de design e HUD

**Problema:**
- O PO pediu a reformulação visual de todo o jogo, a partir de duas imagens de referência (Nova York futurista, interface escura premium) e de um prompt detalhado.
- A direção anterior ("Esquina Nostálgica", dia claro e cores vivas) foi uma escolha do PO em setembro; o pedido novo a substitui.

**Decisão:**
- **Direção nova registrada** em `docs/art-direction.md`, em 7 etapas (`docs/roadmap.md`).
  - A arte antiga continua no histórico do Git.
- **Sistema de design** em `UiTheme`, com a paleta do PO e uma função para cada cor.
  - Os nomes antigos de cor apontam para as cores novas, então a loja, as janelas e a barra herdam o visual escuro de uma vez.
  - Depois, cada tela recebe o acabamento dela.
- **HUD novo**, com os mesmos controles e funções (nenhum botão sem função):
  - cartão do perfil com o retrato do chef (o avatar montado pelo jogador), selo do nível, nome do café (toque para trocar), "Nova York" e a barra de XP em degradê;
  - contadores em pílulas: ouro com o "+", energia, cupons (no lugar dos diamantes da referência) e beleza;
  - no alto à direita, o presente diário com o cronômetro, o cronômetro do evento (só durante o evento) e a engrenagem;
  - menu lateral em blocos de vidro: missões, presentes, conquistas e evento, com as bolinhas de aviso;
  - botões da direita (pausa, porta, zoom, som, música) em vidro escuro, com o símbolo na cor da função;
  - satisfação com a carinha, o percentual, "Satisfeitos", as estrelas e o que ela mede;
  - a barra de baixo com os 9 ícones e nomes limpos.
- **Testes:** os nomes dos nós continuam os mesmos, e os testes novos cobrem o retrato do perfil e o cronômetro do evento.

---

## DT-076 — Correções do QA de ponta a ponta

**Problema:**
- O QA de ponta a ponta (23/10) achou 6 defeitos:
  - janelas novas fora da regra de uma janela por vez;
  - toque duplo nas entregas;
  - confirmar da filial sem pergunta;
  - relógio atrasado travando entregas e filial;
  - save estragado dando erro de script;
  - o quadro de satisfação cortado pela loja em tela larga.

**Decisão:**
- **Regra de uma janela por vez:** o Avatar e a Cidade entram em `Cafe.is_dialog_open()`.
- **Botões ligados à coisa, não à posição:** o botão de entrega guarda o pedido; se ele já saiu, o toque não faz nada.
- **Relógio atrasado:** o próximo pedido nunca fica a mais de um intervalo de agora, e a filial recomeça a conta.
  - Adiantar o relógio continua possível (é o limite de qualquer jogo sem servidor). Na Fase 6, a hora vem do servidor.
- **Leitura segura do save:** `SafeValue` (`core/save/safe_value.gd`); valor de tipo errado vira o padrão, sem erro de script.
- **Satisfação e loja:** o HUD esconde o quadro enquanto a loja está aberta (a barra avisa por `shop_toggled`).
- **Ferramentas de QA:**
  - `tools/perf_check.gd` mede o desempenho com o café cheio;
  - o executor de testes aceita um filtro (`-- journey`) para rodar só alguns arquivos.

---

## DT-075 — Balanceamento: ritmo de níveis e pedidos impossíveis

**Problema:**
- O PO pediu um balanceamento "nível médio": o jogador precisa se prender ao jogo, sem passar raiva e sem conseguir tudo fácil demais.
- Medição com um robô que joga como um jogador médio (`tools/balance_report.gd`, 6 a 10 horas de jogo ativo com os dados reais):
  - **subia de nível rápido demais:** nível 10 em 25 minutos, nível 15 em 1 h 18 e nível 24 em 5 h 30;
  - **clientes irritados sem culpa do jogador:** 40% dos clientes pediam do cardápio inteiro, inclusive pratos de 15 minutos a 12 horas, e a paciência dura uns 90 segundos.
- Quase 80% do XP vinha dos clientes (3 por cliente, e chegam mais de mil por hora nos níveis médios).

**Decisão:**
- **Pedidos do cardápio só de pratos que dá tempo de fazer** (`menu_max_cook_time`, 60 segundos):
  - prato demorado só sai se já estiver no balcão;
  - se nada couber no tempo, sai o mais rápido.
- **XP por cliente de 3 para 2.** O XP passa a vir mais de cozinhar, como no Café Mania.
- **Curva de níveis nova** (`data/progression/levels.tres`):
  - os níveis 2 a 5 continuam rápidos, para prender quem começa;
  - a partir do 6 a curva fica cerca de 2 vezes mais longa;
  - o nível 30 pede 95.200 de XP.
  - **Quem já jogava não perde nível:** o save vai para a versão 24, e o XP é convertido para a curva nova mantendo o nível e a fração do caminho até o próximo.
- **Preços alinhados:**
  - os 5 fogões novos das coleções seguem a mesma régua de preço por efeito dos antigos;
  - a coroa e o dólmã dourado do avatar (nível 20) ficam como itens de prestígio, com cerca de 1 hora de ouro de jogo ativo.
- **O resto ficou como estava**, porque os números já fecham:
  - ouro por hora, recompensas e monetização;
  - a filial, as entregas, os vizinhos, o chão sujo e o terraço.
- Os números e as contas estão em `docs/economy.md` ("Balanceamento de 23/10").

---

## DT-074 — Vizinhos simulados

**Problema:**
- O relatório propõe vizinhos (visitar o café de amigos, ajudar, mandar presentes), mas isso precisa do servidor da Fase 6.
- Até lá, ele sugere simular "vizinhos" com cafés de personagens do jogo, para visitar e ganhar pequenas recompensas (proposta 3.9).

**Decisão:**
- **7 vizinhos** (`NeighborDefinition`, em `data/neighbors`): Ana, Beto, Duda, Caio, Lia, Rafa e Vó Cida.
  - São os personagens da faixa de vizinhos do desenho do HUD.
  - Cada um tem um café com nome, um nível e uma ajuda própria (limpar as mesas, temperar os pratos, lavar a louça...).
- **Visitar e ajudar:**
  - uma vez por dia (pelo dia do relógio do jogador) por vizinho;
  - dá ouro (40 mais 4 por nível do café dele) e 10 de XP;
  - o aviso conta o que o jogador fez e onde.
- **Amizade:** cada visita soma um coração, até 5; cada coração aumenta o ouro da visita em 10%.
- **Na tela:** aba **Vizinhos** na janela da Cidade, com um cartão por vizinho (retrato, nível, amizade e o botão "Ajudar" ou "Visitado hoje").
- **Configuração e save:**
  - os números ficam em `data/config/neighbors.tres` (`NeighborsConfig`);
  - o save guarda o dia da última visita e a amizade de cada vizinho (versão 23).
- **Com o servidor (Fase 6):** os vizinhos simulados podem ficar junto dos amigos de verdade.
- **Com isso, o item 10 do relatório está completo** (o 2º andar ficou planejado, DT-073).

---

## DT-073 — 2º andar: planejado, ainda não feito

**Problema:**
- O relatório propõe um 2º andar: mais um piso de café, por cima do térreo (proposta 3.18).
- Hoje tudo parte de **um** grid por café: a navegação, o desenho das paredes e da mureta, a profundidade dos móveis, as expansões, o terraço, o chão sujo e o save.

**Decisão:**
- **Não fazer agora.** O item fica planejado e documentado; as outras partes do item 10 seguem.
- **Por quê:**
  - um segundo andar mexe em quase todos os sistemas de uma vez;
  - um erro nele pode quebrar saves e o atendimento de quem já joga;
  - pede uma etapa só para ele, com mais tempo de teste.
- **Como seria (para quando o PO pedir):**
  1. **Regra:** `CafeSimulation` passa a ter uma lista de andares, cada um com o seu `CafeLayout` e a sua navegação. A cozinha, os balcões e os garçons continuam no térreo.
  2. **Escada:** um móvel novo (2x1) que liga os andares. Os clientes que não acham cadeira no térreo sobem por ela, e os garçons levam os pratos.
  3. **Tela:** um botão "Térreo / 1º andar" troca o andar que aparece. O de baixo fica escurecido atrás, como num corte.
  4. **Save:** `layout` vira `floors` (lista), com migração que põe o café de hoje como o térreo.
  5. **Liberar:** compra no nível 20, como uma expansão grande.
  6. **Testes:** navegação entre andares, garçom subindo, save com dois andares e migração.

---

## DT-072 — Filial na praia (versão simplificada)

**Problema:**
- O relatório propõe uma filial na praia: um segundo café num mapa diferente, liberado por missões, com receitas próprias (proposta 3.18).
- Um segundo café jogável exigiria outra simulação, outro mapa e outro save, quase um jogo novo.

**Decisão:**
- **Versão simplificada:** a filial é um segundo café que **trabalha sozinho**.
- **Abrir:** a partir do nível 15, por 8.000 de ouro, uma vez só.
- **Rendimento:**
  - aberta, ela junta ouro por hora, também com o jogo fechado;
  - o ouro fica guardado até um limite de horas;
  - coletar dá o ouro e um pouco de XP (5 a cada 100 de ouro).
- **Níveis:** 4, cada um com rendimento, limite e um **prato da praia** a mais no cardápio da filial:

  | Nível | Ouro por hora | Guarda até | Prato novo | Para chegar |
  |---|---|---|---|---|
  | 1 | 240 | 6 h | Açaí na tigela | abrir: 8.000 |
  | 2 | 420 | 8 h | Peixe frito | 12.000 |
  | 3 | 660 | 10 h | Picolé de frutas | 25.000 |
  | 4 | 960 | 12 h | Água de coco | 45.000 |

  - Melhorar coleta antes o ouro guardado, para não mudar de rendimento no meio da conta.
- **Na tela:**
  - novo botão **Cidade** na faixa de baixo abre a janela "Pela cidade", com a ilustração do quiosque na praia;
  - abrir e melhorar pedem confirmação ali mesmo, com Cancelar já selecionado;
  - a faixa de baixo ficou com botões um pouco mais estreitos para caberem os 9 ícones.
- **Configuração e save:**
  - os números ficam em `data/config/branch.tres` (`BranchConfig`);
  - o save guarda a filial (versão 22).
- **Fica para depois:** jogar dentro da filial, com mapa e clientes próprios.

---

## DT-071 — Delivery: o Balcão de Entregas

**Problema:**
- O relatório propõe um balcão de entregas que manda porções prontas para clientes em casa, em troca de ouro (proposta 3.18).

**Decisão:**
- **Balcão de Entregas:**
  - um móvel novo, na aba **Cozinha**;
  - nível 8, 1.500 de ouro, só 1 por café;
  - arte própria: balcão laranja com caixas, bolsa térmica e a plaquinha da motinho.
- **Pedidos** (`DeliveryBoard`):
  - com o balcão no café, chegam até **3 pedidos**;
  - o primeiro chega na hora, e depois chega **um a cada 30 minutos**, também com o jogo fechado;
  - com o quadro cheio, o próximo chega 30 minutos depois de uma entrega;
  - cada pedido pede de 3 a 8 porções de uma receita já liberada, dos fogões comuns e fora do cardápio noturno.
- **Mandar:**
  - escolhido o Balcão de Entregas, a barra mostra **um botão por pedido**;
  - o botão fica aceso quando há porções suficientes nos balcões;
  - mandar tira as porções dos balcões e paga **50% a mais** que no salão, mais 2 de XP por porção;
  - o ouro sobe do balcão, e um aviso confirma a entrega.
- **Configuração e save:**
  - os números ficam em `data/config/delivery.tres` (`DeliveryConfig`);
  - o save guarda os pedidos e o horário do próximo (versão 21).

---

## DT-070 — Avatar do chef

**Problema:**
- O relatório propõe o avatar do chef, com roupa, cabelo e chapéu comprados com ouro (proposta 3.9).

**Decisão:**
- **Peças:** 21 peças (`AvatarPartDefinition`, em `data/avatar`), em 4 partes do corpo:
  - **4 tons de pele**, todos grátis;
  - **6 cabelos**, de 0 a 800 de ouro;
  - **5 chapéus**: toque, toque alto, bandana, boina e coroa (nível 20);
  - **6 dólmãs**: branco, vermelho, azul, preto, rosa e dourado (nível 20).
- **Regras:**
  - cada parte tem uma peça inicial, grátis e já vestida;
  - peça grátis ou já comprada veste na hora;
  - peça nova se compra uma vez (nível e ouro), e depois trocar é grátis.
- **Retrato em camadas:**
  - roupa embaixo, a cabeça (pele e cabelo juntos, 24 combinações) no meio e o chapéu em cima;
  - as camadas se encaixam pela âncora de cada uma, mesmo depois de a arte ser recortada.
- **Janela "Avatar do Chef":**
  - abre pelo botão **Chef** da faixa de baixo;
  - tem abas Pele, Cabelo, Chapéu e Roupa;
  - tocar numa peça nova a **prova no retrato**, e a compra pede confirmação ali mesmo, com Cancelar já selecionado.
- **Save:**
  - guarda as peças compradas e as vestidas (versão 20);
  - peça vestida que não existe, não foi comprada ou é de outra parte do corpo volta para a inicial.
- **Com isso, o item 9 do relatório está completo.**

---

## DT-069 — Terraço ao ar livre (versão simplificada)

**Problema:**
- O relatório propõe um pátio ou terraço na calçada: uma expansão para fora, com mesas ao ar livre e entrada própria (proposta 3.8).
- Uma área fora do grid exigiria refazer a navegação, o desenho e as expansões.

**Decisão:**
- **Versão simplificada:** o terraço transforma a **fileira da frente** do salão (ao longo da borda de baixo) num terraço ao ar livre.
  - O piso vira **deque de madeira**, onde o jogador não pintou outro piso.
  - A mureta dessa borda vira **cerca de jardim** com floreiras.
  - O lado da porta continua com a mureta.
- **Compra:**
  - na aba **Pisos** da loja, coleção Clássico;
  - 3.000 de ouro, nível 10, uma vez só;
  - pede confirmação, com Cancelar já selecionado;
  - soma 15 de beleza.
- **Efeito:**
  - **de dia**, quem senta numa cadeira do terraço paga **25% a mais**;
  - à noite, paga o normal.
- **Expansão:** o terraço acompanha a fileira da frente quando o café cresce.
- **Configuração e save:**
  - os números ficam em `data/config/terrace.tres` (`TerraceConfig`);
  - o estilo guarda `"terrace"`, sem mudar a versão;
  - saves antigos começam sem terraço.
- **Fica para depois:** a área de fora do grid e a entrada própria.

---

## DT-068 — Chão sujo

**Problema:**
- O relatório propõe chão sujo de vez em quando: um toque limpa e dá um pouco de ouro e XP, e um chão limpo segura a popularidade (proposta 3.8).

**Decisão:**
- **Quem suja:** quem termina de comer tem 20% de chance de deixar uma **mancha de café** num piso livre do lado da cadeira.
- **Limites:**
  - no máximo 5 manchas ao mesmo tempo;
  - nunca na entrada;
  - móvel posto em cima cobre a mancha.
- **Limpar:**
  - um toque na mancha limpa;
  - dá 5 de ouro e 2 de XP, com o ouro subindo e o brilho de moedas;
  - a primeira mancha da sessão vem com um aviso explicando.
- **Popularidade:**
  - com o café aberto e o chão sujo, a cada 60 segundos a popularidade cai 0,5 por mancha;
  - chão limpo não perde nada, e café fechado também não.
- **Configuração:** os números ficam em `data/config/dirt.tres` (`DirtConfig`).
- **Save:** guarda as manchas (versão 19); saves antigos começam com o chão limpo.
- **Arte:** 3 variações de poça de café com respingos e migalhas, desenhadas no piso.

---

## DT-067 — Portas por coleção e coleções completas

**Problema:**
- O relatório propõe a porta como item da loja, com modelos por coleção, e coleções completas, cada uma com fogão, balcão, porta e janela próprios (proposta 3.8).
- Faltavam 5 fogões, 5 balcões e 12 janelas, e a porta era fixa.

**Decisão:**
- **Porta:** `DoorDefinition` em `data/doors`, uma por coleção (13 ao todo):
  - a **Porta Clássica** é a inicial e grátis;
  - as outras custam de 450 a 700 de ouro, liberam do nível 3 ao 7 e somam 6 de beleza;
  - comprada uma vez, trocar para ela é grátis e na hora;
  - comprar pede confirmação, com Cancelar já selecionado.
- **Onde fica:**
  - na loja, na aba **Paredes**, filtrável por coleção;
  - a fachada desenha a porta escolhida, aberta ou com a plaquinha FECHADO;
  - cada modelo pinta o batente e o toldo com as cores da coleção.
- **Save:**
  - o estilo guarda a porta em `"door"`, sem mudar a versão;
  - um save sem porta, ou com uma que não existe ou não foi comprada, volta para a clássica.
- **Coleções completas:**
  - **5 fogões novos**, com perfis leves:
    - Fliperama (anos 80): -15% de tempo;
    - Discoteca (balada): +30% de XP;
    - Verde e Amarelo (brasileiro): +15% de porções;
    - a Lenha (country): +10% de porções;
    - Talavera (mexicano): -10% de tempo.
  - **5 balcões novos:** Groovy, Fliperama, Verde e Amarelo, Bistrô e Bambu.
  - **12 janelas novas:** cada coleção tem pelo menos uma janela que deixa a luz entrar.
  - Um teste confere que toda coleção tem fogão, balcão, porta e janela à venda.

---

## DT-066 — Atrações e palco

**Problema:**
- O relatório propõe atrações em que o cliente brinca e deixa ouro, e um palco com shows que aceleram a chegada de clientes (propostas 3.7 e 3.16).

**Decisão:**
- **4 atrações**, com `attraction_gold`, `attraction_capacity` e `attraction_time` em `FurnitureDefinition`:
  - a jukebox e o fliperama, que já existiam;
  - a **Máquina de Garra** (nível 10, 1.800) e o **Jogo de Argolas** (nível 12, 2.400), novos.
- **Como funciona:**
  - quem pagou vai, com 35% de chance (`attraction_visit_chance`), brincar numa atração com lugar, livre e alcançável;
  - ele libera a cadeira, anda até a atração, brinca uns segundos, deixa o ouro e vai embora feliz;
  - o ouro fica guardado na atração (`Attractions`), até a capacidade dela;
  - com ouro, a atração mostra uma moeda, e o toque coleta;
  - se a atração sai do café, quem ia brincar vai embora sem reclamar.
- **Palco** (2x2, nível 15, 5.000, só 1 por café), com os tempos em `data/config/stage.tres`:
  - a cada 10 minutos de café aberto, começa um **show** de 2 minutos;
  - durante o show, os clientes chegam duas vezes mais rápido;
  - as notas musicais sobem do palco, e avisos marcam o começo e o fim;
  - com o café fechado, não tem show.
- **O save guarda** o ouro das atrações (versão 18). O tempo até o show recomeça ao abrir o jogo.
- **Com isso, o item 8 do relatório está completo.**

---

## DT-065 — Plantação e frozen yogurt

**Problema:**
- O relatório propõe um pequeno ciclo de produção como no original (proposta 3.14).
- Árvores frutíferas dão frutas com o tempo, e uma máquina de frozen yogurt usa essas frutas para servir sobremesa na hora.

**Decisão:**
- **3 pés de fruta** (enfeites de 1 piso, nível 7), com `fruit`, `fruit_grow_time` e `fruit_yield` em `FurnitureDefinition`:

  | Pé | Preço | Amadurece em | Frutas por colheita |
  |---|---|---|---|
  | Morango | 600 | 10 min | 3 |
  | Manga | 900 | 20 min | 4 |
  | Mirtilo | 1.200 | 30 min | 5 |

- **Amadurecer pelo relógio** (`Orchard`), inclusive com o jogo fechado.
  - O pé novo começa a crescer ao ser posto.
  - Maduro, mostra a fruta num selo; o toque colhe e começa a próxima fornada.
- **Frutas** (`data/fruits`) vão para um estoque. A barra do pé diz quanto falta para amadurecer.
- **Máquina de Frozen Yogurt** (nível 7, 1.500): 3 sabores, como as bebidas (o cliente pede e o jogador toca nele).
  - O frozen gasta 1 fruta e nenhuma energia (`fruit` e `fruit_cost` em `DrinkDefinition`).
  - Só entra no cardápio com a fruta no estoque.
  - A barra da máquina mostra o estoque de frutas.
- **O save guarda** os pés crescendo e as frutas (versão 17).

---

## DT-064 — Noite no café

**Problema:**
- O relatório propõe que, à noite (pelo relógio do jogo), o café escureça, as luzes acendam e a cidade mude (proposta 3.12).
- Propõe também um fogão especial com um cardápio noturno, de pratos que só saem à noite e rendem mais.

**Decisão:**
- **Horário** (`data/config/night.tres`, `NightConfig`): noite das 19h às 6h, no horário do jogador, com 1 hora de anoitecer e de amanhecer.
- **Visual:**
  - o salão, a rua e a cidade escurecem com um tom azul-noite (`scenes/fx/night_tint.gd`, um `CanvasModulate`);
  - o HUD fica de fora;
  - as luminárias têm `light_radius` em `FurnitureDefinition` e acendem com uma luz quente (`PointLight2D`), mais forte quanto mais escuro;
  - acendem as luminárias de chão, Edison e de Paris, a lâmpada de lava, o neon, a lanterna de papel, o globo de discoteca, a jukebox e o próprio fogão da noite.
- **Fogão Lua Cheia** (nível 9, 2.500): rende 25% mais porções e libera o cardápio noturno, na aba **Noite** do livro.
  - Os 4 pratos são Petit Gâteau, Caldo Verde, Risoto de Cogumelos e Fondue (`night_only` em `RecipeDefinition`).
  - Eles só começam a cozinhar à noite; o que começou de madrugada termina de dia.
  - Os clientes só pedem esses pratos à noite.
  - De dia, o livro mostra os pratos apagados, com "Só à noite".
  - Os pratos passam no teste de equilíbrio. O "rende mais" vem das porções a mais do fogão, e não de preço fora da curva.
- **Avisos** ao anoitecer e ao amanhecer.
- **Save:** nada novo. A noite sai do relógio.

---

## DT-063 — Evento de Halloween, com prazo e historinha

**Problema:**
- O relatório propõe eventos de 1 a 2 semanas com historinha, missões com prazo e prêmio final (proposta 3.17).
- Propõe também o fogão de evento que sobe de nível com as missões (proposta 3.10).

**Decisão:**
- **Evento** (`EventDefinition` em `data/events`): volta todo ano nas mesmas datas.
  - A historinha é `Array[String]`: com `PackedStringArray`, ela chegava vazia no jogo exportado (a conferência do exe pegou).
  - O Halloween vale de 20/10 a 3/11.
  - Aceita eventos que viram o ano, como Natal e Réveillon.
- **Historinha:** a Bruxa Morgana conta, em 4 quadros com o retrato dela, na primeira vez de cada edição.
- **5 missões próprias** (`data/events/halloween`): cozinhar, servir, deixar satisfeitos, ganhar ouro e pratos demorados.
  - Cada edição recomeça do zero; as metas e o ouro acompanham o nível.
- **Prêmio que sobe de nível:** o **Caldeirão da Bruxa**, um fogão que não se compra com ouro.
  - Chega na 1ª missão, sobe para o nível 2 na 3ª e para o 3 na 5ª.
  - Cada nível corta mais o tempo de preparo: 20%, 40% e 60% (`stove_level_cuts`), somando com o troféu até o limite de 80%.
  - O nível fica para sempre, mesmo depois do evento.
- **Prêmio final:** completar tudo dá a **Abóbora Gigante**.
- **Na tela:**
  - um medalhão de abóbora no HUD, só durante o evento, com os dias que faltam;
  - tocar nele abre a janela: a historinha ou, depois, o prazo, as missões e os prêmios;
  - avisos no começo, a cada missão e a cada nível do caldeirão.
- **Cuidados do relatório:**
  - missões possíveis sem pagar;
  - o prazo é o anunciado;
  - o prêmio não depende de sorte.
- **O save guarda** o quadro de missões, os níveis do caldeirão, a historinha vista e o prêmio final (versão 16).
- **Com isso, o item 6 do relatório está completo.**

---

## DT-062 — Loja de troca de cupons

**Problema:** os cupons do crítico (DT-061) precisavam de uso (proposta 3.15 do relatório).

**Decisão:**
- **Aba Cupons na loja**, com itens exclusivos que não se compram com ouro (`coupon_price` e `coupon_season` em `FurnitureDefinition`):
  - temporada 1: Estátua do Crítico (12 cupons) e Fonte de Chocolate (20);
  - temporada 2: Árvore de Cupcakes (15) e Carrinho de Pipoca (25).
- **As temporadas giram a cada 2 semanas** (`shop_seasons` e `weeks_per_season` em `critic.tres`). A barra diz quantos cupons você tem e quando chegam itens novos.
- **Trocar gasta cupons, e não ouro.** O item guardado volta de graça, mesmo fora da temporada.
- **Testes:** 581 passaram, a cena principal subiu sem erros, e os 11 defeitos inseridos de propósito foram pegos.

---

## DT-061 — Crítico gastronômico e cupons

**Problema:**
- O relatório propõe um crítico que aparece de vez em quando, com tema por semana, e dá cupons quando bem servido (propostas 3.5 e 3.15).
- Os cupons são trocados na loja de troca (próxima etapa).

**Decisão:**
- **Quando vem** (`data/config/critic.tres`, `CriticConfig`):
  - uma vez por dia, a partir do nível 5, depois de 90 segundos de café aberto (fechado, não vem);
  - se não há cadeira, espera vagar uma.
- **Como é:** um cliente com o selo do crítico ao lado da cabeça. Ele é exigente: tem 80% da paciência do cliente comum e não pede bebida.
- **Tema da semana:** pede um prato da aba do livro da semana (Básico, Brasil, Doces e Mundo, em rodízio), entre os que o café sabe fazer. O aviso da chegada diz o tema.
- **Servido rápido** (com pelo menos metade da paciência sobrando): deixa uma **estrela** pulsando na mesa.
  - Tocar na estrela dá ouro e XP, que crescem com o nível, e **cupons**: de 1 a 5, mais com o café mais popular.
- **Servido devagar:** paga, mas sem estrela. **Sem ser servido:** vai embora e só volta outro dia.
- **Cupons:**
  - moeda nova na carteira (`Wallet.COUPONS`);
  - contador no HUD, embaixo do ouro ou da energia, que aparece quando o jogador tem algum.
- **O save guarda** o dia da visita e a estrela que espera o toque (versão 15).
- **Arte nova:** o ícone do cupom e o selo do crítico (`tools/art_direction/v3/critic3.py`).

---

## DT-060 — Multifogão Trem em 3 partes

**Problema:**
- No Café Mania, multifogões em 3 partes formavam um conjunto: completo, cozinhava mais e dava um enfeite bônus (proposta 3.10 do relatório).

**Decisão:**
- **3 fogões de 1 piso**, vendidos na aba Cozinha (nível 14, 2.500 de Café Ouro cada):
  - Trem: Locomotiva;
  - Trem: Vagão;
  - Trem: Vagão-Restaurante.
  - Cada um funciona sozinho como um fogão comum.
- **O conjunto** (`data/stove_sets/train.tres`, `StoveSetDefinition`): as peças lado a lado, em linha reta e na ordem.
  - Pode ser em fila ou em coluna, para qualquer lado.
  - Em L, separadas ou fora de ordem não vale.
- **Completo:** cada peça rende o dobro de porções (`servings_multiplier`). Soma com o perfil e com o sal.
- **Prêmio:** a primeira vez que o trem fica completo, o **Relógio da Estação** vai para o inventário, com um aviso.
  - É uma vez só, mesmo desmontando e montando de novo.
  - O relógio não se compra com ouro (campo novo `sold_for_gold` em `FurnitureDefinition`) e aparece na Loja como guardado.
- **Na tela:**
  - a dica da peça na loja explica o conjunto;
  - o fogão diz quantas peças já estão no café ou, completo, que rende o dobro.
- **O save guarda** os conjuntos que já deram prêmio (versão 14).
- **O fogão de evento com níveis** fica para o evento de Halloween (item 6).
- **Com isso, o item 5 do relatório está completo.**

---

## DT-059 — Fogão Japonês com receitas próprias

**Problema:**
- No Café Mania, fogões temáticos liberavam receitas próprias (proposta 3.10 do relatório).
- O Fogão Azul e Dourado, da coleção japonesa, não tinha função.

**Decisão:**
- **O Fogão Azul e Dourado virou o Fogão Japonês** (nível 11, 3.000 de Café Ouro).
- **4 receitas que só saem nele**, numa aba nova do livro, **Japão**:
  - Dango: 4 minutos;
  - Sopa de Missô: 10 minutos;
  - Yakissoba: 25 minutos;
  - Tempurá: 50 minutos.
  - Elas passam no mesmo teste de equilíbrio das outras.
  - Desenhos de prato e de panela em `dishes3.py`.
- **Campo novo `stove` em `RecipeDefinition`:** o id do fogão em que a receita sai (vazio = qualquer fogão).
- **No fogão comum,** a aba Japão mostra os pratos apagados, com "Só no Fogão Japonês".
- **No Fogão Japonês,** as receitas comuns também saem.
- **Os clientes só pedem** esses pratos quando o café tem o Fogão Japonês (`CafeSimulation.order_menu`).
  - As metas de "pratos diferentes" também só contam os pratos que o café sabe fazer.
- **A foto de vitrine** ganhou a opção `japones`: o livro na aba Japão, aberto no Fogão Japonês.

---

## DT-058 — Fogões com perfil

**Problema:**
- Os 8 modelos de fogão eram só cores diferentes (proposta 3.10 do relatório; no lugar dos "rápido e turbo" da 3.6).
- No Café Mania, cada fogão especial tinha um perfil: mais rápido, tempo fixo, mais porções ou mais XP, e alguns eram só 1 por café.

**Decisão:**
- **Campos novos em `FurnitureDefinition`:** `stove_time_cut`, `stove_max_time`, `stove_servings_bonus`, `stove_xp_bonus` e `max_per_cafe`.
  - Só fogões podem ter perfil (protegido pela validação).
- **Perfis:**

  | Fogão | Perfil | Nível e preço |
  |---|---|---|
  | Retrô Menta | 10% mais rápido | 3, 300 |
  | Retrô Creme | +15% de porções (pelo menos 1 a mais) | 3, 320 |
  | Amarelo Canário | +25% de XP | 4, 340 |
  | Inox Industrial | 25% mais rápido | 5, 900 |
  | Cobre | qualquer prato pronto em até 1 hora, só 1 por café | 10, 3.000 |
  | Preto e Dourado | qualquer prato pronto em até 30 minutos, só 1 por café | 16, 7.000 |

  - O Azul e Dourado vira o Fogão Japonês na próxima etapa.
- **Somando com o troféu:** os cortes de tempo do fogão e do troféu se somam, até no máximo 80% (`max_speedup` em `service.tres`).
  - O tempo máximo vale antes do corte.
  - O tempo para estragar continua o da receita.
- **Porções:** as do perfil somam com as do Sal da Fartura.
  - O número que sobe ao tirar o prato passou a mostrar as porções e o XP de verdade, com os bônus.
- **Limite por café:** com o máximo na cafeteria, o cartão da loja diz "Só 1 por café" e fica apagado. Guardado no inventário, abre a vaga.
- **Na tela:** a dica de cada fogão na loja diz o perfil, e o fogão livre também.
- **O save guarda** as porções a mais do perfil em cada prato no fogão. Não mudou de versão: o campo novo é opcional.

---

## DT-057 — Troféus que aceleram os fogões em volta

**Problema:**
- As fotos do Café Mania mostraram troféus que aceleram os fogões em volta deles e se gastam com o uso (proposta 3.11 do relatório).
- É a mecânica que mais combina com o nosso quadriculado: o jogador passa a planejar a cozinha em volta dos troféus.

**Decisão:**
- **3 troféus**, móveis de 1 piso vendidos na aba **Cozinha** da loja:

  | Troféu | Nível | Preço | Fogões em volta | Pratos até se gastar | Renovar |
  |---|---|---|---|---|---|
  | Bronze | 6 | 1.200 | 25% mais rápidos | 30 | 400 |
  | Prata | 12 | 3.500 | 40% mais rápidos | 40 | 1.000 |
  | Ouro | 20 | 8.000 | 65% mais rápidos | 50 | 2.200 |

  - Os números ficam nos .tres dos móveis (`stove_speed_bonus`, `trophy_dishes` e `renew_price` em `FurnitureDefinition`).
- **Alcance:** as 8 casas em volta, inclusive as diagonais. Com dois troféus perto, vale o mais forte (eles não somam).
- **Tempo de cada prato:** decidido ao começar e guardado no fogão.
  - Mover ou gastar o troféu depois não muda o prato que já cozinha.
  - O tempo para estragar continua o da receita.
- **Gastar e renovar** (`StoveTrophies`):
  - cada prato acelerado gasta uma carga;
  - sem cargas, o troféu fica apagado, avisa e para de acelerar;
  - renovar devolve as cargas cheias por Café Ouro, com confirmação.
- **Guardar não renova:** o troféu guardado lembra as cargas que tinha e volta com elas. Vendido, as cargas somem.
- **Na tela:**
  - escolhido ou sendo posicionado, o troféu mostra no chão, em dourado, as casas que acelera;
  - a barra diz quanto ele acelera e quantos pratos ainda acelera;
  - o livro de receitas mostra o tempo já acelerado, e o fogão diz "troféu: 25% mais rápido".
- **O save guarda** as cargas, os troféus guardados e o tempo de cada prato no fogão (versão 13).
- **Com isso, o pacote do relatório (seção 4, item 4) está completo.** O próximo seria o item 5: fogões com perfil, de evento e em partes (3.10).

---

## DT-056 — Temperos

**Problema:**
- No Café Mania, a prateleira de temperos dava mais porções, encurtava o preparo e salvava o prato estragado (proposta 3.4 do relatório).
- Com a comida que estraga (DT-055), faltava um jeito de salvar o prato esquecido.

**Decisão:**
- **5 temperos** em `data/spices` (`SpiceDefinition`), cada um com efeito, preço em Café Ouro e nível para comprar:
  - **Sal da Fartura:** +20% de porções no prato que cozinha (pelo menos 1 a mais), um por prato;
  - **Pimenta-Relâmpago:** 1 hora a menos de preparo;
  - **Páprica-Foguete:** 6 horas a menos de preparo;
  - **Tempero Instantâneo:** o prato fica pronto na hora;
  - **Ervas Salva-Prato:** o prato estragado volta a ficar pronto.
- **Nunca passa do ponto:** adiantar o preparo deixa o prato no máximo pronto agora, com o tempo inteiro para estragar.
- **Onde se ganha:**
  - no presente diário (dias 2, 4 e 6);
  - em 5 missões semanais (o prêmio aparece na janela e no aviso);
  - comprando com Café Ouro direto no fogão.
- **No fogão:** escolhido o fogão, os temperos que servem aparecem em cartões, cada um com quantos você tem, o preço ou o nível de venda.
  - Usar um da prateleira é na hora.
  - Comprar pede confirmação, com Cancelar já escolhido, e só cobra se o tempero servir para o fogão.
  - O efeito sobe do fogão com um brilho.
- **Mais porções que um balcão:** se o prato com sal passa da capacidade, ele se reparte entre os balcões que têm a mesma receita e os vazios.
- **O save guarda** a prateleira e o tempero no fogão (versão 12). Saves antigos começam sem temperos.
- **Correção junto:** o executor de testes espera 0,3 s antes de fechar, para o áudio soltar o último som (sumiu o aviso de vazamento no fim da rodada).

---

## DT-055 — Comida que estraga no fogão

**Problema:**
- Um prato pronto podia ficar no fogão para sempre, sem custo nenhum.
- No Café Mania, a comida esquecida estragava. Isso dava um motivo para voltar ao jogo (proposta 3.4 do relatório).

**Decisão:**
- **Quanto aguenta:** o prato pronto aguenta no fogão o dobro do tempo de preparo, e nunca menos de 10 minutos.
  - Os números ficam em `data/config/service.tres` (`spoil_factor` e `min_spoil_time`).
  - Exemplos: o Café aguenta 10 minutos, a Feijoada 2 horas e a Lagosta 24 horas.
  - Pratos de 4 horas ou mais aguentam uma noite de sono (protegido por teste): quem dorme não é punido.
- **Pelo relógio**, como o preparo: estraga também com o jogo fechado, e a pausa segura.
  - O save não muda, porque o estado sai do horário de início do preparo.
- **O prato estragado:**
  - aparece com a panela esverdeada, fumaça verde e o selo "Estragou";
  - não vai para o balcão, o garçom não busca e não conta como prato a caminho;
  - deixa o fogão ocupado até o jogador tocar nele e escolher **Jogar fora** (botão com a lixeira), sem devolver os ingredientes.
- **Avisos:**
  - quando estraga com o jogo aberto, toca o som de erro e aparece uma mensagem;
  - as boas-vindas contam os pratos que estragaram com o jogo fechado, sem um aviso para cada;
  - o fogão com prato pronto diz quanto falta para estragar.
- **Correção junto:** os efeitos sonoros agora são soltos ao sair da cena, como já acontecia com a música.
  - Um som tocado no último quadro ficava preso na memória e gerava aviso no fim dos testes.
- **Próximas etapas:**
  - temperos, inclusive um que recupera o prato estragado;
  - troféus que aceleram os fogões em volta.

---

## DT-054 — Receitas do nível 18 ao 30

**Problema:**
- Depois do DT-053, o jogo tinha receitas novas só até o nível 17, mas a tabela de níveis vai até o 30.
- Do 18 em diante, subir de nível não liberava nenhum prato novo.

**Decisão:**
- **13 receitas novas**, uma a cada nível do 18 ao 30, de 6 minutos a 12 horas:
  - Básico: Waffles com Morango e Ovos Benedict;
  - Brasil: Açaí na Tigela, Bobó de Camarão, Picanha na Tábua e Churrasco Misto;
  - Doces: Pudim de Leite, Torta de Limão e Floresta Negra;
  - Mundo: Lámen, Paella, Curry com Arroz e Lagosta Grelhada.
  - Cada uma tem desenho de prato e de panela no fogão (`tools/art_direction/v3/dishes3.py`, segunda leva).
- **Tempos longos** (4, 6, 8 e 12 horas) para quem fecha o jogo e volta depois, como no Café Mania.
- **Equilíbrio:** as 31 receitas passam no mesmo teste do DT-053.
  - Entre dois pratos em que um demora pelo menos 4 vezes mais, o demorado rende mais ouro e XP por fornada.
  - O rápido rende mais ouro por minuto.
  - Nenhum prato passa de 40 porções, que é o que cabe num balcão.
- **Livro com páginas:** as abas Básico (7), Brasil (9) e Mundo (9) passaram de 6 receitas e usam as setas de página do DT-053.
- **A foto de vitrine** do livro aceita página e nível (`livro:<aba>:<página>:<nível>`).

---

## DT-053 — Livro de receitas, domínio e 12 receitas novas

**Problema:**
- O jogo tinha 6 pratos, contra uns 90 no Café Mania. Era a maior distância que sobrava no relatório (propostas 3.3 e 3.13).
- Com muitas receitas, o painel do fogão (uma fileira de cartões) não cabe mais.
- As fotos do Facebook mostraram o livro de receitas do original dividido em abas e o "domínio" de receitas com prêmios.

**Decisão:**
- **12 receitas novas**, uma a cada nível do 5 ao 17, de 2 minutos a 3 horas:
  - Básico: Panquecas com Mel e Croissant;
  - Brasil: Pastel, Feijoada, Moqueca e Escondidinho;
  - Doces: Brigadeiro e Cheesecake;
  - Mundo: Pizza, Sushi, Hambúrguer e Tacos.
  - Cada uma tem desenho de prato e de panela no fogão, no mesmo estilo das outras (`tools/art_direction/v3/dishes3.py`).
- **Equilíbrio**, protegido por teste: entre dois pratos em que um demora pelo menos 4 vezes mais,
  - o demorado rende mais ouro e mais XP por fornada (para quem fecha o jogo e volta depois);
  - o rápido rende mais ouro por minuto (para quem joga ativo).
- **Livro de receitas em abas** (`data/recipe_books`: Básico, Brasil, Doces e Mundo; cada receita diz a aba no campo `book`):
  - o fogão livre abre o livro na aba de um prato que algum cliente espera (ou na primeira);
  - cada aba mostra uma bolinha com quantos esperam pratos dela;
  - cada fogão lembra a aba escolhida;
  - abas com mais de 6 receitas ganham setas de página (pronto para as próximas receitas).
- **Domínio** (`RecipeMastery`, metas em `data/config/mastery.tres`):
  - cada prato tirado pronto do fogão (pelo jogador ou pelo garçom) conta para a receita;
  - com 5, 20 e 60 pratos, a receita ganha uma estrela;
  - cada estrela paga na hora um prêmio: 2, 4 e 8 vezes o custo dos ingredientes em ouro, e 1, 2 e 4 vezes o XP da receita;
  - as estrelas aparecem no canto de cada cartão do livro, e a dica do cartão diz quanto falta;
  - a estrela nova avisa: "Domínio de Café: estrela 1 de 3! +12 de Café Ouro e +2 XP".
- **O save guarda o domínio** (versão 11). Saves antigos começam sem estrelas.
- **Próxima etapa:** mais 12 receitas, do nível 18 ao 30.

---

## DT-052 — Máquinas de bebida e energia

**Problema:**
- O PO lembrou que o Café Mania servia café e tinha várias máquinas.
- O relatório (proposta 3.2) e as fotos do Facebook confirmaram:
  - as máquinas de bebida gastavam energia, uma barra que recarrega sozinha;
  - o jogador servia a bebida tocando no cliente;
  - era a ação rápida entre os pratos demorados.

**Opções:**
- (A) bebida feita no fogão, como um prato rápido;
- (B) máquina que serve na hora, sem energia;
- (C) máquina que serve na hora, gastando energia, e o jogador toca no cliente para servir.

**Decisão:** C, como no original.
- **Energia** (`core/economy/energy.gd`, parâmetros em `data/config/energy.tres`):
  - começa cheia, com 10 pontos no nível 1, e ganha 1 ponto a mais a cada 2 níveis;
  - recarrega 1 ponto por minuto pelo relógio do jogo, também com o jogo fechado, e não passa do máximo (cheia, o tempo não vira crédito);
  - subir de nível enche a energia;
  - relógio do aparelho voltando não dá energia.
- **Máquinas** são móveis da categoria nova `MACHINE`, com o campo `machine` (que bebidas preparam):
  - Máquina de Café (nível 2): Café Expresso, Cappuccino e Chocolate Quente;
  - Máquina de Sucos (nível 4): Suco de Laranja, Limonada e Vitamina de Morango;
  - ficam na aba Cozinha da loja e ocupam 1 piso, sem precisar de passagem (ninguém vai até elas).
- **Bebidas** são dados (`data/drinks`, `DrinkDefinition`): máquina, energia, preço, XP e nível.
- **Pedido:**
  - com uma máquina no café, cada cliente tem 30% de chance de pedir uma bebida liberada em vez de um prato;
  - o balão dele aparece com borda verde, porque quem serve é o jogador;
  - sem máquina, o sorteio nem acontece, e o atendimento continua exatamente como antes.
- **Servir:**
  - o jogador toca no cliente (no corpo ou no balão), e a bebida sai na hora, gastando energia e dando o XP dela;
  - o cliente bebe por 3 segundos, paga o preço da bebida e sai satisfeito, ganhando popularidade como num prato;
  - sem energia, a barra de baixo explica que ela volta sozinha;
  - se a máquina sair do café (guardada ou vendida), quem esperava bebida vai embora sem tirar popularidade.
- **Na tela:**
  - o contador de energia ("7/10" e "+1 0:42") fica logo abaixo do ouro e só aparece com uma máquina no café;
  - tocar nele explica a energia.
- **O save guarda a energia** (versão 10). Saves antigos começam com ela cheia.
- **Para depois:**
  - "dominar" os sabores de cada máquina com prêmios (como nas fotos);
  - missões de bebidas;
  - a bebida aparecer na mesa de quem está bebendo.

---

## DT-051 — Placa ABERTO/FECHADO na porta

**Problema:**
- No Café Mania original, os jogadores "fechavam o café" tirando ou tampando a porta, para arrumar e cozinhar sem perder popularidade. Foi essa mesma necessidade que levou o PO a pedir a pausa.
- O relatório do Café Mania (proposta 3.1) recomendou a versão "oficial" desse truque como o próximo pacote, junto com as bebidas.

**Opções:**
- (A) fechar = pausar (já existe);
- (B) fechar mantém o jogo rodando, mas ninguém novo entra, e quem está dentro termina;
- (C) fechar manda todo mundo embora na hora.

**Decisão:** B.
- **A pausa para o tempo** e serve para mexer à vontade. **Fechar** é outra coisa: o café continua funcionando (fogões cozinham, garçons servem, clientes comem), só não entra ninguém novo.
- **Ao fechar:**
  - ninguém novo chega;
  - a fila da calçada vai embora na hora, andando pela calçada, sem tirar popularidade;
  - quem já está lá dentro é atendido normalmente e paga;
  - quem cansar de esperar com o café fechado sai sem tirar popularidade (o café avisou que estava fechando).
- **Ao abrir:** o próximo cliente chega em poucos segundos, como na abertura do jogo (`FIRST_ARRIVAL_DELAY`).
- **Onde fica:**
  - botão da porta na coluna da direita, logo abaixo da pausa (vermelho para fechar, verde para abrir), e a tecla F;
  - uma faixa vermelha "CAFÉ FECHADO" acima da barra de baixo (acima da faixa da pausa, quando as duas aparecem);
  - a plaquinha da porta passa a dizer "FECHADO", em vermelho.
- **O save guarda a placa** (versão 9). Fechou e saiu? O jogo abre com o café fechado e a faixa avisando. Saves antigos abrem com o café aberto.
- **Por que não C:** jogaria fora clientes que já estão comendo e pagando.

---

## DT-050 — Pausa sem bloqueio, balcão de 1 piso e mais fogões e balcões

**Problema:**
- Com a pausa da DT-049, o PO ainda não conseguia mexer no que estava em uso (cadeira com cliente, mesa ocupada, balcão com porção reservada) nem pôr móvel onde havia gente em pé. Ele pediu que a pausa deixe fazer **qualquer** movimento, ou então que zere os clientes.
- O balcão ocupava 2 pisos para guardar um prato só.
- Ele pediu mais modelos de fogões e balcões.

**Opções para a pausa:**
- (A) ao pausar, todos os clientes vão embora (zerar o salão);
- (B) pausado, nada bloqueia, e o jogo acerta na hora as consequências de cada mudança.

**Decisão:** B.
- É o que o PO pediu primeiro, e não joga fora os clientes que já estão comendo.
- **Pausado, sem bloqueio** (`CafeSimulation.is_in_use` e `agent_cells` ficam vazios na pausa):
  - mover, girar, guardar e vender qualquer móvel, mesmo em uso;
  - pôr móvel onde há gente em pé.
- **O que o jogo acerta a cada mudança** (`_settle_after_layout_change`):
  - cadeira que mudou de lugar leva o cliente junto (sentado ou ainda indo para ela);
  - cliente cuja cadeira saiu ou ficou sem mesa vai embora satisfeito, sem tirar popularidade; o pedido é cancelado e a porção volta ao balcão;
  - pedido que tinha porção num balcão que saiu volta a esperar outra porção;
  - garçom indo a um móvel que mudou de lugar refaz o caminho; se o móvel saiu, fica livre para outra tarefa;
  - quem ficou em pé em cima de um móvel novo vai para o piso livre mais perto.
- **Fogão aceso que muda de lugar continua cozinhando.** Fogão guardado ou vendido com comida perde a comida (a escolha é do jogador).
- **Sem a pausa, as proteções continuam iguais.** A regra de acesso (não fechar a passagem até um móvel) vale sempre.

**Balcão de 1 piso:**
- Todos os balcões passam a ocupar 1 piso, com a mesma capacidade de porções.
- Saves antigos abrem com o balcão no mesmo lugar, ocupando só o primeiro piso.

**Modelos novos:**
- fogões: Retrô Creme (anos 70), de Cobre (italiano), Azul e Dourado (japonês) e Amarelo Canário (festa);
- balcões: de Mármore (italiano), de Azulejos (mexicano), Neon (balada) e de Lanchonete (americano).
- Agora são 8 fogões e 8 balcões, todos com as mesmas medidas (a panela e a pilha de pratos caem no mesmo lugar).

---

## DT-049 — Pausa de verdade e a loja que continua aberta depois da compra

**Problema:**
- Com o café lotado, o PO não conseguia arrumar (comprar mesas, fogões e balcões) porque o movimento não parava. Ele pediu uma pausa em que o jogo inteiro fique parado e ele mexa à vontade.
- Na loja, depois de comprar e posicionar uma mesa, o jogo voltava para a faixa de ícones, e era preciso abrir a loja de novo para comprar a cadeira.

**Opções para a pausa:**
- (A) só parar a tela (personagens), deixando os fogões correrem pelo relógio;
- (B) a regra do jogo sabe que está pausada, e os fogões param junto.

**Decisão:** B.
- Com A, pausar viraria um truque: a lasanha ficaria pronta sem ninguém perder paciência.
- **Na regra** (`CafeSimulation.paused`, `Kitchen.set_paused`):
  - pausado, o tick não faz nada: ninguém chega, anda, perde paciência ou pede;
  - os fogões guardam o horário em que o jogo pausou e calculam tudo a partir dele; ao continuar, cada preparo anda o tempo da pausa para a frente;
  - um preparo começado durante a pausa só começa a contar depois;
  - salvo durante a pausa, o tempo dela não conta como cozinhado;
  - o jogo sempre abre rodando.
- **O jogador continua jogando:** comprar, mover, guardar, vender, cozinhar, levar prato ao balcão, reformar e expandir.
  - As proteções continuam (móvel em uso, personagem no caminho), só que nada se mexe.
- **Na tela:**
  - botão laranja de pausa no alto da coluna da direita, que vira o verde de continuar;
  - tecla P;
  - faixa "JOGO PAUSADO" acima da barra de baixo;
  - personagens, vapor e trânsito ficam parados; o resto (avisos, animação de surgir, câmera) continua.
- **Loja:** escolher um móvel esconde a loja só enquanto ele é posicionado. Depois de confirmar ou cancelar, ela volta na mesma aba, coleção e página. Fechar a loja continua no X.

---

## DT-048 — A cidade em volta do café (Nova York)

**Problema:** o PO achou o café "escondido, só com mato dos lados" e pediu um exterior bonito e moderno, como se fosse uma cidade (Nova York).

**Decisão:** o café fica num lote de esquina de um quarteirão de Nova York, tudo só na tela (as regras do jogo não sabem da cidade).
- **Onde fica cada coisa** (`CityPlan`, a partir do tamanho do café e da entrada, acompanhando as expansões):
  - a rua A passa na frente da entrada e a rua B no outro lado da frente, com calçadas dos dois lados e um cruzamento na esquina;
  - atrás (lados −x e −y), fileiras de prédios depois de um beco de um piso, que param antes da calçada;
  - do outro lado das ruas, um parque com árvores e bancos;
  - bem ao longe, o contorno dos arranha-céus, claro como se tivesse névoa.
- **Arte nova** (`tools/art_direction/v3/city3.py`, mesmo traço dos móveis, folha `cidade`):
  - 7 prédios: casa de pedra com escadinha (brownstone), prédio de tijolo com escada de incêndio e caixa-d'água, prédios com loja embaixo (DELI e PIZZA, com toldo), prédio azul, torre de vidro e torre art déco;
  - poste de ferro com lanterna, hidrante, árvore no canteiro com grade, banco, carrinho de cachorro-quente, lixeira, caixa de correio, vaso, bueiro com vapor e semáforo nas 3 cores;
  - táxis e carros (vermelho, branco e azul) nas 4 direções;
  - o chão de concreto.
  - Nenhuma marca de verdade: as placas são genéricas.
- **Na tela:**
  - o `ExteriorView` desenha o chão, as ruas com a linha amarela dupla, as faixas de pedestre e as de parada, as calçadas, o parque, os arranha-céus e os prédios, tudo atrás do café;
  - o `StreetView` (z 2, por cima da mureta, com y-sort próprio) põe os enfeites, os semáforos, os bueiros e os carros;
  - os enfeites ficam a pelo menos 1,2 piso do caminho da porta, dos lugares da fila e do caminho de quem desiste dela, para nunca tampar alguém que está na frente deles.
- **Trânsito** (`TrafficModel`):
  - dois sentidos em cada rua; o semáforo alterna qual rua passa (9 s de verde, 2 s de amarelo, 1,2 s com os dois fechados);
  - o carro para antes da faixa de pedestre quando o sinal da rua dele não está verde, termina de atravessar se já entrou e não encosta no da frente;
  - no fim da rua, volta pelo começo.
- **Câmera:** a folga em volta do café passou de 96 para 360 px, para dar para passear pela rua.
- **Saíram:** o gramado, a cerca de flores e os postes antigos da frente.

---

## DT-047 — Missões diárias (10) e semanais (20)

**Problema:** o PO pediu um roteiro de missões, com 10 diárias e 20 semanais criadas a partir do conteúdo do jogo.

**Opções:**
- (A) sortear algumas missões de uma lista maior a cada dia;
- (B) uma lista fixa de 10 diárias e 20 semanais, todas valendo ao mesmo tempo, com metas que crescem com o nível.

**Decisão:** B.
- É o que o PO pediu ao pé da letra, e o jogador sempre sabe o que tem para fazer.
- O roteiro completo, com metas e recompensas nos níveis 1, 10 e 30, está em [missoes.md](missoes.md).
- **Como funciona:**
  - `MissionBoard` (em `core/progression`) guarda as missões de um período;
  - as diárias recomeçam à meia-noite local e as semanais na segunda-feira à meia-noite;
  - a meta e a recompensa são calculadas no começo do período (meta + por_nível × (nível − 1), em número redondo) e ficam congeladas até o fim dele;
  - missão com nível mínimo fica com o cadeado até o período seguinte (os pratos demorados pedem o nível 3);
  - "pratos diferentes" nunca pede mais receitas do que as liberadas.
- **O que conta:**
  - os eventos que já existiam: pratos levados ao balcão, clientes servidos, vendas e compras;
  - 13 tipos novos: clientes satisfeitos (servidos antes de a paciência cair da metade), XP ganho cozinhando e servindo, pratos diferentes, presente diário, pedidos do cardápio (o que não estava no balcão), ouro em ingredientes, pisos reformados, trechos de parede pintados, itens pendurados, diárias concluídas, pratos demorados, popularidade e clientes da fila que sentaram;
  - XP de recompensa de missão não conta para "Ganhe XP" (senão uma missão alimentaria outra).
- **Recompensa:** entra sozinha quando a missão é concluída, com um aviso ("Missão diária concluída: … +40 ouro +10 XP").
  - As 10 diárias dão uns 450 de ouro no nível 1 (um terço de hora de jogo ativo) e as 20 semanais uns 4.500.
  - No nível 30, umas 2,5 vezes mais.
- **Na tela:**
  - o medalhão **MISSÕES** e o ícone **Missões** abrem a janela com as abas Diárias, Semanais e Começo (o tutorial, que some quando acaba);
  - cada missão mostra o progresso, a recompensa e o cadeado;
  - a janela diz quanto falta para as missões recomeçarem;
  - tocar no cartão do tutorial esconde o cartão, e abrir as missões mostra de novo.
- **Save versão 8:** o progresso do dia e da semana fica salvo. Aberto num dia (ou semana) que já passou, recomeça. Saves antigos começam do zero.

---

## DT-046 — Nível máximo 30

**Problema:** o PO pediu o nível máximo 30 (era 10). Do 10 em diante o jogo não tem receita nem móvel novo para liberar.

**Decisão:**
- **Curva de XP:** os níveis 1 a 10 continuam iguais (ninguém perde nível).
  - Do 11 ao 30, o XP que falta para o próximo nível cresce 10 a mais a cada nível, a mesma regra de antes.
  - O 30 pede 45.530 de XP no total: umas 15 a 20 horas de jogo ativo, mais as missões.
- **Ouro pelo nível:** do 11 em diante, cada nível dá 25 × nível de Café Ouro (275 no 11, 750 no 30), avisado junto com o "Nível N!".
  - O ouro fica em `levels.tres` (`level_up_gold`).
  - Do 2 ao 10 não dá ouro, porque esses níveis já liberam receitas e móveis.
- **O que mais libera nos níveis altos:**
  - 4 expansões novas: 14×12 (nível 10), 14×14 (13), 16×14 (16) e 16×16 (20);
  - 2 garçons a mais: o 5º no nível 12, por 8.000, e o 6º no 18, por 14.000;
  - a conquista "Mestre" (Chef Renomado no 15, Lenda do Café no 20, Rei de Nova York no 30).
- **Próximo passo sugerido:** receitas novas para os níveis 11 a 30 (cada uma precisa de desenho de prato e de panela).

---

## DT-045 — Quem senta, senta de verdade; e cada móvel desenhado em faixas na ordem certa

**Problema:** o PO mostrou duas coisas feias:
- quem senta de frente parecia em pé em cima da cadeira (as canelas tinham 12 de altura e os pés acabavam no assento);
- o garçom "entrava" no balcão: passando na frente da metade de trás de um balcão de 2 pisos, ele era desenhado atrás, e o raio-X ainda chamava atenção para isso.

**Opções para a ordem de desenho:**
- (A) corrigir só os personagens, ajustando a altura de ordenação de cada um contra os móveis próximos;
- (B) cortar o desenho de cada móvel em faixas verticais, cada uma ordenada pela borda da frente da pegada naquele trecho (a técnica padrão dos jogos isométricos).

**Decisão:** B.
- A opção A não resolve um vaso na frente da metade de trás do balcão: o balcão inteiro ainda seria ordenado pela ponta da frente.
- **As faixas:**
  - o `FurnitureView` liga o y-sort próprio, e as faixas (`FurnitureView.Slice`, filhas) entram no y-sort do salão, cada uma na sua altura;
  - cada faixa tem 32 px (um quarto do piso);
  - a altura de cada faixa é a da borda da frente da pegada no meio do trecho dela (desce 1 px a cada 2 do vértice da esquerda até o da frente e sobe do mesmo jeito até o da direita);
  - o que passa dos vértices dos lados (folhas, sombra) vai com a faixa da ponta.
- **O que fica em cima** (panela, pilha de pratos, pratos da mesa) continua no próprio nó, no vértice da frente, depois de todas as faixas.
- **Atrás de todas as faixas:** o contorno laranja de selecionado e o halo de brilho.
- **O vapor** fica num nó no vértice da frente, para sair por cima do fogão.
- **Folga:** quem passa a até um quarto de piso da borda ainda aparece na frente; antes, no meio do lado do móvel, precisava estar a meio piso.
- **Raio-X:** usa a mesma regra da pegada ("atrás" é não estar depois da borda da frente em x nem em y). Só aparece quando a pessoa está de fato atrás de um móvel alto.
- **Durante a animação de surgir** (0,38 s), as faixas acompanham a escala do móvel.

**Sentar:** o boneco é chibi e o assento (30) é mais alto que a perna dele (23).
- O pé não alcança o chão, como criança em cadeira de adulto.
- A pose nova de frente (`people3._seated_legs`): o quadril fica no assento, as coxas vão para a frente até a borda dele (com volume, luz por cima e joelho redondo) e as canelas ficam penduradas na frente do assento.
- De costas continua como era: o encosto cobre a pessoa.

**Ferramenta de foto** `tools/depth_showcase.gd`: monta o garçom na frente do balcão, um vaso na frente de outro, alguém atrás da estante e clientes sentados nas 4 direções em banqueta e cadeiras.

---

## DT-044 — Passe visual: shaders leves, "juice" por Tween e partículas por CPU, só na tela

**Problema:** o PO pediu um acabamento "AAA" (raio-X atrás dos móveis, brilho no que está selecionado e no fogão pronto, mureta que não esconde ninguém, animações de surgir e quicar, vapor e confete), sem quebrar os testes, sem mexer no loop do jogo e rodando bem em celular.

**Opções:**
- (A) efeitos espalhados dentro do desenho de cada cena;
- (B) uma pasta de efeitos (`scenes/fx`) com funções prontas e nós filhos só de efeito, que as cenas apenas ligam e desligam.

E, para rodar no Android: (C) partículas por GPU ou (D) por CPU.

**Decisão:** B e D.
- **Onde fica:**
  - `art/shaders/`: 3 shaders `canvas_item`, cada um com uma leitura de textura por pixel (renderer `mobile`);
  - `scenes/fx/fx_materials.gd`, `juice.gd` e `fx_particles.gd`: os materiais, as animações e as partículas;
  - nada em `core/`: a regra do jogo não sabe que os efeitos existem. Os efeitos só leem o estado (seleção, fogão pronto, porções no balcão, pagamento).
- **Raio-X:**
  - quem passa atrás de um móvel alto (fogão, balcão, estante; 64 px ou mais) aparece como silhueta azul, só onde o móvel cobre;
  - o personagem ganha um filho `XRay` com `clip_children`: ele desenha o formato dos móveis da frente como máscara e, dentro dela, o neto desenha o corpo com o shader de silhueta;
  - mesas e cadeiras nunca tampam, e quem está sentado nunca ganha silhueta (a mesa na frente é o normal).
- **Brilho:**
  - um filho `Halo` atrás do móvel desenha o próprio desenho um pouco maior, numa cor só, pulsando;
  - laranja para o móvel escolhido e dourado para o fogão com prato pronto;
  - a prévia da compra (fantasma) não brilha.
- **Mureta:** o shader esmaece a mureta da frente perto de quem está a até 1,6 piso da borda (também quem está saindo pela porta) e do piso escolhido (até 8 pontos, raio de 80 px, sobra 30% de opacidade).
- **Juice:**
  - móvel novo surge crescendo do chão (TRANS_BACK, EASE_OUT); ao abrir o jogo, a cafeteria já está montada, sem animação;
  - a pilha de pratos cai no tampo do balcão quando chega prato;
  - os personagens esticam ao arrancar e achatam ao frear, no máximo 4,5%;
  - a loja acende, o aviso surge crescendo e o número do ouro quica quando entra ouro.
  - As animações de interface só mudam a transparência e a escala do desenho. A área de toque não muda, então os testes de toque continuam valendo.
- **Partículas:**
  - `CPUParticles2D` (rodam em qualquer celular, sem depender da GPU);
  - vapor nas panelas (cozinhando ou com prato pronto) e nos pratos do balcão;
  - confete dourado com faíscas no pagamento, numa camada própria (`Particles`), que some sozinho;
  - a única textura é uma bolinha de gradiente (`art/fx/soft_dot.tres`). Guardada como recurso, e não em variável estática, ela não vaza memória ao fechar.
- **Toque:** todo botão de ícone tem no mínimo 48 px de área de toque (uns 9 mm num celular comum); o ícone continua do mesmo tamanho.
- **Nitidez no zoom:**
  - o padrão do projeto passou a ser `Linear Mipmap` (`rendering/textures/canvas_textures/default_texture_filter=2`), e as imagens já importavam com mipmaps;
  - todo nó novo (efeitos, partículas) já nasce suave no zoom afastado, sem precisar lembrar de configurar.
- **Ordem de desenho (y-sort):**
  - conferida e protegida por teste: o móvel ordena pelo vértice da frente da pegada (também girado) e o personagem pelos pés;
  - quem está atrás do balcão é desenhado antes, quem está na frente depois.

---

## DT-043 — Compra de Café Ouro: pacotes, taxa e pagamento só pela loja oficial

**Problema:** o PO pediu que, quando faltar ouro, o jogo ofereça pagar um valor X por Y moedas, e que eu calcule uma taxa boa.

**Opções:**
- (A) cobrança própria (cartão dentro do jogo): não é permitida pelas lojas e é um risco legal;
- (B) a cobrança da loja (Google Play Billing no Android), com o jogo entregando o ouro só depois que a loja confirma.

**Decisão:** B.
- **Pacotes em dados** (`data/coin_packs`, gerados por `tools/content/make_coin_packs.py`):

  | Pacote | Ouro | Preço | Ouro por real |
  |---|---|---|---|
  | Punhado de Ouro | 500 | R$ 4,90 | 102 |
  | Saco de Ouro | 1.200 | R$ 9,90 | 121 (+19%) |
  | Baú de Ouro | 3.300 | R$ 24,90 | 133 (+30%) |
  | Cofre de Ouro | 7.000 | R$ 49,90 | 140 (+37%) |
  | Tesouro do Café | 15.000 | R$ 99,90 | 150 (+47%) |

- **Como a taxa foi calculada:**
  - no turno de 30 minutos do robô (níveis 1 a 7), o saldo sobe uns 640 de ouro, já descontados os ingredientes: cerca de 1.300 por hora de jogo ativo;
  - o menor pacote (500) vale uns 25 minutos de jogo por R$ 4,90, a faixa comum em jogos casuais;
  - os maiores dão até 47% a mais por real, para valer a pena comprar de uma vez;
  - comparando com os preços do jogo: a 4ª expansão (1.000) fica perto do Saco, e o 4º garçom (4.000) entre o Baú e o Cofre;
  - os preços seguem os degraus da Play Store em reais.
- **Pagamento:**
  - `CoinShop` pede a compra a um `PaymentProvider` e só põe o ouro na carteira quando o provedor confirma; cancelada ou recusada, nada muda;
  - neste build (Windows e APK de teste) o provedor é o `UnavailablePaymentProvider`: a vitrine aparece, mas a compra explica que só existe na Play Store e que nada foi cobrado;
  - o provedor de verdade (o plugin de cobrança da Google para a Godot) entra quando houver a conta de desenvolvedor do PO com os produtos `cafe_ouro_*` cadastrados e a revisão jurídica da Fase 7 (menores e compras, ECA Digital).
- **Na tela:**
  - um "+" verde no contador de ouro abre a vitrine;
  - quando uma compra falha por falta de ouro, a vitrine aparece sozinha ("Faltou Café Ouro?"), no máximo uma vez por minuto e nunca por cima de outra janela.

---

## DT-042 — Paredes completas (mureta na frente, com porta) e itens de parede do jogador

**Problema:** o PO pediu as paredes da frente e dos lados, com porta, mantendo a mesma visibilidade, e itens para pôr nas paredes (janelas, portas, TV, rádio).

**Opções:**
- (A) parede alta na frente, transparente;
- (B) mureta baixa na frente, como nos jogos de cafeteria, que fecha o salão sem esconder nada;
- e, para os enfeites: (C) continuar com o ciclo fixo da arte ou (D) torná-los itens comprados e postos pelo jogador.

**Decisão:** B e D.
- **Mureta da frente:**
  - nas duas bordas da frente, no lugar da cerca, a parte de baixo da parede (44 px, o lambri) com o mesmo revestimento e acabamento branco por cima;
  - o desenho é a faixa de baixo do próprio painel da parede (polígono com textura): todo revestimento já serve, sem arte nova;
  - ela pode ser pintada trecho a trecho na reforma (`bottom` e `right`);
  - a porta fica no trecho da entrada, com batente, toldo listrado e a plaquinha "ABERTO", e acompanha a expansão.
- **Itens de parede:**
  - `WallItemDefinition` e `WallItemCatalog`, em `data/wall_items`: 13 itens, entre eles os 5 enfeites de sempre e 8 novos (TV, rádio, janela redonda, janelão em arco, lousa de cardápio, neon de xícara, espelho dourado e planta pendurada);
  - cada item fica num trecho das paredes do fundo (a mureta é baixa demais);
  - pendurar usa o mesmo modo da reforma: escolher na aba Paredes, marcar os trechos e confirmar, pagando por trecho; o que estava lá sai;
  - o cartão "Tirar enfeite" tira de graça;
  - janelas deixam a luz entrar no chão.
- **Jogo novo e saves antigos** ficam com os enfeites de sempre (o antigo ciclo da arte, agora como itens). O save versão 7 guarda os itens.
- **Beleza:**
  - os itens somam beleza;
  - os enfeites baratos de sempre valem 1 cada, para o jogo novo não passar da primeira meta da conquista de beleza;
  - essa meta subiu de 50 para 55, porque os enfeites passaram a contar.

---

## DT-041 — Reforma piso a piso, cobrada por célula

**Problema:** o PO pediu que a reforma fosse cobrada por "frame" (célula). Escolher uma parede nova não deve pintar tudo: deve aparecer um retângulo para ir tocando onde quer, para poder misturar duas cores. O mesmo vale para o piso.

**Opções:** (A) continuar com um revestimento para a cafeteria inteira; (B) guardar o revestimento de cada piso e de cada trecho de parede.

**Decisão:** B.
- **Estilo:** o `CafeStyle` guarda o piso e a parede **de base** (que cobrem tudo) e só o que foi pintado por cima: `{piso: revestimento}` e `{"borda:índice": revestimento}`. As paredes do fundo são `top` (ao longo de x) e `left` (ao longo de y). Pintar com a base apaga a pintura.
- **Preço:**
  - cada revestimento ganhou `tile_price`: no piso, 1/16 do preço antigo por célula; na parede, 1/4 por trecho;
  - pintar a cafeteria 8×8 inteira custa cerca de 4 vezes o preço antigo, para a reforma consumir ouro, como o PO quer;
  - os revestimentos iniciais são grátis;
  - os comprados inteiros em saves antigos continuam pintando de graça;
  - só as células que mudam são cobradas.
- **Beleza:** piso e parede valem a **média** das células. O piso inteiro vale a beleza do revestimento; metade dele, metade.
- **Na tela (modo de reforma):**
  - escolher um piso ou uma parede na loja abre a reforma;
  - cada toque marca ou desmarca o piso ou o trecho de parede, que aparece já com o revestimento novo e contorno amarelo;
  - a barra mostra quantos estão marcados e quanto custa, com os botões Tudo, Limpar, Confirmar e Cancelar;
  - confirmar uma reforma paga pede confirmação, com Cancelar selecionado;
  - ao terminar, volta-se para a loja.
- **Save versão 6:** a pintura de piso e de parede. Os saves antigos ficam só com a base, e a pintura com um revestimento que deixou de existir volta para a base, com aviso.

---

## DT-040 — Andar com joelho: ciclo de 8 quadros e corpo sem balanço

**Problema:** o PO achou o andar ainda "engessado, parecendo pinguim". Dois motivos:
- as pernas só trocavam entre 3 desenhos retos (em pé e uma passada para cada lado);
- o corpo inteiro inclinava de um lado para o outro a cada passo, o que dá o gingado de pinguim.

**Opções:** (A) animação por ossos no jogo (Skeleton2D); (B) mais quadros desenhados pelo mesmo gerador da arte.

**Decisão:** B. A arte continua saindo do código das pranchas, e o jogo só escolhe o quadro.
- `people3.py` desenha um **ciclo de 8 quadros** (`passo_0` a `passo_7`), com duas passadas, uma de cada perna. Cada perna tem joelho:
  - **no apoio**, o pé fica no chão e vai da frente para trás;
  - **no balanço**, o joelho dobra, o pé sobe e volta para a frente, e o sapato gira de leve (calcanhar na chegada, ponta na saída);
  - os braços balançam ao contrário das pernas.
- **Perspectiva:** o boneco é desenhado quase de frente, então andar para a frente é ir em direção à câmera. O pé da frente desce na tela e o de trás sobe (de costas, ao contrário); a perna que está mais ao fundo é desenhada primeiro. Mover os pés para os lados fazia as pernas se cruzarem.
- **No jogo:**
  - o `AgentView` escolhe o quadro pelo quanto o desenho andou, então o pé não escorrega;
  - o corpo não inclina mais;
  - o quique caiu de 4 para 2 px, com o corpo no alto quando as pernas se cruzam;
  - as pranchas continuam com as poses "andar" de antes.
- A folha de personagens agora também cresce em várias imagens (`personagens`, `personagens_2`...), como a de móveis.

---

## DT-039 — Atendimento que pressiona: cardápio, fila, garçons que trabalham sozinhos e contratação

**Problema:** o PO achou o jogo fácil demais. Os pontos dele:
- os clientes só pediam o que estava no balcão;
- ninguém esperava lá fora;
- o garçom ficava parado na porta;
- o jogador precisava tocar no fogão para levar cada prato;
- não dava para contratar mais garçons.

O foco que ele quer: o jogador precisar expandir e gastar moeda.

**Opções:** (A) só aumentar o número de clientes; (B) mudar as regras do atendimento para criar demanda de verdade, mantendo o jogador no papel de cozinhar e decorar.

**Decisão:** B, toda a regra em `core/` e cada número em dados (`service.tres`, `economy.tres`).
- **Cardápio:**
  - sentado, o cliente olha o cardápio por 1,5 s e pede;
  - 40% das vezes ele pede qualquer prato liberado, mesmo o que não está no balcão (sem nada no balcão, todos pedem assim);
  - pratos rápidos saem mais (o peso é 1/√tempo de preparo): café sai bem mais que lasanha;
  - o pedido sem porção espera o jogador cozinhar e pega a porção assim que ela chega a um balcão;
  - enquanto o prato está no fogão, a paciência gasta pela metade: o cliente vê que estão preparando.
- **Fila na calçada:**
  - sem cadeira livre, até 5 clientes esperam na calçada, de frente para a porta;
  - o primeiro entra quando vaga uma cadeira;
  - quem cansa (30 s) vai embora e custa popularidade.
- **Mais gente com o nível:** cada nível encurta em 6% o intervalo entre chegadas (até 45% do original) e põe mais um cliente lá dentro.
- **Garçons:**
  - servem os pedidos que já têm porção no balcão;
  - buscam sozinhos nos fogões os pratos prontos e levam ao balcão (o XP é do jogador);
  - **nunca começam a cozinhar**, porque isso é o que prende o jogador;
  - sem tarefa, circulam entre fogões e balcões em vez de ficar na porta;
  - dois garçons nunca vão buscar o mesmo prato.
- **Contratação:**
  - garçons 2, 3 e 4, liberados nos níveis 3, 5 e 8, por 500, 1.500 e 4.000 Café Ouro;
  - o botão "Garçom" fica na faixa de baixo e pede confirmação (Cancelar já selecionado);
  - o save versão 5 guarda quantos garçons há, e os saves antigos ficam com 1.
- **No painel do fogão:** uma bolinha vermelha em cada receita diz quantos clientes esperam aquele prato, e a barra escreve "Clientes esperando: Café ×2".
- **Teste do robô:** ele aprendeu a cozinhar o que os clientes pedem. O teste separa quem desistiu da fila (a pressão que se quer, já que esse robô não compra mesas) de quem saiu irritado da mesa (atendimento que falhou, que precisa ficar abaixo de 25%).

---

## DT-038 — Coleções da loja: estilos e culturas como conteúdo

**Problema:** o PO achou a loja com poucos itens. Ele pediu móveis de estilos e de culturas: anos 70, 80 e 2010, balada, festa, country, americano, mexicano, "todas culturas". A loja tinha 9 móveis e 9 revestimentos, numa fila só por aba.

**Opções:** (A) só acrescentar itens nas abas que já existem; (B) agrupar o conteúdo em coleções, com filtro e páginas na loja.

**Decisão:** B. Com dezenas de itens, uma fila só ficaria comprida demais para o celular.
- **A coleção é conteúdo:** `CollectionDefinition` (id, nome, cor e ordem), em `data/collections/*.tres`, lida pelo `CollectionCatalog`. Móveis e revestimentos ganharam o campo `collection`. O padrão é `classico`, então os itens antigos e os saves não mudam.
- **12 coleções novas:** Anos 70, Country, Festa, Americano, Mexicano, Anos 80, Italiano, Japonês, Francês, Brasileiro, Anos 2010 e Balada.
  - Cada uma tem cadeira, mesa, dois enfeites, piso e parede: são 48 móveis e 24 revestimentos novos.
  - Elas liberam do nível 2 ao 9.
  - Os arquivos saem de `tools/content/make_collections.py`.
- **Loja:**
  - uma fileira de coleções no alto: "Todas" e uma para cada coleção, na cor dela;
  - 6 quadradinhos por página, com setas e a contagem ("1/5");
  - trocar de aba volta para "Todas", e trocar de coleção volta para a primeira página.
- **Arte:**
  - `themes3.py` desenha cadeiras e mesas a partir de duas peças genéricas: o pé, o assento, o encosto, o tampo e a toalha mudam de uma coleção para a outra;
  - cada enfeite tem um desenho próprio;
  - pisos e paredes ficam em `tiles3.py`, com padrões que emendam de uma célula para a outra (o que passa da borda é recortado na sangria).
- **Encosto separado:** quem senta de costas recebe, por cima, o encosto da cadeira em que sentou (`encosto_<cadeira>_r1` e `_r2`). Antes, a pose de costas já vinha com o encosto da cadeira clássica desenhado. A banqueta americana não tem encosto.
- **Folhas que crescem:** os móveis agora ocupam três folhas (`moveis`, `moveis_2` e `moveis_3`), porque o navegador não fotografa uma imagem muito alta. As folhas de um mesmo assunto compartilham os gradientes.
- A beleza e o preço dos itens novos seguem a escala atual. Se o jogo ficar fácil demais, isso entra no **FAÇA BALANCEAMENTO**.
- **Complemento (12/10, pedido do PO):**
  - mais uma cadeira e uma mesa em cada coleção (24 itens), com outras formas, cores e encostos;
  - fogões e balcões modernos: fogão retrô menta, inox industrial e preto com dourado; balcão de madeira, de confeitaria e inox;
  - os fogões mantêm as medidas do clássico, para a panela e o forno aceso caírem no lugar, e os balcões mantêm a altura das pilhas de pratos;
  - a aba Cozinha agora também tem coleções.

---

## DT-037 — Música ambiente: bossa nova composta e sintetizada por código

**Problema:** o PO pediu uma "musiquinha de café" tocando sempre, como no jogo antigo: som de restaurante chique, sem voz, suave.

**Opções:** (A) música licenciada ou de banco gratuito; (B) composição própria gerada por código, como os sons (DT-027).

**Decisão:** B. Não há risco de direito autoral, e a faixa pode ser refeita ou alterada a qualquer momento.
- `tools/music/compose_bossa.py` compõe e sintetiza, só com Python, uma **bossa nova em fá maior a 88 BPM**: piano elétrico (FM) na batida da bossa, contrabaixo dedilhado, vibrafone com a melodia, vassourinha, caxixi e aro de caixa, com reverberação de salão. Três voltas de 16 compassos: melodia, solo suave do piano e melodia de novo. São **2min11**, e o fim emenda no começo, sem corte.
- O equilíbrio foi medido instrumento por instrumento: melodia a cerca de -5 dB do total, piano e baixo a -5 dB, percussão a -17 dB.
- No jogo: `art/music/bossa_do_cafe.wav`, importado comprimido (QOA) e em loop. A música toca a -11 dB, atrás dos efeitos, e entra e sai com fade. Tem **botão próprio** (nota musical), separado do som dos efeitos, e a escolha fica no aparelho.
- Sem saída de som de verdade (modo sem janela), a música não toca: lá ela nunca termina de parar e fica presa na memória ao fechar. Os testes ligam a música mesmo assim (`music_without_audio_device`).

---

## DT-036 — Movimento suave na tela, regras no grid

**Problema:** o PO achou a movimentação "muito travada". Os personagens andavam de centro em centro de piso e viravam em ângulo reto. Ao sentar e ao levantar, pulavam entre a cadeira e o piso ao lado. Os clientes surgiam e sumiam na entrada, e os passos tinham quadros quase iguais.

**Opções:** (A) mudar a navegação (caminhos em diagonal, curvas nas regras); (B) deixar as regras como estão e suavizar só o desenho.

**Decisão:** B. As regras continuam simples e testadas: ocupação de piso, caminho e quem chega primeiro não mudam.
- O desenho **persegue** a posição do personagem com suavidade (`SMOOTHING`), nunca mais rápido que 1,6 vez o passo dele. Assim as curvas saem redondas e os saltos das regras (sentar, levantar) viram um passinho.
- O cliente só aparece **sentado quando o desenho chega na cadeira**.
- **Passos novos na arte** ("passo" e "passo2"): passada mais aberta e braços balançando ao contrário das pernas. A pose "andar" das pranchas não mudou.
- Cada passada tem um **quique** e um **balanço** do corpo, medidos pelo quanto o desenho andou: o pé não escorrega. Parado ou sentado, o personagem **respira** de leve.
- Os clientes **chegam andando da calçada** e, ao sair, **voltam para ela** e somem aos poucos. Para as regras, eles já saíram (a contagem de personagens não muda).

---

## DT-035 — Interface da v3: formato do jogo antigo, loja que abre e fecha

**Problema:** a interface ainda era a do protótipo: painéis escuros, botões de texto e a loja sempre aberta embaixo. As pranchas aprovadas (DT-029) mostram o formato do jogo antigo.

**Decisão:**
- **HUD:** o Café Ouro num contador escuro com a moeda; no meio, a barra de XP listrada com a estrela do chef e o nível em número grande, e a barra de beleza com a flor; no alto à direita, o cronômetro do presente diário (com "Receber!" quando chega a hora); à esquerda, os medalhões Missões (com o cartão da missão, que o medalhão esconde e mostra), Presente e Conquistas; à direita, botões quadrados de zoom, som e configurações (Recomeçar); embaixo à esquerda, a satisfação dos clientes em estrelas (a popularidade) e o nome da cafeteria.
- **Barra de baixo:** a faixa branca de ícones (Loja, Reformar, Expandir, Missões, Presentes, Conquistas). A **Loja abre** um painel com abas coloridas (Salão, Cozinha, Decoração, Pisos, Paredes) e quadradinhos com o desenho do item, o nome e a etiqueta de preço ou o cadeado do nível. Escolher um móvel fecha a loja, para o salão aparecer. Móvel selecionado e construção usam os botões quadrados da arte (Mover, Girar, Guardar, Vender, Fechar; Girar, Confirmar, Cancelar). O fogão mostra as receitas em cartões com o desenho do prato.
- **Abas:** os móveis se dividem pela categoria que já existe nos dados. Mesa e cadeira ficam em Salão; fogão e balcão, em Cozinha; o resto, em Decoração. Nada muda nos dados.
- **Arte e texto:** ícones, botões e medalhões vêm do gerador (folha `interface`, com 2 pixels de textura por pixel da tela). O texto é escrito pela Godot, para os números mudarem e continuarem nítidos.
- **O que não existe no jogo fica de fora:** vizinhos, correio, grãos (moeda premium), festival e cardápio. Eles voltam com as fases deles.
- Os textos que os testes usam continuam iguais ("60 ouro", "Nível 3", "Em uso", "10×8"...). O botão de som mostra o símbolo e diz o estado na dica.
- **Fonte (autorizada pelo PO em 01/10/2026):** Fredoka, a letra arredondada das pranchas, em toda a interface e nos textos do salão. A Nunito fica disponível para textos corridos. As duas vêm do repositório oficial do Google Fonts, com a licença SIL OFL 1.1, que permite usar e distribuir no jogo. Os arquivos e as licenças ficam em `art/fonts/`, e as licenças entram no build exportado.

---

## DT-034 — Cozinha da v3: panela no fogão, selo e pilha de pratos

**Problema:** fogão e balcão mostravam o estado numa etiqueta de texto escura ("Café 0:12", "Café ×6"). As pranchas mostram a panela no fogão, um selo redondo com o prato e o tempo e, no balcão, a pilha de pratos com um número.

**Decisão:**
- O fogão que cozinha ganha por cima a **panela da receita**, com a chama acesa e vapor, e o **forno aceso** nas rotações em que a frente aparece. São figuras à parte, porque o mesmo fogão serve para todas as receitas.
- O **selo do fogão** (círculo branco, prato, anel de progresso, tempo numa pílula azul, "Pronto!" verde com brilho) e o **número do balcão** são desenhados por código, porque o tempo e o progresso mudam a cada quadro. Eles ficam no filho de cima, como os balões, e nenhum móvel os cobre.
- O **balcão** mostra a pilha de pratos com a comida: um prato a cada 4 porções, até 3.
- A etiqueta de texto continua guardando o estado (os testes e a acessibilidade usam) e só é desenhada quando falta arte.

---

## DT-033 — Cenário da v3: piso e parede por célula, rua do lado da entrada

**Problema:** o canvas desenha o salão inteiro de uma vez, mas no jogo o jogador troca o piso e a parede e a cafeteria cresce. Além disso, no canvas a porta fica numa parede do fundo e a rua passa atrás do salão. No jogo, os clientes entram pela borda da frente, à direita.

**Decisão:**
- **Piso:** uma peça do revestimento por célula. No xadrez, claro e escuro se alternam. Nos outros pisos, a variação sai da posição: a mesma célula sempre igual, e tábuas e mármores diferentes lado a lado. Cada peça passa um pouco da borda (sangria) para não abrir fresta. A borda da frente ganha a laje branca e a entrada ganha o tapete listrado do canvas.
- **Parede:** um painel por célula nos dois lados, com a da esquerda mais escura, como no canvas. Os enfeites (relógio, janelas com cortina, prateleira, quadros) seguem um ciclo que se repete quando a parede cresce. A luz das janelas aparece no chão. O acabamento branco no alto e as pontas são desenhados por código. A parede tem a altura do canvas (152 px de mundo), e a câmera enquadra por ela.
- **Revestimentos:** os 9 do jogo foram redesenhados no estilo v3, sem mudar id, preço nem beleza. As listras menta são o papel de parede aprovado nas pranchas.
- **Exterior:** gramado em volta, sem árvores. Do lado da entrada ficam calçada, meio-fio, rua e um caminho de pedras até a porta, porque é por ali que os clientes chegam. As bordas da frente ganham a cerquinha branca, com abertura no caminho, e há canteiros na grama e postes na calçada.
- **Camadas:** gramado, rua e caminho ficam atrás de tudo (`ExteriorView`). Cerca, canteiros e postes ficam por cima do salão (`FrontView`, `z_index` 1), porque estão sempre na frente dele.
- O exportador confere se cada folha é um SVG válido antes de desenhar. Um atributo repetido fazia o navegador desenhar uma página de erro no lugar das figuras.

---

## DT-032 — A cadeira vira sozinha para a mesa (decisão do PO, 01/10/2026)

**Problema:** com a arte dos personagens, quem senta olha para onde a cadeira aponta (DT-031). Antes, a rotação da cadeira quase não aparecia, e o jogador podia pôr cadeiras viradas para qualquer lado.

**Opções apresentadas ao PO:** virar sozinha (as novas e as do save), virar só as novas, ou deixar como está.

**Decisão do PO:** virar sozinha.
- **Modo de construção:** a cadeira levada para o lado de uma mesa já vira para ela. Girar no mesmo piso continua valendo. Ela só se ajeita de novo quando muda de piso. Entre duas mesas, ela continua olhando para a que já olhava.
- **Saves antigos:** o save sobe para a **versão 4**. A migração só põe uma marca, e ao carregar o layout as cadeiras que não olham para nenhuma mesa viram para a mesa vizinha. A marca não volta a ser gravada, então isso acontece **uma vez**. Depois, a escolha do jogador vale.
- A regra fica em `CafeLayout` (`front_direction`, `rotation_toward_table`, `turn_seats_toward_tables`) e vale só para assento de 1 piso.

---

## DT-031 — Personagens da arte v3: poses desenhadas, espelho no jogo e balões por código

**Problema:** trocar os bonecos provisórios pelos personagens aprovados, que andam, sentam, pedem, comem e vão embora, sem multiplicar o número de desenhos.

**Decisão:**
- **12 visuais de cliente** (os tipos de gente das pranchas) e o **garçom Léo**. Cada visual tem: em pé e dois passos de andar, de frente e de costas; sentado de frente com 4 expressões (feliz, esperando, bravo, comendo); sentado de costas para as rotações 1 e 2 da cadeira. O garçom tem as poses com e sem bandeja.
- Cada pose é desenhada olhando para a **direita da tela**. O jogo **espelha** na horizontal para as outras direções, como o canvas já fazia. Isso corta pela metade o número de desenhos.
- Andar é um ciclo de 4 quadros (passo, em pé, outro passo, em pé), que troca de quadro conforme o personagem anda pelo piso, e não pelo relógio. Parado, ele fica em pé.
- O visual do cliente vem do **número de série**: clientes não entram no save, então nada muda nos dados.
- **Quem senta olha para onde a cadeira aponta** (`CafeLayout.front_direction`). Assim o corpo combina com o encosto. Quem senta de costas leva o encosto da cadeira desenhado por cima, como no canvas. Um teste reprova cadeira nova sem essa arte.
- A **expressão segue a paciência**, nas mesmas faixas das cores da barra: acima de 50% feliz, acima de 25% esperando, abaixo disso bravo.
- O **prato de quem come fica na mesa**, desenhado pela própria mesa, para a profundidade sair certa. O garçom leva na bandeja o prato do pedido.
- **Balões e carinhas** são desenhados por código, porque a barra de paciência muda a cada quadro. O prato do pedido vai dentro do balão. Eles ficam num filho com `z_index` alto, e nenhum móvel cobre o balão.
- O exportador agrupa as figuras em **folhas**: o navegador abre 3 vezes, e não 187. A exportação inteira leva uns 5 segundos.

---

## DT-030 — Sprites do jogo gerados do código da arte v3

**Problema:** levar a arte v3 aprovada (SVG gerado em Python) para dentro da Godot, na escala do jogo (piso de 128×64; a arte foi desenhada para 96×48), sem desenhar tudo de novo.

**Opção A:** a Godot importa os SVGs direto (ThorVG).
**Opção B:** o Python desenha os SVGs, o Chrome ou o Edge sem janela converte para PNG, e a Godot só recorta e grava a âncora.

**Impactos:** testado no Windows, o ThorVG da Godot 4.7.2 deixa **vazio** todo gradiente em forma curva (as folhas da planta saíam só com o contorno). Ele também não tem padrões (`<pattern>`), que a toalha da mesa usa. O Chrome desenha igual às pranchas aprovadas. Como o Edge vem em todo Windows, nada novo precisa ser instalado.

**Decisão:** B.
- `tools/art_direction/v3/export_sprites.py` desenha cada móvel nas 4 rotações e amplia o desenho inteiro (traços junto) para **2 pixels de textura por pixel de mundo**. A Godot desenha o sprite pela metade, o que deixa a imagem nítida até o zoom máximo (2×).
- `tools/sprites/crop_sprites.gd` recorta as sobras e grava `art/sprites/*.png` e `sprites.json`, com a âncora de cada sprite no vértice da frente da pegada, o mesmo ponto em que o `FurnitureView` fica. Assim o y-sort continua valendo (DT-009).
- Rotações: a frente para sudoeste (0) e sudeste (3) aparece. Para noroeste (1) e nordeste (2), o móvel aparece **de costas**. Móveis simétricos têm um desenho só.
- Os PNGs entram no repositório: abrir ou exportar o jogo não depende de Python nem de Chrome. Os arquivos crus (`tools/sprites/raw/`) não entram.
- Móvel sem sprite volta à caixa colorida (`PLACEHOLDER_FURNITURE`), então dá para criar conteúdo novo antes de existir arte.
- Texturas importadas **com mipmaps** (padrão do projeto), para o zoom de afastar não serrilhar.

---

## DT-029 — Direção visual v3: formato do jogo antigo, desenho próprio

**Problema:** o PO reprovou o visual da v2 por ser apagado e pediu para chegar o mais perto possível do Café Mania original, liberando até copiar, já que o jogo foi encerrado.

**Opção A:** copiar sprites, personagens, ícones e telas do jogo antigo.
**Opção B:** reproduzir as convenções do gênero (cores, densidade do salão, posição e formato dos elementos da interface) com arte 100% nova.

**Impactos:** a opção A cria risco jurídico real: o direito autoral não acaba quando o jogo sai do ar, e as lojas removem jogos denunciados. A seção 5 do master prompt proíbe essa cópia de forma expressa ("não assumir que algo é livre apenas porque o jogo foi encerrado"). A opção B entrega a mesma sensação de nostalgia sem esse risco.

**Decisão:** B. A v3 usa as convenções que ninguém possui (contadores no alto à esquerda, XP no centro, missões em medalhões na lateral, botões quadrados à direita, vizinhos embaixo, loja em grade com preço sob cada item) e desenha tudo do zero: personagens próprios (Chef Bia, Léo e os clientes), ícones, móveis e cenário. As capturas do PO servem só de referência e não entram no repositório.

---

## DT-028 — APK Android sem Gradle, com chave de teste fora do repositório

**Problema:** o jogo é Android-first (seção 7) e nunca tinha rodado num celular. A nuvem de trabalho não alcança os servidores do Google, então o Android SDK completo não pode ser baixado.

**Decisão:**
- Exportação **sem Gradle**, usando o modelo pronto da Godot (`android_release.apk`). Ela só precisa do JDK e do `apksigner`, que vêm dos pacotes do Ubuntu. Uma pasta de SDK mínima aponta para eles.
- Só **arm64-v8a**: cobre praticamente todos os celulares desde 2017 e deixa o APK com ~26 MB.
- **Chave de assinatura de teste** (`cafemanie-test.keystore`), guardada **fora do repositório**. A senha entra por variáveis de ambiente (`GODOT_ANDROID_KEYSTORE_RELEASE_*`) e nunca fica em `export_presets.cfg`. Para atualizar o app por cima do anterior, a chave precisa ser a mesma; se ela se perder, basta desinstalar e instalar de novo, porque o jogo ainda é de teste. A chave oficial da Play Store fica para a Fase 10.
- O conteúdo de dentro do APK é verificado rodando o `--smoke-check` com o motor de Linux.
- Testes provam que os botões e as janelas respondem a **toque de verdade**, e não só a clique, o que importa porque a emulação de mouse está desligada (DT-006).

---

## DT-027 — Sons gerados por código

**Problema:** a seção 123 pede feedback em toda ação, e não há sons originais nem licenciados.

**Decisão:** cada som é um dado (`data/sounds/*.tres`: notas, duração, forma de onda, envelope, volume). Na abertura do jogo, o `SoundSynth` gera o áudio. São sons 100% originais, sem nenhum arquivo de áudio, e fáceis de trocar por sons finais depois. Ligar ou desligar o som é uma **preferência do aparelho** (`user://settings.cfg`) e não faz parte do save: recomeçar o jogo não liga o som de volta. Toda recusa (sem ouro, lugar inválido, em uso) toca o som de erro.

---

## DT-026 — Nome da cafeteria

**Decisão:** o nome é pedido no primeiro acesso, antes da recompensa diária, e tem de 2 a 24 letras, com espaços arrumados. "Depois" usa "Minha Cafeteria". Tocar no nome, no topo, permite trocar. Um save antigo recebe o nome padrão, em vez de interromper quem já jogava.
**Pendência registrada:** quando o nome ficar visível para outros jogadores (Fase 5), ele passa por moderação no servidor (seções 58 e 114). Hoje ele só aparece para o próprio jogador.

---

## DT-025 — Recompensa diária pelo dia local do jogador

**Problema:** seção 51. Qual "dia" vale, e como evitar abuso do relógio.

**Decisão:**
- O dia muda à **meia-noite local**: `GameClock.local_day()` usa o fuso do aparelho. Com servidor, o relógio passa a ser o dele (seção 66).
- O calendário tem 7 dias e fica em `data/config/daily_rewards.tres`. Perder um dia volta ao Dia 1; isso é configurável.
- **Relógio para trás não rende nada**: só um dia *maior* que o último recebido libera recompensa.
- Os prêmios podem ser ouro, XP, um móvel (vai para o inventário) ou um revestimento. Um revestimento que o jogador já tem vira ouro no valor do preço.
- A janela aparece ao abrir o jogo e ao voltar para ele, nunca por cima de outra pergunta aberta. Fechar sem receber mantém o prêmio disponível.

---

## DT-024 — Conquistas por contadores

**Decisão:** o `PlayerStats` conta o que o jogador faz: clientes, pratos, ouro de vendas, compras, expansões e o maior nível e a maior beleza já alcançados. Cada conquista (`data/achievements`) acompanha um contador e tem 3 degraus, cada um com título e prêmio. Um contador que pula vários degraus desbloqueia cada um, em ordem. Ao carregar um save, nenhum prêmio é pago de novo. Um save antigo, porém, **recebe os degraus que já merecia** (quem já estava no nível 5 ganha "Aprendiz" e "Gerente").
Avisos na tela passaram a entrar numa **fila**, para uma conquista não apagar o aviso de subir de nível.

---

## DT-023 — Venda com proteção contra travar o jogo

**Decisão:** vender devolve **50%** do preço (`data/config/economy.tres`) e sempre pede confirmação. Móvel em uso não é vendido. Também não dá para vender o **último fogão ou o último balcão**, contando os guardados: sem eles o jogador não teria como ganhar ouro de novo. Guardar continua livre, porque o móvel guardado ainda é do jogador.

---

## DT-022 — Beleza com efeito no jogo

**Problema:** seção 35. A decoração não deve ser só visual, mas também não pode obrigar um estilo.

**Decisão:** a beleza é a soma dos móveis posicionados com o piso e a parede aplicados. Ela vira um fator de 0 a 1 (bônus máximo com 200 de beleza): clientes até **30% mais pacientes** e chegadas até **25% mais frequentes**. Todos os números ficam em `service.tres`. A beleza aparece no HUD. Qualquer combinação de decoração conta, então nenhum estilo é obrigatório.

---

## DT-021 — Paredes e revestimentos

**Decisão:** duas paredes, nas bordas de trás do grid, desenhadas por código (`WallView`, PLACEHOLDER), crescem junto com a expansão. Piso e parede são **revestimentos** (`data/surfaces`): compra única com confirmação, e trocar entre os já comprados é grátis. A loja ganhou abas (Móveis, Decoração, Piso, Parede), porque todos os itens não cabiam numa linha só.

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
