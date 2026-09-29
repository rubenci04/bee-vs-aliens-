"""Alien Probe V01. Blender +Y forward, Z up. No rig or gameplay data."""
from pathlib import Path
import bpy, math, json
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/"art_source/blender/bee_prototype"
OUT=ROOT/"assets/models/bee_prototype"
SRC.mkdir(parents=True,exist_ok=True); OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action="SELECT"); bpy.ops.object.delete(use_global=False)
bpy.context.preferences.filepaths.save_version=0
mats={}
for name,color in [
 ("AlienMetal",(.12,.19,.20,1)),("Panel",(.23,.29,.27,1)),
 ("Black",(.018,.025,.027,1)),("Cyan",(.04,.75,.71,1)),
 ("Lens",(.02,.16,.19,1))]:
 m=bpy.data.materials.new(name);m.diffuse_color=color
 bs=next(n for n in m.node_tree.nodes if n.type=="BSDF_PRINCIPLED")
 bs.inputs["Base Color"].default_value=color;bs.inputs["Roughness"].default_value=.72
 if name=="Cyan":
  bs.inputs["Emission Color"].default_value=color;bs.inputs["Emission Strength"].default_value=1.2
 mats[name]=m
root=bpy.data.objects.new("ProbeModel",None);bpy.context.collection.objects.link(root)
def finish(o,name,mat):
 o.name=name;o.data.materials.append(mats[mat]);o.parent=root
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 for p in o.data.polygons:p.use_smooth=False
 return o
def ell(name,pos,scale,mat,segments=12,rings=6):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=pos)
 o=bpy.context.object;o.scale=scale
 return finish(o,name,mat)
def axial(name,a,b,r1,r2,mat,vertices=12):
 a,b=Vector(a),Vector(b);d=b-a
 bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r1,radius2=r2,depth=d.length,location=(a+b)/2)
 o=bpy.context.object;o.rotation_mode="QUATERNION";o.rotation_quaternion=d.to_track_quat("Z","Y")
 return finish(o,name,mat)
def prism(name,points,thickness,mat):
 verts=[(x,y,z+dz) for dz in [-thickness/2,thickness/2] for x,y,z in points]
 n=len(points);faces=[tuple(reversed(range(n))),tuple(range(n,n*2))]
 faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 me=bpy.data.meshes.new(name+"Mesh");me.from_pydata(verts,[],faces);me.materials.append(mats[mat]);me.update()
 o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);o.parent=root
 return o
ell("Hull",(0,-.04,0),(.34,.42,.25),"AlienMetal",12,8)
ell("UpperPanel",(0,-.09,.17),(.29,.32,.135),"Panel",10,4)
ell("LowerCoreHousing",(0,-.08,-.20),(.20,.23,.13),"Black",10,4)
ell("Core",(0,-.08,-.28),(.12,.14,.065),"Cyan",10,4)
# One optical sensor, visible in profile through its forward projection.
axial("SensorHousing",(0,.25,.10),(0,.43,.10),.16,.135,"Black")
ell("SensorLens",(0,.43,.10),(.112,.065,.112),"Lens",10,4)
ell("SensorIris",(0,.49,.10),(.08,.035,.08),"Cyan",10,4)
# Short recessed emitter near the original central projectile axis.
axial("EmitterHousing",(0,.16,-.09),(0,.47,-.09),.11,.095,"Panel")
axial("EmitterSocket",(0,.465,-.09),(0,.49,-.09),.074,.074,"Black")
axial("EmitterAperture",(0,.492,-.09),(0,.501,-.09),.043,.043,"Cyan")
# Three broad geometric stabilizers, no rotor or insect wings.
for side,label in [(-1,"L"),(1,"R")]:
 prism("Stabilizer_"+label,[(side*.25,.08,.02),(side*.61,-.12,.02),(side*.48,-.38,.02),(side*.25,-.23,.02)],.095,"Panel")
 axial("Thruster_"+label,(side*.47,-.20,-.055),(side*.47,-.20,-.12),.07,.055,"Black",10)
 axial("ThrusterCore_"+label,(side*.47,-.20,-.122),(side*.47,-.20,-.132),.037,.037,"Cyan",10)
prism("RearStabilizer",[(-.12,-.30,.02),(-.08,-.69,.02),(.08,-.69,.02),(.12,-.30,.02)],.09,"AlienMetal")
# Independent low-poly rotor collar about the vertical axis.
bpy.ops.mesh.primitive_torus_add(major_segments=12,minor_segments=4,location=(0,-.08,-.24),major_radius=.18,minor_radius=.018)
finish(bpy.context.object,"CoreRing","Panel")
bpy.context.scene.unit_settings.system="METRIC";bpy.context.scene.unit_settings.scale_length=1
bpy.ops.object.select_all(action="SELECT")
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/"alien_probe_visual.blend"))
bpy.ops.export_scene.gltf(filepath=str(OUT/"alien_probe_visual.glb"),export_format="GLB",use_selection=True,export_yup=True,export_animations=False)
objs=[o for o in bpy.context.scene.objects if o.type=="MESH"]
pts=[o.matrix_world@Vector(v) for o in objs for v in o.bound_box]
print("PROBE_STATS",json.dumps({"triangles":sum(len(p.vertices)-2 for o in objs for p in o.data.polygons),"objects":len(objs),"materials":len(mats),"dimensions_blender":[round(max(p[i] for p in pts)-min(p[i] for p in pts),3) for i in range(3)]}))

