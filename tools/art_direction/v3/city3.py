"""Cidade em volta do café (DT-048): prédios de Nova York, enfeites de calçada e carros, no traço v3.

Tudo desenhado na célula (0, 0) com o piso de 96 (como os móveis): o prédio de pegada (w, d) tem a âncora
no vértice da frente (w, d); enfeites e carros têm a âncora no ponto do chão em (0, 0). Nada de marca
de verdade: placas genéricas ("DELI", "PIZZA", "TAXI").
"""
import math

from furniture3 import *  # noqa: F401,F403

IRON = "#2b2d36"
FLOOR_H = 46.0      # altura de um andar (unidades do desenho)
GROUND_H = 58.0     # o térreo é mais alto (loja, porta)
WINDOW = "#9fd2f2"
WINDOW_LIT = "#ffe7a3"
# Noite em Nova York (DT-080): a camada "_luz" de cada prédio tem só as janelas acesas, que o jogo mostra à noite.
# De dia, 18% das janelas aparecem acesas; à noite, as mesmas e mais algumas (o mesmo sorteio, outro limite).
DAY_LIT = 0.18
NIGHT_LIT = 0.5
GLOW = "#ffbf5e"
GLOW_CORE = "#fff0c2"
SHOP_GLOW = "#ffd58a"


def _q(iso, face, w, d, z, h, u0, u1, v0, v1):
    return iso.quad(face, 0, 0, w, d, z, h, u0, u1, v0, v1)


def _brick_lines(iso, w, d, z0, z1, color, step=7.0):
    """Linhas de argamassa nas duas faces de frente."""
    o = []
    z = z0 + step
    while z < z1 - 1:
        a, b, c = iso.v(0, d, z), iso.v(w, d, z), iso.v(w, 0, z)
        o.append(f'<polyline points="{pts([a, b, c])}" fill="none" stroke="{color}" stroke-width="0.6" opacity="0.28"/>')
        z += step
    return "".join(o)


def _window(D, iso, face, w, d, z, h, u0, u1, v0, v1, frame="#ffffff", lit=False, arch=False):
    q = _q(iso, face, w, d, z, h, u0, u1, v0, v1)
    glass = D.lin([(0, "#ffffff"), (0.25, WINDOW_LIT if lit else WINDOW), (1, shade(WINDOW_LIT if lit else WINDOW, 0.25))],
                  0, 0, 1, 1)
    o = [P(q, glass, INK3, 0.8)]
    if arch:
        top = [q[3], q[2]]
        mid = ((top[0][0] + top[1][0]) / 2, (top[0][1] + top[1][1]) / 2 - abs(top[1][0] - top[0][0]) * 0.35)
        o.append(path(f"M{f(top[0][0])},{f(top[0][1])} Q{f(mid[0])},{f(mid[1])} {f(top[1][0])},{f(top[1][1])} Z", glass, INK3, 0.8))
    # caixilho do meio e a soleira clara embaixo
    m0 = ((q[0][0] + q[1][0]) / 2, (q[0][1] + q[1][1]) / 2)
    m1 = ((q[3][0] + q[2][0]) / 2, (q[3][1] + q[2][1]) / 2)
    o.append(line(m0[0], m0[1], m1[0], m1[1], frame, 1.2))
    o.append(line(q[0][0] - 1, q[0][1] + 1, q[1][0] + 1, q[1][1] + 1, frame, 1.8))
    return "".join(o)


def _windows(D, iso, w, d, z0, floors, floor_h, cols_l, cols_r, frame, lit_seed=3, arch=False, wide=0.56, night=False):
    """Janelas das duas faces. [param night]: só o brilho das janelas acesas à noite (a camada "_luz")."""
    r = Rng(lit_seed)
    o = []
    for face, cols in (("L", cols_l), ("R", cols_r)):
        for fl in range(floors):
            for c in range(cols):
                u0 = (c + (1 - wide) / 2) / cols
                u1 = (c + (1 + wide) / 2) / cols
                chance = r.r()
                if night:
                    if chance < NIGHT_LIT:
                        o.append(_glow_quad(D, iso, face, w, d, z0 + fl * floor_h, floor_h, u0, u1, 0.22, 0.82))
                else:
                    o.append(_window(D, iso, face, w, d, z0 + fl * floor_h, floor_h, u0, u1, 0.22, 0.82, frame,
                                     chance < DAY_LIT, arch))
    return "".join(o)


def _glow_quad(D, iso, face, w, d, z, h, u0, u1, v0, v1, color=GLOW, x0=0.0, y0=0.0):
    """Janela acesa à noite: clara no meio, laranja quente nas bordas."""
    q = iso.quad(face, x0, y0, w, d, z, h, u0, u1, v0, v1)
    return P(q, D.lin([(0, GLOW_CORE), (1, color)], 0, 0, 0, 1), None, 0)


