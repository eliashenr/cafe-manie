# Direção de arte

Referência: seções 5, 43, 77, 78, 130–132 do master prompt. Documento vivo: vai ser completado com as impressões do PO sobre as capturas do jogo antigo.

## Ajuste após reprovação do avatar e estudo do original (22/11/2026, DT-108)

O PO mantém a estrutura aprovada e quer reorganização gradual. A pesquisa e as propostas estão em [estudo-cafe-mania-original.md](estudo-cafe-mania-original.md). Preservar o acabamento do cenário, o garçom aprovado e os temas culturais; trabalhar hierarquia, descoberta e coerência dos conjuntos em mudanças pequenas.

O avatar DT-107 foi reprovado: o pescoço apaga a frente da gola, o chapéu é uma camada genérica sobre o cabelo e falta contato entre as peças. Corrigir a composição de **um chef completo vestido e parado** antes de separar camadas. Gola traseira/frontal, cabelo traseiro/mechas e abertura/borda do chapéu precisam de profundidade coerente. A recomposição deve reproduzir a referência completa; só depois animar. Conferir a 210×255 e ampliado. Estabilidade de âncora, ausência de corte e testes aprovados não substituem esse critério visual.

Os portfólios estudados reforçam paletas e proporções pensadas por coleção e personagens compostos como um todo. Aplicar essa disciplina ao visual próprio já aprovado; as imagens históricas são referências de estudo, sem instalação no jogo. O estudo não aprova automaticamente novas cores, telas ou mudanças de economia.

### Primeira prova vestida — DT-109

Fonte única `art/avatar/chef_vestido_v1.png`, gerada como retrato inteiro e apresentada parada no café real. Gola traseira atrás da nuca, abas dianteiras sobre a base do pescoço, faixa do toque acompanhando crânio e cabelo. **Aprovada pelo PO em 22/11/2026**, no tamanho normal e ampliado. Prompt e proveniência em `art/portraits/chef_vestido/`.

### Continuidade animada — DT-110

Preservar a base aprovada byte a byte. Animar por malha contínua, sem separar a união de pescoço/gola ou cabeça/chapéu. Apenas duas áreas dos olhos recebem pálpebras novas durante a piscada; fora delas, textura e alfa são os originais. Movimento discreto, pausa e comparação com a pose aprovada disponíveis na revisão. Não usar geração de novos retratos completos a cada expressão: ela altera traços e caimento. **A animação foi aprovada pelo PO**, que autorizou concluir a interface na DT-111.

### Organização integrada — DT-111

**Aprovada e publicada:** commit `2d91d83`, PR #3, merge `5c35ce0`; 793 testes do pacote limpo passaram no GitHub. O pacote exclui o compositor modular DT-107 e usa os sprites/desenho legados da main para variantes não canônicas. Chef canônico e encaixes aprovados permanecem intactos.

Manter creme, verde e os temas das coleções. A Loja reúne móveis e reforma, com separação por tipo, coleção e busca; o filtro ativo fica à vista mesmo depois de reabrir. No HUD, objetivo e progresso permanecem visíveis ao recolher a dica; controles de funcionamento/zoom ficam agrupados e áudio em Configurações. Cidade separa Filial e Vizinhos com estados e ações legíveis. Nenhuma arte de cenário foi substituída nesta reorganização.

O chef canônico aprovado agora aparece no HUD, nas miniaturas correspondentes e no diálogo real: estático nas áreas pequenas e animado no retrato principal. A integração escolhe a pintura completa para os mesmos IDs; nunca recobre sua gola ou chapéu com partes antigas. Outras combinações continuam compatíveis, mas seus encaixes ainda não foram aprovados. Revisão integrada em `Revisar Interface Completa.cmd`; conferência em 1280×720 e 960×540.

## Direção visual integrada (22/11/2026, DT-105)

A referência do garçom aprovado passa a orientar os clientes, chef personalizável, vizinhos e personagens de evento. A interface usa creme, areia e café, ações verdes, detalhes de terracota e latão; mantém Fredoka nos títulos e Nunito no corpo. Botões grandes, textos escuros e menos área sobre o salão.

