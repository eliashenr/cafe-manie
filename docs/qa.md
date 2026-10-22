# QA

## Estratégia

| Tipo | Onde | Quem roda |
|---|---|---|
| Unitário — regras puras de `core/` | `tests/unit/` | Automático, antes de todo commit |
| Integração — cenas com entrada simulada | `tests/integration/` | Automático, antes de todo commit |
| Subida da cena principal (120 frames, zero erros) | `godot --headless --quit-after 120` | Automático, antes de todo commit |
| Build exportado (conteúdo carregou, zero erros) | `CafeManie -- --smoke-check` (DT-020) | A cada entrega de build |
| Visual e sensação (seção 126) | PC do PO na Godot, depois celular | PO, a cada entrega |

Como rodar está no [README](../README.md#testes-automatizados).

## Cobertura atual — 559 testes

| Arquivo | Testes | O que garante |
|---|---|---|
| `unit/test_cafe_grid.gd` | 10 | limites, ocupação, colisão, expansão segura |
| `unit/test_iso_projection.gd` | 8 | clique cai no piso certo, inclusive nas bordas; posições fracionárias dos personagens; vértices fracionários (calçada, cerca) |
| `unit/test_furniture_catalog.gd` | 8 | balcões de 1 piso, 8 fogões e 8 balcões; dados de móveis válidos (95 móveis); recusa de dados ruins; todo móvel e revestimento numa coleção conhecida, e cada coleção com cadeira, mesa, enfeite, piso e parede |
| `unit/test_collection_catalog.gd` | 2 | coleções na ordem da loja, começando pelo Clássico, cada uma com nome e cor próprios; recusa de dados ruins |
| `unit/test_cafe_layout.gd` | 20 | regras de posicionamento, entrada, acesso, mover/girar/remover sem efeito colateral; para onde a frente aponta; assento vira para a mesa |
| `unit/test_placement_session.gd` | 9 | modo de construção só muda o layout ao confirmar; cadeira levada para o lado da mesa vira para ela |
| `unit/test_content_data.gd` | 10 | receitas, clientes, níveis e jogo novo: válidos, lucrativos, layout inicial legal, um balcão por fogão |
| `unit/test_wallet.gd` | 7 | ganhos, gastos, recusas, registro com limite |
| `unit/test_progression.gd` | 9 | curva de níveis até o **30**, cada nível pedindo mais XP; ouro só do 11 em diante; subir vários níveis de uma vez, nível máximo |
| `unit/test_theme_stove.gd` | 3 | **Fogão Japonês:** 4 receitas próprias na aba Japão; só saem nele; clientes só pedem com o fogão |
| `unit/test_stove_profiles.gd` | 8 | **fogões com perfil:** todo fogão especial com perfil; perfil só em fogão; corte; tempo máximo; corte somado com o troféu até o limite; porções a mais com o sal; XP a mais; 1 por café; save das porções a mais |
| `unit/test_trophies.gd` | 7 | **troféus:** os 3 válidos e cada vez mais fortes; só as 8 casas em volta (diagonal sim, 2 casas não) e vale o mais forte; prato acelerado, carga gasta e tempo de estragar de sempre; mover não muda o prato que cozinha; gastar, avisar e renovar; guardado lembra as cargas, vendido perde; save das cargas, dos guardados e do tempo acelerado |
| `unit/test_spices.gd` | 10 | **temperos:** catálogo válido, em ordem e com ícone; sal uma vez por prato, porções no balcão; prato grande com sal em dois balcões; pimenta e páprica sem passar do ponto; instantâneo; ervas salvam o estragado; cada tempero na hora certa; comprar; presente diário e missões; save da prateleira e do tempero no fogão |
| `unit/test_spoilage.gd` | 10 | **comida que estraga:** configuração válida; prato rápido aguenta o mínimo, longo aguenta mais; estraga no segundo certo; estragado não vai para o balcão nem é buscado e ocupa o fogão; jogar fora só o estragado; pausa segura; fator 0 nunca estraga; aviso uma vez por prato; estragado com o jogo fechado contado nas boas-vindas; pratos de 4 h aguentam uma noite |
| `unit/test_kitchen.gd` | 10 | preparo pelo relógio (inclusive com o jogo fechado), coleta, empilhamento, capacidade, reserva e devolução |
| `unit/test_cafe_simulation.gd` | 30 | loop completo cliente → garçom → pagamento; paciência; porção devolvida; assentos; móvel em uso; personagem no caminho; recálculo de rota; desbloqueio por nível; determinismo; **pedido do cardápio fora do balcão** (com o que falta cozinhar), café sai mais que lasanha, paciência mais calma com o prato no fogão; **fila na calçada** (enche, anda, desiste); mais clientes por nível; **garçom busca no fogão, circula pela cozinha e nunca cozinha**; dois garçons não disputam o mesmo prato; contratação (nível, ouro, limite) |
| `unit/test_long_shift.gd` | 2 | 30 min simulados com o "jogador robô" (que cozinha o que os clientes pedem): ninguém preso, lucro, níveis, menos de 25% irritados à mesa (desistências da fila contadas à parte); o robô conclui as 6 missões iniciais |
| `unit/test_save_codec.gd` | 19 | missões do dia e da semana (e o save versão 7 começando as de hoje); ida e volta por JSON de tudo o que é salvo; preparo continua com o jogo fechado; conteúdo desconhecido pulado; migração das versões 1 a 4; nome da cafeteria; cadeiras de save antigo viram para a mesa uma vez; garçons contratados (saves antigos ficam com 1) |
| `integration/test_staff_and_queue.gd` | 3 | botão Garçom (nível, preço, confirmação com Cancelar selecionado, garçom novo aparece); fila na calçada e quem desiste sai andando por ela; bolinha de pedidos no painel do fogão |
| `unit/test_save_service.gd` | 7 | primeiro acesso, gravar e ler, `.bak`, save danificado, save de versão mais nova protegido, apagar |
| `unit/test_shop_and_missions.gd` | 23 | ouro dos níveis altos, garçons 5 e 6; compra, inventário, expansão, missões; **venda** (metade do preço, em uso, último fogão/balcão) |
| `unit/test_style_and_beauty.gd` | 24 | revestimentos (um inicial por tipo, bloqueios); **pintura por célula** (cobra só o que muda, recusa sem mudar nada, pintar com a base apaga); beleza pela média das células e dos itens de parede; **itens de parede** (dados, enfeites de sempre no jogo novo, pendurar cobra por trecho, tirar é grátis, bloqueio); mureta pintável sem a porta; save da pintura e dos itens, migração das versões 5 e 6 |
| `unit/test_coin_shop.gd` | 4 | pacotes de Café Ouro válidos e em ordem, taxa melhor nos maiores; este build nunca entrega ouro; ouro só com o pagamento confirmado (cancelado ou recusado não muda nada) |
| `unit/test_mission_boards.gd` | 14 | **missões diárias e semanais:** 10 e 20 válidas; metas e recompensas pelo nível, em número redondo, limitadas às receitas liberadas; o quadro congela a meta e recomeça no período seguinte; concluir avisa uma vez; cadeado; pratos diferentes, categoria da compra e popularidade; save; cada evento do jogo que conta; recompensa e diária contando para a semanal; pedido do cardápio só quando o prato não estava no balcão; dia novo e segunda-feira |
| `unit/test_recipe_book.gd` | 7 | **livro de receitas:** abas válidas e na ordem, cada receita com a sua; uma receita nova a cada nível até o 30; receitas de cada aba por nível; receita sem aba recusada; desenho de prato e panela de todas; todas cabem num balcão; equilíbrio (demorado rende mais por fornada e dá mais XP, rápido rende mais por minuto) |
| `unit/test_mastery.gd` | 6 | **domínio:** metas válidas e crescentes; estrela em cada meta e domínio completo; prêmio que cresce com a estrela; tirar o prato paga a estrela na hora; save guarda o domínio; save antigo sem estrelas |
| `unit/test_energy.gd` | 9 | **energia das máquinas:** máximo pelo nível; começa cheia e gasta; recusa sem energia bastante; recarga de 1 ponto por intervalo até o máximo; cheia não acumula tempo; tempo até o próximo ponto; recarga com o jogo fechado; relógio para trás não dá energia; nível novo aumenta o máximo e enche |
| `unit/test_drinks.gd` | 15 | **bebidas:** dados válidos, cada bebida com máquina e desenho; máquina exige o tipo de bebida; sem máquina ninguém pede bebida; com máquina pedem as liberadas; bebida bloqueada não é pedida; servir gasta energia, dá XP e o cliente paga a bebida; sem energia não sai; só serve quem espera bebida, uma vez, e com a máquina certa; máquina vendida libera o cliente sem tirar popularidade; quem desiste tira popularidade; nível enche a energia; save guarda a energia e recarrega fora; save antigo abre cheio |
| `unit/test_open_close.gd` | 9 | **placa ABERTO/FECHADO:** fechado, ninguém chega; ao abrir, o próximo cliente chega logo; a fila da calçada vai embora sem tirar popularidade; quem está dentro é atendido e paga; quem desiste fechado não tira popularidade (aberto, tira); fechar duas vezes não muda nada; o save guarda a placa e o save antigo abre aberto |
| `unit/test_pause.gd` | 12 | **pausa:** pausado, mexe em tudo (cadeira com cliente, mesa ocupada, móvel em cima de quem está em pé, balcão com porção reservada, fogão aceso), com as consequências acertadas; ninguém chega; clientes e garçons parados, sem perder paciência; o fogão para e segue de onde parou; preparo começado na pausa espera; save durante a pausa guarda o tempo que falta; dá para comprar, cozinhar e levar prato pausado |
| `unit/test_achievements.gd` | 10 | conquista Mestre até o nível 30; dados válidos e progressivos; paga uma vez; vários degraus de uma vez; contadores seguem o jogo; save não paga de novo; save antigo recebe o que merecia |
| `unit/test_daily_rewards.gd` | 11 | sequência e volta ao início; uma vez por dia; perder um dia; relógio para trás; meia-noite local; ouro, XP, móvel e revestimento; save |
| `unit/test_sound_synth.gd` | 4 | todos os sons existem e são curtos; duração certa; sem estourar volume; sem estalo |
| `integration/test_theme_stove_scene.gd` | 2 | aba Japão no fogão comum com "Só no Fogão Japonês"; no Fogão Japonês os pratos saem |
| `integration/test_stove_profiles_scene.gd` | 3 | dica do perfil e "Só 1 por café" na loja; fogão livre diz o perfil; número que sobe com as porções de verdade |
| `integration/test_trophies_scene.gd` | 5 | troféu escolhido com as casas no chão, a aceleração e as cargas, Renovar apagado se cheio; fantasma da compra com as casas; gasto apagado, aviso e renovar com confirmação; livro e fogão com o tempo acelerado; troféus na aba Cozinha da loja, com a dica |
| `integration/test_spices_scene.gd` | 5 | fogão cozinhando com os 4 temperos, quantidade e preço; usar na hora, com o efeito e "Já temperado"; comprar pede confirmação; ervas no fogão estragado; presente diário e aviso da missão com o tempero |
| `integration/test_spoilage_scene.gd` | 5 | fogão estragado com selo e fumaça verde, sem vapor nem brilho; tocar mostra o Jogar fora, que libera o fogão; mensagem quando estraga; fogão pronto diz quando estraga; boas-vindas contam o estragado |
| `integration/test_save_scene.gd` | 8 | fechar e reabrir com tudo no lugar, pratos prontos com o jogo fechado, salvamento automático, minimizar salva, Recomeçar com confirmação |
| `integration/test_cafe_scene.gd` | 11 | câmera, seleção, arrasto, zoom, pinça, enquadramento (com as paredes) |
| `integration/test_build_mode.gd` | 14 | construir, recusar com motivo, mover, girar, guardar, teclado, abas da loja |
| `integration/test_service_scene.gd` | 12 | aviso de nível alto com o ouro; jogo novo, HUD, painel do fogão, coleta por toque, personagens, aviso de nível, textos flutuantes |
| `integration/test_shop_scene.gd` | 15 | loja, compra, Guardar, expansão com confirmação, missões; **Vender com confirmação** e recusa do último fogão; filtro por coleção e páginas |
| `integration/test_style_scene.gd` | 12 | abas, piso e parede desenhados; **reforma**: escolher abre o modo, toques marcam, prévia, preço por piso, confirmação, trecho de parede e da mureta, Tudo e Cancelar, comprado antes pinta de graça; **pendurar a TV** com confirmação; tirar enfeite de graça; bloqueio; Beleza no HUD; paredes crescem com a expansão |
| `integration/test_coin_shop_scene.gd` | 3 | o "+" do ouro abre a vitrine com os 5 pacotes; neste build a compra explica que ainda não existe e não dá ouro; com pagamento confirmado o ouro entra; faltando ouro, a vitrine aparece uma vez (sem insistir) |
| `integration/test_progress_scene.gd` | 17 | avisos de conquista em fila, painel de conquistas, recompensa diária (abre, paga, volta no dia seguinte, não empilha janelas), nome da cafeteria, sons e botão de som |
| `integration/test_touch_ui.gd` | 3 | botões da loja e das janelas respondem a **toque de verdade**; toque no botão não vaza para o piso |
| `integration/test_furniture_art.gd` | 7 | todo móvel tem arte nas 4 rotações, com âncora e escala certas; a cena e a prévia usam a arte; panela de cada receita; forno aceso só de frente; fogão e balcão mostram receita, tempo, Pronto! e porções |
| `integration/test_hud_art.gd` | 6 | moeda com ponto de milhar e nível; estrelas pela satisfação; presente com cronômetro; zoom pelos botões; tocar no cartão da missão esconde e o medalhão abre as missões; faixa de ícones abre a loja e as conquistas |
| `integration/test_scene_art.gd` | 6 | todo revestimento tem arte; xadrez alterna; variações estáveis; todo item de parede tem desenho nas duas paredes e a porta existe; a cena usa a arte e enquadra a parede; **mureta** nas duas bordas da frente, baixa, sem fechar a porta; exterior acompanha a expansão |
| `integration/test_character_art.gd` | 15 | todo cliente e o garçom têm todas as poses; toda receita tem prato; direção e espelho; ciclo de 8 quadros do andar, que nunca para no meio do passo, com o corpo subindo e descendo de leve; saltos das regras viram passinhos; senta só quando chega na cadeira; chega e sai pela calçada; sentado segue a cadeira; **encosto da própria cadeira por cima de quem senta de costas**; expressão segue a paciência; bandeja; prato na mesa certa; balão por cima |
| `integration/test_visual_fx.gd` | 17 | **efeitos visuais:** raio-X atrás de móvel alto (só onde cobre; nunca na frente, atrás de mesa ou sentado; some ao sair de trás); halo no móvel escolhido e dourado no fogão pronto, nunca no fantasma; vapor no fogão e nos pratos do balcão; pilha que cai no tampo; móvel novo surge (ao abrir o jogo, não); mureta abre perto de quem está junto da frente (também quem sai pela porta) e do piso escolhido; confete do pagamento some sozinho; esticar ao arrancar e achatar ao frear, sutil; loja acende, aviso surge, ouro quica só ao ganhar; botões de ícone com 48 px de toque; filtro de textura do projeto; âncoras da ordem de desenho (y-sort) |
| `integration/test_depth_order.gd` | 7 | **ordem de desenho em faixas:** o garçom na frente da metade de trás do balcão (também passando a 0,3 piso da borda e com o balcão girado), sem raio-X; quem está atrás do balcão fica atrás de todas as faixas, com silhueta; vaso na frente do balcão aparece na frente; as faixas cobrem o desenho inteiro, encostadas, antes do vértice da frente; mover o móvel não recorta |
| `integration/test_missions_scene.gd` | 6 | janela das missões: 10 diárias e 20 semanais com meta, recompensa, cadeado e contagem; progresso e aviso de concluída; uma janela por vez; aba do começo some no fim; texto do tempo; tempero do prêmio nas semanais |
| `integration/test_city.gd` | 10 | **cidade em volta do café:** toda a arte existe (prédios, enfeites, semáforo e carros nas 4 direções); ruas nas duas frentes e o cruzamento; prédios atrás, fora do café, das ruas, das calçadas e uns dos outros, do fundo para a frente (8×8, 12×10 e 16×16); enfeites longe da porta, da fila e do caminho de quem desiste dela (conferido por conta própria); semáforo alterna, carro para no vermelho e atravessa no verde; quem já entrou no cruzamento não para; distância entre carros e volta pelo começo; rua por cima da mureta, carros andando e semáforos na tela; a cidade acompanha a expansão |
| `integration/test_recipe_book_scene.gd` | 8 | livro na primeira aba e só com as receitas dela; abre na aba do prato esperado, com a bolinha; cada fogão lembra a aba; estrelas e dica nos cartões; domínio marca para salvar; aviso da estrela nova; páginas de uma aba grande; a aba Brasil com segunda página e o Churrasco travado nela |
| `integration/test_drinks_scene.gd` | 7 | tocar no balão verde serve a bebida; o nível novo avisa da máquina nova; recusa sem energia explicada; contador de energia (escondido sem máquina, valores e recarga, explicação ao tocar); gastar energia marca para salvar; máquinas na aba Cozinha; arte das máquinas nas 4 rotações |
| `integration/test_open_close_scene.gd` | 5 | botão da porta (fechar e abrir), faixa, aviso e plaquinha FECHADO; tecla F; save fechado abre mostrando; fechar marca para salvar; faixas de fechado e de pausa sem se tampar |
| `integration/test_pause_scene.gd` | 6 | mover pela barra a cadeira de quem está sentado, pausado; botão de pausa e de continuar, com a faixa; tecla P; ninguém fica invisível ao pausar (quem estava aparecendo aparece inteiro); personagens, vapor e trânsito parados (também num fogão posto durante a pausa); construir pausado |
| `integration/test_music.gd` | 4 | a música toca baixinho e em loop; o botão dela liga e desliga, e o aparelho lembra; som dos efeitos e música são separados; ao sair da cena, nenhum som fica preso |

**Aviso intermitente:** às vezes, no fim da rodada, a Godot avisa "1 resources still in use at exit", sem nenhum teste falhar. Nas rodadas com `--verbose` ele não aparece, então ainda não deu para saber qual recurso é. Fica registrado para investigar.

O executor também **reprova um arquivo de teste que nem compila**. Antes, ele sumia da contagem em silêncio (encontrado nesta etapa).

### Verificação dos próprios testes

Para garantir que a suíte pega defeitos de verdade, bugs são inseridos de propósito, um de cada vez, e os testes precisam reprovar:

- **Fase 1 (5 de 5 pegos):** segundo toque não confirma, sem checagem de acesso, entrada liberada, móvel movido continua visível, Confirmar sempre habilitado.
- **Save (8 de 9 pegos, mais 1 equivalente):** preparo não salvo, porções reservadas perdidas, ids reiniciados após carregar (pego depois de fortalecer o teste; ver DT-015), `.bak` nunca usado, save mais novo sobrescrito, salvamento automático desligado, minimizar não salva, Recomeçar mantém o save. A mutação "sem precisão total no JSON" não muda nada observável: a precisão padrão já basta (erro < 1 ms).
- **Paredes, beleza, venda, conquistas, recompensa diária e sons (20 de 20 pegos):** revestimento de graça, beleza ignorando revestimentos, piso sem atualizar, beleza sem efeito na paciência, revestimento não salvo, venda do último fogão, venda sem confirmação, guardados ignorados na venda, conquista de um degrau por vez, conquistas não restauradas, aviso apagando outro, clientes não contados (pego depois de um teste novo), relógio para trás liberando prêmio, sequência sem reinício, dia em UTC em vez do local, sequência não salva, recusa sem som, som desligado não lembrado, nota sem entrada suave, prato pronto sem som.
- **Loja, expansão e missões (5 de 5 pegos):** móvel novo posicionado de graça, inventário sem salvamento automático, piso não acompanha a expansão, expansão sem confirmação, Guardar destruindo o móvel.
- **Fase 2 (7 de 7 pegos):** paciência nunca acaba, garçom não serve, cozinhar dá ouro em vez de cobrar, cadeira ocupada desprotegida, personagens ignoram mudança de layout, porção reservada se perde, comida pronta na hora.
- **Interface v3 (8 de 8 pegos):** loja começando aberta, loja que não fecha ao escolher, moeda sem ponto de milhar, estrelas apagadas, presente sem aviso de quanto falta, zoom ao contrário, medalhão que não esconde o cartão, Reformar abrindo a aba errada.
- **Arte v3 da cozinha (6 de 6 pegos):** fogão sem a receita, selo sem o Pronto!, balcão sem quantidade, forno aceso de costas, selos por baixo do salão, estado da cozinha sem atualizar.
- **Arte v3 do cenário (8 de 8 pegos):** xadrez sem alternar, variação mudando a cada desenho, parede sem a altura da arte, cerca fechando a entrada, cerca por baixo do salão, exterior parado na expansão, cerca sem acompanhar a entrada, enfeites sem repetir.
- **Arte v3 dos móveis e personagens (13 de 13 pegos):** sentado ignora a cadeira, andar sem trocar de pé, espelho trocado, expressão sem paciência, balão sem camada de cima, garçom sem bandeja, prato fica na mesa depois que o cliente sai, prato fora do lado da cadeira, cadeira não vira no modo de construção, save antigo não vira as cadeiras, save atual também vira, assento entre duas mesas troca de lado, móvel ignora a rotação.
- **Movimento (6 de 6 pegos):** salto sem caminhada, senta antes de chegar na cadeira, passada sem quique, cliente surgindo na porta, cliente sumindo na hora, passos sem alternar.
- **Fogão Japonês (10 de 10 pegos):** receita temática em qualquer fogão, começar sem conferir o fogão, cardápio com pratos sem o fogão, sorteio ignora o cardápio, livro sem o "Só no", livro deixa tocar no prato de outro fogão, dango sai em qualquer fogão, tempurá antes do fogão, fogão sem o nome novo, tempurá desequilibrado.
- **Fogões com perfil (18 de 18 pegos):** corte do fogão ignorado, tempo máximo ignorado, cortes sem limite, porções do fogão ignoradas, porções do fogão sem chegar ao balcão, XP do fogão ignorado, tirar o prato com o XP da receita, sem limite por café, save sem as porções do fogão, save sem ler as porções do fogão, perfil de fogão aceito em outro móvel, configuração aceita corte de 100%, loja sem a dica do perfil, loja sem avisar o limite, fogão livre sem o perfil, perfil sem o tempo máximo, perfil sem o XP, número que sobe com as porções da receita.
- **Troféus (42 de 42 pegos):** a diagonal não conta, troféu longe acelera, vale o troféu mais fraco, troféu gasto acelera, prato acelerado não gasta carga, nunca avisa que se gastou, renovar não enche, guardar perde as cargas, recolocar ignora o guardado, save sem as cargas, save sem os guardados, save não lê as cargas, troféu sem cargas aceito, prato acelerado com o tempo da receita, save sem o tempo acelerado, save não lê o tempo acelerado, estragar pelo tempo acelerado, troféu não acelera, cozinhar não gasta o troféu, sem sinal de gasto, renovar sem cobrar, renovar troféu cheio, renovar sem ouro, guardar sem as cargas, recolocar sem as cargas, save sem os troféus, save não lê os troféus, migração sem os troféus, troféu sem área no chão, fantasma sem área, gasto não fica apagado, camada não marca o gasto, mensagem sem a aceleração, mensagem de gasto sem explicar, renovar sempre aceso, renovar sem confirmação, livro sem o tempo acelerado, fogão cozinhando sem dizer do troféu, fogão livre sem dizer do troféu, troféu na aba de decoração, loja sem a dica do troféu, sem aviso de troféu gasto.
- **Temperos (36 de 36 pegos (2 só depois de testes novos)):** porções do tempero sem chegar ao balcão, tempero de porções duas vezes no prato (pego depois de um teste novo na cozinha), pressa passando do ponto, ervas sem salvar o prato, prato grande sem se repartir, repartir em balcão de outra receita, save sem o tempero do fogão, save sem ler o tempero do fogão, sal sem a porção mínima, ervas servindo no prato cozinhando, tempero sem efeito aceito, prateleira fora de ordem, usar sem gastar o tempero, sal de novo no mesmo prato, instantâneo sem efeito, pimenta sem efeito, ervas salvando sem avisar de novo depois, comprar sem cobrar, comprar antes do nível, comprar e usar cobrando mesmo sem servir, presente diário sem tempero, missão sem tempero, save sem a prateleira, save sem ler a prateleira, migração sem a prateleira (pego depois de um teste novo), fogão cozinhando sem temperos, estragado sem as ervas, comprar virando usar, cartão sem a quantidade, cartão sem o preço, temperado continuando aceso, fogão sem dizer que tem tempero, sem efeito na tela, presente diário sem mostrar o tempero, aviso da missão sem o tempero, janela das missões sem o tempero.
- **Comida que estraga (25 de 25 pegos):** prato rápido estragando antes do mínimo, prato longo sem aguentar mais, nada estragando, pausa sem segurar o prato, estragado indo para o balcão, jogar fora prato bom, jogar fora sem liberar o fogão, estragado contando como prato a caminho, tempo para estragar errado, configuração aceitando fator negativo, simulação sem a regra, aviso repetido, prato estragado sem aviso, boas-vindas avisando de novo, jogo sem vigiar o fogão, fogão estragado parecendo normal, fogão estragado brilhando, sem fumaça verde, estragado com vapor, sem botão Jogar fora, Jogar fora sem fazer nada, pronto sem dizer quando estraga, estragado sem explicar, boas-vindas sem contar o estragado, efeito sonoro preso ao sair da cena.
- **Receitas do nível 18 ao 30 (8 de 8 pegos):** lagosta rendendo menos que a floresta negra, nível 20 sem receita nova, waffle rápido demais, churrasco com pouco XP, picanha numa aba que não existe, lagosta sem caber no balcão, lagosta além do nível 30, curry sem nome.
- **Livro de receitas e domínio (22 de 22 pegos):** domínio sem contar o prato, estrela sem o ouro, estrela sem o XP, estrela só depois da meta, estrela que não é avisada, meta seguinte errada, todas as estrelas valendo igual, metas fora de ordem aceitas, save sem o domínio, save que não lê o domínio, migração sem o domínio, receita sem aba aceita, aba mostrando todas as receitas, livro ignorando o prato esperado, fogão esquecendo a aba, aba sem a bolinha, estrelas apagadas, dica sem o progresso, aba sem páginas, voltar página sempre aceso, estrela sem aviso, domínio sem marcar para salvar.
- **Máquinas de bebida e energia (26 de 26 pegos):** bebida sem gastar energia, energia sem recarregar, energia passando do máximo, relógio para trás dando energia, nível sem aumentar o máximo, máximo sem crescer com o nível, nível sem encher a energia, bebida bloqueada sendo pedida, ninguém pedindo bebida, bebida cobrando o preço errado, bebida sem XP, bebida demorando como prato, servir quem já está bebendo, servir sem a máquina certa, máquina vendida prendendo o cliente, quem espera bebida sem perder paciência, save sem energia, save sem o nível da energia, migração sem energia, máquina sem tipo de bebida aceita, contador que some, contador sem a recarga, toque que não serve, recusa sem explicar, energia sem marcar para salvar, máquinas fora da loja.
- **Placa ABERTO/FECHADO (19 de 19 pegos):** fechado ainda chegando gente, abrir sem trazer cliente logo, fila que não vai embora, fila saindo e tirando popularidade, fila sem andar pela calçada, fila ficando na lista, quem desiste fechado tirando popularidade, quem desiste aberto sem tirar popularidade, save sem gravar a placa, save sem ler a placa, migração sem a placa, faixa que não aparece, botão que não troca, faixas uma em cima da outra, plaquinha que não muda, save fechado abrindo sem mostrar, fechar sem aviso, tecla F sem efeito, fechar sem marcar para salvar.
- **Pausa sem bloqueio e balcão de 1 piso (10 de 10 pegos):** pausa ainda protegendo o que está em uso, pausa ainda protegendo quem está em pé, cliente sem acompanhar a cadeira, cliente ficando em cadeira sem mesa, cliente saindo reclamando (tirando popularidade), pedido preso no balcão que saiu, garçom sem refazer a tarefa, ninguém saindo de cima do móvel novo, piso livre sendo o mesmo piso ocupado, balcão voltando a ter 2 pisos.
- **Pausa e loja aberta (14 de 14 pegos (um depois de reforçar o teste)):** pausa sem parar a simulação, pausa sem parar os fogões, fogão cozinhando pausado, fogão perdendo o tempo da pausa, save contando a pausa como cozinhado, preparo da pausa começando no relógio (escapou na primeira rodada: o teste cozinhava logo depois de pausar; agora deixa o tempo passar antes), personagens andando pausados, trânsito andando pausado, pausa sem aviso, tecla P sem pausar, fogão novo sem congelar, loja fechando ao escolher, personagem invisível na pausa, personagem criado na pausa sem congelar.
- **Cidade em volta do café (12 de 12 pegos (um depois de reforçar o teste)):** carro furando o vermelho, carro parando no meio do cruzamento, carro encostando no da frente, carro sem voltar pelo começo, semáforo parado, enfeite no caminho da fila, prédio em cima da calçada, rua por baixo da mureta, carros parados na tela, semáforo da tela sem mudar, cidade sem acompanhar a expansão, fila sem o caminho de quem desiste (escapou na primeira rodada: o teste usava os pontos da própria função; um teste novo calcula o caminho por conta própria).
- **Missões diárias e semanais (14 de 14 pegos (um depois de reforçar o teste)):** quadro que não recomeça, compra ignorando a categoria, prato repetido contando como diferente, missão com cadeado contando, popularidade somando em vez de guardar o maior valor, missão sem pagar o ouro, diária sem contar para a semanal, todo cliente contando como satisfeito, pedido do cardápio nunca marcado (escapou na primeira rodada: o teste marcava à mão; um teste novo faz o pedido de verdade), semana começando na quinta, save esquecendo as missões, janela abrindo por cima de outra, missão concluída sem aviso, metas sem crescer com o nível.
- **Nível 30 (5 de 5 pegos):** nível alto sem ouro, ouro do nível errado (um nível adiantado), aviso sem o ouro, tabela aceitando ouro de tamanho errado, garçons dos níveis altos sem a trava de nível.
- **Sentar e ordem de desenho (9 de 9 pegos):** faixas sem altura própria, lados da pegada trocados, móvel sem y-sort próprio, faixa larga demais (128 px: quem passa perto da borda some atrás), raio-X pela altura do nó, frente só em x, halo na frente do móvel, contorno de seleção na frente do móvel, vapor atrás do fogão.
- **Efeitos visuais (24 de 24 pegos, mais 1 equivalente):** raio-X para quem está na frente, raio-X atrás de mesa, raio-X em quem está sentado, raio-X que nunca aparece, brilho sem seleção, fogão pronto sem brilho, fogão sem vapor, balcão sem vapor, pilha que não quica, móvel surgindo ao abrir o jogo, móvel novo sem surgir, mureta esmaecendo longe da frente, quem sai sem abrir a mureta, mureta sem foco, piso escolhido sem abrir a mureta, pagamento sem confete, confete que não some, frear esticando, esticar sem limite, ouro quicando ao gastar, loja sem acender, aviso sem surgir, botão pequeno demais, textura sem mipmap. A mutação "fantasma brilha" não mudava nada, porque o fantasma nunca fica selecionado nem pronto: a checagem redundante saiu do código.
- **Compra de moedas (6 de 6 pegos):** ouro sem pagamento, pacote dando o ouro errado, oferta sem pausa, sem oferta quando falta ouro, aviso de indisponível sumido, vitrine sem pacotes.
- **Paredes completas e itens de parede (12 de 12 pegos):** mureta fechando a porta, pendurar cobrando onde já tinha, pendurar sem nível, item sem beleza, save esquecendo os itens, save antigo sem os enfeites de sempre, jogo novo sem enfeites, pendurar na mureta, toque sem achar a mureta, prévia do item sem aparecer, pendurar sem confirmação, mureta sem o revestimento da parede.
- **Reforma piso a piso (10 de 10 pegos):** pintar cobrando o revestimento inteiro, cobrando pisos que já tinham, sem nível, beleza ignorando a pintura, save esquecendo a pintura, pintar com a base sem apagar, reforma paga sem confirmação, toque achando qualquer trecho de parede, prévia sem aparecer, piso pintado sem aparecer.
- **Atendimento e andar (19 de 19 pegos):** cliente só pedindo do balcão, cardápio sem peso, fila que não anda, fila sem paciência, sem fila, garçom que não busca no fogão, garçom parado, dois garçons no mesmo prato, contratar sem cobrar, contratar sem nível, paciência igual com o prato no fogão, nível sem acelerar os clientes (refeito: a primeira versão do defeito nem compilava), porção que nunca chega ao pedido, save que esquece os garçons, contratar sem perguntar, bolinha de pedidos sumida, fila surgindo na porta, pernas paradas no andar, andar sem quique.
- **Coleções e encosto (9 de 9 pegos, mais 1 equivalente):** encosto nunca desenhado, encosto da cadeira errada, cena sem dizer em que cadeira o cliente sentou, loja ignorando a coleção, página sem cortar, aba nova mantendo a coleção, coleção nova sem voltar à página 1 (pego depois de fortalecer o teste: nenhuma coleção sozinha passa de uma página, e o limite escondia o defeito), coleções fora de ordem, móvel sem coleção. A mutação "encosto também de frente" não mudava nada, porque a arte só tem encosto nas rotações 1 e 2. A checagem redundante saiu do código.

## Roteiro de teste manual — Arte v3 (móveis e personagens)

Rode o jogo (F5) com o seu save ou um jogo novo e confira:

1. [ ] Todos os móveis aparecem com a arte nova, sem caixas coloridas.
2. [ ] Escolha um **Balcão** e aperte **Girar** 4 vezes: ele mostra os 4 lados. Virado para o fundo, aparece de costas.
3. [ ] Leve uma **Cadeira** para o lado de uma mesa: a prévia já vira para a mesa. Aperte **Girar** ali mesmo: ela gira e fica como você deixou.
4. [ ] Os clientes andam alternando os pés e viram para o lado em que andam (de frente ou de costas).
5. [ ] Sentados, olham para onde a cadeira aponta. Quem senta de costas aparece com o encosto na frente.
6. [ ] O balão mostra o desenho do prato. A barra vai de verde a amarelo e vermelho, e a cara do cliente acompanha.
7. [ ] Nenhum móvel cobre um balão.
8. [ ] Com o zoom máximo (roda do mouse ou pinça), a arte continua nítida.
9. [ ] Fora do salão há gramado, calçada, rua, cerquinha (aberta no caminho da entrada), canteiros e postes.
10. [ ] Na loja, aba **Piso** e aba **Parede**: cada revestimento troca a arte do salão inteiro, sem frestas entre os pisos.
11. [ ] Expanda a cafeteria: piso, paredes, calçada e cerca crescem junto.
12. [ ] Cozinhe algo: o fogão mostra a panela com vapor e o selo com o tempo; pronto, o selo fica verde ("Pronto!"). No balcão aparece a pilha de pratos com o número.
13. [ ] No alto: a moeda, a barra de XP com o nível, a beleza e o presente diário ("Receber!" ou o cronômetro).
14. [ ] Toque em **Loja**: o painel abre com as abas coloridas e os quadradinhos. Escolha a Mesa: a loja fecha e a mesa aparece para posicionar.
15. [ ] Toque no medalhão **MISSÕES**: o cartão some; toque de novo: volta. **CONQUISTAS** abre a lista.
16. [ ] Os botões azuis da direita aproximam e afastam a câmera e ligam e desligam o som.
17. [ ] Sensação: os personagens, o cenário e a interface parecem os das pranchas aprovadas? Algum tamanho ficou estranho? *(anote)*

## Roteiro de teste manual — Fogão Japonês (22/10)

1. [ ] Num fogão comum, abra a aba Japão do livro: os 4 pratos aparecem apagados, com "Só no Fogão Japonês".
2. [ ] No nível 11, compre o Fogão Japonês na aba Cozinha e toque nele: a aba Japão deixa cozinhar os 4 pratos.
3. [ ] Com o Fogão Japonês no café, espere os clientes: às vezes alguém pede Dango, Missô, Yakissoba ou Tempurá.

## Roteiro de teste manual — Fogões com perfil (22/10)

1. [ ] Abra a Loja na aba Cozinha e pare o mouse em cima de cada fogão: a dica diz a função dele.
2. [ ] Compre o Fogão de Cobre (nível 10): o cartão dele passa a dizer "Só 1 por café".
3. [ ] Toque no Fogão de Cobre livre: a barra diz "qualquer prato pronto em até 1h"; no livro, os pratos longos mostram 1:00:00.
4. [ ] Cozinhe um Café no Retrô Creme e tire o prato: o número que sobe mostra 7 porções em vez de 6.

## Roteiro de teste manual — Troféus (22/10)

1. [ ] No nível 6 ou mais, abra a Loja na aba Cozinha: o Troféu de Bronze está lá; pare o mouse em cima e leia a dica.
2. [ ] Compre e posicione o troféu: antes de confirmar, as 8 casas em volta aparecem em dourado no chão.
3. [ ] Ponha o troféu encostado num fogão (de lado ou na diagonal) e toque no fogão: o livro mostra os tempos 25% menores, e a barra diz "troféu: 25% mais rápido".
4. [ ] Toque no troféu: a barra diz quantos pratos ele ainda acelera; o Renovar está apagado.
5. [ ] Cozinhe até ele se gastar: aparece o aviso, e o troféu fica apagado.
6. [ ] Toque no troféu e em Renovar: aparece a pergunta com o preço, com Cancelar já escolhido; confirme e ele volta a brilhar.
7. [ ] Guarde um troféu meio gasto e ponha de volta: ele continua com as mesmas cargas.

## Roteiro de teste manual — Temperos (22/10)

1. [ ] Receba o presente diário até o dia 2: ele dá 1 Pimenta-Relâmpago.
2. [ ] Comece um prato demorado e toque no fogão: aparecem os cartões dos temperos, e a Pimenta diz "Você tem 1".
3. [ ] Toque na Pimenta: o tempo do prato cai 1 hora (ou fica pronto, se faltava menos), e o efeito sobe do fogão.
4. [ ] Toque num tempero que você não tem: aparece a pergunta de compra com o preço, com Cancelar já escolhido. Confirme: o ouro sai e o tempero é usado.
5. [ ] Use o Sal da Fartura: o fogão diz "com tempero" e quantas porções vai render; o cartão do Sal vira "Já temperado".
6. [ ] Deixe um prato estragar e toque no fogão: as Ervas Salva-Prato aparecem ao lado do Jogar fora; usadas, o prato volta a ficar pronto.
7. [ ] Abra as missões: as semanais que dão tempero mostram o tempero no prêmio.

## Roteiro de teste manual — Comida que estraga (22/10)

1. [ ] Com os balcões cheios (assim o garçom não tem onde pôr o prato), cozinhe um Café e não toque nele. Escolha o fogão: a barra diz "estraga em" e conta o tempo.
2. [ ] Espere 10 minutos: aparece o aviso de que o Café estragou, e o fogão fica com a panela verde, a fumaça verde e o selo "Estragou".
3. [ ] Toque no fogão: o prato não vai para o balcão; aparece o botão Jogar fora, com a lixeira.
4. [ ] Toque em Jogar fora: o fogão fica livre e o livro de receitas abre.
5. [ ] Comece um prato rápido, feche o jogo e abra uma hora depois: as boas-vindas dizem que 1 prato estragou.
6. [ ] Com um prato pronto, pause o jogo por um tempo: ele não estraga enquanto está pausado.

## Roteiro de teste manual — Receitas do nível 18 ao 30 (22/10)

1. [ ] Toque num fogão livre e abra a aba Brasil: aparecem 6 receitas e a seta da direita acesa.
2. [ ] Toque na seta: aparecem Bobó de Camarão, Picanha na Tábua e Churrasco Misto, com o nível que libera cada um.
3. [ ] Abra a aba Doces: Pudim de Leite, Torta de Limão e Floresta Negra estão no fim da fila.
4. [ ] Ao chegar no nível 18, aparece "Nova receita: Açaí na Tigela", e ele já pode ser cozinhado.
5. [ ] Cozinhe um prato de várias horas, feche o jogo e abra depois do tempo: o prato está pronto no fogão.

## Roteiro de teste manual — Livro de receitas e domínio (22/10)

1. [ ] Toque num fogão livre: o livro abre com as abas Básico, Brasil, Doces e Mundo.
2. [ ] Com um cliente esperando um prato de outra aba, toque no fogão: o livro já abre nessa aba, e ela tem uma bolinha vermelha.
3. [ ] Escolha a aba Doces, feche e toque no fogão de novo: ele volta na aba Doces.
4. [ ] Cozinhe o Café 5 vezes: aparece "Domínio de Café: estrela 1 de 3!" com o prêmio, e o cartão do Café ganha uma estrela acesa.
5. [ ] Pare o mouse em cima do cartão: a dica diz quantos pratos faltam para a próxima estrela.
6. [ ] Ao subir de nível (5, 7, 8...), aparece "Nova receita" com o prato novo, que já está no livro com o desenho dele.

## Roteiro de teste manual — Máquinas de bebida e energia (22/10)

1. [ ] No nível 2, abra a Loja, aba Cozinha, e compre a **Máquina de Café**. O contador de energia (raio) aparece embaixo do ouro.
2. [ ] Espere um cliente com o **balão de borda verde** (uma xícara). Toque nele: a bebida sai na hora, a energia cai e aparece "-1 energia". Depois de uns segundos ele paga.
3. [ ] Gaste toda a energia e toque em outro cliente de balão verde: a barra de baixo avisa "Sem energia".
4. [ ] Espere 1 minuto: a energia sobe 1 ponto. Toque no contador: aparece a explicação.
5. [ ] Feche o jogo por alguns minutos e abra de novo: a energia voltou.
6. [ ] Venda a máquina com um cliente esperando bebida: ele vai embora sem baixar a popularidade.

## Roteiro de teste manual — Placa ABERTO/FECHADO (22/10)

1. [ ] Com clientes na fila da calçada, toque no botão vermelho da porta (abaixo da pausa) ou aperte F: a fila vai embora, a faixa "CAFÉ FECHADO" aparece e a plaquinha da porta diz FECHADO.
2. [ ] Fechado, espere: ninguém novo entra, e quem estava dentro come, paga e sai. A popularidade não cai.
3. [ ] Feche o jogo com o café fechado e abra de novo: ele continua fechado.
4. [ ] Toque no botão verde: em poucos segundos chega um cliente.

## Roteiro de teste manual — Pausa sem bloqueio e balcão de 1 piso (22/10)

1. [ ] Pause com o café cheio e mova a cadeira de um cliente sentado para outro lado da mesa: ele vai junto.
2. [ ] Pausado, guarde ou venda uma mesa ocupada: os clientes dela vão embora sem baixar a popularidade (ao continuar).
3. [ ] Pausado, ponha um móvel onde um garçom está parado: ele aparece no piso livre do lado.
4. [ ] Todos os balcões ocupam só 1 piso.
5. [ ] Na aba Cozinha da Loja há 8 fogões e 8 balcões.

## Roteiro de teste manual — Pausa e loja aberta (22/10)

1. [ ] Toque no botão laranja de pausa (ou aperte P): aparece "JOGO PAUSADO", e clientes, garçons, carros e vapor param.
2. [ ] Pausado, compre e ponha mesas, cadeiras, um fogão e um balcão: tudo funciona sem a pausa sair.
3. [ ] Comece a cozinhar com o jogo pausado: o tempo do fogão só anda depois de continuar.
4. [ ] Toque no botão verde (ou P de novo): tudo volta a andar de onde parou.
5. [ ] Na loja, compre uma mesa e posicione: a loja volta sozinha, na mesma aba, pronta para a cadeira.

## Roteiro de teste manual — A cidade em volta do café (21/10)

1. [ ] Afaste o zoom: o café fica numa esquina, com duas ruas, calçadas, prédios atrás e um parque do outro lado.
2. [ ] Os táxis e carros andam nas ruas e param no semáforo vermelho antes da faixa de pedestre.
3. [ ] Os bueiros soltam vapor.
4. [ ] Arraste a câmera: dá para passear pela rua em volta do café.
5. [ ] Os clientes chegando, na fila e indo embora nunca ficam escondidos atrás de um poste ou árvore que está atrás deles.
6. [ ] Expanda o café: as ruas, as calçadas e os prédios acompanham.

## Roteiro de teste manual — Missões diárias e semanais (21/10)

1. [ ] O medalhão **MISSÕES** abre a janela com as abas Diárias (10), Semanais (20) e Começo (enquanto o tutorial não acabou).
2. [ ] Receba o presente do dia: aparece "Missão diária concluída: Receba o presente diário" e o ouro entra.
3. [ ] Cozinhe e sirva um pouco: o progresso das diárias e das semanais anda.
4. [ ] "Cozinhe 8 pratos demorados" aparece com o cadeado até o nível 3.
5. [ ] No dia seguinte, as diárias começam do zero; as semanais só recomeçam na segunda.
6. [ ] Tocar no cartão "Missão 1 de 6" esconde o cartão; abrir as missões mostra de novo.

## Roteiro de teste manual — Nível 30 (21/10)

1. [ ] O seu nível e o XP continuam os mesmos depois de atualizar o jogo.
2. [ ] Ao chegar no nível 11, o aviso mostra "Nível 11! +275 de Café Ouro" e o ouro entra.
3. [ ] O botão Expandir continua oferecendo expansões depois do 12×12 (a próxima é 14×12, no nível 10).
4. [ ] O botão Garçom oferece o 5º garçom no nível 12.

## Roteiro de teste manual — Sentar e ordem de desenho (21/10)

1. [ ] Os clientes sentados de frente aparecem sentados: coxa no assento, joelho dobrado, canela pendurada. Confira na banqueta e em cadeiras de coleções diferentes.
2. [ ] O garçom passando na frente de um balcão de 2 pisos aparece **na frente** dele, nas duas metades, sem silhueta azul.
3. [ ] Ponha um vaso ou planta na frente de um balcão: o vaso aparece na frente.
4. [ ] Só quem passa **atrás** de um móvel alto ganha a silhueta azul.

## Roteiro de teste manual — Passe visual (efeitos)

1. [ ] Toque num móvel: ele ganha um brilho laranja que pulsa em volta. Toque no chão vazio: o brilho some.
2. [ ] Cozinhe algo: sai vapor da panela. Quando ficar pronto, o fogão brilha em dourado.
3. [ ] Leve o prato ao balcão: a pilha cai no tampo com um quique e solta vapor.
4. [ ] Compre um móvel e confirme: ele surge crescendo do chão.
5. [ ] Quando um cliente pagar: confete dourado sobe da mesa e cai, e o número do ouro quica.
6. [ ] Quando alguém passar atrás do balcão ou de um fogão, aparece a silhueta azul dele por cima do móvel.
7. [ ] Quando alguém passar junto da mureta da frente, ela fica transparente ali.
8. [ ] Afaste o zoom ao máximo: a arte continua suave, sem serrilhado nem chuvisco.
9. [ ] Sensação: os efeitos ajudam ou distraem? Algum está forte ou fraco demais? *(anote)*

## Roteiro de teste manual — Mais móveis e compra de moedas (etapas 5 e 6)

1. [ ] Na loja, cada coleção tem duas cadeiras e duas mesas (ex.: Anos 70: Cadeira Ovo e Cadeira Tulipa, Mesa Tulipa e Mesa de Fórmica).
2. [ ] Na aba **Cozinha** há fogões e balcões novos (retrô menta, inox, preto e dourado; madeira, confeitaria, inox). Cozinhe num fogão novo: a panela e o forno aceso aparecem no lugar certo.
3. [ ] O **+** verde ao lado do ouro abre a vitrine com 5 pacotes e os preços em reais.
4. [ ] Tocar num pacote mostra que a compra só existe na Play Store e que nada foi cobrado; o ouro não muda.
5. [ ] Tente comprar algo sem ouro: a vitrine aparece sozinha ("Faltou Café Ouro?"), mas não fica reaparecendo a cada toque.

## Roteiro de teste manual — Paredes completas e itens de parede (etapa 4)

1. [ ] A cafeteria tem mureta nas duas bordas da frente, com o mesmo revestimento da parede, baixa: dá para ver todo o salão.
2. [ ] Na entrada há uma porta com toldo listrado e a plaquinha "ABERTO"; os clientes entram e saem por ela.
3. [ ] Na reforma de parede, a mureta também pode ser pintada trecho a trecho.
4. [ ] Na aba **Paredes**, depois dos revestimentos, aparecem os itens: janelas, quadros, relógio, prateleira, TV, rádio, lousa, neon, espelho, planta pendurada e janelão.
5. [ ] Escolha a TV, toque num trecho da parede do fundo, confirme: ela aparece lá e o que estava antes sai. O cartão **Tirar enfeite** tira de graça.
6. [ ] Seu save continua com as janelas, quadros e relógio de antes.

## Roteiro de teste manual — Reforma piso a piso (etapa 3)

1. [ ] Na loja, aba **Pisos**: o preço aparece por piso (ex.: "6/piso"). Toque num piso: a loja sai e entra a reforma.
2. [ ] Toque em alguns pisos: eles ficam com contorno amarelo e já mostram o piso novo. Tocar de novo desmarca. A barra mostra quantos e quanto custa.
3. [ ] **Tudo** marca o piso inteiro; **Limpar** desmarca; **Cancelar** sai sem mudar nada.
4. [ ] **Confirmar** pergunta antes de cobrar (Cancelar já selecionado). Depois, só os pisos marcados mudam; dá para misturar dois pisos.
5. [ ] Na aba **Paredes**, o mesmo com os trechos de parede (cada trecho tem a largura de um piso).
6. [ ] Revestimentos que você já tinha comprado inteiros pintam de graça.

## Roteiro de teste manual — Atendimento e andar (etapas 1 e 2 do pacote de 12/10)

1. [ ] Os clientes às vezes pedem um prato que não está no balcão. O balão mostra o prato, e no painel do fogão a receita pedida ganha uma bolinha vermelha com quantos esperam.
2. [ ] Cozinhe o prato pedido: enquanto está no fogão, a barra de paciência do cliente desce mais devagar. Quando fica pronto, o garçom busca sozinho e leva ao balcão; depois serve o cliente.
3. [ ] O garçom nunca começa a cozinhar sozinho. Sem tarefa, ele anda entre fogões e balcões (não fica na porta).
4. [ ] Com todas as cadeiras ocupadas, os clientes novos fazem fila na calçada, de frente para a porta. Quem espera demais vai embora e a popularidade cai.
5. [ ] A cada nível chegam clientes mais rápido.
6. [ ] O botão **Garçom** na faixa de baixo mostra o nível que libera (3) e depois o preço. Contratar pede confirmação; o garçom novo entra pela porta.
7. [ ] O andar: as pernas dobram o joelho, o pé sobe e volta, e o corpo não balança de um lado para o outro. Ficou natural? *(anote)*

## Roteiro de teste manual — Movimento, música e coleções

Rode o jogo com o seu save ou um jogo novo e confira:

1. [ ] Os clientes chegam andando pela calçada, sem surgir do nada na porta. Ao ir embora, voltam para a calçada e somem aos poucos.
2. [ ] Andando, eles alternam os pés, com um leve quique, e fazem as curvas arredondadas, sem virar em ângulo reto. Parados, respiram de leve.
3. [ ] O cliente só senta quando chega na cadeira; ao levantar, dá um passinho, sem pular.
4. [ ] Toca uma bossa nova baixinha, sem voz. O botão da nota musical (à direita) liga e desliga só a música; o do alto-falante, só os efeitos.
5. [ ] Feche e abra o jogo: as escolhas de som e de música continuam as mesmas.
6. [ ] Toque em **Loja**: no alto aparece a fileira de coleções (Todas, Clássico, Anos 70, Country, Festa, Americano, Mexicano, Anos 80, Italiano, Japonês, Francês, Brasileiro, Anos 2010, Balada).
7. [ ] Toque numa coleção: só os itens dela aparecem, e o botão dela fica pintado. "Todas" volta a mostrar tudo.
8. [ ] As setas da direita e da esquerda trocam de página, e o número (ex.: "1/5") acompanha.
9. [ ] Itens de nível mais alto aparecem com cadeado e o nível em que liberam.
10. [ ] Compre uma cadeira e uma mesa de uma coleção. Quando um cliente sentar de costas, o encosto que aparece por cima dele é o da cadeira dele (não o da cadeira clássica). A banqueta do Americano não tem encosto.
11. [ ] Nas abas **Pisos** e **Paredes**, aplique o revestimento de uma coleção: o salão inteiro troca, sem frestas entre os pisos nem entre as paredes.
12. [ ] Sensação: alguma coleção ficou estranha ou parecida demais com outra? Faltou algum estilo ou cultura? *(anote)*

## Roteiro de teste manual — Fase 1

Rode o jogo (F5) e confira:

1. [ ] O jogo abre sem janela de erro. O piso quadriculado aparece centralizado.
2. [ ] Clicar num piso destaca **aquele** piso, e o painel mostra as coordenadas dele.
3. [ ] Clicar fora do piso tira o destaque.
4. [ ] Arrastar com o botão esquerdo move a visão **e não** seleciona nada ao soltar.
5. [ ] A roda do mouse aproxima e afasta. O ponto sob o cursor fica parado enquanto o zoom muda.
6. [ ] Não é possível arrastar a cafeteria para fora da tela.
7. [ ] Ao redimensionar a janela (ou maximizar), o piso continua visível e o painel continua legível.
8. [ ] Na barra de baixo, clique em **Fogão**. Passe o mouse pelo piso: a prévia segue o cursor, verde onde pode.
9. [ ] Clique num piso verde: o fogão aparece e a barra volta a mostrar o catálogo.
10. [ ] Escolha **Balcão**, aperte **R** (ou **Girar**) e veja ele trocar de direção antes de posicionar.
11. [ ] Tente pôr algo no piso azul da entrada: prévia vermelha e a barra diz que a entrada precisa ficar livre.
12. [ ] Coloque uma **Mesa** num canto e cerque os dois lados com **Planta**s: a segunda planta é recusada ("deixaria outro móvel sem acesso").
13. [ ] Clique num móvel: ele ganha contorno laranja e a barra mostra Mover/Girar/Guardar/Fechar. Teste **Mover** (o original some e reaparece no novo lugar) e **Guardar**.
14. [ ] Esc cancela a construção sem deixar nada no piso.
15. [ ] Sensação: arrasto, zoom e posicionamento são confortáveis? Rápidos ou lentos demais? Algo confuso? *(anote para ajuste)*

## Roteiro de teste manual — Fase 2

Rode o jogo (F5). O jogo novo já vem com 2 fogões, 2 balcões, 2 mesas com cadeiras e uma planta.

1. [ ] O painel de cima mostra Nível 1, barra de XP, Café Ouro: 200 e Popularidade: 50%.
2. [ ] Toque no fogão da esquerda: aparecem as receitas. Café e Pão de queijo liberados; as outras mostram "Nível N".
3. [ ] Escolha **Café**: o ouro cai 6, aparece "-6" sobre o fogão, e a etiqueta mostra o tempo correndo.
4. [ ] Tente **Guardar** o fogão enquanto cozinha: a barra explica que está em uso.
5. [ ] Em ~15 s a etiqueta fica verde ("Café pronto!"). Toque no fogão: sobem "+6 Café" e "+2 XP", e o balcão mostra "Café ×6".
6. [ ] Clientes entram pela seta azul, sentam e mostram um balão com o desenho do pedido e uma barrinha de paciência.
7. [ ] O garçom busca no balcão (o prato aparece na bandeja dele) e leva à mesa. O prato fica na mesa enquanto o cliente come, sobe "+3" dourado, e ele vai embora com uma carinha verde.
8. [ ] Deixe um cliente sem comida: a barrinha fica amarela e depois vermelha, a cara dele muda, ele vai embora com uma carinha vermelha e a popularidade cai.
9. [ ] Cozinhe Café num fogão e Pão de queijo no outro: cada um vai para um balcão.
10. [ ] Ao juntar 30 XP aparece "Nível 2! Nova receita: Misto-quente", e o botão dela é liberado.
11. [ ] Tente pôr uma Planta no piso onde alguém está passando: a barra diz "Tem alguém passando aí".
12. [ ] Mova uma mesa vazia no meio do movimento dos personagens: eles desviam e continuam.
13. [ ] **Sensação (a pergunta mais importante):** dá vontade de continuar jogando? Esperar é chato ou gostoso? O garçom é rápido demais ou lento? *(anote para o balanceamento)*

## Roteiro de teste manual — Save

1. [ ] Jogue um pouco: ponha um móvel, cozinhe algo demorado (Pão de queijo, 40 s) e junte ouro.
2. [ ] Feche a janela do jogo **enquanto o Pão de queijo cozinha**.
3. [ ] Espere mais de 40 s e rode de novo (F5): os móveis, o ouro e o nível estão iguais, o fogão mostra "Pão de queijo pronto!" e aparece "Bem-vindo de volta! 1 prato ficou pronto enquanto você estava fora."
4. [ ] Toque em **Recomeçar** e depois em **Cancelar**: nada muda.
5. [ ] Toque em **Recomeçar** e depois em **Apagar e recomeçar**: o jogo volta ao começo (Nível 1, 200 de ouro, móveis iniciais).

## Roteiro de teste manual — Novidades (paredes, conquistas, diária, sons)

1. [ ] Jogo novo: pergunta o nome da cafeteria. Digite um nome e toque em **Abrir as portas**. O nome aparece no topo, e em seguida vem a **Recompensa diária** (Dia 1: 50 ouro).
2. [ ] Toque em **Receber**: o ouro sobe 50, com aviso e som.
3. [ ] Na loja, aba **Parede** → **Tijolinho** (120). Aparece a pergunta com Cancelar selecionado. Compre: a parede muda e a **Beleza** no topo sobe 10.
4. [ ] Volte para **Parede creme** (é grátis e não pergunta) e depois para Tijolinho de novo (também grátis).
5. [ ] Aba **Decoração** → **Vaso de flores**: posicione e veja a Beleza subir.
6. [ ] Selecione uma mesa → **Vender**: a pergunta mostra o valor (metade do preço). Venda. Depois tente vender um fogão até sobrar um só: o último é recusado, com explicação.
7. [ ] Toque em **Conquistas**: a lista mostra o progresso. Ao servir o primeiro cliente, aparece "Conquista: Primeiro Cliente! +10 ouro".
8. [ ] Toque em **Som: ligado** para desligar. Feche e abra o jogo: o som continua desligado.
9. [ ] Toque no nome da cafeteria no topo e troque o nome.
10. [ ] **Sensação:** os sons agradam ou incomodam? A beleza faz você querer decorar?

## Roteiro de teste manual — Android (o `.apk`)

1. [ ] Instale seguindo o README ("Jogar no celular Android").
2. [ ] O ícone do café aparece na lista de apps. O jogo abre deitado (paisagem).
3. [ ] Um dedo arrasta a visão; dois dedos (pinça) dão zoom; toque rápido seleciona.
4. [ ] Todos os botões respondem ao toque, inclusive os das janelas (Receber, Comprar, Cancelar).
5. [ ] O teclado do celular aparece ao digitar o nome da cafeteria.
6. [ ] Minimize o jogo (botão de início), espere e volte: tudo continua igual. Feche pelo botão "voltar" e abra de novo: o progresso está lá.
7. [ ] Os textos e botões têm tamanho confortável para o dedo? Algo fica pequeno demais?
8. [ ] O celular esquenta ou a bateria cai rápido em 10 minutos de jogo? *(anote o modelo do aparelho)*

## Roteiro de teste manual — Vertical Slice (o `.exe`)

Abra o `CafeManie.exe` (instruções no README) e siga o cartão de missão no canto direito:

1. [ ] O cartão mostra "Missão 1/6: Prepare 3 pratos (0/3)" e uma dica. A barra de baixo mostra a loja com preços.
2. [ ] Cozinhe e leve 3 pratos ao balcão: aparece "Missão concluída… +30 ouro +5 XP", e o cartão passa para a missão 2.
3. [ ] Siga as missões 2 e 3 (servir e ganhar ouro).
4. [ ] Missão 4: toque em **Mesa** na loja. A barra diz "Posicionando: Mesa (60 ouro)". Posicione: o ouro cai 60 e sobe "-60".
5. [ ] Selecione a mesa nova e toque em **Guardar**: ela some e o botão da loja mostra "1 guardado". Posicione de novo: não cobra.
6. [ ] Missão 6: toque em **Expandir**. Aparece a pergunta com o preço e **Cancelar** já selecionado. Cancele: nada muda. Expanda: o piso cresce e a entrada vai para a nova borda.
7. [ ] Feche o jogo e abra de novo: missão, inventário e tamanho da cafeteria continuam iguais.
8. [ ] **Sensação:** as dicas bastam para entender o jogo sem ajuda? Algum passo ficou confuso? Os preços parecem justos?

Os itens de toque (pinça, arrasto com dedo) serão conferidos no celular quando houver build Android.

## Bug report

Use o formato da seção 88 do master prompt. Severidades: `BLOCKER`, `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`.
