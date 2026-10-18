# Decisões técnicas

Registro no formato da seção 99 do master prompt. As mais recentes ficam no topo.

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
