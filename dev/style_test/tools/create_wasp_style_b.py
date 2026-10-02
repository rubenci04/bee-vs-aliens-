# BEE STYLE TEST 01 - version B ("mid poly suave"). Copy of tools/bee_prototype/create_wasp_visual.py
# with more segments and smooth shading. Same shapes, materials and node names. Writes ONLY to dev/style_test/.
from pathlib import Path
import bpy, math, json, sys
from mathutils import Vector
sys.path.insert(0, str(Path(__file__).resolve().parent))
from style_b_common import smooth, ring_surface, curved_wing
ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "dev/style_test/models"
SRC = ROOT / "dev/style_test/blend"
OUT.mkdir(parents=True, exist_ok=True)
SRC.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.context.preferences.filepaths.save_version = 0
materials = {}
for name, color in [
 ("Ochre",(.48,.235,.027,1)), ("Dark",(.038,.019,.012,1)),
 ("Eye",(.065,.018,.014,1)), ("Wing",(.57,.51,.39,1)),
 ("Chitin",(.17,.065,.023,1))]:
 m=bpy.data.materials.new(name); m.diffuse_color=color; m.use_nodes=True
 bs=next(n for n in m.node_tree.nodes if n.type=="BSDF_PRINCIPLED")
 bs.inputs["Base Color"].default_value=color
 bs.inputs["Roughness"].default_value=.85
 materials[name]=m
root=bpy.data.objects.new("WaspModel",None)
bpy.context.collection.objects.link(root)
def finish(o,name,mat):
 o.name=name; o.data.materials.append(materials[mat])
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.parent=root
 smooth(o)
 return o
def ell(name,pos,scale,mat,segments=24,rings=14):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=pos)
 o=bpy.context.object; o.scale=scale
 return finish(o,name,mat)
def segment(name,a,b,r,mat,tip=None):
 a,b=Vector(a),Vector(b);d=b-a
 bpy.ops.mesh.primitive_cone_add(vertices=12,radius1=r,radius2=r*.72 if tip is None else tip,depth=d.length,location=(a+b)/2)
 o=bpy.context.object;o.rotation_mode='QUATERNION';o.rotation_quaternion=d.to_track_quat('Z','Y')
 return finish(o,name,mat)
ell("Thorax",(0,0,0),(.145,.195,.17),"Chitin",24,16)
ell("ThoraxPlate",(0,.012,.08),(.13,.165,.115),"Ochre",24,14)
ell("Head",(0,.245,.015),(.143,.15,.14),"Ochre",20,12)
segment("Waist",(0,-.14,-.025),(0,-.29,-.035),.057,"Dark")
ring_surface("Abdomen",[(-.245,.065),(-.32,.135),(-.40,.153),(-.48,.118),(-.55,.067),(-.59,.026)],-.035,root,[materials["Ochre"],materials["Dark"]])
segment("Stinger",(0,-.57,-.035),(0,-.69,-.11),.055,"Dark",0)
for s,label in [(-1,"L"),(1,"R")]:
 eye=ell("Eye_"+label,(s*.115,.28,.045),(.058,.09,.074),"Eye",20,12)
 eye.rotation_euler.x=-.25
 segment("Mandible_"+label,(s*.06,.345,-.055),(s*.027,.43,-.085),.036,"Chitin",0)
 segment("AntennaBase_"+label,(s*.07,.29,.12),(s*.105,.37,.23),.023,"Dark")
 segment("AntennaTip_"+label,(s*.105,.37,.23),(s*.14,.43,.25),.022,"Dark",.009)
 for i,y in enumerate([.09,-.03,-.14]):
  a=(s*.11,y,-.08);b=(s*.225,y-.07,-.22);c=(s*.285,y+.04,-.30)
  segment("Leg_%s_%d_Upper"%(label,i),a,b,.026,"Chitin")
  segment("Leg_%s_%d_Lower"%(label,i),b,c,.021,"Dark")
 pts=[(0,0,0),(s*.14,.12,.14),(s*.48,.06,.19),(s*.50,-.07,.16),(s*.32,-.25,.085),(s*.07,-.17,.01)]
 o=curved_wing("Wing_"+label,pts,(s*.23,-.05,.1),materials["Wing"],root)
 o.location=(s*.11,-.02,.14)
materials["Wing"].use_backface_culling=False
bpy.context.scene.unit_settings.system="METRIC"
bpy.context.scene.unit_settings.scale_length=1.0
bpy.ops.object.select_all(action="SELECT")
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/"wasp_style_b.blend"))
bpy.ops.export_scene.gltf(filepath=str(OUT/"wasp_style_b.glb"),export_format="GLB",use_selection=True,export_yup=True,export_animations=False,export_apply=True)
objs=[o for o in bpy.context.scene.objects if o.type=="MESH"]
print("WASP_STYLE_B_STATS",json.dumps({"triangles":sum(len(p.vertices)-2 for o in objs for p in o.data.polygons)}))
