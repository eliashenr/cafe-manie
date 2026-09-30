# Direção de arte

Referência: seções 5, 43, 77, 78, 130–132 do master prompt. Documento vivo: vai ser completado com as impressões do PO sobre as capturas do jogo antigo.

## Direção escolhida: "Esquina Nostálgica" (30/09/2026)

O PO mandou capturas do jogo antigo e pediu **nostalgia acima de modernidade**: quem procurar o Café Manie quer a sensação do jogo de 2010, não um jogo "moderninho". A direção visual foi montada no Claude Design, no canvas **"Café Manie — Direção Visual"**, com 5 pranchas: tela do jogo, loja, personagens, guia de estilo e o cenário sem interface.

**O que traz a nostalgia** (convenções do gênero, que ninguém possui):

- a cafeteria na **esquina de um quarteirão**, com rua, calçada, grama e poste;
- a sala **isométrica com duas paredes no fundo**, com janelas, cortinas e quadros;
- o salão **lotado**, com clientes **cabeçudos**, balões de pedido e carinhas de humor;
- as **cores quentes e saturadas**, com contorno escuro;
- **contadores de moeda no alto à esquerda**, **nível com barra de XP no centro**, **barra de ícones grandes embaixo** e **faixa de vizinhos** à direita;
- os números subindo ("+18", "+8 XP").

**O que é nosso** (para não copiar, seção 5):

- **personagens próprios**: Chef Bia (mascote) e o garçom Léo;
- ícones desenhados do zero;
- paleta "café": espresso, chocolate, canela, mel, creme, tomate, menta;
- fontes Fredoka e Nunito;
- a placa-lousa com o nome da cafeteria;
- o grão verde como moeda premium;
- a disposição própria da interface.

Nenhum sprite, logo, personagem, ícone ou texto do jogo antigo foi usado, e as capturas **não entram no repositório**.

Os desenhos das pranchas são gerados por código (`tools/art_direction/`, Python gerando SVG). O mesmo gerador pode exportar os sprites do jogo, então a próxima etapa é trocar os placeholders da Godot por essa arte.

### Versão 2 (30/09/2026)

O PO reprovou a versão 1: móveis de caixa, pessoas estranhas, cabelos feios e comidas irreconhecíveis. A versão 2 refez tudo peça por peça, com luz de cima à esquerda, sombra no chão e brilho nas quinas:

- **Móveis:** mesa redonda com toalha xadrez, babado e vasinho; cadeira de bistrô com pernas, assento estofado e encosto de ripas; fogão industrial com bocas, botões, forno aceso e a panela mostrando a comida; balcão de madeira com tampo de mármore e pilhas de pratos com a contagem; vitrine de vidro com bolos; máquina de expresso; vaso com folhagem cheia.
- **Pessoas:** vista 3/4 com olhos grandes e brilho, sobrancelhas, nariz, boca com expressão, orelhas, gola, mangas e sapatos. São 9 penteados com volume e reflexo (rabo de cavalo, black, chanel, longo, coque, topete, curto, boné e careca) e poses em pé, andando e sentado.
- **Comidas** grandes e reconhecíveis: café com espuma e coração de leite, pão de queijo dourado e rachado, misto-quente com presunto e queijo escorrendo, bolo de cenoura com cobertura de chocolate e granulado, coxinha (uma mordida mostrando o recheio) e lasanha em camadas.
- **Cena:** papel de parede listrado, lambri, janelas com cortina e sanefa, lousa de cardápio, arandelas, azulejo e coifa na cozinha, piso xadrez, tapete na entrada, rua com meio-fio e faixa, árvores, arbustos floridos, banco e cavalete "Aberto".

O gerador v2 está em `tools/art_direction/v2/`.

## Onde estamos

Tudo o que aparece na tela hoje é **placeholder desenhado por código** (caixas coloridas, piso e parede com padrões simples, bonequinhos básicos). Isso é proposital: as regras de jogo ainda estão mudando, e arte final feita agora teria de ser refeita.

## O que vale desde já

- **Estilo:** 2D cartoon sofisticado, "realidade divertida" (seções 43 e 77). Cafeteria reconhecível, pessoas reconhecíveis, móveis plausíveis, sem realismo fotográfico.
- **Originalidade (seção 5):** nada de sprites, interface, personagens, ícones, logos, sons ou identidade visual do Café Mania. As capturas do jogo antigo servem só para entender **que sensação** ele passava. Elas **não entram no repositório**.
- **Legibilidade no celular primeiro:** tela de 6 polegadas, dedo como ponteiro. Cada objeto precisa ser reconhecível pela silhueta.

## O que vamos tirar das capturas (checklist)

Para cada captura, anotar em palavras (não copiar):

- [ ] Temperatura das cores (quentes? pastéis? saturadas?) e o contraste entre piso, parede e móveis.
- [ ] Densidade: quanta coisa cabe na tela sem ficar confuso.
- [ ] Escala dos personagens em relação aos móveis e ao piso.
- [ ] Como o jogo mostrava estado (comida pronta, cliente esperando, cliente bravo).
- [ ] O que dava vontade de decorar (variedade? cores? itens raros?).
- [ ] O que envelheceu mal e precisa ser modernizado (seção 154).

## Medidas técnicas que a arte final precisa respeitar

| Item | Medida atual | Observação |
|---|---|---|
| Piso isométrico | 128 × 64 px (proporção 2:1) | `IsoProjection.TILE_SIZE`. Mudar a escala muda tudo |
| Parede | 110 px de altura | `WallView.wall_height` |
| Móveis | 1×1, 2×1; giram em 4 direções | Precisam de desenho em pelo menos 2 vistas (as outras 2 podem ser espelhadas) |
| Personagens | ~40 px de altura | Animação mínima: parado, andando (4 direções), sentado comendo |
| Resolução base | 1280 × 720, ampliando para telas maiores | Desenhar em 2× para ficar nítido em celulares de alta densidade |

## Como produzir a arte final (decisão para antes da Fase 8)

| Opção | Custo | Prazo | Risco |
|---|---|---|---|
| **A. Artista freelancer** (estilo exclusivo) | Maior | Semanas a meses | Depende de achar alguém com o estilo certo |
| **B. Pacote licenciado** (lojas de assets com licença comercial) | Baixo | Imediato | Estilo pode não ser exclusivo; conferir licença (seção 130) |
| **C. IA para conceitos + artista finalizando** | Médio | Rápido para testar direções | Conferir licença e consistência (seção 132) |

**Recomendação de engenharia:** usar a **C** para explorar 2 ou 3 direções de estilo com o PO e contratar a **A** para a arte final da direção escolhida. Enquanto isso, os placeholders continuam, porque o código já separa regra e desenho: trocar a arte não mexe no jogo.

## Próximo passo

O PO envia as capturas e o que lembra com carinho do jogo antigo. A partir disso, este documento ganha uma paleta de cores original, uma folha de referência de estilo e 2 ou 3 direções para escolher.
