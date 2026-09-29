# Status

## CAFÉ MANIE — STATUS (29/09/2026)

🟢 **CONCLUÍDO**

- **Fase 0 — Fundação:** projeto Godot 4.7.2 (renderer mobile, 1280×720 responsivo, paisagem), estrutura, `EventBus`, README, `CLAUDE.md` e `docs/` com o master prompt.
- **Fase 1 — Protótipo (implementação completa, falta o teste do PO):**
  - grid lógico e projeção isométrica com clique preciso;
  - câmera com arrastar, zoom com roda e pinça, limites e enquadramento inicial que respeita as barras da interface;
  - móveis como dados: 6 móveis em `data/furniture/*.tres` (Mesa, Cadeira, Fogão, Balcão 2×1, Planta, Mesa longa 2×1), editáveis no inspetor da Godot;
  - modo de construção: prévia verde/vermelha com o motivo da recusa, girar, confirmar e cancelar, tanto no mouse quanto no toque;
  - móvel selecionado: Mover, Girar no lugar, Remover;
  - entrada da cafeteria e **validação de acesso** (nenhum fogão, mesa, cadeira ou balcão fica sem caminho até a entrada);
  - móveis desenhados em ordem de profundidade (placeholder).

🟡 **EM ANDAMENTO**

- Marco de saída da Fase 1: o PO jogar o protótipo no PC seguindo o roteiro de [qa.md](qa.md).

🔴 **BLOQUEADO**

- **Envio para o GitHub:** o push é recusado até o app do Claude ser instalado na conta `eliashenr`. Os commits estão prontos localmente.

🧪 **TESTADO**

- **69 testes automatizados: PASSOU** (grid 10, projeção 6, catálogo 6, layout 15, sessão 7, modo de construção 14, cena 11).
- **Verificação da suíte: PASSOU.** Cinco bugs inseridos de propósito, todos reprovados pelos testes.
- **Cena principal rodando 120 frames: PASSOU**, zero erros e zero avisos.
- **Renderização real (OpenGL): PASSOU.** Capturas conferidas com 12 móveis: profundidade correta, contorno de seleção, prévia verde e vermelha, barra explicando a recusa.
- **Toque em celular real: NÃO FOI POSSÍVEL TESTAR** (ainda sem build Android). Toque coberto por entrada simulada.
- **Sensação e diversão (seção 122):** pendente do PO.

🐞 **BUGS**

- 🐞 **Corrigido (MEDIUM):** ao entrar no modo de construção, o painel de cima continuava mostrando o piso selecionado antes. Causa: limpar a seleção não avisava o `EventBus`. Agora toda mudança de seleção passa por um único método que avisa. Teste de regressão incluído.
- 🐞 **Corrigido (LOW):** em 1280×720 a fileira de trás ficava sob o painel de cima e a frente sob a barra de baixo. A câmera agora enquadra a cafeteria na faixa livre entre as barras (DT-008).

🏗️ **DECISÕES TÉCNICAS**

- DT-007 acesso garantido no posicionamento; DT-008 enquadramento considerando a interface; DT-009 ordem de desenho pelo vértice da frente. Detalhes em [decisions.md](decisions.md).

➡️ **PRÓXIMO PASSO**

- Fase 2 — Core gameplay: `Clock` (tempo por timestamp), fogão com receita e preparo, balcão com porções, cliente básico (entrar → sentar → pedir → esperar → comer → pagar → sair), um garçom com pathfinding (`AStarGrid2D` sobre o mesmo grid), Café Ouro e XP.
