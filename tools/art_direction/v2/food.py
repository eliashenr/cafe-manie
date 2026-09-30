"""Comidas desenhadas com volume e textura (ícones 48x48, centro em 24,26)."""
from core import *

CREAM_PLATE = "#fbf8f2"


def _plate(D, cx=24, cy=38, rx=19, ry=6.2):
    out = [E(cx, cy + 1.6, rx, ry, dark("#d8d0c4", 0.1), INK, 1.1)]
    out.append(E(cx, cy, rx, ry, D.lin([(0, "#ffffff"), (1, "#e9e3da")]), INK, 1.1))
    out.append(E(cx, cy + 0.4, rx * 0.62, ry * 0.6, "#f1ece4", "#d9d1c5", 0.7))
    return "".join(out)


def cafe(D):
    o = []
    # pires
    o.append(E(24, 39.5, 17, 5.2, dark("#e3ddd3", 0.1), INK, 1.1))
    o.append(E(24, 38.6, 17, 5.2, D.lin([(0, "#ffffff"), (1, "#e6e0d7")]), INK, 1.1))
    o.append(E(24, 38.8, 9.5, 2.8, "#efe9e0", "#d4ccc0", 0.7))
    # xícara
    body = D.lin([(0, "#e8e2d9"), (0.35, "#ffffff"), (0.75, "#f1ece5"), (1, "#cfc6b9")], 0, 0, 1, 0)
    o.append(path("M11.5,20 L13.2,31.5 C14,36 18.5,38 24,38 C29.5,38 34,36 34.8,31.5 L36.5,20 Z", body, INK, 1.2))
    o.append(path("M35.5,22.5 C42.5,21 43.5,31 34,32.2", "none", INK, 3.2))
    o.append(path("M35.5,22.5 C42.5,21 43.5,31 34,32.2", "none", "#f6f2ec", 1.4))
    o.append(E(24, 20, 12.5, 4.1, "#faf7f2", INK, 1.2))
    # café com espuma e coração de leite
    o.append(E(24, 20.4, 10.6, 3.1, D.rad([(0, "#d9a36e"), (0.55, "#b0703f"), (1, "#6e3b1c")]), None))
    o.append(path("M24,22.4 C21.2,20.6 20.4,19.2 21.8,18.4 C22.8,17.9 23.6,18.5 24,19.2 C24.4,18.5 25.2,17.9 26.2,18.4 "
                  "C27.6,19.2 26.8,20.6 24,22.4 Z", "#fff4e2", "none"))
    # vapor
    for x0 in (19, 25.5):
        o.append(path(f"M{x0},14.5 C{x0-3},11.5 {x0+3},9 {x0},5.5", "none", "#bdb4a8", 1.8, 'opacity="0.85"'))
    return "".join(o)


def _cheese_ball(D, cx, cy, r):
    o = [C(cx, cy, r, D.rad([(0, "#fff0bf"), (0.35, "#f5cd6c"), (0.78, "#dfa13e"), (1, "#b87326")], 0.4, 0.35, 0.65), "#7e4c17", 1.0)]
    # casquinha rachada
    o.append(path(f"M{f(cx-r*0.45)},{f(cy-r*0.25)} q{f(r*0.3)},{f(-r*0.3)} {f(r*0.6)},{f(-r*0.1)}", "none", "#b97a2c", 1.0))
    o.append(path(f"M{f(cx+r*0.05)},{f(cy+r*0.15)} q{f(r*0.25)},{f(-r*0.2)} {f(r*0.45)},{f(r*0.05)}", "none", "#c78a36", 0.9))
    o.append(C(cx - r * 0.35, cy - r * 0.45, r * 0.22, "#fff7dc", None, extra='opacity="0.85"'))
    return "".join(o)


