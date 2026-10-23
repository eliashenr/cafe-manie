"""Plantação e frozen yogurt (DT-065): os vasos com pés de fruta (1 piso, o mesmo desenho nas 4 rotações), a máquina de
frozen yogurt (1 piso, com a frente nas rotações 0 e 3, como as de bebida), os copinhos de frozen (48x48, como as
bebidas) e os ícones das frutas colhidas."""
from core3 import *

FRUITS = {"morango": ("#ff3b5c", "#a8161f"), "manga": ("#ffb52e", "#e06a1a"), "mirtilo": ("#5a6ad9", "#2a2f80")}


def _pot(D, iso, cx, cy, k, color="#d9734a"):
    o = [soft_shadow(D, iso, cx, cy, 0.28, opacity=0.28)]
    o.append(cyl3(D, iso, cx, cy, 0.2, 0, 22 * k, color, top=shade(color, 0.3)))
    ex, ey, erx, ery = iso.ell(cx, cy, 22 * k, 0.17)
    o.append(E(ex, ey, erx, ery, "#5a3a24", None))
    return "".join(o)


def _fruit(D, kind, x, y, r):
    light, dark = FRUITS[kind]
    if kind == "morango":
        return (path(f"M{f(x)},{f(y + r)} C{f(x - r)},{f(y)} {f(x - r * 0.8)},{f(y - r)} {f(x)},{f(y - r * 0.7)} "
                     f"C{f(x + r * 0.8)},{f(y - r)} {f(x + r)},{f(y)} {f(x)},{f(y + r)} Z", D.lin([(0, light), (1, dark)]), INK3, 0.7)
                + path(f"M{f(x - r * 0.6)},{f(y - r * 0.8)} L{f(x)},{f(y - r * 1.3)} L{f(x + r * 0.6)},{f(y - r * 0.8)}", "none", "#3fae3a", r * 0.4))
    if kind == "manga":
        return E(x, y, r * 0.8, r, D.lin([(0, light), (1, dark)]), INK3, 0.7) + E(x - r * 0.25, y - r * 0.4, r * 0.25, r * 0.35, "#ffffff", None, extra='opacity="0.4"')
    return C(x, y, r * 0.75, D.rad([(0, light), (1, dark)]), INK3, 0.6) + C(x, y - r * 0.35, r * 0.18, "#1a1f50", None)


def fruit_tree(D, iso, x, y, kind):
    """Vaso de barro com um pezinho de fruta e as frutas maduras penduradas."""
    from furniture3 import K  # aqui dentro: furniture3 importa dishes3, que pode importar este
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    o = [_pot(D, iso, cx, cy, k)]
    sx, sy = iso.v(cx, cy, 22 * k)
    if kind == "manga":  # arvorezinha com tronco
        o.append(line(sx, sy, sx, sy - 34 * k, "#7a4a2a", 4 * k))
        crown = [(0, -52, 22), (-14, -44, 16), (14, -44, 16), (0, -38, 18)]
    else:  # arbusto baixo
        crown = [(0, -24, 18), (-14, -16, 13), (14, -16, 13), (0, -12, 15)]
    for dx, dy, r in crown:
        o.append(C(sx + dx * k, sy + dy * k, r * k, D.rad([(0, "#7ee05a"), (1, "#2f8a3a")]), INK3, 0.9))
    r = Rng({"morango": 3, "manga": 5, "mirtilo": 7}[kind])
    spots = 4 if kind == "manga" else 6
    for _ in range(spots):
        dx = r.u(-16, 16)
        dy = (r.u(-50, -34) if kind == "manga" else r.u(-24, -8))
        o.append(_fruit(D, kind, sx + dx * k, sy + dy * k, (5.2 if kind == "manga" else 3.8) * k))
    return "".join(o)


def strawberry_tree(D, iso, x, y):
    return fruit_tree(D, iso, x, y, "morango")


def mango_tree(D, iso, x, y):
    return fruit_tree(D, iso, x, y, "manga")


def blueberry_tree(D, iso, x, y):
    return fruit_tree(D, iso, x, y, "mirtilo")


