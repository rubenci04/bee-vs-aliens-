"""Three original lightweight lake variants, not replacements of the existing plants.
Blender 5.2, metre units, GLB Y-up; closed smooth geometry and <=4 flat PBR materials.
"""
from pathlib import Path
import bpy,bmesh,math,json,struct
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/'art_source/blender/levels/level_02_lake/environment'
OUT=ROOT/'assets/models/levels/level_02_lake/environment'
for p in (SRC,OUT):p.mkdir(parents=True,exist_ok=True)
(SRC/'.gdignore').write_text('',encoding='utf-8')
BUDGET=2000
ANIMATION_FPS=30
IDLE_FRAMES=60
BOB_HEIGHT=.035
ROCK_ANGLE=.035
SWAY_ANGLE=.028
TWIST_ANGLE=.015
TILT_ANGLE=.020
PALETTE={'wood':(.47,.30,.15),'cut':(.70,.49,.27),'bark':(.31,.20,.11),
 'stem':(.38,.48,.20),'leaf':(.30,.48,.19),'edge':(.49,.62,.27),
 'seed':(.42,.25,.13),'pink':(.86,.45,.57),'gold':(.87,.65,.20)}
stats=[]
def linear(x):return x/12.92 if x<=.04045 else ((x+.055)/1.055)**2.4
def start(key):
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.context.preferences.filepaths.save_version=0
 scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.render.fps=ANIMATION_FPS
 root=bpy.data.objects.new(key,None);scene.collection.objects.link(root)
 pivot=empty('FloatPivot' if 'totoras' not in key else 'WindPivot',root)
 mats={}
 for name,rgb in PALETTE.items():
  mat=bpy.data.materials.new(name);mat.use_nodes=True
  color=tuple(linear(x) for x in rgb)+(1,)
  mat.diffuse_color=color;bs=mat.node_tree.nodes.get('Principled BSDF')
  bs.inputs['Base Color'].default_value=color;bs.inputs['Roughness'].default_value=.95
  mat.use_backface_culling=True;mats[name]=mat
 return root,pivot,mats
def empty(name,parent,pos=(0,0,0)):
 obj=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(obj);obj.parent=parent;obj.location=pos;return obj
def finish(obj,name,parent,mat):
 obj.name=name;obj.parent=parent;obj.data.materials.append(mat)
 bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 for poly in obj.data.polygons:poly.use_smooth=True
 return obj
def ell(name,pos,scale,parent,mat,segments=12,rings=6):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=pos)
 obj=bpy.context.object;obj.scale=scale;return finish(obj,name,parent,mat)
def tube(name,points,radii,parent,mat,sides=8):
 pts=[Vector(p) for p in points];verts=[];faces=[]
 for i,p in enumerate(pts):
  tangent=(pts[min(i+1,len(pts)-1)]-pts[max(i-1,0)]).normalized()
  basis=tangent.to_track_quat('Z','Y')
  for j in range(sides):verts.append(p+basis@Vector((radii[i]*math.cos(j*math.tau/sides),radii[i]*math.sin(j*math.tau/sides),0)))
 for i in range(len(pts)-1):
  for j in range(sides):faces.append((i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j))
 faces+=[tuple(reversed(range(sides))),tuple((len(pts)-1)*sides+j for j in range(sides))]
 return mesh(name,verts,faces,parent,mat)
def mesh(name,verts,faces,parent,mat):
 data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update()
 bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(data);bm.free()
 obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);return finish(obj,name,parent,mat)
def blade(name,base,side,length,parent,mat):
 # Closed lenticular cross sections: bend rises naturally, then folds out toward a pointed tip.
 points=[];radii=[]
 for i in range(5):
  k=i/4;points.append((base[0]+side*.55*k*k,base[1]+side*.15*k,base[2]+length*(k-.28*k*k)))
  radii.append(.016 if i in (0,4) else .085*math.sin(k*math.pi))
 obj=tube(name,points,radii,parent,mat,6)
 # Flatten the blade in depth, keeping it closed and legible from the gameplay plane.
 for v in obj.data.vertices:v.co.y=base[1]+(v.co.y-base[1])*.32
 return obj
