"""Bebidas e máquinas de bebida (DT-052): os ícones das bebidas (48x48, centro em 24,26, como os pratos) e as
máquinas de café e de sucos, que ficam na cozinha (1 piso, desenhadas como os fogões: a frente aparece nas
rotações 0 e 3)."""
from core3 import *
from furniture3 import CHROME, WOOD_M, WOOD_D, K

STEAM = "#bdb4a8"


def _saucer(D, cx=24, cy=39):
    return (E(cx, cy + 0.9, 15, 4.6, shade("#e3ddd3", 0.1), INK3, 1.1)
            + E(cx, cy, 15, 4.6, D.lin([(0, "#ffffff"), (1, "#e6e0d7")]), INK3, 1.1)
            + E(cx, cy + 0.2, 8.5, 2.5, "#efe9e0", "#d4ccc0", 0.7))


def _steam(xs, top=5.0, bottom=13.0):
    return "".join(path(f"M{x0},{bottom} C{x0 - 3},{bottom - 3} {x0 + 3},{(bottom + top) / 2 - 1} {x0},{top}", "none", STEAM, 1.8,
                        'opacity="0.85"') for x0 in xs)


def _cup(D, x0, x1, top, bottom, rim_ry, liquid, cup="#ffffff"):
    """Xícara de louça de (x0, top) a (x1, bottom), com a asa à direita e o líquido aparecendo na boca."""
    mid = (x0 + x1) / 2
    half = (x1 - x0) / 2
    body = D.lin([(0, shade(cup, 0.08)), (0.35, cup), (0.75, shade(cup, 0.04)), (1, shade(cup, 0.18))], 0, 0, 1, 0)
    o = [path(f"M{x0},{top} L{x0 + 1.6},{bottom - 5} C{x0 + 2.4},{bottom - 1} {mid - half * 0.4},{bottom} {mid},{bottom} "
              f"C{mid + half * 0.4},{bottom} {x1 - 2.4},{bottom - 1} {x1 - 1.6},{bottom - 5} L{x1},{top} Z", body, INK3, 1.2)]
    handle = f"M{x1 - 1},{top + 2.5} C{x1 + 6},{top + 1.5} {x1 + 7},{bottom - 6} {x1 - 1.8},{bottom - 5}"
    o.append(path(handle, "none", INK3, 3.2) + path(handle, "none", tint(cup, 0.4), 1.4))
    o.append(E(mid, top, half, rim_ry, "#faf7f2", INK3, 1.2))
    o.append(E(mid, top + 0.4, half - 1.8, rim_ry - 0.9, liquid, None))
    return "".join(o)


def expresso(D):
    """Xícara pequena de expresso com creme dourado."""
    o = [_saucer(D)]
    o.append(_cup(D, 15, 33, 25, 38, 3.4, D.rad([(0, "#e8b77a"), (0.6, "#b0703f"), (1, "#5c2f14")])))
    o.append(E(22, 25.2, 2.4, 0.9, "#f6d9a8", None, extra='opacity="0.8"'))
    o.append(_steam((20, 27), 9, 19))
    return "".join(o)


def cappuccino(D):
    """Xícara larga com espuma branca, coração de leite e canela."""
    o = [_saucer(D)]
    o.append(_cup(D, 9, 37, 19, 38, 4.4, D.rad([(0, "#fff8ec"), (0.7, "#f1dcc0"), (1, "#c99a6a")])))
    o.append(path("M23,23.6 C19.8,21.6 19,20 20.6,19.2 C21.8,18.6 22.6,19.3 23,20 C23.4,19.3 24.2,18.6 25.4,19.2 "
                  "C27,20 26.2,21.6 23,23.6 Z", "#b97a45", "none"))
    for (x, y) in [(15, 19.6), (29, 18.8), (31.5, 20.4), (16.5, 21.2)]:
        o.append(C(x, y, 0.7, "#8a4f22", None, extra='opacity="0.8"'))
    o.append(_steam((18, 26), 4, 13))
    return "".join(o)


