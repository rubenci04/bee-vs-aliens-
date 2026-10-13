import bpy,json,hashlib
from pathlib import Path
from mathutils import Vector
p=Path('art_source/blender/shared/bee/bee_alien_visual.blend').resolve();before=hashlib.sha256(p.read_bytes()).hexdigest();bpy.ops.wm.open_mainfile(filepath=str(p));bpy.context.view_layer.update()
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];points=[o.matrix_world@Vector(v) for o in meshes for v in o.bound_box]
stats={'source':str(p),'sha256':before,'meshes':len(meshes),'triangles':sum(len(poly.vertices)-2 for o in meshes for poly in o.data.polygons),'bounds_blender_xyz':[[min(v[i] for v in points) for i in range(3)],[max(v[i] for v in points) for i in range(3)]],'animation_actions':[a.name for a in bpy.data.actions]}
print('SOURCE_INVENTORY',json.dumps(stats))
assert hashlib.sha256(p.read_bytes()).hexdigest()==before
