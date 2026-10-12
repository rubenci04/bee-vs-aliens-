"""User-requested props in four independently exportable, small POCs.
Blender --background --python tools/art/create_requested_props_v01.py -- pine_woods_v01
Other batches: ground_litter_v01, ground_litter_v02, residential_sky_v01.
Original geometry only; preserves existing assets. No texture dependencies.
"""
from pathlib import Path
import importlib.util, json, math, sys
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location("bee_art",ROOT/"tools/art/create_future_biomes_v09.py")
art=importlib.util.module_from_spec(spec); spec.loader.exec_module(art)
batch=sys.argv[sys.argv.index("--")+1] if "--" in sys.argv else "pine_woods_v01"
art.OUT=ROOT/"assets/models"/batch; art.SRC=ROOT/"art_source/blender"/batch
for folder in (art.OUT,art.SRC): folder.mkdir(parents=True,exist_ok=True)
(art.SRC/".gdignore").write_text("",encoding="utf-8")
art.PALETTE.update({"Bark":(.43,.29,.16),"ConeScale":(.59,.39,.20),"ConeLight":(.72,.51,.28),
 "Pine":(.25,.40,.19),"PineLight":(.37,.51,.23),"BottleGlass":(.34,.52,.27),"GlassHighlight":(.79,.85,.64),
 "PaperCream":(.86,.78,.57),"PaperRed":(.69,.28,.17),"Cardboard":(.59,.43,.26),"Striker":(.31,.24,.18),
 "MatchWood":(.76,.61,.38),"MatchHead":(.60,.25,.14),"BananaYellow":(.88,.70,.22),"BananaCream":(.93,.83,.54),
 "BananaTip":(.34,.26,.13),"Metal":(.58,.61,.56),"MetalDark":(.34,.39,.36),"TinLabel":(.68,.54,.29),
 "StarCream":(.89,.79,.49),"Pole":(.35,.39,.32),"LampWarm":(.94,.73,.36),
 "WallCream":(.75,.69,.51),"WallBrick":(.64,.43,.28),"RoofTile":(.51,.29,.20),"RoofSage":(.36,.42,.27),
 "Window":(.44,.51,.38),"DoorWood":(.43,.33,.22)})

def start(name):
    root=art.reset(name)
    return root,art.empty("PropGeometry",root)

def finish(key,role,budget=5000):
    objects=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    before=sum(len(p.vertices)-2 for o in objects for p in o.data.polygons)
    if before>budget:
        for obj in objects:
            mod=obj.modifiers.new("PropBudget","DECIMATE"); mod.ratio=budget/before
            mod.use_collapse_triangulate=True; art.apply_modifier(obj,mod)
    art.join_geometry(bpy.data.objects["PropGeometry"])
    art.save(key,role)
    art.STATS[-1]["emissive"]=key=="warm_street_lamp"
    assert art.STATS[-1]["triangles"]<=budget
    assert art.STATS[-1]["mesh_objects"]==1
    folder=ROOT/"scenes/art_labs"/batch; folder.mkdir(parents=True,exist_ok=True)
    (folder/(key+".tscn")).write_text('''[gd_scene load_steps=3 format=3]
[ext_resource type="Script" path="res://scripts/art/requested_prop_visual.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/%s/%s.glb" id="2"]
[node name="%s" type="Node3D"]
script = ExtResource("1")
[node name="Model" parent="." instance=ExtResource("2")]
'''%(batch,key,key),encoding="utf-8")

