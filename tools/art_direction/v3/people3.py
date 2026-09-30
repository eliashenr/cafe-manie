"""Personagens v3.

Cabeça redonda e centrada no pescoço (sem o 'corcunda' da v2), rosto levemente virado para o lado
em que o boneco olha, olhos de desenho com pálpebra, íris recortada, brilho e cílios, e cabelos em
mechas pontudas com sombra no rosto e reflexo em anel. Pés em (0, 0); cabeça com centro em (0, -84).
"""
from core3 import *

LINE = "#3a2326"

SKIN = {  # base, sombra, luz
    "clara": ("#ffe0cb", "#f0b99c", "#fff3ea"),
    "rosada": ("#ffd2bf", "#eba58c", "#fff0e8"),
    "morena_clara": ("#f6c7a0", "#dd9f74", "#ffe6cf"),
    "morena": ("#dfa472", "#c07f4e", "#f5c79c"),
    "parda": ("#b97849", "#985b31", "#d9a172"),
    "negra": ("#7f4e2e", "#5f351c", "#a5714a"),
}
HAIR = {  # base, sombra, brilho
    "preto": ("#2d2733", "#15111a", "#8a8299"),
    "castanho_escuro": ("#5a3120", "#351a10", "#b07a58"),
    "castanho": ("#8e5427", "#5f3413", "#e0a870"),
    "caramelo": ("#c27a38", "#8f5220", "#f5c27f"),
    "loiro": ("#ffd257", "#dda125", "#fff5c4"),
    "ruivo": ("#f2622a", "#bf3d14", "#ffb88a"),
    "grisalho": ("#d9d9e3", "#a3a3b5", "#ffffff"),
    "rosa": ("#ff78b4", "#dc3f88", "#ffd0e6"),
    "azul": ("#48a6ff", "#2168d0", "#c2e4ff"),
    "verde": ("#4fd16a", "#23964a", "#c8f5cf"),
}

HEAD = ("M-21,-86 C-21,-99 -12,-106.5 0,-106.5 C12,-106.5 21,-99 21,-86 C21,-76 18.5,-68 13,-64 "
        "C9.5,-61.5 4.5,-60.5 0,-60.5 C-4.5,-60.5 -9.5,-61.5 -13,-64 C-18.5,-68 -21,-76 -21,-86 Z")
FS = 1.4          # deslocamento do rosto para o lado em que o boneco olha
EYE_Y = -81.5
EYE_X = 8.3
EYE_W, EYE_H = 5.0, 6.3


# --- Cabelos -----------------------------------------------------------------------

def _ring(cx, cy, rx, ry, a0, a1, n, length, width):
    out = []
    for i in range(n):
        t = (i + 0.5) / n
        a = math.radians(a0 + (a1 - a0) * t)
        x, y = cx + rx * math.cos(a), cy + ry * math.sin(a)
        ln = length * (0.75 + 0.5 * math.sin(math.pi * t))
        out.append(leaf(x, y, math.degrees(a), ln, width))
    return out


def _afro(r=30.0, cy=-89.0, lobes=15, bump=4.2):
    d = []
    for i in range(lobes):
        a0 = math.tau * i / lobes - math.pi / 2
        a1 = math.tau * (i + 1) / lobes - math.pi / 2
        am = (a0 + a1) / 2
        p0 = (r * math.cos(a0), cy + r * 0.94 * math.sin(a0))
        p1 = (r * math.cos(a1), cy + r * 0.94 * math.sin(a1))
        c = ((r + bump) * math.cos(am), cy + (r + bump) * 0.94 * math.sin(am))
        if i == 0:
            d.append(f"M{f(p0[0])},{f(p0[1])}")
        d.append(f"Q{f(c[0])},{f(c[1])} {f(p1[0])},{f(p1[1])}")
    return " ".join(d) + " Z"


