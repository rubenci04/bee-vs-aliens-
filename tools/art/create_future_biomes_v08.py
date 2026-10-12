"""Three original coastal POCs. Blender Z up -> Godot Y up, viewed along Blender +Y.
Run Blender --background --python tools/art/create_future_biomes_v08.py.
Warm natural palettes, no emission, textures or external assets.
"""
from pathlib import Path
import bpy, bmesh, math, json
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"assets/models/future_biomes_v08"
SRC=ROOT/"art_source/blender/future_biomes_v08"
for directory in (OUT,SRC):
    directory.mkdir(parents=True,exist_ok=True)
(SRC/".gdignore").write_text("",encoding="utf-8")
bpy.context.preferences.filepaths.save_version=0
PALETTE={"HullRed":(.57,.25,.17),"HullDark":(.39,.19,.13),"Wood":(.63,.43,.23),"WoodLight":(.76,.58,.33),"RimCream":(.85,.76,.53),"Water":(.28,.47,.45),"Foam":(.84,.85,.71),"Stone":(.46,.47,.40),"Pebble":(.57,.55,.44),"Moss":(.39,.48,.22)}
MATERIALS={}
STATS=[]

def linear(c):
    return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4

def empty(name,parent=None):
    obj=bpy.data.objects.new(name,None)
    bpy.context.collection.objects.link(obj)
    obj.parent=parent
    return obj

def reset(name):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for material in list(bpy.data.materials):
        bpy.data.materials.remove(material)
    MATERIALS.clear()
    for key,rgb in PALETTE.items():
        color=(*[linear(c) for c in rgb],1)
        mat=bpy.data.materials.new(key)
        mat.diffuse_color=color
        mat.use_nodes=True
        mat.node_tree.nodes.clear()
        bs=mat.node_tree.nodes.new("ShaderNodeBsdfPrincipled")
        output=mat.node_tree.nodes.new("ShaderNodeOutputMaterial")
        mat.node_tree.links.new(bs.outputs["BSDF"],output.inputs["Surface"])
        bs.inputs["Base Color"].default_value=color
        bs.inputs["Roughness"].default_value=.95
        mat.use_backface_culling=True
        MATERIALS[key]=mat
    bpy.context.scene.unit_settings.system="METRIC"
    return empty(name)

def ell(name,pos,scale,material,parent,segments=32,rings=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=pos)
    obj=bpy.context.object
    obj.name=name
    obj.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    obj.parent=parent
    obj.data.materials.append(MATERIALS[material])
    for poly in obj.data.polygons:
        poly.use_smooth=True
    return obj

def mesh(name,vertices,faces,material,parent):
    data=bpy.data.meshes.new(name+"Mesh")
    data.from_pydata(vertices,[],faces)
    bm=bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    data.update()
    obj=bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(obj)
    obj.parent=parent
    data.materials.append(MATERIALS[material])
    return obj

def apply_modifier(obj,modifier):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active=obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)

def badge(name,outline,depth,material,parent,bevel=.015):
    n=len(outline)
    vertices=[(x,y,z) for y in (-depth/2,depth/2) for x,z in outline]
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    for i in range(n):
        j=(i+1)%n
        faces.append((i,j,j+n,i+n))
    obj=mesh(name,vertices,faces,material,parent)
    mod=obj.modifiers.new("SoftEdges","BEVEL")
    mod.width=bevel
    mod.segments=3
    apply_modifier(obj,mod)
    # Broad cap faces stay flat; small bevels and side faces stay smooth.
    for polygon in obj.data.polygons:
        polygon.use_smooth=abs(polygon.normal.y)<.999
    return obj

