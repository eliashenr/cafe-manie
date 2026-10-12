"""Coleções da loja (estilos e culturas) no traço da v3: cadeiras, mesas e enfeites de cada uma.

Cadeiras e mesas saem de duas peças genéricas (styled_chair e styled_table), que mudam de pé, assento,
encosto, tampo e toalha; os enfeites são desenhos próprios. Mesma escala dos móveis (piso de 96x48),
mesma luz (de cima, à esquerda) e o mesmo contorno escuro das pranchas.
"""
from core3 import *
from furniture3 import CHROME, WOOD_L, WOOD_M, WOOD_D, K, plane, jukebox

S0, S1 = 0.26, 0.74   # a cadeira ocupa o meio da célula


# --- Padrões (tecidos e azulejos) -----------------------------------------------------------
# Os padrões são desenhados em "px" (W=96) e levados para o plano onde aparecem: deitados num tampo
# (lying) ou de pé numa face (standing). Sem transformação, ficam alinhados com a tela.

def lying(iso, unit=1.0):
    """Deita o padrão num tampo ou no chão, nos eixos do isométrico."""
    a = unit * K(iso)
    return f"matrix({f(a)},{f(a / 2)},{f(-a)},{f(a / 2)},0,0)"


def standing(face, unit=1.0):
    """Põe o padrão de pé numa face da caixa: 'L' (y constante, desce para a direita) ou 'R' (x constante)."""
    return f"matrix({f(unit)},{f(unit * (0.5 if face == 'L' else -0.5))},0,{f(unit)},0,0)"


def fabric(D, kind, color, transform=""):
    """Tecido de toalha: 'gingham' (xadrez), 'confetti' (confete), 'chita' (flores grandes) ou 'plain'."""
    if kind == "plain":
        return color
    if kind == "gingham":
        size = 7
        markup = (f'<rect width="7" height="7" fill="#ffffff"/><rect width="3.5" height="7" fill="{color}" opacity="0.5"/>'
                  f'<rect width="7" height="3.5" fill="{color}" opacity="0.5"/>')
    elif kind == "confetti":
        size = 16
        markup = f'<rect width="16" height="16" fill="{color}"/>' + "".join(
            f'<circle cx="{x}" cy="{y}" r="1.5" fill="{c}"/>' for x, y, c in
            [(3, 3, "#ff4d6d"), (11, 6, "#ffd23f"), (6, 12, "#4fc3ff"), (14, 14, "#7ee85a"), (1, 9, "#b06bff")])
    else:  # chita
        size = 24
        markup = (f'<rect width="24" height="24" fill="{color}"/>'
                  '<ellipse cx="14" cy="5" rx="3" ry="1.4" fill="#2fae4e"/><ellipse cx="3" cy="15" rx="3" ry="1.4" fill="#2fae4e"/>')
        for (x, y, c) in [(6, 6, "#ffd23f"), (18, 14, "#ffffff"), (8, 20, "#ff8fb1")]:
            markup += "".join(f'<circle cx="{f(x + 2.6 * math.cos(math.radians(a)))}" cy="{f(y + 2.6 * math.sin(math.radians(a)))}" '
                              f'r="2.2" fill="{c}"/>' for a in range(0, 360, 72))
            markup += f'<circle cx="{x}" cy="{y}" r="1.4" fill="#2fae4e"/>'
    key = D._key("fabric", kind, color, transform)
    t = f' patternTransform="{transform}"' if transform else ""
    return D.raw(key, f'<pattern id="{key}" patternUnits="userSpaceOnUse" width="{size}" height="{size}"{t}>{markup}</pattern>')


def stripes_pattern(D, a, b, width=6):
    key = f"sp{a[1:]}{b[1:]}{width}"
    return D.raw(key, f'<pattern id="{key}" patternUnits="userSpaceOnUse" width="{width * 2}" height="{width * 2}">'
                      f'<rect width="{width * 2}" height="{width * 2}" fill="{a}"/><rect width="{width}" height="{width * 2}" fill="{b}"/></pattern>')


def weave(D, color):
    """Trama de vime ou palhinha."""
    key = f"wv{color[1:]}"
    dark = shade(color, 0.3)
    return D.raw(key, f'<pattern id="{key}" patternUnits="userSpaceOnUse" width="6" height="6">'
                      f'<rect width="6" height="6" fill="{color}"/>'
                      f'<path d="M0,0 L6,6 M6,0 L0,6" stroke="{dark}" stroke-width="0.9"/></pattern>')


def talavera_tile(cx, cy, r, blue="#2f6fd9"):
    """Florzinha de azulejo talavera (em coordenadas planas)."""
    o = [C(cx, cy, r * 0.32, "#ffd23f", None)]
    for a in range(0, 360, 45):
        px, py = cx + math.cos(math.radians(a)) * r * 0.62, cy + math.sin(math.radians(a)) * r * 0.62
        o.append(C(px, py, r * 0.22, blue, None))
    return "".join(o)


# --- Cadeira genérica ----------------------------------------------------------------------

def _back_shape(D, style, color, width, height, k):
    """Desenho plano do encosto (u de 0 a width para a direita, v de 0 a -height para cima)."""
    kind = style
    w, h = width, height
    grad = D.lin([(0, tint(color, 0.35)), (0.4, color), (1, shade(color, 0.22))], 0, 0, 1, 1)
    o = []
    if kind == "panel":
        o.append(f'<rect x="0" y="{f(-h)}" width="{f(w)}" height="{f(h)}" rx="{f(6 * k)}" fill="{grad}" stroke="{INK3}" stroke-width="1"/>')
        o.append(f'<rect x="{f(3 * k)}" y="{f(-h + 3 * k)}" width="{f(w - 6 * k)}" height="{f(h * 0.35)}" rx="{f(4 * k)}" fill="#ffffff" opacity="0.28"/>')
    elif kind == "slats":
        o.append(f'<rect x="0" y="{f(-h)}" width="{f(w)}" height="{f(6 * k)}" rx="{f(2 * k)}" fill="{grad}" stroke="{INK3}" stroke-width="0.9"/>')
        for i in range(3):
            sx = w * (0.22 + i * 0.28)
            o.append(f'<rect x="{f(sx - 2.2 * k)}" y="{f(-h + 5 * k)}" width="{f(4.4 * k)}" height="{f(h - 5 * k)}" rx="{f(1.4 * k)}" fill="{grad}" stroke="{INK3}" stroke-width="0.8"/>')
        for sx in (0, w - 4 * k):
            o.append(f'<rect x="{f(sx)}" y="{f(-h)}" width="{f(4 * k)}" height="{f(h)}" rx="{f(1.6 * k)}" fill="{shade(color, 0.12)}" stroke="{INK3}" stroke-width="0.8"/>')
    elif kind == "ladder":
        for sx in (0, w - 4 * k):
            o.append(f'<rect x="{f(sx)}" y="{f(-h - 3 * k)}" width="{f(4 * k)}" height="{f(h + 3 * k)}" rx="{f(1.8 * k)}" fill="{shade(color, 0.1)}" stroke="{INK3}" stroke-width="0.8"/>')
        for i in range(3):
            ry = -h * (0.3 + i * 0.3)
            o.append(f'<rect x="{f(2 * k)}" y="{f(ry - 2.6 * k)}" width="{f(w - 4 * k)}" height="{f(5 * k)}" rx="{f(2 * k)}" fill="{grad}" stroke="{INK3}" stroke-width="0.8"/>')
    elif kind == "shell":
        d = f"M0,0 L0,{f(-h * 0.55)} Q0,{f(-h)} {f(w / 2)},{f(-h)} Q{f(w)},{f(-h)} {f(w)},{f(-h * 0.55)} L{f(w)},0 Z"
        o.append(path(d, grad, INK3, 1.0))
        o.append(path(f"M{f(w * 0.2)},{f(-h * 0.5)} Q{f(w * 0.25)},{f(-h * 0.88)} {f(w * 0.5)},{f(-h * 0.9)}", "none", "#ffffff", 2.2 * k, 'opacity="0.55"'))
    elif kind == "egg":
        d = f"M{f(-w * 0.12)},0 C{f(-w * 0.2)},{f(-h * 0.9)} {f(w * 0.1)},{f(-h * 1.25)} {f(w / 2)},{f(-h * 1.25)} C{f(w * 0.9)},{f(-h * 1.25)} {f(w * 1.2)},{f(-h * 0.9)} {f(w * 1.12)},0 Z"
        o.append(path(d, grad, INK3, 1.1))
        inner = f"M{f(w * 0.06)},0 C{f(w * 0.02)},{f(-h * 0.75)} {f(w * 0.2)},{f(-h * 1.05)} {f(w / 2)},{f(-h * 1.05)} C{f(w * 0.8)},{f(-h * 1.05)} {f(w * 0.98)},{f(-h * 0.75)} {f(w * 0.94)},0 Z"
        o.append(path(inner, shade(color, 0.18), None, 'opacity="0.5"'))
        o.append(path(f"M{f(w * 0.1)},{f(-h * 0.6)} Q{f(w * 0.15)},{f(-h * 1.05)} {f(w * 0.45)},{f(-h * 1.15)}", "none", "#ffffff", 2.4 * k, 'opacity="0.5"'))
    elif kind in ("wicker", "cane"):
        fill = weave(D, color)
        d = f"M0,0 L0,{f(-h * 0.7)} Q0,{f(-h)} {f(w / 2)},{f(-h)} Q{f(w)},{f(-h)} {f(w)},{f(-h * 0.7)} L{f(w)},0 Z" if kind == "wicker" \
            else f"M0,0 L0,{f(-h)} L{f(w)},{f(-h)} L{f(w)},0 Z"
        o.append(path(d, fill, INK3, 1.0))
        o.append(path(d, "none", shade(color, 0.4) if kind == "wicker" else WOOD_D, 2.6 * k))
    elif kind == "tufted":
        d = f"M0,0 L0,{f(-h * 0.8)} Q0,{f(-h)} {f(w * 0.2)},{f(-h)} L{f(w * 0.8)},{f(-h)} Q{f(w)},{f(-h)} {f(w)},{f(-h * 0.8)} L{f(w)},0 Z"
        o.append(path(d, grad, INK3, 1.1))
        for (u, v) in [(0.25, 0.3), (0.5, 0.3), (0.75, 0.3), (0.375, 0.62), (0.625, 0.62)]:
            o.append(C(w * u, -h * v, 1.4 * k, shade(color, 0.4), None))
        o.append(path(f"M{f(w * 0.12)},{f(-h * 0.85)} Q{f(w / 2)},{f(-h * 0.98)} {f(w * 0.88)},{f(-h * 0.85)}", "none", "#ffffff", 1.6 * k, 'opacity="0.45"'))
    elif kind == "painted":
        o.append(f'<rect x="0" y="{f(-h)}" width="{f(w)}" height="{f(h)}" rx="{f(5 * k)}" fill="{grad}" stroke="{INK3}" stroke-width="1"/>')
        for (u, v, c) in [(0.3, 0.45, "#ff4d6d"), (0.7, 0.45, "#ffd23f"), (0.5, 0.75, "#ffffff")]:
            for a in range(0, 360, 72):
                o.append(C(w * u + math.cos(math.radians(a)) * 2.2 * k, -h * v + math.sin(math.radians(a)) * 2.2 * k, 1.8 * k, c, INK3, 0.4))
            o.append(C(w * u, -h * v, 1.1 * k, "#2fae4e", None))
    return "".join(o)


