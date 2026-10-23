"""Atrações e palco (DT-066): a máquina de garra e o jogo de argolas (1 piso, o mesmo desenho nas 4 rotações), o palco
(2x2, com caixas de som e o pedestal do microfone) e o ícone da nota musical dos shows."""
from core3 import *


def _k(iso):
    return iso.W / 96.0


def claw_machine(D, iso, x, y):
    """Máquina de garra: gabinete vermelho com vitrine cheia de bichinhos de pelúcia e a garra pendurada."""
    k = _k(iso)
    cx, cy = x + 0.5, y + 0.5
    o = [soft_shadow(D, iso, cx, cy, 0.34, opacity=0.3)]
    o.append(box3(D, iso, cx - 0.3, cy - 0.3, 0.6, 0.6, 26 * k, "#e0303a", top="#ff5a5f"))
    o.append(box3(D, iso, cx - 0.28, cy - 0.28, 0.56, 0.56, 40 * k, "#bfe6ff", z=26 * k, gloss=True))
    r = Rng(11)
    for _ in range(7):
        px, py = iso.v(cx + r.u(-0.2, 0.2), cy + r.u(-0.2, 0.2), (30 + r.u(0, 8)) * k)
        color = ["#ffd23f", "#ff8ab8", "#7ec8ff", "#a8e07a"][int(r.u(0, 3.99))]
        o.append(C(px, py, 4.4 * k, color, INK3, 0.6) + C(px - 2 * k, py - 3.6 * k, 1.6 * k, color, INK3, 0.5)
                 + C(px + 2 * k, py - 3.6 * k, 1.6 * k, color, INK3, 0.5))
    tx, ty = iso.v(cx, cy, 66 * k)
    o.append(line(tx, ty, tx, ty + 14 * k, "#8f9aa7", 1.4 * k))
    o.append(path(f"M{f(tx - 5 * k)},{f(ty + 20 * k)} L{f(tx)},{f(ty + 14 * k)} L{f(tx + 5 * k)},{f(ty + 20 * k)}", "none", "#c9d4e0", 2 * k))
    o.append(box3(D, iso, cx - 0.31, cy - 0.31, 0.62, 0.62, 8 * k, "#ffd23f", z=66 * k, top="#ffe680"))
    return "".join(o)


def ring_toss(D, iso, x, y):
    """Jogo de argolas: bancada listrada com três garrafas e argolas coloridas."""
    k = _k(iso)
    cx, cy = x + 0.5, y + 0.5
    o = [soft_shadow(D, iso, cx, cy, 0.36, opacity=0.28)]
    o.append(box3(D, iso, cx - 0.34, cy - 0.3, 0.68, 0.6, 22 * k, "#2ea3ff", top="#ffffff"))
    for i in range(4):
        u0, u1 = i / 4, (i + 0.5) / 4
        q = [iso.v(cx - 0.34 + 0.68 * u0, cy + 0.3, 22 * k), iso.v(cx - 0.34 + 0.68 * u1, cy + 0.3, 22 * k),
             iso.v(cx - 0.34 + 0.68 * u1, cy + 0.3, 0), iso.v(cx - 0.34 + 0.68 * u0, cy + 0.3, 0)]
        o.append(P(q, "#ffffff", None, 'opacity="0.55"'))
    for i, (dx, dy) in enumerate([(-0.16, -0.06), (0.0, 0.06), (0.16, -0.04)]):
        bx, by = iso.v(cx + dx, cy + dy, 22 * k)
        o.append(path(f"M{f(bx - 3.4 * k)},{f(by)} L{f(bx - 3.4 * k)},{f(by - 12 * k)} Q{f(bx - 3.4 * k)},{f(by - 16 * k)} {f(bx - 1.2 * k)},{f(by - 18 * k)} "
                      f"L{f(bx - 1.2 * k)},{f(by - 23 * k)} L{f(bx + 1.2 * k)},{f(by - 23 * k)} L{f(bx + 1.2 * k)},{f(by - 18 * k)} "
                      f"Q{f(bx + 3.4 * k)},{f(by - 16 * k)} {f(bx + 3.4 * k)},{f(by - 12 * k)} L{f(bx + 3.4 * k)},{f(by)} Z",
                      ["#3fae3a", "#8a4fd1", "#e0303a"][i], INK3, 0.8))
    for (dx, dy, color) in [(-0.04, 0.02, "#ffd23f"), (0.2, 0.12, "#ff5a5f"), (0.1, -0.14, "#7ec8ff")]:
        rx, ry = iso.v(cx + dx, cy + dy, 22 * k)
        o.append(E(rx, ry - 6 * k, 6 * k, 2.4 * k, "none", color, 2 * k))
    return "".join(o)


def stage(D, iso, x, y):
    """Palco 2x2: tablado de madeira com borda dourada, duas caixas de som, o pedestal do microfone e um holofote."""
    k = _k(iso)
    o = [soft_shadow(D, iso, x + 1, y + 1, 1.0, opacity=0.25)]
    o.append(box3(D, iso, x + 0.05, y + 0.05, 1.9, 1.9, 14 * k, "#8a5a3a", top="#c98a4b"))
    for i in range(1, 5):
        a = iso.v(x + 0.05 + 0.38 * i, y + 0.05, 14 * k)
        b = iso.v(x + 0.05 + 0.38 * i, y + 1.95, 14 * k)
        o.append(line(a[0], a[1], b[0], b[1], "#a8703a", 1.0))
    o.append(P([iso.v(x + 0.05, y + 1.95, 14 * k), iso.v(x + 1.95, y + 1.95, 14 * k), iso.v(x + 1.95, y + 1.95, 10 * k),
                iso.v(x + 0.05, y + 1.95, 10 * k)], "#ffd23f", INK3, 0.6))
    for (sx, sy) in [(x + 0.15, y + 0.15), (x + 1.45, y + 0.15)]:
        o.append(box3(D, iso, sx, sy, 0.4, 0.34, 40 * k, "#2a2c34", z=14 * k, top="#3a3c46"))
    for (sx, sy) in [(x + 0.35, y + 0.49), (x + 1.65, y + 0.49)]:
        px, py = iso.v(sx, sy, 14 * k + 20 * k)
        o.append(C(px, py, 7 * k, "#4a4c56", INK3, 0.8) + C(px, py, 3.4 * k, "#15151b", None))
        px, py = iso.v(sx, sy, 14 * k + 40 * k * 0.72)
        o.append(C(px, py, 4 * k, "#4a4c56", INK3, 0.7))
    mx, my = iso.v(x + 1.0, y + 1.2, 14 * k)
    o.append(line(mx, my, mx, my - 34 * k, "#3a3c46", 2 * k) + E(mx, my, 6 * k, 2.4 * k, "#3a3c46", INK3, 0.6))
    o.append(E(mx, my - 36 * k, 2.6 * k, 3.6 * k, "#8f9aa7", INK3, 0.8))
    return "".join(o)


def note_icon(D):
    """Nota musical colorida (ícone 64x64), para as notas que sobem nos shows."""
    o = [path("M24,46 C16,46 14,40 20,37 C24,35 28,36 30,38 L30,14 L48,10 L48,40 C48,46 38,47 36,42 C34,37 42,34 46,36 L46,16 L32,19 L32,42 "
              "C32,46 28,46 24,46 Z", D.lin([(0, "#ff8ab8"), (1, "#b06bff")]), "#33283a", 2.0)]
    return "".join(o)


ATTRACTIONS = {"claw_machine": claw_machine, "ring_toss": ring_toss}