def hair_parts(style):
    """Partes do cabelo: back (atrás da cabeça), front (sobre a cabeça), hairline (linha que desenha
    o contorno quando front não tem traço), strands (fios escuros), shine (brilho), ears (mostra orelhas),
    long_back (mechas que descem atrás do corpo)."""
    H = dict(back=None, front=None, front_stroke=True, hairline=None, strands=[], shine=[], ears=True,
             long_back=None)
    if style == "curto":
        H["front"] = ("M-22.6,-79 C-25.4,-91 -23.6,-103.5 -14.5,-109.6 C-6.5,-115 6,-115.6 14.2,-111.4 "
                      "C21.6,-107.4 25.4,-99 24.8,-89 C24.5,-85 23.7,-81.4 22.5,-78.6 L20.1,-86 "
                      "Q18.2,-92.2 14.4,-94.6 Q12.4,-88.8 7.2,-85.8 Q6.2,-91.4 3,-95.2 Q-0.2,-89 -5.4,-86.4 "
                      "Q-6,-92 -8.4,-95.4 Q-12.4,-90 -17.6,-86.8 Q-17.4,-91.2 -19.4,-93 Q-21.4,-88 -20.6,-82.6 Z")
        H["strands"] = ["M4,-113 Q2.4,-104 3,-95.5", "M-6.5,-112.6 Q-7.6,-104 -8.4,-95.8",
                        "M13.4,-110 Q15.6,-102 14.4,-95", "M-15,-107 Q-18,-100 -19.2,-93.4"]
        H["shine"] = _ring(0, -88, 17, 17.5, 200, 300, 5, 7.5, 1.5)
    elif style == "franja":
        H["front"] = ("M-22.6,-78 C-25.6,-92 -22.6,-106 -11.8,-111.4 C-2.4,-116 10.2,-114.6 17.4,-108.4 "
                      "C23.6,-103 25.6,-94 24.6,-85 C24.2,-81.8 23.4,-79.4 22.4,-77.6 L20.2,-84.6 "
                      "Q19.4,-88.6 17,-89.4 Q15.6,-85.4 12.6,-83.6 Q12.2,-87.6 10,-89.8 Q8.2,-85.2 4.8,-83.4 "
                      "Q4.4,-88 2.2,-90.2 Q0,-85.6 -3.6,-83.6 Q-3.8,-88 -6.2,-90.2 Q-8.4,-85.6 -12,-84 "
                      "Q-12,-88.2 -14.4,-90.2 Q-16.4,-86.8 -19.6,-85.4 Q-21,-82 -20.6,-79.6 Z")
        H["strands"] = ["M2,-113.4 Q1,-101 2.2,-90", "M-8.8,-111.4 Q-7.8,-100 -6.2,-90.2",
                        "M11.8,-111.6 Q11.8,-100 10,-89.8", "M-17.2,-104 Q-15.8,-96 -14.4,-90.2"]
        H["shine"] = _ring(0, -90, 18, 17, 200, 305, 6, 7, 1.4)
    elif style == "topete":
        H["front"] = ("M-22.6,-79.4 C-25.4,-91 -24.4,-100 -19.4,-105.4 C-21.4,-110 -20.4,-115 -16.4,-117.6 "
                      "L-15.8,-113.6 C-13,-119.8 -6.6,-123.8 0.4,-124.4 L-2.4,-120.4 C4.6,-123.8 12.6,-122.6 17.6,-117.6 "
                      "L13.6,-116.6 C19.6,-114.4 23.4,-109 24.4,-102.6 C25.6,-97 25.4,-92 24.8,-88 C24.5,-84.6 23.7,-81.4 "
                      "22.5,-78.6 L20.1,-87.4 Q17.4,-94.4 12,-97.2 Q6,-99.6 0,-99 Q-6.2,-99.4 -11.2,-96.8 "
                      "Q-16.4,-93.4 -18.4,-89.2 Q-21,-86 -20.6,-82 Z")
        H["strands"] = ["M-17.4,-104.6 Q-12.4,-114.4 -2,-117.8", "M-12.6,-99.6 Q-5.4,-112 9.4,-116",
                        "M-5,-98.8 Q3,-108.4 16.4,-111.6", "M16.8,-104 Q20.6,-97 20.4,-89"]
        H["shine"] = [leaf(-8.4, -114.6, 205, 11, 2.0), leaf(0.6, -117.8, 192, 8, 1.5), leaf(-16, -104, 240, 8, 1.5)]
    elif style == "moicano":
        H["front"] = ("M-9,-96 C-10,-106 -9,-114 -6,-119 L-3,-127 L0.4,-118 L4,-129 L6.6,-117.6 L11,-126.4 L11.6,-114.4 "
                      "C12.8,-109 12.4,-102 10.6,-96 C4,-98.4 -3,-98.6 -9,-96 Z")
        H["strands"] = ["M0.4,-118 L1.2,-99", "M6.6,-117.6 L6.2,-99"]
        H["shine"] = [leaf(-3.6, -110, 265, 12, 1.6)]
    elif style == "rabo":
        H["back"] = ("M9,-106 C22,-114 34.4,-103 32.4,-87.4 C31,-77 33.4,-66 29.4,-54 C28.4,-50.6 26.4,-48 24.2,-46.6 "
                     "C25,-52 23.4,-57 21.4,-62.6 C19.2,-69 19.6,-78 18.6,-86 C17.4,-95 13.6,-100.6 9,-102 Z")
        H["front"] = ("M-22.6,-79.6 C-24.8,-94.6 -16.8,-108.6 -2.6,-110.8 C10.4,-112.8 21.6,-104.6 23.8,-92 "
                      "C24.4,-87.4 23.8,-82.2 22.5,-78.8 L20.4,-86.6 Q18,-94.2 12.2,-97.4 Q6.6,-99.6 1.2,-98.4 "
                      "Q-6.4,-96.6 -11.6,-91.8 Q-15,-88.6 -17.2,-83.6 Q-18.4,-89.2 -19.6,-91.2 Q-21.6,-87 -20.8,-82.2 Z")
        H["strands"] = ["M6.6,-110.4 Q3,-104 1.2,-98.6", "M-8,-107.6 Q-2,-101 -6,-96",
                        "M-15.8,-103.4 Q-11.8,-97 -11.6,-92", "M14.6,-107.6 Q19.6,-100 20.4,-91"]
        H["back_strands"] = ["M27.8,-94 Q29.4,-80 28.2,-62", "M23.4,-96.6 Q25,-84 23.8,-66"]
        H["shine"] = _ring(0, -89, 17, 17, 198, 290, 5, 7, 1.4)
        H["back_shine"] = [leaf(29.6, -88, 95, 12, 1.3)]
        H["tie"] = (18.8, -101.4)
    elif style == "chanel":
        H["back"] = ("M-24.4,-86 C-26.4,-101 -15,-112.6 0,-112.6 C15,-112.6 26.4,-101 24.4,-86 C24.6,-77 25.4,-69.6 "
                     "22.4,-64.4 L-22.4,-64.4 C-25.4,-69.6 -24.6,-77 -24.4,-86 Z")
        H["front"] = ("M-23.8,-71.6 C-26.4,-84 -25.4,-100.4 -16.2,-108.6 C-8.2,-114.8 8.2,-114.8 16.2,-108.6 "
                      "C25.4,-100.4 26.4,-84 23.8,-71.6 C23,-67.2 20.8,-64.2 17.8,-63.4 C18.8,-70 17.6,-78.6 16.4,-86.2 "
                      "Q15.2,-91.6 12.4,-93.6 Q11.2,-89.6 8.4,-87.4 Q7.6,-91.6 5,-94.2 Q3.2,-89.8 0.2,-87.6 "
                      "Q-0.8,-91.8 -3.4,-94.2 Q-5,-89.8 -8,-87.6 Q-8.8,-91.6 -11.4,-93.6 Q-13.6,-90 -16.2,-86.6 "
                      "C-17.6,-78.6 -18.6,-70 -17.6,-63.4 C-20.8,-64.2 -23,-67.2 -23.8,-71.6 Z")
        H["strands"] = ["M-2,-113 Q-3.4,-104 -3.4,-94.4", "M8,-112 Q7,-103 5,-94.4", "M-12,-110 Q-12.6,-100 -11.4,-93.8",
                        "M-21.4,-90 Q-21.4,-78 -20.4,-66.6", "M21.4,-90 Q21.8,-78 20.8,-66.6"]
        H["shine"] = _ring(0, -90, 18.5, 17.5, 196, 300, 6, 7.5, 1.5)
        H["ears"] = False
    elif style == "longo":
        H["long_back"] = ("M-24.6,-88 C-26.6,-104 -14.6,-114.6 0,-114.6 C14.6,-114.6 26.6,-104 24.6,-88 C25.6,-70 28.4,-52 "
                          "26.8,-35.4 C22.4,-31.8 17.6,-32.4 14,-36 L14,-58 L-14,-58 L-14,-36 C-17.6,-32.4 -22.4,-31.8 "
                          "-26.8,-35.4 C-28.4,-52 -25.6,-70 -24.6,-88 Z")
        H["front"] = ("M-23.6,-80 C-25.2,-96.4 -15.2,-110.6 0,-111 C15.2,-111.4 25.4,-98 23.8,-80 C24.4,-67 25.6,-55 "
                      "23.4,-42.6 C21.4,-45.6 19.6,-50.6 18.4,-57.4 C17.2,-67.6 18.2,-78 16.8,-86.2 "
                      "Q14.4,-93.6 8.4,-97.6 Q3.4,-93.4 -2.8,-90.4 Q-8.8,-87.4 -14.2,-83 Q-15.4,-87.4 -16.8,-86.2 "
                      "C-18.4,-76 -17.8,-64 -19.2,-56 C-20.2,-50.4 -21.8,-46 -23.2,-43.6 C-25.2,-56 -24.8,-68 -23.6,-80 Z")
        H["strands"] = ["M8.4,-110 Q9.6,-104 8.4,-97.8", "M2,-110.4 Q-2,-100 -9,-90", "M-8,-108.6 Q-14,-100 -17.6,-90",
                        "M-21.8,-84 Q-22.6,-66 -21.4,-48", "M21.6,-84 Q22.6,-66 21.6,-48", "M14.6,-108 Q19.6,-100 20.4,-86"]
        H["shine"] = _ring(0, -89, 18.5, 18, 198, 300, 6, 8, 1.5) + [leaf(-22, -66, 92, 12, 1.2), leaf(22.2, -66, 88, 12, 1.2)]
        H["ears"] = False
    elif style == "black":
        H["back"] = _afro()
        H["front"] = "M-24,-80 C-24,-97 -13,-110 0,-110 C13,-110 24,-97 24,-80 C19,-91 10,-96.6 0,-96.6 C-10,-96.6 -19,-91 -24,-80 Z"
        H["front_stroke"] = False
        H["hairline"] = "M-21.6,-81.6 C-18,-91.2 -9.4,-96.6 0,-96.6 C9.4,-96.6 18,-91.2 21.6,-81.6"
        r = Rng(11)
        curls = []
        for _ in range(26):
            a = r.u(190, 350)
            rr = r.u(12, 28)
            x = rr * math.cos(math.radians(a))
            y = -89 + rr * 0.94 * math.sin(math.radians(a))
            if y > -98 and abs(x) < 21:
                continue
            curls.append(f"M{f(x-2.2)},{f(y+0.8)} q2.2,-2.8 4.4,0")
        H["strands"] = curls
        H["shine"] = _ring(0, -92, 20, 18, 200, 290, 5, 6, 1.6)
        H["ears"] = False
    elif style == "coque":
        H["back"] = ("M-9.6,-113.6 C-10.6,-121 -5,-126 1.4,-126 C8,-126 12.8,-121.4 12,-114.4 C11.2,-108.6 6,-106 1,-106.4 "
                     "C-4.6,-106.8 -9,-108.8 -9.6,-113.6 Z")
        H["back_strands"] = ["M-4,-121.6 Q1,-125 6.6,-120.6", "M-6.4,-115 Q0.6,-120 8,-115.6"]
        H["front"] = ("M-22.6,-80 C-24.8,-95.4 -15,-108.6 0,-109 C15,-109.4 24.8,-95.4 22.6,-80 C21.2,-86.6 18.8,-91.4 14.8,-94.6 "
                      "C10.2,-97.8 4.2,-98.4 0.4,-96.6 C-3.6,-98.4 -9.8,-97.8 -14.6,-94.6 C-18.8,-91.4 -21.2,-86.6 -22.6,-80 Z")
        H["strands"] = ["M0.4,-96.8 Q0.6,-103 1,-108.6", "M-8,-97.4 Q-6,-103 -3,-108.2", "M8.6,-97.4 Q6.6,-103 4,-108.2",
                        "M-16.8,-92 Q-12.6,-101 -6.6,-106.6", "M17,-92 Q13,-101 7,-106.6"]
        H["shine"] = _ring(0, -90, 17, 16, 200, 300, 5, 6.5, 1.3)
        H["back_shine"] = [leaf(-3, -120, 200, 6, 1.2)]
        H["band"] = True
    elif style == "careca":
        H["front"] = ("M-21.4,-78 C-22.6,-84 -22.2,-89 -20.6,-92.6 L-18.6,-90 C-19.4,-86.8 -19.6,-83 -19.2,-79.4 Z "
                      "M21.4,-78 C22.6,-84 22.2,-89 20.6,-92.6 L18.6,-90 C19.4,-86.8 19.6,-83 19.2,-79.4 Z")
    elif style == "bone":
        H["front"] = ("M-22.6,-78.4 C-23.6,-84 -23.2,-89 -21.6,-92 L-18,-90 C-19,-86.8 -19.4,-83 -19.4,-79.6 Z "
                      "M22.6,-78.4 C23.6,-84 23.2,-89 21.6,-92 L18,-90 C19,-86.8 19.4,-83 19.4,-79.6 Z")
    else:
        raise ValueError(style)
    return H