def styled_chair(D, iso, x, y, facing, seat="#ff4d5e", legs="chrome", leg_color=CHROME, back="panel", back_color=None,
                 back_h=30):
    """Cadeira genérica no traço v3: pés ('chrome', 'wood' ou 'pedestal'), assento estofado e encosto
    ('panel', 'slats', 'ladder', 'shell', 'egg', 'wicker', 'cane', 'tufted', 'painted' ou None = banqueta
    de assento redondo). O assento fica na altura da cadeira clássica: quem senta é desenhado no mesmo lugar.
    Como chair(): de frente para +x/+y devolve tudo junto; para -x/-y, (pés e assento, encosto)."""
    k = K(iso)
    back_color = back_color or seat
    seat_z = 23 * k
    o_legs, o_seat, o_back = [soft_shadow(D, iso, x + 0.5, y + 0.5, 0.3, opacity=0.25)], [], []
    if legs == "pedestal":
        o_legs.append(cyl3(D, iso, x + 0.5, y + 0.5, 0.17, 0, 2.5 * k, leg_color, metal=leg_color == CHROME, sw=0.8))
        o_legs.append(cyl3(D, iso, x + 0.5, y + 0.5, 0.035, 2.5 * k, seat_z, leg_color, metal=leg_color == CHROME, sw=0.7, cap=False))
    else:
        r = 0.022 if legs == "chrome" else 0.032
        for (lx, ly) in sorted([(x + S0 + 0.03, y + S0 + 0.03), (x + S1 - 0.03, y + S0 + 0.03), (x + S0 + 0.03, y + S1 - 0.03),
                                (x + S1 - 0.03, y + S1 - 0.03)], key=lambda p: p[0] + p[1]):
            o_legs.append(cyl3(D, iso, lx, ly, r, 0, seat_z, leg_color, metal=legs == "chrome", sw=0.7, cap=False))
    if back is None:
        o_seat.append(cyl3(D, iso, x + 0.5, y + 0.5, 0.25, seat_z, seat_z + 3 * k, CHROME, metal=True, sw=0.9))
        o_seat.append(cyl3(D, iso, x + 0.5, y + 0.5, 0.24, seat_z + 3 * k, seat_z + 8 * k, seat, sw=0.9))
        sx, st, rx, ry = iso.ell(x + 0.5, y + 0.5, seat_z + 8 * k, 0.24)
        o_seat.append(E(sx - rx * 0.25, st - ry * 0.2, rx * 0.4, ry * 0.32, "#ffffff", None, extra='opacity="0.4"'))
    else:
        o_seat.append(box3(D, iso, x + S0, y + S0, S1 - S0, S1 - S0, 3 * k, shade(seat, 0.25), z=seat_z, sw=0.9, bevel=False))
        o_seat.append(box3(D, iso, x + S0 + 0.01, y + S0 + 0.01, S1 - S0 - 0.02, S1 - S0 - 0.02, 5 * k, seat, z=seat_z + 3 * k,
                           sw=0.9, gloss=True))
    if back:
        zb = seat_z + 6 * k
        width_px = (S1 - S0) * iso.W / 2
        if facing in ("+x", "-x"):
            bx = x + S0 if facing == "+x" else x + S1
            posts = [(bx, y + S0 + 0.04), (bx, y + S1 - 0.04)]
            t = plane(iso, "L", bx, y + S1, zb)
        else:
            by = y + S0 if facing == "+y" else y + S1
            posts = [(x + S0 + 0.04, by), (x + S1 - 0.04, by)]
            t = plane(iso, "R", x + S0, by, zb)
        if back not in ("egg", "shell"):
            post_color = leg_color if legs != "pedestal" else shade(back_color, 0.2)
            for (px, py) in posts:
                o_back.append(cyl3(D, iso, px, py, 0.02, seat_z, zb + 4, post_color, metal=legs == "chrome", sw=0.6, cap=False))
        o_back.append(g(_back_shape(D, back, back_color, width_px, back_h * k, k), t))
    if facing in ("+x", "+y"):
        return "".join(o_legs + o_back + o_seat)
    return "".join(o_legs + o_seat), "".join(o_back)


# --- Mesa genérica -------------------------------------------------------------------------

def _top_fill(T, kind, color, k):
    """Desenho por cima do tampo quadrado T (topo, direita, frente, esquerda): 'talavera', 'wood', 'marble' ou 'glow'."""
    def at(u, v):
        return (T[0][0] + (T[1][0] - T[0][0]) * u + (T[3][0] - T[0][0]) * v,
                T[0][1] + (T[1][1] - T[0][1]) * u + (T[3][1] - T[0][1]) * v)
    o = []
    if kind == "talavera":
        for (u, v) in [(0.28, 0.28), (0.72, 0.28), (0.28, 0.72), (0.72, 0.72)]:
            px, py = at(u, v)
            o.append(f'<g transform="translate({f(px)},{f(py)}) scale(1,0.5)">{talavera_tile(0, 0, 9 * k)}</g>')
        a, b = at(0.5, 0.02), at(0.5, 0.98)
        c, d = at(0.02, 0.5), at(0.98, 0.5)
        o.append(line(a[0], a[1], b[0], b[1], "#2f6fd9", 0.8, 'opacity="0.5"') + line(c[0], c[1], d[0], d[1], "#2f6fd9", 0.8, 'opacity="0.5"'))
    elif kind == "wood":
        for i in range(1, 4):
            a, b = at(0, i / 4), at(1, i / 4)
            o.append(line(a[0], a[1], b[0], b[1], shade(color, 0.25), 0.8, 'opacity="0.6"'))
    elif kind == "marble":
        for (u0, v0, u1, v1) in ((0.15, 0.3, 0.8, 0.45), (0.3, 0.7, 0.9, 0.85)):
            a, b, c = at(u0, v0), at((u0 + u1) / 2, (v0 + v1) / 2 - 0.12), at(u1, v1)
            o.append(path(f"M{f(a[0])},{f(a[1])} Q{f(b[0])},{f(b[1])} {f(c[0])},{f(c[1])}", "none", shade(color, 0.3), 0.8,
                          'opacity="0.6"'))
    elif kind == "glow":
        o.append(P([at(0.04, 0.04), at(0.96, 0.04), at(0.96, 0.96), at(0.04, 0.96)], "none", "#4fe0ff", 2.2 * k, 'opacity="0.9"'))
        o.append(P([at(0.12, 0.12), at(0.88, 0.12), at(0.88, 0.88), at(0.12, 0.88)], "none", "#ff4dd2", 1.4 * k, 'opacity="0.8"'))
    return "".join(o)


