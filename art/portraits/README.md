# Retratos e camadas do chef — DT-105

45 sprites: 24 cabeças (quatro peles × seis cabelos), seis roupas, cinco chapéus, ícone chef, sete vizinhos, bruxa e Papai Noel. Mantêm IDs, compras e personalização existentes.

Fontes geradas pela ferramenta integrada da OpenAI usando o garçom aprovado como referência. `prompts.json` guarda os pedidos iniciais; `prompt-limpeza.txt` registra a limpeza do fundo dos vizinhos. Fonte final: `vizinhos_limpos.png`. O importador preserva o alfa original.

`calibracao.json` registra célula, origem, destino na caixa 140×170 e escala uniforme. As cabeças compartilham registro por cabelo entre as quatro peles. Ordem: roupa, cabeça, chapéu. O ícone chef é composto das mesmas camadas. Fontes fora do jogo por `.gdignore`.

```text
python tools/ia/importar_retratos_codex.py art/portraits/calibracao.json --out build/retratos-reproducao
python tools/ia/integrar_visual_codex.py build/retratos-reproducao --install
```

Primeiro gera staging, proveniência e 36 combinações para conferência; depois valida e instala entradas existentes. Um escritor do manifesto por vez. Importar os PNGs na Godot após instalar. Provas: `build/visual-reformulacao/retratos/`.