def _hair_fill(D, col):
    hc = HAIR[col]
    return D.lin_u([(0, light(hc[0], 0.16)), (0.3, hc[0]), (0.75, mix(hc[0], hc[1], 0.55)), (1, hc[1])], -10, -124, 12, -40)


# --- Rosto --------------------------------------------------------------------------

def _eye(D, cx, cy, side, iris, expr, lash):
    """Olho com pálpebra superior grossa, íris recortada pela pálpebra, sombra da pálpebra e dois brilhos.
    side = -1 para o olho da esquerda da tela, +1 para o da direita (o canto externo fica desse lado)."""
    w, h = EYE_W, EYE_H
    ox, ix = cx + side * w, cx - side * w
    oy, iy = cy - 0.2 * h, cy + 0.12 * h
    o = []
    if expr in ("comendo", "feliz_fechado"):
        o.append(path(f"M{f(ix)},{f(cy+1)} Q{f(cx)},{f(cy-h*1.05)} {f(ox)},{f(cy+0.6)}", "none", LINE, 2.1))
        if lash:
            o.append(path(f"M{f(ox)},{f(cy+0.6)} l{f(side*2.2)},-1.2", "none", LINE, 1.4))
        return "".join(o)
    lower = {"bravo": 0.3, "esperando": 0.16}.get(expr, 0.0)
    ty = cy - h * (1.32 - lower)
    tyo = ty - 0.25 * h if expr != "bravo" else ty + 0.2 * h
    upper = f"M{f(ix)},{f(iy)} C{f(ix)},{f(ty)} {f(ox)},{f(tyo)} {f(ox)},{f(oy)}"
    shape = upper + f" C{f(ox)},{f(cy + 1.22 * h)} {f(ix)},{f(cy + 1.22 * h)} {f(ix)},{f(iy)} Z"
    clip = D.clip(shape)
    o.append(path(shape, "#ffffff", None))
    r = 0.82 * w
    icx, icy = cx + 0.9, cy + 0.9
    inner = [
        C(icx, icy, r, D.rad([(0, light(iris, 0.45)), (0.55, iris), (0.9, dark(iris, 0.35)), (1, dark(iris, 0.55))], 0.5, 0.62, 0.62), None),
        C(icx, icy + 0.2, r * 0.47, "#120b0a", None),
        path(upper, "none", "#8f99b8", 3.4, 'opacity="0.5" transform="translate(0,1.4)"'),
        C(icx + r * 0.38, icy - r * 0.42, r * 0.34, "#ffffff", None),
        C(icx - r * 0.38, icy + r * 0.45, r * 0.15, "#ffffff", None, extra='opacity="0.9"'),
    ]
    o.append(f'<g clip-path="{clip}">' + "".join(inner) + "</g>")
    o.append(path(upper, "none", LINE, 2.3))
    o.append(path(f"M{f(ox)},{f(oy)} Q{f(ox + side * 1.4)},{f(oy - 0.4)} {f(ox + side * 2.3)},{f(oy - 1.6)}", "none", LINE, 1.6))
    o.append(path(f"M{f(ox - side * 0.2)},{f(cy + 0.4 * h)} Q{f(cx + side * w * 0.3)},{f(cy + 1.05 * h)} {f(cx - side * w * 0.35)},{f(cy + 0.98 * h)}",
                  "none", LINE, 0.9, 'opacity="0.55"'))
    if lash:
        o.append(path(f"M{f(ox - side * 0.8)},{f(oy - 1.6)} q{f(side * 1.6)},-0.6 {f(side * 2.8)},-2.6", "none", LINE, 1.3))
        o.append(path(f"M{f(ox - side * 2.6)},{f(oy - 3.6)} q{f(side * 1.2)},-1 {f(side * 1.8)},-3", "none", LINE, 1.2))
    return "".join(o)


