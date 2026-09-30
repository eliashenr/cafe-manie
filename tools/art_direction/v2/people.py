"""Personagens v2: proporção de jogo social (cabeça grande), vista 3/4, luz de cima à esquerda."""
from core import *

SKIN = {  # base, sombra, brilho
    "clara": ("#f8d9c2", "#e6b598", "#fff0e4"),
    "morena_clara": ("#e8b48f", "#cf9470", "#f7d3b8"),
    "morena": ("#c98b61", "#ad6f48", "#e3ad86"),
    "parda": ("#a8704a", "#8a5634", "#c89168"),
    "negra": ("#6f4429", "#56321c", "#8f5d3f"),
}
HAIR = {  # base, sombra, brilho
    "preto": ("#2c2320", "#17110f", "#5b4c45"),
    "castanho": ("#6e4127", "#4a2a17", "#a0714b"),
    "loiro": ("#e9b650", "#c48d2c", "#fbe39a"),
    "ruivo": ("#c9562d", "#9c3d1d", "#ef8a5a"),
    "grisalho": ("#cfccc6", "#a6a29b", "#f1f0ed"),
    "mel": ("#b07a3c", "#875a26", "#d9a868"),
}

# Cabeça: forma de ovo com o rosto virado para a direita (vista 3/4). Centro em (0, 0).
HEAD = "M-19,-2 C-19,-16 -9,-21 2,-21 C14,-21 21,-12 21,-1 C21,11 12,19 2,19 C-9,19 -19,11 -19,-2 Z"


