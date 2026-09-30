"""Gera as pranchas (.dc.html) e o índice do canvas de direção visual."""
import json, os, datetime
from svgkit import *
from scene import scene_svg, float_text
from ui import icon, item_preview, head, svg

ROOT = os.path.join(os.path.dirname(__file__), "..", "project")
FONTS = '<link href="https://fonts.googleapis.com/css2?family=Fredoka:wght@500;600;700&amp;family=Nunito:wght@600;700;800&amp;display=swap" rel="stylesheet">'
DISPLAY = "font-family: Fredoka, Nunito, sans-serif"
C = PALETTE


def page(title, w, h, body, lang="pt-BR"):
    return f'''<!doctype html>
<html lang="{lang}">
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
body{{margin:0;background:#3b2316}}
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


# --- Peças da interface -----------------------------------------------------------

PANEL = f"background: {C['creme']}; border: 3px solid {INK}; box-shadow: 0 4px 0 {INK}"


def plus_button(label):
    return (f'<button aria-label="{label}" style="width: 30px; height: 30px; border-radius: 15px; background: {C["folha"]}; border: 2.5px solid {INK}; '
            f'display: flex; align-items: center; justify-content: center; padding: 0; box-shadow: 0 2px 0 {INK}">{icon("mais", 22)}</button>')


def counter_pill(icon_svg, value, plus_label=None, width=196):
    return (f'<div style="display: flex; align-items: center; gap: 8px; width: {width}px; height: 44px; box-sizing: border-box; padding: 0 6px 0 4px; {PANEL}; border-radius: 24px">'
            f'{icon_svg}<span style="{DISPLAY}; font-weight: 600; font-size: 23px; color: {INK}; flex-grow: 1">{value}</span>'
            + (plus_button(plus_label) if plus_label else "") + '</div>')


def level_block(level=12, xp="4.820 / 6.100 XP", pct=62, bar_w=300):
    return (f'<div style="display: flex; align-items: center">'
            f'<div style="position: relative; z-index: 1; width: 66px; height: 66px; border-radius: 33px; background: {C["chocolate"]}; border: 3px solid {INK}; box-shadow: 0 4px 0 {INK}; display: flex; flex-direction: column; align-items: center; justify-content: center">'
            f'<span style="{DISPLAY}; font-size: 11px; font-weight: 600; color: {C["mel"]}; letter-spacing: 1px">NÍVEL</span>'
            f'<span style="{DISPLAY}; font-size: 30px; font-weight: 700; color: #ffffff; line-height: 28px">{level}</span></div>'
            f'<div style="position: relative; margin-left: -12px; width: {bar_w}px; height: 30px; box-sizing: border-box; background: #efe0c2; border: 3px solid {INK}; border-radius: 0 16px 16px 0; overflow: hidden">'
            f'<div style="width: {pct}%; height: 100%; background: {C["mel"]}; border-radius: 0 12px 12px 0"></div>'
            f'<div style="position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; {DISPLAY}; font-size: 15px; font-weight: 600; color: {INK}">{xp}</div></div></div>')


def round_button(name, label, size=46):
    return (f'<button aria-label="{label}" style="width: {size}px; height: {size}px; border-radius: 14px; {PANEL}; box-shadow: 0 3px 0 {INK}; '
            f'display: flex; align-items: center; justify-content: center; padding: 0">{icon(name, size - 14)}</button>')


def toolbar_button(name, label, badge=None):
    b = (f'<span style="position: absolute; top: -8px; right: -6px; min-width: 22px; height: 22px; border-radius: 11px; background: {C["tomate"]}; border: 2px solid {INK}; '
         f'{DISPLAY}; font-size: 13px; font-weight: 700; color: #ffffff; display: flex; align-items: center; justify-content: center">{badge}</span>') if badge else ""
    return (f'<button style="position: relative; width: 90px; height: 86px; border-radius: 16px; background: {C["leite"]}; border: 3px solid {INK}; box-shadow: 0 4px 0 {INK}; '
            f'display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 2px; padding: 0">{icon(name, 46)}'
            f'<span style="{DISPLAY}; font-size: 14px; font-weight: 600; color: {INK}">{label}</span>{b}</button>')


def neighbor_card(name, level, skin, hair, style, bg):
    return (f'<div style="width: 72px; display: flex; flex-direction: column; align-items: center; gap: 3px">'
            f'<div style="position: relative; width: 62px; height: 62px; border-radius: 12px; background: {bg}; border: 3px solid {INK}; display: flex; align-items: flex-end; justify-content: center; overflow: hidden">{head(skin, hair, style, 58)}'
            f'<span style="position: absolute; left: -3px; bottom: -3px; width: 26px; height: 26px; border-radius: 13px; background: {C["mel"]}; border: 2.5px solid {INK}; {DISPLAY}; font-size: 13px; font-weight: 700; color: {INK}; display: flex; align-items: center; justify-content: center">{level}</span></div>'
            f'<span style="{DISPLAY}; font-size: 13px; font-weight: 600; color: {INK}">{name}</span></div>')


def invite_card():
    return (f'<div style="width: 72px; display: flex; flex-direction: column; align-items: center; gap: 3px">'
            f'<button aria-label="Convidar vizinho" style="width: 62px; height: 62px; border-radius: 12px; background: {C["folha"]}; border: 3px solid {INK}; display: flex; align-items: center; justify-content: center; padding: 0">{icon("mais", 36)}</button>'
            f'<span style="{DISPLAY}; font-size: 13px; font-weight: 600; color: {INK}">Convidar</span></div>')


def mission_card():
    return (f'<div style="width: 232px; box-sizing: border-box; padding: 10px 12px; {PANEL}; border-radius: 16px; display: flex; gap: 10px; align-items: center">'
            f'{icon("missoes", 40)}<div style="display: flex; flex-direction: column; gap: 4px; flex-grow: 1">'
            f'<span style="{DISPLAY}; font-size: 12px; font-weight: 600; color: {C["canela"]}; letter-spacing: 0.5px">MISSÃO 4 DE 6</span>'
            f'<span style="font-family: Nunito, sans-serif; font-size: 15px; font-weight: 800; color: {INK}">Compre uma mesa</span>'
            f'<div style="height: 10px; border-radius: 5px; background: #e6d6b8; border: 2px solid {INK}; overflow: hidden"><div style="width: 0%; height: 100%; background: {C["folha"]}"></div></div></div></div>')


def gift_bubble():
    return (f'<button aria-label="Recompensa diária" style="position: relative; width: 60px; height: 60px; border-radius: 30px; {PANEL}; display: flex; align-items: center; justify-content: center; padding: 0">{icon("presentes", 40)}'
            f'<span style="position: absolute; top: -6px; right: -6px; width: 22px; height: 22px; border-radius: 11px; background: {C["tomate"]}; border: 2px solid {INK}; {DISPLAY}; font-size: 13px; font-weight: 700; color: #ffffff; display: flex; align-items: center; justify-content: center">1</span></button>')


def toast(text):
    return (f'<div style="padding: 10px 22px; border-radius: 22px; background: {INK}; border: 3px solid {C["mel"]}; {DISPLAY}; font-size: 19px; font-weight: 600; color: {C["creme"]}">{text}</div>')


def hud_top():
    return (f'<div style="position: absolute; left: 14px; top: 12px; right: 14px; display: flex; align-items: flex-start; justify-content: space-between">'
            f'<div style="display: flex; flex-direction: column; gap: 8px">'
            f'{counter_pill(svg(34, 34, coin(17, 17, 14)), "12.480", "Comprar Café Ouro")}'
            f'{counter_pill(svg(34, 34, bean(17, 17, 13)), "37", "Comprar Café Grana")}</div>'
            f'<div style="display: flex; flex-direction: column; align-items: center; gap: 10px; padding-left: 40px">{level_block()}{toast("Conquista: Anfitrião!  +50 ouro")}</div>'
            f'<div style="display: flex; flex-direction: column; gap: 8px; align-items: flex-end">'
            f'{counter_pill(svg(34, 34, mood(17, 17, "feliz", 14)), "86%", None, 150)}'
            f'{counter_pill(icon("flor", 34), "148", None, 150)}</div></div>')


def hud_side():
    return (f'<div style="position: absolute; right: 14px; top: 132px; display: flex; flex-direction: column; gap: 8px">'
            f'{round_button("zoom_in", "Aproximar")}{round_button("zoom_out", "Afastar")}{round_button("tela", "Tela cheia")}{round_button("musica", "Música")}{round_button("som", "Sons")}</div>'
            f'<div style="position: absolute; left: 14px; top: 124px; display: flex; flex-direction: column; gap: 12px; align-items: flex-start">{mission_card()}{gift_bubble()}</div>')


def hud_bottom():
    tools = "".join(toolbar_button(n, l, b) for n, l, b in [
        ("loja", "Loja", None), ("decorar", "Decorar", None), ("cardapio", "Cardápio", None),
        ("missoes", "Missões", "1"), ("conquistas", "Conquistas", None), ("presentes", "Presentes", "2")])
    neighbors = "".join([
        neighbor_card("Ana", 21, SKINS[0], "#6b3f26", "coque", "#8fd0f0"),
        neighbor_card("Beto", 18, SKINS[3], "#1f1a17", "curto", "#f4c542"),
        neighbor_card("Duda", 25, SKINS[1], "#e8813a", "longo", "#f08aa6"),
        neighbor_card("Caio", 12, SKINS[2], "#1f1a17", "espetado", "#5fc3a4"),
        invite_card()])
    return (f'<div style="position: absolute; left: 14px; bottom: 14px; display: flex; gap: 10px; padding: 12px; {PANEL}; border-radius: 22px">{tools}</div>'
            f'<div style="position: absolute; right: 14px; bottom: 14px; display: flex; flex-direction: column; gap: 6px; padding: 8px 12px 12px; {PANEL}; border-radius: 22px">'
            f'<span style="{DISPLAY}; font-size: 14px; font-weight: 600; color: {C["canela"]}; letter-spacing: 1px">VIZINHOS</span>'
            f'<div style="display: flex; gap: 8px">{neighbors}</div></div>')


def main_board():
    body = (f'<div style="position: relative; width: 1280px; height: 720px; overflow: hidden; font-family: Nunito, sans-serif; background: {C["grama"]}">'
            f'<div style="position: absolute; left: 0; top: 0; width: 1280px; height: 720px"><dc-import name="Cena" hint-size="1280px,720px"></dc-import></div>'
            f'{hud_top()}{hud_side()}{hud_bottom()}</div>')
    return page("Café Manie — tela do jogo", 1280, 720, body)


def scene_board():
    body = f'<div style="width: 1280px; height: 720px; overflow: hidden; background: {C["grama"]}">{scene_svg()}</div>'
    return page("Cenário da cafeteria", 1280, 720, body)


# --- Loja --------------------------------------------------------------------------

SHOP_ITEMS = [
    ("mesa", "Mesa redonda", 60, None, None),
    ("mesa_menta", "Mesa menta", 60, None, "Novo!"),
    ("cadeira", "Cadeira", 30, None, None),
    ("balcao", "Balcão", 120, None, None),
    ("fogao", "Fogão", 150, None, None),
    ("vitrine", "Vitrine de doces", 180, 2, "Novo!"),
    ("jukebox", "Vitrola", 250, 4, None),
    ("estante", "Estante", 150, 3, None),
]


def shop_card(kind, name, price, level, ribbon, selected=False):
    border = f"4px solid {C['mel']}" if selected else f"3px solid {INK}"
    locked = level is not None and level > 3
    preview_style = "filter: grayscale(1); opacity: 0.55" if locked else ""
    rib = (f'<span style="position: absolute; top: 8px; left: -4px; padding: 2px 10px; background: {C["tomate"]}; border: 2px solid {INK}; border-radius: 0 8px 8px 0; '
           f'{DISPLAY}; font-size: 12px; font-weight: 700; color: #ffffff">{ribbon}</span>') if ribbon else ""
    lock = (f'<span style="position: absolute; top: 44px; left: 50%; transform: translateX(-50%); display: flex; align-items: center; gap: 4px; padding: 3px 10px 3px 4px; background: {INK}; border-radius: 14px; '
            f'{DISPLAY}; font-size: 14px; font-weight: 600; color: {C["mel"]}">{icon("cadeado", 22)}Nível {level}</span>') if locked else ""
    price_row = (f'<div style="display: flex; align-items: center; gap: 4px; {DISPLAY}; font-size: 17px; font-weight: 700; color: {INK}">'
                 f'{svg(20, 20, coin(10, 10, 8.5))}{price}</div>')
    return (f'<button style="position: relative; width: 150px; height: 184px; box-sizing: border-box; border-radius: 16px; background: {C["leite"]}; border: {border}; box-shadow: 0 4px 0 {INK}; '
            f'display: flex; flex-direction: column; align-items: center; justify-content: flex-end; gap: 4px; padding: 0 6px 12px">'
            f'<div style="{preview_style}">{item_preview(kind, 104)}</div>'
            f'<span style="{DISPLAY}; font-size: 15px; font-weight: 600; color: {INK}">{name}</span>{price_row}{rib}{lock}</button>')


def shop_board():
    tabs = ""
    for i, (ic, label) in enumerate([("loja", "Móveis"), ("flor", "Decoração"), ("piso", "Piso"), ("parede", "Parede"), ("estrela", "Especiais")]):
        active = i == 0
        bg = C["leite"] if active else "#e6cfa6"
        tabs += (f'<button style="display: flex; align-items: center; gap: 6px; height: 48px; padding: 0 14px 0 8px; border-radius: 14px 14px 0 0; background: {bg}; border: 3px solid {INK}; border-bottom: {"none" if active else f"3px solid {INK}"}; '
                 f'{DISPLAY}; font-size: 16px; font-weight: 600; color: {INK}; margin-bottom: {"-3px" if active else "0"}">{icon(ic, 30)}{label}</button>')
    cards = "".join(shop_card(k, n, p, l, r, selected=(k == "mesa_menta")) for k, n, p, l, r in SHOP_ITEMS)
    detail = (f'<div style="width: 262px; box-sizing: border-box; padding: 16px; border-radius: 16px; background: {C["leite"]}; border: 3px solid {INK}; display: flex; flex-direction: column; align-items: center; gap: 10px">'
              f'<div style="width: 180px; height: 150px; border-radius: 14px; background: #f3e3c3; border: 2px solid #d9c29a; display: flex; align-items: center; justify-content: center">{item_preview("mesa_menta", 150)}</div>'
              f'<span style="{DISPLAY}; font-size: 24px; font-weight: 700; color: {INK}">Mesa menta</span>'
              f'<span style="font-size: 15px; font-weight: 700; color: {C["chocolate"]}; text-align: center">Toalha verde e lugar para duas cadeiras.</span>'
              f'<div style="display: flex; gap: 6px">'
              f'<span style="display: flex; align-items: center; gap: 4px; padding: 4px 10px 4px 4px; border-radius: 14px; background: #fde6ee; border: 2px solid {INK}; font-size: 14px; font-weight: 800; color: {INK}">{icon("flor", 22)}Beleza +5</span>'
              f'<span style="display: flex; align-items: center; gap: 4px; padding: 4px 10px 4px 4px; border-radius: 14px; background: #e3f6ee; border: 2px solid {INK}; font-size: 14px; font-weight: 800; color: {INK}">{icon("amigos", 22)}2 lugares</span></div>'
              f'<div style="display: flex; align-items: center; gap: 6px; {DISPLAY}; font-size: 30px; font-weight: 700; color: {INK}">{svg(32, 32, coin(16, 16, 13))}60</div>'
              f'<button style="width: 100%; height: 54px; border-radius: 16px; background: #2f7a3a; border: 3px solid {INK}; box-shadow: 0 4px 0 {INK}; {DISPLAY}; font-size: 22px; font-weight: 700; color: #ffffff">Comprar</button>'
              f'<span style="font-size: 13px; font-weight: 700; color: {C["canela"]}">Você tem 12.480 de Café Ouro</span></div>')
    modal = (f'<div style="position: absolute; left: 110px; top: 70px; width: 1060px; height: 580px; box-sizing: border-box; padding: 34px 26px 22px; border-radius: 26px; background: #f7e7c7; border: 4px solid {INK}; box-shadow: 0 8px 0 {INK}; display: flex; flex-direction: column">'
             f'<div style="position: absolute; top: -26px; left: 50%; transform: translateX(-50%); padding: 6px 48px; background: {C["tomate"]}; border: 4px solid {INK}; border-radius: 14px; box-shadow: 0 4px 0 {INK}; {DISPLAY}; font-size: 30px; font-weight: 700; color: #ffffff">Loja</div>'
             f'<button aria-label="Fechar loja" style="position: absolute; top: -18px; right: -18px; width: 50px; height: 50px; border-radius: 25px; background: {C["tomate"]}; border: 4px solid {INK}; box-shadow: 0 4px 0 {INK}; display: flex; align-items: center; justify-content: center; padding: 0">{icon("fechar", 34)}</button>'
             f'<div style="display: flex; gap: 6px; padding-left: 8px">{tabs}</div>'
             f'<div style="display: flex; gap: 18px; padding: 18px; border-radius: 0 16px 16px 16px; background: {C["leite"]}; border: 3px solid {INK}; flex-grow: 1">'
             f'<div style="display: flex; flex-direction: column; gap: 12px; flex-grow: 1">'
             f'<div style="display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 14px; justify-items: center">{cards}</div>'
             f'<div style="display: flex; align-items: center; justify-content: center; gap: 14px">'
             f'<button aria-label="Página anterior" style="width: 40px; height: 40px; border-radius: 20px; background: {C["canela"]}; border: 3px solid {INK}; display: flex; align-items: center; justify-content: center; padding: 0">{icon("seta_esq", 30)}</button>'
             f'<span style="{DISPLAY}; font-size: 17px; font-weight: 600; color: {INK}">1 / 3</span>'
             f'<button aria-label="Próxima página" style="width: 40px; height: 40px; border-radius: 20px; background: {C["canela"]}; border: 3px solid {INK}; display: flex; align-items: center; justify-content: center; padding: 0">{icon("seta_dir", 30)}</button></div></div>'
             f'{detail}</div></div>')
    body = (f'<div style="position: relative; width: 1280px; height: 720px; overflow: hidden; font-family: Nunito, sans-serif; background: {C["grama"]}">'
            f'<div style="position: absolute; left: 0; top: 0; width: 1280px; height: 720px"><dc-import name="Cena" hint-size="1280px,720px"></dc-import></div>'
            f'<div style="position: absolute; inset: 0; background: rgba(59, 35, 22, 0.55)"></div>{modal}</div>')
    return page("Café Manie — loja", 1280, 720, body)


# --- Personagens -------------------------------------------------------------------

def label(text, sub=None):
    s = f'<span style="{DISPLAY}; font-size: 17px; font-weight: 600; color: {INK}">{text}</span>'
    if sub:
        s += f'<span style="font-size: 13px; font-weight: 700; color: {C["canela"]}">{sub}</span>'
    return f'<div style="display: flex; flex-direction: column; align-items: center; gap: 1px">{s}</div>'


def figure(person_svg, w=120, h=180, vb="-26 -76 52 80"):
    return svg(w, h, person_svg, vb)


def section_title(text):
    return f'<h2 style="margin: 0; {DISPLAY}; font-size: 26px; font-weight: 700; color: {INK}">{text}</h2>'


def characters_board():
    customers = [
        ("Clara", "cliente comum", person(0, 0, SKINS[0], "#6b3f26", "coque", C["menta"], "#3d5a80")),
        ("Tomás", "apressado", person(0, 0, SKINS[3], "#1f1a17", "bone", C["tomate"], "#3d5a80")),
        ("Dona Lu", "cliente fiel", person(0, 0, SKINS[4], "#d9d4cc", "coque", C["framboesa"], "#6b3f26")),
        ("Rafa", "estudante", person(0, 0, SKINS[1], "#f4c542", "espetado", C["ceu"], "#3b4a55")),
        ("Nina", "turista", person(0, 0, SKINS[2], "#1f1a17", "cacheado", C["mel"], "#5da84e")),
        ("Jorge", "cliente comum", person(0, 0, SKINS[0], "#a8643a", "curto", "#8a5534", "#2b2b33")),
    ]
    row1 = "".join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px">{figure(p)}{label(n, s)}</div>' for n, s, p in customers)
    staff = [
        ("Chef Bia", "mascote e cozinheira", person(0, 0, SKINS[3], "#1f1a17", "cacheado", "#fffaf0", "#3b4a55", apron=C["menta"], chef_hat=True), "-30 -98 60 102"),
        ("Léo", "garçom", person(0, 0, SKINS[1], "#1f1a17", "curto", "#fffaf0", "#2b2b33", bowtie=True, tray="cafe"), "-28 -78 62 82"),
    ]
    row2 = "".join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px">{figure(p, 140, 220, vb)}{label(n, s)}</div>' for n, s, p, vb in staff)
    moods = "".join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 6px">{svg(72, 72, mood(36, 36, st, 30))}{label(t)}</div>'
                    for st, t in [("feliz", "Feliz"), ("esperando", "Esperando"), ("bravo", "Bravo")])
    foods = "".join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px">{svg(96, 88, thought(40, 22, k), "18 4 46 42")}{label(t)}</div>'
                    for k, t in [("cafe", "Café"), ("pao", "Pão de queijo"), ("misto", "Misto-quente"), ("bolo", "Bolo"), ("coxinha", "Coxinha"), ("lasanha", "Lasanha")])
    body = (f'<div style="width: 1280px; height: 720px; box-sizing: border-box; padding: 36px 48px; background: {C["creme"]}; font-family: Nunito, sans-serif; display: flex; flex-direction: column; gap: 22px">'
            f'{section_title("Clientes")}<div style="display: flex; justify-content: space-between">{row1}</div>'
            f'<div style="display: flex; gap: 48px; align-items: flex-start">'
            f'<div style="display: flex; flex-direction: column; gap: 10px">{section_title("Equipe")}<div style="display: flex; gap: 24px">{row2}</div></div>'
            f'<div style="display: flex; flex-direction: column; gap: 14px; flex-grow: 1">{section_title("Humor")}<div style="display: flex; gap: 28px">{moods}</div>'
            f'{section_title("Pedidos")}<div style="display: flex; gap: 18px">{foods}</div></div></div></div>')
    return page("Personagens", 1280, 720, body)


# --- Guia de estilo --------------------------------------------------------------------

SWATCHES = [
    ("Espresso", "espresso", "contorno e texto"), ("Chocolate", "chocolate", "madeira, selo de nível"),
    ("Canela", "canela", "rótulos"), ("Caramelo", "caramelo", "detalhes quentes"),
    ("Mel", "mel", "ouro, XP, destaque"), ("Creme", "creme", "painéis"), ("Leite", "leite", "cartões"),
    ("Tomate", "tomate", "avisos, loja"), ("Framboesa", "framboesa", "cortinas"),
    ("Menta", "menta", "Café Grana, equipe"), ("Folha", "folha", "confirmar, +"), ("Céu", "ceu", "vidro, XP"),
]


def style_board():
    sw = "".join(
        f'<div style="display: flex; flex-direction: column; gap: 4px"><div style="width: 88px; height: 64px; border-radius: 12px; background: {C[k]}; border: 3px solid {INK}"></div>'
        f'<span style="{DISPLAY}; font-size: 15px; font-weight: 600; color: {INK}">{n}</span><span style="font-size: 12px; font-weight: 700; color: {C["canela"]}">{C[k]} · {use}</span></div>'
        for n, k, use in SWATCHES)
    type_block = (f'<div style="display: flex; flex-direction: column; gap: 8px">'
                  f'<span style="{DISPLAY}; font-size: 46px; font-weight: 700; color: {INK}; line-height: 1">Café da Esquina</span>'
                  f'<span style="font-size: 14px; font-weight: 700; color: {C["canela"]}">Fredoka 600–700 · títulos, números e botões (arredondada, amigável, lembra os jogos sociais de 2010)</span>'
                  f'<span style="font-size: 18px; font-weight: 700; color: {INK}; max-width: 520px">O cliente chegou, sentou e está de olho no pão de queijo. Leve ao balcão antes que a paciência acabe!</span>'
                  f'<span style="font-size: 14px; font-weight: 700; color: {C["canela"]}">Nunito 700–800 · textos e dicas (letra cheia, fácil de ler no celular)</span></div>')
    buttons = (f'<div style="display: flex; gap: 12px; flex-wrap: wrap">'
               f'<button style="height: 50px; padding: 0 26px; border-radius: 16px; background: #2f7a3a; border: 3px solid {INK}; box-shadow: 0 4px 0 {INK}; {DISPLAY}; font-size: 20px; font-weight: 700; color: #ffffff">Comprar</button>'
               f'<button style="height: 50px; padding: 0 26px; border-radius: 16px; background: {C["leite"]}; border: 3px solid {INK}; box-shadow: 0 4px 0 {INK}; {DISPLAY}; font-size: 20px; font-weight: 700; color: {INK}">Cancelar</button>'
               f'<button style="height: 50px; padding: 0 26px; border-radius: 16px; background: #b8382a; border: 3px solid {INK}; box-shadow: 0 4px 0 {INK}; {DISPLAY}; font-size: 20px; font-weight: 700; color: #ffffff">Vender</button>'
               f'<button disabled style="display: flex; align-items: center; gap: 4px; height: 50px; padding: 0 20px 0 10px; border-radius: 16px; background: #d9ccb4; border: 3px solid #8c7a62; {DISPLAY}; font-size: 20px; font-weight: 700; color: #5b4a38">{icon("cadeado", 30)}Nível 5</button></div>')
    counters = (f'<div style="display: flex; gap: 12px; align-items: center; flex-wrap: wrap">{counter_pill(svg(34, 34, coin(17, 17, 14)), "12.480", "Comprar Café Ouro")}'
                f'{counter_pill(svg(34, 34, bean(17, 17, 13)), "37", "Comprar Café Grana", 150)}</div>'
                f'<div style="margin-top: 12px">{level_block(12, "4.820 / 6.100 XP", 62, 320)}</div>')
    dialog = (f'<div style="width: 420px; box-sizing: border-box; padding: 20px 22px; border-radius: 22px; background: #f7e7c7; border: 4px solid {INK}; box-shadow: 0 6px 0 {INK}; display: flex; flex-direction: column; gap: 14px; align-items: center">'
              f'<span style="{DISPLAY}; font-size: 24px; font-weight: 700; color: {INK}">Expandir a cafeteria?</span>'
              f'<span style="font-size: 16px; font-weight: 700; color: {C["chocolate"]}; text-align: center">Aumentar para 10×8 por 150 de Café Ouro?</span>'
              f'<div style="display: flex; gap: 12px">'
              f'<button style="height: 48px; padding: 0 22px; border-radius: 16px; background: {C["leite"]}; border: 4px solid {C["mel"]}; box-shadow: 0 4px 0 {INK}; outline: 3px solid {INK}; {DISPLAY}; font-size: 19px; font-weight: 700; color: {INK}">Cancelar</button>'
              f'<button style="height: 48px; padding: 0 22px; border-radius: 16px; background: #2f7a3a; border: 3px solid {INK}; box-shadow: 0 4px 0 {INK}; {DISPLAY}; font-size: 19px; font-weight: 700; color: #ffffff">Expandir</button></div>'
              f'<span style="font-size: 12px; font-weight: 700; color: {C["canela"]}">O botão seguro já vem selecionado (moldura mel).</span></div>')
    feedback = (f'<div style="display: flex; gap: 22px; align-items: center">'
                f'{svg(44, 44, mood(22, 22, "feliz", 18))}{svg(44, 44, mood(22, 22, "esperando", 18))}{svg(44, 44, mood(22, 22, "bravo", 18))}'
                f'{svg(70, 64, thought(34, 24, "pao"), "0 0 68 58")}'
                f'{svg(150, 40, float_text(38, 30, "+18", "#f4c542", 30) + float_text(108, 30, "+8 XP", "#8fd0f0", 24))}</div>'
                f'<div style="margin-top: 12px; display: flex">{toast("Missão concluída: Sirva 3 clientes  +30 ouro")}</div>')
    principles = "".join(
        f'<div style="display: flex; gap: 10px; align-items: flex-start"><span style="flex-shrink: 0; width: 30px; height: 30px; border-radius: 15px; background: {C["mel"]}; border: 2.5px solid {INK}; {DISPLAY}; font-size: 16px; font-weight: 700; color: {INK}; display: flex; align-items: center; justify-content: center">{i}</span>'
        f'<span style="font-size: 15px; font-weight: 700; color: {INK}"><b style="{DISPLAY}; font-weight: 600; font-size: 17px">{t}</b><br>{d}</span></div>'
        for i, (t, d) in enumerate([
            ("Cheia e viva", "Muita gente, muita comida, muito movimento. A cafeteria vazia é a exceção."),
            ("Quente e contornada", "Cores quentes e saturadas; todo objeto com contorno café de 1,5 a 3 px."),
            ("Cabeçudos simpáticos", "Cabeça grande, olhos de ponto, bochecha rosada; silhueta reconhecível no dedo."),
            ("Toda ação dá retorno", "Número subindo, som, balão, brilho. Nada acontece em silêncio."),
            ("A esquina é o palco", "A cafeteria mora num quarteirão: rua, calçada, grama e poste."),
        ], 1))

    swatch_grid = '<div style="display: grid; grid-template-columns: repeat(6, minmax(0, 1fr)); gap: 14px">' + sw + '</div>'

    def card(title, inner, w=None):
        ws = f"width: {w}px; " if w else "flex-grow: 1; "
        return (f'<div style="{ws}box-sizing: border-box; padding: 18px 20px; border-radius: 20px; background: {C["leite"]}; border: 3px solid {INK}; display: flex; flex-direction: column; gap: 12px">'
                f'<h2 style="margin: 0; {DISPLAY}; font-size: 22px; font-weight: 700; color: {INK}">{title}</h2>{inner}</div>')
    body = (f'<div style="width: 1280px; height: 1240px; box-sizing: border-box; padding: 36px 40px; background: {C["creme"]}; font-family: Nunito, sans-serif; display: flex; flex-direction: column; gap: 18px">'
            f'<div style="display: flex; align-items: baseline; gap: 16px"><h1 style="margin: 0; {DISPLAY}; font-size: 40px; font-weight: 700; color: {INK}">Esquina Nostálgica</h1>'
            f'<span style="font-size: 17px; font-weight: 700; color: {C["canela"]}">guia de estilo do Café Manie</span></div>'
            f'{card("Cores", swatch_grid)}'
            f'<div style="display: flex; gap: 18px">{card("Tipografia", type_block, 600)}{card("Princípios", principles)}</div>'
            f'<div style="display: flex; gap: 18px">{card("Botões e contadores", buttons + counters, 600)}{card("Janelas e retorno", dialog + feedback)}</div></div>')
    return page("Guia de estilo", 1280, 1240, body)


def write(name, text):
    with open(os.path.join(ROOT, name), "w") as fh:
        fh.write(text)


if __name__ == "__main__":
    os.makedirs(ROOT, exist_ok=True)
    now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    boards = {
        "Main.dc.html": {"x": 0, "y": 0, "w": 1280, "h": 720, "title": "Tela do jogo"},
        "Loja.dc.html": {"x": 1360, "y": 0, "w": 1280, "h": 720, "title": "Loja"},
        "Personagens.dc.html": {"x": 0, "y": 840, "w": 1280, "h": 720, "title": "Personagens"},
        "GuiaDeEstilo.dc.html": {"x": 1360, "y": 840, "w": 1280, "h": 1240, "title": "Guia de estilo"},
        "Cena.dc.html": {"x": 0, "y": 1680, "w": 1280, "h": 720, "title": "Cenário (sem interface)"},
    }
    index = {
        "v": 3, "createdOnFiles": {"v": 1, "at": now}, "title": "Café Manie — Direção Visual",
        "launch": {"view": "canvas"}, "pages": [], "boards": boards,
        "order": list(boards.keys()),
        "notes": {"titulo": {"x": 0, "y": -300, "text": "Esquina Nostálgica — direção visual do Café Manie", "kind": "title1", "maxW": 2640}},
        "designSystems": [],
    }
    write("canvas.json", json.dumps(index, ensure_ascii=False, indent=1))
    write("Main.dc.html", main_board())
    write("Cena.dc.html", scene_board())
    write("Loja.dc.html", shop_board())
    write("Personagens.dc.html", characters_board())
    write("GuiaDeEstilo.dc.html", style_board())
    print("ok")
