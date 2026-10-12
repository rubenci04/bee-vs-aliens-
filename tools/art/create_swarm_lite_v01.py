"""Create ~5k triangle copies from original .blend files; originals stay untouched.
Budget includes every natural mesh and every external device. No LOD auto switching.
"""
from pathlib import Path
import bpy,bmesh,json,math,struct
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"assets/models/swarm_lite_v01"
SRC=ROOT/"art_source/blender/swarm_lite_v01"
for path in (OUT,SRC): path.mkdir(parents=True,exist_ok=True)
(SRC/".gdignore").write_text("",encoding="utf-8")
INPUTS=[("controlled_ant","future_biomes_v09"),("controlled_mosquito","future_biomes_v01"),
        ("controlled_flying_ladybird","future_biomes_v03"),("controlled_caterpillar","future_biomes_v09")]
stats=[]
def tris(data): return sum(len(p.vertices)-2 for p in data.polygons)
def activate(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active=obj
def join_group(group):
    objects=[o for o in group.children_recursive if o.type=="MESH"]
    bpy.context.view_layer.update()
    for obj in objects:
        world=obj.matrix_world.copy()
        obj.parent=None
        obj.matrix_world=world
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects: obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.join()
    obj=objects[0]
    world=obj.matrix_world.copy()
    obj.parent=group
    obj.matrix_world=world
    obj.name=group.name+"LiteMesh"
    return obj
for key,batch in INPUTS:
    source=ROOT/"art_source/blender"/batch/(key+".blend")
    bpy.ops.wm.open_mainfile(filepath=str(source))
    bpy.context.preferences.filepaths.save_version=0
    objects=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    before=sum(tris(o.data) for o in objects)
    bounds_before=[o.matrix_world@Vector(v) for o in objects for v in o.bound_box]
    # Preserve tiny feet/antennae more strongly than broad smooth body volumes.
    counts={o:tris(o.data) for o in objects}
    minimum={o:min(counts[o],max(24,round(counts[o]*.12))) for o in objects}
    remaining=5000-sum(minimum.values())
    assert remaining>0,"Too many tiny independent objects for this budget"
    weight=sum(counts[o]-minimum[o] for o in objects)
    for obj in objects:
        budget=minimum[obj]+remaining*(counts[obj]-minimum[obj])/weight
        activate(obj)
        mod=obj.modifiers.new("SwarmBudget","DECIMATE")
        mod.decimate_type="COLLAPSE"
        mod.ratio=min(1,budget/counts[obj])
        mod.use_collapse_triangulate=True
        bpy.ops.object.modifier_apply(modifier=mod.name)
        bm=bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-7)
        bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=1e-7)
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        assert all(e.is_manifold for e in bm.edges),"Open reduced mesh: "+obj.name
        assert all(f.calc_area()>1e-12 for f in bm.faces),"Degenerate mesh: "+obj.name
        bm.to_mesh(obj.data)
        bm.free()
    # Two independently removable streams; fewer mesh instances and material surfaces.
    natural=bpy.data.objects.get("NaturalFauna")
    device=bpy.data.objects.get("AlienControlDevice")
    assert natural and device
    join_group(natural)
    join_group(device)
    objects=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    after=sum(tris(o.data) for o in objects)
    assert 4500<=after<=5500,(key,after)
    surfaces=sum(len(o.data.materials) for o in objects)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(key+".blend")))
    bpy.ops.export_scene.gltf(filepath=str(OUT/(key+".glb")),export_format="GLB",use_selection=True,export_yup=True,export_animations=False)
    # Count actual GLB index accessors as well as source topology.
    raw=(OUT/(key+".glb")).read_bytes()
    length=struct.unpack_from('<I',raw,12)[0]
    gltf=json.loads(raw[20:20+length])
    exported=sum(gltf['accessors'][p['indices']]['count']//3 for m in gltf['meshes'] for p in m['primitives'])
    assert exported==after,(key,after,exported)
    stats.append({"id":key,"original_triangles":before,"triangles":after,"glb_triangles":exported,
        "reduction_percent":round((1-after/before)*100,1),"mesh_objects":len(objects),
        "material_slots":surfaces,"closed_meshes":True,"original_source":str(source.relative_to(ROOT)).replace('\\','/'),
        "source":str((SRC/(key+'.blend')).relative_to(ROOT)).replace('\\','/'),
        "glb":str((OUT/(key+'.glb')).relative_to(ROOT)).replace('\\','/')})
(OUT/"manifest.json").write_text(json.dumps({"batch":"swarm_lite_v01","target":5000,"assets":stats},indent=2),encoding="utf-8")
print("SWARM_LITE_V01_OK: "+json.dumps(stats))
