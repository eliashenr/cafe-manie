"""Móveis v3: cores vivas, cromado, vidro e verniz. Alturas em px para W=96 (escalam com iso.W)."""
from core3 import *
from food3 import food

CHROME = "#c9d3de"
WOOD_L = "#f0b56a"
WOOD_M = "#d88a45"
WOOD_D = "#a95f2b"


def K(iso):
    return iso.W / 96.0


# --- Assentos ----------------------------------------------------------------------------

def _rrect_plane(iso, side, x, y, z, width_px, height_px, fill, ink=INK3, sw=1.0, r=5):
    t = plane(iso, side, x, y, z)
    return f'<rect x="0" y="{f(-height_px)}" width="{f(width_px)}" height="{f(height_px)}" rx="{f(r)}" fill="{fill}" stroke="{ink}" stroke-width="{f(sw)}" transform="{t}"/>'


def chair(D, iso, x, y, facing="+x", color="#ff4d5e", legs=CHROME):
    """Cadeira de lanchonete: pés cromados, assento estofado e encosto arredondado.
    facing = para onde a pessoa sentada olha. Para -x/-y devolve (assento, encosto) para o encosto
    ser desenhado por cima de quem senta."""
    k = K(iso)
    s0, s1 = 0.26, 0.74
    seat_z = 23 * k
    o_legs, o_seat, o_back = [], [], []
    o_legs.append(soft_shadow(D, iso, x + 0.5, y + 0.5, 0.3, opacity=0.25))
    for (lx, ly) in sorted([(x + s0 + 0.03, y + s0 + 0.03), (x + s1 - 0.03, y + s0 + 0.03), (x + s0 + 0.03, y + s1 - 0.03),
                            (x + s1 - 0.03, y + s1 - 0.03)], key=lambda p: p[0] + p[1]):
        o_legs.append(cyl3(D, iso, lx, ly, 0.022, 0, seat_z, legs, metal=True, sw=0.7, cap=False))
    o_seat.append(box3(D, iso, x + s0, y + s0, s1 - s0, s1 - s0, 3 * k, shade(color, 0.25), z=seat_z, sw=0.9, bevel=False))
    o_seat.append(box3(D, iso, x + s0 + 0.01, y + s0 + 0.01, s1 - s0 - 0.02, s1 - s0 - 0.02, 5 * k, color, z=seat_z + 3 * k, sw=0.9,
                       gloss=True))
    back_h = 30 * k
    zb = seat_z + 6 * k
    width_px = (s1 - s0) * iso.W / 2
    fill = D.lin([(0, tint(color, 0.35)), (0.35, color), (1, shade(color, 0.22))], 0, 0, 1, 1)
    if facing in ("+x", "-x"):
        bx = x + s0 if facing == "+x" else x + s1
        o_back.append(cyl3(D, iso, bx, y + s0 + 0.04, 0.02, seat_z, zb + 4, legs, metal=True, sw=0.6, cap=False))
        o_back.append(cyl3(D, iso, bx, y + s1 - 0.04, 0.02, seat_z, zb + 4, legs, metal=True, sw=0.6, cap=False))
        o_back.append(_rrect_plane(iso, "L", bx, y + s1, zb, width_px, back_h, fill, r=6 * k))
        t = plane(iso, "L", bx, y + s1, zb)
        o_back.append(f'<rect x="{f(3*k)}" y="{f(-back_h+3*k)}" width="{f(width_px-6*k)}" height="{f(back_h*0.35)}" rx="{f(4*k)}" '
                      f'fill="#ffffff" opacity="0.28" transform="{t}"/>')
    else:
        by = y + s0 if facing == "+y" else y + s1
        o_back.append(cyl3(D, iso, x + s0 + 0.04, by, 0.02, seat_z, zb + 4, legs, metal=True, sw=0.6, cap=False))
        o_back.append(cyl3(D, iso, x + s1 - 0.04, by, 0.02, seat_z, zb + 4, legs, metal=True, sw=0.6, cap=False))
        o_back.append(_rrect_plane(iso, "R", x + s0, by, zb, width_px, back_h, fill, r=6 * k))
        t = plane(iso, "R", x + s0, by, zb)
        o_back.append(f'<rect x="{f(3*k)}" y="{f(-back_h+3*k)}" width="{f(width_px-6*k)}" height="{f(back_h*0.35)}" rx="{f(4*k)}" '
                      f'fill="#ffffff" opacity="0.28" transform="{t}"/>')
    if facing in ("+x", "+y"):
        return "".join(o_legs + o_back + o_seat)
    return "".join(o_legs + o_seat), "".join(o_back)


def seat_point(iso, x, y):
    k = K(iso)
    return iso.v(x + 0.5, y + 0.5, 30 * k)


# --- Mesas -------------------------------------------------------------------------------

