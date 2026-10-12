"""Four original Blender/GLB POCs: forest fauna, alien carrier and relay.

Run Blender --background --python tools/art/create_future_biomes_v02.py.
X horizontal, -X forward, Blender Z -> Godot Y. Colours authored in sRGB.
No external assets. Fauna and removable devices are separate subtrees.
"""
from pathlib import Path
import bpy, bmesh, math, json
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/models/future_biomes_v02"
SRC = ROOT / "art_source/blender/future_biomes_v02"
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

# Forest fauna: recognisable stag beetle, paired branched mandibles, six legs.
root = reset("StagBeetleModel")
fauna = empty("NaturalFauna",root)
ell("Abdomen",(.36,0,.46),(.72,.35,.34),"Chitin",fauna)
for s in (-1,1):
    ell("Elytron_L" if s<0 else "Elytron_R",(.39,s*.17,.53),(.68,.195,.30),"Elytra",fauna)
ell("Thorax",(-.39,0,.48),(.30,.29,.28),"Chestnut",fauna)
ell("Head",(-.77,0,.43),(.23,.24,.20),"Chitin",fauna)
for s in (-1,1):
    ell("Eye",(-.82,s*.216,.50),(.067,.035,.065),"Eye",fauna,16,8)
    curve("Antenna",[(-.88,s*.14,.48),(-1.04,s*.32,.51),(-1.10,s*.40,.57)],[.016,.013,.012],"DarkNatural",fauna,10)
    ell("AntennaClub",(-1.10,s*.40,.57),(.07,.035,.03),"Ochre",fauna,16,8)
    horn=[(-.90,s*.14,.44),(-1.18,s*.22,.51),(-1.46,s*.25,.63),(-1.66,s*.18,.72),(-1.72,s*.07,.70)]
    curve("Mandible_L" if s<0 else "Mandible_R",horn,[.09,.084,.065,.039,.004],"Chestnut",fauna,16)
    curve("MandibleFork",[(-1.31,s*.24,.56),(-1.43,s*.12,.75),(-1.48,s*.08,.84)],[.045,.025,.003],"Chestnut",fauna,12)
    curve("MandibleTooth",[(-1.11,s*.20,.49),(-1.21,s*.08,.60)],[.04,.004],"Chitin",fauna,10)
    for i,(x,spread) in enumerate([(-.46,-.34),(-.02,.06),(.48,.39)]):
        leg=empty("Leg_%s_%d"%(s,i),fauna)
        curve("Upper",[(x,s*.20,.38),(x+spread*.45,s*.38,.23),(x+spread,s*.49,.13)],[.045,.034,.025],"Chitin",leg,10)
        curve("Lower",[(x+spread,s*.49,.13),(x+spread+.12,s*.61,.035),(x+spread-.02,s*.68,.026)],[.024,.017,.009],"DarkNatural",leg,10)
controller(root,(-.35,0,.79),.18)
save("controlled_stag_beetle","Forest armoured fauna visual, external thorax controller")

# Forest fauna: snail with continuous warm shell, spiral and two eye stalks.
root=reset("SnailModel")
fauna=empty("NaturalFauna",root)
ell("Foot",(-.05,0,.10),(1.08,.28,.10),"Foot",fauna)
ell("Body",(-.09,0,.22),(.97,.24,.18),"SnailBody",fauna)
ell("Shell",(.24,0,.75),(.55,.32,.55),"SnailShell",fauna,32,18)
spiral=[]
for i in range(100):
    t=i/99
    a=t*math.tau*1.65+.3
    radius=.025+.477*t
    spiral.append((.24+math.cos(a)*radius,-.32*math.sqrt(max(.05,1-(radius/.55)**2))-.011,.75+math.sin(a)*radius))
curve("NaturalShellSpiral",spiral,[.014+.008*i/99 for i in range(100)],"Spiral",fauna,8,interpolate=False)
ell("Head",(-.82,0,.32),(.23,.22,.18),"SnailBody",fauna)
for s in (-1,1):
    curve("EyeStalk",[(-.87,s*.10,.39),(-1.00,s*.15,.65),(-1.07,s*.17,.84)],[.035,.023,.014],"SnailBody",fauna,12)
    ell("EyeTip",(-1.07,s*.17,.84),(.041,)*3,"Eye",fauna,16,8)
    curve("LowerTentacle",[(-.95,s*.12,.28),(-1.13,s*.21,.34),(-1.22,s*.23,.37)],[.026,.018,.005],"SnailBody",fauna,10)
