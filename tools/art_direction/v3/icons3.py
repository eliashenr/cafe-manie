"""Ícones v3 desenhados do zero (caixa 64x64, centro em 32,32), com brilho e contorno escuro."""
from core3 import *

OL = "#2b2540"


def place(svg, x, y, size=64):
    s = size / 64.0
    return f'<g transform="translate({f(x - size / 2)},{f(y - size / 2)}) scale({f(s)})">{svg}</g>'


def _gloss(d, op=0.45):
    return path(d, "#ffffff", None, f'opacity="{op}"')


# --- Moedas e recursos ------------------------------------------------------------------

def coin(D):
    o = [C(32, 34, 25, D.lin([(0, "#ffd84a"), (1, "#e08a00")]), OL, 2.2)]
    o.append(C(32, 32, 25, D.rad([(0, "#fff6b0"), (0.5, "#ffd23f"), (1, "#f0a000")], 0.38, 0.32, 0.75), OL, 2.2))
    o.append(C(32, 32, 18, "none", "#ffb000", 2.4))
    o.append(C(32, 32, 18, "none", "#fff3a8", 1.0, 'transform="translate(-0.8,-0.8)"'))
    # xícara em relevo
    o.append(path("M22,26 h19 l-2.4,12.6 c-0.5,2.4 -2.4,3.6 -4.8,3.6 h-4.6 c-2.4,0 -4.3,-1.2 -4.8,-3.6 Z", "#f7a800", "#b36b00", 1.4))
    o.append(path("M41,28.4 c5,0 5,7.2 -0.4,7.4", "none", "#b36b00", 2.2))
    o.append(path("M27,22 q-2,-3 0,-5.4 M32,22 q-2,-3 0,-5.4", "none", "#b36b00", 1.6))
    o.append(_gloss("M14,26 C16,16 26,10 36,11 C27,13 20,18 17,27 Z", 0.6))
    return "".join(o)


def bean(D):
    o = [E(32, 34, 18, 25, D.lin([(0, "#3ed16a"), (1, "#138a3e")]), OL, 2.2, 'transform="rotate(28 32 34)"')]
    o.append(E(32, 32, 18, 25, D.rad([(0, "#b9ffb0"), (0.45, "#4fe07a"), (1, "#16a04a")], 0.35, 0.3, 0.8), OL, 2.2, 'transform="rotate(28 32 32)"'))
    o.append(path("M24,15 C36,22 26,40 40,50", "none", "#0f6a33", 3.0))
    o.append(path("M24,15 C36,22 26,40 40,50", "none", "#7df0a0", 1.0, 'transform="translate(1.4,-0.6)"'))
    o.append(_gloss("M20,22 C22,15 28,11 33,11 C28,14 24,19 22,25 Z", 0.7))
    return "".join(o)


def star(D, fill="#ffd23f", edge="#f08c00"):
    pts_ = []
    for i in range(10):
        a = math.radians(-90 + i * 36)
        rr = 27 if i % 2 == 0 else 12.5
        pts_.append((32 + rr * math.cos(a), 34 + rr * math.sin(a)))
    o = [P([(x + 1, y + 2) for (x, y) in pts_], edge, OL, 2.2)]
    o.append(P(pts_, D.rad([(0, "#fff7c2"), (0.5, fill), (1, edge)], 0.4, 0.35, 0.8), OL, 2.2))
    o.append(_gloss("M22,26 L30,24 L32,12 L34,22 Z", 0.55))
    return "".join(o)


def chef_star(D):
    """Selo de nível: estrela com chapéu de chef."""
    o = [star(D, "#ffcf2e", "#f07b00")]
    o.append(path("M22,34 C17,30 20,22 26,24 C27,18 37,18 38,24 C44,22 47,30 42,34 Z", D.lin([(0, "#ffffff"), (1, "#dfe7f2")]), OL, 1.8))
    o.append(path("M23,34 h19 v5 h-19 Z", "#ffffff", OL, 1.8))
    o.append(path("M28,24 v9 M36,24 v9", "none", "#c5d0de", 1.4))
    return "".join(o)


