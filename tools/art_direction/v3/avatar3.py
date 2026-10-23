"""Avatar do chef (DT-070): retrato em camadas que se empilham na mesma caixa.

- roupa (embaixo): ombros com o dólmã de chef, gola alta e botões;
- cabeça: o rosto com a pele e o cabelo escolhidos (uma peça por combinação de pele e cabelo);
- chapéu (em cima).
Tudo no mesmo referencial do retrato do HUD (cabeça com centro em (0, -84), deslocada 88 para baixo).
"""
from core3 import *  # noqa: F401,F403
import people3

LINE = people3.LINE
HEAD_SHIFT = 88

SKINS = ["clara", "morena_clara", "parda", "negra"]
# cabelo do avatar -> (penteado, cor) dos personagens v3
HAIRS = {
    "curto_castanho": ("curto", "castanho"),
    "rabo_preto": ("rabo", "preto"),
    "chanel_ruivo": ("chanel", "ruivo"),
    "coque_loiro": ("coque", "loiro"),
    "topete_azul": ("topete", "azul"),
    "longo_rosa": ("longo", "rosa"),
}
# roupa -> (dólmã claro, dólmã escuro, lenço do pescoço, botões)
OUTFITS = {
    "branca": ("#ffffff", "#d9e1ea", "#ff4d5e", "#c9d3de"),
    "preta": ("#3a3c46", "#1d1d24", "#d9b44a", "#d9b44a"),
    "vermelha": ("#ff5a5f", "#c42a32", "#ffffff", "#ffffff"),
    "azul": ("#4a8dff", "#1d5ac4", "#ffd23f", "#ffffff"),
    "rosa": ("#ff9ec4", "#e0609a", "#ffffff", "#ffffff"),
    "dourada": ("#ffe07a", "#d9a830", "#ff4d5e", "#8a6a2e"),
}


def _g(body):
    return f'<g transform="translate(0,{HEAD_SHIFT})">{body}</g>'


def head_layer(D, skin, hair):
    """Rosto com a pele e o cabelo (sem chapéu): a camada do meio."""
    return _g(people3.head(D, skin, HAIRS[hair], "feliz"))


def outfit_layer(D, outfit):
    """Ombros com o dólmã de chef: gola alta, duas fileiras de botões e o lenço no pescoço."""
    light, dark, scarf, button = OUTFITS[outfit]
    o = [path("M-50,-32 C-48,-46 -36,-54 -16,-58 L16,-58 C36,-54 48,-46 50,-32 Z",
              D.lin([(0, light), (1, dark)], 0, 0, 0, 1), LINE, 1.4)]
    o.append(path("M-14,-66 L14,-66 L16,-55 C6,-52 -6,-52 -16,-55 Z", D.lin([(0, light), (1, dark)]), LINE, 1.2))
    o.append(path("M-9,-56 L0,-46 L9,-56 Z", scarf, LINE, 1.0))
    o.append(path("M0,-46 L0,-32", "none", shade(dark, 0.15), 1.0))
    for y in (-46, -40, -34):
        for x in (-8, 8):
            o.append(C(x, y, 1.8, button, LINE, 0.7))
    o.append(path("M-40,-40 Q-34,-48 -24,-52", "none", "#ffffff", 2.0, 'opacity="0.35"'))
    return _g("".join(o))


def _toque(D, tall=False):
    top = -150 if tall else -133
    puff = (f"M-18,-99 C-25.6,-113 -15.6,{top + 4.4} -4.6,{top + 10.4} C-0.6,{top - 0.6} 16.4,{top + 1} 18.6,{top + 12.4} "
            f"C27,{top + 11.4} 30,-108 20.6,-99 Z")
    o = [path(puff, D.lin([(0, "#ffffff"), (1, "#d9e1ea")]), LINE, 1.3)]
    if tall:
        for x in (-8, 0, 8):
            o.append(path(f"M{x},-100 Q{x + 1},{top + 20} {x},{top + 8}", "none", "#c9d3de", 1.0))
    o.append(path("M-19.6,-102.4 C-8,-105.6 10,-105.6 21.6,-102.4 L20.6,-94 C9,-96.8 -7,-96.8 -18.6,-94 Z", "#ffffff", LINE, 1.2))
    return "".join(o)


def _beret(D):
    o = [path("M-24,-96 C-28,-108 -10,-118 6,-116 C22,-114 30,-104 24,-96 C10,-100 -10,-100 -24,-96 Z",
              D.lin([(0, "#ff5a5f"), (1, "#b8242c")]), LINE, 1.3)]
    o.append(path("M4,-116 L6,-122", "none", LINE, 2.2))
    o.append(path("M-16,-106 Q-4,-112 10,-110", "none", "#ffffff", 1.8, 'opacity="0.4"'))
    return "".join(o)


def _bandana(D):
    o = [path("M-21,-92 C-14,-100 14,-100 21,-92 L21,-86 C14,-93 -14,-93 -21,-86 Z", "#e0303a", LINE, 1.2)]
    for x, y in ((-12, -92), (-2, -94), (8, -93), (16, -90)):
        o.append(C(x, y, 1.1, "#ffffff", None))
    o.append(path("M20,-90 L29,-95 L27,-86 Z M20,-89 L30,-84 L25,-80 Z", "#e0303a", LINE, 1.0))
    return "".join(o)


def _crown(D):
    o = [path("M-18,-96 L-20,-118 L-10,-106 L0,-122 L10,-106 L20,-118 L18,-96 Z",
              D.lin([(0, "#fff3a0"), (0.5, "#ffd23f"), (1, "#d99a00")]), LINE, 1.3)]
    o.append(path("M-18,-96 C-6,-99 6,-99 18,-96 L18,-91 C6,-94 -6,-94 -18,-91 Z", "#e0a800", LINE, 1.1))
    for x, color in ((-10, "#ff4d5e"), (0, "#4a8dff"), (10, "#3fbf4a")):
        o.append(C(x, -93.5, 1.9, color, LINE, 0.6))
    for x, y in ((-20, -118), (0, -122), (20, -118)):
        o.append(C(x, y, 2.2, "#ffffff", LINE, 0.7))
    return "".join(o)


HATS = {
    "toque": lambda D: _toque(D),
    "toque_alto": lambda D: _toque(D, tall=True),
    "boina": _beret,
    "bandana": _bandana,
    "coroa": _crown,
}


def hat_layer(D, hat):
    return _g(HATS[hat](D))


def chef_icon(D):
    """Ícone da faixa (Chef): o rosto com o chapéu de chef, num círculo."""
    o = [C(32, 34, 28, D.lin([(0, "#ffffff"), (1, "#cfe8ff")]), LINE, 2)]
    o.append(f'<g transform="translate(32,30) scale(0.4)">{outfit_layer(D, "branca")}{head_layer(D, "clara", "curto_castanho")}'
             f'{hat_layer(D, "toque")}</g>')
    return "".join(o)
