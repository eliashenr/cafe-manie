"""Cena da cafeteria na esquina (SVG original) para as pranchas de direção visual."""
from svgkit import *

N = 9  # cafeteria 9x9


def ground(iso, width, height):
    out = []
    # manchas de grama mais clara
    for (gx, gy, rx, ry) in [(2, 12, 130, 36), (12, 3, 140, 40), (10, 10, 170, 50)]:
        c = iso.v(gx, gy)
        out.append(f'<ellipse cx="{f(c[0])}" cy="{f(c[1])}" rx="{rx}" ry="{ry}" fill="#8ed27c" opacity="0.7"/>')
    far = 40
    # ruas nas duas bordas de trás, calçadas entre a rua e a cafeteria
    out.append(iso.rect(-5.2, -far, -2.4, far, "#6f7278"))             # rua da esquerda
    out.append(iso.rect(-far, -5.2, far, -2.4, "#6f7278"))             # rua da direita
    out.append(iso.rect(-2.4, -far, -0.25, N + 3, "#d4cfc4"))          # calçada esquerda
    out.append(iso.rect(-far, -2.4, N + 3, -0.25, "#d4cfc4"))          # calçada direita
    out.append(iso.rect(-5.2, -5.2, -2.4, -2.4, "#6f7278"))            # cruzamento
    # juntas da calçada
    for i in range(-12, N + 3):
        a, b = iso.v(-2.4, i), iso.v(-0.25, i)
        out.append(f'<line x1="{f(a[0])}" y1="{f(a[1])}" x2="{f(b[0])}" y2="{f(b[1])}" stroke="#b9b3a7" stroke-width="1"/>')
        a, b = iso.v(i, -2.4), iso.v(i, -0.25)
        out.append(f'<line x1="{f(a[0])}" y1="{f(a[1])}" x2="{f(b[0])}" y2="{f(b[1])}" stroke="#b9b3a7" stroke-width="1"/>')
    # meio-fio
    for (p, q) in [(iso.v(-2.4, -far), iso.v(-2.4, far)), (iso.v(-far, -2.4), iso.v(far, -2.4))]:
        out.append(f'<line x1="{f(p[0])}" y1="{f(p[1])}" x2="{f(q[0])}" y2="{f(q[1])}" stroke="#9c978d" stroke-width="3"/>')
    # faixas tracejadas
    for i in range(-far, far):
        if i in (-5, -4, -3):
            continue
        a, b = iso.v(-3.8, i + 0.15), iso.v(-3.8, i + 0.6)
        out.append(f'<line x1="{f(a[0])}" y1="{f(a[1])}" x2="{f(b[0])}" y2="{f(b[1])}" stroke="#f6f1e4" stroke-width="3" stroke-linecap="round"/>')
        a, b = iso.v(i + 0.15, -3.8), iso.v(i + 0.6, -3.8)
        out.append(f'<line x1="{f(a[0])}" y1="{f(a[1])}" x2="{f(b[0])}" y2="{f(b[1])}" stroke="#f6f1e4" stroke-width="3" stroke-linecap="round"/>')
    # faixa de pedestres no cruzamento
    for k in range(5):
        y0 = -5.0 + k * 0.55
        out.append(iso.rect(-2.3, y0, -1.2, y0 + 0.3, "#f6f1e4"))
    # caminho de entrada (porta na borda da direita)
    out.append(iso.rect(N, 3.7, N + 4, 5.3, "#e6dccb", INK, 1.2))
    return "".join(out)


def floor(iso):
    out = []
    a, b = "#f4e6c8", "#c7473d"  # xadrez creme e terracota
    for y in range(N):
        for x in range(N):
            c = a if (x + y) % 2 == 0 else b
            out.append(iso.tile(x, y, c))
    # tapete central com borda
    out.append(iso.rect(4.15, 3.15, 7.85, 6.85, "#f4c542", INK, 1.4))
    out.append(iso.rect(4.4, 3.4, 7.6, 6.6, "#e8813a", None))
    out.append(iso.rect(4.7, 3.7, 7.3, 6.3, "#f6d58a", None))
    # tapete da porta
    out.append(iso.rect(N - 1, 3.8, N - 0.1, 5.2, "#6b3f26", INK, 1.2))
    # borda do piso
    out.append(poly([iso.v(0, 0), iso.v(N, 0), iso.v(N, N), iso.v(0, N)], "none", INK, 2.2))
    return "".join(out)


