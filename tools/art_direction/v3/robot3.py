"""Robô Garçom (DT-082): o toque futurista de Nova York.

Desenhado no mesmo sistema de coordenadas do person() de people3 (pés em (0, 0), cabeça perto de -116, olhando
para a direita), para usar as mesmas caixas e a mesma bandeja: o prato do jogo cai no mesmo lugar (TRAY_FOOD).
Em vez de pernas, uma base que flutua com o jato ciano; no andar, o corpo balança um pouco e os braços também.
"""
import math

from people3 import LINE, TRAY_EMPTY, WALK_FRAMES, walk_frame, walk_arm_angle
from core3 import *  # noqa: F401,F403

SHELL = ("#ffffff", "#f0f3f7", "#cdd6e1")   # casco branco, do claro ao sombreado
METAL = "#8a97a8"
NAVY = "#14284a"
VISOR = ("#0b1a33", "#1d3a66")
CYAN = "#31d7ff"
BOB = 1.6          # quanto o corpo sobe e desce no andar
TILT = 3.0         # graus de inclinação para a frente andando


def _shell(D, x0, x1, y0, y1):
    return D.lin([(0, SHELL[0]), (0.55, SHELL[1]), (1, SHELL[2])], x0, y0, x1, y1)


def _glow(D, cx, cy, rx, ry, opacity=0.5):
    return E(cx, cy, rx, ry, D.rad([(0, CYAN, opacity), (1, CYAN, 0)]), None)


def _arm(D, s, angle):
    """Braço de tubo, do ombro à mão redonda; gira em torno do ombro."""
    sx = s * 13.4
    o = path(f"M{f(sx - 2.6)},-56 C{f(sx - 2.8)},-48 {f(sx + s * 1.5 - 2.6)},-40 {f(sx + s * 2 - 2.4)},-35 "
             f"L{f(sx + s * 2 + 2.4)},-35 C{f(sx + s * 1.5 + 2.6)},-40 {f(sx + 2.8)},-48 {f(sx + 2.6)},-56 Z",
             _shell(D, sx - 3, sx + 3, -56, -35), LINE, 1.1)
    o += C(sx + s * 2, -33, 3.6, METAL, LINE, 1.0)
    o += C(sx, -56, 3.4, METAL, LINE, 0.9)
    return g(o, f"rotate({f(angle)} {f(sx)} -56)")


def _tray_arm(D):
    """O braço da bandeja: o mesmo desenho do garçom (a mão e a bandeja no mesmo lugar)."""
    o = path("M12.8,-57.8 C19,-58.4 23.4,-55 23.8,-50.4 L28.2,-55.4 L32.4,-61.8 L28.8,-65.2 L20.6,-57.8 Z",
             _shell(D, 12, 32, -66, -50), LINE, 1.15)
    o += E(30.6, -63.4, 3.8, 4.1, METAL, LINE, 1.1)
    o += E(34.6, -67.4, 19, 5.6, D.lin([(0, "#ffffff"), (0.6, "#dfe6ee"), (1, "#aab6c4")]), LINE, 1.3)
    o += E(34.6, -68.4, 15.6, 3.6, "none", "#ffffff", 1.0, 'opacity="0.7"')
    return o


def _head(D, back):
    o = [path("M0,-96 L0,-104", "none", METAL, 1.6)]
    o.append(_glow(D, 0, -106, 6, 6, 0.6))
    o.append(C(0, -106, 2.4, CYAN, LINE, 0.8))
    for s in (-1, 1):  # "orelhas" de disco
        o.append(E(s * 15.6, -81, 3.2, 4.6, METAL, LINE, 1.0))
    o.append(path("M-15,-87 C-15,-93.4 -11,-96.6 -6,-96.6 L6,-96.6 C11,-96.6 15,-93.4 15,-87 L15,-73 C15,-68.4 11.4,-65.6 7,-65.6 "
                  "L-7,-65.6 C-11.4,-65.6 -15,-68.4 -15,-73 Z", _shell(D, -15, 15, -97, -65), LINE, 1.3))
    if back:
        for y in (-84, -80, -76):  # grade de ventilação atrás
            o.append(path(f"M-7,{y} L7,{y}", "none", METAL, 1.1))
        return "".join(o)
    o.append(path("M-12,-86 C-12,-89 -10,-90.4 -7.6,-90.4 L7.6,-90.4 C10,-90.4 12,-89 12,-86 L12,-76.6 C12,-74 10,-72.4 7.6,-72.4 "
                  "L-7.6,-72.4 C-10,-72.4 -12,-74 -12,-76.6 Z", D.lin([(0, VISOR[1]), (1, VISOR[0])], 0, -90, 0, -72), LINE, 1.1))
    o.append(_glow(D, 0, -81.4, 13, 7, 0.35))
    for ex in (-4.6, 5.4):  # olhos de LED
        o.append(f'<rect x="{f(ex - 2.1)}" y="-84.6" width="4.2" height="6.2" rx="2.1" fill="{CYAN}"/>')
    o.append(path("M-3,-76.4 Q0.6,-74.4 4,-76.4", "none", CYAN, 1.2))
    o.append(path("M-10,-88.6 L-4,-88.6", "none", "#ffffff", 1.1, 'opacity="0.35"'))
    return "".join(o)