def _hair_paths(style):
    """(camada de trás, camada da frente, orelha visível?, brilhos) em coordenadas da cabeça."""
    if style == "curto":
        front = ("M-20,5 C-24,-12 -14,-27 2,-27 C8,-27 13,-26 17,-23 C19,-25 23,-23 22,-20 C25,-15 25,-9 23,-4 "
                 "C21,-9 17,-12 11,-12 C12,-9 11,-7 9,-6 C7,-10 2,-12 -3,-11 C-7,-10 -10,-7 -12,-2 C-13,1 -13,5 -14,8 "
                 "C-17,8 -19,7 -20,5 Z")
        return None, front, True, ["M-11,-21 C-5,-24 5,-24 12,-20", "M-16,-11 C-14,-16 -11,-19 -8,-20"]
    if style == "topete":
        front = ("M-19,6 C-23,-8 -17,-22 -4,-25 C0,-30 8,-33 15,-31 C21,-29 25,-23 23,-15 C22,-11 21,-9 19,-7 "
                 "C16,-12 11,-14 5,-13 C-2,-12 -8,-8 -12,-1 C-14,3 -15,7 -16,9 C-17,9 -18,8 -19,6 Z")
        return None, front, True, ["M1,-28 C6,-31 13,-30 17,-26", "M-12,-18 C-9,-21 -6,-22 -3,-22"]
    if style == "rabo":
        back = "M-14,-17 C-29,-17 -34,-2 -30,12 C-29,19 -24,24 -20,21 C-23,13 -23,2 -16,-8 Z"
        front = ("M-20,4 C-23,-14 -12,-28 3,-27 C16,-27 25,-18 23,-6 C18,-11 10,-14 3,-13 C-4,-12 -10,-8 -13,-1 "
                 "C-15,2 -16,5 -17,7 Z")
        return back, front, True, ["M-10,-22 C-3,-25 7,-25 14,-21", "M-27,-6 C-28,2 -27,9 -24,15"]
    if style == "coque":
        back = "M-8,-27 m-9,0 a9,8.4 0 1,0 18,0 a9,8.4 0 1,0 -18,0 Z"
        front = ("M-20,4 C-23,-14 -12,-27 3,-26 C16,-26 24,-18 23,-7 C18,-11 10,-14 3,-13 C-4,-12 -10,-8 -13,-1 "
                 "C-15,2 -16,5 -17,7 Z")
        return back, front, True, ["M-9,-22 C-3,-24 6,-24 13,-20", "M-13,-31 C-11,-34 -6,-35 -3,-32"]
    if style == "chanel":
        back = ("M-23,-2 C-25,-20 -12,-29 2,-28 C18,-28 27,-18 25,-2 C24,8 25,14 22,19 C18,19 15,16 14,11 "
                "L-14,11 C-16,16 -20,18 -24,16 C-22,11 -23,5 -23,-2 Z")
        front = ("M-16,-7 C-13,-22 4,-28 14,-23 C20,-20 24,-14 23,-8 C19,-11 14,-13 8,-12 C8,-10 7,-8 5,-7 "
                 "C3,-11 -2,-12 -6,-11 C-10,-10 -13,-7 -16,-3 Z "
                 "M-19,-7 C-21,4 -20,12 -17,18 L-12,16 C-14,9 -14,1 -13,-8 Z")
        return back, front, False, ["M-10,-21 C-3,-25 6,-25 13,-21", "M-20,0 C-20,6 -19,11 -17,15"]
    if style == "longo":
        back = ("M-22,-4 C-26,-22 -10,-30 3,-29 C18,-29 27,-19 25,-4 C24,8 28,22 25,36 C22,42 16,42 13,37 L13,12 "
                "L-14,12 L-14,37 C-18,42 -24,40 -26,33 C-23,21 -21,8 -22,-4 Z")
        front = ("M-16,-5 C-14,-22 2,-28 14,-24 C20,-21 24,-14 23,-5 C22,3 21,9 19,15 C17,8 16,1 14,-6 "
                 "C11,-11 5,-13 -1,-12 C-7,-11 -12,-8 -16,-2 Z "
                 "M19,-4 C25,7 26,22 21,33 L16,31 C18,22 18,9 15,-1 Z")
        return back, front, False, ["M-8,-22 C-1,-26 8,-25 14,-21", "M22,6 C24,14 24,22 22,28", "M-22,6 C-23,16 -22,26 -20,33"]
    if style == "black":
        n = 14
        d = []
        for i in range(n):
            a0 = math.pi * 2 * i / n
            a1 = math.pi * 2 * (i + 1) / n
            am = (a0 + a1) / 2
            p0 = (1 + 26 * math.cos(a0), -9 + 24.5 * math.sin(a0))
            p1 = (1 + 26 * math.cos(a1), -9 + 24.5 * math.sin(a1))
            cp = (1 + 31.5 * math.cos(am), -9 + 29.5 * math.sin(am))
            if i == 0:
                d.append(f"M{f(p0[0])},{f(p0[1])}")
            d.append(f"Q{f(cp[0])},{f(cp[1])} {f(p1[0])},{f(p1[1])}")
        back = " ".join(d) + " Z"
        front = ("M-18,-1 C-18,-17 -6,-25 4,-25 C15,-25 23,-17 22,-6 C18,-11 12,-13 4,-13 C-4,-13 -11,-9 -14,-3 "
                 "C-15,-2 -17,-1 -18,-1 Z")
        return back, front, True, ["M-6,-30 C0,-33 8,-32 14,-28", "M-20,-18 C-18,-24 -14,-28 -9,-30"]
    if style == "bone":
        front = ("M-20,1 C-21,-18 -8,-28 3,-28 C16,-28 24,-20 23,-6 C14,-9 1,-9 -20,1 Z")
        return None, front, True, ["M-12,-22 C-5,-26 6,-26 13,-22"]
    if style == "careca":
        return None, "M-19,3 C-20,-6 -18,-10 -15,-12 C-15,-4 -16,2 -15,7 C-17,7 -18,6 -19,3 Z", True, []
    raise ValueError(style)