def back_walls(iso, hgt=118):
    out = []
    up = (0, -hgt)

    def p(base, t_up):
        return (base[0], base[1] - hgt * t_up)

    # parede da esquerda: coluna x = 0, de (0,N) até (0,0)
    L0, L1 = iso.v(0, N), iso.v(0, 0)
    R0, R1 = iso.v(0, 0), iso.v(N, 0)
    for (a, b, dark) in [(L0, L1, 0.1), (R0, R1, 0.0)]:
        wall = "#f7ecd4"
        out.append(poly([a, b, p(b, 1), p(a, 1)], shade(wall, -dark)))
        # listras do papel de parede
        steps = 18
        for i in range(steps):
            if i % 2:
                continue
            t0, t1 = i / steps, (i + 1) / steps
            q0 = (a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0)
            q1 = (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1)
            out.append(poly([p(q0, 0.38), p(q1, 0.38), p(q1, 1), p(q0, 1)], shade("#f0dfbd", -dark), None))
        # lambri de madeira embaixo
        out.append(poly([a, b, p(b, 0.36), p(a, 0.36)], shade("#8a5534", -dark)))
        out.append(poly([p(a, 0.34), p(b, 0.34), p(b, 0.4), p(a, 0.4)], shade("#6b3f26", -dark)))
        # arremate no topo
        out.append(poly([p(a, 1), p(b, 1), p(b, 1.06), p(a, 1.06)], shade("#6b3f26", -dark)))
    return "".join(out)


def window(iso, side, t0, t1, hgt=118, lo=0.46, hi=0.9, curtain="#c7355a"):
    """Janela com cortinas numa das paredes do fundo (side 'L' ou 'R')."""
    if side == "L":
        a, b = iso.v(0, N * (1 - t0)), iso.v(0, N * (1 - t1))
    else:
        a, b = iso.v(N * t0, 0), iso.v(N * t1, 0)

    def P(q, t):
        return (q[0], q[1] - hgt * t)

    def lerp(t):
        return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
    out = [poly([P(a, lo), P(b, lo), P(b, hi), P(a, hi)], "#a8764d")]
    ia, ib = lerp(0.12), lerp(0.88)
    out.append(poly([P(ia, lo + 0.04), P(ib, lo + 0.04), P(ib, hi - 0.04), P(ia, hi - 0.04)], "#8fd0f0"))
    # brilho no vidro
    ma, mb = lerp(0.3), lerp(0.45)
    out.append(poly([P(ma, lo + 0.08), P(mb, lo + 0.08), P(lerp(0.3), hi - 0.08), P(lerp(0.15), hi - 0.08)], "#d6f1ff", None))
    mid = lerp(0.5)
    out.append(f'<line x1="{f(mid[0])}" y1="{f(mid[1]-hgt*(lo+0.04))}" x2="{f(mid[0])}" y2="{f(mid[1]-hgt*(hi-0.04))}" stroke="#a8764d" stroke-width="3"/>')
    # cortinas
    for (s0, s1) in [(0.0, 0.22), (0.78, 1.0)]:
        c0, c1 = lerp(s0), lerp(s1)
        out.append(poly([P(c0, lo - 0.02), P(c1, lo + 0.06), P(c1, hi + 0.02), P(c0, hi + 0.02)], curtain))
    # sanefa
    out.append(poly([P(a, hi), P(b, hi), P(b, hi + 0.08), P(a, hi + 0.08)], shade(curtain, -0.2)))
    return "".join(out)


def frame(iso, side, t, hgt=118, color="#f4c542", art="#5fc3a4"):
    if side == "L":
        a, b = iso.v(0, N * (1 - t)), iso.v(0, N * (1 - t - 0.07))
    else:
        a, b = iso.v(N * t, 0), iso.v(N * (t + 0.07), 0)

    def P(q, s):
        return (q[0], q[1] - hgt * s)
    return (poly([P(a, 0.55), P(b, 0.55), P(b, 0.82), P(a, 0.82)], color)
            + poly([P(a, 0.59), P(b, 0.59), P(b, 0.78), P(a, 0.78)], art, None))