def styled_table(D, iso, x, y, shape="square", top=("solid", "#ffffff"), edge="#ff4d5e", base="pedestal", base_color=CHROME,
                 cloth=None, height=32, vase=True, candle=False, flower=("#ff4d8d", "#ffd23f")):
    """Mesa genérica no traço v3. shape 'square' ou 'round'; top (tipo, cor): 'solid' em qualquer uma,
    'talavera' e 'wood' nas quadradas, 'marble', 'memphis' e 'glow' nas redondas; base 'pedestal' (pé central)
    ou 'legs' (quatro pés); cloth (tipo, cor) cobre o tampo e cai pelos lados: 'gingham', 'confetti', 'chita'
    ou 'plain'. height: altura do tampo (o jogo põe ali o prato de quem come)."""
    k = K(iso)
    h = height * k
    o = [soft_shadow(D, iso, x + 0.5, y + 0.5, 0.42, opacity=0.3)]
    metal = base_color == CHROME
    if base == "pedestal":
        o.append(cyl3(D, iso, x + 0.5, y + 0.5, 0.2, 0, 2.5 * k, base_color, metal=metal, sw=0.8))
        o.append(cyl3(D, iso, x + 0.5, y + 0.5, 0.045, 2.5 * k, h - 4 * k, base_color, metal=metal, sw=0.8, cap=False))
    else:
        for (lx, ly) in [(x + 0.14, y + 0.14), (x + 0.86, y + 0.14), (x + 0.14, y + 0.86), (x + 0.86, y + 0.86)]:
            o.append(cyl3(D, iso, lx, ly, 0.035, 0, h - 4 * k, base_color, metal=metal, sw=0.8, cap=False))
    kind, color = top
    if shape == "round":
        cx, cy, r = x + 0.5, y + 0.5, 0.4
        sx, st, rx, ry = iso.ell(cx, cy, h, r)
        if cloth:
            drop = 12 * k
            d = (f"M{f(sx + rx)},{f(st)} L{f(sx + rx * 1.03)},{f(st + drop)} A{f(rx * 1.03)},{f(ry * 1.03)} 0 0 1 {f(sx - rx * 1.03)},{f(st + drop)} "
                 f"L{f(sx - rx)},{f(st)} A{f(rx)},{f(ry)} 0 0 0 {f(sx + rx)},{f(st)} Z")
            o.append(path(d, fabric(D, cloth[0], cloth[1]), INK3, 1.0))
            o.append(path(d, D.lin([(0, "#ffffff", 0.2), (0.4, "#ffffff", 0.0), (1, "#1a1030", 0.25)], 0, 0, 1, 0), None))
            o.append(E(sx, st, rx, ry, fabric(D, cloth[0], cloth[1], lying(iso)), INK3, 1.1))
        else:
            o.append(cyl3(D, iso, cx, cy, r, h - 4 * k, h, edge, top=color, sw=1.0))
            if kind == "marble":
                o.append(path(f"M{f(sx - rx * 0.6)},{f(st)} Q{f(sx)},{f(st - ry * 0.6)} {f(sx + rx * 0.5)},{f(st + ry * 0.2)}", "none", "#a8a39b", 0.8,
                              'opacity="0.6"'))
            elif kind == "memphis":
                o.append(E(sx - rx * 0.4, st - ry * 0.15, 5 * k, 2.6 * k, "#ff4dd2", None) + E(sx + rx * 0.45, st + ry * 0.1, 4.4 * k, 2.3 * k, "#4fe0ff", None))
                o.append(P([(sx + rx * 0.05, st - ry * 0.65), (sx + rx * 0.3, st - ry * 0.2), (sx - rx * 0.15, st - ry * 0.25)], "#2a2d6e", None))
                o.append(path(f"M{f(sx - 10 * k)},{f(st + ry * 0.5)} l{f(4 * k)},{f(-2.6 * k)} l{f(4 * k)},{f(2.6 * k)} l{f(4 * k)},{f(-2.6 * k)} l{f(4 * k)},{f(2.6 * k)}",
                              "none", "#ffd23f", 2 * k))
            elif kind == "glow":
                o.append(E(sx, st, rx, ry, "none", "#4fe0ff", 2.2 * k, 'opacity="0.9"'))
                o.append(E(sx, st + 4 * k, rx * 1.02, ry * 1.02, "none", "#ff4dd2", 1.6 * k, 'opacity="0.8"'))
            o.append(E(sx - rx * 0.25, st - ry * 0.25, rx * 0.45, ry * 0.35, "#ffffff", None, extra='opacity="0.3"'))
        top_center = (sx, st)
    else:
        m = 0.06
        x0, x1, y0, y1 = x + m, x + 1 - m, y + m, y + 1 - m
        if cloth:
            drop = 13 * k
            T = [iso.v(x0, y0, h), iso.v(x1, y0, h), iso.v(x1, y1, h), iso.v(x0, y1, h)]
            o.append(box3(D, iso, x0, y0, x1 - x0, y1 - y0, 3 * k, "#ffffff", z=h - 3 * k, sw=0.8, bevel=False))
            left = [T[3], T[2], (T[2][0], T[2][1] + drop), (T[3][0], T[3][1] + drop)]
            right = [T[2], T[1], (T[1][0], T[1][1] + drop), (T[2][0], T[2][1] + drop)]
            o.append(P(left, fabric(D, cloth[0], cloth[1], standing("L")), INK3, 1.0) + P(left, "#1a1030", None, 'opacity="0.08"'))
            o.append(P(right, fabric(D, cloth[0], cloth[1], standing("R")), INK3, 1.0) + P(right, "#1a1030", None, 'opacity="0.2"'))
            o.append(P(T, fabric(D, cloth[0], cloth[1], lying(iso)), INK3, 1.0))
        else:
            o.append(box3(D, iso, x0, y0, x1 - x0, y1 - y0, 4.5 * k, edge, z=h - 4.5 * k, top=color, sw=1.0))
            T = [iso.v(x0, y0, h), iso.v(x1, y0, h), iso.v(x1, y1, h), iso.v(x0, y1, h)]
            o.append(_top_fill(T, kind, color, k))
            o.append(P(T, D.lin([(0, "#ffffff", 0.0), (0.45, "#ffffff", 0.4), (0.55, "#ffffff", 0.0)], 0, 0, 1, 1), None))
        top_center = iso.v(x + 0.5, y + 0.5, h)
    px, py = top_center
    if candle:
        o.append(cyl3(D, iso, x + 0.5, y + 0.5, 0.05, h, h + 10 * k, "#2f7a3a", sw=0.8))
        o.append(cyl3(D, iso, x + 0.5, y + 0.5, 0.02, h + 10 * k, h + 16 * k, "#fff6d8", sw=0.6))
        o.append(path(f"M{f(px)},{f(py - 21 * k)} q{f(2 * k)},{f(3 * k)} 0,{f(5 * k)} q{f(-2 * k)},{f(-2 * k)} 0,{f(-5 * k)} Z", "#ffb13d", INK3, 0.6))
        o.append(C(px, py - 17 * k, 7 * k, D.rad([(0, "#fff3b0", 0.6), (1, "#fff3b0", 0)]), None))
    elif vase:
        o.append(cyl3(D, iso, x + 0.5, y + 0.5, 0.045, h, h + 9 * k, "#8fe3ff", sw=0.8))
        o.append(C(px - 1.5, py - 13 * k, 3.4 * k, flower[0], INK3, 0.8) + C(px + 2.8, py - 11 * k, 3 * k, flower[1], INK3, 0.8))
    return "".join(o)


# --- Enfeites: Anos 70 ---------------------------------------------------------------------

def lava_lamp(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.22, opacity=0.25), C(sx, sy - 38 * k, 26 * k, D.rad([(0, "#ffb13d", 0.35), (1, "#ffb13d", 0)]), None)]
    o.append(path(f"M{f(sx - 9 * k)},{f(sy)} L{f(sx - 5 * k)},{f(sy - 12 * k)} L{f(sx + 5 * k)},{f(sy - 12 * k)} L{f(sx + 9 * k)},{f(sy)} Z",
                  D.lin([(0, "#e8edf2"), (1, "#8f9aa7")], 0, 0, 1, 0), INK3, 1.0))
    glass = f"M{f(sx - 5 * k)},{f(sy - 12 * k)} C{f(sx - 9 * k)},{f(sy - 30 * k)} {f(sx - 5 * k)},{f(sy - 48 * k)} {f(sx - 3 * k)},{f(sy - 56 * k)} L{f(sx + 3 * k)},{f(sy - 56 * k)} C{f(sx + 5 * k)},{f(sy - 48 * k)} {f(sx + 9 * k)},{f(sy - 30 * k)} {f(sx + 5 * k)},{f(sy - 12 * k)} Z"
    o.append(path(glass, D.lin([(0, "#ffde59"), (1, "#ff7a2f")]), INK3, 1.0))
    for (dx, dy, r) in [(-1.5, -22, 3.4), (1.8, -32, 2.6), (-0.8, -42, 2.2), (1, -17, 2)]:
        o.append(E(sx + dx * k, sy + dy * k, r * k, r * 1.3 * k, "#ff3d6e", None, extra='opacity="0.9"'))
    o.append(path(f"M{f(sx - 3 * k)},{f(sy - 56 * k)} L{f(sx - 2.4 * k)},{f(sy - 62 * k)} L{f(sx + 2.4 * k)},{f(sy - 62 * k)} L{f(sx + 3 * k)},{f(sy - 56 * k)} Z",
                  "#8f9aa7", INK3, 0.9))
    o.append(path(f"M{f(sx - 3 * k)},{f(sy - 20 * k)} Q{f(sx - 5 * k)},{f(sy - 32 * k)} {f(sx - 2.4 * k)},{f(sy - 46 * k)}", "none", "#ffffff", 1.4 * k, 'opacity="0.6"'))
    return "".join(o)


def macrame_plant(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.3, opacity=0.25)]
    o.append(cyl3(D, iso, cx, cy, 0.16, 0, 3 * k, WOOD_D))
    o.append(line(sx - 12 * k, sy - 2 * k, sx - 2 * k, sy - 70 * k, WOOD_M, 2.4 * k) + line(sx + 12 * k, sy - 2 * k, sx + 2 * k, sy - 70 * k, WOOD_M, 2.4 * k))
    o.append(line(sx - 3 * k, sy - 70 * k, sx + 3 * k, sy - 70 * k, WOOD_D, 3 * k))
    top = sy - 66 * k
    for dx in (-6, -2, 2, 6):
        o.append(path(f"M{f(sx + dx * 0.3 * k)},{f(top)} Q{f(sx + dx * k)},{f(top + 14 * k)} {f(sx + dx * 1.2 * k)},{f(top + 24 * k)}", "none", "#f3e6cf", 1.3 * k))
    pot_y = top + 32 * k
    o.append(path(f"M{f(sx - 9 * k)},{f(pot_y - 8 * k)} L{f(sx - 7 * k)},{f(pot_y + 2 * k)} L{f(sx + 7 * k)},{f(pot_y + 2 * k)} L{f(sx + 9 * k)},{f(pot_y - 8 * k)} Z",
                  D.lin([(0, "#f0a65a"), (1, "#c96a2c")]), INK3, 1.0))
    for i in range(7):
        a = math.radians(-160 + i * 23)
        lx, ly = sx + math.cos(a) * 13 * k, pot_y - 9 * k + math.sin(a) * 10 * k
        o.append(f'<path d="{leaf(0, 0, 0, 12 * k, 4.6 * k, 0.1)}" fill="{mix("#3fbf4a", "#7fe06a", i / 7)}" stroke="#1d6b33" stroke-width="0.7" '
                 f'transform="translate({f(lx)},{f(ly)}) rotate({f(math.degrees(a))})"/>')
    for i in range(4):
        o.append(path(f"M{f(sx + (i - 1.5) * 4 * k)},{f(pot_y)} q{f(2 * k)},{f(8 * k)} {f(-1 * k)},{f(16 * k)}", "none", "#4fbf4a", 1.6 * k))
    return "".join(o)


