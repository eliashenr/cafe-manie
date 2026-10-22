# Roadmap

Baseado na seção 82 do master prompt. Uma fase só termina quando cumpre seu marco de saída.

| Fase | Entrega | Marco de saída | Status |
|---|---|---|---|
| 0 — Fundação | Git, projeto Godot, estrutura, docs, testes rodando | Projeto abre sem erros e os testes passam | ✅ Concluída |
| 1 — Protótipo | Grid isométrico, câmera, seleção, móveis genéricos no grid | O PO posiciona móveis com mouse e toque | 🟡 Falta o teste do PO |
| 2 — Core gameplay | Cozinha, balcão, cliente, garçom, Café Ouro, XP | O loop completo roda sozinho | ✅ Implementada (falta o teste do PO) |
| 3 — Cafeteria | Save ✅, loja ✅, inventário ✅, venda ✅, expansão ✅, paredes e revestimentos ✅, decoração com beleza ✅ | Comprar → posicionar → salvar | ✅ Concluída (arte final na Fase 8) |
| 4 — Progressão | Missões iniciais ✅, tutorial ✅, conquistas ✅, recompensa diária ✅ | **Vertical Slice validada** (seção 81) | ✅ Slice validada pelo PO ("joguei e gostei"); falta o balanceamento |
| 5 — Social | Amigos, visitas, mapa, rankings | Só depois da slice validada e divertida | ⏳ |
| 6 — Backend | Autenticação, cloud save, economia no servidor | | ⏳ |
| 7 — Monetização | Café Grana, loja premium, compras de teste | Revisão jurídica feita antes (ver riscos) | ⏳ |
| 8 — Conteúdo | Níveis, receitas, móveis, personagens, eventos | Plano de arte definido | ⏳ |
| 9 — QA | Testes, performance, segurança, regressão | | ⏳ |
| 10 — Release | Android, publicação, analytics | | ⏳ |

## Pacote de melhorias do PO (12/10/2026)

O PO pediu um conjunto de melhorias depois de jogar. Elas entram em etapas, cada uma testada e entregue
separadamente:

- [x] **1. Atendimento** (DT-039):
  - clientes pedem pratos que não estão no balcão;
  - fila na calçada, e mais clientes a cada nível;
  - garçons buscam os pratos prontos nos fogões e circulam pela cozinha;
  - contratar garçons.
- [x] **2. Andar natural** (DT-040): ciclo de 8 quadros com joelho, sem o balanço de pinguim.
- [x] **3. Reforma piso a piso** (DT-041):
  - escolher um piso ou parede e pintar célula por célula, pagando por célula;
  - misturar cores e estilos.
- [x] **4. Paredes completas** (DT-042):
  - paredes da frente e dos lados, com porta, baixas o bastante para continuar vendo o salão;
  - janelas, portas, TV e rádio para pôr nas paredes.
- [x] **5. Mais conteúdo** (24 cadeiras e mesas, 3 fogões e 3 balcões; DT-038): mais cadeiras e mesas em cada coleção e fogões e balcões modernos.
- [x] **6. Compra de moedas** (DT-043; o pagamento de verdade depende da Play Store):
  - pacotes de Café Ouro por dinheiro, oferecidos quando falta ouro, com a taxa calculada pela economia do jogo;
  - o pagamento real depende da Play Store (conta de desenvolvedor do PO) e da revisão jurídica da Fase 7;
  - até lá, a loja de pacotes aparece e explica isso.

## Pacote de pedidos do PO (21/10/2026)

O PO mostrou fotos de dois problemas e pediu mais conteúdo. As etapas entram uma de cada vez, testadas e entregues:

- [x] **1. Sentar de verdade e o garçom que entrava no balcão** (DT-045, urgente):
  - pose sentada nova;
  - móveis desenhados em faixas, na ordem certa.
- [x] **2. Nível máximo 30** (DT-046):
  - curva de XP até o 30, com ouro a cada nível;
  - novas expansões e garçons para os níveis altos.
