"""Temperos (DT-056): os ícones da prateleira de temperos, 48x48 com centro em (24, 26), como os pratos e as bebidas."""
from core3 import *


def _shadow(cx=24, cy=41, rx=12):
    return E(cx, cy, rx, 2.8, "#2a1c3a", None, extra='opacity="0.18"')


def _sparkle(x, y, r, color="#ffe34d"):
    return path(f"M{x},{y - r} L{x + r * 0.28},{y - r * 0.28} L{x + r},{y} L{x + r * 0.28},{y + r * 0.28} L{x},{y + r} "
                f"L{x - r * 0.28},{y + r * 0.28} L{x - r},{y} L{x - r * 0.28},{y - r * 0.28} Z", color, "#c98a00", 0.6)


def _jar(D, color, lid, label):
    """Pote de vidro baixinho com tampa colorida e um rótulo redondo."""
    o = [_shadow()]
    o.append(path("M12,19 L12,37 C12,40 15,41 24,41 C33,41 36,40 36,37 L36,19 Z",
                  D.lin([(0, tint(color, 0.25)), (0.5, color), (1, shade(color, 0.3))], 0, 0, 1, 0), INK3, 1.2))
    o.append(path("M14.5,22 L14.5,35", "none", "#ffffff", 1.6, 'opacity="0.45"'))
    o.append(path("M10.5,13 h27 a2,2 0 0,1 2,2 v4 a2,2 0 0,1 -2,2 h-27 a2,2 0 0,1 -2,-2 v-4 a2,2 0 0,1 2,-2 Z",
                  D.lin([(0, tint(lid, 0.2)), (1, shade(lid, 0.25))]), INK3, 1.2))
    o.append(C(24, 30, 7.4, "#fff8e8", INK3, 1.0))
    o.append(label)
    return "".join(o)


def salt(D):
    """Sal da Fartura: saleiro branco com tampa de metal, grãos caindo e um brilho de "mais"."""
    o = [_shadow(22, 41, 10)]
    o.append(path("M14,20 C14,15 30,15 30,20 L31.5,37 C31.5,40.5 12.5,40.5 12.5,37 Z",
                  D.lin([(0, "#ffffff"), (0.6, "#eef3f8"), (1, "#c9d4e0")], 0, 0, 1, 0), INK3, 1.2))
    o.append(path("M14,20 C14,9 30,9 30,20 C30,22 14,22 14,20 Z", D.lin([(0, "#e8eef5"), (1, "#8f9cab")]), INK3, 1.2))
    for (x, y) in [(19, 15), (22, 13.6), (25, 15), (22, 17)]:
        o.append(C(x, y, 0.9, "#4a5566", None))
    o.append(path("M16.5,24 L17,35", "none", "#ffffff", 1.6, 'opacity="0.8"'))
    for (x, y) in [(33, 9), (36, 13), (34.5, 17), (38, 7)]:
        o.append(f'<rect x="{x}" y="{y}" width="1.8" height="1.8" fill="#ffffff" stroke="#9aa6b5" stroke-width="0.5" transform="rotate(30 {x} {y})"/>')
    o.append(C(37, 28, 6.2, "#3cc04e", INK3, 1.0))
    o.append(path("M37,24.6 V31.4 M33.6,28 H40.4", "none", "#ffffff", 2.2))
    return "".join(o)


def pepper(D):
    """Pimenta-Relâmpago: pimenta vermelha com um raio amarelo (menos 1 hora)."""
    o = [_shadow(24, 41, 13)]
    o.append(path("M13,22 C9,30 14,40 24,39 C33,38 39,31 37,25 C35,20 30,21 27,24 C23,28 19,27 17,23 C16,21 14,20 13,22 Z",
                  D.lin([(0, "#ff6b5c"), (0.6, "#e0303a"), (1, "#a8161f")]), INK3, 1.2))
    o.append(path("M15,27 C16,32 20,35 25,35", "none", "#ffffff", 1.6, 'opacity="0.5"'))
    o.append(path("M13,22 C12,18 13,15 16,14 C15,17 16,19 17,21 Z", "#3fae3a", INK3, 1.0))
    o.append(path("M15.5,14.6 C15,11 17,8.6 20,8", "none", "#2c7a1c", 1.8))
    o.append(path("M31,6 L25,17 L30,17 L26,27 L37,13 L31.5,13 L35,6 Z", "#ffe34d", "#c98a00", 1.0))
    return "".join(o)


