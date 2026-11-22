"""Confere e monta provas do staging de decoracoes_codex, sem editar produção.

python tools/render3d/conferir_decoracoes_codex.py build/visual-cenario/decoracoes
"""
import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def contact(names, stage, patch, destination, title):
    columns=4; cell_w=270; cell_h=280; rows=math.ceil(len(names)/columns)
    page=Image.new("RGB",(columns*cell_w,rows*cell_h+42),"#ede3cf")
    draw=ImageDraw.Draw(page)
    font=ImageFont.truetype(str(ROOT/"art/fonts/Nunito-Variable.ttf"),12)
    draw.text((16,12),title,fill="#382a23",font=font)
    for i,name in enumerate(names):
        x=(i%columns)*cell_w;y=(i//columns)*cell_h+42
        image=Image.open(stage/"sprites"/(name+".png")).convert("RGBA")
        density=patch["sprites"][name]["density"]
        scale=min(1.45/density,246/image.width,235/image.height)
        image=image.resize((max(1,round(image.width*scale)),max(1,round(image.height*scale))),Image.Resampling.LANCZOS)
        page.paste(image,(x+(cell_w-image.width)//2,y+235-image.height),image)
        draw.text((x+10,y+245),name,fill="#382a23",font=font)
    page.save(destination)


def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("stage")
    args=parser.parse_args(argv);stage=(ROOT/args.stage).resolve();build=(ROOT/"build").resolve()
    if stage==build or build not in stage.parents:parser.error("Staging deve estar dentro de build")
    patch=json.loads((stage/"manifest_patch.json").read_text(encoding="utf-8"))
    contract=json.loads((stage/"physical_contract.json").read_text(encoding="utf-8"))
    manifest=json.loads((ROOT/"art/sprites/sprites.json").read_text(encoding="utf-8"))
    expected={n for item in contract["items"].values() for n in item["names"]}
    errors=[];details={};names=set(patch.get("sprites",{}))
    if set(contract.get("requested_items",contract["items"]))!=set(contract["items"]):
        errors.append("Geração incompleta: faltam IDs solicitados no contrato")
    if set(patch)!={"sprites"}:errors.append("Patch altera outra seção além de sprites")
    if names!=expected:errors.append("Sprites diferentes dos nomes declarados no contrato")
    if {p.stem for p in (stage/"sprites").glob("*.png")}!=names:errors.append("PNGs ausentes ou extras no staging")
    for name,meta in patch["sprites"].items():
        if name not in manifest["sprites"]:errors.append(name+": ID novo não permitido")
        if len(meta.get("anchor",[]))!=2 or not all(math.isfinite(v) for v in meta.get("anchor",[])):
            errors.append(name+": âncora inválida")
        if meta.get("density")!=contract["density"]:errors.append(name+": densidade divergente")
        path=stage/"sprites"/(name+".png")
        if not path.exists():errors.append(name+": PNG ausente");continue
        with Image.open(path) as im:
            if im.mode!="RGBA":errors.append(name+": PNG sem RGBA")
            alpha=im.convert("RGBA").getchannel("A");box=alpha.getbbox()
            if box is None:errors.append(name+": vazio")
            if alpha.getextrema()!=(0,255):errors.append(name+": falta transparência/opacidade")
            edge=max(alpha.crop((0,0,im.width,1)).getextrema()[1],alpha.crop((0,im.height-1,im.width,im.height)).getextrema()[1],
                     alpha.crop((0,0,1,im.height)).getextrema()[1],alpha.crop((im.width-1,0,im.width,im.height)).getextrema()[1])
            if edge>0:errors.append(name+": conteúdo encosta no corte")
            raw=stage/"raw"/(name+".png")
            if not raw.is_file():
                errors.append(name+": PNG original ausente em raw")
            else:
                try:
                    with Image.open(raw) as raw_im:
                        raw_alpha=raw_im.convert("RGBA").getchannel("A")
                        raw_bbox=raw_alpha.getbbox()
                        if raw_bbox is None:
                            errors.append(name+": PNG original vazio")
                        elif raw_bbox[0]==0 or raw_bbox[1]==0 or raw_bbox[2]==raw_im.width or raw_bbox[3]==raw_im.height:
                            errors.append(name+": enquadramento original cortado")
                except (OSError,ValueError) as error:
                    errors.append(name+": PNG original inválido: "+str(error))
            details[name]={"size":list(im.size),"alpha_bbox":box,"sha256":digest(path),
                           "changed":digest(path)!=digest(ROOT/"art/sprites"/(name+".png"))}
    groups={kind:[] for kind in ("floor","wall","door")}
    for item,meta in contract["items"].items():
        groups[meta["kind"]].extend(meta["names"])
    pages=[]
    for kind,names_group in groups.items():
        for start in range(0,len(names_group),12):
            path=stage/f"contato_{kind}_{start//12+1:02}.png"
            contact(names_group[start:start+12],stage,patch,path,f"Decoracoes Codex | {kind} | {start+1}–{min(start+12,len(names_group))}")
            pages.append(path.name)
    report={"ok":not errors,"items":len(contract["items"]),"sprites":len(names),"changed_pngs":sum(v["changed"] for v in details.values()),
            "groups":{kind:sum(v["kind"]==kind for v in contract["items"].values()) for kind in groups},
            "errors":errors,"contact_sheets":pages,"details":details}
    (stage/"qa.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({k:v for k,v in report.items() if k!="details"},ensure_ascii=False,indent=2))
    return 0 if report["ok"] else 1


if __name__=="__main__":
    raise SystemExit(main())
