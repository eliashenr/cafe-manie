# Status

## CAFÉ MANIE — STATUS (29/09/2026)

🟢 **CONCLUÍDO**

- Fase 0 — Fundação: projeto Godot 4.7.2 (renderer mobile, 1280×720 responsivo, paisagem), estrutura de pastas, `EventBus`, `.gitignore`/`.gitattributes`/`.editorconfig`, README, `CLAUDE.md` e `docs/` com o master prompt.
- Grid lógico `CafeGrid`: limites, ocupação por retângulo, colisão, remoção e expansão segura.
- Projeção isométrica `IsoProjection` com clique preciso até as bordas dos losangos.
- Cena da cafeteria: piso 8×8 isométrico (placeholder), câmera com arrastar, zoom com roda e pinça e limites, seleção de piso com destaque, HUD de protótipo.
- Executor de testes próprio, sem interface, que reprova teste com erro de script.

🟡 **EM ANDAMENTO**

- Fase 1: sistema genérico de móveis e modo de construção.

🔴 **BLOQUEADO**

- Nada no código.

🧪 **TESTADO**

- 26 testes automatizados: **PASSOU** (10 do grid, 6 da projeção, 10 de integração da cena com mouse e toque simulados).
- Executor: **PASSOU** no teste de sanidade (um teste com erro de script proposital foi reprovado, e o processo saiu com código 1).
- Cena principal rodando 120 frames: **PASSOU**, zero erros e zero avisos.
- Renderização real (OpenGL): **PASSOU**. Captura conferida: piso centralizado, destaque na célula correta, HUD legível.
- Toque real em celular: **NÃO FOI POSSÍVEL TESTAR**, pois ainda não há build Android. Toque coberto só por entrada simulada.
- Sensação de arrasto e zoom: **pendente do PO** (roteiro em [qa.md](qa.md)).

🐞 **BUGS**

- Nenhum no jogo. Um problema do próprio harness de testes foi corrigido antes do commit: a janela headless tem 64×64 e reescalava as posições simuladas.

🏗️ **DECISÕES TÉCNICAS**

- DT-003 a DT-006 registradas em [decisions.md](decisions.md): grid cartesiano + projeção separada, piso desenhado por código, executor de testes próprio no lugar do GUT e toque sem emulação de mouse.

➡️ **PRÓXIMO PASSO**

- Móvel como dado (`FurnitureDefinition` Resource: id, nome, footprint, categoria, preço, nível mínimo, beleza e eficiência) + instância no grid + modo de construção com prévia verde/vermelha, mover e remover.