def flower(D, petal="#ff5fa2"):
    o = []
    for i in range(6):
        a = math.radians(i * 60 - 90)
        cx, cy = 32 + math.cos(a) * 13, 32 + math.sin(a) * 13
        o.append(C(cx, cy, 10, D.rad([(0, tint(petal, 0.6)), (0.6, petal), (1, shade(petal, 0.2))], 0.4, 0.35, 0.8), OL, 2.0))
    o.append(C(32, 32, 9.5, D.rad([(0, "#fff6a0"), (1, "#ffb400")], 0.4, 0.35, 0.8), OL, 2.0))
    o.append(C(29, 29, 3, "#ffffff", None, extra='opacity="0.7"'))
    return "".join(o)


def smiley(D, fill="#8df06a", edge="#2fae3a"):
    o = [C(32, 33, 25, D.rad([(0, tint(fill, 0.5)), (0.6, fill), (1, edge)], 0.4, 0.35, 0.75), OL, 2.2)]
    o.append(E(24, 28, 3.2, 4.4, OL, None) + E(40, 28, 3.2, 4.4, OL, None))
    o.append(path("M20,37 Q32,52 44,37 Q32,43 20,37 Z", "#7a1f2a", OL, 1.8))
    o.append(_gloss("M14,28 C15,18 24,11 33,11 C25,14 19,20 17,29 Z", 0.6))
    return "".join(o)


def gift(D, box="#ff4d6d", ribbon="#ffd23f"):
    o = [path("M12,30 h40 v24 a3,3 0 0,1 -3,3 h-34 a3,3 0 0,1 -3,-3 Z", D.lin([(0, box), (1, shade(box, 0.25))]), OL, 2.2)]
    o.append(path("M9,21 h46 v11 h-46 Z", D.lin([(0, tint(box, 0.25)), (1, box)]), OL, 2.2))
    o.append(path("M28,21 h8 v36 h-8 Z", D.lin([(0, tint(ribbon, 0.3)), (1, shade(ribbon, 0.15))]), OL, 1.8))
    o.append(path("M32,21 C24,8 12,12 18,19 C21,22 28,21 32,21 Z", ribbon, OL, 2.0))
    o.append(path("M32,21 C40,8 52,12 46,19 C43,22 36,21 32,21 Z", ribbon, OL, 2.0))
    o.append(_gloss("M12,23 h14 v3 h-14 Z", 0.5) + _gloss("M14,33 h4 v18 h-4 Z", 0.35))
    return "".join(o)


def trophy(D):
    o = [path("M20,12 h24 v12 c0,10 -5,16 -12,16 c-7,0 -12,-6 -12,-16 Z", D.lin([(0, "#fff08a"), (0.5, "#ffc928"), (1, "#e08a00")], 0, 0, 1, 0), OL, 2.2)]
    o.append(path("M20,16 c-9,0 -9,12 1,13 M44,16 c9,0 9,12 -1,13", "none", OL, 4.2))
    o.append(path("M20,16 c-9,0 -9,12 1,13 M44,16 c9,0 9,12 -1,13", "none", "#ffc928", 2.2))
    o.append(path("M28,40 h8 v7 h-8 Z", "#e0a000", OL, 1.8))
    o.append(path("M20,47 h24 l2,8 h-28 Z", D.lin([(0, "#8a5cff"), (1, "#5a2fd0")]), OL, 2.0))
    o.append(path("M26,50 h12", "none", "#ffd23f", 2.0))
    o.append(_gloss("M24,14 h5 v10 c0,5 1,8 3,10 c-5,-1 -8,-5 -8,-11 Z", 0.6))
    return "".join(o)


