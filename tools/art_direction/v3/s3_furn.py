from prev import out
from furniture3 import *
from people3 import person
from s3_face import page
D = Defs()
iso = Iso(0, 0, 96, 48)
def cell(x, y):
    c = "#ffe9b8" if (x + y) % 2 == 0 else "#ffd27a"
    return P([iso.v(x, y), iso.v(x + 1, y), iso.v(x + 1, y + 1), iso.v(x, y + 1)], c, "#00000018", 0.6)
parts = ["".join(cell(x, y) for y in range(-1, 6) for x in range(-1, 9))]
items = []
items.append((0.5, stove(D, iso, 0, 0, "R", cooking="lasanha")))
items.append((1.5, stove(D, iso, 0, 1, "R", cooking="pao", enamel="#2ec4b6")))
items.append((2.5, counter(D, iso, 1, 1, "R", dishes=[("cafe", 12), ("bolo", 8)])))
items.append((2.5, pastry_case(D, iso, 2, 0)))
items.append((4.5, espresso(D, iso, 4, 0)))
items.append((6.5, fridge(D, iso, 6, 0)))
items.append((5.4, chair(D, iso, 3, 2, "+x", "#ff4d5e")))
items.append((5.5, table_square(D, iso, 4, 2)))
legs, back = chair(D, iso, 5, 2, "-x", "#ffd23f")
items.append((7.4, legs + back))
items.append((6.4, chair(D, iso, 4, 1.99, "+y", "#2ec4b6")))
items.append((8.5, plant(D, iso, 7, 1)))
items.append((5.5, jukebox(D, iso, 0, 4)))
items.append((7.5, table_round(D, iso, 2, 4, "#ff4d8d", dishes=["misto", "cafe"])))
items.append((9.5, flower_vase(D, iso, 5, 4)))
items.append((10.5, aquarium(D, iso, 6, 4)))
items.append((3.5, floor_lamp(D, iso, 1, 3)))
items.sort(key=lambda t: t[0])
body = "".join(parts) + "".join(s for _, s in items)
svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="760" viewBox="-360 -150 880 522">{D.render()}{body}</svg>'
open(out("furn.html"), "w").write(page(svg, "#7fd957"))
