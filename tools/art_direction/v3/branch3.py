"""Filial na praia (DT-072): a ilustração do quiosque na areia, com o mar, o sol, o guarda-sol e a prancha, e o ícone
do botão Cidade."""
from core3 import *  # noqa: F401,F403

W, H = 300, 196


def beach_cafe(D):
    """Quiosque de praia com telhado de palha, balcão com placa, guarda-sol listrado, prancha, mar e sol."""
    clip = D.clip(f"M14,0 H{W - 14} A14,14 0 0,1 {W},14 V{H - 14} A14,14 0 0,1 {W - 14},{H} H14 A14,14 0 0,1 0,{H - 14} V14 A14,14 0 0,1 14,0 Z")
    o = [f'<rect width="{W}" height="{H}" rx="14" fill="{D.lin([(0, "#7fd4ff"), (1, "#d9f3ff")])}"/>']
    g = [f'<circle cx="244" cy="44" r="22" fill="{D.rad([(0, "#fff7b0"), (1, "#ffcf3f")])}" stroke="#f0a800" stroke-width="1.5"/>']
    g.append(f'<path d="M0,96 Q75,88 150,96 T300,94 V140 H0 Z" fill="{D.lin([(0, "#2fa8e0"), (1, "#1d7ac4")])}"/>')
    for y, a in ((104, 0.6), (116, 0.45), (128, 0.3)):
        g.append(f'<path d="M10,{y} q12,-4 24,0 t24,0 M150,{y + 3} q12,-4 24,0 t24,0" fill="none" stroke="#ffffff" stroke-width="1.6" opacity="{a}"/>')
    g.append(f'<path d="M0,132 Q90,120 170,130 T300,126 V{H} H0 Z" fill="{D.lin([(0, "#ffe7a8"), (1, "#f5c97a")])}"/>')
    # quiosque
    g.append(f'<rect x="56" y="104" width="104" height="52" rx="4" fill="{D.lin([(0, "#c98a4b"), (1, "#8a5a2e")])}" stroke="{INK3}" stroke-width="1.6"/>')
    g.append(f'<rect x="50" y="128" width="116" height="10" rx="3" fill="#fff6e6" stroke="{INK3}" stroke-width="1.4"/>')
    for x in (62, 154):
        g.append(f'<rect x="{x - 3}" y="86" width="6" height="22" fill="#8a5a2e" stroke="{INK3}" stroke-width="1.2"/>')
    roof = "M40,90 L108,58 L176,90 Z"
    g.append(f'<path d="{roof}" fill="{D.lin([(0, "#f5d27a"), (1, "#d9a84a")])}" stroke="{INK3}" stroke-width="1.6"/>')
    for i in range(9):
        x = 46 + i * 15
        g.append(f'<path d="M{x},90 l3,9 l3,-9" fill="#e8bd5a" stroke="#a8782e" stroke-width="0.9"/>')
    g.append(f'<rect x="78" y="108" width="60" height="16" rx="4" fill="#ffffff" stroke="{INK3}" stroke-width="1.2"/>')
    g.append(f'<text x="108" y="120" text-anchor="middle" font-family="Fredoka, Nunito, sans-serif" font-weight="700" font-size="10" fill="#ff6b3d">PRAIA</text>')
    # guarda-sol e cadeira
    g.append(f'<line x1="214" y1="104" x2="222" y2="162" stroke="{INK3}" stroke-width="2"/>')
    g.append(f'<path d="M180,108 Q212,74 248,100 Z" fill="#ff4d5e" stroke="{INK3}" stroke-width="1.4"/>')
    g.append(f'<path d="M193,98 Q205,84 214,82 L214,104 Z M228,86 Q240,90 248,100 L222,104 Z" fill="#ffffff"/>')
    g.append(f'<path d="M232,160 L246,140 L262,140 M236,160 L250,150" fill="none" stroke="#3a8de0" stroke-width="3" stroke-linecap="round"/>')
    # prancha
    g.append(f'<ellipse cx="34" cy="134" rx="9" ry="30" transform="rotate(-12 34 134)" fill="{D.lin([(0, "#ffd23f"), (1, "#ff8a1a")])}" stroke="{INK3}" stroke-width="1.4"/>')
    g.append(f'<path d="M28,108 L40,160" stroke="#ffffff" stroke-width="2" opacity="0.7"/>')
    o.append(f'<g clip-path="{clip}">{"".join(g)}</g>')
    o.append(f'<rect width="{W}" height="{H}" rx="14" fill="none" stroke="{INK3}" stroke-width="2"/>')
    return "".join(o)


def city_icon(D):
    """Ícone do botão Cidade: um guarda-sol de praia com o sol atrás."""
    o = [C(44, 20, 11, D.rad([(0, "#fff7b0"), (1, "#ffcf3f")]), "#f0a800", 1.4)]
    o.append(f'<path d="M6,56 Q32,46 58,56 V60 H6 Z" fill="#f5c97a" stroke="{INK3}" stroke-width="1.4"/>')
    o.append(f'<line x1="30" y1="22" x2="34" y2="56" stroke="{INK3}" stroke-width="2.4"/>')
    o.append(f'<path d="M8,30 Q30,4 54,24 Z" fill="#ff4d5e" stroke="{INK3}" stroke-width="1.6"/>')
    o.append(f'<path d="M18,22 Q26,12 31,11 L31,27 Z M40,13 Q48,16 54,24 L33,27 Z" fill="#ffffff"/>')
    return "".join(o)
