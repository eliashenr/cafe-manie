"""Base da arte v3: reaproveita a base v2 e acrescenta gradientes em coordenadas locais e recortes."""
import os
import sys
import math

for _base in ("v2", "gen2"):
    _p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", _base)
    if os.path.isdir(_p):
        sys.path.insert(0, _p)
        break
from core import *  # noqa: F401,F403
from core import Defs as _Defs


import core as _core

INK3 = "#33283a"


def _fix(sw, extra):
    """Aceita a opacidade/atributos extras também na posição de 'sw' (chamadas curtas)."""
    if isinstance(sw, str):
        return 1.0, (sw + (" " + extra if extra else ""))
    return sw, extra


def P(points, fill, stroke=INK3, sw=1.0, extra=""):
    sw, extra = _fix(sw, extra)
    return _core.P(points, fill, stroke, sw, extra)


def E(cx, cy, rx, ry, fill, stroke=INK3, sw=1.0, extra=""):
    sw, extra = _fix(sw, extra)
    return _core.E(cx, cy, rx, ry, fill, stroke, sw, extra)


def C(cx, cy, r, fill, stroke=INK3, sw=1.0, extra=""):
    sw, extra = _fix(sw, extra)
    return _core.E(cx, cy, r, r, fill, stroke, sw, extra)


def path(d, fill, stroke=INK3, sw=1.0, extra=""):
    sw, extra = _fix(sw, extra)
    return _core.path(d, fill, stroke, sw, extra)


class Defs(_Defs):
    def lin_u(self, stops, x1, y1, x2, y2):
        """Gradiente em coordenadas do desenho (várias formas compartilham a mesma rampa, sem emendas)."""
        k = self._key("linu", tuple(map(tuple, stops)), x1, y1, x2, y2)
        if k not in self.items:
            self.items[k] = (f'<linearGradient id="{k}" gradientUnits="userSpaceOnUse" x1="{f(x1)}" y1="{f(y1)}" '
                             f'x2="{f(x2)}" y2="{f(y2)}">' + self._stops(stops) + "</linearGradient>")
        return f"url(#{k})"

    def rad_u(self, stops, cx, cy, r, fx=None, fy=None):
        fx = cx if fx is None else fx
        fy = cy if fy is None else fy
        k = self._key("radu", tuple(map(tuple, stops)), cx, cy, r, fx, fy)
        if k not in self.items:
            self.items[k] = (f'<radialGradient id="{k}" gradientUnits="userSpaceOnUse" cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" '
                             f'fx="{f(fx)}" fy="{f(fy)}">' + self._stops(stops) + "</radialGradient>")
        return f"url(#{k})"

    def clip(self, d):
        """Recorte por um caminho (coordenadas locais de quem usa)."""
        k = self._key("clip", d)
        if k not in self.items:
            self.items[k] = f'<clipPath id="{k}"><path d="{d}"/></clipPath>'
        return f"url(#{k})"

    def blur(self, std):
        k = self._key("blur", std)
        if k not in self.items:
            self.items[k] = (f'<filter id="{k}" x="-50%" y="-50%" width="200%" height="200%">'
                             f'<feGaussianBlur stdDeviation="{f(std)}"/></filter>')
        return f"url(#{k})"


def leaf(x, y, ang, length, width, bias=0.0):
    """Mecha/brilho afinado nas pontas, centrado em (x, y) e apontado no ângulo ang (graus)."""
    a = math.radians(ang)
    dx, dy = math.cos(a), math.sin(a)
    nx, ny = -dy, dx
    x0, y0 = x - dx * length / 2, y - dy * length / 2
    x1, y1 = x + dx * length / 2, y + dy * length / 2
    cx1, cy1 = x + dx * length * bias + nx * width, y + dy * length * bias + ny * width
    cx2, cy2 = x + dx * length * bias - nx * width * 0.35, y + dy * length * bias - ny * width * 0.35
    return (f"M{f(x0)},{f(y0)} Q{f(cx1)},{f(cy1)} {f(x1)},{f(y1)} Q{f(cx2)},{f(cy2)} {f(x0)},{f(y0)} Z")


