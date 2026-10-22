"""Pratos novos do livro de receitas (DT-053 e DT-054): ícones 48x48 com centro em (24, 26), no mesmo estilo dos pratos
da v2 (food.py), e o que aparece no fogão enquanto cada um cozinha (panela, frigideira ou forma, na cor da comida)."""
from core3 import *
from food import _plate

STEAM = "#bdb4a8"


def _steam(xs, top=4.0, bottom=12.0):
    return "".join(path(f"M{x0},{bottom} C{x0 - 3},{bottom - 3} {x0 + 3},{(bottom + top) / 2 - 1} {x0},{top}", "none", STEAM, 1.6,
                        'opacity="0.8"') for x0 in xs)


def _board(D, cx=24, cy=37, w=38, h=10):
    """Tábua de madeira vista de cima, inclinada (para pizza e sushi)."""
    o = [path(f"M{cx - w / 2},{cy} L{cx},{cy - h / 2} L{cx + w / 2},{cy} L{cx},{cy + h / 2} Z", shade("#c98a4b", 0.15), INK3, 1.1)]
    o.append(path(f"M{cx - w / 2},{cy - 1.6} L{cx},{cy - h / 2 - 1.6} L{cx + w / 2},{cy - 1.6} L{cx},{cy + h / 2 - 1.6} Z",
                  D.lin([(0, "#e6b27a"), (1, "#c98a4b")]), INK3, 1.1))
    return "".join(o)


def brigadeiro(D):
    """Quatro brigadeiros em forminhas, com granulado."""
    o = [_plate(D)]
    r = Rng(11)
    for (cx, cy) in [(15, 31), (33, 31), (24, 27.5), (24, 35)]:
        o.append(path(f"M{cx - 6.5},{cy} L{cx - 5},{cy + 4.5} L{cx + 5},{cy + 4.5} L{cx + 6.5},{cy} Z", "#ffffff", INK3, 0.9))
        for dx in (-3.5, 0, 3.5):
            o.append(line(cx + dx, cy + 0.6, cx + dx * 0.8, cy + 4, "#d9d1c5", 0.7))
        o.append(C(cx, cy - 2.6, 5.8, D.rad([(0, "#7a4a2e"), (0.6, "#4a2614"), (1, "#2a1208")], 0.38, 0.32, 0.7), INK3, 1.0))
        for _ in range(9):
            a = r.u(0, 6.28)
            d = r.u(0, 4.6)
            x, y = cx + d * math.cos(a), cy - 2.6 + d * math.sin(a) * 0.9
            o.append(f'<rect x="{f(x)}" y="{f(y)}" width="1.8" height="0.7" rx="0.35" fill="{"#1a0904" if r.r() > 0.4 else "#a86a3c"}" '
                     f'transform="rotate({f(r.u(0, 180))} {f(x)} {f(y)})"/>')
        o.append(E(cx - 2, cy - 5, 1.6, 1, "#ffffff", None, extra='opacity="0.35"'))
    return "".join(o)


def _pastel_shape(D, cx, cy, s=1.0):
    d = (f"M{f(cx - 13 * s)},{f(cy + 3 * s)} C{f(cx - 13 * s)},{f(cy - 9 * s)} {f(cx + 13 * s)},{f(cy - 9 * s)} {f(cx + 13 * s)},{f(cy + 3 * s)} Z")
    o = [path(d, D.lin([(0, "#ffd98a"), (0.6, "#f2b04c"), (1, "#d98a2b")], 0, 0, 0, 1), "#8a5418", 1.1)]
    for i in range(9):  # borda apertada com o garfo
        x = cx - 12 * s + i * 3 * s
        o.append(line(x, cy + 3 * s, x + 0.6 * s, cy + 0.6 * s, "#b9772a", 0.9))
    for (dx, dy) in [(-5, -3), (2, -4.5), (6, -1.5), (-1, -0.5)]:  # bolhinhas da fritura
        o.append(C(cx + dx * s, cy + dy * s, 1.1 * s, "#ffe7b0", "#c98a36", 0.5))
    return "".join(o)


def pastel(D):
    return _plate(D) + _pastel_shape(D, 16, 30, 0.75) + _pastel_shape(D, 29, 33, 0.82)


def pizza(D):
    """Pizza inteira na tábua: borda dourada, molho, queijo derretido, calabresa e manjericão, com uma fatia separada."""
    o = [_board(D)]
    o.append(E(24, 33, 18, 8.4, D.lin([(0, "#f1c27a"), (1, "#c98a3d")]), INK3, 1.1))
    o.append(E(24, 32.6, 15.5, 7, "#d9472e", None))
    o.append(E(24, 32.2, 14, 6.2, D.rad([(0, "#fff0a8"), (0.7, "#ffd25a"), (1, "#f2a33a")]), None))
    for (x, y) in [(17, 31), (24, 29), (30, 31.5), (21, 35), (28, 35.5), (24, 32.4)]:
        o.append(E(x, y, 2.4, 1.3, "#c23a2a", "#7e1d14", 0.6))
    for (x, y, a) in [(19.5, 33.4, 20), (27, 30.2, -30), (32, 34, 40)]:
        o.append(f'<ellipse cx="{x}" cy="{y}" rx="2" ry="0.9" fill="#3fae3a" transform="rotate({a} {x} {y})"/>')
    for a in (20, 140, 260):  # linhas das fatias
        rad = math.radians(a)
        o.append(line(24, 32.4, 24 + 14 * math.cos(rad), 32.4 + 6.2 * math.sin(rad), "#e08a2a", 0.8, 'opacity="0.7"'))
    return "".join(o)


def pancakes(D):
    """Pilha de panquecas com manteiga e mel escorrendo."""
    o = [_plate(D)]
    for i, y in enumerate((35, 31.5, 28, 24.5)):
        o.append(E(24, y + 1.4, 14.5, 4.6, "#c27a32", INK3, 1.0))
        o.append(E(24, y, 14.5, 4.6, D.lin([(0, "#f7d08a"), (1, "#e3a34e")], 0, 0, 0, 1), INK3, 1.0))
    o.append(path("M11,24.5 Q12,30 14,27.5 Q15,33 17,29 Q20,31.5 22,27 L26,27 Q28,32 30,28 Q32,31 34,27.5 Q36,30 37,24.5 Z",
                  "#f2a81d", "#b8720c", 0.8, 'opacity="0.92"'))
    o.append(f'<rect x="20.5" y="19.6" width="7" height="4.6" rx="1" fill="#fff3a6" stroke="{INK3}" stroke-width="0.9"/>')
    o.append(E(22, 21, 1.6, 0.8, "#ffffff", None, extra='opacity="0.6"'))
    return "".join(o)


