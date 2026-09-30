"""Peças de desenho em SVG para a direção visual do Café Manie (arte original)."""
import math

INK = "#3b2316"        # contorno cartoon (marrom café escuro)
SKINS = ["#f6d3b3", "#e8b48f", "#c98a5e", "#8d5a3b", "#f2c9a0"]
PALETTE = {
    "espresso": "#3b2316", "chocolate": "#6b3f26", "canela": "#a8643a", "caramelo": "#d98e3f",
    "mel": "#f4c542", "creme": "#fff4df", "leite": "#fffaf0", "tomate": "#e2503f",
    "framboesa": "#c7355a", "menta": "#5fc3a4", "folha": "#5da84e", "grama": "#7cc36b",
    "ceu": "#8fd0f0", "asfalto": "#6f7278", "calcada": "#c9c4ba",
}


def f(v):
    return f"{v:.1f}".rstrip("0").rstrip(".")


def pts(points):
    return " ".join(f"{f(x)},{f(y)}" for x, y in points)


def poly(points, fill, stroke=INK, sw=1.6, extra=""):
    s = f' stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round"' if stroke else ""
    return f'<polygon points="{pts(points)}" fill="{fill}"{s} {extra}/>'


def shade(hex_color, amount):
    """amount < 0 escurece, > 0 clareia."""
    h = hex_color.lstrip("#")
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    if amount < 0:
        k = 1 + amount
        r, g, b = r * k, g * k, b * k
    else:
        r, g, b = r + (255 - r) * amount, g + (255 - g) * amount, b + (255 - b) * amount
    return "#%02x%02x%02x" % (int(r), int(g), int(b))


class Iso:
    def __init__(self, ox, oy, w=72, h=36):
        self.ox, self.oy, self.w, self.h = ox, oy, w, h

    def v(self, x, y, z=0):
        return (self.ox + (x - y) * self.w / 2, self.oy + (x + y) * self.h / 2 - z)

    def center(self, x, y, z=0):
        return self.v(x + 0.5, y + 0.5, z)

    def tile(self, x, y, fill, stroke=None, sw=1):
        p = [self.v(x, y), self.v(x + 1, y), self.v(x + 1, y + 1), self.v(x, y + 1)]
        return poly(p, fill, stroke, sw)

    def rect(self, x0, y0, x1, y1, fill, stroke=None, sw=1):
        p = [self.v(x0, y0), self.v(x1, y0), self.v(x1, y1), self.v(x0, y1)]
        return poly(p, fill, stroke, sw)

    def box(self, x, y, w, d, hgt, top, left=None, right=None, z=0, sw=1.6):
        left = left or shade(top, -0.18)
        right = right or shade(top, -0.32)
        T = [self.v(x, y, z + hgt), self.v(x + w, y, z + hgt), self.v(x + w, y + d, z + hgt), self.v(x, y + d, z + hgt)]
        L = [self.v(x, y + d, z), self.v(x + w, y + d, z), self.v(x + w, y + d, z + hgt), self.v(x, y + d, z + hgt)]
        R = [self.v(x + w, y + d, z), self.v(x + w, y, z), self.v(x + w, y, z + hgt), self.v(x + w, y + d, z + hgt)]
        return poly(L, left, sw=sw) + poly(R, right, sw=sw) + poly(T, top, sw=sw)


# --- Comida (ícones originais) ---------------------------------------------------

