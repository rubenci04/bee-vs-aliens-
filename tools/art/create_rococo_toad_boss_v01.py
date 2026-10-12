"""Original Rococo giant toad with removable twin-plasma armor. Blender 5.2; no external library assets.
Exports PBR GLBs with an embedded flat palette; saves editable source with studio camera and lights.
"""
from pathlib import Path
import bpy, bmesh, math, json, struct, zlib
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
KEY = 'lvl02_boss_rococo_toad_v01'
SRC = ROOT/'art_source/blender/levels/level_02_lake/bosses'
OUT = ROOT/'assets/models/levels/level_02_lake/bosses'
PREVIEW = ROOT/'concept_art/levels/level_02/rococo_toad'
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
COLORS={'body':(.40,.48,.20),'dark':(.23,.30,.12),'gold':(.76,.65,.32),'eye':(.96,.76,.22),'pupil':(.07,.08,.035),'tongue':(.82,.39,.32)}
# A tiny embedded flat palette keeps the four-material asset portable in native Godot/glTF viewers.
palette_keys=['body','dark','gold','eye','pupil','tongue','body','body']
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

# Natural anatomy, kept intact beneath every detachable piece of technology.
body_pivot=empty('BodyPivot',fauna)
body=ell('body',(.35,0,1.45),(1.48,1.10,1.15),body_pivot,segments=22,rings=10)
ell('belly',(-.16,0,.89),(1.35,.99,.62),body_pivot,color='gold',segments=18,rings=8)
head=empty('HeadPivot',body_pivot)
ell('head',(-1.02,0,1.63),(.90,1.03,.63),head,segments=22,rings=10)
ell('mouth_seam',(-1.40,0,1.31),(.55,.95,.065),head,color='dark')
jaw=empty('JawPivot',head)
ell('lower_jaw',(-1.39,0,1.18),(.58,.91,.20),jaw,color='gold',segments=20,rings=10)
throat=ell('Throat',(-.97,0,.93),(.64,.63,.30),jaw,color='gold')
for side in (-1,1):
    label='L' if side<0 else 'R'
    ell('eye_brow_'+label,(-.97,side*.75,2.16),(.46,.34,.42),head,color='body')
    ell('eye_'+label,(-1.20,side*.87,2.22),(.27,.17,.25),head,color='eye')
    ell('pupil_'+label,(-1.33,side*.96,2.23),(.095,.055,.18),head,color='pupil',segments=12,rings=8)
    ell('nostril_'+label,(-1.79,side*.30,1.81),(.038,.064,.035),head,color='dark',segments=10,rings=6)
    for i in range(3):
        ell(f'skin_spot_{label}_{i}',(.0+i*.44,side*1.01,1.58),(.15,.052,.13),body_pivot,color='dark',segments=10,rings=6)
legs=[]
for side in (-1,1):
    label='L' if side<0 else 'R'
    fore=empty('Foreleg_'+label,body_pivot);legs.append(fore)
    limb('fore_upper_'+label,(-.82,side*.73,1.23),(-.65,side*1.30,.54),.22,fore)
    limb('fore_lower_'+label,(-.65,side*1.30,.54),(-1.30,side*1.38,.21),.16,fore,color='gold')
    ell('fore_web_'+label,(-1.50,side*1.35,.15),(.33,.29,.13),fore,color='body')
    hind=empty('Hindleg_'+label,body_pivot);legs.append(hind)
    ell('hind_thigh_'+label,(1.11,side*1.02,.82),(.81,.52,.66),hind,segments=20,rings=10)
    limb('hind_shin_'+label,(1.49,side*1.14,.66),(.70,side*1.48,.22),.22,hind,color='gold')
    ell('hind_web_'+label,(.39,side*1.58,.15),(.45,.32,.13),hind)
    for i in range(3):
        limb(f'fore_toe_{label}_{i}',(-1.56,side*(1.16+i*.15),.13),(-1.91-(.10 if i==1 else 0),side*(1.08+i*.25),.075),.065,fore,color='gold')
        limb(f'hind_toe_{label}_{i}',(.18,side*(1.35+i*.15),.12),(-.27-(.12 if i==1 else 0),side*(1.26+i*.26),.075),.075,hind,color='gold')
    plate('implant_fore_bracer_'+label,(-.71,side*1.15,.74),(.47,.39,.40),fore,bevel=.065)
    plate('implant_hind_guard_'+label,(1.21,side*1.34,1.05),(.88,.18,.60),hind,bevel=.08)

# Resting tongue is tucked into the mouth. It telescopes from its own pivot and
# remains warm coral, never emissive. Extension length is animation geometry.
tongue=empty('TonguePivot',head,(-1.82,0,1.32))
ell('tongue_shaft',(-.5,0,0),(.50,.11,.09),tongue,color='tongue',segments=12,rings=6)
ell('tongue_tip',(-1.0,0,0),(.15,.18,.13),tongue,color='tongue',segments=12,rings=6)
tongue.scale=(.05,.05,.05)
empty('TongueAnchor',head,(-1.82,0,1.32))
empty('TongueTipAnchor',tongue,(-1.0,0,0))
plate('implant_dorsal_shell',(.48,0,2.56),(1.79,1.53,.25),implant,bevel=.10)
core=ell('implant_core',(.35,0,2.76),(.42,.42,.17),implant,'cyan',segments=20,rings=10)
for side in (-1,1):
    plate('implant_flank_'+str(side),(.40,side*1.08,1.76),(1.28,.19,.51),implant,bevel=.08)
    ell('implant_violet_node_'+str(side),(1.01,side*.48,2.72),(.14,.15,.10),implant,'violet')
    limb('implant_mount_'+str(side),(-.05,side*.65,2.54),(-.16,side*1.28,2.44),.10,implant,'graphite')