def _night_layer(D, glows):
    """As janelas acesas com um halo desfocado em volta (a luz "vaza" da janela)."""
    halo = D.raw("brilho_janela", '<filter id="brilho_janela" x="-60%" y="-60%" width="220%" height="220%">'
                 '<feGaussianBlur stdDeviation="2.6"/></filter>')
    return f'<g filter="{halo}" opacity="0.9">{glows}</g>{glows}'


def _cornice(D, iso, w, d, z, color, h=7.0):
    return box3(D, iso, -0.06, -0.06, w + 0.12, d + 0.12, h, color, z=z, sw=0.9)


def _water_tower(D, iso, x, y, z):
    o = []
    for (lx, ly) in [(x - 0.22, y - 0.22), (x + 0.22, y - 0.22), (x - 0.22, y + 0.22), (x + 0.22, y + 0.22)]:
        o.append(cyl3(D, iso, lx, ly, 0.025, z, z + 16, "#6b4a35", cap=False, sw=0.6))
    o.append(cyl3(D, iso, x, y, 0.3, z + 16, z + 44, "#9a6a45", top="#7a5236", sw=0.9))
    for zz in (z + 22, z + 30, z + 38):
        sx, sy, rx, ry = iso.ell(x, y, zz, 0.3)
        o.append(path(f"M{f(sx - rx)},{f(sy)} A{f(rx)},{f(ry)} 0 0 0 {f(sx + rx)},{f(sy)}", "none", IRON, 0.9))
    sx, sy, rx, ry = iso.ell(x, y, z + 44, 0.3)
    o.append(path(f"M{f(sx - rx - 2)},{f(sy)} L{f(sx)},{f(sy - 18)} L{f(sx + rx + 2)},{f(sy)} Z",
                  D.lin([(0, "#8a6a52"), (1, "#5a3f2e")], 0, 0, 1, 0), INK3, 0.9))
    return "".join(o)


def _fire_escape(D, iso, w, d, z0, floors, floor_h):
    """Escada de incêndio de ferro na face da esquerda (plano y = d), com patamar em cada andar."""
    o = []
    u0, u1 = 0.2, 0.62
    out = 0.16
    for fl in range(floors):
        z = z0 + fl * floor_h
        a, b = iso.v(w * u0, d, z), iso.v(w * u1, d, z)
        c, e = iso.v(w * u1, d + out, z), iso.v(w * u0, d + out, z)
        o.append(P([a, b, c, e], IRON, INK3, 0.6))
        for zz in (z + 6, z + 12):
            p0, p1 = iso.v(w * u0, d + out, zz), iso.v(w * u1, d + out, zz)
            o.append(line(p0[0], p0[1], p1[0], p1[1], IRON, 1.0))
        for i in range(6):
            t = u0 + (u1 - u0) * i / 5
            p0, p1 = iso.v(w * t, d + out, z), iso.v(w * t, d + out, z + 12)
            o.append(line(p0[0], p0[1], p1[0], p1[1], IRON, 0.7))
        if fl + 1 < floors:  # escada até o próximo patamar
            s0 = iso.v(w * (u0 + 0.04), d + out * 0.5, z)
            s1 = iso.v(w * (u1 - 0.04), d + out * 0.5, z + floor_h)
            o.append(line(s0[0], s0[1], s1[0], s1[1], IRON, 2.2))
    return "".join(o)


def _awning(D, iso, w, d, u0, u1, z, color, depth=0.32, drop=14.0):
    """Toldo listrado na face da esquerda (plano y = d), de u0 a u1."""
    a, b = iso.v(w * u0, d, z), iso.v(w * u1, d, z)
    c, e = iso.v(w * u1, d + depth, z - drop), iso.v(w * u0, d + depth, z - drop)
    o = [P([a, b, c, e], color, INK3, 0.9)]
    n = 7
    for i in range(0, n, 2):
        t0, t1 = u0 + (u1 - u0) * i / n, u0 + (u1 - u0) * (i + 1) / n
        o.append(P([iso.v(w * t0, d, z), iso.v(w * t1, d, z), iso.v(w * t1, d + depth, z - drop), iso.v(w * t0, d + depth, z - drop)],
                   "#ffffff", None, 0, 'opacity="0.85"'))
    f0, f1 = iso.v(w * u0, d + depth, z - drop), iso.v(w * u1, d + depth, z - drop)
    o.append(P([f0, f1, (f1[0], f1[1] + 5), (f0[0], f0[1] + 5)], shade(color, 0.15), INK3, 0.8))
    return "".join(o)


