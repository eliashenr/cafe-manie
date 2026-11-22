# CLAUDE.md

Instruções para qualquer sessão do Claude (Claude Code ou chat) que trabalhe neste repositório.

## Contrato

- [docs/master-prompt.md](docs/master-prompt.md) é o contrato principal do projeto. Siga-o.
- O dono do repositório é o **Product Owner**. Ele define visão e prioridades; você define a engenharia (seção 103).
- Comandos do PO (seções 162–167): **CONTINUE**, **TESTE**, **FAÇA QA**, **FAÇA CODE REVIEW**, **FAÇA BALANCEAMENTO**, **PREPARE RELEASE**.
- Em **CONTINUE**, comece lendo [docs/continuar.md](docs/continuar.md) (onde o trabalho parou e os comandos prontos), depois [docs/status.md](docs/status.md) e [docs/roadmap.md](docs/roadmap.md). Não recomece o projeto.
- Ao terminar uma sessão, reescreva a seção "Onde paramos" de [docs/continuar.md](docs/continuar.md).
- O plano geral (código, arte, jogabilidade e processo) está em [docs/revisao-geral.md](docs/revisao-geral.md).
- **Eventos do calendário:** no início de toda sessão, confira a data de hoje com [docs/eventos.md](docs/eventos.md). Se um evento começa em menos de 6 semanas e ainda não está em `data/events/`, avise o PO e proponha prepará-lo antes de qualquer outra tarefa (regra do PO, 20/11/2026).
- **Divisão com o Codex (regra do PO, 22/11/2026):** o Codex cuida da direção visual, dos personagens e da interface; o Claude, das regras, da economia, dos saves e do conteúdo. Antes de alterar sprites, geradores de arte ou arquivos de apresentação, combine quais arquivos cada um vai editar. A divisão, o estado e as pendências ficam em [docs/divisao-claude-codex.md](docs/divisao-claude-codex.md); leia no início de toda sessão.
- **Primeira sessão no PC do PO?** Leia antes [docs/passagem.md](docs/passagem.md): o que veio da conversa na nuvem e o que muda no Windows.
- O PO não usa terminal. Toda instrução para ele explica o que cada passo faz e por quê.

## Stack

- Godot **4.7.2 stable**, GDScript. Nada de C# ou GDExtension sem justificativa registrada em [docs/decisions.md](docs/decisions.md).
- Renderer `mobile`. Viewport base 1280×720, stretch `canvas_items` + `expand`.

## Comandos

```bash
godot --headless --import                        # prepara o projeto (rodar após clonar ou criar classes)
godot --headless -s res://tests/run_tests.gd     # roda todos os testes; sai com 1 se algo falhar
godot --headless --quit-after 120                # sobe a cena principal por 120 frames (checa erros)
```

No Windows, troque `godot` pelo caminho do executável `Godot_v4.7.2-stable_win64_console.exe` (a versão `_console` mostra a saída no terminal).

## Regras de engenharia do projeto

- **Regra vs. apresentação.** Regras de jogo ficam em `core/` como classes puras (`RefCounted`), sem nós nem tela. Cenas em `scenes/` só desenham e capturam entrada.
- **Sem números mágicos espalhados.** Todo número de gameplay é parâmetro: `@export` ou dado de conteúdo.
- **Comunicação entre sistemas** passa pelo autoload `EventBus`. Só declare ali sinais que mais de um sistema usa.
- **Placeholders** têm o prefixo `PLACEHOLDER_` no comentário do arquivo ou no nome do asset.
- **Testes.** Todo sistema em `core/` tem testes em `tests/unit/`. Fluxos de cena têm testes em `tests/integration/`. Em testes, envie entrada com `tree.root.push_input(evento, true)`: a janela headless tem 64×64, e sem o `true` as posições são reescaladas.
- **Testes de cena** usam `CafeTestCase.spawn_cafe()`, que injeta uma `quiet_simulation()` (cafeteria vazia, relógio manual, sem clientes). Para atendimento, avance `clock` e chame `simulation.tick()` à mão.
- **Tempo:** nada de `Time`/`OS` direto na lógica; use o `GameClock` da simulação (com backend, vira horário do servidor).
- **Scripts avulsos com `-s`** compilam antes dos autoloads existirem. Não use tipos que dependem do `EventBus` (como `Cafe`) com tipagem estática neles; carregue com `load()` e use variáveis sem tipo. O executor de testes já faz isso.
- **Conteúdo novo** (móveis etc.) entra como `.tres` em `data/`, nunca como `if` no código.
- **Mensagens na tela** entram numa fila no HUD. Em testes, use `all_messages(cafe)` para ver o aviso atual e os que esperam.
- **Efeitos visuais** (shaders, Tweens, partículas) ficam em `scenes/fx/` e `art/shaders/`, como nós filhos ou funções prontas que as cenas ligam e desligam (DT-044). Só `CPUParticles2D`; nada de efeito em `core/`. Animação de interface mexe só em escala e transparência, nunca no tamanho ou posição da área de toque.
- **Janelas de pergunta:** só uma por vez (`Cafe.is_dialog_open()`). Toda compra imediata pede confirmação com Cancelar já selecionado.
- **O executor reprova arquivo de teste que não compila.** Se a contagem de testes cair, investigue.
- **Exportar:** `godot --headless --export-release "Windows" build/windows/CafeManie.exe` e confira com `godot --headless --main-pack build/windows/CafeManie.exe -- --smoke-check`. Android: ver README (chave por variáveis de ambiente, nunca no repositório).
- **Nunca declare algo pronto sem rodar os testes** e subir a cena principal sem erros (seção 91).
- **Commits** no padrão `feat:`, `fix:`, `test:`, `docs:`, `refactor:`, `chore:` (seção 96).
- **Ao terminar uma etapa**, atualize [docs/status.md](docs/status.md) no formato da seção 102 e registre decisões novas em [docs/decisions.md](docs/decisions.md).
