"""Bee hero v02, original Blender geometry following the supplied four-view sheet.
Never loads/saves v01. Six materials; Y forward in Blender, -Z forward in Godot.
"""
from pathlib import Path
import bpy,bmesh,math,json,struct,hashlib
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/'art_source/blender/shared/bee_hero'
OUT=ROOT/'assets/models/shared/bee_hero'
KEY='shared_hero_bee_v02'
VISUAL_SCALE=1.2
TARGET_VISUAL_LENGTH=1.4
TARGET_RAW_LENGTH=TARGET_VISUAL_LENGTH/VISUAL_SCALE
FULL_MIN=16000;FULL_MAX=18000;HARD_MAX=20000;LITE_MAX=6000
FPS=96;WING_HZ=16.0;WING_AMPLITUDE=.55
for p in (SRC,OUT):p.mkdir(parents=True,exist_ok=True)
(SRC/'.gdignore').write_text('',encoding='utf-8')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version=0
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.render.fps=FPS
materials={}
def lin(c):return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
for name,color,metal,rough,alpha in [
    ('BeeGold',(.94,.64,.12),0,.85,1),('BeeDark',(.22,.115,.07),0,.80,1),
    ('SteelGray',(.59,.59,.54),.65,.38,1),('SteelDark',(.18,.17,.15),.55,.50,1),
    ('Wing',(.86,.81,.68),0,.32,.40),('MuzzleGold',(.97,.67,.18),.2,.40,1)]:
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    rgba=tuple(lin(v) for v in color)+(alpha,);mat.diffuse_color=rgba
    shader=mat.node_tree.nodes['Principled BSDF'];shader.inputs['Base Color'].default_value=rgba
    shader.inputs['Metallic'].default_value=metal;shader.inputs['Roughness'].default_value=rough
    shader.inputs['Alpha'].default_value=alpha
    if name=='Wing':mat.surface_render_method='DITHERED';mat.use_backface_culling=False
    if name=='MuzzleGold':shader.inputs['Emission Color'].default_value=rgba;shader.inputs['Emission Strength'].default_value=.65
    materials[name]=mat
def empty(name,parent=None,pos=(0,0,0)):
    obj=bpy.data.objects.new(name,None);scene.collection.objects.link(obj);obj.parent=parent;obj.location=pos;return obj
model=empty('BeeModel');plates=empty('plates',model)
hips={}
def pivot(name,parent,point):
    obj=empty(name,parent);hips[obj]=Vector(point);return obj
def finish(obj,name,mat,parent=model):
    obj.name=name;bpy.context.view_layer.objects.active=obj
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    obj.parent=parent;obj.data.materials.append(materials[mat])
    for f in obj.data.polygons:f.use_smooth=True
    return obj
def ell(name,pos,scale,mat,parent=model,seg=12,rings=6):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,location=pos)
    obj=bpy.context.object;obj.scale=scale;return finish(obj,name,mat,parent)
def rod(name,a,b,r,mat='BeeDark',parent=model,seg=12,rings=6):
    a,b=Vector(a),Vector(b);bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,location=(a+b)*.5)
    obj=bpy.context.object;obj.scale=(r,r,(b-a).length*.58);obj.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
    return finish(obj,name,mat,parent)
def box(name,pos,size,parent=plates,rotation=(0,0,0),bevel=.025,mat='SteelGray'):
    bpy.ops.mesh.primitive_cube_add(size=1,location=pos);obj=bpy.context.object;obj.scale=size;obj.rotation_euler=rotation
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    mod=obj.modifiers.new('RoundedEdges','BEVEL');mod.width=bevel;mod.segments=2
    bpy.ops.object.modifier_apply(modifier=mod.name);return finish(obj,name,mat,parent)
def torus(name,pos,major,minor,mat,parent=model,seg=24,sides=6):
    bpy.ops.mesh.primitive_torus_add(major_segments=seg,minor_segments=sides,major_radius=major,minor_radius=minor,location=pos,rotation=(math.pi/2,0,0))
    return finish(bpy.context.object,name,mat,parent)
def lathe_y(name,profile,mat,parent=model,center=(0,0,0),segments=48,stripes=False):
    vertices=[];faces=[];cx,cy,cz=center
    for y,r in profile:
        for i in range(segments):
            a=i/segments*math.tau;vertices.append((cx+r*math.cos(a),cy+y,cz+r*math.sin(a)))
    for j in range(len(profile)-1):
        for i in range(segments):faces.append((j*segments+i,(j+1)*segments+i,(j+1)*segments+(i+1)%segments,j*segments+(i+1)%segments))
    # Profile goes toward -Y; normals are recomputed below to handle both orders.
    faces.append(tuple(reversed(range(segments))))
    faces.append(tuple((len(profile)-1)*segments+i for i in range(segments)))
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces);mesh.update()
    obj=bpy.data.objects.new(name,mesh);scene.collection.objects.link(obj);obj.parent=parent;mesh.materials.append(materials[mat])
    if stripes:
        mesh.materials.append(materials['BeeDark'])
        for j in range(len(profile)-1):
            y=(profile[j][0]+profile[j+1][0])*.5
            for i in range(segments):mesh.polygons[j*segments+i].material_index=1 if (-.24<=y<=-.18 or -.42<=y<=-.36 or -.60<=y<=-.54) else 0
    bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free()
    for f in mesh.polygons:f.use_smooth=len(f.vertices)==4
    return obj