# --- Enfeites: Country ---------------------------------------------------------------------

def hay_bale(D, iso, x, y):
    k = K(iso)
    o = [soft_shadow(D, iso, x + 0.5, y + 0.5, 0.42, opacity=0.25)]
    o.append(box3(D, iso, x + 0.14, y + 0.24, 0.72, 0.52, 22 * k, "#e8c25a", top="#f2d474"))
    T = [iso.v(x + 0.14, y + 0.24, 22 * k), iso.v(x + 0.86, y + 0.24, 22 * k), iso.v(x + 0.86, y + 0.76, 22 * k), iso.v(x + 0.14, y + 0.76, 22 * k)]
    r = Rng(3)
    for _ in range(14):
        u, v = r.u(0.05, 0.95), r.u(0.1, 0.9)
        px = T[0][0] + (T[1][0] - T[0][0]) * u + (T[3][0] - T[0][0]) * v
        py = T[0][1] + (T[1][1] - T[0][1]) * u + (T[3][1] - T[0][1]) * v
        o.append(line(px, py, px + r.u(-4, 4) * k, py + r.u(-2, 2) * k, "#b8902e", 0.9))
    for u in (0.3, 0.7):
        a, b = iso.v(x + 0.14 + 0.72 * u, y + 0.76, 0), iso.v(x + 0.14 + 0.72 * u, y + 0.76, 22 * k)
        c = iso.v(x + 0.14 + 0.72 * u, y + 0.24, 22 * k)
        o.append(line(a[0], a[1], b[0], b[1], "#a8582e", 1.8 * k) + line(b[0], b[1], c[0], c[1], "#a8582e", 1.8 * k))
    return "".join(o)


def wagon_wheel(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.3, opacity=0.25)]
    o.append(box3(D, iso, x + 0.42, y + 0.42, 0.16, 0.16, 4 * k, WOOD_D))
    wy = sy - 30 * k
    r = 26 * k
    o.append(E(sx, wy, r, r, "none", INK3, 7 * k))
    o.append(E(sx, wy, r, r, "none", WOOD_M, 5 * k))
    for i in range(8):
        a = math.radians(i * 45)
        o.append(line(sx, wy, sx + math.cos(a) * r, wy + math.sin(a) * r, WOOD_D, 2.4 * k))
    o.append(C(sx, wy, 5 * k, WOOD_L, INK3, 1.0))
    o.append(path(f"M{f(sx - r * 0.7)},{f(wy - r * 0.7)} A{f(r)},{f(r)} 0 0 1 {f(sx + r * 0.2)},{f(wy - r)}", "none", "#ffffff", 1.6 * k, 'opacity="0.4"'))
    return "".join(o)


# --- Enfeites: Festa -----------------------------------------------------------------------

def balloons(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.2, opacity=0.22), cyl3(D, iso, cx, cy, 0.08, 0, 6 * k, "#ffd23f")]
    for (dx, dy, c) in [(-12, -78, "#ff4d6d"), (10, -84, "#4fc3ff"), (0, -96, "#ffd23f"), (-6, -66, "#b06bff"), (13, -64, "#7ee85a")]:
        bx, by = sx + dx * k, sy + dy * k
        o.append(path(f"M{f(sx)},{f(sy - 6 * k)} Q{f(sx + dx * 0.3 * k)},{f(sy - 30 * k)} {f(bx)},{f(by + 11 * k)}", "none", "#8a8f96", 0.8))
        o.append(E(bx, by, 9 * k, 11 * k, D.rad([(0, tint(c, 0.6)), (0.6, c), (1, shade(c, 0.25))], 0.38, 0.32, 0.75), INK3, 1.0))
        o.append(path(f"M{f(bx - 1.6 * k)},{f(by + 11 * k)} l{f(1.6 * k)},{f(3 * k)} l{f(1.6 * k)},{f(-3 * k)} Z", c, INK3, 0.6))
        o.append(E(bx - 3 * k, by - 4 * k, 2 * k, 3 * k, "#ffffff", None, extra='opacity="0.55"'))
    return "".join(o)


def party_cake(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.3, opacity=0.25)]
    o.append(cyl3(D, iso, cx, cy, 0.16, 0, 3 * k, "#dfe6ee"))
    o.append(cyl3(D, iso, cx, cy, 0.04, 3 * k, 18 * k, "#e8edf2", cap=False))
    o.append(cyl3(D, iso, cx, cy, 0.3, 18 * k, 21 * k, "#ffffff"))
    o.append(cyl3(D, iso, cx, cy, 0.24, 21 * k, 33 * k, "#ffb3cf", top="#fff0f6"))
    o.append(cyl3(D, iso, cx, cy, 0.16, 33 * k, 43 * k, "#b8e8ff", top="#fff0f6"))
    for (dx, c) in [(-6, "#ff4d6d"), (0, "#ffd23f"), (6, "#7ee85a")]:
        o.append(line(sx + dx * k, sy - 44 * k, sx + dx * k, sy - 52 * k, c, 2.2 * k))
        o.append(path(f"M{f(sx + dx * k)},{f(sy - 56 * k)} q{f(1.6 * k)},{f(2.4 * k)} 0,{f(4 * k)} q{f(-1.6 * k)},{f(-1.6 * k)} 0,{f(-4 * k)} Z", "#ffb13d", None))
    for i in range(6):
        a = math.radians(200 + i * 25)
        _, _, rx, ry = iso.ell(cx, cy, 0, 0.24)
        o.append(C(sx + math.cos(a) * rx * 0.9, sy - 26 * k + math.sin(a) * ry * 0.4, 1.6 * k, ["#ff4d6d", "#ffd23f", "#4fc3ff"][i % 3], None))
    return "".join(o)


# --- Enfeites: Americano -------------------------------------------------------------------

def neon_sign(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.25, opacity=0.25), cyl3(D, iso, cx, cy, 0.14, 0, 3 * k, "#3a3c46")]
    o.append(line(sx, sy - 3 * k, sx, sy - 40 * k, "#3a3c46", 2.6 * k))
    bw, bh = 46 * k, 24 * k
    bx, by = sx - bw / 2, sy - 66 * k
    o.append(C(sx, by + bh / 2, 34 * k, D.rad([(0, "#ff4da6", 0.35), (1, "#ff4da6", 0)]), None))
    o.append(f'<rect x="{f(bx)}" y="{f(by)}" width="{f(bw)}" height="{f(bh)}" rx="{f(5 * k)}" fill="#2a1d3e" stroke="{INK3}" stroke-width="1"/>')
    # "DINER" em traços de neon (sem fonte): letras simples
    letters = []
    lx = bx + 6 * k
    step = 7.4 * k
    t, b = by + 6 * k, by + bh - 6 * k
    letters.append(f"M{f(lx)},{f(t)} L{f(lx)},{f(b)} Q{f(lx + 5 * k)},{f(b)} {f(lx + 5 * k)},{f((t + b) / 2)} Q{f(lx + 5 * k)},{f(t)} {f(lx)},{f(t)}")
    lx += step
    letters.append(f"M{f(lx + 1 * k)},{f(t)} L{f(lx + 1 * k)},{f(b)}")
    lx += step * 0.6
    letters.append(f"M{f(lx)},{f(b)} L{f(lx)},{f(t)} L{f(lx + 5 * k)},{f(b)} L{f(lx + 5 * k)},{f(t)}")
    lx += step
    letters.append(f"M{f(lx + 5 * k)},{f(t)} L{f(lx)},{f(t)} L{f(lx)},{f(b)} L{f(lx + 5 * k)},{f(b)} M{f(lx)},{f((t + b) / 2)} L{f(lx + 4 * k)},{f((t + b) / 2)}")
    lx += step
    letters.append(f"M{f(lx)},{f(b)} L{f(lx)},{f(t)} Q{f(lx + 6 * k)},{f(t)} {f(lx + 5 * k)},{f((t + b) / 2)} L{f(lx)},{f((t + b) / 2)} L{f(lx + 5 * k)},{f(b)}")
    d = " ".join(letters)
    o.append(path(d, "none", "#ff4da6", 3.2 * k, 'opacity="0.55"'))
    o.append(path(d, "none", "#ffe3f3", 1.4 * k))
    return "".join(o)


# --- Enfeites: Mexicano --------------------------------------------------------------------