Móveis preservam suas coleções culturais e materiais, com estrutura mais leve: 25 assentos e 26 mesas, 169 imagens incluindo rotações/encostos. O novo contrato é assento z 0,28, contato z 0,265 e recuo 0,06; a cadeira básica tem largura 0,41, temas 0,39–0,42 e banquetas 0,34. Tampos de 0,74, ou 1,54 na mesa longa. Japão usa z 0,43; demais 0,46; Club 0,48. Alturas no manifesto e pratos são integrados juntos. Pratos têm largura de 24 pixels de mundo e distribuição aproximada ao centro por fator 0,76, respeitando a área e a rotação da mesa longa. Os tamanhos legados abaixo são histórico, não o contrato atual.

Fontes: `tools/render3d/moveis_codex.py` (geometria), `tools/ia/gerar_icones_ui.py` (25 ícones), `art/portraits/calibracao.json` + `importar_retratos_codex.py` (45 sprites), `art/characters/customers/calibracao.json` (288 poses). Fontes bitmap, prompts e ajustes ficam no repositório, fora da importação do jogo por `.gdignore`. Preservar o alfa nativo, sem remover fundo por limiar.

Revisão real: `Revisar Visual.cmd`, C para coleções e N para dia/noite. Testes e limites da conferência constam de `status.md`.

## Garçom: visual aprovado pelo PO (22/11/2026, DT-103)

O alvo continua sendo o personagem com acabamento de jogo estilizado integrado ao café, com rosto expressivo e proporções legíveis. **O PO aprovou o garçom dentro do jogo:** "ficou bom [...] se for só isso, tá aprovado, pode seguir". A referência A do ambiente permanece abaixo.

O lote contém quatro folhas de nove poses (oito passos e uma pose parada), para frente/costas com/sem bandeja, mais o retrato do botão Garçom. As imagens transparentes foram geradas com a ferramenta da OpenAI integrada ao Codex; fontes, prompts e medidas ficam em `art/characters/waiter/`. A etapa não usa créditos do ElevenLabs.

**Contrato visual aprovado:**

- Altura de referência de 96 pixels de mundo e densidade 4, com uma escala e uma âncora fixas por folha. O recorte preserva o registro das poses, sem nivelar os pés individualmente e apagar o movimento.
- O corpo não contém sombra. `external_shadow` pede uma sombra independente no chão; `authored_motion` mantém o movimento dos quadros sem somar quique, respiração ou deformação do jogo.
- A posição e a largura do prato vêm da bandeja medida em cada quadro, inclusive parado. A comida permanece um sprite separado do personagem.
- Os 36 desenhos respeitam os nomes e direções que o jogo já usa. Esse acabamento orienta os clientes da DT-104; os outros retratos serão tratados em etapa própria.

**Como avaliar:** ver a foto e os quatro ciclos capturados no renderizador real em `build/visual-garcom/`, ou abrir `Revisar Garcom.cmd` na cópia visual. A revisão usa dados em memória, alterna frente/costas e mãos livres/bandeja, e permite observar o personagem andando e parado. A textura isolada serve para conferir recorte; o aceite considera o tamanho, o andar, o prato e a luz dentro do café.

## Clientes: 12 identidades no estilo aprovado, ainda candidatos (22/11/2026, DT-104)

São 24 poses por cliente (288 sprites), preservando tom de pele, cabelo, roupa e acessórios de cada identidade. O candidato v2 usa 12 folhas originais de 24 poses e 12 folhas separadas de seis poses sentadas, selecionadas por `group.file`/`group.cells`; as 216 poses em pé/andando ficam intactas na revisão dos assentos. Fontes RGBA e calibração em `art/characters/customers/`, prompts v2 em `ajuste-assentos-v2.json`. O alfa nativo é preservado; a geração usa a ferramenta da OpenAI integrada ao Codex, sem créditos do ElevenLabs.

