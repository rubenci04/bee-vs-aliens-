"""Four original environment POCs: sapling, flowering shrub, empty can, wrapped candy.

Run Blender --background --python tools/art/create_future_biomes_v06.py.
X horizontal, -X forward, Blender Z -> Godot Y. Colours authored in sRGB.
No external assets. Closed organic forms and non-emissive human props.
"""
from pathlib import Path
import bpy, bmesh, math, json
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/models/future_biomes_v06"
SRC = ROOT / "art_source/blender/future_biomes_v06"
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
    "Bark": (.43,.31,.17), "BarkLight": (.56,.40,.22),
    "LeafDeep": (.24,.40,.16), "LeafMid": (.38,.53,.19),
    "LeafWarm": (.49,.59,.24), "PetalCream": (.89,.81,.57),
    "PollenGold": (.80,.56,.14), "FlowerBud": (.71,.40,.20),
    "CanPaint": (.70,.24,.14), "CanStripe": (.86,.73,.47),
    "Aluminium": (.65,.67,.61), "CanInside": (.30,.32,.27),
    "CandyRed": (.78,.27,.15), "CandyCream": (.91,.76,.44),
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

def lobe(name, pos, scale, mat, parent, phase=0):
    """A broad sculpted organic lobe; no high-frequency grit or faceted planes."""
    obj=ell(name,pos,(1,1,1),mat,parent,28,16)
    for vertex in obj.data.vertices:
        p=vertex.co.normalized()
        variation=1+.065*math.sin(3*p.x+phase)*math.cos(4*p.z-phase)+.045*math.sin(4*p.y+2*p.z+phase)
        vertex.co=Vector((vertex.co.x*scale[0],vertex.co.y*scale[1],vertex.co.z*scale[2]))*variation
    obj.data.update()
    return obj

def leaf(name, start, end, width, mat, parent):
    start,end=Vector(start),Vector(end)
    direction=end-start
    axis=direction.normalized()
    side=axis.cross(Vector((0,1,0))).normalized()
    normal=side.cross(axis).normalized()
    vertices=[]
    # Closed, gently domed leaf, with point tips and a little thickness.
    for top in (1,-1):
        for i in range(9):
            t=i/8
            w=max(.004,math.sin(math.pi*t)*width*(.95+.10*math.sin(math.pi*t)))
            for across in (-1,0,1):
                bulge=top*(math.sin(math.pi*t)*width*(.32 if across==0 else 0)+.006)
                vertices.append(tuple(start+direction*t+side*w*across+normal*bulge))
    faces=[]
    for i in range(8):
        for j in range(2):
            a=i*3+j
            faces.extend([(a,a+1,a+4,a+3),(27+a+3,27+a+4,27+a+1,27+a)])
        for j in (0,2):
            a=i*3+j
            faces.append((a,a+3,27+a+3,27+a))
    for i in (0,8):
        a=i*3
        faces.append((a,a+1,a+2,27+a+2,27+a+1,27+a))
    return mesh(name,vertices,faces,mat,parent)

# Young broadleaf tree: branches readable below a soft lobed crown.
root=reset("GardenSaplingModel")
nature=empty("NaturalPlant",root)
wood=empty("Wood",nature)
curve("Trunk",[(0,0,0),(-.04,0,.55),(.055,.01,1.16),(-.01,0,1.76),(.05,0,2.25)],
      [.135,.105,.078,.049,.012],"Bark",wood,18)
for i,(x,y,z) in enumerate(((-.60,-.02,1.63),(.64,.03,1.85),(-.40,.26,2.10),(.27,-.20,2.34))):
    curve("Branch_%d"%i,[(0,0,.70+i*.25),(x*.42,y*.5,1.12+i*.20),(x,y,z)],
          [.059-i*.006,.041-i*.004,.009],"BarkLight",wood,14)
for i in range(4):
    a=i*math.tau/4+.3
    curve("Root_%d"%i,[(0,0,.08),(.15*math.cos(a),.15*math.sin(a),.025),(.29*math.cos(a),.29*math.sin(a),.005)],
          [.063,.041,.005],"Bark",wood,12)
crown=empty("Crown",nature)
clumps=[]
for i,(pos,scale) in enumerate([
    ((-.62,.02,1.80),(.56,.43,.47)),((.58,.06,1.97),(.60,.46,.50)),
    ((-.29,.28,2.28),(.54,.46,.49)),((.27,-.13,2.45),(.57,.47,.50)),
    ((-.24,-.20,2.06),(.61,.45,.49)),((.02,.09,2.72),(.48,.40,.45))]):
    clumps.append(lobe("CrownLobe",pos,scale,["LeafMid","LeafWarm","LeafDeep"][i%3],crown,i*.9))