def _eye(D, cx, cy, w, h, iris, lashes=False, closed=False, skin_shadow="#c9906f"):
    if closed:
        return path(f"M{f(cx-w)},{f(cy+0.5)} Q{f(cx)},{f(cy+h*0.8)} {f(cx+w)},{f(cy+0.2)}", "none", INK, 1.9)
    o = [E(cx, cy, w, h, D.lin([(0, "#f3f1ee"), (1, "#ffffff")]), None)]
    o.append(E(cx + 0.7, cy + 0.4, w * 0.8, h * 0.84, D.lin([(0, dark(iris, 0.45)), (0.6, iris), (1, light(iris, 0.3))]), None))
    o.append(E(cx + 0.8, cy + 0.7, w * 0.4, h * 0.44, "#120905", None))
    o.append(E(cx + 0.4 + w * 0.3, cy - h * 0.36, w * 0.3, h * 0.26, "#ffffff", None))
    o.append(C(cx - w * 0.25, cy + h * 0.42, w * 0.13, "#ffffff", None, extra='opacity="0.9"'))
    # linha dos cílios em cima (grossa) e pálpebra de baixo (suave)
    o.append(path(f"M{f(cx-w-0.9)},{f(cy+0.4)} Q{f(cx-0.2)},{f(cy-h-2.6)} {f(cx+w+1.3)},{f(cy-0.9)}", "none", INK, 2.3))
    o.append(path(f"M{f(cx-w*0.6)},{f(cy+h*0.9)} Q{f(cx)},{f(cy+h+0.7)} {f(cx+w*0.62)},{f(cy+h*0.88)}", "none", skin_shadow, 0.9,
                  'opacity="0.45"'))
    if lashes:
        o.append(path(f"M{f(cx+w+1.0)},{f(cy-0.9)} q1.6,-0.6 2.4,-2.4", "none", INK, 1.4))
    return "".join(o)


def _face(D, expr, skin, hair_col, eyes="#5a3520", lashes=False, glasses=False, freckles=False, beard=False, **_):
    base, sh, hi = skin
    o = []
    if beard:
        o.append(path("M-12,7 C-8,17 4,21 14,15 C18,12 20,7 20,4 C16,10 8,13 2,12 C-4,11 -9,9 -12,7 Z", hair_col[0], None,
                      extra='opacity="0.55"'))
    # bochechas
    o.append(E(-4, 8, 3.6, 2.1, "#ff8e86", None, extra='opacity="0.42"'))
    o.append(E(16, 10, 2.6, 1.7, "#ff8e86", None, extra='opacity="0.38"'))
    if freckles:
        for (x, y) in [(-6, 6), (-3, 5.5), (-4.5, 8), (14, 6), (16.5, 6.6)]:
            o.append(C(x, y, 0.55, dark(base, 0.35), None))
    angry = expr == "bravo"
    worried = expr == "esperando"
    eyes_closed = expr == "comendo"
    o.append(_eye(D, -2.6, 1.6, 3.7, 5.2, eyes, lashes, eyes_closed, sh))
    o.append(_eye(D, 10.4, 1.6, 4.3, 5.6, eyes, lashes, eyes_closed, sh))
    bc = hair_col[1]
    if angry:
        o.append(path("M-6.6,-8 L1.4,-4.6", "none", bc, 2.3) + path("M6,-4.8 L14.6,-8.6", "none", bc, 2.5))
    elif worried:
        o.append(path("M-6.6,-6 Q-2.6,-10 1.4,-8.6", "none", bc, 2.1) + path("M6.2,-9 Q10.4,-10.8 14.8,-6.8", "none", bc, 2.3))
    else:
        o.append(path("M-6.4,-7.4 Q-2.6,-10.4 1.2,-8.2", "none", bc, 2.1) + path("M6.2,-8.6 Q10.6,-11.4 14.8,-8.4", "none", bc, 2.3))
    # nariz
    o.append(path("M15.2,6.6 Q17,8.4 15,9.6", "none", sh, 1.3, 'opacity="0.9"'))
    # boca
    if expr in ("feliz", "sorriso"):
        o.append(path("M3.6,11.2 Q8.6,17.6 13.6,11 Q8.6,13.2 3.6,11.2 Z", "#7c2b22", INK, 1.1))
        o.append(path("M6.4,14.4 Q8.8,15.8 11.2,14.2 Q8.8,13.4 6.4,14.4 Z", "#e2686a", None))
    elif expr == "bravo":
        o.append(path("M4.6,15 Q8.8,11 13,14.6", "none", INK, 1.6))
    elif expr == "esperando":
        o.append(path("M6,13.6 Q8.8,12.6 11.6,13.8", "none", INK, 1.5))
    elif expr == "comendo":
        o.append(E(9, 13.2, 2.2, 2.6, "#7c2b22", INK, 1.0))
        o.append(E(15, 9, 3.4, 2.6, "#ff8e86", None, extra='opacity="0.35"'))
    else:
        o.append(path("M5.4,12.6 Q8.8,14.8 12.2,12.4", "none", INK, 1.5))
    if glasses:
        o.append(f'<rect x="-8" y="-4.6" width="11" height="11" rx="3.6" fill="#ffffff" fill-opacity="0.15" stroke="#3d2b22" stroke-width="1.5"/>')
        o.append(f'<rect x="5" y="-4.8" width="12.4" height="11.4" rx="3.8" fill="#ffffff" fill-opacity="0.15" stroke="#3d2b22" stroke-width="1.5"/>')
        o.append(line(3, 0.4, 5, 0.4, "#3d2b22", 1.4) + line(-8, 0, -15, -1.6, "#3d2b22", 1.4))
    return "".join(o)