def save(key,role):
    bpy.context.view_layer.update()
    objects=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    # This batch must contain closed, non-degenerate solid meshes only.
    for obj in objects:
        bm=bmesh.new()
        bm.from_mesh(obj.data)
        # Bevels can leave coincident vertices at a tightly curved crest.
        bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
        bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=1e-6)
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        assert all(edge.is_manifold for edge in bm.edges),"Open edge: "+obj.name
        assert all(face.calc_area()>1e-12 for face in bm.faces),"Degenerate face: "+obj.name
        bm.to_mesh(obj.data)
        bm.free()
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(key+".blend")))
    bpy.ops.export_scene.gltf(filepath=str(OUT/(key+".glb")),export_format="GLB",use_selection=True,export_yup=True,export_animations=False)
    bounds=[o.matrix_world@Vector(v) for o in objects for v in o.bound_box]
    STATS.append({"id":key,"role":role,"triangles":sum(len(p.vertices)-2 for o in objects for p in o.data.polygons),
        "mesh_objects":len(objects),"dimensions_xyz_blender":[round(max(p[i] for p in bounds)-min(p[i] for p in bounds),3) for i in range(3)],
        "up_godot":"+Y","view_godot":"XY","rigged":False,"emissive":False,"closed_meshes":True,
        "source":str((SRC/(key+".blend")).relative_to(ROOT)).replace("\\","/"),
        "glb":str((OUT/(key+".glb")).relative_to(ROOT)).replace("\\","/")})

def smooth(obj):
    for p in obj.data.polygons:
        p.use_smooth=True
    return obj

def tube(name,points,radius,material,parent,sides=12,loop=False):
    vertices,faces=[],[]
    previous_u=None
    for i,p in enumerate(points):
        before=points[(i-1)%len(points)] if loop else points[max(0,i-1)]
        after=points[(i+1)%len(points)] if loop else points[min(len(points)-1,i+1)]
        tangent=(Vector(after)-Vector(before)).normalized()
        if previous_u is None:
            reference=Vector((0,0,1)) if abs(tangent.z)<.9 else Vector((0,1,0))
            u=tangent.cross(reference).normalized()
        else:
            # Transport the frame; switching reference axes mid-curve twists foam rings.
            u=(previous_u-tangent*previous_u.dot(tangent)).normalized()
        previous_u=u
        v=tangent.cross(u).normalized()
        for j in range(sides):
            a=j*math.tau/sides
            vertices.append(tuple(Vector(p)+radius*(u*math.cos(a)+v*math.sin(a))))
    for i in range(len(points) if loop else len(points)-1):
        for j in range(sides):
            ni=(i+1)%len(points)
            faces.append((i*sides+j,i*sides+(j+1)%sides,ni*sides+(j+1)%sides,ni*sides+j))
    if not loop:
        faces.extend([tuple(reversed(range(sides))),tuple(range((len(points)-1)*sides,len(points)*sides))])
    return smooth(mesh(name,vertices,faces,material,parent))

def block(name,pos,scale,material,parent,bevel=.035):
    bpy.ops.mesh.primitive_cube_add(size=2,location=pos)
    obj=bpy.context.object
    obj.name=name
    obj.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    obj.parent=parent
    obj.data.materials.append(MATERIALS[material])
    mod=obj.modifiers.new("RoundedCorners","BEVEL")
    mod.width=bevel
    mod.segments=3
    apply_modifier(obj,mod)
    return obj

def soften_closed(points,steps=3):
    out=[]
    for i,p in enumerate(points):
        p0,p1,p2,p3=[Vector(points[j%len(points)]) for j in (i-1,i,i+1,i+2)]
        for k in range(steps):
            t=k/steps
            out.append(tuple(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)))
    return out

def soften_open(points,steps=4):
    out=[]
    for i in range(len(points)-1):
        p0,p1,p2,p3=[Vector(points[max(0,min(len(points)-1,j))]) for j in (i-1,i,i+1,i+2)]
        for k in range(steps):
            t=k/steps
            out.append(tuple(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)))
    return out+[points[-1]]

# Hollow hull: outer skin, gunwale bridge and inner floor form ONE closed shell.
root=reset("CoastalRowboatModel")
boat=empty("BoatAssembly",root)
n=64
sections=[(.12,.64,.28),(.23,.82,.58),(.47,.94,.84),(.73,1,1),
          (.73,.955,.90),(.48,.89,.73),(.27,.73,.39)]
