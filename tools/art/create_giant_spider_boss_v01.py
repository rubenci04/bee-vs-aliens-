"""Original removable alien exoskeleton spider. Blender 5.2; no external library assets.
Exports PBR GLBs with an embedded flat palette; saves editable source with studio camera and lights.
"""
from pathlib import Path
import bpy, bmesh, math, json, struct, zlib
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
KEY = 'lvl01_boss_giant_spider_v01'
SRC = ROOT/'art_source/blender/levels/level_01_garden/bosses'
OUT = ROOT/'assets/models/levels/level_01_garden/bosses'
PREVIEW = ROOT/'concept_art/levels/level_01/giant_spider'
BUDGET = 12000
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
COLORS={'body':(.48,.29,.14),'dark':(.24,.135,.075),'gold':(.76,.52,.22),'eye':(.97,.71,.23),'pupil':(.095,.055,.035)}
# A tiny embedded flat palette keeps the four-material asset portable in native Godot/glTF viewers.
palette_keys=['body','dark','gold','eye','pupil','body','body','body']
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

def ell(name,pos,scale,parent,mat='nature',color='body',segments=16,rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=pos)
    o=bpy.context.object; o.scale=scale; return finish(o,name,parent,mat,color)

def limb(name,a,b,r,parent,mat='nature',color='body'):
    a,b=Vector(a),Vector(b)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,location=(a+b)*.5)
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

body=ell('body',(.65,0,1.65),(1.28,.92,1.00),fauna,segments=28,rings=14)
ell('thorax',(-.65,0,1.3),(.82,.68,.62),fauna,segments=24,rings=12)
ell('head',(-1.34,0,1.27),(.64,.61,.44),fauna,color='dark',segments=24,rings=12)
# Warm markings, never emissive; same palette material via vertex colours.
for side in (-1,1):
    for i in range(3):
        ell(f'abdomen_mark_{side}_{i}',(.30+i*.37,side*.86,1.72),(.18,.075,.30),fauna,color='gold',segments=12,rings=6)
    for i in range(4):
        y=side*(.14+i*.115); z=1.48-(i*.045)
        ell(f'eye_{side}_{i}',(-1.86,y,z),(.10,.085,.105 if i<2 else .075),fauna,color='eye',segments=12,rings=6)
        ell(f'eye_pupil_{side}_{i}',(-1.94,y-.025,z),(.035,.038,.053),fauna,color='pupil',segments=10,rings=6)
    jaw=empty(f'jaw_{"L" if side<0 else "R"}',fauna)
    limb('fang_base',(-1.68,side*.22,1.04),(-1.98,side*.26,.81),.15,jaw,color='dark')
    limb('fang_tip',(-1.98,side*.26,.81),(-1.91,side*.25,.65),.067,jaw,color='pupil')
legs=[]
for side in (-1,1):
    for i in range(4):
        label=f'{"L" if side<0 else "R"}_{i+1:02d}'
        start=Vector((-.99+i*.45,side*.48,1.24))
        knee=Vector(([-2.10,-.90,.95,2.05][i],side*[1.45,1.72,1.75,1.45][i],[1.90,2.25,2.25,1.90][i]))
        foot=Vector(([-2.95,-1.38,1.44,3.01][i]+(.14 if side>0 else 0),side*2.05,.13))
        # Editable rigid leg pivot; natural and foreign pieces remain separately named.
        leg=empty('leg_'+label,fauna); legs.append(leg)
        limb('leg_upper_'+label,start,knee,.14,leg,color='body')
        ell('leg_joint_'+label,knee,(.19,.19,.19),leg,color='gold',segments=12,rings=6)
        limb('leg_lower_'+label,knee,foot,.115,leg,color='dark')
        ell('leg_foot_'+label,foot,(.17,.11,.13),leg,color='gold',segments=12,rings=6)
        # Collar around the tibia, external and removable; does not replace the spider leg.
        at=knee.lerp(foot,.27)
        o=plate('implant_bracer_'+label,at,(.42,.35,.62),leg,bevel=.08)
        o.rotation_euler=(foot-knee).to_track_quat('Z','Y').to_euler()
        bpy.context.view_layer.objects.active=o
        bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
        leg['anatomy']='one of eight legs; detachable graphite tibia collar'

# Separate graphite exoskeleton: visible stand-off between plate and natural abdomen.
plate('implant_dorsal_shell',(.55,0,2.68),(1.70,1.30,.18),implant,bevel=.10)
plate('implant_thorax_guard',(-.71,0,1.98),(.83,.88,.17),implant,bevel=.07)
for side in (-1,1):
    plate('implant_flank_'+str(side),(.78,side*.92,2.11),(1.53,.18,.52),implant,rotation=(side*.26,0,0))
    limb('implant_bridge_'+str(side),(-.63,side*.35,1.99),(.05,side*.51,2.69),.065,implant,'graphite')
    for i in range(2):
        ell(f'implant_nodes_{side}_{i}',(.02+i*.98,side*.50,2.83),(.17,.16,.10),implant,'violet',segments=16,rings=8)
