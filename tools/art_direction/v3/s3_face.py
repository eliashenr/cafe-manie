import sys
from people3 import *

from prev import out


def page(svg, bg="#eaf6ff"):
    return f'<!doctype html><html><head><meta charset="utf-8"><style>body{{margin:0;background:{bg}}}</style></head><body>{svg}</body></html>'

CAST = [
    dict(skin="clara", hair=("rabo", "castanho"), top=("blusa", "#ff4d6d"), bottom=("calca", "#3b6fd6"), lash=True, iris="#3b7fd9"),
    dict(skin="negra", hair=("black", "preto"), top=("camiseta", "#ffc928"), bottom=("calca", "#2fae4e"), lash=True, earrings="#ffc928"),
    dict(skin="morena", hair=("topete", "castanho_escuro"), top=("camisa", "#35b8ff"), bottom=("calca", "#34495e"), iris="#6b4423"),
    dict(skin="clara", hair=("chanel", "ruivo"), top=("vestido", "#9b5cff"), bottom=("saia", "#9b5cff"), lash=True, freckles=True, iris="#2f9e62"),
    dict(skin="parda", hair=("bone", "preto"), top=("moletom", "#ff7a2f"), bottom=("calca", "#2b2b33"), cap="#2f7bff"),
    dict(skin="rosada", hair=("longo", "loiro"), top=("blusa", "#2fd1b5"), bottom=("saia", "#3d5a80"), lash=True, iris="#3b7fd9"),
    dict(skin="morena_clara", hair=("curto", "preto"), top=("camiseta", "#2fae4e"), bottom=("short", "#3b6fd6"), iris="#5a3a22"),
    dict(skin="clara", hair=("coque", "grisalho"), top=("blusa", "#ff5fa2"), bottom=("saia", "#6b4b8a"), lash=True, glasses="#7a4bd6"),
    dict(skin="morena", hair=("careca", "castanho_escuro"), top=("camisa", "#ffffff"), bottom=("calca", "#6b4423"), beard="castanho_escuro"),
    dict(skin="clara", hair=("franja", "castanho"), top=("regata", "#ff4d5e"), bottom=("short", "#2b8cff"), iris="#3b7fd9"),
    dict(skin="parda", hair=("moicano", "verde"), top=("camiseta", "#1d1d2b"), bottom=("calca", "#4a4a5e")),
]

if __name__ == "__main__":
    D = Defs()
    b = []
    x = 70
    for i, c in enumerate(CAST[:6]):
        b.append(person(D, x + i * 228, 540, 3.4, 1 if i % 2 == 0 else -1, **c))
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="580" viewBox="0 0 1400 580">{D.render()}{"".join(b)}</svg>'
    D2 = Defs()
    b2 = []
    for i, c in enumerate(CAST[6:]):
        b2.append(person(D2, 90 + i * 270, 540, 3.4, 1 if i % 2 == 0 else -1, **c))
    svg2 = f'<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="580" viewBox="0 0 1400 580">{D2.render()}{"".join(b2)}</svg>'
    open(out("face.html"), "w").write(page(svg + svg2))
    D3 = Defs()
    b3 = []
    exprs = ["feliz", "sorriso", "esperando", "bravo", "comendo"]
    for i, ex in enumerate(exprs):
        c = dict(CAST[i])
        b3.append(g(head(D3, c["skin"], c["hair"], ex, iris=c.get("iris", "#6a4424"), lash=c.get("lash", False)),
                    f"translate({130 + i*270},{700}) scale(6.2)"))
    svg3 = f'<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="360" viewBox="0 0 1400 360">{D3.render()}{"".join(b3)}</svg>'
    open(out("heads.html"), "w").write(page(svg3))
