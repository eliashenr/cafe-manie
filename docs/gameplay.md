# Gameplay

Regras de gameplay **decididas**. A visão completa está no [master prompt](master-prompt.md) (seções 12–21 e 36–45). Aqui fica só o que já virou decisão ou implementação.

## Cafeteria e grid

- A cafeteria é um grid de células vista em isométrico 2:1. **Implementado.**
- Tamanho inicial: 8×8 (parâmetro `initial_grid_size` da cena). **Implementado.**
- Móveis ocupam retângulos de células, giram em 4 direções (em giros ímpares largura e profundidade trocam) e não podem se sobrepor nem sair do grid. **Implementado.**
- A cafeteria tem uma **entrada** (hoje no meio da borda da frente) que fica sempre livre. **Implementado.**
- **Acesso:** móveis que cliente ou garçom usam (mesa, cadeira, fogão, balcão) precisam de um piso vizinho alcançável a partir da entrada. Decoração pode ficar em qualquer lugar livre. Um posicionamento que deixaria qualquer móvel sem acesso é recusado com explicação. **Implementado.**
- Expansão aumenta o grid e nunca corta móveis já posicionados. **Implementado no grid lógico; falta a interface (Fase 3).**

## Construção

- A barra de baixo lista o catálogo. Escolher um móvel entra no modo de construção.
- Prévia verde = pode; vermelha = não pode, com o motivo na barra.
- No toque, o primeiro toque posiciona a prévia e o segundo no mesmo piso confirma (ou **Confirmar**). No mouse, a prévia segue o cursor e um clique confirma.
- Tocar num móvel o seleciona: **Mover**, **Girar**, **Remover**, **Fechar**.
- Nesta fase posicionar é gratuito e remover apaga o móvel. Na Fase 3 posicionar passa a ser uma compra (com confirmação, seção 32) e remover passa a guardar no inventário.

## Controles

- Arrastar move a visão. Roda do mouse ou pinça dão zoom. Toque curto seleciona. **Implementado.**
- Um toque vira arrasto depois de 12 px de movimento (`drag_threshold`), para que a tremida do dedo não atrapalhe a seleção. **Implementado.**
- Zoom entre 0,5× e 2×. **Implementado.**

## Premissas assumidas no discovery (a implementar)

- **Tempo real + tempo ausente:** a comida continua cozinhando com o jogo fechado. Clientes só são atendidos com o jogo aberto.
- Loop alvo da Vertical Slice: cozinhar → balcão → cliente senta e pede → garçom entrega → cliente paga → XP → nível → comprar → posicionar → salvar.
