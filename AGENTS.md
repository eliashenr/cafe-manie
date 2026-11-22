# AGENTS.md

Instruções para o Codex neste repositório. O Codex pode reescrever este arquivo; ele foi criado pelo Claude só para
apontar o caminho na passagem de 22/11/2026.

- **Leia primeiro [docs/divisao-claude-codex.md](docs/divisao-claude-codex.md).** Ali estão a divisão de trabalho que o PO decidiu, os arquivos de cada um, os arquivos compartilhados, o estado do ramo `etapa-natal` e as pendências.
- **Passagem visual atual:** [docs/passagem-visual-codex.md](docs/passagem-visual-codex.md). DT-105 e DT-106 estão na main. O PO aprovou também a DT-111 e autorizou explicitamente seu envio e integração em 22/11/2026. Preservar os conjuntos aprovados e combinar arquivos compartilhados.
- **Histórico DT-107:** montagem modular reprovada: pescoço cobre a gola e chapéu não veste a cabeça. Não publicar essa montagem como aprovada. O chef canônico completo foi corrigido e aprovado nas DT-109/110; variantes ainda pendentes. Ramo `codex/chef-loja`, base `cac07e8`; preservar sprites aprovados e experimentos herdados.
- **Pesquisa DT-108:** [docs/estudo-cafe-mania-original.md](docs/estudo-cafe-mania-original.md), com fontes e limites. As propostas de organização orientaram a DT-111. O PO considera a estrutura boa; não usar valores históricos como balanceamento aprovado.
- **Publicação DT-111 autorizada:** o PO aprovou Loja/Reforma, HUD e Cidade e pediu enviar e integrar à main. Pacote limpo em `build/publicacao-dt111/repo`, ramo `codex/loja-hud-cidade`, preservando a revisão local e experimentos no ramo `codex/chef-loja`. O pacote usa chef canônico aprovado e desenho legado da main para variantes; exclui compositor, PNGs, shader e importador modular DT-107. Preservar intacta `art/avatar/chef_vestido_v1.png`. Revisão integrada: `Revisar Interface Completa.cmd`. Variantes completas continuam pendentes, fora do aceite canônico. Conferir confirmação remota no topo de `docs/status.md` antes de repetir um envio.
- **O contrato do projeto** é [docs/master-prompt.md](docs/master-prompt.md). As regras de engenharia e os comandos (testes, cena principal, exportação) estão no [CLAUDE.md](CLAUDE.md) e valem para os dois.
- **O PO não usa terminal.** Explique em português, sem jargão, o que cada passo faz e por quê.
- **O save pessoal do PO nunca muda.** A Godot roda com `APPDATA` apontando para outra pasta; os scripts de `tools/revisao/` já fazem isso.
- **Nada de janela na frente do PO:** testes com `--headless`, fotos com janela oculta.
- **Commit e envio só depois do "Pode enviar" do PO**, com a conta `eliashenr` do GitHub.
- **Antes de mexer num arquivo do Claude ou num compartilhado**, combine (pelo PO ou na seção 5 de `docs/divisao-claude-codex.md`).