def front_walls(iso):
    """Mureta baixa nas bordas da frente, com vão na porta (borda da direita, linhas 4)."""
    out = []
    hgt = 16
    t = 0.18
    # borda de baixo à esquerda: linha y = N
    out.append(iso.box(0, N - t, N, t, hgt, "#f7ecd4", "#e3c9a0", "#cdb088", sw=1.4))
    # borda de baixo à direita: coluna x = N, com vão da porta de y=3.8 a 5.2
    out.append(iso.box(N - t, 0, t, 3.8, hgt, "#f7ecd4", "#e3c9a0", "#cdb088", sw=1.4))
    out.append(iso.box(N - t, 5.2, t, N - 5.2 - t, hgt, "#f7ecd4", "#e3c9a0", "#cdb088", sw=1.4))
    return "".join(out)


# --- Móveis ---------------------------------------------------------------------------

def stove(iso, x, y, pot=None):
    out = [iso.box(x + 0.06, y + 0.06, 0.88, 0.88, 34, "#c9cfd6", "#a9b0b8", "#8e959d")]
    for (dx, dy) in [(0.3, 0.3), (0.7, 0.3), (0.3, 0.7), (0.7, 0.7)]:
        c = iso.center(x + dx - 0.5, y + dy - 0.5, 34)
        out.append(f'<ellipse cx="{f(c[0])}" cy="{f(c[1])}" rx="7" ry="3.6" fill="#3b3f45" stroke="{INK}" stroke-width="1"/>')
    # porta do forno
    fc = iso.v(x + 0.5, y + 0.94, 16)
    out.append(f'<rect x="{f(fc[0]-3)}" y="{f(fc[1]-8)}" width="16" height="10" rx="2" fill="#5d646c" stroke="{INK}" stroke-width="1.2" transform="skewY(26.6)" transform-origin="{f(fc[0])} {f(fc[1])}"/>')
    if pot:
        c = iso.center(x, y, 34)
        out.append(f'<path d="M{f(c[0]-11)},{f(c[1]-12)} h22 v10 q0,6 -11,6 q-11,0 -11,-6 z" fill="{pot}" stroke="{INK}" stroke-width="1.5"/>')
        out.append(f'<ellipse cx="{f(c[0])}" cy="{f(c[1]-12)}" rx="11" ry="3.5" fill="{shade(pot, -0.2)}" stroke="{INK}" stroke-width="1.3"/>')
        out.append(f'<path d="M{f(c[0]-4)},{f(c[1]-17)} q-3,-5 0,-9 M{f(c[0]+4)},{f(c[1]-17)} q-3,-5 0,-9" fill="none" stroke="#ffffff" stroke-width="2" opacity="0.85"/>')
    return "".join(out)


def counter(iso, x, y, dishes):
    out = [iso.box(x + 0.04, y + 0.08, 0.92, 0.84, 30, "#fffaf0", "#eadfca", "#d4c6ad")]
    top = iso.center(x, y, 30)
    offs = [(-12, 2), (10, -3), (0, 6)]
    for i, k in enumerate(dishes):
        dx, dy = offs[i]
        out.append(plate(top[0] + dx, top[1] + dy - 3, k, 0.8))
    return "".join(out)


def table(iso, x, y, cloth="#e2503f"):
    """Mesa redonda com toalha (saia e tampo)."""
    top = iso.center(x, y, 24)
    base = iso.center(x, y, 0)
    rx, ry = iso.w * 0.36, iso.h * 0.36
    out = [f'<ellipse cx="{f(base[0])}" cy="{f(base[1])}" rx="{f(rx*0.9)}" ry="{f(ry*0.9)}" fill="#000" opacity="0.15"/>']
    out.append(f'<path d="M{f(top[0]-rx)},{f(top[1])} L{f(base[0]-rx*0.92)},{f(base[1]-3)} Q{f(base[0])},{f(base[1]+ry*1.3)} {f(base[0]+rx*0.92)},{f(base[1]-3)} L{f(top[0]+rx)},{f(top[1])} z" fill="{shade(cloth, -0.18)}" stroke="{INK}" stroke-width="1.5" stroke-linejoin="round"/>')
    out.append(f'<ellipse cx="{f(top[0])}" cy="{f(top[1])}" rx="{f(rx)}" ry="{f(ry)}" fill="{cloth}" stroke="{INK}" stroke-width="1.6"/>')
    out.append(f'<ellipse cx="{f(top[0])}" cy="{f(top[1])}" rx="{f(rx*0.62)}" ry="{f(ry*0.62)}" fill="#ffffff" opacity="0.28"/>')
    return "".join(out)


