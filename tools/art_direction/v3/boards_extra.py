"""Pranchas v3: Personagens, Cardápio e Guia de estilo (tudo em SVG, visual claro e colorido)."""
from hud3 import *
from furniture3 import *
from food3 import food, balloon, mood_face, cooking_badge, NAMES
from people3 import person, head, head_top, SKIN, HAIR
from scene3 import lawn

BG_TOP, BG_BOT = "#eaf6ff", "#cfe6fb"


def card(D, x, y, w, h, title=None, color="#2a7de1"):
    o = [f'<rect x="{f(x)}" y="{f(y+3)}" width="{f(w)}" height="{f(h)}" rx="18" fill="#1d3563" opacity="0.12"/>']
    o.append(f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="18" fill="#ffffff" stroke="#b9d3f0" stroke-width="1.6"/>')
    if title:
        o.append(f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="40" rx="18" fill="{D.lin([(0, tint(color, 0.2)), (1, color)])}"/>')
        o.append(f'<rect x="{f(x)}" y="{f(y+22)}" width="{f(w)}" height="18" fill="{color}"/>')
        o.append(f'<rect x="{f(x+10)}" y="{f(y+5)}" width="{f(w-20)}" height="10" rx="5" fill="#ffffff" opacity="0.22"/>')
        o.append(txt(x + 18, y + 27, title, 18, "#ffffff", 700, "start", shade(color, 0.4), 3))
    return "".join(o)


def caption(x, y, name, sub=None, color=TEXT_D):
    o = txt(x, y, name, 15, color, 700, "middle")
    if sub:
        o += txt(x, y + 16, sub, 11.5, "#5a78a8", 700, "middle")
    return o


def background(D, w, h):
    return (f'<rect width="{w}" height="{h}" fill="{D.lin([(0, BG_TOP), (1, BG_BOT)])}"/>'
            + "".join(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#ffffff" opacity="0.35"/>' for (cx, cy, r) in
                      [(90, 60, 70), (1180, 110, 90), (640, -40, 120), (1240, 700, 110), (40, 740, 90)]))


CLIENTES = [
    ("Clara", "vem todo dia", dict(skin="clara", hair=("rabo", "castanho"), top=("blusa", "#ff4d6d"), bottom=("calca", "#3b6fd6"), lash=True, iris="#3b7fd9")),
    ("Nina", "turista", dict(skin="negra", hair=("black", "preto"), top=("camiseta", "#ffc928"), bottom=("calca", "#2fae4e"), lash=True, earrings="#ffc928")),
    ("Jorge", "trabalha ao lado", dict(skin="morena", hair=("topete", "castanho_escuro"), top=("camisa", "#35b8ff"), bottom=("calca", "#34495e"), iris="#6b4423")),
    ("Bela", "ama bolo", dict(skin="clara", hair=("chanel", "ruivo"), top=("vestido", "#9b5cff"), bottom=("saia", "#9b5cff"), lash=True, freckles=True, iris="#2f9e62")),
    ("Tomás", "sempre com pressa", dict(skin="parda", hair=("bone", "preto"), top=("moletom", "#ff7a2f"), bottom=("calca", "#2b2b33"), cap="#2f7bff")),
    ("Lu", "estudante", dict(skin="rosada", hair=("longo", "loiro"), top=("blusa", "#2fd1b5"), bottom=("saia", "#3d5a80"), lash=True, iris="#3b7fd9")),
    ("Dona Cida", "freguesa fiel", dict(skin="clara", hair=("coque", "grisalho"), top=("blusa", "#ff5fa2"), bottom=("saia", "#6b4b8a"), lash=True, glasses="#7a4bd6")),
    ("Seu Zé", "o do pão na chapa", dict(skin="morena", hair=("careca", "castanho_escuro"), top=("camisa", "#ffffff"), bottom=("calca", "#6b4423"), beard="castanho_escuro")),
    ("Dudu", "skatista", dict(skin="parda", hair=("moicano", "verde"), top=("camiseta", "#1d1d2b"), bottom=("calca", "#4a4a5e"))),
    ("Rafa", "gamer", dict(skin="clara", hair=("franja", "castanho"), top=("regata", "#ff4d5e"), bottom=("short", "#2b8cff"), iris="#3b7fd9")),
]


def characters_board():
    D = Defs()
    W, H = 1280, 760
    o = [background(D, W, H)]
    o.append(card(D, 20, 18, W - 40, 318, "Clientes", "#2a7de1"))
    for i, (nm, sub, spec) in enumerate(CLIENTES):
        x = 84 + i * 123
        o.append(person(D, x, 278, 1.62, 1 if i % 2 == 0 else -1, **spec))
        o.append(caption(x, 304, nm, sub))
    o.append(card(D, 20, 352, 400, 390, "Equipe", "#ff7a2f"))
    o.append(person(D, 120, 668, 2.05, 1, "em_pe", "negra", ("black", "preto"), ("chef", "#ffffff"), ("calca", "#3b4a55"),
                    apron="#ffffff", hat="chef", lash=True, earrings="#ffc928"))
    o.append(caption(120, 698, "Chef Bia", "mascote e cozinheira"))
    o.append(person(D, 300, 668, 2.05, 1, "andar", "morena_clara", ("curto", "preto"), ("garcom", "#ffffff"), ("calca", "#23232b"), tray="bolo", shoes="#2b2b33"))
    o.append(caption(300, 698, "Léo", "garçom"))
    # sentados à mesa
    o.append(card(D, 436, 352, 520, 390, "À mesa", "#26a93a"))
    iso = Iso(0, 0, 84, 42)
    states = [("esperando", ("balao", "misto", 0.45), "esperando o pedido", CLIENTES[3][2]),
              ("comendo", ("prato", "bolo"), "comendo", CLIENTES[1][2]),
              ("bravo", ("humor", "bravo"), "demorou demais!", CLIENTES[2][2])]
    for i, (expr, need, lab, spec) in enumerate(states):
        cx = 526 + i * 170
        base_y = 668
        g_ = []
        ch = chair(D, iso, 0, 0, "+x", "#ff4d5e")
        tb = table_round(D, iso, 1, 0, ["#ff4d8d", "#2ec4b6", "#ff7a2f"][i], dishes=[need[1]] if need[0] == "prato" else [])
        sx, sy = seat_point(iso, 0, 0)
        sy += 4 * K(iso)
        sp = dict(spec)
        sp.pop("top", None)
        sp.pop("bottom", None)
        who = person(D, sx, sy, 0.6, 1, "sentado", spec["skin"], spec["hair"], spec["top"], spec["bottom"], expr=expr,
                     **{k: v for k, v in spec.items() if k not in ("skin", "hair", "top", "bottom")})
        g_.append(ch + who + tb)
        ty = head_top(sy, 0.6, "sentado")
        if need[0] == "balao":
            g_.append(balloon(D, need[1], sx + 4, ty - 2, 30, need[2]))
        elif need[0] == "humor":
            g_.append(mood_face(D, sx + 16, ty - 2, need[1], 11))
        o.append(g("".join(g_), f"translate({f(cx)},{f(base_y)}) scale(1.55) translate(-30,-60)"))
        o.append(caption(cx + 18, 712, lab))
    # expressões
    o.append(card(D, 972, 352, 288, 390, "Humor", "#b06bff"))
    for i, (st, lab) in enumerate([("feliz", "Feliz"), ("esperando", "Esperando"), ("bravo", "Bravo")]):
        y = 432 + i * 96
        o.append(mood_face(D, 1024, y, st, 24))
        spec = CLIENTES[[0, 3, 2][i]][2]
        o.append(g(head(D, spec["skin"], spec["hair"], {"feliz": "feliz", "esperando": "esperando", "bravo": "bravo"}[st],
                        **{k: v for k, v in spec.items() if k in ("lash", "iris", "freckles", "glasses", "earrings")}),
                   f"translate(1110,{f(y+84*0.9)}) scale(0.9)"))
        o.append(txt(1168, y + 6, lab, 16, TEXT_D, 700))
    return D, "".join(o)


def menu_board():
    D = Defs()
    W, H = 1280, 720
    o = [background(D, W, H)]
    # janela "Escolha o prato" (ao tocar num fogão)
    o.append(card(D, 20, 18, 760, 684, "O que vamos cozinhar?", "#ff7a2f"))
    dishes = [("cafe", "Café", "30 s", 12, 8, 30, 2, 1), ("pao", "Pão de queijo", "2 min", 16, 20, 72, 4, 1),
              ("misto", "Misto-quente", "5 min", 10, 30, 95, 6, 2), ("bolo", "Bolo de cenoura", "15 min", 8, 50, 180, 12, 3),
              ("coxinha", "Coxinha", "30 min", 20, 90, 330, 20, 5), ("lasanha", "Lasanha", "1 h", 12, 160, 620, 36, 8)]
    for i, (kind, name, tempo, porcoes, custo, ganho, xp, nivel) in enumerate(dishes):
        r, c = divmod(i, 3)
        x, y = 40 + c * 246, 74 + r * 312
        locked = nivel > 6
        o.append(f'<rect x="{x}" y="{y+2}" width="228" height="296" rx="16" fill="#9fc2ea"/>')
        o.append(f'<rect x="{x}" y="{y}" width="228" height="296" rx="16" fill="{D.lin([(0, "#ffffff"), (1, "#f1f7fe")])}" stroke="#b9d3f0" stroke-width="1.6"/>')
        o.append(f'<ellipse cx="{x+114}" cy="{y+118}" rx="80" ry="22" fill="#e1eefb"/>')
        o.append(food(D, kind, x + 114, y + 76, 130))
        o.append(txt(x + 114, y + 160, name, 18, TEXT_D, 700, "middle"))
        o.append(f'<rect x="{x+14}" y="{y+172}" width="200" height="26" rx="13" fill="#eaf4ff"/>')
        o.append(txt(x + 30, y + 190, f"Tempo: {tempo}", 13, "#1d3563", 700))
        o.append(txt(x + 200, y + 190, f"×{porcoes}", 13, "#2a7de1", 700, "end"))
        o.append(txt(x + 22, y + 220, "Custa", 12, "#5a78a8", 700))
        o.append(place(coin(D), x + 74, y + 216, 18) + txt(x + 86, y + 221, str(custo), 13.5, "#1d3563", 700))
        o.append(txt(x + 122, y + 220, "Rende", 12, "#5a78a8", 700))
        o.append(place(coin(D), x + 176, y + 216, 18) + txt(x + 188, y + 221, str(ganho), 13.5, "#1a8a3e", 700))
        o.append(place(star(D), x + 30, y + 244, 20) + txt(x + 44, y + 250, f"+{xp} XP", 13, "#e08a00", 700))
        if locked:
            o.append(f'<rect x="{x}" y="{y}" width="228" height="296" rx="16" fill="#1d3563" opacity="0.5"/>')
            o.append(f'<rect x="{x+90}" y="{y+100}" width="48" height="40" rx="8" fill="{D.lin([(0, "#ffd23f"), (1, "#f08c00")])}" stroke="{OL}" stroke-width="1.8"/>')
            o.append(path(f"M{x+100},{y+100} v-10 a14,14 0 0,1 28,0 v10", "none", OL, 4))
            o.append(f'<rect x="{x+54}" y="{y+150}" width="120" height="28" rx="14" fill="#ffffff" stroke="{OL}" stroke-width="1.4"/>')
            o.append(txt(x + 114, y + 169.5, f"Nível {nivel}", 15, TEXT_D, 700, "middle"))
        else:
            o.append(f'<rect x="{x+14}" y="{y+258}" width="200" height="30" rx="12" fill="{D.lin([(0, "#7ee85a"), (1, "#26a93a")])}" stroke="#177a28" stroke-width="1.6"/>')
            o.append(txt(x + 114, y + 279, "Cozinhar", 15, "#ffffff", 700, "middle", "#177a28", 3))
    # direita: pedido do cliente e fogão
    o.append(card(D, 800, 18, 460, 300, "O pedido do cliente", "#2a7de1"))
    for i, (pat, lab) in enumerate([(0.9, "chegou agora"), (0.45, "esperando"), (0.15, "quase indo embora")]):
        cx = 880 + i * 150
        o.append(balloon(D, ["cafe", "misto", "coxinha"][i], cx, 176, 56, pat))
        o.append(mood_face(D, cx, 214, ["feliz", "esperando", "bravo"][i], 16))
        o.append(txt(cx, 262, lab, 13, TEXT_D, 700, "middle"))
    o.append(txt(1030, 296, "A barrinha mostra a paciência: verde → amarelo → vermelho.", 12, "#5a78a8", 700, "middle"))
    o.append(card(D, 800, 334, 460, 368, "No fogão", "#26a93a"))
    iso = Iso(0, 0, 96, 48)
    floor_ = "".join(P([iso.v(x, y), iso.v(x + 1, y), iso.v(x + 1, y + 1), iso.v(x, y + 1)], "#2c2f3d" if (x + y) % 2 == 0 else "#f6f8fc", "#00000022", 0.5)
                     for y in range(-1, 3) for x in range(-1, 4))
    cxp, cyp = iso.v(1.5, 1.0)
    chef = person(D, cxp, cyp, 0.78, 1, "em_pe", "negra", ("black", "preto"), ("chef", "#ffffff"), ("calca", "#3b4a55"),
                  apron="#ffffff", hat="chef", lash=True, earrings="#ffc928")
    body = (floor_ + stove(D, iso, 0, 0, "R", cooking="lasanha") + stove(D, iso, 0, 1, "R", cooking="pao") + chef
            + counter(D, iso, 2, 0, "R", [("cafe", 12)], body="#2ec4b6") + counter(D, iso, 2, 1, "R", [("bolo", 8)], body="#2ec4b6"))
    ox, oy = 1030 - 48, 560 - 48
    o.append(g(body, f"translate({ox},{oy})"))
    b1 = iso.v(0.5, 0.5, 118)
    b2 = iso.v(0.5, 1.5, 104)
    o.append(cooking_badge(D, "lasanha", ox + b1[0], oy + b1[1], 0.7, "2:40", False, 22))
    o.append(cooking_badge(D, "pao", ox + b2[0] - 50, oy + b2[1] + 10, 1.0, "", True, 22))
    o.append(txt(1030, 690, "Selo com o prato, o anel de progresso e o tempo.", 12, "#5a78a8", 700, "middle"))
    return D, "".join(o)


PALETTE = [
    ("Céu", "#2a7de1"), ("Azul claro", "#5bb8ff"), ("Gramado", "#78d64a"), ("Verde botão", "#26a93a"),
    ("Coral", "#ff6b6b"), ("Vermelho", "#ff4d5e"), ("Rosa", "#ff5fa2"), ("Lilás", "#b06bff"),
    ("Sol", "#ffd23f"), ("Laranja", "#ff7a2f"), ("Menta", "#2ec4b6"), ("Menta clara", "#bff3e1"),
    ("Madeira mel", "#f6c98a"), ("Tinta", "#1d3563"), ("Contorno", "#2b2540"), ("Branco", "#ffffff"),
]


def style_board():
    D = Defs()
    W, H = 1280, 1200
    o = [background(D, W, H)]
    o.append(card(D, 20, 18, 620, 330, "Cores", "#2a7de1"))
    for i, (nm, c) in enumerate(PALETTE):
        r, cc = divmod(i, 4)
        x, y = 42 + cc * 150, 76 + r * 66
        o.append(f'<rect x="{x}" y="{y}" width="44" height="44" rx="12" fill="{c}" stroke="#2b2540" stroke-width="1.4"/>')
        o.append(f'<rect x="{x+6}" y="{y+5}" width="32" height="10" rx="5" fill="#ffffff" opacity="0.3"/>')
        o.append(txt(x + 54, y + 20, nm, 13.5, TEXT_D, 700) + txt(x + 54, y + 37, c.upper(), 11.5, "#5a78a8", 700))
    o.append(card(D, 660, 18, 600, 330, "Letras", "#ff7a2f"))
    o.append(txt(684, 104, "Fredoka — títulos e números", 26, TEXT_D, 700))
    o.append(txt(684, 150, "12.480", 46, "#ffe34d", 700, "start", "#12254a", 8))
    o.append(txt(850, 150, "+18", 40, "#ffd23f", 700, "start", "#2a2a4a", 7))
    o.append(txt(960, 150, "Nível 12", 34, "#ffffff", 700, "start", "#1d3563", 6))
    o.append(f'<text x="684" y="200" font-family="Nunito, sans-serif" font-weight="800" font-size="20" fill="{TEXT_D}">Nunito — textos e botões</text>')
    o.append(f'<text x="684" y="232" font-family="Nunito, sans-serif" font-weight="700" font-size="15" fill="#5a78a8">Números grandes e com contorno para ler no celular.</text>')
    o.append(f'<text x="684" y="256" font-family="Nunito, sans-serif" font-weight="700" font-size="15" fill="#5a78a8">Textos curtos; nada menor que 12 px na tela do jogo.</text>')
    o.append(txt(684, 312, "Contorno escuro + brilho no canto de cima", 16, "#ff4d5e", 700))
    # componentes
    o.append(card(D, 20, 366, 1240, 318, "Componentes da interface", "#26a93a"))
    o.append(counter_pill(D, 44, 424, 212, coin(D), "12.480"))
    o.append(counter_pill(D, 44, 468, 212, bean(D), "37"))
    o.append(xp_block(D, 290, 420, 420, 12, 4820, 6100))
    o.append(stat_bar(D, 740, 426, 160, flower(D), 0.74, "148", "#ffa3cf", "#ff5fa2", "b2"))
    o.append(timer_panel(D, 1020, 420, "PRESENTE DIÁRIO EM"))
    for i, (kd, col) in enumerate([("zoom_in", "blue"), ("gear", "blue"), ("left", "blue"), ("right", "blue"), ("plus", "green"), ("check", "green"),
                                   ("rotate", "blue"), ("close", "red")]):
        o.append(square_button(D, 64 + i * 58, 548, 46, kd, col))
    bia = f'<g transform="translate(600,562)">{portrait(D, CHEF_BIA, hat="chef", scale=0.6)}</g>'
    o.append(medallion(D, 600, 553, bia, "#ffb400", "MISSÕES", "#ff4d6d", badge=1))
    o.append(quest_tip(D, 646, 527, "Sirva 3 cafés", 2, 3))
    o.append(neighbor_card(D, 846, 512, "Ana", 21, NEIGHBORS[0][2], "#bfe3ff"))
    from shop3 import item_square
    o.append(item_square(D, 958, 512, 86, "mesa_redonda", "150", "coin", ["desconto"], True))
    o.append(item_square(D, 1060, 512, 86, "jukebox", "12", "bean", ["novo"]))
    o.append(rating_block(D, 44, 600))
    for i, (ic, lab, bd) in enumerate([(shop_house(D), "Loja", None), (book(D), "Cardápio", None), (gift(D), "Presentes", 2), (trophy(D), "Conquistas", None)]):
        o.append(glossy_icon_button(D, 290 + i * 86, 628, ic, lab, bd, 52))
    o.append(balloon(D, "cafe", 700, 668, 40, 0.8) + balloon(D, "bolo", 780, 668, 40, 0.3))
    o.append(mood_face(D, 840, 640, "feliz", 16) + mood_face(D, 880, 640, "esperando", 16) + mood_face(D, 920, 640, "bravo", 16))
    o.append(cooking_badge(D, "pao", 1214, 536, 0.6, "0:24") + cooking_badge(D, "lasanha", 1214, 626, 1.0, "", True))
    # materiais
    o.append(card(D, 20, 702, 820, 480, "Materiais do cenário", "#b06bff"))
    mats = []
    iso = Iso(0, 0, 84, 42)
    from scene3 import floor as _floor, _wallpaper, _kitchen_tiles, asphalt
    samples = [
        ("Madeira mel", f'<g transform="translate(150,780) scale(0.42)">{_floor(D, iso)}</g>'),
    ]
    sx = 44
    tiles = [
        ("Gramado", f'<rect x="0" y="0" width="170" height="120" rx="12" fill="{lawn(D)}"/>'),
        ("Asfalto e faixa", f'<rect x="0" y="0" width="170" height="120" rx="12" fill="{asphalt(D)}"/><rect x="20" y="56" width="40" height="7" rx="3" fill="#ffffff"/><rect x="100" y="56" width="40" height="7" rx="3" fill="#ffffff"/>'),
        ("Papel de parede", f'<g transform="translate(0,120)">{_wallpaper(D, 170)}</g>'),
        ("Azulejo da cozinha", f'<g transform="translate(0,120)">{_kitchen_tiles(D, 170)}</g>'),
    ]
    for i, (nm, art) in enumerate(tiles):
        x = 44 + i * 196
        cid = D.clip(f"M{x+12},{760} h146 a12,12 0 0,1 12,12 v96 a12,12 0 0,1 -12,12 h-146 a12,12 0 0,1 -12,-12 v-96 a12,12 0 0,1 12,-12 Z")
        o.append(f'<g clip-path="{cid}"><g transform="translate({x},760)">{art}</g></g>')
        o.append(f'<rect x="{x}" y="760" width="170" height="120" rx="12" fill="none" stroke="#2b2540" stroke-width="1.4"/>')
        o.append(txt(x + 85, 902, nm, 14, TEXT_D, 700, "middle"))
    def flat(kind):
        if kind == "madeira":
            r = Rng(5)
            out = []
            for j in range(8):
                x = -r.u(0, 60)
                while x < 170:
                    ln = r.u(50, 90)
                    c = ["#f6c98a", "#f0bc78", "#f9d49c", "#ecb46c"][int(r.u(0, 4))]
                    out.append(f'<rect x="{f(x)}" y="{j*15}" width="{f(ln)}" height="15" fill="{c}" stroke="#c98d4a" stroke-width="0.6"/>')
                    out.append(f'<line x1="{f(x+ln*0.2)}" y1="{j*15+7}" x2="{f(x+ln*0.7)}" y2="{j*15+7.5}" stroke="#d99a55" stroke-width="0.8" opacity="0.6"/>')
                    x += ln
            return "".join(out)
        if kind == "xadrez":
            return "".join(f'<rect x="{i*20}" y="{j*20}" width="20" height="20" fill="{"#2c2f3d" if (i+j)%2==0 else "#f6f8fc"}"/>' for i in range(9) for j in range(6))
        if kind == "toalha":
            return ('<rect width="170" height="120" fill="#ffffff"/>' + "".join(f'<rect x="{i*16}" y="0" width="8" height="120" fill="#ff4d8d" opacity="0.5"/>' for i in range(11))
                    + "".join(f'<rect x="0" y="{j*16}" width="170" height="8" fill="#ff4d8d" opacity="0.5"/>' for j in range(8)))
        if kind == "bolinhas":
            return ('<rect width="170" height="120" fill="#ffd23f"/>' + "".join(f'<circle cx="{i*14 + (7 if j%2 else 0)}" cy="{j*14+4}" r="3" fill="#ffffff"/>' for i in range(13) for j in range(9)))
        return ""
    tiles2 = [("Madeira mel", flat("madeira")), ("Xadrez da cozinha", flat("xadrez")), ("Toalha xadrez", flat("toalha")), ("Cortina de bolinhas", flat("bolinhas"))]
    for i, (nm, art) in enumerate(tiles2):
        x = 44 + i * 196
        cid = D.clip(f"M{x+12},{930} h146 a12,12 0 0,1 12,12 v96 a12,12 0 0,1 -12,12 h-146 a12,12 0 0,1 -12,-12 v-96 a12,12 0 0,1 12,-12 Z")
        o.append(f'<g clip-path="{cid}"><g transform="translate({x},930)">{art}</g></g>')
        o.append(f'<rect x="{x}" y="930" width="170" height="120" rx="12" fill="none" stroke="#2b2540" stroke-width="1.4"/>')
        o.append(txt(x + 85, 1072, nm, 14, TEXT_D, 700, "middle"))
    o.append(txt(430, 1130, "Cores vivas com brilho e sombra de contato; texturas simples que leem bem no celular.", 13, "#5a78a8", 700, "middle"))
    # princípios
    o.append(card(D, 860, 702, 400, 480, "Princípios", "#ff4d5e"))
    rules = [("Luz de dia e cores vivas", "nada de tons apagados"),
             ("Salão grande e lotado", "a graça é ver o movimento"),
             ("Gramado limpo", "sem árvores tampando a cafeteria"),
             ("Bonecos cabeçudos", "olhos grandes, cabelo em mechas"),
             ("Interface do jogo de 2010", "contadores, XP, missões ao lado, vizinhos embaixo"),
             ("Tudo nosso", "nenhum desenho, logo ou personagem do jogo antigo")]
    for i, (a, b) in enumerate(rules):
        y = 770 + i * 66
        o.append(C(888, y - 5, 12, D.lin([(0, "#7ee85a"), (1, "#26a93a")]), "#177a28", 1.6))
        o.append(path(f"M882,{y-5} l4,4 l8,-8", "none", "#ffffff", 2.6))
        o.append(txt(910, y, a, 15.5, TEXT_D, 700) + txt(910, y + 19, b, 12.5, "#5a78a8", 700))
    return D, "".join(o)
