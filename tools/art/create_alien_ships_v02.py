"""Two original side-view alien ships, a small 5k-budget POC. No external assets."""
from pathlib import Path
import importlib.util, json
import bpy
ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("bee_art", ROOT / "tools/art/create_future_biomes_v09.py")
art = importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)
art.OUT = ROOT / "assets/models/alien_ships_v02"
art.SRC = ROOT / "art_source/blender/alien_ships_v02"
for folder in (art.OUT, art.SRC):
    folder.mkdir(parents=True, exist_ok=True)
(art.SRC / ".gdignore").write_text("", encoding="utf-8")

def marker(root, name, position):
    obj = art.empty(name, root)
    obj.location = position

def finish(key, role):
    objects = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    count = sum(len(p.vertices)-2 for o in objects for p in o.data.polygons)
    if count > 5000:
        for obj in objects:
            modifier = obj.modifiers.new("ShipBudget", "DECIMATE")
            modifier.ratio = 5000 / count
            modifier.use_collapse_triangulate = True
            art.apply_modifier(obj, modifier)
    art.save(key, role)
    assert art.STATS[-1]["triangles"] <= 5000
    assert art.STATS[-1]["mesh_objects"] == 1

def interceptor():
    root = art.reset("AlienNeedleInterceptorModel")
    tech = art.empty("AlienControlDevice", root)
    art.badge("SweptNeedleHull",[(-1.65,0.02),(-0.70,0.32),(0.55,0.27),(1.20,0.03),
        (0.68,-0.25),(-0.82,-0.20)],0.56,"Shell",tech,0.065)
    art.ell("ArmouredBridge",(-0.12,0,0.30),(0.60,0.29,0.20),"ShellEdge",tech,28,14)
    art.ell("CyanCockpit",(-0.32,-0.272,0.36),(0.31,0.027,0.085),"Cyan",tech,24,12)
    art.badge("NoseEnergySlit",[(-1.52,0.015),(-0.88,0.115),(-0.39,0.105),(-0.62,0.04)],
        0.018,"Cyan",tech,0.008).location.y=-0.292
    for side in (-1,1):
        # Different side-view heights keep both swept fins and engines readable.
        height = 0.52 if side < 0 else -0.36
        fin = art.badge("SweptFin_%d"%side,[(0.04,0.10),(0.47,height),(1.43,height*1.18),
            (0.97,0.04),(0.46,-0.10)],0.12,"ShellEdge",tech,0.025)
        fin.location.y=side*0.30
        pod = (0.86,side*0.36,height*0.72)
        art.ell("EnginePod_%d"%side,pod,(0.54,0.22,0.17),"Shell",tech,28,14)
        art.ell("EngineBezel_%d"%side,(1.31,side*0.36,height*0.72),(0.07,0.185,0.145),"Rubber",tech,20,10)
        art.ell("CyanThrust_%d"%side,(1.365,side*0.36,height*0.72),(0.035,0.135,0.095),"Cyan",tech,20,10)
        art.ell("SideEngineLens_%d"%side,(0.99,side*0.575,height*0.72),(0.15,0.018,0.047),"Cyan",tech,20,10)
        art.ell("SecondaryNode_%d"%side,(0.25,side*0.38,0.08),(0.065,0.024,0.055),"Violet",tech,16,8)
    art.tapered("VentralGun",[(-0.32,0,-0.23),(-0.86,0,-0.30),(-1.14,0,-0.30)],
        [0.08,0.07,0.055],"ShellEdge",tech,12)
    art.ell("GunCyanLens",(-1.17,0,-0.30),(0.028,0.052,0.052),"Cyan",tech,16,8)
    for name,pos in [("Muzzle",(-1.22,0,-0.30)),("EngineLeft",(1.41,-0.36,0.3744)),
        ("EngineRight",(1.41,0.36,-0.2592)),("CoreTarget",(-0.32,-0.28,0.36))]:
        marker(root,name,pos)
    finish("alien_needle_interceptor","Fast needle interceptor; swept fins, twin engines and ventral cannon")

def bomber():
    root = art.reset("AlienArmouredBomberModel")
    tech = art.empty("AlienControlDevice",root)
    art.ell("BroadHull",(0.05,0,0.08),(1.18,0.51,0.57),"Shell",tech,32,16)
    art.ell("DorsalArmour",(0.11,0,0.47),(0.89,0.46,0.30),"ShellEdge",tech,28,14)
    art.ell("FrontSensorBezel",(-1.035,0,0.17),(0.24,0.36,0.30),"Rubber",tech,24,12)
    art.ell("FrontCyanSensor",(-1.18,-0.13,0.17),(0.12,0.22,0.18),"Cyan",tech,24,12)
    for side in (-1,1):
        y=side*0.47
        shield=art.badge("SideArmour_%d"%side,[(-0.66,0.48),(0.64,0.51),(1.12,0.18),
            (0.79,-0.20),(-0.56,-0.25),(-0.96,0.10)],0.095,"ShellEdge",tech,0.04)
        shield.location.y=y
        art.badge("SideCyanRail_%d"%side,[(-0.70,0.12),(-0.35,0.19),(0.45,0.19),
            (0.68,0.09),(0.29,0.10),(-0.35,0.10)],0.019,"Cyan",tech,0.008).location.y=y+side*0.06
        art.ell("RearEngine_%d"%side,(1.0,side*0.34,0.10),(0.56,0.26,0.30),"Shell",tech,24,12)
        art.ell("ExhaustBezel_%d"%side,(1.48,side*0.34,0.10),(0.085,0.20,0.23),"Rubber",tech,20,10)
        art.ell("CyanExhaust_%d"%side,(1.55,side*0.34,0.10),(0.04,0.145,0.17),"Cyan",tech,20,10)
        art.ell("VioletShieldNode_%d"%side,(0.45,y+side*0.071,0.35),(0.09,0.022,0.07),"Violet",tech,16,8)
    # Payload cradle sits below the broad hull, giving a heavier silhouette.
    art.block("BombBay",(0.12,0,-0.47),(0.63,0.35,0.16),"Rubber",tech,0.055)
    for i,x in enumerate((-0.32,0.44)):
        art.ell("ArmouredPayload_%d"%i,(x,0,-0.68),(0.25,0.26,0.28),"Shell",tech,24,12)
        art.ell("PayloadCyanLens_%d"%i,(x,-0.255,-0.68),(0.11,0.022,0.10),"Cyan",tech,20,10)
    art.badge("DorsalReceiverFin",[(-0.06,0.58),(0.16,1.02),(0.56,0.96),(0.47,0.60)],
        0.12,"Shell",tech,0.025)
    art.ell("ReceiverVioletNode",(0.35,-0.075,0.91),(0.075,0.025,0.042),"Violet",tech,16,8)
    for name,pos in [("BombDropLeft",(-0.32,0,-1.0)),("BombDropRight",(0.44,0,-1.0)),
        ("EngineLeft",(1.61,-0.34,0.1)),("EngineRight",(1.61,0.34,0.1)),
        ("CoreTarget",(-1.2,-0.13,0.17))]:
        marker(root,name,pos)
    finish("alien_armoured_bomber","Heavy armoured bomber; broad shell, twin engines, two payloads and drop markers")

interceptor()
bomber()
(art.OUT/"manifest.json").write_text(json.dumps({"batch":"alien_ships_v02","assets":art.STATS},indent=2),encoding="utf-8")
print("ALIEN_SHIPS_V02_OK: "+json.dumps(art.STATS))
