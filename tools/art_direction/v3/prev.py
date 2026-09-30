"""Página HTML local para conferir os desenhos com as fontes certas (Fredoka e Nunito)."""

FONTS = "".join(
    f"@font-face{{font-family:'{fam}';font-weight:{w};src:url('node_modules/@fontsource/{fam.lower()}/files/{fam.lower()}-latin-{w}-normal.woff2') format('woff2');}}"
    for fam, ws in (("Fredoka", (500, 600, 700)), ("Nunito", (600, 700, 800))) for w in ws)


def page(body, bg="#eaf6ff"):
    return (f'<!doctype html><html><head><meta charset="utf-8"><style>{FONTS}'
            f'body{{margin:0;background:{bg};font-family:Nunito,sans-serif}}</style></head><body>{body}</body></html>')


import os

PREVIEW_DIR = os.environ.get("PREVIEW_DIR", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "prev3"))


def out(name):
    """Caminho do HTML de prévia (a pasta precisa do link node_modules com as fontes para a letra certa)."""
    os.makedirs(PREVIEW_DIR, exist_ok=True)
    return os.path.join(PREVIEW_DIR, name)