def feijoada(D):
    """Cumbuca de barro com feijão preto, linguiça e uma rodela de laranja."""
    o = [_plate(D)]
    o.append(path("M9,24 C9,35 15,39 24,39 C33,39 39,35 39,24 Z", D.lin([(0, "#c96a3a"), (1, "#8a3d1c")], 0, 0, 1, 0), INK3, 1.2))
    o.append(E(24, 24, 15, 4.8, "#a8522a", INK3, 1.2))
    o.append(E(24, 24.4, 13, 3.8, D.rad([(0, "#5a3a32"), (1, "#24130f")]), None))
    r = Rng(4)
    for _ in range(14):
        o.append(E(24 + r.u(-10, 10), 24.4 + r.u(-2.4, 2.4), 1.3, 0.8, "#120806", None, extra='opacity="0.85"'))
    for (x, y) in [(19, 23.5), (28, 25), (24, 22.6)]:
        o.append(E(x, y, 2.6, 1.6, "#b8432f", "#6a1c12", 0.6) + E(x, y, 1.2, 0.7, "#e98a6e", None))
    o.append(C(39, 34, 4.6, "#ff8a00", INK3, 0.9) + C(39, 34, 3.4, "#ffc04d", None))
    o.append(_steam((18, 26), 6, 17))
    return "".join(o)


def _maki(D, cx, cy, filling):
    o = [E(cx, cy + 3, 5.4, 2.4, "#1f2b22", INK3, 0.9)]
    o.append(f'<rect x="{cx - 5.4}" y="{cy - 1}" width="10.8" height="4" fill="#1f2b22"/>')
    o.append(E(cx, cy - 1, 5.4, 2.4, "#ffffff", INK3, 0.9))
    o.append(E(cx, cy - 1, 2.4, 1.1, filling, None))
    return "".join(o)


def sushi(D):
    """Tábua com três makis (salmão, pepino, salmão) e dois niguiris."""
    o = [_board(D)]
    for (cx, cy, fill) in [(13, 33, "#ff8a5c"), (20, 30, "#7ccf3a"), (27, 33.5, "#ff8a5c")]:
        o.append(_maki(D, cx, cy, fill))
    for (cx, cy) in [(34, 31), (33, 36)]:
        o.append(E(cx, cy + 1, 6, 2.6, "#ffffff", INK3, 0.9))
        o.append(path(f"M{cx - 6},{cy} C{cx - 4},{cy - 4} {cx + 4},{cy - 4} {cx + 6},{cy} C{cx + 3},{cy + 1.5} {cx - 3},{cy + 1.5} {cx - 6},{cy} Z",
                      D.lin([(0, "#ffb08a"), (1, "#ff6b3d")]), INK3, 0.9))
        for dx in (-2.5, 0.5, 3.5):
            o.append(line(cx + dx, cy - 2.4, cx + dx - 1.2, cy + 0.4, "#ffffff", 0.7, 'opacity="0.7"'))
    o.append(path("M38,25 C41,23 42,27 39.5,28 C38,28.6 37,26.5 38,25 Z", "#9ad15a", INK3, 0.7))  # wasabi
    return "".join(o)


def cheesecake(D):
    """Fatia de cheesecake com base de biscoito e calda de frutas vermelhas."""
    o = [_plate(D)]
    front = [(8, 34), (28, 30), (28, 21), (8, 25)]
    side = [(28, 30), (37, 33), (37, 24), (28, 21)]
    top = [(8, 25), (28, 21), (37, 24), (17, 28)]
    o.append(P([(8, 34), (28, 30), (28, 33), (8, 37)], "#b9773a", INK3, 1.0))
    o.append(P([(28, 30), (37, 33), (37, 36), (28, 33)], "#9a5c2a", INK3, 1.0))
    o.append(P(front, D.lin([(0, "#fff6df"), (1, "#f1dfb8")]), INK3, 1.1))
    o.append(P(side, D.lin([(0, "#efdcb2"), (1, "#d9c08a")]), INK3, 1.1))
    o.append(P(top, "#c8102e", INK3, 1.1))
    o.append(path("M8,25 L28,21 L28,23.5 Q26,26 24.5,23.8 Q22,27.5 20,24.6 Q17.5,27 15.5,25.6 Q12,28.5 10,26.4 Q8.6,27.4 8,26.6 Z", "#a50d26", None))
    for (x, y) in [(15, 24.6), (22, 23), (29, 23.6), (33, 25)]:
        o.append(C(x, y, 1.9, "#e0234a", "#7a0a1c", 0.6) + C(x - 0.6, y - 0.6, 0.6, "#ffffff", None, extra='opacity="0.6"'))
    return "".join(o)


def moqueca(D):
    """Panela de barro com moqueca alaranjada, camarões e coentro."""
    o = [E(24, 40, 18, 4, "#2a1c3a", None, extra='opacity="0.18"')]
    o.append(path("M7,24 C7,36 14,40 24,40 C34,40 41,36 41,24 Z", D.lin([(0, "#5a3a2a"), (1, "#2e1c14")], 0, 0, 1, 0), INK3, 1.2))
    o.append(path("M4,24 h4 M40,24 h4", "none", INK3, 3))
    o.append(E(24, 24, 17, 5.2, "#4a2e22", INK3, 1.2))
    o.append(E(24, 24.4, 15, 4.2, D.rad([(0, "#ffb04a"), (0.6, "#f07a1a"), (1, "#c2500c")]), None))
    for (x, y, a) in [(17, 24, 10), (27, 23, -20), (31, 25.5, 30)]:
        o.append(f'<path d="M{x - 3},{y} q3,-4 6,0 q-2,1.2 -3,2.6 q-1.4,-1 -3,-2.6 Z" fill="#ff8a6a" stroke="#a8361c" stroke-width="0.7" '
                 f'transform="rotate({a} {x} {y})"/>')
    for (x, y) in [(22, 25.6), (25, 22.6), (20, 22.8), (29, 25)]:
        o.append(E(x, y, 1.4, 0.7, "#3fae3a", None))
    o.append(_steam((18, 27), 6, 17))
    return "".join(o)