core=ell('implant_core',(.55,-.09,2.88),(.49,.40,.19),implant,'cyan',segments=24,rings=12)
plate('implant_sensor_housing',(-1.36,0,1.89),(.35,.73,.10),implant,bevel=.035)
empty('ImplantAnchor',model,(.55,-.09,2.88))
empty('MuzzleAnchor',model,(-1.93,0,1.02))
empty('BodyAnchor',model,(.0,0,1.25))
empty('SilkAnchor',model,(1.89,0,1.65))
empty('GroundAnchor',model)

# Shift each leg's origin to its hip without changing geometry, then bake rigid-node loops.
bpy.context.view_layer.update()
for leg in legs:
    i=int(leg.name[-2:])-1; side=-1 if '_L_' in leg.name else 1
    hip=Vector((-.99+i*.45,side*.48,1.24))
    for o in leg.children:
        o.location-=hip
    leg.location=hip
animated=legs+[fauna]+[o for o in fauna.children if o.name.startswith('jaw_')]
scene.render.fps=30
for clip,frames in [('idle',60),('walk',36),('attack',42)]:
    for node in animated:
        node.rotation_euler=(0,0,0)
        act=bpy.data.actions.new(clip+'_'+node.name); node.animation_data_create(); node.animation_data.action=act
        base=node.location.copy()
        for f in range(0,frames+1,3):
            phase=f/frames*math.tau
            node.location=base
            node.rotation_euler=(0,0,0)
            if node==fauna:
                node.location.z=base.z+(.035*math.sin(phase) if clip=='idle' else .035*(1-math.cos(phase)))
            elif node.name.startswith('leg_'):
                index=legs.index(node)
                if clip=='walk':
                    node.rotation_euler.z=.16*math.sin(phase+(index%2)*math.pi)
                    node.rotation_euler.x=.07*math.sin(phase+(index%2)*math.pi)
                elif clip=='attack' and index%4==0:
                    node.rotation_euler.y=-.30*math.sin(f/frames*math.pi)**2
            elif clip=='attack':
                node.rotation_euler.z=(.28 if node.name.endswith('R') else -.28)*math.sin(f/frames*math.pi)**2
            node.keyframe_insert('location',frame=f); node.keyframe_insert('rotation_euler',frame=f)
        track=node.animation_data.nla_tracks.new(); track.name=clip
        track.strips.new(clip,0,act)
        node.animation_data.action=None
        track.mute=True
    # Exporter matches the NLA track names across objects into one animation per clip.
for node in animated:
    for track in node.animation_data.nla_tracks: track.mute=False
scene.frame_set(0)

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
    selected=[o for o in meshes if not liberated or not o.name.startswith('implant')]
    points=[o.matrix_world@Vector(v) for o in selected for v in o.bound_box]
    dims=[max(v[i] for v in points)-min(v[i] for v in points) for i in range(3)]
    return [round(dims[0],3),round(dims[2],3),round(dims[1],3)]

def export(name,liberated=False):
    bpy.ops.object.select_all(action='DESELECT')
    model.select_set(True)
    for o in model.children_recursive:
        if not liberated or not (o.name.startswith('implant') or o==implant): o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,
        export_vertex_color='NONE',export_all_vertex_colors=False,
        export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True)
    raw=(OUT/(name+'.glb')).read_bytes(); length=struct.unpack_from('<I',raw,12)[0]
    data=json.loads(raw[20:20+length])
    actual=sum(data['accessors'][p['indices']]['count']//3 for m in data['meshes'] for p in m['primitives'])
    clips=[a.get('name') for a in data.get('animations',[])]
    assert set(clips)=={'idle','walk','attack'},clips
    assert len(data.get('materials',[]))<=4
    return {'id':name,'triangles':actual,'materials':len(data['materials']),'animations':clips,
        'source':str((SRC/(KEY+'.blend')).relative_to(ROOT)).replace('\\','/'),
        'glb':str((OUT/(name+'.glb')).relative_to(ROOT)).replace('\\','/'),
        'size_godot_xyz_m':size_for(liberated),
        'up':'+Y','forward':'-X','rig':'rigid node animation, eight editable leg pivots','original':True,'palette_texture':[8,2],'texture_embedded':True}
stats=[export(KEY),export(KEY+'_liberado',True)]
(OUT/(KEY+'_manifest.json')).write_text(json.dumps({'assets':stats,'budget':BUDGET,'emission_only':'implant_core'},indent=2),encoding='utf-8')

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
print('GIANT_SPIDER_BOSS_OK '+json.dumps(stats),flush=True)
