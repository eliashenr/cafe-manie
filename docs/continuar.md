# Como continuar (guia para a próxima sessão)

Este arquivo existe para a próxima sessão do Claude (qualquer modelo) retomar o trabalho sem depender da conversa anterior.
Atualizado em 11/11/2026. Se este guia e o [status.md](status.md) discordarem, vale o que o `git log` e o `git status` mostrarem.

> **22/11/2026: leia antes [divisao-claude-codex.md](divisao-claude-codex.md).** O Codex assumiu a direção visual, os personagens e a interface; o Claude ficou com regras, economia, saves e conteúdo. O estado do ramo `etapa-natal` e as pendências estão lá. As rodadas de personagem abaixo (DT-101) ficam como histórico.

## 1. Regras que não podem ser quebradas

| Regra | Detalhe |
|---|---|
| Conta do GitHub | Só `eliashenr` (repositório `eliashenr/cafe-manie`). Existe outro login no `gh`, `eliasboncourage`, que **não** deve ser usado. Confira com `gh auth status` antes de qualquer `git push` |
| Save pessoal do PO | `%APPDATA%\Godot\app_userdata\Café Manie\save.json`, com horário de 31/10/2026 às 23:33:27. Nunca pode mudar. Todo comando da Godot roda com `APPDATA` apontando para outra pasta (os scripts de `tools/revisao/` já fazem isso) |
| Nenhuma janela na tela do PO | Testes com `--headless`; fotos com janela oculta; a janela de revisão abre uma vez, minimizada, no fim de cada etapa |
| Commit e envio | Só quando o PO pedir ("Pode enviar"). Commits em inglês, no padrão `feat:`, `fix:` etc. |
| Economia e saves | Ids, preços, níveis, pegadas, economia e formato do save não mudam no redesenho. `data/` e `core/` não entram nas etapas de arte |
| Aprovação visual | Nenhuma etapa de arte é declarada pronta antes de o PO ver no jogo e aprovar |
| O PO não usa terminal | Toda instrução para ele explica o que cada passo faz e por quê, em português |

## 2. Ferramentas neste PC

| Ferramenta | Caminho |
|---|---|
| Godot (testes e fotos) | `C:\Godot\Godot_v4.7.2-stable_win64_console.exe` |
| Godot (janela de revisão) | `C:\Godot\Godot_v4.7.2-stable_win64.exe` |
| Blender | `C:\Blender\blender-5.2.3-windows-x64\blender.exe` (com MPFB 2.0.18 e os pacotes do MakeHuman já instalados) |
| Projeto | `C:\Projetos\cafe-manie`, ramo `amostra-a-2` |

Scripts prontos em `tools/revisao/` (rodar com `powershell -File`):

| Script | O que faz |
|---|---|
| `testes.ps1` | Importa o projeto, roda todos os testes e sobe a cena principal por 120 quadros, sem janela. Mostra o horário do save pessoal no fim |
| `foto.ps1` | Tira uma foto do jogo com a janela oculta. Parâmetros: `-Script`, `-Out`, `-Variant`, `-Time dia|noite`, `-Mode fixa` |
| `revisar.ps1` | Abre a janela de revisão do PO, minimizada (`-Variant mostruario`). Tecla N troca dia e noite; loja toda liberada; nada é salvo |
| `folha.ps1` | Monta uma folha com várias fotos de `art/sprites` lado a lado, para conferir um lote |
| `superficies.gd`, `enfeites.gd`, `assentos.gd`, `cozinha.gd`, `loja.gd` | Cenas de conferência, usadas com `foto.ps1` (`-Script res://tools/revisao/superficies.gd -Variant surf:0`) |

Os dados isolados e os registros ficam em `build/revisao/`, que o git ignora.
> **Atenção ao rodar os scripts `.ps1`:** este Windows bloqueia `powershell -File` (política de execução). Rode de dentro do PowerShell com `& 'C:\Projetos\cafe-manie\tools\revisao\testes.ps1'`, ou use `powershell -ExecutionPolicy Bypass -File ...`.

## 3. Como é uma etapa de arte, do começo ao fim

1. O PO libera: "Pode começar".
2. Escrever ou ajustar os modelos em `tools/render3d/` (Python do Blender).
3. Rascunho: `blender.exe -b -P tools/render3d/<script>.py -- <grupo> rascunho prova`. **Um processo do Blender por vez**: dois juntos disputam o `art/sprites/sprites.json`.
4. Conferir no jogo com `tools/revisao/foto.ps1` (janela oculta) e ler as fotos. Folhas de fotos soltas não mostram emenda nem a luz do salão.
5. Fotos finais: o mesmo comando sem `rascunho` e sem `prova`. Demora (a etapa de pisos e portas levou cerca de 1 h 30).
6. `tools/revisao/testes.ps1`: precisa dar 739 testes aprovados (ou mais), cena principal com saída 0 e o save pessoal com o horário de sempre.
7. Atualizar `docs/status.md`, `docs/roadmap.md`, `docs/decisions.md` (uma DT nova) e `docs/art-direction.md`.
8. Abrir a revisão com `tools/revisao/revisar.ps1` e avisar o PO de que a janela está minimizada na barra de tarefas.
9. O PO aprova ou pede ajustes. Só depois de "Pode enviar": conferir `gh auth status` (conta ativa `eliashenr`), `git add` dos arquivos da etapa, commit e `git push origin amostra-a-2`.

## 4. Mapa dos scripts de arte (`tools/render3d/`)

| Arquivo | O que tem |
|---|---|
| `cena3d.py` | Câmera, luz (`rig="a"` é a luz quente da referência A), foto, recorte e gravação do `sprites.json` |
| `moveis3d.py` | Peças e materiais básicos (`box`, `cylinder`, `sphere`, `tube`, `solid`, `emission`, `fabric`) |
| `enfeites3d.py` | Peças compartilhadas de plantas e vidros (`leaf`, `rosette`, `foliage`, `glass`, `torus`, `cone`) |
| `amostra_a3d.py` | Os itens da amostra aprovada (DT-091) e os materiais novos (`rich_wood`, `grain_wood`, `leather`, `brushed_steel`, `cast_iron`) |
| `assentos_a3d.py` | Cadeiras e mesas (DT-093) |
| `cozinha_a3d.py` | Fogões e balcões (DT-094) |
| `enfeites_a3d.py` | Enfeites e máquinas (DT-095) |
| `superficies_a3d.py` | **Etapa atual (DT-096):** pisos, paredes, itens de parede, portas e terraço |
| `superficies3d.py`, `cidade3d.py`, `personagens3d.py` | Catálogo anterior de superfícies (base de medidas), cidade e personagens |

Medidas que nunca mudam (o jogo depende delas): altura da parede (`S.WALL_Z`), tampo da mesa, tampo do balcão, bocas do fogão, assento a 0,41, âncoras gravadas pelo `cena3d.shoot`.

## 5. Onde paramos (atualizado em 13/11/2026)

### Estado do git

