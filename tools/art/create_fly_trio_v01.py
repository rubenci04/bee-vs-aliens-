"""Original common fly, green bottle fly and lightweight eight-fly swarm. Blender 5.2; no external library assets.
Exports PBR GLBs with an embedded flat palette; saves editable source with studio camera and lights.
"""
from pathlib import Path
import bpy, bmesh, math, json, struct, zlib, sys
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
VARIANT = sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'common'
assert VARIANT in ('common','green','swarm')
KEY = 'lvl01_enemy_fly_'+VARIANT+'_v01'
SRC = ROOT/'art_source/blender/levels/level_01_garden/enemies'
OUT = ROOT/'assets/models/levels/level_01_garden/enemies'
PREVIEW = ROOT/'concept_art/levels/level_01/fly_trio'
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
COLORS={'body':(.37,.39,.34),'dark':(.19,.21,.16),'green':(.23,.53,.23),'eye':(.68,.23,.12),'pupil':(.10,.07,.045),'cream':(.80,.78,.60),'gold':(.65,.49,.20)}
# A tiny embedded flat palette keeps the four-material asset portable in native Godot/glTF viewers.
palette_keys=['body','dark','gold','eye','pupil','cream','green','green']
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

flies=[]; wings=[]; leg_nodes=[]
def make_fly(index,green=False,lite=False,pos=(0,0,0),scale=1):
    root=empty('Fly_%02d'%index,fauna)
    skin='green' if green else 'body'
    seg,ring=(10,4) if lite else (20,10)
    abdomen=ell('abdomen_%02d'%index,(.35,0,.58),(.51,.29,.29),root,color=skin,segments=seg,rings=ring)
    ell('thorax_%02d'%index,(-.19,0,.64),(.31,.31,.29),root,color='dark',segments=seg,rings=ring)
    ell('head_%02d'%index,(-.58,0,.63),(.26,.32,.26),root,color=skin,segments=10 if lite else 16,rings=4 if lite else 8)
    for side in (-1,1):
        label=f'{index:02d}_{"L" if side<0 else "R"}'
        ell('eye_'+label,(-.68,side*.245,.70),(.19,.125,.18),root,color='eye',segments=10 if lite else 16,rings=4 if lite else 8)
        if not lite:
            ell('eye_glint_'+label,(-.79,side*.29,.76),(.038,.027,.04),root,color='gold',segments=8,rings=4)
            limb('antenna_'+label,(-.76,side*.10,.82),(-.92,side*.14,.92),.027,root,color='dark')
        wing=empty('Wing_'+label,root)
        o=ell('wing_'+label,(.12,side*.54,.87),(.48,.34,.037),wing,color='cream',segments=10 if lite else 20,rings=4 if lite else 10)
        o.rotation_euler.z=side*.32
        if not lite:
            limb('wing_vein_'+label,(-.19,side*.20,.90),(.45,side*.65,.90),.015,wing,color='gold')
        hinge=Vector((-.19,side*.20,.87))
        for child in wing.children:child.location-=hinge
        wing.location=hinge;wings.append((wing,index,side))
        for i in range(3):
            leg=empty('Leg_'+label+'_'+str(i),root)
            hip=Vector((-.39+i*.28,side*.20,.48))
            knee=Vector((-.51+i*.34,side*.43,.23))
            foot=Vector((-.69+i*.47,side*.59,.065))
            if lite:
                # A compact closed limb per leg for cloud members, never duplicate full enemies.
                a,b=hip,foot
                bpy.ops.mesh.primitive_uv_sphere_add(segments=5,ring_count=3,location=(a+b)*.5)
                o=bpy.context.object;o.scale=(.026,.026,(b-a).length*.55);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
                finish(o,'leg_'+label+'_'+str(i),leg,color='dark')
            else:
                limb('leg_upper_'+label+'_'+str(i),hip,knee,.032,leg,color='dark')
                limb('leg_lower_'+label+'_'+str(i),knee,foot,.028,leg,color='dark')
            for child in leg.children:child.location-=hip
            leg.location=hip;leg_nodes.append((leg,index,side,i))
    if not lite:
        for i in range(2):
            ell('abdomen_band_'+str(index)+'_'+str(i),(.25+i*.25,0,.83),(.035,.20,.032),root,color='dark',segments=12,rings=6)
        ell('proboscis_'+str(index),(-.78,0,.41),(.10,.055,.08),root,color='dark',segments=8,rings=4)
    # Removable control backpack, without replacing eyes, wings or legs.
    if lite:
        ell('implant_pack_'+str(index),(-.16,0,.98),(.17,.15,.045),root,'graphite',segments=6,rings=4)
        ell('implant_core_'+str(index),(-.16,0,1.03),(.075,.075,.035),root,'cyan',segments=6,rings=4)
    else:
        plate('implant_pack_'+str(index),(-.16,0,.99),(.39,.35,.10),root,bevel=.035)
        ell('implant_core_'+str(index),(-.16,0,1.075),(.12,.11,.045),root,'cyan')
        ell('implant_node_'+str(index),(.07,0,1.04),(.062,.064,.04),root,'violet',segments=10,rings=6)
    empty('ImplantAnchor_'+str(index),root,(-.16,0,1.075))
    empty('MuzzleAnchor_'+str(index),root,(-.91,0,.63))
    root.location=pos;root.scale=(scale,scale,scale)
    if green:root.scale.x*=1.12;root.scale.y*=1.06
    flies.append(root)
    return abdomen
