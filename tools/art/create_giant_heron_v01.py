"""Original articulated alien-controlled heron. Blender 5.2; no external library assets.
Exports PBR GLBs with an embedded flat palette; saves editable source with studio camera and lights.
"""
from pathlib import Path
import bpy, bmesh, math, json, struct, zlib
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
KEY = 'lvl02_enemy_giant_heron_v01'
SRC = ROOT/'art_source/blender/levels/level_02_lake/enemies'
OUT = ROOT/'assets/models/levels/level_02_lake/enemies'
PREVIEW = ROOT/'concept_art/levels/level_02/giant_heron'
BUDGET = 6000
for directory in (SRC,OUT,PREVIEW): directory.mkdir(parents=True,exist_ok=True)
(SRC/'.gdignore').write_text('',encoding='utf-8')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version = 0
scene=bpy.context.scene
scene.unit_settings.system='METRIC'
scene.render.engine='CYCLES'
scene.cycles.samples=24
scene.render.resolution_x=1100; scene.render.resolution_y=800
scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('NeutralStudio')
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.65,.67,.69,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.45
scene.view_settings.view_transform='Standard'
scene.view_settings.look='None'

def linear(c): return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
def rgba(c): return tuple(linear(v) for v in c)+(1,)
COLORS={'body':(.62,.66,.66),'dark':(.24,.29,.32),'gold':(.78,.57,.22),'eye':(.95,.71,.18),'pupil':(.055,.06,.07),'cream':(.87,.85,.73)}
# A tiny embedded flat palette keeps the four-material asset portable in native Godot/glTF viewers.
palette_keys=['body','dark','gold','eye','pupil','cream','body','body']
def png_chunk(kind,data):
    return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
pixels=bytes(round(v*255) for key in palette_keys for v in COLORS[key])
png=b'\x89PNG\r\n\x1a\n'+png_chunk(b'IHDR',struct.pack('>IIBBBBB',8,2,8,2,0,0,0))+png_chunk(b'sRGB',b'\x00')+png_chunk(b'IDAT',zlib.compress((b'\x00'+pixels)*2))+png_chunk(b'IEND',b'')
palette_path=SRC/(KEY+'_palette.png');palette_path.write_bytes(png)
palette=bpy.data.images.load(str(palette_path));palette.pack()
materials={}
for name,color in [('nature',(1,1,1)),('graphite',(.20,.23,.28)),('cyan',(.12,.80,.88)),('violet',(.57,.30,.75))]:
    m=bpy.data.materials.new(name); m.use_nodes=True; m.diffuse_color=rgba(color)
    bs=m.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=rgba(color)
    bs.inputs['Roughness'].default_value=.85
    if name=='nature':
        attr=m.node_tree.nodes.new('ShaderNodeTexImage'); attr.image=palette; attr.interpolation='Closest'
        m.node_tree.links.new(attr.outputs['Color'],bs.inputs['Base Color'])
    if name=='cyan':
        bs.inputs['Emission Color'].default_value=rgba(color); bs.inputs['Emission Strength'].default_value=.65
    materials[name]=m

def empty(name,parent=None,pos=(0,0,0)):
    o=bpy.data.objects.new(name,None); scene.collection.objects.link(o); o.parent=parent; o.location=pos; return o
model=empty(KEY)
fauna=empty('NaturalFauna',model)
implant=empty('implant',model)
model['license']='Original Bee Alien project asset; generated in Blender, no external content'
model['forward_godot']='-X'; model['up_godot']='+Y'; model['tri_budget']=BUDGET

def finish(o,name,parent,mat='nature',color='body'):
    o.name=name
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    o.parent=parent
    o.data.materials.append(materials[mat])
    for poly in o.data.polygons: poly.use_smooth=True
    if mat=='nature':
        colors=o.data.color_attributes.new(name='Palette',type='FLOAT_COLOR',domain='CORNER')
        value=rgba(COLORS[color])
        for item in colors.data: item.color=value
        for loop in o.data.uv_layers.active.data: loop.uv=((palette_keys.index(color)+.5)/8,.5)
    return o