- [x] **3. Missões diárias e semanais** (DT-047, roteiro em [missoes.md](missoes.md)):
  - 10 diárias e 20 semanais, criadas a partir do conteúdo do jogo;
  - metas que acompanham o nível.
- [x] **4. Cidade em volta do café** (DT-048):
  - ruas, calçadas, prédios e táxis no estilo de Nova York, no lugar do gramado.

## Pedidos do PO (22/10/2026)

- [x] **Pausa** (DT-049): o jogo inteiro para (clientes, garçons, fogões, trânsito) e o jogador mexe à vontade.
- [x] **Loja aberta depois da compra** (DT-049): volta na mesma aba depois de posicionar o móvel.
- [x] **Pausa sem bloqueio** (DT-050): pausado, mexe em tudo, mesmo com clientes.
- [x] **Balcão de 1 piso e mais fogões e balcões** (DT-050): 8 de cada.
- [x] **Relatório do Café Mania original** ([relatorio_cafe_mania.md](relatorio_cafe_mania.md)): o que aprender e a ordem sugerida.

## Próximo pacote do relatório (seção 4, item 2)

- [x] **1. Placa ABERTO/FECHADO** (DT-051): fechado, ninguém novo entra; quem está dentro termina sem tirar popularidade.
- [x] **2. Máquinas de café e de sucos, com energia** (DT-052): 6 bebidas, servidas tocando no cliente.
- [x] **3. Livro de receitas, domínio e 12 receitas novas** (DT-053): 18 receitas até o nível 17, em 4 abas, com estrelas.
- [ ] **4. Mais 12 receitas, do nível 18 ao 30** (proposta 3.3).

## Passe visual (18/10/2026)

- [x] **Efeitos visuais só na tela** (DT-044):
  - raio-X atrás de móveis altos, halo no móvel escolhido e no fogão pronto, mureta que abre perto de quem passa;
  - móvel que surge, pratos que quicam, esticar e achatar, loja, aviso e ouro animados;
  - vapor e confete dourado;
  - toque de 48 px, filtro de textura do projeto, ordem de desenho protegida por teste.

## Fase 1 — detalhamento

- [x] Grid lógico 8×8 com ocupação, colisão e expansão
- [x] Projeção isométrica com clique preciso
- [x] Câmera: arrastar, zoom com roda e pinça, limites
- [x] Seleção de piso com destaque
- [x] Definição de móvel por dados (Resource) e catálogo com 6 móveis
- [x] Modo de construção: escolher um móvel, ver prévia verde/vermelha com motivo da recusa, girar e posicionar
- [x] Mover, girar no lugar e remover móveis
- [x] Ordenação de desenho isométrico (y-sort) com objetos de várias células
- [x] Validação: nenhum móvel funcional fica sem caminho até a entrada, e a entrada fica sempre livre
- [ ] Teste do PO no PC (roteiro em [qa.md](qa.md)) — **marco de saída da fase**

## Fase 3 — detalhamento

- [x] Save local versionado: layout, cozinha com horários, balcões, ouro, XP, popularidade
- [x] Gravação atômica, cópia de segurança, recuperação de save danificado, proteção de save de versão mais nova
- [x] Salvamento automático (ao mudar algo, no máximo a cada 5 s) e na hora ao minimizar ou fechar
- [x] "Bem-vindo de volta" contando os pratos que ficaram prontos com o jogo fechado
- [x] Botão Recomeçar com confirmação (Cancelar já selecionado)
- [x] Loja: móveis custam Café Ouro e exigem nível; cobrança só ao confirmar a posição (seção 32)
- [x] Inventário: **Guardar** leva o móvel ao inventário; recolocar é grátis
- [x] Expansão da cafeteria em 4 etapas, com confirmação
- [x] Save versão 2 (inventário e missões), com migração da versão 1

## Fase 4 — detalhamento