if VARIANT=='swarm':
    positions=[(-.80,0,1.10),(-.25,-.45,.55),(.55,.18,.78),(.85,-.38,1.36),(-.38,.42,1.74),(.30,-.30,2.04),(1.06,.38,2.16),(-1.10,-.30,2.01)]
    for i,point in enumerate(positions):body=make_fly(i,i%2==1,True,point,.43 if i%3 else .49)
else:body=make_fly(0,VARIANT=='green')
empty('BodyAnchor',model,(0,0,1.3 if VARIANT=='swarm' else .60))
empty('GroundAnchor',model)
animated=flies+[w[0] for w in wings]+[l[0] for l in leg_nodes]
rest={node:(node.location.copy(),node.rotation_euler.copy()) for node in animated}
CLIPS={'hover':36,'attack':36,'liberate':48}
scene.render.fps=30
for clip,frames in CLIPS.items():
    for node in animated:
        act=bpy.data.actions.new(clip+'_'+node.name);node.animation_data_create();node.animation_data.action=act
        for f in range(0,frames+1,2):
            t=f/frames;phase=t*math.tau;node.location=rest[node][0];node.rotation_euler=rest[node][1]
            if node in flies:
                index=flies.index(node)
                node.location.z+=.07*math.sin(phase+index*.8)
                if VARIANT=='swarm':
                    node.location.x+=.13*math.sin(phase+index)
                    node.location.y+=.12*math.cos(phase+index)
                if clip=='attack':node.location.x-=.30*math.sin(t*math.pi)**2;node.rotation_euler.y=-.12*math.sin(phase)
                if clip=='liberate':node.rotation_euler.y=.08*math.sin(phase);node.location.z+=.18*math.sin(t*math.pi)**2
            else:
                wing=next((w for w in wings if w[0]==node),None)
                if wing:
                    _,index,side=wing
                    node.rotation_euler.x=side*(.48 if clip!='attack' else .67)*math.sin(phase*3+index*.7)
                else:
                    _,index,side,i=next(l for l in leg_nodes if l[0]==node)
                    node.rotation_euler.y=.13*math.sin(phase+index+i)
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
        'up':'+Y','forward':'-X','rig':'rigid node animation, fly roots, two wing hinges and six leg pivots per animal','original':True,'palette_texture':[8,2],'texture_embedded':True}
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
print('FLY_TRIO_OK '+json.dumps(stats),flush=True)

