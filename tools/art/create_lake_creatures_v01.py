"""Original articulated alien-controlled heron. Blender 5.2; no external library assets.
Exports PBR GLBs with an embedded flat palette; saves editable source with studio camera and lights.
"""
from pathlib import Path
import bpy, bmesh, math, json, struct, zlib, sys, hashlib
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
VARIANT = sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'turtle'
assert VARIANT in ('turtle','salamander','mosquito_cloud')
KEY = 'lvl02_enemy_'+VARIANT+'_v01'
SRC = ROOT/'art_source/blender/levels/level_02_lake/enemies'
OUT = ROOT/'assets/models/levels/level_02_lake/enemies'
PREVIEW = ROOT/'concept_art/levels/level_02/lake_creatures_v01'
BUDGET = 5000
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
COLORS={'body':(.34,.40,.19),'dark':(.19,.22,.12),'gold':(.71,.51,.24),'eye':(.86,.68,.26),'pupil':(.055,.055,.03),'cream':(.81,.75,.48),'red':(.72,.31,.16),'brown':(.43,.30,.17)}
# A tiny embedded flat palette keeps the four-material asset portable in native Godot/glTF viewers.
palette_keys=['body','dark','gold','eye','pupil','cream','red','brown']
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

animated=[];wings=[];roots=[];hips={}
def joint(name,parent,point):
    n=empty(name,parent);hips[n]=Vector(point);animated.append(n);return n
if VARIANT=='mosquito_cloud':
    reference=ROOT/'art_source/blender/levels/level_02_lake/enemies/controlled_mosquito.blend'
    before_hash=hashlib.sha256(reference.read_bytes()).hexdigest()
    with bpy.data.libraries.load(str(reference),link=False) as (source,target):
        target.objects=[n for n in source.objects if n not in ('Camera','Light')]
    imported=[o for o in target.objects if o and o.type=='MESH']
    assert imported
    mapping={'Abdomen':'brown','Chitin':'dark','Ochre':'gold','Eye':'eye','Wing':'cream'}
    def source_world(obj):
        return source_world(obj.parent) @ obj.matrix_basis if obj.parent else obj.matrix_basis.copy()
    prototypes=[]
    for old in imported:
        obj=old.copy();obj.data=old.data.copy();scene.collection.objects.link(obj)
        # Original primitives are authored in local mosquito space; no source file is saved.
        obj.parent=None;obj.matrix_world=source_world(old)
        is_wing=old.name.startswith('Wing_')
        original_mats=list(obj.data.materials)
        obj.data.materials.clear()
        obj.data.materials.append(materials['nature'])
        for key in ('graphite','cyan','violet'):obj.data.materials.append(materials[key])
        for poly in obj.data.polygons:
            name=original_mats[poly.material_index].name.split('.')[0]
            if name in mapping:
                poly.material_index=0
                if not obj.data.uv_layers:obj.data.uv_layers.new()
                for index in poly.loop_indices:obj.data.uv_layers.active.data[index].uv=((palette_keys.index(mapping[name])+.5)/8,.5)
            else:poly.material_index=2 if name=='Cyan' else 3 if name=='Violet' else 1
        bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
        count=sum(len(p.vertices)-2 for p in obj.data.polygons)
        # Keep thin legs/antennae closed; reduction is only for this miniature cloud.
        mod=obj.modifiers.new('CloudReduction','DECIMATE');mod.ratio=max(.065,min(1,16/max(1,count)))
        bpy.ops.object.modifier_apply(modifier=mod.name)
        for poly in obj.data.polygons:poly.use_smooth=True
        obj.name=('implant_' if any(m.name.split('.')[0] in ('Cyan','Violet','Shell','ShellEdge') for m in original_mats) else '')+old.name
        prototypes.append((obj,is_wing))
    # Join static pieces in each natural/foreign stream, preserving two movable wings.
    def merge(group,name):
        bpy.ops.object.select_all(action='DESELECT')
        for o in group:o.select_set(True)
        bpy.context.view_layer.objects.active=group[0];bpy.ops.object.join()
        group[0].name=name;return group[0]
    natural_group=[o for o,w in prototypes if not w and not o.name.startswith('implant')]
    device_group=[o for o,w in prototypes if o.name.startswith('implant')]
    wing_meshes=[o for o,w in prototypes if w]
    natural=merge(natural_group,'mosquito_body')
    device=merge(device_group,'implant_mosquito_device')
    points=[(-1.0,0,.85),(-.36,-.35,1.47),(.56,.10,.90),(.92,-.22,1.89),(-.60,.32,2.21),(.30,.18,2.64)]
    for i,point in enumerate(points):
        root=empty('Mosquito_%02d'%i,fauna,point);root.scale=(.55,.55,.55);roots.append(root);animated.append(root)
        for proto in [natural,device]+wing_meshes:
            obj=proto.copy();obj.data=proto.data;scene.collection.objects.link(obj)
            obj.name=proto.name+'_%02d'%i;obj.parent=root
            if proto in wing_meshes:
                side=-1 if 'Wing_L' in proto.name else 1
                wing=empty('WingPivot_%02d_%s'%(i,'L' if side<0 else 'R'),root)
                wing.location=(-.06,side*.09,.15);obj.parent=wing;obj.location-=wing.location
                animated.append(wing);wings.append((wing,i,side))
        empty('ImplantAnchor_%02d'%i,root,(-.02,0,.21))
        empty('MuzzleAnchor_%02d'%i,root,(-.91,0,-.025))
    for obj in [natural,device]+wing_meshes:
        if obj.name in bpy.data.objects and obj.users_collection:bpy.data.objects.remove(obj,do_unlink=True)
    # Removing temporary datablocks is confined to this empty Blender process, never disk assets.
    assert hashlib.sha256(reference.read_bytes()).hexdigest()==before_hash
    body=next(o for o in model.children_recursive if o.type=='MESH' and o.name.startswith('mosquito_body'))
    model['source_reference']=str(reference.relative_to(ROOT));model['source_sha256']=before_hash
