"""Cena v2 da cafeteria na esquina."""
from core import *
from furniture import *
from people import person, head_top
from food import balloon, mood_face, cooking_badge

N = 9
WALL_H = 140


# --- Exterior -------------------------------------------------------------------------

def grass_pattern(D):
    markup = ('<pattern id="grass" patternUnits="userSpaceOnUse" width="22" height="16">'
              '<rect width="22" height="16" fill="#79c267"/>'
              '<path d="M3,12 l1,-4 M5,13 l2,-4 M14,6 l1,-4 M16,7 l2,-3 M10,15 l1,-3" stroke="#5fae55" stroke-width="1.2" '
              'stroke-linecap="round"/><path d="M19,13 l1,-3 M8,5 l1,-3" stroke="#93d47e" stroke-width="1.2" stroke-linecap="round"/>'
              '</pattern>')
    return D.raw("grass", markup)


def asphalt_pattern(D):
    r = Rng(21)
    dots = "".join(f'<circle cx="{f(r.u(0,30))}" cy="{f(r.u(0,30))}" r="{f(r.u(0.4,1.1))}" fill="{"#80848b" if r.r() > 0.5 else "#5d6168"}"/>'
                   for _ in range(18))
    return D.raw("asphalt", f'<pattern id="asphalt" patternUnits="userSpaceOnUse" width="30" height="30"><rect width="30" height="30" fill="#6c7077"/>{dots}</pattern>')


def street(D, iso):
    o = []
    far = 40
    ga = asphalt_pattern(D)
    o.append(P([iso.v(-6, -far), iso.v(-2.6, -far), iso.v(-2.6, far), iso.v(-6, far)], ga, None))
    o.append(P([iso.v(-far, -6), iso.v(far, -6), iso.v(far, -2.6), iso.v(-far, -2.6)], ga, None))
    # calçadas com lajotas
    side = D.lin([(0, "#dcd6cb"), (1, "#cfc8bb")])
    o.append(P([iso.v(-2.6, -far), iso.v(-0.15, -far), iso.v(-0.15, N + 4), iso.v(-2.6, N + 4)], side, None))
    o.append(P([iso.v(-far, -2.6), iso.v(N + 4, -2.6), iso.v(N + 4, -0.15), iso.v(-far, -0.15)], side, None))
    for i in range(-14, N + 4):
        for (a, b) in [((-2.6, i), (-0.15, i)), ((i, -2.6), (i, -0.15))]:
            p0, p1 = iso.v(*a), iso.v(*b)
            o.append(line(p0[0], p0[1], p1[0], p1[1], "#b9b2a5", 1.0))
    for k in (-1.4,):
        p0, p1 = iso.v(k, -far), iso.v(k, N + 4)
        o.append(line(p0[0], p0[1], p1[0], p1[1], "#b9b2a5", 1.0))
        p0, p1 = iso.v(-far, k), iso.v(N + 4, k)
        o.append(line(p0[0], p0[1], p1[0], p1[1], "#b9b2a5", 1.0))
    # meio-fio com altura
    o.append(box(D, iso, -2.75, -far, 0.15, far + N + 4, 4, "#bdb6aa", bevel=False, sw=0.6))
    o.append(box(D, iso, -far, -2.75, far + N + 4, 0.15, 4, "#bdb6aa", bevel=False, sw=0.6))
    # faixas
    for i in range(-far, far):
        if -7 < i < -1:
            continue
        a, b = iso.v(-4.3, i + 0.1), iso.v(-4.3, i + 0.55)
        o.append(line(a[0], a[1], b[0], b[1], "#f2d45c", 3.2))
        a, b = iso.v(i + 0.1, -4.3), iso.v(i + 0.55, -4.3)
        o.append(line(a[0], a[1], b[0], b[1], "#f2d45c", 3.2))
    for k in range(6):
        y0 = -5.8 + k * 0.55
        o.append(P([iso.v(-2.5, y0), iso.v(-1.1, y0), iso.v(-1.1, y0 + 0.3), iso.v(-2.5, y0 + 0.3)], "#f4f1e8", None))
    # caminho da porta
    o.append(P([iso.v(N, 3.8), iso.v(N + 5, 3.8), iso.v(N + 5, 5.2), iso.v(N, 5.2)], D.lin([(0, "#e8dfcf"), (1, "#d6ccb9")]), INK, 1))
    for i in range(1, 5):
        a, b = iso.v(N + i, 3.8), iso.v(N + i, 5.2)
        o.append(line(a[0], a[1], b[0], b[1], "#bfb4a0", 1.0))
    return "".join(o)