controller(root,(.35,0,1.30),.15)
save("controlled_woodland_snail","Forest slow fauna visual, intact natural shell and removable top clamp")

# Alien technology: a broad cargo carrier distinct from V01's small skimmer.
root=reset("AlienSeedCarrierModel")
ell("LowerHull",(0,0,.02),(1.07,.37,.25),"Shell",root,32,16)
ell("UpperArmour",(.01,0,.22),(.80,.40,.27),"Shell",root,32,16)
ell("SideCyanViewport",(-.43,-.34,.17),(.31,.057,.13),"Cyan",root)
ell("OtherCyanViewport",(-.43,.34,.17),(.31,.057,.13),"Cyan",root)
curve("NoseRail",[(-1.19,0,-.09),(-1.03,0,.12),(-.66,0,.39),(-.08,0,.50),(.42,0,.40)],[.006,.06,.08,.075,.026],"ShellEdge",root,16,.6)
for s in (-1,1):
    pod=empty("CargoPod_L" if s<0 else "CargoPod_R",root)
    ell("CargoShell",(.32,s*.34,-.28),(.58,.20,.22),"Shell",pod)
    curve("CargoRail",[(-.25,s*.40,-.30),(-.01,s*.51,-.15),(.37,s*.51,-.13),(.73,s*.43,-.27)],
        [.02,.05,.05,.015],"ShellEdge",pod,12,.7)
    ell("VioletCargoLatch",(.17,s*.51,-.19),(.063,.036,.063),"Violet",pod,16,8)
    curve("SweptWing",[(-.56,s*.28,.11),(-.22,s*.52,.17),(.35,s*.77,.13),(.95,s*.88,-.07)],
        [.016,.14,.18,.005],"Shell",root,16,.6)
    curve("CyanWingTrace",[(.15,s*.78,.19),(.48,s*.84,.12),(.76,s*.91,.02)],[.009,.016,.004],"Cyan",root,8)
    curve("ReceiverProng",[(.41,s*.17,.39),(.61,s*.20,.59),(.78,s*.21,.65)],[.027,.017,.007],"ShellEdge",root,10)
    ell("VioletReceiver",(.78,s*.21,.65),(.042,)*3,"Violet",root,16,8)
ell("EngineShroud",(.98,0,.03),(.20,.25,.25),"Shell",root)
torus("RearEngineRing",(1.17,0,.03),.235,.055,"ShellEdge",root,(0,math.pi/2,0))
ell("RearEngineLens",(1.20,0,.03),(.035,.19,.19),"Cyan",root)
save("alien_seed_carrier","Alien cargo ship visual, swept wings and twin external cargo pods")

# Portable alien signal relay: separate clamps, shielded core, no fauna.
root=reset("AlienSignalRelayModel")
ell("BaseShell",(0,0,.15),(.32,.27,.16),"Shell",root)
ell("CoreHousing",(0,0,.42),(.25,.23,.28),"Shell",root)
ell("CyanSignalCore",(-.02,-.15,.47),(.17,.125,.22),"Cyan",root)
curve("CoreShield",[(-.29,0,.23),(-.24,0,.59),(-.07,0,.77),(.15,0,.70),(.26,0,.38)],
    [.028,.053,.055,.044,.018],"ShellEdge",root,16,.7)
clamps=empty("MountingClamps",root)
for i in range(3):
    a=i*math.tau/3+.2
    ux,uy=math.cos(a),math.sin(a)
    curve("RemovableClamp_%d"%i,[(ux*.16,uy*.16,.24),(ux*.37,uy*.37,.18),(ux*.45,uy*.45,.03),(ux*.54,uy*.54,.012)],
        [.044,.058,.036,.010],"Shell",clamps,12)
    ell("VioletClampJoint",(ux*.32,uy*.32,.21),(.045,)*3,"Violet",clamps,16,8)
for s in (-1,1):
    curve("ReceiverAntenna",[(.09,s*.12,.61),(.23,s*.16,.81),(.26,s*.19,.94)],
        [.022,.013,.007],"Shell",root,10)
    ell("VioletAntennaTip",(.26,s*.19,.94),(.042,)*3,"Violet",root,16,8)
save("alien_signal_relay","Portable alien control relay, removable mounting clamps and protected cyan emitter")

(OUT/"manifest.json").write_text(json.dumps({"version":2,"original_assets":True,"assets":STATS},indent=2),encoding="utf-8")
print("FUTURE_BIOMES_V02_STATS",json.dumps(STATS))