def ell(name,pos,scale,parent,mat='nature',color='body',segments=12,rings=6):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=pos)
    o=bpy.context.object; o.scale=scale; return finish(o,name,parent,mat,color)

def limb(name,a,b,r,parent,mat='nature',color='body'):
    a,b=Vector(a),Vector(b)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8,ring_count=6,location=(a+b)*.5)
    o=bpy.context.object; o.scale=(r,r,(b-a).length*.55)
    o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
    return finish(o,name,parent,mat,color)

def plate(name,pos,size,parent,rotation=(0,0,0),bevel=.08):
    bpy.ops.mesh.primitive_cube_add(size=1,location=pos)
    o=bpy.context.object; o.scale=size; o.rotation_euler=rotation
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    mod=o.modifiers.new('RoundedEdges','BEVEL'); mod.width=bevel; mod.segments=2
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(o,name,parent,'graphite')

def localize(o):
    world=o.matrix_world.copy(); o.matrix_world=world
    # Set parent inverse so all authored geometry stays at its anatomical world position.
    if o.parent: o.matrix_parent_inverse=o.parent.matrix_world.inverted()
    o.matrix_world=world

body_pivot=empty('BodyPivot',fauna)
body=ell('body',(.35,0,2.65),(.91,.53,.62),body_pivot,segments=20,rings=10)
ell('chest',(-.21,0,2.71),(.49,.49,.63),body_pivot,color='cream')
hips={}
def joint(name,parent,point):
    n=empty(name,parent);hips[n]=Vector(point);return n
neck_base=joint('NeckBase',body_pivot,(-.39,0,2.93))
neck_mid=joint('NeckMid',neck_base,(-.77,0,3.48))
neck_upper=joint('NeckUpper',neck_mid,(-.37,0,4.10))
head=joint('HeadPivot',neck_upper,(-1.04,0,4.55))
limb('neck_lower',(-.39,0,2.93),(-.77,0,3.48),.21,neck_base,color='cream')
limb('neck_middle',(-.77,0,3.48),(-.37,0,4.10),.17,neck_mid,color='cream')
limb('neck_upper',(-.37,0,4.10),(-1.04,0,4.55),.15,neck_upper,color='cream')
ell('neck_joint_mid',(-.77,0,3.48),(.17,.17,.17),neck_mid,color='cream')
ell('neck_joint_upper',(-.37,0,4.10),(.145,.145,.145),neck_upper,color='cream')
ell('head',(-1.25,0,4.62),(.41,.26,.27),head)
jaw=joint('JawPivot',head,(-1.52,0,4.51))
def wedge(name,a,b,width,height,parent,color):
    x,y,z=a;tx,ty,tz=b
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata([(x,y-width,z-height),(x,y+width,z-height),(x,y+width,z+height),(x,y-width,z+height),(tx,ty,tz)],[],[(3,2,1,0),(0,1,4),(1,2,4),(2,3,4),(3,0,4)])
    for poly in mesh.polygons: poly.flip()
    mesh.uv_layers.new();obj=bpy.data.objects.new(name,mesh);scene.collection.objects.link(obj)
    bpy.context.view_layer.objects.active=obj;obj.select_set(True)
    return finish(obj,name,parent,color=color)
wedge('beak_upper',(-1.55,0,4.61),(-2.88,0,4.56),.14,.12,head,'gold')
wedge('beak_lower',(-1.54,0,4.49),(-2.81,0,4.54),.12,.055,jaw,'gold')
for side in (-1,1):
    label='L' if side<0 else 'R'
    ell('eye_'+label,(-1.35,side*.235,4.69),(.14,.053,.10),head,color='eye',segments=10,rings=6)
    ell('pupil_'+label,(-1.40,side*.280,4.69),(.040,.025,.078),head,color='pupil',segments=8,rings=6)
    brow=limb('angry_brow_'+label,(-1.49,side*.26,4.73),(-1.16,side*.24,4.86),.051,head,color='dark')
    limb('crest_'+label,(-.99,side*.10,4.81),(-.53,side*.18,4.84),.042,head,color='dark')
