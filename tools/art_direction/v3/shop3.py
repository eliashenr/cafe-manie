"""Loja v3: abas grandes, fileira de categorias, quadradinhos brancos com o móvel e a etiqueta de preço,
setas azuis, prévia do item e botão verde de comprar. Por trás, o móvel sendo posicionado no salão."""
from hud3 import *
from furniture3 import *

ISO_ITEM = Iso(0, 0, 84, 42)


def _item(D, kind):
    """Desenho do móvel na origem (célula 0,0) e a escala/deslocamento para caber num quadrado."""
    iso = ISO_ITEM
    if kind == "cadeira_vermelha":
        return chair(D, iso, 0, 0, "+y", "#ff4d5e"), 1.35, 10
    if kind == "cadeira_turquesa":
        return chair(D, iso, 0, 0, "+x", "#2ec4b6"), 1.35, 10
    if kind == "cadeira_amarela":
        return chair(D, iso, 0, 0, "+y", "#ffd23f"), 1.35, 10
    if kind == "mesa_redonda":
        return table_round(D, iso, 0, 0, "#ff4d8d"), 1.2, 6
    if kind == "mesa_quadrada":
        return table_square(D, iso, 0, 0, "#ffffff", "#ffb400"), 1.2, 4
    if kind == "fogao":
        return stove(D, iso, 0, 0, "R", cooking="lasanha"), 1.05, 2
    if kind == "balcao":
        return counter(D, iso, 0, 0, "R", [("bolo", 8)], body="#2ec4b6"), 1.05, 2
    if kind == "vitrine":
        return pastry_case(D, iso, 0, 0), 0.95, -6
    if kind == "expresso":
        return espresso(D, iso, 0, 0), 0.95, -6
    if kind == "geladeira":
        return fridge(D, iso, 0, 0), 0.82, -18
    if kind == "jukebox":
        return jukebox(D, iso, 0, 0), 1.05, -4
    if kind == "aquario":
        return aquarium(D, iso, 0, 0), 1.05, 0
    if kind == "vaso_flores":
        return flower_vase(D, iso, 0, 0), 1.15, -2
    if kind == "planta":
        return plant(D, iso, 0, 0, pot="#ffd23f"), 0.95, -10
    if kind == "luminaria":
        return floor_lamp(D, iso, 0, 0, "#ff8fb1"), 0.85, -22
    if kind == "estante":
        return bookshelf(D, iso, 0, 0), 0.72, -12
    raise ValueError(kind)


def item_art(D, kind, cx, cy, size):
    art, s, dy = _item(D, kind)
    k = size / 110.0 * s
    return f'<g transform="translate({f(cx)},{f(cy + dy * size / 110.0)}) scale({f(k)}) translate(0,-8)">{art}</g>'


ITEMS = [
    # (tipo, nome, preço, moeda, selos)
    ("cadeira_vermelha", "Cadeira Lanchonete", "80", "coin", ["coracao"]),
    ("mesa_redonda", "Mesa Toalha Rosa", "150", "coin", ["desconto"]),
    ("mesa_quadrada", "Mesa Fórmica", "120", "coin", []),
    ("cadeira_turquesa", "Cadeira Menta", "80", "coin", []),
    ("fogao", "Fogão Retrô", "400", "coin", []),
    ("balcao", "Balcão Menta", "250", "coin", []),
    ("vitrine", "Vitrine de Doces", "380", "coin", ["nivel:4"]),
    ("expresso", "Máquina de Expresso", "520", "coin", ["nivel:6"]),
    ("geladeira", "Geladeira Retrô", "450", "coin", []),
    ("jukebox", "Jukebox Neon", "12", "bean", ["novo"]),
    ("aquario", "Aquário", "8", "bean", ["novo"]),
    ("vaso_flores", "Vaso de Flores", "55", "coin", []),
    ("planta", "Costela-de-adão", "90", "coin", ["coracao"]),
    ("luminaria", "Luminária de Pé", "70", "coin", []),
]