def clipboard(D):
    o = [path("M13,12 h38 a3,3 0 0,1 3,3 v42 a3,3 0 0,1 -3,3 h-38 a3,3 0 0,1 -3,-3 v-42 a3,3 0 0,1 3,-3 Z", D.lin([(0, "#ffb163"), (1, "#e2742a")]), OL, 2.2)]
    o.append(path("M16,17 h32 v38 h-32 Z", "#ffffff", OL, 1.6))
    o.append(path("M24,8 h16 v9 h-16 Z", D.lin([(0, "#dfe6ee"), (1, "#9aa6b3")]), OL, 1.8))
    for i, y in enumerate((26, 36, 46)):
        o.append(path(f"M20,{y} l3,3 l6,-6", "none", "#23b04a" if i < 2 else "#c9d3de", 2.6))
        o.append(path(f"M32,{y} h12", "none", "#9aa6b3", 2.4))
    return "".join(o)


def book(D):
    o = [path("M12,14 h34 a4,4 0 0,1 4,4 v38 h-34 a4,4 0 0,1 -4,-4 Z", D.lin([(0, "#ff5a6a"), (1, "#c81e3a")], 0, 0, 1, 1), OL, 2.2)]
    o.append(path("M16,52 h34 v5 h-34 a3,3 0 0,1 0,-5 Z", "#ffffff", OL, 1.8))
    o.append(path("M14,15 v38", "none", "#8a0f2a", 3.0))
    o.append(C(33, 33, 11, "#fff3e0", OL, 1.6))
    o.append(path("M28,26 v14 M26,26 v5 a2,2 0 0,0 4,0 v-5 M38,26 c-3,2 -3,7 0,8 v6", "none", "#9aa6b3", 1.8))
    o.append(_gloss("M17,17 h28 v3 h-28 Z", 0.4))
    return "".join(o)


def shop_house(D):
    o = [path("M12,30 h40 v26 h-40 Z", D.lin([(0, "#fff7e6"), (1, "#f0dcc0")]), OL, 2.2)]
    o.append(path("M26,40 h12 v16 h-12 Z", D.lin([(0, "#4aa3ff"), (1, "#1f6fd1")]), OL, 1.8))
    o.append(path("M15,36 h8 v8 h-8 Z M41,36 h8 v8 h-8 Z", "#bfe9ff", OL, 1.6))
    # toldo listrado
    for i in range(6):
        x0 = 8 + i * 8
        col = "#ff4d5e" if i % 2 == 0 else "#ffffff"
        o.append(path(f"M{x0},18 h8 v12 a4,4 0 0,1 -8,0 Z", col, OL, 1.6))
    o.append(path("M10,12 h44 l2,6 h-48 Z", "#ff4d5e", OL, 2.0))
    o.append(_gloss("M12,13 h40 v2 h-40 Z", 0.5))
    return "".join(o)


def roller(D):
    o = [path("M14,12 h30 a5,5 0 0,1 5,5 v6 a5,5 0 0,1 -5,5 h-30 a5,5 0 0,1 -5,-5 v-6 a5,5 0 0,1 5,-5 Z",
              D.lin([(0, "#6fe0ff"), (1, "#1f9ad1")]), OL, 2.2)]
    o.append(path("M49,19 h5 v14 h-22 v8", "none", OL, 4.2) + path("M49,19 h5 v14 h-22 v8", "none", "#c9d3de", 2.2))
    o.append(path("M28,40 h8 v18 a4,4 0 0,1 -8,0 Z", D.lin([(0, "#ffb163"), (1, "#d9601a")], 0, 0, 1, 0), OL, 2.0))
    o.append(path("M16,28 q2,8 -2,12 q6,-1 8,-8 Z", "#1f9ad1", OL, 1.4))
    o.append(_gloss("M13,14 h28 v4 h-28 Z", 0.55))
    return "".join(o)


