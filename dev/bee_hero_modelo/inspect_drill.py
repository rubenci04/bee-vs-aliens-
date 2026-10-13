import bpy,bmesh
bpy.ops.wm.open_mainfile(filepath=r'D:\proyectos\bee_alien_3d\art_source\blender\shared\bee_hero\shared_hero_bee_v02.blend')
for obj in bpy.context.scene.objects:
 if obj.type=='MESH':
  bm=bmesh.new();bm.from_mesh(obj.data);v=bm.calc_volume(signed=True)
  if obj.name.startswith('drill') or v<0:print(obj.name,v,tuple(obj.location))
  bm.free()