def _brow(cx, cy, side, color, expr):
    w = EYE_W
    base = cy - EYE_H - 3.1
    ix, ox = cx - side * w * 1.0, cx + side * w * 1.25
    iyy, oyy = base + 0.4, base + 0.6
    if expr == "bravo":
        iyy += 3.4
        oyy -= 1.2
    elif expr == "esperando":
        iyy -= 1.8
        oyy += 1.0
    mx = (ix + ox) / 2
    ctrl = (mx, min(iyy, oyy) - (2.6 if expr != "bravo" else 0.6))
    return path(taper((ix, iyy), ctrl, (ox, oyy), 2.3, 0.9), color, None)


def face(D, skin, hair_col, expr="feliz", iris="#6a4424", lash=False, glasses=None, freckles=False, beard=None,
         earrings=None, makeup=False):
    sk = SKIN[skin]
    hc = HAIR[hair_col] if hair_col else HAIR["preto"]
    o = []
    cx0 = FS
    blush = D.rad_u([(0, "#ff7d8a", 0.55), (1, "#ff7d8a", 0)], 0, 0, 1)
    for bx in (-11.4 + cx0 * 0.6, 12.2 + cx0 * 0.6):
        o.append(f'<ellipse cx="0" cy="0" rx="1" ry="1" fill="{blush}" transform="translate({f(bx)},-72.2) scale(4.6,2.8)"/>')
    if freckles:
        for (x, y) in [(-13, -74.2), (-10.4, -73.4), (-11.8, -71.4), (11.8, -74.2), (14.4, -73.4), (13, -71.2)]:
            o.append(C(x + cx0 * 0.6, y, 0.65, sk[1], None))
    brow_col = mix(hc[1], LINE, 0.25) if hair_col != "grisalho" else "#8b8698"
    for side, ex in ((-1, -EYE_X + cx0), (1, EYE_X + cx0)):
        o.append(path(f"M{f(ex - side * EYE_W * 0.1)},{f(EYE_Y - EYE_H - 1.4)} Q{f(ex + side * EYE_W * 0.6)},{f(EYE_Y - EYE_H - 1.6)} "
                      f"{f(ex + side * EYE_W * 1.05)},{f(EYE_Y - EYE_H * 0.5)}", "none", sk[1], 0.9, 'opacity="0.8"'))
        if makeup:
            o.append(path(f"M{f(ex - side * EYE_W)},{f(EYE_Y - 0.4)} C{f(ex - side * EYE_W)},{f(EYE_Y - EYE_H * 1.5)} "
                          f"{f(ex + side * EYE_W * 1.2)},{f(EYE_Y - EYE_H * 1.55)} {f(ex + side * EYE_W * 1.3)},{f(EYE_Y - EYE_H * 0.3)} Z",
                          "#b77be0", None, 'opacity="0.35"'))
        o.append(_eye(D, ex, EYE_Y, side, iris, expr, lash))
        o.append(_brow(ex, EYE_Y, side, brow_col, expr))
    o.append(path(f"M{f(cx0 + 0.6)},-77.4 Q{f(cx0 + 2.8)},-74.6 {f(cx0 + 0.4)},-73", "none", sk[1], 1.4))
    o.append(C(cx0 - 1.6, -75.4, 1.2, sk[2], None, extra='opacity="0.7"'))
    mx = cx0 + 0.6
    if expr == "feliz":
        o.append(path(f"M{f(mx-5.4)},-68.6 Q{f(mx)},-60.6 {f(mx+5.4)},-68.6 Q{f(mx)},-67 {f(mx-5.4)},-68.6 Z", "#7c2432", LINE, 1.1))
        o.append(path(f"M{f(mx-4.4)},-68.3 Q{f(mx)},-67.1 {f(mx+4.4)},-68.3 L{f(mx+3.9)},-66.6 Q{f(mx)},-65.7 {f(mx-3.9)},-66.6 Z",
                      "#ffffff", None))
        o.append(E(mx + 0.4, -63.9, 2.6, 1.3, "#ff7f8e", None))
    elif expr == "sorriso":
        o.append(path(f"M{f(mx-4.6)},-67.8 Q{f(mx)},-63.6 {f(mx+4.6)},-67.8", "none", LINE, 1.4))
    elif expr == "esperando":
        o.append(path(f"M{f(mx-3)},-66.6 Q{f(mx)},-67.4 {f(mx+3)},-66.2", "none", LINE, 1.4))
    elif expr == "bravo":
        o.append(path(f"M{f(mx-4)},-64.8 Q{f(mx)},-68.8 {f(mx+4)},-64.8 Z", "#7c2432", LINE, 1.2))
        o.append(path(f"M{f(mx-3)},-65.4 L{f(mx+3)},-65.4", "none", "#ffffff", 1.0))
        o.append(f'<path d="{HEAD}" fill="{D.lin_u([(0, "#ff3b3b", 0.32), (0.55, "#ff3b3b", 0)], 0, -106, 0, -60)}"/>')
    elif expr == "comendo":
        o.append(path(f"M{f(mx-4.2)},-67.4 Q{f(mx-0.4)},-64.4 {f(mx+3.2)},-67.2", "none", LINE, 1.4))
        o.append(path(f"M{f(mx+2.4)},-68.4 Q{f(mx+4.8)},-67.2 {f(mx+3.6)},-65.2", "none", LINE, 1.1))
        o.append(path("M16.4,-74 C19.8,-72.4 20.4,-68.6 18,-66.4", "none", LINE, 1.1, 'opacity="0.6"'))
    if beard:
        bf = _hair_fill(D, beard)
        o.append(path("M-18.6,-78 C-17.6,-66 -9,-60.6 0,-60.6 C9,-60.6 17.6,-66 18.6,-78 C15.6,-71 10.4,-68.2 6,-69.2 "
                      "C3,-70.4 -2,-70.4 -5,-69.2 C-9.8,-68.2 -15.6,-71 -18.6,-78 Z", bf, LINE, 1.0))
        o.append(path(f"M{f(mx-5.2)},-69.8 Q{f(mx)},-72 {f(mx+5.2)},-69.8 Q{f(mx)},-68.4 {f(mx-5.2)},-69.8 Z", bf, LINE, 0.9))
    if glasses:
        for side, ex in ((-1, -EYE_X + cx0), (1, EYE_X + cx0)):
            o.append(f'<rect x="{f(ex-6.6)}" y="{f(EYE_Y-7.4)}" width="13.2" height="12.4" rx="4.6" fill="#ffffff" fill-opacity="0.16" '
                     f'stroke="{glasses}" stroke-width="1.7"/>')
            o.append(path(f"M{f(ex - 4)},{f(EYE_Y - 5.2)} l3,-1.2", "none", "#ffffff", 1.1, 'opacity="0.8"'))
        o.append(path(f"M{f(cx0 - 1.7)},{f(EYE_Y - 2.4)} Q{f(cx0)},{f(EYE_Y - 3.8)} {f(cx0 + 1.7)},{f(EYE_Y - 2.4)}", "none", glasses, 1.5))
    if earrings:
        o.append(C(-21.6, -73.6, 1.8, earrings, LINE, 0.8))
    return "".join(o)