def _sign(iso, w, d, u, z, text, color):
    """Placa da loja na face da esquerda: o texto segue a inclinação da face."""
    p = iso.v(w * u, d, z)
    width = 9.0 * len(text) + 12
    return (f'<g transform="translate({f(p[0])},{f(p[1])}) matrix(1,0.5,0,1,0,0)">'
            f'<rect x="{f(-width / 2)}" y="-11" width="{f(width)}" height="15" rx="3" fill="{color}" stroke="{INK3}" stroke-width="0.9"/>'
            f'<text x="0" y="0" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-weight="bold" '
            f'font-size="11" fill="#ffffff">{text}</text></g>')


def _door(D, iso, w, d, u, z=0.0, color="#3b2a2a", width=0.16, h=34.0):
    q = iso.quad("L", 0, 0, w, d, z, h, u - width / 2, u + width / 2, 0, 1)
    return P(q, D.lin([(0, tint(color, 0.2)), (1, shade(color, 0.25))], 0, 0, 1, 1), INK3, 0.9)


def _stoop(D, iso, w, d, u, color="#b9a68e"):
    """Escadinha de entrada das casas de pedra (brownstone), saindo da face da esquerda."""
    o = []
    x0 = w * (u - 0.1)
    for i in range(4):
        o.append(box3(D, iso, x0, d + 0.05 * (3 - i), w * 0.2, 0.05 * (i + 1), 4.0, color, z=4.0 * (3 - i), sw=0.7, bevel=False))
    return "".join(o)


def building(D, iso, w, d, style):
    """Prédio de pegada (w, d) na célula (0, 0). style: floors, color, trim, frame e extras."""
    floors = style["floors"]
    color, trim, frame = style["color"], style.get("trim", "#efe6d6"), style.get("frame", "#ffffff")
    top = GROUND_H + floors * FLOOR_H
    o = [soft_shadow(D, iso, w / 2, d / 2, max(w, d) * 0.6, opacity=0.25)]
    o.append(box3(D, iso, 0, 0, w, d, top, color, sw=1.1, bevel=False))
    if style.get("brick"):
        o.append(_brick_lines(iso, w, d, 0, top, shade(color, 0.45)))
    # térreo: faixa de pedra, loja ou casa
    o.append(box3(D, iso, -0.02, -0.02, w + 0.04, d + 0.04, 6, trim, z=GROUND_H - 6, sw=0.8, faces="LR", bevel=False))
    shop = style.get("shop")
    if shop:
        text, awning = shop
        q = iso.quad("L", 0, 0, w, d, 0, GROUND_H - 8, 0.08, 0.92, 0.0, 0.78)
        o.append(P(q, D.lin([(0, "#cfe8f7"), (1, "#6fa6c9")], 0, 0, 1, 1), INK3, 0.9))
        o.append(_door(D, iso, w, d, 0.82, h=36.0, color="#2a3b4a"))
        o.append(_awning(D, iso, w, d, 0.06, 0.94, GROUND_H - 6, awning))
        q = iso.quad("R", 0, 0, w, d, 0, GROUND_H - 8, 0.15, 0.85, 0.0, 0.78)
        o.append(P(q, D.lin([(0, "#bfe0f2"), (1, "#5f94b8")], 0, 0, 1, 1), INK3, 0.9))
    else:
        o.append(_windows(D, iso, w, d, 4, 1, GROUND_H - 10, max(1, round(w * 1.2)), max(1, round(d * 1.2)), frame, 11))
        if style.get("stoop"):
            o.append(_stoop(D, iso, w, d, 0.5))
            o.append(_door(D, iso, w, d, 0.5, z=16.0, color=style.get("door", "#5a2f22"), h=30.0))
        else:
            o.append(_door(D, iso, w, d, 0.5, color=style.get("door", "#5a2f22")))
    o.append(_windows(D, iso, w, d, GROUND_H, floors, FLOOR_H, max(1, round(w * 1.5)), max(1, round(d * 1.5)), frame,
                      style.get("seed", 5), style.get("arch", False)))
    for fl in range(1, floors):  # frisos entre os andares
        z = GROUND_H + fl * FLOOR_H
        a, b, c = iso.v(0, d, z), iso.v(w, d, z), iso.v(w, 0, z)
        o.append(f'<polyline points="{pts([a, b, c])}" fill="none" stroke="{trim}" stroke-width="2" opacity="0.8"/>')
    if shop:  # a placa por cima das janelas do térreo
        o.append(_sign(iso, w, d, 0.42, GROUND_H - 22, shop[0], shade(shop[1], 0.2)))
    if style.get("fire_escape"):
        o.append(_fire_escape(D, iso, w, d, GROUND_H, floors, FLOOR_H))
    o.append(_cornice(D, iso, w, d, top, trim))
    if style.get("water_tower"):
        o.append(_water_tower(D, iso, w * 0.35, d * 0.35, top + 7))
    return "".join(o)


