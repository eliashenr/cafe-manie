"""Noite no café (DT-064): o Fogão Lua Cheia (com as medidas do fogão comum, para a panela e o forno aceso caírem no
lugar) e os pratos do cardápio noturno, no estilo dos outros pratos (48x48, centro em 24,26)."""
from core3 import *

MOON_STOVE = dict(enamel="#1f2a5a", top_color="#c9d4ff", panel=("#fff6c4", "#d9c25a", "#8a7a2e"), knob="#ffe066",
                  door=("#3a4a8a", "#141a3a"), handle="#ffe066")


def moon_stove(D, iso, x, y, front):
    """Fogão Lua Cheia: azul-noite com estrelinhas e uma lua dourada no canto de trás."""
    from furniture3 import K, stove, STOVE_INSET, STOVE_HEIGHT  # aqui dentro: furniture3 importa dishes3, que importa este
    k = K(iso)
    bx, by = x + STOVE_INSET, y + STOVE_INSET
    h = STOVE_HEIGHT * k
    o = [stove(D, iso, x, y, front, **MOON_STOVE)]
    sx, sy = iso.v(bx + 0.12, by + 0.12, h)
    o.append(C(sx, sy - 16 * k, 9 * k, D.rad([(0, "#fff6b0"), (1, "#ffc928")]), INK3, 1.0))
    o.append(C(sx + 4 * k, sy - 19 * k, 7.6 * k, "#1f2a5a", None))
    for dx, dy, r in [(16, -26, 2.2), (26, -14, 1.6), (-10, -30, 1.8)]:
        o.append(C(sx + dx * k, sy + dy * k, r * k, "#fff6b0", None))
    return "".join(o)


def _plate(D, cx=24, cy=38, rx=19, ry=6.2, color="#ffffff"):
    o = [E(cx, cy + 1.6, rx, ry, shade(color, 0.15), INK3, 1.1)]
    o.append(E(cx, cy, rx, ry, D.lin([(0, color), (1, shade(color, 0.08))]), INK3, 1.1))
    return "".join(o)


def fondue(D):
    """Fondue: panelinha de queijo derretido sobre o fogareiro, com garfinhos e pão."""
    o = [E(24, 41, 15, 3, "#2a1c3a", None, extra='opacity="0.18"')]
    o.append(path("M14,40 L17,32 M34,40 L31,32", "none", "#3a3c46", 2))
    o.append(path("M11,22 C11,34 37,34 37,22 Z", D.lin([(0, "#e0303a"), (1, "#8a1a20")], 0, 0, 1, 0), INK3, 1.2))
    o.append(E(24, 22, 13, 4, D.rad([(0, "#fff3a8"), (1, "#f2c24a")]), INK3, 1.1))
    for (x, y, a) in [(17, 21, -30), (30, 20, 25)]:
        o.append(line(x, y, x + (-6 if a < 0 else 6), y - 13, "#c9d4e0", 1.4))
        o.append(f'<rect x="{x - 2.4}" y="{y - 2.4}" width="4.8" height="4.8" rx="1" fill="#e8b25a" stroke="{INK3}" stroke-width="0.6"/>')
    return "".join(o)


def risotto(D):
    """Risoto de cogumelos: arroz cremoso com cogumelos e salsinha."""
    o = [_plate(D)]
    o.append(E(24, 34, 13, 4.6, D.rad([(0, "#fff6dc"), (1, "#e8d2a0")]), INK3, 0.9))
    r = Rng(9)
    for _ in range(18):
        o.append(E(24 + r.u(-10, 10), 34 + r.u(-3.4, 3.4), 0.9, 0.5, "#ffffff", None, extra='opacity="0.8"'))
    for (x, y) in [(19, 32), (28, 33), (24, 35)]:
        o.append(path(f"M{x - 3},{y} C{x - 3},{y - 4} {x + 3},{y - 4} {x + 3},{y} Z", "#a8703a", INK3, 0.7))
        o.append(f'<rect x="{x - 0.9}" y="{y}" width="1.8" height="2.4" fill="#f2e2c4" stroke="{INK3}" stroke-width="0.4"/>')
    for (x, y) in [(22, 31.5), (30, 35.4), (17, 35)]:
        o.append(C(x, y, 0.9, "#3fae3a", None))
    return "".join(o)


def caldo_verde(D):
    """Caldo verde: tigela de sopa verde com rodelas de linguiça e um fio de azeite."""
    o = [E(24, 40, 13, 3, "#2a1c3a", None, extra='opacity="0.18"')]
    o.append(path("M10,24 C10,38 38,38 38,24 Z", D.lin([(0, "#f4efe6"), (1, "#c9c0b0")], 0, 0, 1, 0), INK3, 1.2))
    o.append(E(24, 24, 14, 4.4, D.rad([(0, "#c8e68a"), (1, "#6aa83a")]), INK3, 1.1))
    for (x, y) in [(18, 23.4), (27, 22.6), (30, 25), (22, 25.4)]:
        o.append(E(x, y, 2.2, 1.3, "#b8432f", INK3, 0.5) + C(x, y, 0.6, "#ffcfa0", None))
    o.append(path("M15,24 q4,-1.5 8,0 t8,0", "none", "#ffd84a", 0.9, 'opacity="0.9"'))
    o.append(path("M17,13 C15,10 19,8 17,5 M27,13 C25,10 29,8 27,5", "none", "#bdb4a8", 1.6, 'opacity="0.8"'))
    return "".join(o)


def petit_gateau(D):
    """Petit gâteau: bolinho de chocolate escorrendo, com uma bola de sorvete e morango."""
    o = [_plate(D)]
    o.append(path("M13,36 C13,28 17,24 22,24 C27,24 31,28 31,36 Z", D.lin([(0, "#6a3a1a"), (1, "#3a1a0a")], 0, 0, 1, 0), INK3, 1.1))
    o.append(E(22, 25, 8.4, 2.6, "#2a1208", INK3, 0.8))
    o.append(path("M17,26 Q15,32 16,37 L19,37 Q18,31 20,27 Z", "#2a1208", None))
    o.append(C(33, 30, 5.6, D.rad([(0, "#ffffff"), (1, "#f1e6d0")]), INK3, 1.0))
    o.append(path("M35,22 C33,19.6 34,17 36.4,17.2 C38.8,17 39.6,19.6 37,22 Z", "#ff3b5c", INK3, 0.7))
    return "".join(o)


DISHES = {"fondue": fondue, "risoto": risotto, "caldo_verde": caldo_verde, "petit_gateau": petit_gateau}
COOKWARE = {
    "fondue": ("panela", "#f2c24a", "#fff3a8"), "risoto": ("frigideira", "#efe0b8", "#a8703a"),
    "caldo_verde": ("panela", "#8ac04a", "#b8432f"), "petit_gateau": ("forma", "#4a2614", "#ff3b5c"),
}