def chocolate_quente(D):
    """Caneca vermelha de chocolate com chantili e um marshmallow."""
    o = [E(24, 40, 13, 3.6, "#2a1c3a", None, extra='opacity="0.18"')]
    o.append(_cup(D, 11, 35, 17, 40, 3.8, "#5a2a14", cup="#ff5a5f"))
    o.append(path("M12.5,17.5 C11,13.5 15,11.5 17.5,13 C18,9 24,8 26,11.5 C29,9.5 34,12 33,15.5 C35,16 34.5,19 32,19.5 "
                  "L14,19.5 C12,19.5 11.5,18 12.5,17.5 Z", D.lin([(0, "#ffffff"), (1, "#efe7da")]), INK3, 1.1))
    o.append(path("M17,14.5 C19,13.5 21,14.2 22,15.4 M25,13 C27,12.5 29,13.2 30,14.6", "none", "#d9cfc0", 0.9))
    o.append(f'<rect x="25.5" y="9" width="6" height="5" rx="1.6" fill="#ffd7e8" stroke="{INK3}" stroke-width="0.9" '
             f'transform="rotate(14 28.5 11.5)"/>')
    for (x, y) in [(16, 17.2), (21, 16.4), (29.5, 17.6)]:
        o.append(C(x, y, 0.8, "#6a331a", None))
    return "".join(o)


def _glass(D, x0, x1, top, bottom, liquid, level, straw=None):
    """Copo alto de vidro (boca de x0 a x1, mais estreito embaixo) com o suco até a fração [level] da altura."""
    inset = 2.6
    lt = bottom - (bottom - top) * level
    glass = f"M{x0},{top} L{x0 + inset},{bottom} L{x1 - inset},{bottom} L{x1},{top} Z"
    o = [E((x0 + x1) / 2, bottom + 0.6, (x1 - x0) / 2 - 1, 2.2, "#2a1c3a", None, extra='opacity="0.18"')]
    if straw:
        o.append(path(f"M{x1 - 6},{top + 6} L{x1 + 3},{top - 9}", "none", INK3, 4.2)
                 + path(f"M{x1 - 6},{top + 6} L{x1 + 3},{top - 9}", "none", straw, 2.4))
    t = (lt - top) / (bottom - top)
    lx0 = x0 + inset * t
    lx1 = x1 - inset * t
    o.append(path(f"M{f(lx0)},{f(lt)} L{x0 + inset},{bottom} L{x1 - inset},{bottom} L{f(lx1)},{f(lt)} Z",
                  D.lin([(0, tint(liquid, 0.25)), (0.6, liquid), (1, shade(liquid, 0.2))], 0, 0, 1, 0), None))
    o.append(E((lx0 + lx1) / 2, lt, (lx1 - lx0) / 2, 1.6, tint(liquid, 0.35), None))
    o.append(path(glass, "#ffffff", INK3, 1.2, 'fill-opacity="0.18"'))
    o.append(path(f"M{x0 + 2.2},{top + 3} L{x0 + 4},{bottom - 3}", "none", "#ffffff", 1.6, 'opacity="0.7"'))
    o.append(E((x0 + x1) / 2, top, (x1 - x0) / 2, 1.8, "none", INK3, 1.1))
    return "".join(o)


def _slice(cx, cy, r, peel, pulp):
    o = [C(cx, cy, r, peel, INK3, 1.0), C(cx, cy, r - 1.4, pulp, None)]
    for a in range(0, 360, 60):
        o.append(line(cx, cy, cx + (r - 1.6) * math.cos(math.radians(a)), cy + (r - 1.6) * math.sin(math.radians(a)),
                      tint(pulp, 0.5), 0.7))
    return "".join(o)


def suco_laranja(D):
    o = [_glass(D, 13, 33, 12, 40, "#ffa31a", 0.82, straw="#ff4d6d")]
    o.append(_slice(13.5, 14, 5.2, "#ff8a00", "#ffc04d"))
    return "".join(o)


