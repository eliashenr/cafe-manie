"""Cena v3: salão claro, grande e lotado, gramado verde-vivo, rua e calçada. Sem árvores."""
from core3 import *
from furniture3 import *
from people3 import person, head_top
from food3 import balloon, mood_face, cooking_badge

N = 12
TW, TH = 84, 42
WALL_H = 100
KITCHEN_X = 3      # piso de cozinha de x=0 até aqui
KITCHEN_Y = 7      # e de y=0 até aqui

MINT = "#bff3e1"
MINT_STRIPE = "#e3fbf2"
CORAL = "#ff6b6b"
CORAL_D = "#e04b55"


# --- Exterior ---------------------------------------------------------------------------

def lawn(D):
    r = Rng(31)
    marks = []
    for _ in range(14):
        x, y = r.u(0, 60), r.u(0, 44)
        c = "#5cc23a" if r.r() > 0.45 else "#a6ee78"
        marks.append(f'<path d="M{f(x)},{f(y)} l{f(-1.6)},{f(-4.2)} M{f(x)},{f(y)} l1,-4.8 M{f(x)},{f(y)} l{f(3)},{f(-3.6)}" '
                     f'stroke="{c}" stroke-width="1.2" stroke-linecap="round" fill="none"/>')
    markup = (f'<pattern id="lawn3" patternUnits="userSpaceOnUse" width="60" height="44">'
              f'<rect width="60" height="44" fill="#78d64a"/>{"".join(marks)}</pattern>')
    return D.raw("lawn3", markup)


def asphalt(D):
    r = Rng(21)
    dots = "".join(f'<circle cx="{f(r.u(0,30))}" cy="{f(r.u(0,30))}" r="{f(r.u(0.4,1.0))}" fill="{"#8c93a0" if r.r() > 0.5 else "#6a717d"}"/>'
                   for _ in range(16))
    return D.raw("asph3", f'<pattern id="asph3" patternUnits="userSpaceOnUse" width="30" height="30"><rect width="30" height="30" fill="#7a818e"/>{dots}</pattern>')


def street(D, iso):
    o = []
    far = 40
    ga = asphalt(D)
    s0, s1 = -2.3, -0.25   # calçada
    r0 = -6.6              # rua
    o.append(P([iso.v(r0, -far), iso.v(s0, -far), iso.v(s0, far), iso.v(r0, far)], ga, None))
    o.append(P([iso.v(-far, r0), iso.v(far, r0), iso.v(far, s0), iso.v(-far, s0)], ga, None))
    side = D.lin([(0, "#f1ece4"), (1, "#e2dbd0")])
    o.append(P([iso.v(s0, -far), iso.v(s1, -far), iso.v(s1, N + 6), iso.v(s0, N + 6)], side, None))
    o.append(P([iso.v(-far, s0), iso.v(N + 6, s0), iso.v(N + 6, s1), iso.v(-far, s1)], side, None))
    for i in range(-16, N + 6):
        for (a, b) in [((s0, i), (s1, i)), ((i, s0), (i, s1))]:
            p0, p1 = iso.v(*a), iso.v(*b)
            o.append(line(p0[0], p0[1], p1[0], p1[1], "#d3cabd", 1.0))
    for kk in (-1.3,):
        p0, p1 = iso.v(kk, -far), iso.v(kk, N + 6)
        o.append(line(p0[0], p0[1], p1[0], p1[1], "#d3cabd", 1.0))
        p0, p1 = iso.v(-far, kk), iso.v(N + 6, kk)
        o.append(line(p0[0], p0[1], p1[0], p1[1], "#d3cabd", 1.0))
    # meio-fio
    o.append(box3(D, iso, s0 - 0.14, -far, 0.14, far + N + 6, 4, "#d9dee5", bevel=False, sw=0.6))
    o.append(box3(D, iso, -far, s0 - 0.14, far + N + 6, 0.14, 4, "#d9dee5", bevel=False, sw=0.6))
    # faixas brancas tracejadas
    mid = (r0 + s0) / 2
    for i in range(-far, far):
        if -7 < i < -1:
            continue
        a, b = iso.v(mid, i + 0.1), iso.v(mid, i + 0.6)
        o.append(line(a[0], a[1], b[0], b[1], "#ffffff", 3.2))
        a, b = iso.v(i + 0.1, mid), iso.v(i + 0.6, mid)
        o.append(line(a[0], a[1], b[0], b[1], "#ffffff", 3.2))
    # faixa de pedestres na esquina
    for kk in range(7):
        y0 = r0 + 0.2 + kk * 0.58
        o.append(P([iso.v(s0 - 0.1, y0), iso.v(-0.9 + s0 + 0.2, y0), iso.v(-0.9 + s0 + 0.2, y0 + 0.32), iso.v(s0 - 0.1, y0 + 0.32)], "#ffffff", None, 'opacity="0.9"'))
    # bueiro e sinalização
    for (x, y) in [(6.0, s0 - 0.35), (s0 - 0.35, 8.5)]:
        pts_ = [iso.v(x, y), iso.v(x + 0.5, y), iso.v(x + 0.5, y + 0.22), iso.v(x, y + 0.22)] if y < 0 and x > 0 else \
               [iso.v(x, y), iso.v(x + 0.22, y), iso.v(x + 0.22, y + 0.5), iso.v(x, y + 0.5)]
        o.append(P(pts_, "#4c525d", "#3a3f48", 0.8))
    return "".join(o)


def lamp_post(D, x, y, s=1.0):
    o = [E(x, y, 11 * s, 4.5 * s, "#1a2a1a", None, extra='opacity="0.22"')]
    o.append(f'<rect x="{f(x-5*s)}" y="{f(y-10*s)}" width="{f(10*s)}" height="{f(10*s)}" rx="{f(2*s)}" fill="#3a4a66" stroke="{INK3}" stroke-width="1"/>')
    o.append(f'<rect x="{f(x-2.2*s)}" y="{f(y-92*s)}" width="{f(4.4*s)}" height="{f(84*s)}" fill="{D.lin([(0, "#6a7fa6"), (1, "#34446a")], 0, 0, 1, 0)}" stroke="{INK3}" stroke-width="1"/>')
    o.append(C(x, y - 104 * s, 28 * s, D.rad([(0, "#fff7b8", 0.7), (1, "#fff7b8", 0)]), None))
    o.append(path(f"M{f(x-9*s)},{f(y-92*s)} h{f(18*s)} l{f(-3*s)},{f(-20*s)} h{f(-12*s)} Z", D.lin([(0, "#fffbe0"), (1, "#ffd966")]), INK3, 1.1))
    o.append(path(f"M{f(x-11*s)},{f(y-112*s)} h{f(22*s)} l{f(-11*s)},{f(-8*s)} Z", "#3a4a66", INK3, 1.0))
    return "".join(o)


