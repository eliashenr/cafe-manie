# CLAUDE.md

Instruções para qualquer sessão do Claude (Claude Code ou chat) que trabalhe neste repositório.

## Contrato

- [docs/master-prompt.md](docs/master-prompt.md) é o contrato principal do projeto. Siga-o.
- O dono do repositório é o **Product Owner**. Ele define visão e prioridades; você define a engenharia (seção 103).
- Comandos do PO (seções 162–167): **CONTINUE**, **TESTE**, **FAÇA QA**, **FAÇA CODE REVIEW**, **FAÇA BALANCEAMENTO**, **PREPARE RELEASE**.
- Em **CONTINUE**, comece lendo [docs/status.md](docs/status.md) e [docs/roadmap.md](docs/roadmap.md). Não recomece o projeto.
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

## Regras de engenharia do projeto

- **Regra vs. apresentação.** Regras de jogo ficam em `core/` como classes puras (`RefCounted`), sem nós nem tela. Cenas em `scenes/` só desenham e capturam entrada.
- **Sem números mágicos espalhados.** Todo número de gameplay é parâmetro: `@export` ou dado de conteúdo.
- **Comunicação entre sistemas** passa pelo autoload `EventBus`. Só declare ali sinais que mais de um sistema usa.
- **Placeholders** têm o prefixo `PLACEHOLDER_` no comentário do arquivo ou no nome do asset.
- **Testes.** Todo sistema em `core/` tem testes em `tests/unit/`. Fluxos de cena têm testes em `tests/integration/`. Em testes, envie entrada com `tree.root.push_input(evento, true)`: a janela headless tem 64×64, e sem o `true` as posições são reescaladas.
- **Scripts avulsos com `-s`** compilam antes dos autoloads existirem. Não use tipos que dependem do `EventBus` (como `Cafe`) com tipagem estática neles; carregue com `load()` e use variáveis sem tipo. O executor de testes já faz isso.
- **Conteúdo novo** (móveis etc.) entra como `.tres` em `data/`, nunca como `if` no código.
- **Nunca declare algo pronto sem rodar os testes** e subir a cena principal sem erros (seção 91).
- **Commits** no padrão `feat:`, `fix:`, `test:`, `docs:`, `refactor:`, `chore:` (seção 96).
- **Ao terminar uma etapa**, atualize [docs/status.md](docs/status.md) no formato da seção 102 e registre decisões novas em [docs/decisions.md](docs/decisions.md).