def table_square(D, iso, x, y, top="#ffffff", edge="#ff4d5e", dishes=(), vase=True, joined=""):
    """Mesa quadrada de lanchonete com tampo de fórmica e borda colorida. joined: lados sem margem ('x', 'y')."""
    k = K(iso)
    m = 0.06
    x0 = x + (0 if "-x" in joined else m)
    x1 = x + 1 - (0 if "+x" in joined else m)
    y0 = y + (0 if "-y" in joined else m)
    y1 = y + 1 - (0 if "+y" in joined else m)
    h = 32 * k
    o = [soft_shadow(D, iso, x + 0.5, y + 0.5, 0.42, opacity=0.3)]
    o.append(cyl3(D, iso, x + 0.5, y + 0.5, 0.2, 0, 2.5 * k, "#8d98a6", metal=True, sw=0.8))
    o.append(cyl3(D, iso, x + 0.5, y + 0.5, 0.045, 2.5 * k, h - 4 * k, CHROME, metal=True, sw=0.8, cap=False))
    o.append(box3(D, iso, x0, y0, x1 - x0, y1 - y0, 4.5 * k, edge, z=h - 4.5 * k, top=top, sw=1.0))
    T = [iso.v(x0, y0, h), iso.v(x1, y0, h), iso.v(x1, y1, h), iso.v(x0, y1, h)]
    o.append(P(T, D.lin([(0, "#ffffff", 0.0), (0.45, "#ffffff", 0.45), (0.55, "#ffffff", 0.0)], 0, 0, 1, 1), None))
    spots = [(0.3, 0.45), (0.7, 0.55), (0.5, 0.3)]
    for i, kind in enumerate(dishes):
        u, v = spots[i % 3]
        px, py = iso.v(x + u, y + v, h)
        o.append(E(px, py + 1.5, 13 * k, 5.2 * k, "#ffffff", INK3, 0.9) + E(px, py + 1.8, 8.5 * k, 3.2 * k, "#eef2f7", None))
        o.append(food(D, kind, px, py - 4 * k, 26 * k))
    if vase and not dishes:
        px, py = iso.v(x + 0.5, y + 0.5, h)
        o.append(cyl3(D, iso, x + 0.5, y + 0.5, 0.045, h, h + 9 * k, "#8fe3ff", sw=0.8))
        o.append(path(f"M{f(px)},{f(py-9*k)} L{f(px-1)},{f(py-17*k)} M{f(px)},{f(py-9*k)} L{f(px+3)},{f(py-15*k)}", "none", "#2f9e44", 1.2))
        o.append(C(px - 1.5, py - 18 * k, 3.4 * k, "#ff4d8d", INK3, 0.8) + C(px + 3.4, py - 15.6 * k, 3 * k, "#ffd23f", INK3, 0.8))
        o.append(C(px - 1.5, py - 18 * k, 1.1 * k, "#ffe680", None) + C(px + 3.4, py - 15.6 * k, 1 * k, "#ffffff", None))
    return "".join(o)


def _stripes(D, color):
    key = "st3" + color[1:]
    markup = (f'<pattern id="{key}" patternUnits="userSpaceOnUse" width="8" height="8">'
              f'<rect width="8" height="8" fill="#ffffff"/><rect width="4" height="8" fill="{color}"/></pattern>')
    return D.raw(key, markup)


def _gingham(D, iso, color):
    key = "gi3" + color[1:] + str(int(iso.W))
    a, b = iso.W / 2 * 0.1, iso.H / 2 * 0.1
    markup = (f'<pattern id="{key}" patternUnits="userSpaceOnUse" width="2" height="2" '
              f'patternTransform="matrix({f(a)},{f(b)},{f(-a)},{f(b)},0,0)">'
              f'<rect width="2" height="2" fill="#ffffff"/>'
              f'<rect width="1" height="2" fill="{color}" opacity="0.5"/>'
              f'<rect width="2" height="1" fill="{color}" opacity="0.5"/></pattern>')
    return D.raw(key, markup)


def table_round(D, iso, x, y, cloth="#ff4d5e", dishes=(), r=0.4):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    h = 34 * k
    o = [soft_shadow(D, iso, cx, cy, r * 1.05, opacity=0.3)]
    o.append(cyl3(D, iso, cx, cy, 0.16, 0, 3 * k, "#8d98a6", metal=True, sw=0.8))
    o.append(cyl3(D, iso, cx, cy, 0.035, 3 * k, h - 8 * k, CHROME, metal=True, sw=0.8, cap=False))
    sx, st, rx, ry = iso.ell(cx, cy, h, r)
    drop = 12 * k
    n = 9
    hem = []
    for i in range(n + 1):
        th = math.pi * i / n
        hem.append((sx + rx * 1.03 * math.cos(th), st + drop + ry * 1.03 * math.sin(th)))
    d = f"M{f(sx+rx)},{f(st)} L{f(hem[0][0])},{f(hem[0][1])}"
    for i in range(1, len(hem)):
        (x0, y0), (x1, y1) = hem[i - 1], hem[i]
        d += f" Q{f((x0+x1)/2)},{f((y0+y1)/2+3*k)} {f(x1)},{f(y1)}"
    d += f" L{f(sx-rx)},{f(st)} A{f(rx)},{f(ry)} 0 0 0 {f(sx+rx)},{f(st)} Z"
    o.append(path(d, _stripes(D, cloth), INK3, 1.0))
    o.append(path(d, D.lin([(0, "#ffffff", 0.25), (0.3, "#ffffff", 0.0), (0.7, "#1a1030", 0.06), (1, "#1a1030", 0.3)], 0, 0, 1, 0), None))
    o.append(E(sx, st, rx, ry, _gingham(D, iso, cloth), INK3, 1.1))
    o.append(E(sx - rx * 0.25, st - ry * 0.25, rx * 0.5, ry * 0.4, "#ffffff", None, extra='opacity="0.35"'))
    spots = [(-0.14, -0.05), (0.12, 0.1)]
    for i, kind in enumerate(dishes):
        dx, dy = spots[i % 2]
        px, py = iso.v(cx + dx, cy + dy, h)
        o.append(E(px, py + 2, 13 * k, 5 * k, "#ffffff", INK3, 0.9) + E(px, py + 2.2, 8 * k, 3 * k, "#eef2f7", None))
        o.append(food(D, kind, px, py - 4 * k, 26 * k))
    if not dishes:
        px, py = iso.v(cx, cy, h)
        o.append(cyl3(D, iso, cx, cy, 0.045, h, h + 9 * k, "#8fe3ff", sw=0.8))
        o.append(C(px - 1.5, py - 13 * k, 3.4 * k, "#ffd23f", INK3, 0.8) + C(px + 2.8, py - 11 * k, 3 * k, "#ff4d8d", INK3, 0.8))
    return "".join(o)