def burger(D):
    """Hambúrguer com pão de gergelim, alface, queijo derretido e tomate."""
    o = [_plate(D)]
    o.append(path("M10,32 Q10,37 24,37 Q38,37 38,32 Z", D.lin([(0, "#f2b45a"), (1, "#c97a2a")]), INK3, 1.1))
    o.append(path("M9,30 Q12,27.6 15,30 Q18,27.6 21,30 Q24,27.6 27,30 Q30,27.6 33,30 Q36,27.6 39,30 L38,32 L10,32 Z", "#5cc23a", "#2c7a1c", 0.8))
    o.append(f'<rect x="10" y="26.6" width="28" height="4.4" rx="2.2" fill="#5a2e18" stroke="{INK3}" stroke-width="1"/>')
    o.append(path("M9,26.4 L39,26.4 L35,30 L31,27.6 L26,30.4 L21,27.4 L15,30 Z", "#ffcf33", "#c99a14", 0.8))
    o.append(path("M10,26 C10,15 38,15 38,26 Z", D.lin([(0, "#ffd08a"), (0.55, "#f0a64a"), (1, "#d1802c")], 0, 0, 0, 1), INK3, 1.1))
    for (x, y) in [(16, 21), (21, 18.6), (26, 19), (31, 21), (19, 23), (28, 23.2), (24, 21.6)]:
        o.append(E(x, y, 1.1, 0.6, "#fff6dc", "#c9a46a", 0.4))
    o.append(E(17, 20, 3, 1.6, "#ffffff", None, extra='opacity="0.35"'))
    return "".join(o)


def croissant(D):
    """Croissant dourado, com as dobras da massa."""
    o = [_plate(D)]
    o.append(path("M8,31 C8,22 16,17 24,17 C32,17 40,22 40,31 C36,27 33,26.5 31,28 C28,24.5 20,24.5 17,28 C15,26.5 12,27 8,31 Z",
                  D.lin([(0, "#ffd890"), (0.5, "#f0a84a"), (1, "#c9741e")], 0, 0, 0, 1), "#7e4a14", 1.1))
    for (a, b, c) in [((14, 21.5), (16.5, 27.5), (12, 25)), ((20, 18.4), (21, 25.5), (17.6, 21)), ((28, 18.4), (27, 25.5), (30.4, 21)),
                      ((34, 21.5), (31.5, 27.5), (36, 25))]:
        o.append(path(f"M{a[0]},{a[1]} Q{c[0]},{c[1]} {b[0]},{b[1]}", "none", "#a8621c", 1.0))
    o.append(path("M17,19.6 C20,18 28,18 31,19.6", "none", "#fff2cc", 1.4, 'opacity="0.7"'))
    return "".join(o)


def escondidinho(D):
    """Travessa com escondidinho vista de cima e de lado: purê gratinado dourado e o canto já servido mostrando a carne."""
    o = [E(24, 40, 19, 3.6, "#2a1c3a", None, extra='opacity="0.18"')]
    o.append(path("M5,27 L43,27 L40,38 L8,38 Z", D.lin([(0, "#ffffff"), (1, "#dfe6ee")], 0, 0, 1, 0), INK3, 1.2))
    o.append(path("M8,17 L40,17 L43,27 L5,27 Z", "#f4f1ea", INK3, 1.1))
    o.append(path("M10,18.6 L38,18.6 L40.6,25.6 L7.4,25.6 Z", D.rad([(0, "#fff3b0"), (0.55, "#f5c84a"), (1, "#d48a24")]), None))
    r = Rng(9)
    for _ in range(18):
        o.append(E(r.u(11, 37), r.u(19.6, 25), r.u(0.9, 1.8), r.u(0.5, 0.9), "#c26f1c", None, extra='opacity="0.75"'))
    o.append(path("M29,18.6 L38,18.6 L40.6,25.6 L31,25.6 Z", "#9a4a24", None))  # canto servido: a carne aparece
    o.append(path("M29,18.6 L31,25.6", "none", "#f3e6c0", 1.6))
    for (x, y) in [(33, 21), (36, 23.4), (34.5, 24.6)]:
        o.append(E(x, y, 1.4, 0.8, "#c25a2e", None))
    o.append(path("M8,17 L40,17 L43,27 L5,27 Z", "none", INK3, 1.1))
    o.append(_steam((15, 22), 4, 15))
    return "".join(o)


def _taco(D, cx, cy):
    """Taco em pé: a tortilha em U e o recheio (carne, alface e tomate) aparecendo por cima."""
    o = [path(f"M{cx - 10},{cy - 6} C{cx - 10},{cy - 9} {cx + 10},{cy - 9} {cx + 10},{cy - 6} Z", "#d9952f", INK3, 0.9)]
    o.append(E(cx, cy - 6, 9, 2.6, "#7a3a1c", None))
    for i in range(6):  # alface por cima
        x = cx - 8 + i * 3.2
        o.append(C(x, cy - 8 - (i % 2), 2.4, "#5cc23a", "#2c7a1c", 0.6))
    for (dx, dy) in [(-4, -8.5), (2, -9.5), (6, -8)]:
        o.append(C(cx + dx, cy + dy, 1.5, "#e0303a", "#8a141c", 0.5))
    o.append(path(f"M{cx - 11},{cy - 6} C{cx - 11},{cy + 8} {cx + 11},{cy + 8} {cx + 11},{cy - 6} C{cx + 7},{cy - 2} {cx - 7},{cy - 2} {cx - 11},{cy - 6} Z",
                  D.lin([(0, "#ffe08a"), (1, "#e3a33a")], 0, 0, 0, 1), INK3, 1.0))
    for (dx, dy) in [(-6, 1), (-1, 3), (5, 1.5)]:
        o.append(C(cx + dx, cy + dy, 0.8, "#c9852a", None, extra='opacity="0.7"'))
    return "".join(o)