- A escala parte da pose em pé, com referência de 96 pixels de mundo e densidade 4. A cabeça deve manter proporção coerente ao sentar; ajustes por grupo ficam explícitos, sem ampliar a pose pela própria altura sentada.
- O contato sob os glúteos deve coincidir com o assento da cadeira. Sentados usam essa referência, convertida para a âncora do runtime; isso ainda não garante contato dos pés com o piso. Baixar o corpo inteiro para ocultar a folga pode afundá-lo no assento.
- Frente tem os quatro humores; costas têm as rotações 1 e 2. Selecionar o sentido do tronco e dos joelhos pelo mapeamento de cada fonte; as antigas trocas 22/23 de 01, 03 e 11 não definem a ordem das folhas v2.
- Os oito passos de cada direção mantêm o movimento desenhado, sem quique extra; a sombra das poses em pé fica separada no piso. Conferir continuidade do ciclo, contato dos pés, tamanho da cabeça e oclusão pelo encosto no café real.

**Primeiro candidato instalado:** os 12 clientes estão calibrados e instalados, com 288 sprites, incluindo os 72 sentados v2. Nenhuma pose falta gerar para essa primeira avaliação.

**Refinamento visual pendente:** pés elevados em algumas poses, chegando a cerca de 12 pixels de mundo no 05; no lote 01–06, 02 ~7, 03 ~9,4 e 05 ~11,8. Os casos mais fortes são 05 e 03. No lote 07–12, os pés ficam 4,8–8,1 pixels elevados e a cabeça varia 13–32% entre frente/costas, mais evidente no 09. Essas limitações acompanham a avaliação do primeiro candidato; encaixe, proporções e aprovação visual continuam pendentes.

**Revisão visual pendente:** passaram 758 testes Godot e 15 Python. Após instalação, importação e cena principal por 120 quadros terminaram com saída 0; 6 testes focados passaram. Foram geradas 111 capturas de dia + 1 à noite sem erros e 13 montagens dos 108 detalhes (`status.md`). `Revisar Clientes.cmd` abre o mostruário minimizado, com amostra em memória e dados isolados. N troca dia/noite; 1/2 mostram seis clientes por vez e 0 mostra todos. O aceite do garçom não aprova automaticamente os clientes.

## Direção atual do ambiente: referência A, "Nova York contemporânea" (31/10/2026, DT-090)

O PO escolheu a opção A de duas imagens conceituais como **referência de acabamento**. A imagem é um conceito, não uma tela a copiar: ela não entra no repositório e não vira o café inicial.

**A intenção do jogo vem primeiro:**
- o jogador começa com um café simples e o melhora comprando pisos, paredes, móveis e decoração;
- ele continua livre para transformar e misturar estilos, inclusive os nostálgicos. Não existe seleção fixa de tema;
- o café inicial não vem equipado como o conceito: o neon, o tijolo, o assoalho e o terraço continuam sendo conquistas.

**Onde a consistência mora:** não é em todos os itens terem o mesmo estilo, e sim em estas regras valerem para todos:

| Regra | Medida |
|---|---|
| Perspectiva | isométrica 2:1, câmera ortográfica (60°, 0, 45°), piso de 128×64 |
| Escala | 1 unidade do 3D = 1 piso; densidade 2 das texturas; parede de 152,38 px |
| Encaixe | âncoras e alturas do `sprites.json` (tampo da mesa 45,33; do balcão 62,67), pelo contrato de `scenes/cafe/art_sprites.gd` |
| Luz | a mesma para todos no fim: a `rig="a"` de `tools/render3d/cena3d.py`. Durante a amostra, só os itens dela a usam, e os antigos destoam até serem refeitos (DT-091) |
| Materiais | madeira envernizada, tijolo em relevo, reboco creme, aço escovado, ferro e couro, sem brilho de plástico |