- **Histórico:** o trabalho de arte foi feito no ramo `amostra-a-2` e juntado na `main` em 19/11/2026. Ver "Onde paramos (19/11/2026, depois da junção)" no fim deste arquivo.
- `main` continua em `bb843d6`, sem o redesenho.
- A rodada de 14/11 (retrato do chef, pratos e panelas) foi **enviada em 16/11/2026** no commit `feat: reference A chef portrait, dishes and cookware in 3D`, logo depois de `78e2e33`. Confira com `git log --oneline -3`; `git status --short` tem de vir vazio.
- Há três logins no `gh`: `eliashenr` (o único permitido), `eliasboncourage` e `Chiebao`. Confira qual está ativo antes de qualquer envio.

### Etapa concluída: pisos, paredes, itens de parede, portas e terraço (DT-096)

| Passo | Situação |
|---|---|
| Modelos escritos | Feito |
| Defeito dos pisos pretos | Corrigido: em `_image`, o espaço de cor tem de ser definido **antes** de gravar os pixels |
| Rascunho conferido no jogo | Feito para os pisos dos lotes 0 a 4 e todas as paredes. Itens e portas vistos em folha |
| Ajustes depois do rascunho | Azulejo azul mais azul, cimento queimado mais cinza, granilite com menos lascas |
| Fotos finais | Geradas (`SUPERFICIES OK 191` em `build/revisao/render_final.log`) |
| Testes com as fotos finais | Feito em 13/11: 739 aprovados, cena principal com saída 0 |
| Conferência das fotos finais no jogo | Feita por fotos: todos os pisos e paredes de dia (lotes 0 a 4 ainda no rascunho; 5 a 9 já finais), o lote 0 à noite, os 27 itens de parede pendurados e as portas francesa e mexicana. **Falta:** as outras 10 portas no café, as portas fechadas e o terraço montado |
| Documentos (status, roadmap, DT-096, art-direction) | Feitos em 13/11 |
| Revisão do PO | **Aprovados em 13/11/2026** e enviados ao GitHub no commit `fe416d4` |

### Como conferir o que falta (comandos prontos)

Dentro do PowerShell:

```powershell
$f = 'C:\Projetos\cafe-manie\tools\revisao\foto.ps1'
$o = 'C:\Projetos\cafe-manie\build\revisao'
# Pisos e paredes: lotes de 0 a 9 (4 pisos por lote, em quadrantes; 4 paredes por lote)
foreach ($b in 5..9) { & $f -Script 'res://tools/revisao/superficies.gd' -Out "$o\s$b.png" -Variant "surf:$b" -Time dia -Mode fixa }
# De noite: trocar -Time dia por -Time noite
```

Depois, ler cada `build\revisao\s<N>.png` com a ferramenta de leitura de imagem.

Para os itens de parede e as portas colocados no café, use `tools/revisao/parede.gd` com a variante `parede:<lote>:<porta>` (lote 0 ou 1; porta: `frances`, `japones`, `italiano`, `anos70`, `americano`, `anos2010`, `festa`, `anos80`, `balada`, `brasileiro`, `country`, `mexicano` ou `classico`). Ela usa:
- pendurar com `style.own(id)` e `style.hang([style.segment(style.EDGE_TOP, i)] as Array[String], id)` (e `EDGE_LEFT`);
- trocar a porta com `style.own(door_id)` e `style.set_door(door_id)` (ids em `data/doors/`, por exemplo `door_frances`).

### Pontos a olhar com atenção nas fotos finais

| Item | O que observar |
|---|---|
| Toldos das portas (francesa, italiana, anos 70, diner, festa, brasileira) | As listras de alto contraste podem parecer ripas soltas, e não lona. Se parecer, baixar o contraste das duas cores em `wedge()` |
| Plaquinha ABERTO | Fica escondida atrás do toldo nas portas com toldo. A porta clássica já aprovada tem o mesmo comportamento, então não é defeito novo |
| `tv` | A imagem da tela é uma mancha; a xícara mal se lê. Simplificar o desenho em `flat_tv()` |
| `janela_groovy` e `janela_neon` | O vidro é uma cor chapada. Pode ganhar um degradê |
| `janela_festa` | Bandeirinhas pequenas e cortina roxa pesada |
| `floor_mirror` (Piso Espelhado) | Parece um vidro escuro, sem leitura de espelho. Clarear o reflexo em `mirror_tex()` |
| `floor_blue_tiles` (Azulejo azul) | Fica acinzentado à noite. Se o PO reclamar, saturar mais o azul |
| `floor_talavera` | O azul da pintura lê como quase preto sob a luz quente. Pode clarear `#21508f` |
| `floor_oak_light` | Saiu alaranjado sob a luz quente. Se destoar do nome "Carvalho Claro", clarear a base `#c79a63` |
| Variações de piso | Em pisos com mais de uma foto (madeiras, mármores, granilites), conferir que não há emenda visível entre variações vizinhas |

### Pergunta pendente para o PO

A "Janela com Cortina" da amostra aprovada (DT-091) não tem cortina: só caixilho e peitoril. Perguntar na revisão desta etapa se ele quer a cortina ou se mantém.

### Depois que o PO aprovar esta etapa

Seguir o plano da seção 5 de [revisao-geral.md](revisao-geral.md), sempre com a liberação dele:

1. Teste de sanidade da arte (um teste que reprova foto vazia, preta ou estourada).
2. Gerar o APK e o PO fazer o roteiro "Android" do `qa.md`.
3. Panelas e pratos em 3D, depois retratos.
4. Juntar `amostra-a-2` em `main` e ligar os testes automáticos no GitHub.

### Última verificação

- **13/11/2026, depois da aprovação do PO:** 739 testes passaram, nenhum falhou; cena principal com saída 0; `data/` e `core/` sem mudança; janela de revisão fechada.
- Save pessoal do PO conferido: 31/10/2026 às 23:33.

### Se o PO pedir ajustes nesta etapa

1. Mexer só na receita do item em `tools/render3d/superficies_a3d.py` (dicionários `FLOORS`, `WALLS`, `WALL_ITEMS` e a função `door_a`).
2. Refazer só o item, pelo nome da foto. Exemplos:
   - um piso: `blender.exe -b -P tools/render3d/superficies_a3d.py -- piso_floor_mirror_0`
   - uma parede, os dois lados: `... -- parede_wall_club_R parede_wall_club_L`
   - um item de parede: `... -- enfeite_tv_R enfeite_tv_L`
   - uma porta, aberta e fechada, os dois lados: `... -- enfeite_porta_festa_R enfeite_porta_festa_L enfeite_porta_festa_fechada_R enfeite_porta_festa_fechada_L`
   - um grupo inteiro: `... -- pisos` (ou `paredes`, `itens`, `portas`, `terraco`)
3. Rodar `tools/revisao/testes.ps1`, tirar as fotos de conferência e reabrir a revisão.

### Modelo de envio (usado em 13/11; repetir nas próximas etapas)

