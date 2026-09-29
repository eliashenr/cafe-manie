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
- Tocar num móvel o seleciona: **Mover**, **Girar**, **Guardar** (vai para o inventário; recolocar é grátis), **Fechar**.
- Nesta fase posicionar é gratuito e remover apaga o móvel. Na Fase 3 posicionar passa a ser uma compra (com confirmação, seção 32) e remover passa a guardar no inventário.

## Controles

- Arrastar move a visão. Roda do mouse ou pinça dão zoom. Toque curto seleciona. **Implementado.**
- Um toque vira arrasto depois de 12 px de movimento (`drag_threshold`), para que a tremida do dedo não atrapalhe a seleção. **Implementado.**
- Zoom entre 0,5× e 2×. **Implementado.**

## Cozinha

- Tocar num fogão livre mostra as receitas liberadas, com tempo e custo; as bloqueadas mostram o nível que falta. Escolher uma cobra os ingredientes em Café Ouro. **Implementado.**
- O preparo é tempo real e continua com o jogo fechado. **Implementado.**
- Prato pronto: a etiqueta do fogão fica verde; tocar no fogão leva as porções para um balcão (primeiro um com a mesma receita, senão um vazio) e dá XP. **Implementado.**
- Um balcão guarda um tipo de prato por vez (até 40 porções). Sem balcão com espaço, o prato espera no fogão. **Implementado.**

## Atendimento

- Assento = cadeira encostada numa mesa. Clientes só chegam se houver assento livre. **Implementado.**
- O cliente senta e pede algo que esteja no balcão; se não houver nada, espera ("?") até aparecer comida ou a paciência acabar. **Implementado.**
- A barra no balão mostra a paciência. Servido: come, paga o preço da receita (tipo apressado paga +30%), dá XP e popularidade. Não servido: vai embora irritado e a popularidade cai. **Implementado.**
- Um garçom automático busca no balcão e leva à mesa. O layout influencia: balcão longe das mesas = mais caminhada. **Implementado.**
- Popularidade (0–100%) acelera ou desacelera as chegadas. **Implementado.**
- Móvel em uso não pode ser movido nem removido; não dá para pôr móvel em cima de quem está andando. **Implementado.**

## Save

- O jogo salva sozinho e reabre de onde parou. O que estava no fogão continua cozinhando com o jogo fechado. **Implementado.**
- Ao voltar, o jogo avisa quantos pratos ficaram prontos enquanto você estava fora. **Implementado.**
- A cafeteria reabre sem clientes; porções que estavam reservadas voltam ao balcão. **Implementado.**
- **Recomeçar** (canto de cima) apaga o progresso, sempre com confirmação. **Implementado.**

## Loja, inventário e expansão

- Os botões da loja mostram preço, "Nível N" ou "N guardado(s)", e ficam apagados quando não dá para comprar. **Implementado.**
- O móvel só é cobrado ao confirmar a posição; cancelar ou tentar um lugar inválido não cobra. **Implementado.**
- **Guardar** leva o móvel ao inventário; recolocar é grátis e não exige nível. **Implementado.**
- **Expandir** aumenta o piso em 4 etapas (nível e preço em dados), sempre com confirmação. Os móveis não mudam de lugar; a entrada acompanha a borda da direita. **Implementado.**

## Missões iniciais (tutorial)

- Seis missões, uma de cada vez, com dica sempre visível no canto direito. Concluir mostra a recompensa e já passa para a próxima. **Implementado.**

## Ainda a implementar

- Conquistas, decoração com arte final e o resto das fases 5+ (ver [roadmap.md](roadmap.md)).