vertices=[]
for z,fx,fy in sections:
    for j in range(n):
        a=j*math.tau/n
        x=2.15*fx*math.cos(a)
        y=.69*fy*math.sin(a)
        vertices.append((x,y,z+.13*abs(math.cos(a))**4))
faces=[tuple(reversed(range(n)))]
for i in range(len(sections)-1):
    for j in range(n):
        faces.append((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j))
faces.append(tuple(range((len(sections)-1)*n,len(sections)*n)))
hull=smooth(mesh("HollowHull",vertices,faces,"HullRed",boat))
hull.data.materials.append(MATERIALS["Wood"])
hull.data.materials.append(MATERIALS["HullDark"])
for p in hull.data.polygons:
    if p.index==0 or 1<=p.index<=n:
        p.material_index=2
    elif p.index>3*n:
        p.material_index=1
rim=[(2.15*math.cos(j*math.tau/n),.69*math.sin(j*math.tau/n),.735+.13*abs(math.cos(j*math.tau/n))**4) for j in range(n)]
tube("Gunwale",rim,.045,"RimCream",boat,loop=True)
for i,y in enumerate((-.15,0,.15)):
    block("FloorSlat_%d"%i,(0,y,.385),(1.25,.065,.025),"WoodLight",boat,.02)
for i,x in enumerate((-.91,0,.91)):
    block("Bench_%d"%i,(x,0,.62),(.16,.53,.045),"WoodLight",boat,.025)
    for sign in (-1,1):
        block("BenchSupport_%d_%d"%(i,sign),(x,sign*.32,.48),(.075,.045,.11),"Wood",boat,.02)
for sign,label in ((-1,"Near"),(1,"Far")):
    oar=empty("Oar_"+label,boat)
    y=sign*.79
    # Resting oars are separate removable pieces, with broad paddle blades.
    tube("Shaft_"+label,[(-1.55,y,.86),(1.55,y,.86)],.035,"WoodLight",oar)
    paddle=badge("Blade_"+label,[(1.40,.90),(1.65,.99),(2.40,1.02),(2.55,.95),(2.55,.77),(2.40,.70),(1.65,.73),(1.40,.82)],.055,"Wood",oar,.025)
    paddle.location.y=y
    tube("Oarlock_"+label,[(-.10,sign*.65,.75),(-.10,sign*.73,.88),(-.10,sign*.84,.88)],.024,"RimCream",boat)
save("coastal_rowboat","Hollow human rowboat with three benches and two removable oars")

# A solid curved wave tile for shoreline dressing; no transparency or light emission.
root=reset("ShoreWaveModel")
wave=empty("WaveAssembly",root)
profile=[(-1.80,.06),(-1.80,.21),(-1.30,.27),(-.82,.46),(-.47,.85),
         (-.30,1.20),(.02,1.51),(.43,1.61),(.82,1.48),(1.03,1.23),
         (.96,1.00),(.74,.92),(.55,1.04),(.62,1.19),(.43,1.27),
         (.23,1.15),(.20,.93),(.43,.63),(.94,.34),(1.80,.20),(1.80,.06)]
water=badge("WaterBody",soften_closed(profile,4),.60,"Water",wave,.045)
# Add interior topology to the broad faces, then bow their depth smoothly.
# The front remains a pure side-view silhouette while light can read its volume.
bm=bmesh.new()
bm.from_mesh(water.data)
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=1e-6)
bmesh.ops.triangulate(bm,faces=[f for f in bm.faces if len(f.verts)>4])
bmesh.ops.subdivide_edges(bm,edges=list(bm.edges),cuts=1,use_grid_fill=True)
bm.to_mesh(water.data)
bm.free()
def swell(z):
    return .18*math.sin(math.pi*max(0,min(1,z/1.68)))
for v in water.data.vertices:
    v.co.y += swell(v.co.z)*v.co.y/.30