def flower_bed(D, x, y, s=1.0, cols=("#ff4d8d", "#ffd23f", "#ffffff", "#ff7a2f")):
    """Canteirinho de flores na grama."""
    o = [E(x, y + 2, 30 * s, 10 * s, "#3f9a2c", None, extra='opacity="0.45"')]
    r = Rng(int(x * 7 + y * 3))
    for (dx, dy, rr) in [(-16, -6, 10), (14, -6, 10), (0, -11, 12), (-4, -2, 11), (9, -1, 9)]:
        o.append(C(x + dx * s, y + dy * s, rr * s, D.rad([(0, "#a8f07a"), (0.6, "#4fc23f"), (1, "#2a8a32")], 0.35, 0.3, 0.75), "#1f6a2a", 1.0))
    for i in range(12):
        fx, fy = x + r.u(-24, 24) * s, y + r.u(-20, 2) * s
        c = cols[i % len(cols)]
        for j in range(5):
            b = math.radians(j * 72 + i * 11)
            o.append(C(fx + math.cos(b) * 2.3 * s, fy + math.sin(b) * 2.3 * s, 2.1 * s, c, INK3, 0.45))
        o.append(C(fx, fy, 1.3 * s, "#ffcf33" if c != "#ffd23f" else "#ff7a2f", None))
    return "".join(o)


def picket_fence(D, iso, x0, y0, x1, y1):
    """Cerquinha branca de madeira entre dois pontos (em células)."""
    o = []
    n = int(max(abs(x1 - x0), abs(y1 - y0)) * 4)
    for i in range(n + 1):
        t = i / n
        x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        px, py = iso.v(x, y)
        o.append(path(f"M{f(px-2.4)},{f(py)} L{f(px-2.4)},{f(py-20)} L{f(px)},{f(py-24)} L{f(px+2.4)},{f(py-20)} L{f(px+2.4)},{f(py)} Z",
                      D.lin([(0, "#ffffff"), (1, "#dfe6ee")], 0, 0, 1, 0), INK3, 0.8))
    for z in (7, 15):
        a, b = iso.v(x0, y0, z), iso.v(x1, y1, z)
        o.append(line(a[0], a[1], b[0], b[1], "#ffffff", 3.2) + line(a[0], a[1] + 1.6, b[0], b[1] + 1.6, "#c9d2dc", 1.0))
    return "".join(o)


def aframe_sign(D, iso, x, y):
    px, py = iso.v(x, y)
    o = [E(px, py, 16, 5, "#1a1a2a", None, extra='opacity="0.2"')]
    o.append(path(f"M{f(px-14)},{f(py)} L{f(px-8)},{f(py-46)} L{f(px+8)},{f(py-46)} L{f(px+14)},{f(py)}", "none", "#c96a2c", 3))
    o.append(path(f"M{f(px-12)},{f(py-4)} L{f(px-7)},{f(py-42)} L{f(px+7)},{f(py-42)} L{f(px+12)},{f(py-4)} Z", "#2f3b45", INK3, 1.1))
    o.append(f'<text x="{f(px)}" y="{f(py-27)}" text-anchor="middle" font-family="Fredoka, Nunito, sans-serif" font-weight="600" font-size="8.5" fill="#ffffff">Aberto</text>')
    o.append(path(f"M{f(px-6)},{f(py-18)} q6,-4 12,0", "none", "#ffd23f", 1.4))
    o.append(C(px - 4, py - 11, 2, "#ff4d8d", None) + C(px + 4, py - 11, 2, "#4fe0c0", None))
    return "".join(o)


# --- Paredes ----------------------------------------------------------------------------

def _wallpaper(D, length, dark_k=0.0):
    o = [f'<rect x="0" y="{-WALL_H}" width="{f(length)}" height="{WALL_H}" fill="{D.lin([(0, shade(MINT, dark_k)), (1, shade(MINT, dark_k + 0.05))])}"/>']
    x = 4
    while x < length:
        o.append(f'<rect x="{f(x)}" y="{-WALL_H+6}" width="9" height="{WALL_H-6-36}" fill="{shade(MINT_STRIPE, dark_k)}"/>')
        o.append(f'<rect x="{f(x+12)}" y="{-WALL_H+6}" width="1.4" height="{WALL_H-6-36}" fill="#ffffff" opacity="0.8"/>')
        x += 21
    # lambri branco com frisos e rodameio coral
    o.append(f'<rect x="0" y="-36" width="{f(length)}" height="36" fill="{shade("#ffffff", dark_k + 0.02)}"/>')
    x = 4
    while x + 26 < length:
        o.append(f'<rect x="{f(x)}" y="-30" width="26" height="22" rx="2" fill="none" stroke="{shade("#d8e2ee", dark_k)}" stroke-width="1.4"/>')
        x += 31
    o.append(f'<rect x="0" y="-39" width="{f(length)}" height="5.5" fill="{shade(CORAL, dark_k)}" stroke="{INK3}" stroke-width="0.7"/>')
    o.append(f'<rect x="0" y="-5" width="{f(length)}" height="5" fill="{shade(CORAL_D, dark_k)}"/>')
    o.append(f'<rect x="0" y="{-WALL_H}" width="{f(length)}" height="6" fill="{shade("#ffffff", dark_k)}" stroke="{INK3}" stroke-width="0.7"/>')
    # sombra suave no canto de cima e perto do chão
    o.append(f'<rect x="0" y="{-WALL_H+6}" width="{f(length)}" height="14" fill="{D.lin([(0, "#1a3a4a", 0.12), (1, "#1a3a4a", 0)])}"/>')
    return "".join(o)


