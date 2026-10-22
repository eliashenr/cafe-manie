"""Crítico, cupons e loja de troca (DT-061 e DT-062): o ícone do cupom, o selo do crítico e os enfeites exclusivos que
só se trocam por cupons (1 piso cada, o mesmo desenho nas 4 rotações)."""
from core3 import *
from furniture3 import K
from icons3 import _gloss

OL = "#33283a"


def coupon(D):
    """Cupom: tíquete rosa com a borda picotada e uma estrela dourada."""
    o = [P([(9, 20), (55, 14), (59, 44), (13, 50)], "#b8326a", OL, 2.2)]
    o.append(P([(8, 18), (54, 12), (58, 42), (12, 48)], D.lin([(0, "#ff8ab8"), (1, "#e0457f")]), OL, 2.2))
    for t in (0.25, 0.5, 0.75):  # picote
        x, y = 8 + 4 * t + 9, 18 + 30 * t
        o.append(C(x - 9 + 2, y, 1.6, "#ffffff", None))
    o.append(path("M20,17 L24,47", "none", "#ffffff", 1.6, 'stroke-dasharray="3,3" opacity="0.9"'))
    pts = []
    for i in range(10):
        a = math.radians(-90 + i * 36)
        rr = 10 if i % 2 == 0 else 4.4
        pts.append((39 + rr * math.cos(a), 30 + rr * math.sin(a)))
    o.append(P(pts, D.rad([(0, "#fff7c2"), (1, "#ffb400")]), OL, 1.6))
    o.append(_gloss("M12,22 L30,19 L31,24 L13,27 Z", 0.35))
    return "".join(o)


def critic_badge(D):
    """Selo do crítico: medalha dourada com um monóculo, presa numa fita vermelha."""
    o = [P([(22, 4), (30, 4), (34, 26), (26, 22)], "#e0303a", OL, 2.0), P([(42, 4), (34, 4), (30, 26), (38, 22)], "#ff5a5f", OL, 2.0)]
    o.append(C(32, 38, 20, D.rad([(0, "#fff6b0"), (0.6, "#ffc928"), (1, "#e08a00")], 0.4, 0.35, 0.8), OL, 2.2))
    o.append(C(32, 38, 14, "none", "#b36b00", 2.0))
    o.append(C(29, 36, 7, "#e9f6ff", OL, 2.0) + path("M35,40 q4,4 2,9", "none", OL, 1.8))
    o.append(_gloss("M17,32 C19,24 26,20 33,20 C26,23 21,27 19,34 Z", 0.55))
    return "".join(o)


ICONS = {"cupom": coupon, "critico": critic_badge}


# --- Enfeites exclusivos da loja de cupons -----------------------------------------------------

def _pedestal(D, iso, cx, cy, k, h=26, color="#f4efe6"):
    return box3(D, iso, cx - 0.25, cy - 0.25, 0.5, 0.5, h * k, color, top=tint(color, 0.3), sw=1.0)


def critic_statue(D, iso, x, y):
    """Estátua do Crítico: um chapéu de chef dourado sobre um pedestal de mármore com uma estrela."""
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    o = [soft_shadow(D, iso, cx, cy, 0.32, opacity=0.28), _pedestal(D, iso, cx, cy, k, 30)]
    sx, sy = iso.v(cx, cy, 30 * k)
    gold = D.lin([(0, "#fff3a8"), (0.4, "#ffc928"), (1, "#c98a00")], 0, 0, 1, 0)
    o.append(path(f"M{f(sx - 14 * k)},{f(sy)} L{f(sx - 13 * k)},{f(sy - 16 * k)} L{f(sx + 13 * k)},{f(sy - 16 * k)} L{f(sx + 14 * k)},{f(sy)} Z",
                  gold, INK3, 1.1))
    for dx, dy, r in [(-10, -24, 9), (0, -30, 11), (10, -24, 9)]:
        o.append(C(sx + dx * k, sy + dy * k, r * k, gold, INK3, 1.1))
    o.append(path(f"M{f(sx - 13 * k)},{f(sy - 16 * k)} L{f(sx + 13 * k)},{f(sy - 16 * k)}", "none", "#c98a00", 1.6 * k))
    px, py = iso.v(cx, cy + 0.25, 14 * k)
    pts = []
    for i in range(10):
        a = math.radians(-90 + i * 36)
        rr = (6 if i % 2 == 0 else 2.6) * k
        pts.append((px - 6 * k + rr * math.cos(a), py + rr * math.sin(a)))
    o.append(P(pts, "#ffc928", INK3, 0.7))
    return "".join(o)