def tacos(D):
    return _plate(D) + _taco(D, 16, 33) + _taco(D, 31, 34) + C(40, 24, 3.6, "#7ccf3a", INK3, 0.8) + C(40, 24, 2.4, "#e6f59a", None)


DISHES = {"brigadeiro": brigadeiro, "pastel": pastel, "pizza": pizza, "panqueca": pancakes, "feijoada": feijoada,
          "sushi": sushi, "cheesecake": cheesecake, "moqueca": moqueca, "hamburguer": burger, "croissant": croissant,
          "escondidinho": escondidinho, "tacos": tacos}


def dish(D, kind, cx, cy, size=48):
    s = size / 48.0
    return g(DISHES[kind](D), f"translate({f(cx - 24 * s)},{f(cy - 26 * s)}) scale({f(s)})")


# --- No fogão ------------------------------------------------------------------------------

# kind -> (utensílio, cor da comida, cor dos pedaços)
COOKWARE = {
    "brigadeiro": ("panela", "#4a2614", "#7a4a2e"), "feijoada": ("panela", "#2a1814", "#b8432f"),
    "moqueca": ("panela", "#f07a1a", "#ff8a6a"), "pastel": ("frigideira", "#f2b04c", "#ffd98a"),
    "panqueca": ("frigideira", "#e8b25a", "#f7d08a"), "hamburguer": ("frigideira", "#5a2e18", "#ffcf33"),
    "tacos": ("frigideira", "#e8b04a", "#5cc23a"), "pizza": ("redonda", "#d9472e", "#ffd25a"),
    "cheesecake": ("redonda", "#f1dfb8", "#c8102e"), "croissant": ("forma", "#f0a84a", "#ffd890"),
    "escondidinho": ("forma", "#f5c84a", "#c97a22"), "sushi": ("tabua", "#ffffff", "#ff8a5c"),
}


def _bubbles(iso, cx, cy, z, r, color, k, n=4, seed=3):
    rng = Rng(seed)
    o = []
    for _ in range(n):
        a = rng.u(0, 6.28)
        d = rng.u(0, r * 0.7)
        px, py = iso.v(cx + d * math.cos(a), cy + d * math.sin(a), z)
        o.append(C(px, py, rng.u(1.6, 2.6) * k, color, None, extra='opacity="0.9"'))
    return "".join(o)


def cookware(D, iso, kind, cx, cy, z, k):
    """Utensílio no fogão com a comida do prato [kind] (pratos novos do livro de receitas)."""
    style, food, bits = COOKWARE[kind]
    sx, sy = iso.v(cx, cy, z)
    o = []
    if style == "panela":
        o.append(cyl3(D, iso, cx, cy, 0.22, z, z + 14 * k, "#40434d", top="#2b2c33"))
        ex, ey, erx, ery = iso.ell(cx, cy, z + 13 * k, 0.19)
        o.append(E(ex, ey, erx, ery, food, None))
        o.append(_bubbles(iso, cx, cy, z + 13 * k, 0.19, bits, k))
        o.append(path(f"M{f(sx - 18 * k)},{f(sy - 12 * k)} h{f(-6 * k)} M{f(sx + 18 * k)},{f(sy - 12 * k)} h{f(6 * k)}", "none", "#26262e", 2.6 * k))
        steam_at = 26
    elif style == "frigideira":
        o.append(path(f"M{f(sx + 12 * k)},{f(sy - 3 * k)} l{f(18 * k)},{f(6 * k)}", "none", "#26262e", 3.2 * k))
        o.append(cyl3(D, iso, cx, cy, 0.22, z, z + 4 * k, "#34353d", top="#2b2c33"))
        ex, ey, erx, ery = iso.ell(cx, cy, z + 4 * k, 0.18)
        o.append(E(ex, ey, erx, ery, "#4a4c56", None))
        for (dx, dy) in [(-0.07, -0.03), (0.06, 0.04), (0.0, 0.09)]:
            px, py = iso.v(cx + dx, cy + dy, z + 4 * k)
            o.append(E(px, py - 1.5 * k, 6 * k, 3 * k, food, INK3, 0.7) + E(px - 1 * k, py - 2.4 * k, 2.4 * k, 1.1 * k, bits, None))
        steam_at = 16
    elif style == "redonda":
        o.append(cyl3(D, iso, cx, cy, 0.21, z, z + 5 * k, "#6e727c", metal=True))
        ex, ey, erx, ery = iso.ell(cx, cy, z + 5 * k, 0.18)
        o.append(E(ex, ey, erx, ery, food, None))
        o.append(_bubbles(iso, cx, cy, z + 5 * k, 0.18, bits, k, n=5, seed=7))
        steam_at = 16
    elif style == "forma":
        o.append(box3(D, iso, cx - 0.26, cy - 0.22, 0.52, 0.44, 7 * k, "#ffffff", z=z, sw=0.9))
        o.append(box3(D, iso, cx - 0.22, cy - 0.18, 0.44, 0.36, 1, food, z=z + 6 * k, sw=0, bevel=False))
        o.append(_bubbles(iso, cx, cy, z + 7 * k, 0.16, bits, k, n=5, seed=5))
        steam_at = 18
    else:  # tábua
        o.append(box3(D, iso, cx - 0.26, cy - 0.2, 0.52, 0.4, 3 * k, "#d9a066", z=z, sw=0.9))
        for (dx, dy) in [(-0.12, 0.0), (0.0, 0.0), (0.12, 0.0)]:
            o.append(cyl3(D, iso, cx + dx, cy + dy, 0.05, z + 3 * k, z + 8 * k, "#1f2b22", top=food, sw=0.7))
        return "".join(o)
    o.append(_steam_puff(sx, sy - steam_at * k, 0.8 * k))
    return "".join(o)


def _steam_puff(x, y, k):
    return "".join(C(x + dx * k, y + dy * k, r * k, "#ffffff", None, extra=f'opacity="{op}"')
                   for dx, dy, r, op in [(0, 0, 5, 0.6), (4, -7, 6, 0.5), (-2, -15, 7, 0.38), (3, -24, 6, 0.26)])


# --- Segunda leva do livro de receitas (níveis 18 a 30) -----------------------------------

