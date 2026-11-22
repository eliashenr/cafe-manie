# Passagem visual — Codex para Claude

## Estado e autorização (22/11/2026)

**Atualização:** o PO também aprovou a DT-106: “Pode enviar esse novo cenário e integrar à main.” Os 413 sprites foram publicados em `26c873f` e integrados à `main` pela [PR #2](https://github.com/eliashenr/cafe-manie/pull/2), merge `71489f0`, com a conta `eliashenr` e CI aprovado. A próxima etapa autorizada (DT-107) é melhorar a interação/continuidade do avatar do chef e unificar Loja/Reforma; ela não faz parte do lote de cenário já integrado.

O PO aprovou a reformulação dentro do jogo: “Ficou muito bom! Pode enviar”, e confirmou “Sim, pode integrar à main”. A entrega DT-103/104/105 partiu de `737f73e`, após o Natal, foi enviada em `a09f8e9` e integrada pela [PR #1](https://github.com/eliashenr/cafe-manie/pull/1) no merge `449e755`. Os testes de push e PR passaram antes da integração. A `main` já contém a reformulação aprovada; o cenário DT-106 também foi aprovado e integrado pela PR #2.

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
