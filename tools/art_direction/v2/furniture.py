"""Móveis v2 com pernas, tampo, estofado, metal e vidro (tile 96x48; 1 célula ≈ 1 m)."""
from core import *
from food import food

WOOD = "#9a5b33"
WOOD_DARK = "#6a3a20"
STEEL = "#b9c1c9"
IRON = "#3b3a40"


def gingham(D, color="#d83a3a", size=0.1):
    """Xadrez de toalha deitado no chão isométrico (padrão com a mesma inclinação do piso)."""
    key = "ging" + color[1:]
    a, b = 48 * size, 24 * size
    markup = (f'<pattern id="{key}" patternUnits="userSpaceOnUse" width="2" height="2" '
              f'patternTransform="matrix({f(a)},{f(b)},{f(-a)},{f(b)},0,0)">'
              f'<rect width="2" height="2" fill="#fffaf2"/>'
              f'<rect width="1" height="2" fill="{color}" opacity="0.55"/>'
              f'<rect width="2" height="1" fill="{color}" opacity="0.55"/></pattern>')
    return D.raw(key, markup)


def stripes_v(D, color="#d83a3a"):
    key = "strv" + color[1:]
    markup = (f'<pattern id="{key}" patternUnits="userSpaceOnUse" width="7" height="7">'
              f'<rect width="7" height="7" fill="#fffaf2"/><rect width="3.5" height="7" fill="{color}" opacity="0.55"/></pattern>')
    return D.raw(key, markup)


def round_table(D, iso, x, y, cloth="#d83a3a", h=38, r=0.4, dishes=()):
    cx, cy = x + 0.5, y + 0.5
    o = [shadow(iso, cx, cy, r * 1.1, 0.2)]
    o.append(cylinder(D, iso, cx, cy, 0.17, 0, 3, IRON))
    o.append(cylinder(D, iso, cx, cy, 0.035, 3, h - 10, IRON, cap=False))
    sx, st, rx, ry = iso.ell(cx, cy, h, r)
    drop = 13
    # saia da toalha com babado
    n = 9
    hem = []
    for i in range(n + 1):
        th = math.pi * i / n
        hem.append((sx + rx * 1.03 * math.cos(th), st + drop + ry * 1.03 * math.sin(th)))
    d = f"M{f(sx+rx)},{f(st)} L{f(hem[0][0])},{f(hem[0][1])}"
    for i in range(1, len(hem)):
        (x0, y0), (x1, y1) = hem[i - 1], hem[i]
        d += f" Q{f((x0+x1)/2)},{f((y0+y1)/2+3.2)} {f(x1)},{f(y1)}"
    d += f" L{f(sx-rx)},{f(st)} A{f(rx)},{f(ry)} 0 0 0 {f(sx+rx)},{f(st)} Z"
    o.append(path(d, stripes_v(D, cloth), INK, 1.1))
    o.append(path(d, D.lin([(0, "#000000", 0.22), (0.3, "#000000", 0.0), (0.7, "#000000", 0.05), (1, "#000000", 0.35)], 0, 0, 1, 0), None))
    for i in range(1, n, 2):
        (x1, y1) = hem[i]
        o.append(line(x1, y1 - drop + 3, x1, y1 - 1, "#000000", 1.0, 'opacity="0.12"'))
    # tampo com xadrez deitado
    o.append(E(sx, st, rx, ry, gingham(D, cloth), INK, 1.2))
    o.append(E(sx - rx * 0.2, st - ry * 0.25, rx * 0.55, ry * 0.45, "#ffffff", None, extra='opacity="0.28"'))
    spots = [(-0.14, -0.05), (0.12, 0.1)]
    for i, kind in enumerate(dishes):
        dx, dy = spots[i % 2]
        px, py = iso.v(cx + dx, cy + dy, h)
        o.append(E(px, py + 2, 13, 5, "#ffffff", INK, 0.9) + E(px, py + 2.2, 8, 3, "#efe9df", None))
        o.append(food(D, kind, px, py - 4, 24))
    if not dishes:
        px, py = iso.v(cx, cy, h)
        o.append(cylinder(D, iso, cx, cy, 0.05, h, h + 10, "#9fd3e8") + C(px - 2, py - 16, 3.4, "#f25f7a", INK, 0.9)
                 + C(px + 3, py - 14, 3, "#ffd23f", INK, 0.9) + path(f"M{f(px)},{f(py-10)} L{f(px-1)},{f(py-16)}", "none", "#3f8f3a", 1.2))
    return "".join(o)