# --- Cozinha -----------------------------------------------------------------------------

def _burner(D, iso, cx, cy, z, flame=False):
    sx, sy, rx, ry = iso.ell(cx, cy, z, 0.13)
    o = [E(sx, sy, rx, ry, "#15151b", INK3, 0.8), E(sx, sy, rx * 0.55, ry * 0.55, "#474a55", None)]
    o.append(line(sx - rx, sy, sx + rx, sy, "#7b7f8b", 1.1) + line(sx, sy - ry, sx, sy + ry, "#7b7f8b", 1.1))
    if flame:
        o.append(E(sx, sy - 0.5, rx * 0.75, ry * 0.75, "none", "#4fb3ff", 2.4, 'opacity="0.95"'))
        o.append(E(sx, sy - 1, rx * 0.75, ry * 0.75, "none", "#ffd166", 1.0, 'opacity="0.9"'))
    return "".join(o)


def _steam(x, y, k=1.0):
    return "".join(C(x + dx * k, y + dy * k, r * k, "#ffffff", None, extra=f'opacity="{op}"')
                   for dx, dy, r, op in [(0, 0, 5, 0.6), (4, -7, 6, 0.5), (-2, -15, 7, 0.38), (3, -24, 6, 0.26)])


def cookware(D, iso, kind, cx, cy, z):
    """Utensílio no fogão mostrando a comida."""
    k = K(iso)
    o = []
    sx, sy = iso.v(cx, cy, z)
    if kind == "cafe":
        o.append(cyl3(D, iso, cx, cy, 0.09, z, z + 12 * k, "#cfd6de", metal=True))
        o.append(cyl3(D, iso, cx, cy, 0.1, z + 12 * k, z + 26 * k, "#e4e9ee", metal=True))
        o.append(path(f"M{f(sx+9*k)},{f(sy-24*k)} l{f(7*k)},{f(-4*k)} l{f(-1*k)},{f(5*k)} Z", "#cfd6de", INK3, 0.9))
        o.append(path(f"M{f(sx-9*k)},{f(sy-14*k)} q{f(-8*k)},0 {f(-7*k)},{f(-8*k)}", "none", "#26262e", 2.6 * k))
        o.append(_steam(sx + 16 * k, sy - 32 * k, 0.8 * k))
    elif kind == "pao":
        o.append(box3(D, iso, cx - 0.28, cy - 0.28, 0.56, 0.56, 3 * k, "#474a55", z=z, sw=0.9))
        for i in range(3):
            for j in range(3):
                px, py = iso.v(cx - 0.18 + i * 0.18, cy - 0.18 + j * 0.18, z + 3 * k)
                o.append(C(px, py - 4 * k, 5.4 * k, D.rad([(0, "#fff4c9"), (0.4, "#ffd06a"), (1, "#d8902c")], 0.4, 0.35, 0.7), "#8a5418", 0.8))
        o.append(_steam(sx, sy - 22 * k, 0.8 * k))
    elif kind == "coxinha":
        o.append(cyl3(D, iso, cx, cy, 0.22, z, z + 12 * k, "#40434d", top="#2b2c33"))
        ex, ey, erx, ery = iso.ell(cx, cy, z + 11 * k, 0.19)
        o.append(E(ex, ey, erx, ery, "#f0b640", None, extra='opacity="0.9"'))
        for (dx, dy) in [(-0.07, -0.02), (0.06, 0.03), (0.0, 0.08)]:
            px, py = iso.v(cx + dx, cy + dy, z + 12 * k)
            o.append(path(f"M{f(px)},{f(py-9*k)} C{f(px+5*k)},{f(py-5*k)} {f(px+5*k)},{f(py+1)} {f(px)},{f(py+1.5)} "
                          f"C{f(px-5*k)},{f(py+1)} {f(px-5*k)},{f(py-5*k)} {f(px)},{f(py-9*k)} Z", "#ec9a3e", "#6d3a12", 0.8))
        o.append(_steam(sx, sy - 22 * k, 0.8 * k))
    elif kind == "misto":
        o.append(box3(D, iso, cx - 0.3, cy - 0.3, 0.6, 0.6, 4 * k, "#34353d", z=z, sw=0.9))
        for (dx, dy) in [(-0.1, -0.08), (0.12, 0.1)]:
            o.append(box3(D, iso, cx + dx - 0.1, cy + dy - 0.1, 0.2, 0.2, 5 * k, "#eeb05a", z=z + 4 * k, sw=0.8, top="#f3c070"))
            px, py = iso.v(cx + dx, cy + dy, z + 9 * k)
            o.append(line(px - 5 * k, py, px + 5 * k, py, "#9b5a24", 1.4, 'opacity="0.6"'))
        o.append(_steam(sx, sy - 20 * k, 0.7 * k))
    elif kind == "bolo":
        o.append(cyl3(D, iso, cx, cy, 0.2, z, z + 10 * k, "#6e727c", metal=True))
        ex, ey, erx, ery = iso.ell(cx, cy, z + 10 * k, 0.17)
        o.append(E(ex, ey, erx, ery, D.rad([(0, "#ffc978"), (1, "#f08a22")]), None))
    elif kind == "lasanha":
        o.append(box3(D, iso, cx - 0.26, cy - 0.2, 0.52, 0.4, 9 * k, "#ffffff", z=z, sw=0.9))
        o.append(box3(D, iso, cx - 0.22, cy - 0.16, 0.44, 0.32, 1, "#f2b43f", z=z + 8 * k, sw=0, bevel=False))
        for (dx, dy) in [(-0.1, -0.05), (0.08, 0.04), (0.0, 0.1)]:
            px, py = iso.v(cx + dx, cy + dy, z + 9 * k)
            o.append(E(px, py, 3.4 * k, 1.8 * k, "#c2541d", None, extra='opacity="0.85"'))
        o.append(_steam(sx, sy - 20 * k, 0.8 * k))
    return "".join(o)


