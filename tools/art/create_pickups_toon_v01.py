"""Four small, original bee-side pickups. Natural warm palette, no alien glow."""
from pathlib import Path
import importlib.util,json,math
import bpy
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location("bee_art",ROOT/"tools/art/create_future_biomes_v09.py")
art=importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)
art.OUT=ROOT/"assets/models/pickups_toon_v01"
art.SRC=ROOT/"art_source/blender/pickups_toon_v01"
for p in (art.OUT,art.SRC): p.mkdir(parents=True,exist_ok=True)
(art.SRC/".gdignore").write_text("",encoding="utf-8")
art.PALETTE.update({"HoneyGold":(.94,.63,.12),"PollenLight":(.98,.81,.32),
    "BeeDark":(.24,.19,.12),"LeafGreen":(.42,.57,.22),"Clay":(.70,.36,.19),"HeartRed":(.81,.26,.20)})
ell,empty=art.ell,art.empty
def start(name):
    root=art.reset(name)
    return root,empty("PickupGeometry",root)
def finish(key,role):
    art.join_geometry(bpy.data.objects["PickupGeometry"])
    art.save(key,role)
    art.STATS[-1]["emissive"]=False
    assert art.STATS[-1]["triangles"]<4000
    wrapper=ROOT/"scenes/art_labs/pickups_toon_v01"/(key+".tscn")
    wrapper.parent.mkdir(parents=True,exist_ok=True)
    wrapper.write_text('''[gd_scene load_steps=3 format=3]
[ext_resource type="Script" path="res://scripts/art/future_asset_visual.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/pickups_toon_v01/%s.glb" id="2"]
[node name="%s" type="Node3D"]
script = ExtResource("1")
[node name="Model" parent="." instance=ExtResource("2")]
'''%(key,key),encoding="utf-8")

root,g=start("PollenPickupModel")
ell("PollenCore",(0,0,0),(.30,.25,.30),"HoneyGold",g,24,12)
for i in range(6):
    a=i*math.tau/6
    ell("PollenGrain_%d"%i,(math.cos(a)*.29,-.04,math.sin(a)*.29),(.135,.13,.135),"PollenLight",g,16,8)
ell("FrontGrain",(0,-.245,0),(.145,.075,.145),"PollenLight",g,16,8)
finish("pickup_pollen","Golden rounded pollen cluster; collectible currency")

root,g=start("SpreadPickupModel")
outline=[(math.cos(a*math.tau/6)*.40,math.sin(a*math.tau/6)*.40) for a in range(6)]
art.badge("HexagonalCase",outline,.20,"HoneyGold",g,.025)
art.badge("DarkFace",[(x*.82,z*.82) for x,z in outline],.025,"BeeDark",g,.012).location.y=-.12
for i,angle in enumerate((-.52,0,.52)):
    arrow=art.badge("SpreadRay_%d"%i,[(-.20,-.027),(.08,-.027),(.08,-.075),(.22,0),(.08,.075),(.08,.027),(-.20,.027)],.022,"Cream",g,.008)
    arrow.location=(0,-.144,(i-1)*.14)
    arrow.rotation_euler.y=-angle
finish("pickup_spread","Warm hexagonal upgrade with three fanned arrows; side-view readable without text")

root,g=start("BombPickupModel")
ell("BombBody",(0,0,0),(.31,.25,.31),"BeeDark",g,28,14)
ell("GoldBand",(0,0,0),(.318,.26,.13),"HoneyGold",g,24,12)
art.block("FuseCollar",(0,0,.32),(.075,.065,.07),"HoneyGold",g,.016)
art.tapered("Fuse",[(0,0,.37),(.09,0,.48),(.20,0,.46)],[.023,.019,.008],"Cream",g,10)
for side in (-1,1):
    wing=ell("BeeWing_%d"%side,(side*.18,.045,.26),(.14,.075,.065),"Cream",g,16,8)
    wing.rotation_euler.y=side*.5
finish("pickup_bomb","Bee bomb pickup; dark warm casing, honey band and short cream fuse")

root,g=start("HealingPickupModel")
ell("HoneyJar",(0,0,-.05),(.30,.245,.29),"Clay",g,24,12)
ell("HoneyLid",(0,0,.23),(.27,.23,.055),"HoneyGold",g,24,10)
art.badge("CreamLabel",[(-.19,-.18),(.19,-.18),(.19,.13),(-.19,.13)],.027,"Cream",g,.025).location.y=-.237
heart=[(0,-.105),(-.125,.020),(-.117,.105),(-.065,.135),(0,.078),(.065,.135),(.117,.105),(.125,.020)]
art.badge("HealingHeart",heart,.018,"HeartRed",g,.012).location.y=-.258
leaf=ell("LidLeaf",(.10,0,.30),(.14,.07,.035),"LeafGreen",g,16,8)
leaf.rotation_euler.y=-.32
finish("pickup_healing","Honey healing jar with red heart, cream label and natural green leaf")
(art.OUT/"manifest.json").write_text(json.dumps({"batch":"pickups_toon_v01","assets":art.STATS},indent=2),encoding="utf-8")
print("PICKUPS_TOON_V01_OK: "+json.dumps(art.STATS))
