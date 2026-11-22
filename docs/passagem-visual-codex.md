# Passagem visual — Codex para Claude

## Estado e autorização (22/11/2026)

**Publicação anterior:** o PO aprovou a DT-106: “Pode enviar esse novo cenário e integrar à main.” Os 413 sprites foram publicados em `26c873f` e integrados à `main` pela [PR #2](https://github.com/eliashenr/cafe-manie/pull/2), merge `71489f0`, com a conta `eliashenr` e CI aprovado. Depois vieram as DT-107–110; a continuação atual é a DT-111 abaixo e não faz parte do lote de cenário já integrado.

O PO aprovou a reformulação dentro do jogo: “Ficou muito bom! Pode enviar”, e confirmou “Sim, pode integrar à main”. A entrega DT-103/104/105 partiu de `737f73e`, após o Natal, foi enviada em `a09f8e9` e integrada pela [PR #1](https://github.com/eliashenr/cafe-manie/pull/1) no merge `449e755`. Os testes de push e PR passaram antes da integração. A `main` já contém a reformulação aprovada; o cenário DT-106 também foi aprovado e integrado pela PR #2.

## Entrega atual — interface DT-111 integrada à main

**Publicação confirmada:** commit `2d91d83`, [PR #3](https://github.com/eliashenr/cafe-manie/pull/3), merge `5c35ce0`, conta `eliashenr`. O PO aprovou e autorizou envio/merge; os dois workflows passaram antes da integração, com 793 testes e cena principal sem erros. O lote inclui os 60 arquivos do pacote limpo e mantém regras, conteúdo, save e sprites existentes. Esta é a versão para o Claude continuar.

**Diferença deliberada do pacote:** o chef canônico e a interface são os aprovados. Outras combinações usam o desenho legado de `cac07e8`, pelos mesmos sprites/âncoras, sem carregar o compositor modular reprovado. `art/avatar` recebe apenas três PNGs do chef, sua configuração e arquivos de importação. As fontes DT-107, seu shader/importador/teste e a revisão antiga Chef e Loja ficam somente locais. A referência histórica da geração está documentada como não incluída, sem dependência de execução. Esse cuidado evita publicar trabalho explicitamente reprovado junto da interface aprovada.

O PO aprovou a animação DT-110 e autorizou concluir Loja/Reforma, HUD e Central sem pausas de autorização. A revisão atual é `Revisar Interface Completa.cmd`: inicia no café, com Loja, Configurações, Chef e Cidade reais, ouro/nível para testar e sem salvar. A DT-111 em `decisions.md` detalha os contratos; resultados finais estão no topo de `status.md`.

**Arquivos de apresentação:** `build_bar.gd` reúne a Loja e organiza tipos/busca/coleções; `game_hud.gd` reorganiza objetivo e controles e cria Configurações; `city_dialog.gd` apresenta Filial/Vizinhos; `avatar_portrait.gd` integra o chef inteiro aprovado na combinação canônica. `scenes/cafe/cafe.gd` muda somente a lista de janelas abertas para incluir Configurações. APIs, sinais, IDs, compras, preços e formato do save permanecem compatíveis. Os novos testes são `test_shop_organization.gd`, `test_hud_organization.gd`, `test_city_presentation.gd`, `test_avatar_legacy_fallback.gd`, o componente animado e os fluxos do chef no diálogo real.

**Claude:** não refazer essas telas nem restaurar o botão Reforma. Continuar com regras, conteúdo, calendário, economia e save; combinar futuras ligações de apresentação na seção 5 da divisão. A combinação canônica está aprovada; variantes completas do chef continuam pendentes, e a montagem DT-107 não está aprovada. Preservar as fontes `chef_vestido_v1.png` e `chef_blink_*`, seus contratos e os experimentos herdados. A continuação aprovada está publicada conforme confirmação acima. A pasta `codex/chef-loja` permanece com experiências locais, preservadas fora do pacote enviado. Logs temporários de Cidade ficaram em `C:\Projetos\cafe-manie\build\city-presentation-tests` após bloqueio automático de limpeza, sem alterações de código na cópia do Claude; não são dependência do projeto.

## Histórico — animação do chef aprovado, DT-110

O PO aprovou o chef parado DT-109: “Agora sim, ficou muito bom!” Autorizou a animação mantendo o rosto e os encaixes. A PNG aprovada permanece intacta; `scenes/ui/chef_animated_portrait.gd` usa uma malha contínua, e apenas regiões dos olhos leem as novas fontes de pálpebras. Prompt, fonte e hash em `art/portraits/chef_animado/`; mapeamento em `art/avatar/chef_blink_v1.json`.

`Revisar Chef Animado.cmd` apresenta a animação no café real, minimizada, com pausa, cumprimento e comparação ao original. Dados isolados em `build/chef-animado/`. Resultado das verificações no topo de `status.md`. A prova estática aprovada foi preservada; o compositor de personalização legado não foi alterado. Não tratar uma prova de um chef como todas as variantes resolvidas.

**Aceite posterior:** o PO aprovou a animação e autorizou a DT-111 acima. A separação histórica desta prova não limita a continuação explicitamente autorizada.

## Histórico — prova estática DT-109, agora aprovada

Depois de reprovar o avatar DT-107 e receber o estudo DT-108, o PO pediu primeiro um chef completo vestido e parado. A nova fonte `art/avatar/chef_vestido_v1.png` desenha gola, pescoço, cabelo e toque como uma composição inteira; origem, prompt e hash estão em `art/portraits/chef_vestido/`. O PO aprovou essa prova antes de autorizar a DT-110.

`Revisar Chef Vestido.cmd` abre minimizado o café real com o tema existente: retrato 210×255, detalhe 336×408, C para reabrir, D para ampliar e N para dia/noite. Os dados são isolados em `build/chef-vestido/interactive`, sem save pessoal. A prova é exclusivamente visual: não altera o compositor de produção, compras, peças, cores, regras ou conteúdo. Resultados de testes/capturas constam do topo de `status.md`.

**Claude:** manter a apresentação com Codex e preservar os conjuntos aprovados da main. DT-107 continua local e reprovada no encaixe; não publicar essa montagem nem presumir que DT-109 já conclui personalização. Animação, Loja, HUD e Central foram adiados pelo PO até esta avaliação. Nenhum commit/envio autorizado nesta rodada.

## O que mudou

- Garçom: 36 poses próprias de frente/costas, com/sem bandeja, parado e andando; ícone correspondente. Clientes: 12 identidades, 288 poses, incluindo 72 sentadas recalibradas para o novo mobiliário.
- Mobiliário: 25 assentos e 26 mesas, 169 sprites com rotações/encostos, preservando coleções, preços, área ocupada e IDs. Pratos menores e distribuídos dentro dos novos tampos.
- Interface: HUD, central, loja, receitas, missões, calendário e diálogos na paleta creme/café/verde; objetivos recolhíveis, melhor separação dos recursos/eventos e contraste de texto. 25 ícones novos.
- Retratos: chef personalizável (35 camadas + ícone), sete vizinhos, bruxa e Papai Noel. Compras, personalização e armazenamento continuam iguais.
- Apresentação do salão: letreiro, balões e indicadores harmonizados. Revisão interativa usa velocidade e navegação reais, com dados isolados e sem salvar.

`core/**`, `data/**`, autoloads, `project.godot`, `cafe.gd` e `cafe.tscn` não foram alterados. A pasta original do Claude não foi modificada. O save pessoal do PO nunca foi aberto pelo jogo de revisão.

## Contratos que precisam continuar juntos

- PNGs e suas entradas em `art/sprites/sprites.json` formam um conjunto. Não regenerar imagens ou substituir o manifesto inteiro por uma cópia antiga.
- `authored_motion` desliga a deformação procedural nos quadros desenhados; `external_shadow` desenha a sombra no piso. A bandeja usa a posição registrada em cada quadro. O comportamento legado continua disponível para arte antiga.
- Assento: altura 0,28, contato sentado 0,265, recuo 0,06. Mesas: largura 0,74, longa 1,54; alturas 0,43 Japão, 0,48 Club, 0,46 demais. Os alvos de registro estão no gerador e nas calibrações. `table_tops` deve acompanhar o render.
- Os encostos das rotações 1/2 são imagens separadas que passam na frente de quem senta de costas. Não incluem pés nem a cadeira inteira.
- `FurnitureView.dish_draw_position` adapta apenas a posição desenhada dos pratos, usando o centro da área ocupada; não muda lugares, navegação ou regras.

## Fontes e reprodução

- `art/characters/waiter/` e `art/characters/customers/`: fontes, prompts, calibrações e READMEs. `tools/ia/importar_garcom_codex.py` e `importar_clientes_codex.py` preparam sprites em uma pasta de saída.
- `art/portraits/`: fontes e calibração dos retratos; `tools/ia/importar_retratos_codex.py` preserva alfa e camadas combináveis.
- `tools/render3d/moveis_codex.py`: geometria dos móveis, com medidas de origem fixas. `conferir_moveis_codex.py` valida o lote. Não depende de backup em `build/` para reproduzir.
- `tools/ia/gerar_icones_ui.py`: desenhos vetoriais dos ícones. O jogo usa `icone_rolo`; o alias `icone_reformar` não deve ser instalado.
- `tools/ia/integrar_visual_codex.py`: valida IDs existentes, prepara backup, restaura imagens em caso de erro e confirma o manifesto atomicamente por último. Um escritor por vez.
- `build/` contém somente provas, logs e saídas regeneráveis, e não vai ao GitHub. Os caminhos reprovados de anime/MakeHuman e os montadores antigos herdados foram preservados localmente e não fazem parte desta entrega.

## Validação da entrega aprovada

764 testes Godot e 27 testes Python passaram. A cena principal rodou 120 quadros sem erros. Foram conferidos 108 detalhes dos 12 clientes, telas em 1280×720 e 960×540, salão de dia/noite, Japão, Brasil e central. Há pequenas variações de apoio em algumas poses de costas, incluídas no conjunto que o PO avaliou.

Para revisar sem terminal: `Revisar Visual.cmd`. Abre minimizado. C troca 12 coleções; N alterna dia/noite; 1/2 escolhem lotes e 0 mostra todos. APPDATA e LOCALAPPDATA ficam em `build/visual-reformulacao/interactive`; não usar o save pessoal para testes.

## Continuidade alinhada

O PO pediu também fogões, janelas, pisos e decorações. Essa extensão é a DT-106, sob responsabilidade visual do Codex, e será apresentada separadamente da DT-105 já aprovada. Cozinha, revestimentos e enfeites manterão IDs, dimensões lógicas, regras e temas.

### Extensão do cenário — DT-106, ramo `codex/visual-cenario`

O ramo parte de `94474fc`, que já contém a integração aprovada e a passagem da DT-105 publicada na `main`. O cenário foi validado e aprovado visualmente pelo PO, com envio e integração autorizados em 22/11/2026. Confirmação remota: commit `26c873f`, PR #2 e merge `71489f0`; testes de push e PR aprovados antes da integração.

- **Cozinha:** 37 itens em quatro rotações, mais dois brilhos de forno: 150 PNGs. Fogões com corpo arredondado, pés, porta e comandos separados; balcões com marcenaria mais leve; máquinas compactas. Inclui trem, caldeirão, forno do Natal e balcão de entregas.
- **Revestimentos e janelas:** 139 PNGs para 39 pisos (75 variações), 16 paredes, 15 janelas e dois pilares. Veios e juntas mais discretos, vidros legíveis e molduras mais finas. O cache dos materiais distingue os planos XY/XZ, evitando a colisão entre o piso e a parede brasileiros.
- **Decorações e portas:** 124 PNGs para 44 enfeites de piso, 12 de parede e 13 portas, incluindo lados e estados aberto/fechado. Vasos, suportes, luminárias, quadros e acabamentos harmonizados; aliases e móveis de 2×1/2×2 preservados.
- **Contrato:** somente 413 PNGs existentes e suas entradas de âncora/densidade mudam. A densidade passa a 4, acompanhando os personagens e móveis aprovados. Os outros 754 sprites e todos os campos de mapeamento do manifesto devem permanecer idênticos à DT-105. Apoios preservados: fogão z=0,748455, panela z=0,794455, balcão z=0,799486 (62,67 no jogo), parede 152,38. Sem mudança de preço, beleza, tamanho lógico ou regra.
- **Revisão:** `Revisar Cenario.cmd` abre minimizado, com C para coleções completas e N para dia/noite. `cenario_codex.gd` muda apenas dados de amostra em memória; recria vistas ao trocar os enfeites para não herdar luzes ou selos, e restaura os enfeites-base quando a coleção não tem os seus. `catalogo_cenario.gd` mostra todos os itens da cozinha e de decoração por página.

Fontes novas: `tools/render3d/cozinha_codex.py`, `superficies_codex.py` e `decoracoes_codex.py`, com seus três `conferir_*_codex.py`. Os módulos históricos usados como primitivas não foram alterados. Os geradores escrevem apenas em subpastas de `build/`; cada saída inclui `physical_contract.json`, `manifest_patch.json`, imagens brutas e sprites.

Para reproduzir, executar pelo Blender em segundo plano (`-b -t 3 -P <gerador> -- --out <subpasta nova de build> --samples <amostras>`). Cozinha/decorações usam 32 amostras; superfícies, 40; densidade 4. Executar o conferidor correspondente com a pasta gerada (cozinha usa `--staging <pasta> --complete` para exigir os 150 sprites). Conferir as imagens antes de instalar com `tools/ia/integrar_visual_codex.py`. Usar saídas novas: não sobrescrever lotes ou misturar uma retomada com fontes diferentes. Cozinha e decorações tiveram correções pontuais, com os dois lotes documentados nos contratos e nas proveniências locais. As correções posteriores de retomada/QA da decoração não alteram a geometria nem os PNGs.

Capturas e relatórios desta rodada ficam em `build/visual-cenario/`; não são dependências dos geradores. A revisão usa APPDATA/LOCALAPPDATA em `build/visual-cenario/interactive`. O teste de contrato visual passa a exigir densidade 4 também no fogão e no balcão básicos; os valores de preço, área e apoio continuam os mesmos.

**Validação final DT-106:** 764 testes Godot, 27 Python e 13 verificações focadas de controle de geração aprovados; cena principal por 120 quadros, saída 0. Inspecionadas 70 capturas reais: 26 salões, 14 páginas de cozinha, 16 de decoração, 10 de pisos e quatro de parede, incluindo dia/noite. Brilho dos fornos, panelas, pratos, luzes, janelas, juntas e apoios conferidos. Escopo final confirma 413 sprites instalados e 754 preservados, sem alterar os demais contratos, regras ou dados. Revisão minimizada confirmada no desktop, processo 23204, log isolado limpo.

Claude continua com Ano Novo, calendário, conteúdo, regras, economia e saves. Para novos itens, passar ao Codex ID, dimensões, rotações e contexto visual antes de criar imagens. Não há necessidade de refazer a interface nem os personagens aprovados.

Antes de atualizar a pasta do Claude, preservar as mudanças locais antigas. Integrar pelo Git e resolver conflitos de manifesto por entrada; não copiar esta pasta inteira nem descartar experimentos locais automaticamente. Acordos e novas intervenções continuam na seção 5 de `divisao-claude-codex.md`.

### Chef e Loja — DT-107, avatar reprovado e implementação ainda local

**Retorno posterior do PO:** a gola é coberta pelo pescoço e o chapéu parece sobreposto sem vestir a cabeça. Não publicar essa montagem. O diagnóstico e a pesquisa do Café Mania/Vostu estão em [estudo-cafe-mania-original.md](estudo-cafe-mania-original.md), DT-108. Os testes abaixo continuam válidos como verificação funcional, mas não comprovam encaixe visual. Próxima prova: um chef completo vestido e parado antes de decompor em camadas ou animar. Loja unificada permanece sem aceite próprio.

Ramo `codex/chef-loja`, base `cac07e8` da main após a publicação do cenário e sua passagem. O PO pediu corrigir a troca arbitrária de rostos, trazer movimento ao chef e reunir Loja/Reforma. Este ajuste novo **ainda não foi aprovado visualmente nem enviado**; a DT-106 continua integrada pela PR #2.

- **Identidade:** `AvatarPortrait` mantém `layers` e `layer_names(parts)` e interpreta os mesmos nomes `avatar_cabeca_<pele>_<cabelo>`. Internamente combina uma face contínua, seis cabelos, a roupa e o chapéu aprovados. Quatro tons de pele usam material próprio por instância somente na face; olhos, cabelo e roupas não são tingidos. Sem migração de save ou mudança em IDs/preços.
- **Movimento:** quatro expressões próprias (olhos abertos, meia-piscada, fechados e sorriso), piscada de 0,16 s, cumprimento de 0,85 s e respiração suave. Face, cabelo e chapéu seguem o mesmo pivô; a área de toque não se move. Somente a prévia grande usa `animated=true`; HUD e miniaturas ficam estáticos. Ocultar a janela ou o retrato interrompe seu processamento. A cabeça legada permanece como fallback se faltar uma camada modular.
- **Diálogo:** amostras de pele substituem quatro rostos diferentes; demais abas mostram a combinação atual. “Seu visual”, “Experimentando” e “Usando” esclarecem o estado. Tocar no retrato provoca um cumprimento; escolher peça também provoca reação. Comprar/Cancelar continuam explícitos, com Cancelar selecionado inicialmente. Fechar a prova não compra nem equipa uma peça paga.
- **Loja:** `build_bar.gd` mantém um único botão Loja e seis abas: Salão, Cozinha, Decoração, Pisos, Paredes e Cupons. O botão Reforma foi removido por abrir o mesmo catálogo. Aplicação/cancelamento de revestimentos e custos seguem o fluxo existente. Não foi necessário editar `cafe.gd`, tutorial ou regras.

**Arquivos:** `scenes/ui/avatar_portrait.gd`, `avatar_dialog.gd`, `avatar_part_button.gd`, `build_bar.gd`, `art/shaders/avatar_skin.gdshader`; 10 PNGs e proveniência em `art/avatar/`. Fontes RGBA, prompts exatos, hashes e calibração em [`art/portraits/avatar_modular/README.md`](../art/portraits/avatar_modular/README.md). Geradas com a ferramenta de imagens integrada da OpenAI; Python somente registra e empacota. Reproduzir com `python tools/ia/importar_avatar_modular.py`; não usar o importador legado para substituir estas fontes. Os 1.167 PNGs de `art/sprites/` e `sprites.json` permanecem idênticos à base.

**Revisão:** `Revisar Chef e Loja.cmd` abre minimizado, já no diálogo. Tocar no chef para cumprimentar; fechar para acessar a Loja no café. O script `tools/revisao/chef_loja_codex.gd` estende a amostra com simulação em memória, sem serviço de save. APPDATA/LOCALAPPDATA isolados em `build/chef-loja/interactive`; pela automação, iniciar fora da sandbox para a janela aparecer no desktop, sem trazer à frente.

**Evidências locais:** 85 capturas reais em `build/chef-loja/capturas/candidato1/`: 30 em 1280×720, 30 em 960×540 e 25 da animação. Cobrem abas, 21 peças, barra, Loja/Pisos/Paredes e gesto/piscada; execuções com saída 0 e stderr vazio. O limite do diálogo é medido no viewport lógico de 1280×720, considerando o título; a janela física de 960×540 aplica escala, não um corte de altura. `build/visual-avatar/` contém 30 combinações cabelo/chapéu, expressões e GIF de capturas reais. Resultados consolidados da suíte no topo de `status.md`.

**Contratos cobertos:** seis testes novos de retrato (identidade, materiais, ciclo/pivô, pausa e fallback), quatro de diálogo (amostras, toque, persistência e cancelamento/limites), um de navegação da Loja e três do importador. Executor, base dos testes, `core/`, `data/`, autoloads e configuração não mudam. Preservar os experimentos antigos herdados, sem incluí-los no eventual commit. Claude continua com conteúdo/calendário, regras, economia e save; aguardar avaliação e autorização do PO para publicar esta etapa.

**Validação concluída:** 775 testes Godot e 30 Python aprovados; cena principal por 120 quadros, saída 0 e sem erros. Revisão aberta minimizada no desktop (processo 27260), título confirmado e log isolado limpo. Esses resultados validam a implementação; o aceite visual da DT-107 continua com o PO.

**Pesquisa posterior, DT-108:** o PO quer preservar a estrutura e reorganizar aos poucos. O estudo registra nove posts oficiais, limites do Facebook/blog, fontes de artistas e propostas pequenas de Loja/HUD/Cidade. Nenhuma regra ou valor histórico foi aplicado ao projeto. Nesta rodada só documentos mudaram; correção de arte e reorganização ainda por executar. Claude mantém conteúdo, economia e calendário; registros antigos de “pronto para avaliar” não anulam a reprovação do avatar.