def tree(D, x, y, s=1.0):
    o = [E(x, y, 34 * s, 11 * s, "#1c0d05", None, extra='opacity="0.2"')]
    o.append(path(f"M{f(x-6*s)},{f(y)} C{f(x-5*s)},{f(y-30*s)} {f(x-8*s)},{f(y-44*s)} {f(x-3*s)},{f(y-56*s)} L{f(x+4*s)},{f(y-56*s)} "
                  f"C{f(x+6*s)},{f(y-42*s)} {f(x+5*s)},{f(y-28*s)} {f(x+7*s)},{f(y)} Z", D.lin([(0, "#9a6a45"), (1, "#5e3b22")], 0, 0, 1, 0), INK, 1.2))
    for (dx, dy, r, c) in [(-22, -70, 26, "#3f8a3a"), (22, -72, 26, "#46953d"), (0, -58, 24, "#3f8a3a"), (-12, -96, 26, "#58a844"),
                           (14, -98, 25, "#5fb24a"), (0, -118, 22, "#6cc25a"), (-30, -92, 17, "#4f9c42"), (32, -92, 17, "#4f9c42")]:
        o.append(C(x + dx * s, y + dy * s, r * s, D.rad([(0, light(c, 0.35)), (0.6, c), (1, dark(c, 0.3))], 0.35, 0.3, 0.75), "#23511f", 1.2))
    r = Rng(int(x))
    for _ in range(12):
        o.append(C(x + r.u(-34, 34) * s, y + r.u(-120, -60) * s, 2.2 * s, "#a9e38a", None, extra='opacity="0.6"'))
    return "".join(o)


def bush(D, x, y, s=1.0, flowers=None):
    o = [E(x, y + 2, 26 * s, 8 * s, "#1c0d05", None, extra='opacity="0.18"')]
    for (dx, dy, r) in [(-14, -10, 13), (12, -10, 13), (0, -18, 15), (-2, -6, 13)]:
        o.append(C(x + dx * s, y + dy * s, r * s, D.rad([(0, "#8ed36a"), (0.6, "#4f9c42"), (1, "#2c6a2a")], 0.35, 0.3, 0.75), "#23511f", 1.1))
    if flowers:
        r = Rng(int(x + y))
        for _ in range(9):
            fx, fy = x + r.u(-20, 20) * s, y + r.u(-28, -4) * s
            o.append(C(fx, fy, 2.6 * s, flowers, "#7a2030", 0.6) + C(fx, fy, 0.9 * s, "#ffe066", None))
    return "".join(o)


def lamp_post(D, x, y, s=1.0):
    o = [E(x, y, 10 * s, 4 * s, "#1c0d05", None, extra='opacity="0.22"')]
    o.append(f'<rect x="{f(x-5*s)}" y="{f(y-10*s)}" width="{f(10*s)}" height="{f(10*s)}" rx="{f(2*s)}" fill="#2e2d33" stroke="{INK}" stroke-width="1"/>')
    o.append(f'<rect x="{f(x-2.2*s)}" y="{f(y-92*s)}" width="{f(4.4*s)}" height="{f(84*s)}" fill="#34333a" stroke="{INK}" stroke-width="1"/>')
    o.append(C(x, y - 104 * s, 26 * s, D.rad([(0, "#fff3b0", 0.6), (1, "#fff3b0", 0)]), None))
    o.append(path(f"M{f(x-9*s)},{f(y-92*s)} h{f(18*s)} l{f(-3*s)},{f(-20*s)} h{f(-12*s)} Z", D.lin([(0, "#fff6c4"), (1, "#ffd76b")]), INK, 1.1))
    o.append(path(f"M{f(x-11*s)},{f(y-112*s)} h{f(22*s)} l{f(-11*s)},{f(-8*s)} Z", "#2e2d33", INK, 1.0))
    return "".join(o)


def bench(D, iso, x, y):
    o = [box(D, iso, x, y, 0.12, 0.8, 14, "#3b3a40", bevel=False)]
    o.append(box(D, iso, x + 0.5, y, 0.12, 0.8, 14, "#3b3a40", bevel=False))
    o.append(box(D, iso, x - 0.05, y - 0.02, 0.72, 0.84, 4, "#b86f3f", z=14))
    o.append(box(D, iso, x - 0.05, y - 0.02, 0.1, 0.84, 18, "#a8643a", z=18))
    return "".join(o)