tail=joint('TailPivot',body_pivot,(1.01,0,2.65))
for i in range(3):limb('tail_feather_'+str(i),(1.00,(i-1)*.14,2.64),(1.53,(i-1)*.18,2.45),.095,tail,color='dark')
wing_joints=[];leg_joints=[]
for side in (-1,1):
    label='L' if side<0 else 'R'
    shoulder=joint('WingShoulder_'+label,body_pivot,(.16,side*.43,2.91))
    elbow=joint('WingElbow_'+label,shoulder,(.51,side*1.06,2.81))
    wrist=joint('WingWrist_'+label,elbow,(-.02,side*1.72,2.93))
    wing_joints += [shoulder,elbow,wrist]
    limb('wing_upper_'+label,(.16,side*.43,2.91),(.51,side*1.06,2.81),.21,shoulder)
    limb('wing_forearm_'+label,(.51,side*1.06,2.81),(-.02,side*1.72,2.93),.17,elbow)
    for i in range(4):
        limb(f'secondary_{label}_{i}',(.31,side*(.62+i*.18),2.86),(1.19,side*(.63+i*.23),2.65),.115,elbow,color='body')
    for i in range(5):
        limb(f'primary_{label}_{i}',(-.02,side*(1.48+i*.11),2.91),(.64+i*.16,side*(2.08+i*.14),2.76-i*.05),.10,wrist,color='dark')
    hip=joint('LegHip_'+label,body_pivot,(.23,side*.30,2.21))
    knee=joint('LegKnee_'+label,hip,(-.07,side*.37,1.31))
    ankle=joint('LegAnkle_'+label,knee,(.38,side*.38,.32))
    toe=joint('ToePivot_'+label,ankle,(.11,side*.38,.12))
    leg_joints += [hip,knee,ankle,toe]
    limb('thigh_'+label,(.23,side*.30,2.21),(-.07,side*.37,1.31),.095,hip,color='gold')
    limb('shin_'+label,(-.07,side*.37,1.31),(.38,side*.38,.32),.068,knee,color='gold')
    ell('knee_joint_'+label,(-.07,side*.37,1.31),(.085,.085,.085),knee,color='gold',segments=8,rings=6)
    ell('ankle_joint_'+label,(.38,side*.38,.32),(.074,.074,.074),ankle,color='gold',segments=8,rings=6)
    limb('foot_'+label,(.38,side*.38,.32),(.11,side*.38,.12),.073,ankle,color='gold')
    for i in range(3):limb(f'toe_{label}_{i}',(.11,side*.38,.12),(-.41-(.15 if i==1 else 0),side*.38+(i-1)*.20,.055),.039,toe,color='gold')
    limb('rear_toe_'+label,(.15,side*.38,.10),(.48,side*.40,.055),.035,toe,color='gold')
    plate('implant_wing_cuff_'+label,(.34,side*.68,3.08),(.38,.38,.15),shoulder,bevel=.04)
    ell('implant_wing_node_'+label,(.33,side*.68,3.19),(.10,.10,.045),shoulder,'violet',segments=10,rings=6)
    empty('WindAnchor_'+label,wrist,(.45,side*2.12,2.84))
plate('implant_dorsal',(.44,0,3.29),(1.05,.64,.17),implant,bevel=.055)
ell('implant_core',(.38,0,3.42),(.23,.23,.085),implant,'cyan')
plate('implant_neck_collar',(-.75,0,3.48),(.29,.40,.20),neck_mid,bevel=.04)
empty('BeakTipAnchor',head,(-2.88,0,4.56))
empty('ImplantAnchor',model,(.38,0,3.42));empty('BodyAnchor',model,(.35,0,2.65));empty('GroundAnchor',model)
# Work deepest-first: geometry is authored in a shared coordinate space.
for node in reversed(list(hips)):
    point=hips[node]
    for child in node.children:child.location-=point
    node.location=point
