"""Four original Blender/GLB fauna POCs: stick insect, pigeon, mouse and bottle cap.

Run Blender --background --python tools/art/create_future_biomes_v04.py.
X horizontal, -X forward, Blender Z -> Godot Y. Colours authored in sRGB.
No external assets. Fauna and removable devices are separate subtrees.
"""
from pathlib import Path
import bpy, bmesh, math, json
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/models/future_biomes_v04"
SRC = ROOT / "art_source/blender/future_biomes_v04"
for directory in (OUT, SRC):
    directory.mkdir(parents=True, exist_ok=True)
(SRC / ".gdignore").write_text("", encoding="utf-8")
bpy.context.preferences.filepaths.save_version = 0
PALETTE = {
    "Shell": (.20,.22,.27), "ShellEdge": (.30,.32,.37),
    "Cyan": (.15,.95,1), "Violet": (.62,.22,.95),
    "Chestnut": (.46,.20,.10), "Elytra": (.62,.29,.14),
    "Chitin": (.23,.11,.065), "DarkNatural": (.12,.085,.045),
    "Eye": (.065,.045,.025), "Ochre": (.70,.46,.20),
    "SnailBody": (.57,.53,.35), "Foot": (.72,.66,.43),
    "SnailShell": (.74,.48,.24), "Spiral": (.48,.28,.12),
    "Cream": (.85,.76,.53),
    "FireflyBack": (.32,.25,.13), "FireflyThorax": (.65,.40,.15),
    "NaturalLantern": (.90,.72,.16), "Wing": (.73,.71,.56),
    "LadybirdRed": (.74,.12,.065), "LadybirdCream": (.86,.80,.60),
    "OwlBack": (.39,.26,.14), "OwlFeather": (.53,.37,.21),
    "OwlBreast": (.76,.66,.44), "OwlFace": (.83,.74,.53),
    "RayBack": (.34,.40,.39), "RayBelly": (.70,.69,.59),
    "Twig": (.48,.43,.23), "TwigJoint": (.35,.33,.17),
    "PigeonGrey": (.46,.48,.47), "PigeonLight": (.68,.68,.60),
    "PigeonDark": (.25,.28,.27), "NeckOlive": (.37,.43,.29),
    "MouseFur": (.53,.40,.26), "MouseBelly": (.77,.69,.52),
    "EarPink": (.69,.47,.39), "Paw": (.61,.43,.33),
    "CapPaint": (.72,.32,.17), "CapInside": (.75,.59,.38),
}
MATERIALS = {}
STATS = []

def linear(c):
    return c/12.92 if c <= .04045 else ((c+.055)/1.055)**2.4

def empty(name, parent=None):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    return obj

def reset(name):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for material in list(bpy.data.materials):
        bpy.data.materials.remove(material)
    MATERIALS.clear()
    for key, rgb in PALETTE.items():
        color = (*[linear(c) for c in rgb], 1)
        mat = bpy.data.materials.new(key)
        mat.diffuse_color = color
        mat.use_nodes = True
        mat.node_tree.nodes.clear()
        bs = mat.node_tree.nodes.new("ShaderNodeBsdfPrincipled")
        output = mat.node_tree.nodes.new("ShaderNodeOutputMaterial")
        mat.node_tree.links.new(bs.outputs["BSDF"], output.inputs["Surface"])
        bs.inputs["Base Color"].default_value = color
        bs.inputs["Roughness"].default_value = .85
        mat.use_backface_culling = True
        if key in ("Cyan", "Violet"):
            bs.inputs["Emission Color"].default_value = color
            bs.inputs["Emission Strength"].default_value = 1.3
        if key == "NaturalLantern":
            bs.inputs["Emission Color"].default_value = color
            bs.inputs["Emission Strength"].default_value = .45
        if key == "Wing":
            mat.use_backface_culling = False
        MATERIALS[key] = mat
    bpy.context.scene.unit_settings.system = "METRIC"
    return empty(name)

def finish(obj, name, mat, parent):
    obj.name = name
    obj.data.materials.append(MATERIALS[mat])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.parent = parent
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj

def ell(name, pos, scale, mat, parent, segments=24, rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=pos)
    obj = bpy.context.object
    obj.scale = scale
    return finish(obj, name, mat, parent)

def mesh(name, vertices, faces, mat, parent):
    data = bpy.data.meshes.new(name+"Mesh")
    data.from_pydata(vertices, [], faces)
    bm = bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    data.materials.append(MATERIALS[mat])
    for polygon in data.polygons:
        polygon.use_smooth = True
    return obj