def lathe(name,profile,mat,parent,sides=32,offset=(0,0,0),inner_from=None,inner_mat=None,lobes=0):
    vertices=[]; rows=[]; faces=[]; segments=[]
    for r,z in profile:
        row=[]
        for j in range(1 if r==0 else sides):
            a=j*math.tau/sides; radius=r*(1+.035*math.cos(a*lobes)) if lobes else r
            row.append(len(vertices)); vertices.append((offset[0]+radius*math.cos(a),offset[1]+radius*math.sin(a),offset[2]+z))
        rows.append(row)
    for i,(a,b) in enumerate(zip(rows,rows[1:])):
        for j in range(sides):
            k=(j+1)%sides
            faces.append((a[0],b[k],b[j]) if len(a)==1 else ((a[j],a[k],b[0]) if len(b)==1 else (a[j],a[k],b[k],b[j])))
            segments.append(i)
    obj=art.smooth(art.mesh(name,vertices,faces,mat,parent))
    if inner_mat:
        obj.data.materials.append(art.MATERIALS[inner_mat])
        for p,segment in zip(obj.data.polygons,segments):
            if segment>=inner_from: p.material_index=1
    return obj

def pinecone():
    root,g=start("PineConeModel")
    art.ell("ConeCore",(0,0,.45),(.20,.20,.43),"Bark",g,20,10)
    for row in range(5):
        radius=[.20,.29,.30,.25,.16][row]
        for j in range(8):
            a=(j+(.5 if row%2 else 0))*math.tau/8
            scale=art.ell("Scale_%d_%d"%(row,j),(radius*math.cos(a),radius*math.sin(a),.15+row*.145),
                (.16,.105,.072),"ConeLight" if row%2 else "ConeScale",g,12,6)
            scale.rotation_euler=(.0,-.34,a)
    art.tapered("ConeStem",[(0,0,.80),(.02,0,.94)],[.035,.024],"Bark",g,10)
    finish("pine_cone","Pine cone with forty overlapping rounded woody scales",5000)

def pines():
    root,g=start("TallPineModel")
    art.tapered("Trunk",[(0,0,0),(0,0,1.4),(.04,0,2.8)],[.13,.085,.025],"Bark",g,16)
    for i,(r,z,h) in enumerate(((.85,.48,1.15),(.69,1.06,1.10),(.50,1.65,.97),(.30,2.18,.80))):
        lathe("RoundedNeedleTier_%d"%i,[(0,0),(r*.82,.025),(r,.10),(r*.90,.23),(r*.57,h*.53),(r*.22,h*.86),(0,h)],
            "Pine" if i%2==0 else "PineLight",g,32,(0,0,z),lobes=5)
    finish("tall_pine","Tall tiered pine with smooth lobed needle masses and visible trunk",4000)
    root,g=start("UmbrellaPineModel")
    art.tapered("BentTrunk",[(0,0,0),(.04,0,.80),(-.08,0,1.65),(.0,0,2.2)],[.16,.12,.085,.05],"Bark",g,14)
    for i,(x,y,z) in enumerate(((-.63,0,2.10),(.59,.06,2.18),(-.15,-.19,2.43),(.22,.22,2.43))):
        art.tapered("Branch_%d"%i,[(-.02,0,1.4),(x*.55,y*.6,1.9),(x,y,z)],[.063,.040,.023],"Bark",g,10)
        art.ell("NeedleCrown_%d"%i,(x,y,z),(.75,.53,.38),"Pine" if i%2 else "PineLight",g,24,12)
    finish("umbrella_pine","Mediterranean umbrella pine; spreading crown and visible forked branches",4500)

def bottle():
    root,g=start("GlassBottleModel")
    material=art.MATERIALS["BottleGlass"]
    material.diffuse_color=(*material.diffuse_color[:3],.58)
    bs=next(n for n in material.node_tree.nodes if n.type=="BSDF_PRINCIPLED")
    bs.inputs["Alpha"].default_value=.58
    bs.inputs["Roughness"].default_value=.30
    # Continuous inner wall and recessed bottom; open rim, no cap over the mouth.
    profile=[(0,.03),(.30,.03),(.34,.09),(.34,.79),(.31,.90),(.17,1.07),(.13,1.15),(.13,1.44),(.155,1.46),
        (.155,1.53),(.105,1.53),(.095,1.43),(.095,1.16),(.13,1.07),(.275,.89),(.29,.78),(.29,.12),(0,.12)]
    lathe("HollowGlass",profile,"BottleGlass",g,40)
    art.ell("SoftReflection",(-.13,-.317,.48),(.027,.018,.24),"GlassHighlight",g,20,10)
    mouth=art.empty("BottleMouth",root); mouth.location=(0,0,1.54)
    finish("glass_bottle","Open green glass bottle with continuous wall, thick rim and stylized reflection",3000)