def chair(D, iso, x, y, facing="+x", wood=WOOD_DARK, cushion="#c2323c"):
    """Cadeira de bistrô. facing = para onde a pessoa sentada olha."""
    s0, s1 = 0.3, 0.7
    leg = 0.06
    seat_z = 24
    o_back_rest, o_legs, o_seat = [], [], []
    legs = [(x + s0, y + s0), (x + s1 - leg, y + s0), (x + s0, y + s1 - leg), (x + s1 - leg, y + s1 - leg)]
    legs.sort(key=lambda p: p[0] + p[1])
    for (lx, ly) in legs:
        o_legs.append(box(D, iso, lx, ly, leg, leg, seat_z, wood, sw=0.8, bevel=False))
    o_seat.append(box(D, iso, x + s0 - 0.02, y + s0 - 0.02, s1 - s0 + 0.04, s1 - s0 + 0.04, 3, wood, z=seat_z, sw=0.9))
    o_seat.append(box(D, iso, x + s0 + 0.01, y + s0 + 0.01, s1 - s0 - 0.02, s1 - s0 - 0.02, 5, cushion, z=seat_z + 3, sw=0.9))
    top_z = 58
    if facing in ("+x", "-x"):
        bx = x + s0 if facing == "+x" else x + s1 - leg
        posts = [(bx, y + s0), (bx, y + s1 - leg)]
        rail = lambda z0, hh: box(D, iso, bx, y + s0, leg, s1 - s0, hh, wood, z=z0, sw=0.8)
        slats = [box(D, iso, bx + 0.005, y + s0 + t, leg * 0.8, 0.035, 14, wood, z=seat_z + 26, sw=0.6, bevel=False)
                 for t in (0.1, 0.18, 0.26)]
    else:
        by = y + s0 if facing == "+y" else y + s1 - leg
        posts = [(x + s0, by), (x + s1 - leg, by)]
        rail = lambda z0, hh: box(D, iso, x + s0, by, s1 - s0, leg, hh, wood, z=z0, sw=0.8)
        slats = [box(D, iso, x + s0 + t, by + 0.005, 0.035, leg * 0.8, 14, wood, z=seat_z + 26, sw=0.6, bevel=False)
                 for t in (0.1, 0.18, 0.26)]
    for (px, py) in posts:
        o_back_rest.append(box(D, iso, px, py, leg, leg, top_z - seat_z, wood, z=seat_z, sw=0.8, bevel=False))
    o_back_rest.append(rail(seat_z + 16, 5))
    o_back_rest.extend(slats)
    o_back_rest.append(rail(top_z - 7, 8))
    if facing in ("+x", "+y"):
        return "".join(o_legs + o_back_rest + o_seat)
    return "".join(o_legs + o_seat), "".join(o_back_rest)


def _burner(D, iso, cx, cy, z, flame=False):
    sx, sy, rx, ry = iso.ell(cx, cy, z, 0.13)
    o = [E(sx, sy, rx, ry, "#1c1c21", INK, 0.8), E(sx, sy, rx * 0.55, ry * 0.55, "#4d4f57", None)]
    o.append(line(sx - rx, sy, sx + rx, sy, "#6d7078", 1.1) + line(sx, sy - ry, sx, sy + ry, "#6d7078", 1.1))
    if flame:
        o.append(E(sx, sy - 0.5, rx * 0.72, ry * 0.72, "none", "#4aa8ff", 2.2, 'opacity="0.9"'))
        o.append(E(sx, sy - 1, rx * 0.72, ry * 0.72, "none", "#ffb347", 1.0, 'opacity="0.8"'))
    return "".join(o)


def _steam(x, y, k=1.0):
    return "".join(C(x + dx * k, y + dy * k, r * k, "#ffffff", None, extra=f'opacity="{op}"')
                   for dx, dy, r, op in [(0, 0, 5, 0.55), (4, -7, 6, 0.45), (-2, -15, 7, 0.35), (3, -24, 6, 0.25)])


