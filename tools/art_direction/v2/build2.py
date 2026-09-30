"""Pranchas v2 do canvas "Café Manie — Direção Visual"."""
import json, os, sys, datetime
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "gen"))
from ui import icon  # ícones da interface (v1, aprovados como base)
from core import *
from food import food, balloon, mood_face, cooking_badge, NAMES
from people import person
from furniture import round_table, chair, stove, counter, pastry_case, espresso, plant, jukebox, floor_lamp
from scene2 import scene_svg

ROOT = os.path.join(os.path.dirname(__file__), "..", "project")
FONTS = '<link href="https://fonts.googleapis.com/css2?family=Fredoka:wght@500;600;700&amp;family=Nunito:wght@600;700;800&amp;display=swap" rel="stylesheet">'
DISP = "font-family: Fredoka, Nunito, sans-serif"
CREAM, LEITE, MEL, TOMATE, FOLHA, CHOC, CANELA = "#fff4df", "#fffaf0", "#f4c542", "#e2503f", "#3f9a45", "#6b3f26", "#a8643a"


def page(title, w, h, body):
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
{FONTS}
<style>
body{{margin:0;background:#3a2217}}
a{{color:#a8643a}}a:hover{{color:#6b3f26}}
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


def svg_el(w, h, vb, D, body, label=None):
    aria = f' role="img" aria-label="{label}"' if label else ' aria-hidden="true"'
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{vb}"{aria}>{D.render()}{body}</svg>'


# --- HUD com cara de jogo social (painéis cremosos, contorno café, brilho em cima) ---------

GLOSS = (f"background: linear-gradient(180deg, #fffdf6 0%, #fff3da 48%, #f3dfb8 100%); border: 3px solid {INK}; "
         f"box-shadow: 0 4px 0 {INK}, inset 0 2px 0 rgba(255,255,255,0.9)")


def plus_button(label):
    return (f'<button aria-label="{label}" style="width: 30px; height: 30px; border-radius: 15px; '
            f'background: linear-gradient(180deg, #7fd36b, #3f9a45); border: 2.5px solid {INK}; box-shadow: 0 2px 0 {INK}, inset 0 2px 0 rgba(255,255,255,0.55); '
            f'display: flex; align-items: center; justify-content: center; padding: 0">{icon("mais", 22)}</button>')


def coin_svg(size=34):
    D = Defs()
    r = 14
    b = (C(17, 17, r, D.rad([(0, "#fff3b0"), (0.5, "#f7cf4a"), (1, "#d09a1f")], 0.35, 0.3, 0.75), INK, 1.8)
         + C(17, 17, r * 0.68, "none", "#c28a1d", 1.5)
         + path("M20.5,12.4 a5.4,5.4 0 1 0 0,9.2", "none", "#8a5a17", 2.4)
         + E(11, 11, 3.4, 1.8, "#fffbe0", None, extra='transform="rotate(-35 11 11)"'))
    return svg_el(size, size, "0 0 34 34", D, b)


def bean_svg(size=34):
    D = Defs()
    b = g(E(17, 17, 10.5, 13.5, D.rad([(0, "#9ff0cf"), (0.55, "#3fbf8f"), (1, "#1f7a57")], 0.35, 0.3, 0.75), INK, 1.8)
          + path("M17,5 q-6,12 0,24", "none", "#17664a", 2.2)
          + E(12.5, 11, 1.8, 3.6, "#e2fff3", None), "rotate(-25 17 17)")
    return svg_el(size, size, "0 0 34 34", D, b)


def counter_pill(icon_svg, value, plus_label=None, width=198):
    return (f'<div style="display: flex; align-items: center; gap: 8px; width: {width}px; height: 44px; box-sizing: border-box; padding: 0 6px 0 4px; {GLOSS}; border-radius: 24px">'
            f'{icon_svg}<span style="{DISP}; font-weight: 700; font-size: 23px; color: {INK}; flex-grow: 1">{value}</span>'
            + (plus_button(plus_label) if plus_label else "") + '</div>')


def level_block(level=12, xp="4.820 / 6.100 XP", pct=62, bar_w=300):
    return (f'<div style="display: flex; align-items: center">'
            f'<div style="position: relative; z-index: 1; width: 68px; height: 68px; border-radius: 34px; '
            f'background: radial-gradient(circle at 35% 30%, #9a6440, #6b3f26 60%, #4a2715); border: 3px solid {INK}; box-shadow: 0 4px 0 {INK}, inset 0 2px 0 rgba(255,255,255,0.35); '
            f'display: flex; flex-direction: column; align-items: center; justify-content: center">'
            f'<span style="{DISP}; font-size: 11px; font-weight: 600; color: {MEL}; letter-spacing: 1px">NÍVEL</span>'
            f'<span style="{DISP}; font-size: 30px; font-weight: 700; color: #ffffff; line-height: 28px">{level}</span></div>'
            f'<div style="position: relative; margin-left: -12px; width: {bar_w}px; height: 32px; box-sizing: border-box; background: linear-gradient(180deg, #e9d9b8, #f7ecd6); '
            f'border: 3px solid {INK}; border-radius: 0 17px 17px 0; overflow: hidden; box-shadow: 0 3px 0 {INK}">'
            f'<div style="width: {pct}%; height: 100%; background: linear-gradient(180deg, #ffe68a 0%, #f4c542 55%, #e0a624 100%); border-radius: 0 13px 13px 0"></div>'
            f'<div style="position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; {DISP}; font-size: 15px; font-weight: 700; color: {INK}">{xp}</div></div></div>')


def round_button(name, label, size=46):
    return (f'<button aria-label="{label}" style="width: {size}px; height: {size}px; border-radius: 14px; {GLOSS}; box-shadow: 0 3px 0 {INK}, inset 0 2px 0 rgba(255,255,255,0.9); '
            f'display: flex; align-items: center; justify-content: center; padding: 0">{icon(name, size - 14)}</button>')


def badge(text):
    return (f'<span style="position: absolute; top: -8px; right: -6px; min-width: 22px; height: 22px; border-radius: 11px; background: linear-gradient(180deg, #ff7a5c, #d83a2a); '
            f'border: 2px solid {INK}; {DISP}; font-size: 13px; font-weight: 700; color: #ffffff; display: flex; align-items: center; justify-content: center">{text}</span>')


def toolbar_button(name, label, b=None):
    return (f'<button style="position: relative; width: 90px; height: 88px; border-radius: 16px; {GLOSS}; '
            f'display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 2px; padding: 0">{icon(name, 48)}'
            f'<span style="{DISP}; font-size: 14px; font-weight: 600; color: {INK}">{label}</span>{badge(b) if b else ""}</button>')


def avatar(skin, hair, top, extra=None, size=58):
    D = Defs()
    b = person(D, 0, 0, 1.0, 1, "em_pe", skin, hair, top, ("calca", "#34495e"), **(extra or {}))
    return svg_el(size, size, "-22 -104 48 48", D, b)


def neighbor_card(name, level, skin, hair, top, bg, extra=None):
    return (f'<div style="width: 72px; display: flex; flex-direction: column; align-items: center; gap: 3px">'
            f'<div style="position: relative; width: 62px; height: 62px; border-radius: 12px; background: {bg}; border: 3px solid {INK}; overflow: hidden; '
            f'display: flex; align-items: center; justify-content: center">{avatar(skin, hair, top, extra)}'
            f'<span style="position: absolute; left: -3px; bottom: -3px; width: 26px; height: 26px; border-radius: 13px; background: linear-gradient(180deg, #ffe68a, #e0a624); '
            f'border: 2.5px solid {INK}; {DISP}; font-size: 13px; font-weight: 700; color: {INK}; display: flex; align-items: center; justify-content: center">{level}</span></div>'
            f'<span style="{DISP}; font-size: 13px; font-weight: 600; color: {INK}">{name}</span></div>')


def invite_card():
    return (f'<div style="width: 72px; display: flex; flex-direction: column; align-items: center; gap: 3px">'
            f'<button aria-label="Convidar vizinho" style="width: 62px; height: 62px; border-radius: 12px; background: linear-gradient(180deg, #7fd36b, #3f9a45); '
            f'border: 3px solid {INK}; box-shadow: inset 0 2px 0 rgba(255,255,255,0.5); display: flex; align-items: center; justify-content: center; padding: 0">{icon("mais", 36)}</button>'
            f'<span style="{DISP}; font-size: 13px; font-weight: 600; color: {INK}">Convidar</span></div>')


def mission_card():
    return (f'<div style="width: 236px; box-sizing: border-box; padding: 10px 12px; {GLOSS}; border-radius: 16px; display: flex; gap: 10px; align-items: center">'
            f'{icon("missoes", 40)}<div style="display: flex; flex-direction: column; gap: 4px; flex-grow: 1">'
            f'<span style="{DISP}; font-size: 12px; font-weight: 600; color: {CANELA}; letter-spacing: 0.5px">MISSÃO 4 DE 6</span>'
            f'<span style="font-family: Nunito, sans-serif; font-size: 15px; font-weight: 800; color: {INK}">Sirva 3 cafés</span>'
            f'<div style="height: 11px; border-radius: 6px; background: #eadbbd; border: 2px solid {INK}; overflow: hidden">'
            f'<div style="width: 66%; height: 100%; background: linear-gradient(180deg, #8fe07a, #3f9a45)"></div></div></div></div>')


def gift_bubble():
    return (f'<button aria-label="Recompensa diária" style="position: relative; width: 62px; height: 62px; border-radius: 31px; {GLOSS}; display: flex; align-items: center; justify-content: center; padding: 0">'
            f'{icon("presentes", 42)}{badge("1")}</button>')


def mood_svg(state, size=34):
    D = Defs()
    return svg_el(size, size, "-17 -17 34 34", D, mood_face(D, 0, 0, state, 14))


def hud():
    top = (f'<div style="position: absolute; left: 14px; top: 12px; right: 14px; display: flex; align-items: flex-start; justify-content: space-between">'
           f'<div style="display: flex; flex-direction: column; gap: 8px">{counter_pill(coin_svg(), "12.480", "Comprar Café Ouro")}'
           f'{counter_pill(bean_svg(), "37", "Comprar Café Grana")}</div>'
           f'<div style="padding-left: 40px">{level_block()}</div>'
           f'<div style="display: flex; flex-direction: column; gap: 8px; align-items: flex-end">'
           f'{counter_pill(mood_svg("feliz"), "86%", None, 150)}{counter_pill(icon("flor", 34), "148", None, 150)}</div></div>')
    side = (f'<div style="position: absolute; right: 14px; top: 124px; display: flex; flex-direction: column; gap: 8px">'
            f'{round_button("zoom_in", "Aproximar")}{round_button("zoom_out", "Afastar")}{round_button("tela", "Tela cheia")}{round_button("musica", "Música")}{round_button("som", "Sons")}</div>'
            f'<div style="position: absolute; left: 14px; top: 122px; display: flex; flex-direction: column; gap: 12px; align-items: flex-start">{mission_card()}{gift_bubble()}</div>')
    tools = "".join(toolbar_button(n, l, b) for n, l, b in [
        ("loja", "Loja", None), ("decorar", "Decorar", None), ("cardapio", "Cardápio", None),
        ("missoes", "Missões", "1"), ("conquistas", "Conquistas", None), ("presentes", "Presentes", "2")])
    neighbors = "".join([
        neighbor_card("Ana", 21, "clara", ("coque", "castanho"), ("blusa", "#5fc3a4"), "#bfe6f5", {"lashes": True}),
        neighbor_card("Beto", 18, "negra", ("curto", "preto"), ("camisa", "#f4c542"), "#ffe39a"),
        neighbor_card("Duda", 25, "morena_clara", ("longo", "ruivo"), ("blusa", "#c7355a"), "#ffc7d4", {"lashes": True, "freckles": True}),
        neighbor_card("Caio", 12, "parda", ("bone", "preto"), ("moletom", "#3d7fc9"), "#c9f0dd", {"cap": "#e2503f"}),
        invite_card()])
    bottom = (f'<div style="position: absolute; left: 14px; bottom: 12px; display: flex; gap: 10px; padding: 12px; {GLOSS}; border-radius: 22px">{tools}</div>'
              f'<div style="position: absolute; right: 14px; bottom: 12px; display: flex; flex-direction: column; gap: 6px; padding: 8px 12px 12px; {GLOSS}; border-radius: 22px">'
              f'<span style="{DISP}; font-size: 14px; font-weight: 600; color: {CANELA}; letter-spacing: 1px">VIZINHOS</span>'
              f'<div style="display: flex; gap: 8px">{neighbors}</div></div>')
    return top + side + bottom


def with_scene(overlay):
    return (f'<div style="position: relative; width: 1280px; height: 720px; overflow: hidden; font-family: Nunito, sans-serif; background: #79c267">'
            f'<div style="position: absolute; left: 0; top: 0; width: 1280px; height: 720px"><dc-import name="Cena" hint-size="1280px,720px"></dc-import></div>'
            f'{overlay}</div>')


def main_board():
    return page("Café Manie — tela do jogo", 1280, 720, with_scene(hud()))


def scene_board():
    return page("Cenário da cafeteria", 1280, 720, f'<div style="width: 1280px; height: 720px; overflow: hidden">{scene_svg()}</div>')


# --- Loja ------------------------------------------------------------------------------

def item_svg(kind, size=112):
    D = Defs()
    iso = Iso(0, 0)
    vb = "-46 -66 92 104"
    if kind == "mesa":
        b = round_table(D, iso, 0, 0, "#d83a3a")
    elif kind == "mesa_verde":
        b = round_table(D, iso, 0, 0, "#2f8f5a")
    elif kind == "cadeira":
        b = chair(D, iso, 0, 0, "+x")
        vb = "-40 -66 80 104"
    elif kind == "balcao":
        b = counter(D, iso, 0, 0, "R", [("bolo", 8)])
        vb = "-52 -84 104 128"
    elif kind == "fogao":
        b = stove(D, iso, 0, 0, "R", cooking="pao")
        vb = "-52 -66 104 110"
    elif kind == "vitrine":
        b = pastry_case(D, iso, 0, 0)
        vb = "-52 -86 104 128"
    elif kind == "vitrola":
        b = jukebox(D, iso, 0, 0)
        vb = "-50 -70 100 112"
    elif kind == "planta":
        b = plant(D, iso, 0, 0, big=True, seed=5)
        vb = "-58 -128 116 176"
    elif kind == "luminaria":
        b = floor_lamp(D, iso, 0, 0)
        vb = "-58 -128 116 176"
    elif kind == "expresso":
        b = espresso(D, iso, 0, 0)
        vb = "-52 -96 104 140"
    return svg_el(size, size, vb, D, b)


SHOP = [("mesa", "Mesa xadrez", 60, None, None), ("mesa_verde", "Mesa verde", 60, None, "Novo!"), ("cadeira", "Cadeira bistrô", 30, None, None),
        ("balcao", "Balcão de mármore", 120, None, None), ("fogao", "Fogão industrial", 150, None, None),
        ("vitrine", "Vitrine de doces", 180, 2, "Novo!"), ("expresso", "Máquina de expresso", 320, 5, None), ("vitrola", "Vitrola", 250, 4, None)]


def shop_card(kind, name, price, level, ribbon, selected=False):
    border = f"4px solid {MEL}" if selected else f"3px solid {INK}"
    locked = level is not None and level > 3
    rib = (f'<span style="position: absolute; top: 8px; left: -4px; padding: 2px 10px; background: linear-gradient(180deg, #ff7a5c, #d83a2a); border: 2px solid {INK}; '
           f'border-radius: 0 8px 8px 0; {DISP}; font-size: 12px; font-weight: 700; color: #ffffff">{ribbon}</span>') if ribbon else ""
    lock = (f'<span style="position: absolute; top: 50px; left: 50%; transform: translateX(-50%); display: flex; align-items: center; gap: 4px; padding: 3px 10px 3px 4px; '
            f'background: {INK}; border-radius: 14px; {DISP}; font-size: 14px; font-weight: 600; color: {MEL}">{icon("cadeado", 22)}Nível {level}</span>') if locked else ""
    D = Defs()
    coin = svg_el(20, 20, "0 0 34 34", D, C(17, 17, 14, "#f7cf4a", INK, 2) + path("M20.5,12.4 a5.4,5.4 0 1 0 0,9.2", "none", "#8a5a17", 2.6))
    prev_style = "filter: grayscale(1); opacity: 0.5" if locked else ""
    return (f'<button style="position: relative; width: 154px; height: 190px; box-sizing: border-box; border-radius: 16px; '
            f'background: linear-gradient(180deg, #fffdf8, #f6ead4); border: {border}; box-shadow: 0 4px 0 {INK}; '
            f'display: flex; flex-direction: column; align-items: center; justify-content: flex-end; gap: 3px; padding: 0 6px 12px">'
            f'<div style="{prev_style}">{item_svg(kind, 118)}</div>'
            f'<span style="{DISP}; font-size: 14px; font-weight: 600; color: {INK}; text-align: center; line-height: 1.1">{name}</span>'
            f'<div style="display: flex; align-items: center; gap: 4px; {DISP}; font-size: 17px; font-weight: 700; color: {INK}">{coin}{price}</div>{rib}{lock}</button>')


def shop_board():
    tabs = ""
    for i, (ic, label) in enumerate([("loja", "Móveis"), ("flor", "Decoração"), ("piso", "Piso"), ("parede", "Parede"), ("estrela", "Especiais")]):
        active = i == 0
        bg = "linear-gradient(180deg, #fffdf8, #fffaf0)" if active else "linear-gradient(180deg, #f3dfb8, #e2c796)"
        tabs += (f'<button style="display: flex; align-items: center; gap: 6px; height: 48px; padding: 0 14px 0 8px; border-radius: 14px 14px 0 0; background: {bg}; '
                 f'border: 3px solid {INK}; border-bottom: {"none" if active else f"3px solid {INK}"}; margin-bottom: {"-3px" if active else "0"}; '
                 f'{DISP}; font-size: 16px; font-weight: 600; color: {INK}">{icon(ic, 30)}{label}</button>')
    cards = "".join(shop_card(k, n, p, l, r, selected=(k == "mesa_verde")) for k, n, p, l, r in SHOP)
    detail = (f'<div style="width: 262px; box-sizing: border-box; padding: 16px; border-radius: 16px; background: linear-gradient(180deg, #fffdf8, #f6ead4); '
              f'border: 3px solid {INK}; display: flex; flex-direction: column; align-items: center; gap: 10px">'
              f'<div style="width: 190px; height: 168px; border-radius: 14px; background: radial-gradient(circle at 50% 40%, #fff7e6, #efdcb8); border: 2px solid #d9c29a; '
              f'display: flex; align-items: center; justify-content: center">{item_svg("mesa_verde", 170)}</div>'
              f'<span style="{DISP}; font-size: 24px; font-weight: 700; color: {INK}">Mesa verde</span>'
              f'<span style="font-size: 15px; font-weight: 700; color: {CHOC}; text-align: center">Toalha xadrez com babado e vasinho de flor. Dois lugares.</span>'
              f'<div style="display: flex; gap: 6px">'
              f'<span style="display: flex; align-items: center; gap: 4px; padding: 4px 10px 4px 4px; border-radius: 14px; background: #fde6ee; border: 2px solid {INK}; font-size: 14px; font-weight: 800; color: {INK}">{icon("flor", 22)}Beleza +5</span>'
              f'<span style="display: flex; align-items: center; gap: 4px; padding: 4px 10px 4px 4px; border-radius: 14px; background: #e3f6ee; border: 2px solid {INK}; font-size: 14px; font-weight: 800; color: {INK}">{icon("amigos", 22)}2 lugares</span></div>'
              f'<div style="display: flex; align-items: center; gap: 6px; {DISP}; font-size: 30px; font-weight: 700; color: {INK}">{coin_svg(32)}60</div>'
              f'<button style="width: 100%; height: 54px; border-radius: 16px; background: linear-gradient(180deg, #6fcf5c 0%, #2f8a3a 100%); border: 3px solid {INK}; '
              f'box-shadow: 0 4px 0 {INK}, inset 0 2px 0 rgba(255,255,255,0.5); {DISP}; font-size: 22px; font-weight: 700; color: #ffffff">Comprar</button>'
              f'<span style="font-size: 13px; font-weight: 700; color: {CANELA}">Você tem 12.480 de Café Ouro</span></div>')
    arrow = lambda ic, lab: (f'<button aria-label="{lab}" style="width: 42px; height: 42px; border-radius: 21px; background: linear-gradient(180deg, #c98a5e, #8a5534); '
                             f'border: 3px solid {INK}; display: flex; align-items: center; justify-content: center; padding: 0">{icon(ic, 30)}</button>')
    modal = (f'<div style="position: absolute; left: 104px; top: 62px; width: 1072px; height: 600px; box-sizing: border-box; padding: 34px 26px 22px; border-radius: 26px; '
             f'background: linear-gradient(180deg, #fbefd6, #f1ddb6); border: 4px solid {INK}; box-shadow: 0 8px 0 {INK}; display: flex; flex-direction: column">'
             f'<div style="position: absolute; top: -26px; left: 50%; transform: translateX(-50%); padding: 6px 52px; background: linear-gradient(180deg, #ff7a5c, #d8392a); '
             f'border: 4px solid {INK}; border-radius: 14px; box-shadow: 0 4px 0 {INK}, inset 0 2px 0 rgba(255,255,255,0.45); {DISP}; font-size: 30px; font-weight: 700; color: #ffffff">Loja</div>'
             f'<button aria-label="Fechar loja" style="position: absolute; top: -18px; right: -18px; width: 52px; height: 52px; border-radius: 26px; background: linear-gradient(180deg, #ff7a5c, #d8392a); '
             f'border: 4px solid {INK}; box-shadow: 0 4px 0 {INK}; display: flex; align-items: center; justify-content: center; padding: 0">{icon("fechar", 34)}</button>'
             f'<div style="display: flex; gap: 6px; padding-left: 8px">{tabs}</div>'
             f'<div style="display: flex; gap: 18px; padding: 18px; border-radius: 0 16px 16px 16px; background: #fffaf0; border: 3px solid {INK}; flex-grow: 1">'
             f'<div style="display: flex; flex-direction: column; gap: 12px; flex-grow: 1">'
             f'<div style="display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 12px; justify-items: center">{cards}</div>'
             f'<div style="display: flex; align-items: center; justify-content: center; gap: 14px">{arrow("seta_esq", "Página anterior")}'
             f'<span style="{DISP}; font-size: 17px; font-weight: 600; color: {INK}">1 / 3</span>{arrow("seta_dir", "Próxima página")}</div></div>'
             f'{detail}</div></div>')
    overlay = f'<div style="position: absolute; inset: 0; background: rgba(40, 22, 12, 0.55)"></div>{modal}'
    return page("Café Manie — loja", 1280, 720, with_scene(overlay))


# --- Personagens -------------------------------------------------------------------------

def figure(D, body, w, h, vb):
    return svg_el(w, h, vb, D, body)


def label(text, sub=None):
    s = f'<span style="{DISP}; font-size: 17px; font-weight: 600; color: {INK}">{text}</span>'
    if sub:
        s += f'<span style="font-size: 13px; font-weight: 700; color: {CANELA}">{sub}</span>'
    return f'<div style="display: flex; flex-direction: column; align-items: center; gap: 1px">{s}</div>'


def h2(text):
    return f'<h2 style="margin: 0; {DISP}; font-size: 26px; font-weight: 700; color: {INK}">{text}</h2>'


def characters_board():
    cast = [
        ("Clara", "vem todo dia", dict(skin="clara", hair=("rabo", "castanho"), top=("blusa", "#e2503f"), bottom=("calca", "#34495e"), lashes=True)),
        ("Tomás", "sempre com pressa", dict(skin="parda", hair=("bone", "preto"), top=("moletom", "#3d7fc9"), bottom=("calca", "#2b2b33"), cap="#e2503f")),
        ("Dona Lu", "freguesa fiel", dict(skin="clara", hair=("chanel", "grisalho"), top=("blusa", "#c7355a"), bottom=("saia", "#6b3f26"), glasses=True, lashes=True)),
        ("Rafa", "estudante", dict(skin="clara", hair=("curto", "loiro"), top=("camiseta", "#e8813a"), bottom=("calca", "#3b4a55"))),
        ("Nina", "turista", dict(skin="negra", hair=("black", "preto"), top=("camiseta", "#f4c542"), bottom=("calca", "#5da84e"), lashes=True)),
        ("Jorge", "trabalha ao lado", dict(skin="morena", hair=("topete", "preto"), top=("camisa", "#8fd0f0"), bottom=("calca", "#3b4a55"), beard=True)),
        ("Bela", "ama bolo", dict(skin="morena_clara", hair=("longo", "ruivo"), top=("blusa", "#5fc3a4"), bottom=("saia", "#3d5a80"), lashes=True, freckles=True)),
        ("Iara", "leva para viagem", dict(skin="negra", hair=("coque", "preto"), top=("camisa", "#ffffff"), bottom=("calca", "#6b3f26"), lashes=True)),
    ]
    row1 = ""
    for i, (n, sub, kw) in enumerate(cast):
        D = Defs()
        body = person(D, 0, 0, 1.0, 1 if i % 2 == 0 else -1, "em_pe", **kw)
        row1 += f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px">{figure(D, body, 120, 190, "-34 -110 70 114")}{label(n, sub)}</div>'
    staff = [
        ("Chef Bia", "mascote e cozinheira", dict(pose="em_pe", skin="negra", hair=("black", "preto"), top=("chef", "#ffffff"), bottom=("calca", "#3b4a55"), apron="#ffffff", hat="chef", lashes=True), "-34 -130 70 134"),
        ("Léo", "garçom", dict(pose="andar", skin="morena_clara", hair=("curto", "preto"), top=("garcom", "#ffffff"), bottom=("calca", "#23232b"), tray="bolo"), "-30 -112 80 116"),
    ]
    row2 = ""
    for (n, sub, kw, vb) in staff:
        D = Defs()
        body = person(D, 0, 0, 1.0, 1, **kw)
        row2 += f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px">{figure(D, body, 150, 230, vb)}{label(n, sub)}</div>'
    D = Defs()
    moods = ""
    for st, t in [("feliz", "Feliz"), ("esperando", "Esperando"), ("bravo", "Bravo")]:
        D = Defs()
        moods += f'<div style="display: flex; flex-direction: column; align-items: center; gap: 6px">{svg_el(64, 64, "-32 -32 64 64", D, mood_face(D, 0, 0, st, 26))}{label(t)}</div>'
    seated = ""
    for (expr, t, kw) in [("esperando", "esperando o pedido", dict(skin="clara", hair=("rabo", "loiro"), top=("blusa", "#c7355a"), lashes=True)),
                          ("comendo", "comendo", dict(skin="parda", hair=("longo", "preto"), top=("blusa", "#f4c542"), lashes=True)),
                          ("bravo", "demorou demais!", dict(skin="morena", hair=("topete", "castanho"), top=("camisa", "#5da84e")))]:
        D = Defs()
        iso = Iso(0, 0)
        sx, sy = iso.v(0.5, 0.5, 30)
        body = (chair(D, iso, 0, 0, "+x") + person(D, sx, sy, 1.0, 1, "sentado", expr=expr, bottom=("calca", "#34495e"), **kw)
                + round_table(D, iso, 1, 0, "#d83a3a", dishes=["cafe"] if expr == "comendo" else []))
        if expr == "esperando":
            body += balloon(D, "pao", sx + 8, sy - 50, 30, patience=0.55)
        if expr == "bravo":
            body += mood_face(D, sx + 18, sy - 58, "bravo", 10)
        seated += f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px">{figure(D, body, 170, 150, "-44 -112 132 150")}{label(t)}</div>'
    body = (f'<div style="width: 1280px; height: 760px; box-sizing: border-box; padding: 34px 44px; background: {CREAM}; font-family: Nunito, sans-serif; display: flex; flex-direction: column; gap: 18px">'
            f'{h2("Clientes")}<div style="display: flex; justify-content: space-between">{row1}</div>'
            f'<div style="display: flex; gap: 56px; align-items: flex-start">'
            f'<div style="display: flex; flex-direction: column; gap: 10px">{h2("Equipe")}<div style="display: flex; gap: 28px">{row2}</div></div>'
            f'<div style="display: flex; flex-direction: column; gap: 12px">{h2("Sentados à mesa")}<div style="display: flex; gap: 24px">{seated}</div>'
            f'{h2("Humor")}<div style="display: flex; gap: 28px">{moods}</div></div></div></div>')
    return page("Personagens", 1280, 760, body)


# --- Cardápio e cozinha ---------------------------------------------------------------------

def menu_board():
    foods = ""
    for k, n in NAMES.items():
        D = Defs()
        foods += (f'<div style="display: flex; flex-direction: column; align-items: center; gap: 8px; width: 176px; padding: 14px 8px; border-radius: 18px; '
                  f'background: linear-gradient(180deg, #fffdf8, #f6ead4); border: 3px solid {INK}; box-shadow: 0 4px 0 {INK}">'
                  f'{svg_el(150, 150, "0 0 48 48", D, food(D, k, 24, 26, 48))}<span style="{DISP}; font-size: 19px; font-weight: 700; color: {INK}">{n}</span></div>')
    D = Defs()
    balloons = "".join(balloon(D, k, 60 + i * 110, 110, 56, patience=p) for i, (k, p) in enumerate(zip(NAMES, [0.9, 0.7, 0.5, 0.85, 0.2, 0.6])))
    balloons_svg = svg_el(680, 130, "0 -6 680 124", D, balloons)
    D = Defs()
    badges = (cooking_badge(D, "lasanha", 50, 40, 0.3, "12:40") + cooking_badge(D, "misto", 150, 40, 0.65, "0:58")
              + cooking_badge(D, "pao", 250, 40, ready=True))
    badges_svg = svg_el(465, 126, "0 0 310 84", D, badges)
    D = Defs()
    iso = Iso(0, 0)
    kitchen = (stove(D, iso, 0, 0, "R", cooking="coxinha") + stove(D, iso, 0, 1, "R", cooking="misto")
               + counter(D, iso, 1, 0, "R", [("cafe", 12)]) + counter(D, iso, 1, 1, "R", [("coxinha", 16), ("pao", 8)]))
    kitchen_svg = svg_el(420, 270, "-110 -110 230 190", D, kitchen)
    body = (f'<div style="width: 1280px; height: 720px; box-sizing: border-box; padding: 34px 44px; background: {CREAM}; font-family: Nunito, sans-serif; display: flex; flex-direction: column; gap: 18px">'
            f'{h2("Cardápio: dá para reconhecer cada prato de longe")}'
            f'<div style="display: flex; gap: 16px; justify-content: space-between">{foods}</div>'
            f'<div style="display: flex; gap: 40px; align-items: flex-start">'
            f'<div style="display: flex; flex-direction: column; gap: 10px">{h2("O que o cliente quer")}'
            f'<span style="font-size: 15px; font-weight: 700; color: {CHOC}; max-width: 660px">Balão com o prato e a barrinha de paciência (verde → amarelo → vermelho).</span>{balloons_svg}'
            f'{h2("O que está no fogo")}<span style="font-size: 15px; font-weight: 700; color: {CHOC}">Selo com o prato, o anel de progresso e o tempo; verde quando fica pronto.</span>{badges_svg}</div>'
            f'<div style="display: flex; flex-direction: column; gap: 10px">{h2("Na cozinha")}{kitchen_svg}'
            f'<span style="font-size: 15px; font-weight: 700; color: {CHOC}; max-width: 420px">Cada fogão mostra a panela com a comida; o balcão mostra os pratos e quantos restam.</span></div></div></div>')
    return page("Cardápio e cozinha", 1280, 720, body)


SWATCHES = [
    ("Espresso", "#3a2217", "contorno e texto"), ("Chocolate", "#6b3f26", "madeira escura, nível"), ("Canela", "#a8643a", "rótulos"),
    ("Terracota", "#c6503f", "piso, detalhes"), ("Mel", "#f4c542", "ouro, XP"), ("Creme", "#fff4df", "painéis"),
    ("Vinho", "#b8263a", "cortinas, estofado"), ("Tomate", "#e2503f", "avisos, loja"), ("Menta", "#5fc3a4", "Café Grana"),
    ("Folha", "#3f9a45", "confirmar"), ("Céu", "#9fd8f3", "vidro, janelas"), ("Grama", "#79c267", "exterior"),
]


def style_board():
    sw = "".join(
        f'<div style="display: flex; flex-direction: column; gap: 4px"><div style="width: 88px; height: 60px; border-radius: 12px; background: {c}; border: 3px solid {INK}"></div>'
        f'<span style="{DISP}; font-size: 15px; font-weight: 600; color: {INK}">{n}</span><span style="font-size: 12px; font-weight: 700; color: {CANELA}">{c} · {use}</span></div>'
        for n, c, use in SWATCHES)
    grid = '<div style="display: grid; grid-template-columns: repeat(6, minmax(0, 1fr)); gap: 14px">' + sw + '</div>'
    btn = lambda text, bg, fg="#ffffff": (f'<button style="height: 52px; padding: 0 26px; border-radius: 16px; background: {bg}; border: 3px solid {INK}; '
                                          f'box-shadow: 0 4px 0 {INK}, inset 0 2px 0 rgba(255,255,255,0.5); {DISP}; font-size: 20px; font-weight: 700; color: {fg}">{text}</button>')
    buttons = ('<div style="display: flex; gap: 12px; flex-wrap: wrap">'
               + btn("Comprar", "linear-gradient(180deg, #6fcf5c, #2f8a3a)") + btn("Cancelar", "linear-gradient(180deg, #fffdf8, #f3dfb8)", INK)
               + btn("Vender", "linear-gradient(180deg, #ff7a5c, #c62f22)")
               + f'<button disabled style="display: flex; align-items: center; gap: 4px; height: 52px; padding: 0 20px 0 10px; border-radius: 16px; background: #d9ccb4; '
               f'border: 3px solid #8c7a62; {DISP}; font-size: 20px; font-weight: 700; color: #5b4a38">{icon("cadeado", 30)}Nível 5</button></div>')
    counters = (f'<div style="display: flex; gap: 12px; align-items: center">{counter_pill(coin_svg(), "12.480", "Comprar Café Ouro")}'
                f'{counter_pill(bean_svg(), "37", "Comprar Café Grana", 150)}</div><div>{level_block(12, "4.820 / 6.100 XP", 62, 320)}</div>')
    dialog = (f'<div style="width: 420px; box-sizing: border-box; padding: 20px 22px; border-radius: 22px; background: linear-gradient(180deg, #fbefd6, #f1ddb6); '
              f'border: 4px solid {INK}; box-shadow: 0 6px 0 {INK}; display: flex; flex-direction: column; gap: 14px; align-items: center">'
              f'<span style="{DISP}; font-size: 24px; font-weight: 700; color: {INK}">Expandir a cafeteria?</span>'
              f'<span style="font-size: 16px; font-weight: 700; color: {CHOC}; text-align: center">Aumentar para 10×8 por 150 de Café Ouro?</span>'
              f'<div style="display: flex; gap: 12px">{btn("Cancelar", "linear-gradient(180deg, #fffdf8, #f3dfb8)", INK).replace("border: 3px solid", "outline: 4px solid #f4c542; border: 3px solid")}'
              f'{btn("Expandir", "linear-gradient(180deg, #6fcf5c, #2f8a3a)")}</div>'
              f'<span style="font-size: 12px; font-weight: 700; color: {CANELA}">O botão seguro já vem selecionado (moldura mel).</span></div>')
    D = Defs()
    fb = (mood_face(D, 26, 34, "feliz", 18) + mood_face(D, 72, 34, "esperando", 18) + mood_face(D, 118, 34, "bravo", 18)
          + balloon(D, "pao", 190, 66, 42, 0.6) + cooking_badge(D, "misto", 262, 30, 0.6, "0:58"))
    fb += (f'<text x="330" y="44" font-family="Fredoka, Nunito, sans-serif" font-weight="700" font-size="28" fill="none" stroke="{INK}" stroke-width="6" stroke-linejoin="round">+18</text>'
           f'<text x="330" y="44" font-family="Fredoka, Nunito, sans-serif" font-weight="700" font-size="28" fill="#ffd23f">+18</text>'
           f'<text x="394" y="44" font-family="Fredoka, Nunito, sans-serif" font-weight="700" font-size="22" fill="none" stroke="{INK}" stroke-width="5" stroke-linejoin="round">+8 XP</text>'
           f'<text x="394" y="44" font-family="Fredoka, Nunito, sans-serif" font-weight="700" font-size="22" fill="#9fd8f3">+8 XP</text>')
    feedback = svg_el(480, 80, "0 0 480 80", D, fb)
    principles = "".join(
        f'<div style="display: flex; gap: 10px; align-items: flex-start"><span style="flex-shrink: 0; width: 30px; height: 30px; border-radius: 15px; background: {MEL}; '
        f'border: 2.5px solid {INK}; {DISP}; font-size: 16px; font-weight: 700; color: {INK}; display: flex; align-items: center; justify-content: center">{i}</span>'
        f'<span style="font-size: 15px; font-weight: 700; color: {INK}"><b style="{DISP}; font-weight: 600; font-size: 17px">{t}</b><br>{d}</span></div>'
        for i, (t, d) in enumerate([
            ("Objetos de verdade", "Mesa tem tampo, toalha e pé; cadeira tem pernas, assento e encosto; fogão tem bocas, botões e forno."),
            ("Luz de cima à esquerda", "Topo claro, lado esquerdo médio, lado direito escuro; brilho nas quinas e sombra no chão."),
            ("Comida que se reconhece", "Cada prato com cor, forma e textura próprias, sempre no prato, grande no balão."),
            ("Gente simpática", "Cabeça grande, olhos com brilho, cabelo com volume e reflexo, roupa com gola e dobras."),
            ("Cheia e viva", "Movimento, vapor, números subindo, a rua lá fora. Nada acontece em silêncio."),
        ], 1))

    def card(title, inner, w=None):
        ws = f"width: {w}px; " if w else "flex-grow: 1; "
        return (f'<div style="{ws}box-sizing: border-box; padding: 18px 20px; border-radius: 20px; background: {LEITE}; border: 3px solid {INK}; '
                f'display: flex; flex-direction: column; gap: 12px"><h2 style="margin: 0; {DISP}; font-size: 22px; font-weight: 700; color: {INK}">{title}</h2>{inner}</div>')
    type_block = (f'<span style="{DISP}; font-size: 46px; font-weight: 700; color: {INK}; line-height: 1">Café da Esquina</span>'
                  f'<span style="font-size: 14px; font-weight: 700; color: {CANELA}">Fredoka 600–700 · títulos, números e botões</span>'
                  f'<span style="font-size: 18px; font-weight: 700; color: {INK}">O cliente chegou, sentou e está de olho no pão de queijo. Leve ao balcão antes que a paciência acabe!</span>'
                  f'<span style="font-size: 14px; font-weight: 700; color: {CANELA}">Nunito 700–800 · textos e dicas</span>')
    body = (f'<div style="width: 1280px; height: 1200px; box-sizing: border-box; padding: 36px 40px; background: {CREAM}; font-family: Nunito, sans-serif; display: flex; flex-direction: column; gap: 18px">'
            f'<div style="display: flex; align-items: baseline; gap: 16px"><h1 style="margin: 0; {DISP}; font-size: 40px; font-weight: 700; color: {INK}">Esquina Nostálgica</h1>'
            f'<span style="font-size: 17px; font-weight: 700; color: {CANELA}">guia de estilo do Café Manie · versão 2</span></div>'
            f'{card("Cores", grid)}'
            f'<div style="display: flex; gap: 18px">{card("Tipografia", type_block, 600)}{card("Princípios", principles)}</div>'
            f'<div style="display: flex; gap: 18px">{card("Botões e contadores", buttons + counters, 600)}{card("Janelas e retorno", dialog + feedback)}</div></div>')
    return page("Guia de estilo", 1280, 1200, body)


def write(name, text):
    with open(os.path.join(ROOT, name), "w") as fh:
        fh.write(text)


if __name__ == "__main__":
    write("Main.dc.html", main_board())
    write("Cena.dc.html", scene_board())
    write("Loja.dc.html", shop_board())
    write("Personagens.dc.html", characters_board())
    write("Cardapio.dc.html", menu_board())
    write("GuiaDeEstilo.dc.html", style_board())
    print("ok")
