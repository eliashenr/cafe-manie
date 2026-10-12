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

## Cobertura atual — 353 testes

| Arquivo | Testes | O que garante |
|---|---|---|
| `unit/test_cafe_grid.gd` | 10 | limites, ocupação, colisão, expansão segura |
| `unit/test_iso_projection.gd` | 8 | clique cai no piso certo, inclusive nas bordas; posições fracionárias dos personagens; vértices fracionários (calçada, cerca) |
| `unit/test_furniture_catalog.gd` | 7 | dados de móveis válidos (57 móveis); recusa de dados ruins; todo móvel e revestimento numa coleção conhecida, e cada coleção com cadeira, mesa, enfeite, piso e parede |
| `unit/test_collection_catalog.gd` | 2 | coleções na ordem da loja, começando pelo Clássico, cada uma com nome e cor próprios; recusa de dados ruins |
| `unit/test_cafe_layout.gd` | 20 | regras de posicionamento, entrada, acesso, mover/girar/remover sem efeito colateral; para onde a frente aponta; assento vira para a mesa |
| `unit/test_placement_session.gd` | 9 | modo de construção só muda o layout ao confirmar; cadeira levada para o lado da mesa vira para ela |
| `unit/test_content_data.gd` | 10 | receitas, clientes, níveis e jogo novo: válidos, lucrativos, layout inicial legal, um balcão por fogão |
| `unit/test_wallet.gd` | 7 | ganhos, gastos, recusas, registro com limite |
| `unit/test_progression.gd` | 7 | curva de níveis, subir vários níveis de uma vez, nível máximo |
| `unit/test_kitchen.gd` | 10 | preparo pelo relógio (inclusive com o jogo fechado), coleta, empilhamento, capacidade, reserva e devolução |
| `unit/test_cafe_simulation.gd` | 30 | loop completo cliente → garçom → pagamento; paciência; porção devolvida; assentos; móvel em uso; personagem no caminho; recálculo de rota; desbloqueio por nível; determinismo; **pedido do cardápio fora do balcão** (com o que falta cozinhar), café sai mais que lasanha, paciência mais calma com o prato no fogão; **fila na calçada** (enche, anda, desiste); mais clientes por nível; **garçom busca no fogão, circula pela cozinha e nunca cozinha**; dois garçons não disputam o mesmo prato; contratação (nível, ouro, limite) |
| `unit/test_long_shift.gd` | 2 | 30 min simulados com o "jogador robô" (que cozinha o que os clientes pedem): ninguém preso, lucro, níveis, menos de 25% irritados à mesa (desistências da fila contadas à parte); o robô conclui as 6 missões iniciais |
| `unit/test_save_codec.gd` | 17 | ida e volta por JSON de tudo o que é salvo; preparo continua com o jogo fechado; conteúdo desconhecido pulado; migração das versões 1 a 4; nome da cafeteria; cadeiras de save antigo viram para a mesa uma vez; garçons contratados (saves antigos ficam com 1) |
| `integration/test_staff_and_queue.gd` | 3 | botão Garçom (nível, preço, confirmação com Cancelar selecionado, garçom novo aparece); fila na calçada e quem desiste sai andando por ela; bolinha de pedidos no painel do fogão |
| `unit/test_save_service.gd` | 7 | primeiro acesso, gravar e ler, `.bak`, save danificado, save de versão mais nova protegido, apagar |
| `unit/test_shop_and_missions.gd` | 21 | compra, inventário, expansão, missões; **venda** (metade do preço, em uso, último fogão/balcão) |
| `unit/test_style_and_beauty.gd` | 24 | revestimentos (um inicial por tipo, bloqueios); **pintura por célula** (cobra só o que muda, recusa sem mudar nada, pintar com a base apaga); beleza pela média das células e dos itens de parede; **itens de parede** (dados, enfeites de sempre no jogo novo, pendurar cobra por trecho, tirar é grátis, bloqueio); mureta pintável sem a porta; save da pintura e dos itens, migração das versões 5 e 6 |
| `unit/test_coin_shop.gd` | 4 | pacotes de Café Ouro válidos e em ordem, taxa melhor nos maiores; este build nunca entrega ouro; ouro só com o pagamento confirmado (cancelado ou recusado não muda nada) |
| `unit/test_achievements.gd` | 9 | dados válidos e progressivos; paga uma vez; vários degraus de uma vez; contadores seguem o jogo; save não paga de novo; save antigo recebe o que merecia |
| `unit/test_daily_rewards.gd` | 11 | sequência e volta ao início; uma vez por dia; perder um dia; relógio para trás; meia-noite local; ouro, XP, móvel e revestimento; save |
| `unit/test_sound_synth.gd` | 4 | todos os sons existem e são curtos; duração certa; sem estourar volume; sem estalo |
| `integration/test_save_scene.gd` | 8 | fechar e reabrir com tudo no lugar, pratos prontos com o jogo fechado, salvamento automático, minimizar salva, Recomeçar com confirmação |
| `integration/test_cafe_scene.gd` | 11 | câmera, seleção, arrasto, zoom, pinça, enquadramento (com as paredes) |
| `integration/test_build_mode.gd` | 14 | construir, recusar com motivo, mover, girar, guardar, teclado, abas da loja |
| `integration/test_service_scene.gd` | 11 | jogo novo, HUD, painel do fogão, coleta por toque, personagens, aviso de nível, textos flutuantes |
| `integration/test_shop_scene.gd` | 15 | loja, compra, Guardar, expansão com confirmação, missões; **Vender com confirmação** e recusa do último fogão; filtro por coleção e páginas |
| `integration/test_style_scene.gd` | 12 | abas, piso e parede desenhados; **reforma**: escolher abre o modo, toques marcam, prévia, preço por piso, confirmação, trecho de parede e da mureta, Tudo e Cancelar, comprado antes pinta de graça; **pendurar a TV** com confirmação; tirar enfeite de graça; bloqueio; Beleza no HUD; paredes crescem com a expansão |
| `integration/test_coin_shop_scene.gd` | 3 | o "+" do ouro abre a vitrine com os 5 pacotes; neste build a compra explica que ainda não existe e não dá ouro; com pagamento confirmado o ouro entra; faltando ouro, a vitrine aparece uma vez (sem insistir) |
| `integration/test_progress_scene.gd` | 17 | avisos de conquista em fila, painel de conquistas, recompensa diária (abre, paga, volta no dia seguinte, não empilha janelas), nome da cafeteria, sons e botão de som |
| `integration/test_touch_ui.gd` | 3 | botões da loja e das janelas respondem a **toque de verdade**; toque no botão não vaza para o piso |
| `integration/test_furniture_art.gd` | 7 | todo móvel tem arte nas 4 rotações, com âncora e escala certas; a cena e a prévia usam a arte; panela de cada receita; forno aceso só de frente; fogão e balcão mostram receita, tempo, Pronto! e porções |
| `integration/test_hud_art.gd` | 6 | moeda com ponto de milhar e nível; estrelas pela satisfação; presente com cronômetro; zoom pelos botões; medalhão de missões esconde e mostra; faixa de ícones abre a loja e as conquistas |
| `integration/test_scene_art.gd` | 6 | todo revestimento tem arte; xadrez alterna; variações estáveis; todo item de parede tem desenho nas duas paredes e a porta existe; a cena usa a arte e enquadra a parede; **mureta** nas duas bordas da frente, baixa, sem fechar a porta; exterior acompanha a expansão |
| `integration/test_character_art.gd` | 15 | todo cliente e o garçom têm todas as poses; toda receita tem prato; direção e espelho; ciclo de 8 quadros do andar, que nunca para no meio do passo, com o corpo subindo e descendo de leve; saltos das regras viram passinhos; senta só quando chega na cadeira; chega e sai pela calçada; sentado segue a cadeira; **encosto da própria cadeira por cima de quem senta de costas**; expressão segue a paciência; bandeja; prato na mesa certa; balão por cima |
| `integration/test_music.gd` | 3 | a música toca baixinho e em loop; o botão dela liga e desliga, e o aparelho lembra; som dos efeitos e música são separados |

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