def stove(D, iso, x, y, front="R", cooking=None, enamel="#ff4d5e"):
    """Fogão retrô esmaltado: tampo preto com 4 bocas, painel cromado com botões e forno com visor.
    front=None: frente virada para longe da câmera (só o corpo e as bocas)."""
    k = K(iso)
    bx, by, w, d, h = x + 0.05, y + 0.05, 0.9, 0.9, 44 * k
    o = [soft_shadow(D, iso, x + 0.5, y + 0.5, 0.5, opacity=0.3)]
    o.append(box3(D, iso, bx, by, w, d, h, enamel, top="#ffffff"))
    top = [iso.v(bx + 0.05, by + 0.05, h), iso.v(bx + w - 0.05, by + 0.05, h), iso.v(bx + w - 0.05, by + d - 0.05, h), iso.v(bx + 0.05, by + d - 0.05, h)]
    o.append(P(top, D.lin([(0, "#3a3c46"), (1, "#1c1d23")], 0, 0, 1, 1), INK3, 0.9))
    burners = [(0.3, 0.3), (0.72, 0.3), (0.3, 0.72), (0.72, 0.72)]
    for i, (u, v) in enumerate(burners):
        o.append(_burner(D, iso, bx + u * w, by + v * d, h, cooking is not None and i == 3))
    if front is None:
        return "".join(o)
    q = lambda u0, u1, v0, v1: iso.quad(front, bx, by, w, d, 0, h, u0, u1, v0, v1)
    o.append(P(q(0.0, 1.0, 0.78, 0.97), D.lin([(0, "#f4f7fa"), (0.5, CHROME), (1, "#8f9aa7")]), INK3, 0.8))
    for u in (0.16, 0.38, 0.62, 0.84):
        px, py = iso.face_center(front, bx, by, w, d, 0, h, u, 0.875)
        o.append(C(px, py, 3.3 * k, "#1f2027", INK3, 0.7) + line(px, py, px, py - 2.4 * k, "#ffffff", 1.0))
    o.append(P(q(0.08, 0.92, 0.1, 0.7), D.lin([(0, tint(enamel, 0.25)), (1, shade(enamel, 0.1))]), INK3, 0.9))
    o.append(P(q(0.18, 0.82, 0.2, 0.58), D.lin([(0, "#2a2230"), (1, "#120e16")]), INK3, 0.9))
    if cooking:
        o.append(P(q(0.24, 0.76, 0.24, 0.5), "#ffab40", None, 'opacity="0.55"'))
        o.append(P(q(0.3, 0.7, 0.28, 0.38), "#ffe08a", None, 'opacity="0.6"'))
    o.append(P(q(0.22, 0.4, 0.46, 0.56), "#ffffff", None, 'opacity="0.18"'))
    o.append(P(q(0.14, 0.86, 0.63, 0.67), "#f4f7fa", INK3, 0.8))
    o.append(P(q(0.02, 0.98, 0.0, 0.06), "#2a2230", None, 'opacity="0.6"'))
    if cooking:
        u, v = burners[3]
        o.append(cookware(D, iso, cooking, bx + u * w, by + v * d, h))
    return "".join(o)


