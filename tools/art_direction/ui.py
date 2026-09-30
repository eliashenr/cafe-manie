"""Ícones cheios com contorno (estilo cartoon original) e miniaturas de itens."""
from svgkit import *
from scene import table, chair, plant, jukebox, stove, counter, pastry_case


def svg(w, h, body, vb=None, label=None):
    vb = vb or f"0 0 {w} {h}"
    aria = f' role="img" aria-label="{label}"' if label else ' aria-hidden="true"'
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{vb}"{aria}>{body}</svg>'


S = f'stroke="{INK}" stroke-width="2.2" stroke-linejoin="round" stroke-linecap="round"'


def icon(name, size=40):
    b = ""
    if name == "loja":
        b = (f'<rect x="7" y="18" width="26" height="16" rx="2" fill="#fff4df" {S}/>'
             f'<rect x="15" y="23" width="10" height="11" fill="#a8643a" {S}/>'
             f'<path d="M5,12 h30 l-2,7 q-2.2,3 -4.5,0 q-2.3,3 -4.5,0 q-2.2,3 -4.5,0 q-2.3,3 -4.5,0 q-2.2,3 -4.5,0 z" fill="#e2503f" {S}/>'
             f'<path d="M11.5,12 v7 M20,12 v7 M28.5,12 v7" stroke="#fff4df" stroke-width="3"/>'
             f'<rect x="8" y="6" width="24" height="6" rx="2" fill="#6b3f26" {S}/>')
    elif name == "decorar":
        b = (f'<rect x="6" y="6" width="22" height="10" rx="3" fill="#5fc3a4" {S}/>'
             f'<path d="M28,11 h4 v9 h-12 v5" fill="none" {S}/>'
             f'<rect x="17" y="25" width="6" height="11" rx="2" fill="#a8643a" {S}/>'
             f'<path d="M9,9 h10" stroke="#c8f5e2" stroke-width="2.4" stroke-linecap="round"/>')
    elif name == "cardapio":
        b = (f'<path d="M20,11 q-7,-5 -14,-2 v22 q7,-3 14,2 q7,-5 14,-2 v-22 q-7,-3 -14,2 z" fill="#fff4df" {S}/>'
             f'<path d="M20,11 v22" {S}/>'
             f'<path d="M10,15 h6 M10,20 h6 M24,15 h6 M24,20 h6" stroke="#a8643a" stroke-width="2" stroke-linecap="round"/>'
             f'<path d="M26,26 q2,-6 4,0 z" fill="#e2503f" {S}/>')
    elif name == "missoes":
        b = (f'<rect x="8" y="7" width="24" height="29" rx="3" fill="#fff4df" {S}/>'
             f'<rect x="14" y="4" width="12" height="6" rx="2" fill="#a8643a" {S}/>'
             f'<path d="M13,18 l3,3 l5,-6" fill="none" stroke="#5da84e" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>'
             f'<path d="M13,29 h14" stroke="#c9b89c" stroke-width="2.4" stroke-linecap="round"/><path d="M24,19 h4" stroke="#c9b89c" stroke-width="2.4" stroke-linecap="round"/>')
    elif name == "conquistas":
        b = (f'<path d="M12,7 h16 v9 q0,9 -8,9 q-8,0 -8,-9 z" fill="#f4c542" {S}/>'
             f'<path d="M12,10 h-5 q0,8 6,8 M28,10 h5 q0,8 -6,8" fill="none" {S}/>'
             f'<rect x="17" y="25" width="6" height="5" fill="#d98e3f" {S}/>'
             f'<rect x="11" y="30" width="18" height="5" rx="1.5" fill="#6b3f26" {S}/>'
             f'<path d="M16,11 v5" stroke="#fff6c8" stroke-width="2.4" stroke-linecap="round"/>')
    elif name == "presentes":
        b = (f'<rect x="7" y="17" width="26" height="18" rx="2" fill="#c7355a" {S}/>'
             f'<rect x="5" y="12" width="30" height="7" rx="2" fill="#e2503f" {S}/>'
             f'<path d="M20,12 v23" stroke="#f4c542" stroke-width="4"/>'
             f'<path d="M20,12 q-9,-9 -10,-2 q1,3 10,2 q9,1 10,-2 q-1,-7 -10,2 z" fill="#f4c542" {S}/>')
    elif name == "amigos":
        b = (f'<circle cx="14" cy="15" r="6" fill="#f6d3b3" {S}/><path d="M4,33 q0,-10 10,-10 q10,0 10,10 z" fill="#5fc3a4" {S}/>'
             f'<circle cx="27" cy="14" r="5.5" fill="#c98a5e" {S}/><path d="M22,31 q1,-9 6,-9 q8,0 8,9 z" fill="#f4c542" {S}/>')
    elif name == "mais":
        b = f'<path d="M20,11 v18 M11,20 h18" stroke="#ffffff" stroke-width="4.5" stroke-linecap="round"/>'
    elif name == "zoom_in":
        b = f'<circle cx="17" cy="17" r="9" fill="#fff4df" {S}/><path d="M24,24 l8,8" {S}/><path d="M13,17 h8 M17,13 v8" {S}/>'
    elif name == "zoom_out":
        b = f'<circle cx="17" cy="17" r="9" fill="#fff4df" {S}/><path d="M24,24 l8,8" {S}/><path d="M13,17 h8" {S}/>'
    elif name == "musica":
        b = f'<path d="M15,28 v-17 l14,-3 v17" fill="none" {S}/><circle cx="12" cy="28" r="4" fill="#6b3f26" {S}/><circle cx="26" cy="25" r="4" fill="#6b3f26" {S}/>'
    elif name == "som":
        b = f'<path d="M8,16 h6 l8,-6 v20 l-8,-6 h-6 z" fill="#fff4df" {S}/><path d="M27,14 q4,6 0,12 M31,11 q7,9 0,18" fill="none" {S}/>'
    elif name == "tela":
        b = f'<path d="M8,15 v-7 h7 M25,8 h7 v7 M32,25 v7 h-7 M15,32 h-7 v-7" fill="none" {S}/>'
    elif name == "fechar":
        b = f'<path d="M12,12 l16,16 M28,12 l-16,16" stroke="#ffffff" stroke-width="4.5" stroke-linecap="round"/>'
    elif name == "flor":
        b = (''.join(f'<circle cx="{f(20+7*math.cos(a))}" cy="{f(18+7*math.sin(a))}" r="5.5" fill="#f08aa6" {S}/>' for a in [i*math.tau/5 - math.pi/2 for i in range(5)])
             + f'<circle cx="20" cy="18" r="4.5" fill="#f4c542" {S}/><path d="M20,26 v10" stroke="#5da84e" stroke-width="3" stroke-linecap="round"/>')
    elif name == "cadeado":
        b = f'<rect x="10" y="18" width="20" height="16" rx="3" fill="#f4c542" {S}/><path d="M14,18 v-4 a6,6 0 0 1 12,0 v4" fill="none" {S}/><circle cx="20" cy="26" r="2.2" fill="{INK}"/>'
    elif name == "seta_esq":
        b = f'<path d="M24,10 l-10,10 l10,10" fill="none" stroke="#ffffff" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>'
    elif name == "seta_dir":
        b = f'<path d="M16,10 l10,10 l-10,10" fill="none" stroke="#ffffff" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>'
    elif name == "piso":
        b = (f'<path d="M20,6 l15,8 l-15,8 l-15,-8 z" fill="#f4e6c8" {S}/><path d="M20,6 l7.5,4 l-7.5,4 l-7.5,-4 z M20,14 l7.5,4 l-7.5,4 l-7.5,-4 z" fill="#c7473d"/>'
             f'<path d="M5,14 v6 l15,8 l15,-8 v-6" fill="none" {S}/><path d="M20,22 v6" {S}/>')
    elif name == "parede":
        b = (f'<rect x="7" y="8" width="26" height="24" rx="2" fill="#f7ecd4" {S}/><path d="M7,23 h26" {S}/>'
             f'<rect x="7" y="23" width="26" height="9" fill="#8a5534" {S}/><rect x="14" y="11" width="12" height="9" rx="1" fill="#8fd0f0" {S}/>')
    elif name == "estrela":
        pts_ = []
        for i in range(10):
            a = -math.pi / 2 + i * math.pi / 5
            r = 15 if i % 2 == 0 else 6.5
            pts_.append((20 + r * math.cos(a), 21 + r * math.sin(a)))
        b = f'<polygon points="{pts(pts_)}" fill="#f4c542" {S}/>'
    return svg(size, size, b, "0 0 40 40")


