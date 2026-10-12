"""Six original visual POCs. Run with Blender --background --python this_file.

Blender X = gameplay X, Z = up, -X = creature forward. GLB -> Godot X/Y.
No external models, textures or Python dependencies. Every control device is a
separate removable subtree. Exported PBR colours are styled in Godot by Style C.
"""
from pathlib import Path
import bpy
import math
import json
import bmesh
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/models/future_biomes_v01"
SRC = ROOT / "art_source/blender/future_biomes_v01"
for folder in (OUT, SRC):
    folder.mkdir(parents=True, exist_ok=True)
(SRC / ".gdignore").write_text("", encoding="utf-8")
bpy.context.preferences.filepaths.save_version = 0
STATS = []
MATS = {}
PALETTE = {
    "Shell": (0.20, 0.22, 0.27), "ShellEdge": (0.30, 0.32, 0.37),
    "Cyan": (0.15, 0.95, 1.0), "Violet": (0.62, 0.22, 0.95),
    "Chitin": (0.27, 0.13, 0.085), "Abdomen": (0.47, 0.25, 0.13),
    "Ochre": (0.70, 0.44, 0.16), "Eye": (0.075, 0.055, 0.035),
    "Wing": (0.72, 0.69, 0.57), "Cream": (0.79, 0.73, 0.47),
    "FishBack": (0.30, 0.40, 0.16), "FishSide": (0.58, 0.65, 0.29),
    "FishBelly": (0.83, 0.78, 0.49), "Fin": (0.73, 0.39, 0.15),
    "Stripe": (0.23, 0.31, 0.11), "Leaf": (0.27, 0.48, 0.10),
    "LeafLight": (0.47, 0.61, 0.19), "LeafDark": (0.14, 0.30, 0.08),
    "Stem": (0.40, 0.48, 0.13), "Cattail": (0.39, 0.20, 0.09),
    "Petal": (0.87, 0.66, 0.53), "PetalInner": (0.89, 0.80, 0.64),
    "Pollen": (0.85, 0.60, 0.14), "Rock": (0.39, 0.31, 0.25),
    "RockLight": (0.52, 0.44, 0.34), "RockDark": (0.25, 0.21, 0.19),
}

def linear(c):
    return c/12.92 if c <= .04045 else ((c+.055)/1.055)**2.4

def interpolated(points, values, steps=4):
    """Catmull-Rom sections avoid faceted bends in swept mid-poly forms."""
    out_points, out_values = [], []
    for i in range(len(points)-1):
        p0,p1,p2,p3=[Vector(points[max(0,min(len(points)-1,j))]) for j in (i-1,i,i+1,i+2)]
        for j in range(steps):
            t=j/steps
            out_points.append(tuple(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)))
            out_values.append(values[i]*(1-t)+values[i+1]*t)
    return out_points+[points[-1]],out_values+[values[-1]]