def counter(D, iso, x, y, front="R", dishes=(), body="#2ec4b6", top="#ffffff", cells=1, along="x"):
    """Balcão de servir: frente colorida com frisos, tampo de mármore claro, pilhas de pratos com a contagem.
    cells/along: comprimento em células e o eixo em que ele se estende. front=None: frente escondida."""
    k = K(iso)
    if along == "x":
        bx, by, w, d = x + 0.02, y + 0.06, cells - 0.04, 0.88
    else:
        bx, by, w, d = x + 0.06, y + 0.02, 0.88, cells - 0.04
    h = 42 * k
    o = [soft_shadow(D, iso, x + w / 2 + 0.02, y + d / 2 + 0.02, 0.5 * cells, 0.5, opacity=0.28) if cells > 1
         else soft_shadow(D, iso, x + 0.5, y + 0.5, 0.5, opacity=0.28)]
    o.append(box3(D, iso, bx, by, w, d, h, body))
    if front is not None:
        q = lambda u0, u1, v0, v1: iso.quad(front, bx, by, w, d, 0, h, u0, u1, v0, v1)
        o.append(P(q(0, 1, 0, 0.1), shade(body, 0.35), None, 'opacity="0.7"'))
        n = cells if (front == "L") == (along == "x") else 1
        for c in range(n):
            for (u0, u1) in ((0.08, 0.46), (0.54, 0.92)):
                a, b = (c + u0) / n, (c + u1) / n
                o.append(P(q(a, b, 0.18, 0.84), D.lin([(0, tint(body, 0.3)), (1, shade(body, 0.1))]), INK3, 0.8))
                o.append(P(q(a + 0.05 / n, b - 0.05 / n, 0.62, 0.72), "#ffffff", None, 'opacity="0.35"'))
    o.append(box3(D, iso, bx - 0.03, by - 0.03, w + 0.06, d + 0.06, 5 * k, "#e8edf2", z=h, top=top))
    for (a, b) in [((0.15, 0.2), (0.55, 0.35)), ((0.4, 0.62), (0.88, 0.72))]:
        p0 = iso.v(bx + a[0] * w, by + a[1] * d, h + 5 * k)
        p1 = iso.v(bx + b[0] * w, by + b[1] * d, h + 5 * k)
        o.append(path(f"M{f(p0[0])},{f(p0[1])} Q{f((p0[0]+p1[0])/2+4)},{f((p0[1]+p1[1])/2-3)} {f(p1[0])},{f(p1[1])}",
                      "none", "#c3ccd6", 0.9, 'opacity="0.8"'))
    spots = [(0.32, 0.32), (0.72, 0.38), (0.48, 0.72)]
    for i, (kind, count) in enumerate(dishes):
        u, v = spots[i % 3]
        px, py = iso.v(bx + u * w, by + v * d, h + 5 * k)
        n = min(3, max(1, count // 4))
        for j in range(n):
            o.append(E(px, py + 1 - j * 2.2 * k, 15 * k, 5.4 * k, "#ffffff", INK3, 0.9))
        o.append(food(D, kind, px, py - 6 * k - n * 2 * k, 30 * k))
        o.append(count_badge(px + 16 * k, py - 26 * k, count, k))
    return "".join(o)


def count_badge(x, y, count, k=1.0):
    w = 26 * k
    return (f'<rect x="{f(x-w/2)}" y="{f(y-8*k)}" width="{f(w)}" height="{f(16*k)}" rx="{f(8*k)}" fill="#ffffff" stroke="#1f6fd1" stroke-width="{f(1.6*k)}"/>'
            f'<text x="{f(x)}" y="{f(y+4.2*k)}" text-anchor="middle" font-family="Fredoka, Nunito, sans-serif" font-weight="700" '
            f'font-size="{f(11.5*k)}" fill="#1f4f99">{count}</text>')


def pastry_case(D, iso, x, y, body="#ff8fb1"):
    k = K(iso)
    bx, by, w, d = x + 0.05, y + 0.08, 0.9, 0.84
    o = [soft_shadow(D, iso, x + 0.5, y + 0.5, 0.5, opacity=0.28)]
    o.append(box3(D, iso, bx, by, w, d, 34 * k, body))
    o.append(box3(D, iso, bx + 0.02, by + 0.02, w - 0.04, d - 0.04, 2 * k, "#ffffff", z=34 * k))
    sx, sy = iso.v(bx + w * 0.35, by + d * 0.4, 36 * k)
    o.append(food(D, "bolo", sx + 4 * k, sy - 2 * k, 30 * k))
    o.append(food(D, "pao", sx + 30 * k, sy + 6 * k, 26 * k))
    o.append(box3(D, iso, bx + 0.04, by + 0.04, w - 0.08, d - 0.08, 1.5 * k, "#f1f4f8", z=52 * k, sw=0.6))
    px, py = iso.v(bx + w * 0.55, by + d * 0.45, 54 * k)
    o.append(food(D, "coxinha", px, py - 2 * k, 24 * k) + food(D, "misto", px + 22 * k, py + 6 * k, 24 * k))
    gz0, gz1 = 36 * k, 70 * k
    gT = [iso.v(bx, by, gz1), iso.v(bx + w, by, gz1), iso.v(bx + w, by + d, gz1), iso.v(bx, by + d, gz1)]
    gL = [iso.v(bx, by + d, gz0), iso.v(bx + w, by + d, gz0), iso.v(bx + w, by + d, gz1), iso.v(bx, by + d, gz1)]
    gR = [iso.v(bx + w, by + d, gz0), iso.v(bx + w, by, gz0), iso.v(bx + w, by, gz1), iso.v(bx + w, by + d, gz1)]
    for face in (gL, gR, gT):
        o.append(P(face, "#c9f0ff", INK3, 0.9, 'fill-opacity="0.25"'))
    for t in (0.18, 0.3):
        a = (gL[0][0] + (gL[1][0] - gL[0][0]) * t, gL[0][1] + (gL[1][1] - gL[0][1]) * t)
        o.append(line(a[0] + 4, a[1] - 6 * k, a[0] + 14 * k, a[1] - 26 * k, "#ffffff", 2.4, 'opacity="0.85"'))
    o.append(box3(D, iso, bx - 0.01, by - 0.01, w + 0.02, d + 0.02, 3 * k, shade(body, 0.15), z=gz1))
    return "".join(o)


def espresso(D, iso, x, y, body="#ff4d5e"):
    k = K(iso)
    o = [counter(D, iso, x, y, body="#ffd23f")]
    bx, by = x + 0.2, y + 0.22
    z0 = 47 * k
    o.append(box3(D, iso, bx, by, 0.6, 0.5, 30 * k, CHROME, z=z0, top="#f2f5f8"))
    o.append(box3(D, iso, bx + 0.05, by + 0.05, 0.5, 0.4, 6 * k, body, z=z0 + 30 * k, gloss=True))
    fx0, fy0 = iso.face_center("R", bx, by, 0.6, 0.5, z0, 30 * k, 0.5, 0.78)
    o.append(C(fx0, fy0, 4 * k, "#ffffff", INK3, 0.8) + line(fx0, fy0, fx0 + 2 * k, fy0 - 2.5 * k, "#1f2027", 1.0))
    for u in (0.28, 0.72):
        px, py = iso.face_center("R", bx, by, 0.6, 0.5, z0, 30 * k, u, 0.42)
        o.append(E(px, py, 4 * k, 3 * k, "#3a3c46", INK3, 0.8) + line(px + 2, py + 1, px + 9 * k, py + 5 * k, "#1f2027", 2.2))
        o.append(E(px + 1, py + 13 * k, 4.4 * k, 1.8 * k, "#ffffff", INK3, 0.8))
    for i in range(3):
        px, py = iso.v(bx + 0.15 + i * 0.15, by + 0.2, z0 + 36 * k)
        o.append(E(px, py, 4.5 * k, 2.2 * k, "#ffffff", INK3, 0.8)
                 + path(f"M{f(px-4*k)},{f(py)} L{f(px-3*k)},{f(py+4*k)} L{f(px+3*k)},{f(py+4*k)} L{f(px+4*k)},{f(py)}", "#ffffff", INK3, 0.8))
    return "".join(o)


def fridge(D, iso, x, y, color="#7ee0c3"):
    """Geladeira retrô de uma porta, com puxador cromado e logotipo de estrela."""
    k = K(iso)
    bx, by, w, d, h = x + 0.1, y + 0.1, 0.8, 0.75, 92 * k
    o = [soft_shadow(D, iso, x + 0.5, y + 0.5, 0.5, opacity=0.3)]
    o.append(box3(D, iso, bx, by, w, d, h, color, gloss=True))
    q = lambda u0, u1, v0, v1: iso.quad("R", bx, by, w, d, 0, h, u0, u1, v0, v1)
    o.append(P(q(0.0, 1.0, 0.64, 0.66), shade(color, 0.35), None))
    o.append(P(q(0.08, 0.14, 0.4, 0.58), D.lin([(0, "#ffffff"), (1, CHROME)]), INK3, 0.8))
    o.append(P(q(0.08, 0.14, 0.72, 0.84), D.lin([(0, "#ffffff"), (1, CHROME)]), INK3, 0.8))
    o.append(P(q(0.3, 0.5, 0.1, 0.6), "#ffffff", None, 'opacity="0.22"'))
    o.append(P(q(0.0, 1.0, 0.0, 0.05), "#2a2230", None, 'opacity="0.55"'))
    return "".join(o)


def sink(D, iso, x, y):
    k = K(iso)
    o = [counter(D, iso, x, y, body="#8fd0ff")]
    bx, by = x + 0.22, y + 0.2
    z = 47 * k
    o.append(P([iso.v(bx, by, z), iso.v(bx + 0.56, by, z), iso.v(bx + 0.56, by + 0.56, z), iso.v(bx, by + 0.56, z)],
               D.lin([(0, "#9aa6b3"), (1, "#dfe6ee")], 0, 0, 1, 1), INK3, 0.9))
    px, py = iso.v(bx + 0.1, by + 0.3, z)
    o.append(path(f"M{f(px)},{f(py)} l0,{f(-16*k)} q{f(8*k)},{f(-5*k)} {f(12*k)},{f(3*k)}", "none", "#aab5c2", 2.6 * k))
    o.append(path(f"M{f(px)},{f(py)} l0,{f(-16*k)} q{f(8*k)},{f(-5*k)} {f(12*k)},{f(3*k)}", "none", "#ffffff", 1.0 * k, 'opacity="0.6"'))
    return "".join(o)


# --- Decoração ---------------------------------------------------------------------------

def plant(D, iso, x, y, pot="#ffd23f", big=True, seed=3):
    """Vaso colorido com folhagem cheia e brilhante (folhas largas em camadas)."""
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    o = [soft_shadow(D, iso, cx, cy, 0.34, opacity=0.3)]
    o.append(cyl3(D, iso, cx, cy, 0.19, 0, 24 * k, pot))
    o.append(cyl3(D, iso, cx, cy, 0.22, 20 * k, 27 * k, shade(pot, 0.1)))
    sx, sy, rx, ry = iso.ell(cx, cy, 27 * k, 0.19)
    o.append(E(sx, sy, rx, ry, "#5a3a24", None))
    r = Rng(seed)
    hgt = (62 if big else 40) * k
    wid = (30 if big else 20) * k
    leaves = []
    n = 22 if big else 12
    for i in range(n):
        a = -math.pi / 2 + r.u(-1.0, 1.0) * math.pi * 0.62
        ln = r.u(0.55, 1.0)
        tipx = sx + math.cos(a) * wid * ln * 1.1
        tipy = sy - hgt * 0.3 + math.sin(a) * hgt * 0.75 * ln
        leaves.append((tipy, tipx, a, ln, r.r()))
    leaves.sort(key=lambda t: t[0])
    for (tipy, tipx, a, ln, sh) in leaves:
        stemx, stemy = sx + math.cos(a) * 3 * k, sy - 3 * k
        o.append(path(f"M{f(stemx)},{f(stemy)} Q{f((stemx+tipx)/2)},{f(min(stemy, tipy) - 5*k)} {f(tipx)},{f(tipy)}", "none", "#2f8a3a", 1.2 * k))
        ang = math.degrees(math.atan2(tipy - stemy, tipx - stemx)) + r.u(-25, 25)
        base = mix("#3fbf4a", "#7fe06a", sh)
        col = D.lin([(0, tint(base, 0.35)), (0.55, base), (1, shade(base, 0.3))], 0, 0, 1, 1)
        L = 22 * k * ln + 9 * k
        Wd = 11 * k * ln + 4 * k
        o.append(f'<path d="{leaf(0, 0, 0, L, Wd, 0.08)}" fill="{col}" stroke="#1d6b33" stroke-width="0.9" '
                 f'transform="translate({f(tipx)},{f(tipy)}) rotate({f(ang)})"/>')
        o.append(f'<path d="M{f(-L*0.42)},0 L{f(L*0.42)},{f(Wd*0.12)}" stroke="#1d6b33" stroke-width="0.7" opacity="0.55" '
                 f'transform="translate({f(tipx)},{f(tipy)}) rotate({f(ang)})"/>')
    return "".join(o)


def flower_vase(D, iso, x, y, vase="#7a5cff"):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    o = [soft_shadow(D, iso, cx, cy, 0.22, opacity=0.28)]
    o.append(cyl3(D, iso, cx, cy, 0.14, 0, 26 * k, "#ffffff"))
    o.append(cyl3(D, iso, cx, cy, 0.1, 26 * k, 44 * k, vase))
    sx, sy = iso.v(cx, cy, 44 * k)
    r = Rng(5)
    for i in range(7):
        a = math.radians(-160 + i * 23)
        fx, fy = sx + math.cos(a) * 14 * k, sy - 16 * k + math.sin(a) * 12 * k
        o.append(path(f"M{f(sx)},{f(sy)} Q{f((sx+fx)/2)},{f(fy+4*k)} {f(fx)},{f(fy)}", "none", "#2f8a3a", 1.2))
        col = ["#ff4d8d", "#ffd23f", "#ff7a2f", "#ffffff", "#ff4d5e", "#b06bff", "#ff8fb1"][i]
        for j in range(5):
            b = math.radians(j * 72)
            o.append(C(fx + math.cos(b) * 2.6 * k, fy + math.sin(b) * 2.6 * k, 2.4 * k, col, INK3, 0.5))
        o.append(C(fx, fy, 1.6 * k, "#ffe066", None))
    return "".join(o)


def jukebox(D, iso, x, y, body="#ff3d7f"):
    """Jukebox com arco de neon e grade cromada."""
    k = K(iso)
    bx, by, w, d = x + 0.12, y + 0.2, 0.76, 0.6
    h = 58 * k
    o = [soft_shadow(D, iso, x + 0.5, y + 0.5, 0.45, opacity=0.3)]
    o.append(box3(D, iso, bx, by, w, d, h, body))
    # arco no alto (frente = face L, plano y constante)
    width_px = w * iso.W / 2
    t = plane(iso, "R", bx, by + d, h)
    arch = f"M0,0 L0,{f(-8*k)} Q0,{f(-width_px*0.62)} {f(width_px/2)},{f(-width_px*0.62)} Q{f(width_px)},{f(-width_px*0.62)} {f(width_px)},{f(-8*k)} L{f(width_px)},0 Z"
    o.append(f'<path d="{arch}" fill="{D.lin([(0, "#fff3a0"), (0.4, "#ffb13d"), (1, "#ff5a36")])}" stroke="{INK3}" stroke-width="1" transform="{t}"/>')
    o.append(f'<path d="{arch}" fill="none" stroke="#ffffff" stroke-width="{f(2*k)}" opacity="0.7" transform="{t} translate({f(width_px*0.12)},{f(-2*k)}) scale(0.76)"/>')
    tf = plane(iso, "R", bx, by + d, 0)
    inner = (f'<rect x="{f(width_px*0.12)}" y="{f(-h*0.88)}" width="{f(width_px*0.76)}" height="{f(h*0.36)}" rx="{f(3*k)}" fill="#c9f0ff" stroke="{INK3}" stroke-width="0.8"/>'
             f'<rect x="{f(width_px*0.1)}" y="{f(-h*0.46)}" width="{f(width_px*0.8)}" height="{f(h*0.36)}" rx="{f(3*k)}" fill="#2a2230" stroke="{INK3}" stroke-width="0.8"/>')
    for i in range(6):
        xx = width_px * (0.16 + i * 0.12)
        col = ["#ffd23f", "#4fe0c0", "#ff4d5e", "#8fd0ff", "#ff8fb1", "#b06bff"][i]
        inner += f'<rect x="{f(xx)}" y="{f(-h*0.42)}" width="{f(width_px*0.07)}" height="{f(h*0.28)}" rx="{f(1.5*k)}" fill="{col}" opacity="0.9"/>'
    for i in range(4):
        yy = -h * (0.84 - i * 0.07)
        inner += f'<line x1="{f(width_px*0.18)}" y1="{f(yy)}" x2="{f(width_px*0.82)}" y2="{f(yy)}" stroke="#7aa9c2" stroke-width="0.8"/>'
    o.append(f'<g transform="{tf}">{inner}</g>')
    return "".join(o)


def floor_lamp(D, iso, x, y, shade_col="#ffd23f"):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.2, opacity=0.25), cyl3(D, iso, cx, cy, 0.12, 0, 3 * k, "#3a3c46")]
    o.append(line(sx, sy - 3 * k, sx, sy - 82 * k, "#3a3c46", 2.6 * k))
    o.append(C(sx, sy - 74 * k, 34 * k, D.rad([(0, "#fff6b8", 0.6), (1, "#fff6b8", 0.0)]), None))
    o.append(path(f"M{f(sx-15*k)},{f(sy-76*k)} L{f(sx-9*k)},{f(sy-96*k)} L{f(sx+9*k)},{f(sy-96*k)} L{f(sx+15*k)},{f(sy-76*k)} Z",
                  D.lin([(0, tint(shade_col, 0.4)), (1, shade(shade_col, 0.1))]), INK3, 1.1))
    o.append(E(sx, sy - 76 * k, 15 * k, 3.8 * k, "#fff9d6", INK3, 0.9))
    return "".join(o)