def cookware(D, iso, kind, cx, cy, z):
    """Utensílio no fogão já mostrando a comida."""
    o = []
    sx, sy = iso.v(cx, cy, z)
    if kind == "cafe":      # bule italiano (moka)
        o.append(cylinder(D, iso, cx, cy, 0.09, z, z + 12, "#c7ccd2"))
        o.append(cylinder(D, iso, cx, cy, 0.1, z + 12, z + 26, "#dfe3e7"))
        o.append(path(f"M{f(sx+9)},{f(sy-24)} l7,-4 l-1,5 Z", "#c7ccd2", INK, 0.9))
        o.append(path(f"M{f(sx-9)},{f(sy-14)} q-8,0 -7,-8", "none", "#2d2d33", 2.6))
        o.append(_steam(sx + 16, sy - 32, 0.8))
    elif kind in ("pao", "coxinha"):  # assadeira / tacho
        if kind == "pao":
            o.append(box(D, iso, cx - 0.28, cy - 0.28, 0.56, 0.56, 3, "#4a4c54", z=z, sw=0.9))
            for i in range(3):
                for j in range(3):
                    px, py = iso.v(cx - 0.18 + i * 0.18, cy - 0.18 + j * 0.18, z + 3)
                    o.append(C(px, py - 4, 5.2, D.rad([(0, "#fff0bf"), (0.4, "#f5cd6c"), (1, "#c98a2e")], 0.4, 0.35, 0.7), "#7e4c17", 0.8))
        else:
            o.append(cylinder(D, iso, cx, cy, 0.22, z, z + 12, "#3e4048", top="#2b2c31"))
            ex, ey, erx, ery = iso.ell(cx, cy, z + 11, 0.19)
            o.append(E(ex, ey, erx, ery, "#e8b24a", None, extra='opacity="0.85"'))
            for (dx, dy) in [(-0.07, -0.02), (0.06, 0.03), (0.0, 0.08)]:
                px, py = iso.v(cx + dx, cy + dy, z + 12)
                o.append(path(f"M{f(px)},{f(py-9)} C{f(px+5)},{f(py-5)} {f(px+5)},{f(py+1)} {f(px)},{f(py+1.5)} "
                              f"C{f(px-5)},{f(py+1)} {f(px-5)},{f(py-5)} {f(px)},{f(py-9)} Z", "#e0913b", "#6d3a12", 0.8))
            o.append(_steam(sx, sy - 22, 0.8))
    elif kind == "misto":   # chapa com sanduíches
        o.append(box(D, iso, cx - 0.3, cy - 0.3, 0.6, 0.6, 4, "#2f3036", z=z, sw=0.9))
        for (dx, dy) in [(-0.1, -0.08), (0.12, 0.1)]:
            o.append(box(D, iso, cx + dx - 0.1, cy + dy - 0.1, 0.2, 0.2, 5, "#e3a651", z=z + 4, sw=0.8))
            px, py = iso.v(cx + dx, cy + dy, z + 9)
            o.append(line(px - 5, py, px + 5, py, "#9b5a24", 1.4, 'opacity="0.6"'))
        o.append(_steam(sx, sy - 20, 0.7))
    elif kind == "bolo":    # forma redonda com massa assando
        o.append(cylinder(D, iso, cx, cy, 0.2, z, z + 10, "#6b6e76"))
        ex, ey, erx, ery = iso.ell(cx, cy, z + 10, 0.17)
        o.append(E(ex, ey, erx, ery, D.rad([(0, "#ffc16b"), (1, "#e8841e")]), None))
    elif kind == "lasanha":  # travessa
        o.append(box(D, iso, cx - 0.26, cy - 0.2, 0.52, 0.4, 9, "#f2ece2", z=z, sw=0.9))
        o.append(box(D, iso, cx - 0.22, cy - 0.16, 0.44, 0.32, 1, "#e9ad3f", z=z + 8, sw=0, bevel=False))
        for (dx, dy) in [(-0.1, -0.05), (0.08, 0.04), (0.0, 0.1)]:
            px, py = iso.v(cx + dx, cy + dy, z + 9)
            o.append(E(px, py, 3.4, 1.8, "#b0621f", None, extra='opacity="0.8"'))
        o.append(_steam(sx, sy - 20, 0.8))
    elif kind == "panela":
        o.append(cylinder(D, iso, cx, cy, 0.2, z, z + 20, STEEL))
        ex, ey, erx, ery = iso.ell(cx, cy, z + 19, 0.17)
        o.append(E(ex, ey, erx, ery, "#c7412b", None))
    return "".join(o)


