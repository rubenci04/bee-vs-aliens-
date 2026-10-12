"""Two low-cost original projectile meshes, distinct bee/alien allegiance."""
from pathlib import Path
import importlib.util,json
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location("bee_art",ROOT/"tools/art/create_future_biomes_v09.py")
art=importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)
art.OUT=ROOT/"assets/models/projectiles_toon_v01"
art.SRC=ROOT/"art_source/blender/projectiles_toon_v01"
for p in (art.OUT,art.SRC): p.mkdir(parents=True,exist_ok=True)
(art.SRC/".gdignore").write_text("",encoding="utf-8")
art.PALETTE.update({"HoneyGold":(.94,.63,.12),"BeeCream":(.98,.81,.32)})
for alien in (False,True):
    key="alien_bolt" if alien else "bee_bolt"
    root=art.reset(key+"Model")
    g=art.empty("AlienControlDevice" if alien else "BeeProjectile",root)
    art.ell("BoltCore",(-.02,0,0),(.28,.052,.052),"Cyan" if alien else "HoneyGold",g,20,10)
    art.ell("TailCollar",(.19,0,0),(.072,.068,.068),"Shell" if alien else "BeeCream",g,16,8)
    for side in (-1,1):
        fin=art.badge("TailFin_%d"%side,[(.13,0),(.31,.075*side),(.27,0)],.028,"Violet" if alien else "BeeCream",g,.005)
        fin.location.z=side*.014
    art.join_geometry(g)
    art.save(key,"Alien cyan bolt with violet tail" if alien else "Bee honey-yellow bolt with cream tail")
    art.STATS[-1]["emissive"]=alien
    assert art.STATS[-1]["triangles"]<1000
    wrapper=ROOT/"scenes/art_labs/projectiles_toon_v01"/(key+".tscn")
    wrapper.parent.mkdir(parents=True,exist_ok=True)
    wrapper.write_text('''[gd_scene load_steps=3 format=3]
[ext_resource type="Script" path="res://scripts/art/future_asset_visual.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/projectiles_toon_v01/%s.glb" id="2"]
[node name="%s" type="Node3D"]
script = ExtResource("1")
[node name="Model" parent="." instance=ExtResource("2")]
'''%(key,key),encoding="utf-8")
(art.OUT/"manifest.json").write_text(json.dumps({"assets":art.STATS},indent=2),encoding="utf-8")
print("PROJECTILES_TOON_V01_OK: "+json.dumps(art.STATS))