def head(D, skin="clara", hair=("curto", "castanho"), expr="feliz", back=False, **face):
    sk = SKIN[skin]
    style, hcol_name = hair
    hc = HAIR[hcol_name]
    back_layer, front, ear_visible, shines = _hair_paths(style)
    hair_fill = D.lin([(0, hc[2]), (0.35, hc[0]), (1, hc[1])], 0.2, 0, 0.8, 1)
    o = []
    if back_layer:
        o.append(path(back_layer, D.lin([(0, hc[0]), (1, hc[1])]), INK, 1.3))
    # pescoço é desenhado pelo corpo; aqui cabeça
    o.append(path(HEAD, D.rad([(0, sk[2]), (0.55, sk[0]), (1, sk[1])], 0.58, 0.38, 0.72), INK, 1.4))
    if back:
        # vista de costas: o cabelo cobre a cabeça toda
        cover = "M-20,6 C-23,-12 -12,-26 2,-26 C16,-26 24,-14 22,4 C20,10 16,12 10,12 C0,13 -12,12 -20,6 Z"
        if style in ("chanel", "longo"):
            cover = "M-22,14 C-26,-12 -12,-28 2,-28 C18,-28 27,-12 24,14 C14,17 -10,17 -22,14 Z"
        if style == "careca":
            cover = "M-19,3 C-20,-4 -18,-10 -15,-12 C-15,-4 -16,2 -15,7 Z M21,3 C22,-4 20,-10 17,-12 C17,-4 18,2 17,7 Z"
        o.append(path(cover, hair_fill, INK, 1.3))
        for s in shines[:1]:
            o.append(path(s, "none", hc[2], 2.6, 'opacity="0.6"'))
        if ear_visible:
            o.append(E(-19.5, 4, 3.2, 5, sk[0], INK, 1.1) + E(21.5, 4, 3.2, 5, sk[0], INK, 1.1))
        return "".join(o)
    o.append(_face(D, expr, sk, hc, **face))
    o.append(path(front, hair_fill, INK, 1.3))
    if style == "bone":
        cap = face.get("cap", "#e2503f")
        o.append(path("M-20.5,1 C-21.5,-18 -8,-29 3,-29 C16,-29 24.5,-20 23.5,-6 C14,-9 1,-9 -20.5,1 Z",
                      D.lin([(0, light(cap, 0.25)), (1, dark(cap, 0.15))]), INK, 1.3))
        o.append(path("M12,-9 C22,-13 34,-12 38,-6.5 C32,-3.5 22,-3.5 12,-4.5 Z", dark(cap, 0.25), INK, 1.3))
        o.append(E(2, -28.5, 2.6, 1.3, dark(cap, 0.3), INK, 0.9))
        o.append(path("M3,-28 C1,-20 1,-13 2,-8", "none", dark(cap, 0.3), 1.0))
    for s in shines:
        o.append(path(s, "none", hc[2], 2.6, 'opacity="0.6"'))
    if style == "rabo":
        o.append(E(-15.5, -13.5, 2.6, 3.4, face.get("tie", "#e2503f"), INK, 1.0))
    if style == "coque":
        o.append(path("M-14,-28 C-11,-23 -5,-23 -3,-27", "none", hc[1], 1.4))
    if style == "black":
        r = Rng(11)
        for _ in range(9):
            a = r.u(math.pi * 1.0, math.pi * 1.9)
            rr = r.u(22, 27)
            x, y = 1 + rr * math.cos(a), -9 + rr * 0.93 * math.sin(a)
            o.append(path(f"M{f(x-2.2)},{f(y+0.6)} q2.2,-2.6 4.4,0", "none", hc[1], 1.0, 'opacity="0.7"'))
    if ear_visible:
        o.append(E(-16.5, 4, 3.4, 5, D.lin([(0, sk[0]), (1, sk[1])]), INK, 1.1))
        o.append(path("M-17.4,1.6 Q-15.2,4 -17,6.4", "none", sk[1], 1.1))
    return "".join(o)


