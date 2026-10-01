"""Pisos, paredes, enfeites de parede e peças do exterior da v3, no formato do jogo.

O canvas desenha o salão inteiro de uma vez. O jogo monta piso e parede piso a piso, porque o
jogador troca o revestimento e a cafeteria cresce. Aqui cada peça cobre uma célula, nas mesmas
cores e traços das pranchas (escala do canvas: piso de 84x42, parede de 100 de altura).
Os revestimentos são os do jogo (res://data/surfaces), redesenhados no estilo v3.
"""
from core3 import *
from scene3 import _window, _frame, _shelf, _clock, lawn, asphalt, lamp_post, flower_bed

TW, TH = 84, 42
WALL_H = 100
BLEED = 0.025  # o fundo de cada peça passa um pouco da borda, para não abrir fresta entre vizinhas


# --- Pisos -------------------------------------------------------------------------------

def _quad(iso, x0, y0, x1, y1):
    return [iso.v(x0, y0), iso.v(x1, y0), iso.v(x1, y1), iso.v(x0, y1)]


def _base(iso, color):
    """Losango da célula um pouco maior que ela (sangria), na cor do rejunte."""
    b = BLEED
    return P(_quad(iso, -b, -b, 1 + b, 1 + b), color, None)


def _gloss(D, iso, strength=0.16):
    """Brilho suave do canto de cima, como no xadrez da cozinha do canvas."""
    return P(_quad(iso, 0, 0, 1, 1), D.lin([(0, "#ffffff", strength), (0.5, "#ffffff", 0.0), (1, "#ffffff", strength * 0.4)],
                                           0, 0, 1, 1), None)


def floor_checker(D, iso, light, dark, grout, which):
    """Xadrez uma cor por piso: 'a' (claro) ou 'b' (escuro), alternados pelo jogo."""
    color = light if which == "a" else dark
    o = [_base(iso, grout)]
    inset = 0.018
    o.append(P(_quad(iso, inset, inset, 1 - inset, 1 - inset), D.lin([(0, tint(color, 0.18)), (1, shade(color, 0.04))], 0, 0, 1, 1),
               shade(grout, 0.05), 0.5))
    o.append(_gloss(D, iso, 0.14))
    return "".join(o)


def floor_small_checker(D, iso, light, dark, grout):
    """Xadrez miúdo: quatro quadradinhos por piso (o padrão continua de um piso para o outro)."""
    o = [_base(iso, grout)]
    for yy in range(2):
        for xx in range(2):
            c = dark if (xx + yy) % 2 == 0 else light
            o.append(P(_quad(iso, xx / 2, yy / 2, (xx + 1) / 2, (yy + 1) / 2), c, "#00000022", 0.4))
    o.append(_gloss(D, iso, 0.18))
    return "".join(o)


def floor_planks(D, iso, seed):
    """Tábuas cor de mel correndo ao longo do eixo x, quatro fileiras por piso, como o salão do canvas."""
    r = Rng(seed)
    woods = ["#f6c98a", "#f0bc78", "#f9d49c", "#ecb46c", "#f4c483"]
    o = [_base(iso, "#c98d4a")]
    for j in range(4):
        y0, y1 = j / 4, (j + 1) / 4
        x = -r.u(0, 0.9)
        while x < 1:
            ln = r.u(0.7, 1.4)
            a, b = max(0.0, x), min(1.0, x + ln)
            if b - a > 0.02:
                c = woods[int(r.u(0, len(woods)))]
                o.append(P(_quad(iso, a, y0, b, y1), c, "#c98d4a", 0.5))
                gx0, gx1 = a + (b - a) * r.u(0.1, 0.3), a + (b - a) * r.u(0.6, 0.9)
                gy = y0 + (y1 - y0) * r.u(0.3, 0.7)
                p0, p1 = iso.v(gx0, gy), iso.v(gx1, gy)
                o.append(line(p0[0], p0[1], p1[0], p1[1], "#d99a55", 0.7, 'opacity="0.55"'))
            x += ln
    return "".join(o)