implant.parent=body_pivot
animated=[body_pivot,neck_base,neck_mid,neck_upper,head,jaw,tail]+wing_joints+leg_joints
rest={node:node.location.copy() for node in animated}
CLIPS={'idle':60,'walk':48,'fly':36,'wind_attack':60,'peck_attack':48}
scene.render.fps=30
for clip,frames in CLIPS.items():
    for node in animated:
        act=bpy.data.actions.new(clip+'_'+node.name);node.animation_data_create();node.animation_data.action=act
        for f in range(0,frames+1,3):
            t=f/frames;phase=t*math.tau;wave=math.sin(t*math.pi)**2
            node.location=rest[node];node.rotation_euler=(0,0,0)
            side=-1 if node.name.endswith('L') else 1
            if clip=='idle':
                if node==body_pivot:node.location.z+=.035*math.sin(phase)
                if node in [neck_base,neck_mid,neck_upper,head]:node.rotation_euler.y=.025*math.sin(phase)
                if node in wing_joints:node.rotation_euler.x=side*.025*math.sin(phase)
                if node in leg_joints:node.rotation_euler.y=.008*math.sin(phase)
                if node==tail:node.rotation_euler.z=.035*math.sin(phase)
            elif clip=='walk':
                if node==body_pivot:node.location.z+=.05*(1-math.cos(phase*2))
                if node in leg_joints:
                    offset=phase+(math.pi if side>0 else 0)
                    amp=.24 if node.name.startswith('LegHip') else .18
                    node.rotation_euler.y=amp*math.sin(offset)
                if node in [neck_base,neck_mid,neck_upper,head]:node.rotation_euler.y=.04*math.sin(phase)
                if node in wing_joints:node.rotation_euler.x=side*.035*math.sin(phase)
                if node==tail:node.rotation_euler.z=.07*math.sin(phase)
            elif clip in ['fly','wind_attack']:
                # Wind attack has a 0.6 s windup before the powerful downstroke.
                flap=math.sin(phase) if clip=='fly' else math.sin(phase)*(.45 if t<.30 else 1.0)
                if node.name.startswith('WingShoulder'):node.rotation_euler.x=side*.82*flap
                if node.name.startswith('WingElbow'):node.rotation_euler.x=side*.38*flap
                if node.name.startswith('WingWrist'):node.rotation_euler.x=side*.24*flap;node.rotation_euler.z=side*.12*flap
                if node in leg_joints:node.rotation_euler.y=(-.65 if node.name.startswith('LegHip') else .35)*wave
                if node==body_pivot:node.location.z+=.16*wave
                if node in [neck_base,neck_mid,neck_upper,head]:node.rotation_euler.y=.08*math.sin(phase)
                if node==tail:node.rotation_euler.y=.12*flap
            else:
                # Telegraph head retract, thrust the complete articulated neck, recover.
                thrust=max(0,1-abs(t-.55)/.22)
                if node==neck_base:node.rotation_euler.y=-.72*thrust
                if node==neck_mid:node.rotation_euler.y=.20*thrust
                if node==neck_upper:node.rotation_euler.y=-.32*thrust
                if node==head:node.rotation_euler.y=.45*thrust
                if node==jaw:node.rotation_euler.y=-.18*wave
                if node in wing_joints:node.rotation_euler.x=side*.15*wave
                if node in leg_joints:node.rotation_euler.y=.08*wave
                if node==body_pivot:node.location.x-=.32*thrust
                if node==tail:node.rotation_euler.y=.12*wave
            node.keyframe_insert('location',frame=f);node.keyframe_insert('rotation_euler',frame=f)
        track=node.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,0,act)
        node.animation_data.action=None;track.mute=True
for node in animated:
    for track in node.animation_data.nla_tracks:track.mute=False
scene.frame_set(0)


def foreign(o):
    while o and o!=model:
        if o.name.startswith('implant'):return True
        o=o.parent
    return False

