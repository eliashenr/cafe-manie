# Garçom — visual aprovado no jogo

Fontes do primeiro lote do Codex, baseado na imagem-alvo aprovada pelo PO em 22/11/2026.
As folhas e o retrato foram gerados com a ferramenta de imagem integrada ao Codex. Os prompts estão nesta pasta.
`art/characters/.gdignore` mantém as fontes fora da importação/exportação do jogo; os PNGs usados pelo jogo ficam em `art/sprites`.

## Fontes e calibração

- `frente_livre.png` e `frente_bandeja.png`: oito passos e uma pose parada, em grade 3×3.
- `costas_livre_v2.png` e `costas_bandeja_v2.png`: costas com o contato dos pés corrigido. As primeiras versões ficam como registro da comparação.
- `icone.png`: retrato do mesmo garçom para o botão da interface.
- `calibracao.json`: registro das células, escala única por folha, espelho das costas e posição do prato em cada quadro.

O importador só recorta, redimensiona e registra as imagens com transparência nativa. Não apaga o fundo nem inventa quadros por deformação. Cada ciclo tem oito imagens distintas. Os estados com e sem bandeja têm desenhos próprios.

## Gerar e conferir

Na raiz da cópia visual, com Python, Pillow e NumPy disponíveis:

```text
python tools/ia/importar_garcom_codex.py art/characters/waiter/calibracao.json --out build/visual-garcom
```

Isso gera as poses, o ícone, uma folha com marcas e um GIF em `build/visual-garcom`, sem mudar o catálogo do jogo. Depois de conferir, repetir com `--install` instala somente os 36 sprites `garcom_*`, `icone_garcom`, suas entradas e as duas medidas legadas da bandeja no manifesto. Não rodar dois instaladores/geradores ao mesmo tempo.

Importar o projeto na Godot antes de conferir imagens novas. Usar `APPDATA` e `LOCALAPPDATA` de teste. Nunca usar o save pessoal.

`tools/revisao/garcom_codex.gd` permite conferir quatro ciclos e poses paradas no café real. Ele usa o renderizador do jogo, com simulação em memória, sem salvar progresso.

## Contrato de apresentação

- Altura de referência: 96 pixels de mundo; densidade: 4.
- A imagem não contém sombra. `external_shadow` solicita uma sombra desenhada no chão.
- `authored_motion` evita somar quique, respiração ou deformação aos quadros já desenhados.
- `tray` informa a posição e a largura do prato, inclusive na pose parada.
- Clientes, regras, economia, IDs e formato do save permanecem fora deste lote.

O PO aprovou o visual no jogo em 22/11/2026 e autorizou seguir para os clientes. A demonstração original usava um corredor artificial lento; isso não alterava a velocidade nem a navegação de produção. A revisão interativa está sendo ajustada para usar os caminhos reais do café. Aprovação visual não autoriza commit/envio.