def item_preview(kind, size=112):
    """Miniatura isométrica de um item da loja, centrada."""
    iso = Iso(0, 0, 72, 36)
    body = ""
    if kind == "mesa":
        body = table(iso, 0, 0, "#e2503f")
    elif kind == "mesa_menta":
        body = table(iso, 0, 0, "#5fc3a4")
    elif kind == "cadeira":
        body = chair(iso, 0, 0, "R")
    elif kind == "planta":
        body = plant(iso, 0, 0, big=True)
    elif kind == "jukebox":
        body = jukebox(iso, 0, 0)
    elif kind == "fogao":
        body = stove(iso, 0, 0, "#e2503f")
    elif kind == "balcao":
        body = counter(iso, 0, 0, ["bolo", "pao"])
    elif kind == "vitrine":
        body = pastry_case(iso, 0, 0)
    elif kind == "luminaria":
        c = iso.center(0, 0)
        body = (f'<ellipse cx="{f(c[0])}" cy="{f(c[1])}" rx="14" ry="6" fill="#6b3f26" stroke="{INK}" stroke-width="1.5"/>'
                f'<rect x="{f(c[0]-2.5)}" y="{f(c[1]-62)}" width="5" height="62" fill="#6b3f26" stroke="{INK}" stroke-width="1.3"/>'
                f'<path d="M{f(c[0]-16)},{f(c[1]-56)} l6,-20 h20 l6,20 z" fill="#f4c542" stroke="{INK}" stroke-width="1.6"/>'
                f'<ellipse cx="{f(c[0])}" cy="{f(c[1]-52)}" rx="22" ry="7" fill="#fff0b8" opacity="0.6"/>')
    elif kind == "vaso":
        c = iso.center(0, 0)
        body = (f'<path d="M{f(c[0]-11)},{f(c[1]-20)} h22 l-4,20 h-14 z" fill="#5fc3a4" stroke="{INK}" stroke-width="1.6"/>'
                + ''.join(f'<circle cx="{f(c[0]+dx)}" cy="{f(c[1]+dy)}" r="6" fill="{col}" stroke="{INK}" stroke-width="1.3"/><circle cx="{f(c[0]+dx)}" cy="{f(c[1]+dy)}" r="2" fill="#f4c542"/>'
                          for dx, dy, col in [(-9, -30, "#e2503f"), (8, -32, "#f08aa6"), (0, -42, "#c7355a"), (-2, -26, "#fff4df")]))
    elif kind == "estante":
        body = iso.box(0.1, 0.3, 1.8, 0.4, 70, "#8a5534")
        for i, col in enumerate(["#e2503f", "#5fc3a4", "#f4c542", "#3d5a80", "#c7355a", "#5da84e"]):
            p = iso.v(0.3 + i * 0.25, 0.7, 20 + (i % 2) * 26)
            body += f'<rect x="{f(p[0])}" y="{f(p[1]-16)}" width="6" height="16" fill="{col}" stroke="{INK}" stroke-width="1"/>'
    # enquadra: a célula (0,0) vai de x -36..36 e y 0..36; objetos sobem até ~80px
    tall = {"planta", "jukebox", "luminaria", "vaso", "vitrine"}
    if kind == "estante":
        vb = "-36 -86 118 118"
    elif kind in tall:
        vb = "-40 -78 80 100"
    else:
        vb = "-38 -52 76 88"
    return svg(size, size, body, vb)


def head(skin, hair_color, style, size=48, hat=False):
    body = person(0, 0, skin, hair_color, style, "#5fc3a4", chef_hat=hat)
    return svg(size, size, body, "-19 -66 38 38" if not hat else "-20 -80 40 50")
