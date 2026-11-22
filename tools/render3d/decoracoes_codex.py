"""Decorações Codex: modelos nativos e prova isolada, sem instalar arte.

Blender -b -t 3 -P tools/render3d/decoracoes_codex.py -- --proof
Blender -b -t 3 -P tools/render3d/decoracoes_codex.py -- --samples 40

Mantém IDs, aliases, pegadas, origem isométrica e os estados das portas.
O JSON contém somente metadados dos PNGs produzidos; core/data não são escritos.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import random
import re
import sys

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cena3d as C
import moveis3d as M
import amostra_a3d as A
import assentos_a3d as H
import enfeites_a3d as E
import superficies3d as S

ROOT = Path(__file__).resolve().parents[2]
CREAM, TEAL, CLAY, HONEY, INK = "#f3e6cb", "#346b5c", "#ae6348", "#b38750", "#343b37"
EXCLUDE = {"machine_coffee", "machine_coffee_smart", "machine_juice", "machine_frozen",
           "train_locomotive", "train_wagon", "train_dining", "witch_cauldron", "delivery_counter", "santa_oven"}
FLOOR = tuple(k for k in E.ITEMS if k not in EXCLUDE)
WALL = ("arandela", "espelho", "lousa", "neon_xicara", "painel_digital", "planta_pendurada",
        "prateleira", "quadro_cupcake", "quadro_paisagem", "radio", "relogio", "tv")
DOORS = tuple("door_" + (style or "classico") for style in S.DOOR_STYLES)
PROOF = ("plant_pot", "tree_mango", "floor_lamp", "arcade", "bookshelf", "christmas_tree",
         "quadro_cupcake", "neon_xicara", "door_classico", "door_japones")


def flat(objects):
    return [o for o in M._flatten(objects) if o is not None]


def ceramic(color=CREAM):
    return M.solid(color, 0.38, 0.0, 0.22)


def brass():
    return M.solid("#b68c4b", 0.4, 0.65)


def oak():
    return A.grain_wood("#92704f", 0.18)


def transform(objects, scale=(1, 1, 1), offset=(0, 0, 0)):
    """Aplica a proporção em espaço de mundo, incluindo texto, sem deslocar a origem."""
    bpy.context.view_layer.update()
    mat = Matrix.Translation(Vector(offset)) @ Matrix.Diagonal((*scale, 1))
    for obj in objects:
        obj.matrix_world = mat @ obj.matrix_world
    bpy.context.view_layer.update()
    return objects


def pot(radius, height, material=None):
    """Vaso canelado: pé, bojo suave, borda arredondada e terra recuada."""
    r, h = radius, height
    body = material or ceramic()
    parts = [H.lathe([(0, 0), (r*.65, 0), (r*.68, h*.12), (r*.85, h*.18),
                      (r, h*.83), (r*.98, h), (r*.87, h), (r*.86, h*.87), (0, h*.87)], body),
             M.cylinder(r*.86, h*.86, h*.875, M.solid("#514030", .95)),
             E.torus(r*.94, r*.045, (0, 0, h*.94), body)]
    for i in range(18):
        a = math.tau*i/18
        parts.append(M.tube((math.cos(a)*r*.82, math.sin(a)*r*.82, h*.22),
                            (math.cos(a)*r*.99, math.sin(a)*r*.99, h*.82), r*.018, body))
    return parts


def planter_box(radius, height, material):
    r, h = radius, height
    parts = [M.box((r*2, r*2, h*.88), (0, 0, h*.54), ceramic(CREAM), .035),
             M.box((r*2.08, r*2.08, h*.10), (0, 0, h*.95), oak(), .012),
             M.box((r*1.8, r*1.8, .01), (0, 0, h), M.solid("#514030", .95), 0)]
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(M.box((r*.24, r*.24, h*.18), (sx*r*.7, sy*r*.7, h*.09), oak(), .008))
    for i in (-1, 0, 1):
        parts.append(M.box((.012, .012, h*.56), (i*r*.52, -r-.003, h*.55), ceramic(CLAY), .003))
    return parts


def stem_leaf(base, tip, width, color):
    direction = Vector(tip)-Vector(base)
    parts = [E.leaf(base, direction, direction.length, width, ceramic(color))]
    parts.append(M.tube(base, Vector(base)+direction*.86, .0023, ceramic("#99aa6b")))
    return parts


def plant_pot():
    parts = pot(.19, .27, ceramic(CREAM))
    greens = ("#396e50", "#5f8d62", "#7d9d68")
    for i in range(9):
        a = i*2.4; h = .52 + (i%3)*.12; r = .22 + (i%2)*.08
        joint = (math.cos(a)*r*.35, math.sin(a)*r*.35, h*.72)
        tip = (math.cos(a)*r, math.sin(a)*r, h)
        parts.append(M.tube((0, 0, .25), joint, .008, ceramic(greens[0])))
        parts += stem_leaf(joint, tip, .062, greens[i%3])
    return parts


def succulents():
    parts = [M.box((.72, .36, .035), (0, 0, .12), oak(), .018)]
    for x in (-.28, .28):
        for y in (-.11, .11):
            parts.append(A.taper((x, y, 0), (x*.9, y, .12), .011, .016, oak()))
    for i, (x, color) in enumerate(((-.23, "#7eaa8e"), (0, "#a9b789"), (.23, "#709596"))):
        parts += transform(pot(.105, .13, ceramic((CREAM, CLAY, TEAL)[i])), offset=(x, 0, .14))
        for row in range(3):
            parts += E.rosette((x, 0, .267+row*.01), 9-row*2, .12-row*.025, .038-row*.004,
                               67-row*22, ceramic(color), phase=i+row*.4)
    return parts


def bonsai():
    parts = [M.box((.5, .36, .04), (0, 0, .09), oak(), .018)]
    for x in (-.19, .19):
        for y in (-.12, .12):
            parts.append(M.box((.035, .035, .08), (x, y, .04), oak(), .008))
    parts += transform(pot(.21, .13, ceramic(TEAL)), scale=(1, .72, 1), offset=(0, 0, .11))
    parts += E.crooked([(0, 0, .23), (.07, .01, .33), (-.03, 0, .45), (.03, .01, .58)], .028, oak())
    for x, z, r in ((-.17, .48, .12), (.18, .42, .11), (.03, .61, .14)):
        parts.append(M.tube((0, 0, z-.1), (x, 0, z), .014, oak()))
        parts += E.crown([(x, 0, z, r)], "#557c4f", int(z*100), 26, .065, .027)
    return parts


def floor_lamp(kind):
    dark, gold = ceramic(INK), brass()
    parts = [M.cylinder(.155, 0, .035, dark, bevel=.012), M.cylinder(.025, .03, 1.04, gold)]
    if kind == "floor_lamp":
        for i in range(28):
            a=math.tau*i/28
            parts.append(M.tube((math.cos(a)*.23, math.sin(a)*.23, .86),
                                (math.cos(a)*.16, math.sin(a)*.16, 1.13), .005, ceramic(CREAM)))
        parts.append(H.lathe([(.23,.86),(.16,1.13),(.151,1.13),(.22,.86)], ceramic(CREAM)))
        parts += [E.torus(.227,.008,(0,0,.86),gold), E.torus(.157,.007,(0,0,1.13),gold)]
    elif kind == "edison_lamp":
        parts += E.crooked([(0,0,1.04),(.05,0,1.12),(.2,0,1.13),(.27,0,1.05)], .018, dark)
        parts.append(H.lathe([(.15,.90),(.14,.96),(.07,1.04),(.025,1.05)], ceramic(TEAL), (.27,0)))
        parts.append(M.sphere(.045,(.27,0,.92),M.emission("#ffd9a0",2.0)))
    else:
        # Akari: lanterna oval com costelas bambu e haste em balanço.
        parts.append(M.tube((0,0,1.04),(.24,0,1.14),.014,oak()))
        parts.append(M.tube((.24,0,1.14),(.24,0,1.08),.006,gold))
        parts.append(M.sphere(.20,(.24,0,.89),ceramic("#f1d9b2"),(1,1,1.13)))
        for i in range(1,9):
            z=.89-.225+i*.045; rr=.202*math.sqrt(max(.01,1-((z-.89)/.226)**2))
            parts.append(E.torus(rr,.0035,(.24,0,z),ceramic("#b29065")))
        parts.append(M.cylinder(.055,.655,.685,ceramic(CLAY),(.24,0)))
        parts.append(M.tube((.24,0,.655),(.24,0,.55),.005,brass()))
    return parts


def ring_stand(radius=.29, height=.08, color=TEAL):
    return [M.cylinder(radius,0,height,ceramic(color),bevel=.014),
            E.torus(radius*.98,.009,(0,0,height*.84),brass())]


def floor_item(item):
    if item == "plant_pot": return plant_pot()
    if item == "bonsai": return bonsai()
    if item == "succulents": return succulents()
    if item in ("floor_lamp", "edison_lamp", "paper_lantern"): return floor_lamp(item)
    objects = flat(E.ITEMS[item]())
    if item=="bookshelf":
        # O modelo legado sobrepõe faces de fundo/prateleiras exatamente no mesmo plano.
        # Separa o painel traseiro e a frente das três prateleiras para evitar z-fighting.
        bpy.context.view_layer.update()
        objects[0].location.y += .014
        for obj in objects:
            if abs(obj.dimensions.x-1.86)<.0001 and abs(obj.dimensions.z-.035)<.0001:
                obj.location.y -= .009
    # Silhuetas específicas preservadas, proporções menos maciças e novos suportes/detalhes.
    scale = {"bookshelf":(.92,.88,.77), "stage":(.94,.94,.77), "dj_booth":(.9,.85,.8),
             "arcade":(.88,.9,.76), "claw_machine":(.86,.88,.8), "jukebox":(.86,.86,.83),
             "christmas_tree":(.85,.85,.9), "macrame_plant":(.85,.85,.88),
             "giant_pumpkin":(.79,.79,.76), "party_cake":(.85,.85,.82),
             "paris_lamp":(.9,.9,.85), "station_clock":(.88,.88,.86),
             "banana_tree":(.85,.85,.88), "olive_tree":(.84,.84,.88)}.get(item,(.88,.88,.87))
    transform(objects,scale)
    if item in ("arcade","claw_machine","jukebox"):
        # Rodapé cerâmico e molduras táteis substituem o bloco visual único.
        objects += [M.box((.61,.58,.06),(0,0,.03),ceramic(CREAM),.02)]
        for x in (-.28,.28):
            objects.append(M.box((.035,.035,.64),(x,-.28,.4),brass(),.008))
        if item=="arcade":
            screen=[E.prism([(-.26,1.245),(-.25,1.245),(-.305,.89),(-.315,.89)],.50,ceramic("#26463f"),0)]
            for row,bits in enumerate(("0100010","0011100","0111110","1101011","1111111","1010101")):
                for col,bit in enumerate(bits):
                    if bit=="1":
                        z=1.17-row*.027;y=-.321+(z-.89)*.155
                        screen.append(M.box((.020,.008,.020),((col-3)*.029,y,z),M.emission("#b8d7a4",.8),.001))
            objects += transform(screen,scale)
    elif item == "bookshelf":
        # Credenza baixa com pés, moldura estreita e travessas de latão.
        transform(objects,offset=(0,0,.075))
        for x in (-.72,.72):
            for y in (-.15,.15): objects.append(A.taper((x,y,0),(x,y,.09),.015,.025,brass()))
        for x in (-.57,0,.57):
            objects.append(M.box((.48,.012,.018),(x,-.205,.52),brass(),.004))
    elif item in ("boombox","lava_lamp","trophy_bronze","trophy_silver","trophy_gold","parrot"):
        transform(objects,offset=(0,0,.045))
        objects += ring_stand(.25 if item != "boombox" else .32,.045,CLAY if item=="lava_lamp" else TEAL)
    elif item in ("critic_statue","eiffel"):
        objects += [M.box((.60,.60,.025),(0,0,.013),ceramic(TEAL),.02)]
        for x in (-.21,.21): objects.append(M.sphere(.018,(x,-.25,.10),brass()))
    elif item in ("cupcake_tree","chocolate_fountain","party_cake"):
        objects += [E.torus(.33,.012,(0,0,.045),ceramic(CREAM))]
        for a in (0,math.tau/3,math.tau*2/3):
            objects.append(M.sphere(.018,(.26*math.cos(a),.26*math.sin(a),.025),brass()))
    elif item in ("giant_pumpkin","hay_bale","wagon_wheel","wine_barrel"):
        # Folhas, pequenos volumes laterais e base de apoio quebram a simetria dos prêmios.
        for i in range(5):
            a=i*1.7
            objects.append(E.leaf((.25*math.cos(a),.25*math.sin(a),.015),
                                  (math.cos(a),math.sin(a),.1),.14,.035,ceramic("#8b9b60")))
    elif item in ("balloons","pinata","popcorn_cart","ring_toss"):
        objects += [M.box((.37,.32,.045),(0,0,.023),ceramic(CREAM),.024)]
        for x in (-.13,.13): objects.append(M.sphere(.014,(x,-.166,.03),brass()))
    elif item in ("disco_ball","dj_booth","stage"):
        for x in (-.28,.28):
            objects += [M.box((.15,.08,.04),(x,-.4,.025),ceramic(TEAL),.01),
                        M.sphere(.019,(x,-.4,.06),M.emission("#eac995",1.5))]
    elif item in ("neon_diner","station_clock","paris_lamp"):
        objects += [M.cylinder(.17,0,.03,ceramic(TEAL),bevel=.012)]
    elif item == "christmas_tree":
        objects += E.gift((-.22,.19,0),(.13,.12,.11),ceramic(TEAL),brass())
        objects += E.gift((.2,-.22,0),(.14,.10,.09),ceramic(CREAM),ceramic(CLAY))
    elif item == "flower_vase":
        objects += ring_stand(.15,.018,CREAM)
    return flat(objects)


def wall_frame(width,height,cx,cz,color=TEAL):
    parts = [M.box((width+.055,.04,height+.055),(cx,-.022,cz),oak(),.012),
             M.box((width,.012,height),(cx,-.048,cz),ceramic(CREAM),.003)]
    for x in (cx-width/2,cx+width/2):
        parts.append(M.box((.014,.012,height),(x,-.058,cz),ceramic(color),.004))
    for z in (cz-height/2,cz+height/2):
        parts.append(M.box((width,.012,.014),(cx,-.058,z),ceramic(color),.004))
    return parts


def wall_print(kind):
    cx,cz=S.at(21,-67); w,h=.56,.54
    parts=wall_frame(w,h,cx,cz)
    y=-.068
    if kind=="cupcake":
        parts += [M.box((.21,.008,.14),(cx,y,cz-.08),ceramic(CLAY),.018),
                  M.sphere(.12,(cx,y-.004,cz+.04),ceramic("#e4b294"),(1,.055,.55)),
                  M.sphere(.023,(cx,y-.012,cz+.14),ceramic("#a3483a"))]
        for x in (-.07,-.035,0,.035,.07):
            parts.append(M.box((.009,.005,.11),(cx+x,y-.008,cz-.09),ceramic(CREAM),.003))
    else:
        parts += [M.box((.45,.006,.35),(cx,y,cz),ceramic("#d1ded3"),0),
                  M.sphere(.048,(cx+.12,y-.005,cz+.1),ceramic("#d7ad58"),(1,.04,1))]
        for x,z,r,sx,c in ((-.11,-.12,.17,.65,"#6f8e71"),(.10,-.13,.22,.60,"#426c59"),(0,-.16,.17,.9,"#b4b88b")):
            parts.append(M.sphere(r,(cx+x,y-.012,cz+z),ceramic(c),(sx,.025,.5)))
    return parts


def wall_item(item):
    if item.startswith("quadro_"): return wall_print(item[7:])
    if item=="prateleira":
        parts=A.shelf_a()
        # Segundo nível menor e ganchos de canecas abaixo da tábua.
        z=S.at(3,-58)[1]
        for x in (.27,.50,.73):
            parts.append(E.torus(.025,.004,(x,-.08,z-.06),brass(),(math.pi/2,0,0)))
            parts += [M.cylinder(.032,z-.16,z-.09,ceramic((TEAL,CLAY,CREAM)[round(x*10)%3]),(x,-.1),bevel=.008)]
        return parts
    cx,cz=S.at(21,-66)
    if item in ("tv","painel_digital"):
        parts=wall_frame(.78,.47,cx,cz,INK)
        parts += [M.box((.72,.008,.41),(cx,-.065,cz),ceramic("#263f3b"),.006)]
        if item=="tv":
            parts += [M.sphere(.055,(cx+.21,-.073,cz+.1),M.emission("#e3bb6c",.7),(1,.05,1))]
            for i,(color,h) in enumerate((("#6b967b",.17),("#3b6b58",.11),("#b8be92",.07))):
                parts.append(M.box((.65-i*.05,.004,h),(cx,-.075-i*.005,cz-.18+h/2),ceramic(color),.005))
        else:
            for i in range(3):
                z=cz+.12-i*.115
                parts += [M.box((.34,.006,.018),(cx-.12,-.073,z),ceramic(CREAM),.005),
                          M.box((.07,.006,.018),(cx+.24,-.073,z),ceramic(HONEY),.005)]
        return parts
    if item=="lousa":
        parts=wall_frame(.67,.57,cx,cz,CLAY)
        parts += [M.box((.60,.01,.5),(cx,-.066,cz),ceramic("#294c42"),.004),
                  M.box((.70,.075,.025),(cx,-.075,cz-.3),oak(),.006)]
        for i,w in enumerate((.34,.40,.29)):
            parts += [M.box((w,.005,.014),(cx-.04,-.076,cz+.11-i*.115),ceramic(CREAM),.004),
                      M.sphere(.012,(cx+.23,-.079,cz+.11-i*.115),ceramic(HONEY),(1,.2,1))]
        return parts
    if item=="neon_xicara":
        parts=wall_frame(.64,.61,cx,cz,CLAY)
        parts.append(M.box((.58,.008,.55),(cx,-.064,cz),ceramic("#293e38"),.008))
        glow=M.emission("#e9b785",2.0)
        points=[(cx-.17,-.079,cz+.02),(cx-.14,-.079,cz-.14),(cx+.10,-.079,cz-.14),(cx+.14,-.079,cz+.02)]
        parts += E.crooked(points,.010,glow)
        parts += [E.torus(.065,.009,(cx+.16,-.08,cz-.04),glow,(math.pi/2,0,0)),
                  M.tube((cx-.21,-.08,cz-.20),(cx+.20,-.08,cz-.20),.009,glow)]
        for x in (-.06,.05):
            parts += E.crooked([(cx+x,-.08,cz+.08),(cx+x-.02,-.08,cz+.15),(cx+x+.01,-.08,cz+.21)],.007,M.emission("#86bca2",1.8))
        return parts
    if item=="arandela":
        cx,cz=S.at(21,-71)
        return [M.box((.09,.035,.20),(cx,-.02,cz),ceramic(TEAL),.02),
                M.tube((cx,-.02,cz+.03),(cx,-.18,cz+.07),.014,brass()),
                M.sphere(.075,(cx,-.18,cz+.01),ceramic("#f1d9b2"),(1,1,1.15)),
                M.cylinder(.055,cz-.09,cz-.075,brass(),(cx,-.18)),
                M.cylinder(.08,cz+.085,cz+.10,ceramic(TEAL),(cx,-.18),bevel=.008)]
    if item=="relogio":
        parts=A.clock_a()
        cx,cz=S.at(21,-74)
        for i in range(12):
            a=math.tau*i/12
            parts.append(M.sphere(.008,(cx+.14*math.sin(a),-.064,cz+.14*math.cos(a)),brass(),(1,.25,1)))
        parts.append(M.sphere(.017,(cx,-.071,cz),ceramic(CLAY),(1,.3,1)))
        return parts
    if item=="espelho":
        parts=S.wall_item(item)
        for i in range(12):
            a=math.tau*i/12
            parts.append(M.sphere(.012,(cx+.31*math.sin(a),-.045,cz+.38*math.cos(a)),brass()))
        parts.append(M.box((.38,.10,.022),(cx,-.07,cz-.40),oak(),.008))
        return parts
    if item=="radio":
        parts=S.wall_item(item)
        _,z=S.at(5,-50)
        for i in range(9): parts.append(M.box((.008,.008,.19),(.31+i*.027,-.143,z+.19),ceramic("#aa946b"),.002))
        parts.append(M.box((.14,.008,.026),(.66,-.143,z+.17),ceramic(TEAL),.003))
        return parts
    # Novo pendente: vaso canelado, três cordas e folhas com queda assimétrica.
    top=S.WALL_Z*.96; pz=top-.48
    parts=transform(pot(.115,.14,ceramic(CLAY)),offset=(cx,-.17,pz))
    for a in (0,math.tau/3,math.tau*2/3):
        parts.append(M.tube((cx,-.17,top),(cx+.1*math.cos(a),-.17+.1*math.sin(a),pz+.1),.004,ceramic(CREAM)))
    for i in range(9):
        a=i*2.4; base=(cx,-.17,pz+.14); tip=(cx+.19*math.cos(a),-.17+.13*math.sin(a),pz-.1-(i%3)*.05)
        parts += stem_leaf(base,tip,.032,("#5c855b","#7d9c69","#3e6b4e")[i%3])
    return parts


DOOR_COLOR={"classico":TEAL,"frances":"#627b8b","japones":"#7a5638","italiano":"#657c50",
            "anos70":"#b87c42","americano":"#ad594a","anos2010":"#546760","festa":"#b78482",
            "anos80":"#6d6484","balada":"#594a68","brasileiro":"#527c53","country":"#906647","mexicano":"#ae704b"}


def doorway(item,closed):
    style=item[5:]; color=DOOR_COLOR[style]; top=78/S.DESIGN_H*S.WALL_Z
    frame=ceramic(color); wood=oak(); gold=brass()
    parts=[M.box((.095,.115,top),(x,-.025,top/2),frame,.014) for x in (.05,.95)]
    parts += [M.box((1.06,.13,.09),(.5,-.025,top+.045),frame,.014),
              M.box((1.10,.14,.025),(.5,-.025,top+.103),wood,.006)]
    for x in (.05,.95):
        parts += [M.box((.13,.14,.16),(x,-.03,.08),wood,.012),
                  M.box((.016,.009,top-.2),(x,-.087,top/2+.02),gold,.004)]
    # Folha aberta apoiada no batente; fechada ocupa o mesmo vão, sem alterar passagem no grid.
    w=.80 if closed else .35
    panel=[M.box((w,.035,top-.08),(0,0,(top-.08)/2),frame,.009),
           M.box((w-.09,.041,top*.55),(0,-.003,top*.59),ceramic("#8da49b"),.003),
           M.box((w-.09,.045,top*.21),(0,-.004,top*.18),wood,.005)]
    for z in (top*.32,top*.87): panel.append(M.box((w,.048,.025),(0,-.005,z),frame,.004))
    panel.append(M.tube((w*.35,-.037,top*.42),(w*.35,-.037,top*.54),.009,gold))
    if closed:
        transform(panel,offset=(.5,.015,.025))
    else:
        mat=Matrix.Translation(Vector((.91,.18,.025))) @ Matrix.Rotation(math.pi/2,4,"Z")
        for obj in panel: obj.matrix_world=mat@obj.matrix_world
    parts+=panel
    if style=="japones":
        parts += [M.box((1.14,.32,.045),(.5,-.14,top+.13),wood,.008)]
        for x in (.25,.5,.75): parts.append(M.box((.19,.018,.17),(x,-.29,top-.01),ceramic(CREAM),.004))
    elif style in ("country","brasileiro"):
        canopy=M.box((1.13,.35,.045),(.5,-.18,top+.08),wood,.007); canopy.rotation_euler.x=math.radians(-15);parts.append(canopy)
        for x in (.18,.82): parts.append(M.tube((x,-.03,top-.13),(x,-.31,top+.01),.012,frame))
    else:
        canopy=M.box((1.12,.34,.024),(.5,-.18,top+.055),S.pattern("stripes",[CREAM,color],5,rough=.8),.007)
        canopy.rotation_euler.x=math.radians(-16);parts.append(canopy)
        parts.append(M.box((1.12,.018,.075),(.5,-.342,top-.015),frame,.009))
        for i in range(9): parts.append(M.sphere(.063,(.0+i*.125,-.342,top-.046),frame,(1,.15,.22)))
    if style=="frances":
        # Florão e transom arredondado; o vão de passagem permanece livre.
        parts.append(E.torus(.11,.012,(.5,-.10,top+.05),gold,(math.pi/2,0,0)))
        for x in (.22,.78):parts.append(M.sphere(.025,(x,-.10,top+.05),gold,(1,.5,1)))
    elif style in ("italiano","mexicano"):
        for i in range(7):
            tile=M.box((.055,.009,.055),(.23+i*.09,-.095,top+.04),ceramic(CREAM if i%2 else TEAL),.003)
            tile.rotation_euler.y=math.pi/4;parts.append(tile)
    elif style=="anos70":
        for x in (.05,.95):
            for z in (.28,.50,.72):parts.append(E.torus(.035,.008,(x,-.091,z),ceramic(CREAM),(math.pi/2,0,0)))
    elif style in ("anos80","balada"):
        glow=M.emission("#9bbfb3" if style=="anos80" else "#c8a9b4",1.2)
        for x in (.05,.95):parts.append(M.tube((x,-.093,.22),(x,-.093,top-.05),.006,glow))
    elif style=="americano":
        for x in (.05,.95):
            for z in (.28,.34,.40):parts.append(M.box((.10,.01,.015),(x,-.09,z),gold,.004))
    elif style=="anos2010":
        for x in (.05,.95):
            for z in (.12,top-.12):parts.append(M.sphere(.012,(x,-.091,z),gold,(1,.5,1)))
    sign_z=top-.26
    for x in (.4,.6):parts.append(M.tube((x,-.11,top-.08),(.5,-.11,sign_z+.065),.0035,gold))
    parts += [M.box((.40,.025,.155),(.5,-.11,sign_z),wood,.015),
              M.box((.375,.008,.13),(.5,-.126,sign_z),ceramic(CREAM),.008)]
    bpy.ops.object.text_add(location=(.5,-.133,sign_z-.029),rotation=(math.pi/2,0,0))
    text=bpy.context.active_object;text.data.body="FECHADO" if closed else "ABERTO"
    text.data.font=bpy.data.fonts.load(S.FONT,check_existing=True);text.data.align_x="CENTER"
    text.data.size=.067 if closed else .077;text.data.extrude=.0005
    text.data.materials.append(ceramic(CLAY if closed else TEAL));parts.append(text)
    return parts


def write_json(path,value):
    path.parent.mkdir(parents=True,exist_ok=True)
    temp=path.with_suffix(path.suffix+".tmp")
    temp.write_text(json.dumps(value,ensure_ascii=False,indent=2)+"\n",encoding="utf-8");temp.replace(path)


def bounds(objects):
    bpy.context.view_layer.update()
    points=[obj.matrix_world@v.co for obj in objects if obj.type=="MESH" for v in obj.data.vertices]
    points += [obj.matrix_world@Vector(v) for obj in objects if obj.type!="MESH" for v in obj.bound_box]
    return {"min":[round(min(p[i] for p in points),6) for i in range(3)],
            "max":[round(max(p[i] for p in points),6) for i in range(3)]}


def setup(args,footprint=(1,1),wall=False):
    fx,fy=footprint
    size=(int((1000 if max(footprint)>1 else 680)*args.density/4),int(1080*args.density/4))
    C.setup(args.samples,size,shadow_center=(fx/2,-fy/2),shadow_size=.001 if wall else (fx+.1,fy+.1),rig="a")
    bpy.context.scene.render.threads_mode="FIXED";bpy.context.scene.render.threads=args.threads
    # Sombra radial nativa: o shadow catcher do Cycles espalha alfa residual no fundo.
    for obj in list(bpy.data.objects):
        if obj.is_shadow_catcher:
            # Mantém o retorno de luz do piso; só sua imagem fica fora da câmera.
            obj.is_shadow_catcher=False;obj.visible_camera=False


def radial_shadow(center,size,wall=False):
    mat=bpy.data.materials.get("CodexDecorShadow")
    if mat is None:
        mat=bpy.data.materials.new("CodexDecorShadow");mat.use_nodes=True
        n,links=mat.node_tree.nodes,mat.node_tree.links;n.clear()
        uv=n.new("ShaderNodeTexCoord");offset=n.new("ShaderNodeVectorMath");offset.operation="SUBTRACT"
        offset.inputs[1].default_value=(.5,.5,0)
        length=n.new("ShaderNodeVectorMath");length.operation="LENGTH"
        fade=n.new("ShaderNodeMapRange");fade.interpolation_type="SMOOTHERSTEP"
        for key,value in (("From Min",.18),("From Max",.5),("To Min",.25),("To Max",0)):fade.inputs[key].default_value=value
        clear=n.new("ShaderNodeBsdfTransparent");dark=n.new("ShaderNodeEmission")
        dark.inputs["Color"].default_value=(.022,.016,.012,1)
        mix=n.new("ShaderNodeMixShader");output=n.new("ShaderNodeOutputMaterial")
        links.new(uv.outputs["UV"],offset.inputs[0]);links.new(offset.outputs["Vector"],length.inputs[0])
        links.new(length.outputs["Value"],fade.inputs["Value"]);links.new(fade.outputs["Result"],mix.inputs[0])
        links.new(clear.outputs[0],mix.inputs[1]);links.new(dark.outputs[0],mix.inputs[2]);links.new(mix.outputs[0],output.inputs["Surface"])
    bpy.ops.mesh.primitive_plane_add(size=1,location=center,rotation=(math.pi/2,0,0) if wall else (0,0,0))
    obj=bpy.context.object;obj.scale=(size[0],size[1],1);obj.data.materials.append(mat)
    obj.visible_diffuse=False;obj.visible_glossy=False;obj.visible_shadow=False
    return obj


def floor_shadow(objects,footprint):
    """A sombra acompanha a base do objeto, não o quadrado vazio inteiro do grid."""
    bpy.context.view_layer.update()
    points=[obj.matrix_world@v.co for obj in objects if obj.type=="MESH" for v in obj.data.vertices]
    contact=[p for p in points if -.01<=p.z<=.075]
    if not contact:contact=points
    low=[min(p[i] for p in contact) for i in (0,1)];high=[max(p[i] for p in contact) for i in (0,1)]
    size=[max(.25,min(footprint[i]+.12,high[i]-low[i]+.16)) for i in (0,1)]
    return radial_shadow(((low[0]+high[0])/2,(low[1]+high[1])/2,.001),size)


def validate_resume(previous,current):
    """A retomada conserva exatamente o pedido original, inclusive os modos."""
    for key in ("generator_sha256","source_manifest_sha256","density","samples",
                "requested_items","proof","geometry_only"):
        if key not in previous or previous[key]!=current[key]:
            raise ValueError("Retomada com fonte/parâmetro diferente: "+key)


def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("items",nargs="*");parser.add_argument("--out",default="build/visual-cenario/decoracoes")
    parser.add_argument("--proof",action="store_true");parser.add_argument("--geometry-only",action="store_true")
    parser.add_argument("--resume",action="store_true",help="Retoma somente com gerador e parâmetros idênticos")
    parser.add_argument("--samples",type=int,default=40);parser.add_argument("--density",type=float,default=4)
    parser.add_argument("--threads",type=int,default=3)
    args=parser.parse_args(argv)
    if args.samples<1 or not 1<=args.density<=8 or not 1<=args.threads<=4:parser.error("samples >=1; density 1..8; threads 1..4")
    out=(ROOT/args.out).resolve();build=(ROOT/"build").resolve()
    if out==build or build not in out.parents:parser.error("Saída precisa estar em uma subpasta de build")
    items=args.items or (list(PROOF) if args.proof else list(FLOOR)+list(WALL)+list(DOORS))
    if set(items)-set(FLOOR)-set(WALL)-set(DOORS):parser.error("ID desconhecido")
    manifest=json.loads((ROOT/"art/sprites/sprites.json").read_text(encoding="utf-8"))
    original_manifest=hashlib.sha256((ROOT/"art/sprites/sprites.json").read_bytes()).hexdigest()
    C.SPRITES=str(out/"sprites");Path(C.SPRITES).mkdir(parents=True,exist_ok=True)
    C.DENSITY=args.density;C.PX_PER_UNIT=128/math.sqrt(2)*args.density;C.MIN_ALPHA=0;S.WORK=str(out/"raw")
    # Troca apenas a fábrica de vasos usada neste processo; módulos de origem ficam intactos.
    E.pot=pot;E.planter_box=planter_box
    E.emission=lambda color,strength=1:M.emission(color,min(strength,1.3))
    # Mesmo veio fino aprovado no lambri; substituições só neste processo Blender.
    E.wood=lambda color,gloss=.3:A.grain_wood(color,min(gloss,.22))
    A.rich_wood=lambda color,scale=6,gloss=.55:A.grain_wood(color,min(gloss,.22))
    S.wood=lambda color:A.grain_wood(color,.18)
    patch={"sprites":{}};contract={"schema":1,"density":args.density,"samples":args.samples,
        "proof":args.proof,"geometry_only":args.geometry_only,
        "anchor":"floor: front vertex of footprint; wall: existing R/L origin at wall floor",
        "alpha":"native render, no threshold; radial geometry shadow instead of Cycles catcher",
        "wall_height_world":manifest["wall_height"],"generator_sha256":hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "source_manifest_sha256":original_manifest,"requested_items":items,"items":{},"sprites":{}}
    if args.resume and (out/"manifest_patch.json").exists():
        previous=json.loads((out/"physical_contract.json").read_text(encoding="utf-8"))
        validate_resume(previous,contract)
        patch=json.loads((out/"manifest_patch.json").read_text(encoding="utf-8"));contract=previous
    for item in items:
        if item in FLOOR:
            fp=E.FOOTPRINTS.get(item,(1,1));names=sorted(set(manifest["furniture"][item].values()))
            if args.proof:names=names[:1]
        else:
            fp=(1,1)
            stem="porta"+("" if item=="door_classico" else "_"+item[5:]) if item in DOORS else item
            names=[f"enfeite_{stem}{state}_{side}" for state in (("","_fechada") if item in DOORS else ("",)) for side in ("R","L")]
            if args.proof:names=names[:1]
        if any(n not in manifest["sprites"] for n in names):raise ValueError("Contrato de nome ausente: "+item)
        contract["items"][item]={"kind":"floor" if item in FLOOR else "door" if item in DOORS else "wall",
                                  "footprint":list(fp),"names":names}
        for name in names:
            if args.resume and name in patch["sprites"] and (out/"sprites"/(name+".png")).exists():continue
            rotation=int(name.rsplit("_r",1)[1]) if item in FLOOR else 0
            frot=fp if rotation%2==0 else fp[::-1]
            setup(args,frot,wall=item not in FLOOR)
            objects=flat(floor_item(item) if item in FLOOR else doorway(item,"_fechada_" in name) if item in DOORS else wall_item(item))
            geometry=bounds(objects)
            if not all(math.isfinite(v) for p in geometry.values() for v in p):raise ValueError("Geometria inválida: "+item)
            contract["sprites"][name]={"geometry_bounds":geometry}
            if args.geometry_only:continue
            if item in FLOOR:
                objects.append(floor_shadow(objects,fp))
                anchor,center=M.assemble(objects,fp,rotation)
                if item in E.FACE_CAMERA:
                    objects[0].parent.rotation_euler.z+=math.radians(E.FACE_CAMERA[item]);bpy.context.view_layer.update()
                C.aim_camera((center[0],center[1],.55))
                point=C.shoot(name,anchor,str(out/"raw"))
            else:
                if item not in DOORS:
                    low,high=geometry["min"],geometry["max"]
                    objects.append(radial_shadow(((low[0]+high[0])/2,.003,(low[2]+high[2])/2),
                                                 (high[0]-low[0]+.06,high[2]-low[2]+.06),wall=True))
                anchors={};S.shoot_wall(name,objects,name[-1],args.samples,anchors,catcher=False);point=anchors[name]
            patch["sprites"][name]={"anchor":point,"density":args.density}
            write_json(out/"manifest_patch.json",patch);write_json(out/"physical_contract.json",contract)
            print("SPRITE_READY",name,flush=True)
        print("ITEM_READY",item,flush=True)
    write_json(out/"manifest_patch.json",patch);write_json(out/"physical_contract.json",contract)
    if hashlib.sha256((ROOT/"art/sprites/sprites.json").read_bytes()).hexdigest()!=original_manifest:
        raise RuntimeError("O manifesto de produção mudou durante a geração; confira a integração separadamente")
    print("STAGING_COMPLETE",len(items),len(patch["sprites"]),str(out),flush=True)


if __name__=="__main__":
    main(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