def reset(name):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for material in list(bpy.data.materials):
        bpy.data.materials.remove(material)
    MATS.clear()
    for key, rgb in PALETTE.items():
        rgb = tuple(linear(c) for c in rgb)
        m = bpy.data.materials.new(key)
        m.diffuse_color = (*rgb, 1)
        m.use_nodes = True
        bs = next((n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if bs is None:
            bs = m.node_tree.nodes.new("ShaderNodeBsdfPrincipled")
            output = m.node_tree.nodes.new("ShaderNodeOutputMaterial")
            m.node_tree.links.new(bs.outputs["BSDF"], output.inputs["Surface"])
        bs.inputs["Base Color"].default_value = (*rgb, 1)
        bs.inputs["Roughness"].default_value = 0.86
        m.use_backface_culling = True
        if key in ("Cyan", "Violet"):
            bs.inputs["Emission Color"].default_value = (*rgb, 1)
            bs.inputs["Emission Strength"].default_value = 1.3
        if key == "Wing":
            m.use_backface_culling = False
        MATS[key] = m
    bpy.context.scene.unit_settings.system = "METRIC"
    return empty(name)


def empty(name, parent=None):
    o = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(o)
    o.parent = parent
    return o


def finish(o, name, mat, parent, smooth=True):
    o.name = name
    o.data.materials.append(MATS[mat])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.parent = parent
    for p in o.data.polygons:
        p.use_smooth = smooth
    return o


def ell(name, pos, scale, mat, parent, segments=24, rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=pos)
    o = bpy.context.object
    o.scale = scale
    return finish(o, name, mat, parent)


def rod(name, a, b, radius, mat, parent, tip=None):
    a, b = Vector(a), Vector(b)
    d = b-a
    bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=radius,
        radius2=radius if tip is None else tip, depth=d.length, location=(a+b)*0.5)
    o = bpy.context.object
    o.rotation_mode = "QUATERNION"
    o.rotation_quaternion = d.to_track_quat("Z", "Y")
    return finish(o, name, mat, parent)


def mesh(name, verts, faces, mat, parent, smooth=True):
    me = bpy.data.meshes.new(name+"Mesh")
    me.from_pydata(verts, [], faces)
    me.update()
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    o.parent = parent
    o.data.materials.append(MATS[mat])
    for p in me.polygons:
        p.use_smooth = smooth
    return o


def blade(name, points, radii, mat, parent, sides=12, flatten=1):
    """Smooth, tapered closed tube along a path, used for fins and leaves."""
    points,radii = interpolated(points,radii)
    verts, faces = [], []
    for i, point in enumerate(points):
        tangent = Vector(points[min(i+1, len(points)-1)]) - Vector(points[max(0,i-1)])
        tangent.normalize()
        axis = Vector((0,1,0))
        if abs(tangent.dot(axis)) > 0.9:
            axis = Vector((1,0,0))
        u = tangent.cross(axis).normalized()
        v = tangent.cross(u).normalized()
        for j in range(sides):
            a = j*math.tau/sides
            p = Vector(point) + radii[i]*(math.cos(a)*u + math.sin(a)*v*flatten)
            verts.append(tuple(p))
    for i in range(len(points)-1):
        for j in range(sides):
            k = i*sides+j
            faces.append((k,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,k+sides))
    faces.extend([tuple(reversed(range(sides))),tuple(range((len(points)-1)*sides,len(points)*sides))])
    return mesh(name, verts, faces, mat, parent)


def device(parent, pos, size):
    """All technology remains inside a single removable node."""
    tech = empty("AlienControlDevice", parent)
    x,y,z = pos
    ell("ControlShell", pos, (size, size*.75, size*.43), "Shell", tech)
    ell("CyanLens", (x-.03,y,z+size*.31), (size*.68,size*.50,size*.22), "Cyan", tech)
    for s in (-1,1):
        rod("ExternalClamp", (x,y+s*size*.54,z), (x+.05,y+s*size*.88,z-size*.28),
            size*.10, "ShellEdge", tech)
        ell("VioletNode", (x+size*.42,y+s*size*.67,z+.01),
            (size*.14,)*3, "Violet", tech,16,8)
    rod("Receiver", (x+size*.52,y,z+size*.18),(x+size*.97,y,z+size*.79),size*.07,"Shell",tech)
    ell("ReceiverTip",(x+size*.97,y,z+size*.79),(size*.13,)*3,"Violet",tech,16,8)
    return tech


def save(key, root, role):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(key+".blend")))
    bpy.ops.export_scene.gltf(filepath=str(OUT/(key+".glb")), export_format="GLB",
        use_selection=True, export_yup=True, export_animations=False)
    objs = [o for o in bpy.context.scene.objects if o.type=="MESH"]
    pts = [o.matrix_world@Vector(v) for o in objs for v in o.bound_box]
    STATS.append({"id":key,"role":role,"triangles":sum(len(p.vertices)-2 for o in objs for p in o.data.polygons),
        "mesh_objects":len(objs),"dimensions_xyz_blender":[round(max(p[i] for p in pts)-min(p[i] for p in pts),3) for i in range(3)],
        "source":str((SRC/(key+".blend")).relative_to(ROOT)).replace("\\","/"),
        "glb":str((OUT/(key+".glb")).relative_to(ROOT)).replace("\\","/"),
        "forward":"-X","up_godot":"+Y","rigged":False})


