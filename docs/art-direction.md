# Direção de arte

Referência: seções 5, 43, 77, 78, 130–132 do master prompt. Documento vivo: vai ser completado com as impressões do PO sobre as capturas do jogo antigo.

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
