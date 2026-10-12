"""Three original natural props for garden/forest, editable closed mid-poly solids."""
from pathlib import Path
import importlib.util, json, math
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location("bee_art",ROOT/"tools/art/create_future_biomes_v09.py")
art=importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)
art.OUT=ROOT/"assets/models/forest_floor_v01"
art.SRC=ROOT/"art_source/blender/forest_floor_v01"
for folder in (art.OUT,art.SRC): folder.mkdir(parents=True,exist_ok=True)
(art.SRC/".gdignore").write_text("",encoding="utf-8")
art.PALETTE.update({"Bark":(.43,.29,.16),"CutWood":(.75,.57,.32),"HeartWood":(.31,.22,.12),
    "Moss":(.42,.52,.21),"Fern":(.32,.49,.19),"FernLight":(.47,.61,.25),"Stem":(.28,.39,.13),
    "BellCoral":(.82,.43,.26),"BellCream":(.91,.75,.45),"PollenGold":(.86,.60,.16)})

def start(name):
    root=art.reset(name)
    return root,art.empty("NaturalGeometry",root)

def finish(key,role,budget):
    art.join_geometry(bpy.data.objects["NaturalGeometry"])
    art.save(key,role)
    art.STATS[-1]["emissive"]=False
    assert art.STATS[-1]["triangles"]<=budget
    assert art.STATS[-1]["mesh_objects"]==1
    folder=ROOT/"scenes/art_labs/forest_floor_v01"
    folder.mkdir(parents=True,exist_ok=True)
    (folder/(key+".tscn")).write_text('''[gd_scene load_steps=3 format=3]
[ext_resource type="Script" path="res://scripts/art/future_asset_visual.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/forest_floor_v01/%s.glb" id="2"]
[node name="%s" type="Node3D"]
script = ExtResource("1")
[node name="Model" parent="." instance=ExtResource("2")]
'''%(key,key),encoding="utf-8")

def leaf(name,base,tip,width,material,parent):
    # Rounded biconvex blade, broad face arranged for readable side-view foliage.
    base,tip=Vector(base),Vector(tip)
    axis=(tip-base).normalized()
    across=Vector((0,1,0)).cross(axis).normalized()
    normal=axis.cross(across).normalized()
    vertices=[]; rows=[]; faces=[]; sides=8
    for t in (0,.2,.5,.8,1):
        row=[]
        for j in range(1 if t in (0,1) else sides):
            angle=j*math.tau/sides
            position=base.lerp(tip,t)+across*(math.sin(math.pi*t)*width*math.cos(angle))+normal*(math.sin(math.pi*t)*.012*math.sin(angle))
            row.append(len(vertices)); vertices.append(tuple(position))
        rows.append(row)
    for a,b in zip(rows,rows[1:]):
        for j in range(sides):
            k=(j+1)%sides
            faces.append((a[0],b[k],b[j]) if len(a)==1 else ((a[j],a[k],b[0]) if len(b)==1 else (a[j],a[k],b[k],b[j])))
    return art.smooth(art.mesh(name,vertices,faces,material,parent))

root,g=start("HollowFallenLogModel")
# Annular end cuts, bark outside and a continuous open bore: closed wood wall.
vertices=[]; faces=[]; sides=40
profile=[(-1.14,.47),(1.08,.43),(1.08,.31),(-1.14,.35)]
for x,r in profile:
    for j in range(sides):
        a=j*math.tau/sides
        radius=r*(1+.035*math.sin(a*3)+.018*math.cos(a*5))
        vertices.append((x,radius*math.cos(a),.48+radius*math.sin(a)))
for i in range(4):
    for j in range(sides):
        k=(j+1)%sides; n=(i+1)%4
        faces.append((i*sides+j,i*sides+k,n*sides+k,n*sides+j))
wood=art.mesh("HollowWoodWall",vertices,faces,"Bark",g)
wood.data.materials.append(art.MATERIALS["CutWood"])
wood.data.materials.append(art.MATERIALS["HeartWood"])
for polygon in wood.data.polygons:
    row=polygon.index//sides
    polygon.material_index=1 if row in (1,3) else (2 if row==2 else 0)
    polygon.use_smooth=row in (0,2)
art.tapered("BranchStub",[(-.35,.14,.79),(-.46,.13,.97),(-.65,.12,1.07)],[.13,.10,.073],"Bark",g,12)
art.ell("BranchCut",(-.675,.12,1.08),(.028,.075,.073),"CutWood",g,20,10)
for i,(x,y,z) in enumerate(((.25,-.12,.88),(.61,-.08,.87),(-.05,-.10,.90))):
    art.ell("BroadMossPatch_%d"%i,(x,y,z),(.24,.17,.048),"Moss",g,20,10)