def stove(D, iso, x, y, front="R", cooking=None, flame=True):
    bx, by, w, d, h = x + 0.04, y + 0.04, 0.92, 0.92, 46
    o = [shadow(iso, x + 0.5, y + 0.5, 0.55, 0.18)]
    o.append(box(D, iso, bx, by, w, d, h, STEEL, top="#dfe4e8"))
    # tampo de cocção
    top = [iso.v(bx + 0.06, by + 0.06, h), iso.v(bx + w - 0.06, by + 0.06, h), iso.v(bx + w - 0.06, by + d - 0.06, h), iso.v(bx + 0.06, by + d - 0.06, h)]
    o.append(P(top, D.lin([(0, "#3b3d44"), (1, "#23242a")], 0, 0, 1, 1), INK, 0.9))
    burners = [(0.3, 0.3), (0.72, 0.3), (0.3, 0.72), (0.72, 0.72)]
    for i, (u, v) in enumerate(burners):
        o.append(_burner(D, iso, bx + u * w, by + v * d, h, flame and cooking is not None and i == 3))
    # frente: painel de botões, porta do forno com vidro e puxador
    q = lambda u0, u1, v0, v1: iso.quad(front, bx, by, w, d, 0, h, u0, u1, v0, v1)
    o.append(P(q(0.04, 0.96, 0.8, 0.96), D.lin([(0, "#8f98a2"), (1, "#6d757e")]), INK, 0.8))
    for u in (0.18, 0.39, 0.61, 0.82):
        px, py = iso.face_center(front, bx, by, w, d, 0, h, u, 0.88)
        o.append(C(px, py, 3.3, "#26272c", INK, 0.7) + line(px, py, px, py - 2.4, "#e7e9ec", 1.0))
    o.append(P(q(0.08, 0.92, 0.1, 0.72), D.lin([(0, "#d3d9df"), (1, "#a9b2bb")]), INK, 0.9))
    o.append(P(q(0.18, 0.82, 0.2, 0.6), D.lin([(0, "#3a2a24"), (1, "#1c1512")]), INK, 0.9))
    if cooking:
        o.append(P(q(0.24, 0.76, 0.24, 0.52), "#ff9a3c", None, 'opacity="0.35"'))
    o.append(P(q(0.14, 0.86, 0.66, 0.7), "#eef1f4", INK, 0.8))
    if cooking:
        u, v = burners[3]
        o.append(cookware(D, iso, cooking, bx + u * w, by + v * d, h))
    return "".join(o)


