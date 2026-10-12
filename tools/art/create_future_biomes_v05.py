"""Three original Blender/GLB coastal POCs: octopus, gull and buoy.

Run Blender --background --python tools/art/create_future_biomes_v05.py.
X horizontal, -X forward, Blender Z -> Godot Y. Colours authored in sRGB.
No external assets. Fauna and removable devices are separate subtrees.
"""
from pathlib import Path
import bpy, bmesh, math, json
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/models/future_biomes_v05"
SRC = ROOT / "art_source/blender/future_biomes_v05"
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
    "OctopusSkin": (.65,.30,.17), "OctopusBelly": (.76,.46,.27),
    "SuckerRim": (.85,.65,.43), "SuckerInner": (.52,.30,.18),
    "GullWhite": (.86,.85,.74), "GullGrey": (.54,.58,.57),
    "GullTips": (.18,.21,.20), "BeakYellow": (.84,.63,.20),
    "BuoyOrange": (.76,.34,.12), "BuoyCream": (.84,.78,.59),
    "MarineRope": (.46,.39,.25), "MarineMetal": (.37,.39,.34),
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

def torus(name, pos, major, minor, mat, parent, rotation=(0,0,0), segments=32, rings=8):
    bpy.ops.mesh.primitive_torus_add(major_segments=segments, minor_segments=rings, major_radius=major, minor_radius=minor, location=pos, rotation=rotation)
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

def combine(objects, name, parent):
    """Combine repeated details, retaining editable topology and material slots."""
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.join()
    result=bpy.context.object
    result.name=name
    result.parent=parent
    return result

# Octopus: mantle and head, eight arms with a two-row ventral sucker pattern.
# Arm tips are splayed in the game plane while still placed around a natural base.
root=reset("OctopusModel")
fauna=empty("NaturalFauna",root)
ell("Mantle",(.19,0,.48),(.38,.31,.53),"OctopusSkin",fauna,32,16)
ell("Head",(-.045,0,.015),(.34,.32,.25),"OctopusSkin",fauna,28,14)
ell("VentralWeb",(.01,.035,-.12),(.32,.27,.17),"OctopusBelly",fauna)
for s in (-1,1):
    ell("EyeLid",(-.20,s*.272,.09),(.12,.068,.095),"OctopusBelly",fauna,20,10)
    ell("Eye",(-.23,s*.319,.10),(.072,.026,.057),"Ochre",fauna,20,10)
    ell("HorizontalPupil",(-.242,s*.341,.10),(.047,.009,.014),"Eye",fauna,16,8)
curve("NaturalFunnel",[(-.17,-.19,-.08),(-.32,-.23,-.12),(-.40,-.23,-.10)],
      [.060,.052,.040],"OctopusBelly",fauna,14)
end_xs=[-1.40,-1.10,-.74,-.30,.20,.65,1.06,1.40]
end_zs=[-.65,-.96,-1.22,-1.40,-1.37,-1.18,-.94,-.62]
for i,(ex,ez) in enumerate(zip(end_xs,end_zs)):
    arm=empty("Arm_%02d"%(i+1),fauna)
    angle=(i/8)*math.tau
    y=-.13 if i%2==0 else .12
    points=[(-.015+.18*math.cos(angle),.18*math.sin(angle),-.13),
            (ex*.32,y,-.38),(ex*.78,y,ez*.86),
            (ex,y,ez),(ex+(.15 if ex<0 else -.15),y-.015,ez+.16)]
    tube=curve("ArmSkin",points,[.116,.102,.067,.033,.004],"OctopusSkin",arm,16)
    details=[]
    # Read the actual swept rings to place cups on the same natural surface.
    for ring in (5,8,11):
        center=sum((tube.data.vertices[ring*16+j].co for j in range(16)),Vector())/16
        radius=(tube.data.vertices[ring*16].co-center).length
        for row in (-1,1):
            pos=(center.x+row*radius*.40,center.y-radius*.99,center.z)
            details.append(torus("SuckerRing",pos,radius*.27,radius*.075,"SuckerRim",arm,(math.pi/2,0,0),12,6))
            details.append(ell("SuckerCenter",(pos[0],pos[1]+.008,pos[2]),(radius*.19,.012,radius*.19),"SuckerInner",arm,8,4))
    combine(details,"NaturalSuckers",arm)
controller(root,(.11,-.23,.82),.145)
save("controlled_octopus","Costa/mar: ocho brazos naturales con ventosas; receptor removible en manto")

# Gull: long bill, slender body, long swept wings and dark natural feather tips.
root=reset("GullModel")
fauna=empty("NaturalFauna",root)
ell("Body",(.08,0,.01),(.60,.23,.26),"GullWhite",fauna,28,14)
ell("Back",(.16,.015,.15),(.47,.20,.15),"GullGrey",fauna)
curve("Neck",[(-.26,0,.02),(-.44,0,.17),(-.58,0,.25)],
      [.18,.145,.12],"GullWhite",fauna,20)
ell("Head",(-.63,0,.30),(.20,.14,.155),"GullWhite",fauna)
curve("NaturalBeak",[(-.78,0,.265),(-.96,0,.245),(-1.12,0,.21),(-1.13,0,.18)],
      [.047,.041,.019,.003],"BeakYellow",fauna,16,flatten=.75)
