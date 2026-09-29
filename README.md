# ☕ Café Manie

Jogo de gerenciamento de cafeteria, mobile-first (Android), feito em **Godot 4.7.2** com **GDScript**.

> Nome provisório. Status: **pré-produção — Fase 1 (protótipo)**.

O documento que manda em tudo é o [master prompt](docs/master-prompt.md). O estado atual está em [docs/status.md](docs/status.md).

---

## Como abrir e jogar o protótipo (Windows)

Você só precisa fazer isto uma vez.

**1. Instale a Godot 4.7.2**

- Acesse https://godotengine.org/download/archive/4.7.2-stable/
- Baixe **Windows – x86_64** da versão *Standard*. **Não** baixe a versão ".NET", que é para C#.
- É um `.zip`. Descompacte numa pasta, por exemplo `C:\Godot`. A Godot não tem instalador: o `.exe` já é o programa.

**2. Baixe o projeto**

- Opção mais simples: na página do repositório no GitHub, clique em **Code → Download ZIP** e descompacte.
- Opção recomendada para acompanhar as atualizações: instale o [GitHub Desktop](https://desktop.github.com/), faça login e use **File → Clone repository → cafe-manie**. Para pegar as atualizações depois, basta clicar em **Fetch origin** e depois em **Pull**.

**3. Abra na Godot**

- Abra o `.exe` da Godot.
- Clique em **Import** (Importar), navegue até a pasta do projeto e escolha o arquivo `project.godot`.
- Clique em **Import & Edit**. Na primeira vez a Godot leva alguns segundos preparando os arquivos.

**4. Rode o jogo**

- Aperte **F5**, ou clique no botão ▶ no canto superior direito.

### O que dá para fazer hoje

| Ação | Mouse | Toque |
|---|---|---|
| Mover a visão | Arrastar com o botão esquerdo | Arrastar com um dedo |
| Zoom | Roda do mouse | Pinça com dois dedos |
| Selecionar um piso | Clique rápido | Toque rápido |

---

## Estrutura

```text
autoload/     serviços globais (hoje: EventBus)
core/         regras do jogo sem tela — testáveis sozinhas
  grid/       grid lógico e projeção isométrica
scenes/       o que aparece na tela
  cafe/       cena principal, câmera e piso
  ui/         interface
tests/        testes automatizados (unit/ e integration/)
docs/         documentação do projeto
```

Os detalhes de arquitetura estão em [docs/architecture.md](docs/architecture.md).

## Testes automatizados

Quem desenvolve roda os testes antes de cada commit. Na pasta do projeto:

```bash
godot --headless --import
godot --headless -s res://tests/run_tests.gd
```

- O primeiro comando prepara o projeto sem abrir janela (`--headless` significa "sem tela").
- O segundo roda todos os arquivos `tests/**/test_*.gd` e mostra `PASSOU` ou `FALHOU` para cada teste.
- O processo termina com código `0` se tudo passar e `1` se algo falhar. Um erro de script no meio de um teste também conta como falha.

## Documentação

| Documento | Conteúdo |
|---|---|
| [master-prompt.md](docs/master-prompt.md) | Contrato do projeto: visão, regras e roadmap |
| [status.md](docs/status.md) | Último relatório de status |
| [architecture.md](docs/architecture.md) | Arquitetura e princípios técnicos |
| [decisions.md](docs/decisions.md) | Registro de decisões técnicas |
| [roadmap.md](docs/roadmap.md) | Fases e marcos |
| [qa.md](docs/qa.md) | Estratégia de testes e roteiro de teste manual |
| [gameplay.md](docs/gameplay.md) | Regras de gameplay decididas |
| [economy.md](docs/economy.md) | Economia e moedas |
| [progression.md](docs/progression.md) | Níveis, XP e desbloqueios |
| [social.md](docs/social.md) | Sistemas sociais (futuro) |
