"""Four original sky POCs. Blender Z up -> Godot Y up, viewed along Blender +Y.
Run Blender --background --python tools/art/create_future_biomes_v07.py.
Warm natural palettes, no emission, textures or external assets.
"""
from pathlib import Path
import bpy, bmesh, math, json
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"assets/models/future_biomes_v07"
SRC=ROOT/"art_source/blender/future_biomes_v07"
for directory in (OUT,SRC):
    directory.mkdir(parents=True,exist_ok=True)
(SRC/".gdignore").write_text("",encoding="utf-8")
bpy.context.preferences.filepaths.save_version=0
PALETTE={"CloudCream":(.81,.82,.74),"SunGold":(.88,.66,.22),
         "MoonIvory":(.76,.77,.67),"MoonMare":(.59,.62,.54),
         "StarCream":(.86,.80,.61),"StarMuted":(.68,.71,.62)}
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
        assert all(edge.is_manifold for edge in bm.edges),"Open edge: "+obj.name
        assert all(face.calc_area()>1e-12 for face in bm.faces),"Degenerate face: "+obj.name
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

# Continuous cloud volume: lobed outline and a smooth dome on both sides.
# Radial rings avoid internal valleys that create noisy lighting-band islands.
root=reset("SkyCloudModel")
sky=empty("SkyElement",root)
lobes=[(0,-.10,1.14,.27),(-.74,.06,.46,.37),(-.31,.30,.55,.48),
       (.24,.40,.57,.51),(.73,.12,.45,.38)]
segments,rings=128,12
radii=[]
for j in range(segments):
    a=j*math.tau/segments
    dx,dz=math.cos(a),math.sin(a)
    candidates=[]
    for x,z,rx,rz in lobes:
        ox,oz=-x,.20-z
        aa=(dx/rx)**2+(dz/rz)**2
        bb=2*(ox*dx/(rx*rx)+oz*dz/(rz*rz))
        cc=(ox/rx)**2+(oz/rz)**2-1
        disc=bb*bb-4*aa*cc
        if disc>=0:
            candidates.append((-bb+math.sqrt(disc))/(2*aa))
    radii.append(max(candidates))
for _ in range(5):
    radii=[.25*radii[(j-1)%segments]+.50*radii[j]+.25*radii[(j+1)%segments] for j in range(segments)]
vertices,faces=[],[]
for sign in (-1,1):
    center=len(vertices)
    vertices.append((0,sign*.44,.20))
    for i in range(1,rings+1):
        angle=(i/rings)*math.pi/2
        rho=math.sin(angle)
        for j in range(segments):
            a=j*math.tau/segments
            vertices.append((radii[j]*math.cos(a)*rho,sign*.44*math.cos(angle),.20+radii[j]*math.sin(a)*rho))
    for j in range(segments):
        faces.append((center,center+1+j,center+1+(j+1)%segments))
    for i in range(rings-1):
        for j in range(segments):
            a=center+1+i*segments+j
            b=center+1+i*segments+(j+1)%segments
            faces.append((a,b,b+segments,a+segments))
cloud=mesh("CloudBody",vertices,faces,"CloudCream",sky)
bm=bmesh.new()
bm.from_mesh(cloud.data)
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
bm.to_mesh(cloud.data)
bm.free()
cloud.data.update()
for polygon in cloud.data.polygons:
    polygon.use_smooth=True
save("sky_cloud","Cielo: nube continua lobulada, base baja y contorno suave")

# Unadorned solar disk: a shallow rounded lens, no spikes, faces or rings.
root=reset("SkySunModel")
sky=empty("SkyElement",root)
ell("SunDisc",(0,0,0),(.72,.145,.72),"SunGold",sky,48,24)
save("sky_sun","Cielo diurno: disco solar ocre/dorado, sin emisión ni luz incorporada")

# True concave crescent. No dark disk or alpha quad fakes the cutout.
root=reset("SkyMoonModel")
sky=empty("SkyElement",root)
radius,cut_radius,offset=.72,.65,.29
ix=(radius*radius-cut_radius*cut_radius+offset*offset)/(2*offset)
iz=math.sqrt(radius*radius-ix*ix)
outer_angle=math.atan2(iz,ix)
inner_angle=math.atan2(iz,ix-offset)
outline=[]
steps=64
for i in range(steps+1):
    angle=outer_angle+(math.tau-2*outer_angle)*i/steps
    outline.append((radius*math.cos(angle)+.20,radius*math.sin(angle)))
for i in range(1,steps):
    angle=-inner_angle-(math.tau-2*inner_angle)*i/steps
    outline.append((offset+cut_radius*math.cos(angle)+.20,cut_radius*math.sin(angle)))
badge("CrescentBody",outline,.13,"MoonIvory",sky,.018)
for i,(x,z,rx,rz) in enumerate(((-.40,0,.064,.10),(-.31,.26,.049,.066),(-.20,-.36,.043,.056))):
    ell("MoonMare_%d"%i,(x,-.066,z),(rx,.004,rz),"MoonMare",sky,24,12)
save("sky_crescent_moon","Cielo nocturno: creciente sólido biselado con tres manchas suaves de superficie")

# Sparse background cluster. Four-point sparkles are separate from soft dots.
root=reset("SkyStarsModel")
sky=empty("SkyElement",root)
layout=[(-.92,.32,.13),(-.53,-.22,.055),(-.20,.57,.085),(.18,.13,.045),(.50,.40,.11),
        (.93,-.06,.07),(.30,-.43,.12),(-.71,-.48,.04),(.83,.66,.035)]
for i,(x,z,size) in enumerate(layout):
    if i in (0,2,4,6):
        outline=[(0,size),(.18*size,.22*size),(.68*size,0),(.18*size,-.22*size),
                 (0,-size),(-.18*size,-.22*size),(-.68*size,0),(-.18*size,.22*size)]
        star=badge("StarGlint_%02d"%i,outline,.018,"StarCream",sky,.003)
        star.location=(x,0,z)
    else:
        ell("StarDot_%02d"%i,(x,0,z),(size*.5,.016,size*.5),"StarMuted",sky,16,8)
save("sky_star_cluster","Cielo nocturno: nueve estrellas cálidas discretas, cuatro destellos y cinco puntos")

(OUT/"manifest.json").write_text(json.dumps({"version":7,"original_assets":True,"assets":STATS},indent=2,ensure_ascii=False),encoding="utf-8")
print("FUTURE_BIOMES_V07_STATS",json.dumps(STATS))