meshes=[o for o in model.children_recursive if o.type=='MESH']
tris=sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons)
assert tris<=BUDGET,(tris,BUDGET)
for o in meshes:
    bm=bmesh.new(); bm.from_mesh(o.data)
    assert all(e.is_manifold for e in bm.edges),'Open geometry '+o.name
    assert all(f.calc_area()>1e-10 for f in bm.faces),'Degenerate '+o.name
    bm.free()
bpy.context.view_layer.update()
bounds=[o.matrix_world@Vector(v) for o in meshes for v in o.bound_box]
dimensions=[max(p[i] for p in bounds)-min(p[i] for p in bounds) for i in range(3)]

def size_for(liberated):
    selected=[o for o in meshes if not liberated or not foreign(o)]
    points=[o.matrix_world@Vector(v) for o in selected for v in o.bound_box]
    dims=[max(v[i] for v in points)-min(v[i] for v in points) for i in range(3)]
    return [round(dims[0],3),round(dims[2],3),round(dims[1],3)]

def export(name,liberated=False):
    bpy.ops.object.select_all(action='DESELECT')
    model.select_set(True)
    for o in model.children_recursive:
        if not liberated or not foreign(o): o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,
        export_vertex_color='NONE',export_all_vertex_colors=False,
        export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True)
    raw=(OUT/(name+'.glb')).read_bytes(); length=struct.unpack_from('<I',raw,12)[0]
    data=json.loads(raw[20:20+length])
    actual=sum(data['accessors'][p['indices']]['count']//3 for m in data['meshes'] for p in m['primitives'])
    clips=[a.get('name') for a in data.get('animations',[])]
    assert set(clips)==set(CLIPS),clips
    assert len(data.get('materials',[]))<=4
    return {'id':name,'triangles':actual,'materials':len(data['materials']),'animations':clips,
        'source':str((SRC/(KEY+'.blend')).relative_to(ROOT)).replace('\\','/'),
        'glb':str((OUT/(name+'.glb')).relative_to(ROOT)).replace('\\','/'),
        'size_godot_xyz_m':size_for(liberated),
        'up':'+Y','forward':'-X','rig':'rigid node animation, 21 articulated rigid nodes: neck, head, jaw, wings, legs, toes, tail and body','original':True,'palette_texture':[8,2],'texture_embedded':True}
stats=[export(KEY),export(KEY+'_liberado',True)]
(OUT/(KEY+'_manifest.json')).write_text(json.dumps({'assets':stats,'budget':BUDGET,'emission_only':'implant* cyan hardware'},indent=2),encoding='utf-8')

# Useful, portable Blender studio preview. PBR nodes remain exportable; Godot supplies the cel shader/outline.
for node in animated:
    for track in node.animation_data.nla_tracks: track.mute=track.name!='idle'
scene.frame_set(0)
camdata=bpy.data.cameras.new('StudioCamera'); camera=bpy.data.objects.new('StudioCamera',camdata)
scene.collection.objects.link(camera); camera.location=(-9,-13,7)
camera.rotation_euler=(Vector((0,0,1.45))-camera.location).to_track_quat('-Z','Y').to_euler()
camdata.type='ORTHO'; camdata.ortho_scale=9.0; scene.camera=camera
for name,position,power,size in [('Key',(-4,-6,9),1000,7),('Rim',(4,5,7),650,5)]:
    data=bpy.data.lights.new(name,'AREA'); data.energy=power; data.shape='DISK'; data.size=size
    obj=bpy.data.objects.new(name,data); scene.collection.objects.link(obj); obj.location=position
    obj.rotation_euler=(Vector((0,0,1.5))-obj.location).to_track_quat('-Z','Y').to_euler()
scene.render.film_transparent=False
bpy.context.view_layer.objects.active=body
bpy.ops.object.select_all(action='DESELECT'); body.select_set(True)
# Save source with exportable PBR materials, all named parts and editable NLA animation tracks.
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(KEY+'.blend')))
print('GIANT_HERON_OK '+json.dumps(stats),flush=True)

