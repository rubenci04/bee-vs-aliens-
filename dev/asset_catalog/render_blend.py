# Blender headless: side render (orthographic, neutral background) + stats of one .blend.
# Usage: blender -b file.blend -P render_blend.py -- out.png out.json
import bpy, sys, json, math
from mathutils import Vector
out_png, out_json = sys.argv[sys.argv.index("--") + 1:][:2]
scene = bpy.context.scene
objs = [o for o in scene.objects if o.type == "MESH" and not o.hide_render and o.visible_get()]
if not objs:
    objs = [o for o in scene.objects if o.type == "MESH"]
tris = 0
lo = Vector((1e9,) * 3); hi = Vector((-1e9,) * 3)
dg = bpy.context.evaluated_depsgraph_get()
for o in objs:
    ev = o.evaluated_get(dg)
    me = ev.to_mesh()
    me.calc_loop_triangles()
    tris += len(me.loop_triangles)
    ev.to_mesh_clear()
    for c in o.bound_box:
        w = o.matrix_world @ Vector(c)
        lo = Vector((min(lo[i], w[i]) for i in range(3))); hi = Vector((max(hi[i], w[i]) for i in range(3)))
size = hi - lo; mid = (hi + lo) / 2
for o in list(scene.objects):
    if o.type in ("CAMERA", "LIGHT"):
        bpy.data.objects.remove(o)
cam_data = bpy.data.cameras.new("cat"); cam_data.type = "ORTHO"
cam_data.ortho_scale = max(size.x, size.z, 0.01) * 1.25
cam = bpy.data.objects.new("cat", cam_data); scene.collection.objects.link(cam)
cam.location = (mid.x, mid.y - max(size.y, 1.0) - 20.0, mid.z)
cam.rotation_euler = (math.radians(90), 0, 0)
scene.camera = cam
scene.render.engine = "BLENDER_WORKBENCH"
sh = scene.display.shading
sh.light = "STUDIO"; sh.color_type = "MATERIAL"; sh.show_cavity = False
scene.world = scene.world or bpy.data.worlds.new("w")
scene.world.color = (0.62, 0.64, 0.66)
scene.render.film_transparent = False
scene.render.resolution_x = 512; scene.render.resolution_y = 512
scene.render.filepath = out_png
try:
    scene.view_settings.view_transform = "Standard"
except Exception:
    pass
bpy.ops.render.render(write_still=True)
json.dump({"tris": tris, "size": [round(v, 3) for v in size], "objects": len(objs)}, open(out_json, "w"))