def floor_azulejo(D, iso):
    """Azulejo azul e branco: quatro peças por piso, cada uma com uma florzinha no meio."""
    o = [_base(iso, "#ffffff")]
    for yy in range(2):
        for xx in range(2):
            x0, y0 = xx / 2 + 0.02, yy / 2 + 0.02
            x1, y1 = (xx + 1) / 2 - 0.02, (yy + 1) / 2 - 0.02
            o.append(P(_quad(iso, x0, y0, x1, y1), D.lin([(0, "#bfe6ff"), (1, "#7fc4ec")], 0, 0, 1, 1), "#4d9bd0", 0.5))
            cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
            for (dx, dy) in ((0.09, 0), (-0.09, 0), (0, 0.09), (0, -0.09)):
                px, py = iso.v(cx + dx, cy + dy)
                o.append(E(px, py, 3.2, 1.7, "#2f7fc4", None, extra='opacity="0.8"'))
            px, py = iso.v(cx, cy)
            o.append(E(px, py, 2.2, 1.2, "#ffffff", None))
    o.append(_gloss(D, iso, 0.2))
    return "".join(o)


def floor_marble(D, iso, seed):
    """Mármore claro, uma placa por piso, com veios cinza diferentes em cada variação."""
    r = Rng(seed)
    o = [_base(iso, "#c9c4bc")]
    inset = 0.015
    o.append(P(_quad(iso, inset, inset, 1 - inset, 1 - inset), D.lin([(0, "#fbfaf7"), (0.6, "#efede8"), (1, "#e2dfd8")], 0, 0, 1, 1),
               "#bdb8b0", 0.5))
    for _ in range(3):
        u0, v0 = r.u(0.05, 0.4), r.u(0.05, 0.95)
        pts_ = [iso.v(u0, v0)]
        u, v = u0, v0
        for _ in range(4):
            u += r.u(0.12, 0.22)
            v += r.u(-0.18, 0.18)
            pts_.append(iso.v(min(u, 0.97), min(max(v, 0.03), 0.97)))
        d = f"M{f(pts_[0][0])},{f(pts_[0][1])} " + " ".join(f"L{f(p[0])},{f(p[1])}" for p in pts_[1:])
        o.append(path(d, "none", "#a8a39b", r.u(0.5, 1.0), 'opacity="0.55"'))
    o.append(_gloss(D, iso, 0.22))
    return "".join(o)


def entrance_mat(D, iso):
    """Tapete listrado vermelho e branco da porta (o do canvas), em cima do piso da entrada."""
    o = [P(_quad(iso, 0.08, 0.1, 0.92, 0.9), "#ff4d5e", INK3, 1.0)]
    for i in range(1, 4):
        xx = 0.08 + i * 0.21
        o.append(P(_quad(iso, xx - 0.05, 0.1, xx + 0.03, 0.9), "#ffffff", None, 'opacity="0.85"'))
    return "".join(o)


# id do revestimento -> (variações, desenho). O jogo escolhe a variação: "a"/"b" pelo xadrez, ou pelo piso.
FLOORS = {
    "floor_beige": ("xadrez", lambda D, iso, v: floor_checker(D, iso, "#fbe8c4", "#f1d29c", "#d9b77e", v)),
    "floor_bistro": (1, lambda D, iso, v: floor_small_checker(D, iso, "#fbf3e4", "#8f2a37", "#5a1a22")),
    "floor_blue_tiles": (1, lambda D, iso, v: floor_azulejo(D, iso)),
    "floor_marble": (3, lambda D, iso, v: floor_marble(D, iso, 40 + v)),
    "floor_wood": (4, lambda D, iso, v: floor_planks(D, iso, 17 + v * 13)),
}


# --- Paredes -----------------------------------------------------------------------------
# Cada painel cobre uma célula de parede: u de 0 a L (para a direita), v de -WALL_H a 0 (para cima).

L = TW / 2


def _wainscot(color, dark_k, rail, base):
    """Lambri com frisos, rodameio e rodapé (comum a quase todas as paredes)."""
    o = [f'<rect x="{-BLEED * L}" y="-36" width="{f(L * (1 + 2 * BLEED))}" height="36" fill="{shade(color, dark_k + 0.02)}"/>']
    o.append(f'<rect x="4" y="-30" width="{f(L - 8)}" height="22" rx="2" fill="none" stroke="{shade("#d8e2ee", dark_k)}" stroke-width="1.4"/>')
    o.append(f'<rect x="{-BLEED * L}" y="-39" width="{f(L * (1 + 2 * BLEED))}" height="5.5" fill="{shade(rail, dark_k)}"/>')
    o.append(f'<line x1="{-BLEED * L}" y1="-39" x2="{f(L * (1 + BLEED))}" y2="-39" stroke="{INK3}" stroke-width="0.7"/>')
    o.append(f'<line x1="{-BLEED * L}" y1="-33.5" x2="{f(L * (1 + BLEED))}" y2="-33.5" stroke="{INK3}" stroke-width="0.7"/>')
    o.append(f'<rect x="{-BLEED * L}" y="-5" width="{f(L * (1 + 2 * BLEED))}" height="5" fill="{shade(base, dark_k)}"/>')
    return "".join(o)