# --- Corpo ----------------------------------------------------------------------------

TORSO = ("M-12,-55 C-15,-54 -16,-50 -15,-46 L-13,-31 C-12,-28 -9,-27 -6,-27 L8,-27 C12,-27 14,-29 14,-32 "
         "L16,-46 C17,-51 15,-55 10,-56 C4,-58 -6,-57 -12,-55 Z")


def _cloth(D, c):
    return D.lin([(0, light(c, 0.2)), (0.5, c), (1, dark(c, 0.18))], 0, 0, 1, 1)


def _arms(D, top_style, shirt, skin, pose, dy=0.0, tray=None):
    sk = SKIN[skin]
    skin_fill = D.lin([(0, sk[0]), (1, sk[1])], 0, 0, 1, 0)
    long_sleeve = top_style in ("camisa", "moletom", "chef", "garcom")
    sleeve = _cloth(D, "#ffffff" if top_style in ("chef", "garcom") else shirt)
    o_back, o_front = [], []
    # braço de trás
    swing = {"andar": -3.0}.get(pose, 0.0)
    if long_sleeve:
        o_back.append(path(f"M-12,{f(-55+dy)} C-17,{f(-54+dy)} {f(-19.5+swing)},{f(-48+dy)} {f(-19+swing)},{f(-36+dy)} "
                           f"L{f(-14+swing)},{f(-35.5+dy)} L-12.5,{f(-50+dy)} Z", sleeve, INK, 1.2))
    else:
        o_back.append(path(f"M{f(-19.4+swing)},{f(-45+dy)} L{f(-19.6+swing)},{f(-35+dy)} C{f(-19.6+swing)},{f(-32.6+dy)} "
                           f"{f(-14+swing)},{f(-32.6+dy)} {f(-13.8+swing)},{f(-35+dy)} L-13.2,{f(-44.5+dy)} Z", skin_fill, INK, 1.1))
        o_back.append(path(f"M-11.5,{f(-55.5+dy)} C-17.5,{f(-55+dy)} -20.5,{f(-50+dy)} -20.2,{f(-42.5+dy)} L-12.6,{f(-42+dy)} L-12,{f(-50+dy)} Z",
                           sleeve, INK, 1.2))
    o_back.append(C(-16.4 + swing, -32.5 + dy, 3.1, sk[0], INK, 1.1))
    # braço da frente
    if tray:
        o_front.append(path(f"M10,{f(-56+dy)} C16,{f(-56+dy)} 20,{f(-51+dy)} 20.5,{f(-46+dy)} L22,{f(-52+dy)} L27,{f(-56+dy)} "
                            f"L24,{f(-60+dy)} L15.5,{f(-53+dy)} Z", sleeve, INK, 1.2))
        o_front.append(C(26.5, -57.5 + dy, 3.2, sk[0], INK, 1.1))
        o_front.append(E(31, -61 + dy, 17, 5, D.lin([(0, "#f4f6f8"), (1, "#aeb6bf")]), INK, 1.3))
        o_front.append(E(31, -62 + dy, 14, 3.8, "#dfe4e9", None))
        from food import food
        o_front.append(food(D, tray, 31, -71 + dy, 30))
        return "".join(o_back), "".join(o_front)
    swing_f = {"andar": 3.0}.get(pose, 0.0)
    if long_sleeve:
        o_front.append(path(f"M10,{f(-56+dy)} C16,{f(-56+dy)} {f(20+swing_f)},{f(-50+dy)} {f(19.5+swing_f)},{f(-36.5+dy)} "
                            f"L{f(14.5+swing_f)},{f(-36+dy)} L13,{f(-50+dy)} Z", sleeve, INK, 1.2))
    else:
        o_front.append(path(f"M13.4,{f(-45+dy)} L{f(14.2+swing_f)},{f(-35.5+dy)} C{f(14.4+swing_f)},{f(-33+dy)} "
                            f"{f(19.6+swing_f)},{f(-33+dy)} {f(19.6+swing_f)},{f(-35.5+dy)} L19.6,{f(-45.5+dy)} Z", skin_fill, INK, 1.1))
        o_front.append(path(f"M9.6,{f(-56.5+dy)} C16.5,{f(-56.5+dy)} 20.8,{f(-51+dy)} 20.4,{f(-43.5+dy)} L12.8,{f(-43+dy)} L12.6,{f(-50+dy)} Z",
                            sleeve, INK, 1.2))
    o_front.append(C(16.8 + swing_f, -33 + dy, 3.3, sk[0], INK, 1.1))
    return "".join(o_back), "".join(o_front)