def pao(D):
    o = [_plate(D)]
    for (cx, cy, r) in [(15, 30, 7.2), (33, 30, 7.2), (24, 24.5, 7.6), (24, 33, 7.4)]:
        o.append(_cheese_ball(D, cx, cy, r))
    return "".join(o)


def _sandwich_half(D, A, B, Cc, thick=9.5):
    """Metade de misto: topo tostado (triângulo A-B-Cc) e o corte (A-B) mostrando pão, queijo e presunto."""
    ax, ay = A
    bx, by = B
    o = []
    band = lambda t0, t1, col, st=None, sw=0.8: P([(ax, ay + t0), (bx, by + t0), (bx, by + t1), (ax, ay + t1)], col, st, sw)
    o.append(band(0, thick, "#e5b369", INK, 1.2))
    o.append(band(0, 2.6, "#d9964a"))                    # casca de cima
    o.append(band(2.6, 4.2, "#fff0d2"))                   # miolo
    o.append(band(4.2, 6.0, "#ffcf33"))                   # queijo
    o.append(band(6.0, 7.6, "#f2939c"))                   # presunto
    o.append(band(7.6, thick, "#f6e2b8"))                 # miolo de baixo
    o.append(P([(ax, ay), (bx, by), (bx, by + thick), (ax, ay + thick)], "none", INK, 1.2))
    # queijo escorrendo
    mx, my = ax + (bx - ax) * 0.55, ay + (by - ay) * 0.55
    o.append(path(f"M{f(mx-3)},{f(my+5)} Q{f(mx-2.5)},{f(my+11)} {f(mx)},{f(my+11)} Q{f(mx+2.5)},{f(my+11)} {f(mx+2)},{f(my+5)} Z",
                  "#ffcf33", "#c99a14", 0.8))
    # topo tostado com marcas da chapa
    o.append(P([A, B, Cc], D.lin([(0, "#f7d898"), (0.55, "#e6aa55"), (1, "#c9853a")], 0, 0, 1, 1), INK, 1.2))
    for t in (0.3, 0.55, 0.8):
        p0 = (ax + (Cc[0] - ax) * t, ay + (Cc[1] - ay) * t)
        p1 = (bx + (Cc[0] - bx) * t, by + (Cc[1] - by) * t)
        o.append(line(p0[0] + 1, p0[1], p1[0] - 1, p1[1], "#9b5a24", 1.6, 'opacity="0.55"'))
    return "".join(o)


def misto(D):
    o = [_plate(D)]
    o.append(_sandwich_half(D, (21, 20), (43, 23.5), (34, 9)))
    o.append(_sandwich_half(D, (4, 25), (27, 29), (13, 13)))
    return "".join(o)


def bolo(D):
    o = [_plate(D)]
    # fatia alta de bolo de cenoura (laranja) com cobertura fina de chocolate e granulado
    front = [(6, 35), (29, 29.5), (29, 13), (6, 18.5)]
    side = [(29, 29.5), (38, 32.5), (38, 16), (29, 13)]
    top = [(6, 18.5), (29, 13), (38, 16), (15, 21.5)]
    o.append(P(front, D.lin([(0, "#ffb24a"), (1, "#f28a1a")]), INK, 1.2))
    o.append(P(side, D.lin([(0, "#e8801a"), (1, "#c96412")]), INK, 1.2))
    r = Rng(5)
    for _ in range(22):
        x = r.u(8, 27.5)
        y = r.u(22.5, 33) - (x - 6) * 0.24
        o.append(C(x, y, r.u(0.5, 0.95), "#ffd08a" if r.r() > 0.5 else "#d9700f", None, extra='opacity="0.85"'))
    o.append(P(top, D.lin([(0, "#6a331a"), (1, "#3a1a0b")], 0, 0, 1, 1), INK, 1.2))
    o.append(path("M6,18.5 L29,13 L29,16.2 Q27.8,18.8 26.6,16.5 Q25,19.4 23.2,17.2 Q21.4,21 19.6,18 Q17.8,20 16,18.8 "
                  "Q14.2,22 12.4,19.8 Q10.4,21.6 8.6,20.4 Q7,21.2 6,20.8 Z", "#4b2412", INK, 1.0))
    o.append(path("M29,13 L38,16 L38,18.4 Q36.8,20.8 35.6,18.4 Q34,20.6 32.4,17.6 Q30.8,19 29,16.2 Z", "#3c1b0c", INK, 1.0))
    o.append(path("M10,18.2 L25,14.6", "none", "#a8704f", 1.4, 'opacity="0.7"'))
    for (x, y, a) in [(11, 19, 20), (16, 17.6, -30), (21, 18.8, 45), (26, 15.6, 10), (31, 16.4, -25), (19, 20.2, 70),
                      (14, 20.2, -60), (34, 17.4, 60), (24, 16.8, -10)]:
        o.append(f'<rect x="{x}" y="{y}" width="2.4" height="0.9" rx="0.45" fill="#2a1207" transform="rotate({a} {x} {y})"/>')
    return "".join(o)