def expand(D):
    o = []
    for (dx, dy, c) in [(0, 0, "#8fe06a"), (12, 6, "#6fd15a"), (-12, 6, "#6fd15a"), (0, 12, "#56c24a")]:
        cx, cy = 32 + dx, 28 + dy
        o.append(P([(cx, cy - 6), (cx + 12, cy), (cx, cy + 6), (cx - 12, cy)], c, OL, 1.8))
    for (x, y, a) in [(11, 17, 225), (53, 17, 315), (11, 51, 135), (53, 51, 45)]:
        o.append(g(path("M-7,-3.5 h7 v-5 l9,8.5 l-9,8.5 v-5 h-7 Z", D.lin([(0, "#fff08a"), (1, "#ffb400")]), OL, 1.8), f"translate({x},{y}) rotate({a})"))
    return "".join(o)


def mail(D):
    o = [path("M10,18 h44 a3,3 0 0,1 3,3 v28 a3,3 0 0,1 -3,3 h-44 a3,3 0 0,1 -3,-3 v-28 a3,3 0 0,1 3,-3 Z",
              D.lin([(0, "#ffffff"), (1, "#dbe6f2")]), OL, 2.2)]
    o.append(path("M8,20 L32,38 L56,20", "none", OL, 2.2))
    o.append(path("M8,50 L26,34 M56,50 L38,34", "none", "#9aa6b3", 1.6))
    o.append(path("M42,12 a8,8 0 1,1 0.1,0 Z", "#ff4d6d", OL, 1.6, 'transform="translate(8,6)"'))
    return "".join(o)


def cake(D):
    o = [path("M12,34 h40 v16 a4,4 0 0,1 -4,4 h-32 a4,4 0 0,1 -4,-4 Z", D.lin([(0, "#ffd9a8"), (1, "#f0a860")]), OL, 2.2)]
    o.append(path("M12,34 c0,-6 40,-6 40,0 c-3,4 -6,0 -8,4 c-3,4 -6,-1 -8,3 c-3,4 -7,-1 -9,3 c-3,3 -6,-2 -8,1 c-3,3 -6,-2 -7,-2 Z", "#ff8fb1", OL, 2.0))
    o.append(path("M16,44 h32", "none", "#e07a3a", 2.0, 'opacity="0.6"'))
    for x in (22, 32, 42):
        o.append(path(f"M{x-2},18 h4 v12 h-4 Z", "#4fc3ff", OL, 1.4))
        o.append(path(f"M{x},10 q3,4 0,7 q-3,-3 0,-7 Z", "#ffb400", OL, 1.2))
    o.append(_gloss("M15,36 h8 v12 h-8 Z", 0.3))
    return "".join(o)


def hammer(D):
    o = [path("M30,26 l6,-6 l20,20 a4,4 0 0,1 0,6 a4,4 0 0,1 -6,0 Z", D.lin([(0, "#ffb163"), (1, "#c65a16")], 0, 0, 1, 1), OL, 2.0)]
    o.append(path("M10,20 l14,-14 l10,4 l6,6 l-6,6 l-6,-2 l-10,12 Z", D.lin([(0, "#e6ecf3"), (1, "#8f9aa7")], 0, 0, 1, 1), OL, 2.2))
    return "".join(o)


# --- Glifos brancos para botões quadrados azuis ----------------------------------------