else:
    body_pivot=joint('BodyPivot',fauna,(0,0,0));roots=[body_pivot]
    turtle=VARIANT=='turtle'
    skin='body' if turtle else 'brown'
    body=ell('body',(0,0,.50),(.91,.63,.29) if turtle else (.95,.27,.23),body_pivot,color=skin,segments=20,rings=10)
    if turtle:
        ell('plastron',(-.05,0,.35),(.87,.59,.13),body_pivot,color='cream',segments=20,rings=10)
        ell('shell',(0,0,.66),(1.0,.69,.42),body_pivot,color='dark',segments=20,rings=10)
        for side in (-1,1):
            for i in range(3):
                ell('painted_shell_rim_%s_%d'%(side,i),(-.55+i*.52,side*.63,.55),(.16,.057,.075),body_pivot,color='red',segments=10,rings=6)
        for i in range(3):ell('shell_scute_'+str(i),(-.47+i*.47,0,1.025),(.21,.28,.040),body_pivot,color='body',segments=10,rings=4)
    else:
        for side in (-1,1):
            for i in range(4):ell('skin_spot_%s_%d'%(side,i),(-.55+i*.36,side*.25,.55),(.095,.025,.09),body_pivot,color='gold',segments=8,rings=4)
    head=joint('HeadPivot',body_pivot,(-.80,0,.53))
    ell('neck',(-.94,0,.53),(.28,.16,.14),head,color=skin)
    ell('head',(-1.19,0,.54),(.30,.20,.18) if turtle else (.35,.25,.15),head,color=skin,segments=16,rings=8)
    jaw=joint('JawPivot',head,(-1.13,0,.45))
    ell('jaw',(-1.27,0,.42),(.24,.18,.06),jaw,color='cream')
    for side in (-1,1):
        ell('eye_'+str(side),(-1.30,side*.16,.62),(.068,.042,.056),head,color='eye',segments=10,rings=6)
        ell('pupil_'+str(side),(-1.32,side*.196,.62),(.03,.016,.04),head,color='pupil',segments=8,rings=4)
        if turtle:ell('painted_cheek_'+str(side),(-1.07,side*.174,.59),(.11,.025,.034),head,color='red',segments=10,rings=6)
        for i in range(2):
            x=-.48 if i==0 else .57
            leg=joint('Leg_%s_%s'%('L' if side<0 else 'R','Front' if i==0 else 'Hind'),body_pivot,(x,side*(.40 if turtle else .19),.45))
            end=(x-.23,side*(.91 if turtle else .52),.18)
            limb('limb_'+leg.name,(x,side*(.40 if turtle else .19),.45),end,.12 if turtle else .075,leg,color=skin)
            ell('web_'+leg.name,end,(.20,.15,.055) if turtle else (.14,.10,.04),leg,color=skin,segments=10,rings=6)
            for toe in range(3):
                limb('toe_'+leg.name+'_'+str(toe),(end[0]-.06, end[1]+(toe-1)*.07,end[2]),(end[0]-.23,end[1]+(toe-1)*.12,.14),.023,leg,color='gold')
    tail1=joint('TailBase',body_pivot,(.74,0,.50))
    if turtle:
        limb('tail',(.74,0,.50),(1.17,0,.38),.08,tail1,color=skin)
    else:
        tail2=joint('TailMid',tail1,(1.26,0,.45));tail3=joint('TailTip',tail2,(1.81,0,.40))
        for node,a,b,r in [(tail1,(.74,0,.50),(1.26,0,.45),.17),(tail2,(1.26,0,.45),(1.81,0,.40),.13),(tail3,(1.81,0,.40),(2.38,0,.36),.07)]:
            limb('tail_'+node.name,a,b,r,node,color=skin)
            ell('tail_fin_'+node.name,((a[0]+b[0])*.5,0,a[2]+.07),((b[0]-a[0])*.57,.035,r*1.65),node,color='gold')
    for node in reversed(list(hips)):
        for child in node.children:child.location-=hips[node]
        node.location=hips[node]
    implant.parent=body_pivot
    top=1.12 if turtle else .78
    plate('implant_mount',(0,0,top),(.44,.34,.10),implant,bevel=.035)
    ell('implant_core',(-.04,0,top+.075),(.13,.13,.048),implant,'cyan')
    ell('implant_node',(.16,0,top+.05),(.065,.06,.038),implant,'violet',segments=10,rings=6)
    empty('ImplantAnchor',model,(0,0,top+.075));empty('MuzzleAnchor',head,Vector((-1.49,0,.52))-hips[head])
