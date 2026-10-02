# BEE STYLE TEST 01 - version B ("mid poly suave"). Copy of tools/bee_prototype/create_bee_visual.py
# with more segments and smooth shading. Same shapes, colours and node names. Writes ONLY to dev/style_test/.
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
 ("Gold",(0.58,0.34,0.055,1)), ("Dark",(0.043,0.026,0.019,1)),
 ("Eye",(0.018,0.028,0.032,1)), ("Wing",(0.49,0.68,0.72,1)),
 ("AlienMetal",(0.12,0.19,0.20,1)), ("Cyan",(0.04,0.75,0.71,1))]:
 m=bpy.data.materials.new(name); m.diffuse_color=color; m.use_nodes=True
 bs=next(n for n in m.node_tree.nodes if n.type=="BSDF_PRINCIPLED"); bs.inputs["Base Color"].default_value=color
 bs.inputs["Roughness"].default_value=0.82
 if name=="Cyan":
  bs.inputs["Emission Color"].default_value=color; bs.inputs["Emission Strength"].default_value=1.5
 materials[name]=m
root=bpy.data.objects.new("BeeModel",None); bpy.context.collection.objects.link(root)
def finish(o,name,mat,parent=root):
 o.name=name; o.data.materials.append(materials[mat])
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.parent=parent
 smooth(o)
 return o
def ell(name,pos,scale,mat,segments=24,rings=14):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=pos)
 o=bpy.context.object; o.scale=scale
 return finish(o,name,mat)
def segment(name,a,b,r,mat):
 a,b=Vector(a),Vector(b); d=b-a
 bpy.ops.mesh.primitive_cone_add(vertices=12,radius1=r,radius2=r*0.78,depth=d.length,location=(a+b)/2)
 o=bpy.context.object; o.rotation_mode='QUATERNION'; o.rotation_quaternion=d.to_track_quat('Z','Y')
 return finish(o,name,mat)
ell("Thorax",(0,0,0),(0.155,0.19,0.16),"Gold")
ell("Head",(0,0.235,0.025),(0.17,0.145,0.15),"Gold")
abd=ring_surface("Abdomen",[(-0.12,.13),(-.20,.165),(-.28,.155),(-.36,.125),(-.43,.075)],-.025,root,[materials["Gold"],materials["Dark"]])
segment("Stinger",(0,-.425,-.03),(0,-.56,-.055),.045,"Dark")
for s,label in [(-1,"L"),(1,"R")]:
 eye=ell("Eye_"+label,(s*.128,.285,.055),(.059,.082,.089),"Eye",20,12)
 eye.rotation_euler.y=s*.22
 segment("Brow_"+label,(s*.085,.335,.118),(s*.163,.285,.13),.022,"Dark")
 segment("Mandible_"+label,(s*.044,.345,-.05),(s*.021,.39,-.072),.022,"Dark")
 segment("AntennaBase_"+label,(s*.073,.285,.14),(s*.097,.33,.235),.023,"Dark")
 segment("AntennaTip_"+label,(s*.097,.33,.235),(s*.115,.405,.25),.021,"Dark")
 for i,y in enumerate([.09,-.035,-.14]):
  a=(s*.1,y,-.09);b=(s*.20,y-.06,-.18);c=(s*.24,y+.025,-.24)
  segment("Leg_%s_%d_Upper"%(label,i),a,b,.022,"Dark")
  segment("Leg_%s_%d_Lower"%(label,i),b,c,.019,"Dark")
 pts=[(0,0,0),(s*.16,.10,.11),(s*.36,.075,.17),(s*.44,-.025,.15),(s*.32,-.17,.08),(s*.08,-.15,.015)]
 ob=curved_wing("Wing_"+label,pts,(s*.20,-.04,.095),materials["Wing"],root)
 ob.location=(s*.11,-.035,.13)
 materials["Wing"].use_backface_culling=False
ell("ImplantHousing",(0,.045,.158),(.10,.085,.055),"AlienMetal",16,8)
for s,label in [(-1,"L"),(1,"R")]:
 ell("Sensor_"+label,(s*.088,.055,.18),(.025,.04,.023),"Cyan",16,8)
 segment("Conduit_"+label,(s*.07,.015,.185),(s*.13,-.045,.11),.018,"AlienMetal")
segment("BrokenCable",(0,.09,.20),(.065,.145,.215),.012,"Cyan")
bpy.ops.mesh.primitive_cube_add(size=1,location=(-.028,-.018,.215))
plate=bpy.context.object;plate.scale=(.11,.065,.018);plate.rotation_euler=(.28,-.40,.18)
finish(plate,"LiftedBrokenPlate","AlienMetal")
bpy.context.scene.unit_settings.system="METRIC"
bpy.context.scene.unit_settings.scale_length=1.0
bpy.ops.object.select_all(action="SELECT")
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/"bee_style_b.blend"))
bpy.ops.export_scene.gltf(filepath=str(OUT/"bee_style_b.glb"),export_format="GLB",use_selection=True,export_yup=True,export_animations=False,export_apply=True)
tris=sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=="MESH" for p in o.data.polygons)
print("BEE_STYLE_B_STATS",json.dumps({"triangles":tris}))