def _overlay(expr):
    if expr == "esperando":
        return path("M24.6,-100 q3.2,4.6 0,7 q-3.2,-2.4 0,-7 Z", "#bfe6ff", "#2f86c9", 0.9) + path("M23.8,-96.4 q0.4,-1.4 1.2,-2", "none", "#ffffff", 0.8)
    if expr == "bravo":
        vein = "M22,-108 q2.6,1.2 3.4,-1.8 M29.4,-110.6 q-1.2,2.6 1.8,3.4 M27.8,-102.6 q-2.6,-1.2 -3.4,1.8 M20.4,-100 q1.2,-2.6 -1.8,-3.4"
        return path(vein, "none", "#ff2d3d", 2.2)
    return ""


def _cap(D, color, back=False):
    o = []
    crown = D.lin_u([(0, light(color, 0.35)), (0.6, color), (1, dark(color, 0.18))], -10, -114, 10, -84)
    if back:
        o.append(path("M-22.6,-84 C-23.6,-101 -12.6,-111.6 0,-111.6 C12.6,-111.6 23.6,-101 22.6,-84 C12,-88.4 -12,-88.4 -22.6,-84 Z",
                      crown, LINE, 1.3))
        o.append(path("M-6,-88 L6,-88 L5,-84.6 L-5,-84.6 Z", "#ffffff", LINE, 0.9))
        return "".join(o)
    o.append(path("M-22.6,-86.4 C-23.6,-102 -12.6,-112 0,-112 C12.6,-112 23.6,-102 22.6,-86.4 C12,-90.8 -12,-90.8 -22.6,-86.4 Z",
                  crown, LINE, 1.3))
    o.append(path("M-1,-111.8 Q0.4,-100 0.6,-90", "none", dark(color, 0.25), 1.0))
    o.append(path("M-12,-108 Q-15,-99 -15.6,-89.4", "none", dark(color, 0.18), 0.9, 'opacity="0.8"'))
    o.append(path("M-6,-89.6 C6,-94.6 27,-94.6 34.6,-87.6 C27.4,-83.6 10,-83.8 -6,-86 Z",
                  D.lin_u([(0, dark(color, 0.1)), (1, dark(color, 0.32))], 0, -94, 0, -84), LINE, 1.3))
    o.append(E(0, -112, 3.2, 1.5, dark(color, 0.3), LINE, 0.9))
    o.append(path("M-15.6,-103 C-9.6,-108.6 1.4,-109.6 8,-106.4", "none", "#ffffff", 2.4, 'opacity="0.4"'))
    star = []
    for i in range(10):
        a = math.radians(-90 + i * 36)
        rr = 4.6 if i % 2 == 0 else 2.0
        star.append((7.6 + rr * math.cos(a), -101.6 + rr * math.sin(a)))
    o.append(P(star, "#ffffff", LINE, 0.8))
    return "".join(o)


def head(D, skin, hair, expr="feliz", back=False, cap=None, **fx):
    style, col = hair
    hc = HAIR[col]
    sk = SKIN[skin]
    Hp = hair_parts(style)
    hf = _hair_fill(D, col)
    o = []
    if Hp["back"]:
        o.append(path(Hp["back"], hf, LINE, 1.3))
        for s in Hp.get("back_strands", []):
            o.append(path(s, "none", hc[1], 1.0, 'opacity="0.7"'))
        for s in Hp.get("back_shine", []):
            o.append(path(s, hc[2], None, 'opacity="0.8"'))
    skin_fill = D.rad_u([(0, sk[2]), (0.45, sk[0]), (1, sk[1])], -5, -92, 30, -8, -96)
    if Hp["ears"] or back:
        o.append(E(-20.8, -80, 3.6, 5.0, skin_fill, LINE, 1.1))
        o.append(E(20.6, -80, 2.9, 4.6, skin_fill, LINE, 1.1))
        o.append(path("M-21.8,-82.6 Q-19.6,-80 -21.2,-77.2", "none", sk[1], 1.1))
        o.append(path("M21.4,-82.4 Q19.8,-80 21,-77.4", "none", sk[1], 1.0))
    o.append(path(HEAD, skin_fill, LINE, 1.4))
    headclip = D.clip(HEAD)
    if back:
        cover = ("M-22.6,-72 C-25.6,-92 -14,-110.6 0,-110.6 C14,-110.6 25.6,-92 22.6,-72 C17,-64.6 8,-62.6 0,-62.6 "
                 "C-8,-62.6 -17,-64.6 -22.6,-72 Z")
        if style == "chanel":
            cover = "M-24.6,-64 C-27.6,-92 -14,-113 0,-113 C14,-113 27.6,-92 24.6,-64 Z"
        elif style == "longo":
            cover = ("M-25.6,-44 C-28.6,-70 -26,-96 -14,-108 C-8,-113.6 8,-113.6 14,-108 C26,-96 28.6,-70 25.6,-44 "
                     "C18,-40 -18,-40 -25.6,-44 Z")
        elif style == "black":
            cover = _afro()
        elif style in ("careca", "bone"):
            cover = None
        elif style == "moicano":
            cover = Hp["front"]
        if cover:
            o.append(path(cover, hf, LINE, 1.3))
            if style == "longo":
                back_lines = ["M-12,-106 Q-18,-80 -18,-48", "M-4,-110 Q-8,-80 -7,-44", "M5,-110 Q7,-80 6,-44",
                              "M13,-106 Q19,-80 18,-48", "M20,-96 Q24,-76 22,-50", "M-20,-96 Q-24,-76 -22,-50"]
            elif style in ("coque",):
                back_lines = ["M-18,-78 Q-12,-96 -3,-106", "M-8,-70 Q-4,-92 0,-106", "M8,-70 Q4,-92 1,-106", "M18,-78 Q12,-96 4,-106"]
            elif style == "black":
                back_lines = Hp["strands"]
            else:
                back_lines = ["M0,-110 Q-2,-90 -3,-66", "M-10,-107 Q-16,-90 -15,-70", "M10,-107 Q15,-90 14,-70",
                              "M-18,-98 Q-22,-86 -20,-74", "M18,-98 Q22,-86 20,-74"]
            for ln in back_lines:
                o.append(path(ln, "none", hc[1], 1.0, 'opacity="0.7"'))
            for sh in _ring(0, -92, 17, 15, 205, 300, 5, 7, 1.4):
                o.append(path(sh, hc[2], None, 'opacity="0.6"'))
            if style == "coque":
                o.append(path(Hp["back"], hf, LINE, 1.3))
        if style == "careca":
            o.append(path("M-12,-100 Q-4,-106 6,-103", "none", "#ffffff", 2.6, 'opacity="0.45"'))
        if style == "bone":
            o.append(_cap(D, cap or "#ff4d5e", back=True))
        return "".join(o)
    if Hp["front"] and style not in ("careca", "bone", "moicano"):
        o.append(f'<g clip-path="{headclip}"><path d="{Hp["front"]}" fill="{sk[1]}" opacity="0.55" transform="translate(0.8,2.6)"/></g>')
    o.append(face(D, skin, col, expr, **fx))
    if style == "careca":
        o.append(path(Hp["front"], hf, LINE, 1.0))
        o.append(path("M-12,-100 Q-4,-106 6,-103", "none", "#ffffff", 2.6, 'opacity="0.5"'))
        o.append(_overlay(expr))
        return "".join(o)
    if style == "bone":
        o.append(path(Hp["front"], hf, LINE, 1.0))
        o.append(_cap(D, cap or "#ff4d5e"))
        o.append(_overlay(expr))
        return "".join(o)
    if style == "moicano":
        o.append(path("M-20.6,-86 C-20,-95 -15,-101 -9,-103 L-9,-96 C-14,-94 -18,-91 -20.6,-86 Z M20.6,-86 C20,-95 15,-101 10.6,-103 "
                      "L10.6,-96 C15,-94 18,-91 20.6,-86 Z", hc[1], None, 'opacity="0.35"'))
    if Hp["front_stroke"]:
        o.append(path(Hp["front"], hf, LINE, 1.3))
    else:
        o.append(path(Hp["front"], hf, None))
        o.append(path(Hp["hairline"], "none", LINE, 1.3))
    for s in Hp["strands"]:
        o.append(path(s, "none", hc[1], 1.0, 'opacity="0.75"'))
    for s in Hp["shine"]:
        o.append(path(s, hc[2], None, 'opacity="0.85"'))
    if Hp.get("tie"):
        x, y = Hp["tie"]
        o.append(E(x, y, 3.2, 4.2, "#ff4d8d", LINE, 1.0))
        o.append(path(f"M{f(x-1.4)},{f(y-2.4)} Q{f(x+0.6)},{f(y)} {f(x-1.2)},{f(y+2.6)}", "none", "#ffffff", 0.9, 'opacity="0.6"'))
    if Hp.get("band"):
        o.append(path("M-8.8,-108.6 Q1,-104.4 11.2,-108.8 L11.8,-106 Q1,-101.4 -9.2,-105.8 Z", "#ff4d8d", LINE, 0.9))
    o.append(_overlay(expr))
    return "".join(o)


