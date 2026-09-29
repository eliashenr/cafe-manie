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

**`test_furniture_catalog.gd` — 6 testes**
- carrega os 6 móveis de `data/furniture`, todos válidos e completos
- móveis funcionais exigem acesso e decoração não
- ordenação por nível e preço; recusa de id repetido, vazio, tamanho zero e nulo

**`test_cafe_layout.gd` — 15 testes**
- entrada padrão; tamanho girado
- ids únicos e aviso de mudança por operação
- recusas: fora do grid, sobreposto, na entrada — sem efeito colateral
- decoração em canto fechado é permitida; móvel funcional sem acesso é recusado
- não dá para emparedar uma mesa nem isolar a entrada quando alguém precisa dela
- mover para piso livre e sobre as próprias células; movimento inválido não altera nada
- giro muda as células; giro que sairia do grid é recusado
- remoção e ids inexistentes

**`test_placement_session.gd` — 7 testes**
- precisa de alvo antes de confirmar; só posiciona ao confirmar
- ciclo de rotação; alvo inválido não confirma
- sessão de mover começa na posição atual; descartar a sessão equivale a cancelar

**`test_build_mode.gd` — 14 testes**
- entrar em construção limpa o painel de seleção *(regressão)*
- toque: dois toques no mesmo piso posicionam; tocar em outro piso só move a prévia
- mouse: a prévia segue o cursor e um clique posiciona
- lugar inválido: prévia vermelha, motivo na barra, Confirmar desabilitado, Esc cancela sem deixar nada
- girar durante a construção (tecla R) e confirmar com Enter
- selecionar móvel mostra Mover/Girar/Remover/Fechar; mover pela barra; cancelar movimento
- girar no lugar com recusa explicada; remover com Delete
- botões do catálogo e Cancelar pela barra; arrastar a câmera em construção não posiciona

**`test_cafe_scene.gd` — 11 testes**
- a cena inicia com grid 8×8 vazio e entrada marcada
- a câmera enquadra a cafeteria inteira entre as barras e reduz o zoom em tela baixa
- clique seleciona o piso certo, atualiza o destaque e avisa o EventBus uma única vez
- clique fora do grid limpa a seleção
- arrastar o mouse move a câmera e não seleciona
- tremida pequena do dedo ainda conta como toque
- zoom pela roda respeita mínimo e máximo
- o zoom mantém fixo o ponto sob o cursor
- pinça com dois dedos dá zoom proporcional e não seleciona
- a câmera não sai dos limites da cafeteria

### Verificação dos próprios testes

Para garantir que a suíte pega defeitos de verdade, cinco bugs foram inseridos de propósito, um de cada vez: segundo toque não confirma, sem checagem de acesso, entrada liberada, móvel movido continua visível, Confirmar sempre habilitado. Os testes reprovaram todos. A regressão do painel de seleção também falha quando a correção é removida.

## Roteiro de teste manual — Fase 1

Rode o jogo (F5) e confira:

1. [ ] O jogo abre sem janela de erro. O piso quadriculado aparece centralizado.
2. [ ] Clicar num piso destaca **aquele** piso, e o painel mostra as coordenadas dele.
3. [ ] Clicar fora do piso tira o destaque.
4. [ ] Arrastar com o botão esquerdo move a visão **e não** seleciona nada ao soltar.
5. [ ] A roda do mouse aproxima e afasta. O ponto sob o cursor fica parado enquanto o zoom muda.
6. [ ] Não é possível arrastar a cafeteria para fora da tela.
7. [ ] Ao redimensionar a janela (ou maximizar), o piso continua visível e o painel continua legível.
8. [ ] Na barra de baixo, clique em **Fogão**. Passe o mouse pelo piso: a prévia segue o cursor, verde onde pode.
9. [ ] Clique num piso verde: o fogão aparece e a barra volta a mostrar o catálogo.
10. [ ] Escolha **Balcão**, aperte **R** (ou **Girar**) e veja ele trocar de direção antes de posicionar.
11. [ ] Tente pôr algo no piso azul da entrada: prévia vermelha e a barra diz que a entrada precisa ficar livre.
12. [ ] Coloque uma **Mesa** num canto e cerque os dois lados com **Planta**s: a segunda planta é recusada ("deixaria outro móvel sem acesso").
13. [ ] Clique num móvel: ele ganha contorno laranja e a barra mostra Mover/Girar/Remover/Fechar. Teste **Mover** (o original some e reaparece no novo lugar) e **Remover**.
14. [ ] Esc cancela a construção sem deixar nada no piso.
15. [ ] Sensação: arrasto, zoom e posicionamento são confortáveis? Rápidos ou lentos demais? Algo confuso? *(anote para ajuste)*

Os itens de toque (pinça, arrasto com dedo) serão conferidos no celular quando houver build Android.

## Bug report

Use o formato da seção 88 do master prompt. Severidades: `BLOCKER`, `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`.
