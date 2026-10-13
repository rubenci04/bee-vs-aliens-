import bpy,json,hashlib
from pathlib import Path
from mathutils import Vector
p=Path('dev/style_test/blend/bee_style_b.blend').resolve();sha=hashlib.sha256(p.read_bytes()).hexdigest();bpy.ops.wm.open_mainfile(filepath=str(p));bpy.context.view_layer.update()
objects=[o for o in bpy.context.scene.objects if o.type=='MESH'];root=bpy.data.objects.get('BeeModel')
print('MIDPOLY_SOURCE',json.dumps({'source':str(p),'sha256':sha,'triangles':sum(len(f.vertices)-2 for o in objects for f in o.data.polygons),'meshes':len(objects),'root_location':list(root.location),'root_scale':list(root.scale),'root_rotation':list(root.rotation_euler),'actions':[a.name for a in bpy.data.actions]},ensure_ascii=False))
assert hashlib.sha256(p.read_bytes()).hexdigest()==sha