# --- Corpo --------------------------------------------------------------------------

TORSO = ("M-8,-58.6 C-12,-58.6 -15.6,-57.6 -16.6,-54 C-17.6,-50 -16.2,-42 -14.8,-35 C-14.6,-32.4 -13.4,-31 -11.2,-30.4 "
         "C-4,-29 4,-29 11.2,-30.4 C13.4,-31 14.6,-32.4 14.8,-35 C16.2,-42 17.6,-50 16.6,-54 C15.6,-57.6 12,-58.6 8,-58.6 Z")


def _cloth(D, c, x0=-18, x1=18, y0=-60, y1=-28):
    return D.lin_u([(0, light(c, 0.28)), (0.45, c), (1, dark(c, 0.16))], x0, y0, x1, y1)


def _arm(D, s, sleeve, skin_fill, sk, cloth, pose):
    """Braço pendurado (s = -1 esquerda, +1 direita). sleeve: 'curta', 'longa' ou None (regata)."""
    o = []
    sw = 2.4 * s if pose == "andar" else 0.0
    arm = (f"M{f(s*12.6)},-57.6 C{f(s*19)},-58 {f(s*22.4)},-54 {f(s*22.8)},-48 L{f(s*22.4+sw)},-37 "
           f"C{f(s*20.4+sw)},-36 {f(s*18.2+sw)},-36 {f(s*16.2+sw)},-37 L{f(s*16)},-46 "
           f"C{f(s*15.8)},-49 {f(s*15)},-51.5 {f(s*13.6)},-53 Z")
    o.append(path(arm, skin_fill, LINE, 1.15))
    hx = s * 19.4 + sw
    o.append(path(f"M{f(hx - s*3.2)},-37.4 C{f(hx - s*4)},-34 {f(hx - s*3.2)},-29.6 {f(hx - s*0.2)},-29.2 "
                  f"C{f(hx + s*2.8)},-29 {f(hx + s*3.8)},-32.6 {f(hx + s*3.2)},-37.4 Z", skin_fill, LINE, 1.1))
    o.append(path(f"M{f(hx - s*2.8)},-35.6 q{f(-s*1.6)},0.9 {f(-s*1)},3.2 q{f(s*0.9)},0.9 {f(s*1.9)},-0.1", skin_fill, LINE, 0.9))
    o.append(path(f"M{f(hx + s*0.4)},-31.2 q{f(s*1.4)},0.4 {f(s*2.2)},-0.8", "none", sk[1], 0.8))
    if sleeve == "curta":
        o.append(path(f"M{f(s*12.8)},-57.8 C{f(s*19.2)},-58.4 {f(s*23.2)},-54.2 {f(s*23.8)},-47 C{f(s*20.8)},-45.2 "
                      f"{f(s*17.8)},-45 {f(s*15.4)},-46 L{f(s*13.8)},-52.6 Z", cloth, LINE, 1.15))
        o.append(path(f"M{f(s*16.4)},-47.6 C{f(s*18.6)},-47 {f(s*21)},-47.2 {f(s*23.2)},-48.6", "none", LINE, 0.7, 'opacity="0.35"'))
    elif sleeve == "longa":
        o.append(path(f"M{f(s*12.8)},-57.8 C{f(s*19.2)},-58.4 {f(s*23)},-54.2 {f(s*23.3)},-48 L{f(s*22.9+sw)},-38.8 "
                      f"C{f(s*20.6+sw)},-37.8 {f(s*17.8+sw)},-37.8 {f(s*15.6+sw)},-38.8 L{f(s*15.4)},-46.4 C{f(s*15.2)},-49.4 "
                      f"{f(s*14.6)},-51.4 {f(s*13.2)},-53 Z", cloth, LINE, 1.15))
        o.append(path(f"M{f(s*15.6+sw)},-41 C{f(s*18)},-40.2 {f(s*20.6)},-40.2 {f(s*23+sw)},-41", "none", LINE, 0.8, 'opacity="0.45"'))
        o.append(path(f"M{f(s*19.6)},-52 Q{f(s*20.6)},-47 {f(s*20)},-43.4", "none", "#ffffff", 0.9, 'opacity="0.35"'))
    return "".join(o)


def _shoe(D, sx, sy, shoes):
    sole = (f"M{f(sx-6)},{f(sy)} C{f(sx-6.2)},{f(sy-4.6)} {f(sx-3)},{f(sy-6.4)} {f(sx)},{f(sy-6.2)} C{f(sx+4)},{f(sy-6)} "
            f"{f(sx+6.4)},{f(sy-3.6)} {f(sx+6.2)},{f(sy)} C{f(sx+2)},{f(sy+1.8)} {f(sx-2)},{f(sy+1.8)} {f(sx-6)},{f(sy)} Z")
    return (path(sole, D.lin([(0, light(shoes, 0.35)), (0.6, shoes), (1, dark(shoes, 0.2))]), LINE, 1.1)
            + path(f"M{f(sx-5.8)},{f(sy-0.6)} C{f(sx-2)},{f(sy+1)} {f(sx+2)},{f(sy+1)} {f(sx+6)},{f(sy-0.6)}", "none", "#ffffff", 1.2, 'opacity="0.9"')
            + path(f"M{f(sx-3)},{f(sy-4.8)} Q{f(sx)},{f(sy-5.8)} {f(sx+2.6)},{f(sy-4.6)}", "none", "#ffffff", 0.9, 'opacity="0.5"'))