def _bowl(D, cx=24, top=24, bottom=39, rx=15, color="#ffffff", inner="#ffffff"):
    """Tigela vista de lado com a boca em elipse; devolve o desenho e a elipse do conteúdo."""
    o = [E(cx, bottom + 1, rx * 0.8, 2.4, "#2a1c3a", None, extra='opacity="0.16"')]
    o.append(path(f"M{cx - rx},{top} C{cx - rx},{bottom - 2} {cx - rx * 0.5},{bottom} {cx},{bottom} C{cx + rx * 0.5},{bottom} {cx + rx},{bottom - 2} {cx + rx},{top} Z",
                  D.lin([(0, tint(color, 0.15)), (1, shade(color, 0.25))], 0, 0, 1, 0), INK3, 1.2))
    o.append(E(cx, top, rx, rx * 0.32, tint(color, 0.3), INK3, 1.2))
    o.append(E(cx, top + 0.3, rx - 1.6, rx * 0.32 - 1.0, inner, None))
    return "".join(o)


def acai(D):
    """Tigela de açaí com granola, banana e morango."""
    o = [_bowl(D, color="#8a4fd1", inner=D.rad([(0, "#7a3a8a"), (1, "#3e1a4a")]))]
    r = Rng(21)
    for _ in range(14):  # granola
        o.append(E(18 + r.u(-4, 4), 23.6 + r.u(-1.6, 1.6), 1.2, 0.8, "#d99a4a" if r.r() > 0.4 else "#a8642a", None))
    for (x, y) in [(26, 22.6), (30, 24.4), (24.5, 25.4)]:  # banana
        o.append(E(x, y, 2.4, 1.4, "#fff3c0", "#c9a24a", 0.6) + C(x, y, 0.5, "#c9a24a", None))
    o.append(path("M33,21 C30,18.6 31,15.6 33.6,15.8 C36.2,15.6 37,18.6 34,21 C33.6,21.4 33.4,21.4 33,21 Z", "#ff3b5c", INK3, 0.8))
    o.append(path("M31.6,16.2 L33.6,14.6 L35.4,16.2", "none", "#3fae3a", 1.2))
    return "".join(o)


def ramen(D):
    """Tigela de lámen: caldo, macarrão, ovo, naruto, alga, cebolinha e os hashis."""
    o = [_bowl(D, color="#e0303a", inner=D.rad([(0, "#f7d9a0"), (1, "#d9a050")]))]
    for i in range(4):  # macarrão
        o.append(path(f"M{14 + i * 2},{23 + i * 0.6} q4,-2 8,0 t8,0", "none", "#fff0b0", 1.2))
    o.append(E(29, 23.6, 3.6, 2.2, "#ffffff", INK3, 0.7) + E(29, 23.6, 1.8, 1.1, "#ffb400", None))  # ovo
    o.append(E(19, 22.4, 2.8, 1.6, "#ffffff", INK3, 0.6) + path("M17.6,22.4 q1.4,-1 2.8,0 q-1.4,1 -2.8,0", "none", "#ff7aa8", 0.8))
    o.append(f'<rect x="31" y="17" width="4" height="7" fill="#1f2b22" stroke="{INK3}" stroke-width="0.6" transform="rotate(12 33 20)"/>')
    for (x, y) in [(23, 25), (25, 22.2), (21, 25.6), (27, 25.8)]:
        o.append(C(x, y, 0.8, "#5cc23a", None))
    o.append(line(30, 9, 44, 21, "#c98a4b", 1.6) + line(33, 8, 45, 19, "#c98a4b", 1.6))
    o.append(_steam((16, 22), 6, 17))
    return "".join(o)


def pudim(D):
    """Pudim de leite com calda de caramelo brilhando."""
    o = [_plate(D)]
    o.append(path("M11,36 Q24,40 37,36 Q38,33 35,32 L13,32 Q10,33 11,36 Z", "#c96a12", None, 'opacity="0.85"'))
    o.append(path("M13,33 L16,19 C18,16.5 30,16.5 32,19 L35,33 C30,36 18,36 13,33 Z",
                  D.lin([(0, "#ffd890"), (0.55, "#f2b24a"), (1, "#d9902a")], 0, 0, 1, 0), INK3, 1.1))
    o.append(E(24, 18.6, 8.2, 2.6, "#b85a0c", INK3, 1.0))
    o.append(path("M16.6,20 Q18,26 16.4,29 M20,21 Q21,27 19.6,31 M31,20.4 Q30,26 31.6,30", "none", "#b85a0c", 1.6, 'opacity="0.8"'))
    o.append(E(21, 22, 1.4, 4.4, "#ffffff", None, extra='opacity="0.35"'))
    return "".join(o)


def bobo(D):
    """Cumbuca de bobó de camarão, cremoso e amarelo, com camarões e coentro."""
    o = [_plate(D)]
    o.append(_bowl(D, top=25, bottom=38, rx=14, color="#a8522a", inner=D.rad([(0, "#ffe08a"), (0.7, "#f5c04a"), (1, "#d9922a")])))
    for (x, y, a) in [(19, 24.4, 10), (27, 23.4, -15), (30, 26, 25)]:
        o.append(f'<path d="M{x - 3},{y} q3,-4 6,0 q-2,1.2 -3,2.6 q-1.4,-1 -3,-2.6 Z" fill="#ff8a6a" stroke="#a8361c" stroke-width="0.7" '
                 f'transform="rotate({a} {x} {y})"/>')
    for (x, y) in [(23, 26), (25, 23.2), (17, 25.8)]:
        o.append(E(x, y, 1.4, 0.7, "#3fae3a", None))
    o.append(_steam((18, 27), 7, 18))
    return "".join(o)