def building_lights(D, iso, w, d, style):
    """Camada "_luz" do prédio (DT-080): as vitrines da loja e as janelas acesas à noite, nos mesmos lugares."""
    floors = style["floors"]
    o = []
    if style.get("shop"):
        o.append(_glow_quad(D, iso, "L", w, d, 0, GROUND_H - 8, 0.08, 0.92, 0.05, 0.75, SHOP_GLOW))
        o.append(_glow_quad(D, iso, "R", w, d, 0, GROUND_H - 8, 0.15, 0.85, 0.05, 0.75, SHOP_GLOW))
    else:
        o.append(_windows(D, iso, w, d, 4, 1, GROUND_H - 10, max(1, round(w * 1.2)), max(1, round(d * 1.2)), "", 11,
                          night=True))
    o.append(_windows(D, iso, w, d, GROUND_H, floors, FLOOR_H, max(1, round(w * 1.5)), max(1, round(d * 1.5)), "",
                      style.get("seed", 5), night=True))
    return _night_layer(D, "".join(o))


def glass_tower_lights(D, iso, w, d, floors=10):
    """Escritórios acesos na torre de vidro: faixas de andar, umas acesas e outras não."""
    fh = 30.0
    r = Rng(41)
    o = []
    for face, cols in (("L", round(w * 3)), ("R", round(d * 3))):
        for fl in range(floors):
            for c in range(cols):
                if r.r() < 0.42:
                    o.append(_glow_quad(D, iso, face, w, d, fl * fh, fh, (c + 0.08) / cols, (c + 0.92) / cols, 0.15, 0.85,
                                        "#ffd98f"))
    return _night_layer(D, "".join(o))


def deco_tower_lights(D, iso, w, d):
    """Janelas acesas da torre art déco, em cada degrau."""
    r = Rng(43)
    o = []
    z = 0.0
    for inset, floors in [(0.0, 7), (0.15, 3), (0.28, 2)]:
        x0, y0 = w * inset, d * inset
        ww, dd = w * (1 - 2 * inset), d * (1 - 2 * inset)
        h = floors * FLOOR_H
        for face, cols in (("L", max(2, round(ww * 2))), ("R", max(2, round(dd * 2)))):
            for c in range(cols):
                for fl in range(floors):
                    if r.r() < NIGHT_LIT:
                        o.append(_glow_quad(D, iso, face, ww, dd, z + 6 + fl * (h - 10) / floors, (h - 10) / floors,
                                            (c + 0.3) / cols, (c + 0.7) / cols, 0.12, 0.88, x0=x0, y0=y0))
        z += h
    return _night_layer(D, "".join(o))


def glass_tower(D, iso, w, d, floors=10, color="#5aa7d8"):
    """Torre moderna de vidro, com um recuo no alto."""
    fh = 30.0
    body = floors * fh
    o = [soft_shadow(D, iso, w / 2, d / 2, max(w, d) * 0.6, opacity=0.25)]
    o.append(box3(D, iso, 0, 0, w, d, body, color, sw=1.1, bevel=False, top="#cfe6f5"))
    for face, cols in (("L", round(w * 3)), ("R", round(d * 3))):
        for c in range(1, cols):
            q = iso.quad(face, 0, 0, w, d, 0, body, c / cols, c / cols, 0, 1)
            o.append(line(q[0][0], q[0][1], q[3][0], q[3][1], "#e8f4fb", 1.0, 'opacity="0.7"'))
        for fl in range(1, floors):
            q = iso.quad(face, 0, 0, w, d, fl * fh, 0, 0, 1, 0, 0)
            o.append(line(q[0][0], q[0][1], q[1][0], q[1][1], "#2f6f9c", 0.8, 'opacity="0.6"'))
        q = iso.quad(face, 0, 0, w, d, 0, body, 0.08, 0.4, 0.15, 0.95)
        o.append(P(q, "#ffffff", None, 0, 'opacity="0.18"'))
    o.append(box3(D, iso, w * 0.2, d * 0.2, w * 0.6, d * 0.6, 26, shade(color, 0.1), z=body, sw=1.0, bevel=False, top="#d9edf8"))
    o.append(cyl3(D, iso, w * 0.5, d * 0.5, 0.02, body + 26, body + 60, "#d0d6de", cap=False, sw=0.6))
    return "".join(o)