def _top_band(dark_k):
    return (f'<rect x="{-BLEED * L}" y="{-WALL_H}" width="{f(L * (1 + 2 * BLEED))}" height="6" fill="{shade("#ffffff", dark_k)}"/>'
            f'<line x1="{-BLEED * L}" y1="{-WALL_H + 6}" x2="{f(L * (1 + BLEED))}" y2="{-WALL_H + 6}" stroke="{INK3}" stroke-width="0.7"/>')


def _upper(D, color, dark_k, top_shadow=True):
    o = [f'<rect x="{-BLEED * L}" y="{-WALL_H}" width="{f(L * (1 + 2 * BLEED))}" height="{WALL_H}" '
         f'fill="{D.lin([(0, shade(color, dark_k)), (1, shade(color, dark_k + 0.05))])}"/>']
    if top_shadow:
        o.append(f'<rect x="{-BLEED * L}" y="{-WALL_H + 6}" width="{f(L * (1 + 2 * BLEED))}" height="14" '
                 f'fill="{D.lin([(0, "#1a3a4a", 0.12), (1, "#1a3a4a", 0)])}"/>')
    return "".join(o)


def wall_mint(D, dark_k):
    """O papel de parede aprovado: listras menta, lambri branco e rodameio coral."""
    o = [_upper(D, "#bff3e1", dark_k, top_shadow=False)]
    for x in (4, 25):
        o.append(f'<rect x="{x}" y="{-WALL_H + 6}" width="9" height="{WALL_H - 6 - 36}" fill="{shade("#e3fbf2", dark_k)}"/>')
        o.append(f'<rect x="{x + 12}" y="{-WALL_H + 6}" width="1.4" height="{WALL_H - 6 - 36}" fill="#ffffff" opacity="0.8"/>')
    o.append(_wainscot("#ffffff", dark_k, "#ff6b6b", "#e04b55"))
    o.append(_top_band(dark_k))
    o.append(f'<rect x="{-BLEED * L}" y="{-WALL_H + 6}" width="{f(L * (1 + 2 * BLEED))}" height="14" '
             f'fill="{D.lin([(0, "#1a3a4a", 0.12), (1, "#1a3a4a", 0)])}"/>')
    return "".join(o)


def wall_cream(D, dark_k):
    """Creme com lambri branco e rodameio de madeira."""
    o = [_upper(D, "#fff1d2", dark_k)]
    for x in (10.5, 31.5):
        o.append(f'<circle cx="{x}" cy="-70" r="1.6" fill="{shade("#f3d9a6", dark_k)}"/>')
        o.append(f'<circle cx="{x - 10.5}" cy="-52" r="1.6" fill="{shade("#f3d9a6", dark_k)}"/>')
    o.append(_wainscot("#ffffff", dark_k, "#c98a52", "#9e6a3e"))
    o.append(_top_band(dark_k))
    return "".join(o)


def wall_brick(D, dark_k):
    """Tijolinho aparente vermelho com rejunte claro, faixa branca no alto e rodapé escuro."""
    o = [f'<rect x="{-BLEED * L}" y="{-WALL_H}" width="{f(L * (1 + 2 * BLEED))}" height="{WALL_H}" fill="{shade("#f3e3d6", dark_k)}"/>']
    r = Rng(5)
    row_h = 9.0
    row = 0
    y = -5.0
    while y > -WALL_H + 6:
        y0 = max(y - row_h, -WALL_H + 6)
        off = 0.0 if row % 2 == 0 else -L / 4
        x = off
        while x < L:
            a, b = max(x + 0.8, -BLEED * L), min(x + L / 2 - 0.8, L * (1 + BLEED))
            if b > a:
                c = mix("#e0674a", "#c8513a", r.r())
                o.append(f'<rect x="{f(a)}" y="{f(y0 + 0.8)}" width="{f(b - a)}" height="{f(y - y0 - 1.6)}" rx="1.2" '
                         f'fill="{shade(c, dark_k)}"/>')
                o.append(f'<rect x="{f(a + 1)}" y="{f(y0 + 1.6)}" width="{f(max(b - a - 2, 0))}" height="1.6" rx="0.8" fill="#ffffff" opacity="0.22"/>')
            x += L / 2
        y = y0
        row += 1
    o.append(f'<rect x="{-BLEED * L}" y="-5" width="{f(L * (1 + 2 * BLEED))}" height="5" fill="{shade("#6b3a2c", dark_k)}"/>')
    o.append(_top_band(dark_k))
    return "".join(o)


