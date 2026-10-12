"""Four original Blender/GLB fauna POCs: firefly, ladybird, owl and manta ray.

Run Blender --background --python tools/art/create_future_biomes_v03.py.
X horizontal, -X forward, Blender Z -> Godot Y. Colours authored in sRGB.
No external assets. Fauna and removable devices are separate subtrees.
"""
from pathlib import Path
import bpy, bmesh, math, json
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/models/future_biomes_v03"
SRC = ROOT / "art_source/blender/future_biomes_v03"
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

def insect_legs(parent, xs, spread=.40):
    for s in (-1,1):
        for i,x in enumerate(xs):
            leg=empty("Leg_%s_%d"%(s,i),parent)
            curve("Upper",[(x,s*.08,-.015),(x-.08+i*.045,s*.21,-.16)],
                [.015,.011],"Chitin",leg,8)
            curve("Lower",[(x-.08+i*.045,s*.21,-.16),(x+.04,s*spread,-.28+i*.025)],
                [.011,.004],"DarkNatural",leg,8)

# Firefly: six legs, paired lifted elytra, two membrane wings and warm lantern.
root=reset("FireflyModel")
fauna=empty("NaturalFauna",root)
ell("Thorax",(-.14,0,.015),(.18,.135,.145),"FireflyThorax",fauna)
ell("Head",(-.36,0,-.015),(.13,.12,.105),"Chitin",fauna)
for i in range(5):
    ell("Abdomen_%d"%i,(.055+i*.105,0,-.015),(.105,.10-i*.006,.09-i*.004),
        "NaturalLantern" if i>2 else "Chitin",fauna,20,10)
for s in (-1,1):
    ell("Eye",(-.40,s*.092,.018),(.058,.027,.063),"Eye",fauna,16,8)
    curve("Antenna",[(-.43,s*.047,.041),(-.54,s*.12,.16),(-.62,s*.16,.20)],
        [.010,.008,.003],"Chitin",fauna,8)
    cover=ell("Elytron_L" if s<0 else "Elytron_R",(.09,s*.17,.20),(.33,.095,.062),"FireflyBack",fauna)
    cover.rotation_euler.y=-.35
    wing=ell("Wing_L" if s<0 else "Wing_R",(.24,s*.29,.23),(.42,.14,.016),"Wing",fauna)
    wing.rotation_euler.y=-.50 if s<0 else -.28
    wing.rotation_euler.z=s*.35
insect_legs(fauna,[-.19,-.075,.045])
controller(root,(-.16,0,.185),.105)
save("controlled_firefly","Flying firefly visual, warm natural lantern and removable thorax receiver")

# Ladybird: red spotted elytra remain natural and distinct from the receiver.
root=reset("LadybirdModel")
fauna=empty("NaturalFauna",root)
ell("Abdomen",(.11,0,.015),(.36,.21,.17),"DarkNatural",fauna)
ell("Pronotum",(-.23,0,.07),(.18,.18,.14),"LadybirdCream",fauna)
ell("Head",(-.40,0,.04),(.14,.145,.12),"Chitin",fauna)
for s in (-1,1):
    elytron=empty("Elytron_L" if s<0 else "Elytron_R",fauna)
    elytron.location=(.12,s*.085,.13)
    elytron.rotation_euler.x=s*.48
    ell("RedShell",(0,s*.11,.01),(.36,.16,.24),"LadybirdRed",elytron)
    for i,x in enumerate([-.19,.015,.21]):
        y=s*.22
        z=.01+.24*math.sqrt(max(.1,1-(x/.36)**2-((y-s*.11)/.16)**2))
        spot=ell("NaturalSpot_%s_%d"%(s,i),(x,y,z+.003),(.063,.050,.008),"DarkNatural",elytron,16,8)
        normal=Vector((x/(.36**2),(y-s*.11)/(.16**2),(z-.01)/(.24**2)))
        spot.rotation_mode="QUATERNION"
        spot.rotation_quaternion=normal.to_track_quat("Z","Y")
    ell("Eye",(-.44,s*.119,.079),(.052,.023,.05),"Eye",fauna,16,8)
    ell("CreamCheek",(-.32,s*.153,.09),(.049,.012,.049),"LadybirdCream",fauna,16,8)
    curve("Antenna",[(-.46,s*.065,.12),(-.56,s*.11,.20),(-.59,s*.14,.22)],
        [.011,.008,.004],"Chitin",fauna,8)
    wing=ell("Wing_L" if s<0 else "Wing_R",(.30,s*.37,.26),(.48,.14,.015),"Wing",fauna)
    wing.rotation_euler.y=-.48 if s<0 else -.30
    wing.rotation_euler.z=s*.33
insect_legs(fauna,[-.22,-.06,.10],.31)
controller(root,(-.24,0,.235),.095)
save("controlled_flying_ladybird","Flying ladybird visual, six natural spots, six legs and removable receiver")

