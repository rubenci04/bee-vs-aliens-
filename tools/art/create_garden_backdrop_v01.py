"""Four original garden props, natural colours, closed geometry and editable sources."""
from pathlib import Path
import importlib.util,json,math,bpy
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location("bee_art",ROOT/"tools/art/create_future_biomes_v09.py")
art=importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)
art.OUT=ROOT/"assets/models/garden_backdrop_v01"
art.SRC=ROOT/"art_source/blender/garden_backdrop_v01"
for p in (art.OUT,art.SRC): p.mkdir(parents=True,exist_ok=True)
(art.SRC/".gdignore").write_text("",encoding="utf-8")
art.PALETTE.update({"HoseGreen":(.36,.46,.20),"HoseShade":(.24,.31,.14),"Brass":(.71,.52,.23),
    "CanSage":(.53,.62,.37),"CanRim":(.66,.71,.46),"CanInterior":(.38,.45,.25),"Wood":(.68,.51,.30),"WoodShade":(.45,.34,.21),
    "HouseOchre":(.70,.65,.48),"RoofMuted":(.50,.43,.32),"WindowMuted":(.46,.50,.40)})
def start(name):
    root=art.reset(name)
    return root,art.empty("GardenGeometry",root)
def finish(key,role):
    art.join_geometry(bpy.data.objects["GardenGeometry"])
    art.save(key,role)
    art.STATS[-1]["emissive"]=False
    assert art.STATS[-1]["triangles"]<5000
    folder=ROOT/"scenes/art_labs/garden_backdrop_v01"
    folder.mkdir(parents=True,exist_ok=True)
    (folder/(key+".tscn")).write_text('''[gd_scene load_steps=3 format=3]
[ext_resource type="Script" path="res://scripts/art/future_asset_visual.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/garden_backdrop_v01/%s.glb" id="2"]
[node name="%s" type="Node3D"]
script = ExtResource("1")
[node name="Model" parent="." instance=ExtResource("2")]
'''%(key,key),encoding="utf-8")

root,g=start("GardenHoseModel")
points=[]
for i in range(111):
    t=i/110
    a=t*math.tau*2.5
    r=.26+.51*t
    points.append((math.cos(a)*r,math.sin(a)*r,.075+.012*math.sin(a)))
art.tube("CoiledRubber",points,.055,"HoseGreen",g,12)
end=points[-1]
art.tapered("LooseHoseEnd",[end,(-.91,-.14,.07),(-1.05,-.46,.09),(-1.24,-.53,.14)],[.055]*4,"HoseGreen",g,12)
art.tapered("BrassConnector",[(-1.24,-.53,.14),(-1.37,-.54,.16)],[.070,.070],"Brass",g,12)
art.tapered("NozzleGrip",[(-1.38,-.54,.16),(-1.58,-.56,.20)],[.07,.055],"HoseShade",g,12)
art.ell("NozzleMouth",(-1.60,-.565,.21),(.03,.050,.050),"Brass",g,16,8)
finish("garden_hose","Coiled natural green hose with loose end and brass nozzle; ground-scale prop")

root,g=start("GardenWateringCanModel")
# Closed shell with a genuinely recessed interior, smooth lathed mid-poly walls.
profile=[(0,.08),(.38,.08),(.46,.16),(.46,.69),(.43,.75),(.38,.75),(.36,.69),(.36,.20),(0,.20)]
vertices=[]; rows=[]; faces=[]; sides=32
for r,z in profile:
    row=[]
    for j in range(1 if r==0 else sides):
        row.append(len(vertices))
        vertices.append((r*math.cos(j*math.tau/sides),r*math.sin(j*math.tau/sides),z))
    rows.append(row)
for a,b in zip(rows,rows[1:]):
    for j in range(sides):
        k=(j+1)%sides
        faces.append((a[0],b[k],b[j]) if len(a)==1 else ((a[j],a[k],b[0]) if len(b)==1 else (a[j],a[k],b[k],b[j])))
body=art.smooth(art.mesh("HollowBody",vertices,faces,"CanSage",g))
body.data.materials.append(art.MATERIALS["CanInterior"])
for polygon in body.data.polygons:
    if polygon.index//sides>=5: polygon.material_index=1
art.tube("UpperHandle",[(-.30,0,.71),(-.32,0,1.03),(-.12,0,1.16),(.12,0,1.16),(.31,0,1.03),(.30,0,.71)],.044,"CanRim",g,12)
art.tapered("RearHandle",[(.39,0,.58),(.66,0,.62),(.72,0,.36),(.43,0,.21)],[.041]*4,"CanRim",g,12)
art.tapered("LongSpout",[(-.38,0,.22),(-.63,0,.36),(-.82,0,.62),(-1.03,0,.73)],[.092,.075,.054,.04],"CanSage",g,14)
head=art.ell("SprinklerRose",(-1.07,0,.75),(.09,.16,.16),"Brass",g,24,12)
head.rotation_euler.y=-.40
for i in range(7):
    a=i*math.tau/6
    y=0 if i==6 else math.cos(a)*.09
    z=.75 if i==6 else .75+math.sin(a)*.09
    art.ell("SprinklerHole_%d"%i,(-1.158,y,z),(.008,.014,.014),"WoodShade",g,12,6)
finish("garden_watering_can","Sage watering can with recessed open top, overhead handle and long sprinkler spout")

root,g=start("GardenFenceModuleModel")
for x in (-.88,.88):
    art.block("Post",(x,0,.70),(.083,.095,.70),"WoodShade",g,.018)
    art.ell("PostCap",(x,0,1.42),(.11,.12,.06),"Wood",g,16,8)
for z in (.33,.94):
    art.block("Rail",(0,.06,z),(.95,.065,.05),"WoodShade",g,.012)
for i in range(7):
    x=(i-3)*.235
    slat=art.badge("Picket_%d"%i,[(-.075,.06),(.075,.06),(.075,1.12),(0,1.25),(-.075,1.12)],.075,"Wood",g,.012)
    slat.location=(x,-.03,0)
finish("garden_fence_module","Repeatable warm wooden fence, seven pointed pickets, two rails and two capped posts")

root,g=start("GardenDistantHouseModel")
art.block("HouseBody",(0,0,.86),(1.38,.20,.84),"HouseOchre",g,.026)
art.badge("Roof",[(-1.59,1.64),(0,2.40),(1.59,1.64),(1.43,1.54),(0,2.18),(-1.43,1.54)],.53,"RoofMuted",g,.025)
art.badge("Gable",[(-1.31,1.67),(0,2.28),(1.31,1.67)],.40,"HouseOchre",g,.012)
art.block("Chimney",(.73,.02,2.15),(.11,.13,.30),"RoofMuted",g,.014)
art.block("Door",(0,-.214,.50),(.17,.025,.48),"RoofMuted",g,.012)
for x in (-.78,.78):
    art.block("WindowFrame",(x,-.219,1.01),(.25,.027,.25),"RoofMuted",g,.012)
    art.block("Window",(x,-.248,1.01),(.213,.012,.213),"WindowMuted",g,.009)
    art.block("WindowMullion",(x,-.264,1.01),(.012,.008,.215),"HouseOchre",g,.004)
finish("garden_distant_house","Shallow muted house silhouette for distant parallax; natural roof and non-emissive windows")
(art.OUT/"manifest.json").write_text(json.dumps({"assets":art.STATS},indent=2),encoding="utf-8")
print("GARDEN_BACKDROP_V01_OK: "+json.dumps(art.STATS))
