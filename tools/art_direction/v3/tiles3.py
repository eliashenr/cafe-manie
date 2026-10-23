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


def _wainscot(color, dark_k, rail, base, frame="#d8e2ee"):
    """Lambri com frisos, rodameio e rodapé (comum a quase todas as paredes)."""
    o = [f'<rect x="{-BLEED * L}" y="-36" width="{f(L * (1 + 2 * BLEED))}" height="36" fill="{shade(color, dark_k + 0.02)}"/>']
    o.append(f'<rect x="4" y="-30" width="{f(L - 8)}" height="22" rx="2" fill="none" stroke="{shade(frame, dark_k)}" stroke-width="1.4"/>')
    o.append(f'<rect x="{-BLEED * L}" y="-39" width="{f(L * (1 + 2 * BLEED))}" height="5.5" fill="{shade(rail, dark_k)}"/>')
    o.append(f'<line x1="{-BLEED * L}" y1="-39" x2="{f(L * (1 + BLEED))}" y2="-39" stroke="{INK3}" stroke-width="0.7"/>')
    o.append(f'<line x1="{-BLEED * L}" y1="-33.5" x2="{f(L * (1 + BLEED))}" y2="-33.5" stroke="{INK3}" stroke-width="0.7"/>')
    o.append(f'<rect x="{-BLEED * L}" y="-5" width="{f(L * (1 + 2 * BLEED))}" height="5" fill="{shade(base, dark_k)}"/>')
    return "".join(o)


