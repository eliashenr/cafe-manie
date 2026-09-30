from prev import out
from people3 import *
from s3_face import page
D = Defs()
b = []
b.append(person(D, 110, 420, 3.0, 1, pose="andar", skin="morena_clara", hair=("curto", "preto"), top=("garcom", "#ffffff"), bottom=("calca", "#23232b"), tray="bolo", shoes="#2b2b33"))
b.append(person(D, 330, 420, 3.0, 1, skin="negra", hair=("black", "preto"), top=("chef", "#ffffff"), bottom=("calca", "#3b4a55"), apron="#ffffff", hat="chef", lash=True, earrings="#ffc928"))
b.append(person(D, 540, 420, 3.0, -1, pose="andar", skin="clara", hair=("rabo", "loiro"), top=("camiseta", "#ff4d6d"), bottom=("calca", "#3b6fd6"), lash=True, iris="#3b7fd9"))
b.append(person(D, 760, 360, 3.0, 1, pose="sentado", skin="clara", hair=("chanel", "ruivo"), top=("blusa", "#9b5cff"), bottom=("calca", "#34495e"), expr="esperando", lash=True, iris="#2f9e62"))
b.append(person(D, 960, 360, 3.0, -1, pose="sentado", skin="morena", hair=("topete", "castanho"), top=("camisa", "#2fae4e"), bottom=("calca", "#3b4a55"), expr="bravo"))
b.append(person(D, 1160, 360, 3.0, 1, pose="sentado", skin="clara", hair=("longo", "castanho"), top=("moletom", "#ff7a2f"), bottom=("calca", "#34495e"), back=True))
b.append(person(D, 1330, 360, 3.0, -1, pose="sentado", skin="negra", hair=("coque", "preto"), top=("blusa", "#35b8ff"), bottom=("calca", "#34495e"), back=True))
svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="1440" height="460" viewBox="0 0 1440 460">{D.render()}{"".join(b)}</svg>'
# escala do jogo
D2 = Defs()
b2 = []
from s3_face import CAST
for i, c in enumerate(CAST):
    b2.append(person(D2, 40 + i * 62, 110, 0.72, 1 if i % 2 else -1, **c))
for i, c in enumerate(CAST):
    b2.append(person(D2, 740 + i * 62, 110, 0.72, 1, pose="sentado", expr=["feliz","esperando","bravo","comendo","sorriso"][i % 5], **c))
svg2 = f'<svg xmlns="http://www.w3.org/2000/svg" width="1440" height="140" viewBox="0 0 1440 140">{D2.render()}{"".join(b2)}</svg>'
open(out("pose.html"), "w").write(page(svg + svg2))