smooth(water)
crest_points=[(-.29,-.31,1.20),(-.12,-.31,1.40),(.04,-.31,1.51),(.23,-.31,1.59),
              (.43,-.31,1.61),(.64,-.31,1.56),(.82,-.31,1.48),(.96,-.31,1.34),
              (1.03,-.31,1.23),(1.01,-.31,1.10),(.96,-.31,1.00),(.84,-.31,.94),(.74,-.31,.92)]
crest_points=[(x,y-swell(z),z) for x,y,z in soften_open(crest_points)]
tube("FoamCrest",crest_points,.065,"Foam",wave)
# Two broad shallow foam rivulets sit on the near face, keeping the curl legible.
for label,points,radius in [("A",[(-1.30,-.335,.18),(-1.05,-.335,.20),(-.80,-.335,.25),(-.58,-.335,.34)],.025),
                            ("B",[(.62,-.335,.32),(.89,-.335,.24),(1.15,-.335,.20),(1.42,-.335,.18)],.022)]:
    tube("FoamTrail_"+label,[(x,y-swell(z),z) for x,y,z in soften_open(points)],radius,"Foam",wave)
save("shore_wave_module","Closed decorative shore wave with cream foam crest")

# Smoothly sculpted stone: broad asymmetry, no noisy texture or faceted triangles.
root=reset("ShoreRockModel")
rocks=empty("RockAssembly",root)
def sculpt(a,t):
    ripple=1+.065*math.sin(3*a+.7)*math.sin(t)**2+.035*math.cos(5*a-2*t)
    x=1.18*math.cos(a)*math.sin(t)*ripple+.13*math.cos(t)
    y=.63*math.sin(a)*math.sin(t)*ripple
    z=.65+.70*math.cos(t)+.05*math.cos(2*a)*math.sin(t)**2
    # Compressed underside gives a stable contact patch without a sharp chopped edge.
    z=max(.035,z) if z>=.035 else .035+(z-.035)*.12
    return x,y,z
stone=ell("Stone",(0,0,0),(1,1,1),"Stone",rocks,48,24)
for v in stone.data.vertices:
    p=v.co.normalized()
    a=math.atan2(p.y,p.x)
    t=math.acos(max(-1,min(1,p.z)))
    v.co=sculpt(a,t)
stone.data.update()
ell("Pebble_Left",(-.98,-.16,.20),(.39,.32,.22),"Pebble",rocks,32,16)
ell("Pebble_Right",(.98,.06,.17),(.34,.27,.19),"Stone",rocks,32,16)
# Closed cap follows the exact stone surface; variable boundary makes a single moss patch.
segments,rings=48,7
verts=[]
for layer in (0,1):
    for k in range(rings):
        rho=(k+1)/rings
        for j in range(segments):
            a=j*math.tau/segments
            edge=.69+.12*math.sin(3*a+.5)+.07*math.cos(5*a)
            x,y,z=sculpt(a,rho*edge)
            verts.append((x,y,z+(.026 if layer==0 else .004)))
    verts.append((.13,0,1.35+(.026 if layer==0 else .004)))
per_layer=rings*segments+1
faces=[]
for layer in (0,1):
    off=layer*per_layer
    pole=off+rings*segments
    for j in range(segments):
        faces.append((pole,off+j,off+(j+1)%segments))
    for k in range(rings-1):
        for j in range(segments):
            faces.append((off+k*segments+j,off+k*segments+(j+1)%segments,off+(k+1)*segments+(j+1)%segments,off+(k+1)*segments+j))
for j in range(segments):
    a=(rings-1)*segments+j
    b=(rings-1)*segments+(j+1)%segments
    faces.append((a,b,b+per_layer,a+per_layer))
smooth(mesh("MossCap",verts,faces,"Moss",rocks))
save("shore_rock","Smooth shore stone with conforming olive moss cap and two pebbles")

(OUT/"manifest.json").write_text(json.dumps({"batch":"V08","assets":STATS},indent=2),encoding="utf-8")
print("FUTURE_BIOMES_V08_BLENDER_OK: "+json.dumps(STATS))