def deco_tower(D, iso, w, d, color="#e7d8b8"):
    """Torre art déco de pedra clara, em degraus, com a ponta fina."""
    o = [soft_shadow(D, iso, w / 2, d / 2, max(w, d) * 0.6, opacity=0.25)]
    z = 0.0
    steps = [(0.0, 7), (0.15, 3), (0.28, 2)]
    for inset, floors in steps:
        x0, y0 = w * inset, d * inset
        ww, dd = w * (1 - 2 * inset), d * (1 - 2 * inset)
        h = floors * FLOOR_H
        o.append(box3(D, iso, x0, y0, ww, dd, h, color, z=z, sw=1.0, bevel=False))
        for face, cols in (("L", max(2, round(ww * 2))), ("R", max(2, round(dd * 2)))):
            for c in range(cols):
                q = iso.quad(face, x0, y0, ww, dd, z + 6, h - 10, (c + 0.3) / cols, (c + 0.7) / cols, 0, 1)
                o.append(P(q, D.lin([(0, "#cfe4f2"), (1, "#7fa3bd")], 0, 0, 0, 1), INK3, 0.6))
        z += h
    o.append(cyl3(D, iso, w * 0.5, d * 0.5, 0.06, z, z + 30, "#d8c58f", sw=0.8))
    sx, sy = iso.v(w * 0.5, d * 0.5, z + 30)
    o.append(path(f"M{f(sx - 4)},{f(sy)} L{f(sx)},{f(sy - 40)} L{f(sx + 4)},{f(sy)} Z", "#e9dcae", INK3, 0.8))
    return "".join(o)


def building_height(style):
    """Altura do topo do prédio (com a caixa-d'água), para o retângulo da figura."""
    return GROUND_H + style["floors"] * FLOOR_H + 7 + (62 if style.get("water_tower") else 0)


GLASS_FLOORS = 10
GLASS_HEIGHT = GLASS_FLOORS * 30.0 + 26 + 34
DECO_HEIGHT = 12 * FLOOR_H + 70


def _styled(w, d, style):
    return ((w, d), building_height(style), lambda D, iso: building(D, iso, w, d, style),
            lambda D, iso: building_lights(D, iso, w, d, style))


# Prédios da cidade: id -> (pegada em células, altura, desenho, camada das janelas acesas à noite).
BUILDINGS = {
    "predio_brownstone": _styled(3, 2, dict(floors=3, color="#9a5b45", trim="#d9c3a5", stoop=True, arch=True, seed=4,
                                            door="#4a2a1f")),
    "predio_tijolo": _styled(3, 3, dict(floors=5, color="#b5513d", trim="#e8dccb", brick=True, fire_escape=True,
                                        water_tower=True, seed=7)),
    "predio_deli": _styled(2, 2, dict(floors=3, color="#d8c7a4", trim="#ffffff", shop=("DELI", "#2f9e62"), seed=9)),
    "predio_pizza": _styled(2, 3, dict(floors=4, color="#7f8fa6", trim="#f1ece2", shop=("PIZZA", "#e8483c"),
                                       fire_escape=True, seed=13)),
    "predio_azul": _styled(3, 2, dict(floors=4, color="#4a6fa5", trim="#f4efe6", brick=True, water_tower=True, seed=17)),
    "predio_vidro": ((3, 3), GLASS_HEIGHT, lambda D, iso: glass_tower(D, iso, 3, 3, GLASS_FLOORS),
                     lambda D, iso: glass_tower_lights(D, iso, 3, 3, GLASS_FLOORS)),
    "predio_deco": ((3, 3), DECO_HEIGHT, lambda D, iso: deco_tower(D, iso, 3, 3), lambda D, iso: deco_tower_lights(D, iso, 3, 3)),
}


def concrete_tile(D, size):
    """Textura de repetir do chão de concreto da cidade: cinza claro com pintinhas."""
    r = Rng(33)
    o = [f'<rect x="0" y="0" width="{f(size)}" height="{f(size)}" fill="#cfd4db"/>']  # concreto frio (DT-080)
    for _ in range(int(14 * size * size / 900) + 1):
        x, y, rr = r.u(0, size), r.u(0, size), r.u(0.3, 0.9)
        c = "#dfe3e8" if r.r() > 0.5 else "#b8bfc9"
        for dx in (-size, 0, size):
            for dy in (-size, 0, size):
                o.append(f'<circle cx="{f(x + dx)}" cy="{f(y + dy)}" r="{f(rr)}" fill="{c}"/>')
    return f'<svg x="0" y="0" width="{f(size)}" height="{f(size)}" overflow="hidden">{"".join(o)}</svg>'


# --- Enfeites da calçada (âncora no chão, em (0, 0)) ------------------------------------------

# Lanterna do poste (o ponto que acende à noite, DT-080), em unidades do desenho a partir do pé.
LAMP_HEAD = (22.0, -118.0)


