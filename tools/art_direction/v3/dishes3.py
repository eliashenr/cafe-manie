"""Pratos novos do livro de receitas (DT-053): ícones 48x48 com centro em (24, 26), no mesmo estilo dos pratos
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