empty('BodyAnchor',model,(0,0,1.5 if VARIANT=='mosquito_cloud' else .5));empty('GroundAnchor',model)
rest={node:(node.location.copy(),node.rotation_euler.copy()) for node in animated}
CLIPS={'idle':60,'swim':48,'attack':42,'liberate':48}
scene.render.fps=30
for clip,frames in CLIPS.items():
    for node in animated:
        act=bpy.data.actions.new(clip+'_'+node.name);node.animation_data_create();node.animation_data.action=act
        for f in range(0,frames+1,2):
            t=f/frames;phase=t*math.tau;wave=math.sin(t*math.pi)**2
            node.location=rest[node][0];node.rotation_euler=rest[node][1]
            if VARIANT=='mosquito_cloud':
                if node in roots:
                    i=roots.index(node);node.location.x+=.14*math.sin(phase+i);node.location.z+=.12*math.sin(phase+i*.8);node.location.y+=.09*math.cos(phase+i)
                    if clip=='attack':node.location.x-=.28*wave
                else:
                    _,i,side=next(w for w in wings if w[0]==node);node.rotation_euler.x+=side*.48*math.sin(phase*3+i)
            else:
                if node==body_pivot:node.location.z+=.025*math.sin(phase)
                if node.name.startswith('Leg_'):node.rotation_euler.z=(.32 if clip=='swim' else .06)*math.sin(phase+(math.pi if 'Hind' in node.name else 0))
                if node.name.startswith('Tail'):node.rotation_euler.z=(.28 if clip=='swim' else .07)*math.sin(phase+animated.index(node)*.7)
                if node==head:
                    node.rotation_euler.y=.06*math.sin(phase)
                    if clip=='attack':node.location.x-=.18*wave
                if node==jaw and clip=='attack':node.rotation_euler.y=-.30*wave
            node.keyframe_insert('location',frame=f);node.keyframe_insert('rotation_euler',frame=f)
        track=node.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,0,act);node.animation_data.action=None;track.mute=True
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
    unique=sum(data['accessors'][p['indices']]['count']//3 for m in data['meshes'] for p in m['primitives'])
    actual=sum(data['accessors'][p['indices']]['count']//3 for node in data['nodes'] if 'mesh' in node for p in data['meshes'][node['mesh']]['primitives'])
    clips=[a.get('name') for a in data.get('animations',[])]
    assert set(clips)==set(CLIPS),clips
    assert len(data.get('materials',[]))<=4
    return {'id':name,'triangles':actual,'unique_mesh_triangles':unique,'materials':len(data['materials']),'animations':clips,
        'source':str((SRC/(KEY+'.blend')).relative_to(ROOT)).replace('\\','/'),
        'glb':str((OUT/(name+'.glb')).relative_to(ROOT)).replace('\\','/'),
        'size_godot_xyz_m':size_for(liberated),
        'up':'+Y','forward':'-X','rig':'rigid node animation, hierarchical rigid limb/neck/tail rig or six original-derived mosquito roots with wing hinges','original':True,'palette_texture':[8,2],'texture_embedded':True}
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
print('LAKE_CREATURES_OK '+json.dumps(stats),flush=True)