def price_tag(D, cx, y, price, currency, old=None):
    o = []
    icon = coin(D) if currency == "coin" else bean(D)
    tw = 18 + len(price) * 9
    x0 = cx - tw / 2 + 8
    o.append(place(icon, x0 - 2, y - 5, 20))
    col = "#1d3563" if currency == "coin" else "#1a8a3e"
    o.append(txt(x0 + 10, y + 1, price, 15, col, 700))
    if old:
        o.append(txt(cx, y + 15, old, 10.5, "#ff4d5e", 700, "middle", None, 0, 'text-decoration="line-through"'))
    return "".join(o)


def item_square(D, x, y, size, kind, price, currency, badges, selected=False):
    o = []
    if selected:
        o.append(f'<rect x="{f(x-4)}" y="{f(y-4)}" width="{f(size+8)}" height="{f(size+8)}" rx="14" fill="none" stroke="#2a7de1" stroke-width="4"/>')
    o.append(f'<rect x="{f(x)}" y="{f(y+2)}" width="{f(size)}" height="{f(size)}" rx="11" fill="#9fc2ea"/>')
    o.append(f'<rect x="{f(x)}" y="{f(y)}" width="{f(size)}" height="{f(size)}" rx="11" fill="{D.lin([(0, "#ffffff"), (1, "#eef5fd")])}" stroke="#b9d3f0" stroke-width="1.6"/>')
    o.append(f'<ellipse cx="{f(x+size/2)}" cy="{f(y+size*0.78)}" rx="{f(size*0.34)}" ry="{f(size*0.1)}" fill="#dbe9f8"/>')
    o.append(item_art(D, kind, x + size / 2, y + size * 0.7, size))
    old = None
    for b in badges:
        if b == "novo":
            o.append(path(f"M{f(x)},{f(y+30)} L{f(x)},{f(y+11)} Q{f(x)},{f(y)} {f(x+11)},{f(y)} L{f(x+30)},{f(y)} Z", D.lin([(0, "#ff7a7a"), (1, "#e0202e")]), OL, 1.2))
            o.append(txt(x + 9.5, y + 13.5, "NOVO", 8.5, "#ffffff", 700, "middle", None, 0, f'transform="rotate(-45 {f(x+9.5)} {f(y+10)})"'))
        elif b == "coracao":
            o.append(path(f"M{f(x+13)},{f(y+20)} C{f(x+4)},{f(y+14)} {f(x+5)},{f(y+6)} {f(x+10)},{f(y+7)} C{f(x+12)},{f(y+7.4)} {f(x+13)},{f(y+9)} {f(x+13)},{f(y+10)} "
                          f"C{f(x+13)},{f(y+9)} {f(x+14)},{f(y+7.4)} {f(x+16)},{f(y+7)} C{f(x+21)},{f(y+6)} {f(x+22)},{f(y+14)} {f(x+13)},{f(y+20)} Z", "#ff3b5c", OL, 1.2))
        elif b == "desconto":
            o.append(f'<rect x="{f(x+size-40)}" y="{f(y+5)}" width="36" height="16" rx="8" fill="{D.lin([(0, "#ffe34d"), (1, "#ffb400")])}" stroke="{OL}" stroke-width="1.2"/>')
            o.append(txt(x + size - 22, y + 17, "-20%", 10.5, "#b33a00", 700, "middle"))
            old = "190"
        elif b.startswith("nivel:"):
            lv = b.split(":")[1]
            o.append(f'<rect x="{f(x)}" y="{f(y)}" width="{f(size)}" height="{f(size)}" rx="11" fill="#1d3563" opacity="0.45"/>')
            o.append(f'<rect x="{f(x+size/2-12)}" y="{f(y+size/2-22)}" width="24" height="20" rx="4" fill="{D.lin([(0, "#ffd23f"), (1, "#f08c00")])}" stroke="{OL}" stroke-width="1.4"/>')
            o.append(path(f"M{f(x+size/2-7)},{f(y+size/2-22)} v-5 a7,7 0 0,1 14,0 v5", "none", OL, 2.6))
            o.append(f'<rect x="{f(x+size/2-26)}" y="{f(y+size/2+2)}" width="52" height="17" rx="8.5" fill="#ffffff" stroke="{OL}" stroke-width="1.2"/>')
            o.append(txt(x + size / 2, y + size / 2 + 14.6, f"Nível {lv}", 11, "#1d3563", 700, "middle"))
    o.append(price_tag(D, x + size / 2, y + size + 18, price, currency, old))
    return "".join(o)


