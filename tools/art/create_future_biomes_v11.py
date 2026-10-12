"""Two original fauna POCs, budgeted at ~5k per spider and ~7k per eagle.
Uses only original local construction helpers; no external assets.
"""
from pathlib import Path
import importlib.util,json,math,struct
import bpy,bmesh
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location("bee_canonical_art",ROOT/"tools/art/create_future_biomes_v09.py")
art=importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)
art.OUT=ROOT/"assets/models/future_biomes_v11"
art.SRC=ROOT/"art_source/blender/future_biomes_v11"
for path in (art.OUT,art.SRC): path.mkdir(parents=True,exist_ok=True)
(art.SRC/".gdignore").write_text("",encoding="utf-8")
art.PALETTE.update({"SpiderBrown":(.37,.24,.13),"SpiderOchre":(.55,.40,.22),"Silk":(.78,.76,.61),
    "EagleBrown":(.35,.24,.14),"EagleFeather":(.48,.35,.20),"EagleHead":(.81,.76,.58),
    "EagleGold":(.76,.56,.18),"FeatherTip":(.24,.17,.10)})
ell,empty,tapered=art.ell,art.empty,art.tapered

def finish(key,role,budget):
    objects=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    before=sum(len(p.vertices)-2 for o in objects for p in o.data.polygons)
    for obj in objects:
        count=sum(len(p.vertices)-2 for p in obj.data.polygons)
        mod=obj.modifiers.new("MidPolyBudget","DECIMATE")
        mod.ratio=min(1,budget/before)
        mod.use_collapse_triangulate=True
        art.apply_modifier(obj,mod)
    # Batch natural surfaces, keep semantic limb/wing groups as future rig references.
    art.join_geometry(bpy.data.objects["NaturalFauna"])
    art.save(key,role)
    assert art.STATS[-1]["triangles"]<=budget*1.05

root=art.reset("ControlledHangingSpiderModel")
fauna=empty("NaturalFauna",root)
ell("Abdomen",(.22,0,.28),(.39,.28,.36),"SpiderBrown",fauna,32,16)
ell("Cephalothorax",(-.30,0,-.05),(.25,.20,.20),"SpiderOchre",fauna,32,16)
for side in (-1,1):
    for i in range(4):
        x=-.41+i*.095
        knee=(x+(-.41,-.31,.18,.40)[i],side*(.38+i*.01),(.19,.36,.34,.50)[i])
        end=(x+(-.67,-.60,.54,.78)[i],side*(.46+i*.02),(-.49,-.28,-.22,.02)[i]+(.09 if side>0 else 0))
        leg=empty("SpiderLeg_%s_%d"%(side,i),fauna)
        tapered("Femur",[(x,side*.14,-.04),knee],[.032,.026],"SpiderBrown",leg,12)
        tapered("Tibia",[knee,end,(end[0]+.06,end[1],end[2]-.055)],[.022,.013,.005],"SpiderOchre",leg,10)
    for i in range(3):
        ell("Eye_%s_%d"%(side,i),(-.45-i*.016,side*(.17-i*.04),.02+i*.052),(.035,.027,.036),"Eye",fauna,16,8)
    palp=empty("Pedipalp_%d"%side,fauna)
    tapered("Palp",[(-.48,side*.10,-.12),(-.65,side*.14,-.22)],[.029,.014],"SpiderBrown",palp,10)
    ell("Spinneret_%d"%side,(.41,side*.05,.55),(.04,.035,.06),"SpiderOchre",fauna,16,8)
art.implant(root,(-.28,0,.14),.51,"insect")
silk=empty("NaturalSilk",root)
art.tube("SilkThread",[(.41,0,.57),(.41,0,1.50),(.41,0,2.65)],.006,"Silk",silk,8)
anchor=empty("SilkAnchor",root)
anchor.location=(.41,0,2.65)
finish("controlled_hanging_spider","Eight-legged hanging spider, natural silk and removable thorax controller",5000)

root=art.reset("ControlledEagleModel")
fauna=empty("NaturalFauna",root)
ell("Body",(.08,0,.02),(.65,.32,.36),"EagleBrown",fauna,32,16)
ell("Neck",(-.47,0,.23),(.26,.22,.32),"EagleHead",fauna,28,14)
ell("Head",(-.69,0,.46),(.27,.19,.22),"EagleHead",fauna,32,16)
tapered("HookedBeak",[(-.87,0,.40),(-1.10,0,.34),(-1.05,0,.23)],[.095,.075,.018],"EagleGold",fauna,16)
for side in (-1,1):
    ell("Eye_%d"%side,(-.82,side*.163,.49),(.046,.020,.052),"Eye",fauna,20,10)
    tapered("NaturalBrow_%d"%side,[(-.92,side*.17,.54),(-.70,side*.19,.57)],[.022,.030],"EagleHead",fauna,10)
    wing=empty("EagleWing_%d"%side,fauna)
    # Banking gives two different side-view heights and separates the flight feathers.
    wing.location=(.02,side*.22,.13)
    wing.rotation_euler.x=-.75 if side<0 else -.25
    ell("Coverts",(.12,side*.50,.04),(.43,.60,.13),"EagleBrown",wing,28,14)
    for i in range(7):
        feather=ell("PrimaryFeather_%d"%i,(.32+i*.060,side*(.84+i*.145),-.015),
                    (.52-i*.029,.118,.047),"EagleFeather" if i%2 else "FeatherTip",wing,20,10)
        feather.rotation_euler.z=side*(.35+i*.045)
    for i in range(4):
        feather=ell("SecondaryFeather_%d"%i,(-.02+i*.09,side*(.31+i*.15),.15),(.24,.16,.055),"EagleFeather",wing,20,10)
    leg=empty("EagleLeg_%d"%side,fauna)
    tapered("Tarsus",[(.14,side*.18,-.26),(.30,side*.22,-.43)],[.050,.032],"EagleGold",leg,12)
    for j in range(3):
        tapered("Talon_%d"%j,[(.29,side*.22+(j-1)*.04,-.42),(.05,side*.25+(j-1)*.06,-.49),(.04,side*.25+(j-1)*.06,-.40)],
                [.022,.014,.004],"FeatherTip",leg,10)
tail=empty("EagleTail",fauna)
for i in range(5):
    feather=ell("TailFeather_%d"%i,(.78,(i-2)*.075,-.10),(.35,.082,.045),"EagleHead",tail,20,10)
    feather.rotation_euler.y=.18
art.implant(root,(-.43,-.14,.49),.70,"bird")
finish("controlled_eagle","Large sky threat with hooked beak, two broad wings, fingered flight feathers and removable neck mount",7000)
(art.OUT/"manifest.json").write_text(json.dumps({"batch":"V11","assets":art.STATS},indent=2),encoding="utf-8")
print("FUTURE_BIOMES_V11_OK: "+json.dumps(art.STATS))