def nyc_lamp(D, iso):
    """Poste de ferro com braço curvo e lanterna."""
    o = [E(0, 0, 10, 4, "#1a1a2a", None, extra='opacity="0.22"')]
    o.append(cyl3(D, iso, 0, 0, 0.07, 0, 8, "#28463a", sw=0.8))
    o.append(cyl3(D, iso, 0, 0, 0.03, 8, 112, "#2f5444", cap=False, sw=0.8))
    o.append(path("M0,-110 C0,-124 10,-130 22,-126", "none", "#2f5444", 3.2))
    o.append(path("M0,-110 C0,-124 10,-130 22,-126", "none", INK3, 0.7))
    o.append(C(22, -112, 22, D.rad([(0, "#fff7c2", 0.55), (1, "#fff7c2", 0)]), None))
    o.append(path("M15,-124 h14 l-3,12 h-8 Z", D.lin([(0, "#fffbe0"), (1, "#ffd966")]), INK3, 1.0))
    o.append(path("M14,-126 h16 l-8,-6 Z", "#2f5444", INK3, 0.8))
    return "".join(o)


def hydrant(D, iso):
    o = [E(0, 0, 8, 3, "#1a1a2a", None, extra='opacity="0.22"')]
    o.append(cyl3(D, iso, 0, 0, 0.1, 0, 3, "#b92a2a", sw=0.8))
    o.append(cyl3(D, iso, 0, 0, 0.065, 3, 18, "#e23b3b", sw=0.8))
    o.append(E(0, -18, 6.4, 3.2, "#c73030", INK3, 0.8))
    o.append(path("M-4,-18 Q0,-26 4,-18 Z", "#e23b3b", INK3, 0.8))
    o.append(f'<rect x="-9" y="-13" width="18" height="4" rx="2" fill="#c73030" stroke="{INK3}" stroke-width="0.7"/>')
    o.append(C(-9, -11, 2.2, "#ffd23f", INK3, 0.6) + C(9, -11, 2.2, "#ffd23f", INK3, 0.6))
    return "".join(o)


def street_tree(D, iso):
    """Árvore no canteiro quadrado da calçada, com grade baixa."""
    o = [P([iso.v(-0.3, -0.3), iso.v(0.3, -0.3), iso.v(0.3, 0.3), iso.v(-0.3, 0.3)], "#6b4f36", INK3, 0.8)]
    for (a, b) in [((-0.3, 0.3), (0.3, 0.3)), ((0.3, 0.3), (0.3, -0.3))]:
        p0, p1 = iso.v(*a, 7), iso.v(*b, 7)
        o.append(line(p0[0], p0[1], p1[0], p1[1], IRON, 1.4))
        for t in (0.0, 0.25, 0.5, 0.75, 1.0):
            x, y = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
            q0, q1 = iso.v(x, y), iso.v(x, y, 7)
            o.append(line(q0[0], q0[1], q1[0], q1[1], IRON, 1.0))
    o.append(path("M-3,0 L-2.4,-40 L2.4,-40 L3,0 Z", D.lin([(0, "#8a6244"), (1, "#5c3f2b")], 0, 0, 1, 0), INK3, 0.9))
    leaves = D.rad([(0, "#b7f08a"), (0.55, "#5cc24a"), (1, "#2e8a3c")], 0.35, 0.3, 0.8)
    for (cx, cy, r) in [(-14, -54, 16), (14, -56, 16), (0, -70, 19), (-8, -46, 13), (9, -45, 13)]:
        o.append(C(cx, cy, r, leaves, "#1f6a2a", 1.0))
    return "".join(o)


def bench(D, iso):
    o = [soft_shadow(D, iso, 0, 0, 0.45, 0.2, opacity=0.25)]
    for x in (-0.35, 0.35):
        o.append(box3(D, iso, x - 0.03, -0.12, 0.06, 0.24, 10, IRON, sw=0.6, bevel=False))
    for i in range(3):
        o.append(box3(D, iso, -0.42, -0.12 + i * 0.085, 0.84, 0.07, 2.2, "#b8763f", z=10, sw=0.6, bevel=False))
    for i in range(2):
        o.append(box3(D, iso, -0.42, -0.14, 0.84, 0.03, 4, "#a8682f", z=16 + i * 6, sw=0.6, bevel=False, faces="LRT"))
    return "".join(o)


def hotdog_cart(D, iso):
    o = [soft_shadow(D, iso, 0, 0, 0.5, 0.3, opacity=0.25)]
    o.append(box3(D, iso, -0.4, -0.22, 0.8, 0.44, 22, "#d6dde6", z=6, sw=0.9, gloss=True))
    for (x, y) in [(-0.28, 0.22), (0.28, 0.22)]:
        sx, sy = iso.v(x, y, 6)
        o.append(E(sx, sy, 5.5, 5.5, IRON, INK3, 0.8) + C(sx, sy, 2, "#c9d3de", None))
    q = iso.quad("L", -0.4, -0.22, 0.8, 0.44, 8, 14, 0.12, 0.88, 0.1, 0.9)
    o.append(P(q, "#e8483c", INK3, 0.7))
    o.append(cyl3(D, iso, 0, 0, 0.018, 28, 66, "#c9d3de", cap=False, sw=0.5))
    sx, sy = iso.v(0, 0, 66)
    for i in range(8):
        a0, a1 = math.radians(i * 45), math.radians(i * 45 + 45)
        c = "#2f7de1" if i % 2 == 0 else "#ffd23f"
        p0 = (sx + math.cos(a0) * 34, sy + math.sin(a0) * 14 + 8)
        p1 = (sx + math.cos(a1) * 34, sy + math.sin(a1) * 14 + 8)
        o.append(P([(sx, sy - 6), p0, p1], c, INK3, 0.7))
    return "".join(o)