def _torso(D, top_style, shirt, skin, dy=0.0, accent="#5fc3a4"):
    sk = SKIN[skin]
    t = f"translate(0,{f(dy)})"
    base = "#ffffff" if top_style in ("chef", "garcom") else shirt
    o = [path(TORSO, _cloth(D, base), INK, 1.3)]
    o.append(path("M13.6,-31 L15.6,-46 C16.4,-50 15,-53 12,-54.5 C13,-48 12.4,-38 11,-28 Z", dark(base, 0.12), None,
                  'opacity="0.7"'))
    # gola / detalhes
    if top_style == "camiseta":
        o.append(path("M-3,-57.2 C-1,-52.4 6,-52.4 8,-57.4 Z", D.lin([(0, sk[1]), (1, sk[0])]), INK, 1.0))
    elif top_style == "blusa":
        o.append(path("M-4,-57 L2.6,-49 L9,-57.4 Z", D.lin([(0, sk[1]), (1, sk[0])]), INK, 1.0))
        o.append(path("M-12,-40 C-4,-38 6,-38 15,-41", "none", dark(base, 0.2), 1.0))
    elif top_style == "camisa":
        o.append(path("M-4,-57 L2.6,-50 L9,-57.4 Z", D.lin([(0, sk[1]), (1, sk[0])]), INK, 1.0))
        o.append(path("M-5,-57.5 L2.4,-50 L-1,-47.6 L-6.4,-54 Z M9.6,-57.8 L2.8,-50 L6.4,-47.8 L11,-54.4 Z", light(base, 0.35), INK, 1.0))
        for yy in (-45, -39, -33):
            o.append(C(3.4, yy, 0.9, dark(base, 0.35), None))
    elif top_style == "moletom":
        o.append(path("M-9,-56 C-6,-61 10,-62 13,-56 C9,-54 -5,-54 -9,-56 Z", dark(base, 0.15), INK, 1.1))
        o.append(line(1.4, -54.5, 1.2, -46, light(base, 0.6), 1.1) + line(5, -54.5, 5.4, -46, light(base, 0.6), 1.1))
        o.append(path("M-7,-36 L12,-36.6 L12.6,-30 L-6.6,-29.4 Z", dark(base, 0.1), INK, 0.9))
    elif top_style == "garcom":
        o.append(path("M-4,-57 L2.6,-50 L9,-57.4 Z", "#ffffff", INK, 1.0))
        vest = D.lin([(0, "#4a4a55"), (1, "#23232b")], 0, 0, 1, 1)
        o.append(path("M-12,-55 C-15,-54 -16,-50 -15,-46 L-13,-31 C-12,-28 -9,-27 -6,-27 L1.6,-27 L1.6,-42 Z", vest, INK, 1.1))
        o.append(path("M10,-56 C15,-55 17,-51 16,-46 L14,-32 C14,-29 12,-27 8,-27 L3.4,-27 L3.4,-42 Z", vest, INK, 1.1))
        o.append(path("M-2.6,-56 L2.6,-53.6 L7.8,-56.4 L7.8,-51 L2.6,-53.4 L-2.6,-51 Z", "#c7353f", INK, 1.0))
        for yy in (-38, -33):
            o.append(C(4.2, yy, 0.9, "#d8dde2", None))
    elif top_style == "chef":
        o.append(path("M-3,-57.4 L2.6,-52 L9,-57.6 Z", accent, INK, 1.0))
        o.append(path("M2.6,-52 L1,-46 L4.2,-46 Z", accent, INK, 0.9))
        for col_x in (-2, 8):
            for yy in (-44, -38, -32):
                o.append(C(col_x, yy, 1.0, "#cfd4da", INK, 0.6))
    return g("".join(o), t)


