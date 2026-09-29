# Status

## CAFÉ MANIE — STATUS (29/09/2026)

🟢 **CONCLUÍDO**

- **Fases 0, 1 e 2:** fundação, construção com validação de acesso, cozinha, atendimento, economia, XP e HUD.
- **Save local versionado (antecipado para o início da Fase 3, aprovado pelo PO):**
  - salva layout (com ids originais), cozinha com horários, balcões, Café Ouro, XP e popularidade;
  - o que estava no fogão continua cozinhando com o jogo fechado;
  - ao voltar: "Bem-vindo de volta! N pratos ficaram prontos enquanto você estava fora.";
  - salvamento automático quando algo muda (no máximo a cada 5 s) e na hora ao minimizar ou fechar;
  - gravação atômica, cópia de segurança, recuperação de save danificado, proteção de save de versão mais nova, migração de versões;
  - **Recomeçar** com confirmação (Cancelar já selecionado).

🟡 **EM ANDAMENTO**

- Teste do PO no PC: roteiros das Fases 1, 2 e do Save em [qa.md](qa.md). Agora o progresso não se perde entre uma sessão de teste e outra.

🔴 **BLOQUEADO**

- **Envio para o GitHub:** push recusado até o app do Claude ser instalado na conta `eliashenr`. Os commits estão prontos localmente; o projeto vai em zip enquanto isso.

🧪 **TESTADO**

- **160 testes automatizados: PASSOU.**
- **Fechar e reabrir de ponta a ponta: PASSOU** — móveis, ouro, nível e o tempo de preparo exato voltam; pratos ficam prontos com o jogo fechado.
- **Save danificado, save de versão mais nova, arquivo vazio: PASSOU** — o jogo nunca apaga um save por conta própria.
- **Verificação da suíte: PASSOU** — 9 bugs inseridos de propósito no save: 8 pegos e 1 sem efeito observável (explicado em [qa.md](qa.md)). Um deles só foi pego depois de fortalecer o teste, o que revelou um risco real (abaixo).
- **Cena principal rodando 300 frames: PASSOU**, zero erros e zero avisos.
- **Renderização real: PASSOU** — capturas do "bem-vindo de volta" e da confirmação de Recomeçar.
- **Celular real (minimizar, sistema matar o app): NÃO FOI POSSÍVEL TESTAR** (sem build Android). O código salva ao pausar e ao perder o foco, e isso tem teste com a notificação simulada.

🐞 **BUGS** (corrigidos, com teste)

- 🐞 **HIGH (evitado antes de acontecer) — móvel sobrescrito em silêncio:** se o contador de ids não fosse restaurado ao carregar, o próximo fogão comprado ganharia o id de um fogão existente e o apagaria. Agora o contador é salvo e o layout ainda confere se o id já existe.
- 🐞 **MEDIUM — save estragado gerava erro no log:** um caso esperado e tratado não deve parecer falha do jogo. A leitura agora trata o erro sem registrá-lo.
- 🐞 **LOW — aviso ilegível:** o aviso do topo ganhou fundo.
- 🐞 **LOW (segurança) — confirmação perigosa:** o botão pré-selecionado era "Apagar e recomeçar"; agora é "Cancelar".

🏗️ **DECISÕES TÉCNICAS**

- DT-015 formato e segurança do save; DT-016 quando salvar. Detalhes em [decisions.md](decisions.md).

➡️ **PRÓXIMO PASSO**

- **Loja (resto da Fase 3):** móveis passam a custar Café Ouro e a exigir nível, com confirmação de compra; remover guarda no inventário; expansão da cafeteria.
- Depois do seu teste: **FAÇA BALANCEAMENTO**, com as suas impressões.