def big_tab(D, x, y, w, icon_svg, label, active=False, color="#2a7de1", bottom=None):
    yy = y if active else y + 6
    bottom = bottom if bottom is not None else y + 66
    fill = "#ffffff" if active else D.lin([(0, tint(color, 0.35)), (1, color)])
    o = [f'<rect x="{f(x)}" y="{f(yy)}" width="{f(w)}" height="{f(bottom-yy+12)}" rx="14" fill="{fill}" stroke="{"#9fc2ea" if active else shade(color, 0.3)}" stroke-width="2"/>']
    o.append(f'<rect x="{f(x+6)}" y="{f(yy+4)}" width="{f(w-12)}" height="12" rx="6" fill="#ffffff" opacity="{0 if active else 0.25}"/>')
    o.append(place(icon_svg, x + w / 2, yy + 24, 46))
    o.append(txt(x + w / 2, yy + 52, label, 12.5, "#1d3563" if active else "#ffffff", 700, "middle", None if active else shade(color, 0.45), 3))
    return "".join(o)


def cat_chip(D, x, y, icon_svg, active=False):
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="46" height="40" rx="10" fill="{"#dff0ff" if active else "#f4f8fd"}" stroke="{"#2a7de1" if active else "#c9dcf0"}" stroke-width="{2.4 if active else 1.4}"/>']
    o.append(f'<g transform="translate({f(x+23)},{f(y+20)})">{icon_svg}</g>')
    return "".join(o)


def _mini(D, kind, s=0.3, dy=10):
    art, _, _ = _item(D, kind)
    return f'<g transform="translate(0,{dy}) scale({s})">{art}</g>'


def burst(D, cx, cy, r, text):
    pts_ = []
    for i in range(20):
        a = math.radians(i * 18)
        rr = r if i % 2 == 0 else r * 0.78
        pts_.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return P(pts_, D.lin([(0, "#ff7a7a"), (1, "#e0202e")]), OL, 1.6) + txt(cx, cy + 4.5, text, 12, "#ffffff", 700, "middle", "#8a0f1a", 2.5)


def tag_icon(D):
    return (path("M14,20 L34,12 L54,32 L34,52 L14,32 Z", D.lin([(0, "#ffe34d"), (1, "#ffb400")]), OL, 2.2)
            + C(26, 24, 4, "#ffffff", OL, 1.6) + txt(36, 38, "%", 16, "#b33a00", 700, "middle"))


def tiles_icon(D):
    o = []
    for (dx, dy, c) in [(0, -8, "#ffffff"), (12, -2, "#2c2f3d"), (-12, -2, "#2c2f3d"), (0, 4, "#ffffff"), (12, 10, "#ffffff"), (-12, 10, "#ffffff"), (0, 16, "#2c2f3d")]:
        cx, cy = 32 + dx, 26 + dy
        o.append(P([(cx, cy - 6), (cx + 12, cy), (cx, cy + 6), (cx - 12, cy)], c, OL, 1.4))
    return "".join(o)