def food(kind, cx, cy, s=1.0):
    """Um prato pequeno centrado em (cx, cy)."""
    g = [f'<g transform="translate({f(cx)},{f(cy)}) scale({s})">']
    if kind == "cafe":
        g.append(f'<path d="M-7,-4 h14 l-2,10 a3,3 0 0 1 -3,2 h-4 a3,3 0 0 1 -3,-2 z" fill="{PALETTE["leite"]}" stroke="{INK}" stroke-width="1.4"/>')
        g.append(f'<ellipse cx="0" cy="-4" rx="7" ry="2.2" fill="#7a4526" stroke="{INK}" stroke-width="1.2"/>')
        g.append(f'<path d="M7,-1 q5,0 4,4 q-1,3 -5,2" fill="none" stroke="{INK}" stroke-width="1.4"/>')
        g.append(f'<path d="M-2,-9 q-2,-3 0,-6 M3,-9 q-2,-3 0,-6" fill="none" stroke="#ffffff" stroke-width="1.4" opacity="0.9"/>')
    elif kind == "pao":
        for dx, dy in [(-5, 1), (5, 1), (0, -4)]:
            g.append(f'<circle cx="{dx}" cy="{dy}" r="5.2" fill="#f2c14e" stroke="{INK}" stroke-width="1.3"/>')
            g.append(f'<circle cx="{dx-1.5}" cy="{dy-1.8}" r="1.4" fill="#fff0b8"/>')
    elif kind == "bolo":
        g.append(f'<path d="M-9,4 l9,-11 l9,11 z" fill="#f7a64d" stroke="{INK}" stroke-width="1.4" stroke-linejoin="round"/>')
        g.append(f'<path d="M-6,0 h12" stroke="#fff4df" stroke-width="2"/>')
        g.append(f'<path d="M-2.5,-3 l2.5,-3 l2.5,3" fill="#6b3f26" stroke="none"/>')
        g.append(f'<circle cx="0" cy="-8" r="2.2" fill="{PALETTE["tomate"]}" stroke="{INK}" stroke-width="1"/>')
    elif kind == "coxinha":
        g.append(f'<path d="M0,-9 q9,7 7,12 q-7,4 -14,0 q-2,-5 7,-12 z" fill="#e7913c" stroke="{INK}" stroke-width="1.4"/>')
        g.append(f'<path d="M-3,1 q3,2 6,0" fill="none" stroke="#ffd08a" stroke-width="1.6"/>')
    elif kind == "lasanha":
        g.append(f'<rect x="-9" y="-6" width="18" height="11" rx="2" fill="#f4d27a" stroke="{INK}" stroke-width="1.4"/>')
        g.append(f'<path d="M-9,-2 h18 M-9,2 h18" stroke="{PALETTE["tomate"]}" stroke-width="2"/>')
    elif kind == "misto":
        g.append(f'<path d="M-9,3 l9,-9 l9,9 z" fill="#e9b872" stroke="{INK}" stroke-width="1.4" stroke-linejoin="round"/>')
        g.append(f'<path d="M-6,1 h12" stroke="#f9e27a" stroke-width="2.2"/>')
    g.append("</g>")
    return "".join(g)


def plate(cx, cy, kind, s=1.0):
    return (f'<ellipse cx="{f(cx)}" cy="{f(cy+3*s)}" rx="{f(12*s)}" ry="{f(5*s)}" fill="#ffffff" stroke="{INK}" stroke-width="1.2"/>'
            + food(kind, cx, cy - 2 * s, 0.75 * s))


# --- Balões -------------------------------------------------------------------------

def thought(cx, cy, kind):
    """Balão de pensamento com o pedido do cliente."""
    return (f'<g><ellipse cx="{f(cx)}" cy="{f(cy)}" rx="17" ry="15" fill="#ffffff" stroke="{INK}" stroke-width="1.6"/>'
            f'<circle cx="{f(cx-8)}" cy="{f(cy+17)}" r="3.4" fill="#ffffff" stroke="{INK}" stroke-width="1.3"/>'
            f'<circle cx="{f(cx-12)}" cy="{f(cy+23)}" r="2" fill="#ffffff" stroke="{INK}" stroke-width="1.1"/>'
            + food(kind, cx, cy + 1, 0.95) + "</g>")