def wall_navy(D, dark_k):
    """Azul-marinho com frisos verticais, rodameio dourado e lambri branco."""
    o = [_upper(D, "#2f4170", dark_k)]
    for x in (10.5, 31.5):
        o.append(f'<rect x="{x - 0.6}" y="{-WALL_H + 6}" width="1.2" height="{WALL_H - 6 - 36}" fill="#ffffff" opacity="0.12"/>')
    o.append(_wainscot("#ffffff", dark_k, "#e8b84a", "#2a3556"))
    o.append(_top_band(dark_k))
    return "".join(o)


WALLS = {"wall_cream": wall_cream, "wall_mint_stripes": wall_mint, "wall_brick": wall_brick, "wall_navy": wall_navy}
# A parede da esquerda recebe menos luz (como no canvas).
LEFT_DARK = 0.07


def wall_window(D, curtain):
    return _window(D, 9, 33, curtain=curtain)


def wall_frame_cupcake(D):
    return _frame(D, 6, 44, 30, 36, "cupcake", "#ff4d8d")


def wall_frame_landscape(D):
    return _frame(D, 3, 46, 36, 30, "paisagem", "#4d8dff")


def wall_clock(D):
    return _clock(D, L / 2, 74)


def wall_shelf(D):
    return _shelf(D, 3, 58, L - 6, [("pote", "#ff4d5e"), ("xicara", "#ffffff"), ("planta", "#ffd23f")])


# enfeite -> desenho (o mesmo para as duas paredes; a da esquerda escurece um pouco)
DECORATIONS = {
    "janela": lambda D, side: wall_window(D, "#ffd23f" if side == "R" else "#ff4d8d"),
    "quadro_cupcake": lambda D, side: wall_frame_cupcake(D),
    "quadro_paisagem": lambda D, side: wall_frame_landscape(D),
    "relogio": lambda D, side: wall_clock(D),
    "prateleira": lambda D, side: wall_shelf(D),
}


def wall_piece(side, flat):
    """Leva o desenho plano de uma célula para a parede da direita ('R', ao longo de x, desce para a
    direita) ou da esquerda ('L', ao longo de y, sobe para a direita), como o plane() do canvas.
    A âncora (0, 0) é a ponta de baixo à esquerda na tela."""
    return g(flat, f"matrix(1,{0.5 if side == 'R' else -0.5},0,1,0,0)")


# --- Exterior ----------------------------------------------------------------------------

def lawn_tile(D, size):
    """Quadrado de grama que emenda com ele mesmo (os tufos que passam da borda reaparecem do outro lado)."""
    r = Rng(31)
    o = [f'<rect x="0" y="0" width="{size}" height="{size}" fill="#78d64a"/>']
    for _ in range(int(14 * size * size / (60 * 44)) + 1):
        x, y = r.u(0, size), r.u(0, size)
        c = "#5cc23a" if r.r() > 0.45 else "#a6ee78"
        for dx in (-size, 0, size):
            for dy in (-size, 0, size):
                px, py = x + dx, y + dy
                o.append(f'<path d="M{f(px)},{f(py)} l-1.6,-4.2 M{f(px)},{f(py)} l1,-4.8 M{f(px)},{f(py)} l3,-3.6" '
                         f'stroke="{c}" stroke-width="1.2" stroke-linecap="round" fill="none"/>')
    return f'<svg x="0" y="0" width="{size}" height="{size}" overflow="hidden">{"".join(o)}</svg>'


def asphalt_tile(D, size):
    r = Rng(21)
    o = [f'<rect x="0" y="0" width="{size}" height="{size}" fill="#7a818e"/>']
    for _ in range(int(16 * size * size / 900) + 1):
        x, y, rr = r.u(0, size), r.u(0, size), r.u(0.4, 1.0)
        c = "#8c93a0" if r.r() > 0.5 else "#6a717d"
        for dx in (-size, 0, size):
            for dy in (-size, 0, size):
                o.append(f'<circle cx="{f(x + dx)}" cy="{f(y + dy)}" r="{f(rr)}" fill="{c}"/>')
    return f'<svg x="0" y="0" width="{size}" height="{size}" overflow="hidden">{"".join(o)}</svg>'