```bash
gh auth status                       # a conta ativa tem de ser eliashenr
git -C C:/Projetos/cafe-manie status --short -- data core      # tem de vir vazio
git -C C:/Projetos/cafe-manie add art/sprites docs tools/render3d/superficies_a3d.py tools/render3d/cena3d.py tools/revisao
git -C C:/Projetos/cafe-manie commit -m "feat: reference A floors, walls, wall items and doors with new materials"   # mais a linha Co-Authored-By do modelo em uso
git -C C:/Projetos/cafe-manie push origin amostra-a-2
```

Os documentos já registram a aprovação (feito em 13/11).

### Próximo passo

A etapa de arte está fechada. O próximo trabalho precisa da liberação do PO e segue a seção 5 de [revisao-geral.md](revisao-geral.md): primeiro o teste de sanidade da arte, e em paralelo o APK para o teste no celular. Os pontos fracos aceitos nesta etapa (TV, Piso Espelhado, Azulejo azul à noite) e a pergunta da "Janela com Cortina" continuam anotados acima.

### Rodada de 14/11/2026 (em andamento; pedido do PO: "Faz ambos e já foca também no personagem")

O PO pediu três coisas juntas e respondeu a duas perguntas:

| Pedido | Resposta do PO | Situação |
|---|---|---|
| Teste no celular | "Pode baixar": autorizou baixar e instalar em `C:\AndroidTools` os modelos de exportação da Godot 4.7.2, o Java JDK 17 e o kit do Android, aceitar a licença do Android SDK e criar uma chave de teste fora do repositório | Downloads em `C:\AndroidTools\downloads` (ver abaixo) |
| Personagem "xoxo e feio" da tela inicial | É **o retrato do chef** (canto de cima à esquerda e botão Chef), não o garçom | A fazer |
| Pratos e panelas em 3D | Liberado ("Faz ambos") | A fazer |

**Retrato do chef, como funciona hoje:** `scenes/ui/avatar_portrait.gd` empilha 3 camadas pela âncora: `avatar_roupa_<roupa>`, `avatar_cabeca_<pele>_<cabelo>` e `avatar_chapeu_<chapeu>`. São 6 roupas, 24 cabeças (4 peles × 6 cabelos) e 5 chapéus, em `art/sprites`, com caixa comum de 140×170 e âncora em (70, 110). As peças vêm de `data/avatar/*.tres` (campo `art`). A arte nova tem de manter esses nomes e esse encaixe por camadas.