# --- Paredes ---------------------------------------------------------------------------

def _wall_face(D, iso, side, a, b, dark_k):
    """Papel de parede listrado, lambri com painéis e rodatetos de madeira, de a até b (em células)."""
    if side == "R":
        p0 = iso.v(a, 0)
        length = (b - a) * iso.W / 2
    else:
        p0 = iso.v(0, b)
        length = (b - a) * iso.W / 2
    wp = D.lin([(0, dark("#f7ebd3", dark_k)), (1, dark("#f1e1c2", dark_k + 0.04))])
    o = [f'<rect x="0" y="{-WALL_H}" width="{f(length)}" height="{WALL_H}" fill="{wp}" stroke="{INK}" stroke-width="1"/>']
    stripe = dark("#ead6b0", dark_k)
    x = 6
    while x < length:
        o.append(f'<rect x="{f(x)}" y="{-WALL_H+8}" width="7" height="{WALL_H-8-50}" fill="{stripe}" opacity="0.8"/>')
        o.append(f'<rect x="{f(x+9.5)}" y="{-WALL_H+8}" width="1" height="{WALL_H-8-50}" fill="#c9a24a" opacity="0.6"/>')
        x += 22
    # lambri
    o.append(f'<rect x="0" y="-50" width="{f(length)}" height="50" fill="{dark("#8e5634", dark_k)}"/>')
    x = 5
    while x + 30 < length:
        o.append(f'<rect x="{f(x)}" y="-43" width="30" height="34" rx="2" fill="{dark("#7a4728", dark_k)}" stroke="{dark("#a76a42", dark_k)}" stroke-width="1.4"/>')
        x += 36
    o.append(f'<rect x="0" y="-54" width="{f(length)}" height="6" fill="{dark("#6b3a20", dark_k)}" stroke="{INK}" stroke-width="0.8"/>')
    o.append(f'<rect x="0" y="-6" width="{f(length)}" height="6" fill="{dark("#5a3019", dark_k)}"/>')
    o.append(f'<rect x="0" y="{-WALL_H}" width="{f(length)}" height="9" fill="{dark("#6b3a20", dark_k)}" stroke="{INK}" stroke-width="0.8"/>')
    return g("".join(o), wall_matrix(p0, side))


