# Sprites do jogo

Os sprites dos móveis saem do mesmo código que desenhou a direção visual v3 (`tools/art_direction/v3`).
Decisão em [DT-030](../../docs/decisions.md).

## Como regenerar

Na pasta do projeto:

```bash
python tools/art_direction/v3/export_sprites.py                  # desenha e converte para tools/sprites/raw/
godot --headless -s res://tools/sprites/crop_sprites.gd          # recorta e grava art/furniture/
godot --headless --import                                        # a Godot importa os PNGs novos
```

- O primeiro passo precisa do Chrome ou do Edge (todo Windows tem o Edge). Outro caminho vai em `SPRITES_BROWSER`.
- No Windows, rode o Python com `PYTHONUTF8=1` se aparecer erro de acentuação.
- `tools/sprites/raw/` é descartável e fica fora do git. Os PNGs de `art/furniture/` entram no repositório.

## Como entra um móvel novo

1. Desenhe a função do móvel em `tools/art_direction/v3/furniture3.py` (ou reaproveite uma).
2. Acrescente o id dele em `FURNITURE`, no `export_sprites.py`, com a pegada e quantos desenhos diferentes ele tem
   (4 se a frente importa, 2 se só muda o comprimento, 1 se é simétrico).
3. Rode os três comandos acima. O teste `test_furniture_art.gd` reprova móvel do catálogo sem sprite.

## Conferência visual

```bash
godot -s res://tools/screenshot.gd -- <cópia do save.json> foto.png 120 1.8
```

Abre a cafeteria com uma janela de verdade e grava a tela (o último número é o zoom). Use sempre uma **cópia** do save:
o jogo salva sozinho.