| Situação | O que é |
|---|---|
| **Referência A (o alvo)** | Madeira, tijolo, creme e metal; luz quente dentro e azulada fora; neon com moderação; materiais ricos e sóbrios |
| **1ª amostra (DT-090)** | O PO aceitou os ajustes funcionais, mas não o visual: ela trocava cores e texturas e mantinha a linguagem anterior |
| **2ª amostra (DT-091, aprovada pelo PO como caminho)** | Modelos novos da cadeira, mesa, balcão e fogão iniciais; piso, parede e itens de parede do café inicial; assoalho, tijolinho e arandela; pilares e vigas; luz do salão; garçom e 3 clientes em nova proporção |
| **Personagens (DT-092, aprovados pelo PO)** | Os 12 clientes na nova proporção; encostos das outras cadeiras corrigidos |
| **Cadeiras e mesas (DT-093, aprovadas pelo PO)** | 24 cadeiras e banquetas e 25 mesas com modelo novo, na proporção e na luz da amostra, mantendo o caráter de cada coleção |
| **Fogões e balcões (DT-094, aprovados pelo PO)** | 13 fogões e 12 balcões com modelo novo, com a panela, o forno aceso e os pratos nos mesmos lugares |
| **Enfeites e máquinas (DT-095, aprovados pelo PO)** | 52 itens com modelo novo, incluindo as máquinas de bebida, o trem, o caldeirão e o balcão de entregas |
| **Pisos, paredes, itens de parede, portas e terraço (DT-096, aprovados pelo PO)** | 37 pisos e 14 paredes com texturas sem emenda; 21 itens de parede, 12 portas e o terraço com modelo novo |
| **Retrato do chef (DT-097) e pratos e panelas (DT-098), aprovados pelo PO** | O chef em 3D por camadas (24 cabeças, 6 roupas, 5 chapéus); 39 pratos e 39 panelas |
| **Vizinhos, bruxa, Garçom, bebidas e frutas (DT-099, aprovados pelo PO)** | 7 vizinhos, a bruxa e o ícone do Garçom como pessoas realistas; 9 bebidas e 3 frutas |
| **Pendente** | A cidade com a luz antiga; ícones de interface e temperos ficam desenhados de propósito |

**Fica de fora nesta direção:** o que o conceito mostra e o jogo não tem. Os garçons continuam humanos e a loja continua na barra de baixo (DT-088).

**Como conferir:** `tools/art_sample.gd` monta o mesmo café em memória, sem save, com piso e parede que já existem na loja e uma mistura de estilos. Com `fixa`, a câmera não depende da versão do jogo.

## Direção anterior: "Nova York Futurista" (24/10/2026, DT-077)

A interface escura e o sistema de cores abaixo continuam valendo. O robô e o "futurista" saíram (DT-088), e a arte vetorial citada foi trocada pela 3D no ramo `arte-3d` (DT-084 a DT-087).

O PO mandou duas imagens de referência e um prompt detalhado pedindo a reformulação de **todo o jogo**. A direção nova substitui a "Esquina Nostálgica" (abaixo, que fica como histórico).

**O que o PO pediu:**
- uma cafeteria em Nova York, de um futuro próximo, que pareça um jogo comercial moderno;
- isometria 2.5D, materiais (madeira, tijolo, metal, vidro), luz quente dentro e azulada fora, e neon com moderação;
- robôs e painéis digitais integrados, sem virar "tudo neon";
- interface escura e elegante, com hierarquia clara e um sistema de design único;
- sem perder a diversão e as mecânicas do Café Manie.

**Sistema de design** (`scenes/ui/ui_theme.gd`). Cada cor tem uma função:

| Cor | Valor | Função |
|---|---|---|
| Azul-marinho profundo | `#071426` | fundo das janelas e faixas |
| Vidro escuro | `#0B182D`, 93% | painéis do HUD e das janelas |
| Azul tecnológico | `#0878F9` | botões principais e abas ativas |
| Ciano luminoso | `#31D7FF` | seleção, foco, brilho e destaques pequenos |
| Dourado premium | `#FFBE55` | moedas, nível e prêmios |
| Madeira quente | `#70452F` | detalhes do restaurante |
| Branco suave | `#F5F7FA` | texto principal |
| Cinza metálico | `#8C9BAD` | texto secundário e ícones apagados |
| Verde de sucesso | `#35C779` | comprar, confirmar, satisfação |

- **Letras:** Fredoka para títulos, números e botões; Nunito para textos corridos (as duas já no projeto, licença OFL).
- **Medidas:** painel com raio de 16, cartão com 12; texto sem contorno grosso, só uma sombra leve para ler em cima do cenário.
- **Componentes:** painel de vidro (borda azul, brilho ciano ao passar), pílula de contador, bloco do menu lateral, botão quadrado de vidro (borda e símbolo na cor da função, com halo) e barra em degradê.
- **Arte da interface:** contornos com 60% da espessura de antes (`UI_STROKE_SCALE`). Os traços grossos que formam o próprio desenho não mudam.

