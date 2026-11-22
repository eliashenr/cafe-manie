# AGENTS.md

Instruções para o Codex neste repositório. O Codex pode reescrever este arquivo; ele foi criado pelo Claude só para
apontar o caminho na passagem de 22/11/2026.

- **Leia primeiro [docs/divisao-claude-codex.md](docs/divisao-claude-codex.md).** Ali estão a divisão de trabalho que o PO decidiu, os arquivos de cada um, os arquivos compartilhados, o estado do ramo `etapa-natal` e as pendências.
- **O contrato do projeto** é [docs/master-prompt.md](docs/master-prompt.md). As regras de engenharia e os comandos (testes, cena principal, exportação) estão no [CLAUDE.md](CLAUDE.md) e valem para os dois.
- **O PO não usa terminal.** Explique em português, sem jargão, o que cada passo faz e por quê.
- **O save pessoal do PO nunca muda.** A Godot roda com `APPDATA` apontando para outra pasta; os scripts de `tools/revisao/` já fazem isso.
- **Nada de janela na frente do PO:** testes com `--headless`, fotos com janela oculta.
- **Commit e envio só depois do "Pode enviar" do PO**, com a conta `eliashenr` do GitHub.
- **Antes de mexer num arquivo do Claude ou num compartilhado**, combine (pelo PO ou na seção 5 de `docs/divisao-claude-codex.md`).
