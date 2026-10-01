"""Peças da interface v3 para o jogo: ícones, botões quadrados com símbolo, medalhões, fitas e listras.

O texto fica de fora: o jogo escreve por cima, com a fonte dele, e assim os números mudam e continuam nítidos.
Tudo na caixa 64x64 dos ícones do canvas (centro em 32,32), menos fitas e listras.
"""
from icons3 import *  # noqa: F401,F403
from icons3 import glyph as _canvas_glyph, _gloss
from hud3 import medallion, ribbon, portrait, CHEF_BIA

GLYPH_STROKE = 'fill="none" stroke="#ffffff" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"'


def glyph(kind):
    """Símbolos brancos dos botões: os do canvas e os que o jogo precisa a mais."""
    if kind == "mute":
        return ('<path d="M12,26 h9 l11,-9 v30 l-11,-9 h-9 Z" fill="#ffffff"/>'
                f'<path d="M40,24 L54,40 M54,24 L40,40" {GLYPH_STROKE}/>')
    if kind == "move":
        return (f'<path d="M32,10 V54 M10,32 H54" {GLYPH_STROKE}/>'
                '<path d="M32,6 l7,9 h-14 Z M32,58 l7,-9 h-14 Z M6,32 l9,7 v-14 Z M58,32 l-9,7 v-14 Z" fill="#ffffff"/>')
    if kind == "store":
        return (f'<path d="M12,24 h40 v26 a3,3 0 0,1 -3,3 h-34 a3,3 0 0,1 -3,-3 Z" {GLYPH_STROKE}/>'
                f'<path d="M8,16 h48 v8 h-48 Z M26,33 h12" {GLYPH_STROKE}/>')
    if kind == "sell":
        return (f'<circle cx="32" cy="32" r="21" {GLYPH_STROKE}/>'
                '<path d="M38,22 c-2,-3 -12,-4 -12,2 c0,7 13,4 13,11 c0,6 -11,6 -14,2 M32,16 v6 M32,42 v6" '
                'fill="none" stroke="#ffffff" stroke-width="4.5" stroke-linecap="round"/>')
    if kind == "serve":
        return ('<path d="M10,40 h44 a22,22 0 0,0 -44,0 Z" fill="#ffffff"/>'
                f'<path d="M6,46 h52 M32,14 v4" {GLYPH_STROKE}/>')
    return _canvas_glyph(kind)


def square_button(D, kind, color="blue"):
    """Botão quadrado brilhante (como o do canvas) na caixa 64x64."""
    pal = {"blue": ("#5bb8ff", "#1f6fd1", "#15509c"), "green": ("#7ee85a", "#26a93a", "#177a28"),
           "orange": ("#ffc15a", "#f07b00", "#b85a00"), "red": ("#ff8a8a", "#e0303a", "#a01a24")}[color]
    r = 12
    o = [f'<rect x="3" y="6" width="58" height="58" rx="{r}" fill="{pal[2]}"/>']
    o.append(f'<rect x="3" y="3" width="58" height="56" rx="{r}" fill="{D.lin([(0, pal[0]), (1, pal[1])])}" stroke="{pal[2]}" stroke-width="2"/>')
    o.append(f'<path d="M9,{r+1} a{r-4},{r-4} 0 0,1 {r-4},{-(r-4)} h{58-2*r} a{r-4},{r-4} 0 0,1 {r-4},{r-4} v6 h-50 Z" fill="#ffffff" opacity="0.3"/>')
    o.append(f'<g transform="translate(32,31) scale(0.62) translate(-32,-32)">{glyph(kind)}</g>')
    return "".join(o)


def padlock(D):
    o = [path("M20,30 v-8 a12,12 0 0,1 24,0 v8", "none", OL, 6.0)]
    o.append(path("M20,30 v-8 a12,12 0 0,1 24,0 v8", "none", "#c9d3de", 3.0))
    o.append(f'<rect x="13" y="29" width="38" height="28" rx="6" fill="{D.lin([(0, "#ffd23f"), (1, "#f08c00")])}" stroke="{OL}" stroke-width="2.2"/>')
    o.append(C(32, 41, 4, OL, None) + path("M32,43 v7", "none", OL, 3.2))
    o.append(_gloss("M17,32 h12 v4 h-12 Z", 0.5))
    return "".join(o)


def medallion_missions(D):
    bia = f'<g transform="translate(32,41)">{portrait(D, CHEF_BIA, hat="chef", scale=0.6)}</g>'
    return medallion(D, 32, 32, bia, "#ffb400")


def medallion_gift(D):
    return medallion(D, 32, 32, place(gift(D), 32, 32, 46), "#ff5fa2")


def medallion_trophy(D):
    return medallion(D, 32, 32, place(trophy(D), 32, 32, 44), "#8fe06a")


def ribbon_band(D, width, color):
    """Fita sem texto, centrada em x = 0 e com o topo em y = 0."""
    return ribbon(D, 0, 0, "", color, w=width)


def stripes_tile(size, light, dark, period=16):
    """Listras diagonais que emendam com elas mesmas (o período divide o lado)."""
    o = [f'<rect x="0" y="0" width="{size}" height="{size}" fill="{light}"/>']
    half = period / 2
    a = -size
    while a < 2 * size:
        o.append(P([(a, 0), (a + half, 0), (a + half - size, size), (a - size, size)], dark, None))
        a += period
    return f'<svg x="0" y="0" width="{size}" height="{size}" overflow="hidden">{"".join(o)}</svg>'


ICONS = {
    "moeda": coin, "estrela_chef": chef_star, "flor": flower, "sorriso": smiley, "estrela": star,
    "estrela_vazia": lambda D: star(D, "#d9e3f0", "#aab8cc"), "presente": gift, "trofeu": trophy,
    "prancheta": clipboard, "loja": shop_house, "rolo": roller, "expandir": expand, "livro": book,
    "bolo": cake, "martelo": hammer, "cadeado": padlock,
}

BUTTONS = [("zoom_in", "blue"), ("zoom_out", "blue"), ("sound", "blue"), ("mute", "blue"), ("gear", "blue"),
           ("rotate", "blue"), ("move", "blue"), ("store", "blue"), ("sell", "orange"), ("serve", "green"),
           ("check", "green"), ("close", "red"), ("left", "blue"), ("right", "blue")]

MEDALLIONS = {"missoes": medallion_missions, "presente": medallion_gift, "conquistas": medallion_trophy}

RIBBONS = {"missoes": (84, "#ff4d6d"), "presente": (88, "#b06bff"), "conquistas": (106, "#26a93a")}

STRIPES = {"xp": ("#ffe34d", "#ffb400"), "beleza": ("#ffa3cf", "#ff5fa2")}