def bookshelf(D, iso, x, y, color="#ffffff", front="+y"):
    """Estante 2x1 encostada na parede da direita, com livros e potes coloridos.
    front: para onde as prateleiras abrem ('+y' e '+x' aparecem; '-y' e '-x' mostram as costas)."""
    k = K(iso)
    h = 80 * k
    if front in ("+y", "-y"):
        bx, by, w, d = x + 0.05, y + (0.05 if front == "+y" else 0.5), 1.9, 0.45
        o = [soft_shadow(D, iso, x + 1, by + 0.25, 0.9, 0.3, opacity=0.25)]
    else:
        bx, by, w, d = x + (0.05 if front == "+x" else 0.5), y + 0.05, 0.45, 1.9
        o = [soft_shadow(D, iso, bx + 0.25, y + 1, 0.3, 0.9, opacity=0.25)]
    o.append(box3(D, iso, bx, by, w, d, h, color))
    if front in ("-x", "-y"):
        return "".join(o)
    t = plane(iso, "R", bx, by + d, 0) if front == "+y" else plane(iso, "L", bx + w, by + d, 0)
    if front == "+x":
        w = d
    width_px = w * iso.W / 2
    inner = []
    r = Rng(9)
    for s in range(3):
        y0 = -h * (0.08 + s * 0.31)
        inner.append(f'<rect x="{f(4*k)}" y="{f(y0 - h*0.27)}" width="{f(width_px-8*k)}" height="{f(h*0.27)}" fill="#f1e6ff" stroke="{INK3}" stroke-width="0.7"/>')
        xx = 6 * k
        while xx < width_px - 12 * k:
            bw = r.u(4, 7) * k
            bh = h * r.u(0.16, 0.25)
            col = ["#ff4d5e", "#ffd23f", "#2ec4b6", "#4d8dff", "#ff8fb1", "#b06bff", "#ff7a2f"][int(r.u(0, 7))]
            inner.append(f'<rect x="{f(xx)}" y="{f(y0 - bh)}" width="{f(bw)}" height="{f(bh)}" rx="1" fill="{col}" stroke="{INK3}" stroke-width="0.6"/>')
            xx += bw + r.u(0.5, 2.5) * k
    o.append(f'<g transform="{t}">{"".join(inner)}</g>')
    return "".join(o)