def _coxinha_shape(D, cx, cy, s, bite=False):
    k = s
    d = (f"M{f(cx)},{f(cy-16*k)} C{f(cx+6*k)},{f(cy-9*k)} {f(cx+11*k)},{f(cy-2*k)} {f(cx+10.5*k)},{f(cy+5*k)} "
         f"C{f(cx+10*k)},{f(cy+11*k)} {f(cx-10*k)},{f(cy+11*k)} {f(cx-10.5*k)},{f(cy+5*k)} "
         f"C{f(cx-11*k)},{f(cy-2*k)} {f(cx-6*k)},{f(cy-9*k)} {f(cx)},{f(cy-16*k)} Z")
    o = [path(d, D.rad([(0, "#f7c46e"), (0.55, "#e0913b"), (1, "#a95a1e")], 0.38, 0.35, 0.7), "#6d3a12", 1.1)]
    r = Rng(int(cx * 7 + cy))
    for _ in range(16):
        x = cx + r.u(-8, 8) * k
        y = cy + r.u(-8, 8) * k
        if abs(x - cx) / k < 9 - abs(y - cy) / k * 0.3:
            o.append(C(x, y, 0.7 * k, "#b8692a" if r.r() > 0.5 else "#ffd68e", None, extra='opacity="0.9"'))
    if bite:
        o.append(path(f"M{f(cx+4*k)},{f(cy-6*k)} C{f(cx+9*k)},{f(cy-5*k)} {f(cx+11*k)},{f(cy)} {f(cx+10.4*k)},{f(cy+5*k)} "
                      f"C{f(cx+7*k)},{f(cy+3*k)} {f(cx+4*k)},{f(cy)} {f(cx+4*k)},{f(cy-6*k)} Z", "#f5e6c4", "#8a5a2a", 0.9))
        for (dx, dy) in [(6, -2), (7.5, 1.5), (5.5, 1)]:
            o.append(path(f"M{f(cx+dx*k)},{f(cy+dy*k)} l{f(2*k)},{f(0.8*k)}", "none", "#e7a13f", 1.0))
    o.append(E(cx - 3.6 * k, cy - 5 * k, 1.6 * k, 3 * k, "#ffe9b8", None, extra='opacity="0.75"'))
    return "".join(o)


def coxinha(D):
    return _plate(D) + _coxinha_shape(D, 16, 27, 0.78) + _coxinha_shape(D, 30, 28, 0.95, bite=True)