**O que a referência mostra e não existe no jogo** (telefone, estatísticas, "Seja VIP"): fica de fora. Não criamos botões sem função (pedido do próprio prompt).

**Limitação honesta:** as imagens de referência parecem renderização 3D. A arte do Café Manie é vetorial, gerada por código, original e sem depender de serviços de fora. Ela chega bem mais perto da atmosfera, das cores, dos materiais e da luz, mas não ao nível de foto de um render.

**Loja (DT-078):** painel de vidro com as categorias numa coluna à esquerda (a ativa em azul tecnológico com brilho ciano), coleções em pílulas com a borda na cor delas, cartões escuros com o selo da coleção e um painel de detalhes com o botão verde "Comprar".

**Janelas (DT-079):** papéis dos botões no tema (azul principal, verde para confirmar, vidro "fantasma" para Fechar e Cancelar, vermelho só para apagar, abas com brilho ciano), fundo escurecido atrás da janela, cartões no presente diário, nas conquistas e nos pacotes de ouro, retratos em palcos de vidro.

**Cidade (DT-080):** de dia, concreto e calçadas cinza-azulados, asfalto escuro e poças da rua molhada; à noite, metade das janelas dos prédios acesa (camada "_luz" de cada prédio), vitrines quentes, janelinhas dos arranha-céus, postes com poça de luz, faróis e a luz quente do salão contra o azul da rua.

**O café (DT-081):** letreiro neon ciano com o nome do café e sublinhado rosa em cima da parede do fundo, acabamento de madeira escura (`#7a4b31`) nas paredes e na mureta, itens de parede que acendem à noite (Arandela Industrial, Neon de Xícara).

**Toque futurista (DT-082):** Robô Garçom branco com visor de LED ciano, colete azul-marinho e base flutuante; Máquina de Café Inteligente de vidro escuro com tela ciano; Painel Digital de cardápio. O ciano aparece só nos detalhes de luz.

**Revisão (DT-083):** pílulas escuras com a borda na cor (coleções e abas do livro), cartões bloqueados escuros, botões de texto com os papéis do tema e progresso sempre em ciano (verde só para o que terminou).

**Etapas:** ver `docs/roadmap.md` ("Redesign Nova York Futurista"), as 7 concluídas.

## Direção anterior: "Esquina Nostálgica" (30/09/2026)

O PO mandou capturas do jogo antigo e pediu **nostalgia acima de modernidade**: quem procurar o Café Manie quer a sensação do jogo de 2010, não um jogo "moderninho". A direção visual foi montada no Claude Design, no canvas **"Café Manie — Direção Visual"**, com 5 pranchas: tela do jogo, loja, personagens, guia de estilo e o cenário sem interface.

**O que traz a nostalgia** (convenções do gênero, que ninguém possui):

- a cafeteria na **esquina de um quarteirão**, com rua, calçada, grama e poste;
- a sala **isométrica com duas paredes no fundo**, com janelas, cortinas e quadros;
- o salão **lotado**, com clientes **cabeçudos**, balões de pedido e carinhas de humor;
- as **cores quentes e saturadas**, com contorno escuro;
- **contadores de moeda no alto à esquerda**, **nível com barra de XP no centro**, **barra de ícones grandes embaixo** e **faixa de vizinhos** à direita;
- os números subindo ("+18", "+8 XP").

**O que é nosso** (para não copiar, seção 5):

- **personagens próprios**: Chef Bia (mascote) e o garçom Léo;
- ícones desenhados do zero;
- paleta "café": espresso, chocolate, canela, mel, creme, tomate, menta;
- fontes Fredoka e Nunito;
- a placa-lousa com o nome da cafeteria;
- o grão verde como moeda premium;
- a disposição própria da interface.

Nenhum sprite, logo, personagem, ícone ou texto do jogo antigo foi usado, e as capturas **não entram no repositório**.

Os desenhos das pranchas são gerados por código (`tools/art_direction/`, Python gerando SVG). O mesmo gerador pode exportar os sprites do jogo, então a próxima etapa é trocar os placeholders da Godot por essa arte.

### Versão 2 (30/09/2026)