def matchbox():
    root,g=start("MatchboxModel")
    # Open sleeve is built from four rounded walls; tray projects to the right.
    for name,pos,scale in (("SleeveTop",(0,0,.37),(.62,.32,.035)),("SleeveBottom",(0,0,.055),(.62,.32,.035)),
        ("FrontWall",(0,-.30,.21),(.62,.026,.15)),("BackWall",(0,.30,.21),(.62,.026,.15))):
        art.block(name,pos,scale,"PaperRed",g,.018)
    art.block("CreamTopPanel",(0,0,.407),(.48,.25,.007),"PaperCream",g,.008)
    art.block("StrikingStrip",(0,-.332,.21),(.47,.009,.067),"Striker",g,.008)
    art.block("TrayBottom",(.34,0,.095),(.74,.25,.025),"Cardboard",g,.014)
    for y in (-.24,.24): art.block("TraySide",(.34,y,.19),(.74,.020,.085),"Cardboard",g,.011)
    art.block("TrayEnd",(1.06,0,.19),(.025,.25,.085),"Cardboard",g,.012)
    for i in range(4):
        y=(i-1.5)*.105
        art.tapered("MatchStick_%d"%i,[(.48,y,.16),(.96,y,.16)],[.017,.017],"MatchWood",g,8)
        art.ell("MatchHead_%d"%i,(.99,y,.16),(.045,.03,.032),"MatchHead",g,12,6)
    # Printed geometric emblem, generic and text-free.
    art.badge("TopDiamond",[(0,.07),(.12,0),(0,-.07),(-.12,0)],.012,"PaperRed",g,.005).rotation_euler.x=math.pi/2
    emblem=bpy.context.scene.objects.get("TopDiamond"); emblem.location=(0,0,.425)
    finish("matchbox","Generic partly open matchbox, striker, sliding tray and four unused matches",3000)