def _legs(D, bottom_style, bottom, shoes, pose, skin):
    sk = SKIN[skin]
    cloth = _cloth(D, bottom)
    shoe_fill = D.lin([(0, light(shoes, 0.25)), (1, dark(shoes, 0.2))])
    o = []
    if pose == "sentado":
        o.append(path("M11.5,6 L12,19 C12,21 16,21 16.4,19 L17,5 Z", _cloth(D, bottom if bottom_style == "calca" else sk[0]), INK, 1.1))
        o.append(path("M11.4,18 C11,22 17,23 21.4,22 C22.6,20 20.4,17.4 17,17.2 Z", shoe_fill, INK, 1.1))
        if bottom_style == "saia":
            o.append(path("M-12,-4 C-13,2 -9,5 -4,5.4 L14,9 C17,9 18.2,6 17,2.6 L4,-4 Z", cloth, INK, 1.2))
        else:
            o.append(path("M-10,-3 C-11,3 -7,5 -3,5 L12,8.5 C15.5,9 17,6 16,2.6 L4,-3 Z", cloth, INK, 1.2))
        return "".join(o)
    if pose == "andar":
        legs = [("M-9,-28 L-13.5,-6 C-14,-4 -12.5,-3 -11,-3 L-7,-3 C-5.6,-3 -5,-4 -4.8,-5.6 L1,-27 Z",
                 "M-14.4,-5 C-15.4,-0.6 -8,0.8 -4.2,0 C-3,-1.6 -3.6,-4.8 -5.6,-5.2 Z"),
                ("M1,-27 L7,-5.4 C7.4,-3.6 8.6,-2.6 10.4,-2.8 L14,-3.2 C15.8,-3.4 16.4,-4.6 16.2,-6.2 L13.6,-28 Z",
                 "M6.6,-4 C6.6,0.4 15,1.8 21,0.4 C22,-1.6 20,-4.8 16.4,-5.2 L8,-5.2 Z")]
    else:
        legs = [("M-10,-28 L-9.6,-6 C-9.6,-4 -8,-3.4 -6,-3.4 L-2.4,-3.4 C-1,-3.4 0,-4.4 0,-6 L1,-27 Z",
                 "M-10,-4.5 C-10.4,0 -3,1 1,0.2 C2.2,-1.4 1.4,-4.8 -0.6,-5 Z"),
                ("M1,-27 L2,-5 C2,-3 3.4,-2.4 5,-2.4 L9,-2.4 C11,-2.4 12,-3.2 12,-5 L13.6,-28 Z",
                 "M1.6,-3.8 C1.4,0.6 10,1.8 16,0.6 C17,-1.4 15,-4.6 11.6,-5 L3,-5 Z")]
    for leg, shoe in legs:
        fill = cloth if bottom_style == "calca" else D.lin([(0, sk[0]), (1, sk[1])], 0, 0, 1, 0)
        o.append(path(leg, fill, INK, 1.2))
        o.append(path(shoe, shoe_fill, INK, 1.2))
    if bottom_style == "saia":
        o.append(path("M-13,-30 L15,-30 L19,-13 C8,-9.6 -6,-9.6 -16,-13 Z", cloth, INK, 1.2))
        o.append(path("M-4,-29 L-6.5,-11 M6,-29 L7.5,-10.6", "none", dark(bottom, 0.2), 0.9))
    return "".join(o)


