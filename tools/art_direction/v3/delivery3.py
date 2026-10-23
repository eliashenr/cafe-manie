"""Entregas (DT-071): o Balcão de Entregas, um balcão laranja com caixas de papelão, a bolsa térmica do motoboy e a
plaquinha com a motinho."""
from core3 import *  # noqa: F401,F403


def delivery_counter(D, iso, x, y, front="R"):
    """Balcão de entregas: corpo laranja com frisos, caixas de papelão empilhadas, a bolsa térmica e a placa."""
    import furniture3  # aqui dentro: furniture3 importa módulos que importam este
    o = [furniture3.counter(D, iso, x, y, front, body="#ff7a2f", top="#fff6e6", face="panels", rim="#ffd27a", veins=False)]
    k = furniture3.K(iso)
    top = 47 * k
    o.append(box3(D, iso, x + 0.16, y + 0.2, 0.34, 0.34, 9 * k, "#d9a86a", z=top, top="#e8c08a"))
    o.append(box3(D, iso, x + 0.2, y + 0.24, 0.28, 0.28, 8 * k, "#c9955a", z=top + 9 * k, top="#dcb27a"))
    o.append(box3(D, iso, x + 0.56, y + 0.46, 0.3, 0.3, 16 * k, "#e0303a", z=top, top="#ff5a5f"))
    px, py = iso.v(x + 0.71, y + 0.61, top + 16 * k)
    o.append(f'<path d="M{f(px - 5 * k)},{f(py - 1)} q{f(5 * k)},{f(-7 * k)} {f(10 * k)},0" fill="none" stroke="{INK3}" stroke-width="1.2"/>')
    sx, sy = iso.v(x + 0.32, y + 0.36, top + 17 * k)
    o.append(f'<line x1="{f(sx)}" y1="{f(sy)}" x2="{f(sx)}" y2="{f(sy - 22 * k)}" stroke="{INK3}" stroke-width="1.4"/>')
    o.append(f'<rect x="{f(sx - 15 * k)}" y="{f(sy - 36 * k)}" width="{f(30 * k)}" height="{f(16 * k)}" rx="{f(3 * k)}" '
             f'fill="#ffffff" stroke="{INK3}" stroke-width="1.2"/>')
    cx, cy = sx, sy - 28 * k
    o.append(f'<circle cx="{f(cx - 7 * k)}" cy="{f(cy + 3 * k)}" r="{f(2.6 * k)}" fill="none" stroke="#e0303a" stroke-width="1.4"/>')
    o.append(f'<circle cx="{f(cx + 7 * k)}" cy="{f(cy + 3 * k)}" r="{f(2.6 * k)}" fill="none" stroke="#e0303a" stroke-width="1.4"/>')
    o.append(f'<path d="M{f(cx - 7 * k)},{f(cy + 3 * k)} L{f(cx - 2 * k)},{f(cy - 2 * k)} L{f(cx + 4 * k)},{f(cy - 2 * k)} '
             f'L{f(cx + 7 * k)},{f(cy + 3 * k)} M{f(cx - 2 * k)},{f(cy - 2 * k)} L{f(cx - 4 * k)},{f(cy - 5 * k)}" fill="none" '
             f'stroke="#e0303a" stroke-width="1.4" stroke-linecap="round"/>')
    return "".join(o)


def delivery_icon(D):
    """Ícone das entregas: a motinho vermelha com a caixa atrás."""
    o = [C(18, 46, 8, "#3a3c46", INK3, 1.6), C(18, 46, 3, "#c9d3de", None), C(48, 46, 8, "#3a3c46", INK3, 1.6),
         C(48, 46, 3, "#c9d3de", None)]
    o.append(f'<path d="M14,40 L28,40 L34,30 L46,30 L52,40 L54,46 L26,46 Z" fill="{D.lin([(0, "#ff5a5f"), (1, "#c42a32")])}" '
             f'stroke="{INK3}" stroke-width="1.6"/>')
    o.append(f'<path d="M44,30 L40,18 L46,16" fill="none" stroke="{INK3}" stroke-width="2.4" stroke-linecap="round"/>')
    o.append(f'<rect x="8" y="22" width="18" height="16" rx="2" fill="{D.lin([(0, "#e8c08a"), (1, "#c9955a")])}" stroke="{INK3}" stroke-width="1.6"/>')
    o.append(f'<path d="M8,28 H26" stroke="{INK3}" stroke-width="1"/>')
    return "".join(o)