# LAKE: natural mosquito, six legs, two wings, halteres, removable dorsal clamp.
r = reset("MosquitoModel")
body = empty("NaturalFauna",r)
ell("Thorax",(-.06,0,.03),(.22,.12,.15),"Chitin",body)
ell("Head",(-.33,0,.06),(.12,.11,.12),"Ochre",body)
for i in range(6):
    ell("Abdomen_%02d"%i,(.18+i*.10,0,-.01-i*.016),(.105,.10-i*.009,.10-i*.01),
        "Abdomen" if i%2==0 else "Chitin",body,20,10)
rod("Proboscis",(-.42,0,.04),(-.91,0,-.025),.016,"Chitin",body,.008)
for s in (-1,1):
    ell("Eye",(-.36,s*.087,.08),(.070,.033,.073),"Eye",body,20,10)
    rod("Antenna",(-.39,s*.04,.15),(-.62,s*.10,.31),.009,"Chitin",body,.004)
    for i in range(3):
        a=(-.13+i*.12,s*.09,0)
        b=(-.35+i*.27,s*.25,-.22-i*.03)
        c=(-.54+i*.49,s*.43,-.47+i*.035)
        rod("Leg_%s_%d_Upper"%(s,i),a,b,.017,"Chitin",body,.012)
        rod("Leg_%s_%d_Lower"%(s,i),b,c,.012,"Chitin",body,.006)
    wing = ell("Wing_L" if s<0 else "Wing_R",(.26,s*.28,.23),(.40,.105,.018),"Wing",body)
    wing.rotation_euler.z = s*.38
    wing.rotation_euler.y = -.42 if s < 0 else -.25
    rod("HalterStem",(.10,s*.12,.01),(.21,s*.20,.03),.008,"Ochre",body)
    ell("Halter",(.21,s*.20,.03),(.018,)*3,"Ochre",body,12,6)
device(r,(-.02,0,.21),.13)
save("controlled_mosquito",r,"Lake aerial swarmer visual; external dorsal device")

# LAKE: recognisable perch silhouette, warm fins, natural olive stripes.
r = reset("PerchModel")
body = empty("NaturalFauna",r)
profiles=[(-1.02,.035,.05),(-.91,.20,.24),(-.65,.32,.40),(-.26,.37,.47),(.20,.30,.40),(.58,.16,.23),(.81,.055,.105)]
profiles,_ = interpolated(profiles,[1]*len(profiles),4)
verts,faces=[],[]
sides=24
for x,ry,rz in profiles:
    for j in range(sides):
        a=j*math.tau/sides
        verts.append((x,math.cos(a)*ry,math.sin(a)*rz))
for i in range(len(profiles)-1):
    for j in range(sides):
        faces.append((i*sides+j,(i+1)*sides+j,(i+1)*sides+(j+1)%sides,i*sides+(j+1)%sides))
faces += [tuple(range(sides)),tuple(reversed(range((len(profiles)-1)*sides,len(profiles)*sides)))]
o=mesh("FishBody",verts,faces,"FishSide",body)
for key in ("FishBack","FishBelly","Stripe"):
    o.data.materials.append(MATS[key])
for p in o.data.polygons:
    z=sum(o.data.vertices[v].co.z for v in p.vertices)/len(p.vertices)
    p.material_index=1 if z>.18 else (2 if z<-.18 else 0)
    x=sum(o.data.vertices[v].co.x for v in p.vertices)/len(p.vertices)
    if any(abs(x-stripe)<.055 for stripe in (-.42,-.03,.34,.59)) and -.17<z<.30:
        p.material_index=3