def pad(name,pos,radius,parent,mat):
 # A closed fleshy disc with a real radial notch, not a painted mark.
 count=30;angles=[math.radians(-155+i*310/(count-1)) for i in range(count)]
 ring=[(pos[0]+radius*math.cos(a),pos[1]+radius*.82*math.sin(a),pos[2]) for a in angles]
 verts=[(pos[0],pos[1],pos[2]+.045)]+[(x,y,z+.025) for x,y,z in ring]
 verts+=[(pos[0],pos[1],pos[2]-.025)]+[(x,y,z-.025) for x,y,z in ring]
 offset=count+1;faces=[]
 for i in range(count-1):
  faces.extend([(0,i+1,i+2),(offset,offset+i+2,offset+i+1),(i+1,offset+i+1,offset+i+2,i+2)])
 faces.extend([(0,offset,offset+1,1),(count,offset+count,offset,0)])
 return mesh(name,verts,faces,parent,mat)
def save(key,root,pivot,mats):
 scene=bpy.context.scene;bpy.context.view_layer.update()
 objects=[o for o in root.children_recursive if o.type=='MESH']
 # Root origin is the centre of the lower contact plane, as requested in the asset template.
 points=[o.matrix_world@Vector(v) for o in objects for v in o.bound_box]
 minimum=min(v.z for v in points)
 centre_x=(min(v.x for v in points)+max(v.x for v in points))*.5
 centre_y=(min(v.y for v in points)+max(v.y for v in points))*.5
 for obj in objects:
  obj.location.x-=centre_x;obj.location.y-=centre_y;obj.location.z-=minimum
 water=.18-minimum if 'branch' in key else (.05-minimum if 'lily' in key else 0)
 empty('WaterlineAnchor' if 'totoras' not in key else 'GroundAnchor',root,(0,0,water))
 empty('PlacementAnchor',root)
 tris=sum(len(p.vertices)-2 for o in objects for p in o.data.polygons)
 assert tris<=BUDGET,(key,tris)
 for obj in objects:
  bm=bmesh.new();bm.from_mesh(obj.data)
  assert all(e.is_manifold for e in bm.edges),'Open mesh '+obj.name
  assert all(f.calc_area()>1e-10 for f in bm.faces),'Degenerate '+obj.name
  bm.free()
 for frame in range(0,IDLE_FRAMES+1,5):
  t=frame/IDLE_FRAMES*math.tau;pivot.location.z=0 if 'totoras' in key else BOB_HEIGHT*math.sin(t)
  pivot.rotation_euler=(0,SWAY_ANGLE*math.sin(t),TWIST_ANGLE*math.sin(t)) if 'totoras' in key else (ROCK_ANGLE*math.sin(t),TILT_ANGLE*math.sin(t),0)
  pivot.keyframe_insert('location',frame=frame);pivot.keyframe_insert('rotation_euler',frame=frame)
 pivot.animation_data.action.name='idle';scene.frame_start=0;scene.frame_end=IDLE_FRAMES;scene.frame_set(0)
 bpy.context.view_layer.update();points=[o.matrix_world@Vector(v) for o in objects for v in o.bound_box]
 dims=[round(max(v[i] for v in points)-min(v[i] for v in points),3) for i in (0,2,1)]
 bpy.ops.object.select_all(action='DESELECT');root.select_set(True)
 for o in root.children_recursive:o.select_set(True)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(key+'.glb')),export_format='GLB',use_selection=True,export_yup=True,
  export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True)
 raw=(OUT/(key+'.glb')).read_bytes();data=json.loads(raw[20:20+struct.unpack_from('<I',raw,12)[0]])
 actual=sum(data['accessors'][p['indices']]['count']//3 for m in data['meshes'] for p in m['primitives'])
 assert actual==tris and len(data['materials'])<=4
 assert data.get('animations') and not any('emissiveFactor' in m for m in data['materials'])
 # Editable source with useful camera/light; these helpers are not exported into the GLB.
 scene.world=bpy.data.worlds.new('NeutralStudio');scene.world.color=(.55,.57,.59)
 camdata=bpy.data.cameras.new('StudioCamera');cam=bpy.data.objects.new('StudioCamera',camdata);scene.collection.objects.link(cam)
 target=Vector((0,0,dims[1]*.45));cam.location=(-4,-7,4.5)
 cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();camdata.type='ORTHO';camdata.ortho_scale=max(dims)*1.8;scene.camera=cam
 lightdata=bpy.data.lights.new('SoftKey','AREA');lightdata.energy=700;lightdata.size=7
 light=bpy.data.objects.new('SoftKey',lightdata);scene.collection.objects.link(light);light.location=(-3,-4,7)
 light.rotation_euler=(target-light.location).to_track_quat('-Z','Y').to_euler()
 scene.render.engine='CYCLES';scene.cycles.samples=24
 for material in list(bpy.data.materials):
  if material.users==0:bpy.data.materials.remove(material)
 bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(key+'.blend')))
 stats.append({'id':key,'triangles':tris,'materials':len(data['materials']),'size_godot_xyz_m':dims,
  'source':str((SRC/(key+'.blend')).relative_to(ROOT)).replace('\\','/'),'glb':str((OUT/(key+'.glb')).relative_to(ROOT)).replace('\\','/'),
  'animations':[a.get('name') for a in data['animations']],'waterline_y':round(water,3),'up':'+Y','origin':'base centre','emission':False,'original':True})

