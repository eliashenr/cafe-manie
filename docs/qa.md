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

## Cobertura atual — 191 testes

| Arquivo | Testes | O que garante |
|---|---|---|
| `unit/test_cafe_grid.gd` | 10 | limites, ocupação, colisão, expansão segura |
| `unit/test_iso_projection.gd` | 7 | clique cai no piso certo, inclusive nas bordas; posições fracionárias dos personagens |
| `unit/test_furniture_catalog.gd` | 6 | dados de móveis válidos; recusa de dados ruins |
| `unit/test_cafe_layout.gd` | 16 | regras de posicionamento, entrada, acesso, mover/girar/remover sem efeito colateral |
| `unit/test_placement_session.gd` | 7 | modo de construção só muda o layout ao confirmar |
| `unit/test_content_data.gd` | 10 | receitas, clientes, níveis e jogo novo: válidos, lucrativos, layout inicial legal, um balcão por fogão |
| `unit/test_wallet.gd` | 7 | ganhos, gastos, recusas, registro com limite |
| `unit/test_progression.gd` | 7 | curva de níveis, subir vários níveis de uma vez, nível máximo |
| `unit/test_kitchen.gd` | 10 | preparo pelo relógio (inclusive com o jogo fechado), coleta, empilhamento, capacidade, reserva e devolução |
| `unit/test_cafe_simulation.gd` | 17 | loop completo cliente → garçom → pagamento; paciência; porção devolvida; assentos; móvel em uso; personagem no caminho; recálculo de rota; desbloqueio por nível; determinismo |
| `unit/test_long_shift.gd` | 2 | 30 min simulados com o jogo novo real e um "jogador robô": ninguém preso, sem erros, lucro, níveis; o robô conclui as 6 missões iniciais (a Vertical Slice inteira) |
| `unit/test_save_codec.gd` | 13 | ida e volta por JSON de layout, ids, ouro, XP, popularidade, inventário e missões; preparo continua com o jogo fechado; tempo exato; porções reservadas voltam; conteúdo desconhecido pulado; migração da versão 1 |
| `unit/test_shop_and_missions.gd` | 17 | compra cobra só quando posiciona; nível e ouro; guardar e recolocar grátis; móvel em uso não é guardado; expansão (nível, ouro, entrada, garçom, acesso, tamanho máximo); missões em ordem, recompensas, categoria certa, nível já cumprido |
| `unit/test_save_service.gd` | 7 | primeiro acesso, gravar e ler, cópia de segurança, save danificado recupera o `.bak`, tudo danificado recomeça sem apagar arquivos, save de versão mais nova protegido, apagar |
| `integration/test_save_scene.gd` | 8 | fechar e reabrir com tudo no lugar, pratos prontos com o jogo fechado e aviso, salvamento automático, minimizar salva, recuperação avisada, Recomeçar com confirmação, testes não mexem no disco |
| `integration/test_cafe_scene.gd` | 11 | câmera, seleção, arrasto, zoom, pinça, enquadramento |
| `integration/test_build_mode.gd` | 14 | construir, recusar com motivo, mover, girar, remover, teclado |
| `integration/test_service_scene.gd` | 11 | jogo novo a partir dos dados, HUD, painel do fogão, tempo ao vivo, coleta por toque, balcão cheio, personagens na tela, aviso de nível, textos flutuantes |
| `integration/test_shop_scene.gd` | 11 | preço e bloqueio nos botões, botões atualizados no lugar, confirmar compra, sem ouro no meio da construção, Guardar e recolocar, expansão com confirmação (Cancelar selecionado), piso e câmera acompanham, cartão de missão, aviso de missão concluída, salvamento automático do inventário |

### Verificação dos próprios testes

Para garantir que a suíte pega defeitos de verdade, bugs são inseridos de propósito, um de cada vez, e os testes precisam reprovar:

- **Fase 1 (5 de 5 pegos):** segundo toque não confirma, sem checagem de acesso, entrada liberada, móvel movido continua visível, Confirmar sempre habilitado.
- **Save (8 de 9 pegos, mais 1 equivalente):** preparo não salvo, porções reservadas perdidas, ids reiniciados após carregar (pego depois de fortalecer o teste; ver DT-015), `.bak` nunca usado, save mais novo sobrescrito, salvamento automático desligado, minimizar não salva, Recomeçar mantém o save. A mutação "sem precisão total no JSON" não muda nada observável: a precisão padrão já basta (erro < 1 ms).
- **Loja, expansão e missões (5 de 5 pegos):** móvel novo posicionado de graça, inventário sem salvamento automático, piso não acompanha a expansão, expansão sem confirmação, Guardar destruindo o móvel.
- **Fase 2 (7 de 7 pegos):** paciência nunca acaba, garçom não serve, cozinhar dá ouro em vez de cobrar, cadeira ocupada desprotegida, personagens ignoram mudança de layout, porção reservada se perde, comida pronta na hora.

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
6. [ ] Clientes entram pela seta azul, sentam e mostram um balão com o pedido e uma barrinha de paciência.
7. [ ] O garçom busca no balcão (aparece um prato na mão dele) e leva à mesa. O cliente come, sobe "+3" dourado, e ele vai embora.
8. [ ] Deixe um cliente sem comida: a barrinha esvazia, aparece "Demorou!" e a popularidade cai.
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