def trash_bin(D, iso):
    o = [E(0, 0, 9, 3.5, "#1a1a2a", None, extra='opacity="0.22"')]
    o.append(cyl3(D, iso, 0, 0, 0.12, 0, 24, "#2f6b4a", sw=0.9))
    for z in (6, 12, 18):
        sx, sy, rx, ry = iso.ell(0, 0, z, 0.12)
        o.append(path(f"M{f(sx - rx)},{f(sy)} A{f(rx)},{f(ry)} 0 0 0 {f(sx + rx)},{f(sy)}", "none", "#1d4a32", 0.9))
    return "".join(o)


def mailbox(D, iso):
    o = [E(0, 0, 9, 3.5, "#1a1a2a", None, extra='opacity="0.22"')]
    for (x, y) in [(-0.1, -0.08), (0.1, -0.08), (-0.1, 0.08), (0.1, 0.08)]:
        o.append(cyl3(D, iso, x, y, 0.015, 0, 8, IRON, cap=False, sw=0.5))
    o.append(box3(D, iso, -0.13, -0.11, 0.26, 0.22, 22, "#2f5fbf", z=8, sw=0.9, gloss=True))
    q = iso.quad("L", -0.13, -0.11, 0.26, 0.22, 8, 22, 0.2, 0.8, 0.62, 0.72)
    o.append(P(q, "#1d3f86", INK3, 0.6))
    return "".join(o)


def planter(D, iso):
    o = [box3(D, iso, -0.32, -0.18, 0.64, 0.36, 12, "#c8c3b8", sw=0.9)]
    leaves = D.rad([(0, "#a8f07a"), (0.6, "#4fc23f"), (1, "#2a8a32")], 0.35, 0.3, 0.75)
    for (x, y, r) in [(-0.18, 0.0, 9), (0.0, -0.05, 10), (0.18, 0.0, 9)]:
        sx, sy = iso.v(x, y, 16)
        o.append(C(sx, sy, r, leaves, "#1f6a2a", 0.9))
    for (x, y, c) in [(-0.2, 0.03, "#ff4d8d"), (0.05, -0.02, "#ffd23f"), (0.2, 0.04, "#ffffff")]:
        sx, sy = iso.v(x, y, 22)
        o.append(C(sx, sy, 2.4, c, INK3, 0.5))
    return "".join(o)


def manhole(D, iso):
    o = [P([iso.v(-0.22, -0.22), iso.v(0.22, -0.22), iso.v(0.22, 0.22), iso.v(-0.22, 0.22)], "none", None, 0)]
    sx, sy, rx, ry = iso.ell(0, 0, 0, 0.2)
    o.append(E(sx, sy, rx, ry, "#4a4f5a", INK3, 0.8))
    o.append(E(sx, sy, rx * 0.7, ry * 0.7, "none", "#6a707c", 0.8))
    o.append(line(sx - rx * 0.7, sy, sx + rx * 0.7, sy, "#6a707c", 0.8))
    return "".join(o)


def traffic_light(D, iso, state):
    """Semáforo: poste e a caixa com as 3 luzes; acesa a do estado ('verde', 'amarelo' ou 'vermelho')."""
    o = [E(0, 0, 8, 3, "#1a1a2a", None, extra='opacity="0.22"')]
    o.append(cyl3(D, iso, 0, 0, 0.035, 0, 96, "#3a3f4a", cap=False, sw=0.7))
    o.append(f'<rect x="-8" y="-136" width="16" height="42" rx="4" fill="#2b2d36" stroke="{INK3}" stroke-width="1"/>')
    colors = {"vermelho": "#ff3b3b", "amarelo": "#ffc21f", "verde": "#33d26b"}
    for i, name in enumerate(("vermelho", "amarelo", "verde")):
        cy = -128 + i * 13
        on = name == state
        if on:
            o.append(C(0, cy, 10, D.rad([(0, colors[name], 0.6), (1, colors[name], 0)]), None))
        o.append(C(0, cy, 4.6, colors[name] if on else shade(colors[name], 0.65), INK3, 0.7))
    return "".join(o)


