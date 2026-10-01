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

## Cobertura atual — 284 testes

| Arquivo | Testes | O que garante |
|---|---|---|
| `unit/test_cafe_grid.gd` | 10 | limites, ocupação, colisão, expansão segura |
| `unit/test_iso_projection.gd` | 7 | clique cai no piso certo, inclusive nas bordas; posições fracionárias dos personagens |
| `unit/test_furniture_catalog.gd` | 6 | dados de móveis válidos (9 móveis); recusa de dados ruins |
| `unit/test_cafe_layout.gd` | 20 | regras de posicionamento, entrada, acesso, mover/girar/remover sem efeito colateral; para onde a frente aponta; assento vira para a mesa |
| `unit/test_placement_session.gd` | 9 | modo de construção só muda o layout ao confirmar; cadeira levada para o lado da mesa vira para ela |
| `unit/test_content_data.gd` | 10 | receitas, clientes, níveis e jogo novo: válidos, lucrativos, layout inicial legal, um balcão por fogão |
| `unit/test_wallet.gd` | 7 | ganhos, gastos, recusas, registro com limite |
| `unit/test_progression.gd` | 7 | curva de níveis, subir vários níveis de uma vez, nível máximo |
| `unit/test_kitchen.gd` | 10 | preparo pelo relógio (inclusive com o jogo fechado), coleta, empilhamento, capacidade, reserva e devolução |
| `unit/test_cafe_simulation.gd` | 17 | loop completo cliente → garçom → pagamento; paciência; porção devolvida; assentos; móvel em uso; personagem no caminho; recálculo de rota; desbloqueio por nível; determinismo |
| `unit/test_long_shift.gd` | 2 | 30 min simulados com o "jogador robô": ninguém preso, lucro, níveis; o robô conclui as 6 missões iniciais |
| `unit/test_save_codec.gd` | 16 | ida e volta por JSON de tudo o que é salvo; preparo continua com o jogo fechado; conteúdo desconhecido pulado; migração das versões 1, 2 e 3; nome da cafeteria; cadeiras de save antigo viram para a mesa uma vez |
| `unit/test_save_service.gd` | 7 | primeiro acesso, gravar e ler, `.bak`, save danificado, save de versão mais nova protegido, apagar |
| `unit/test_shop_and_missions.gd` | 21 | compra, inventário, expansão, missões; **venda** (metade do preço, em uso, último fogão/balcão) |
| `unit/test_style_and_beauty.gd` | 11 | revestimentos (um inicial por tipo, compra única, troca grátis, bloqueios); beleza soma móveis e revestimentos; beleza aumenta a paciência; save e migração |
| `unit/test_achievements.gd` | 9 | dados válidos e progressivos; paga uma vez; vários degraus de uma vez; contadores seguem o jogo; save não paga de novo; save antigo recebe o que merecia |
| `unit/test_daily_rewards.gd` | 10 | sequência e volta ao início; uma vez por dia; perder um dia; relógio para trás; meia-noite local; ouro, XP, móvel e revestimento; save |
| `unit/test_sound_synth.gd` | 4 | todos os sons existem e são curtos; duração certa; sem estourar volume; sem estalo |
| `integration/test_save_scene.gd` | 8 | fechar e reabrir com tudo no lugar, pratos prontos com o jogo fechado, salvamento automático, minimizar salva, Recomeçar com confirmação |
| `integration/test_cafe_scene.gd` | 11 | câmera, seleção, arrasto, zoom, pinça, enquadramento (com as paredes) |
| `integration/test_build_mode.gd` | 14 | construir, recusar com motivo, mover, girar, guardar, teclado, abas da loja |
| `integration/test_service_scene.gd` | 11 | jogo novo, HUD, painel do fogão, coleta por toque, personagens, aviso de nível, textos flutuantes |
| `integration/test_shop_scene.gd` | 13 | loja, compra, Guardar, expansão com confirmação, missões; **Vender com confirmação** e recusa do último fogão |
| `integration/test_style_scene.gd` | 8 | abas, piso e parede desenhados, compra com confirmação, troca sem perguntar, bloqueio, Beleza no HUD, paredes crescem com a expansão |
| `integration/test_progress_scene.gd` | 17 | avisos de conquista em fila, painel de conquistas, recompensa diária (abre, paga, volta no dia seguinte, não empilha janelas), nome da cafeteria, sons e botão de som |
| `integration/test_touch_ui.gd` | 3 | botões da loja e das janelas respondem a **toque de verdade**; toque no botão não vaza para o piso |
| `integration/test_furniture_art.gd` | 5 | todo móvel tem arte nas 4 rotações, com âncora e escala certas; a cena e a prévia usam a arte |
| `integration/test_character_art.gd` | 11 | todo cliente e o garçom têm todas as poses; toda receita tem prato; direção e espelho; passos alternados; sentado segue a cadeira; expressão segue a paciência; bandeja; prato na mesa certa; balão por cima |

O executor também **reprova um arquivo de teste que nem compila**. Antes, ele sumia da contagem em silêncio (encontrado nesta etapa).

### Verificação dos próprios testes

Para garantir que a suíte pega defeitos de verdade, bugs são inseridos de propósito, um de cada vez, e os testes precisam reprovar:

- **Fase 1 (5 de 5 pegos):** segundo toque não confirma, sem checagem de acesso, entrada liberada, móvel movido continua visível, Confirmar sempre habilitado.
- **Save (8 de 9 pegos, mais 1 equivalente):** preparo não salvo, porções reservadas perdidas, ids reiniciados após carregar (pego depois de fortalecer o teste; ver DT-015), `.bak` nunca usado, save mais novo sobrescrito, salvamento automático desligado, minimizar não salva, Recomeçar mantém o save. A mutação "sem precisão total no JSON" não muda nada observável: a precisão padrão já basta (erro < 1 ms).
- **Paredes, beleza, venda, conquistas, recompensa diária e sons (20 de 20 pegos):** revestimento de graça, beleza ignorando revestimentos, piso sem atualizar, beleza sem efeito na paciência, revestimento não salvo, venda do último fogão, venda sem confirmação, guardados ignorados na venda, conquista de um degrau por vez, conquistas não restauradas, aviso apagando outro, clientes não contados (pego depois de um teste novo), relógio para trás liberando prêmio, sequência sem reinício, dia em UTC em vez do local, sequência não salva, recusa sem som, som desligado não lembrado, nota sem entrada suave, prato pronto sem som.
- **Loja, expansão e missões (5 de 5 pegos):** móvel novo posicionado de graça, inventário sem salvamento automático, piso não acompanha a expansão, expansão sem confirmação, Guardar destruindo o móvel.
- **Fase 2 (7 de 7 pegos):** paciência nunca acaba, garçom não serve, cozinhar dá ouro em vez de cobrar, cadeira ocupada desprotegida, personagens ignoram mudança de layout, porção reservada se perde, comida pronta na hora.
- **Arte v3 dos móveis e personagens (13 de 13 pegos):** sentado ignora a cadeira, andar sem trocar de pé, espelho trocado, expressão sem paciência, balão sem camada de cima, garçom sem bandeja, prato fica na mesa depois que o cliente sai, prato fora do lado da cadeira, cadeira não vira no modo de construção, save antigo não vira as cadeiras, save atual também vira, assento entre duas mesas troca de lado, móvel ignora a rotação.

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
9. [ ] Sensação: os personagens parecem os das pranchas aprovadas? Algum tamanho ficou estranho (gente grande ou pequena demais perto dos móveis)? *(anote)*

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
