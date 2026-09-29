# Roadmap

Baseado na seção 82 do master prompt. Uma fase só termina quando cumpre seu marco de saída.

| Fase | Entrega | Marco de saída | Status |
|---|---|---|---|
| 0 — Fundação | Git, projeto Godot, estrutura, docs, testes rodando | Projeto abre sem erros e os testes passam | ✅ Concluída |
| 1 — Protótipo | Grid isométrico, câmera, seleção, móveis genéricos no grid | O PO posiciona móveis com mouse e toque | 🟡 Falta o teste do PO |
| 2 — Core gameplay | Cozinha, balcão, cliente, garçom, Café Ouro, XP | O loop completo roda sozinho | ✅ Implementada (falta o teste do PO) |
| 3 — Cafeteria | **Save (antecipado, aprovado pelo PO)** ✅, loja, inventário, decoração, expansão | Comprar → posicionar → salvar | 🟡 Save pronto; loja a seguir |
| 4 — Progressão | Missões, tutorial, conquistas (níveis 1–10 já existem) | **Vertical Slice validada** (seção 81) | ⏳ |
| 5 — Social | Amigos, visitas, mapa, rankings | Só depois da slice validada e divertida | ⏳ |
| 6 — Backend | Autenticação, cloud save, economia no servidor | | ⏳ |
| 7 — Monetização | Café Grana, loja premium, compras de teste | Revisão jurídica feita antes (ver riscos) | ⏳ |
| 8 — Conteúdo | Níveis, receitas, móveis, personagens, eventos | Plano de arte definido | ⏳ |
| 9 — QA | Testes, performance, segurança, regressão | | ⏳ |
| 10 — Release | Android, publicação, analytics | | ⏳ |

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
- [ ] Loja: móveis passam a custar Café Ouro e a exigir nível, com confirmação de compra (seção 32)
- [ ] Inventário: remover guarda o móvel em vez de apagar
- [ ] Expansão da cafeteria pela interface

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
| Balanceamento fácil demais no teste do robô (0 irritados, nível 7 em 30 min) | Comando **FAÇA BALANCEAMENTO** após o teste do PO | Após o teste do PO |