def curve(name, points, radii, mat, parent, sides=12, flatten=1, interpolate=True):
    if interpolate:
        coords, widths = [], []
        for i in range(len(points)-1):
            p0,p1,p2,p3 = [Vector(points[max(0,min(len(points)-1,j))]) for j in (i-1,i,i+1,i+2)]
            for j in range(4):
                t = j/4
                coords.append(tuple(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)))
                widths.append(radii[i]*(1-t)+radii[i+1]*t)
        points, radii = coords+[points[-1]], widths+[radii[-1]]
    vertices, faces = [], []
    for i, point in enumerate(points):
        direction = Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])
        direction.normalize()
        reference = Vector((0,1,0)) if abs(direction.y)<.9 else Vector((1,0,0))
        u = direction.cross(reference).normalized()
        v = direction.cross(u).normalized()
        for j in range(sides):
            angle = j*math.tau/sides
            vertices.append(tuple(Vector(point)+radii[i]*(u*math.cos(angle)+v*math.sin(angle)*flatten)))
    for i in range(len(points)-1):
        for j in range(sides):
            a=i*sides+j
            faces.append((a,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,a+sides))
    faces += [tuple(reversed(range(sides))),tuple(range((len(points)-1)*sides,len(points)*sides))]
    return mesh(name, vertices, faces, mat, parent)

def torus(name, pos, major, minor, mat, parent, rotation=(0,0,0)):
    bpy.ops.mesh.primitive_torus_add(major_segments=32, minor_segments=8, major_radius=major, minor_radius=minor, location=pos, rotation=rotation)
    return finish(bpy.context.object, name, mat, parent)

def controller(parent, pos, radius, prefix=""):
    tech = empty("AlienControlDevice", parent)
    x,y,z=pos
    ell(prefix+"ControlShell",pos,(radius,radius*.74,radius*.44),"Shell",tech)
    ell(prefix+"CyanLens",(x-.02,y,z+radius*.31),(radius*.67,radius*.49,radius*.21),"Cyan",tech)
    for s in (-1,1):
        curve(prefix+"Clamp",[(x-.07,y+s*radius*.35,z),(x-.02,y+s*radius*.74,z-radius*.12),(x+.05,y+s*radius*.88,z-radius*.27)],
            [radius*.09,radius*.10,radius*.04],"ShellEdge",tech,10)
        ell(prefix+"VioletFastener",(x+radius*.38,y+s*radius*.62,z+radius*.07),(radius*.13,)*3,"Violet",tech,16,8)
    curve(prefix+"Receiver",[(x+radius*.5,y,z+radius*.2),(x+radius*.8,y,z+radius*.65),(x+radius*.9,y,z+radius*.9)],
        [radius*.07,radius*.045,radius*.025],"Shell",tech,10)
    ell(prefix+"VioletReceiver",(x+radius*.9,y,z+radius*.9),(radius*.11,)*3,"Violet",tech,16,8)
    return tech

def save(key, role):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(key+".blend")))
    bpy.ops.export_scene.gltf(filepath=str(OUT/(key+".glb")),export_format="GLB",use_selection=True,export_yup=True,export_animations=False)
    objects = [o for o in bpy.context.scene.objects if o.type=="MESH"]
    bounds = [o.matrix_world@Vector(v) for o in objects for v in o.bound_box]
    STATS.append({"id":key,"role":role,"triangles":sum(len(p.vertices)-2 for o in objects for p in o.data.polygons),
        "mesh_objects":len(objects),"dimensions_xyz_blender":[round(max(p[i] for p in bounds)-min(p[i] for p in bounds),3) for i in range(3)],
        "forward":"-X","up_godot":"+Y","rigged":False,
        "source":str((SRC/(key+".blend")).relative_to(ROOT)).replace("\\","/"),
        "glb":str((OUT/(key+".glb")).relative_to(ROOT)).replace("\\","/")})

# Walking stick: six articulated natural legs and two long antennae.
root=reset("StickInsectModel")
fauna=empty("NaturalFauna",root)
curve("Abdomen",[(.0,0,0),(.42,0,-.015),(.90,.01,-.035),(1.14,.01,-.035)],
      [.075,.065,.046,.012],"Twig",fauna,16)
curve("Thorax",[(-.79,0,.01),(-.44,0,0),(.07,0,0)],
      [.058,.072,.070],"TwigJoint",fauna,16)
