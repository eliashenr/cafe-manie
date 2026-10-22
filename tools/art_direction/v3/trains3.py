"""Multifogão Trem (DT-060): três fogões de 1 piso (locomotiva, vagão e vagão-restaurante) que, lado a lado, formam o
conjunto; e o Relógio da Estação, o enfeite de prêmio por completar o trem. Os fogões usam o desenho do fogão comum
(as medidas não mudam, para a panela e o forno aceso caírem no lugar) com a pintura e os enfeites de cada vagão."""
from core3 import *
from furniture3 import K, stove, STOVE_INSET, STOVE_SIZE, STOVE_HEIGHT

PARTS = {
    "locomotiva": dict(enamel="#e0303a", top_color="#ffd23f", panel=("#ffe7a0", "#d9b44a", "#8a6a2e"), knob="#2a2c34",
                       door=("#ff7a6a", "#a8161f"), handle="#ffd23f"),
    "vagao": dict(enamel="#2ea36b", top_color="#ffd23f", panel=("#ffe7a0", "#d9b44a", "#8a6a2e"), knob="#2a2c34",
                  door=("#7ee0a8", "#1d7a4a"), handle="#ffd23f"),
    "restaurante": dict(enamel="#2f5fbf", top_color="#ffd23f", panel=("#ffe7a0", "#d9b44a", "#8a6a2e"), knob="#2a2c34",
                        door=("#7aa6ff", "#1d3f86"), handle="#ffd23f"),
}


def _wheels(D, iso, bx, by, front, k):
    o = []
    for u in (0.22, 0.78):
        px, py = iso.face_center(front, bx, by, STOVE_SIZE, STOVE_SIZE, 0, STOVE_HEIGHT * k, u, 0.02)
        o.append(E(px, py, 6.4 * k, 6.4 * k, "#2a2c34", INK3, 1.0) + E(px, py, 3.4 * k, 3.4 * k, "#d9b44a", INK3, 0.6)
                 + C(px, py, 1.2 * k, "#2a2c34", None))
    return "".join(o)


def train_stove(D, iso, x, y, front, part):
    k = K(iso)
    bx, by = x + STOVE_INSET, y + STOVE_INSET
    h = STOVE_HEIGHT * k
    o = [stove(D, iso, x, y, front, **PARTS[part])]
    if front is not None:
        o.append(_wheels(D, iso, bx, by, front, k))
    if part == "locomotiva":  # chaminé no canto de trás, com fumaça
        cx, cy = bx + 0.1, by + 0.1
        o.append(cyl3(D, iso, cx, cy, 0.07, h, h + 26 * k, "#2a2c34", top="#15151b"))
        o.append(cyl3(D, iso, cx, cy, 0.09, h + 20 * k, h + 24 * k, "#d9b44a", metal=True))
        sx, sy = iso.v(cx, cy, h + 26 * k)
        for dx, dy, r, op in [(0, -6, 5, 0.7), (5, -14, 6.5, 0.55), (1, -24, 8, 0.4)]:
            o.append(C(sx + dx * k, sy + dy * k, r * k, "#ffffff", None, extra=f'opacity="{op}"'))
    elif part == "restaurante":  # toldinho listrado em cima, atrás
        a = iso.v(bx, by, h + 16 * k)
        b = iso.v(bx + STOVE_SIZE, by, h + 16 * k)
        c = iso.v(bx + STOVE_SIZE, by + 0.16, h + 10 * k)
        d = iso.v(bx, by + 0.16, h + 10 * k)
        o.append(P([a, b, c, d], D.lin([(0, "#ffffff"), (0.5, "#e0303a"), (1, "#ffffff")], 0, 0, 1, 0), INK3, 0.8))
        for u in (0.02, 0.98):
            p0 = iso.v(bx + u * STOVE_SIZE, by + 0.02, h)
            o.append(line(p0[0], p0[1], p0[0], p0[1] - 13 * k, "#8f9aa7", 1.6 * k))
    else:  # vagão: faixa dourada com janelinhas no alto da traseira
        for u in (0.2, 0.5, 0.8):
            px, py = iso.v(bx + u * STOVE_SIZE, by + 0.02, h + 6 * k)
            o.append(f'<rect x="{f(px - 4 * k)}" y="{f(py - 5 * k)}" width="{f(8 * k)}" height="{f(8 * k)}" rx="{f(1.5 * k)}" '
                     f'fill="#bfe6ff" stroke="{INK3}" stroke-width="0.8"/>')
            o.append(line(px - 4 * k, py + 3 * k, px - 4 * k, py + 6 * k, "#d9b44a", 1.4 * k))
    return "".join(o)


def station_clock(D, iso, x, y):
    """Relógio da Estação: poste de ferro verde com o relógio redondo de dois mostradores e uma placa."""
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    sx, sy = iso.v(cx, cy)
    o = [soft_shadow(D, iso, cx, cy, 0.22, opacity=0.28), cyl3(D, iso, cx, cy, 0.12, 0, 6 * k, "#1d5a3a")]
    o.append(line(sx, sy - 6 * k, sx, sy - 70 * k, "#1d5a3a", 4.2 * k))
    o.append(line(sx, sy - 6 * k, sx, sy - 70 * k, "#2ea36b", 2 * k))
    o.append(path(f"M{f(sx - 16 * k)},{f(sy - 40 * k)} h{f(32 * k)} v{f(9 * k)} h{f(-32 * k)} Z", "#ffffff", INK3, 1.0))
    o.append(path(f"M{f(sx - 13 * k)},{f(sy - 35.5 * k)} h{f(26 * k)}", "none", "#2f5fbf", 2.2 * k))
    o.append(C(sx, sy - 84 * k, 15 * k, "#1d5a3a", INK3, 1.2))
    o.append(C(sx, sy - 84 * k, 12 * k, "#fffaf0", INK3, 0.9))
    for i in range(12):
        a = math.radians(i * 30)
        o.append(line(sx + math.cos(a) * 9.5 * k, sy - 84 * k + math.sin(a) * 9.5 * k,
                      sx + math.cos(a) * 11 * k, sy - 84 * k + math.sin(a) * 11 * k, INK3, 0.8))
    o.append(line(sx, sy - 84 * k, sx, sy - 92 * k, INK3, 1.6 * k) + line(sx, sy - 84 * k, sx + 5 * k, sy - 81 * k, INK3, 1.6 * k))
    o.append(C(sx, sy - 101 * k, 3 * k, "#d9b44a", INK3, 0.8))
    return "".join(o)


# id do móvel no jogo -> vagão
TRAIN = {"train_locomotive": "locomotiva", "train_wagon": "vagao", "train_dining": "restaurante"}