def waffles(D):
    """Waffle quadrado dourado com morangos e chantili."""
    o = [_plate(D)]
    top = [(8, 30), (24, 23), (40, 30), (24, 37)]
    o.append(P([(8, 30), (24, 37), (24, 40), (8, 33)], "#c98a3a", INK3, 1.0))
    o.append(P([(24, 37), (40, 30), (40, 33), (24, 40)], "#a86a2a", INK3, 1.0))
    o.append(P(top, D.lin([(0, "#ffd890"), (1, "#e3a34a")]), INK3, 1.1))
    for t in (0.25, 0.5, 0.75):  # quadriculado
        o.append(line(8 + 16 * t, 30 - 7 * t, 24 + 16 * t, 37 - 7 * t, "#c27a2a", 0.9))
        o.append(line(8 + 16 * t, 30 + 7 * t, 24 + 16 * t, 23 + 7 * t, "#c27a2a", 0.9))
    o.append(path("M20,27 C19,23 23,21 25,23 C27,20.6 31,22 30,26 C32,27 30,30 27,29.4 L21,29.4 C18.6,29.4 18.6,27.4 20,27 Z", "#ffffff", INK3, 0.9))
    for (x, y) in [(17, 31.4), (31, 32), (29, 24)]:
        o.append(path(f"M{x},{y + 2.6} C{x - 3},{y} {x - 2},{y - 2.4} {x},{y - 1.6} C{x + 2},{y - 2.4} {x + 3},{y} {x},{y + 2.6} Z", "#ff3b5c", INK3, 0.7))
    return "".join(o)


def paella(D):
    """Paellera com arroz amarelo, camarões, mexilhões, ervilhas e limão."""
    o = [E(24, 38, 20, 4.2, "#2a1c3a", None, extra='opacity="0.16"')]
    o.append(path("M2,27 h5 M41,27 h5", "none", INK3, 3.2))
    o.append(E(24, 29, 18, 8.4, "#40434d", INK3, 1.2))
    o.append(E(24, 28.4, 16, 7.2, D.rad([(0, "#ffe46b"), (0.7, "#f5c518"), (1, "#d99a12")]), None))
    r = Rng(14)
    for _ in range(20):
        o.append(C(24 + r.u(-13, 13), 28.4 + r.u(-5.4, 5.4), 0.7, "#fff6c0", None, extra='opacity="0.8"'))
    for (x, y) in [(15, 27), (30, 25), (26, 32)]:  # mexilhões
        o.append(E(x, y, 3, 1.6, "#2a2240", INK3, 0.6) + E(x, y - 0.4, 1.6, 0.8, "#ff9a6a", None))
    for (x, y, a) in [(21, 25, 10), (33, 30, -20), (18, 31.4, 30)]:
        o.append(f'<path d="M{x - 3},{y} q3,-4 6,0 q-2,1.2 -3,2.6 q-1.4,-1 -3,-2.6 Z" fill="#ff8a6a" stroke="#a8361c" stroke-width="0.7" '
                 f'transform="rotate({a} {x} {y})"/>')
    for (x, y) in [(24, 27), (28, 29), (20, 29.4), (31, 27.6)]:
        o.append(C(x, y, 1, "#5cc23a", "#2c7a1c", 0.4))
    o.append(path("M33,33 L39,29 A5,5 0 0,1 36,35 Z", "#f2ec7a", INK3, 0.8))
    return "".join(o)


def torta_limao(D):
    """Fatia de torta de limão com merengue tostado."""
    o = [_plate(D)]
    o.append(P([(8, 34), (28, 30), (28, 33), (8, 37)], "#d9a050", INK3, 1.0))
    o.append(P([(28, 30), (37, 33), (37, 36), (28, 33)], "#b9773a", INK3, 1.0))
    o.append(P([(8, 34), (28, 30), (28, 25), (8, 29)], D.lin([(0, "#f2f59a"), (1, "#c9d84a")]), INK3, 1.1))
    o.append(P([(28, 30), (37, 33), (37, 28), (28, 25)], D.lin([(0, "#d9e06a"), (1, "#a8b83a")]), INK3, 1.1))
    o.append(path("M8,29 C8,22 12,18 16,20 C18,15 24,15 26,19 C29,16 34,18 34,22 C37,23 38,26 37,28 L28,25 Z",
                  D.lin([(0, "#ffffff"), (0.7, "#fff1d6"), (1, "#e9b97a")]), INK3, 1.0))
    for (x, y) in [(15, 21), (22, 18.6), (30, 20.6)]:
        o.append(E(x, y, 2.4, 1.2, "#d9902a", None, extra='opacity="0.55"'))
    o.append(C(36, 18, 3.4, "#7ccf3a", INK3, 0.8) + C(36, 18, 2.2, "#e6f59a", None))
    return "".join(o)


def picanha(D):
    """Tábua com picanha fatiada (rosada por dentro, capa de gordura) e alecrim."""
    o = [_board(D)]
    for i in range(4):
        x = 12 + i * 6.4
        y = 33 - i * 1.6
        o.append(path(f"M{x},{y} L{x + 5},{y - 1.4} L{x + 5.6},{y - 9} L{x + 0.6},{y - 7.6} Z", "#7a3a24", INK3, 0.9))
        o.append(path(f"M{x + 0.6},{y - 0.6} L{x + 4.6},{y - 1.8} L{x + 5},{y - 7.6} L{x + 1},{y - 6.6} Z",
                      D.lin([(0, "#ff9a8a"), (1, "#e0605a")]), None))
        o.append(path(f"M{x + 0.6},{y - 7.6} L{x + 5.6},{y - 9} L{x + 5.8},{y - 10.6} L{x + 0.8},{y - 9.2} Z", "#fff3dc", INK3, 0.7))
    o.append(path("M33,28 L42,22", "none", "#3a6a2a", 1.2))
    for i in range(5):
        x, y = 34 + i * 1.8, 27.4 - i * 1.2
        o.append(line(x, y, x - 1.6, y - 2, "#3fae3a", 1.0) + line(x, y, x + 1.6, y - 0.6, "#3fae3a", 1.0))
    o.append(C(10, 36, 1, "#ffffff", None, extra='opacity="0.8"') + C(13, 37.4, 0.8, "#ffffff", None, extra='opacity="0.8"'))
    return "".join(o)