for s in (-1,1):
    ell("EyeSocket",(-.78,s*.223,.10),(.16,.044,.15),"Ochre",body)
    ell("Eye",(-.81,s*.256,.11),(.093,.018,.098),"Eye",body)
    ell("EyeGlint",(-.84,s*.275,.15),(.022,.007,.025),"Cream",body,12,6)
    blade("GillLine",[(-.56,s*.28,.20),(-.48,s*.337,0),(-.56,s*.27,-.19)],[.015,.018,.009],"FishBack",body,8)
    fin=ell("PectoralFin",(-.23,s*.34,-.17),(.29,.04,.095),"Fin",body)
    fin.rotation_euler.y=-.4
    blade("TailLobe",[(.75,0,0),(.94,0,s*.13),(1.24,0,s*.32),(1.43,0,s*.35)],
        [.07,.13,.14,.006],"Fin",body,16,.22)
rod("MouthLine",(-1.015,-.055,-.055),(-1.015,.055,-.055),.015,"FishBack",body)
blade("DorsalFin",[(-.48,0,.37),(-.18,0,.69),(.16,0,.66),(.50,0,.26)],[.025,.18,.16,.008],"Fin",body,16,.15)
blade("LowerFin",[(.10,0,-.33),(.28,0,-.54),(.58,0,-.21)],[.015,.12,.008],"Fin",body,12,.18)
device(r,(-.60,0,.38),.20)
save("controlled_perch",r,"Lake underwater threat visual; dorsal detachable receiver")

# SPACE: independent alien machine, swept shell lobes and external energy lenses.
r=reset("OrbitalSkimmerModel")
ell("CoreShell",(0,0,0),(.51,.29,.25),"Shell",r)
ell("CyanCore",(-.09,-.17,.12),(.28,.17,.18),"Cyan",r)
blade("NoseRail",[(-.70,0,-.05),(-.49,0,.26),(-.12,0,.36),(.31,0,.23)],
    [.008,.085,.11,.028],"ShellEdge",r,16,.70)
for s in (-1,1):
    blade("ScytheFin",[(-.53,s*.17,-.12),(-.20,s*.39,.08),(.28,s*.55,.12),(.66,s*.58,-.14),(.79,s*.54,-.38)],
        [.015,.12,.16,.09,.005],"Shell",r,16,.68)
    blade("CyanFinChannel",[(-.08,s*.475,.11),(.25,s*.63,.11),(.56,s*.65,-.11)],
        [.011,.020,.005],"Cyan",r,10)
    ell("VioletJoint",(.31,s*.46,.15),(.065,)*3,"Violet",r,20,10)
    blade("ReceiverProng",[(.19,s*.12,.22),(.39,s*.16,.45),(.63,s*.19,.60)],
        [.035,.022,.012],"ShellEdge",r)
    ell("VioletReceiver",(.63,s*.19,.60),(.053,)*3,"Violet",r,16,8)
ell("RearThruster",(.45,0,-.04),(.12,.17,.12),"ShellEdge",r)
ell("ThrusterLens",(.53,0,-.04),(.045,.11,.07),"Cyan",r)
save("orbital_skimmer",r,"Space alien interceptor visual; no animal anatomy")

# LAKE environment: sculpted closed leaf with genuine wedge notch, warm lotus.
r=reset("LilyPadModel")
n=48
angles=[math.radians(22)+(math.tau-math.radians(44))*i/n for i in range(n+1)]
verts=[(0,0,.012)]
for radius in (.35,.70,1.0):
    for a in angles:
        rr=radius*(1+.025*math.sin(5*a))
        verts.append((math.cos(a)*rr,math.sin(a)*rr*.81,.018+radius*.028*math.cos(3*a)))
faces=[(0,1+i,2+i) for i in range(n)]
for ring in range(2):
    for i in range(n):
        a=1+ring*(n+1)+i
        faces.append((a,a+n+1,a+n+2,a+1))