def mood(cx, cy, state="feliz", r=9):
    """Carinha de humor do cliente (original: gota de café com rosto)."""
    colors = {"feliz": "#7fd06a", "esperando": "#f4c542", "bravo": "#e2503f"}
    c = colors[state]
    k = r / 9.0
    g = [f'<g transform="translate({f(cx)},{f(cy)}) scale({f(k)}) translate({f(-cx)},{f(-cy)})"><circle cx="{f(cx)}" cy="{f(cy)}" r="9" fill="{c}" stroke="{INK}" stroke-width="1.5"/>']
    g.append(f'<circle cx="{f(cx-3.2)}" cy="{f(cy-2)}" r="1.4" fill="{INK}"/><circle cx="{f(cx+3.2)}" cy="{f(cy-2)}" r="1.4" fill="{INK}"/>')
    if state == "feliz":
        g.append(f'<path d="M{f(cx-4)},{f(cy+2)} q4,4 8,0" fill="none" stroke="{INK}" stroke-width="1.5" stroke-linecap="round"/>')
    elif state == "esperando":
        g.append(f'<path d="M{f(cx-3.5)},{f(cy+3.5)} h7" stroke="{INK}" stroke-width="1.5" stroke-linecap="round"/>')
    else:
        g.append(f'<path d="M{f(cx-4)},{f(cy+4.5)} q4,-4 8,0" fill="none" stroke="{INK}" stroke-width="1.5" stroke-linecap="round"/>')
        g.append(f'<path d="M{f(cx-5.5)},{f(cy-5.5)} l4,1.8 M{f(cx+5.5)},{f(cy-5.5)} l-4,1.8" stroke="{INK}" stroke-width="1.4" stroke-linecap="round"/>')
    g.append("</g>")
    return "".join(g)


# --- Personagens cabeçudos (originais) ---------------------------------------------

def hair_shape(style, hx, hy, r, color):
    c = color
    s = f'fill="{c}" stroke="{INK}" stroke-width="1.5" stroke-linejoin="round"'
    if style == "curto":
        return f'<path d="M{f(hx-r)},{f(hy+1)} q0,-{f(r*1.25)} {f(r)},-{f(r*1.2)} q{f(r)},0 {f(r)},{f(r*1.2)} q-{f(r*0.45)},-{f(r*0.55)} -{f(r)},-{f(r*0.5)} q-{f(r*0.6)},0 -{f(r)},{f(r*0.5)} z" {s}/>'
    if style == "coque":
        return (f'<circle cx="{f(hx)}" cy="{f(hy-r-3)}" r="{f(r*0.45)}" {s}/>'
                + f'<path d="M{f(hx-r)},{f(hy+2)} q0,-{f(r*1.3)} {f(r)},-{f(r*1.2)} q{f(r)},0 {f(r)},{f(r*1.2)} q-{f(r*0.5)},-{f(r*0.5)} -{f(r)},-{f(r*0.45)} q-{f(r*0.5)},0 -{f(r)},{f(r*0.45)} z" {s}/>')
    if style == "longo":
        return (f'<path d="M{f(hx-r-1.5)},{f(hy+r*1.25)} q-2,-{f(r*2.2)} {f(r+1.5)},-{f(r*2.25)} q{f(r+3.5)},0 {f(r+1.5)},{f(r*2.25)} z" {s}/>')
    if style == "cacheado":
        out = ""
        for i in range(7):
            a = math.pi * (1.05 + i * 0.15)
            out += f'<circle cx="{f(hx + math.cos(a) * r * 0.95)}" cy="{f(hy + math.sin(a) * r * 0.95)}" r="{f(r*0.42)}" {s}/>'
        return out
    if style == "espetado":
        return (f'<path d="M{f(hx-r)},{f(hy)} l{f(r*0.2)},-{f(r*1.2)} l{f(r*0.4)},{f(r*0.45)} l{f(r*0.35)},-{f(r*0.8)} '
                f'l{f(r*0.35)},{f(r*0.75)} l{f(r*0.4)},-{f(r*0.7)} l{f(r*0.3)},{f(r*1.1)} q-{f(r)},-{f(r*0.3)} -{f(r*2)},{f(r*0.4)} z" {s}/>')
    if style == "bone":  # boné
        return (f'<path d="M{f(hx-r)},{f(hy-1)} q0,-{f(r*1.2)} {f(r)},-{f(r*1.2)} q{f(r)},0 {f(r)},{f(r*1.2)} z" {s}/>'
                + f'<path d="M{f(hx)},{f(hy-2)} h{f(r*1.35)} q2,0 1,2.5 h-{f(r*1.4)} z" {s}/>')
    return ""


