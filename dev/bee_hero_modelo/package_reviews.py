"""Compose reviews of actual Godot renders; never edit reference/model geometry."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageOps,ImageChops
import json
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'docs/art/renders/bee_hero'
REFERENCE=ROOT/'concept_art/shared/bee_hero/Lámina de abeja mecánica blindada.png'
for round_name in sorted(p.name for p in OUT.glob('round_*') if p.is_dir()):
    directory=OUT/round_name
    if not (directory/'full_side.png').exists():continue
    for version in ('full','lite'):
        sheet=Image.new('RGB',(1800,1000),(161,161,156))
        for i,view in enumerate(('side','front','rear','top','three_quarter')):
            tile=Image.open(directory/(version+'_'+view+'.png')).convert('RGB')
            # Crop empty studio space so the five actual views are readable.
            background=Image.new('RGB',tile.size,tile.getpixel((0,0)))
            occupied=ImageChops.difference(tile,background).convert('L').point(lambda v:255 if v>12 else 0).getbbox()
            if occupied:
                x0,y0,x1,y1=occupied
                tile=tile.crop((max(0,x0-25),max(0,y0-25),min(tile.width,x1+25),min(tile.height,y1+25)))
            tile=ImageOps.contain(tile,(570,455))
            x=i%3*600;y=i//3*500
            sheet.paste(tile,(x+(600-tile.width)//2,y))
            ImageDraw.Draw(sheet).text((x+15,y+475),view,fill=(30,25,20))
        sheet.save(directory/(version+'_five_views.png'))
        reference=Image.open(REFERENCE).convert('RGB')
        reference=ImageOps.contain(reference,(1672,1000))
        comparison=Image.new('RGB',(3472,1000),(170,169,165))
        comparison.paste(reference,(0,(1000-reference.height)//2));comparison.paste(sheet,(1672,0))
        comparison.save(directory/(version+'_comparison.png'))
        raw=Image.open(directory/(version+'_silhouette.png')).convert('RGB')
        mask=raw.convert('L').point(lambda v:255 if v<30 else 0)
        box=mask.getbbox();assert box,'Empty silhouette'
        shape=mask.crop(box);width=round(shape.width/shape.height*96)
        shape=shape.resize((width,96),Image.Resampling.LANCZOS).point(lambda v:255 if v>=127 else 0)
        black=Image.new('RGB',shape.size,'white');black.paste((0,0,0),(0,0,width,96),shape)
        black.save(directory/(version+'_silhouette_96.png'))
        # Eight-neighbour pixel connectivity catches disappearing drill/blaster parts.
        remaining={(x,y) for y in range(96) for x in range(width) if black.getpixel((x,y))==(0,0,0)}
        components=[]
        while remaining:
            queue=[remaining.pop()];count=0
            while queue:
                x,y=queue.pop();count+=1
                for dx,dy in ((-1,0),(1,0),(0,-1),(0,1),(-1,-1),(1,1),(-1,1),(1,-1)):
                    q=(x+dx,y+dy)
                    if q in remaining:remaining.remove(q);queue.append(q)
            components.append(count)
        (directory/(version+'_silhouette_96_metrics.json')).write_text(json.dumps({'width':width,'height':96,'black_pixels':sum(components),'components':sorted(components,reverse=True),'largest_component_fraction':max(components)/sum(components)},indent=2),encoding='utf-8')