key='lvl02_environment_floating_branch_lite_v01';root,pivot,m=start(key)
main=[(-1.55,0,.23),(-.85,-.05,.32),(0,.10,.24),(.80,.17,.30),(1.50,.19,.26)]
tube('branch_main',main,[.12,.18,.19,.16,.10],pivot,m['wood'],12)
tube('branch_fork_a',[(-.42,.06,.28),(-.75,.34,.40),(-1.07,.62,.46)],[.10,.065,.025],pivot,m['wood'],10)
tube('branch_fork_b',[(.42,.14,.28),(.72,-.18,.38),(1.04,-.35,.49)],[.08,.055,.022],pivot,m['bark'],10)
for label,point,radius in [('left',main[0],.11),('right',main[-1],.09)]:
 obj=ell('cut_end_'+label,point,(.012,radius,radius),pivot,m['cut'],12,6)
for i in range(3):
 ell('bark_band_'+str(i),(-.65+i*.63,-.095,.39),(.20,.025,.055),pivot,m['bark'],10,5)
save(key,root,pivot,m)

key='lvl02_environment_totoras_cluster_lite_v01';root,pivot,m=start(key)
for i in range(5):
 x=-.53+i*.25;y=.10 if i%2 else -.11;height=[2.5,1.95,3.05,2.25,2.72][i]
 lean=[-.15,.10,.08,-.08,.18][i]
 tube('stem_'+str(i),[(x,y,0),(x+lean*.4,y,.8),(x+lean,y,height)],[.027,.023,.015],pivot,m['stem'],8)
 ell('seed_head_'+str(i),(x+lean,y,height-.29),(.11,.105,.34),pivot,m['seed'],12,8)
 tube('seed_tip_'+str(i),[(x+lean,y,height),(x+lean+.01,y,height+.24)],[.014,.009],pivot,m['cut'],6)
 blade('leaf_a_'+str(i),(x,y,.08),-1 if i%2 else 1,height*.64,pivot,m['leaf'])
 blade('leaf_b_'+str(i),(x,y+.06,.13),1 if i%2 else -1,height*.42,pivot,m['leaf'])
save(key,root,pivot,m)

key='lvl02_environment_flowering_lily_pads_lite_v01';root,pivot,m=start(key)
pad('lily_pad_main',(-.25,0,.08),1.02,pivot,m['leaf'])
pad('lily_pad_small',(1.02,.40,.07),.53,pivot,m['edge'])
for i in range(5):
 angle=math.radians(-120+i*60)
 end=(-.25+.83*math.cos(angle),.68*math.sin(angle),.11)
 tube('leaf_vein_'+str(i),[(-.25,0,.12),end],[.020,.009],pivot,m['edge'],6)
for i in range(7):
 angle=i*math.tau/7
 obj=ell('flower_outer_petal_'+str(i),(-.25+.26*math.cos(angle),.26*math.sin(angle),.34),(.30,.11,.065),pivot,m['pink'],12,6)
 obj.rotation_euler=(0,-.26,angle);bpy.context.view_layer.objects.active=obj;bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
for i in range(3):
 angle=i*math.tau/3
 obj=ell('flower_inner_petal_'+str(i),(-.25+.10*math.cos(angle),.10*math.sin(angle),.40),(.18,.08,.10),pivot,m['pink'],10,5)
 obj.rotation_euler.z=angle;bpy.context.view_layer.objects.active=obj;bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
ell('flower_heart',(-.25,0,.44),(.115,.11,.09),pivot,m['gold'],12,6)
save(key,root,pivot,m)
(OUT/'lake_botanical_v01_manifest.json').write_text(json.dumps({'budget_per_asset':BUDGET,'assets':stats},indent=2),encoding='utf-8')
print('LAKE_BOTANICAL_OK '+json.dumps(stats),flush=True)
