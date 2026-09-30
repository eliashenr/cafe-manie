"""Base da arte v2: cores, gradientes, projeção isométrica e formas com volume."""
import math
import hashlib

INK = "#3a2217"
SQ2 = math.sqrt(2)
SHADOW = "#24120a"


def f(v):
    s = f"{v:.2f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "", "-") else s


def pts(p):
    return " ".join(f"{f(x)},{f(y)}" for x, y in p)


def _rgb(c):
    c = c.lstrip("#")
    return [int(c[i:i + 2], 16) for i in (0, 2, 4)]


def _hex(r):
    return "#%02x%02x%02x" % tuple(max(0, min(255, int(round(v)))) for v in r)


def mix(a, b, t):
    A, B = _rgb(a), _rgb(b)
    return _hex([A[i] + (B[i] - A[i]) * t for i in range(3)])


def light(c, t):
    return mix(c, "#ffffff", t)


def dark(c, t):
    return mix(c, SHADOW, t)


class Defs:
    """Gradientes e padrões usados por um desenho (ids estáveis pelo conteúdo)."""

    def __init__(self):
        self.items = {}

    def _key(self, *parts):
        return "a" + hashlib.md5(repr(parts).encode()).hexdigest()[:10]

    @staticmethod
    def _stops(stops):
        out = []
        for s in stops:
            o, c = s[0], s[1]
            op = "" if len(s) < 3 else ' stop-opacity="' + f(s[2]) + '"'
            out.append('<stop offset="' + f(o) + '" stop-color="' + c + '"' + op + "/>")
        return "".join(out)

    def lin(self, stops, x1=0, y1=0, x2=0, y2=1):
        k = self._key("lin", tuple(map(tuple, stops)), x1, y1, x2, y2)
        if k not in self.items:
            self.items[k] = (f'<linearGradient id="{k}" x1="{f(x1)}" y1="{f(y1)}" x2="{f(x2)}" y2="{f(y2)}">'
                             + self._stops(stops) + "</linearGradient>")
        return f"url(#{k})"

    def rad(self, stops, cx=0.5, cy=0.5, r=0.5, fx=None, fy=None):
        fx = cx if fx is None else fx
        fy = cy if fy is None else fy
        k = self._key("rad", tuple(map(tuple, stops)), cx, cy, r, fx, fy)
        if k not in self.items:
            self.items[k] = (f'<radialGradient id="{k}" cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fx="{f(fx)}" fy="{f(fy)}">'
                             + self._stops(stops) + "</radialGradient>")
        return f"url(#{k})"

    def raw(self, key, markup):
        self.items.setdefault(key, markup)
        return f"url(#{key})"

    def render(self):
        return "<defs>" + "".join(self.items.values()) + "</defs>"


# --- Formas ------------------------------------------------------------------------

def P(points, fill, stroke=INK, sw=1.0, extra=""):
    s = f' stroke="{stroke}" stroke-width="{f(sw)}" stroke-linejoin="round"' if stroke else ""
    return f'<polygon points="{pts(points)}" fill="{fill}"{s}{(" " + extra) if extra else ""}/>'


def E(cx, cy, rx, ry, fill, stroke=INK, sw=1.0, extra=""):
    s = f' stroke="{stroke}" stroke-width="{f(sw)}"' if stroke else ""
    return f'<ellipse cx="{f(cx)}" cy="{f(cy)}" rx="{f(rx)}" ry="{f(ry)}" fill="{fill}"{s}{(" " + extra) if extra else ""}/>'


def C(cx, cy, r, fill, stroke=INK, sw=1.0, extra=""):
    return E(cx, cy, r, r, fill, stroke, sw, extra)


def path(d, fill, stroke=INK, sw=1.0, extra=""):
    s = f' stroke="{stroke}" stroke-width="{f(sw)}" stroke-linejoin="round" stroke-linecap="round"' if stroke else ""
    return f'<path d="{d}" fill="{fill}"{s}{(" " + extra) if extra else ""}/>'


def line(x1, y1, x2, y2, color, sw=1.0, extra=""):
    return (f'<line x1="{f(x1)}" y1="{f(y1)}" x2="{f(x2)}" y2="{f(y2)}" stroke="{color}" stroke-width="{f(sw)}" '
            f'stroke-linecap="round"{(" " + extra) if extra else ""}/>')


def g(content, transform=None, extra=""):
    t = f' transform="{transform}"' if transform else ""
    return f"<g{t}{(' ' + extra) if extra else ''}>{content}</g>"