def ring(name,pos,major,minor,parent,mat):
    bpy.ops.mesh.primitive_torus_add(major_segments=20,minor_segments=6,location=pos,major_radius=major,minor_radius=minor,rotation=(0,math.pi/2,0))
    o=bpy.context.object
    return finish(o,name,parent,mat)
cannons=[]
for side in (-1,1):
    label='L' if side<0 else 'R'
    cannon=empty('implant_CannonPivot_'+label,implant);cannons.append(cannon)
    plate('implant_cannon_body_'+label,(-.58,side*1.31,2.44),(1.44,.48,.48),cannon,bevel=.08)
    ring('implant_muzzle_ring_'+label,(-1.38,side*1.31,2.44),.23,.065,cannon,'graphite')
    ring('implant_muzzle_energy_'+label,(-1.46,side*1.31,2.44),.17,.030,cannon,'cyan')
    ell('implant_muzzle_dark_'+label,(-1.31,side*1.31,2.44),(.032,.17,.17),cannon,'graphite')
    ell('implant_muzzle_lens_'+label,(-1.35,side*1.31,2.44),(.030,.10,.10),cannon,'cyan')
    plate('implant_cannon_fin_'+label,(-.08,side*1.31,2.74),(.48,.14,.16),cannon,bevel=.035)
    empty('Muzzle_'+label,cannon,(-1.52,side*1.31,2.44))
empty('ImplantAnchor',model,(.35,0,2.76))
empty('BodyAnchor',model,(.10,0,1.38))
empty('GroundAnchor',model)

# Rigid editable part rig: pivot origins at anatomical hinges, no mesh welding.
bpy.context.view_layer.update()
for node,hip in [(jaw,(-.91,0,1.25)),(head,(-.52,0,1.56))]+[(leg,(-.82 if leg.name.startswith('Fore') else 1.03,-.8 if leg.name.endswith('L') else .8,1.1)) for leg in legs]+[(c,(-.1,-1.31 if c.name.endswith('L') else 1.31,2.44)) for c in cannons]:
    hip=Vector(hip)
    for child in node.children:child.location-=hip
    node.location=hip
# Head and jaw are nested; account for the shifted parent origin.

implant.parent=body_pivot
animated=[body_pivot,head,jaw,throat,tongue]+legs+cannons
rest={n:(n.location.copy(),n.scale.copy()) for n in animated}
scene.render.fps=30
CLIPS={'idle':60,'hop':48,'plasma_fire':54,'tongue_attack':72}
for clip,frames in CLIPS.items():
    for node in animated:
        act=bpy.data.actions.new(clip+'_'+node.name);node.animation_data_create();node.animation_data.action=act
        base,scale=rest[node]
        for f in range(0,frames+1,3):
            t=f/frames; wave=math.sin(t*math.pi)**2
            node.location=base;node.scale=scale;node.rotation_euler=(0,0,0)
            if clip=='idle':
                if node==body_pivot:node.scale.z=1+.018*math.sin(t*math.tau)
                if node==throat:node.scale=(1,1,1+.08*math.sin(t*math.tau))
                if node==head:node.rotation_euler.y=.025*math.sin(t*math.tau)
            elif clip=='hop':
                if node==body_pivot:node.location.z=base.z+1.15*wave;node.rotation_euler.y=.10*math.sin(t*math.tau)
                if node in legs:node.rotation_euler.y=(.52 if node.name.startswith('Hind') else -.28)*wave
            elif clip=='plasma_fire':
                # 0.6 s charge, followed by two separate recoil pulses.
                pulse=max(0,1-abs(t-.42)/.10)+max(0,1-abs(t-.70)/.10)
                if node in cannons:node.location.x=base.x+.23*pulse;node.rotation_euler.y=-.06*pulse
                if node==body_pivot:node.location.x=base.x+.07*pulse
                if node==head:node.rotation_euler.y=-.045*pulse
            else:
                # Jaw windup ~0.6s; 6.8m extension, stationary tip at peak, retract.
                opening=min(1,t/.25)*min(1,(1-t)/.20)
                extension=max(0,min(1,(t-.25)/.15,(.85-t)/.15))
                if node==jaw:node.rotation_euler.y=-.35*opening
                if node==head:node.rotation_euler.y=.05*opening
                if node==tongue:node.scale=(.05+6.75*extension,.05+.95*extension,.05+.95*extension)
                if node==throat:node.scale=(1,1,1+.18*opening)
            node.keyframe_insert('location',frame=f);node.keyframe_insert('rotation_euler',frame=f);node.keyframe_insert('scale',frame=f)
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
        'up':'+Y','forward':'-X','rig':'rigid node animation, four limb pivots, head, jaw, throat, tongue and two cannon pivots','original':True,'palette_texture':[8,2],'texture_embedded':True}
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
print('ROCOCO_TOAD_BOSS_OK '+json.dumps(stats),flush=True)