def _kitchen_tiles(D, length, dark_k=0.04):
    o = [f'<rect x="0" y="{-WALL_H}" width="{f(length)}" height="{WALL_H}" fill="{shade("#fbfdff", dark_k)}"/>']
    step = 8
    for row in range(0, WALL_H, step):
        off = 0 if (row // step) % 2 == 0 else 8
        o.append(f'<line x1="0" y1="{-row}" x2="{f(length)}" y2="{-row}" stroke="#d5dee8" stroke-width="1"/>')
        x = off
        while x < length:
            o.append(f'<line x1="{f(x)}" y1="{-row}" x2="{f(x)}" y2="{-row-step}" stroke="#d5dee8" stroke-width="1"/>')
            x += 16
    o.append(f'<rect x="0" y="-44" width="{f(length)}" height="6" fill="{CORAL}" stroke="{INK3}" stroke-width="0.7"/>')
    o.append(f'<rect x="0" y="-5" width="{f(length)}" height="5" fill="#3a3f4a"/>')
    o.append(f'<rect x="0" y="{-WALL_H}" width="{f(length)}" height="6" fill="#ffffff" stroke="{INK3}" stroke-width="0.7"/>')
    return "".join(o)


def _window(D, u0, u1, z0=40, z1=86, curtain="#ffd23f"):
    w = u1 - u0
    o = [f'<rect x="{f(u0-4)}" y="{-z1-4}" width="{f(w+8)}" height="{z1-z0+8}" rx="2" fill="#ffffff" stroke="{INK3}" stroke-width="1.2"/>']
    o.append(f'<rect x="{f(u0+2)}" y="{-z1+2}" width="{f(w-4)}" height="{z1-z0-4}" fill="{D.lin([(0, "#6cc8ff"), (0.65, "#bfe9ff"), (1, "#e8f8ff")])}" stroke="{INK3}" stroke-width="0.9"/>')
    o.append(f'<ellipse cx="{f(u0+w*0.32)}" cy="{-z1+13}" rx="{f(w*0.2)}" ry="4.5" fill="#ffffff" opacity="0.95"/>')
    o.append(f'<ellipse cx="{f(u0+w*0.48)}" cy="{-z1+10}" rx="{f(w*0.14)}" ry="5.5" fill="#ffffff" opacity="0.95"/>')
    o.append(f'<path d="M{f(u0+2)},{-z0-8} Q{f(u0+w*0.3)},{-z0-18} {f(u0+w*0.55)},{-z0-12} T{f(u1-2)},{-z0-14} L{f(u1-2)},{-z0-2} L{f(u0+2)},{-z0-2} Z" fill="#8fe06a" opacity="0.9"/>')
    o.append(f'<path d="M{f(u0+6)},{-z0-4} L{f(u0+w*0.38)},{-z1+4} M{f(u0+w*0.26)},{-z0-4} L{f(u0+w*0.6)},{-z1+4}" stroke="#ffffff" stroke-width="3" opacity="0.6"/>')
    o.append(f'<rect x="{f(u0+w/2-1.6)}" y="{-z1+2}" width="3.2" height="{z1-z0-4}" fill="#ffffff" stroke="{INK3}" stroke-width="0.6"/>')
    o.append(f'<rect x="{f(u0+2)}" y="{f(-(z0+z1)/2-1.6)}" width="{f(w-4)}" height="3.2" fill="#ffffff" stroke="{INK3}" stroke-width="0.6"/>')
    o.append(f'<rect x="{f(u0-8)}" y="{-z0}" width="{f(w+16)}" height="5" rx="1.5" fill="#ffffff" stroke="{INK3}" stroke-width="1"/>')
    # cortinas de bolinhas presas com laço
    dots = D.raw("dots" + curtain[1:], f'<pattern id="dots{curtain[1:]}" patternUnits="userSpaceOnUse" width="8" height="8">'
                 f'<rect width="8" height="8" fill="{curtain}"/><circle cx="2" cy="2" r="1.3" fill="#ffffff" opacity="0.9"/>'
                 f'<circle cx="6" cy="6" r="1.3" fill="#ffffff" opacity="0.9"/></pattern>')
    for side in (0, 1):
        x0 = u0 - 9 if side == 0 else u1 - 5
        cw = 14
        tip = -cw / 2 if side == 0 else cw / 2
        d = (f"M{f(x0)},{-z1-8} h{cw} v{z1-z0-16} q{f(tip)},5 {f(tip)},20 h{f(-cw/2 if side == 0 else -cw*1.5)} "
             f"q{-2 if side == 0 else 2},-12 0,-24 Z")
        o.append(f'<path d="{d}" fill="{dots}" stroke="{INK3}" stroke-width="1"/>')
        o.append(f'<path d="{d}" fill="{D.lin([(0, "#000000", 0.12), (0.35, "#ffffff", 0.2), (0.7, "#000000", 0.0), (1, "#000000", 0.2)], 0, 0, 1, 0)}"/>')
        o.append(f'<rect x="{f(x0+1)}" y="{-z0-22}" width="{cw-2}" height="4" rx="2" fill="#ff4d8d" stroke="{INK3}" stroke-width="0.6"/>')
    o.append(f'<rect x="{f(u0-12)}" y="{-z1-12}" width="{f(w+24)}" height="5" rx="2.5" fill="#ffffff" stroke="{INK3}" stroke-width="0.9"/>')
    return "".join(o)


def _door(D, u0, u1, z1=80):
    w = u1 - u0
    o = [f'<rect x="{f(u0-5)}" y="{-z1-5}" width="{f(w+10)}" height="{z1+5}" rx="2" fill="#ffffff" stroke="{INK3}" stroke-width="1.2"/>']
    o.append(f'<rect x="{f(u0)}" y="{-z1}" width="{f(w)}" height="{z1}" fill="{D.lin([(0, "#ff8a3d"), (1, "#e2562a")], 0, 0, 1, 0)}" stroke="{INK3}" stroke-width="1"/>')
    o.append(f'<rect x="{f(u0+5)}" y="{-z1+6}" width="{f(w-10)}" height="{f(z1*0.52)}" rx="2" fill="{D.lin([(0, "#8fd8ff"), (1, "#e3f6ff")])}" stroke="{INK3}" stroke-width="0.9"/>')
    o.append(f'<path d="M{f(u0+9)},{f(-z1+36)} L{f(u0+w*0.55)},{f(-z1+9)}" stroke="#ffffff" stroke-width="3" opacity="0.7"/>')
    o.append(f'<rect x="{f(u0+5)}" y="{f(-z1*0.4)}" width="{f(w-10)}" height="{f(z1*0.3)}" rx="2" fill="none" stroke="{shade("#e2562a", 0.2)}" stroke-width="1.2"/>')
    o.append(f'<circle cx="{f(u1-7)}" cy="{f(-z1*0.46)}" r="2.6" fill="#ffd23f" stroke="{INK3}" stroke-width="0.8"/>')
    # plaquinha "Aberto"
    o.append(f'<path d="M{f(u0+w*0.3)},{f(-z1+20)} L{f(u0+w/2)},{f(-z1+13)} L{f(u0+w*0.7)},{f(-z1+20)}" stroke="#6a4a2a" stroke-width="0.8" fill="none"/>')
    o.append(f'<rect x="{f(u0+w*0.2)}" y="{f(-z1+20)}" width="{f(w*0.6)}" height="11" rx="2" fill="#ffffff" stroke="{INK3}" stroke-width="0.8"/>')
    o.append(f'<text x="{f(u0+w/2)}" y="{f(-z1+28.6)}" text-anchor="middle" font-family="Fredoka, Nunito, sans-serif" font-weight="700" font-size="7.4" fill="#2fae3a">ABERTO</text>')
    return "".join(o)


def _neon(D, u, z, text="Café"):
    glow = D.blur(2.4)
    o = [f'<rect x="{f(u-4)}" y="{f(-z-26)}" width="{f(len(text)*15+30)}" height="30" rx="6" fill="#3a2a5a" stroke="{INK3}" stroke-width="1"/>']
    t = (f'font-family="Fredoka, Nunito, sans-serif" font-weight="600" font-size="22" text-anchor="start"')
    o.append(f'<text x="{f(u+24)}" y="{f(-z-4)}" {t} fill="none" stroke="#ff4da6" stroke-width="4" filter="{glow}" opacity="0.9">{text}</text>')
    o.append(f'<text x="{f(u+24)}" y="{f(-z-4)}" {t} fill="#ffe3f3" stroke="#ff4da6" stroke-width="1.2">{text}</text>')
    # xícara de neon
    cup = f"M{f(u+3)},{f(-z-18)} h14 l-2,11 h-10 Z M{f(u+17)},{f(-z-16)} q5,0 4,5 q-1,3 -5,2"
    o.append(f'<path d="{cup}" fill="none" stroke="#4fe0ff" stroke-width="3.6" filter="{glow}" opacity="0.9"/>')
    o.append(f'<path d="{cup}" fill="none" stroke="#e8fcff" stroke-width="1.3"/>')
    o.append(f'<path d="M{f(u+7)},{f(-z-21)} q-2,-3 0,-5 M{f(u+12)},{f(-z-21)} q-2,-3 0,-5" fill="none" stroke="#4fe0ff" stroke-width="1.3"/>')
    return "".join(o)


def _clock(D, u, z, r=11):
    o = [f'<circle cx="{f(u)}" cy="{f(-z)}" r="{r+2}" fill="#ff4d5e" stroke="{INK3}" stroke-width="1.1"/>']
    o.append(f'<circle cx="{f(u)}" cy="{f(-z)}" r="{r}" fill="#ffffff" stroke="{INK3}" stroke-width="0.8"/>')
    for i in range(12):
        a = math.radians(i * 30)
        o.append(line(u + math.cos(a) * (r - 2.5), -z + math.sin(a) * (r - 2.5), u + math.cos(a) * (r - 1), -z + math.sin(a) * (r - 1), "#3a3f4a", 1.0))
    o.append(line(u, -z, u + 5, -z - 3, "#2a2a33", 1.6) + line(u, -z, u - 1, -z - 8, "#2a2a33", 1.2) + C(u, -z, 1.4, "#ff4d5e", None))
    return "".join(o)


def _frame(D, u, z, w, h, kind="donut", frame="#ffd23f"):
    o = [f'<rect x="{f(u)}" y="{f(-z-h)}" width="{f(w)}" height="{f(h)}" rx="2" fill="{D.lin([(0, tint(frame, 0.3)), (1, shade(frame, 0.15))])}" stroke="{INK3}" stroke-width="1.1"/>']
    ix, iy, iw, ih = u + 4, -z - h + 4, w - 8, h - 8
    if kind == "donut":
        o.append(f'<rect x="{f(ix)}" y="{f(iy)}" width="{f(iw)}" height="{f(ih)}" fill="#8fd8ff"/>')
        cx, cy, r = ix + iw / 2, iy + ih / 2, min(iw, ih) * 0.34
        o.append(f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="#f2b36a" stroke="{INK3}" stroke-width="0.8"/>')
        o.append(f'<path d="M{f(cx-r*0.9)},{f(cy-r*0.1)} q{f(r*0.3)},{f(-r*0.9)} {f(r*0.9)},{f(-r*0.9)} q{f(r*0.9)},0 {f(r*0.95)},{f(r*0.8)} q{f(-r*0.5)},{f(r*0.3)} {f(-r*0.9)},0 q{f(-r*0.5)},{f(r*0.2)} {f(-r*0.95)},{f(r*0.1)} Z" fill="#ff7ab8"/>')
        o.append(f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r*0.32)}" fill="#8fd8ff" stroke="{INK3}" stroke-width="0.8"/>')
        for (dx, dy, c) in [(-0.5, -0.4, "#ffffff"), (0.3, -0.6, "#ffd23f"), (0.6, -0.1, "#4fe0c0"), (-0.2, -0.75, "#4d8dff")]:
            o.append(f'<rect x="{f(cx+dx*r)}" y="{f(cy+dy*r)}" width="3" height="1.2" rx="0.6" fill="{c}" transform="rotate(35 {f(cx+dx*r)} {f(cy+dy*r)})"/>')
    elif kind == "cupcake":
        o.append(f'<rect x="{f(ix)}" y="{f(iy)}" width="{f(iw)}" height="{f(ih)}" fill="#ffe36b"/>')
        cx, cy = ix + iw / 2, iy + ih * 0.6
        o.append(f'<path d="M{f(cx-8)},{f(cy)} l2,{f(ih*0.3)} h12 l2,{f(-ih*0.3)} Z" fill="#ff8fb1" stroke="{INK3}" stroke-width="0.8"/>')
        o.append(f'<path d="M{f(cx-9)},{f(cy)} q0,-9 9,-10 q9,1 9,10 Z" fill="#ffffff" stroke="{INK3}" stroke-width="0.8"/>')
        o.append(f'<circle cx="{f(cx)}" cy="{f(cy-11)}" r="2.2" fill="#ff3b5c" stroke="{INK3}" stroke-width="0.6"/>')
    else:
        o.append(f'<rect x="{f(ix)}" y="{f(iy)}" width="{f(iw)}" height="{f(ih)}" fill="{D.lin([(0, "#7fd3ff"), (1, "#e6f7ff")])}"/>')
        o.append(f'<path d="M{f(ix)},{f(iy+ih)} L{f(ix)},{f(iy+ih*0.62)} Q{f(ix+iw*0.3)},{f(iy+ih*0.35)} {f(ix+iw*0.55)},{f(iy+ih*0.6)} '
                 f'Q{f(ix+iw*0.8)},{f(iy+ih*0.42)} {f(ix+iw)},{f(iy+ih*0.55)} L{f(ix+iw)},{f(iy+ih)} Z" fill="#5fd35f"/>')
        o.append(f'<circle cx="{f(ix+iw*0.76)}" cy="{f(iy+ih*0.28)}" r="{f(ih*0.12)}" fill="#ffd23f"/>')
    return "".join(o)


def _menu_board(D, u, z, w=96, h=50):
    o = [f'<rect x="{f(u)}" y="{f(-z-h)}" width="{w}" height="{h}" rx="4" fill="#ff8a3d" stroke="{INK3}" stroke-width="1.2"/>']
    o.append(f'<rect x="{f(u+4)}" y="{f(-z-h+4)}" width="{w-8}" height="{h-8}" rx="3" fill="#2f3b45"/>')
    o.append(f'<text x="{f(u+w/2)}" y="{f(-z-h+16)}" text-anchor="middle" font-family="Fredoka, Nunito, sans-serif" font-weight="600" font-size="10.5" fill="#ffe36b">CARDÁPIO</text>')
    rows = [("Café", "#ffffff"), ("Pão de queijo", "#8fe3ff"), ("Misto-quente", "#ff9ec6"), ("Bolo", "#b8f5a0")]
    for i, (n, c) in enumerate(rows):
        y = -z - h + 25 + i * 6.6
        o.append(f'<text x="{f(u+9)}" y="{f(y)}" font-family="Nunito, sans-serif" font-weight="800" font-size="5.6" fill="{c}">{n}</text>')
        o.append(f'<line x1="{f(u+46)}" y1="{f(y-1.6)}" x2="{f(u+w-18)}" y2="{f(y-1.6)}" stroke="{c}" stroke-width="0.6" stroke-dasharray="1 1.4" opacity="0.7"/>')
        o.append(f'<circle cx="{f(u+w-12)}" cy="{f(y-2)}" r="2.2" fill="#ffd23f"/>')
    return "".join(o)


def _shelf(D, u, z, w, items):
    o = [f'<rect x="{f(u)}" y="{f(-z)}" width="{f(w)}" height="4" rx="1" fill="#ffffff" stroke="{INK3}" stroke-width="0.9"/>']
    x = u + 5
    for (kind, col) in items:
        if kind == "pote":
            o.append(f'<rect x="{f(x)}" y="{f(-z-13)}" width="9" height="13" rx="2" fill="{col}" stroke="{INK3}" stroke-width="0.8"/>'
                     f'<rect x="{f(x-0.5)}" y="{f(-z-15)}" width="10" height="3" rx="1" fill="#ffffff" stroke="{INK3}" stroke-width="0.7"/>'
                     f'<rect x="{f(x+2)}" y="{f(-z-10)}" width="5" height="4" rx="1" fill="#ffffff" opacity="0.8"/>')
            x += 13
        elif kind == "planta":
            o.append(f'<rect x="{f(x)}" y="{f(-z-8)}" width="10" height="8" rx="2" fill="{col}" stroke="{INK3}" stroke-width="0.8"/>')
            for (dx, dy, a) in [(5, -12, -30), (3, -13, -70), (7, -13, 20), (5, -15, -5)]:
                o.append(f'<ellipse cx="{f(x+dx)}" cy="{f(-z+dy)}" rx="5" ry="2.4" fill="#4fcf4f" stroke="#1d6b33" stroke-width="0.6" transform="rotate({a} {f(x+dx)} {f(-z+dy)})"/>')
            x += 15
        elif kind == "xicara":
            o.append(f'<path d="M{f(x)},{f(-z-8)} h9 l-1,7 h-7 Z" fill="{col}" stroke="{INK3}" stroke-width="0.8"/>'
                     f'<path d="M{f(x+9)},{f(-z-7)} q3,0 2,3 q-1,2 -3,1" fill="none" stroke="{INK3}" stroke-width="0.9"/>')
            x += 14
    return "".join(o)


def walls(D, iso):
    o = []
    L = N * iso.W / 2
    # parede da direita (y = 0)
    right = [_wallpaper(D, L, 0.0)]
    u = lambda cells: cells * iso.W / 2
    right.append(_kitchen_tiles(D, u(2.6), 0.0))
    right.append(_shelf(D, u(0.3), 54, u(2.0), [("pote", "#ff4d5e"), ("pote", "#ffd23f"), ("pote", "#4fe0c0"), ("xicara", "#ffffff"), ("xicara", "#ff8fb1")]))
    right.append(_clock(D, u(1.3), 82))
    right.append(_menu_board(D, u(3.1), 48, u(2.3), 46))
    right.append(_window(D, u(5.7), u(6.8), curtain="#ffd23f"))
    right.append(_neon(D, u(7.25), 64, "Café"))
    right.append(_window(D, u(9.35), u(10.3), curtain="#ffd23f"))
    right.append(_door(D, u(10.75), u(11.7)))
    o.append(g("".join(right), plane(iso, "R", 0, 0)))
    # parede da esquerda (x = 0): azulejo até y = KITCHEN_Y e papel de parede depois
    left = [_wallpaper(D, L, 0.07)]
    left.append(g(_kitchen_tiles(D, u(KITCHEN_Y), 0.06), f"translate({f(u(N - KITCHEN_Y))},0)"))
    left.append(_frame(D, u(0.9), 44, 30, 36, "cupcake", "#ff4d8d"))
    left.append(_window(D, u(1.9), u(3.2), curtain="#ff4d8d"))
    left.append(_frame(D, u(3.7), 46, 36, 30, "paisagem", "#4d8dff"))
    left.append(_shelf(D, u(N - 6.6), 62, u(5.2), [("pote", "#ffd23f"), ("pote", "#ff4d5e"), ("planta", "#ff8fb1"), ("pote", "#4fe0c0"),
                                                     ("xicara", "#ffffff"), ("pote", "#b06bff"), ("planta", "#ffd23f"), ("pote", "#ff7a2f")]))
    o.append(g("".join(left), plane(iso, "L", 0, N)))
    # topo das paredes (espessura branca) e pontas
    t = 0.16
    o.append(P([iso.v(-t, -t, WALL_H), iso.v(N, -t, WALL_H), iso.v(N, 0, WALL_H), iso.v(0, 0, WALL_H)], "#ffffff", INK3, 1.0))
    o.append(P([iso.v(-t, -t, WALL_H), iso.v(0, 0, WALL_H), iso.v(0, N, WALL_H), iso.v(-t, N, WALL_H)], "#f3f6fa", INK3, 1.0))
    o.append(P([iso.v(N, -t, 0), iso.v(N, 0, 0), iso.v(N, 0, WALL_H), iso.v(N, -t, WALL_H)], "#e6ebf2", INK3, 1.0))
    o.append(P([iso.v(-t, N, 0), iso.v(0, N, 0), iso.v(0, N, WALL_H), iso.v(-t, N, WALL_H)], "#dfe5ee", INK3, 1.0))
    # coifa sobre os fogões
    o.append(box3(D, iso, 0.0, 0.9, 0.7, 5.2, 14, "#dfe6ee", z=74, top="#f4f7fa"))
    o.append(box3(D, iso, 0.0, 1.2, 0.34, 4.6, 12, "#c9d3de", z=88, top="#e6ebf2"))
    return "".join(o)


def floor(D, iso):
    o = []
    r = Rng(17)
    woods = ["#f6c98a", "#f0bc78", "#f9d49c", "#ecb46c", "#f4c483"]
    rows = N * 4
    for j in range(rows):
        y0, y1 = j / 4, (j + 1) / 4
        x = -r.u(0, 2.0)
        while x < N:
            ln = r.u(1.6, 3.2)
            a, b = max(0.0, x), min(float(N), x + ln)
            if b > a:
                c = woods[int(r.u(0, len(woods)))]
                o.append(P([iso.v(a, y0), iso.v(b, y0), iso.v(b, y1), iso.v(a, y1)], c, "#c98d4a", 0.5))
                gx0, gx1 = a + (b - a) * r.u(0.1, 0.3), a + (b - a) * r.u(0.6, 0.9)
                gy = y0 + (y1 - y0) * r.u(0.3, 0.7)
                p0, p1 = iso.v(gx0, gy), iso.v(gx1, gy)
                o.append(line(p0[0], p0[1], p1[0], p1[1], "#d99a55", 0.7, 'opacity="0.55"'))
            x += ln
    # piso de cozinha xadrez preto e branco
    for yy in range(KITCHEN_Y * 2):
        for xx in range(KITCHEN_X * 2):
            x0, y0 = xx / 2, yy / 2
            c = "#2c2f3d" if (xx + yy) % 2 == 0 else "#f6f8fc"
            o.append(P([iso.v(x0, y0), iso.v(x0 + 0.5, y0), iso.v(x0 + 0.5, y0 + 0.5), iso.v(x0, y0 + 0.5)], c, "#00000022", 0.4))
    o.append(P([iso.v(0, 0), iso.v(KITCHEN_X, 0), iso.v(KITCHEN_X, KITCHEN_Y), iso.v(0, KITCHEN_Y)],
               D.lin([(0, "#ffffff", 0.18), (0.5, "#ffffff", 0.0), (1, "#ffffff", 0.08)], 0, 0, 1, 1), None))
    o.append(P([iso.v(KITCHEN_X, 0), iso.v(KITCHEN_X, KITCHEN_Y), iso.v(0, KITCHEN_Y)], "none", "#9aa6b8", 2.0))
    # tapete de entrada listrado (da porta para dentro)
    o.append(P([iso.v(10.5, 0.2), iso.v(11.7, 0.2), iso.v(11.7, 3.6), iso.v(10.5, 3.6)], "#ff4d5e", INK3, 1.0))
    for i in range(1, 6):
        yy = 0.2 + i * 0.57
        o.append(P([iso.v(10.5, yy - 0.12), iso.v(11.7, yy - 0.12), iso.v(11.7, yy + 0.08), iso.v(10.5, yy + 0.08)], "#ffffff", None, 'opacity="0.85"'))
    # luz das janelas no chão
    for (a, b) in ((5.7, 6.8), (9.35, 10.3)):
        o.append(P([iso.v(a + 0.4, 0.05), iso.v(b + 0.4, 0.05), iso.v(b + 2.2, 2.6), iso.v(a + 2.2, 2.6)], "#fffbe0", None, 'opacity="0.35"'))
    # sombra de canto junto às paredes
    o.append(P([iso.v(0, 0), iso.v(N, 0), iso.v(N, 0.45), iso.v(0.45, 0.45)], D.lin([(0, "#3a2a1a", 0.22), (1, "#3a2a1a", 0)], 0, 0, 0, 1), None))
    o.append(P([iso.v(0, 0), iso.v(0.45, 0.45), iso.v(0.45, N), iso.v(0, N)], D.lin([(0, "#3a2a1a", 0.2), (1, "#3a2a1a", 0)], 0, 0, 1, 0), None))
    # borda da laje na frente
    th = 7
    o.append(P([iso.v(0, N, 0), iso.v(N, N, 0), iso.v(N, N, -th), iso.v(0, N, -th)], D.lin([(0, "#ffffff"), (1, "#d7dee8")]), INK3, 1.0))
    o.append(P([iso.v(N, 0, 0), iso.v(N, N, 0), iso.v(N, N, -th), iso.v(N, 0, -th)], D.lin([(0, "#e8edf4"), (1, "#c3ccd8")]), INK3, 1.0))
    o.append(P([iso.v(0, 0), iso.v(N, 0), iso.v(N, N), iso.v(0, N)], "none", INK3, 1.4))
    return "".join(o)


# --- Montagem ---------------------------------------------------------------------------

SKINS = ["clara", "morena", "negra", "rosada", "parda", "morena_clara"]
CUSTOMERS = [
    # (cadeira x, y, voltado, pele, cabelo, roupa, calça, expressão, pedido, extras)
    (4, 2, "+x", "clara", ("rabo", "castanho"), ("blusa", "#ff4d6d"), ("calca", "#3b6fd6"), "feliz", ("balao", "cafe", 0.9), dict(lash=True, iris="#3b7fd9")),
    (6, 2, "-x", "morena", ("curto", "preto"), ("camiseta", "#2fae4e"), ("calca", "#34495e"), "feliz", None, {}),
    (4, 3, "+x", "negra", ("black", "preto"), ("camiseta", "#ffc928"), ("calca", "#2fae4e"), "comendo", ("prato", "bolo"), dict(lash=True, earrings="#ffc928")),
    (6, 3, "-x", "clara", ("chanel", "ruivo"), ("blusa", "#9b5cff"), ("calca", "#34495e"), "feliz", None, dict(lash=True)),
    (4, 4, "+x", "parda", ("bone", "preto"), ("moletom", "#ff7a2f"), ("calca", "#2b2b33"), "esperando", ("balao", "misto", 0.4), dict(cap="#2f7bff")),
    (6, 4, "-x", "rosada", ("longo", "loiro"), ("blusa", "#2fd1b5"), ("calca", "#3d5a80"), "feliz", None, {}),
    (4, 5, "+x", "morena_clara", ("topete", "castanho_escuro"), ("camisa", "#35b8ff"), ("calca", "#34495e"), "feliz", ("prato", "misto"), {}),
    (4, 8, "+x", "clara", ("coque", "grisalho"), ("blusa", "#ff5fa2"), ("saia", "#6b4b8a"), "feliz", ("humor", "feliz"), dict(lash=True, glasses="#7a4bd6")),
    (6, 8, "-x", "negra", ("coque", "preto"), ("blusa", "#35b8ff"), ("calca", "#34495e"), "feliz", None, {}),
    (4, 9, "+x", "morena", ("careca", "castanho_escuro"), ("camisa", "#ffffff"), ("calca", "#6b4423"), "bravo", ("humor", "bravo"), dict(beard="castanho_escuro")),
    (6, 9, "-x", "clara", ("franja", "castanho"), ("camiseta", "#ff4d5e"), ("calca", "#2b8cff"), "feliz", None, {}),
    (4, 10, "+x", "parda", ("moicano", "verde"), ("camiseta", "#1d1d2b"), ("calca", "#4a4a5e"), "esperando", ("balao", "coxinha", 0.2), {}),
    (8, 2, "+x", "morena_clara", ("longo", "castanho"), ("vestido", "#ffd23f"), ("saia", "#ffd23f"), "feliz", ("balao", "pao", 0.75), dict(lash=True, iris="#2f9e62")),
    (8, 5, "+x", "clara", ("curto", "loiro"), ("camiseta", "#4d8dff"), ("calca", "#34495e"), "comendo", ("prato", "lasanha"), {}),
    (10, 5, "-x", "negra", ("black", "preto"), ("blusa", "#ff8fb1"), ("calca", "#34495e"), "feliz", None, dict(lash=True)),
    (8, 8, "+x", "morena", ("rabo", "preto"), ("blusa", "#4fe0c0"), ("calca", "#3b6fd6"), "feliz", ("balao", "lasanha", 0.6), dict(lash=True)),
    (10, 8, "-x", "rosada", ("topete", "ruivo"), ("moletom", "#b06bff"), ("calca", "#34495e"), "feliz", None, {}),
]
LONG_TABLES = [(5, [2, 3, 4, 5], "#ff4d5e", "#ff4d5e"), (5, [8, 9, 10], "#ffd23f", "#ffb400")]
ROUND_TABLES = [((9, 2), "#ff4d8d"), ((9, 5), "#2ec4b6"), ((9, 8), "#ff7a2f")]
STOVES = [((0, 1), "lasanha", 0.7, "2:40", False), ((0, 2), "pao", 1.0, "", True), ((0, 3), "misto", 0.35, "0:58", False),
          ((0, 4), "cafe", 0.85, "0:03", False), ((0, 5), "bolo", 0.2, "5:12", False)]
COUNTERS = [((2, 1), [("cafe", 12)]), ((2, 2), [("pao", 16)]), ((2, 3), [("misto", 8)]), ((2, 4), [("bolo", 8)]), ((2, 5), [("coxinha", 10)])]
PERSON_SCALE = 0.6


def build(D, iso, with_overlay=True):
    k = K(iso)
    items = []
    overlay = []

    def add(depth, svg):
        items.append((depth, svg))

    add(0.5, fridge(D, iso, 0, 0))
    add(6.5, sink(D, iso, 0, 6))
    for (cell, cook, prog, lab, ready) in STOVES:
        add(cell[0] + cell[1] + 0.5, stove(D, iso, cell[0], cell[1], "R", cooking=cook, enamel="#ff4d5e"))
        bx, by = iso.v(cell[0] + 0.5, cell[1] + 0.5, 104)
        overlay.append(cooking_badge(D, cook, bx, by, prog, lab, ready, r=15))
    for (cell, dishes) in COUNTERS:
        add(cell[0] + cell[1] + 0.5, counter(D, iso, cell[0], cell[1], "R", dishes, body="#2ec4b6"))
    add(3.5, espresso(D, iso, 3, 0))
    add(4.5, pastry_case(D, iso, 4, 0))
    add(7.5, jukebox(D, iso, 7, 0))
    add(6.5, plant(D, iso, 6, 0, pot="#4d8dff", seed=4))
    add(5.5, plant(D, iso, 5, 0, pot="#ff8fb1", big=False, seed=8))
    add(9.5, aquarium(D, iso, 0, 9))
    add(8.5, plant(D, iso, 0, 8, pot="#ffd23f", seed=6))
    add(11.5, plant(D, iso, 0, 11, pot="#ff4d5e", big=False, seed=2))
    add(22.5, flower_vase(D, iso, 11, 11))
    add(7.5, floor_lamp(D, iso, 0, 7, "#ff8fb1"))
    served = {(c[0], c[1]): c[8][1] for c in CUSTOMERS if c[8] and c[8][0] == "prato"}
    for (tx, ys, edge, _) in LONG_TABLES:
        for i, ty in enumerate(ys):
            joined = ("-y" if i > 0 else "") + ("+y" if i < len(ys) - 1 else "")
            dishes = [served[(cx, cy)] for (cx, cy) in served if cy == ty and abs(cx - tx) == 1]
            add(tx + ty + 0.5, table_square(D, iso, tx, ty, "#ffffff", edge, dishes=dishes, vase=(i % 2 == 0), joined=joined))
    for ((tx, ty), cloth) in ROUND_TABLES:
        dishes = [served[(cx, cy)] for (cx, cy) in served if cy == ty and abs(cx - tx) == 1]
        add(tx + ty + 0.5, table_round(D, iso, tx, ty, cloth, dishes=dishes))
    occupied = {(c[0], c[1]) for c in CUSTOMERS}
    chair_color = {}
    for (tx, ys, edge, _) in LONG_TABLES:
        for ty in ys:
            chair_color[(tx - 1, ty)] = edge
            chair_color[(tx + 1, ty)] = edge
    for ((tx, ty), cloth) in ROUND_TABLES:
        chair_color[(tx - 1, ty)] = cloth
        chair_color[(tx + 1, ty)] = cloth
    for (cx, cy), col in chair_color.items():
        if (cx, cy) in occupied:
            continue
        fc = "+x" if cx < 7 and (cx == 4 or cx == 8) else "-x"
        ch = chair(D, iso, cx, cy, fc, col)
        add(cx + cy + 0.4, ch if isinstance(ch, str) else ch[0] + ch[1])
    for (cx, cy, fc, skin, hair, top, bottom, expr, need, extra) in CUSTOMERS:
        col = chair_color.get((cx, cy), "#ff4d5e")
        ch = chair(D, iso, cx, cy, fc, col)
        sx, sy = seat_point(iso, cx, cy)
        sy += 4 * k
        mirror = {"+x": 1, "+y": -1, "-x": -1, "-y": 1}[fc]
        is_back = fc in ("-x", "-y")
        who = person(D, sx, sy, PERSON_SCALE, mirror, "sentado", skin, hair, top, bottom, expr=expr, back=is_back, **extra)
        if is_back:
            add(cx + cy + 0.4, ch[0] + who + ch[1])
        else:
            add(cx + cy + 0.4, ch + who)
        if need:
            top_y = head_top(sy, PERSON_SCALE, "sentado")
            if need[0] == "balao":
                overlay.append(balloon(D, need[1], sx + 4 * mirror, top_y - 2, 30, patience=need[2]))
            elif need[0] == "humor":
                overlay.append(mood_face(D, sx + 14 * mirror, top_y - 2, need[1], 10))
    # equipe
    wx, wy = iso.v(7.3, 6.4)
    add(13.9, person(D, wx, wy, PERSON_SCALE, 1, "andar", "morena_clara", ("curto", "preto"), ("garcom", "#ffffff"), ("calca", "#23232b"),
                     tray="misto", shoes="#2b2b33"))
    cx_, cy_ = iso.v(1.5, 3.5)
    add(5.2, person(D, cx_, cy_, PERSON_SCALE, 1, "em_pe", "negra", ("black", "preto"), ("chef", "#ffffff"), ("calca", "#3b4a55"),
                    apron="#ffffff", hat="chef", lash=True, earrings="#ffc928"))
    # clientes chegando pela porta
    for (gx, gy, skin, hair, top, bottom, facing, ex) in [
        (11.1, 1.3, "clara", ("rabo", "loiro"), ("camiseta", "#ff4d6d"), ("calca", "#3b6fd6"), -1, dict(lash=True, iris="#3b7fd9")),
        (11.3, 2.6, "parda", ("curto", "preto"), ("camiseta", "#ffd23f"), ("short", "#2b8cff"), -1, {}),
        (10.9, 4.0, "morena", ("chanel", "castanho_escuro"), ("vestido", "#b06bff"), ("saia", "#b06bff"), -1, dict(lash=True)),
    ]:
        px, py = iso.v(gx, gy)
        add(gx + gy + 0.6, person(D, px, py, PERSON_SCALE, facing, "andar", skin, hair, top, bottom, **ex))
    items.sort(key=lambda it: it[0])
    return "".join(s for _, s in items), "".join(overlay)


def floaters(iso):
    out = []
    for (x, y, z, txt, col) in [(5.6, 3.2, 120, "+18", "#ffd23f"), (9.4, 5.2, 118, "+6 XP", "#8fe3ff")]:
        fx, fy = iso.v(x, y, z)
        style = 'font-family="Fredoka, Nunito, sans-serif" font-weight="700" font-size="18" text-anchor="middle"'
        out.append(f'<text x="{f(fx)}" y="{f(fy)}" {style} fill="none" stroke="#2a2a4a" stroke-width="5" stroke-linejoin="round">{txt}</text>'
                   f'<text x="{f(fx)}" y="{f(fy)}" {style} fill="{col}">{txt}</text>')
        if txt.startswith("+1"):
            out.append(f'<circle cx="{f(fx-30)}" cy="{f(fy-6)}" r="8" fill="#ffc928" stroke="#b07a00" stroke-width="1.4"/>'
                       f'<circle cx="{f(fx-30)}" cy="{f(fy-6)}" r="4.6" fill="none" stroke="#fff3b0" stroke-width="1.2"/>')
    return "".join(out)


def scene_svg(width=1280, height=720, ox=640, oy=140, scale=1.0, overlay=True, inner_only=False):
    D = Defs()
    iso = Iso(0, 0, TW, TH)
    body, over = build(D, iso)
    ext = street(D, iso)
    back_deco = []
    for (x, y) in [(-1.4, 13.6), (13.6, -1.4)]:
        p = iso.v(x, y)
        back_deco.append(lamp_post(D, p[0], p[1], 0.85))
    front_deco = []
    for (x, y) in [(3.0, 13.4), (13.4, 6.6), (8.6, 13.3)]:
        p = iso.v(x, y)
        front_deco.append(flower_bed(D, p[0], p[1], 0.9))
    front_deco.append(picket_fence(D, iso, 12.9, 8.2, 12.9, 12.9))
    front_deco.append(picket_fence(D, iso, 5.0, 12.9, 12.9, 12.9))
    content = (f'<rect x="0" y="0" width="{width}" height="{height}" fill="{lawn(D)}"/>'
               f'<g transform="translate({ox},{oy}) scale({scale})">{ext}{"".join(back_deco)}{walls(D, iso)}{floor(D, iso)}'
               f'{body}{"".join(front_deco)}{over if overlay else ""}{floaters(iso) if overlay else ""}</g>')
    if inner_only:
        return D.render() + content
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">'
            + D.render() + content + "</svg>")


if __name__ == "__main__":
    from prev import page, out
    open(out("scene.html"), "w").write(page(scene_svg()))