def _legs(D, bottom, skin_fill, sk, shoes, pose):
    bkind, bcol = bottom
    o = []
    st = 2.6 if pose == "andar" else 0.0
    left = f"M-12.2,-32.6 C-12.8,-24 -12.8,-14 {f(-12.2-st)},-5.4 L{f(-2.4-st)},-5.4 C{f(-2.2-st)},-12 -1.6,-18 0,-21.4 L0,-32.6 Z"
    right = (f"M12.2,-32.6 C12.8,-24 12.8,-14 {f(12.2+st*0.4)},{f(-5.4-st)} L{f(2.4+st*0.4)},{f(-5.4-st)} "
             f"C{f(2.2+st*0.4)},-12 1.6,-18 0,-21.4 L0,-32.6 Z")
    if bkind in ("saia", "short"):
        o.append(path(f"M-11,-20 L{f(-11-st)},-5.4 L{f(-3-st)},-5.4 L-3,-20 Z", skin_fill, LINE, 1.1))
        o.append(path(f"M11,-20 L{f(11+st*0.4)},{f(-5.4-st)} L{f(3+st*0.4)},{f(-5.4-st)} L3,-20 Z", skin_fill, LINE, 1.1))
    o.append(_shoe(D, -7.4 - st, -1.2, shoes))
    o.append(_shoe(D, 7.4 + st * 0.4, -1.2 - st, shoes))
    if bkind == "calca":
        lf = _cloth(D, bcol, -14, 14, -34, -4)
        o.append(path(left, lf, LINE, 1.15) + path(right, lf, LINE, 1.15))
        o.append(path(f"M-7,-28 L{f(-7-st)},-7", "none", dark(bcol, 0.2), 0.8, 'opacity="0.6"'))
        o.append(path(f"M7,-28 L{f(7+st*0.4)},{f(-7-st)}", "none", dark(bcol, 0.2), 0.8, 'opacity="0.6"'))
    elif bkind == "short":
        lf = _cloth(D, bcol, -14, 14, -34, -18)
        o.append(path("M-12.2,-32.6 C-12.8,-26 -12.8,-22 -12.6,-18.4 L-1.6,-18.4 C-1.4,-19.6 -1,-20.6 0,-21.4 L0,-32.6 Z", lf, LINE, 1.15))
        o.append(path("M12.2,-32.6 C12.8,-26 12.8,-22 12.6,-18.4 L1.6,-18.4 C1.4,-19.6 1,-20.6 0,-21.4 L0,-32.6 Z", lf, LINE, 1.15))
    elif bkind == "saia":
        o.append(path("M-12.6,-33 L12.6,-33 L17.6,-16.4 C8,-12.8 -8,-12.8 -17.6,-16.4 Z", _cloth(D, bcol, -18, 18, -34, -14), LINE, 1.15))
        o.append(path("M-5,-31 L-7.4,-15 M5,-31 L7.4,-15", "none", dark(bcol, 0.25), 0.8, 'opacity="0.6"'))
    return "".join(o)


def _torso_details(D, kind, base, sk):
    o = []
    neck = D.lin([(0, sk[1]), (1, sk[0])])
    if kind == "camiseta":
        o.append(path("M-5.8,-58.9 Q0,-53 5.8,-58.9 Z", neck, LINE, 1.0))
        o.append(path("M-6.6,-58.4 Q0,-51.8 6.6,-58.4", "none", dark(base, 0.25), 1.0))
    elif kind == "regata":
        o.append(path("M-7,-58.8 Q0,-50 7,-58.8 Z", neck, LINE, 1.0))
    elif kind == "blusa":
        o.append(path("M-6.2,-58.8 L0,-50.2 L6.2,-58.8 Z", neck, LINE, 1.0))
        o.append(path("M-14.8,-38.2 C-6,-35.8 6,-35.8 14.8,-38.2 L15.4,-35.8 C6,-33.4 -6,-33.4 -15.4,-35.8 Z", dark(base, 0.14), None, 'opacity="0.7"'))
    elif kind == "camisa":
        o.append(path("M-5.8,-58.8 L0,-51.4 L5.8,-58.8 Z", neck, LINE, 1.0))
        o.append(path("M-7.6,-59.2 L0,-51.4 L-3.2,-48.4 L-9.4,-55.8 Z M7.6,-59.2 L0,-51.4 L3.2,-48.4 L9.4,-55.8 Z", light(base, 0.55), LINE, 1.0))
        o.append(path("M0,-51 L0,-30.4", "none", dark(base, 0.3), 0.9))
        for yy in (-45.6, -40, -34.6):
            o.append(C(1.4, yy, 0.95, light(base, 0.7), dark(base, 0.4), 0.6))
        o.append(path("M-12.4,-49 L-6.6,-49 L-6.8,-43.4 L-12.2,-43.4 Z", "none", dark(base, 0.3), 0.8))
    elif kind == "moletom":
        o.append(path("M-11.4,-58.4 C-8.4,-63.4 8.4,-63.4 11.4,-58.4 C7,-55.4 -7,-55.4 -11.4,-58.4 Z", dark(base, 0.2), LINE, 1.1))
        o.append(path("M-2.6,-56.4 L-2.9,-47.4 M2.6,-56.4 L2.9,-47.4", "none", "#ffffff", 1.2))
        o.append(C(-2.9, -47, 0.9, "#ffffff", None) + C(2.9, -47, 0.9, "#ffffff", None))
        o.append(path("M-9.4,-40 L9.4,-40 L10.6,-32.4 L-10.6,-32.4 Z", dark(base, 0.1), LINE, 1.0))
    elif kind == "garcom":
        o.append(path("M-5.8,-58.8 L0,-51.4 L5.8,-58.8 Z", "#ffffff", LINE, 1.0))
        vest = D.lin_u([(0, "#4d4966"), (1, "#242236")], -12, -58, 12, -30)
        o.append(path("M-8,-58.6 C-12,-58.6 -15.6,-57.6 -16.6,-54 C-17.6,-50 -16.6,-42 -15.6,-35 C-15.2,-32.4 -14,-31 -11.6,-30.6 "
                      "L-1.2,-29.8 L-1.2,-44 Z", vest, LINE, 1.1))
        o.append(path("M8,-58.6 C12,-58.6 15.6,-57.6 16.6,-54 C17.6,-50 16.6,-42 15.6,-35 C15.2,-32.4 14,-31 11.6,-30.6 "
                      "L1.2,-29.8 L1.2,-44 Z", vest, LINE, 1.1))
        o.append(path("M-6,-58.6 L0,-55.8 L6,-58.6 L6,-52.4 L0,-55.2 L-6,-52.4 Z", "#ff3d57", LINE, 1.0))
        for yy in (-41, -36):
            o.append(C(-2.6, yy, 0.8, "#d8c27a", None))
    elif kind == "chef":
        o.append(path("M-6.4,-59 C-3,-55.4 3,-55.4 6.4,-59 L4.6,-53 L0,-50.6 L-4.6,-53 Z", "#28c6a6", LINE, 1.0))
        for cx in (-4.8, 4.8):
            for yy in (-46, -40.4, -34.8):
                o.append(C(cx, yy, 1.1, "#e7ebf1", LINE, 0.6))
        o.append(path("M0.4,-50 L0.4,-30", "none", "#c9d1dc", 0.9))
    elif kind == "vestido":
        o.append(path("M-6.2,-58.8 Q0,-52.6 6.2,-58.8 Z", neck, LINE, 1.0))
        o.append(path("M-15.8,-40 C-6,-37.6 6,-37.6 15.8,-40", "none", dark(base, 0.3), 1.1))
    return "".join(o)