combine(clumps,"Canopy",crown)
details=[]
for i,(start,end) in enumerate([((-.64,-.17,1.55),(-.96,-.23,1.65)),((.61,-.06,1.62),(.96,-.09,1.74)),
                               ((-.18,-.28,2.31),(-.54,-.43,2.48)),((.42,-.31,2.50),(.72,-.39,2.65))]):
    details.append(leaf("Leaf",start,end,.09,"LeafWarm",crown))
combine(details,"CrownLeaves",crown)
save("garden_sapling","Jardín/bosque: árbol joven de copa lobulada, tronco curvo, ramas y raíces")

# Flowering shrub: real stems and pointed leaves; detachable three daisy heads.
root=reset("FloweringShrubModel")
nature=empty("NaturalPlant",root)
stems=empty("Stems",nature)
foliage=empty("Foliage",nature)
leaves=[]
for i in range(5):
    x=(i-2)*.23
    y=math.sin(i*2.4)*.16
    height=.53+.12*math.sin(i*1.7)
    curve("Stem_%02d"%i,[(x*.3,y*.3,0),(x*.65,y,.28),(x,y,height)],
          [.023,.018,.007],"LeafDeep",stems,10)
    for k in range(3):
        for s in (-1,1):
            z=.12+k*.14+.024*math.sin(i*1.8+k+s)
            start=(x*.7,y,z)
            end=(x*.7+s*(.27+.04*math.sin(i+k)),y-.08,z+.16+.065*math.cos(i*2+k+s))
            leaves.append(leaf("Leaf",start,end,.045+.008*k,"LeafDeep" if (i+k)%3==0 else "LeafMid",foliage))
combine(leaves,"ShrubLeaves",foliage)
flowers=empty("FlowerHeads",nature)
for i,(x,y,z) in enumerate(((-.44,-.06,.86),(.04,-.15,1.08),(.47,-.02,.81))):
    head=empty("Flower_%02d"%(i+1),flowers)
    curve("FlowerStem",[(x*.45,y,0),(x*.72,y,.42),(x,y,z)],
          [.018,.013,.006],"LeafMid",stems,10)
    petals=[]
    for j in range(8):
        a=j*math.tau/8
        petal=ell("Petal",(x+math.cos(a)*.105,y-.02,z+math.sin(a)*.105),(.11,.030,.052),"PetalCream",head,16,8)
        petal.rotation_euler.y=-a
        petals.append(petal)
    combine(petals,"Petals",head)
    ell("FlowerCenter",(x,y-.06,z),(.071,.035,.071),"PollenGold",head,20,10)
for i,(x,z) in enumerate(((-.71,.48),(.67,.49))):
    curve("BudStem_%d"%i,[(x*.38,-.02,.12),(x*.72,-.03,z-.12),(x,-.04,z)],
          [.013,.009,.004],"LeafMid",stems,10)
    ell("FlowerBud_%d"%i,(x,-.04,z),(.039,.037,.061),"FlowerBud",nature,16,8)
save("flowering_shrub","Jardín: arbusto bajo de hojas lanceoladas y tres margaritas crema/ocre")

# Empty drinks can: rolled rims, real drinking aperture and a separate pull tab.
root=reset("EmptyDrinkCanModel")
prop=empty("HumanProp",root)
can=empty("CanAssembly",prop)
segments=64
profile=[(.285,-.60),(.32,-.57),(.345,-.49),(.35,-.30),(.35,.30),(.345,.47),(.30,.55),(.29,.59),
         (.267,.59),(.267,.55),(.315,.45),(.323,-.40),(.29,-.52)]
verts=[]
for radius,z in profile:
    for j in range(segments):
        a=j*math.tau/segments
        # Soft shallow dent, clean and readable, never gritty damage.
        dent=.032*math.exp(-((math.atan2(math.sin(a+1.0),math.cos(a+1.0)))/.48)**2)*max(0,1-abs(z)/.55)
        r=radius-dent
        verts.append((r*math.cos(a),r*math.sin(a),z))
faces=[]
for i in range(len(profile)-1):
    for j in range(segments):
        a=i*segments+j
        faces.append((a,i*segments+(j+1)%segments,(i+1)*segments+(j+1)%segments,a+segments))