ell("BeakMark",(-1.015,-.025,.212),(.037,.010,.018),"OctopusSkin",fauna,16,8)
for s in (-1,1):
    ell("EyeRing",(-.68,s*.122,.33),(.028,.012,.029),"Cream",fauna,16,8)
    ell("Eye",(-.685,s*.131,.33),(.018,.008,.019),"Eye",fauna,16,8)
    wing=empty("Wing_L" if s==-1 else "Wing_R",fauna)
    height=1.0 if s==-1 else .64
    curve("WingCoverts",[(-.08,s*.15,.15),(.06,s*.44,.39*height),(.38,s*.71,.69*height),(.94,s*.91,.88*height)],
          [.17,.20,.14,.022],"GullGrey",wing,20,flatten=.38)
    for i in range(7):
        x=.04+i*.105
        feather=curve("FlightFeather_%02d"%i,[(x,s*(.38+i*.043),(.33+i*.055)*height),
             (x+.31,s*(.67+i*.043),(.59+i*.052)*height),
             (x+.61,s*(.91+i*.028),(.62+i*.069)*height)],
             [.063,.071,.007],"GullGrey",wing,12,flatten=.30)
        feather.data.materials.append(MATERIALS["GullTips"])
        feather.data.materials.append(MATERIALS["GullWhite"])
        for polygon in feather.data.polygons:
            if polygon.index//12>=5:
                polygon.material_index=1
            if polygon.index//12==7:
                polygon.material_index=2
    leg=empty("TuckedLeg_%s"%s,fauna)
    curve("Leg",[(.09,s*.12,-.15),(.25,s*.15,-.29),(.43,s*.15,-.27)],
          [.016,.014,.009],"BeakYellow",leg,10)
    mesh("WebbedFoot",[(.36,s*.15,-.27),(.50,s*.08,-.29),(.52,s*.23,-.29),(.40,s*.15,-.26)],
         [(0,1,2),(0,3,1),(1,3,2),(2,3,0)],"BeakYellow",leg)
tail=empty("NaturalTail",fauna)
for i in range(5):
    curve("TailFeather_%d"%i,[(.46,(i-2)*.042,.02),(.80,(i-2)*.062,-.01),(1.03,(i-2)*.070,-.06)],
          [.045,.051,.009],"GullWhite",tail,12,flatten=.37)
controller(root,(-.33,-.16,.20),.105)
save("controlled_gull","Costa: gaviota de alas largas, pico amarillo, patas palmeadas; receptor en hombro")

# Human fishing buoy: no alien materials, no light; separate editable rope.
root=reset("CoastalBuoyModel")
prop=empty("HumanProp",root)
segments=48
profile=[(.08,-.39),(.32,-.30),(.46,-.10),(.47,.13),(.39,.34),(.22,.44),(.12,.46)]
smooth_profile=[]
for i in range(len(profile)-1):
    p0,p1,p2,p3=[Vector(profile[max(0,min(len(profile)-1,j))]) for j in (i-1,i,i+1,i+2)]
    for j in range(4):
        t=j/4
        smooth_profile.append(tuple(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)))
profile=smooth_profile+[profile[-1]]
verts=[]
for radius,z in profile:
    for j in range(segments):
        a=j*math.tau/segments
        verts.append((radius*math.cos(a),radius*math.sin(a),z))
faces=[]
for i in range(len(profile)-1):
    for j in range(segments):
        a=i*segments+j
        faces.append((a,i*segments+(j+1)%segments,(i+1)*segments+(j+1)%segments,a+segments))
faces.extend([tuple(reversed(range(segments))),tuple(range((len(profile)-1)*segments,len(profile)*segments))])
body=mesh("BuoyBody",verts,faces,"BuoyOrange",prop)
body.data.materials.append(MATERIALS["BuoyCream"])
for polygon in body.data.polygons:
    if -.10<=polygon.center.z<=.13:
        polygon.material_index=1
ell("TopPlug",(0,0,.47),(.12,.12,.055),"MarineMetal",prop,20,10)
torus("Handle",(0,0,.59),.105,.025,"MarineMetal",prop,(math.pi/2,0,0))
torus("BottomEyelet",(0,0,-.40),.073,.023,"MarineMetal",prop,(math.pi/2,0,0))
rope=empty("MooringRope",prop)
curve("Rope",[(0,0,-.46),(.07,0,-.66),(.04,0,-.89),(-.10,0,-1.12),(-.12,0,-1.38)],
      [.026]*5,"MarineRope",rope,12)
for s in (-1,1):
    curve("MouldSeam",[(s*.33,0,-.28),(s*.465,0,-.06),(s*.46,0,.14),(s*.38,0,.34)],
          [.009]*4,"BuoyOrange",prop,8)
save("coastal_buoy","Costa/lago: boya humana naranja con banda crema, asa y cabo de amarre, sin emisión")

(OUT/"manifest.json").write_text(json.dumps({"version":5,"original_assets":True,"assets":STATS},indent=2,ensure_ascii=False),encoding="utf-8")
print("FUTURE_BIOMES_V05_STATS",json.dumps(STATS))