def aquarium(D, iso, x, y):
    k = K(iso)
    bx, by, w, d = x + 0.06, y + 0.2, 0.88, 0.6
    o = [soft_shadow(D, iso, x + 0.5, y + 0.5, 0.45, opacity=0.25)]
    o.append(box3(D, iso, bx, by, w, d, 30 * k, "#4d8dff"))
    z0, z1 = 30 * k, 64 * k
    gL = [iso.v(bx, by + d, z0), iso.v(bx + w, by + d, z0), iso.v(bx + w, by + d, z1), iso.v(bx, by + d, z1)]
    gR = [iso.v(bx + w, by + d, z0), iso.v(bx + w, by, z0), iso.v(bx + w, by, z1), iso.v(bx + w, by + d, z1)]
    o.append(P(gL, D.lin([(0, "#7fe3ff"), (1, "#2f9fe0")]), INK3, 0.9, 'fill-opacity="0.85"'))
    o.append(P(gR, D.lin([(0, "#5fcdf5"), (1, "#1f7fc6")]), INK3, 0.9, 'fill-opacity="0.85"'))
    t = plane(iso, "R", bx, by + d, z0)
    fish = ""
    for (u, v, c) in [(0.3, 14, "#ff7a2f"), (0.62, 22, "#ffd23f"), (0.45, 8, "#ff4d8d")]:
        fx = u * w * iso.W / 2
        fish += (f'<ellipse cx="{f(fx)}" cy="{f(-v*k)}" rx="{f(4*k)}" ry="{f(2.6*k)}" fill="{c}" stroke="{INK3}" stroke-width="0.5"/>'
                 f'<path d="M{f(fx-4*k)},{f(-v*k)} l{f(-3*k)},{f(-2*k)} l0,{f(4*k)} Z" fill="{c}"/>')
    fish += f'<path d="M{f(6*k)},0 q{f(3*k)},{f(-10*k)} 0,{f(-18*k)} M{f(10*k)},0 q{f(-3*k)},{f(-8*k)} 0,{f(-14*k)}" stroke="#2fbf4f" stroke-width="{f(1.6*k)}" fill="none"/>'
    o.append(f'<g transform="{t}">{fish}</g>')
    o.append(P([iso.v(bx, by, z1), iso.v(bx + w, by, z1), iso.v(bx + w, by + d, z1), iso.v(bx, by + d, z1)], "#bff1ff", INK3, 0.9, 'fill-opacity="0.6"'))
    o.append(line(gL[3][0] + 6, gL[3][1] + 4, gL[3][0] + 14 * k, gL[3][1] + 22 * k, "#ffffff", 2.0, 'opacity="0.8"'))
    return "".join(o)