def cactus(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.26, opacity=0.25)]
    o.append(cyl3(D, iso, cx, cy, 0.18, 0, 16 * k, "#d9824a"))
    _, band, rx, ry = iso.ell(cx, cy, 9 * k, 0.18)
    o.append(path(f"M{f(sx - rx)},{f(band)} A{f(rx)},{f(ry)} 0 0 0 {f(sx + rx)},{f(band)}", "none", "#2f6fd9", 3 * k, 'opacity="0.85"'))
    _, top, rx, ry = iso.ell(cx, cy, 16 * k, 0.18)
    body = D.lin([(0, "#7fe06a"), (0.5, "#3fae4a"), (1, "#23803a")], 0, 0, 1, 0)
    o.append(path(f"M{f(sx - 7 * k)},{f(top)} L{f(sx - 7 * k)},{f(top - 40 * k)} Q{f(sx)},{f(top - 50 * k)} {f(sx + 7 * k)},{f(top - 40 * k)} L{f(sx + 7 * k)},{f(top)} Z", body, INK3, 1.1))
    o.append(path(f"M{f(sx - 7 * k)},{f(top - 18 * k)} L{f(sx - 15 * k)},{f(top - 18 * k)} Q{f(sx - 19 * k)},{f(top - 18 * k)} {f(sx - 19 * k)},{f(top - 24 * k)} L{f(sx - 19 * k)},{f(top - 32 * k)} Q{f(sx - 15 * k)},{f(top - 37 * k)} {f(sx - 12 * k)},{f(top - 32 * k)} L{f(sx - 12 * k)},{f(top - 25 * k)} L{f(sx - 7 * k)},{f(top - 25 * k)} Z", body, INK3, 1.0))
    o.append(path(f"M{f(sx + 7 * k)},{f(top - 26 * k)} L{f(sx + 13 * k)},{f(top - 26 * k)} L{f(sx + 13 * k)},{f(top - 36 * k)} Q{f(sx + 16 * k)},{f(top - 40 * k)} {f(sx + 19 * k)},{f(top - 36 * k)} L{f(sx + 19 * k)},{f(top - 24 * k)} Q{f(sx + 19 * k)},{f(top - 20 * k)} {f(sx + 15 * k)},{f(top - 20 * k)} L{f(sx + 7 * k)},{f(top - 20 * k)} Z", body, INK3, 1.0))
    for (dx, dy) in [(-3, -30), (3, -22), (-2, -12), (2, -38), (-15, -28), (16, -32)]:
        o.append(line(sx + dx * k, top + dy * k, sx + dx * k + 1.6 * k, top + dy * k - 1.6 * k, "#fff6d8", 0.8))
    o.append(C(sx, top - 47 * k, 3.6 * k, "#ff4d8d", INK3, 0.8) + C(sx, top - 47 * k, 1.4 * k, "#ffd23f", None))
    return "".join(o)


def pinata(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.3, opacity=0.22), box3(D, iso, x + 0.36, y + 0.36, 0.28, 0.28, 3 * k, WOOD_D)]
    o.append(line(sx, sy - 3 * k, sx, sy - 88 * k, WOOD_M, 2.6 * k) + line(sx, sy - 88 * k, sx + 18 * k, sy - 92 * k, WOOD_M, 2.4 * k))
    o.append(line(sx + 16 * k, sy - 91 * k, sx + 16 * k, sy - 80 * k, "#8a8f96", 0.9))
    # burro de piñata em listras coloridas
    by = sy - 62 * k
    bx = sx + 16 * k
    body = f"M{f(bx - 14 * k)},{f(by)} Q{f(bx - 14 * k)},{f(by - 14 * k)} {f(bx)},{f(by - 14 * k)} Q{f(bx + 14 * k)},{f(by - 14 * k)} {f(bx + 14 * k)},{f(by)} Q{f(bx + 14 * k)},{f(by + 8 * k)} {f(bx)},{f(by + 8 * k)} Q{f(bx - 14 * k)},{f(by + 8 * k)} {f(bx - 14 * k)},{f(by)} Z"
    o.append(path(body, stripes_pattern(D, "#ff4d6d", "#ffd23f", 3), INK3, 1.0))
    o.append(path(f"M{f(bx + 10 * k)},{f(by - 10 * k)} L{f(bx + 16 * k)},{f(by - 22 * k)} L{f(bx + 22 * k)},{f(by - 18 * k)} L{f(bx + 15 * k)},{f(by - 8 * k)} Z",
                  stripes_pattern(D, "#4fc3ff", "#7ee85a", 3), INK3, 1.0))
    for lx in (-10, -4, 4, 10):
        o.append(line(bx + lx * k, by + 6 * k, bx + lx * k, by + 16 * k, "#b06bff", 3 * k))
    o.append(C(bx + 18 * k, by - 18 * k, 1.2 * k, INK3, None))
    return "".join(o)


# --- Enfeites: Anos 80 ---------------------------------------------------------------------

def arcade(D, iso, x, y):
    k = K(iso)
    bx, by, w, d = x + 0.16, y + 0.2, 0.68, 0.6
    h = 64 * k
    o = [soft_shadow(D, iso, x + 0.5, y + 0.5, 0.45, opacity=0.3)]
    o.append(box3(D, iso, bx, by, w, d, h, "#2a2d6e", left="#3a3fa0", right="#1d2050"))
    t = plane(iso, "R", bx, by + d, 0)
    width_px = w * iso.W / 2
    inner = (f'<rect x="{f(width_px * 0.12)}" y="{f(-h * 0.84)}" width="{f(width_px * 0.76)}" height="{f(h * 0.3)}" rx="{f(2 * k)}" fill="#0d1a36" stroke="{INK3}" stroke-width="0.8"/>'
             f'<rect x="{f(width_px * 0.18)}" y="{f(-h * 0.8)}" width="{f(width_px * 0.64)}" height="{f(h * 0.22)}" fill="{D.lin([(0, "#4fe0ff"), (1, "#b04dff")])}"/>'
             f'<circle cx="{f(width_px * 0.35)}" cy="{f(-h * 0.7)}" r="{f(2.4 * k)}" fill="#ffd23f"/>'
             f'<rect x="{f(width_px * 0.55)}" y="{f(-h * 0.74)}" width="{f(4 * k)}" height="{f(4 * k)}" fill="#ff4dd2"/>'
             f'<rect x="{f(width_px * 0.08)}" y="{f(-h * 0.5)}" width="{f(width_px * 0.84)}" height="{f(h * 0.1)}" rx="{f(1.5 * k)}" fill="#ff4dd2" stroke="{INK3}" stroke-width="0.7"/>'
             f'<circle cx="{f(width_px * 0.3)}" cy="{f(-h * 0.46)}" r="{f(2.2 * k)}" fill="#ff3d3d" stroke="{INK3}" stroke-width="0.6"/>'
             f'<circle cx="{f(width_px * 0.6)}" cy="{f(-h * 0.46)}" r="{f(1.8 * k)}" fill="#4fe0ff" stroke="{INK3}" stroke-width="0.6"/>'
             f'<circle cx="{f(width_px * 0.72)}" cy="{f(-h * 0.46)}" r="{f(1.8 * k)}" fill="#7ee85a" stroke="{INK3}" stroke-width="0.6"/>'
             f'<rect x="{f(width_px * 0.12)}" y="{f(-h * 0.98)}" width="{f(width_px * 0.76)}" height="{f(h * 0.1)}" rx="{f(2 * k)}" fill="#ffd23f" stroke="{INK3}" stroke-width="0.7"/>'
             f'<rect x="{f(width_px * 0.3)}" y="{f(-h * 0.25)}" width="{f(width_px * 0.4)}" height="{f(h * 0.08)}" rx="1" fill="#0d1a36"/>')
    o.append(f'<g transform="{t}">{inner}</g>')
    return "".join(o)


def boombox(D, iso, x, y):
    k = K(iso)
    o = [soft_shadow(D, iso, x + 0.5, y + 0.5, 0.36, opacity=0.25)]
    o.append(box3(D, iso, x + 0.28, y + 0.28, 0.44, 0.44, 14 * k, "#ffd23f"))
    bx, by, w, d, h = x + 0.14, y + 0.36, 0.72, 0.28, 22 * k
    o.append(box3(D, iso, bx, by, w, d, h, "#3a3c46", z=14 * k, left="#4a4d5a", right="#2a2c34"))
    t = plane(iso, "R", bx, by + d, 14 * k)
    width_px = w * iso.W / 2
    inner = ""
    for u in (0.22, 0.78):
        inner += f'<circle cx="{f(width_px * u)}" cy="{f(-h * 0.45)}" r="{f(h * 0.3)}" fill="#1d1e24" stroke="#8f9aa7" stroke-width="{f(1.4 * k)}"/>'
        inner += f'<circle cx="{f(width_px * u)}" cy="{f(-h * 0.45)}" r="{f(h * 0.12)}" fill="#4a4d5a"/>'
    inner += f'<rect x="{f(width_px * 0.4)}" y="{f(-h * 0.65)}" width="{f(width_px * 0.2)}" height="{f(h * 0.35)}" rx="1" fill="#4fe0ff" opacity="0.8"/>'
    o.append(f'<g transform="{t}">{inner}</g>')
    a, b = iso.v(bx + 0.1, by + d / 2, 14 * k + h), iso.v(bx + w - 0.1, by + d / 2, 14 * k + h)
    o.append(path(f"M{f(a[0])},{f(a[1])} Q{f((a[0] + b[0]) / 2)},{f(a[1] - 12 * k)} {f(b[0])},{f(b[1])}", "none", "#8f9aa7", 2.4 * k))
    return "".join(o)


# --- Enfeites: Italiano --------------------------------------------------------------------

def wine_barrel(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.34, opacity=0.28)]
    o.append(cyl3(D, iso, cx, cy, 0.3, 0, 34 * k, "#a8582e", top="#c98a52"))
    for z in (6, 28):
        _, zy, rx, ry = iso.ell(cx, cy, z * k, 0.3)
        o.append(path(f"M{f(sx - rx)},{f(zy)} A{f(rx)},{f(ry)} 0 0 0 {f(sx + rx)},{f(zy)}", "none", "#3a3c46", 2.6 * k))
    _, top, rx, ry = iso.ell(cx, cy, 34 * k, 0.3)
    # garrafa e taça em cima
    o.append(cyl3(D, iso, cx - 0.06, cy, 0.05, 34 * k, 50 * k, "#2f6a3a"))
    o.append(cyl3(D, iso, cx - 0.06, cy, 0.02, 50 * k, 56 * k, "#2f6a3a", cap=False))
    o.append(path(f"M{f(sx + 8 * k)},{f(top - 2 * k)} L{f(sx + 8 * k)},{f(top - 8 * k)} M{f(sx + 4 * k)},{f(top - 14 * k)} Q{f(sx + 8 * k)},{f(top - 6 * k)} {f(sx + 12 * k)},{f(top - 14 * k)} Z",
                  "#9a1d3a", INK3, 0.8))
    return "".join(o)