def limonada(D):
    o = [_glass(D, 13, 33, 12, 40, "#f2ec7a", 0.8, straw="#26a93a")]
    for (x, y) in [(18, 22), (25, 25), (21, 30)]:  # gelo
        o.append(f'<rect x="{x}" y="{y}" width="5.5" height="5" rx="1.3" fill="#ffffff" fill-opacity="0.55" stroke="#b9d7e8" '
                 f'stroke-width="0.8"/>')
    o.append(_slice(13.5, 14, 5.2, "#7ccf3a", "#e6f59a"))
    return "".join(o)


def vitamina_morango(D):
    o = [_glass(D, 13, 33, 12, 40, "#ff7aa8", 0.86, straw="#ffffff")]
    o.append(path("M14,12 C13,8 18,6.5 20,9 C21.5,6 27,6.5 27.5,10 C31,9.5 33,12 32,13.5 L14,13.5 Z",
                  D.lin([(0, "#ffffff"), (1, "#f4e9ee")]), INK3, 1.0))
    o.append(path("M11,15 C8,12 9,7.5 13,7.5 C17,7.5 18,12 15,15 C13.8,16.2 12.2,16.2 11,15 Z", "#ff3b5c", INK3, 1.0))
    o.append(path("M10.5,8 L13,6 L15.5,8 L13,9 Z", "#3fae3a", INK3, 0.8))
    for (x, y) in [(11.5, 11), (14, 12.5), (13, 9.8)]:
        o.append(E(x, y, 0.5, 0.7, "#ffe08a", None))
    return "".join(o)


DRINK_ART = {"expresso": expresso, "cappuccino": cappuccino, "chocolate": chocolate_quente,
             "laranja": suco_laranja, "limonada": limonada, "morango": vitamina_morango}


def drink(D, kind, cx, cy, size=48):
    """Ícone de bebida com centro em (cx, cy) e largura size (mesma caixa dos pratos)."""
    s = size / 48.0
    return g(DRINK_ART[kind](D), f"translate({f(cx - 24 * s)},{f(cy - 26 * s)}) scale({f(s)})")


# --- Máquinas ---------------------------------------------------------------------------

MACHINE_INSET = 0.08
MACHINE_SIZE = 0.84
CABINET_HEIGHT = 24


def _cabinet(D, iso, x, y, front, body):
    """Armarinho de base das máquinas (madeira ou laca), com duas portinhas na frente."""
    k = K(iso)
    bx, by, w, d, h = x + MACHINE_INSET, y + MACHINE_INSET, MACHINE_SIZE, MACHINE_SIZE, CABINET_HEIGHT * k
    o = [soft_shadow(D, iso, x + 0.5, y + 0.5, 0.5, opacity=0.3), box3(D, iso, bx, by, w, d, h, body, top="#f4f1ea")]
    if front is not None:
        q = lambda u0, u1, v0, v1: iso.quad(front, bx, by, w, d, 0, h, u0, u1, v0, v1)
        for (u0, u1) in ((0.08, 0.48), (0.52, 0.92)):
            o.append(P(q(u0, u1, 0.14, 0.86), D.lin([(0, tint(body, 0.25)), (1, shade(body, 0.12))]), INK3, 0.8))
        for u in (0.42, 0.58):
            px, py = iso.face_center(front, bx, by, w, d, 0, h, u, 0.5)
            o.append(C(px, py, 1.5 * k, CHROME, INK3, 0.6))
    return "".join(o), (bx, by, w, d, h)