def taper(p0, c, p1, w0, w1, n=12):
    """Traço afinado ao longo de uma curva quadrática p0 -> p1 (controle c), com largura w0 no início e w1 no fim."""
    up, down = [], []
    for i in range(n + 1):
        t = i / n
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t * t * p1[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t * t * p1[1]
        dx = 2 * (1 - t) * (c[0] - p0[0]) + 2 * t * (p1[0] - c[0])
        dy = 2 * (1 - t) * (c[1] - p0[1]) + 2 * t * (p1[1] - c[1])
        ln = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / ln, dx / ln
        w = (w0 + (w1 - w0) * t) / 2
        up.append((x + nx * w, y + ny * w))
        down.append((x - nx * w, y - ny * w))
    pts_ = up + down[::-1]
    return "M" + " L".join(f"{f(a)},{f(b)}" for a, b in pts_) + " Z"


# --- Cor e volume v3 (sombras que não 'sujam' a cor) ------------------------------------
import colorsys
from core import _rgb, _hex


def shade(c, t):
    """Escurece mantendo a saturação (em vez de misturar com marrom)."""
    r, g_, b = [v / 255 for v in _rgb(c)]
    h, l, s = colorsys.rgb_to_hls(r, g_, b)
    l = max(0.0, l * (1 - t))
    s = min(1.0, s * (1 + t * 0.4)) if s > 0.05 else s
    return _hex([v * 255 for v in colorsys.hls_to_rgb(h, l, s)])


def tint(c, t):
    r, g_, b = [v / 255 for v in _rgb(c)]
    h, l, s = colorsys.rgb_to_hls(r, g_, b)
    l = l + (1 - l) * t
    return _hex([v * 255 for v in colorsys.hls_to_rgb(h, l, s)])


def box3(D, iso, x, y, w, d, h, color, z=0.0, top=None, sw=1.0, faces="LRT", bevel=True, ink=INK3, gloss=False,
         left=None, right=None):
    """Caixa isométrica com luz de cima à esquerda: face esquerda clara, direita mais escura, tampo claro."""
    top = top or color
    T = [iso.v(x, y, z + h), iso.v(x + w, y, z + h), iso.v(x + w, y + d, z + h), iso.v(x, y + d, z + h)]
    L = [iso.v(x, y + d, z), iso.v(x + w, y + d, z), iso.v(x + w, y + d, z + h), iso.v(x, y + d, z + h)]
    R = [iso.v(x + w, y + d, z), iso.v(x + w, y, z), iso.v(x + w, y, z + h), iso.v(x + w, y + d, z + h)]
    out = []
    lc = left or color
    rc = right or color
    if "L" in faces and h > 0:
        out.append(P(L, D.lin([(0, tint(lc, 0.06)), (1, shade(lc, 0.1))]), ink, sw))
    if "R" in faces and h > 0:
        out.append(P(R, D.lin([(0, shade(rc, 0.16)), (1, shade(rc, 0.28))]), ink, sw))
    if "T" in faces:
        out.append(P(T, D.lin([(0, tint(top, 0.3)), (0.6, tint(top, 0.1)), (1, top)], 0, 0, 1, 1), ink, sw))
        if bevel and h > 1.5:
            a, b, c = T[3], T[2], T[1]
            out.append(f'<polyline points="{pts([(a[0]+1.4, a[1]), (b[0], b[1]-1.1), (c[0]-1.4, c[1])])}" fill="none" '
                       f'stroke="#ffffff" stroke-width="1.1" stroke-linecap="round" opacity="0.75"/>')
        if gloss:
            cx = (T[0][0] + T[2][0]) / 2
            cy = (T[0][1] + T[2][1]) / 2
            rx = abs(T[1][0] - T[3][0]) * 0.22
            ry = abs(T[2][1] - T[0][1]) * 0.16
            out.append(E(cx - rx * 0.35, cy - ry * 0.4, rx, ry, "#ffffff", None, extra='opacity="0.38"'))
    return "".join(out)


def cyl3(D, iso, cx, cy, r, z0, z1, color, top=None, sw=1.0, cap=True, ink=INK3, metal=False):
    sx, s0, rx, ry = iso.ell(cx, cy, z0, r)
    _, s1, _, _ = iso.ell(cx, cy, z1, r)
    if metal:
        gr = D.lin([(0, shade(color, 0.3)), (0.2, tint(color, 0.7)), (0.35, "#ffffff"), (0.55, color), (0.8, shade(color, 0.35)),
                    (1, shade(color, 0.15))], 0, 0, 1, 0)
    else:
        gr = D.lin([(0, shade(color, 0.08)), (0.25, tint(color, 0.3)), (0.6, color), (1, shade(color, 0.3))], 0, 0, 1, 0)
    d = f"M{f(sx-rx)},{f(s1)} L{f(sx-rx)},{f(s0)} A{f(rx)},{f(ry)} 0 0 0 {f(sx+rx)},{f(s0)} L{f(sx+rx)},{f(s1)} Z"
    out = [path(d, gr, ink, sw)]
    if cap:
        t = top or color
        out.append(E(sx, s1, rx, ry, D.lin([(0, tint(t, 0.4)), (1, t)], 0, 0, 1, 1), ink, sw))
    return "".join(out)


def soft_shadow(D, iso, cx, cy, rx_cells, ry_cells=None, opacity=0.28):
    """Sombra de contato difusa no chão."""
    ry_cells = rx_cells if ry_cells is None else ry_cells
    sx, sy = iso.v(cx, cy)
    rx = (rx_cells + ry_cells) / 2 * iso.W / SQ2
    ry = (rx_cells + ry_cells) / 2 * iso.H / SQ2
    grad = D.rad([(0, "#2a1c3a", opacity), (0.65, "#2a1c3a", opacity * 0.55), (1, "#2a1c3a", 0)])
    return E(sx, sy, rx * 1.15, ry * 1.15, grad, None)


def plane(iso, side, x, y, z=0.0):
    """Transforma um desenho plano (u para a direita, v para baixo, em px de tela) num plano vertical.
    side 'R': plano de y constante (desce para a direita), origem em (x, y, z).
    side 'L': plano de x constante (sobe para a direita), origem em (x, y, z) na ponta de baixo."""
    p = iso.v(x, y, z)
    k = 0.5 if side == "R" else -0.5
    return f"matrix(1,{k},0,1,{f(p[0])},{f(p[1])})"
