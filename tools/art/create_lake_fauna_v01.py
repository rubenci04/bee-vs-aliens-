"""Small original lake batch: two controlled insects and one natural root module."""
from pathlib import Path
import importlib.util,json,bpy,math
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location("bee_art",ROOT/"tools/art/create_future_biomes_v09.py")
art=importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)
art.OUT=ROOT/"assets/models/lake_fauna_v01"
art.SRC=ROOT/"art_source/blender/lake_fauna_v01"
for p in (art.OUT,art.SRC): p.mkdir(parents=True,exist_ok=True)
(art.SRC/".gdignore").write_text("",encoding="utf-8")
art.PALETTE.update({"StriderBrown":(.40,.28,.15),"StriderLight":(.61,.46,.25),"NymphOlive":(.43,.47,.23),
    "NymphLight":(.62,.60,.32),"RootWood":(.48,.34,.19),"RootLight":(.62,.46,.27)})
def start(name,group):
    root=art.reset(name)
    return root,art.empty(group,root)
def finish(key,role,group,controlled):
    objects=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    before=sum(len(p.vertices)-2 for o in objects for p in o.data.polygons)
    if before>4900:
        for obj in objects:
            mod=obj.modifiers.new("SmallEnemyBudget","DECIMATE")
            mod.ratio=4900/before
            mod.use_collapse_triangulate=True
            art.apply_modifier(obj,mod)
    art.join_geometry(group)
    art.save(key,role)
    art.STATS[-1]["emissive"]=controlled
    assert art.STATS[-1]["triangles"]<=5000
    folder=ROOT/"scenes/art_labs/lake_fauna_v01"
    folder.mkdir(parents=True,exist_ok=True)
    (folder/(key+".tscn")).write_text('''[gd_scene load_steps=3 format=3]
[ext_resource type="Script" path="res://scripts/art/future_asset_visual.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/lake_fauna_v01/%s.glb" id="2"]
[node name="%s" type="Node3D"]
script = ExtResource("1")
[node name="Model" parent="." instance=ExtResource("2")]
'''%(key,key),encoding="utf-8")

root,g=start("ControlledWaterStriderModel","NaturalFauna")
art.ell("LongAbdomen",(.38,0,.32),(.61,.12,.12),"StriderBrown",g,28,14)
art.ell("Thorax",(-.19,0,.35),(.26,.15,.15),"StriderLight",g,24,12)
art.ell("Head",(-.47,0,.37),(.17,.12,.13),"StriderBrown",g,24,12)
for side in (-1,1):
    art.ell("Eye_%d"%side,(-.52,side*.105,.41),(.067,.033,.058),"Eye",g,16,8)
    art.tapered("Antenna_%d"%side,[(-.56,side*.06,.42),(-.74,side*.13,.54),(-.92,side*.19,.53)],[.015,.011,.004],"StriderLight",g,8)
    points=[((-.28,side*.12,.32),(-.50,side*.26,.10),(-.64,side*.36,-.12)),
            ((-.04,side*.13,.32),(-.19,side*.56,.16),(-.88,side*.96,-.18)),
            ((.14,side*.11,.32),(.72,side*.40,.12),(1.18,side*.83,-.18))]
    for i,(hip,knee,foot) in enumerate(points):
        leg=art.empty("StriderLeg_%d_%d"%(side,i),g)
        shift=.065 if side>0 else 0
        art.tapered("WalkingLeg",[hip,knee,(foot[0],foot[1],foot[2]+shift)],[.022,.016,.005],"StriderBrown",leg,10)
art.implant(root,(-.17,0,.49),.40,"insect")
finish("controlled_water_strider","Water-surface insect: six legs with long middle/hind pairs, slender body and removable thorax control",g,True)

root,g=start("ControlledDragonflyNymphModel","NaturalFauna")
for i in range(7):
    x=.02+i*.135
    width=.24-i*.019
    art.ell("AbdomenSegment_%d"%i,(x,0,.25),(.145,width,.135-i*.007),"NymphOlive" if i%2==0 else "NymphLight",g,20,10)
art.ell("Thorax",(-.25,0,.28),(.27,.22,.15),"NymphOlive",g,24,12)
art.ell("BroadHead",(-.57,0,.28),(.24,.25,.15),"NymphLight",g,28,14)
art.ell("ClosedLabium",(-.65,-.01,.16),(.16,.19,.042),"NymphOlive",g,20,10)
for side in (-1,1):
    art.ell("Eye_%d"%side,(-.66,side*.214,.34),(.079,.062,.084),"Eye",g,20,10)
    art.tapered("ShortAntenna_%d"%side,[(-.73,side*.11,.36),(-.84,side*.17,.43)],[.012,.005],"NymphOlive",g,8)
    for i,x in enumerate((-.48,-.30,-.12)):
        leg=art.empty("NymphLeg_%d_%d"%(side,i),g)
        foot_x=(-.76,-.04,.48)[i]
        art.tapered("BentLeg",[(x,side*.17,.25),(x+(-.12,.08,.20)[i],side*.36,.16),(foot_x,side*.47,-.02+( .04 if side>0 else 0))],
                    [.036,.027,.011],"NymphOlive",leg,10)
art.implant(root,(-.23,0,.42),.55,"insect")
finish("controlled_dragonfly_nymph","Compact aquatic dragonfly nymph, broad head, segmented olive abdomen and six bent legs; external removable controller",g,True)

root,g=start("SubmergedRootModuleModel","NaturalRoots")
art.tapered("MainRoot",[(-1.1,0,.78),(-.50,.02,.55),(.06,0,.17),(.67,.06,.08),(1.17,.10,-.04)],
            [.15,.17,.13,.095,.025],"RootWood",g,14)
for i,(start,knee,end) in enumerate([
    ((-.74,0,.68),(-1.02,-.15,.25),(-1.28,-.24,-.15)),
    ((-.39,0,.48),(-.53,-.25,.04),(-.84,-.32,-.33)),
    ((-.14,0,.32),(.12,-.20,-.02),(.26,-.26,-.37)),
    ((.37,0,.12),(.62,.23,-.15),(1.01,.36,-.38)),
    ((.64,.06,.08),(.90,-.18,.25),(1.27,-.23,.33))]):
    art.tapered("BranchRoot_%d"%i,[start,knee,end],[.08,.045,.007],"RootLight" if i%2 else "RootWood",g,12)
finish("submerged_root_module","Warm natural branching root module for lake shallows; no emissive moss or technology",g,False)
(art.OUT/"manifest.json").write_text(json.dumps({"assets":art.STATS},indent=2),encoding="utf-8")
print("LAKE_FAUNA_V01_OK: "+json.dumps(art.STATS))