def coffee_machine(D, iso, x, y, front="R"):
    """Máquina de expresso cromada, com faixa vermelha, manômetro, dois bicos e xícaras em cima."""
    k = K(iso)
    o, (bx, by, w, d, h0) = _cabinet(D, iso, x, y, front, WOOD_M)
    mx, my, mw, md, mh = bx + 0.1, by + 0.16, w - 0.2, d - 0.3, 30 * k
    o += box3(D, iso, mx, my, mw, md, mh, CHROME, z=h0, top="#e9eef3", gloss=True)
    o += box3(D, iso, mx, my, mw, md, 5 * k, "#e0303a", z=h0 + mh - 5 * k, faces="LR", bevel=False)
    # xícaras emborcadas em cima, esquentando
    for (u, v) in ((0.3, 0.35), (0.62, 0.35), (0.46, 0.68)):
        o += cyl3(D, iso, mx + mw * u, my + md * v, 0.075, h0 + mh, h0 + mh + 7 * k, "#ffffff", top="#f1ece4", sw=0.8)
    if front is not None:
        q = lambda u0, u1, v0, v1: iso.quad(front, mx, my, mw, md, h0, mh, u0, u1, v0, v1)
        o += P(q(0.1, 0.9, 0.0, 0.08), "#3a3c46", INK3, 0.8)          # bandeja de pingos
        gx, gy = iso.face_center(front, mx, my, mw, md, h0, mh, 0.5, 0.7)
        o += C(gx, gy, 4.2 * k, "#ffffff", INK3, 0.9) + line(gx, gy, gx + 2.4 * k, gy - 1.6 * k, "#e0303a", 1.0)
        for u in (0.28, 0.72):                                          # bicos com a xícara embaixo
            px, py = iso.face_center(front, mx, my, mw, md, h0, mh, u, 0.42)
            o += path(f"M{f(px - 3.2 * k)},{f(py)} h{f(6.4 * k)} l{f(-1.2 * k)},{f(4 * k)} h{f(-4 * k)} Z", "#2a2230", INK3, 0.7)
            cx, cy = iso.face_center(front, mx, my, mw, md, h0, mh, u, 0.1)
            o += path(f"M{f(cx - 3 * k)},{f(cy - 5 * k)} h{f(6 * k)} l{f(-0.8 * k)},{f(5 * k)} h{f(-4.4 * k)} Z", "#ffffff", INK3, 0.7)
    return o


def juice_machine(D, iso, x, y, front="R"):
    """Dispensador de sucos: três tanques transparentes (laranja, limão e morango) com torneirinhas."""
    k = K(iso)
    o, (bx, by, w, d, h0) = _cabinet(D, iso, x, y, front, "#2ec4b6")
    base_h = 9 * k
    o += box3(D, iso, bx + 0.06, by + 0.12, w - 0.12, d - 0.24, base_h, "#ffffff", z=h0, top="#e9eef3")
    tank_z0 = h0 + base_h
    tank_z1 = tank_z0 + 26 * k
    colors = ("#ffa31a", "#f2ec7a", "#ff7aa8")
    cells = [(0.28, 0.5), (0.5, 0.5), (0.72, 0.5)] if front == "L" or front is None else [(0.5, 0.28), (0.5, 0.5), (0.5, 0.72)]
    for (u, v), color in zip(cells, colors):
        cx, cy = bx + w * u, by + d * v
        o += cyl3(D, iso, cx, cy, 0.1, tank_z0, tank_z0 + 18 * k, color, top=tint(color, 0.3), sw=0.8)
        o += cyl3(D, iso, cx, cy, 0.1, tank_z0 + 18 * k, tank_z1, "#e9f4fb", top="#ffffff", sw=0.8)
        o += cyl3(D, iso, cx, cy, 0.105, tank_z1, tank_z1 + 3 * k, "#2ec4b6", sw=0.8)
    if front is not None:
        for u in (0.25, 0.5, 0.75):
            px, py = iso.face_center(front, bx + 0.06, by + 0.12, w - 0.12, d - 0.24, h0, base_h, u, 0.55)
            o += f'<rect x="{f(px - 1.6 * k)}" y="{f(py - 1.2 * k)}" width="{f(3.2 * k)}" height="{f(3.6 * k)}" rx="0.8" fill="#3a3c46" stroke="{INK3}" stroke-width="0.6"/>'
    return o


# Máquinas por id do móvel no jogo.
MACHINES = {"machine_coffee": coffee_machine, "machine_juice": juice_machine}
