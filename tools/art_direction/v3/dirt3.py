"""Chão sujo (DT-068): poça de café derramado com respingos e migalhas, desenhada no losango do piso."""
import math

from core3 import *  # noqa: F401,F403

VARIANTS = 3


def _blob(iso, cx, cy, r, rng, lobes=3):
    """Contorno arredondado e irregular de líquido no chão (em coordenadas de célula, de 0 a 1)."""
    phase, phase2 = rng.u(0, math.tau), rng.u(0, math.tau)
    points = []
    for i in range(36):
        a = i / 36 * math.tau
        rr = r * (0.84 + 0.12 * math.sin(a * lobes + phase) + 0.05 * math.sin(a * (lobes + 2) + phase2))
        points.append(iso.v(cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    return points


def floor_spot(D, iso, variant):
    """Mancha de café: poça marrom com brilho, gotinhas em volta e migalhas de bolo."""
    rng = Rng(71 + variant * 17)
    cx, cy = 0.5 + rng.u(-0.06, 0.06), 0.5 + rng.u(-0.06, 0.06)
    o = [P(_blob(iso, cx, cy, 0.24, rng), D.lin([(0, "#9a6434"), (1, "#5e3a1c")], 0, 0, 1, 1), "#4a2a14", 0.8,
           'opacity="0.88"')]
    o.append(P(_blob(iso, cx - 0.06, cy - 0.06, 0.07, rng, 2), "#ffffff", None, 0, 'opacity="0.32"'))
    for _ in range(3 + variant):
        a, d = rng.u(0, math.tau), rng.u(0.3, 0.38)
        o.append(P(_blob(iso, cx + math.cos(a) * d, cy + math.sin(a) * d, rng.u(0.025, 0.045), rng, 3),
                   "#74471f", "#4a2a14", 0.5, 'opacity="0.88"'))
    for _ in range(4):
        px, py = iso.v(rng.u(0.15, 0.85), rng.u(0.15, 0.85))
        o.append(E(px, py, 1.8, 1.1, "#e8c48a", "#8a5a2e", 0.5))
    return "".join(o)
