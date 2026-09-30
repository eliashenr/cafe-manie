"""Pranchas v3 do canvas "Café Manie — Direção Visual"."""
import os
import sys
from hud3 import *
from scene3 import scene_svg, TW, TH, N
from furniture3 import *
from food3 import food, balloon, mood_face, cooking_badge, NAMES
from people3 import person

ROOT = os.environ.get("CANVAS_DIR", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "project"))
FONTS_LINK = ('<link href="https://fonts.googleapis.com/css2?family=Fredoka:wght@500;600;700&amp;family=Nunito:wght@600;700;800'
              '&amp;display=swap" rel="stylesheet">')


def page(title, w, h, body, bg="#1d3563"):
    return f'''<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<title>{title}</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
{FONTS_LINK}
<style>
body{{margin:0}}
</style>
</helmet>
{body}
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":{w},"height":{h}}}}}'>
class Component extends DCLogic {{
renderVals() {{
return {{}};
}}
}}
</script>
</body>
</html>
'''


def svg(w, h, D, body, vb=None, label=None):
    vb = vb or f"0 0 {w} {h}"
    aria = f' role="img" aria-label="{label}"' if label else ' aria-hidden="true"'
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{vb}"{aria}>{D.render()}{body}</svg>'


def over_scene(overlay_svg, scene_inline=None):
    """Prancha 1280x720: cenário (importado da prancha Cena) com a interface por cima."""
    base = scene_inline if scene_inline is not None else '<dc-import name="Cena" hint-size="1280px,720px"></dc-import>'
    return (f'<div style="position: relative; width: 1280px; height: 720px; overflow: hidden; background: #78d64a">'
            f'<div style="position: absolute; left: 0; top: 0; width: 1280px; height: 720px">{base}</div>'
            f'<div style="position: absolute; left: 0; top: 0; width: 1280px; height: 720px">{overlay_svg}</div></div>')


# --- Tela principal ----------------------------------------------------------------------

def main_overlay():
    D = Defs()
    return svg(1280, 720, D, full_hud(D), label="Interface do jogo")


def main_board(inline=False):
    return page("Café Manie — tela do jogo", 1280, 720, over_scene(main_overlay(), scene_svg() if inline else None))


def shop_overlay_svg():
    from shop3 import shop_overlay
    D = Defs()
    return svg(1280, 720, D, shop_overlay(D), label="Loja do jogo")


def shop_board(inline=False):
    return page("Café Manie — loja", 1280, 720, over_scene(shop_overlay_svg(), scene_svg() if inline else None))


def svg_board(fn, w, h, label):
    D, body = fn()
    return svg(w, h, D, body, label=label)


def characters_board_page():
    from boards_extra import characters_board
    return page("Personagens", 1280, 760, boxed(svg_board(characters_board, 1280, 760, "Personagens"), 1280, 760))


def menu_board_page():
    from boards_extra import menu_board
    return page("Cardápio e cozinha", 1280, 720, boxed(svg_board(menu_board, 1280, 720, "Cardápio e cozinha"), 1280, 720))


def style_board_page():
    from boards_extra import style_board
    return page("Guia de estilo", 1280, 1200, boxed(svg_board(style_board, 1280, 1200, "Guia de estilo"), 1280, 1200))


def scene_board():
    return page("Cenário da cafeteria", 1280, 720,
                f'<div style="width: 1280px; height: 720px; overflow: hidden; background: #78d64a">{scene_svg()}</div>')


def boxed(inner, w, h, bg="#eaf6ff"):
    return f'<div style="width: {w}px; height: {h}px; overflow: hidden; background: {bg}">{inner}</div>'


def write(name, text):
    os.makedirs(ROOT, exist_ok=True)
    with open(os.path.join(ROOT, name), "w") as fh:
        fh.write(text)


def preview(name, html_body, w, h):
    from prev import page as ppage, out
    open(out(name + ".html"), "w").write(ppage(html_body, "#1d3563"))


if __name__ == "__main__":
    what = sys.argv[1:] or ["main"]
    if "main" in what:
        preview("Main", over_scene(main_overlay(), scene_svg()), 1280, 720)
    if "loja" in what:
        preview("Loja", over_scene(shop_overlay_svg(), scene_svg()), 1280, 720)
    if "personagens" in what:
        from boards_extra import characters_board
        preview("Personagens", svg_board(characters_board, 1280, 760, "Personagens"), 1280, 760)
    if "cardapio" in what:
        from boards_extra import menu_board
        preview("Cardapio", svg_board(menu_board, 1280, 720, "Cardápio"), 1280, 720)
    if "guia" in what:
        from boards_extra import style_board
        preview("GuiaDeEstilo", svg_board(style_board, 1280, 1200, "Guia de estilo"), 1280, 1200)
    if "canvas" in what:
        write("Main.dc.html", main_board())
        write("Loja.dc.html", shop_board())
        write("Cena.dc.html", scene_board())
        write("Personagens.dc.html", characters_board_page())
        write("Cardapio.dc.html", menu_board_page())
        write("GuiaDeEstilo.dc.html", style_board_page())
    print("ok")
