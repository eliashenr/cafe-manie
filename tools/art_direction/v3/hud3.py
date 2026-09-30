"""Interface v3 no formato do jogo antigo (convenções do gênero, desenho nosso):
contadores escuros com '+', barra de XP com selo e número do nível, missões em medalhões na lateral,
botões quadrados azuis, barra de ícones e faixa de vizinhos embaixo."""
from icons3 import *
from people3 import head, person

FONT = 'font-family="Fredoka, Nunito, sans-serif"'
NAVY = "#12254a"
BLUE = "#2a7de1"
TEXT_D = "#1d3563"


def txt(x, y, s, size=16, fill="#ffffff", weight=700, anchor="start", stroke=None, sw=4, extra=""):
    base = f'x="{f(x)}" y="{f(y)}" {FONT} font-weight="{weight}" font-size="{f(size)}" text-anchor="{anchor}" {extra}'
    o = ""
    if stroke:
        o += f'<text {base} fill="none" stroke="{stroke}" stroke-width="{f(sw)}" stroke-linejoin="round">{s}</text>'
    return o + f'<text {base} fill="{fill}">{s}</text>'


def pill(D, x, y, w, h, fill=None, stroke="#ffffff", sw=2.0, op=0.78):
    fill = fill or D.lin([(0, "#2a3f6e"), (1, "#0d1a36")])
    return (f'<rect x="{f(x)}" y="{f(y+2)}" width="{f(w)}" height="{f(h)}" rx="{f(h/2)}" fill="#000000" opacity="0.18"/>'
            f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(h/2)}" fill="{fill}" fill-opacity="{op}" stroke="{stroke}" stroke-width="{f(sw)}"/>'
            f'<rect x="{f(x+h/3)}" y="{f(y+3)}" width="{f(w-h*0.66)}" height="{f(h*0.32)}" rx="{f(h*0.16)}" fill="#ffffff" opacity="0.14"/>')


def counter_pill(D, x, y, w, icon_svg, value, plus_color="green"):
    h = 34
    o = [pill(D, x + 16, y, w - 16, h)]
    o.append(place(icon_svg, x + 18, y + h / 2, 46))
    o.append(txt(x + 46, y + 25, value, 22))
    if plus_color:
        o.append(square_button(D, x + w - 4, y + h / 2, 36, "plus", plus_color))
    return "".join(o)


def striped_bar(D, x, y, w, h, frac, c1="#ffe34d", c2="#ffb400", key="xp"):
    pid = f"stripe_{key}"
    D.raw(pid, f'<pattern id="{pid}" patternUnits="userSpaceOnUse" width="14" height="14" patternTransform="rotate(35)">'
               f'<rect width="14" height="14" fill="{c1}"/><rect width="7" height="14" fill="{c2}"/></pattern>')
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(h/2)}" fill="#0d1a36" fill-opacity="0.72" stroke="#ffffff" stroke-width="2"/>']
    fw = max(h, (w - 4) * frac)
    o.append(f'<rect x="{f(x+2)}" y="{f(y+2)}" width="{f(fw)}" height="{f(h-4)}" rx="{f((h-4)/2)}" fill="url(#{pid})"/>')
    o.append(f'<rect x="{f(x+2)}" y="{f(y+2)}" width="{f(fw)}" height="{f(h-4)}" rx="{f((h-4)/2)}" fill="{D.lin([(0, "#ffffff", 0.5), (0.5, "#ffffff", 0.05), (1, "#000000", 0.12)])}"/>')
    return "".join(o)


def xp_block(D, x, y, w, level, cur, maxv):
    o = [striped_bar(D, x + 34, y + 10, w - 34 - 64, 26, cur / maxv)]
    o.append(txt(x + 34 + (w - 34 - 64) / 2, y + 29.5, f"{cur:,} / {maxv:,} XP".replace(",", "."), 15, "#ffffff", 700, "middle", NAVY, 4))
    o.append(place(chef_star(D), x + 22, y + 22, 68))
    o.append(txt(x + w - 30, y + 39, str(level), 40, "#ffe34d", 700, "middle", NAVY, 7))
    o.append(txt(x + w - 30, y + 52, "NÍVEL", 10.5, "#ffffff", 700, "middle", NAVY, 3.5))
    return "".join(o)