def _seated_legs(D, bottom, skin_fill, shoes, back):
    bkind, bcol = bottom
    if back:
        return ""
    o = []
    cloth = _cloth(D, bcol, -14, 14, -8, 16) if bkind == "calca" else skin_fill
    for s in (-1, 1):
        x = s * 6.8
        o.append(path(f"M{f(x-5.2)},2 L{f(x-4.8)},14 C{f(x-4.8)},15.6 {f(x+4.8)},15.6 {f(x+4.8)},14 L{f(x+5.2)},2 Z", cloth, LINE, 1.1))
        o.append(_shoe(D, x, 18.6, shoes))
    o.append(path("M-13.6,-7 C-14,0 -12.6,4.6 -7,4.6 L7,4.6 C12.6,4.6 14,0 13.6,-7 Z", _cloth(D, bcol, -14, 14, -10, 6), LINE, 1.2))
    o.append(path("M0,-5 L0,4", "none", LINE, 0.8, 'opacity="0.6"'))
    return "".join(o)


def body(D, skin, top, bottom, pose="em_pe", tray=None, apron=None, back=False, shoes="#5b4a66"):
    sk = SKIN[skin]
    kind, color = top
    base = "#ffffff" if kind in ("chef", "garcom") else color
    cl = _cloth(D, base)
    skin_fill = D.lin_u([(0, sk[2]), (0.5, sk[0]), (1, sk[1])], -20, -60, 20, -26)
    sleeve = {"camiseta": "curta", "blusa": "curta", "regata": None, "vestido": "curta"}.get(kind, "longa")
    o = []
    if pose == "sentado":
        o.append(_seated_legs(D, bottom, skin_fill, shoes, back))
    else:
        o.append(_legs(D, bottom, skin_fill, sk, shoes, pose))
    dy = 26 if pose == "sentado" else 0
    b = [path("M-4.8,-64.6 L-4.8,-57.4 C-2,-55.2 2,-55.2 4.8,-57.4 L4.8,-64.6 Z", D.lin([(0, sk[1]), (0.55, sk[1]), (1, sk[0])]), LINE, 1.0)]
    b.append(path(TORSO, cl, LINE, 1.35))
    b.append(path("M9.6,-58.2 C13.6,-55 15,-46 14.4,-31 L10.6,-30.6 C12,-41 12,-51 9.6,-58.2 Z", dark(base, 0.14), None, 'opacity="0.5"'))
    if kind == "vestido" and pose != "sentado":
        b.append(path("M-15.6,-35 L15.6,-35 L19.6,-12.6 C8,-8.6 -8,-8.6 -19.6,-12.6 Z", _cloth(D, base, -20, 20, -36, -10), LINE, 1.2))
    if not back:
        b.append(_torso_details(D, kind, base, sk))
    if apron and not back:
        b.append(path("M-10.6,-50.4 L10.6,-50.4 L12.6,-14 C6,-11.2 -6,-11.2 -12.6,-14 Z", _cloth(D, apron, -12, 12, -52, -12), LINE, 1.1))
        b.append(path("M-6.4,-38 L6.4,-38 L6.4,-30.6 L-6.4,-30.6 Z", "none", dark(apron, 0.22), 0.9))
    for s in (-1, 1):
        if tray and s == 1:
            continue
        b.append(_arm(D, s, sleeve, skin_fill, sk, _cloth(D, base), pose))
    if tray:
        b.append(path("M12.8,-57.8 C19,-58.4 23.4,-55 23.8,-50.4 L28.2,-55.4 L32.4,-61.8 L28.8,-65.2 L20.6,-57.8 Z",
                      _cloth(D, base) if sleeve else skin_fill, LINE, 1.15))
        b.append(E(30.6, -63.4, 3.8, 4.1, skin_fill, LINE, 1.1))
        b.append(E(34.6, -67.4, 19, 5.6, D.lin([(0, "#ffffff"), (0.6, "#dfe6ee"), (1, "#aab6c4")]), LINE, 1.3))
        b.append(E(34.6, -68.4, 15.6, 3.6, "none", "#ffffff", 1.0, 'opacity="0.7"'))
        from food3 import food
        b.append(food(D, tray, 34.6, -77, 30))
    o.append(g("".join(b), f"translate(0,{dy})"))
    return "".join(o)


def person(D, x, y, s=1.0, facing=1, pose="em_pe", skin="clara", hair=("curto", "castanho"), top=("camiseta", "#2fa6ff"),
           bottom=("calca", "#3b6fd6"), expr="feliz", back=False, tray=None, apron=None, hat=None, shoes="#5b4a66", cap=None, **fx):
    dy = 26 if pose == "sentado" else 0
    o = []
    if pose != "sentado":
        o.append(E(0, 0.6, 19, 5.4, "#1a0f18", None, extra='opacity="0.2"'))
    Hp = hair_parts(hair[0])
    if Hp["long_back"] and not back:
        o.append(g(path(Hp["long_back"], _hair_fill(D, hair[1]), LINE, 1.3), f"translate(0,{dy})"))
    o.append(body(D, skin, top, bottom, pose, tray, apron, back, shoes))
    o.append(g(head(D, skin, hair, expr, back, cap=cap, **fx), f"translate(0,{dy})"))
    if hat == "chef":
        o.append(g(path("M-18,-99 C-25.6,-113 -15.6,-128.6 -4.6,-122.6 C-0.6,-133.6 16.4,-132 18.6,-120.6 C27,-121.6 30,-108 20.6,-99 Z",
                        D.lin([(0, "#ffffff"), (1, "#d9e1ea")]), LINE, 1.3)
                   + path("M-7,-121 C-7,-113 -6,-106 -5,-101 M7,-124 C7,-116 7,-108 7,-101", "none", "#c5ced9", 1.1)
                   + path("M-19.6,-102.4 C-8,-105.6 10,-105.6 21.6,-102.4 L20.6,-94 C9,-96.8 -7,-96.8 -18.6,-94 Z", "#ffffff", LINE, 1.2),
                   f"translate(0,{dy})"))
    return g("".join(o), f"translate({f(x)},{f(y)}) scale({f(s*facing)},{f(s)})")


def head_top(y, s=1.0, pose="em_pe"):
    return y + (-116 + (26 if pose == "sentado" else 0)) * s