def olive_tree(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.34, opacity=0.28)]
    o.append(cyl3(D, iso, cx, cy, 0.22, 0, 20 * k, "#d9824a"))
    o.append(cyl3(D, iso, cx, cy, 0.25, 16 * k, 22 * k, "#c96a2c"))
    _, top, _, _ = iso.ell(cx, cy, 22 * k, 0.2)
    o.append(path(f"M{f(sx - 2 * k)},{f(top)} Q{f(sx - 6 * k)},{f(top - 20 * k)} {f(sx + 1 * k)},{f(top - 40 * k)} M{f(sx + 1 * k)},{f(top - 26 * k)} Q{f(sx + 10 * k)},{f(top - 32 * k)} {f(sx + 12 * k)},{f(top - 44 * k)}",
                  "none", "#6b4a2e", 3.2 * k))
    r = Rng(11)
    for _ in range(26):
        lx, ly = sx + r.u(-22, 22) * k, top - r.u(30, 64) * k
        o.append(f'<path d="{leaf(0, 0, 0, 9 * k, 2.6 * k, 0.1)}" fill="{mix("#8aa85a", "#b8c98a", r.r())}" stroke="#4a6a2e" stroke-width="0.6" '
                 f'transform="translate({f(lx)},{f(ly)}) rotate({f(r.u(-60, 60))})"/>')
    for _ in range(6):
        o.append(E(sx + r.u(-16, 16) * k, top - r.u(36, 58) * k, 1.6 * k, 2.2 * k, "#2a2d3e", None))
    return "".join(o)


# --- Enfeites: Japonês ---------------------------------------------------------------------

def bonsai(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.3, opacity=0.25)]
    o.append(box3(D, iso, x + 0.3, y + 0.34, 0.4, 0.32, 18 * k, "#4a2a1e"))
    o.append(box3(D, iso, x + 0.24, y + 0.28, 0.52, 0.44, 8 * k, "#2f6fb0", z=18 * k, left="#3a82c8", right="#245a90"))
    top = sy - 26 * k
    o.append(path(f"M{f(sx)},{f(top)} Q{f(sx - 10 * k)},{f(top - 10 * k)} {f(sx - 4 * k)},{f(top - 20 * k)} Q{f(sx + 6 * k)},{f(top - 28 * k)} {f(sx - 2 * k)},{f(top - 38 * k)}",
                  "none", "#5a3a24", 3.4 * k))
    for (dx, dy, rx, ry) in [(-14, -22, 13, 6), (8, -30, 12, 5.5), (-6, -42, 11, 5.4), (14, -18, 8, 4)]:
        o.append(E(sx + dx * k, top + dy * k, rx * k, ry * k, D.rad([(0, "#9fe07a"), (0.6, "#4fae3f"), (1, "#2a7a2e")], 0.4, 0.3, 0.8), "#1d5a2a", 1.0))
    return "".join(o)


def paper_lantern(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.24, opacity=0.25), cyl3(D, iso, cx, cy, 0.12, 0, 3 * k, "#2a2d3e")]
    o.append(line(sx, sy - 3 * k, sx, sy - 74 * k, "#2a2d3e", 2.4 * k) + line(sx, sy - 74 * k, sx + 14 * k, sy - 78 * k, "#2a2d3e", 2.2 * k))
    lx, ly = sx + 14 * k, sy - 54 * k
    o.append(C(lx, ly, 26 * k, D.rad([(0, "#ffb13d", 0.4), (1, "#ffb13d", 0)]), None))
    o.append(E(lx, ly, 13 * k, 17 * k, D.rad([(0, "#ffe08a"), (0.5, "#ff5a4a"), (1, "#c81e2a")], 0.45, 0.4, 0.75), INK3, 1.1))
    for dy in (-10, -4, 2, 8):
        w = 13 * k * math.sqrt(max(0.0, 1 - (dy / 17) ** 2))
        o.append(path(f"M{f(lx - w)},{f(ly + dy * k)} Q{f(lx)},{f(ly + dy * k + 2 * k)} {f(lx + w)},{f(ly + dy * k)}", "none", "#9a1d2a", 0.8, 'opacity="0.7"'))
    o.append(f'<rect x="{f(lx - 6 * k)}" y="{f(ly - 20 * k)}" width="{f(12 * k)}" height="{f(4 * k)}" rx="1" fill="#2a2d3e"/>')
    o.append(f'<rect x="{f(lx - 6 * k)}" y="{f(ly + 16 * k)}" width="{f(12 * k)}" height="{f(4 * k)}" rx="1" fill="#2a2d3e"/>')
    o.append(line(lx, ly + 20 * k, lx, ly + 28 * k, "#ffd23f", 1.4 * k))
    return "".join(o)


# --- Enfeites: Francês ---------------------------------------------------------------------

def eiffel(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.3, opacity=0.25)]
    o.append(box3(D, iso, x + 0.3, y + 0.3, 0.4, 0.4, 14 * k, "#ffffff", top="#f3f6fa"))
    base = sy - 14 * k
    col = D.lin([(0, "#c9a46a"), (1, "#8a6a3e")], 0, 0, 1, 0)
    o.append(path(f"M{f(sx - 14 * k)},{f(base)} Q{f(sx - 6 * k)},{f(base - 20 * k)} {f(sx - 3 * k)},{f(base - 46 * k)} L{f(sx - 1 * k)},{f(base - 72 * k)} "
                  f"L{f(sx + 1 * k)},{f(base - 72 * k)} L{f(sx + 3 * k)},{f(base - 46 * k)} Q{f(sx + 6 * k)},{f(base - 20 * k)} {f(sx + 14 * k)},{f(base)} "
                  f"L{f(sx + 8 * k)},{f(base)} Q{f(sx)},{f(base - 12 * k)} {f(sx - 8 * k)},{f(base)} Z", col, INK3, 1.0))
    for (y0, w) in [(-20, 9), (-46, 4.6)]:
        o.append(f'<rect x="{f(sx - w * k)}" y="{f(base + y0 * k - 2 * k)}" width="{f(2 * w * k)}" height="{f(3 * k)}" fill="#6b4a2e" stroke="{INK3}" stroke-width="0.6"/>')
    o.append(line(sx, base - 72 * k, sx, base - 80 * k, "#6b4a2e", 1.2 * k))
    for i in range(5):
        y0 = base - (6 + i * 8) * k
        o.append(path(f"M{f(sx - (11 - i * 1.8) * k)},{f(y0)} L{f(sx + (11 - i * 1.8) * k)},{f(y0 - 6 * k)}", "none", "#6b4a2e", 0.6, 'opacity="0.7"'))
    return "".join(o)


def paris_lamp(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.24, opacity=0.25)]
    o.append(cyl3(D, iso, cx, cy, 0.12, 0, 6 * k, "#2a3a3a"))
    o.append(path(f"M{f(sx - 3 * k)},{f(sy - 6 * k)} L{f(sx - 1.6 * k)},{f(sy - 80 * k)} L{f(sx + 1.6 * k)},{f(sy - 80 * k)} L{f(sx + 3 * k)},{f(sy - 6 * k)} Z",
                  D.lin([(0, "#4a6060"), (1, "#1d2a2a")], 0, 0, 1, 0), INK3, 1.0))
    o.append(path(f"M{f(sx - 1 * k)},{f(sy - 70 * k)} Q{f(sx - 12 * k)},{f(sy - 72 * k)} {f(sx - 14 * k)},{f(sy - 84 * k)} M{f(sx + 1 * k)},{f(sy - 70 * k)} Q{f(sx + 12 * k)},{f(sy - 72 * k)} {f(sx + 14 * k)},{f(sy - 84 * k)}",
                  "none", "#2a3a3a", 1.8 * k))
    for lx in (-14, 14):
        x0 = sx + lx * k
        o.append(C(x0, sy - 92 * k, 14 * k, D.rad([(0, "#fff3b0", 0.55), (1, "#fff3b0", 0)]), None))
        o.append(path(f"M{f(x0 - 5 * k)},{f(sy - 86 * k)} L{f(x0 - 4 * k)},{f(sy - 98 * k)} L{f(x0 + 4 * k)},{f(sy - 98 * k)} L{f(x0 + 5 * k)},{f(sy - 86 * k)} Z",
                      D.lin([(0, "#fffbe0"), (1, "#ffd966")]), INK3, 0.9))
        o.append(path(f"M{f(x0 - 6 * k)},{f(sy - 98 * k)} L{f(x0)},{f(sy - 104 * k)} L{f(x0 + 6 * k)},{f(sy - 98 * k)} Z", "#2a3a3a", INK3, 0.8))
    return "".join(o)


# --- Enfeites: Brasileiro ------------------------------------------------------------------

def banana_tree(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.34, opacity=0.28)]
    o.append(cyl3(D, iso, cx, cy, 0.2, 0, 18 * k, "#ffd23f"))
    o.append(cyl3(D, iso, cx, cy, 0.23, 14 * k, 20 * k, "#2fae4e"))
    _, top, _, _ = iso.ell(cx, cy, 20 * k, 0.2)
    o.append(path(f"M{f(sx - 2 * k)},{f(top)} L{f(sx - 1 * k)},{f(top - 40 * k)} L{f(sx + 2 * k)},{f(top - 40 * k)} L{f(sx + 2 * k)},{f(top)} Z", "#8aa85a", INK3, 0.9))
    for (a, ln) in [(-150, 38), (-115, 44), (-80, 46), (-45, 42), (-15, 34), (-170, 30)]:
        ang = math.radians(a)
        tx, ty = sx + math.cos(ang) * ln * k, top - 40 * k + math.sin(ang) * ln * 0.7 * k
        mx, my = (sx + tx) / 2, (top - 40 * k + ty) / 2
        o.append(f'<path d="{leaf(0, 0, 0, ln * k, 11 * k, 0.05)}" fill="{D.lin([(0, "#8ff06a"), (0.6, "#3fbf4a"), (1, "#23803a")], 0, 0, 1, 1)}" stroke="#1d6b33" stroke-width="0.9" '
                 f'transform="translate({f(mx)},{f(my)}) rotate({f(a)})"/>')
        o.append(line(sx, top - 40 * k, tx, ty, "#1d6b33", 0.8, 'opacity="0.6"'))
    for i in range(3):
        o.append(path(f"M{f(sx + 3 * k)},{f(top - (24 + i * 4) * k)} q{f(5 * k)},{f(-1 * k)} {f(8 * k)},{f(4 * k)}", "none", "#ffd23f", 2.4 * k))
    return "".join(o)