def chocolate_fountain(D, iso, x, y):
    """Fonte de Chocolate: três pratos de prata com chocolate escorrendo, sobre uma mesinha redonda."""
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    o = [soft_shadow(D, iso, cx, cy, 0.3, opacity=0.28), cyl3(D, iso, cx, cy, 0.3, 0, 18 * k, "#ffffff", top="#f6f2ea")]
    choc = D.lin([(0, "#8a4f22"), (1, "#4a2614")], 0, 0, 1, 0)
    for z, r in [(18, 0.27), (40, 0.19), (58, 0.11)]:
        o.append(cyl3(D, iso, cx, cy, r, z * k, z * k + 4 * k, "#c9d4e0", metal=True))
        ex, ey, erx, ery = iso.ell(cx, cy, z * k + 4 * k, r * 0.86)
        o.append(E(ex, ey, erx, ery, "#5a2e18", None))
    o.append(cyl3(D, iso, cx, cy, 0.035, 22 * k, 70 * k, "#c9d4e0", metal=True, cap=False))
    sx, sy = iso.v(cx, cy, 70 * k)
    o.append(C(sx, sy, 3.6 * k, "#5a2e18", INK3, 0.8))
    for z, r in [(40, 0.19), (58, 0.11)]:  # chocolate escorrendo para o prato de baixo
        for side in (-1, 1):
            ax, ay = iso.v(cx + side * r * 0.7, cy + r * 0.7, z * k + 4 * k)
            o.append(path(f"M{f(ax)},{f(ay)} q{f(side * 2 * k)},{f(8 * k)} {f(side * 1 * k)},{f(16 * k)}", "none", choc, 2.6 * k))
    for dx, dy, c in [(-12, -24, "#ff3b5c"), (13, -22, "#ffe08a"), (9, -27, "#ff3b5c")]:
        o.append(C(sx + dx * k, sy + 46 * k + dy * k, 2.6 * k, c, INK3, 0.6))
    return "".join(o)


def cupcake_tree(D, iso, x, y):
    """Árvore de Cupcakes: suporte de três andares com cupcakes coloridos e uma cereja no topo."""
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    o = [soft_shadow(D, iso, cx, cy, 0.3, opacity=0.28), cyl3(D, iso, cx, cy, 0.04, 0, 78 * k, "#d9b44a", metal=True, cap=False)]
    colors = ["#ff8ab8", "#7ec8ff", "#fff1a8", "#a8e07a", "#c9a0ff"]
    for level, (z, r, n) in enumerate([(6, 0.3, 6), (32, 0.22, 5), (56, 0.14, 3)]):
        o.append(cyl3(D, iso, cx, cy, r, z * k, z * k + 3 * k, "#ffffff", top="#fffaf0"))
        for i in range(n):
            a = math.radians(i * 360 / n + level * 20)
            px, py = iso.v(cx + math.cos(a) * r * 0.65, cy + math.sin(a) * r * 0.65, z * k + 3 * k)
            o.append(path(f"M{f(px - 4.4 * k)},{f(py)} L{f(px - 3.4 * k)},{f(py - 5 * k)} L{f(px + 3.4 * k)},{f(py - 5 * k)} L{f(px + 4.4 * k)},{f(py)} Z",
                          "#e8b25a", INK3, 0.6))
            o.append(C(px, py - 7 * k, 4.4 * k, colors[(i + level) % len(colors)], INK3, 0.7))
    sx, sy = iso.v(cx, cy, 78 * k)
    o.append(C(sx, sy - 3 * k, 3.4 * k, "#e0303a", INK3, 0.8) + path(f"M{f(sx)},{f(sy - 6 * k)} q2,-5 5,-6", "none", "#3a6a2a", 1.2))
    return "".join(o)


def popcorn_cart(D, iso, x, y):
    """Carrinho de Pipoca: carrinho vermelho com vitrine cheia de pipoca, rodas e um toldo listrado."""
    k = K(iso)
    cx, cy = x + 0.5, y + 0.5
    o = [soft_shadow(D, iso, cx, cy, 0.34, opacity=0.28)]
    o.append(box3(D, iso, cx - 0.3, cy - 0.22, 0.6, 0.44, 30 * k, "#e0303a", top="#ffd23f", z=8 * k))
    o.append(box3(D, iso, cx - 0.26, cy - 0.18, 0.52, 0.36, 30 * k, "#e9f6ff", z=38 * k, gloss=True))
    r = Rng(4)
    for _ in range(22):
        px, py = iso.v(cx + r.u(-0.22, 0.22), cy + r.u(-0.14, 0.14), r.u(40, 62) * k)
        o.append(C(px, py, r.u(2.0, 3.0) * k, "#fff6d6", "#e8c27a", 0.5))
    o.append(box3(D, iso, cx - 0.32, cy - 0.24, 0.64, 0.48, 4 * k, "#ffffff", z=70 * k))
    for i in range(4):
        u0, u1 = i / 4, (i + 0.5) / 4
        q = [iso.v(cx - 0.32 + 0.64 * u0, cy + 0.24, 74 * k), iso.v(cx - 0.32 + 0.64 * u1, cy + 0.24, 74 * k),
             iso.v(cx - 0.32 + 0.64 * u1, cy + 0.24, 70 * k), iso.v(cx - 0.32 + 0.64 * u0, cy + 0.24, 70 * k)]
        o.append(P(q, "#e0303a", None))
    for u in (0.2, 0.8):
        px, py = iso.v(cx - 0.3 + 0.6 * u, cy + 0.22, 4 * k)
        o.append(E(px, py, 6 * k, 6 * k, "#2a2c34", INK3, 0.9) + C(px, py, 2.4 * k, "#d9b44a", None))
    return "".join(o)


# id do móvel no jogo -> desenho
DECOR = {"critic_statue": critic_statue, "chocolate_fountain": chocolate_fountain, "cupcake_tree": cupcake_tree,
         "popcorn_cart": popcorn_cart}