def chair(iso, x, y, side="L", color="#6b3f26", seat="#c7355a"):
    out = [iso.box(x + 0.3, y + 0.3, 0.4, 0.4, 12, seat, shade(seat, -0.15), shade(seat, -0.3))]
    if side == "L":   # encosto do lado de trás-esquerdo
        out.append(iso.box(x + 0.3, y + 0.3, 0.4, 0.08, 30, color))
    else:
        out.append(iso.box(x + 0.3, y + 0.3, 0.08, 0.4, 30, color))
    return "".join(out)


def plant(iso, x, y, big=False):
    c = iso.center(x, y)
    h = 44 if big else 30
    out = [iso.box(x + 0.32, y + 0.32, 0.36, 0.36, 16, "#d98e3f")]
    for (dx, dy, r, col) in [(-7, -h + 12, 10, "#4f9a44"), (7, -h + 10, 10, "#5da84e"), (0, -h, 12, "#6cc25a"), (-2, -h + 4, 7, "#8ed27c")]:
        out.append(f'<circle cx="{f(c[0]+dx)}" cy="{f(c[1]+dy)}" r="{r}" fill="{col}" stroke="{INK}" stroke-width="1.4"/>')
    return "".join(out)


def jukebox(iso, x, y):
    out = [iso.box(x + 0.12, y + 0.2, 0.76, 0.6, 58, "#f4c542", "#e2503f", "#c7355a")]
    c = iso.v(x + 0.5, y + 0.8, 40)
    out.append(f'<circle cx="{f(c[0]+4)}" cy="{f(c[1]-4)}" r="9" fill="#8fd0f0" stroke="{INK}" stroke-width="1.4"/>')
    out.append(f'<circle cx="{f(c[0]+4)}" cy="{f(c[1]-4)}" r="3" fill="#ffffff"/>')
    return "".join(out)


def pastry_case(iso, x, y):
    out = [iso.box(x + 0.06, y + 0.1, 0.88, 0.8, 26, "#a8643a")]
    out.append(iso.box(x + 0.1, y + 0.14, 0.8, 0.72, 22, "#d6f1ff", "#b8e2f5", "#a2d3ea", z=26, sw=1.3))
    c = iso.center(x, y, 32)
    out.append(food("bolo", c[0] - 8, c[1], 0.7) + food("pao", c[0] + 10, c[1] - 2, 0.6))
    return "".join(out)


def lamp_post(x, y):
    return (f'<g><rect x="{x-3}" y="{y-70}" width="6" height="70" rx="2" fill="#3b4a55" stroke="{INK}" stroke-width="1.3"/>'
            f'<path d="M{x-11},{y-70} h22 l-5,-14 h-12 z" fill="#3b4a55" stroke="{INK}" stroke-width="1.3"/>'
            f'<rect x="{x-6}" y="{y-82}" width="12" height="10" rx="2" fill="#fff0b8" stroke="{INK}" stroke-width="1.2"/>'
            f'<ellipse cx="{x}" cy="{y}" rx="9" ry="3.5" fill="#000" opacity="0.2"/></g>')


def tree(x, y, s=1.0):
    return (f'<g transform="translate({x},{y}) scale({s})"><ellipse cx="0" cy="0" rx="26" ry="9" fill="#000" opacity="0.18"/>'
            f'<rect x="-6" y="-38" width="12" height="38" rx="3" fill="#8a5534" stroke="{INK}" stroke-width="1.5"/>'
            f'<circle cx="-18" cy="-52" r="22" fill="#4f9a44" stroke="{INK}" stroke-width="1.6"/>'
            f'<circle cx="18" cy="-54" r="22" fill="#5da84e" stroke="{INK}" stroke-width="1.6"/>'
            f'<circle cx="0" cy="-74" r="26" fill="#6cc25a" stroke="{INK}" stroke-width="1.6"/>'
            f'<circle cx="-8" cy="-80" r="8" fill="#8ed27c"/></g>')


def flower_bed(x, y):
    out = [f'<ellipse cx="{x}" cy="{y}" rx="46" ry="16" fill="#8a5534" stroke="{INK}" stroke-width="1.5"/>']
    for i, (dx, dy, c) in enumerate([(-28, -4, "#e2503f"), (-12, -8, "#f4c542"), (6, -6, "#c7355a"), (22, -3, "#fff4df"), (-18, 4, "#f4c542"), (12, 4, "#e2503f")]):
        out.append(f'<circle cx="{x+dx}" cy="{y+dy}" r="6" fill="{c}" stroke="{INK}" stroke-width="1.2"/><circle cx="{x+dx}" cy="{y+dy}" r="2" fill="#f4c542"/>')
    return "".join(out)