def lasanha(D):
    o = [_plate(D)]
    o.append(E(22, 36, 16, 3.4, "#c7412b", None, extra='opacity="0.8"'))   # molho no prato
    fx0, fy0, fx1, fy1, top = 6, 34, 30, 28.5, 13.0   # frente: de (fx0,fy0) a (fx1,fy1), altura top
    o.append(P([(fx0, fy0), (fx1, fy1), (fx1, fy1 - top), (fx0, fy0 - top)], "#f3dc9a", INK, 1.2))
    layers = [(0.0, 0.16, "#f4d57e"), (0.16, 0.34, "#c63b22"), (0.34, 0.44, "#fff6e0"), (0.44, 0.56, "#f4d57e"),
              (0.56, 0.74, "#c63b22"), (0.74, 0.84, "#fff6e0"), (0.84, 1.0, "#f0c35a")]
    for (a, b, col) in layers:
        o.append(P([(fx0, fy0 - top * a), (fx1, fy1 - top * a), (fx1, fy1 - top * b), (fx0, fy0 - top * b)], col, None))
    o.append(P([(fx0, fy0), (fx1, fy1), (fx1, fy1 - top), (fx0, fy0 - top)], "none", INK, 1.2))
    o.append(P([(fx1, fy1), (42, 32), (42, 32 - top), (fx1, fy1 - top)], D.lin([(0, "#e3b451"), (1, "#b8741d")]), INK, 1.2))
    o.append(P([(fx0, fy0 - top), (fx1, fy1 - top), (42, 32 - top), (18, 37.5 - top)],
               D.rad([(0, "#f9dc76"), (0.7, "#e9ad3f"), (1, "#c67a24")]), INK, 1.2))
    for (x, y, r) in [(14, 22.8, 1.7), (21, 20.6, 1.4), (28, 19.6, 1.6), (34, 21.4, 1.2), (19, 23.8, 1.0), (25, 22.8, 0.9)]:
        o.append(E(x, y, r * 1.35, r * 0.8, "#a9561b", None, extra='opacity="0.85"'))
    o.append(path("M11,21 Q12.4,26 10.6,28.6", "none", "#c63b22", 2.4))
    o.append(path("M23,17.6 C26.4,13.2 31,14 32.2,16.8 C28.8,18.8 26,19 23,17.6 Z", "#4d9a3a", "#2c5e20", 0.9))
    o.append(path("M24,17.4 L31.2,16.2", "none", "#8fd07a", 0.8))
    for x0 in (14, 22):
        o.append(path(f"M{x0},12 C{x0-3},9 {x0+3},6.5 {x0},3.5", "none", "#bdb4a8", 1.6, 'opacity="0.8"'))
    return "".join(o)


FOODS = {"cafe": cafe, "pao": pao, "misto": misto, "bolo": bolo, "coxinha": coxinha, "lasanha": lasanha}
NAMES = {"cafe": "Café", "pao": "Pão de queijo", "misto": "Misto-quente", "bolo": "Bolo de cenoura",
         "coxinha": "Coxinha", "lasanha": "Lasanha"}


def food(D, kind, cx, cy, size=48):
    """Ícone de comida com centro em (cx, cy) e largura size."""
    s = size / 48.0
    return g(FOODS[kind](D), f"translate({f(cx - 24 * s)},{f(cy - 26 * s)}) scale({f(s)})")


def balloon(D, kind, x, y, size=44, patience=None):
    """Balão de pedido acima da cabeça: (x, y) é a ponta do rabinho."""
    w = size + 8
    h = size + 4
    bx, by = x - w / 2, y - h - 8
    o = [path(f"M{f(bx+10)},{f(by)} H{f(bx+w-10)} Q{f(bx+w)},{f(by)} {f(bx+w)},{f(by+10)} V{f(by+h-10)} Q{f(bx+w)},{f(by+h)} "
              f"{f(bx+w-10)},{f(by+h)} H{f(x+5)} L{f(x)},{f(y)} L{f(x-4)},{f(by+h)} H{f(bx+10)} Q{f(bx)},{f(by+h)} {f(bx)},{f(by+h-10)} "
              f"V{f(by+10)} Q{f(bx)},{f(by)} {f(bx+10)},{f(by)} Z", D.lin([(0, "#ffffff"), (1, "#f1ebe2")]), INK, 1.6)]
    o.append(food(D, kind, x, by + h / 2 + (1 if patience is None else -2), size))
    if patience is not None:
        col = "#5cc05a" if patience > 0.5 else ("#f2b632" if patience > 0.25 else "#e04a3a")
        o.append(f'<rect x="{f(bx+8)}" y="{f(by+h-8)}" width="{f(w-16)}" height="4.5" rx="2.25" fill="#e3dccf"/>')
        o.append(f'<rect x="{f(bx+8)}" y="{f(by+h-8)}" width="{f((w-16)*patience)}" height="4.5" rx="2.25" fill="{col}"/>')
    return "".join(o)


