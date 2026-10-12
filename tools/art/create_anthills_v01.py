"""Two original natural anthills: open summit funnel and recessed side tunnel. Blender 5.2; no external library assets.
Exports PBR GLBs with an embedded flat palette; saves editable source with studio camera and lights.
"""
from pathlib import Path
import bpy, bmesh, math, json, struct, zlib, sys
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
VARIANT = sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'crater'
assert VARIANT in ('crater','side_tunnel')
KEY = 'lvl01_environment_anthill_'+VARIANT+'_v01'
SRC = ROOT/'art_source/blender/levels/level_01_garden/environment'
OUT = ROOT/'assets/models/levels/level_01_garden/environment'
PREVIEW = ROOT/'concept_art/levels/level_01/anthills_v01'
BUDGET = 2000
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
COLORS={'body':(.52,.36,.20),'dark':(.35,.24,.14),'gold':(.70,.53,.29),'eye':(.44,.50,.21),'pupil':(.15,.105,.06),'cream':(.76,.64,.40),'red':(.48,.29,.16),'brown':(.40,.30,.19)}
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
implant=None
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


exec((ROOT/'tools/art/anthills_geometry_v01.py').read_text(encoding='utf-8'))

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
        export_yup=True,export_animations=False,export_animation_mode='NLA_TRACKS',export_force_sampling=True)
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
        'up':'+Y','forward':'-X','rig':'static environment prop with entrance/tunnel anchors','original':True,'palette_texture':[8,2],'texture_embedded':True}
stats=[export(KEY)]
(OUT/(KEY+'_manifest.json')).write_text(json.dumps({'assets':stats,'budget':BUDGET,'emission_only':'none'},indent=2),encoding='utf-8')

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
print('ANTHILLS_OK '+json.dumps(stats),flush=True)