O PO reprovou a versão 1: móveis de caixa, pessoas estranhas, cabelos feios e comidas irreconhecíveis. A versão 2 refez tudo peça por peça, com luz de cima à esquerda, sombra no chão e brilho nas quinas:

- **Móveis:** mesa redonda com toalha xadrez, babado e vasinho; cadeira de bistrô com pernas, assento estofado e encosto de ripas; fogão industrial com bocas, botões, forno aceso e a panela mostrando a comida; balcão de madeira com tampo de mármore e pilhas de pratos com a contagem; vitrine de vidro com bolos; máquina de expresso; vaso com folhagem cheia.
- **Pessoas:** vista 3/4 com olhos grandes e brilho, sobrancelhas, nariz, boca com expressão, orelhas, gola, mangas e sapatos. São 9 penteados com volume e reflexo (rabo de cavalo, black, chanel, longo, coque, topete, curto, boné e careca) e poses em pé, andando e sentado.
- **Comidas** grandes e reconhecíveis: café com espuma e coração de leite, pão de queijo dourado e rachado, misto-quente com presunto e queijo escorrendo, bolo de cenoura com cobertura de chocolate e granulado, coxinha (uma mordida mostrando o recheio) e lasanha em camadas.
- **Cena:** papel de parede listrado, lambri, janelas com cortina e sanefa, lousa de cardápio, arandelas, azulejo e coifa na cozinha, piso xadrez, tapete na entrada, rua com meio-fio e faixa, árvores, arbustos floridos, banco e cavalete "Aberto".

O gerador v2 está em `tools/art_direction/v2/`.

### Versão 3 (30/09/2026) — a direção atual

O PO achou a v2 **apagada** ("não dá vontade de continuar no jogo") e mandou mais capturas: tela cheia com interface, a loja em quadradinhos e uma cafeteria temática. Os pedidos foram: estilo mais jovial, menos árvores, a formatação e as cores do jogo antigo, o formato da loja e das missões laterais, mais realismo e bonecos melhores (olhos falsos, cabeça "corcunda", cabelo fraco).

**O que mudou:**

- **Cores de dia claro e saturadas:** gramado verde-vivo, paredes brancas e menta, piso de madeira mel, cozinha em xadrez preto e branco, móveis vermelhos, amarelos, rosa e turquesa. Os marrons da v2 saíram. As sombras escurecem a cor sem "sujar" de marrom (`shade` em `core3.py`).
- **Sem árvores.** Fora do salão ficam só gramado, rua com faixa, calçada, postes, canteiros de flores e cerquinha branca.
- **Salão grande e lotado:** 12×12 casas, 5 fogões, 5 balcões com pilhas de pratos e contagem, duas mesas compridas e mesas redondas, 17 clientes sentados, 3 chegando pela porta, chef e garçom.
- **Interface no formato do jogo de 2010** (convenções do gênero, desenho nosso):
  - contadores escuros com botão verde de "+" e o botão "Moedas e grãos";
  - barra de XP listrada com selo de estrela e o número do nível grande;
  - barra da Beleza e o relógio do presente diário no alto;
  - **missões laterais em medalhões redondos com fita** (Missões com a Chef Bia, Presente, Festival, Conquistas) e o cartão da missão atual;
  - botões quadrados azuis à direita (zoom, tela cheia, esconder, música, som);
  - barra de ícones embaixo (Loja, Decorar, Expandir, Cardápio, Missões, Presentes, Conquistas, Correio) e a faixa de vizinhos com setas azuis, nível na estrela e os cartões "Convidar amigos" e "Adicionar vizinho".
- **Loja em quadradinhos:** abas grandes, fileira de categorias, grade de itens brancos com a etiqueta de preço embaixo, selos (Novo, −20%, favorito, "Nível 4" com cadeado), setas azuis, prévia do item com a Beleza e o botão verde de comprar. Ao fundo, o móvel sendo posicionado no salão, com piso verde e os botões girar, confirmar e cancelar.
- **Personagens refeitos:**
  - cabeça redonda **centrada no pescoço** (o "corcunda" vinha da cabeça em 3/4 sobrando para trás);
  - olhos de desenho com pálpebra grossa, íris recortada pela pálpebra, sombra da pálpebra e dois brilhos;
  - sobrancelhas que mudam com o humor, bochechas, nariz e boca por expressão (feliz, sorriso, esperando, bravo, comendo), gota de suor e veia de raiva;
  - 12 penteados em mechas pontudas, com sombra do cabelo na testa, fios e reflexo em anel;
  - braços com mãos de verdade, roupas com gola, botões, capuz e dobras.