def parrot(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.26, opacity=0.25), cyl3(D, iso, cx, cy, 0.14, 0, 3 * k, WOOD_D)]
    o.append(line(sx, sy - 3 * k, sx, sy - 60 * k, WOOD_M, 2.6 * k))
    o.append(line(sx - 14 * k, sy - 60 * k, sx + 14 * k, sy - 60 * k, WOOD_D, 3 * k))
    px, py = sx + 2 * k, sy - 72 * k
    o.append(path(f"M{f(px - 2 * k)},{f(py + 12 * k)} L{f(px - 6 * k)},{f(py + 30 * k)} L{f(px + 1 * k)},{f(py + 28 * k)} Z", "#2f6fd9", INK3, 0.8))
    o.append(E(px, py, 7 * k, 12 * k, D.lin([(0, "#7ee85a"), (1, "#23a63a")]), INK3, 1.0))
    o.append(path(f"M{f(px - 6 * k)},{f(py - 2 * k)} Q{f(px - 11 * k)},{f(py + 8 * k)} {f(px - 3 * k)},{f(py + 12 * k)} Z", "#ffd23f", INK3, 0.8))
    o.append(C(px + 1 * k, py - 12 * k, 6 * k, "#ff4d4d", INK3, 1.0))
    o.append(path(f"M{f(px + 6 * k)},{f(py - 13 * k)} Q{f(px + 11 * k)},{f(py - 12 * k)} {f(px + 8 * k)},{f(py - 6 * k)} Z", "#ffe08a", INK3, 0.8))
    o.append(C(px + 3 * k, py - 14 * k, 1.6 * k, "#ffffff", None) + C(px + 3.4 * k, py - 14 * k, 0.8 * k, INK3, None))
    return "".join(o)


# --- Enfeites: Anos 2010 -------------------------------------------------------------------

def edison_lamp(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.22, opacity=0.25), cyl3(D, iso, cx, cy, 0.14, 0, 3 * k, "#2a2c34")]
    o.append(line(sx, sy - 3 * k, sx, sy - 70 * k, "#2a2c34", 2.2 * k) + line(sx, sy - 70 * k, sx + 18 * k, sy - 74 * k, "#2a2c34", 2 * k))
    o.append(line(sx + 18 * k, sy - 74 * k, sx + 18 * k, sy - 62 * k, "#2a2c34", 1 * k))
    bx, by = sx + 18 * k, sy - 54 * k
    o.append(C(bx, by, 16 * k, D.rad([(0, "#ffd27a", 0.5), (1, "#ffd27a", 0)]), None))
    o.append(f'<rect x="{f(bx - 2.4 * k)}" y="{f(by - 10 * k)}" width="{f(4.8 * k)}" height="{f(4 * k)}" fill="#b8902e" stroke="{INK3}" stroke-width="0.6"/>')
    o.append(E(bx, by, 5.4 * k, 7 * k, "#fff3c8", INK3, 0.9, 'opacity="0.9"'))
    o.append(path(f"M{f(bx - 2 * k)},{f(by + 2 * k)} L{f(bx - 1 * k)},{f(by - 3 * k)} L{f(bx)},{f(by + 1 * k)} L{f(bx + 1 * k)},{f(by - 3 * k)} L{f(bx + 2 * k)},{f(by + 2 * k)}",
                  "none", "#ff8a2a", 0.9))
    return "".join(o)


def succulents(D, iso, x, y):
    k = K(iso)
    o = [soft_shadow(D, iso, x + 0.5, y + 0.5, 0.36, opacity=0.25)]
    o.append(box3(D, iso, x + 0.16, y + 0.3, 0.68, 0.4, 26 * k, WOOD_L, top="#f2d0a0"))
    for (u, pot, plant) in [(0.28, "#ffffff", "#8fd18a"), (0.5, "#e0c49a", "#6fbf8a"), (0.72, "#b8bcc2", "#a0d8a0")]:
        px, py = iso.v(x + 0.16 + 0.68 * u, y + 0.5, 26 * k)
        o.append(path(f"M{f(px - 6 * k)},{f(py)} L{f(px - 5 * k)},{f(py - 8 * k)} L{f(px + 5 * k)},{f(py - 8 * k)} L{f(px + 6 * k)},{f(py)} Z", pot, INK3, 0.9))
        for i in range(6):
            a = math.radians(i * 60)
            o.append(E(px + math.cos(a) * 3.4 * k, py - 11 * k + math.sin(a) * 1.8 * k, 3 * k, 2 * k, plant, "#3a7a4a", 0.6))
        o.append(C(px, py - 12 * k, 2.2 * k, tint(plant, 0.3), "#3a7a4a", 0.6))
    return "".join(o)


# --- Enfeites: Balada ----------------------------------------------------------------------

def disco_ball(D, iso, x, y):
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.24, opacity=0.25), cyl3(D, iso, cx, cy, 0.14, 0, 3 * k, "#1d1d2b")]
    o.append(line(sx, sy - 3 * k, sx, sy - 82 * k, "#1d1d2b", 2.4 * k) + line(sx, sy - 82 * k, sx + 16 * k, sy - 86 * k, "#1d1d2b", 2.2 * k))
    o.append(line(sx + 16 * k, sy - 86 * k, sx + 16 * k, sy - 76 * k, "#8f9aa7", 1 * k))
    bx, by = sx + 16 * k, sy - 62 * k
    for (c, a) in [("#ff4dd2", -40), ("#4fe0ff", 20), ("#ffd23f", 160)]:
        ang = math.radians(a)
        o.append(path(f"M{f(bx)},{f(by)} L{f(bx + math.cos(ang - 0.15) * 40 * k)},{f(by + math.sin(ang - 0.15) * 40 * k)} L{f(bx + math.cos(ang + 0.15) * 40 * k)},{f(by + math.sin(ang + 0.15) * 40 * k)} Z",
                      c, None, 'opacity="0.18"'))
    o.append(C(bx, by, 13 * k, D.rad([(0, "#ffffff"), (0.5, "#c9d3de"), (1, "#6a7480")], 0.35, 0.3, 0.8), INK3, 1.1))
    for i in range(-3, 4):
        w = 13 * k * math.sqrt(max(0.0, 1 - (i / 3.5) ** 2))
        o.append(line(bx - w, by + i * 3.4 * k, bx + w, by + i * 3.4 * k, "#8f9aa7", 0.6, 'opacity="0.8"'))
    for i in range(-2, 3):
        o.append(path(f"M{f(bx + i * 4.4 * k)},{f(by - 12.6 * k)} Q{f(bx + i * 5.4 * k)},{f(by)} {f(bx + i * 4.4 * k)},{f(by + 12.6 * k)}", "none", "#8f9aa7", 0.6, 'opacity="0.8"'))
    for (dx, dy) in [(-5, -6), (3, -8), (-2, 2), (6, 4)]:
        o.append(f'<rect x="{f(bx + dx * k)}" y="{f(by + dy * k)}" width="{f(2.6 * k)}" height="{f(2.6 * k)}" fill="#ffffff"/>')
    return "".join(o)


def dj_booth(D, iso, x, y, along="x"):
    """Cabine de DJ 2x1: mesa preta com toca-discos, mixer de luzinhas e frente de LED."""
    k = K(iso)
    if along == "x":
        bx, by, w, d = x + 0.06, y + 0.14, 1.88, 0.72
    else:
        bx, by, w, d = x + 0.14, y + 0.06, 0.72, 1.88
    h = 34 * k
    o = [soft_shadow(D, iso, bx + w / 2, by + d / 2, 0.7, 0.3, opacity=0.3)]
    o.append(box3(D, iso, bx, by, w, d, h, "#1d1d2b", top="#2a2d3e", left="#2a2d3e", right="#15151f"))
    face = "L" if along == "x" else "R"
    for i in range(6):
        u0, u1 = i / 6 + 0.02, (i + 1) / 6 - 0.02
        q = iso.quad(face, bx, by, w, d, 0, h, u0, u1, 0.2, 0.8)
        o.append(P(q, ["#ff4dd2", "#4fe0ff", "#ffd23f", "#7ee85a", "#b04dff", "#ff7a2f"][i], None, 'opacity="0.85"'))
    spots = [(0.25, 0.5), (0.75, 0.5)] if along == "x" else [(0.5, 0.25), (0.5, 0.75)]
    for (u, v) in spots:
        tx, ty = bx + u * w, by + v * d
        sx, st, rx, ry = iso.ell(tx, ty, h, 0.24)
        o.append(E(sx, st, rx, ry, "#0d0d14", "#8f9aa7", 1.2))
        o.append(E(sx, st, rx * 0.4, ry * 0.4, "#ff4d6d", None))
    mx, my = iso.v(bx + w / 2, by + d / 2, h)
    for i in range(4):
        o.append(C(mx - 6 * k + i * 4 * k, my, 1.6 * k, ["#7ee85a", "#ffd23f", "#ff4d6d", "#4fe0ff"][i], None))
    return "".join(o)


# --- Coleções: cadeiras, mesas e enfeites --------------------------------------------------