leaf=mesh("NotchedLeaf",verts,faces,"Leaf",r)
solid=leaf.modifiers.new("LeafThickness","SOLIDIFY")
solid.thickness=.035
bpy.context.view_layer.objects.active=leaf
bpy.ops.object.modifier_apply(modifier=solid.name)
for i,a in enumerate(angles[::6]):
    rod("LeafVein_%d"%i,(math.cos(a)*.08,math.sin(a)*.065,.045),(math.cos(a)*.91,math.sin(a)*.73,.047),.008,"LeafLight",r,.003)
flower=empty("LotusFlower",r)
for ring,(count,radius,height,length,mat) in enumerate([(10,.23,.11,.24,"Petal"),(7,.13,.18,.20,"PetalInner")]):
    for i in range(count):
        a=i*math.tau/count+ring*.2
        p=ell("Petal_%d_%d"%(ring,i),(-.25+math.cos(a)*radius,.08+math.sin(a)*radius,height),
            (length,.083,.048),mat,flower,20,10)
        p.rotation_euler=(0,-.30,a)
ell("PollenHeart",(-.25,.08,.21),(.12,.12,.08),"Pollen",flower)
save("lotus_lily_pad",r,"Lake modular platform decoration; warm lotus, no glow")

# LAKE environment: three individual cattails with bent strap leaves.
r=reset("CattailsModel")
for i,(x,y,h) in enumerate([(-.33,.09,1.8),(.02,-.04,2.3),(.37,.18,1.95)]):
    stalk=empty("Stalk_%d"%i,r)
    rod("Stem",(x,y,0),(x+.04,y,h),.023,"Stem",stalk,.015)
    ell("BrownSeedHead",(x+.04,y,h-.13),(.087,.085,.29),"Cattail",stalk)
    rod("DryTip",(x+.04,y,h+.1),(x+.045,y,h+.31),.010,"Ochre",stalk,.004)
    for s in (-1,1):
        blade("StrapLeaf",[(x,y,.02),(x+s*.11,y-.06,h*.35),(x+s*.28,y-.10,h*.65),(x+s*.43,y-.06,h*.78),(x+s*.52,y-.01,h*.68)],
            [.013,.057,.068,.041,.002],"Leaf" if s<0 else "LeafLight",stalk,12,.14)
save("cattails_cluster",r,"Lake shore vertical framing; natural green and ochre")

# SPACE environment: smooth mid-poly dry rock, not a luminous crystal.
r=reset("AsteroidModel")
o=ell("RockBody",(0,0,0),(1,.72,.78),"Rock",r,32,18)
for v in o.data.vertices:
    p=v.co
    distortion=1+.08*math.sin(p.x*6+p.y*3)+.055*math.cos(p.z*7-p.x*2)
    p*=distortion
o.data.update()
for key in ("RockLight","RockDark"):
    o.data.materials.append(MATS[key])
for p in o.data.polygons:
    c=p.center
    geological=math.sin(c.x*3+c.z*2)*math.cos(c.y*3-c.z)
    p.material_index=1 if geological>.55 else (2 if geological<-.65 else 0)
for i,(x,y,z,s) in enumerate([(-.33,-.59,.25,.24),(.38,-.59,-.14,.18),(.14,-.46,.54,.16)]):
    ell("CraterBasin_%d"%i,(x,y,z),(s,.034,s*.73),"RockDark",r,24,12)
    # Low lip at the lower edge creates a readable depression without a black hole.
    ell("CraterLip_%d"%i,(x,y-.015,z-s*.60),(s*.85,.045,s*.15),"RockLight",r,20,10)
save("warm_asteroid",r,"Space modular obstacle decoration; no emission")

(OUT/"manifest.json").write_text(json.dumps({"version":1,"original_assets":True,"assets":STATS},indent=2),encoding="utf-8")
print("FUTURE_BIOMES_STATS",json.dumps(STATS))