def person(cx, cy, skin, hair_color, hair="curto", shirt="#5fc3a4", pants="#3d5a80",
           sitting=False, face="feliz", scale=1.0, apron=None, bowtie=False, tray=None, chef_hat=False, back_hair=False):
    """Personagem cabeçudo em pé (ou sentado) com os pés em (cx, cy)."""
    g = [f'<g transform="translate({f(cx)},{f(cy)}) scale({scale})">']
    g.append('<ellipse cx="0" cy="0" rx="11" ry="4" fill="#000000" opacity="0.18"/>')
    body_y = -30 if not sitting else -24
    if not sitting:
        g.append(f'<rect x="-7" y="-13" width="6" height="12" rx="2.5" fill="{pants}" stroke="{INK}" stroke-width="1.4"/>')
        g.append(f'<rect x="1" y="-13" width="6" height="12" rx="2.5" fill="{pants}" stroke="{INK}" stroke-width="1.4"/>')
    else:
        g.append(f'<rect x="-8" y="-9" width="16" height="7" rx="3" fill="{pants}" stroke="{INK}" stroke-width="1.4"/>')
    g.append(f'<rect x="-10" y="{body_y}" width="20" height="19" rx="7" fill="{shirt}" stroke="{INK}" stroke-width="1.5"/>')
    if apron:
        g.append(f'<path d="M-6,{body_y+5} h12 v13 q-6,3 -12,0 z" fill="{apron}" stroke="{INK}" stroke-width="1.2"/>')
    if bowtie:
        g.append(f'<path d="M-4,{body_y+2} l4,2 l4,-2 v4 l-4,-2 l-4,2 z" fill="{PALETTE["tomate"]}" stroke="{INK}" stroke-width="1"/>')
    # braços
    g.append(f'<rect x="-14" y="{body_y+3}" width="6" height="12" rx="3" fill="{shirt}" stroke="{INK}" stroke-width="1.3"/>')
    if tray:
        g.append(f'<rect x="8" y="{body_y-1}" width="6" height="11" rx="3" fill="{shirt}" stroke="{INK}" stroke-width="1.3" transform="rotate(-35 11 {body_y+4})"/>')
        g.append(f'<ellipse cx="17" cy="{body_y-4}" rx="12" ry="3.5" fill="#d9dde2" stroke="{INK}" stroke-width="1.3"/>')
        g.append(food(tray, 17, body_y - 10, 0.7))
    else:
        g.append(f'<rect x="8" y="{body_y+3}" width="6" height="12" rx="3" fill="{shirt}" stroke="{INK}" stroke-width="1.3"/>')
    # cabeça grande
    hy = body_y - 13
    r = 14
    if back_hair or hair == "longo":
        g.append(hair_shape("longo", 0, hy, r, hair_color))
    g.append(f'<circle cx="0" cy="{hy}" r="{r}" fill="{skin}" stroke="{INK}" stroke-width="1.6"/>')
    g.append(f'<ellipse cx="-4.5" cy="{hy+1}" rx="1.7" ry="2.3" fill="{INK}"/><ellipse cx="4.5" cy="{hy+1}" rx="1.7" ry="2.3" fill="{INK}"/>')
    g.append(f'<circle cx="-4" cy="{hy+0.2}" r="0.6" fill="#ffffff"/><circle cx="5" cy="{hy+0.2}" r="0.6" fill="#ffffff"/>')
    g.append(f'<ellipse cx="-8" cy="{hy+5}" rx="2.4" ry="1.5" fill="#f08a7a" opacity="0.55"/><ellipse cx="8" cy="{hy+5}" rx="2.4" ry="1.5" fill="#f08a7a" opacity="0.55"/>')
    if face == "feliz":
        g.append(f'<path d="M-3.5,{hy+6} q3.5,3.5 7,0" fill="none" stroke="{INK}" stroke-width="1.4" stroke-linecap="round"/>')
    elif face == "bravo":
        g.append(f'<path d="M-3.5,{hy+8} q3.5,-3 7,0" fill="none" stroke="{INK}" stroke-width="1.4" stroke-linecap="round"/>')
        g.append(f'<path d="M-7,{hy-4} l4,1.5 M7,{hy-4} l-4,1.5" stroke="{INK}" stroke-width="1.4" stroke-linecap="round"/>')
    else:
        g.append(f'<path d="M-2.5,{hy+7} h5" stroke="{INK}" stroke-width="1.4" stroke-linecap="round"/>')
    if hair != "longo":
        g.append(hair_shape(hair, 0, hy, r, hair_color))
    else:
        g.append(f'<path d="M-{r},{hy-1} q2,-{r} {r},-{r} q{r-2},0 {r},{r} q-5,-4 -{r},-3 q-{r-6},-1 -{r},3 z" fill="{hair_color}" stroke="{INK}" stroke-width="1.5"/>')
    if chef_hat:
        g.append(f'<path d="M-9,{hy-10} q-7,-9 1,-13 q3,-7 9,-2 q7,-5 9,3 q6,4 -1,12 z" fill="#ffffff" stroke="{INK}" stroke-width="1.5"/>')
        g.append(f'<rect x="-9" y="{hy-12}" width="18" height="5" rx="1.5" fill="#ffffff" stroke="{INK}" stroke-width="1.4"/>')
    g.append("</g>")
    return "".join(g)