def benedict(D):
    """Ovos Benedict: muffin, presunto, ovo pochê e molho holandês com cebolinha."""
    o = [_plate(D)]
    for (cx, cy) in [(16, 31), (31, 32)]:
        o.append(E(cx, cy + 3, 8, 2.8, "#c98a3a", INK3, 0.9) + E(cx, cy + 1.6, 8, 2.8, "#f2c98a", INK3, 0.9))
        o.append(E(cx, cy + 0.6, 7.4, 2.4, "#ff9aa2", INK3, 0.8))
        o.append(path(f"M{cx - 7},{cy} C{cx - 7},{cy - 7} {cx + 7},{cy - 7} {cx + 7},{cy} Z", D.lin([(0, "#ffffff"), (1, "#f1ece4")]), INK3, 0.9))
        o.append(path(f"M{cx - 7.4},{cy - 0.4} C{cx - 6},{cy - 6.4} {cx + 6},{cy - 6.4} {cx + 7.4},{cy - 0.4} Q{cx + 5},{cy + 3} {cx + 3},{cy} "
                      f"Q{cx},{cy + 3.4} {cx - 2},{cy} Q{cx - 5},{cy + 3} {cx - 7.4},{cy - 0.4} Z", "#ffd84a", "#c99a14", 0.8))
        for dx in (-3, 0, 3):
            o.append(C(cx + dx, cy - 3.6, 0.7, "#3fae3a", None))
    return "".join(o)


def curry(D):
    """Prato de curry alaranjado com montinho de arroz e coentro."""
    o = [_plate(D)]
    o.append(E(27, 32, 12, 4.4, D.rad([(0, "#ffb04a"), (0.7, "#e8851a"), (1, "#b85a0c")]), INK3, 0.9))
    for (x, y) in [(23, 31), (30, 33), (27, 30.4), (33, 31)]:
        o.append(E(x, y, 2, 1.2, "#ffe0b0", "#b85a0c", 0.5))
    o.append(path("M9,32 C9,24 21,24 21,32 C17,34 13,34 9,32 Z", D.lin([(0, "#ffffff"), (1, "#e9e3da")]), INK3, 1.0))
    r = Rng(3)
    for _ in range(10):
        o.append(E(15 + r.u(-4.5, 4.5), 29 + r.u(-2.6, 2.4), 0.9, 0.4, "#d9d1c5", None))
    for (x, y) in [(15, 26), (28, 29), (32, 33.6)]:
        o.append(E(x, y, 1.4, 0.7, "#3fae3a", None))
    o.append(_steam((24, 31), 12, 24))
    return "".join(o)


def floresta_negra(D):
    """Fatia de bolo floresta negra: camadas de chocolate e chantili, cerejas e raspas."""
    o = [_plate(D)]
    front = [(8, 35), (28, 30.5), (28, 16), (8, 20.5)]
    side = [(28, 30.5), (37, 33.5), (37, 19), (28, 16)]
    o.append(P(front, "#3a1a0c", INK3, 1.1))
    o.append(P(side, "#2a1208", INK3, 1.1))
    for t in (0.33, 0.66):  # camadas de creme
        a = (8, 35 - 14.5 * t)
        b = (28, 30.5 - 14.5 * t)
        c = (37, 33.5 - 14.5 * t)
        o.append(P([a, b, (b[0], b[1] - 2.2), (a[0], a[1] - 2.2)], "#fff6e8", None))
        o.append(P([b, c, (c[0], c[1] - 2.2), (b[0], b[1] - 2.2)], "#efe2cc", None))
    o.append(P([(8, 20.5), (28, 16), (37, 19), (17, 23.5)], "#fff6e8", INK3, 1.1))
    r = Rng(8)
    for _ in range(12):
        x = r.u(12, 33)
        o.append(f'<rect x="{f(x)}" y="{f(r.u(17.4, 21.4))}" width="2" height="0.8" fill="#3a1a0c" transform="rotate({f(r.u(0, 180))} {f(x)} 19)"/>')
    for (x, y) in [(15, 18.4), (23, 16.8), (30, 18.8)]:
        o.append(C(x, y, 2.2, "#b8102a", INK3, 0.7) + path(f"M{x},{y - 2} q1,-3 3,-4", "none", "#3a6a2a", 0.9))
    return "".join(o)


def churrasco(D):
    """Tábua de churrasco misto: espetos com carne, linguiça e frango, e farofa."""
    o = [_board(D)]
    for (y0, colors) in [(27, ("#7a3a24", "#b8432f", "#d98a3a")), (32, ("#b8432f", "#7a3a24", "#d98a3a"))]:
        o.append(line(8, y0 + 2, 40, y0 - 4, "#d9d1c5", 1.4))
        for i, c in enumerate(colors * 2):
            x = 12 + i * 4.6
            y = y0 + 1.2 - i * 0.9
            o.append(E(x, y, 2.4, 2, c, INK3, 0.6) + E(x - 0.6, y - 0.8, 0.9, 0.5, "#ffffff", None, extra='opacity="0.35"'))
    r = Rng(6)
    for _ in range(16):
        o.append(C(34 + r.u(-4, 4), 36 + r.u(-1.6, 1.4), 0.8, "#e8c27a" if r.r() > 0.4 else "#c99a4a", None))
    return "".join(o)


def lagosta(D):
    """Lagosta vermelha no prato, com limão e salsinha."""
    o = [_plate(D)]
    o.append(path("M14,30 C14,24 30,22 36,26 C38,28 36,32 32,32 C26,33.6 18,34 14,30 Z", D.lin([(0, "#ff6b5c"), (1, "#c8102e")]), INK3, 1.1))
    for x in (19, 23, 27, 31):
        o.append(path(f"M{x},{25 - (x - 19) * 0.2} q1,4 0,7.4", "none", "#8a0a1c", 0.8))
    o.append(path("M36,26 C40,24 43,26 42,29 C41,31 38,30 36,28 Z", "#e0303a", INK3, 0.9))  # cauda
    o.append(path("M14,28 C9,24 6,20 9,18 C11,17 13,19 12,21 C14,22 15,25 15,27 Z", "#e0303a", INK3, 0.9))  # garra
    o.append(path("M14,31 C9,32 6,35 8,37 C10,38 12,36 12,34 C14,34 15,33 15,32 Z", "#e0303a", INK3, 0.9))
    o.append(line(14, 26, 6, 13, "#c8102e", 0.8) + line(15, 26, 9, 12, "#c8102e", 0.8))
    o.append(C(16.5, 26.6, 0.9, "#1a0904", None))
    o.append(path("M34,35 L40,31 A5,5 0 0,1 37,37 Z", "#f2ec7a", INK3, 0.8))
    return "".join(o)


DISHES.update({"acai": acai, "ramen": ramen, "pudim": pudim, "bobo": bobo, "waffle": waffles, "paella": paella,
               "torta_limao": torta_limao, "picanha": picanha, "benedict": benedict, "curry": curry,
               "floresta": floresta_negra, "churrasco": churrasco, "lagosta": lagosta})

