# Como continuar (guia para a próxima sessão)

Este arquivo existe para a próxima sessão do Claude (qualquer modelo) retomar o trabalho sem depender da conversa anterior.
Atualizado em 11/11/2026. Se este guia e o [status.md](status.md) discordarem, vale o que o `git log` e o `git status` mostrarem.

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

- Ramo `amostra-a-2`. Último commit de arte, já no GitHub: `fe416d4` (pisos, paredes, itens de parede, portas e terraço, mais a revisão geral, este guia e `tools/revisao/`).
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