PROPS = {
    "rua_poste": (nyc_lamp, (-30.0, -160.0, 84.0, 170.0)),
    "rua_hidrante": (hydrant, (-14.0, -32.0, 28.0, 38.0)),
    "rua_arvore": (street_tree, (-40.0, -96.0, 80.0, 116.0)),
    "rua_banco": (bench, (-60.0, -50.0, 120.0, 84.0)),
    "rua_carrinho": (hotdog_cart, (-50.0, -90.0, 100.0, 110.0)),
    "rua_lixeira": (trash_bin, (-14.0, -36.0, 28.0, 42.0)),
    "rua_correio": (mailbox, (-18.0, -46.0, 36.0, 54.0)),
    "rua_vaso": (planter, (-36.0, -36.0, 72.0, 56.0)),
    "rua_bueiro": (manhole, (-24.0, -14.0, 48.0, 28.0)),
}
for _state in ("verde", "amarelo", "vermelho"):
    PROPS[f"rua_semaforo_{_state}"] = ((lambda s: lambda D, iso: traffic_light(D, iso, s))(_state), (-16.0, -150.0, 32.0, 156.0))


# --- Carros (âncora no meio do carro, no chão) ----------------------------------------------

CAR_LENGTH = 1.05
CAR_WIDTH = 0.5


def car(D, iso, direction, body="#ffcc1f", taxi=True):
    """Carro andando para direction ('+x', '-x', '+y', '-y'). Na tela aparecem as faces +x e +y:
    andando para + vemos a frente (faróis), para - a traseira (lanternas)."""
    along_x = direction in ("+x", "-x")
    w, d = (CAR_LENGTH, CAR_WIDTH) if along_x else (CAR_WIDTH, CAR_LENGTH)
    x0, y0 = -w / 2, -d / 2
    o = [soft_shadow(D, iso, 0, 0, max(w, d) * 0.6, min(w, d) * 0.7, opacity=0.3)]
    # rodas nas laterais visíveis
    side = "L" if along_x else "R"
    for u in (0.2, 0.8):
        q = iso.quad(side, x0, y0, w, d, 0, 10, u, u, 0.4, 0.4)
        o.append(E(q[0][0], q[0][1], 5.2, 5.2, IRON, INK3, 0.8) + C(q[0][0], q[0][1], 2, "#c9d3de", None))
    o.append(box3(D, iso, x0, y0, w, d, 12, body, z=4, sw=1.0, gloss=True))
    # cabine com vidros, um pouco para trás do meio
    if along_x:
        cx0, cw, cy0, cd = x0 + w * (0.22 if direction == "+x" else 0.3), w * 0.48, y0 + 0.04, d - 0.08
    else:
        cy0, cd, cx0, cw = y0 + d * (0.22 if direction == "+y" else 0.3), d * 0.48, x0 + 0.04, w - 0.08
    o.append(box3(D, iso, cx0, cy0, cw, cd, 10, "#cfe8f7", z=16, sw=0.9, top=body))
    for face in ("L", "R"):
        q = iso.quad(face, cx0, cy0, cw, cd, 16, 10, 0.08, 0.92, 0.15, 0.85)
        o.append(P(q, D.lin([(0, "#e8f6ff"), (1, "#7fb3d6")], 0, 0, 1, 1), INK3, 0.6))
    # faróis na frente ou lanternas atrás, na face que aparece
    end = "R" if along_x else "L"
    lights = "#fff6c8" if direction in ("+x", "+y") else "#ff4a4a"
    for u in (0.18, 0.82):
        q = iso.quad(end, x0, y0, w, d, 4, 12, u, u, 0.55, 0.55)
        o.append(C(q[0][0], q[0][1], 2.4, lights, INK3, 0.6))
    if taxi:
        sx, sy = iso.v(cx0 + cw / 2, cy0 + cd / 2, 26)
        o.append(f'<rect x="{f(sx - 9)}" y="{f(sy - 7)}" width="18" height="7" rx="2" fill="#fff4b0" stroke="{INK3}" stroke-width="0.7"/>')
        o.append(f'<text x="{f(sx)}" y="{f(sy - 1.6)}" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" '
                 f'font-weight="bold" font-size="5" fill="#33283a">TAXI</text>')
        # faixa quadriculada na lateral
        q = iso.quad(side, x0, y0, w, d, 4, 12, 0.1, 0.9, 0.45, 0.6)
        o.append(P(q, IRON, None, 0, 'opacity="0.75"'))
    return "".join(o)


CARS = {
    "taxi": ("#ffcc1f", True),
    "carro_vermelho": ("#e8483c", False),
    "carro_branco": ("#f2f4f7", False),
    "carro_azul": ("#3f7ad9", False),
}
CAR_BOUNDS = (-60.0, -60.0, 120.0, 96.0)