def wrapper():
    root,g=start("CandyWrapperModel")
    vertices=[]; faces=[]; columns=6; rows=5
    for side in (-1,1):
        for j in range(rows):
            for i in range(columns):
                x=(i/(columns-1)-.5)*1.6; z=(j/(rows-1)-.5)*.64
                y=.075*math.sin(i*1.9+j*.8)+.04*math.cos(j*2.2)+side*.009
                vertices.append((x,y,z+.36))
    count=columns*rows
    for j in range(rows-1):
        for i in range(columns-1):
            a=j*columns+i; b=a+1; c=a+columns+1; d=a+columns
            faces.extend(((a,d,c,b),(a+count,b+count,c+count,d+count)))
    boundary=list(range(columns))+[j*columns+columns-1 for j in range(1,rows)]+list(range(count-2,count-columns-1,-1))+[j*columns for j in range(rows-2,0,-1)]
    for a,b in zip(boundary,boundary[1:]+boundary[:1]): faces.append((a,b,b+count,a+count))
    paper=art.mesh("FoldedPaper",vertices,faces,"PaperCream",g)
    paper.data.materials.append(art.MATERIALS["PaperRed"])
    for polygon in paper.data.polygons:
        if polygon.index<40 and (polygon.index//2)%5 in (0,4): polygon.material_index=1
    finish("open_candy_wrapper","Empty crumpled candy paper, coral edge bands and cream middle; closed thin sheet",1200)

def peel_strip(name,centres,widths,g,angle):
    vertices=[]; faces=[]; count=len(centres)
    # Two broad faces with a rounded ridge, outer yellow and inner cream.
    for thickness in (-.022,.022):
        for i,(centre,width) in enumerate(zip(centres,widths)):
            centre=Vector(centre)
            tangent=(Vector(centres[min(i+1,count-1)])-Vector(centres[max(i-1,0)])).normalized()
            breadth=Vector((-math.sin(angle)*.65,math.cos(angle)*.65,.76))
            breadth=(breadth-tangent*breadth.dot(tangent)).normalized()
            normal=tangent.cross(breadth).normalized()
            for across in (-1,0,1):
                point=centre+breadth*(across*width)+normal*(thickness+.04*(1-abs(across)))
                vertices.append(tuple(point))
    n=count*3
    for i in range(count-1):
        for j in range(2):
            a=i*3+j; b=a+1; c=a+4; d=a+3
            faces.extend(((a,b,c,d),(a+n,d+n,c+n,b+n)))
    boundary=[0,1,2]+[i*3+2 for i in range(1,count)]+[n-2,n-3]+[i*3 for i in range(count-2,0,-1)]
    for a,b in zip(boundary,boundary[1:]+boundary[:1]): faces.append((a,b,b+n,a+n))
    obj=art.smooth(art.mesh(name,vertices,faces,"BananaYellow",g))
    obj.data.materials.append(art.MATERIALS["BananaCream"])
    for polygon in obj.data.polygons:
        if polygon.index<(count-1)*4 and polygon.index%2==1: polygon.material_index=1

def banana():
    root,g=start("BananaPeelModel")
    for i,angle in enumerate((.08,2.55,4.3)):
        centres=[]; widths=[]
        for j in range(9):
            t=j/8; r=.07+1.12*t
            centres.append((r*math.cos(angle),r*math.sin(angle)*.7,.60*(1-t)**2+.10+.08*math.sin(t*math.pi*1.4)))
            widths.append(.035+.18*math.sin(math.pi*(.07+.87*t)))
        peel_strip("PeelFlap_%d"%i,centres,widths,g,angle)
        end=centres[-1]; art.ell("DarkTip_%d"%i,end,(.052,.045,.023),"BananaTip",g,12,6)
    art.tapered("BananaStem",[(0,0,.58),(-.03,0,.78)],[.09,.057],"BananaYellow",g,12)
    art.ell("StemTip",(-.03,0,.79),(.06,.057,.027),"BananaTip",g,12,6)
    finish("banana_peel","Empty yellow banana peel with three curved flaps, cream interiors and brown tips",1500)

def tuna():
    root,g=start("TunaTinModel")
    lathe("OpenTin",[(0,.015),(.51,.015),(.56,.045),(.56,.33),(.58,.36),(.58,.40),(.53,.40),(.51,.33),(.51,.075),(0,.075)],
        "Metal",g,40,inner_from=6,inner_mat="MetalDark")
    lathe("OchreLabel",[(.561,.09),(.568,.095),(.568,.285),(.561,.29),(.561,.09)],"TinLabel",g,40)
    # Lifted lid with a pull ring, source remains closed solid geometry.
    lid=art.empty("LiftedLid",g); lid.location=(.40,0,.38); lid.rotation_euler.y=1.12
    lathe("LidDisc",[(0,-.018),(.52,-.018),(.54,0),(.52,.018),(0,.018)],"Metal",lid,40,offset=(-.45,0,0))
    ring=[(-.44+.13*math.cos(i*math.tau/24),.17*math.sin(i*math.tau/24),.04) for i in range(24)]
    art.tube("PullRing",ring,.024,"MetalDark",lid,8,True)
    finish("open_tuna_tin","Empty low tuna can, open interior, ochre label and lifted pull-tab lid",3000)

def stars():
    root,g=start("WarmStarSetModel")
    for i,(x,z,r) in enumerate(((-.73,.62,.23),(.58,.72,.17),(.82,-.29,.11),(-.35,-.42,.10),(.08,.06,.15))):
        points=[]
        for j in range(10):
            a=math.pi/2+j*math.tau/10; radius=r if j%2==0 else r*.45
            points.append((x+math.cos(a)*radius,z+math.sin(a)*radius))
        art.badge("Star_%d"%i,points,.045,"StarCream",g,.012)
    finish("warm_star_set","Five rounded cream stars for distant night backgrounds; no alien glow",1800)

def lamp():
    root,g=start("WarmStreetLampModel")
    lathe("Foot",[(0,0),(.20,0),(.22,.04),(.16,.18),(.11,.22),(0,.22)],"Pole",g,24)
    art.tapered("Post",[(0,0,.17),(0,0,1.9),(0,0,2.8)],[.08,.055,.046],"Pole",g,16)
    art.tapered("CurvedArm",[(0,0,2.72),(.12,0,3.05),(.43,0,3.13),(.69,0,2.97)],[.047,.043,.038,.032],"Pole",g,12)
    lathe("LampShade",[(0,0),(.31,0),(.32,.055),(.22,.17),(0,.23)],"Pole",g,24,offset=(.70,0,2.75))
    art.ell("WarmBulb",(.70,0,2.74),(.23,.20,.055),"LampWarm",g,20,10)
    material=art.MATERIALS["LampWarm"]
    node=next(n for n in material.node_tree.nodes if n.type=="BSDF_PRINCIPLED")
    node.inputs["Emission Color"].default_value=material.diffuse_color
    node.inputs["Emission Strength"].default_value=.22
    anchor=art.empty("WarmLightAnchor",root); anchor.location=(.70,0,2.70)
    finish("warm_street_lamp","Human-scale curved street lamp, graphite-green pole and warm amber bulb",3500)

def house(key,two_storeys=False):
    root,g=start("ResidentialHouseModel")
    height=1.85 if two_storeys else 1.05; width=.97 if two_storeys else 1.23
    wall="WallBrick" if two_storeys else "WallCream"; roof="RoofSage" if two_storeys else "RoofTile"
    art.block("HouseBody",(0,0,height*.5),(width,.36,height*.5),wall,g,.028)
    art.badge("Roof",[(-width-.18,height),(0,height+.66),(width+.18,height),(width+.05,height-.10),
        (0,height+.49),(-width-.05,height-.10)],.90,roof,g,.026)
    art.badge("Gable",[(-width,height-.01),(0,height+.49),(width,height-.01)],.71,wall,g,.008)
    art.block("Chimney",(.57,.05,height+.45),(.10,.14,.29),roof,g,.018)
    art.block("Door",(-.12,-.384,.40),(.19,.027,.38),"DoorWood",g,.010)
    art.ell("DoorHandle",(.01,-.42,.41),(.015,.012,.021),"PaperCream",g,12,6)
    heights=[.61,1.41] if two_storeys else [.59]
    for z in heights:
        for x in (-.63,.62):
            art.block("WindowFrame",(x,-.386,z),(.19,.030,.21),"DoorWood",g,.013)
            art.block("Window",(x,-.419,z),(.16,.012,.178),"Window",g,.006)
            art.block("Mullion",(x,-.436,z),(.012,.006,.18),"PaperCream",g,.004)
    if not two_storeys:
        art.block("PorchStep",(-.12,-.51,.055),(.32,.18,.045),"Cardboard",g,.015)
        for x in (-.48,.24): art.block("PorchPost",(x,-.56,.52),(.022,.025,.47),"DoorWood",g,.006)
        art.block("PorchRoof",(-.12,-.57,1.0),(.46,.29,.04),roof,g,.014)
    finish(key,"Two-storey brick house for distant parallax" if two_storeys else "Warm single-storey cottage with porch for distant parallax",3500)

if batch=="pine_woods_v01": pinecone(); pines()
elif batch=="ground_litter_v01": bottle(); matchbox(); wrapper()
elif batch=="ground_litter_v02": banana(); tuna()
elif batch=="residential_sky_v01": stars(); lamp(); house("residential_cottage"); house("residential_two_storey",True)
else: raise ValueError("Unknown batch: "+batch)
(art.OUT/"manifest.json").write_text(json.dumps({"batch":batch,"assets":art.STATS},indent=2),encoding="utf-8")
print("REQUESTED_PROPS_OK: "+json.dumps(art.STATS))