CHAIRS = {
    "chair_70s": dict(seat="#ff8a3d", legs="pedestal", leg_color="#f2f0e8", back="egg", back_color="#e07a2e", back_h=26),
    "chair_country": dict(seat="#c98a52", legs="wood", leg_color=WOOD_M, back="ladder", back_color=WOOD_M),
    "chair_party": dict(seat="#ff8fb1", legs="wood", leg_color="#ffffff", back="panel", back_color="#ffd6e7"),
    "stool_diner": dict(seat="#e0303a", legs="pedestal", leg_color=CHROME, back=None),
    "chair_mexican": dict(seat="#2ea86b", legs="wood", leg_color="#2f6fd9", back="painted", back_color="#ffd23f"),
    "chair_80s": dict(seat="#ff4dd2", legs="chrome", leg_color="#4fe0ff", back="shell", back_color="#4fe0ff"),
    "chair_italian": dict(seat="#b0382e", legs="wood", leg_color="#5a3020", back="slats", back_color="#6b3a1e"),
    "chair_japanese": dict(seat="#d9433b", legs="wood", leg_color="#c9a46a", back="cane", back_color="#e0c48a"),
    "chair_french": dict(seat="#3a6ad9", legs="wood", leg_color="#a8743e", back="wicker", back_color="#d9b77e"),
    "chair_brazil": dict(seat="#ffd23f", legs="wood", leg_color=WOOD_D, back="cane", back_color="#e8c890"),
    "chair_2010s": dict(seat="#f2f2f2", legs="wood", leg_color="#d9b77e", back="shell", back_color="#ffffff"),
    "chair_club": dict(seat="#7a2fd0", legs="chrome", leg_color="#ffd23f", back="tufted", back_color="#8a3fe0", back_h=34),
}

TABLES = {
    "table_70s": (dict(shape="round", top=("solid", "#ff8a3d"), edge="#e07a2e", base="pedestal", base_color="#f2f0e8"), 34),
    "table_country": (dict(shape="square", top=("wood", "#b8743e"), edge="#8a4f26", base="legs", base_color="#8a4f26",
                           flower=("#ffd23f", "#ffffff")), 32),
    "table_party": (dict(shape="round", cloth=("confetti", "#fff0f6"), base="pedestal", base_color="#ffffff", flower=("#ff4d6d", "#4fc3ff")), 34),
    "table_diner": (dict(shape="square", top=("solid", "#ffffff"), edge="#4fd1c5", base="pedestal", base_color=CHROME), 32),
    "table_mexican": (dict(shape="square", top=("talavera", "#ffffff"), edge="#2f6fd9", base="legs", base_color=WOOD_D, vase=False), 32),
    "table_80s": (dict(shape="round", top=("memphis", "#ffffff"), edge="#2a2d6e", base="pedestal", base_color="#ff4dd2", vase=False), 34),
    "table_italian": (dict(shape="square", cloth=("gingham", "#e04040"), base="legs", base_color="#5a3020", vase=False, candle=True), 32),
    "table_japanese": (dict(shape="square", top=("wood", "#6b4423"), edge="#4a2a1e", base="legs", base_color="#2a1a12", flower=("#ff8fb1", "#ffffff")), 30),
    "table_french": (dict(shape="round", top=("marble", "#f2f1ee"), edge="#c9c4bc", base="pedestal", base_color="#2a2d3e"), 34),
    "table_brazil": (dict(shape="square", cloth=("chita", "#ff5a5a"), base="legs", base_color=WOOD_D, flower=("#ffd23f", "#ff4d8d")), 32),
    "table_2010s": (dict(shape="square", top=("wood", "#e8cfa4"), edge="#d9b77e", base="legs", base_color="#2a2c34", flower=("#ffffff", "#8fd18a")), 32),
    "table_club": (dict(shape="round", top=("glow", "#1d1d2b"), edge="#0d0d14", base="pedestal", base_color="#1d1d2b", vase=False, candle=True), 36),
}

# Mais uma cadeira e uma mesa em cada coleção (o PO pediu mais opções por estilo e cultura).
CHAIRS.update({
    "chair_tulip": dict(seat="#ffffff", legs="pedestal", leg_color="#ffffff", back="shell", back_color="#ff8a3d"),
    "bench_country": dict(seat="#d9a066", legs="wood", leg_color=WOOD_D, back="slats", back_color=WOOD_M),
    "chair_party_blue": dict(seat="#8fd0ff", legs="wood", leg_color="#ffffff", back="panel", back_color="#cfeaff"),
    "chair_diner": dict(seat="#e0303a", legs="chrome", leg_color=CHROME, back="panel", back_color="#ffffff"),
    "chair_equipal": dict(seat="#c98a52", legs="wood", leg_color="#8a5530", back="cane", back_color="#b8743e"),
    "chair_80s_pink": dict(seat="#4fe0ff", legs="chrome", leg_color="#ff4dd2", back="shell", back_color="#ff4dd2"),
    "chair_tuscan": dict(seat="#2f9e44", legs="wood", leg_color="#6b3a1e", back="cane", back_color="#d9b77e"),
    "stool_zen": dict(seat="#d9433b", legs="wood", leg_color="#c9a46a", back=None),
    "chair_french_red": dict(seat="#c81e3a", legs="wood", leg_color="#2a2d3e", back="wicker", back_color="#c9a46a"),
    "chair_brazil_flag": dict(seat="#2fae4e", legs="wood", leg_color=WOOD_M, back="panel", back_color="#ffd23f"),
    "stool_industrial": dict(seat="#c98a52", legs="chrome", leg_color="#3a3c46", back=None),
    "stool_club": dict(seat="#7a2fd0", legs="pedestal", leg_color="#ffd23f", back=None),
})

TABLES.update({
    "table_70s_square": (dict(shape="square", top=("solid", "#f2b33d"), edge="#b0532a", base="pedestal", base_color="#f2f0e8"), 32),
    "table_country_round": (dict(shape="round", cloth=("gingham", "#3a6ad9"), base="pedestal", base_color=WOOD_D, flower=("#ffd23f", "#ffffff")), 34),
    "table_party_square": (dict(shape="square", cloth=("confetti", "#e8f6ff"), base="legs", base_color="#ffffff", flower=("#ff4d6d", "#ffd23f")), 32),
    "table_diner_round": (dict(shape="round", top=("solid", "#e0303a"), edge=CHROME, base="pedestal", base_color=CHROME), 34),
    "table_mexican_round": (dict(shape="round", cloth=("plain", "#ff7a2f"), base="pedestal", base_color=WOOD_D, flower=("#ff4d8d", "#ffd23f")), 34),
    "table_80s_square": (dict(shape="square", top=("glow", "#1d1d2b"), edge="#ff4dd2", base="pedestal", base_color="#4fe0ff", vase=False), 32),
    "table_italian_round": (dict(shape="round", cloth=("plain", "#ffffff"), base="pedestal", base_color="#5a3020", vase=False, candle=True), 34),
    "table_japanese_round": (dict(shape="round", top=("solid", "#8a5a34"), edge="#4a2a1e", base="pedestal", base_color="#2a1a12", flower=("#ff8fb1", "#ffffff")), 30),
    "table_french_square": (dict(shape="square", top=("marble", "#f2f1ee"), edge="#d9b44a", base="legs", base_color="#2a2d3e"), 32),
    "table_brazil_round": (dict(shape="round", cloth=("chita", "#2f6fd9"), base="pedestal", base_color=WOOD_D, flower=("#ffd23f", "#ff4d8d")), 34),
    "table_2010s_round": (dict(shape="round", top=("solid", "#e8cfa4"), edge="#ffffff", base="pedestal", base_color="#2a2c34", flower=("#ffffff", "#8fd18a")), 34),
    "table_club_square": (dict(shape="square", top=("glow", "#1d1d2b"), edge="#0d0d14", base="pedestal", base_color="#1d1d2b", vase=False, candle=True), 36),
})

# Fogões e balcões modernos: as medidas do fogão e a altura do balcão são as mesmas do clássico
# (a panela, o forno aceso e as pilhas de pratos do jogo caem no lugar certo).
STOVES = {
    "stove_steel": dict(enamel="#b9c3cf", top_color="#e8edf2", panel=("#4a4d5a", "#2a2c34", "#15151b"), knob="#c9d3de",
                        door=("#d9e0e8", "#8f9aa7"), handle="#2a2c34"),
    "stove_mint": dict(enamel="#7fdcc0", knob="#ff4d5e"),
    "stove_black": dict(enamel="#2a2a33", top_color="#4a4a55", panel=("#ffe7a0", "#d9b44a", "#8a6a2e"), knob="#d9b44a",
                        door=("#3a3c46", "#15151b"), handle="#d9b44a"),
}
COUNTERS = {
    "counter_steel": dict(body="#b9c3cf", top="#eef2f6", face="plain", rim="#c9d3de", veins=False),
    "counter_wood": dict(body="#a86d40", top="#e0b97e", face="planks", rim="#b8743e", veins=False),
    "counter_pastel": dict(body="#ff9ec4", top="#ffffff", face="panels", rim="#ffe0ef"),
}

DECOR = {
    "lava_lamp": lava_lamp, "macrame_plant": macrame_plant, "hay_bale": hay_bale, "wagon_wheel": wagon_wheel,
    "balloons": balloons, "party_cake": party_cake, "jukebox": jukebox, "neon_diner": neon_sign,
    "cactus": cactus, "pinata": pinata, "arcade": arcade, "boombox": boombox, "wine_barrel": wine_barrel,
    "olive_tree": olive_tree, "bonsai": bonsai, "paper_lantern": paper_lantern, "eiffel": eiffel,
    "paris_lamp": paris_lamp, "banana_tree": banana_tree, "parrot": parrot, "edison_lamp": edison_lamp,
    "succulents": succulents, "disco_ball": disco_ball,
}