def counter(D, iso, x, y, front="R", dishes=(), wood=WOOD):
    bx, by, w, d, h = x + 0.03, y + 0.06, 0.94, 0.88, 44
    o = [shadow(iso, x + 0.5, y + 0.5, 0.55, 0.16)]
    o.append(box(D, iso, bx, by, w, d, h, wood))
    q = lambda u0, u1, v0, v1: iso.quad(front, bx, by, w, d, 0, h, u0, u1, v0, v1)
    for (u0, u1) in ((0.07, 0.47), (0.53, 0.93)):
        o.append(P(q(u0, u1, 0.12, 0.84), D.lin([(0, dark(wood, 0.3)), (1, dark(wood, 0.18))]), INK, 0.8))
        o.append(P(q(u0 + 0.04, u1 - 0.04, 0.2, 0.76), D.lin([(0, dark(wood, 0.12)), (1, dark(wood, 0.28))]), None))
    # tampo de mármore
    o.append(box(D, iso, bx - 0.03, by - 0.03, w + 0.06, d + 0.06, 5, "#e9e5df", z=h, top="#f6f4f0"))
    for (a, b) in [((0.15, 0.2), (0.5, 0.35)), ((0.4, 0.6), (0.85, 0.7))]:
        p0 = iso.v(bx + a[0] * w, by + a[1] * d, h + 5)
        p1 = iso.v(bx + b[0] * w, by + b[1] * d, h + 5)
        o.append(path(f"M{f(p0[0])},{f(p0[1])} Q{f((p0[0]+p1[0])/2+4)},{f((p0[1]+p1[1])/2-3)} {f(p1[0])},{f(p1[1])}",
                      "none", "#b9b2a8", 0.9, 'opacity="0.7"'))
    spots = [(0.3, 0.3), (0.7, 0.35), (0.45, 0.7)]
    for i, (kind, count) in enumerate(dishes):
        u, v = spots[i % 3]
        px, py = iso.v(bx + u * w, by + v * d, h + 5)
        for k in range(min(3, max(1, count // 4))):
            o.append(E(px, py + 1 - k * 2.2, 15, 5.4, "#ffffff", INK, 0.9))
        o.append(food(D, kind, px, py - 6 - min(3, count // 4) * 2, 30))
        o.append(f'<rect x="{f(px+8)}" y="{f(py-30)}" width="24" height="14" rx="7" fill="{INK}"/>'
                 f'<text x="{f(px+20)}" y="{f(py-19.6)}" text-anchor="middle" font-family="Fredoka, Nunito, sans-serif" '
                 f'font-weight="700" font-size="10.5" fill="#ffffff">×{count}</text>')
    return "".join(o)


def pastry_case(D, iso, x, y):
    bx, by, w, d = x + 0.05, y + 0.08, 0.9, 0.84
    o = [shadow(iso, x + 0.5, y + 0.5, 0.55, 0.16)]
    o.append(box(D, iso, bx, by, w, d, 34, WOOD))
    o.append(box(D, iso, bx + 0.02, by + 0.02, w - 0.04, d - 0.04, 2, "#f1ede6", z=34))
    # itens dentro (antes do vidro)
    sx, sy = iso.v(bx + w * 0.35, by + d * 0.4, 36)
    o.append(cylinder(D, iso, bx + w * 0.3, by + d * 0.35, 0.14, 36, 46, "#f39a2c", top="#4a2412"))
    o.append(food(D, "pao", sx + 30, sy + 4, 26))
    o.append(box(D, iso, bx + 0.04, by + 0.04, w - 0.08, d - 0.08, 1.5, "#e7e2da", z=52, sw=0.6))
    px, py = iso.v(bx + w * 0.55, by + d * 0.45, 54)
    o.append(food(D, "bolo", px, py - 6, 26) + food(D, "coxinha", px + 22, py + 4, 22))
    # vidro
    glass_T = [iso.v(bx, by, 68), iso.v(bx + w, by, 68), iso.v(bx + w, by + d, 68), iso.v(bx, by + d, 68)]
    glass_L = [iso.v(bx, by + d, 36), iso.v(bx + w, by + d, 36), iso.v(bx + w, by + d, 68), iso.v(bx, by + d, 68)]
    glass_R = [iso.v(bx + w, by + d, 36), iso.v(bx + w, by, 36), iso.v(bx + w, by, 68), iso.v(bx + w, by + d, 68)]
    for face in (glass_L, glass_R, glass_T):
        o.append(P(face, "#bfe6f5", INK, 0.9, 'fill-opacity="0.28"'))
    for t in (0.2, 0.32):
        a = (glass_L[0][0] + (glass_L[1][0] - glass_L[0][0]) * t, glass_L[0][1] + (glass_L[1][1] - glass_L[0][1]) * t)
        o.append(line(a[0] + 4, a[1] - 6, a[0] + 14, a[1] - 26, "#ffffff", 2.2, 'opacity="0.75"'))
    o.append(box(D, iso, bx - 0.01, by - 0.01, w + 0.02, d + 0.02, 3, WOOD_DARK, z=68))
    return "".join(o)


def espresso(D, iso, x, y):
    """Máquina de café expresso num balcãozinho."""
    o = [counter(D, iso, x, y)]
    bx, by = x + 0.2, y + 0.22
    o.append(box(D, iso, bx, by, 0.6, 0.5, 30, "#c9cfd6", z=49, top="#e9edf1"))
    o.append(box(D, iso, bx + 0.05, by + 0.05, 0.5, 0.4, 6, "#c2353f", z=79))
    for u in (0.3, 0.7):
        px, py = iso.face_center("R", bx, by, 0.6, 0.5, 49, 30, u, 0.35)
        o.append(E(px, py, 4, 3, "#3b3d44", INK, 0.8) + line(px + 2, py + 1, px + 9, py + 5, "#26272c", 2.2))
        o.append(E(px + 1, py + 13, 4.4, 1.8, "#ffffff", INK, 0.8))
    for i in range(3):
        px, py = iso.v(bx + 0.15 + i * 0.15, by + 0.2, 85)
        o.append(E(px, py, 4.5, 2.2, "#ffffff", INK, 0.8) + path(f"M{f(px-4)},{f(py)} L{f(px-3)},{f(py+4)} L{f(px+3)},{f(py+4)} L{f(px+4)},{f(py)}", "#ffffff", INK, 0.8))
    return "".join(o)


def plant(D, iso, x, y, big=False, seed=3):
    """Vaso de cerâmica com folhagem cheia (fícus)."""
    cx, cy = x + 0.5, y + 0.5
    o = [shadow(iso, cx, cy, 0.34, 0.2)]
    o.append(cylinder(D, iso, cx, cy, 0.2, 0, 26, "#c96a3a"))
    o.append(cylinder(D, iso, cx, cy, 0.23, 22, 30, "#b85a2e"))
    sx, sy, rx, ry = iso.ell(cx, cy, 30, 0.19)
    o.append(E(sx, sy, rx, ry, "#4a2e1c", None))
    r = Rng(seed)
    hgt = 70 if big else 44
    width = 34 if big else 24
    o.append(path(f"M{f(sx)},{f(sy)} C{f(sx-3)},{f(sy-hgt*0.3)} {f(sx+4)},{f(sy-hgt*0.5)} {f(sx)},{f(sy-hgt*0.62)}", "none", "#6a4a2a", 3))
    # copa: bolas de folhagem com luz de cima à esquerda, depois folhas soltas nas bordas
    blobs = [(0, -0.72, 0.62), (-0.55, -0.55, 0.5), (0.55, -0.55, 0.5), (-0.25, -0.95, 0.5), (0.3, -0.92, 0.48), (0, -0.4, 0.5)]
    for (bxr, byr, br) in blobs:
        bxp, byp, brr = sx + bxr * width, sy + byr * hgt, br * width
        o.append(C(bxp, byp, brr, D.rad([(0, "#8fd36a"), (0.55, "#58a844"), (1, "#2f6e2e")], 0.35, 0.3, 0.75), "#23511f", 1.0))
    leaves = []
    for i in range(46 if big else 28):
        a = r.u(0, math.tau)
        rad = r.u(0.55, 1.05)
        lx = sx + math.cos(a) * width * rad
        ly = sy - hgt * 0.68 + math.sin(a) * hgt * 0.36 * rad
        ang = math.degrees(a) + r.u(-30, 30)
        leaves.append((ly, lx, ang, r.r()))
    leaves.sort()
    for (ly, lx, ang, sh) in leaves:
        col = mix("#3f8a3a", "#8fd36a", sh)
        o.append(f'<ellipse cx="{f(lx)}" cy="{f(ly)}" rx="6.5" ry="3.4" fill="{col}" stroke="#23511f" stroke-width="0.7" '
                 f'transform="rotate({f(ang)} {f(lx)} {f(ly)})"/>')
    return "".join(o)


def jukebox(D, iso, x, y):
    bx, by, w, d = x + 0.12, y + 0.22, 0.76, 0.56
    o = [shadow(iso, x + 0.5, y + 0.5, 0.5, 0.18)]
    o.append(box(D, iso, bx, by, w, d, 52, "#8a3a2a"))
    # frente arredondada: arco colorido
    q = lambda u0, u1, v0, v1: iso.quad("L", bx, by, w, d, 0, 52, u0, u1, v0, v1)
    o.append(P(q(0.08, 0.92, 0.55, 0.95), D.lin([(0, "#ffd86b"), (0.5, "#ff8a3c"), (1, "#e2503f")]), INK, 0.9))
    o.append(P(q(0.18, 0.82, 0.62, 0.9), "#bfe6f5", INK, 0.8, 'fill-opacity="0.8"'))
    o.append(P(q(0.1, 0.9, 0.12, 0.5), D.lin([(0, "#5b2a1f"), (1, "#3a1a12")]), INK, 0.8))
    for i in range(5):
        u = 0.18 + i * 0.16
        p = q(u, u + 0.08, 0.16, 0.46)
        o.append(P(p, ["#ffd23f", "#5fc3a4", "#e2503f", "#8fd0f0", "#f08aa6"][i], None, 'opacity="0.85"'))
    o.append(box(D, iso, bx, by, w, d, 6, "#c9a24a", z=52))
    return "".join(o)


def floor_lamp(D, iso, x, y):
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [shadow(iso, cx, cy, 0.2, 0.18), cylinder(D, iso, cx, cy, 0.12, 0, 3, IRON)]
    o.append(line(sx, sy - 3, sx, sy - 80, "#2e2d33", 2.6))
    o.append(C(sx, sy - 70, 30, D.rad([(0, "#fff3b0", 0.55), (1, "#fff3b0", 0.0)]), None))
    o.append(path(f"M{f(sx-14)},{f(sy-74)} L{f(sx-9)},{f(sy-92)} L{f(sx+9)},{f(sy-92)} L{f(sx+14)},{f(sy-74)} Z",
                  D.lin([(0, "#ffe08a"), (1, "#f2b632")]), INK, 1.1))
    o.append(E(sx, sy - 74, 14, 3.6, "#fff6cf", INK, 0.9))
    return "".join(o)
