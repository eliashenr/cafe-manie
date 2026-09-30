from icons3 import *
from prev import page, out
D = Defs()
b = []
names = [coin, bean, star, chef_star, flower, smiley, gift, trophy, clipboard, book, shop_house, roller, expand, mail, cake, hammer]
for i, fn in enumerate(names):
    b.append(place(fn(D), 60 + (i % 8) * 150, 70 + (i // 8) * 140, 110))
kinds = ["zoom_in", "zoom_out", "full", "eye", "music", "sound", "gear", "left", "right", "first", "last", "plus", "check", "rotate", "close"]
for i, kd in enumerate(kinds):
    b.append(square_button(D, 40 + i * 82, 330, 64, kd, ["blue", "green", "orange", "red"][i % 4] if kd in ("plus", "check") else "blue"))
svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="380" viewBox="0 0 1280 380">{D.render()}{"".join(b)}</svg>'
open(out("icons.html"), "w").write(page(svg, "#dff1ff"))