# Heroic core: bigger head, wider thorax, smooth clear striped abdomen.
ell('Thorax',(0,0,0),(.23,.235,.21),'BeeGold',seg=36,rings=18)
ell('Head',(0,.30,.035),(.27,.245,.27),'BeeGold',seg=48,rings=24)
lathe_y('Abdomen',[(-.08,.11),(-.12,.16),(-.18,.20),(-.24,.23),(-.30,.24),(-.36,.23),(-.42,.218),(-.48,.193),(-.54,.158),(-.60,.117),(-.64,.078)],'BeeGold',center=(0,0,-.035),stripes=True)
# Decisive inset eyes and angled brows; no expensive fur detail.
for side,label in [(-1,'L'),(1,'R')]:
    ell('Eye_'+label,(side*.126,.514,.087),(.105,.029,.097),'BeeDark',seg=20,rings=10)
    ell('EyeGlint_'+label,(side*.117,.542,.121),(.019,.008,.024),'SteelGray',seg=8,rings=4)
    rod('Brow_'+label,(side*.043,.538,.135),(side*.216,.442,.206),.032,seg=12,rings=6)
    rod('Mandible_'+label,(0,.540,-.080),(side*.083,.515,-.108),.009,seg=12,rings=6)
    rod('AntennaBase_'+label,(side*.10,.35,.254),(side*.12,.43,.40),.020,seg=12,rings=6)
    if side<0:rod('AntennaTip_'+label,(side*.12,.43,.40),(side*.20,.46,.43),.024,seg=12,rings=6)
    else:rod('AntennaTip_'+label,(side*.12,.43,.40),(side*.13,.47,.42),.022,seg=12,rings=6)
    for i,y in enumerate([.12,-.025,-.17]):
        a=(side*.16,y,-.14);b=(side*.30,y+.045,-.29);c=(side*.27,y+.095,-.47)
        rod('Leg_%s_%d_Upper'%(label,i),a,b,.036,seg=12,rings=6)
        ell('LegJoint_%s_%d'%(label,i),b,(.038,.038,.038),'BeeDark',seg=12,rings=6)
        rod('Leg_%s_%d_Lower'%(label,i),b,c,.032,seg=12,rings=6)
        rod('Foot_%s_%d'%(label,i),c,(side*.26,y+.105,-.54),.033,seg=12,rings=6)
    wing=pivot('Wing_'+label,model,(side*.15,-.025,.18))
    # Both pairs follow the legacy two independent hinge names.
    blade=ell('WingMembrane_'+label,(side*.33,-.26,.55),(.13,.38,.014),'Wing',wing,seg=20,rings=8)
    blade.rotation_euler.x=-.70;blade.rotation_euler.z=side*.36
    bpy.context.view_layer.objects.active=blade;bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    hind=ell('WingHind_'+label,(side*.30,-.25,.33),(.11,.26,.012),'Wing',wing,seg=20,rings=8)
    hind.rotation_euler.x=-.43;hind.rotation_euler.z=side*.44
    bpy.context.view_layer.objects.active=hind;bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    rod('WingVein_'+label,(side*.16,-.04,.22),(side*.36,-.40,.70),.006,'SteelGray',wing,seg=8,rings=4)

# Separate torso/forehead armor as in the sheet, never a helmet.
box('dorsal_plate',(0,-.02,.215),(.28,.28,.055),bevel=.02)
box('chest_plate',(0,.165,-.132),(.30,.095,.15),rotation=(.15,0,0),bevel=.025)
box('forehead_plate',(0,.435,.252),(.092,.042,.09),bevel=.009)
for side in (-1,1):
    box('flank_plate_'+str(side),(side*.201,-.015,-.01),(.045,.22,.20),rotation=(0,side*.12,0),bevel=.016)
    for i in range(2):ell('armor_rivet_%s_%d'%(side,i),(side*.09,.219,-.098-i*.065),(.009,.008,.009),'SteelGray',plates,seg=8,rings=4)
empty('helmet_socket',model,(0,.30,.322))

