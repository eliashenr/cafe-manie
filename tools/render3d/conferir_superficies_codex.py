"""QA local de staging: contrato, recorte e pranchas. Não instala nem modifica sprites."""
import argparse
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import numpy as np
ROOT = Path(__file__).resolve().parents[2]
FONT = ImageFont.truetype(str(ROOT / 'art/fonts/Nunito-Variable.ttf'), 21) if (ROOT / 'art/fonts/Nunito-Variable.ttf').exists() else ImageFont.load_default()
SMALL = ImageFont.truetype(str(ROOT / 'art/fonts/Nunito-Variable.ttf'), 16)


def run(folder):
    manifest = json.loads((ROOT / 'art/sprites/sprites.json').read_text(encoding='utf-8'))
    patch = json.loads((folder / 'manifest_patch.json').read_text(encoding='utf-8'))
    contract = json.loads((folder / 'physical_contract.json').read_text(encoding='utf-8'))
    staged = patch['sprites']
    failures, evidence, raw_evidence = [], {}, {}
    if contract['rendered_items'] != contract['requested_items']:
        failures.append('lote incompleto')
    if set(patch) != {'sprites'}:
        failures.append('patch alterou outro contrato')
    for name, meta in staged.items():
        if name not in manifest['sprites']:
            failures.append(name + ': ID novo')
        image = Image.open(folder / 'sprites' / (name + '.png')).convert('RGBA')
        alpha = np.array(image)[:, :, 3]
        ys, xs = np.where(alpha > 0)
        if not len(xs):
            failures.append(name + ': vazio')
            continue
        if min(xs.min(), ys.min(), image.width - 1 - xs.max(), image.height - 1 - ys.max()) < 3:
            failures.append(name + ': alfa tocando recorte')
        anchor, density = meta.get('anchor'), meta.get('density')
        valid_anchor = isinstance(anchor,list) and len(anchor)==2 and all(isinstance(v,(int,float)) and math.isfinite(v) for v in anchor)
        valid_density = isinstance(density,(int,float)) and math.isfinite(density) and density>0 and density==contract['density']
        if not valid_anchor or not valid_density:
            failures.append(name + ': âncora/densidade inválida ou não finita')
            continue
        raw_path=folder/'raw'/(name+'.png')
        if not raw_path.is_file():
            failures.append(name+': render bruto ausente')
        else:
            raw_alpha=np.array(Image.open(raw_path).convert('RGBA'))[:,:,3]
            border=np.concatenate((raw_alpha[0,:],raw_alpha[-1,:],raw_alpha[:,0],raw_alpha[:,-1]))
            touching=int(np.count_nonzero(border>22))
            raw_evidence[name]={'size':[int(raw_alpha.shape[1]),int(raw_alpha.shape[0])],
                                'significant_border_pixels':touching,'alpha_threshold':22}
            if touching: failures.append(name+': alfa significativo toca a borda do render bruto')
        ax, ay = anchor
        d = density
        evidence[name] = {'size': list(image.size), 'world_bbox': [round((xs.min()-ax)/d,3), round((ys.min()-ay)/d,3),
                        round((xs.max()-ax)/d,3), round((ys.max()-ay)/d,3)]}
    print('METADATA_CHECK', len(staged), 'sprites;', len(failures), 'failures')
    if failures:
        (folder/'qa.json').write_text(json.dumps({'sprites':len(staged),'failures':failures,
                                               'evidence':evidence,'raw_edges':raw_evidence},indent=2),encoding='utf-8')
        raise SystemExit('\n'.join(failures))
    def fetch(name):
        meta = staged.get(name, manifest['sprites'][name])
        path = folder / 'sprites' / (name + '.png') if name in staged else ROOT / 'art/sprites' / (name + '.png')
        return Image.open(path).convert('RGBA'), meta.get('anchor', [0,0]), meta.get('density', manifest['density'])
    def sprite(canvas, name, anchor, scale=1.0):
        im, off, density = fetch(name)
        im = im.resize((max(1,round(im.width/density*scale)), max(1,round(im.height/density*scale))), Image.Resampling.LANCZOS)
        canvas.alpha_composite(im, (round(anchor[0]-off[0]/density*scale), round(anchor[1]-off[1]/density*scale)))
    # Piso de 4x4 com as mesmas escolhas determinísticas do runtime: não pode haver frestas de alfa.
    seam_evidence = {}
    for item in contract['rendered_items']:
        if item not in manifest['floors']:
            continue
        entry = manifest['floors'][item]; names = entry['sprites']
        available = [n for n in names if n in staged]
        density = contract['density']
        origin = (round(260*density), round(4*density))
        tiled = Image.new('RGBA',(round(520*density),round(264*density)),(0,0,0,0))
        for y in range(4):
            for x in range(4):
                i=(x+y)%2 if entry['mode']=='xadrez' else (x*7+y*13+x*y)%len(names)
                name=names[i] if names[i] in staged else available[i%len(available)]
                im,anchor,d=fetch(name)
                tiled.alpha_composite(im,(round(origin[0]+64*(x-y)*density-anchor[0]),
                                         round(origin[1]+32*(x+y)*density-anchor[1])))
        alpha=np.array(tiled)[:,:,3]
        yy,xx=np.indices(alpha.shape)
        wx=(xx-origin[0])/density; wy=(yy-origin[1])/density
        u=wx/128+wy/64;v=wy/64-wx/128
        inside=(u>0.025)&(u<3.975)&(v>0.025)&(v<3.975)
        gaps=int(np.count_nonzero(inside & (alpha<250)))
        seam_evidence[item]={'transparent_interior_pixels':gaps}
        if gaps: failures.append(item+': frestas no mosaico 4x4')
    # Quatro painéis adjacentes em cada orientação também devem preencher o miolo da parede.
    wall_evidence = {}
    for item in contract['rendered_items']:
        if item not in manifest['walls']:
            continue
        for side,sign,base_y in [('R',1,160),('L',-1,292)]:
            name=manifest['walls'][item][side]
            if name not in staged: continue
            im,anchor,density=fetch(name)
            strip=Image.new('RGBA',(round(272*density),round(304*density)),(0,0,0,0))
            origin=(8*density,base_y*density)
            for i in range(4):
                strip.alpha_composite(im,(round(origin[0]+64*i*density-anchor[0]),
                                          round(origin[1]+sign*32*i*density-anchor[1])))
            alpha=np.array(strip)[:,:,3];yy,xx=np.indices(alpha.shape)
            u=(xx-origin[0])/density/64
            height=sign*32*u-(yy-origin[1])/density
            inside=(u>0.025)&(u<3.975)&(height>2)&(height<150)
            gaps=int(np.count_nonzero(inside & (alpha<250)))
            wall_evidence[name]={'transparent_interior_pixels':gaps}
            if gaps: failures.append(name+': frestas entre painéis')
    rooms = [
        ('BÁSICO', 'floor_beige', 'wall_cream', 'janela', 'table_round', 'chair_wood'),
        ('BISTRÔ', 'floor_wood', 'wall_brick', 'janela', 'table_round', 'chair_wood'),
        ('JAPÃO', 'floor_japanese', 'wall_japanese', 'janela_shoji', 'table_japanese', 'chair_japanese'),
        ('BRASIL', 'floor_brazil', 'wall_brazil', 'janelao_brasileiro', 'table_brazil', 'chair_brazil'),
        ('FRANÇA', 'floor_french', 'wall_french', 'janelao_frances', 'table_french', 'chair_french'),
        ('BRASIL / HIDRÁULICO', 'floor_hydraulic', 'wall_cream', 'janelao_brasileiro', 'table_brazil', 'chair_brazil'),
    ]
    sheet = Image.new('RGBA', (1440, 1740), '#e6dfd2')
    for idx, (title, floor, wall, window, table, chair) in enumerate(rooms):
        canvas = Image.new('RGBA', (720,580), '#f6efdf')
        draw = ImageDraw.Draw(canvas)
        draw.text((22,16), title, fill='#382a23', font=FONT)
        draw.text((22,45), 'Composição de staging · arte nova + móveis DT-105', fill='#786653', font=SMALL)
        scale=1.16
        def iso(x,y): return (360+64*(x-y)*scale, 220+32*(x+y)*scale)
        def at(name,x,y): sprite(canvas,name,iso(x,y),scale)
        for y in range(4):
            for x in range(4):
                entry=manifest['floors'][floor]
                names=entry['sprites']
                variant=(x+y)%2 if entry['mode']=='xadrez' else (x*7+y*13+x*y)%len(names)
                # Prova pode conter somente a primeira variante; evita misturar piso antigo no mosaico.
                available=[n for n in names if n in staged]
                n=names[variant] if names[variant] in staged else available[variant%len(available)] if available else names[variant]
                at(n,x,y)
        for y in range(4): at(manifest['walls'][wall]['L'],0,y+1)
        for x in range(4): at(manifest['walls'][wall]['R'],x,0)
        at('enfeite_'+window+'_L',0,2)
        at('enfeite_'+window+'_R',2,0)
        for side,x,y in [('L',0,2),('R',2,0)]:
            if manifest['wall_pilaster'][side] in staged:
                at(manifest['wall_pilaster'][side],x,y)
        for item,x,y,rot in [(chair,2,2,1),(table,3,2,0),(chair,3,3,3)]:
            name=manifest['furniture'][item][str(rot)]
            at(name,x,y)
        sheet.alpha_composite(canvas,((idx%2)*720,(idx//2)*580))
        canvas.convert('RGB').save(folder / ('prova_'+str(idx+1)+'.png'))
    sheet.convert('RGB').save(folder/'provas_ambientes.png')
    # Catálogo final: cada piso em 4x4 células e paredes/janelas nos dois lados.
    ids=list(contract['rendered_items'])
    cols=5; card_w=320; card_h=280
    catalog=Image.new('RGBA',(cols*card_w,((len(ids)+cols-1)//cols)*card_h),'#efe7d7')
    for idx,item in enumerate(ids):
        x=(idx%cols)*card_w; y=(idx//cols)*card_h
        card=Image.new('RGBA',(card_w,card_h),'#f8f1e5')
        d=ImageDraw.Draw(card);d.text((10,10),item,fill='#382a23',font=SMALL)
        if item in manifest['floors']:
            entry=manifest['floors'][item];names=entry['sprites'];available=[n for n in names if n in staged]
            for row in range(4):
                for col in range(4):
                    v=(col+row)%2 if entry['mode']=='xadrez' else (col*7+row*13+col*row)%len(names)
                    n=names[v] if names[v] in staged else available[v%len(available)]
                    sprite(card,n,(160+64*(col-row)*0.55,62+32*(col+row)*0.55),0.55)
        else:
            for side,xp in [('L',60),('R',200)]:
                name=manifest['walls'][item][side] if item in manifest['walls'] else manifest['wall_pilaster'][side] if item=='pilaster' else 'enfeite_'+item+'_'+side
                # Piso/parede de apoio deixa legíveis vidros e sombras sem cortar o alfa.
                if item not in manifest['walls'] and item!='pilaster':
                    sprite(card,manifest['walls']['wall_cream'][side],(xp,222),0.90)
                sprite(card,name,(xp,222),0.90)
        catalog.alpha_composite(card,(x,y))
    catalog.convert('RGB').save(folder/'catalogo.png')
    for group,selected,height in [('pisos',[i for i in ids if i in manifest['floors']],215),
                                  ('paredes',[i for i in ids if i in manifest['walls']],280),
                                  ('janelas',[i for i in ids if i not in manifest['floors'] and i not in manifest['walls']],280)]:
        if not selected: continue
        contact=Image.new('RGB',(5*card_w,((len(selected)+4)//5)*height),'#efe7d7')
        for dst,item in enumerate(selected):
            idx=ids.index(item);x=(idx%cols)*card_w;y=(idx//cols)*card_h
            contact.paste(catalog.crop((x,y,x+card_w,y+height)).convert('RGB'),((dst%5)*card_w,(dst//5)*height))
        contact.save(folder/('catalogo_'+group+'.png'))
    (folder/'qa.json').write_text(json.dumps({'sprites':len(staged),'failures':failures,'evidence':evidence,'floor_seams':seam_evidence,'wall_seams':wall_evidence,'raw_edges':raw_evidence},indent=2),encoding='utf-8')
    print('VALIDATED', len(staged), 'sprites;', len(seam_evidence), 'floor mosaics;', len(wall_evidence), 'wall strips;', len(failures), 'failures')
    if failures: raise SystemExit('\n'.join(failures))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('folder',help='Pasta de staging sob build, absoluta ou relativa ao repositório')
    args=parser.parse_args()
    folder=(ROOT/args.folder).resolve();build=(ROOT/'build').resolve()
    if folder==build or build not in folder.parents:
        parser.error('A conferência só escreve em uma subpasta de build')
    run(folder)