def sign_board(iso):
    """Placa pendurada na parede da direita com o nome da cafeteria (original)."""
    a = iso.v(3.35, 0)
    x, y = a[0], a[1] - 96
    return (f'<g transform="translate({f(x)},{f(y)}) skewY(26.57)">'
            f'<rect x="-2" y="0" width="132" height="34" rx="8" fill="#3b2316" stroke="#a8643a" stroke-width="3"/>'
            f'<text x="64" y="23" text-anchor="middle" font-family="Fredoka, Nunito, sans-serif" font-weight="600" font-size="16" fill="#fff4df">Café da Esquina</text></g>')


def float_text(x, y, text, color, size):
    base = f'x="{f(x)}" y="{f(y)}" font-family="Fredoka, Nunito, sans-serif" font-weight="700" font-size="{size}" text-anchor="middle"'
    return (f'<text {base} fill="none" stroke="#3b2316" stroke-width="5" stroke-linejoin="round">{text}</text>'
            f'<text {base} fill="{color}">{text}</text>')


def scene_svg(width=1280, height=720, ox=640, oy=208, scale=1.18, crowd=True):
    iso = Iso(0, 0, 72, 36)
    items = []  # (chave de profundidade, svg)

    def add(key, svg):
        items.append((key, svg))

    # cozinha junto à parede da esquerda
    add(0.5, pastry_case(iso, 0, 0))
    add(1.5, pastry_case(iso, 0, 1))
    pots = ["#e2503f", None, "#f4c542", "#5fc3a4"]
    for i, y in enumerate(range(2, 6)):
        add(y + 0.5, stove(iso, 0, y, pots[i]))
    dishes = [["cafe", "cafe", "pao"], ["pao", "pao"], ["bolo", "misto"], ["coxinha", "coxinha", "lasanha"]]
    for i, y in enumerate(range(2, 6)):
        add(y + 1.5, counter(iso, 1, y, dishes[i]))
    add(7.2, plant(iso, 0, 7, big=True))
    # fundo, parede da direita
    add(2.4, jukebox(iso, 2, 0))
    add(5.2, plant(iso, 5, 0))
    add(8.2, plant(iso, 8, 0, big=True))
    add(1.8, plant(iso, 1, 0))

    # mesas com cadeiras
    tables = [(4, 1, "#e2503f"), (7, 1, "#5fc3a4"), (4, 3.9, "#e2503f"), (7, 3.9, "#5fc3a4"),
              (4, 6.9, "#5fc3a4"), (7, 6.9, "#e2503f")]
    seated = []
    for (tx, ty, cloth) in tables:
        ty = round(ty)
        add(tx + ty + 0.5, table(iso, tx, ty, cloth))
        add(tx - 1 + ty + 0.4, chair(iso, tx - 1, ty, "R"))
        add(tx + 1 + ty + 0.4, chair(iso, tx + 1, ty, "R"))
        seated.append((tx - 1, ty))
        seated.append((tx + 1, ty))

    people = [
        # (cell, skin, hair color, style, shirt, extras)
        ((3, 1), 0, "#3b2316", "curto", "#5fc3a4", {"face": "feliz", "want": "cafe"}),
        ((5, 1), 2, "#1f1a17", "cacheado", "#f4c542", {"face": "feliz", "mood": "feliz"}),
        ((6, 1), 1, "#d98e3f", "longo", "#c7355a", {"face": "neutro", "want": "bolo"}),
        ((8, 1), 3, "#1f1a17", "coque", "#8fd0f0", {"face": "feliz"}),
        ((3, 4), 4, "#f4c542", "espetado", "#e2503f", {"face": "feliz", "mood": "feliz"}),
        ((5, 4), 0, "#6b3f26", "longo", "#5da84e", {"face": "neutro", "want": "pao"}),
        ((6, 4), 3, "#3b2316", "bone", "#3d5a80", {"face": "bravo", "mood": "bravo"}),
        ((8, 4), 1, "#a8643a", "curto", "#f4c542", {"face": "feliz", "want": "coxinha"}),
        ((3, 7), 2, "#1f1a17", "coque", "#c7355a", {"face": "feliz"}),
        ((5, 7), 4, "#d98e3f", "cacheado", "#5fc3a4", {"face": "neutro", "mood": "esperando"}),
        ((6, 7), 0, "#3b2316", "espetado", "#8fd0f0", {"face": "feliz", "want": "lasanha"}),
    ] if crowd else []
    for (cell, sk, hc, hs, shirt, ex) in people:
        c = iso.center(cell[0], cell[1], 12)
        svg = person(c[0], c[1] + 4, SKINS[sk], hc, hs, shirt, "#3d5a80", sitting=True, face=ex.get("face", "feliz"), scale=0.95)
        if "want" in ex:
            svg += thought(c[0] + 18, c[1] - 78, ex["want"])
        if "mood" in ex:
            svg += mood(c[0] + 16, c[1] - 66, ex["mood"])
        add(cell[0] + cell[1] + 0.6, svg)
    # pratos servidos nas mesas
    for (tx, ty, _) in tables[::2]:
        c = iso.center(tx, round(ty), 24)
        add(tx + round(ty) + 0.55, plate(c[0] - 6, c[1] - 2, "misto", 0.8) + plate(c[0] + 8, c[1] + 2, "cafe", 0.7))

    if crowd:
        # garçom levando pedido, chef na cozinha, clientes chegando
        c = iso.center(2.6, 3.4)
        add(6.1, person(c[0], c[1], SKINS[1], "#1f1a17", "curto", "#fffaf0", "#2b2b33", bowtie=True, tray="bolo"))
        c = iso.center(2.2, 6.4)
        add(8.7, person(c[0], c[1], SKINS[3], "#1f1a17", "cacheado", "#fffaf0", "#3b4a55", apron="#5fc3a4", chef_hat=True))
        c = iso.center(8.2, 4.5)
        add(12.8, person(c[0], c[1], SKINS[0], "#e8813a", "longo", "#f4c542", "#6b3f26", face="feliz"))
        c = iso.center(9.3, 4.3)
        add(13.6, person(c[0], c[1], SKINS[2], "#3b2316", "bone", "#e2503f", "#3d5a80", face="feliz"))
        c = iso.center(10.6, 4.6)
        add(15.2, person(c[0], c[1], SKINS[4], "#6b3f26", "coque", "#5fc3a4", "#3d5a80", face="neutro"))

    items.sort(key=lambda it: it[0])
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
             f'<rect x="0" y="0" width="{width}" height="{height}" fill="#7cc36b"/>',
             f'<g transform="translate({ox},{oy}) scale({scale})">',
             ground(iso, width, height)]
    for (x, y) in [(-1.3, 11.5), (11.5, -1.3), (-1.3, -1.3)]:
        a = iso.v(x, y)
        parts.append(lamp_post(a[0], a[1]))
    parts.append(back_walls(iso))
    for (s, t0, t1) in [("L", 0.06, 0.24), ("L", 0.56, 0.74), ("R", 0.08, 0.24), ("R", 0.76, 0.92)]:
        parts.append(window(iso, s, t0, t1))
    parts.append(frame(iso, "L", 0.36) + frame(iso, "L", 0.46, color="#a8643a", art="#e2503f") + frame(iso, "R", 0.64, art="#f4c542"))
    parts.append(sign_board(iso))
    parts.append(floor(iso))
    parts.extend(svg for _, svg in items)
    parts.append(front_walls(iso))
    # jardim da frente
    t1, t2, f1, f2 = iso.v(1.5, 12.2), iso.v(12.8, 2.2), iso.v(4.5, 11.2), iso.v(11.6, 7.8)
    parts.append(tree(t1[0], t1[1], 0.9) + tree(t2[0], t2[1], 0.85) + flower_bed(f1[0], f1[1]) + flower_bed(f2[0], f2[1]))
    # feedback flutuante
    c = iso.center(4.2, 4.6, 118)
    parts.append(float_text(c[0], c[1], "+18", "#f4c542", 20))
    c = iso.center(1.2, 2.2, 104)
    parts.append(float_text(c[0], c[1], "+8 XP", "#8fd0f0", 17))
    parts.append("</g></svg>")
    return "".join(parts)


if __name__ == "__main__":
    import sys
    open(sys.argv[1], "w").write(scene_svg())