def glyph(kind):
    w = 'fill="none" stroke="#ffffff" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"'
    if kind == "zoom_in":
        return f'<circle cx="28" cy="28" r="13" {w}/><path d="M38,38 L50,50 M22,28 h12 M28,22 v12" {w}/>'
    if kind == "zoom_out":
        return f'<circle cx="28" cy="28" r="13" {w}/><path d="M38,38 L50,50 M22,28 h12" {w}/>'
    if kind == "full":
        return f'<path d="M14,24 v-10 h10 M40,14 h10 v10 M50,40 v10 h-10 M24,50 h-10 v-10" {w}/>'
    if kind == "eye":
        return (f'<path d="M10,32 C18,18 46,18 54,32 C46,46 18,46 10,32 Z" {w}/>'
                '<circle cx="32" cy="32" r="6" fill="#ffffff"/>')
    if kind == "music":
        return ('<path d="M24,44 V16 L48,11 V39" fill="none" stroke="#ffffff" stroke-width="5" stroke-linejoin="round"/>'
                '<ellipse cx="19" cy="45" rx="7" ry="5.5" fill="#ffffff"/><ellipse cx="43" cy="40" rx="7" ry="5.5" fill="#ffffff"/>')
    if kind == "sound":
        return (f'<path d="M12,26 h9 l11,-9 v30 l-11,-9 h-9 Z" fill="#ffffff"/>'
                f'<path d="M40,24 q6,8 0,16 M46,18 q11,14 0,28" {w}/>')
    if kind == "gear":
        teeth = "".join(f'<rect x="28" y="8" width="8" height="10" rx="2" fill="#ffffff" transform="rotate({a} 32 32)"/>' for a in range(0, 360, 45))
        return teeth + '<circle cx="32" cy="32" r="15" fill="#ffffff"/><circle cx="32" cy="32" r="6" fill="#2a7de1"/>'
    if kind == "left":
        return '<path d="M40,14 L20,32 L40,50 Z" fill="#ffffff"/>'
    if kind == "right":
        return '<path d="M24,14 L44,32 L24,50 Z" fill="#ffffff"/>'
    if kind == "first":
        return '<path d="M44,14 L26,32 L44,50 Z" fill="#ffffff"/><rect x="16" y="14" width="6" height="36" rx="2" fill="#ffffff"/>'
    if kind == "last":
        return '<path d="M20,14 L38,32 L20,50 Z" fill="#ffffff"/><rect x="42" y="14" width="6" height="36" rx="2" fill="#ffffff"/>'
    if kind == "plus":
        return '<path d="M32,14 V50 M14,32 H50" fill="none" stroke="#ffffff" stroke-width="9" stroke-linecap="round"/>'
    if kind == "check":
        return '<path d="M14,33 L27,46 L51,19" fill="none" stroke="#ffffff" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>'
    if kind == "rotate":
        return (f'<path d="M46,24 A16,16 0 1,0 48,38" {w}/><path d="M50,12 L50,26 L36,26 Z" fill="#ffffff"/>')
    if kind == "close":
        return '<path d="M18,18 L46,46 M46,18 L18,46" fill="none" stroke="#ffffff" stroke-width="8" stroke-linecap="round"/>'
    raise ValueError(kind)


def square_button(D, x, y, size, kind, color="blue"):
    """Botão quadrado brilhante (azul, verde, laranja ou vermelho) com glifo branco."""
    pal = {"blue": ("#5bb8ff", "#1f6fd1", "#15509c"), "green": ("#7ee85a", "#26a93a", "#177a28"),
           "orange": ("#ffc15a", "#f07b00", "#b85a00"), "red": ("#ff8a8a", "#e0303a", "#a01a24")}[color]
    s = size / 64.0
    r = 12
    o = [f'<rect x="3" y="6" width="58" height="58" rx="{r}" fill="{pal[2]}"/>']
    o.append(f'<rect x="3" y="3" width="58" height="56" rx="{r}" fill="{D.lin([(0, pal[0]), (1, pal[1])])}" stroke="{pal[2]}" stroke-width="2"/>')
    o.append(f'<path d="M9,{r+1} a{r-4},{r-4} 0 0,1 {r-4},{-(r-4)} h{58-2*r} a{r-4},{r-4} 0 0,1 {r-4},{r-4} v6 h-50 Z" fill="#ffffff" opacity="0.3"/>')
    o.append(f'<g transform="translate(32,31) scale(0.62) translate(-32,-32)">{glyph(kind)}</g>')
    return f'<g transform="translate({f(x - size/2)},{f(y - size/2)}) scale({f(s)})">{"".join(o)}</g>'