# Seal the bottom outer-to-inner profile with one disk on each side.
faces.extend([tuple(reversed(range(segments))),tuple(range((len(profile)-1)*segments,len(profile)*segments))])
body=mesh("CanBody",verts,faces,"CanPaint",can)
body.data.materials.append(MATERIALS["CanStripe"])
body.data.materials.append(MATERIALS["CanInside"])
body.data.materials.append(MATERIALS["Aluminium"])
for polygon in body.data.polygons:
    band=polygon.index//segments
    if band==3:
        polygon.material_index=1
    elif band>=8:
        polygon.material_index=2
    elif band>=5 or band==0:
        polygon.material_index=3
body.data.polygons[-2].material_index=3
# Lid annulus interpolates an outer round edge to an offset oval aperture.
lidverts=[]
for row in range(5):
    t=row/4
    for j in range(segments):
        a=j*math.tau/segments
        outer=Vector((.267*math.cos(a),.267*math.sin(a),.576))
        inner=Vector((.106*math.cos(a),-.105+.074*math.sin(a),.565))
        lidverts.append(tuple(outer.lerp(inner,t)))
lidfaces=[]
for i in range(4):
    for j in range(segments):
        a=i*segments+j
        lidfaces.append((a,i*segments+(j+1)%segments,(i+1)*segments+(j+1)%segments,a+segments))
lid=mesh("OpenLid",lidverts,lidfaces,"Aluminium",can)
solid=lid.modifiers.new("LidThickness","SOLIDIFY")
solid.thickness=.008
bpy.context.view_layer.objects.active=lid
lid.select_set(True)
bpy.ops.object.modifier_apply(modifier=solid.name)
tab=torus("PullTab",(0,.068,.599),.075,.017,"Aluminium",can,segments=32,rings=6)
tab.scale.y=1.45
ell("TabRivet",(0,.008,.591),(.021,.021,.008),"Aluminium",can,16,8)
torus("TopRim",(0,0,.591),.282,.014,"Aluminium",can)
torus("BottomRim",(0,0,-.592),.286,.014,"Aluminium",can)
can.rotation_euler=(0,-math.radians(83),math.radians(23))
can.location.z=.42
save("empty_drink_can","Residencial: lata vacía genérica tumbada, abertura real, anilla y abolladura suave")

# Wrapped sweet: soft capsule and two genuinely twisted, closed wrapper ends.
root=reset("WrappedCandyModel")
prop=empty("HumanProp",root)
wrapper=empty("Wrapper",prop)
body=ell("WrappedSweet",(0,0,.19),(.43,.19,.19),"CandyRed",wrapper,32,16)
bm=bmesh.new()
bm.from_mesh(body.data)
for cut_x in (-.095,.095):
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,
        plane_co=(cut_x,0,0),plane_no=(1,0,0),clear_inner=False,clear_outer=False)
bm.to_mesh(body.data)
bm.free()
body.data.update()
body.data.materials.append(MATERIALS["CandyCream"])
for polygon in body.data.polygons:
    if abs(polygon.center.x)<.095:
        polygon.material_index=1
for s in (-1,1):
    vertices=[]
    rings=9
    sides=24
    for i in range(rings):
        t=i/(rings-1)
        x=s*(.34+t*.42)
        radius=.11*(1-t)+.145*t-.10*math.sin(math.pi*t)**2
        twist=s*t*2.4
        for j in range(sides):
            a=j*math.tau/sides+twist
            r=radius*(1+.12*t*math.cos(j*math.tau*4/sides))
            vertices.append((x,r*math.cos(a),.19+r*math.sin(a)))
    faces=[]
    for i in range(rings-1):
        for j in range(sides):
            a=i*sides+j
            faces.append((a,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,a+sides))
    faces.extend([tuple(reversed(range(sides))),tuple(range((rings-1)*sides,rings*sides))])
    end=mesh("TwistedEnd_L" if s==-1 else "TwistedEnd_R",vertices,faces,"CandyCream",wrapper)
    end.data.materials.append(MATERIALS["CandyRed"])
    for polygon in end.data.polygons:
        if polygon.index%24 in range(5,9) or polygon.index%24 in range(17,21):
            polygon.material_index=1
save("wrapped_candy","Residencial: caramelo envuelto rojo/crema, dos extremos retorcidos, sin marca")

(OUT/"manifest.json").write_text(json.dumps({"version":6,"original_assets":True,"assets":STATS},indent=2,ensure_ascii=False),encoding="utf-8")
print("FUTURE_BIOMES_V06_STATS",json.dumps(STATS))