class Iso:
    """Projeção 2:1. Células em (x, y); z em pixels para cima."""

    def __init__(self, ox=0.0, oy=0.0, W=96.0, H=48.0):
        self.ox, self.oy, self.W, self.H = ox, oy, W, H

    def v(self, x, y, z=0.0):
        return (self.ox + (x - y) * self.W / 2, self.oy + (x + y) * self.H / 2 - z)

    def ell(self, cx, cy, z, r):
        sx, sy = self.v(cx, cy, z)
        return sx, sy, r * self.W / SQ2, r * self.H / SQ2

    def quad(self, face, x, y, w, d, z, h, u0, u1, v0, v1):
        """Retângulo numa face de uma caixa. face 'R' = plano x+w; 'L' = plano y+d.
        u vai da esquerda para a direita na tela; v de baixo para cima."""
        def at(u, v):
            if face == "R":
                return self.v(x + w, y + d - u * d, z + v * h)
            return self.v(x + u * w, y + d, z + v * h)
        return [at(u0, v0), at(u1, v0), at(u1, v1), at(u0, v1)]

    def face_center(self, face, x, y, w, d, z, h, u, v):
        return self.quad(face, x, y, w, d, z, h, u, u, v, v)[0]


def box(D, iso, x, y, w, d, h, color, z=0.0, top=None, sw=1.0, faces="LRT", bevel=True):
    top = top or light(color, 0.1)
    T = [iso.v(x, y, z + h), iso.v(x + w, y, z + h), iso.v(x + w, y + d, z + h), iso.v(x, y + d, z + h)]
    L = [iso.v(x, y + d, z), iso.v(x + w, y + d, z), iso.v(x + w, y + d, z + h), iso.v(x, y + d, z + h)]
    R = [iso.v(x + w, y + d, z), iso.v(x + w, y, z), iso.v(x + w, y, z + h), iso.v(x + w, y + d, z + h)]
    out = []
    if "L" in faces:
        out.append(P(L, D.lin([(0, dark(color, 0.04)), (1, dark(color, 0.2))]), sw=sw))
    if "R" in faces:
        out.append(P(R, D.lin([(0, dark(color, 0.22)), (1, dark(color, 0.38))]), sw=sw))
    if "T" in faces:
        out.append(P(T, D.lin([(0, light(top, 0.22)), (1, top)], 0, 0, 1, 1), sw=sw))
        if bevel and w * d > 0.01 and h > 2:
            a, b, c = T[3], T[2], T[1]
            out.append(f'<polyline points="{pts([(a[0]+1.2, a[1]+0.2), (b[0], b[1]-1.0), (c[0]-1.2, c[1]+0.2)])}" fill="none" '
                       f'stroke="{light(top, 0.55)}" stroke-width="0.9" stroke-linecap="round" opacity="0.8"/>')
    return "".join(out)


def cylinder(D, iso, cx, cy, r, z0, z1, color, top=None, sw=1.0, cap=True):
    sx, s0, rx, ry = iso.ell(cx, cy, z0, r)
    _, s1, _, _ = iso.ell(cx, cy, z1, r)
    gr = D.lin([(0, dark(color, 0.1)), (0.28, light(color, 0.22)), (0.62, color), (1, dark(color, 0.4))], 0, 0, 1, 0)
    d = f"M{f(sx-rx)},{f(s1)} L{f(sx-rx)},{f(s0)} A{f(rx)},{f(ry)} 0 0 0 {f(sx+rx)},{f(s0)} L{f(sx+rx)},{f(s1)} Z"
    out = [path(d, gr, sw=sw)]
    if cap:
        t = top or light(color, 0.08)
        out.append(E(sx, s1, rx, ry, D.lin([(0, light(t, 0.3)), (1, t)], 0, 0, 1, 1), sw=sw))
    return "".join(out)


def shadow(iso, cx, cy, r, opacity=0.22):
    sx, sy, rx, ry = iso.ell(cx, cy, 0, r)
    return E(sx, sy, rx, ry, "#1c0d05", None, extra=f'opacity="{opacity}"')


def wall_matrix(p, side):
    """Transforma um desenho plano (x para a direita, y para baixo, em px) na parede.
    side 'R' = parede da direita (desce para a direita); 'L' = parede da esquerda (sobe para a direita)."""
    k = 0.5 if side == "R" else -0.5
    return f"matrix(1,{k},0,1,{f(p[0])},{f(p[1])})"


def floor_matrix(iso, x, y, scale_cells=1.0):
    """Desenho plano (u, v em unidades de célula) deitado no chão isométrico."""
    p = iso.v(x, y)
    a, b = iso.W / 2 * scale_cells, iso.H / 2 * scale_cells
    return f"matrix({f(a)},{f(b)},{f(-a)},{f(b)},{f(p[0])},{f(p[1])})"


class Rng:
    """Aleatório determinístico (mesma arte a cada geração)."""

    def __init__(self, seed=7):
        self.s = seed

    def r(self):
        self.s = (self.s * 1103515245 + 12345) & 0x7FFFFFFF
        return self.s / 0x7FFFFFFF

    def u(self, a, b):
        return a + (b - a) * self.r()