def frozen_machine(D, iso, x, y, front="R"):
    """Máquina de frozen yogurt: armarinho rosa com a máquina branca de duas alavancas e copinhos em cima."""
    from drinks3 import _cabinet
    from furniture3 import K
    k = K(iso)
    o, (bx, by, w, d, h0) = _cabinet(D, iso, x, y, front, "#ff7aa8")
    o = [o]
    o.append(box3(D, iso, bx + 0.12, by + 0.12, w - 0.24, d - 0.3, 34 * k, "#f4f7fa", z=h0, top="#ffffff", gloss=True))
    tx, ty = iso.v(bx + w / 2, by + 0.2, h0 + 34 * k)
    for dx, color in [(-10, "#ff7aa8"), (10, "#ffb52e")]:
        o.append(cyl3(D, iso, bx + w / 2 + dx / 96, by + 0.25, 0.06, h0 + 34 * k, h0 + 46 * k, color, top=tint(color, 0.3)))
    for u in (0.3, 0.7):
        px, py = iso.v(bx + w * u, by + d - 0.1, h0 + 18 * k)
        o.append(line(px, py, px, py - 8 * k, "#8f9aa7", 2.4 * k) + C(px, py - 9 * k, 2.6 * k, "#e0303a", INK3, 0.6))
    for i, color in enumerate(["#ff7aa8", "#ffe08a", "#8a9aff"]):
        px, py = iso.v(bx + 0.18 + i * 0.22, by + d - 0.05, h0 + 1)
        o.append(path(f"M{f(px - 4 * k)},{f(py)} L{f(px - 3 * k)},{f(py - 7 * k)} L{f(px + 3 * k)},{f(py - 7 * k)} L{f(px + 4 * k)},{f(py)} Z", "#ffffff", INK3, 0.6))
        o.append(C(px, py - 9 * k, 3.6 * k, color, INK3, 0.6))
    return "".join(o)


def _frozen_cup(D, swirl, topping):
    o = [E(24, 41, 11, 2.6, "#2a1c3a", None, extra='opacity="0.18"')]
    o.append(path("M14,28 L17,40 L31,40 L34,28 Z", D.lin([(0, "#ffffff"), (1, "#e6e0d7")], 0, 0, 1, 0), INK3, 1.1))
    o.append(path("M15,31 L33,31", "none", "#ff7aa8", 1.6))
    o.append(path("M12,28 C12,22 18,20 24,20 C30,20 36,22 36,28 Z", D.lin([(0, tint(swirl, 0.4)), (1, swirl)]), INK3, 1.1))
    o.append(path("M16,24 C18,16 30,16 32,24 Z", D.lin([(0, tint(swirl, 0.5)), (1, swirl)]), INK3, 1.0))
    o.append(path("M20,18 C21,12 27,12 28,18 Z", tint(swirl, 0.3), INK3, 0.9))
    o.append(topping)
    return "".join(o)


def frozen_morango(D):
    return _frozen_cup(D, "#ff9ab8", _fruit(D, "morango", 24, 11, 4))


def frozen_manga(D):
    return _frozen_cup(D, "#ffd27a", _fruit(D, "manga", 24, 11, 4))


def frozen_mirtilo(D):
    return _frozen_cup(D, "#b4b8ff", _fruit(D, "mirtilo", 22, 12, 3.6) + _fruit(D, "mirtilo", 27, 12, 3.6))


def fruit_icon(D, kind):
    """Ícone da fruta colhida (48x48, centro em 24,26)."""
    return E(24, 40, 12, 3, "#2a1c3a", None, extra='opacity="0.18"') + _fruit(D, kind, 24, 26, 13)


FROZEN = {"frozen_morango": frozen_morango, "frozen_manga": frozen_manga, "frozen_mirtilo": frozen_mirtilo}
TREES = {"tree_strawberry": strawberry_tree, "tree_mango": mango_tree, "tree_blueberry": blueberry_tree}


def frozen(D, kind, cx, cy, size=48):
    """Copinho de frozen com centro em (cx, cy) e largura size (a caixa das bebidas)."""
    s = size / 48.0
    return g(FROZEN[kind](D), f"translate({f(cx - 24 * s)},{f(cy - 26 * s)}) scale({f(s)})")


def fruit(D, kind, cx, cy, size=48):
    s = size / 48.0
    return g(fruit_icon(D, kind), f"translate({f(cx - 24 * s)},{f(cy - 26 * s)}) scale({f(s)})")