- [x] 6 missões iniciais em dados, uma por vez, com dica sempre visível (tutorial)
- [x] Cartão de missão no HUD e aviso de missão concluída com recompensa
- [x] Build para Windows (`CafeManie.exe`, sem precisar da Godot) com checagem automática do build
- [x] Conquistas progressivas (7 × 3 degraus)
- [x] Recompensa diária de 7 dias
- [x] Nome da cafeteria, sons de feedback
- [x] **Validação da Vertical Slice pelo PO**, em 29/09/2026
- [x] Primeiro APK Android (arm64), falta testar num celular de verdade
- [ ] **FAÇA BALANCEAMENTO** com as impressões do PO

## Fase 3 — complementos desta etapa

- [x] Paredes do fundo e revestimentos de piso e parede (compra única, troca grátis)
- [x] Beleza (móveis + revestimentos) aumentando a paciência e as chegadas (seção 35)
- [x] Venda de móveis com confirmação; o último fogão e o último balcão são protegidos
- [x] 3 itens de decoração novos; loja em abas

## Fase 2 — detalhamento

- [x] Relógio do jogo (`GameClock`) e preparo por horário: o prato fica pronto mesmo com o jogo fechado
- [x] 6 receitas em dados, com custo, preço, XP e nível de desbloqueio
- [x] Fogão: escolher receita (cobra ingredientes), acompanhar o tempo, tocar para levar ao balcão
- [x] Balcão com porções empilhadas por receita e capacidade
- [x] Clientes (2 tipos em dados): entram, sentam em cadeira ao lado de mesa, pedem o que há no balcão, esperam com paciência, comem, pagam e saem
- [x] Garçom com caminho (A*) que busca no balcão e entrega na mesa
- [x] Café Ouro com registro de transações; XP e níveis 1–10 em dados; popularidade que acelera as chegadas
- [x] Proteções: móvel em uso não sai do lugar; móvel não cai em cima de quem está andando; quem anda recalcula o caminho
- [x] HUD (nível, XP, ouro, popularidade), avisos e textos flutuantes de feedback
- [x] Teste de turno longo (30 min simulados com um "jogador robô")
- [ ] Teste do PO no PC (roteiro em [qa.md](qa.md)) — **marco de saída da fase**

## Riscos acompanhados

| Risco | Mitigação | Quando tratar |
|---|---|---|
| Nome "Café Manie" e moedas "Café Ouro/Grana" parecidos com o Café Mania original | IDs internos neutros; nomes na tela ficam em dados. Busca no INPI | Antes da Fase 7 |
| Arte 2D isométrica consistente é o maior gargalo | Plano de arte (artista, pacote licenciado ou IA com revisão) | Antes da Fase 8 |
| Menores + compras + chat (classificação 12 anos, ECA Digital) | Validação jurídica | Antes das Fases 5 e 7 |
| Pathfinding com layout editável (garçom preso) | ✅ Mitigado: posicionamento recusa layouts sem acesso (DT-007) | Fases 1–2 |
| Ordem de desenho com móveis longos cruzados | y-sort pelo vértice da frente; rever com arte final (DT-009) | Fase 8 |
| Desempenho em Android de entrada | Medir num aparelho real (precisa de build Android) | Fase 2 em diante |
| Progresso some ao fechar o jogo | ✅ Mitigado: save local versionado (DT-015, DT-016) | — |
| Relógio do aparelho pode ser adiantado para pular o preparo (seção 66) | Aceito enquanto o jogo é offline; o `GameClock` vira horário do servidor na Fase 6 | Fase 6 |
| Balanceamento fácil demais no teste do robô (0 irritados, nível 8 em 30 min; a beleza facilita ainda mais) | Comando **FAÇA BALANCEAMENTO** | Próxima etapa |
| Chave de teste do APK só existe na nuvem de trabalho | Se ela se perder, desinstalar e instalar de novo (o jogo ainda é de teste). A chave oficial é criada e guardada pelo PO na Fase 10 | Fase 10 |
| Nome da cafeteria visível para outros jogadores sem moderação | Moderação no servidor antes de qualquer recurso social (DT-026) | Fase 5 |