def wallpaper_icon(D):
    return (path("M14,12 h30 v40 h-30 Z", "#bff3e1", OL, 2.2)
            + "".join(f'<rect x="{18 + i*8}" y="12" width="4" height="40" fill="#ffffff"/>' for i in range(3))
            + path("M14,12 h30 v40 h-30 Z", "none", OL, 2.2)
            + path("M44,12 c8,0 8,10 0,10", D.lin([(0, "#8fe3c8"), (1, "#3fbf9a")]), OL, 2.0)
            + path("M14,40 h30 v12 h-30 Z", "#ffffff", OL, 1.6) + path("M14,39 h30 v3 h-30 Z", "#ff6b6b", None))


def shop_panel(D, W=1280, top=342):
    o = []
    tabs = [(burst(D, 32, 30, 22, "NOVO!"), "Novidades", False, "#ff4d5e"),
            (tag_icon(D), "Promoções", False, "#ffb400"),
            (_mini_icon_chair(D), "Salão", True, "#2a7de1"),
            (_mini_icon_stove(D), "Cozinha", False, "#2a7de1"),
            (_mini_icon_plant(D), "Decoração", False, "#26a93a"),
            (tiles_icon(D), "Pisos", False, "#b06bff"),
            (wallpaper_icon(D), "Paredes", False, "#2ec4b6")]
    px, py, pw = 30, top + 62, W - 60
    ph = 716 - py
    x = 44
    for (ic, lab, act, col) in tabs:
        if not act:
            o.append(big_tab(D, x, top, 104, ic, lab, act, col, bottom=py))
        x += 110
    o.append(f'<rect x="{px}" y="{py+3}" width="{pw}" height="{ph}" rx="18" fill="#1d3563" opacity="0.25"/>')
    o.append(f'<rect x="{px}" y="{py}" width="{pw}" height="{ph}" rx="18" fill="#ffffff" stroke="#9fc2ea" stroke-width="2"/>')
    x = 44
    for (ic, lab, act, col) in tabs:
        if act:
            o.append(big_tab(D, x, top, 104, ic, lab, act, col, bottom=py))
            o.append(f'<rect x="{f(x+2)}" y="{f(py-1)}" width="100" height="16" fill="#ffffff"/>')
        x += 110
    o.append(f'<rect x="{px+10}" y="{py+8}" width="{pw-20}" height="48" rx="12" fill="#f1f7fe"/>')
    cats = [("todos", True), ("cadeira_vermelha", False), ("mesa_redonda", False), ("fogao", False), ("balcao", False), ("vitrine", False),
            ("geladeira", False), ("planta", False), ("luminaria", False), ("jukebox", False), ("estante", False), ("aquario", False)]
    cx = px + 18
    for (kind, act) in cats:
        if kind == "todos":
            ic = txt(0, 5, "Tudo", 13, "#1d3563", 700, "middle")
        else:
            ic = _mini(D, kind, 0.3 if kind not in ("geladeira", "luminaria", "estante") else 0.23, 10)
        o.append(cat_chip(D, cx, py + 12, ic, act))
        cx += 52
    o.append(txt(px + pw - 24, py + 37, "Salão › Mesas e cadeiras", 13, "#5a78a8", 700, "end"))
    gx, gy, size, gap = px + 64, py + 68, 86, 22
    o.append(square_button(D, px + 30, gy + 36, 38, "first") + square_button(D, px + 30, gy + 150, 38, "left"))
    for i, (kind, name, price, cur, badges) in enumerate(ITEMS):
        r, c = divmod(i, 7)
        o.append(item_square(D, gx + c * (size + gap), gy + r * (size + 32), size, kind, price, cur, badges, selected=(kind == "mesa_redonda")))
    ax = gx + 7 * (size + gap) - gap + 26
    o.append(square_button(D, ax, gy + 36, 38, "right") + square_button(D, ax, gy + 150, 38, "last"))
    o.append(txt(ax, gy + 98, "1/6", 12, "#5a78a8", 700, "middle"))
    vx, vy, vw, vh = ax + 32, gy - 4, px + pw - ax - 48, 228
    o.append(f'<rect x="{f(vx)}" y="{f(vy)}" width="{f(vw)}" height="{vh}" rx="14" fill="{D.lin([(0, "#f4f9ff"), (1, "#e2effc")])}" stroke="#b9d3f0" stroke-width="1.6"/>')
    o.append(txt(vx + vw / 2, vy + 24, "Mesa Toalha Rosa", 15, "#1d3563", 700, "middle"))
    fl = Iso(vx + vw / 2, vy + 92, 84, 42)
    tile = [fl.v(-0.5, -0.5), fl.v(0.5, -0.5), fl.v(0.5, 0.5), fl.v(-0.5, 0.5)]
    o.append(P(tile, "#f6c98a", OL, 1.2))
    o.append(f'<g transform="translate({f(vx+vw/2)},{f(vy+92)})">{table_round(D, ISO_ITEM, -0.5, -0.5, "#ff4d8d")}</g>')
    o.append(place(flower(D), vx + 22, vy + 134, 22) + txt(vx + 36, vy + 140, "Beleza +20", 12.5, "#e0337f", 700))
    o.append(txt(vx + 16, vy + 160, "2 lugares · 1×1", 11.5, "#5a78a8", 700))
    o.append(place(coin(D), vx + 28, vy + 190, 24) + txt(vx + 44, vy + 197, "150", 20, "#1d3563", 700))
    o.append(txt(vx + 96, vy + 196, "190", 12, "#ff4d5e", 700, "start", None, 0, 'text-decoration="line-through"'))
    o.append(square_button(D, vx + vw - 34, vy + 184, 50, "check", "green"))
    o.append(txt(vx + vw - 34, vy + 222, "Comprar", 11.5, "#1a8a3e", 700, "middle"))
    return "".join(o)