# Owl in a banked flight pose: two broad wings with rounded feather groups.
root=reset("OwlModel")
fauna=empty("NaturalFauna",root)
ell("Body",(.02,0,0),(.56,.29,.37),"OwlBack",fauna)
ell("Breast",(-.20,-.23,-.045),(.34,.093,.28),"OwlBreast",fauna)
ell("Head",(-.52,0,.29),(.29,.25,.29),"OwlBack",fauna)
for s in (-1,1):
    ell("FacialDisc",(-.64,s*.14,.31),(.19,.115,.225),"OwlFace",fauna)
    ell("Iris",(-.73,s*.197,.365),(.086,.029,.090),"Ochre",fauna,20,10)
    ell("Pupil",(-.759,s*.217,.365),(.049,.014,.055),"Eye",fauna,16,8)
    ell("EyeGlint",(-.772,s*.23,.39),(.013,.005,.014),"Cream",fauna,12,6)
    curve("BrowTuft",[(-.39,s*.14,.47),(-.33,s*.16,.62)],
        [.056,.003],"OwlFeather",fauna,12)
    wing=empty("Wing_L" if s<0 else "Wing_R",fauna)
    wing.location=(.02,s*.20,.075)
    wing.rotation_euler.x=-.78 if s<0 else -.26
    ell("WingCoverts",(.10,s*.39,0),(.36,.49,.105),"OwlBack",wing,24,12)
    for i in range(6):
        feather=ell("PrimaryFeather_%s_%d"%(s,i),(.30+i*.04,s*(.64+i*.115),-.025),
            (.36-i*.020,.095,.034),"OwlFeather" if i%2==0 else "OwlBack",wing,16,8)
        feather.rotation_euler.z=s*.28
    for i in range(3):
        ell("SecondaryCoverts_%s_%d"%(s,i),(.08,s*(.26+i*.17),.073),(.21,.105,.044),"OwlFeather",wing,16,8)
    leg=empty("TuckedLeg_L" if s<0 else "TuckedLeg_R",fauna)
    curve("Tarsus",[(.11,s*.15,-.26),(.21,s*.17,-.38)],[.039,.025],"Ochre",leg,10)
    for j in range(3):
        curve("Claw_%s_%d"%(s,j),[(.20,s*.17+(j-1)*.025,-.36),(.08,s*.17+(j-1)*.025,-.43),(.04,s*.17+(j-1)*.025,-.40)],
            [.018,.010,.002],"DarkNatural",leg,8)
curve("HookedBeak",[(-.75,0,.25),(-.88,0,.20),(-.84,0,.12)],[.066,.042,.003],"Ochre",fauna,12)
for i in range(3):
    tail=ell("TailFeather_%d"%i,(.61,(i-1)*.09,-.12),(.25,.065,.035),"OwlFeather",fauna,16,8)
    tail.rotation_euler.y=.18
controller(root,(-.32,-.265,.48),.14)
save("controlled_owl","Large airborne owl threat visual, natural paired wings and external dorsal receiver")

# Manta: broad pectoral fins, paired front cephalic lobes, long thin tail.
root=reset("MantaRayModel")
fauna=empty("NaturalFauna",root)
body=ell("Body",(-.10,0,0),(.60,.44,.105),"RayBack",fauna,32,16)
body.data.materials.append(MATERIALS["RayBelly"])
for p in body.data.polygons:
    if p.center.z<0:
        p.material_index=1
for s in (-1,1):
    vertices,faces=[],[]
    spans,sides=22,20
    for i in range(spans+1):
        t=i/spans
        y=s*(.15+1.45*t)
        center_x=.025+.39*t
        width=.61*((1-t)**.60)+.012
        center_z=math.sin(t*math.pi*.85)*(.32 if s<0 else -.14)
        thickness=.063*(1-t)+.006
        for j in range(sides):
            a=j*math.tau/sides
            vertices.append((center_x+math.cos(a)*width,y,center_z+math.sin(a)*thickness))
    for i in range(spans):
        for j in range(sides):
            a=i*sides+j
            faces.append((a,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,a+sides))
    faces += [tuple(reversed(range(sides))),tuple(range(spans*sides,(spans+1)*sides))]
    fin=mesh("PectoralFin_L" if s<0 else "PectoralFin_R",vertices,faces,"RayBack",fauna)
    fin.data.materials.append(MATERIALS["RayBelly"])
    for p in fin.data.polygons:
        if p.normal.z<-.15:
            p.material_index=1
    ell("EyeSocket",(-.53,s*.29,.063),(.088,.057,.041),"RayBack",fauna,20,10)
    ell("Eye",(-.57,s*.318,.080),(.032,.016,.027),"Eye",fauna,16,8)
    curve("CephalicFin_L" if s<0 else "CephalicFin_R",[(-.48,s*.18,-.015),(-.73,s*.23,-.012),(-.86,s*.19,.030),(-.80,s*.13,.068)],
        [.074,.061,.043,.014],"RayBack",fauna,12,.55)
curve("NaturalTail",[(.43,0,0),(.87,.015,-.015),(1.42,.028,.05),(2.10,.043,.16)],
    [.032,.023,.015,.003],"RayBack",fauna,12)
curve("Mouth",[(-.61,-.09,-.052),(-.64,0,-.075),(-.61,.09,-.052)],[.007,.009,.007],"DarkNatural",fauna,8)
controller(root,(-.46,0,.155),.135)
save("controlled_manta_ray","Marine manta ray visual, broad natural fins, cephalic lobes and removable dorsal clamp")

(OUT/"manifest.json").write_text(json.dumps({"version":3,"original_assets":True,"assets":STATS},indent=2),encoding="utf-8")
print("FUTURE_BIOMES_V03_STATS",json.dumps(STATS))