ell("Head",(-.92,0,.015),(.15,.074,.065),"Twig",fauna)
for s in (-1,1):
    ell("Eye",(-.955,s*.064,.027),(.025,.018,.024),"Eye",fauna,16,8)
    curve("NaturalAntenna",[(-1.04,s*.035,.035),(-1.30,s*.075,.12),(-1.57,s*.12,.15),(-1.73,s*.16,.12)],
          [.010,.008,.006,.002],"TwigJoint",fauna,10)
    for i,x in enumerate((-.61,-.28,.16)):
        leg=empty("Leg_%s_%d"%(s,i),fauna)
        elbow_x=x+(-.24,.19,.40)[i]
        elbow_z=(-.18,-.25,-.19)[i] if s==-1 else (.17,.20,.14)[i]
        end_x=(-1.15,.03,1.0)[i] if s==-1 else (-.95,.44,1.12)[i]
        end_z=(-.60,-.69,-.46)[i] if s==-1 else (.48,.55,.38)[i]
        curve("Femur",[(x,s*.035,0),(elbow_x,s*.21,elbow_z)],
              [.019,.015],"Twig",leg,10)
        ell("Joint",(elbow_x,s*.21,elbow_z),(.025,)*3,"TwigJoint",leg,16,8)
        curve("Tibia",[(elbow_x,s*.21,elbow_z),(end_x,s*.35,end_z),(end_x-.07,s*.38,end_z-.025)],
              [.012,.008,.003],"TwigJoint",leg,10)
controller(root,(-.50,-.026,.075),.105)
save("controlled_stick_insect","Bosque: emboscada entre ramitas; receptor removible sobre tórax")

# Pigeon: natural rounded chest, short bill, upswept paired feather wings.
root=reset("PigeonModel")
fauna=empty("NaturalFauna",root)
ell("Body",(.05,0,.02),(.56,.26,.31),"PigeonGrey",fauna)
ell("Breast",(-.31,-.015,.03),(.30,.245,.33),"PigeonLight",fauna)
ell("Neck",(-.42,0,.30),(.18,.17,.29),"NeckOlive",fauna)
ell("Head",(-.54,0,.55),(.19,.145,.17),"PigeonGrey",fauna)
curve("NaturalBeak",[(-.69,0,.51),(-.81,0,.49),(-.88,0,.47)],
      [.048,.034,.004],"PigeonDark",fauna,16,flatten=.75)
ell("Cere",(-.70,0,.54),(.055,.040,.030),"Cream",fauna,16,8)
for s in (-1,1):
    ell("EyeRing",(-.615,s*.123,.58),(.036,.013,.039),"Ochre",fauna,16,8)
    ell("Eye",(-.619,s*.133,.581),(.023,.009,.027),"Eye",fauna,16,8)
    wing=empty("Wing_L" if s==-1 else "Wing_R",fauna)
    # Far wing is lower: both wings remain readable in a side-view pose.
    height=1.0 if s==-1 else .69
    curve("WingCoverts",[(-.11,s*.20,.18),(.02,s*.39,.47*height),(.25,s*.55,.80*height),(.46,s*.64,.91*height)],
          [.16,.22,.19,.035],"PigeonGrey",wing,16,flatten=.50)
    for i in range(6):
        x=.10+i*.068
        z=(.43+i*.065)*height
        feather=curve("FlightFeather_%d"%i,[(x,s*(.42+i*.025),z),
              (x+.20,s*(.56+i*.025),(1.05-i*.04)*height),
              (x+.46,s*(.60+i*.025),(1.19-i*.072)*height)],
              [.068,.085,.009],"PigeonGrey",wing,12,flatten=.34)
        # Two dark feather bands are pigmentation, never raised hardware.
        feather.data.materials.append(MATERIALS["PigeonDark"])
        feather.data.materials.append(MATERIALS["PigeonLight"])
        for polygon in feather.data.polygons:
            row=polygon.index//12
            if row in (3,5):
                polygon.material_index=1
            elif row==7:
                polygon.material_index=2
    leg=empty("TuckedLeg_%s"%s,fauna)
    curve("Ankle",[(.02,s*.12,-.20),(.16,s*.16,-.34),(.30,s*.16,-.31)],
          [.020,.017,.010],"Paw",leg,10)
    for i in range(3):
        curve("Toe",[(.26,s*.16,-.31),(.37,s*.16+(i-1)*.026,-.32)],
              [.008,.003],"Paw",leg,8)
tail=empty("NaturalTail",fauna)
for i in range(5):
    curve("TailFeather_%d"%i,[(.39,(i-2)*.048,.01),(.75,(i-2)*.057,-.08),(.95,(i-2)*.075,-.12)],
          [.047,.049,.009],"PigeonDark",tail,12,flatten=.40)
