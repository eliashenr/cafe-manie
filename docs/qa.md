# QA

## Estratégia

| Tipo | Onde | Quem roda |
|---|---|---|
| Unitário — regras puras de `core/` | `tests/unit/` | Automático, antes de todo commit |
| Integração — cenas com entrada simulada | `tests/integration/` | Automático, antes de todo commit |
| Subida da cena principal (120 frames, zero erros) | `godot --headless --quit-after 120` | Automático, antes de todo commit |
| Visual e sensação (seção 126) | PC do PO na Godot, depois celular | PO, a cada entrega |

Como rodar está no [README](../README.md#testes-automatizados).

## Cobertura atual

**`test_cafe_grid.gd` — 10 testes**
- limites nas 4 bordas
- ocupação de objetos com várias células
- recusa de sobreposição, de objeto saindo do grid, de id repetido ou vazio e de tamanho inválido, sempre sem efeito colateral
- remoção e recolocação
- expansão, e recusa de expansão que cortaria objetos

**`test_iso_projection.gd` — 6 testes**
- origem e direção dos eixos
- ida e volta célula → mundo → célula num grid 14×14, incluindo coordenadas negativas
- pontos perto dos vértices ficam na própria célula
- pontos logo além de uma borda caem no vizinho certo
- o retângulo de limites contém todo o grid

**`test_cafe_scene.gd` — 10 testes**
- a cena inicia com grid 8×8 vazio e câmera centralizada
- clique seleciona o piso certo, atualiza o destaque e avisa o EventBus uma única vez
- clique fora do grid limpa a seleção
- arrastar o mouse move a câmera e não seleciona
- tremida pequena do dedo ainda conta como toque
- zoom pela roda respeita mínimo e máximo
- o zoom mantém fixo o ponto sob o cursor
- pinça com dois dedos dá zoom proporcional e não seleciona
- a câmera não sai dos limites da cafeteria

## Roteiro de teste manual — Fase 1 (parcial)

Rode o jogo (F5) e confira:

1. [ ] O jogo abre sem janela de erro. O piso quadriculado aparece centralizado.
2. [ ] Clicar num piso destaca **aquele** piso, e o painel mostra as coordenadas dele.
3. [ ] Clicar fora do piso tira o destaque.
4. [ ] Arrastar com o botão esquerdo move a visão **e não** seleciona nada ao soltar.
5. [ ] A roda do mouse aproxima e afasta. O ponto sob o cursor fica parado enquanto o zoom muda.
6. [ ] Não é possível arrastar a cafeteria para fora da tela.
7. [ ] Ao redimensionar a janela (ou maximizar), o piso continua visível e o painel continua legível.
8. [ ] Sensação: o arrasto e o zoom são confortáveis? Rápidos ou lentos demais? *(anote para ajuste)*

Os itens de toque (pinça, arrasto com dedo) serão conferidos no celular quando houver build Android.

## Bug report

Use o formato da seção 88 do master prompt. Severidades: `BLOCKER`, `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`.