# Five overlapping steel drill bands; their rivets rotate with the same mesh origin.
stinger=pivot('Stinger',model,(0,-.60,-.035))
drill=lathe_y('stinger_drill',[(-.59,.083),(-.65,.079),(-.72,.060),(-.80,.044),(-.89,.018),(-.95,.002)],'SteelDark',stinger,center=(0,0,-.035),segments=32)
hips[drill]=Vector((0,-.60,-.035))
for band in range(5):
    y=-.59-band*.061;r=.091-band*.016
    lathe_y('drill_band_%02d'%band,[(y,r),(y-.018,r),(y-.073,max(.012,r-.016))],'SteelGray',drill,center=(0,0,-.035),segments=32)
    for j in range(6):
        a=j/6*math.tau+.2
        ell('drill_rivet_%02d_%02d'%(band,j),(r*math.cos(a),y-.025,-.035+r*math.sin(a)),(.008,.008,.008),'SteelGray',drill,seg=6,rings=4)
tip=empty('stinger_tip',drill,(0,-.952,-.035));tip.rotation_euler.z=math.pi

# Steel lateral thrusters. Rounded dark wells, no modeled fire or blue emission.
for side,label in [(-1,'L'),(1,'R')]:
    jet=pivot('thruster_'+label,model,(side*.285,-.025,.065))
    lathe_y('thruster_shell_'+label,[(.12,.085),(.09,.12),(-.14,.12),(-.24,.10),(-.26,.076),(-.19,.063)],'SteelGray',jet,center=(side*.285,0,.065),segments=32)
    torus('thruster_rim_'+label,(side*.285,-.26,.065),.078,.016,'SteelGray',jet,seg=24,sides=6)
    ell('thruster_well_'+label,(side*.285,-.193,.065),(.063,.010,.063),'SteelDark',jet,seg=16,rings=8)
    for fin in (-1,1):box('thruster_fin_%s_%s'%(label,fin),(side*.285,-.065,.065+fin*.14),(.11,.13,.035),jet,bevel=.009)
    for i in range(3):box('thruster_vent_%s_%d'%(label,i),(side*.403,-.09+i*.054,.07),(.015,.020,.078),jet,bevel=.003,mat='SteelDark')
    nozzle=empty('nozzle_'+label,jet,(side*.285,-.283,.065));nozzle.rotation_euler.z=math.pi

# The right antenna blaster has a forward-facing muzzle with the only emission.
gun=pivot('antenna_R_blaster',model,(.13,.477,.414))
box('blaster_receiver',(.13,.471,.414),(.112,.113,.107),gun,bevel=.015)
lathe_y('blaster_barrel',[(.49,.043),(.61,.043),(.624,.040),(.624,.031),(.586,.029)],'SteelGray',gun,center=(.13,0,.414),segments=32)
torus('blaster_muzzle_rim',(.13,.626,.414),.034,.007,'SteelDark',gun,seg=24,sides=6)
torus('blaster_muzzle_gold',(.13,.628,.414),.027,.004,'MuzzleGold',gun,seg=24,sides=6)
ell('blaster_bore',(.13,.588,.414),(.029,.006,.029),'SteelDark',gun,seg=16,rings=8)
empty('muzzle',gun,(.13,.637,.414))

# Move origins deepest-first. Mesh drill origin is its spin axis, not scene zero.
for node in reversed(list(hips)):
    point=hips[node]
    if node.type=='MESH':
        for v in node.data.vertices:v.co-=point
    for child in node.children:child.location-=point
    node.location=point
bpy.context.view_layer.update()
meshes=[o for o in model.children_recursive if o.type=='MESH']
points=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
factor=TARGET_RAW_LENGTH/(max(v.y for v in points)-min(v.y for v in points))
for obj in model.children_recursive:
    obj.location*=factor
    if obj.type=='MESH':
        for v in obj.data.vertices:v.co*=factor
bpy.context.view_layer.update()

animated=[bpy.data.objects['Wing_L'],bpy.data.objects['Wing_R'],drill]
CLIPS={'wingbeat':48,'drill_spin':48}
for clip,frames in CLIPS.items():
    for node in animated:
        action=bpy.data.actions.new(clip+'_'+node.name);node.animation_data_create();node.animation_data.action=action
        for frame in range(frames+1):
            t=frame/FPS;node.rotation_euler=(0,0,0)
            if node.name.startswith('Wing_'):node.rotation_euler.y=(1 if node.name.endswith('R') else -1)*WING_AMPLITUDE*math.sin(t*math.tau*WING_HZ)
            elif clip=='drill_spin':node.rotation_euler.y=frame/frames*math.tau
            node.keyframe_insert('rotation_euler',frame=frame)
        track=node.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,0,action);node.animation_data.action=None;track.mute=True
for node in animated:
    for track in node.animation_data.nla_tracks:track.mute=False