controller(root,(-.43,-.155,.39),.105)
save("controlled_pigeon","Residencial: vuelo de cruce; dos alas y patas recogidas, receptor en nuca")

# Mouse: four natural paws, round ears, pointed snout and long flexible tail.
root=reset("MouseModel")
fauna=empty("NaturalFauna",root)
ell("Body",(.12,0,-.02),(.59,.27,.31),"MouseFur",fauna)
ell("Belly",(.07,-.015,-.16),(.46,.235,.17),"MouseBelly",fauna)
ell("Head",(-.43,0,.03),(.28,.23,.23),"MouseFur",fauna)
curve("Snout",[(-.53,0,.025),(-.70,0,-.045),(-.82,0,-.085)],
      [.17,.11,.028],"MouseFur",fauna,20,flatten=.90)
ell("Nose",(-.823,0,-.084),(.041,.05,.034),"EarPink",fauna,16,8)
for s in (-1,1):
    ear=empty("Ear_%s"%s,fauna)
    ell("EarRim",(-.34,s*.18,.31),(.155,.065,.175),"MouseFur",ear)
    ell("EarInterior",(-.355,s*.228,.325),(.114,.023,.130),"EarPink",ear)
    ell("Eye",(-.58,s*.19,.092),(.038,.018,.043),"Eye",fauna,16,8)
    for i in range(2):
        curve("NaturalWhisker",[(-.74,s*.071,-.05),(-.81,s*.23,-.035+i*.054),(-.88,s*.34,-.02+i*.072)],
              [.0045,.003,.0015],"MouseBelly",fauna,6)
    for i,x in enumerate((-.27,.47)):
        leg=empty("Leg_%s_%d"%(s,i),fauna)
        ell("Haunch",(x,s*.16,-.19),(.12 if i else .075,.09,.14),"MouseFur",leg,20,10)
        ell("Paw",(x-.08,s*.19,-.315),(.15,.067,.045),"Paw",leg,20,10)
curve("NaturalTail",[(.58,0,-.065),(.98,.035,-.13),(1.38,.08,-.22),(1.70,.11,-.12),(1.91,.15,.10)],
      [.051,.039,.029,.019,.004],"Paw",fauna,14)
controller(root,(-.13,-.115,.245),.13)
save("controlled_mouse","Residencial y jardín: amenaza de suelo liberable con orejas, cuatro patas y cola")

# Human-sized bottle cap, concave, painted outside, warm metal inside.
# A continuous ring mesh makes a closed hollow shell, no interior black hole.
root=reset("BottleCapModel")
prop=empty("HumanProp",root)
segments=64
profile=[(.65,-.12),(.72,-.065),(.72,.16),(.665,.195),(.615,.155),(.615,-.025)]
vertices=[]
for radius,z in profile:
    for j in range(segments):
        angle=j*math.tau/segments
        vertices.append((radius*math.cos(angle),radius*math.sin(angle),z))
faces=[]
for i in range(len(profile)-1):
    for j in range(segments):
        a=i*segments+j
        faces.append((a,i*segments+(j+1)%segments,(i+1)*segments+(j+1)%segments,a+segments))
# Triangle fans with one center vertex each avoid degenerate center quads.
lower=len(vertices)
vertices.append((0,0,-.12))
upper=len(vertices)
vertices.append((0,0,-.025))
for j in range(segments):
    faces.append((lower,(j+1)%segments,j))
for j in range(segments):
    a=(len(profile)-1)*segments+j
    b=(len(profile)-1)*segments+(j+1)%segments
    faces.append((upper,a,b))
cap=mesh("HollowCap",vertices,faces,"CapPaint",prop)
cap.data.materials.append(MATERIALS["CapInside"])
for polygon in cap.data.polygons:
    if 3*segments<=polygon.index<5*segments or polygon.index>=6*segments:
        polygon.material_index=1
torus("RolledRim",(0,0,.177),.669,.029,"CapInside",prop)
for j in range(28):
    angle=j*math.tau/28
    rib=ell("GripRib_%02d"%j,(.718*math.cos(angle),.718*math.sin(angle),.035),(.022,.029,.108),"CapPaint",prop,12,8)
    rib.rotation_euler.z=angle
save("giant_bottle_cap","Residencial: tapa humana cóncava, plataforma o refugio a escala de Bee")

(OUT/"manifest.json").write_text(json.dumps({"version":4,"original_assets":True,"assets":STATS},indent=2,ensure_ascii=False),encoding="utf-8")
print("FUTURE_BIOMES_V04_STATS",json.dumps(STATS))

