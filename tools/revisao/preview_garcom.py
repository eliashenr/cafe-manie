"""Monta uma prévia de QA a partir de capturas reais da Godot, sem alterar sprites."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "visual-garcom"
FONT = str(ROOT / "art" / "fonts" / "Nunito-Variable.ttf")
STATES = [("frente", "Frente · mãos livres"), ("costas", "Costas · mãos livres"),
          ("frente_bandeja", "Frente · com bandeja"), ("costas_bandeja", "Costas · com bandeja")]
# Mesmo recorte do café nas quatro poses. Só as capturas são recortadas; o jogo
# já desenhou sombra, prato, iluminação e oclusão antes de salvar cada imagem.
CROP = (200, 104, 450, 328)


def board(frame):
    canvas = Image.new("RGB", (532, 590), "#171b24")
    draw = ImageDraw.Draw(canvas)
    title = ImageFont.truetype(FONT, 23)
    label = ImageFont.truetype(FONT, 16)
    draw.text((16, 10), "Café Manie · revisão do garçom", font=title, fill="#fff6e8")
    for i, (state, text) in enumerate(STATES):
        x, y = 12 + (i % 2) * 258, 51 + (i // 2) * 266
        path = OUT / f"garcom_jogo_{state}_{frame:02d}.png"
        with Image.open(path) as image:
            canvas.paste(image.convert("RGB").crop(CROP), (x, y + 27))
        draw.text((x + 3, y), text, font=label, fill="#dfcaa7")
    return canvas


def main():
    frames = [board(i) for i in range(8)]
    frames[0].save(OUT / "previa_garcom.png")
    frames[0].save(OUT / "previa_garcom.gif", save_all=True, append_images=frames[1:],
                   duration=120, loop=0, disposal=2, optimize=False)
    # Os oito quadros lado a lado também permitem inspecionar o ciclo sem player.
    strip = Image.new("RGB", (532 * 4, 590 * 2), "#171b24")
    for i, frame in enumerate(frames):
        strip.paste(frame, ((i % 4) * 532, (i // 4) * 590))
    strip.save(OUT / "quadros_no_jogo.png")
    print("Prévias: previa_garcom.gif, previa_garcom.png e quadros_no_jogo.png")


if __name__ == "__main__":
    main()