def paprika(D):
    """Páprica-Foguete: pote laranja com um foguete no rótulo (menos 6 horas)."""
    rocket = (path("M24,23.6 C26.6,25.6 27,29.4 26,33 L22,33 C21,29.4 21.4,25.6 24,23.6 Z", "#ffffff", INK3, 0.8)
              + C(24, 28.2, 1.3, "#5bb8ff", INK3, 0.5)
              + path("M22,31 L19.8,34.6 L22.2,33.6 Z M26,31 L28.2,34.6 L25.8,33.6 Z", "#e0303a", INK3, 0.6)
              + path("M22.8,33.4 L24,37.2 L25.2,33.4 Z", "#ffb400", None))
    o = [_jar(D, "#f07a1a", "#e0303a", rocket)]
    for (x, y, r) in [(9, 10, 2.4), (40, 9, 3.0), (41, 26, 2.0)]:
        o.append(_sparkle(x, y, r))
    return "".join(o)


def instant(D):
    """Tempero Instantâneo: pote dourado com um relógio no rótulo e brilhos (pronto na hora)."""
    clock = (C(24, 30, 5.2, "#ffffff", INK3, 0.9)
             + path("M24,26.6 V30 L26.6,31.6", "none", INK3, 1.2)
             + path("M22.6,24.2 h2.8", "none", INK3, 1.4))
    o = [_jar(D, "#ffcf33", "#b06bff", clock)]
    for (x, y, r) in [(8, 12, 3.0), (40, 8, 2.4), (42, 24, 2.8), (8, 30, 2.0)]:
        o.append(_sparkle(x, y, r))
    return "".join(o)


def herbs(D):
    """Ervas Salva-Prato: maço de ervas verdes amarrado com barbante e uma cruz de socorro (recupera o prato estragado)."""
    o = [_shadow(23, 41, 12)]
    for (x0, x1, c) in [(22, 13, "#2c7a1c"), (23, 23, "#3fae3a"), (24, 33, "#2c7a1c"), (23, 18, "#5cc23a"), (24, 28, "#5cc23a")]:
        o.append(path(f"M{x0},39 Q{(x0 + x1) / 2},{26} {x1},{12}", "none", "#4a6a2a", 1.4))
        for t in (0.35, 0.6, 0.85):
            lx = x0 + (x1 - x0) * t
            ly = 39 - 27 * t
            o.append(E(lx - 2.6, ly, 3.4, 1.7, c, INK3, 0.6, extra=f'transform="rotate(-35 {f(lx - 2.6)} {f(ly)})"'))
            o.append(E(lx + 2.6, ly - 1, 3.4, 1.7, tint(c, 0.15), INK3, 0.6, extra=f'transform="rotate(35 {f(lx + 2.6)} {f(ly - 1)})"'))
    o.append(path("M18.5,32 C21,33.6 25.5,33.6 28.5,32 L28.5,35 C25.5,36.6 21,36.6 18.5,35 Z", "#d9a066", INK3, 0.9))
    o.append(C(36.5, 31, 6.4, "#ffffff", INK3, 1.0))
    o.append(path("M36.5,27.4 V34.6 M32.9,31 H40.1", "none", "#e0303a", 2.6))
    return "".join(o)


SPICES = {"sal": salt, "pimenta": pepper, "paprica": paprika, "instantaneo": instant, "ervas": herbs}


def spice(D, kind, cx, cy, size=48):
    s = size / 48.0
    return g(SPICES[kind](D), f"translate({f(cx - 24 * s)},{f(cy - 26 * s)}) scale({f(s)})")