COOKWARE.update({
    "acai": ("redonda", "#4a1e5a", "#d99a4a"), "ramen": ("panela", "#e8b46a", "#fff0b0"),
    "pudim": ("redonda", "#f2b24a", "#b85a0c"), "bobo": ("panela", "#f5c04a", "#ff8a6a"),
    "waffle": ("forma", "#f0b85a", "#ffd890"), "paella": ("frigideira", "#f5c518", "#ff8a6a"),
    "torta_limao": ("redonda", "#d8e86a", "#ffffff"), "picanha": ("frigideira", "#7a3a24", "#ff9a8a"),
    "benedict": ("frigideira", "#ffffff", "#ffd84a"), "curry": ("panela", "#e8851a", "#ffe0b0"),
    "floresta": ("redonda", "#3a1a0c", "#b8102a"), "churrasco": ("frigideira", "#b8432f", "#d98a3a"),
    "lagosta": ("panela", "#e0303a", "#ffffff"),
})


# --- Pratos do Fogão Japonês (DT-059): só saem no fogão temático ---------------------------------

def misso(D):
    """Tigela de sopa de missô: caldo dourado, cubinhos de tofu, alga e cebolinha."""
    o = [_bowl(D, top=25, bottom=39, rx=14, color="#2a2a2a", inner=D.rad([(0, "#f7d9a0"), (0.7, "#e0a850"), (1, "#b8782a")]))]
    for (x, y) in [(19, 24.6), (25, 23.4), (28.6, 25.8), (22.4, 26.4)]:
        o.append(P([(x - 1.6, y - 0.8), (x + 1.4, y - 1.4), (x + 1.8, y + 0.8), (x - 1.2, y + 1.4)], "#fffaf0", INK3, 0.5))
    o.append(path("M15.5,25 q3,-2 6,0 q3,2 6,0", "none", "#1f3b22", 1.4, 'opacity="0.9"'))
    for (x, y) in [(31, 24.2), (17.4, 26.6), (26.6, 27)]:
        o.append(C(x, y, 0.8, "#5cc23a", None))
    o.append(_steam((18, 26), 7, 18))
    return "".join(o)


def yakisoba(D):
    """Prato de yakissoba: macarrão dourado com cenoura, repolho, brócolis e pimentão."""
    o = [_plate(D)]
    o.append(E(24, 33, 14, 5, "#c98a3a", None, extra='opacity="0.35"'))
    for i in range(7):  # macarrão em ondas
        y = 30 + i * 0.9
        o.append(path(f"M{12 + i % 2},{y} q3,-2.4 6,0 t6,0 t6,0", "none", "#e8b04a", 1.6))
        o.append(path(f"M{12 + i % 2},{y} q3,-2.4 6,0 t6,0 t6,0", "none", "#a8701a", 0.4))
    for (x, y, c) in [(17, 29, "#ff8a2a"), (28, 31, "#ff8a2a"), (22, 33, "#e0303a"), (31, 28.6, "#7ccf3a")]:
        o.append(f'<rect x="{x - 2}" y="{y - 0.8}" width="4" height="1.6" rx="0.6" fill="{c}" stroke="{INK3}" stroke-width="0.4" '
                 f'transform="rotate({(x * 7) % 50 - 25} {x} {y})"/>')
    for (x, y) in [(20, 30.4), (30, 33)]:  # brócolis
        o.append(C(x, y, 2, "#3fae3a", INK3, 0.5) + C(x - 1, y - 0.8, 1.1, "#5cc23a", None))
    o.append(line(30, 18, 40, 30, "#c98a4b", 1.6) + line(33, 17, 42, 28, "#c98a4b", 1.6))
    o.append(_steam((20, 27), 12, 24))
    return "".join(o)


def tempura(D):
    """Tempurá: camarões empanados crocantes num prato, com molho e limão."""
    o = [_plate(D)]
    for (x, y, a) in [(17, 31, -25), (24, 29.4, -10), (31, 31.2, 8)]:
        o.append(f'<g transform="rotate({a} {x} {y})">'
                 + E(x, y, 4, 7.4, D.lin([(0, "#ffe9a8"), (0.6, "#f2c25a"), (1, "#d9922a")]), INK3, 0.9)
                 + path(f"M{x - 2.4},{y - 6} l1.4,-0.8 l1,0.9 l1.2,-0.9 l1.2,0.8", "none", "#c47a1a", 0.6)
                 + path(f"M{x - 1.6},{y + 6.6} l1.6,3 l1.6,-3 Z", "#ff6b4a", INK3, 0.6)
                 + "</g>")
    o.append(E(37, 36, 4.2, 1.8, "#5a2e18", INK3, 0.7))
    o.append(path("M8,35 L13,32 A4.6,4.6 0 0,1 11,37.6 Z", "#f2ec7a", INK3, 0.7))
    return "".join(o)


def mochi(D):
    """Dango: três bolinhas de mochi (rosa, branca e verde) no palito, com calda."""
    o = [_plate(D)]
    o.append(line(10, 37, 38, 21, "#d9a066", 1.8))
    for (x, y, c) in [(16, 33.6, "#ffb3c7"), (23, 29.6, "#fffaf0"), (30, 25.6, "#a8e07a")]:
        o.append(C(x, y + 0.6, 5.2, shade(c, 0.12), INK3, 1.0) + C(x, y, 5.2, c, INK3, 1.0)
                 + E(x - 1.6, y - 2, 1.8, 1, "#ffffff", None, extra='opacity="0.7"'))
    o.append(path("M14,30 C17,28 25,24 32,21 C33,22 32,23 31,23.4 C25,26 18,30 15,31.6 Z", "#b8701a", None, 'opacity="0.55"'))
    return "".join(o)


DISHES.update({"misso": misso, "yakisoba": yakisoba, "tempura": tempura, "mochi": mochi})

COOKWARE.update({
    "misso": ("panela", "#e0a850", "#fffaf0"), "yakisoba": ("frigideira", "#e8b04a", "#ff8a2a"),
    "tempura": ("panela", "#f2c25a", "#ffe9a8"), "mochi": ("tabua", "#ffb3c7", "#a8e07a"),
})
