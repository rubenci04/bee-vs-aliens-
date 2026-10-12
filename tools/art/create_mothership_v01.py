"""One original campaign mothership silhouette POC; graphite/cyan/violet only."""
from pathlib import Path
import importlib.util,json,bpy
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location("bee_art",ROOT/"tools/art/create_future_biomes_v09.py")
art=importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)
art.OUT=ROOT/"assets/models/mothership_v01"
art.SRC=ROOT/"art_source/blender/mothership_v01"
for p in (art.OUT,art.SRC): p.mkdir(parents=True,exist_ok=True)
(art.SRC/".gdignore").write_text("",encoding="utf-8")
root=art.reset("AlienMothershipModel")
g=art.empty("AlienControlDevice",root)
art.ell("MainHull",(0,0,0),(1.68,.72,.30),"Shell",g,32,16)
art.ell("DorsalShell",(.15,0,.24),(1.15,.60,.26),"ShellEdge",g,28,14)
art.ell("CommandBridge",(-.08,0,.51),(.56,.35,.24),"Shell",g,24,12)
art.ell("BridgeCyanWindow",(-.17,-.37,.52),(.30,.028,.08),"Cyan",g,20,10)
for side in (-1,1):
    wing=art.badge("ScytheArm_%d"%side,[(side*x,z) for x,z in [(1.02,.14),(1.66,.44),(2.42,.41),(2.73,.19),(2.48,.26),(1.89,.21),(1.48,-.07)]],.24,"ShellEdge",g,.025)
    wing.location.y=.03
    art.ell("EnginePod_%d"%side,(side*1.22,0,-.30),(.29,.34,.30),"Shell",g,24,12)
    art.ell("EngineCyan_%d"%side,(side*1.22,-.36,-.36),(.15,.030,.13),"Cyan",g,20,10)
    art.ell("SecondaryNode_%d"%side,(side*.87,-.62,.08),(.10,.028,.08),"Violet",g,16,8)
    anchor=art.empty("EscortDock_%d"%side,root)
    anchor.location=(side*1.25,0,-.65)
art.ell("HangarGraphite",(0,-.52,-.20),(.68,.18,.18),"Rubber",g,24,12)
for i in range(3):
    art.block("HangarCyanBar_%d"%i,((i-1)*.24,-.692,-.20),(.064,.015,.052),"Cyan",g,.008)
art.tapered("ReceiverMast",[(.21,0,.63),(.38,0,.80),(.54,0,.86)],[.031,.024,.015],"ShellEdge",g,10)
art.ell("VioletReceiver",(.54,0,.86),(.054,.044,.046),"Violet",g,16,8)
for name,pos in (("MainLensTarget",(-.17,-.35,.52)),("HangarSpawn",(0,-.72,-.20)),("BossOrigin",(0,0,0))):
    marker=art.empty(name,root)
    marker.location=pos
before=sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=="MESH" for p in o.data.polygons)
if before>8000:
    for obj in [o for o in bpy.context.scene.objects if o.type=="MESH"]:
        mod=obj.modifiers.new("BossBudget","DECIMATE")
        mod.ratio=8000/before
        mod.use_collapse_triangulate=True
        art.apply_modifier(obj,mod)
art.join_geometry(g)
art.save("alien_mothership","Campaign boss silhouette study; command bridge, scythe arms, hangar, twin engines and external rig markers")
assert art.STATS[-1]["triangles"]<=8000
(art.OUT/"manifest.json").write_text(json.dumps({"assets":art.STATS},indent=2),encoding="utf-8")
print("MOTHERSHIP_V01_OK: "+json.dumps(art.STATS))