# --- Ícones da interface (traço + preenchimento, originais) ------------------------

def coin(cx, cy, r=13):
    return (f'<g><circle cx="{f(cx)}" cy="{f(cy)}" r="{r}" fill="#f4c542" stroke="{INK}" stroke-width="1.8"/>'
            f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r*0.68)}" fill="none" stroke="#c9912a" stroke-width="1.6"/>'
            f'<path d="M{f(cx+r*0.28)},{f(cy-r*0.3)} a{f(r*0.38)},{f(r*0.38)} 0 1 0 0,{f(r*0.6)}" fill="none" stroke="#8a5a17" stroke-width="2.2" stroke-linecap="round"/>'
            f'<ellipse cx="{f(cx-r*0.4)}" cy="{f(cy-r*0.45)}" rx="{f(r*0.25)}" ry="{f(r*0.14)}" fill="#fff6c8" transform="rotate(-35 {f(cx-r*0.4)} {f(cy-r*0.45)})"/></g>')


def bean(cx, cy, r=13):
    """Moeda premium: grão de café verde-menta brilhante."""
    return (f'<g transform="rotate(-25 {f(cx)} {f(cy)})"><ellipse cx="{f(cx)}" cy="{f(cy)}" rx="{f(r*0.8)}" ry="{r}" fill="#46b88f" stroke="{INK}" stroke-width="1.8"/>'
            f'<path d="M{f(cx)},{f(cy-r*0.85)} q-{f(r*0.45)},{f(r*0.85)} 0,{f(r*1.7)}" fill="none" stroke="#1f6b50" stroke-width="2"/>'
            f'<ellipse cx="{f(cx-r*0.35)}" cy="{f(cy-r*0.4)}" rx="{f(r*0.15)}" ry="{f(r*0.3)}" fill="#c8f5e2"/></g>')
