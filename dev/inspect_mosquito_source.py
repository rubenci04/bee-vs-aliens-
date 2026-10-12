import bpy
from pathlib import Path
bpy.ops.wm.open_mainfile(filepath=str(Path('art_source/blender/swarm_lite_v01/controlled_mosquito.blend').resolve()))
for o in bpy.data.objects:
 if o.type=='MESH':print(o.name,len(o.data.polygons),[m.name for m in o.data.materials])
