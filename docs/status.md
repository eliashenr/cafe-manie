# Status

## CAFÉ MANIE — STATUS (29/09/2026)

🟢 **CONCLUÍDO**

- **Fase 0 — Fundação.**
- **Fase 1 — Protótipo:** grid, câmera, construção com validação de acesso.
- **Fase 2 — Core gameplay (implementada; falta o teste do PO):**
  - relógio do jogo e preparo por horário (o prato fica pronto mesmo com o jogo fechado — vale de verdade quando houver save);
  - 6 receitas, 2 tipos de cliente, curva de níveis 1–10, parâmetros do atendimento e jogo novo — tudo em `data/`;
  - fogão com painel de receitas (custo, tempo, bloqueio por nível), tempo ao vivo, toque no fogão pronto leva ao balcão;
  - balcões com porções empilhadas por receita;
  - clientes que chegam conforme a popularidade, sentam, pedem, esperam com paciência, comem, pagam e vão embora (ou saem irritados);
  - garçom com caminho A* que busca no balcão e entrega na mesa;
  - Café Ouro com registro de transações, XP, níveis e desbloqueio de receitas;
  - proteções: móvel em uso não sai do lugar; nada é posto em cima de quem anda; quem anda recalcula a rota;
  - HUD (nível, XP, ouro, popularidade), avisos e textos flutuantes de feedback.

🟡 **EM ANDAMENTO**

- Teste do PO no PC — roteiros das Fases 1 e 2 em [qa.md](qa.md). É o marco de saída das duas fases.

🔴 **BLOQUEADO**

- **Envio para o GitHub:** push recusado até o app do Claude ser instalado na conta `eliashenr`. Commits prontos localmente; o projeto vai em zip enquanto isso.

🧪 **TESTADO**

- **133 testes automatizados: PASSOU.**
- **Turno longo (30 min simulados, jogo novo real, clientes aleatórios): PASSOU** — 282 servidos, ninguém preso, sem erros, lucro e níveis.
- **Verificação da suíte: PASSOU** — 7 bugs inseridos de propósito na simulação e na cozinha, todos reprovados.
- **Cena principal rodando 300 frames: PASSOU**, zero erros e zero avisos. Sem vazamento de memória ao sair.
- **Renderização real: PASSOU** — capturas do jogo novo em atendimento e do painel do fogão conferidas.
- **Toque em celular real e desempenho em Android: NÃO FOI POSSÍVEL TESTAR** (sem build Android).
- **Diversão (seção 122): pendente do PO.**

🐞 **BUGS** (encontrados nesta fase e corrigidos, cada um com teste de regressão)

- 🐞 **HIGH — jogo novo com 2 fogões e 1 balcão:** o segundo prato ficava preso no fogão, porque um balcão guarda um tipo de prato por vez. Achado na captura de tela. O jogo novo agora tem 2 balcões, e um teste exige pelo menos um balcão por fogão.
- 🐞 **MEDIUM — motivo da recusa sumia:** com o fogão cozinhando, a atualização do tempo apagava a explicação "está em uso". Achado por teste de integração.
- 🐞 **MEDIUM — barra de XP ilegível:** sem fundo, parecia um traço cinza. Achado na captura.
- 🐞 **LOW — vazamento de memória:** referências circulares (pedido ↔ garçom) impediam a memória de ser liberada. Achado no aviso de saída da Godot.

🏗️ **DECISÕES TÉCNICAS**

- DT-010 a DT-014 em [decisions.md](decisions.md): catálogos por composição, simulação pura com relógio injetável, móvel em uso e personagem no caminho, personagens sem colisão entre si, porção reservada no pedido.

💡 **SUGESTÃO DE PRODUTO — antecipar o save**

O roadmap coloca o save na Fase 4. Só que, sem save:
- fechar o jogo perde tudo, então os seus testes de jogo recomeçam do zero toda vez;
- a mecânica "cozinhar, fechar e voltar depois", que já está pronta na lógica, não pode ser sentida.

Proposta: fazer o **save local versionado** (seções 63–64) como primeira entrega da Fase 3, antes da loja.

💡 **SUGESTÃO DE PRODUTO — balanceamento depois do seu teste**

O "jogador robô" chegou ao nível 7 em 30 minutos, com 0 clientes irritados e popularidade 100%. Os números atuais parecem fáceis demais. Recomendo você jogar primeiro e depois pedir **FAÇA BALANCEAMENTO** com as suas impressões.

➡️ **PRÓXIMO PASSO**

- Se aprovar a sugestão: save local versionado (layout, cozinha com horários, balcões, carteira, XP, popularidade), com migração de versão e teste de "fechar e reabrir".
- Depois: Fase 3 — loja (móveis passam a custar ouro e exigir nível), inventário e expansão.