def _torso(D, back):
    o = [path("M-4,-66 L4,-66 L4,-61 L-4,-61 Z", METAL, LINE, 1.0)]
    o.append(path("M-13,-56 C-13,-61 -9,-62.6 -4,-62.6 L4,-62.6 C9,-62.6 13,-61 13,-56 L12,-24 C12,-19 8,-16.6 3,-16.6 "
                  "L-3,-16.6 C-8,-16.6 -12,-19 -12,-24 Z", _shell(D, -13, 13, -62, -17), LINE, 1.35))
    if back:
        o.append(path("M-6,-52 L6,-52 L6,-36 L-6,-36 Z", "none", METAL, 1.0))
        return "".join(o)
    # colete azul-marinho de garçom, com a gravata-borboleta e a luz do peito
    o.append(path("M-12.4,-50 L-3.2,-61.6 L0,-50 L3.2,-61.6 L12.4,-50 L11.8,-27 C9,-24.6 -9,-24.6 -11.8,-27 Z",
                  D.lin([(0, "#1f3a66"), (1, NAVY)], 0, -60, 0, -25), LINE, 1.1))
    o.append(path("M0,-50 L0,-27", "none", "#0a1630", 0.9))
    for y in (-44, -37):
        o.append(C(1.6, y, 0.9, "#d9e1ea", None))
    o.append(path("M0,-59.6 L-5.6,-62.4 L-5.6,-56.6 Z M0,-59.6 L5.6,-62.4 L5.6,-56.6 Z", "#1d1d24", LINE, 0.8))
    o.append(C(0, -59.6, 1.4, "#1d1d24", None))
    o.append(_glow(D, -6.4, -46, 4.6, 4.6, 0.55))
    o.append(C(-6.4, -46, 1.8, CYAN, None))
    return "".join(o)


def _base(D):
    o = [path("M-11.4,-17 L11.4,-17 L8.4,-6 C5,-4 -5,-4 -8.4,-6 Z", _shell(D, -11, 11, -17, -4), LINE, 1.2)]
    o.append(path("M-9.6,-11 L9.6,-11", "none", CYAN, 1.2, 'opacity="0.8"'))
    o.append(_glow(D, 0, -2.6, 11, 3.6, 0.7))
    o.append(E(0, -3.4, 6.4, 1.8, CYAN, None, extra='opacity="0.9"'))
    return "".join(o)


def robot_waiter(D, x, y, s=1.0, facing=1, pose="em_pe", back=False, tray=None):
    """Robô Garçom nos mesmos quadros do garçom: parado (em_pe) e os passos do andar (passo_N)."""
    frame = walk_frame(pose)
    bob = BOB * math.sin(2 * math.pi * frame / WALK_FRAMES) if frame is not None else 0.0
    tilt = TILT if frame is not None else 0.0
    o = [E(0, 0.6, 15, 4.6, "#1a0f18", None, extra='opacity="0.2"')]
    body = [_base(D)]
    for side in (-1, 1):
        if tray and side == 1:
            continue
        angle = walk_arm_angle(frame, side) if frame is not None else 0.0
        if side == -1 or not back:
            body.append(_arm(D, side, angle))
    body.append(_torso(D, back))
    body.append(_head(D, back))
    if back and not tray:
        body.append(_arm(D, 1, walk_arm_angle(frame, 1) if frame is not None else 0.0))
    if tray:
        body.append(_tray_arm(D))
        if tray != TRAY_EMPTY:
            from food3 import food
            body.append(food(D, tray, 34.6, -77, 30))
    o.append(g("".join(body), f"translate(0,{f(-bob - 2)}) rotate({f(tilt)} 0 -8)"))
    return g("".join(o), f"translate({f(x)},{f(y)}) scale({f(s * facing)},{f(s)})")
