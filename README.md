# ☕ Café Manie

Jogo de gerenciamento de cafeteria, mobile-first (Android), feito em **Godot 4.7.2** com **GDScript**.

> Nome provisório. Status: **Vertical Slice jogável** (cozinhar, atender, loja, inventário, expansão e missões iniciais), aguardando a validação do PO.

O documento que manda em tudo é o [master prompt](docs/master-prompt.md). O estado atual está em [docs/status.md](docs/status.md).

---

## Jogar no Windows sem instalar nada (recomendado)

1. Baixe o arquivo **`CafeManie-Windows.zip`** que o Claude enviou na conversa.
2. Clique com o botão direito nele → **Extrair tudo…** → **Extrair**. Isso cria uma pasta com o `CafeManie.exe` dentro.
3. Dê dois cliques em **`CafeManie.exe`**.
4. Na primeira vez o Windows pode mostrar **"O Windows protegeu o computador"**. Isso acontece com todo programa que não tem uma assinatura digital paga, e não quer dizer que haja algo errado. Clique em **Mais informações** e depois em **Executar assim mesmo**. O aviso não volta depois.

O jogo salva sozinho em `%APPDATA%\Godot\app_userdata\Café Manie\` (cole esse caminho na barra de endereço do Explorador de Arquivos para ver a pasta). Um `.exe` novo continua o mesmo save.

## Abrir o projeto na Godot (para quem vai editar)

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

| Ação | Mouse / teclado | Toque |
|---|---|---|
| Mover a visão | Arrastar com o botão esquerdo | Arrastar com um dedo |
| Zoom | Roda do mouse | Pinça com dois dedos |
| Selecionar piso ou móvel | Clique rápido | Toque rápido |
| Posicionar um móvel | Botão do móvel na barra de baixo, depois clique no piso | Botão do móvel, depois toque duas vezes no mesmo piso (ou toque e **Confirmar**) |
| Girar | **R** ou botão **Girar** | Botão **Girar** |
| Confirmar / cancelar | **Enter** / **Esc** | **Confirmar** / **Cancelar** |
| Mover ou guardar um móvel | Selecione-o e use **Mover** / **Guardar** (ou **Delete**) | Selecione-o e use **Mover** / **Guardar** |

### Cozinhar e atender

1. Toque num **fogão** e escolha uma receita. Os ingredientes custam Café Ouro.
2. Quando a etiqueta ficar verde ("pronto!"), toque no fogão para levar o prato ao **balcão**.
3. Os clientes entram, sentam nas cadeiras ao lado das mesas e pedem o que houver no balcão. O garçom leva.
4. Cliente servido paga, dá XP e popularidade. Cliente que espera demais vai embora irritado.

### Loja, missões e expansão

- O **cartão no canto direito** mostra a missão atual e uma dica. São 6 missões iniciais que ensinam o jogo, cada uma com recompensa em Café Ouro e XP.
- A **barra de baixo** é a loja: cada botão mostra o preço, o nível necessário ou quantos você tem guardados. O móvel só é cobrado quando você confirma o lugar dele. Cancelar não custa nada.
- **Guardar** tira o móvel da cafeteria e leva para o inventário. Colocar de volta é grátis.
- **Expandir** aumenta a cafeteria (a partir do nível 2). Antes de cobrar, o jogo pergunta, e o botão já selecionado é o **Cancelar**.

### Save

O jogo salva sozinho: ao mudar algo (no máximo a cada 5 s) e na hora em que você minimiza ou fecha. Ao reabrir, tudo volta como estava, e o que estava no fogão continuou cozinhando. Para começar do zero, use **Recomeçar** no canto de cima (ele pede confirmação).

O piso azul com a seta é a **entrada**. Ela não pode ser ocupada, e nenhum móvel que cliente ou garçom usam pode ficar sem caminho até ela. Quando uma posição é recusada, a prévia fica vermelha e a barra explica o motivo.

---

## Estrutura

```text
autoload/     serviços globais (hoje: EventBus)
core/         regras do jogo sem tela — testáveis sozinhas
  grid/       grid lógico e projeção isométrica
  furniture/  definição de móvel e catálogo
  cafe/       layout da cafeteria (posicionamento) e sessão de construção
  cooking/    receitas e cozinha (fogões e balcões)
  service/    atendimento: simulação, clientes, garçom, navegação, configs
  economy/    carteira de moedas e inventário
  progression/ XP, níveis e missões
  time/       relógio do jogo
  save/       formato do save e gravação em disco
data/         conteúdo editável no inspetor da Godot
  furniture/  um arquivo .tres por móvel (preço, nível, tamanho...)
  recipes/    receitas (tempo, porções, custo, preço, XP, nível)
  customers/  tipos de cliente
  progression/ curva de níveis
  missions/   missões iniciais (tutorial)
  config/     parâmetros do atendimento, do jogo novo e das expansões
scenes/       o que aparece na tela
  cafe/       cena principal, câmera, piso e móveis
  ui/         interface
  debug/      checagem automática do jogo exportado
tests/        testes automatizados (unit/, integration/ e support/)
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

## Gerar o jogo para Windows (exportar)

Precisa dos *export templates* da Godot 4.7.2 instalados (na Godot: **Editor → Manage Export Templates → Download and Install**). Depois:

```bash
godot --headless --export-release "Windows" build/windows/CafeManie.exe
godot --headless --main-pack build/windows/CafeManie.exe -- --smoke-check
```

- O primeiro comando gera um `.exe` único, com todo o conteúdo dentro.
- O segundo abre o conteúdo desse `.exe` sem janela, roda alguns segundos de jogo e imprime `SMOKE OK` (ou `SMOKE FALHOU` com o motivo). Ele não mexe no save.

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
