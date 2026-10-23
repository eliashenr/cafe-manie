"""Evento de Halloween (DT-063): o Caldeirão da Bruxa (um fogão de evento, com as medidas do fogão comum para a panela
e o forno aceso caírem no lugar), a Abóbora Gigante (enfeite de prêmio) e o retrato da Bruxa Morgana, que conta a
historinha do evento."""
from core3 import *
from furniture3 import K, stove, STOVE_INSET, STOVE_SIZE, STOVE_HEIGHT
from hud3 import portrait, medallion

CAULDRON = dict(enamel="#4a2a6a", top_color="#ff8a1a", panel=("#ffd29a", "#ff8a1a", "#8a3a0a"), knob="#7ee05a",
                door=("#7a4aa8", "#2a1440"), handle="#ff8a1a")


def _pumpkin(D, sx, sy, r, k, face=True):
    o = []
    for dx, rx in [(-0.55, 0.55), (0.55, 0.55), (0.0, 0.6)]:
        o.append(E(sx + dx * r, sy, rx * r, r * 0.85, D.lin([(0, "#ffb04a"), (1, "#e0601a")], 0, 0, 1, 0), INK3, 1.0))
    o.append(path(f"M{f(sx)},{f(sy - r * 0.8)} q{f(1 * k)},{f(-5 * k)} {f(4 * k)},{f(-6 * k)}", "none", "#3a6a2a", 2.2 * k))
    if face:
        o.append(P([(sx - r * 0.45, sy - r * 0.15), (sx - r * 0.2, sy - r * 0.45), (sx - r * 0.05, sy - r * 0.15)], "#3a1a0a", None))
        o.append(P([(sx + r * 0.45, sy - r * 0.15), (sx + r * 0.2, sy - r * 0.45), (sx + r * 0.05, sy - r * 0.15)], "#3a1a0a", None))
        o.append(path(f"M{f(sx - r * 0.5)},{f(sy + r * 0.2)} q{f(r * 0.5)},{f(r * 0.45)} {f(r)},0 l{f(-r * 0.2)},{f(r * 0.1)} "
                      f"l{f(-r * 0.15)},{f(-r * 0.12)} l{f(-r * 0.15)},{f(r * 0.12)} l{f(-r * 0.15)},{f(-r * 0.12)} Z", "#3a1a0a", None))
        o.append(C(sx, sy - r * 0.1, r * 0.25, "#ffe08a", None, extra='opacity="0.35"'))
    return "".join(o)


def cauldron_stove(D, iso, x, y, front):
    """Caldeirão da Bruxa: fogão roxo e laranja com uma abóbora e um morcego no canto de trás."""
    k = K(iso)
    bx, by = x + STOVE_INSET, y + STOVE_INSET
    h = STOVE_HEIGHT * k
    o = [stove(D, iso, x, y, front, **CAULDRON)]
    sx, sy = iso.v(bx + 0.14, by + 0.14, h)
    o.append(_pumpkin(D, sx, sy - 6 * k, 8 * k, k))
    bx2, by2 = iso.v(bx + STOVE_SIZE - 0.1, by + 0.1, h + 34 * k)
    o.append(path(f"M{f(bx2 - 12 * k)},{f(by2)} q{f(4 * k)},{f(-6 * k)} {f(8 * k)},{f(-1 * k)} q{f(2 * k)},{f(-3 * k)} {f(4 * k)},0 "
                  f"q{f(2 * k)},{f(-3 * k)} {f(4 * k)},0 q{f(4 * k)},{f(-5 * k)} {f(8 * k)},{f(1 * k)} q{f(-6 * k)},{f(1 * k)} {f(-12 * k)},{f(6 * k)} "
                  f"q{f(-6 * k)},{f(-5 * k)} {f(-12 * k)},{f(-6 * k)} Z", "#2a1440", INK3, 0.8))
    return "".join(o)


def giant_pumpkin(D, iso, x, y):
    """Abóbora Gigante: uma abóbora de Halloween acesa por dentro, com folhas e uma vela."""
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.38, opacity=0.3)]
    o.append(C(sx, sy - 22 * k, 34 * k, D.rad([(0, "#ffe08a", 0.5), (1, "#ffe08a", 0.0)]), None))
    o.append(_pumpkin(D, sx, sy - 22 * k, 26 * k, k))
    for side in (-1, 1):
        o.append(E(sx + side * 20 * k, sy - 4 * k, 9 * k, 3.6 * k, "#3fae3a", INK3, 0.8,
                   extra=f'transform="rotate({side * 20} {f(sx + side * 20 * k)} {f(sy - 4 * k)})"'))
    return "".join(o)


def witch_hat(D, scale=1.0):
    s = scale
    o = [E(0, -30 * s, 40 * s, 9 * s, "#2a1440", INK3, 1.6)]
    o.append(path(f"M{-22 * s},{-34 * s} C{-16 * s},{-60 * s} {-4 * s},{-82 * s} {18 * s},{-92 * s} C{8 * s},{-74 * s} {14 * s},{-56 * s} {22 * s},{-34 * s} Z",
                  D.lin([(0, "#6a3a9a"), (1, "#2a1440")], 0, 0, 1, 0), INK3, 1.6))
    o.append(path(f"M{-21 * s},{-38 * s} Q0,{-44 * s} {21 * s},{-38 * s} L{21 * s},{-32 * s} Q0,{-38 * s} {-21 * s},{-32 * s} Z", "#ff8a1a", INK3, 1.0))
    o.append(C(16 * s, -88 * s, 3.4 * s, "#ffd23f", INK3, 0.8))
    return "".join(o)


def witch_portrait(D):
    """A Bruxa Morgana: retrato do jeito dos chefs do HUD, com chapéu de bruxa e cabelo ruivo."""
    spec = dict(skin="clara", hair=("longo", "ruivo"), lash=True, freckles=True, expr="feliz")
    return portrait(D, spec) + witch_hat(D)


# id do móvel no jogo -> desenho
FURNITURE = {"witch_cauldron": cauldron_stove, "giant_pumpkin": giant_pumpkin}


def medallion_event(D):
    """Medalhão do evento no HUD: uma abóbora de Halloween acesa."""
    return medallion(D, 32, 32, _pumpkin(D, 32, 38, 15, 1.0), "#ff8a1a")