def person(D, x, y, s=1.0, facing=1, pose="em_pe", skin="clara", hair=("curto", "castanho"),
           top=("camiseta", "#5fc3a4"), bottom=("calca", "#34495e"), shoes="#3b2a22", expr="feliz",
           back=False, tray=None, apron=None, hat=None, **face):
    """Personagem com os pés em (x, y). pose: em_pe | andar | sentado (y = assento).
    facing 1 = olha para a direita, -1 = esquerda. back = visto de costas."""
    top_style, shirt = top
    bottom_style, bcol = bottom
    dy = 26.0 if pose == "sentado" else 0.0
    o = []
    if pose != "sentado":
        o.append(E(2, 0.5, 17, 5, "#1c0d05", None, extra='opacity="0.2"'))
    # cabelo comprido fica atrás do corpo
    style = hair[0]
    hc = HAIR[hair[1]]
    arm_back, arm_front = _arms(D, top_style, shirt, skin, pose, dy, tray)
    hx, hy = 3.0, -78.0 + dy
    if style == "longo" and not back:
        back_layer = _hair_paths("longo")[0]
        o.append(g(path(back_layer, D.lin([(0, hc[0]), (1, hc[1])]), INK, 1.3), f"translate({f(hx)},{f(hy)})"))
    if not (back and pose == "sentado"):
        o.append(_legs(D, bottom_style, bcol, shoes, pose, skin))
    o.append(arm_back)
    o.append(_torso(D, top_style, shirt, skin, dy, face.get("accent", "#5fc3a4")))
    if apron:
        o.append(path(f"M-9,{f(-47+dy)} L11,{f(-47+dy)} L13.4,{f(-11+dy if pose != 'sentado' else -1)} "
                      f"C6,{f(-8+dy if pose != 'sentado' else 2)} -6,{f(-8+dy if pose != 'sentado' else 2)} -12,{f(-11+dy if pose != 'sentado' else -1)} Z",
                      _cloth(D, apron), INK, 1.1))
        o.append(line(-9, -47 + dy, -12, -53 + dy, INK, 1.0) + line(11, -47 + dy, 13, -53 + dy, INK, 1.0))
    sk = SKIN[skin]
    # pescoço
    o.append(path(f"M-3,{f(-60+dy)} L-3,{f(-54.5+dy)} C-1,{f(-52.5+dy)} 6,{f(-52.5+dy)} 8,{f(-54.5+dy)} L8,{f(-60+dy)} Z",
                  D.lin([(0, sk[1]), (1, sk[0])]), INK, 1.0))
    o.append(g(head(D, skin, hair, expr, back=back, **face), f"translate({f(hx)},{f(hy)})"))
    if hat == "chef":
        o.append(g(path("M-15,-17 C-20,-31 -12,-42 -3,-38 C0,-47 14,-46 16,-36 C23,-36 26,-25 19,-17 Z",
                        D.lin([(0, "#ffffff"), (1, "#dde2e8")]), INK, 1.3)
                   + path("M-5,-37 C-5,-30 -4,-24 -3,-19 M6,-40 C6,-32 6,-25 6,-19", "none", "#c9d0d8", 1.0)
                   + path("M-16,-19 C-6,-22 10,-22 21,-19 L20,-12 C9,-14 -5,-14 -15,-12 Z", "#ffffff", INK, 1.2),
                   f"translate({f(hx)},{f(hy)})"))
    o.append(arm_front)
    t = f"translate({f(x)},{f(y)}) scale({f(s*facing)},{f(s)})"
    return g("".join(o), t)


def head_top(y_feet, s=1.0, pose="em_pe"):
    """Altura do topo da cabeça em relação aos pés (para posicionar balões)."""
    dy = 26.0 if pose == "sentado" else 0.0
    return y_feet + (-78 + dy - 24) * s