def mood_face(D, cx, cy, state="feliz", r=11):
    cols = {"feliz": ("#8ee06f", "#4fa33d"), "esperando": ("#ffd75a", "#d9a21b"), "bravo": ("#ff7a5c", "#c9382a")}
    c1, c2 = cols[state]
    k = r / 11.0
    o = [C(0, 0, 11, D.rad([(0, light(c1, 0.35)), (0.6, c1), (1, c2)], 0.4, 0.35, 0.7), INK, 1.4)]
    o.append(E(-3.6, -2.4, 1.5, 2.1, INK, None) + E(3.6, -2.4, 1.5, 2.1, INK, None))
    if state == "feliz":
        o.append(path("M-5.2,1.8 Q0,7.8 5.2,1.8 Q0,4.2 -5.2,1.8 Z", "#6b2418", INK, 1.0))
    elif state == "esperando":
        o.append(line(-3.4, 3.8, 3.4, 3.8, INK, 1.5))
        o.append(path("M7.5,-8 q2,3 0,4.5 q-2,-1.5 0,-4.5 Z", "#8fd0ff", "#2f7fb8", 0.7))
    else:
        o.append(path("M-4.6,5.6 Q0,1.2 4.6,5.6", "none", INK, 1.6))
        o.append(line(-6.2, -6.4, -1.8, -4.4, INK, 1.6) + line(6.2, -6.4, 1.8, -4.4, INK, 1.6))
    o.append(E(-4.5, -6.5, 3, 1.6, "#ffffff", None, extra='opacity="0.45"'))
    return g("".join(o), f"translate({f(cx)},{f(cy)}) scale({f(k)})")


def cooking_badge(D, kind, x, y, progress=0.6, label="0:32", ready=False):
    """Selo acima do fogão: o que está cozinhando e quanto falta."""
    r = 18
    o = []
    if ready:
        o.append(C(x, y, r + 7, "#fff3b0", None, extra='opacity="0.55"'))
    o.append(C(x, y, r, D.lin([(0, "#ffffff"), (1, "#efe7da")]), INK, 1.6))
    ring = "#5cc05a" if ready else "#f2b632"
    circ = 2 * math.pi * (r - 3.2)
    p = 1.0 if ready else progress
    o.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r-3.2)}" fill="none" stroke="#e7dccb" stroke-width="4"/>')
    o.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r-3.2)}" fill="none" stroke="{ring}" stroke-width="4" '
             f'stroke-dasharray="{f(circ*p)} {f(circ)}" transform="rotate(-90 {f(x)} {f(y)})" stroke-linecap="round"/>')
    o.append(food(D, kind, x, y + 1, 26))
    tw = 42 if not ready else 54
    o.append(f'<rect x="{f(x-tw/2)}" y="{f(y+r-5)}" width="{tw}" height="17" rx="8.5" fill="{"#2f7a3a" if ready else INK}" stroke="{INK}" stroke-width="1.2"/>')
    o.append(f'<text x="{f(x)}" y="{f(y+r+7.5)}" text-anchor="middle" font-family="Fredoka, Nunito, sans-serif" font-weight="700" '
             f'font-size="12" fill="#ffffff">{"Pronto!" if ready else label}</text>')
    return "".join(o)