def _mini_icon_chair(D):
    art, _, _ = _item(D, "cadeira_vermelha")
    return f'<g transform="translate(32,50) scale(0.62)">{art}</g>'


def _mini_icon_stove(D):
    art, _, _ = _item(D, "fogao")
    return f'<g transform="translate(32,52) scale(0.5)">{art}</g>'


def _mini_icon_plant(D):
    art, _, _ = _item(D, "planta")
    return f'<g transform="translate(32,60) scale(0.5)">{art}</g>'


def placement_overlay(D, ox=640, oy=140, cell=(6, 1)):
    """Móvel sendo posicionado no salão: piso verde, setas e botões de girar, confirmar e cancelar."""
    iso = Iso(0, 0, 84, 42)
    x, y = cell
    o = []
    for (dx, dy) in [(0, 0)]:
        t = [iso.v(x + dx, y + dy), iso.v(x + dx + 1, y + dy), iso.v(x + dx + 1, y + dy + 1), iso.v(x + dx, y + dy + 1)]
        o.append(P(t, "#46e05a", "#1f9a33", 2.2, 'fill-opacity="0.55"'))
    o.append(table_round(D, iso, x, y, "#ff4d8d"))
    cx, cy = iso.v(x + 0.5, y + 0.5)
    for (ax_, ay_, ang) in [(-48, 0, 180), (48, 0, 0), (0, -30, 270), (0, 30, 90)]:
        o.append(g(path("M-6,-4 h6 v-5 l9,9 l-9,9 v-5 h-6 Z", D.lin([(0, "#ffffff"), (1, "#cfe3fa")]), "#1f6fd1", 1.6),
                   f"translate({f(cx+ax_)},{f(cy+ay_)}) rotate({ang})"))
    bx, by = cx, cy - 92
    o.append(square_button(D, bx - 44, by, 38, "rotate") + square_button(D, bx, by, 38, "check", "green") + square_button(D, bx + 44, by, 38, "close", "red"))
    return g("".join(o), f"translate({ox},{oy})")


def shop_overlay(D):
    return (top_hud(D) + side_buttons(D) + placement_overlay(D) +
            f'<rect x="0" y="0" width="1280" height="720" fill="none"/>' + shop_panel(D))