def stat_bar(D, x, y, w, icon_svg, frac, label, c1, c2, key):
    o = [striped_bar(D, x + 18, y + 8, w - 18, 22, frac, c1, c2, key)]
    o.append(txt(x + 18 + (w - 18) / 2, y + 24.5, label, 14, "#ffffff", 700, "middle", NAVY, 4))
    o.append(place(icon_svg, x + 12, y + 19, 42))
    return "".join(o)


def timer_panel(D, x, y, title, digits=("02", "09", "44"), labels=("H", "M", "S")):
    w, h = 214, 58
    o = [f'<rect x="{f(x)}" y="{f(y+2)}" width="{w}" height="{h}" rx="14" fill="#000000" opacity="0.18"/>',
         f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="{h}" rx="14" fill="{D.lin([(0, "#2a3f6e"), (1, "#0d1a36")])}" fill-opacity="0.82" stroke="#ffffff" stroke-width="2"/>']
    o.append(place(gift(D), x + 6, y + 30, 58))
    o.append(txt(x + 42, y + 15, title, 11, "#bfe3ff", 700))
    for i, (dg, lb) in enumerate(zip(digits, labels)):
        bx = x + 42 + i * 56
        o.append(f'<rect x="{f(bx)}" y="{f(y+20)}" width="44" height="26" rx="6" fill="#ffffff" stroke="{TEXT_D}" stroke-width="1.4"/>')
        o.append(txt(bx + 22, y + 40, dg, 20, TEXT_D, 700, "middle"))
        o.append(txt(bx + 22, y + 56, lb, 9, "#bfe3ff", 700, "middle"))
        if i < 2:
            o.append(txt(bx + 50, y + 39, ":", 18, "#ffffff", 700, "middle"))
    return "".join(o)


def ribbon(D, cx, y, text, color="#ff4d6d", w=None):
    w = w or max(64, len(text) * 7.6 + 22)
    x0, x1 = cx - w / 2, cx + w / 2
    h = 18
    o = [path(f"M{f(x0-7)},{f(y+3)} L{f(x0+4)},{f(y+3)} L{f(x0+4)},{f(y+h+3)} L{f(x0-7)},{f(y+h+3)} L{f(x0-2)},{f(y+h/2+3)} Z", shade(color, 0.3), OL, 1.4)]
    o.append(path(f"M{f(x1+7)},{f(y+3)} L{f(x1-4)},{f(y+3)} L{f(x1-4)},{f(y+h+3)} L{f(x1+7)},{f(y+h+3)} L{f(x1+2)},{f(y+h/2+3)} Z", shade(color, 0.3), OL, 1.4))
    o.append(f'<rect x="{f(x0)}" y="{f(y)}" width="{f(w)}" height="{h}" rx="3" fill="{D.lin([(0, tint(color, 0.25)), (1, shade(color, 0.12))])}" stroke="{OL}" stroke-width="1.6"/>')
    o.append(txt(cx, y + 13.4, text, 11.5, "#ffffff", 700, "middle", shade(color, 0.45), 3))
    return "".join(o)


def portrait(D, spec, hat=None, scale=1.0):
    """Cabeça de um personagem (com chapéu de chef opcional), centrada em (0, 0)."""
    sk = spec.get("skin", "clara")
    hr = spec.get("hair", ("curto", "castanho"))
    extras = {k: v for k, v in spec.items() if k in ("lash", "iris", "glasses", "freckles", "beard", "earrings", "cap")}
    body = head(D, sk, hr, spec.get("expr", "feliz"), **extras)
    if hat == "chef":
        body += (path("M-18,-99 C-25.6,-113 -15.6,-128.6 -4.6,-122.6 C-0.6,-133.6 16.4,-132 18.6,-120.6 C27,-121.6 30,-108 20.6,-99 Z",
                      D.lin([(0, "#ffffff"), (1, "#d9e1ea")]), "#3a2326", 1.3)
                 + path("M-19.6,-102.4 C-8,-105.6 10,-105.6 21.6,-102.4 L20.6,-94 C9,-96.8 -7,-96.8 -18.6,-94 Z", "#ffffff", "#3a2326", 1.2))
    return f'<g transform="scale({f(scale)}) translate(0,{f(88 if hat else 84)})">{body}</g>'


def medallion(D, x, y, inner, rim="#ffb400", label=None, label_color="#ff4d6d", badge=None, sticker=None, r=32):
    cid = D.clip(f"M{f(x-r+4)},{f(y)} a{f(r-4)},{f(r-4)} 0 1,0 {f(2*(r-4))},0 a{f(r-4)},{f(r-4)} 0 1,0 {f(-2*(r-4))},0 Z")
    o = [C(x + 1.5, y + 3, r, "#000000", None, extra='opacity="0.2"')]
    o.append(C(x, y, r, D.lin([(0, tint(rim, 0.4)), (1, shade(rim, 0.2))]), OL, 2.2))
    o.append(C(x, y, r - 4, D.rad([(0, "#ffffff"), (1, "#cfe8ff")], 0.5, 0.35, 0.7), OL, 1.4))
    o.append(f'<g clip-path="{cid}">{inner}</g>')
    o.append(path(f"M{f(x-r+8)},{f(y-8)} A{f(r-8)},{f(r-8)} 0 0,1 {f(x+2)},{f(y-r+8)}", "none", "#ffffff", 3, 'opacity="0.5"'))
    if label:
        o.append(ribbon(D, x, y + r - 8, label, label_color))
    if badge:
        o.append(C(x + r - 6, y - r + 8, 11, D.lin([(0, "#ff7a7a"), (1, "#e0202e")]), "#ffffff", 2.2))
        o.append(txt(x + r - 6, y - r + 13, str(badge), 13, "#ffffff", 700, "middle"))
    if sticker:
        pts_ = []
        for i in range(16):
            a = math.radians(i * 22.5)
            rr = 17 if i % 2 == 0 else 13
            pts_.append((x - r + 8 + rr * math.cos(a), y - r + 8 + rr * math.sin(a)))
        o.append(P(pts_, D.lin([(0, "#fff36b"), (1, "#ffb400")]), OL, 1.4))
        o.append(txt(x - r + 8, y - r + 11.5, sticker, 9, "#d9331f", 700, "middle", None, 0, f'transform="rotate(-14 {f(x-r+8)} {f(y-r+8)})"'))
    return "".join(o)


def quest_tip(D, x, y, title, prog, total, reward="+50"):
    w, h = 176, 58
    o = [f'<rect x="{f(x)}" y="{f(y+2)}" width="{w}" height="{h}" rx="12" fill="#000000" opacity="0.15"/>']
    o.append(path(f"M{f(x)},{f(y+22)} l-10,6 l10,6 Z", "#ffffff", OL, 1.6))
    o.append(f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="{h}" rx="12" fill="#ffffff" stroke="{OL}" stroke-width="1.6"/>')
    o.append(path(f"M{f(x+1)},{f(y+23)} l0,10", "none", "#ffffff", 3))
    o.append(txt(x + 12, y + 18, "MISSÃO 4 DE 6", 10, "#ff6b3d", 700))
    o.append(txt(x + 12, y + 35, title, 15, TEXT_D, 700))
    o.append(f'<rect x="{f(x+12)}" y="{f(y+42)}" width="102" height="9" rx="4.5" fill="#dce8f7"/>')
    o.append(f'<rect x="{f(x+12)}" y="{f(y+42)}" width="{f(102*prog/total)}" height="9" rx="4.5" fill="{D.lin([(0, "#7ee85a"), (1, "#26a93a")])}"/>')
    o.append(txt(x + 120, y + 51, f"{prog}/{total}", 11, TEXT_D, 700))
    o.append(place(coin(D), x + w - 22, y + 24, 22) + txt(x + w - 22, y + 50, reward, 11, "#e08a00", 700, "middle"))
    return "".join(o)


def glossy_icon_button(D, cx, cy, icon_svg, label, badge=None, size=60):
    o = [E(cx, cy + size * 0.42, size * 0.36, 5, "#000000", None, extra='opacity="0.18"')]
    o.append(place(icon_svg, cx, cy, size))
    o.append(txt(cx, cy + size / 2 + 13, label, 12.5, TEXT_D, 700, "middle", "#ffffff", 3.5))
    if badge:
        o.append(C(cx + size * 0.36, cy - size * 0.34, 10, D.lin([(0, "#ff7a7a"), (1, "#e0202e")]), "#ffffff", 2))
        o.append(txt(cx + size * 0.36, cy - size * 0.34 + 4.5, str(badge), 12, "#ffffff", 700, "middle"))
    return "".join(o)


NEIGHBORS = [
    ("Ana", 21, dict(skin="clara", hair=("rabo", "castanho"), lash=True, iris="#3b7fd9"), "#bfe3ff"),
    ("Beto", 18, dict(skin="negra", hair=("curto", "preto")), "#ffe0b3"),
    ("Duda", 25, dict(skin="clara", hair=("chanel", "ruivo"), lash=True, freckles=True, iris="#2f9e62"), "#ffd0e4"),
    ("Caio", 12, dict(skin="parda", hair=("bone", "preto"), cap="#2f7bff"), "#d5f5c8"),
    ("Lia", 30, dict(skin="morena", hair=("longo", "preto"), lash=True), "#e5dcff"),
    ("Rafa", 9, dict(skin="rosada", hair=("topete", "loiro"), iris="#3b7fd9"), "#bfe3ff"),
    ("Vó Cida", 44, dict(skin="clara", hair=("coque", "grisalho"), lash=True, glasses="#7a4bd6"), "#ffe0b3"),
]


def neighbor_card(D, x, y, name, level, spec, bg, w=100, h=94):
    o = [f'<rect x="{f(x)}" y="{f(y+2)}" width="{w}" height="{h}" rx="10" fill="#000000" opacity="0.12"/>']
    o.append(f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="{h}" rx="10" fill="#ffffff" stroke="#9fc2ea" stroke-width="1.6"/>')
    o.append(txt(x + w / 2, y + 15, name, 12.5, TEXT_D, 700, "middle"))
    px, py, pw, ph = x + 8, y + 20, w - 16, h - 28
    cid = D.clip(f"M{f(px+6)},{f(py)} h{f(pw-12)} a6,6 0 0,1 6,6 v{f(ph-12)} a6,6 0 0,1 -6,6 h{f(-pw+12)} a6,6 0 0,1 -6,-6 v{f(-ph+12)} a6,6 0 0,1 6,-6 Z")
    o.append(f'<rect x="{f(px)}" y="{f(py)}" width="{f(pw)}" height="{f(ph)}" rx="6" fill="{D.lin([(0, tint(bg, 0.5)), (1, bg)])}" stroke="#c9dcf0" stroke-width="1"/>')
    o.append(f'<g clip-path="{cid}"><g transform="translate({f(px+pw/2)},{f(py+ph*0.58)})">{portrait(D, spec, scale=0.9)}</g></g>')
    o.append(place(star(D), x + 14, y + h - 12, 34))
    o.append(txt(x + 14, y + h - 7, str(level), 12, "#7a3a00", 700, "middle", "#fff3a8", 2.5))
    return "".join(o)


def special_card(D, x, y, title1, title2, color, icon, w=100, h=94):
    pal = {"orange": ("#ffb13d", "#f07b00", "#b85a00"), "green": ("#8ff06a", "#26a93a", "#177a28")}[color]
    o = [f'<rect x="{f(x)}" y="{f(y+2)}" width="{w}" height="{h}" rx="10" fill="#000000" opacity="0.14"/>']
    o.append(f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="{h}" rx="10" fill="{D.lin([(0, pal[0]), (1, pal[1])])}" stroke="{pal[2]}" stroke-width="2"/>')
    o.append(f'<rect x="{f(x+6)}" y="{f(y+4)}" width="{w-12}" height="18" rx="8" fill="#ffffff" opacity="0.25"/>')
    o.append(icon)
    o.append(txt(x + w / 2, y + h - 22, title1, 12.5, "#ffffff", 700, "middle", pal[2], 3))
    o.append(txt(x + w / 2, y + h - 8, title2, 12.5, "#ffffff", 700, "middle", pal[2], 3))
    return "".join(o)


def neighbors_row(D, x0, y, width):
    o = []
    o.append(square_button(D, x0 + 20, y + 26, 38, "first") + square_button(D, x0 + 20, y + 70, 38, "left"))
    cards_x = x0 + 46
    n_cards = len(NEIGHBORS) + 2
    gap = (width - 92 - n_cards * 100) / (n_cards - 1)
    xx = cards_x
    plus = (f'<g transform="translate({f(xx+50)},{f(y+34)})">'
            f'<circle r="20" fill="#ffffff" opacity="0.95"/><path d="M0,-11 V11 M-11,0 H11" stroke="#f07b00" stroke-width="6" stroke-linecap="round"/></g>')
    o.append(special_card(D, xx, y, "Convidar", "amigos", "orange", plus))
    xx += 100 + gap
    for (name, lvl, spec, bg) in NEIGHBORS:
        o.append(neighbor_card(D, xx, y, name, lvl, spec, bg))
        xx += 100 + gap
    plus2 = (f'<g transform="translate({f(xx+50)},{f(y+34)})">'
             f'<circle r="20" fill="#ffffff" opacity="0.95"/><path d="M0,-11 V11 M-11,0 H11" stroke="#26a93a" stroke-width="6" stroke-linecap="round"/></g>')
    o.append(special_card(D, xx, y, "Adicionar", "vizinho", "green", plus2))
    o.append(square_button(D, x0 + width - 20, y + 26, 38, "last") + square_button(D, x0 + width - 20, y + 70, 38, "right"))
    return "".join(o)


def rating_block(D, x, y, pct=86, name="Café da Bia"):
    w, h = 188, 64
    o = [f'<rect x="{f(x)}" y="{f(y+2)}" width="{w}" height="{h}" rx="12" fill="#000000" opacity="0.14"/>']
    o.append(f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="{h}" rx="12" fill="#ffffff" stroke="#9fc2ea" stroke-width="1.6"/>')
    o.append(place(smiley(D), x + 26, y + 27, 40))
    o.append(txt(x + 52, y + 26, f"{pct}%", 22, TEXT_D, 700))
    o.append(txt(x + 106, y + 25, "satisfeitos", 11, "#5a78a8", 700))
    for i in range(5):
        fill = "#ffc928" if i < 4 else "#d9e3f0"
        o.append(place(star(D, fill, "#f08c00" if i < 4 else "#aab8cc"), x + 60 + i * 16, y + 38, 18))
    o.append(f'<rect x="{f(x+8)}" y="{f(y+h-17)}" width="{w-16}" height="14" rx="7" fill="#eaf4ff"/>')
    o.append(txt(x + w / 2, y + h - 6, name, 11.5, "#e0512a", 700, "middle"))
    return "".join(o)


def bottom_bar(D, W=1280, Hh=720):
    o = []
    top = Hh - 170
    # faixa de ícones
    o.append(f'<rect x="206" y="{top+8}" width="{W-206-72}" height="50" rx="16" fill="#ffffff" fill-opacity="0.93" stroke="#9fc2ea" stroke-width="1.6"/>')
    icons = [(shop_house(D), "Loja", None), (roller(D), "Decorar", None), (expand(D), "Expandir", None), (book(D), "Cardápio", None),
             (clipboard(D), "Missões", 1), (gift(D), "Presentes", 2), (trophy(D), "Conquistas", None), (mail(D), "Correio", 3)]
    span = (W - 206 - 72 - 40) / len(icons)
    for i, (ic, lab, bd) in enumerate(icons):
        o.append(glossy_icon_button(D, 226 + span * (i + 0.5), top + 14, ic, lab, bd, 52))
    o.append(square_button(D, W - 36, top + 33, 46, "gear"))
    o.append(rating_block(D, 12, top - 2))
    # vizinhos
    o.append(f'<rect x="0" y="{top+64}" width="{W}" height="{Hh-top-64}" fill="{D.lin([(0, "#eaf4ff"), (1, "#cfe3fa")])}" fill-opacity="0.97"/>')
    o.append(f'<rect x="0" y="{top+64}" width="{W}" height="3" fill="#ffffff"/>')
    o.append(neighbors_row(D, 8, top + 70, W - 16))
    return "".join(o)


def top_hud(D, W=1280):
    o = []
    o.append(counter_pill(D, 12, 12, 212, coin(D), "12.480"))
    o.append(counter_pill(D, 12, 54, 212, bean(D), "37"))
    # botão verde "Moedas e grãos"
    o.append(f'<rect x="20" y="96" width="176" height="28" rx="9" fill="{D.lin([(0, "#7ee85a"), (1, "#26a93a")])}" stroke="#177a28" stroke-width="2"/>')
    o.append(f'<rect x="26" y="99" width="164" height="8" rx="4" fill="#ffffff" opacity="0.3"/>')
    o.append(place(coin(D), 36, 110, 22) + place(bean(D), 50, 111, 20))
    o.append(txt(122, 115.5, "Moedas e grãos", 14, "#ffffff", 700, "middle", "#177a28", 3))
    o.append(xp_block(D, 402, 8, 420, 12, 4820, 6100))
    o.append(stat_bar(D, 842, 12, 150, flower(D), 0.74, "148", "#ffa3cf", "#ff5fa2", "beleza"))
    o.append(timer_panel(D, W - 226, 8, "PRESENTE DIÁRIO EM"))
    return "".join(o)


def side_buttons(D, W=1280, y0=150):
    o = []
    for i, kd in enumerate(["zoom_in", "zoom_out", "full", "eye", "music", "sound"]):
        o.append(square_button(D, W - 28, y0 + i * 48, 42, kd))
    return "".join(o)


CHEF_BIA = dict(skin="negra", hair=("black", "preto"), lash=True, earrings="#ffc928")
LEO = dict(skin="morena_clara", hair=("curto", "preto"))


def side_quests(D, x=46, y0=178):
    o = []
    bia = f'<g transform="translate({f(x)},{f(y0+9)})">{portrait(D, CHEF_BIA, hat="chef", scale=0.6)}</g>'
    o.append(medallion(D, x, y0, bia, "#ffb400", "MISSÕES", "#ff4d6d", badge=1))
    o.append(medallion(D, x, y0 + 96, place(gift(D), x, y0 + 96, 46), "#ff5fa2", "PRESENTE", "#b06bff"))
    o.append(medallion(D, x, y0 + 192, place(cake(D), x, y0 + 194, 46), "#4fc3ff", "FESTIVAL", "#2a7de1", sticker="NOVO!"))
    o.append(medallion(D, x, y0 + 288, place(trophy(D), x, y0 + 288, 44), "#8fe06a", "CONQUISTAS", "#26a93a"))
    o.append(quest_tip(D, x + 44, y0 - 26, "Sirva 3 cafés", 2, 3))
    return "".join(o)


def full_hud(D, W=1280, Hh=720):
    return top_hud(D, W) + side_buttons(D, W) + side_quests(D) + bottom_bar(D, W, Hh)
