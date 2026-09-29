# Gameplay

Regras de gameplay **decididas**. A visão completa está no [master prompt](master-prompt.md) (seções 12–21 e 36–45). Aqui fica só o que já virou decisão ou implementação.

## Cafeteria e grid

- A cafeteria é um grid de células vista em isométrico 2:1. **Implementado.**
- Tamanho inicial: 8×8 (parâmetro `initial_grid_size` da cena). **Implementado.**
- Móveis ocupam retângulos de células. Não podem se sobrepor nem sair do grid. **Implementado no grid lógico; falta a interface.**
- Expansão aumenta o grid e nunca corta móveis já posicionados. **Implementado no grid lógico.**

## Controles

- Arrastar move a visão. Roda do mouse ou pinça dão zoom. Toque curto seleciona. **Implementado.**
- Um toque vira arrasto depois de 12 px de movimento (`drag_threshold`), para que a tremida do dedo não atrapalhe a seleção. **Implementado.**
- Zoom entre 0,5× e 2×. **Implementado.**

## Premissas assumidas no discovery (a implementar)

- **Tempo real + tempo ausente:** a comida continua cozinhando com o jogo fechado. Clientes só são atendidos com o jogo aberto.
- Loop alvo da Vertical Slice: cozinhar → balcão → cliente senta e pede → garçom entrega → cliente paga → XP → nível → comprar → posicionar → salvar.
- Nenhum móvel pode bloquear o caminho entre a entrada, as mesas, o balcão e os fogões.
