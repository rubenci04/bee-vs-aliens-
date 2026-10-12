# Geometry fragment read by create_anthills_v01.py, not a standalone Blender entry point.
n=32
if VARIANT=='crater':
    profile=[(1.20,.015),(1.07,.10),(.87,.26),(.63,.47),(.43,.60),(.30,.62),(.22,.565),(.18,.39),(.15,.23)]
else:
    profile=[(.91,.015),(.87,.15),(.74,.44),(.66,.77),(.52,1.08),(.36,1.34),(.16,1.53),(.06,1.57)]
vertices=[];faces=[]
for j,(radius,z) in enumerate(profile):
    for i in range(n):
        a=i/n*math.tau
        variation=1+.035*math.sin(a*3+j*.17)+.018*math.cos(a*5)
        vertices.append((radius*variation*math.cos(a),radius*variation*math.sin(a),z))
for j in range(len(profile)-1):
    for i in range(n):faces.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
vertices.append((0,0,profile[0][1]));bottom=len(vertices)-1
for i in range(n):faces.append((bottom,(i+1)%n,i))
vertices.append((0,0,.205 if VARIANT=='crater' else 1.59));end=len(vertices)-1
for i in range(n):faces.append(((len(profile)-1)*n+i,(len(profile)-1)*n+(i+1)%n,end))
mesh=bpy.data.meshes.new('Mound');mesh.from_pydata(vertices,[],faces);mesh.uv_layers.new()
body=bpy.data.objects.new('soil_mound',mesh);scene.collection.objects.link(body)
bpy.context.view_layer.objects.active=body;body.select_set(True)
finish(body,'soil_mound',fauna,color='body' if VARIANT=='crater' else 'gold')
if VARIANT=='crater':
    # Descending inner rings plus recessed end form a real cavity, not a painted circle.
    for index,poly in enumerate(mesh.polygons):
        if index>=5*n and index<(len(profile)-1)*n or index>=(len(profile)-1)*n+n:
            for loop in poly.loop_indices:mesh.uv_layers.active.data[loop].uv=((palette_keys.index('pupil')+.5)/8,.5)
    empty('EntranceAnchor',model,(0,0,.59));empty('TunnelAnchor',model,(0,0,.24))
else:
    # A blind rounded tunnel, cut in a new mesh only; the back of the mound stays intact.
    cutter=ell('TemporaryTunnelCutter',(-.72,0,.47),(1.05,.235,.23),None,color='pupil',segments=24,rings=12)
    bpy.context.view_layer.objects.active=body
    mod=body.modifiers.new('SideEntrance','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cutter
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(cutter,do_unlink=True)
    bm=bmesh.new();bm.from_mesh(body.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-7)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(body.data);bm.free()
    for poly in body.data.polygons:poly.use_smooth=True
    empty('EntranceAnchor',model,(-.78,0,.47));empty('TunnelAnchor',model,(-.12,0,.47))
# Small natural stones and two grass blades give scale without hiding the entrance.
for i in range(6):
    a=i/6*math.tau+.48;r=1.03 if VARIANT=='crater' else .80
    ell('soil_pebble_%02d'%i,(r*math.cos(a),r*math.sin(a),.075),(.13,.10,.075),fauna,color='brown' if i%2 else 'cream',segments=10,rings=6)
for side in (-1,1):
    limb('grass_'+str(side),(.60,side*.67,.045),(.63,side*.69,.31),.025,fauna,color='eye')
empty('BaseAnchor',model);empty('BodyAnchor',model,(0,0,.40 if VARIANT=='crater' else .80));empty('GroundAnchor',model)
animated=[];CLIPS={}