def _kitchen_tiles(D, iso, a, b):
    """Azulejo branco (metrô) atrás dos fogões, na parede da esquerda, de y=a até y=b."""
    p0 = iso.v(0, b)
    length = (b - a) * iso.W / 2
    o = [f'<rect x="0" y="-118" width="{f(length)}" height="118" fill="#f7f7f4" stroke="{INK}" stroke-width="1"/>']
    for row in range(0, 118, 9):
        off = 0 if (row // 9) % 2 == 0 else 9
        o.append(f'<line x1="0" y1="{-row}" x2="{f(length)}" y2="{-row}" stroke="#d6d3cc" stroke-width="1"/>')
        x = off
        while x < length:
            o.append(f'<line x1="{f(x)}" y1="{-row}" x2="{f(x)}" y2="{-row-9}" stroke="#d6d3cc" stroke-width="1"/>')
            x += 18
    o.append(f'<rect x="0" y="-124" width="{f(length)}" height="6" fill="#5fc3a4" stroke="{INK}" stroke-width="0.8"/>')
    # prateleira com potes
    o.append(f'<rect x="{f(length*0.12)}" y="-128" width="{f(length*0.76)}" height="4" fill="#8e5634" stroke="{INK}" stroke-width="0.8"/>')
    r = Rng(4)
    x = length * 0.15
    while x < length * 0.85:
        hh = r.u(10, 16)
        col = ["#e2503f", "#f4c542", "#5fc3a4", "#f7f7f4", "#c98a5e"][int(r.u(0, 5))]
        o.append(f'<rect x="{f(x)}" y="{f(-128-hh)}" width="10" height="{f(hh)}" rx="2" fill="{col}" stroke="{INK}" stroke-width="0.8"/>')
        x += 14
    return g("".join(o), wall_matrix(p0, "L"))


def _window(D, u0, u1, z0=62, z1=124, curtain="#b8263a"):
    w = u1 - u0
    o = [f'<rect x="{f(u0-4)}" y="{-z1-4}" width="{f(w+8)}" height="{z1-z0+8}" fill="#fbf7ef" stroke="{INK}" stroke-width="1.2"/>']
    o.append(f'<rect x="{f(u0+2)}" y="{-z1+2}" width="{f(w-4)}" height="{z1-z0-4}" fill="{D.lin([(0, "#9fd8f3"), (0.7, "#d9f1fb"), (1, "#f4fbff")])}" stroke="{INK}" stroke-width="0.9"/>')
    o.append(f'<ellipse cx="{f(u0+w*0.35)}" cy="{-z1+18}" rx="{f(w*0.22)}" ry="5" fill="#ffffff" opacity="0.9"/>')
    o.append(f'<ellipse cx="{f(u0+w*0.52)}" cy="{-z1+15}" rx="{f(w*0.16)}" ry="6" fill="#ffffff" opacity="0.9"/>')
    o.append(f'<path d="M{f(u0+6)},{-z0-6} L{f(u0+w*0.4)},{-z1+6} M{f(u0+w*0.28)},{-z0-6} L{f(u0+w*0.62)},{-z1+6}" stroke="#ffffff" stroke-width="3" opacity="0.55"/>')
    o.append(f'<rect x="{f(u0+w/2-1.6)}" y="{-z1+2}" width="3.2" height="{z1-z0-4}" fill="#fbf7ef" stroke="{INK}" stroke-width="0.7"/>')
    o.append(f'<rect x="{f(u0+2)}" y="{f(-(z0+z1)/2-1.6)}" width="{f(w-4)}" height="3.2" fill="#fbf7ef" stroke="{INK}" stroke-width="0.7"/>')
    o.append(f'<rect x="{f(u0-8)}" y="{-z0}" width="{f(w+16)}" height="6" fill="#efe5d2" stroke="{INK}" stroke-width="1"/>')
    # cortinas com dobras e prendedor
    for side in (0, 1):
        x0 = u0 - 10 if side == 0 else u1 - 6
        cw = 16
        fold = D.lin([(0, dark(curtain, 0.25)), (0.3, light(curtain, 0.15)), (0.6, curtain), (1, dark(curtain, 0.3))], 0, 0, 1, 0)
        o.append(f'<path d="M{f(x0)},{-z1-10} h{cw} v{z1-z0-18} q{-cw/2 if side == 0 else cw/2},6 {-cw/2 if side == 0 else cw/2},22 '
                 f'h{-cw/2 if side == 0 else -cw*1.5} q{-2 if side == 0 else 2},-12 0,-24 Z" fill="{fold}" stroke="{INK}" stroke-width="1"/>')
        o.append(f'<rect x="{f(x0+2)}" y="{-z0-24}" width="{cw-4}" height="4" rx="2" fill="#f2b632" stroke="{INK}" stroke-width="0.7"/>')
    o.append(f'<path d="M{f(u0-12)},{-z1-12} h{f(w+24)} v10 q{f(-(w+24)/8)},8 {f(-(w+24)/4)},0 q{f(-(w+24)/8)},8 {f(-(w+24)/4)},0 '
             f'q{f(-(w+24)/8)},8 {f(-(w+24)/4)},0 q{f(-(w+24)/8)},8 {f(-(w+24)/4)},0 Z" fill="{dark(curtain, 0.15)}" stroke="{INK}" stroke-width="1"/>')
    return "".join(o)


def _painting(D, u, z, w, h, kind="paisagem"):
    o = [f'<rect x="{f(u)}" y="{f(-z-h)}" width="{f(w)}" height="{f(h)}" fill="{D.lin([(0, "#f7d57a"), (1, "#c9922e")])}" stroke="{INK}" stroke-width="1.1"/>']
    ix, iy, iw, ih = u + 4, -z - h + 4, w - 8, h - 8
    if kind == "paisagem":
        o.append(f'<rect x="{f(ix)}" y="{f(iy)}" width="{f(iw)}" height="{f(ih)}" fill="{D.lin([(0, "#8fd0f0"), (1, "#e7f6ff")])}"/>')
        o.append(f'<path d="M{f(ix)},{f(iy+ih)} L{f(ix)},{f(iy+ih*0.6)} Q{f(ix+iw*0.3)},{f(iy+ih*0.35)} {f(ix+iw*0.55)},{f(iy+ih*0.6)} '
                 f'Q{f(ix+iw*0.8)},{f(iy+ih*0.45)} {f(ix+iw)},{f(iy+ih*0.55)} L{f(ix+iw)},{f(iy+ih)} Z" fill="#5da84e"/>')
        o.append(f'<circle cx="{f(ix+iw*0.78)}" cy="{f(iy+ih*0.28)}" r="{f(ih*0.12)}" fill="#ffd23f"/>')
    else:  # xícara estilizada
        o.append(f'<rect x="{f(ix)}" y="{f(iy)}" width="{f(iw)}" height="{f(ih)}" fill="#f4e3c3"/>')
        o.append(f'<path d="M{f(ix+iw*0.25)},{f(iy+ih*0.4)} h{f(iw*0.5)} l{f(-iw*0.05)},{f(ih*0.35)} h{f(-iw*0.4)} Z" fill="#c2353f"/>')
        o.append(f'<path d="M{f(ix+iw*0.4)},{f(iy+ih*0.3)} q-3,-5 0,-9 M{f(ix+iw*0.55)},{f(iy+ih*0.3)} q-3,-5 0,-9" stroke="#8a5534" stroke-width="1.4" fill="none"/>')
    return "".join(o)


def _chalkboard(D, u, z, w=110, h=66):
    o = [f'<rect x="{f(u)}" y="{f(-z-h)}" width="{w}" height="{h}" rx="3" fill="#8e5634" stroke="{INK}" stroke-width="1.2"/>']
    o.append(f'<rect x="{f(u+5)}" y="{f(-z-h+5)}" width="{w-10}" height="{h-10}" rx="2" fill="#2f3b33"/>')
    tx = u + w / 2
    o.append(f'<text x="{f(tx)}" y="{f(-z-h+19)}" text-anchor="middle" font-family="Fredoka, Nunito, sans-serif" font-weight="600" font-size="12" fill="#f4f1e8">CARDÁPIO</text>')
    lines_ = [("Café", "3"), ("Pão de queijo", "4"), ("Misto-quente", "6"), ("Bolo de cenoura", "7")]
    for i, (n, p) in enumerate(lines_):
        y = -z - h + 31 + i * 8.6
        o.append(f'<text x="{f(u+10)}" y="{f(y)}" font-family="Nunito, sans-serif" font-weight="700" font-size="7" fill="#e9e4d6">{n}</text>')
        o.append(f'<text x="{f(u+w-10)}" y="{f(y)}" text-anchor="end" font-family="Nunito, sans-serif" font-weight="700" font-size="7" fill="#f7d57a">{p}</text>')
    return "".join(o)


def _sconce(D, u, z):
    return (f'<circle cx="{f(u)}" cy="{f(-z)}" r="22" fill="{D.rad([(0, "#fff3b0", 0.65), (1, "#fff3b0", 0)])}"/>'
            f'<rect x="{f(u-2)}" y="{f(-z+4)}" width="4" height="10" fill="#c9922e" stroke="{INK}" stroke-width="0.8"/>'
            f'<path d="M{f(u-8)},{f(-z+4)} l3,-12 h10 l3,12 Z" fill="{D.lin([(0, "#fff6c4"), (1, "#ffd76b")])}" stroke="{INK}" stroke-width="1"/>')


def walls(D, iso):
    o = []
    # parede da direita (y = 0): papel de parede, janelas, cardápio, quadro, arandelas
    o.append(_wall_face(D, iso, "R", 0, N, 0.0))
    deco_R = [_window(D, 2.3 * 48, 3.7 * 48), _window(D, 6.1 * 48, 7.5 * 48), _chalkboard(D, 4.25 * 48, 66, 98, 62),
              _painting(D, 8.05 * 48, 74, 34, 44, "xicara"), _sconce(D, 1.6 * 48, 112), _sconce(D, 5.8 * 48, 114)]
    o.append(g("".join(deco_R), wall_matrix(iso.v(0, 0), "R")))
    # parede da esquerda (x = 0): azulejo da cozinha até y=5.2 e salão depois
    o.append(_wall_face(D, iso, "L", 0, N, 0.1))
    o.append(_kitchen_tiles(D, iso, 0.0, 5.2))
    deco_L = [_window(D, (N - 8.1) * 48, (N - 6.7) * 48, curtain="#b8263a"), _painting(D, (N - 6.1) * 48, 70, 42, 34)]
    o.append(g("".join(deco_L), wall_matrix(iso.v(0, N), "L")))
    # coifa sobre os fogões
    o.append(box(D, iso, 0.0, 1.0, 0.62, 4.0, 16, "#c9cfd6", z=106, top="#e3e7eb"))
    o.append(box(D, iso, 0.0, 1.2, 0.3, 3.6, 12, "#b3bac2", z=122, top="#d7dce1"))
    return "".join(o)


def front_walls(D, iso):
    """Mureta baixa de tijolinho nas bordas da frente, com a porta."""
    o = []
    t, hh = 0.14, 18
    for (x, y, w, d) in [(0, N - t, N, t), (N - t, 0, t, 3.8), (N - t, 5.2, t, N - 5.2 - t)]:
        o.append(box(D, iso, x, y, w, d, hh, "#b8563a", top="#e9dcc3"))
    o.append(box(D, iso, N - 0.8, 4.0, 0.6, 1.0, 1.5, "#6b3a20", top="#8e5634"))
    return "".join(o)


def aframe_sign(D, iso, x, y):
    """Cavalete de lousa na calçada: 'Aberto'."""
    px, py = iso.v(x, y)
    o = [E(px, py, 16, 5, "#1c0d05", None, extra='opacity="0.2"')]
    o.append(path(f"M{f(px-14)},{f(py)} L{f(px-8)},{f(py-44)} L{f(px+8)},{f(py-44)} L{f(px+14)},{f(py)}", "none", "#6b3a20", 3))
    o.append(path(f"M{f(px-12)},{f(py-4)} L{f(px-7)},{f(py-40)} L{f(px+7)},{f(py-40)} L{f(px+12)},{f(py-4)} Z", "#2f3b33", INK, 1.1))
    o.append(f'<text x="{f(px)}" y="{f(py-24)}" text-anchor="middle" font-family="Fredoka, Nunito, sans-serif" font-weight="600" font-size="8.5" fill="#f4f1e8">Aberto</text>')
    o.append(path(f"M{f(px-6)},{f(py-14)} q6,-4 12,0", "none", "#f7d57a", 1.2))
    return "".join(o)


def floor(D, iso):
    o = []
    ga = D.lin([(0, "#f8ecd4"), (1, "#eadbbc")], 0, 0, 1, 1)
    gb = D.lin([(0, "#c6503f"), (1, "#a63d31")], 0, 0, 1, 1)
    for y in range(N):
        for x in range(N):
            poly_ = [iso.v(x, y), iso.v(x + 1, y), iso.v(x + 1, y + 1), iso.v(x, y + 1)]
            o.append(P(poly_, ga if (x + y) % 2 == 0 else gb, "#00000030", 0.6))
    # tapete na entrada do salão
    o.append(P([iso.v(5.2, 3.7), iso.v(8.9, 3.7), iso.v(8.9, 5.3), iso.v(5.2, 5.3)], "#8b1f2d", INK, 1.1))
    o.append(P([iso.v(5.4, 3.9), iso.v(8.7, 3.9), iso.v(8.7, 5.1), iso.v(5.4, 5.1)], "none", "#f2b632", 1.6))
    o.append(P([iso.v(0, 0), iso.v(N, 0), iso.v(N, N), iso.v(0, N)], "none", INK, 1.6))
    return "".join(o)


# --- Montagem --------------------------------------------------------------------------

CAST = [
    # (cadeira, voltada para, pele, cabelo, roupa, calça, expressão, pedido/estado, extras)
    ((3, 2), "+x", "clara", ("rabo", "castanho"), ("blusa", "#e2503f"), ("calca", "#34495e"), "feliz", ("balao", "cafe", 0.9), {"lashes": True}),
    ((4, 1), "+y", "negra", ("black", "preto"), ("camiseta", "#f4c542"), ("calca", "#5da84e"), "comendo", ("prato", "bolo"), {"lashes": True}),
    ((6, 2), "+x", "morena", ("topete", "preto"), ("camisa", "#8fd0f0"), ("calca", "#3b4a55"), "esperando", ("balao", "misto", 0.45), {}),
    ((7, 1), "+y", "clara", ("chanel", "grisalho"), ("blusa", "#c7355a"), ("saia", "#6b3f26"), "feliz", ("humor", "feliz"), {"glasses": True, "lashes": True}),
    ((3, 5), "+x", "morena_clara", ("longo", "ruivo"), ("blusa", "#5fc3a4"), ("saia", "#3d5a80"), "feliz", ("balao", "pao", 0.75), {"lashes": True, "freckles": True}),
    ((4, 4), "+y", "parda", ("bone", "preto"), ("moletom", "#3d7fc9"), ("calca", "#2b2b33"), "bravo", ("humor", "bravo"), {"cap": "#e2503f"}),
    ((6, 5), "+x", "clara", ("curto", "loiro"), ("camiseta", "#e8813a"), ("calca", "#3b4a55"), "comendo", ("prato", "misto"), {}),
    ((7, 4), "+y", "negra", ("coque", "preto"), ("camisa", "#ffffff"), ("calca", "#6b3f26"), "esperando", ("balao", "coxinha", 0.2), {"lashes": True}),
    ((5, 5), "-x", "morena", ("curto", "castanho"), ("moletom", "#c7355a"), ("calca", "#34495e"), "feliz", None, {}),
    ((3, 8), "+x", "clara", ("chanel", "castanho"), ("blusa", "#f08aa6"), ("calca", "#34495e"), "feliz", ("balao", "lasanha", 0.6), {"lashes": True}),
    ((4, 7), "+y", "morena_clara", ("curto", "preto"), ("camisa", "#5da84e"), ("calca", "#3b4a55"), "feliz", ("humor", "feliz"), {"beard": True}),
    ((7, 3), "-y", "negra", ("black", "preto"), ("blusa", "#8fd0f0"), ("calca", "#34495e"), "feliz", None, {}),
]
TABLES = [((4, 2), "#d83a3a"), ((7, 2), "#2f8f5a"), ((4, 5), "#2f8f5a"), ((7, 5), "#d83a3a"), ((4, 8), "#d83a3a"), ((7, 8), "#2f8f5a")]
STOVES = [((0, 1), "lasanha", 0.7, "2:40", False), ((0, 2), "pao", 1.0, "", True), ((0, 3), "misto", 0.35, "0:58", False),
          ((0, 4), "cafe", 0.85, "0:03", False)]
COUNTERS = [((1, 2), [("cafe", 12)]), ((1, 3), [("pao", 16), ("coxinha", 8)]), ((1, 4), [("bolo", 8)])]
PERSON_SCALE = 0.86


def build(D, iso):
    items = []   # (profundidade, svg)
    overlay = []

    def add(depth, svg):
        items.append((depth, svg))

    add(0.5, pastry_case(D, iso, 0, 0))
    add(1.6, espresso(D, iso, 1, 1))
    for (cell, cook, prog, lab, ready) in STOVES:
        add(cell[0] + cell[1] + 0.5, stove(D, iso, cell[0], cell[1], "R", cooking=cook))
        bx, by = iso.v(cell[0] + 0.5, cell[1] + 0.5, 122)
        overlay.append(cooking_badge(D, cook, bx, by, prog, lab, ready))
    for (cell, dishes) in COUNTERS:
        add(cell[0] + cell[1] + 0.5, counter(D, iso, cell[0], cell[1], "R", dishes))
    add(0 + 6 + 0.5, plant(D, iso, 0, 6, big=True, seed=5))
    add(2 + 0.4, jukebox(D, iso, 2, 0))
    add(5 + 0.4, floor_lamp(D, iso, 5, 0))
    add(8.5, plant(D, iso, 8, 0, big=True, seed=9))
    add(8.3, plant(D, iso, 0, 8, big=False, seed=12))
    served = {c[0]: c[7][1] for c in CAST if c[7] and c[7][0] == "prato"}
    for (cell, cloth) in TABLES:
        tx, ty = cell
        dishes = [k for (cc, k) in served.items() if abs(cc[0] - tx) + abs(cc[1] - ty) == 1]
        add(tx + ty + 0.5, round_table(D, iso, tx, ty, cloth, dishes=dishes))
    occupied = {c[0] for c in CAST}
    for (cell, _) in TABLES:
        tx, ty = cell
        for (cc, fc) in [((tx - 1, ty), "+x"), ((tx, ty - 1), "+y")]:
            if cc not in occupied:
                add(cc[0] + cc[1] + 0.4, chair(D, iso, cc[0], cc[1], fc))
    for (cell, facing, skin, hair, top, bottom, expr, need, extra) in CAST:
        cx, cy = cell
        ch = chair(D, iso, cx, cy, facing)
        sx, sy = iso.v(cx + 0.5, cy + 0.5, 30)
        mirror = 1 if facing in ("+x", "-x") else -1
        is_back = facing in ("-x", "-y")
        mirror = {"+x": 1, "+y": -1, "-x": -1, "-y": 1}[facing]
        who = person(D, sx, sy, PERSON_SCALE, mirror, "sentado", skin, hair, top, bottom, expr=expr, back=is_back, **extra)
        if is_back:
            legs_seat, backrest = ch
            add(cx + cy + 0.4, legs_seat + who + backrest)
        else:
            add(cx + cy + 0.4, ch + who)
        if need:
            top_y = head_top(sy, PERSON_SCALE, "sentado")
            if need[0] == "balao":
                overlay.append(balloon(D, need[1], sx + 6 * mirror, top_y - 2, 40, patience=need[2]))
            elif need[0] == "humor":
                overlay.append(mood_face(D, sx + 18 * mirror, top_y - 4, need[1], 12))
    # equipe e clientes chegando
    wx, wy = iso.v(5.6, 3.5)
    add(9.2, person(D, wx, wy, PERSON_SCALE, 1, "andar", "morena_clara", ("curto", "preto"), ("garcom", "#ffffff"), ("calca", "#23232b"), tray="misto"))
    cx_, cy_ = iso.v(1.5, 5.6)
    add(7.2, person(D, cx_, cy_, PERSON_SCALE, 1, "em_pe", "negra", ("black", "preto"), ("chef", "#ffffff"), ("calca", "#3b4a55"),
                    apron="#ffffff", hat="chef", lashes=True))
    for (gx, gy, skin, hair, top, bottom, facing) in [
        (8.3, 4.6, "clara", ("longo", "loiro"), ("blusa", "#f4c542"), ("saia", "#c7355a"), -1),
        (9.5, 4.2, "parda", ("curto", "preto"), ("camiseta", "#3d7fc9"), ("calca", "#2b2b33"), -1),
        (10.6, 4.7, "morena_clara", ("rabo", "mel"), ("moletom", "#5fc3a4"), ("calca", "#34495e"), -1),
    ]:
        px, py = iso.v(gx, gy)
        add(gx + gy + 0.5, person(D, px, py, PERSON_SCALE, facing, "andar", skin, hair, top, bottom, lashes=True))
    items.sort(key=lambda it: it[0])
    return "".join(s for _, s in items), "".join(overlay)


def scene_svg(width=1280, height=720, ox=640, oy=186, scale=1.0):
    D = Defs()
    iso = Iso(0, 0)
    body, overlay = build(D, iso)
    ext = street(D, iso)
    deco = []
    for (x, y, s_) in [(-1.3, 12.0, 0.9), (12.0, -1.3, 0.9), (-1.3, -1.3, 0.9)]:
        p = iso.v(x, y)
        deco.append(lamp_post(D, p[0], p[1], s_))
    front_deco = []
    for (x, y) in [(2.0, 11.8), (12.4, 2.4)]:
        p = iso.v(x, y)
        front_deco.append(tree(D, p[0], p[1], 0.9))
    for (x, y, fl) in [(4.6, 10.2, "#f25f7a"), (6.8, 10.2, "#ffd23f"), (10.2, 7.2, "#f25f7a"), (10.2, 1.6, "#ffffff")]:
        p = iso.v(x, y)
        front_deco.append(bush(D, p[0], p[1], 0.9, fl))
    front_deco.append(bench(D, iso, 10.4, 6.0))
    front_deco.append(aframe_sign(D, iso, 10.3, 3.2))
    fx, fy = iso.v(5.3, 3.6, 125)
    floats = (f'<text x="{f(fx)}" y="{f(fy)}" text-anchor="middle" font-family="Fredoka, Nunito, sans-serif" font-weight="700" font-size="22" '
              f'fill="none" stroke="{INK}" stroke-width="5" stroke-linejoin="round">+18</text>'
              f'<text x="{f(fx)}" y="{f(fy)}" text-anchor="middle" font-family="Fredoka, Nunito, sans-serif" font-weight="700" font-size="22" fill="#ffd23f">+18</text>')
    content = (f'<rect x="0" y="0" width="{width}" height="{height}" fill="{grass_pattern(D)}"/>'
               f'<g transform="translate({ox},{oy}) scale({scale})">{ext}{"".join(deco)}{walls(D, iso)}{floor(D, iso)}'
               f'{body}{front_walls(D, iso)}{"".join(front_deco)}{overlay}{floats}</g>')
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">'
            + D.render() + content + "</svg>")


if __name__ == "__main__":
    import sys
    open(sys.argv[1], "w").write(scene_svg())