def _top_band(dark_k, color="#ffffff"):
    return (f'<rect x="{-BLEED * L}" y="{-WALL_H}" width="{f(L * (1 + 2 * BLEED))}" height="6" fill="{shade(color, dark_k)}"/>'
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


# --- Coleções da loja (estilos e culturas) ---------------------------------------------------
# Um piso e uma parede para cada coleção (res://data/collections). O que passa da borda é recortado
# na sangria; os padrões que atravessam a emenda têm o período de uma célula, então o vizinho
# desenha a continuação no mesmo lugar, sem fresta.

X0, X1 = -BLEED * L, L * (1 + BLEED)  # a parede de uma célula, com a sangria dos lados


def _clip_cell(D, iso, content):
    q = _quad(iso, -BLEED, -BLEED, 1 + BLEED, 1 + BLEED)
    d = "M" + " L".join(f"{f(x)},{f(y)}" for x, y in q) + " Z"
    return f'<g clip-path="{D.clip(d)}">{content}</g>'


def _clip_panel(D, content):
    d = f"M{f(X0)},{-WALL_H} L{f(X1)},{-WALL_H} L{f(X1)},0 L{f(X0)},0 Z"
    return f'<g clip-path="{D.clip(d)}">{content}</g>'


def _band_rect(y0, y1, fill, extra=""):
    """Faixa de parede de uma ponta à outra (com a sangria), de y0 a y1 (y cresce para baixo)."""
    return f'<rect x="{f(X0)}" y="{f(y0)}" width="{f(X1 - X0)}" height="{f(y1 - y0)}" fill="{fill}"{(" " + extra) if extra else ""}/>'


def floor_retro_circles(D, iso):
    """Anos 70: círculos concêntricos laranja e mostarda num piso marrom; os quartos de círculo dos
    cantos fecham círculos inteiros com os vizinhos."""
    o = [_base(iso, "#5a2a12")]
    inset = 0.012
    o.append(P(_quad(iso, inset, inset, 1 - inset, 1 - inset), "#8a4a24", None))
    rings = [(0.42, "#e07a2e"), (0.32, "#f2b33d"), (0.22, "#fbe3b8"), (0.12, "#b0532a")]
    art = []
    for (cx, cy, scale) in [(0.5, 0.5, 1.0), (0, 0, 0.6), (1, 0, 0.6), (1, 1, 0.6), (0, 1, 0.6)]:
        sx, sy = iso.v(cx, cy)
        for r, c in rings:
            art.append(E(sx, sy, r * scale * iso.W / SQ2, r * scale * iso.H / SQ2, c, "#5a2a12", 0.5))
    o.append(_clip_cell(D, iso, "".join(art)))
    o.append(_gloss(D, iso, 0.12))
    return "".join(o)


def floor_rustic(D, iso, seed):
    """Country: tábuas largas de madeira escura, três fileiras por piso, com pregos nas pontas."""
    r = Rng(seed)
    woods = ["#9a6238", "#8a5530", "#a86d40", "#7d4a28"]
    o = [_base(iso, "#4a2a16")]
    for j in range(3):
        y0, y1 = j / 3, (j + 1) / 3
        x = -r.u(0, 0.9)
        while x < 1:
            ln = r.u(0.8, 1.5)
            a, b = max(0.0, x), min(1.0, x + ln)
            if b - a > 0.04:
                c = woods[int(r.u(0, len(woods)))]
                o.append(P(_quad(iso, a, y0, b, y1), D.lin([(0, tint(c, 0.08)), (1, shade(c, 0.08))], 0, 0, 1, 1), "#4a2a16", 0.7))
                gy = y0 + (y1 - y0) * r.u(0.3, 0.7)
                p0, p1 = iso.v(a + (b - a) * 0.12, gy), iso.v(a + (b - a) * 0.88, gy + r.u(-0.04, 0.04))
                o.append(line(p0[0], p0[1], p1[0], p1[1], shade(c, 0.3), 0.8, 'opacity="0.55"'))
                # pregos só nas pontas de verdade (não onde a tábua continua no piso vizinho)
                for px in ([a + 0.05] if x >= 0 else []) + ([b - 0.05] if x + ln <= 1 else []):
                    for py in (y0 + 0.07, y1 - 0.07):
                        q = iso.v(px, py)
                        o.append(C(q[0], q[1], 0.9, "#2e1a0e", None))
            x += ln
    return "".join(o)


def floor_confetti(D, iso, seed):
    """Festa: piso rosa-claro com confete colorido espalhado."""
    r = Rng(seed)
    o = [_base(iso, "#f3c6da")]
    inset = 0.012
    o.append(P(_quad(iso, inset, inset, 1 - inset, 1 - inset), D.lin([(0, "#fff6fa"), (1, "#ffe1ee")], 0, 0, 1, 1), None))
    colors = ["#ff8fb1", "#ffd23f", "#7fd6ff", "#9be38a", "#c39bff"]
    art = []
    for _ in range(16):
        px, py = iso.v(r.u(0.04, 0.96), r.u(0.04, 0.96))
        c = colors[int(r.u(0, len(colors)))]
        if r.r() < 0.45:
            art.append(E(px, py, 2.1, 1.1, c, None))
        else:
            art.append(f'<rect x="-2.6" y="-0.8" width="5.2" height="1.6" rx="0.6" fill="{c}" '
                       f'transform="translate({f(px)},{f(py)}) scale(1,0.55) rotate({f(r.u(0, 180))})"/>')
    o.append(_clip_cell(D, iso, "".join(art)))
    o.append(_gloss(D, iso, 0.16))
    return "".join(o)


def floor_saltillo(D, iso, seed):
    """Mexicano: lajota de barro (saltillo), quatro por piso, cada uma num tom, com rejunte claro."""
    r = Rng(seed)
    tones = ["#c8643a", "#d27245", "#bb5a34", "#d9804f", "#c26a3f"]
    o = [_base(iso, "#ead8bf")]
    for yy in range(2):
        for xx in range(2):
            x0, y0, x1, y1 = xx / 2 + 0.022, yy / 2 + 0.022, (xx + 1) / 2 - 0.022, (yy + 1) / 2 - 0.022
            c = tones[int(r.u(0, len(tones)))]
            o.append(P(_quad(iso, x0, y0, x1, y1), D.lin([(0, tint(c, 0.12)), (1, shade(c, 0.08))], 0, 0, 1, 1), shade(c, 0.25), 0.5))
            for _ in range(2):
                px, py = iso.v(r.u(x0 + 0.12, x1 - 0.12), r.u(y0 + 0.12, y1 - 0.12))
                o.append(E(px, py, r.u(2.0, 3.6), r.u(1.0, 1.8), shade(c, 0.14), None, extra='opacity="0.5"'))
    o.append(_gloss(D, iso, 0.12))
    return "".join(o)


def floor_memphis(D, iso, seed):
    """Anos 80: estilo Memphis, fundo lilás-claro com rabiscos, triângulos e bolinhas."""
    r = Rng(seed)
    o = [_base(iso, "#cfc4ec")]
    inset = 0.012
    o.append(P(_quad(iso, inset, inset, 1 - inset, 1 - inset), "#f6f2ff", None))
    colors = ["#ff4dd2", "#4fe0ff", "#ffd23f", "#2a2d6e"]
    art = []
    for i in range(8):
        px, py = iso.v(r.u(0.1, 0.9), r.u(0.1, 0.9))
        c = colors[i % 4]
        if i % 3 == 0:
            art.append(path(f"M{f(px - 7)},{f(py)} l3.5,-2 l3.5,2 l3.5,-2 l3.5,2", "none", c, 1.6))
        elif i % 3 == 1:
            art.append(P([(px - 4, py + 2), (px + 4, py + 2), (px, py - 3)], c, None))
        else:
            art.append(E(px, py, 2.6, 1.4, c, None))
    o.append(_clip_cell(D, iso, "".join(art)))
    o.append(_gloss(D, iso, 0.14))
    return "".join(o)


def floor_terrazzo(D, iso, seed):
    """Italiano: granilite claro com lascas de pedra coloridas."""
    r = Rng(seed)
    o = [_base(iso, "#cdbfac")]
    inset = 0.01
    o.append(P(_quad(iso, inset, inset, 1 - inset, 1 - inset), D.lin([(0, "#f7f1e8"), (1, "#e9dfcf")], 0, 0, 1, 1), None))
    chips = ["#b0382e", "#2f9e44", "#8a8f96", "#3a3c46", "#e0a050", "#ffffff"]
    art = []
    for _ in range(28):
        px, py = iso.v(r.u(0.03, 0.97), r.u(0.03, 0.97))
        c = chips[int(r.u(0, len(chips)))]
        s = r.u(0.8, 2.0)
        ang = r.u(0, 360)
        corners = []
        for i, a in enumerate((0, 100, 190, 280)):
            k = s * (1.3 if i % 2 else 1.0)
            corners.append((px + k * math.cos(math.radians(ang + a)), py + k * 0.55 * math.sin(math.radians(ang + a))))
        art.append(P(corners, c, None))
    o.append(_clip_cell(D, iso, "".join(art)))
    o.append(_gloss(D, iso, 0.2))
    return "".join(o)


def floor_tatami(D, iso, which):
    """Japonês: tatame de palha com borda de tecido escuro. 'a' e 'b' deitam as duas esteiras em direções
    diferentes; o jogo alterna as duas como num xadrez, igual ao encaixe de verdade."""
    o = [_base(iso, "#3a4a32")]
    straw = D.lin([(0, "#e0db9e"), (1, "#c4bf7a")], 0, 0, 1, 1)
    along_x = which == "a"
    halves = [(0, 0, 1, 0.5), (0, 0.5, 1, 1)] if along_x else [(0, 0, 0.5, 1), (0.5, 0, 1, 1)]
    for (x0, y0, x1, y1) in halves:
        x0, y0, x1, y1 = x0 + 0.015, y0 + 0.015, x1 - 0.015, y1 - 0.015
        o.append(P(_quad(iso, x0, y0, x1, y1), straw, "#8a8a5a", 0.5))
        for i in range(1, 9):
            t = i / 9
            if along_x:
                a, b = iso.v(x0 + 0.02, y0 + (y1 - y0) * t), iso.v(x1 - 0.02, y0 + (y1 - y0) * t)
            else:
                a, b = iso.v(x0 + (x1 - x0) * t, y0 + 0.02), iso.v(x0 + (x1 - x0) * t, y1 - 0.02)
            o.append(line(a[0], a[1], b[0], b[1], "#a8a462", 0.5, 'opacity="0.6"'))
        if along_x:
            edges = [((x0, y0 + 0.03), (x1, y0 + 0.03)), ((x0, y1 - 0.03), (x1, y1 - 0.03))]
        else:
            edges = [((x0 + 0.03, y0), (x0 + 0.03, y1)), ((x1 - 0.03, y0), (x1 - 0.03, y1))]
        for (p, q) in edges:
            a, b = iso.v(*p), iso.v(*q)
            o.append(f'<line x1="{f(a[0])}" y1="{f(a[1])}" x2="{f(b[0])}" y2="{f(b[1])}" stroke="#26402c" stroke-width="2.4"/>')
    o.append(_gloss(D, iso, 0.1))
    return "".join(o)


def floor_parquet(D, iso):
    """Francês: parquê em cesto (quadrados de três tábuas que alternam a direção), cor de mel."""
    o = [_base(iso, "#7a4a22")]
    woods = ["#d89a5a", "#c98a4e", "#e2a868"]
    for yy in range(2):
        for xx in range(2):
            x0, y0 = xx / 2, yy / 2
            for i in range(3):
                c = woods[(i + xx + 2 * yy) % 3]
                if (xx + yy) % 2 == 0:
                    q = _quad(iso, x0 + 0.012, y0 + i / 6 + 0.008, x0 + 0.488, y0 + (i + 1) / 6 - 0.008)
                else:
                    q = _quad(iso, x0 + i / 6 + 0.008, y0 + 0.012, x0 + (i + 1) / 6 - 0.008, y0 + 0.488)
                o.append(P(q, D.lin([(0, tint(c, 0.12)), (1, shade(c, 0.06))], 0, 0, 1, 1), "#8a5a2e", 0.4))
    o.append(_gloss(D, iso, 0.22))
    return "".join(o)


def floor_copacabana(D, iso):
    """Brasileiro: as ondas pretas e brancas do calçadão de Copacabana. A onda tem o período de um piso
    e passa pela sangria: emenda com o vizinho sem fresta."""
    o = [_base(iso, "#f8f5ec")]
    n = 32
    art = []
    for v0 in (0.25, 0.75):
        top, bottom = [], []
        for i in range(n + 1):
            u = -BLEED + (1 + 2 * BLEED) * i / n
            vc = v0 + 0.1 * math.sin(2 * math.pi * u)
            top.append(iso.v(u, vc - 0.09))
            bottom.append(iso.v(u, vc + 0.09))
        art.append(P(top + bottom[::-1], "#26262b", None))
    o.append(_clip_cell(D, iso, "".join(art)))
    r = Rng(14)
    for _ in range(18):  # pedrinhas portuguesas
        px, py = iso.v(r.u(0.05, 0.95), r.u(0.05, 0.95))
        o.append(C(px, py, 0.6, "#bdb8ac", None, extra='opacity="0.6"'))
    return "".join(o)


def floor_concrete(D, iso, seed):
    """Anos 2010: cimento queimado cinza, com manchas suaves e a junta entre as placas."""
    r = Rng(seed)
    o = [_base(iso, "#8f959a")]
    inset = 0.008
    o.append(P(_quad(iso, inset, inset, 1 - inset, 1 - inset), D.lin([(0, "#cdd1d4"), (1, "#b7bcc0")], 0, 0, 1, 1), None))
    art = []
    for _ in range(7):
        px, py = iso.v(r.u(0.1, 0.9), r.u(0.1, 0.9))
        art.append(E(px, py, r.u(6, 12), r.u(3, 6), "#ffffff" if r.r() < 0.5 else "#7d848a", None,
                     extra=f'opacity="{f(r.u(0.08, 0.16))}"'))
    o.append(_clip_cell(D, iso, "".join(art)))
    o.append(_gloss(D, iso, 0.24))
    return "".join(o)


def floor_led(D, iso, variant):
    """Balada: pista de LED, quatro placas por piso, cada uma acesa numa cor (ou apagada); cada variação
    gira a ordem das cores, para os pisos vizinhos não repetirem."""
    colors = ["#ff4dd2", "#4fe0ff", "#b04dff", "#ffd23f", "#2a2440"]
    o = [_base(iso, "#0d0b16")]
    for yy in range(2):
        for xx in range(2):
            x0, y0, x1, y1 = xx / 2 + 0.03, yy / 2 + 0.03, (xx + 1) / 2 - 0.03, (yy + 1) / 2 - 0.03
            c = colors[(variant * 2 + (yy * 2 + xx) * 3) % len(colors)]
            o.append(P(_quad(iso, x0, y0, x1, y1), D.lin([(0, tint(c, 0.4)), (0.5, c), (1, shade(c, 0.35))], 0, 0, 1, 1),
                       shade(c, 0.5), 0.6))
            o.append(P(_quad(iso, x0 + 0.07, y0 + 0.07, x1 - 0.07, y1 - 0.07), "#ffffff", None, 'opacity="0.16"'))
    return "".join(o)


FLOORS.update({
    "floor_70s": (1, lambda D, iso, v: floor_retro_circles(D, iso)),
    "floor_country": (3, lambda D, iso, v: floor_rustic(D, iso, 61 + v * 7)),
    "floor_party": (2, lambda D, iso, v: floor_confetti(D, iso, 71 + v)),
    "floor_diner": ("xadrez", lambda D, iso, v: floor_checker(D, iso, "#ffffff", "#2a2a33", "#9aa0a8", v)),
    "floor_mexican": (3, lambda D, iso, v: floor_saltillo(D, iso, 81 + v)),
    "floor_80s": (2, lambda D, iso, v: floor_memphis(D, iso, 91 + v)),
    "floor_italian": (3, lambda D, iso, v: floor_terrazzo(D, iso, 101 + v)),
    "floor_japanese": ("xadrez", lambda D, iso, v: floor_tatami(D, iso, v)),
    "floor_french": (1, lambda D, iso, v: floor_parquet(D, iso)),
    "floor_brazil": (1, lambda D, iso, v: floor_copacabana(D, iso)),
    "floor_2010s": (3, lambda D, iso, v: floor_concrete(D, iso, 111 + v)),
    "floor_club": (3, lambda D, iso, v: floor_led(D, iso, v)),
})


def wall_groovy(D, dark_k):
    """Anos 70: creme com três ondas largas (laranja, mostarda e marrom) e lambri de madeira."""
    o = [_upper(D, "#fbe6bf", dark_k)]
    n = 16
    for (base_y, c) in [(-78, "#e07a2e"), (-66, "#f2b33d"), (-54, "#b0532a")]:
        top, bottom = [], []
        for i in range(n + 1):
            u = X0 + (X1 - X0) * i / n
            off = 4.5 * math.sin(2 * math.pi * u / L)
            top.append((u, base_y + off - 5))
            bottom.append((u, base_y + off + 5))
        o.append(P(top + bottom[::-1], shade(c, dark_k), None))
    o.append(_wainscot("#9a6238", dark_k, "#e07a2e", "#5a3a20", frame="#c48a5a"))
    o.append(_top_band(dark_k))
    return _clip_panel(D, "".join(o))


def wall_logs(D, dark_k):
    """Country: parede de toras empilhadas, com a massa clara entre elas."""
    o = [_band_rect(-WALL_H, 0, shade("#e2d4b4", dark_k))]
    r = Rng(8)
    y = -5.0
    while y > -WALL_H + 6:
        y0 = max(y - 11.0, -WALL_H + 6)
        c = mix("#a86d40", "#86522e", r.r())
        o.append(_band_rect(y0 + 0.9, y - 0.9, D.lin([(0, shade(tint(c, 0.3), dark_k)), (0.45, shade(c, dark_k)),
                                                      (1, shade(c, dark_k + 0.3))])))
        o.append(_band_rect(y0 + 2.2, y0 + 3.2, "#ffffff", 'opacity="0.22"'))
        u = r.u(4, L - 4)
        o.append(f'<ellipse cx="{f(u)}" cy="{f((y0 + y) / 2)}" rx="2.2" ry="1.4" fill="none" '
                 f'stroke="{shade(c, dark_k + 0.35)}" stroke-width="0.8"/>')
        y = y0
    o.append(_band_rect(-5, 0, shade("#4a2e1a", dark_k)))
    o.append(_top_band(dark_k))
    return _clip_panel(D, "".join(o))


def wall_party(D, dark_k):
    """Festa: rosa-claro de bolinhas coloridas, varal de bandeirinhas e lambri branco."""
    o = [_upper(D, "#ffe2f0", dark_k)]
    for (u, v, c) in [(6, -76, "#7fd6ff"), (27, -80, "#ffd23f"), (16, -62, "#9be38a"), (37, -58, "#c39bff"),
                      (5, -48, "#ff8fb1"), (26, -46, "#7fd6ff")]:
        for du in (-L, 0, L):
            o.append(f'<circle cx="{f(u + du)}" cy="{v}" r="3.2" fill="{shade(c, dark_k)}"/>')

    def sag(u):  # o varal cai um pouco entre as emendas (período de uma célula)
        return -90 + 5 * abs(math.sin(math.pi * u / L))
    n = 12
    us = [X0 + (X1 - X0) * i / n for i in range(n + 1)]
    o.append(path("M" + " L".join(f"{f(u)},{f(sag(u))}" for u in us), "none", shade("#8a5a7a", dark_k), 0.8))
    for i, u in enumerate((5.25, 15.75, 26.25, 36.75)):
        y = sag(u)
        c = ["#ff4d6d", "#ffd23f", "#4fc3ff", "#7ee85a"][i]
        o.append(P([(u - 3.4, y), (u + 3.4, y), (u, y + 7.5)], shade(c, dark_k), INK3, 0.5))
    o.append(_wainscot("#ffffff", dark_k, "#ff8fb1", "#e05a8a"))
    o.append(_top_band(dark_k))
    return _clip_panel(D, "".join(o))


def wall_diner(D, dark_k):
    """Americano: azulejo branco no alto, faixa cromada e painel vermelho com xadrez preto e branco."""
    o = [_band_rect(-WALL_H, -46, shade("#fbfbfb", dark_k))]
    grout = shade("#d4d9de", dark_k)
    for y in range(-WALL_H + 13, -46, 7):
        o.append(_band_rect(y - 0.4, y + 0.4, grout))
    for i in range(7):
        o.append(f'<rect x="{f(i * 7 - 0.4)}" y="{-WALL_H + 6}" width="0.8" height="{WALL_H - 6 - 46}" fill="{grout}"/>')
    o.append(_band_rect(-46, -40, D.lin([(0, shade("#ffffff", dark_k)), (0.3, shade("#c9d3de", dark_k)),
                                         (0.6, shade("#8d98a6", dark_k)), (1, shade("#e8edf2", dark_k))])))
    o.append(_band_rect(-40, -5, shade("#e0303a", dark_k)))
    for i in range(-1, 13):
        for row in range(2):
            color = "#1d1d24" if (i + row) % 2 == 0 else "#ffffff"
            o.append(f'<rect x="{f(i * 3.5)}" y="{f(-16 + row * 3.5)}" width="3.5" height="3.5" fill="{shade(color, dark_k)}"/>')
    o.append(_band_rect(-5, 0, shade("#1d1d24", dark_k)))
    o.append(_band_rect(-46, -45.4, INK3) + _band_rect(-40.3, -39.7, INK3))
    o.append(_top_band(dark_k))
    return _clip_panel(D, "".join(o))


def wall_stucco(D, dark_k):
    """Mexicano: estuque amarelo com textura, faixa de azulejos de talavera e barra de barro."""
    o = [_upper(D, "#f6c445", dark_k)]
    r = Rng(12)
    for _ in range(16):
        u, v = r.u(2, L - 2), r.u(-WALL_H + 12, -46)
        o.append(f'<ellipse cx="{f(u)}" cy="{f(v)}" rx="{f(r.u(1.5, 3.5))}" ry="{f(r.u(0.8, 1.6))}" '
                 f'fill="{shade("#dc9f2a", dark_k)}" opacity="0.45"/>')
    o.append(_band_rect(-42, -27, shade("#f4efe2", dark_k)))
    blue, yellow, green = shade("#2f6fd9", dark_k), shade("#ffd23f", dark_k), shade("#2fae4e", dark_k)
    for i in range(3):
        cx, cy = i * 14 + 7, -34.5
        o.append(f'<rect x="{f(i * 14 + 0.6)}" y="-41.4" width="12.8" height="13.8" fill="none" stroke="{blue}" stroke-width="1"/>')
        o.append(f'<circle cx="{cx}" cy="{cy}" r="2" fill="{yellow}"/>')
        for a in range(0, 360, 45):
            o.append(f'<circle cx="{f(cx + math.cos(math.radians(a)) * 3.8)}" cy="{f(cy + math.sin(math.radians(a)) * 3.8)}" '
                     f'r="1.4" fill="{blue}"/>')
        for (dx, dy) in ((-5, -5.5), (5, -5.5), (-5, 5.5), (5, 5.5)):
            o.append(f'<circle cx="{f(cx + dx)}" cy="{f(cy + dy)}" r="1" fill="{green}"/>')
    o.append(_band_rect(-42.6, -41.8, INK3) + _band_rect(-27.2, -26.4, INK3))
    o.append(_band_rect(-26.4, -5, shade("#c8643a", dark_k)))
    o.append(_band_rect(-5, 0, shade("#7a3a20", dark_k)))
    o.append(_top_band(dark_k))
    return _clip_panel(D, "".join(o))


def wall_synth(D, dark_k):
    """Anos 80: roxo escuro com zigue-zague de neon rosa e ciano e grade de neon embaixo."""
    o = [_band_rect(-WALL_H, 0, D.lin([(0, shade("#2a1a4a", dark_k)), (1, shade("#4a1f6e", dark_k))]))]
    for (vc, c) in [(-76, "#ff4dd2"), (-64, "#4fe0ff")]:
        d = "M" + " L".join(f"{f(7 * i)},{f(vc + (4 if i % 2 else -4))}" for i in range(-1, 8))
        o.append(path(d, "none", shade(c, dark_k), 5, 'opacity="0.3"'))
        o.append(path(d, "none", shade(tint(c, 0.5), dark_k), 1.6))
    grid = shade("#ff4dd2", dark_k)
    for y in (-42, -32, -24, -17, -11):
        o.append(_band_rect(y - 0.5, y + 0.5, grid, 'opacity="0.8"'))
    for u in (0, 14, 28, 42):
        o.append(f'<rect x="{f(u - 0.5)}" y="-42" width="1" height="37" fill="{grid}" opacity="0.8"/>')
    o.append(_band_rect(-5, 0, shade("#120a22", dark_k)))
    o.append(_top_band(dark_k, "#ff4dd2"))
    return _clip_panel(D, "".join(o))


def wall_tuscan(D, dark_k):
    """Italiano: reboco toscano cor de ocre com manchas, rodameio de madeira e tijolo aparente embaixo."""
    o = [_upper(D, "#f0c890", dark_k)]
    r = Rng(19)
    for _ in range(10):
        u, v = r.u(3, L - 3), r.u(-WALL_H + 12, -44)
        o.append(f'<ellipse cx="{f(u)}" cy="{f(v)}" rx="{f(r.u(3, 6))}" ry="{f(r.u(1.5, 3))}" '
                 f'fill="{shade("#e0b070", dark_k)}" opacity="0.4"/>')
    o.append(_band_rect(-38, -5, shade("#e9dccb", dark_k)))
    for row in range(6):
        y0 = -38 + row * 5.5
        off = 0.0 if row % 2 == 0 else -L / 8
        for i in range(-1, 5):
            brick = shade(mix("#c8603e", "#a84a30", r.r()), dark_k)
            o.append(f'<rect x="{f(off + i * L / 4 + 0.5)}" y="{f(y0 + 0.5)}" width="{f(L / 4 - 1)}" height="4.5" rx="0.8" fill="{brick}"/>')
            o.append(f'<rect x="{f(off + i * L / 4 + 1.2)}" y="{f(y0 + 1.1)}" width="{f(L / 8)}" height="0.9" rx="0.45" fill="#ffffff" opacity="0.2"/>')
    o.append(_band_rect(-40.5, -37.5, shade("#8a5a32", dark_k)))
    o.append(_band_rect(-40.5, -40, INK3) + _band_rect(-37.8, -37.3, INK3))
    o.append(_band_rect(-5, 0, shade("#6b3a22", dark_k)))
    o.append(_top_band(dark_k))
    return _clip_panel(D, "".join(o))


def wall_shoji(D, dark_k):
    """Japonês: painel shoji de papel claro com grade de madeira, e lambri de madeira escura."""
    wood = shade("#6b4423", dark_k)
    o = [_band_rect(-WALL_H, 0, wood)]
    top, bottom = -WALL_H + 7, -40
    paper = D.lin([(0, shade("#fdf9ee", dark_k)), (1, shade("#efe5cc", dark_k))])
    o.append(f'<rect x="2.5" y="{top}" width="{f(L - 5)}" height="{bottom - top}" fill="{paper}"/>')
    for i in (1, 2):
        o.append(f'<rect x="{f(2.5 + (L - 5) * i / 3 - 0.6)}" y="{top}" width="1.2" height="{bottom - top}" fill="{wood}"/>')
    for j in (1, 2, 3):
        o.append(f'<rect x="2.5" y="{f(top + (bottom - top) * j / 4 - 0.6)}" width="{f(L - 5)}" height="1.2" fill="{wood}"/>')
    post = shade("#4a2a16", dark_k)
    for u in (0, L):  # pilares nas emendas: o vizinho desenha a outra metade
        o.append(f'<rect x="{f(u - 2.5)}" y="{-WALL_H}" width="5" height="{WALL_H}" fill="{post}"/>')
    o.append(_band_rect(-40, -38.4, shade("#3a2212", dark_k)))
    for u in (10.5, 21, 31.5):
        o.append(f'<rect x="{f(u - 0.4)}" y="-38.4" width="0.8" height="33.4" fill="{post}"/>')
    o.append(_band_rect(-5, 0, shade("#2a1a0e", dark_k)))
    o.append(_top_band(dark_k, "#4a2a16"))
    return _clip_panel(D, "".join(o))


def wall_boiserie(D, dark_k):
    """Francês: boiserie azul-acinzentado com molduras douradas em cima e no lambri."""
    o = [_upper(D, "#bcd2e4", dark_k)]
    gold = shade("#d9b44a", dark_k)
    o.append(f'<rect x="5" y="-86" width="{f(L - 10)}" height="38" rx="3" fill="none" stroke="{gold}" stroke-width="1.4"/>')
    o.append(f'<rect x="7.5" y="-83.5" width="{f(L - 15)}" height="33" rx="2" fill="none" stroke="#ffffff" stroke-width="0.7" opacity="0.6"/>')
    o.append(f'<circle cx="{f(L / 2)}" cy="-86" r="2" fill="{gold}"/>')
    o.append(_wainscot("#a9c3da", dark_k, "#d9b44a", "#7d95ab", frame="#d9b44a"))
    o.append(_top_band(dark_k))
    return _clip_panel(D, "".join(o))


def wall_tropical(D, dark_k):
    """Brasileiro: papel de parede de folhagem tropical, lambri branco e rodameio amarelo."""
    o = [_upper(D, "#e9f6e2", dark_k)]
    vein = shade("#1d6b33", dark_k)
    leaves = [(6, -78, -40, 22, 7, "#2fae4e"), (20, -66, 30, 24, 8, "#3fbf4a"), (34, -84, -120, 20, 6.5, "#23803a"),
              (30, -52, 160, 18, 6, "#4fcf5a"), (12, -50, -150, 16, 5.5, "#23803a"), (40, -64, 70, 18, 6, "#2fae4e")]
    for (u, v, ang, ln, w, c) in leaves:
        fill = D.lin([(0, shade(tint(c, 0.25), dark_k)), (1, shade(c, dark_k + 0.15))], 0, 0, 1, 1)
        dx, dy = math.cos(math.radians(ang)) * ln / 2, math.sin(math.radians(ang)) * ln / 2
        for du in (-L, 0, L):
            o.append(path(leaf(u + du, v, ang, ln, w, 0.05), fill, vein, 0.7))
            o.append(line(u + du - dx, v - dy, u + du + dx, v + dy, vein, 0.6, 'opacity="0.6"'))
    o.append(_wainscot("#ffffff", dark_k, "#ffd23f", "#2fae4e"))
    o.append(_top_band(dark_k))
    return _clip_panel(D, "".join(o))


def wall_subway(D, dark_k):
    """Anos 2010: azulejo de metrô branco em amarração, rejunte cinza e rodapé preto."""
    o = [_band_rect(-WALL_H, 0, shade("#c3c8cd", dark_k))]
    tile = D.lin([(0, shade("#ffffff", dark_k)), (1, shade("#e9edf1", dark_k))])
    w, h = L / 4, 5.4
    y, row = -5.0, 0
    while y > -WALL_H + 6:
        y0 = max(y - h, -WALL_H + 6)
        off = 0.0 if row % 2 == 0 else -w / 2
        for i in range(-1, 6):
            x0 = off + i * w
            o.append(f'<rect x="{f(x0 + 0.45)}" y="{f(y0 + 0.45)}" width="{f(w - 0.9)}" height="{f(y - y0 - 0.9)}" rx="0.9" fill="{tile}"/>')
            o.append(f'<rect x="{f(x0 + 1.2)}" y="{f(y0 + 1)}" width="{f(w * 0.45)}" height="0.8" rx="0.4" fill="#ffffff" opacity="0.8"/>')
        y = y0
        row += 1
    o.append(_band_rect(-5, 0, shade("#2a2c34", dark_k)))
    o.append(_top_band(dark_k))
    return _clip_panel(D, "".join(o))


def wall_neon(D, dark_k):
    """Balada: preto-azulado com duas faixas de neon (rosa e ciano) e pontinhos de luz."""
    o = [_band_rect(-WALL_H, 0, D.lin([(0, shade("#15121f", dark_k)), (1, shade("#251a38", dark_k))]))]
    for (u, v) in [(5, -84), (17, -78), (29, -88), (38, -74), (11, -52), (24, -48), (35, -56)]:
        o.append(f'<circle cx="{u}" cy="{v}" r="0.9" fill="#ffffff" opacity="0.7"/>')
    for (y, c) in [(-68, "#ff4dd2"), (-62, "#4fe0ff")]:
        o.append(_band_rect(y - 3, y + 3, shade(c, dark_k), 'opacity="0.28"'))
        o.append(_band_rect(y - 0.9, y + 0.9, shade(tint(c, 0.55), dark_k)))
    o.append(_band_rect(-38, -5, shade("#1d1a2b", dark_k)))
    o.append(_band_rect(-38.8, -37.6, shade("#b04dff", dark_k)))
    o.append(_band_rect(-5, 0, shade("#0d0b16", dark_k)))
    o.append(_top_band(dark_k, "#2a2440"))
    return _clip_panel(D, "".join(o))


WALLS.update({
    "wall_70s": wall_groovy, "wall_country": wall_logs, "wall_party": wall_party, "wall_diner": wall_diner,
    "wall_mexican": wall_stucco, "wall_80s": wall_synth, "wall_italian": wall_tuscan, "wall_japanese": wall_shoji,
    "wall_french": wall_boiserie, "wall_brazil": wall_tropical, "wall_2010s": wall_subway, "wall_club": wall_neon,
})


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


# --- Itens de parede que o jogador compra e pendura (TV, rádio, janelas, lousa...) ------------
# Mesmo formato dos enfeites: desenho plano numa célula de parede (u de 0 a L, v para cima).

def wall_tv(D):
    """TV de tela plana na parede, passando um desenho de xícara."""
    o = [f'<rect x="{f(L / 2 - 3)}" y="-50" width="6" height="4" fill="#3a3c46"/>']
    o.append(f'<rect x="4" y="-78" width="{f(L - 8)}" height="28" rx="2.5" fill="#1d1d24" stroke="{INK3}" stroke-width="1.2"/>')
    o.append(f'<rect x="6.5" y="-75.5" width="{f(L - 13)}" height="23" rx="1" fill="{D.lin([(0, "#4fc3ff"), (1, "#b06bff")])}"/>')
    o.append(f'<path d="M{f(L / 2 - 6)},-68 h12 v6 a6,6 0 0,1 -12,0 Z" fill="#ffffff" stroke="{INK3}" stroke-width="0.8"/>')
    o.append(f'<path d="M{f(L / 2 + 6)},-66 a3,3 0 0,1 0,5" fill="none" stroke="#ffffff" stroke-width="1.4"/>')
    o.append(f'<path d="M{f(L / 2 - 3)},-71 q2,-3 0,-5 M{f(L / 2 + 2)},-71 q2,-3 0,-5" fill="none" stroke="#ffffff" stroke-width="1.1" opacity="0.8"/>')
    o.append(f'<path d="M8,-75 L20,-75 L9,-56 Z" fill="#ffffff" opacity="0.18"/>')
    o.append(f'<circle cx="{f(L - 7)}" cy="-52.5" r="0.9" fill="#ff4d5e"/>')
    return "".join(o)


def wall_radio(D):
    """Prateleira com um rádio antigo de madeira e botões dourados."""
    o = [f'<rect x="5" y="-50" width="{f(L - 10)}" height="4" rx="1.2" fill="#c98a52" stroke="{INK3}" stroke-width="0.9"/>']
    o.append(f'<path d="M9,-46 l3,6 M{f(L - 9)},-46 l-3,6" stroke="#8a5530" stroke-width="1.6"/>')
    o.append(f'<path d="M9,-50 V-66 Q9,-74 {f(L / 2)},-74 Q{f(L - 9)},-74 {f(L - 9)},-66 V-50 Z" '
             f'fill="{D.lin([(0, "#d88a45"), (1, "#8a4f26")], 0, 0, 1, 0)}" stroke="{INK3}" stroke-width="1.1"/>')
    grille = D.raw("grade_radio", '<pattern id="grade_radio" patternUnits="userSpaceOnUse" width="3" height="3">'
                   '<rect width="3" height="3" fill="#f3e2c0"/><rect width="1.4" height="3" fill="#c9a46a"/></pattern>')
    o.append(f'<path d="M12,-54 V-64 Q12,-70 {f(L / 2)},-70 Q{f(L / 2 + 3)},-70 {f(L / 2 + 3)},-66 V-54 Z" fill="{grille}" stroke="{INK3}" stroke-width="0.8"/>')
    for yy in (-66, -59):
        o.append(f'<circle cx="{f(L - 14)}" cy="{yy}" r="2.6" fill="#ffd23f" stroke="{INK3}" stroke-width="0.7"/>')
    o.append(f'<path d="M{f(L / 2)},-74 L{f(L / 2 + 8)},-84" stroke="#3a3c46" stroke-width="1.2"/>')
    return "".join(o)


def wall_round_window(D, frame="#ffffff", sky=("#6cc8ff", "#e3f6ff"), lattice=False):
    """Janela redonda (escotilha) com céu e moldura (branca na clássica; as coleções mudam as cores, DT-067).
    lattice: janela japonesa redonda, com papel de arroz e treliça de madeira no lugar do céu."""
    cx, cy, r = L / 2, -68, 13
    o = [f'<circle cx="{f(cx)}" cy="{cy}" r="{r + 4}" fill="{frame}" stroke="{INK3}" stroke-width="1.2"/>']
    o.append(f'<circle cx="{f(cx)}" cy="{cy}" r="{r}" fill="{D.lin([(0, sky[0]), (1, sky[1])])}" stroke="{INK3}" stroke-width="0.9"/>')
    if lattice:
        bars = []
        for k in (-2, -1, 0, 1, 2):
            half = math.sqrt(max(r * r - (k * 5.2) ** 2, 0.0))
            bars.append(f"M{f(cx + k * 5.2)},{f(cy - half)} V{f(cy + half)} M{f(cx - half)},{f(cy + k * 5.2)} H{f(cx + half)}")
        o.append(f'<path d="{" ".join(bars)}" stroke="{shade(frame, 0.15)}" stroke-width="1.1"/>')
        return "".join(o)
    o.append(f'<ellipse cx="{f(cx - 4)}" cy="{cy - 4}" rx="6" ry="3" fill="#ffffff" opacity="0.95"/>')
    o.append(f'<path d="M{f(cx - r)},{cy + 5} Q{f(cx)},{cy - 1} {f(cx + r)},{cy + 4} L{f(cx + r - 2)},{cy + 8} A{r},{r} 0 0,1 {f(cx - r + 2)},{cy + 8} Z" fill="#8fe06a"/>')
    o.append(f'<path d="M{f(cx - 7)},{cy + 6} L{f(cx + 2)},{cy - 9}" stroke="#ffffff" stroke-width="2.4" opacity="0.6"/>')
    for a in range(0, 360, 90):
        x, y = cx + math.cos(math.radians(a + 45)) * (r + 2), cy + math.sin(math.radians(a + 45)) * (r + 2)
        o.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="0.9" fill="#c9d3de"/>')
    return "".join(o)


def wall_arched_window(D, frame="#ffffff", box=("#e07a2e", "#b0532a")):
    """Janelão em arco, alto, com vidro dividido e floreira (moldura e floreira nas cores da coleção, DT-067)."""
    u0, u1, z0, z1 = 8, L - 8, 38, 90
    w = u1 - u0
    arch = f"M{u0},{-z0} V{-z1 + w / 2} A{w / 2},{w / 2} 0 0,1 {u1},{-z1 + w / 2} V{-z0} Z"
    o = [f'<path d="M{u0 - 4},{-z0 + 1} V{-z1 + w / 2} A{w / 2 + 4},{w / 2 + 4} 0 0,1 {u1 + 4},{-z1 + w / 2} V{-z0 + 1} Z" fill="{frame}" stroke="{INK3}" stroke-width="1.2"/>']
    o.append(f'<path d="{arch}" fill="{D.lin([(0, "#6cc8ff"), (0.7, "#c8ecff"), (1, "#eaf9ff")])}" stroke="{INK3}" stroke-width="0.9"/>')
    o.append(f'<path d="M{u0},{-z0 - 10} Q{u0 + w * 0.4},{-z0 - 20} {u1},{-z0 - 13} V{-z0} H{u0} Z" fill="#8fe06a" opacity="0.9"/>')
    o.append(f'<path d="M{f(L / 2)},{-z1} V{-z0} M{u0},{-z0 - 22} H{u1}" stroke="#ffffff" stroke-width="2.6"/>')
    o.append(f'<path d="M{u0 + 4},{-z0 - 4} L{u0 + w * 0.45},{-z1 + 14}" stroke="#ffffff" stroke-width="2.6" opacity="0.6"/>')
    o.append(f'<rect x="{u0 - 6}" y="{-z0}" width="{w + 12}" height="7" rx="2" fill="{D.lin([(0, box[0]), (1, box[1])])}" stroke="{INK3}" stroke-width="1"/>')
    for i, c in enumerate(("#ff4d8d", "#ffd23f", "#ff7a2f", "#b06bff")):
        x = u0 + 2 + i * (w - 4) / 3
        o.append(f'<circle cx="{f(x)}" cy="{-z0 - 3}" r="2.6" fill="{c}" stroke="{INK3}" stroke-width="0.6"/>')
    return "".join(o)


def wall_chalkboard(D):
    """Lousa de cardápio com moldura de madeira e desenhos de giz."""
    o = [f'<rect x="5" y="-82" width="{f(L - 10)}" height="36" rx="2" fill="#a86d40" stroke="{INK3}" stroke-width="1.2"/>']
    o.append(f'<rect x="8" y="-79" width="{f(L - 16)}" height="30" rx="1" fill="{D.lin([(0, "#3a4a42"), (1, "#26332d")])}"/>')
    o.append(f'<path d="M12,-73 h{f(L - 24)}" stroke="#ffffff" stroke-width="1.4" opacity="0.85"/>')
    for i, y in enumerate((-67, -61, -55)):
        o.append(f'<path d="M12,{y} h{f(L * 0.35)}" stroke="#ffffff" stroke-width="1" opacity="0.7"/>')
        o.append(f'<circle cx="{f(L - 13)}" cy="{y}" r="1.4" fill="{("#ffd23f", "#ff8fb1", "#8fe3ff")[i]}" opacity="0.9"/>')
    o.append(f'<path d="M{f(L - 20)},-71 h7 v3 a3.5,3.5 0 0,1 -7,0 Z" fill="none" stroke="#ffffff" stroke-width="0.9" opacity="0.8"/>')
    o.append(f'<rect x="10" y="-47" width="{f(L - 20)}" height="2.4" rx="1" fill="#8a5530"/>')
    return "".join(o)


def wall_neon(D):
    """Letreiro de neon em forma de xícara com coração, com brilho na parede."""
    cx, cy = L / 2, -66
    o = [f'<circle cx="{f(cx)}" cy="{cy}" r="20" fill="{D.rad([(0, "#ff4da6", 0.35), (1, "#ff4da6", 0)])}"/>']
    cup = (f"M{f(cx - 10)},{cy - 6} h20 v8 a10,10 0 0,1 -20,0 Z M{f(cx + 10)},{cy - 3} a5,5 0 0,1 0,9 "
           f"M{f(cx - 13)},{cy + 13} h26")
    o.append(f'<path d="{cup}" fill="none" stroke="#ff4da6" stroke-width="4" stroke-linecap="round" opacity="0.5"/>')
    o.append(f'<path d="{cup}" fill="none" stroke="#ffe3f3" stroke-width="1.6" stroke-linecap="round"/>')
    heart = f"M{f(cx)},{cy - 9} c-2,-4 -8,-3 -6,2 l6,5 l6,-5 c2,-5 -4,-6 -6,-2 Z"
    o.append(f'<path d="{heart}" transform="translate(0,-8)" fill="none" stroke="#4fe0ff" stroke-width="3.6" opacity="0.45"/>')
    o.append(f'<path d="{heart}" transform="translate(0,-8)" fill="none" stroke="#e3fbff" stroke-width="1.3"/>')
    return "".join(o)


def wall_mirror(D):
    """Espelho oval com moldura dourada trabalhada."""
    cx, cy = L / 2, -66
    o = [f'<ellipse cx="{f(cx)}" cy="{cy}" rx="13" ry="17" fill="{D.lin([(0, "#ffe7a0"), (0.5, "#d9b44a"), (1, "#8a6a2e")])}" stroke="{INK3}" stroke-width="1.2"/>']
    o.append(f'<ellipse cx="{f(cx)}" cy="{cy}" rx="10" ry="14" fill="{D.lin([(0, "#e8f4ff"), (0.6, "#b9d4ea"), (1, "#8fb0cc")], 0, 0, 1, 1)}" stroke="{INK3}" stroke-width="0.8"/>')
    o.append(f'<path d="M{f(cx - 6)},{cy + 4} L{f(cx + 2)},{cy - 10} M{f(cx - 2)},{cy + 8} L{f(cx + 5)},{cy - 4}" stroke="#ffffff" stroke-width="1.8" opacity="0.8"/>')
    o.append(f'<circle cx="{f(cx)}" cy="{cy - 18}" r="2.6" fill="#d9b44a" stroke="{INK3}" stroke-width="0.7"/>')
    return "".join(o)


def wall_hanging_plant(D):
    """Vaso pendurado no teto por cordas, com folhas caindo."""
    cx = L / 2
    o = [f'<path d="M{f(cx)},-96 L{f(cx - 7)},-72 M{f(cx)},-96 L{f(cx + 7)},-72" stroke="#c9a46a" stroke-width="1"/>']
    o.append(f'<path d="M{f(cx - 9)},-72 h18 l-2,9 a6,3 0 0,1 -14,0 Z" fill="{D.lin([(0, "#ffffff"), (1, "#d9e1ea")], 0, 0, 1, 0)}" stroke="{INK3}" stroke-width="1"/>')
    r = Rng(41)
    for i in range(9):
        x0 = cx - 8 + i * 2
        ln = r.u(10, 26)
        o.append(f'<path d="M{f(x0)},-70 q{f(r.u(-6, 6))},{f(ln / 2)} {f(r.u(-3, 3))},{f(ln)}" fill="none" stroke="#2f8a3a" stroke-width="1"/>')
        for j in range(3):
            yy = -70 + ln * (j + 1) / 3
            o.append(f'<ellipse cx="{f(x0 + r.u(-2, 2))}" cy="{f(yy)}" rx="2.6" ry="1.6" fill="{mix("#3fbf4a", "#8fe06a", r.r())}" stroke="#1d6b33" stroke-width="0.5"/>')
    return "".join(o)


DECORATIONS.update({
    "tv": lambda D, side: wall_tv(D),
    "radio": lambda D, side: wall_radio(D),
    "janela_redonda": lambda D, side: wall_round_window(D),
    "janelao": lambda D, side: wall_arched_window(D),
    "lousa": lambda D, side: wall_chalkboard(D),
    "neon_xicara": lambda D, side: wall_neon(D),
    "espelho": lambda D, side: wall_mirror(D),
    "planta_pendurada": lambda D, side: wall_hanging_plant(D),
    # janelas das coleções (DT-067)
    "janela_diner": lambda D, side: wall_round_window(D, frame="#e0303a"),
    "janela_neon": lambda D, side: wall_round_window(D, frame="#b06bff", sky=("#2a1440", "#6a3ab0")),
    "janela_country": lambda D, side: wall_window(D, "#b8432f"),
    "janela_festa": lambda D, side: wall_window(D, "#b06bff"),
    "janelao_italiano": lambda D, side: wall_arched_window(D, frame="#2f8a3a", box=("#c47a3a", "#8a4a1e")),
    "janela_shoji": lambda D, side: wall_round_window(D, frame="#8a5a2e", sky=("#fffaf0", "#f4e6cc"), lattice=True),
    "janelao_mexicano": lambda D, side: wall_arched_window(D, frame="#2f6fd9", box=("#ffd23f", "#e0303a")),
    "janela_groovy": lambda D, side: wall_round_window(D, frame="#f07a1a", sky=("#ffb04a", "#ffe7a0")),
    "janela_arcade": lambda D, side: wall_round_window(D, frame="#3ee0ff", sky=("#4a2a8a", "#ff3d7f")),
    "janelao_brasileiro": lambda D, side: wall_arched_window(D, frame="#2fae3a", box=("#ffd23f", "#2f6fd9")),
    "janela_industrial": lambda D, side: wall_window(D, "#4a4d5a"),
    "janelao_frances": lambda D, side: wall_arched_window(D, frame="#2a2a33", box=("#ffe7a0", "#8a6a2e")),
})


def wall_doorway(D, closed=False, frame=("#ffffff", "#dfe6ee"), awning=("#ffffff", "#ff4d5e"), name="entrada"):
    """Entrada na parede da frente: batente com toldo listrado e a plaquinha "ABERTO" (o vão fica livre).
    Com o café fechado, a plaquinha diz "FECHADO", em vermelho. Cada coleção pinta o batente e o toldo (DT-067)."""
    top = 78
    o = []
    for x0 in (0.5, L - 5.5):
        o.append(f'<rect x="{f(x0)}" y="{-top}" width="5" height="{top}" fill="{D.lin([(0, frame[0]), (1, frame[1])], 0, 0, 1, 0)}" '
                 f'stroke="{INK3}" stroke-width="1.1"/>')
    o.append(f'<rect x="-1" y="{-top - 6}" width="{f(L + 2)}" height="7" rx="1.5" fill="{frame[0]}" stroke="{INK3}" stroke-width="1.1"/>')
    # toldo listrado por cima do batente
    stripes = D.raw(f"toldo_{name}", f'<pattern id="toldo_{name}" patternUnits="userSpaceOnUse" width="8" height="8">'
                    f'<rect width="8" height="8" fill="{awning[0]}"/><rect width="4" height="8" fill="{awning[1]}"/></pattern>')
    o.append(f'<path d="M-3,{-top - 6} L{f(L + 3)},{-top - 6} L{f(L + 1)},{-top + 6} Q{f(L * 0.75)},{-top + 10} {f(L / 2)},{-top + 6} '
             f'Q{f(L * 0.25)},{-top + 10} -1,{-top + 6} Z" fill="{stripes}" stroke="{INK3}" stroke-width="1"/>')
    # plaquinha "ABERTO" (ou "FECHADO")
    cx = L / 2
    o.append(f'<path d="M{f(cx - 6)},{-top + 9} L{f(cx)},{-top + 4} L{f(cx + 6)},{-top + 9}" stroke="#6a4a2a" stroke-width="0.8" fill="none"/>')
    o.append(f'<rect x="{f(cx - 10)}" y="{-top + 9}" width="20" height="9" rx="2" fill="#ffffff" stroke="{INK3}" stroke-width="0.8"/>')
    text, size, color = ("FECHADO", 5.3, "#e0303a") if closed else ("ABERTO", 6.2, "#2fae3a")
    o.append(f'<text x="{f(cx)}" y="{-top + 16}" text-anchor="middle" font-family="Fredoka, Nunito, sans-serif" font-weight="700" '
             f'font-size="{size}" fill="{color}">{text}</text>')
    return "".join(o)


DECORATIONS["porta"] = lambda D, side: wall_doorway(D)
DECORATIONS["porta_fechada"] = lambda D, side: wall_doorway(D, closed=True)

# Portas das coleções (DT-067): nome -> (batente claro e escuro, faixas do toldo)
DOORS = {
    "frances": (("#2a2a33", "#15151b"), ("#ffffff", "#2a2a33")),
    "japones": (("#c98a4b", "#8a5a2e"), ("#2a3f86", "#1d2a5a")),
    "italiano": (("#2f8a3a", "#1d5a26"), ("#ffffff", "#2f8a3a")),
    "anos70": (("#f07a1a", "#a84a0a"), ("#ffd27a", "#a8522a")),
    "americano": (("#7fdcc0", "#3aa88a"), ("#ffffff", "#e0303a")),
    "anos2010": (("#c9d4e0", "#8f9aa7"), ("#f4f7fa", "#4a4d5a")),
    "festa": (("#ffcf3f", "#e0a800"), ("#ff8ab8", "#ffe066")),
    "anos80": (("#8a4fd1", "#4a2a8a"), ("#3ee0ff", "#ff3d7f")),
    "balada": (("#2a1440", "#120a20"), ("#b06bff", "#2a1440")),
    "brasileiro": (("#2fae3a", "#1d7a26"), ("#ffd23f", "#2fae3a")),
    "country": (("#a8703a", "#6a4a2a"), ("#f4ead6", "#b8432f")),
    "mexicano": (("#d9734a", "#a84a2a"), ("#ffd23f", "#e0303a")),
}
for _name, (_door_frame, _door_awning) in DOORS.items():
    DECORATIONS[f"porta_{_name}"] = (lambda fr, aw, nm: lambda D, side: wall_doorway(D, False, fr, aw, nm))(_door_frame, _door_awning, _name)
    DECORATIONS[f"porta_{_name}_fechada"] = (lambda fr, aw, nm: lambda D, side: wall_doorway(D, True, fr, aw, nm))(_door_frame, _door_awning, _name)


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