scene.frame_set(0)

def triangulate_and_validate():
    for obj in meshes:
        bm=bmesh.new();bm.from_mesh(obj.data)
        bmesh.ops.triangulate(bm,faces=list(bm.faces))
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        assert all(e.is_manifold for e in bm.edges),'Open geometry '+obj.name
        assert all(f.calc_area()>1e-12 for f in bm.faces),'Degenerate '+obj.name
        bm.to_mesh(obj.data);bm.free()
    return sum(len(o.data.polygons) for o in meshes)

def export(name):
    bpy.ops.object.select_all(action='DESELECT');model.select_set(True)
    for obj in model.children_recursive:obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_yup=True,
        export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True)
    raw=(OUT/(name+'.glb')).read_bytes();n=struct.unpack_from('<I',raw,12)[0];gltf=json.loads(raw[20:20+n])
    actual=sum(gltf['accessors'][p['indices']]['count']//3 for node in gltf['nodes'] if 'mesh' in node for p in gltf['meshes'][node['mesh']]['primitives'])
    assert len(gltf['materials'])==6
    assert {a['name'] for a in gltf['animations']}==set(CLIPS)
    bpy.context.view_layer.update();p=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    size=[max(v[i] for v in p)-min(v[i] for v in p) for i in range(3)]
    return {'id':name,'triangles':actual,'materials':6,'raw_length_height_width_m':[round(size[1],6),round(size[2],6),round(size[0],6)],
        'visual_scale':VISUAL_SCALE,'visual_length_height_width_m':[round(size[1]*VISUAL_SCALE,6),round(size[2]*VISUAL_SCALE,6),round(size[0]*VISUAL_SCALE,6)],
        'forward_godot':'-Z','up_godot':'+Y','origin':'thorax center','animations':{k:f/FPS for k,f in CLIPS.items()},'wing_frequency_hz':WING_HZ,
        'source':str((SRC/(name+'.blend')).relative_to(ROOT)).replace('\\','/'),'glb':str((OUT/(name+'.glb')).relative_to(ROOT)).replace('\\','/')}

# Portable studio source; native game toon is applied only by the art lab wrapper.
world=bpy.data.worlds.new('NeutralStudio');scene.world=world;world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(.55,.55,.55,1)
camdata=bpy.data.cameras.new('StudioCamera');camera=bpy.data.objects.new('StudioCamera',camdata);scene.collection.objects.link(camera)
camera.location=(2.5,3,1.8);camera.rotation_euler=(Vector((0,0,.05))-camera.location).to_track_quat('-Z','Y').to_euler();camdata.type='ORTHO';camdata.ortho_scale=1.8;scene.camera=camera
for name,pos,energy in [('Key',(2,3,4),400),('Rim',(-2,-2,3),250)]:
    lightdata=bpy.data.lights.new(name,'AREA');lightdata.energy=energy;lightdata.shape='DISK';lightdata.size=3
    light=bpy.data.objects.new(name,lightdata);scene.collection.objects.link(light);light.location=pos;light.rotation_euler=(-light.location).to_track_quat('-Z','Y').to_euler()
scene.view_settings.view_transform='Standard';scene.view_settings.look='None'
full=triangulate_and_validate();print('FULL_PRE_EXPORT',full,flush=True)
assert full<=HARD_MAX,full
stats=[export(KEY)]
for node in animated:
    for track in node.animation_data.nla_tracks:track.mute=track.name!='wingbeat'
scene.frame_set(0);bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(KEY+'.blend')))
# Keep all named pieces and animations. Reduce new mesh copies only, never v01.
for obj in meshes:
    obj.data=obj.data.copy();bpy.context.view_layer.objects.active=obj
    ratio=max(.28,min(1,8/max(1,len(obj.data.polygons))))
    mod=obj.modifiers.new('LiteReduction','DECIMATE');mod.ratio=ratio
    bpy.ops.object.modifier_apply(modifier=mod.name)
lite=triangulate_and_validate();assert lite<=LITE_MAX,lite
for node in animated:
    for track in node.animation_data.nla_tracks:track.mute=False
stats.append(export(KEY+'_lite'))
for node in animated:
    for track in node.animation_data.nla_tracks:track.mute=track.name!='wingbeat'
scene.frame_set(0);bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(KEY+'_lite.blend')))
(OUT/'bee_hero_v02_manifest.json').write_text(json.dumps({'assets':stats,'target_full':[FULL_MIN,FULL_MAX],'hard_max':HARD_MAX,'lite_max':LITE_MAX,'source_scale_factor':factor,'emission_only':'blaster_muzzle_gold'},indent=2),encoding='utf-8')
print('BEE_HERO_V02_OK '+json.dumps(stats),flush=True)