**Android, passos planejados:**
1. Conferir o SHA-512 de `templates.tpz` contra `SHA512-SUMS.txt`.
2. Descompactar: JDK em `C:\AndroidTools\jdk17`; kit em `C:\AndroidTools\sdk\cmdline-tools\latest`; modelos em `<APPDATA isolado>\Godot\export_templates\4.7.2.stable` (o `.tpz` é um zip com a pasta `templates`).
3. `sdkmanager --licenses` e instalar `platform-tools`, `build-tools` e `platforms` nas versões que o `config.gradle` dos modelos pedir.
4. Chave de teste com `keytool` em `C:\AndroidTools\chaves\` (nunca no repositório, DT-028).
5. Exportar com as variáveis `GODOT_ANDROID_KEYSTORE_*` (ver README, seção Android) e as configurações do editor apontando para o JDK e o SDK, usando o APPDATA isolado.
6. Conferir o APK com `apksigner verify` e entregar ao PO com o roteiro "Android" do `qa.md`.

**Andamento da rodada de 14/11 (atualizado no meio do trabalho):**

| Item | Situação |
|---|---|
| Ferramentas do Android | **Instaladas** em `C:\AndroidTools`: `jdk17` (Java 17.0.21, SHA-256 conferido), `sdk` (platform-tools, build-tools 36.1.0, platforms android-36; licença aceita com a autorização do PO) e os modelos da Godot 4.7.2 em `C:\AndroidTools\appdata\Godot\export_templates\4.7.2.stable` (SHA-512 conferido) |
| Configuração da Godot para exportar | `C:\AndroidTools\appdata\Godot\editor_settings-4.7.tres` aponta para o JDK e o SDK. Toda exportação roda com `APPDATA=C:\AndroidTools\appdata`, sem tocar na configuração nem no save do PO |
| Chave de teste | `C:\AndroidTools\chaves\cafemanie-teste.keystore`, alias `cafemanie`, senha em `senha.txt` na mesma pasta. Fora do repositório. **Nunca** copiar a senha para o repositório nem para a conversa |
| Retrato do chef em 3D (DT-097) | Script novo `tools/render3d/retratos_a3d.py`; 35 fotos finais geradas (24 cabeças, 6 roupas, 5 chapéus). `scenes/cafe/art_sprites.gd` passou a aceitar densidade por foto (os retratos têm 4). Folha de conferência em `tools/render3d/out_retratos/retratos_folha.png`. **Falta:** conferir no jogo, rodar os testes e a revisão do PO |
| APK | **Falta exportar** (comando abaixo), depois de os testes passarem com o retrato novo |
| Pratos e panelas em 3D | **Não começado.** São 39 `prato_<receita>` e 39 `panela_<receita>` em `art/sprites`, com `food_width` 64 no `sprites.json`; a panela é desenhada sobre o fogão e o prato em balcões, mesas, bandeja e ícones |

Comando da exportação (Git Bash):

```bash
export APPDATA='C:\AndroidTools\appdata'
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH='C:\AndroidTools\chaves\cafemanie-teste.keystore'
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=cafemanie
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(cat /c/AndroidTools/chaves/senha.txt)"
cd /c/Projetos/cafe-manie && mkdir -p build/android
/c/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Android" build/android/CafeManie.apk
/c/AndroidTools/sdk/build-tools/36.1.0/apksigner.bat verify --print-certs build/android/CafeManie.apk
```

Como o retrato foi montado, para quem for ajustar: o script mede a pessoa **depois** de aplicar as formas (função `fit`), porque os vértices do objeto guardam só a forma básica; na camada da cabeça, a roupa entra invisível (`hide_below_collar`) para o pescoço acabar na borda do colarinho.

**Andamento, segunda anotação de 14/11:**

| Item | Situação |
|---|---|
| Retrato do chef | Fotos finais prontas (35 + `icone_chef`), conferidas no jogo: tela inicial, janela do avatar (abas Cabelo e Chapéu) e botão Chef. DT-097 registrada. Cena de conferência: `tools/revisao/avatar.gd` (usar `-Mode revisao -Extra <aba>`, com a aba de 0 a 3) |
| Pratos e panelas | Script novo `tools/render3d/pratos_a3d.py` (DT-098, ainda não escrita nos documentos). Rascunho conferido em folha e no jogo (fogões com `tools/revisao/cozinha.gd`, variante `cozinha:0:0`; mesas e balões no `mostruario`): o encaixe está certo. **Fotos finais em geração**: o fim aparece como `PRATOS OK 78`. Se a sessão cair, rodar de novo `blender.exe -b -P tools/render3d/pratos_a3d.py` (sem argumentos) e conferir com as folhas |
| Depois das fotos finais | Rodar `tools/revisao/testes.ps1`; exportar o APK (comando acima); escrever a DT-098; atualizar `status.md`, `roadmap.md` e `art-direction.md`; abrir a revisão com `tools/revisao/revisar.ps1` |

Pontos fracos já vistos no rascunho dos pratos: o tempurá ficou pequeno e fino; as frigideiras são pequenas perto das panelas fundas; o ícone do botão Garçom e os retratos do crítico, vizinhos e bruxa continuam desenhados a traço.

**Andamento, terceira anotação de 14/11:**

- A primeira leva de fotos finais dos pratos saiu **escura**: esconder de vez o chão que recebe a sombra (`hide_render`) tira também a luz que ele rebate. Corrigido em `no_floor()` de `pratos_a3d.py`: o chão fica fora da câmera (`visible_camera = False`) e continua rebatendo luz. **As fotos finais estão sendo refeitas.**
- A exportação do APK foi testada e funciona (98 MB, assinado). Um APK foi gerado **com os pratos escuros**: precisa ser **exportado de novo** depois que as fotos finais terminarem e os testes passarem.
- DT-097 e DT-098 escritas; `status.md`, `roadmap.md` e `art-direction.md` atualizados como "aguardando a revisão do PO".
- Ordem para fechar: (1) conferir `PRATOS OK 78`; (2) folhas com `tools/revisao/folha.ps1` e uma foto no jogo; (3) `tools/revisao/testes.ps1`; (4) exportar o APK (comando acima) e conferir com `apksigner verify`; (5) abrir a revisão com `tools/revisao/revisar.ps1`; (6) entregar ao PO o caminho `build\android\CafeManie.apk` e o passo a passo de instalação (README, "Jogar no celular Android").

### Estado atual (14/11/2026, fim da sessão) — leia isto primeiro

| Item | Situação |
|---|---|
| Retrato do chef (DT-097) | **Aprovado pelo PO em 16/11/2026.** 35 fotos e o `icone_chef` |
| Pratos e panelas (DT-098) | **Aprovados pelo PO em 16/11/2026.** 78 fotos finais, claras e sem sombra no chão |
| Testes | 739 aprovados de novo em 16/11, depois da aprovação; cena principal com saída 0; `data/` e `core/` sem mudança; save do PO em 31/10 23:33; janela de revisão fechada |
| APK | **Gerado:** `build\android\CafeManie.apk`, 96 MB, pacote `io.github.eliashenr.cafemanie`, versão 0.2.0 (código 2), só arm64, assinado com a chave de teste (v2 e v3 conferidos com `apksigner`). `build/` não vai para o git |
| Checagem do conteúdo do APK | **Não feita.** O `--smoke-check` com o motor de exportação do Windows não acha o projeto dentro da pasta `assets` e para num erro. O jogo foi testado a partir do projeto, não de dentro do APK |
| Revisão do PO | Aprovados em 16/11/2026. Os documentos já registram a aprovação |
| Commit e envio | **Enviado em 16/11/2026** para `origin/amostra-a-2`, na conta `eliashenr` |

**Modelo de envio usado nesta etapa** (repetir nas próximas, trocando os arquivos e a mensagem):

```bash
gh auth status          # a conta ativa tem de ser eliashenr
git -C C:/Projetos/cafe-manie status --short -- data core      # tem de vir vazio
git -C C:/Projetos/cafe-manie add art/sprites docs README.md scenes/cafe/art_sprites.gd tools/render3d/retratos_a3d.py tools/render3d/pratos_a3d.py tools/revisao
git -C C:/Projetos/cafe-manie commit -m "feat: reference A chef portrait, dishes and cookware in 3D"    # mais a linha Co-Authored-By do modelo em uso
git -C C:/Projetos/cafe-manie push origin amostra-a-2
```

**Se o PO pedir ajustes:**
- um prato ou panela: mexer na função da receita em `tools/render3d/pratos_a3d.py` e rodar `blender.exe -b -P tools/render3d/pratos_a3d.py -- <receita>` (faz o prato e a panela dela; acrescente `pratos` ou `panelas` para fazer só um);
- o retrato: `tools/render3d/retratos_a3d.py`, com os grupos `cabecas`, `roupas`, `chapeus`, `icone` e `folha`;
- depois, `tools/revisao/testes.ps1`, as folhas com `tools/revisao/folha.ps1` e a revisão de novo.

**Teste no celular (depende do PO):** ele copia `build\android\CafeManie.apk` para o aparelho e instala (README, "Jogar no celular Android"); se já houver um Café Manie instalado, precisa desinstalar antes, porque a chave mudou. Depois segue o roteiro "Android" do `qa.md`. Os achados dele entram como a próxima etapa (ordem 9 do plano da revisão geral).

**Próximos passos do plano, com a liberação do PO:** teste de sanidade da arte (C4); retratos do crítico, vizinhos e bruxa e o ícone do Garçom; bebidas, frutas e temperos; juntar `amostra-a-2` em `main` e ligar os testes no GitHub.

### Rodada de 16/11/2026 (em andamento; o PO escolheu "Retratos que faltam")

Escopo decidido pela engenharia para esta etapa (DT-099, a escrever):

| Grupo | Fotos | Como |
|---|---|---|
| Vizinhos | `vizinho_ana`, `_beto`, `_caio`, `_duda`, `_lia`, `_rafa`, `_vo_cida` | Pessoas do MakeHuman em busto, numa foto só cada (sem camadas), no fim de `tools/render3d/retratos_a3d.py` (dicionário `PEOPLE`). Aparecem na janela da Cidade com 66×70 |
| Bruxa Morgana | `retrato_bruxa` | Mesma técnica, com o chapéu de bruxa. Aparece na janela do evento (`scenes/ui/event_dialog.gd`) |
| Ícone do Garçom | `icone_garcom` | O garçom do jogo (mesma receita de `personagens3d.py`) em busto, como o `icone_chef` |
| Bebidas e frutas | 9 `bebida_*` e 3 `fruta_*` | Modelos em `tools/render3d/pratos_a3d.py`, com a mesma âncora dos pratos (a base fica 24 px de mundo abaixo da âncora) |

**Ficam como estão, de propósito:** `icone_critico` (é uma medalha, um símbolo de interface, não um retrato) e os 5 `tempero_*` (os desenhos têm símbolos de função: mais porções, raio, foguete, relógio, cruz; em 3D perderiam a leitura). Se o PO quiser, viram uma etapa própria.

Traços de cada vizinho na arte antiga, para manter a identidade: Ana (pele clara, rabo de cavalo castanho), Beto (pele negra, cabelo preto curto), Caio (pele negra, boné azul com estrela), Duda (pele clara, chanel ruivo), Lia (pele morena, cabelo preto longo), Rafa (pele clara, loiro curto), Vó Cida (idosa, coque grisalho, óculos). A bruxa é ruiva de cabelo longo, com chapéu roxo de faixa laranja.

**Andamento da rodada de 16/11 (atualizado em 19/11, quando o PO trocou para o Opus):**

| Item | Situação |
|---|---|
| Vizinhos, bruxa e ícone do Garçom | Fotos finais prontas (`retratos_a3d.py -- pessoas`). Conferidos no jogo com `tools/revisao/janelas.gd` (`-Extra cidade` ou `-Extra evento`) |
| Bebidas e frutas | Fotos finais prontas (`pratos_a3d.py -- bebidas frutas`). Vistas em folha |
| DT-099, status, roadmap, art-direction | Escritos, como "aguardando a revisão do PO" |
| Testes | 739 aprovados, cena principal com saída 0, `data/` e `core/` sem mudança, save em 31/10 23:33 |
| Revisão do PO | **Aprovados em 19/11/2026.** Os documentos já registram a aprovação |
| Commit | **Enviado em 19/11/2026** para `origin/amostra-a-2`, na conta `eliashenr` (commit `feat: reference A neighbors, witch, waiter icon, drinks and fruits in 3D`) |

Se o PO aprovar: trocar "aguardando/aguardam a revisão" por "aprovados pelo PO" em `status.md`, `roadmap.md`, `art-direction.md` e na DT-099; rodar `tools/revisao/testes.ps1`; e, com "Pode enviar", commit `feat: reference A neighbors, witch, waiter icon, drinks and fruits in 3D`.

### Onde paramos (19/11/2026, depois do envio)

- Tudo enviado; `git status --short` tem de vir vazio. O redesenho está completo no ramo `amostra-a-2`, menos a cidade (luz antiga) e os ícones de interface e temperos (desenhados de propósito).
- `main` continua em `bb843d6`, **sem nada do redesenho**.
- **Próximos passos recomendados, com a liberação do PO:**
  1. **Juntar `amostra-a-2` em `main`** e ligar os testes automáticos no GitHub (P1 e P2 da [revisão geral](revisao-geral.md)). Quanto mais tempo separado, mais difícil juntar. Antes, perguntar ao PO; ligar o GitHub Actions mexe na configuração do repositório.
  2. **Teste no celular:** o APK de 14/11 está em `build\android\CafeManie.apk`, mas é anterior aos vizinhos, bruxa, bebidas e frutas. Exportar de novo antes de entregar (comando na seção da rodada de 14/11).
  3. Teste de sanidade da arte (C4), evento de Natal (J2), cidade com a luz nova (G2).

### Rodada de 19/11/2026: juntar na main (pedido do PO: "Juntar na main")

- `origin/main` está em `bb843d6` e é ancestral de `amostra-a-2`: a junção é um **avanço direto** (fast-forward), sem conflito e sem commit de junção.
- O repositório `eliashenr/cafe-manie` é **público** e a `main` não tem proteção.
- Plano: (1) criar `.github/workflows/testes.yml`, que baixa a Godot 4.7.2 para Linux e roda os testes sem janela a cada envio; (2) enviar no `amostra-a-2` e ver o GitHub rodar verde; (3) avançar a `main` até o `amostra-a-2` e enviar; (4) conferir que a `main` também rodou verde.
- Se o GitHub reprovar algo que passa neste PC, a diferença provável é o sistema (Linux lá, Windows aqui): ler o registro com `gh run view --log-failed` antes de mexer.
- **Feito em 19/11:** o GitHub rodou os testes no `amostra-a-2` (739 aprovados, 1 min 43 s, run 44597919778). O `actions/checkout` passou para a v5, porque a v4 roda em Node 20, que o GitHub está desligando.
- **Depois do avanço da `main`:** todo trabalho novo sai de `main` em ramos curtos por etapa (por exemplo `etapa-cidade`), e volta para a `main` quando o PO aprovar e os testes do GitHub ficarem verdes. O `amostra-a-2` e o `arte-3d` ficam só como histórico.

### Onde paramos (19/11/2026, depois da junção) — leia isto primeiro

- **Ramo de trabalho agora é a `main`**, em `decdbcd` (ou o commit de documentos logo depois). `amostra-a-2` e `arte-3d` ficam só como histórico; não trabalhe neles.
- **Testes no GitHub:** `.github/workflows/testes.yml`. Depois de cada envio, confira com `gh run list --repo eliashenr/cafe-manie --limit 3` (tem de aparecer `success`). Se falhar: `gh run view <id> --repo eliashenr/cafe-manie --log-failed`.
- **Fluxo de uma etapa nova:** `git switch -c etapa-<nome> main` → trabalho → revisão do PO → "Pode enviar" → `git push origin etapa-<nome>` → testes verdes no GitHub → `git switch main && git merge --ff-only etapa-<nome> && git push origin main`.
- **Pendências e próximos passos (com a liberação do PO):**
  1. **Novo APK** para o teste no celular: o de 14/11 é anterior aos vizinhos, bebidas e frutas.
  2. Teste de sanidade da arte (achado C4 da revisão geral).
  3. Evento de Natal (J2), cidade com a luz nova (G2), mais poses dos personagens (G3).
  4. Dividir os arquivos grandes (C1, C2) e reescrever `architecture.md`, `gameplay.md` e `progression.md` (C6).

### Rodada de 20/11/2026: evento de Natal (ramo `etapa-natal`)

Pedido do PO: preparar o Natal e registrar a regra de que todo evento do calendário deve ser preparado sem ele lembrar.

| Item | Situação |
|---|---|
| Regra do calendário | Em `docs/eventos.md`, no `CLAUDE.md` e na memória do Claude |
| Dados | `data/events/natal.tres`, `data/events/natal/n1..n5`, `data/furniture/santa_oven.tres`, `data/furniture/christmas_tree.tres` |
| Código | `EventDefinition.icon` (ícone de cada evento) e `GameHud._show_event_icon`; aviso de início sem "abóbora" |
| Arte | `santa_oven` e `christmas_tree` em `enfeites_a3d.py`; `retrato_papai_noel` e `medalhao_natal` em `retratos_a3d.py` (grupo `natal`) |
| Teste novo | `tests/unit/test_christmas_event.gd` |
| Conferência no jogo | `tools/revisao/janelas.gd` com `-Extra natal` (história) ou `-Extra natal_cafe` (o café em dezembro) |
| DT-100 | Escrita como "aguardando a revisão do PO" |

Próximo evento da fila: **Ano Novo**, já atrasado pelo calendário.

### Rodada de 20/11/2026, parte 2: personagens com vida (pedido urgente do PO)

- O PO **aprovou o Natal** (documentos já atualizados; o ramo `etapa-natal` ainda não tem commit).
- Logo depois, reprovou os personagens: "Está muito FEIO, não parece um jogo... Parece personagens NPC total, sem vida, sem expressão... nem que não mantenha o padrão 3D... Use a inteligência".
- **Decisão da engenharia:** trocar as pessoas realistas do MakeHuman por **personagens estilizados de jogo** (cabeça grande, olhos grandes com brilho, sobrancelhas e boca que mudam com o humor, cores saturadas e contorno), modelados por código no Blender em `tools/render3d/personagens_toon.py`. O resto do jogo (salão, móveis, comida) continua igual.
- **Contrato que não muda:** os mesmos nomes de foto (`garcom_*`, `cliente_NN_*`), as mesmas poses (em pé, 8 passos, bandeja, sentado com 4 humores, sentado de costas r1 e r2), a âncora nos pés e o `tray_food` do manifesto. Assim o jogo não precisa mudar.
- **Ordem:** amostra com o garçom e 2 clientes → PO aprova o caminho → os outros 10 clientes → depois os retratos (chef, vizinhos, Papai Noel, bruxa), que hoje também são MakeHuman.
- **Andamento (20/11):** `tools/render3d/personagens_toon.py` escrito e provado em 3 rodadas (rosto virado para a câmera com `HEAD_TURN`, olhos grandes, cabelo em mechas achatadas, afro em tufos redondos). Em geração: todos os 13 personagens. Se a sessão cair, rodar de novo `blender.exe -b -P tools/render3d/personagens_toon.py` (sem argumentos), depois `tools/revisao/testes.ps1` e a revisão com `tools/revisao/revisar.ps1 -Variant mostruario`.
- **Para voltar aos personagens realistas**, se o PO preferir: `git checkout -- art/sprites/garcom_* art/sprites/cliente_*` desfaz só as fotos das pessoas (a arte do Natal, também sem commit, fica). As âncoras delas ficam no `sprites.json`: refazer com `personagens3d.py` regrava as certas.
- **Fim da rodada (20/11):** os 13 personagens gerados (324 fotos, `PERSONAGENS OK 324`), conferidos em folha e no `mostruario`. DT-101 e `status.md` escritos como "aguardando a revisão do PO". Revisão aberta minimizada. Se o PO aprovar: refazer os retratos (chef, Garçom, vizinhos, bruxa, Papai Noel) no mesmo estilo, depois "Pode enviar" leva o Natal e os personagens juntos (o ramo `etapa-natal` tem os dois).
- **Próximo do calendário:** o Ano Novo (27/12 a 06/01) está atrasado; propor ao PO assim que os personagens fecharem.

**Ajuste pedido pelo PO (20/11), depois de ver os personagens:** "O corpo eu gostei, o andar, está ótimo. Mas o rosto, muito redondo e feio". Mandou duas imagens de referência (meninos de desenho animado). Elas ficam só neste PC, em `docs/referencias/` e fora do git, porque não sabemos a licença delas. Ele quer **esse formato de rosto**, em versão de **homem e mulher adultos**. O que tirar delas:
- rosto oval, mais largo nas bochechas, com queixo arredondado marcado (não uma bola);
- olhos grandes com o contorno escuro e grosso da pálpebra de cima, íris colorida com brilho;
- sobrancelhas grossas e arqueadas; nariz de bolinha; orelhas aparentes;
- sorriso aberto com dentes brancos e língua;
- cabelo em mechas pontudas, com brilho;
- contorno escuro mais forte.
O corpo, as poses e o andar **não mudam**.
- **Rosto novo (20/11):** cabeça oval (`shaped_head`), rosto por raios (`on_face`), pálpebra grossa, nariz, orelhas, sorriso com dentes, mechas grossas (`lock`), queixo levantado (`HEAD_LIFT`) e contorno só na silhueta (`no_outline` marca o rosto e o chão). Conferir de perto com o script de closes: um `close.py` que monta `T.build(...)` e fotografa a cabeça com `ortho_scale = 0.75`. Em geração: os 13 personagens finais.
- **Fim do ajuste do rosto (20/11):** 324 fotos finais (`PERSONAGENS OK 324`), conferidas em folha e no `mostruario`. 744 testes aprovados e a cena principal com saída 0. Revisão aberta minimizada. Falta a resposta do PO sobre o rosto novo.
- **Segundo ajuste pedido pelo PO (20/11):** "O rosto ainda está redondo demais, quero igual à referência... Parece que os bonecos estão sendo criados com MASSINHAS... quero que pareça um DESENHO real, tipo anime". Decisão: **sombreado de desenho (cel shading)** no lugar do sombreado 3D suave. As cores ficam chapadas com uma sombra recortada, o render passa para o EEVEE (que tem o nó Shader to RGB) e o contorno fica forte. A sombra no chão vira uma mancha desenhada. O rosto fica mais anguloso: maçãs marcadas e queixo fino.
- **Sombreado de desenho pronto (20/11):** `cel()` (cor chapada com sombra e brilho recortados), `flat()` para olhos, boca e bochechas, uma luz própria de desenho em `outline_on()` (EEVEE, sem o chão do Cycles), `ground_shadow()` para a sombra desenhada e o rosto anguloso (`CHEEKS`, `CHIN`). Prova aprovada pela engenharia; em geração os 13 finais.
- **21/11:** a geração dos 13 foi interrompida no cliente 9 (a sessão caiu). Do garçom ao cliente 08 estão prontos em desenho; os clientes 09 a 12 foram refeitos em seguida com `personagens_toon.py -- cliente_09 cliente_10 cliente_11 cliente_12`. Para saber se uma foto já é a nova, compare a data com a do `personagens_toon.py`.
- **Fim do sombreado de desenho (21/11):** os 13 personagens prontos e conferidos em folha e no `mostruario`. 744 testes aprovados e a cena principal com saída 0. Revisão aberta minimizada. Falta a resposta do PO. Os retratos (chef, Garçom, vizinhos, bruxa, Papai Noel) ainda são realistas.
- **Terceiro retorno do PO (21/11), reprovando o estilo de bonecos:** "ESTÁ MUIIIIITO FEIO; Não quero que pareçam bonecos de ARGILA!!!... copia um Anime mano, um naruto, um dragonball z. Algo que seja mais realista em forma de desenho". Decisão: o corpo de bolas e tubos (`personagens_toon.py`) parece argila com qualquer sombreado. Volta o **corpo humano do MakeHuman** (`personagens3d.py`, proporção real, andar e poses já prontos) com **sombreado de anime** (cor da textura em duas faixas recortadas, EEVEE), **traço de nanquim** (Freestyle) e **olhos maiores**, a técnica de jogos como Dragon Ball FighterZ. Sem copiar personagens das séries (direitos autorais): só o estilo. O modo novo é o argumento `anime` de `personagens3d.py`.
- **Visual de anime (21/11):** `tools/render3d/anime3d.py` + argumento `anime` em `personagens3d.py`. Corpo do MakeHuman, cada textura reduzida a 4 cores chapadas (`_flatten`), pele numa cor só (`_skin_tone`), sombra recortada (Shader to RGB no EEVEE), traço preto na silhueta e nas divisas de material, olhos um pouco maiores e a sombra no chão desenhada. A altura passou a ser medida com as máscaras de roupa desligadas (antes, com os olhos de anime, a pessoa saía grande demais). Comando: `blender.exe -b -P tools/render3d/personagens3d.py -- anime` (todos) ou com os nomes.
- **Resultado do anime (21/11), avaliação honesta da engenharia:** os 13 foram gerados e os testes passaram (744). Mas, no tamanho do salão, eles ainda leem como gente realista com cor chapada, não como Naruto ou Dragon Ball. A pele dos personagens negros saiu clara demais (`_skin_tone` pega uma média errada nessas texturas). Os rostos, com uns 20 px de altura no jogo, não mostram o traço de anime.
- **Limite encontrado:** três caminhos procedurais (bonecos de bolas, cel shading nos bonecos, anime no MakeHuman) não chegaram ao que o PO quer. O caminho que entrega desenho de anime de verdade é **arte 2D desenhada**, quadro a quadro, por ilustrador ou por gerador de imagem com folha de personagem. Isso é uma decisão do PO (custo, serviço externo, prazo) e foi perguntada a ele em 21/11.
- **Estado dos arquivos:** as fotos dos personagens no disco são as de anime, sem commit. Para voltar às realistas aprovadas: `git checkout -- art/sprites/garcom_* art/sprites/cliente_*` e o `sprites.json` (com cuidado: ele também tem as âncoras do Natal, que não têm commit).
- **Desenho 2D com IA (21/11):** o PO escolheu esse caminho e autorizou **só a prova do garçom** na conta ElevenLabs dele (cerca de 10 imagens, uns 2.000 créditos ou US$ 0,40). A Higgsfield está com 0 crédito. Os outros 12 dependem da aprovação da prova. Plano: imagem base do personagem (anime, corpo inteiro, ângulo do jogo, fundo branco); as outras poses geradas com ela de referência; fundo removido aqui com Python; os quadros do andar derivados da imagem parada (balanço e inclinação), sem mudar o código do jogo.
- **Prova do garçom pronta (21/11):** 4 desenhos no fluxo `fKnBWSbARNlReVKtaJkS` da ElevenLabs (modelo `gpt-image-2.5-sunburst`; 1.489 créditos gastos de uns 2.000 liberados): `base_frente`, `bandeja_frente` e `base_costas` (com a de frente como referência) e `bandeja_costas` (com a de costas como referência). Os originais ficam em `build/ia/garcom/` (fora do git). **`tools/ia/montar_personagem.py <pasta> <look>`** tira o fundo branco, acha os pés, reduz para 104 px de mundo com densidade 4, desenha a sombra no chão, faz os 8 passos (balanço e inclinação leves, `BOB` e `SWAY`) e grava as 36 fotos `garcom_*`, as âncoras e o `tray_food`/`tray_food_back` (medidos no metal da bandeja, `TRAY_BOX`). **Depois de trocar PNGs, rode `testes.ps1` antes da foto:** sem a importação o jogo usa a imagem antiga com a âncora nova e o personagem sai pela metade. Conferência de perto: `foto.ps1 -Script res://tools/revisao/garcom.gd -Variant inicial -Mode perto -Extra frente_bandeja`. 744 testes aprovados, cena principal com saída 0, revisão aberta minimizada. **Falta a resposta do PO.**
- **Se o PO aprovar a prova:** pedir a liberação de créditos para os 12 clientes (cada um precisa de base de frente, de costas e, sentados, 4 humores de frente e 2 de costas: umas 8 imagens, uns 3.300 créditos por cliente com referência) e para os retratos. Os sentados exigem um ajuste novo em `montar_personagem.py` (âncora no assento, não nos pés). Os clientes de hoje no disco são os de anime 3D, reprovados.
- **Limite conhecido da prova:** o andar é só um balanço do desenho parado. Passos de verdade pedem 2 a 4 desenhos por lado (custo extra), se o PO quiser.
- **Ajuste do PO na prova (21/11): "O andar".** Ele escolheu passos de verdade (com o custo extra de uns 1.700 créditos já dito na pergunta). Feito: 4 folhas de passos (`andar_frente`, `andar_frente_bandeja`, `andar_costas`, `andar_costas_bandeja`, cada uma com 4 desenhos lado a lado, geradas com o desenho parado como referência; total gasto na prova: 3.221 créditos). `montar_personagem.py` agora separa os passos por pedaço ligado de pixels (a bandeja de um passo invade as colunas do vizinho), põe a âncora sob a cintura à mesma distância da cabeça que no parado (o corpo não treme), usa os quadros 0-0-1-1-2-2-3-3 e **espelha tudo** (os desenhos olham para a esquerda; o jogo quer a direita). A bandeja tem largura fixa (`TRAY_WIDTH`), medida a partir da ponta de fora. **Mudança no jogo:** cada quadro andando com bandeja guarda onde vai o prato (`"tray"` no `sprites.json`, `ArtSprites.Sprite.tray`, `AgentView.tray_food()`), porque a bandeja sobe e desce com o passo; teste novo `test_walking_the_plate_follows_the_tray_of_each_frame`. 745 testes aprovados. Conferência: `--marcas <folha.png>` no script (âncora em vermelho, prato em azul) e `garcom.gd -Extra andando_frente_bandeja`. Animação para o PO: `build/ia/garcom/andar_garcom.gif`. **Falta a resposta do PO.**
- **Retorno do PO (22/11): "muito falso".** Ele marcou os 4 problemas: o andar, desenho colado no cenário, o próprio desenho e o tamanho. Causa: um desenho chapado de anime (com contorno preto) sobre um café renderizado em 3D nunca combina. Decisão aceita pelo PO: **primeiro uma imagem-alvo**, antes de qualquer personagem. `tools/revisao/cena_alvo.gd` fotografa o café sem o garçom e sem o painel (`foto.ps1 -Script res://tools/revisao/cena_alvo.gd -Variant mostruario -Mode perto`). A foto subiu para a ElevenLabs pelo botão de arquivo (o PO escolhe `build/ia/foto_do_cafe.png`; o serviço não aceita arquivo local de outro jeito). Resultado em `build/ia/imagem_alvo.png` (e `imagem_alvo_perto.png`): garçom no acabamento do café (3D estilizado de jogo de celular, rosto expressivo, sombra no chão, tamanho das outras pessoas), **não anime chapado**. Créditos gastos no total: 3.654. **Falta o PO dizer se é esse o visual.** Se for, o próximo passo é decidir como produzir o personagem nesse acabamento com andar de verdade (modelo 3D com esqueleto, como os antigos, mas com esse rosto e essas proporções), e propor isso a ele antes de gastar.
- **O PO aprovou o visual da imagem-alvo (22/11): "É esse o visual".** Proposta da engenharia, aguardando o OK do PO para gastar: **andar feito com vídeo** (a IA anima o personagem andando sem sair do lugar, num vídeo de 5 s, e o script tira 8 quadros de um ciclo; os quadros saem encaixados, sem o andar "travado" das folhas de passos). Orçamento consultado com `estimate_only` (nada cobrado): `kling-2.5-turbo` 2.121 créditos por vídeo de 5 s (US$ 0,42), `seedance-v2.5-flash` 9.163, `seedance-v2.5` 14.005. Prova sugerida: o garçom parado de frente e de costas no visual novo (2 imagens com `imagem_alvo` como referência, nó `SE6AGMC8c5yuSRI8MKWa`) + 1 vídeo do andar de frente = uns 3.000 créditos (US$ 0,60). Estimativa do elenco inteiro: uns 7.700 créditos por cliente (8 imagens + 2 vídeos) e 9.350 para o garçom (4 vídeos, com e sem bandeja): uns 102.000 créditos (US$ 20), mais uns 30% de refação. Alternativa sem custo: refazer em 3D no Blender com esqueleto, buscando esse visual (mais lento e já reprovado 4 vezes por estilo).
- **O PO escolheu "Tentar no Blender" (22/11)**, sem gastar créditos. Feito: modo **`estilo`** em `personagens3d.py` com o módulo novo **`tools/render3d/estilo3d.py`** (o MakeHuman de antes, com esqueleto e andar, mas no acabamento da imagem-alvo): pele lisa e mais quente (`smooth_skin`), roupas com a textura resumida e sem relevo (`soften`), cabelo numa cor escolhida guardando os fios (`hair_color`), sobrancelhas grossas e escuras (`BROWS`, `BROW_COLOR`), íris quase preta (`dark_iris`, peça `high-poly`), olhos maiores e bem abertos (`EYES`), rosto mais jovem e redondo com nariz menor (`FACE`), sorriso (`SMILE`), cabeça 1,55 e, de frente, o rosto virado para a câmera (`face_camera`, `HEAD_TURN`, `HEAD_LIFT`). O garçom: paletó pintado como colete preto, mangas brancas e gravata vermelha (`paint` no `CHARACTERS["garcom"]`, regiões achadas com `estilo_close.py ... mapa`), bandeja menor e de lado (`TRAY_*`). `set_expression` agora zera todas as formas `expr-` antes da nova. `cena3d.update_manifest` mescla as entradas, então o `main` tira `density` e `tray` que sobraram dos desenhos da IA.
- **Ferramentas:** `blender.exe -b -P tools/render3d/estilo_close.py -- estilo garcom <saida.png> [rosto] [bandeja] [costas] [mapa]` (foto de perto, não grava sprites); `blender.exe -b -P tools/render3d/personagens3d.py -- estilo garcom [prova]` (as fotos do jogo); `foto.ps1 -Script res://tools/revisao/cena_alvo.gd -Variant mostruario -Mode perto -Extra garcom` põe o garçom no lugar da imagem-alvo para comparar (`build/ia/imagem_alvo.png`). Rode `godot --headless --import` (ou `testes.ps1`) antes da foto.
- **Fim da rodada no Blender (22/11):** as 36 fotos do garçom no modo `estilo` geradas (`PERSONAGENS OK 36`), 745 testes aprovados, cena principal com saída 0. Para o PO: `build/ia/andar_garcom_blender.gif` (o andar) e `build/ia/comparacao_blender_alvo.png` (o garçom no jogo, à esquerda, ao lado da imagem-alvo). Revisão aberta minimizada. **Falta a resposta do PO.** Se aprovar: rodar `personagens3d.py -- estilo cliente_01 ... cliente_12` (cada cliente precisa das cores de roupa e do cabelo no visual novo: conferir com `estilo_close.py`), depois os retratos. Diferenças que ainda ficam em relação à imagem-alvo: o rosto do MakeHuman é mais "boneco realista", o cabelo tem fios e a bandeja fica na altura da cintura.
- **O PO reprovou o Blender (22/11): "tá bem feio kkkkkkkkk segue pelo elevenlabs o garçom, se ficar bom, vemos de seguir com os outros".** Feita a prova pela IA, no visual da imagem-alvo (2.987 créditos; total gasto nos personagens: 6.641):
  - imagem `frente.png` (o garçom da imagem-alvo sozinho em fundo branco, com a bandeja vazia; nó `YRAK5iutTdxd9dZ1rclT`) e `costas.png` (de costas, nó `8Gicn2duklx77D2WwoF0`), em `build/ia/garcom_v2/`;
  - vídeo `andar_frente.mp4` (`kling-2.5-turbo`, 5 s, 1920x1080, 24 qps; nó `0wddR1zz3K2H4NlWNiYY`): ele anda no lugar, câmera parada;
  - **`tools/ia/montar_video.py <pasta> <look> [--marcas folha.png]`** tira os quadros com o ffmpeg do computador, acha o ciclo do andar sozinho (o período em que as pernas se repetem: 33 quadros), escolhe 8 quadros, usa a mesma âncora em todos (a câmera não mexe), mede a bandeja em cada quadro (o maior pedaço de metal na metade de cima) e grava os sprites. Demora uns 8 minutos (o recorte de 121 quadros em 1920x1080).
  - **Limites da prova:** sem bandeja, ele usa os quadros com a bandeja vazia; de costas, a foto parada (o jogo faz o balanço). Para completar o garçom: vídeo de costas com bandeja (2.121) e, se o PO quiser mãos livres, os dois vídeos sem bandeja (2 x 2.121 + 2 imagens).
