# Passagem para o Claude Code (30/09/2026)

Até aqui, o projeto foi feito numa conversa do Claude (app) com o PO, de 29 a 30/09/2026, num computador na nuvem. A partir de agora ele continua no **Claude Code**, nesta pasta do PC do PO. A conversa não vem junto: o que importa dela está registrado nos arquivos abaixo.

## Primeiro passo no PC: recuperar o histórico

A pasta chegou ao PC sem a pasta oculta `.git`, porque as ferramentas remotas não podem gravar nela. Todo o histórico (os commits de 29 e 30/09) veio no arquivo `cafe-manie.bundle`, na raiz do projeto. Na primeira sessão, o Claude Code roda, dentro da pasta do projeto:

```bash
git init -b main                                   # cria o repositório vazio
git fetch ./cafe-manie.bundle main                 # traz todos os commits do arquivo
git update-ref refs/heads/main FETCH_HEAD          # aponta a branch main para o último commit
git reset                                          # alinha o índice com os arquivos que já estão na pasta
git remote add origin https://github.com/eliashenr/cafe-manie
git status                                         # deve mostrar só o cafe-manie.bundle como novo
```

Depois disso, o `cafe-manie.bundle` pode ser apagado. Esse caminho foi testado: com os arquivos da pasta e o bundle, o `git status` fica limpo e o `git log` mostra o histórico inteiro.

## Por onde começar

1. [CLAUDE.md](../CLAUDE.md): regras do projeto.
2. [master-prompt.md](master-prompt.md): o contrato.
3. [status.md](status.md): onde paramos.
4. [roadmap.md](roadmap.md): as fases.
5. [decisions.md](decisions.md): decisões DT-001 a DT-029.

Quando o PO disser **CONTINUE**, siga o CLAUDE.md: leia o status e o roadmap e continue de onde parou.

## Como o PO trabalha (combinado na conversa)

- Fala português e é o **Product Owner**: ele define visão e prioridades, o Claude decide a engenharia.
- **Não usa terminal.** Todo passo que ele precisar fazer vem explicado: o que faz e por quê.
- Prefere **passo a passo com pontos de conferência visual** e **opções** a uma resposta única.
- Quer **nostalgia do Café Mania** acima de um visual moderno, mas sem copiar a arte do jogo antigo (DT-029).

## O que já foi entregue

- **Fases 0 a 4**: grid isométrico, câmera, modo de construção, cozinha, balcão, clientes, garçom com caminho, Café Ouro, XP e níveis, save versionado, loja, inventário, venda, expansão, paredes e revestimentos, beleza, missões com tutorial, conquistas, recompensa diária, nome da cafeteria e sons.
- **Vertical Slice validada pelo PO** em 29/09/2026 ("joguei e gostei").
- **Builds**: `.exe` para Windows (entregue como instalador de 7-Zip) e APK Android arm64.
- **260 testes automatizados** passando no último commit.

## Direção visual

| Versão | Resultado | Retorno do PO |
|---|---|---|
| v1 | Reprovada | Móveis "ridículos", pessoas esquisitas, cabelos feios, comidas que não dava para reconhecer |
| v2 | Reprovada | "Apagado", árvores demais, olhos "100% falsos", cabeça "corcunda", cabelos ainda fracos |
| **v3** | **Aprovada em 30/09/2026** | "Gostei! Agora sim começamos conversar" |

- **Canvas** no Claude Design, "Café Manie — Direção Visual" (privado, na conta do PO): https://claude.ai/artifact/QbUPeotH9P32DLSKkVpWfF
- **Gerador da arte**: [tools/art_direction/v3](../tools/art_direction/v3/README.md). É Python e gera SVG. O mesmo código deve exportar os sprites do jogo.
- **Resumo da v3**: [art-direction.md](art-direction.md), seção "Versão 3".

## Próximos passos

1. **Levar a arte v3 para o jogo.** Exportar os sprites do gerador em PNG 2× e trocar os placeholders. Atenção à escala: o jogo usa piso de 128×64 (`IsoProjection.TILE_SIZE`) e a arte foi desenhada para 84×42.
2. **FAÇA BALANCEAMENTO.** O jogo está fácil demais: o robô faz 6 missões em 5,2 min.
3. **Teste no celular**, pelo roteiro "Android" em [qa.md](qa.md).
4. **Backend (Fase 6)**, antes de qualquer recurso social.

## O que muda ao sair da nuvem

| Item | Na nuvem | No PC do PO (Windows) |
|---|---|---|
| Godot | 4.7.2 para Linux, sem janela | Instalar a Godot 4.7.2 (ver o README). Para os testes, usar o executável terminado em `_console.exe`, que mostra a saída no terminal |
| Testes | `godot --headless -s res://tests/run_tests.gd` | O mesmo comando, trocando `godot` pelo caminho do `_console.exe` |
| Exportar `.exe` | Export templates 4.7.2 instalados | Instalar os templates na Godot (Editor → Manage Export Templates) |
| Exportar APK | JDK 21 e `apksigner` dos pacotes do Ubuntu | Instalar o JDK 17 ou mais novo e o Android SDK (build-tools com `apksigner`) |
| Chave de teste do APK | Ficou só na nuvem | Criar uma chave nova, **fora do repositório** (DT-028). O app de teste já instalado precisa ser desinstalado antes, porque a chave muda |
| GitHub | Envio recusado (403): faltava o app do Claude na conta | Do PC, com o login do PO, o `git push origin main` deve funcionar. Todos os commits estão na branch `main`. Se o GitHub recusar por já ter algum commit lá, integrar antes de enviar e nunca forçar sem o PO |
| Prévias da arte | Node, Playwright e as fontes Fredoka e Nunito | Opcional, só para conferir as pranchas fora do canvas |
