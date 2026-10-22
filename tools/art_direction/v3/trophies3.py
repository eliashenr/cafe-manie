"""Troféus aceleradores (DT-057): taça de bronze, prata ou ouro num pedestal com plaquinha, 1 piso. Eles aceleram os
fogões das 8 casas em volta. O desenho é igual nas 4 rotações."""
from core3 import *
from furniture3 import K

METALS = {"bronze": "#d9884a", "prata": "#c9d4e0", "ouro": "#ffc928"}


def trophy(D, iso, x, y, metal="ouro"):
    k = K(iso)
    color = METALS[metal]
    cx, cy = x + 0.5, y + 0.5
    o = [soft_shadow(D, iso, cx, cy, 0.3, opacity=0.28)]
    # pedestal de madeira escura com a plaquinha dourada na frente (face voltada para +y)
    half = 0.27
    o.append(box3(D, iso, cx - half, cy - half, 2 * half, 2 * half, 30 * k, "#5a3a2a", top="#6e4a36", sw=1.0))
    plaque = [iso.v(cx - 0.17, cy + half, 10 * k), iso.v(cx + 0.17, cy + half, 10 * k), iso.v(cx + 0.17, cy + half, 21 * k),
              iso.v(cx - 0.17, cy + half, 21 * k)]
    o.append(P(plaque, D.lin([(0, tint(color, 0.4)), (1, shade(color, 0.2))]), INK3, 0.8))
    # base, haste e taça
    o.append(cyl3(D, iso, cx, cy, 0.17, 30 * k, 37 * k, color, metal=True))
    o.append(cyl3(D, iso, cx, cy, 0.06, 37 * k, 52 * k, color, metal=True, cap=False))
    sx, sy = iso.v(cx, cy, 52 * k)
    w = 23 * k
    h = 34 * k
    cup = D.lin([(0, shade(color, 0.3)), (0.25, tint(color, 0.6)), (0.4, "#ffffff"), (0.6, color), (1, shade(color, 0.35))], 0, 0, 1, 0)
    for side in (-1, 1):  # alças
        o.append(path(f"M{f(sx + side * w * 0.8)},{f(sy - h * 0.85)} C{f(sx + side * w * 1.6)},{f(sy - h * 0.9)} "
                      f"{f(sx + side * w * 1.5)},{f(sy - h * 0.35)} {f(sx + side * w * 0.45)},{f(sy - h * 0.3)}",
                      "none", INK3, 4.4 * k))
        o.append(path(f"M{f(sx + side * w * 0.8)},{f(sy - h * 0.85)} C{f(sx + side * w * 1.6)},{f(sy - h * 0.9)} "
                      f"{f(sx + side * w * 1.5)},{f(sy - h * 0.35)} {f(sx + side * w * 0.45)},{f(sy - h * 0.3)}",
                      "none", color, 2.4 * k))
    o.append(path(f"M{f(sx - w)},{f(sy - h)} C{f(sx - w)},{f(sy - h * 0.25)} {f(sx - w * 0.3)},{f(sy)} {f(sx)},{f(sy)} "
                  f"C{f(sx + w * 0.3)},{f(sy)} {f(sx + w)},{f(sy - h * 0.25)} {f(sx + w)},{f(sy - h)} Z", cup, INK3, 1.1))
    o.append(E(sx, sy - h, w, 4.4 * k, shade(color, 0.25), INK3, 1.1))
    o.append(E(sx, sy - h + 0.6 * k, w - 2 * k, 3.2 * k, shade(color, 0.45), None))
    # estrela no meio da taça
    r = 7 * k
    pts = []
    for i in range(10):
        a = math.radians(-90 + i * 36)
        rr = r if i % 2 == 0 else r * 0.45
        pts.append(f"{f(sx + math.cos(a) * rr)},{f(sy - h * 0.55 + math.sin(a) * rr)}")
    o.append(f'<polygon points="{" ".join(pts)}" fill="#ffffff" stroke="{INK3}" stroke-width="{f(0.6)}" opacity="0.9"/>')
    # brilho do lado
    o.append(path(f"M{f(sx - w * 0.6)},{f(sy - h * 0.9)} Q{f(sx - w * 0.75)},{f(sy - h * 0.45)} {f(sx - w * 0.35)},{f(sy - h * 0.15)}",
                  "none", "#ffffff", 1.8 * k, 'opacity="0.7"'))
    return "".join(o)


def trophy_bronze(D, iso, x, y):
    return trophy(D, iso, x, y, "bronze")


def trophy_silver(D, iso, x, y):
    return trophy(D, iso, x, y, "prata")


def trophy_gold(D, iso, x, y):
    return trophy(D, iso, x, y, "ouro")


# id do móvel no jogo -> desenho
TROPHIES = {"trophy_bronze": trophy_bronze, "trophy_silver": trophy_silver, "trophy_gold": trophy_gold}