- **Fim da prova pela IA (22/11):** altura igual à da imagem-alvo (`M.HEIGHT = 96` em `montar_video.py`), 745 testes aprovados, cena principal com saída 0. Para o PO: `build/ia/andar_garcom_v2.gif` e `build/ia/comparacao_v2_alvo.png`. Revisão aberta minimizada. **Falta a resposta do PO.** Se aprovar, propor o resto: vídeo de costas com bandeja (2.121) e depois os clientes (cada um: imagem de frente e de costas a partir da imagem-alvo, vídeos de andar de frente e de costas e as poses sentadas).

### Onde paramos (22/11/2026, divisão com o Codex) — leia isto primeiro

- O PO dividiu o trabalho: o **Codex** cuida do visual, dos personagens e da interface; o **Claude**, das regras, da economia, dos saves e do conteúdo. Arquivos de apresentação, sprites e geradores de arte só mudam depois de os dois combinarem quem edita o quê (DT-102).
- O estado completo, a proposta de divisão por pasta e as pendências estão em [divisao-claude-codex.md](divisao-claude-codex.md).
- **Natal enviado (22/11, "Pode enviar o Natal"):** foi num commit só dele (o `sprites.json` com só as âncoras do Natal, conferido numa cópia limpa com `git worktree`), mais um commit de documentos, e a `main` avançou até eles. Na pasta continuam, sem commit, os experimentos de personagem.
- **Próximo passo do Claude:** o Ano Novo, que está atrasado, e o build novo para o celular, se o PO quiser.
- **Próximo passo do Codex:** um garçom completo, validado no jogo pelo PO, antes de expandir o estilo.
