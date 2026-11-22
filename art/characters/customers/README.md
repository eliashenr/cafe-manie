# Clientes — integração com o mobiliário da DT-105

Doze identidades e 24 poses por pessoa: oito passos de frente, oito de costas, duas poses em pé, quatro expressões sentadas e duas costas sentadas. Total: 288 sprites. A reformulação ampla foi autorizada em 22/11/2026; o aceite anterior se referia ao garçom.

## Fontes em uso

`calibracao.json` é a fonte de verdade; todos os arquivos são relativos a esta pasta.

- As 12 folhas originais 4×6 fornecem as 216 poses em pé/andando. Cliente 03 mantém a correção registrada em `ajuste-contato-03.json`.
- As folhas `cliente_NN_sentados_v2.png` fornecem as frentes sentadas, normalizadas pela cabeça da pose em pé, sem a ampliação anterior de 15%.
- Cliente 05 usa `cliente_05_frentes_v3.png`: quatro poses 2×2 com canelas corrigidas, células explícitas e registro dos glúteos em `frames.registration`.
- As 24 costas usam `costas_lote1_v4.png` e `costas_lote2_v4.png`: quatro colunas × três linhas, seis pessoas por folha, cada par r1/r2. A primeira célula do lote 2 exclui 12 pixels de margem superior com fragmento externo, sem atingir a cabeça.

Fontes geradas/editadas pela ferramenta integrada da OpenAI, sem créditos de ElevenLabs. Prompts originais e ajustes v2/v3/v4 acompanham as fontes. Experimentos permanecem como histórico; não selecionar imagens automaticamente pelo maior número de versão.

## Encaixe

O ponto sob os glúteos ancora no assento, relativo ao vértice frontal da cadeira. Contrato DT-105: assento z0,28, contato z0,265, recuo0,06. Alvos: frente[-3,84;-54,691673], costas r1[3,84;-50,851673], costas r2[-3,84;-50,851673]. A frente r0 é espelhada pelo jogo; as costas são poses próprias.

Escala uniforme por grupo, baseada na cabeça em pé. Não normalizar pela altura sentada nem mover o corpo inteiro para esconder erro dos pés. Medidas de piso em 2D são diagnósticas: separação lateral e perspectiva mudam a projeção. Validar também nas cadeiras reais, nas quatro direções.

`authored_motion` evita quique/respiração adicional. `external_shadow` só nas poses em pé; cadeira e encosto são desenhados separadamente. Preservar o alfa nativo, sem remover fundo por limiar. As fontes ficam fora do jogo por `.gdignore`.

## Reproduzir e conferir

```text
python tools/ia/importar_clientes_codex.py art/characters/customers/calibracao.json --out build/clientes-reproducao
```

Sem `--install`, prepara 288 PNGs, manifesto parcial, proveniência e mosaicos. Instalar depois de conferir, com um único escritor do manifesto. Importar na Godot antes de testar/capturar.

`clientes_codex.gd -Extra todos` produz 111 capturas; 108 detalhes cobrem 12 pessoas × nove estados. A rodada DT-105 fica em `build/visual-reformulacao/capturas-clientes/` e `montagens/`; resultados em `docs/status.md`.

`Revisar Visual.cmd` abre minimizado, com navegação real e dados em memória: C coleções, N dia/noite, 1/2 lotes, 0 todos. APPDATA e LOCALAPPDATA isolados; save pessoal intocado. Commit/envio exigem "Pode enviar".