g.rotation_euler.z=.30
opening=art.empty("HollowEntrance",g); opening.location=(-1.18,0,.48)
finish("hollow_fallen_log","Warm hollow fallen log with continuous bore, end cuts, one branch and broad moss patches",2500)

root,g=start("ForestFernModel")
for i,(x,y,height) in enumerate(((-.95,-.04,.75),(-.59,.14,1.13),(.05,.25,1.40),(.59,.10,1.13),(.95,-.07,.75))):
    points=[(0,0,.04),(x*.16,y*.2,height*.60),(x*.48,y*.6,height),(x,y,height*.80)]
    art.tapered("FrondStem_%d"%i,points,[.019,.016,.012,.005],"Stem",g,8)
    curve=[Vector(p) for p in art.soften_open(points,4)]
    for j,t in enumerate((.33,.51,.70,.88)):
        index=min(len(curve)-2,round(t*(len(curve)-1)))
        base=curve[index]
        tangent=(curve[index+1]-curve[index-1]).normalized()
        across=Vector((-tangent.z,0,tangent.x)).normalized()
        for side in (-1,1):
            tip=base+across*(side*(.30-.12*t))+tangent*.09
            tip.y+=side*.025
            leaf("Leaflet_%d_%d_%d"%(i,j,side),base,tip,.055 if j<3 else .040,
                "Fern" if i%2==0 else "FernLight",g)
finish("forest_fern","Five curved fern fronds with forty rounded leaflets; natural green, non-emissive",3800)

root,g=start("GardenBellflowerModel")
art.tapered("MainStem",[(0,0,.02),(-.06,.03,.45),(.03,.02,.95),(-.06,0,1.47)],[.036,.029,.023,.013],"Stem",g,10)
for i,(base,tip) in enumerate((((0,0,.20),(-.49,-.03,.41)),((-.04,0,.39),(.43,-.03,.65)),
    ((.01,0,.73),(-.43,-.02,.93)))):
    leaf("LanceLeaf_%d"%i,base,tip,.10,"FernLight",g)
for i,(x,z) in enumerate(((-.40,1.09),(.27,1.53))):
    art.tapered("FlowerBranch_%d"%i,[(0,0,z-.18),(x*.60,0,z+.18),(x,0,z+.20)],[.021,.016,.011],"Stem",g,10)
    bell=art.empty("Bell_%d"%i,g); bell.location=(x,0,z)
    profile=[(0,.30),(.08,.29),(.14,.10),(.27,-.20),(.25,-.235),(.22,-.20),(.10,.10),(.055,.23),(0,.23)]
    vertices=[]; rows=[]; faces=[]; sides=32
    for r,height in profile:
        row=[]
        for j in range(1 if r==0 else sides):
            a=j*math.tau/sides
            scallop=math.cos(5*a) if height<0 else 0
            row.append(len(vertices))
            vertices.append((r*(1+.06*scallop)*math.cos(a),r*(1+.06*scallop)*math.sin(a),height+.025*scallop))
        rows.append(row)
    for a,b in zip(rows,rows[1:]):
        for j in range(sides):
            k=(j+1)%sides
            faces.append((a[0],b[k],b[j]) if len(a)==1 else ((a[j],a[k],b[0]) if len(b)==1 else (a[j],a[k],b[k],b[j])))
    flower=art.smooth(art.mesh("HollowCorolla",vertices,faces,"BellCoral",bell))
    flower.data.materials.append(art.MATERIALS["BellCream"])
    for polygon in flower.data.polygons:
        if polygon.index//sides>=4: polygon.material_index=1
    for j in range(3):
        art.tapered("Stamen_%d"%j,[(0,0,.10),((j-1)*.065,-.03,-.18)],[.009,.008],"BellCream",bell,8)
        art.ell("PollenTip_%d"%j,((j-1)*.065,-.03,-.19),(.023,.022,.031),"PollenGold",bell,12,6)
    bell.rotation_euler.y=-.22 if i==0 else .22
finish("garden_bellflower","Warm coral bellflowers with real open corollas, cream interiors, stamens and lance leaves",3000)
(art.OUT/"manifest.json").write_text(json.dumps({"batch":"forest_floor_v01","assets":art.STATS},indent=2),encoding="utf-8")
print("FOREST_FLOOR_V01_OK: "+json.dumps(art.STATS))