**Originalidade (seção 5):** o PO liberou copiar, porque o Café Mania acabou. Mesmo assim, **não copiamos** personagens, logo, ícones, sprites nem telas: o direito autoral continua depois que um jogo sai do ar, e uma cópia pode tirar o Café Manie das lojas. O que traz a nostalgia são as convenções do gênero (layout da interface, salão isométrico lotado, cores vivas), redesenhadas do zero.

O gerador v3 está em `tools/art_direction/v3/` (ver o README de lá).

## O que vale desde já

- **Estilo:** 2D cartoon sofisticado, "realidade divertida" (seções 43 e 77). Cafeteria reconhecível, pessoas reconhecíveis, móveis plausíveis, sem realismo fotográfico.
- **Originalidade (seção 5):** nada de sprites, interface, personagens, ícones, logos, sons ou identidade visual do Café Mania. As capturas do jogo antigo servem só para entender **que sensação** ele passava. Elas **não entram no repositório**.
- **Legibilidade no celular primeiro:** tela de 6 polegadas, dedo como ponteiro. Cada objeto precisa ser reconhecível pela silhueta.

## O que vamos tirar das capturas (checklist)

Para cada captura, anotar em palavras (não copiar):

- [ ] Temperatura das cores (quentes? pastéis? saturadas?) e o contraste entre piso, parede e móveis.
- [ ] Densidade: quanta coisa cabe na tela sem ficar confuso.
- [ ] Escala dos personagens em relação aos móveis e ao piso.
- [ ] Como o jogo mostrava estado (comida pronta, cliente esperando, cliente bravo).
- [ ] O que dava vontade de decorar (variedade? cores? itens raros?).
- [ ] O que envelheceu mal e precisa ser modernizado (seção 154).

## Medidas técnicas que a arte final precisa respeitar

| Item | Medida atual | Observação |
|---|---|---|
| Piso isométrico | 128 × 64 px (proporção 2:1) | `IsoProjection.TILE_SIZE`. Mudar a escala muda tudo |
| Parede | 152,38 px de altura | `wall_height` no `sprites.json` |
| Móveis | 1×1, 2×1; giram em 4 direções | Foto 3D de cada rotação; a cadeira também tem o encosto de quem senta de costas (rotações 1 e 2) |
| Personagens | Sprites nos quadros do `sprites.json`; DT-103/104 com 96 px de referência e densidade 4 | Garçom aprovado; 12 clientes com 24 poses cada ainda candidatos |
| Resolução base | 1280 × 720, ampliando para telas maiores | Cenário com densidade 2; personagens da DT-103/104 com densidade 4 |

## Como produzir a arte final (decisão para antes da Fase 8)

| Opção | Custo | Prazo | Risco |
|---|---|---|---|
| **A. Artista freelancer** (estilo exclusivo) | Maior | Semanas a meses | Depende de achar alguém com o estilo certo |
| **B. Pacote licenciado** (lojas de assets com licença comercial) | Baixo | Imediato | Estilo pode não ser exclusivo; conferir licença (seção 130) |
| **C. IA para conceitos + artista finalizando** | Médio | Rápido para testar direções | Conferir licença e consistência (seção 132) |

**Recomendação de engenharia:** usar a **C** para explorar 2 ou 3 direções de estilo com o PO e contratar a **A** para a arte final da direção escolhida. Enquanto isso, os placeholders continuam, porque o código já separa regra e desenho: trocar a arte não mexe no jogo.

## Próximo passo

O PO pode testar Loja, HUD e Cidade na revisão integrada DT-111. Garçom, clientes, cenário e chef canônico possuem os aceites registrados nas DT-103–110. Variantes completas de personalização continuam como trabalho futuro; não confundir compatibilidade de IDs com aprovação de encaixe visual.
