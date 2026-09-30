"""Comidas v3: os pratos da v2 com balões, carinhas e selos de fogão no visual claro e colorido."""
from core3 import *
import food as _f2
from food import NAMES  # noqa: F401

BLUE = "#1f7ae0"
BLUE_D = "#1456a8"


def food(D, kind, cx, cy, size=48):
    return _f2.food(D, kind, cx, cy, size)


def balloon(D, kind, x, y, size=44, patience=None):
    """Balão de pedido acima da cabeça: (x, y) é a ponta do rabinho."""
    w = size + 10
    h = size + 6
    bx, by = x - w / 2, y - h - 9
    d = (f"M{f(bx+12)},{f(by)} H{f(bx+w-12)} Q{f(bx+w)},{f(by)} {f(bx+w)},{f(by+12)} V{f(by+h-12)} Q{f(bx+w)},{f(by+h)} "
         f"{f(bx+w-12)},{f(by+h)} H{f(x+6)} L{f(x)},{f(y)} L{f(x-5)},{f(by+h)} H{f(bx+12)} Q{f(bx)},{f(by+h)} {f(bx)},{f(by+h-12)} "
         f"V{f(by+12)} Q{f(bx)},{f(by)} {f(bx+12)},{f(by)} Z")
    o = [path(d, "#1a2a4a", None, f'opacity="0.18" transform="translate(1.5,2.5)"')]
    o.append(path(d, D.lin([(0, "#ffffff"), (1, "#eaf3ff")]), "#2a5fa8", 1.6))
    o.append(food(D, kind, x, by + h / 2 + (1 if patience is None else -2.5), size))
    if patience is not None:
        col = "#35c24a" if patience > 0.5 else ("#ffb400" if patience > 0.25 else "#ff3b3b")
        o.append(f'<rect x="{f(bx+8)}" y="{f(by+h-9)}" width="{f(w-16)}" height="5" rx="2.5" fill="#d7e3f3"/>')
        o.append(f'<rect x="{f(bx+8)}" y="{f(by+h-9)}" width="{f((w-16)*patience)}" height="5" rx="2.5" fill="{col}"/>')
    return "".join(o)


def mood_face(D, cx, cy, state="feliz", r=11):
    cols = {"feliz": ("#8df06a", "#2fae3a"), "esperando": ("#ffe066", "#f0a800"), "bravo": ("#ff8a6a", "#e02f2f")}
    c1, c2 = cols[state]
    k = r / 11.0
    o = [C(0, 0, 11, D.rad([(0, tint(c1, 0.45)), (0.6, c1), (1, c2)], 0.4, 0.35, 0.7), "#2e2a3a", 1.4)]
    o.append(E(-3.6, -2.4, 1.5, 2.1, "#2e2a3a", None) + E(3.6, -2.4, 1.5, 2.1, "#2e2a3a", None))
    if state == "feliz":
        o.append(path("M-5.2,1.8 Q0,7.8 5.2,1.8 Q0,4.2 -5.2,1.8 Z", "#7a1f2a", "#2e2a3a", 1.0))
    elif state == "esperando":
        o.append(line(-3.4, 3.8, 3.4, 3.8, "#2e2a3a", 1.5))
        o.append(path("M7.5,-8 q2,3 0,4.5 q-2,-1.5 0,-4.5 Z", "#9fdcff", "#2f86c9", 0.7))
    else:
        o.append(path("M-4.6,5.6 Q0,1.2 4.6,5.6", "none", "#2e2a3a", 1.6))
        o.append(line(-6.2, -6.4, -1.8, -4.4, "#2e2a3a", 1.6) + line(6.2, -6.4, 1.8, -4.4, "#2e2a3a", 1.6))
    o.append(E(-4.5, -6.5, 3, 1.6, "#ffffff", None, extra='opacity="0.55"'))
    return g("".join(o), f"translate({f(cx)},{f(cy)}) scale({f(k)})")


def cooking_badge(D, kind, x, y, progress=0.6, label="0:32", ready=False, r=18):
    """Selo acima do fogão: o prato, o anel de progresso e o tempo (verde quando fica pronto)."""
    o = []
    if ready:
        o.append(C(x, y, r + 9, D.rad([(0, "#fff6a8", 0.9), (1, "#fff6a8", 0)]), None))
    o.append(C(x + 1.2, y + 2.2, r, "#1a2a4a", None, extra='opacity="0.2"'))
    o.append(C(x, y, r, D.lin([(0, "#ffffff"), (1, "#e3eefc")]), "#2a5fa8", 1.6))
    ring = "#35c24a" if ready else BLUE
    circ = 2 * math.pi * (r - 3.4)
    p = 1.0 if ready else progress
    o.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r-3.4)}" fill="none" stroke="#d3e2f5" stroke-width="4.2"/>')
    o.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r-3.4)}" fill="none" stroke="{ring}" stroke-width="4.2" '
             f'stroke-dasharray="{f(circ*p)} {f(circ)}" transform="rotate(-90 {f(x)} {f(y)})" stroke-linecap="round"/>')
    o.append(food(D, kind, x, y + 1, r * 1.45))
    tw = 44 if not ready else 58
    fill = D.lin([(0, "#5fe06a"), (1, "#23a63a")]) if ready else D.lin([(0, "#4aa3ff"), (1, BLUE_D)])
    o.append(f'<rect x="{f(x-tw/2)}" y="{f(y+r-5)}" width="{tw}" height="18" rx="9" fill="{fill}" stroke="#ffffff" stroke-width="1.6"/>')
    o.append(f'<text x="{f(x)}" y="{f(y+r+8.2)}" text-anchor="middle" font-family="Fredoka, Nunito, sans-serif" font-weight="700" '
             f'font-size="12.5" fill="#ffffff">{"Pronto!" if ready else label}</text>')
    return "".join(o)
