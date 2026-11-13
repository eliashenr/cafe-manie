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
- Nada pendente neste PC depois do envio de 13/11. `main` continua em `bb843d6`, sem o redesenho.
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
