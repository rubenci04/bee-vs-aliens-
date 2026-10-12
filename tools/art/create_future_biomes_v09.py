"""Canonical control device and three ground fauna POCs. Blender Z up -> Godot Y up, viewed along Blender +Y.
Run Blender --background --python tools/art/create_future_biomes_v09.py.
Natural fauna with removable external graphite/cyan/violet technology.
"""
from pathlib import Path
import bpy, bmesh, math, json
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"assets/models/future_biomes_v09"
SRC=ROOT/"art_source/blender/future_biomes_v09"
for directory in (OUT,SRC):
    directory.mkdir(parents=True,exist_ok=True)
(SRC/".gdignore").write_text("",encoding="utf-8")
bpy.context.preferences.filepaths.save_version=0
PALETTE={"Shell":(.19,.21,.26),"ShellEdge":(.32,.34,.39),"Cyan":(.10,.78,.85),"Violet":(.59,.27,.84),"Rubber":(.12,.14,.16),"AntRust":(.43,.21,.12),"AntDark":(.26,.13,.075),"Eye":(.065,.045,.025),"LarvaGreen":(.48,.58,.23),"LarvaLight":(.63,.68,.34),"LeafOlive":(.37,.46,.19),"ToadSkin":(.43,.48,.24),"ToadLight":(.65,.66,.39),"ToadSpot":(.31,.35,.17),"Iris":(.77,.55,.19),"Cream":(.87,.78,.55)}
MATERIALS={}
STATS=[]

def linear(c):
    return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4

def empty(name,parent=None):
    obj=bpy.data.objects.new(name,None)
    bpy.context.collection.objects.link(obj)
    obj.parent=parent
    return obj

def reset(name):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for material in list(bpy.data.materials):
        bpy.data.materials.remove(material)
    MATERIALS.clear()
    for key,rgb in PALETTE.items():
        color=(*[linear(c) for c in rgb],1)
        mat=bpy.data.materials.new(key)
        mat.diffuse_color=color
        mat.use_nodes=True
        mat.node_tree.nodes.clear()
        bs=mat.node_tree.nodes.new("ShaderNodeBsdfPrincipled")
        output=mat.node_tree.nodes.new("ShaderNodeOutputMaterial")
        mat.node_tree.links.new(bs.outputs["BSDF"],output.inputs["Surface"])
        bs.inputs["Base Color"].default_value=color
        bs.inputs["Roughness"].default_value=.95
        if key in ("Cyan","Violet"):
            bs.inputs["Emission Color"].default_value=color
            bs.inputs["Emission Strength"].default_value=.7
        mat.use_backface_culling=True
        MATERIALS[key]=mat
    bpy.context.scene.unit_settings.system="METRIC"
    return empty(name)

def ell(name,pos,scale,material,parent,segments=32,rings=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=pos)
    obj=bpy.context.object
    obj.name=name
    obj.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    obj.parent=parent
    obj.data.materials.append(MATERIALS[material])
    for poly in obj.data.polygons:
        poly.use_smooth=True
    return obj

def mesh(name,vertices,faces,material,parent):
    data=bpy.data.meshes.new(name+"Mesh")
    data.from_pydata(vertices,[],faces)
    bm=bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    data.update()
    obj=bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(obj)
    obj.parent=parent
    data.materials.append(MATERIALS[material])
    return obj

def apply_modifier(obj,modifier):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active=obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)

def badge(name,outline,depth,material,parent,bevel=.015):
    n=len(outline)
    vertices=[(x,y,z) for y in (-depth/2,depth/2) for x,z in outline]
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    for i in range(n):
        j=(i+1)%n
        faces.append((i,j,j+n,i+n))
    obj=mesh(name,vertices,faces,material,parent)
    mod=obj.modifiers.new("SoftEdges","BEVEL")
    mod.width=bevel
    mod.segments=3
    apply_modifier(obj,mod)
    # Broad cap faces stay flat; small bevels and side faces stay smooth.
    for polygon in obj.data.polygons:
        polygon.use_smooth=abs(polygon.normal.y)<.999
    return obj

def save(key,role):
    groups=[o for o in bpy.context.scene.objects if o.type=="EMPTY" and o.name.startswith(("AlienControlDevice","Leg_","Foreleg_","Hindleg_"))]
    for group in groups:
        join_geometry(group)
    bpy.context.view_layer.update()
    objects=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    # This batch must contain closed, non-degenerate solid meshes only.
    for obj in objects:
        bm=bmesh.new()
        bm.from_mesh(obj.data)
        # Bevels can leave coincident vertices at a tightly curved crest.
        bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
        bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=1e-6)
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        assert all(edge.is_manifold for edge in bm.edges),"Open edge: "+obj.name
        assert all(face.calc_area()>1e-12 for face in bm.faces),"Degenerate face: "+obj.name
        bm.to_mesh(obj.data)
        bm.free()
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(key+".blend")))
    bpy.ops.export_scene.gltf(filepath=str(OUT/(key+".glb")),export_format="GLB",use_selection=True,export_yup=True,export_animations=False)
    bounds=[o.matrix_world@Vector(v) for o in objects for v in o.bound_box]
    STATS.append({"id":key,"role":role,"triangles":sum(len(p.vertices)-2 for o in objects for p in o.data.polygons),
        "mesh_objects":len(objects),"dimensions_xyz_blender":[round(max(p[i] for p in bounds)-min(p[i] for p in bounds),3) for i in range(3)],
        "up_godot":"+Y","view_godot":"XY","rigged":False,"emissive":True,"closed_meshes":True,
        "source":str((SRC/(key+".blend")).relative_to(ROOT)).replace("\\","/"),
        "glb":str((OUT/(key+".glb")).relative_to(ROOT)).replace("\\","/")})

def smooth(obj):
    for p in obj.data.polygons:
        p.use_smooth=True
    return obj

def tube(name,points,radius,material,parent,sides=12,loop=False):
    vertices,faces=[],[]
    previous_u=None
    for i,p in enumerate(points):
        before=points[(i-1)%len(points)] if loop else points[max(0,i-1)]
        after=points[(i+1)%len(points)] if loop else points[min(len(points)-1,i+1)]
        tangent=(Vector(after)-Vector(before)).normalized()
        if previous_u is None:
            reference=Vector((0,0,1)) if abs(tangent.z)<.9 else Vector((0,1,0))
            u=tangent.cross(reference).normalized()
        else:
            # Transport the frame; switching reference axes mid-curve twists foam rings.
            u=(previous_u-tangent*previous_u.dot(tangent)).normalized()
        previous_u=u
        v=tangent.cross(u).normalized()
        for j in range(sides):
            a=j*math.tau/sides
            vertices.append(tuple(Vector(p)+radius*(u*math.cos(a)+v*math.sin(a))))
    for i in range(len(points) if loop else len(points)-1):
        for j in range(sides):
            ni=(i+1)%len(points)
            faces.append((i*sides+j,i*sides+(j+1)%sides,ni*sides+(j+1)%sides,ni*sides+j))
    if not loop:
        faces.extend([tuple(reversed(range(sides))),tuple(range((len(points)-1)*sides,len(points)*sides))])
    return smooth(mesh(name,vertices,faces,material,parent))

def block(name,pos,scale,material,parent,bevel=.035):
    bpy.ops.mesh.primitive_cube_add(size=2,location=pos)
    obj=bpy.context.object
    obj.name=name
    obj.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    obj.parent=parent
    obj.data.materials.append(MATERIALS[material])
    mod=obj.modifiers.new("RoundedCorners","BEVEL")
    mod.width=bevel
    mod.segments=3
    apply_modifier(obj,mod)
    return obj

def soften_closed(points,steps=3):
    out=[]
    for i,p in enumerate(points):
        p0,p1,p2,p3=[Vector(points[j%len(points)]) for j in (i-1,i,i+1,i+2)]
        for k in range(steps):
            t=k/steps
            out.append(tuple(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)))
    return out

def soften_open(points,steps=4):
    out=[]
    for i in range(len(points)-1):
        p0,p1,p2,p3=[Vector(points[max(0,min(len(points)-1,j))]) for j in (i-1,i,i+1,i+2)]
        for k in range(steps):
            t=k/steps
            out.append(tuple(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)))
    return out+[points[-1]]

def tapered(name,points,radii,material,parent,sides=10):
    # Parallel transported tube with interpolated width; joints are model-space geometry.
    coords=soften_open(points,4)
    vertices,faces=[],[]
    previous_u=None
    for i,p in enumerate(coords):
        tangent=(Vector(coords[min(i+1,len(coords)-1)])-Vector(coords[max(0,i-1)])).normalized()
        if previous_u is None:
            ref=Vector((0,1,0)) if abs(tangent.y)<.9 else Vector((1,0,0))
            u=tangent.cross(ref).normalized()
        else:
            u=(previous_u-tangent*previous_u.dot(tangent)).normalized()
        previous_u=u
        v=tangent.cross(u).normalized()
        k=min(len(radii)-2,i//4)
        t=1 if i==len(coords)-1 else (i%4)/4
        radius=radii[k]*(1-t)+radii[k+1]*t
        for j in range(sides):
            a=j*math.tau/sides
            vertices.append(tuple(Vector(p)+radius*(u*math.cos(a)+v*math.sin(a))))
    for i in range(len(coords)-1):
        for j in range(sides):
            faces.append((i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j))
    faces.extend([tuple(reversed(range(sides))),tuple(range((len(coords)-1)*sides,len(coords)*sides))])
    return smooth(mesh(name,vertices,faces,material,parent))

def implant(parent,position=(0,0,0),scale=1,variant="insect"):
    """One identity, four mounts. Local +Z points away from the animal's back.
    Side-view cyan window remains visible even when the top lens is foreshortened.
    Every tech component is owned by AlienControlDevice; pads touch, never pierce.
    """
    device=empty("AlienControlDevice",parent)
    device.location=position
    device.scale=(scale,)*3
    ell("ContactSaddle",(0,0,-.015),(.32,.23,.055),"Rubber",device,24,12)
    ell("GraphiteShell",(0,0,.055),(.35,.235,.12),"Shell",device,32,16)
    ell("LensBezel",(-.055,0,.13),(.23,.174,.058),"ShellEdge",device,24,12)
    ell("PrimaryCyanLens",(-.06,0,.173),(.195,.139,.035),"Cyan",device,24,12)
    for side in (-1,1):
        ell("CyanSideWindow_%d"%side,(-.04,side*.218,.075),(.145,.018,.035),"Cyan",device,20,10)
    # Curved fork fins share a pointed-but-rounded outline from the references.
    for side in (-1,1):
        fin=badge("ForkFin_%d"%side,[(-.42,.015),(-.27,.15),(.04,.18),(.27,.13),(.31,.07),(-.12,.09),(-.30,-.005)],.052,"ShellEdge",device,.012)
        fin.location.y=side*.155
    rows={"insect":[-.14,.18],"mammal":[-.20,.20],"bird":[-.12,.18],"amphibian":[-.23,0,.23]}[variant]
    reach={"insect":.23,"mammal":.40,"bird":.31,"amphibian":.40}[variant]
    drop={"insect":.20,"mammal":.17,"bird":.12,"amphibian":.29}[variant]
    for i,x in enumerate(rows):
        for side in (-1,1):
            arm=empty("Clamp_%d_%d"%(i,side),device)
            tapered("GraphiteArm",[(x,side*.16,.04),(x+.025,side*(reach-.05),-.01),(x+.055,side*reach,-drop)],
                    [.042,.035,.022],"Shell",arm,10)
            ell("SoftContactPad",(x+.055,side*reach,-drop),(.065,.046,.025),"Rubber",arm,16,8)
            ell("VioletHinge",(x,side*.225,.07),(.037,.026,.037),"Violet",arm,16,8)
    tapered("ReceiverMast",[(.20,0,.14),(.33,0,.28),(.38,0,.42)],[.026,.019,.012],"Shell",device,10)
    ell("VioletReceiver",(.38,0,.42),(.045,)*3,"Violet",device,16,8)
    target=empty("DamageTarget",device)
    target.location=(-.06,0,.173)
    return device

def join_geometry(group):
    """Keep semantic groups while merging repeated pieces/materials for cheaper presentation."""
    objects=[o for o in group.children_recursive if o.type=="MESH"]
    bpy.context.view_layer.update()
    for obj in objects:
        world=obj.matrix_world.copy()
        obj.parent=None
        obj.matrix_world=world
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.join()
    objects[0].name=group.name+"Geometry"
    world=objects[0].matrix_world.copy()
    objects[0].parent=group
    objects[0].matrix_world=world

def ant():
    root=reset("ControlledAntModel")
    fauna=empty("NaturalFauna",root)
    ell("Head",(-.66,0,.49),(.27,.19,.235),"AntRust",fauna,32,16)
    ell("Thorax",(-.16,0,.48),(.31,.145,.16),"AntRust",fauna,32,16)
    ell("Petiole",(.20,0,.46),(.115,.085,.105),"AntDark",fauna,24,12)
    ell("Gaster",(.66,0,.48),(.42,.235,.265),"AntDark",fauna,32,16)
    for side in (-1,1):
        ell("Eye_%d"%side,(-.75,side*.16,.56),(.055,.025,.065),"Eye",fauna,20,10)
        tapered("ElbowedAntenna_%d"%side,[(-.79,side*.08,.65),(-.94,side*.13,.88),(-1.18,side*.17,.87),(-1.29,side*.18,.80)],
                [.015,.014,.010,.005],"AntDark",fauna,10)
        tapered("Mandible_%d"%side,[(-.87,side*.10,.40),(-1.03,side*.13,.36),(-1.09,side*.045,.39)],
                [.047,.030,.008],"AntDark",fauna,12)
        for i,x in enumerate((-.36,-.13,.07)):
            leg=empty("Leg_%s_%d"%(side,i),fauna)
            knee_x=x+(-.32,.06,.40)[i]
            foot_x=x+(-.56,.27,.68)[i]+(.14 if side>0 else 0)
            knee=(knee_x,side*.27,.28+(.045 if side>0 else 0))
            tapered("Femur",[(x,side*.10,.47),knee],[.028,.023],"AntRust",leg,10)
            tapered("Tibia",[knee,(foot_x,side*.42,.045),(foot_x-.09,side*.44,.03)],[.019,.011,.005],"AntDark",leg,10)
    implant(root,(-.21,0,.63),.65,"insect")
    save("controlled_ant","Common ground enemy; six legs, elbowed antennae, petiole and removable dorsal controller")

def caterpillar():
    root=reset("ControlledCaterpillarModel")
    fauna=empty("NaturalFauna",root)
    spiracles=empty("Spiracles",fauna)
    for i in range(8):
        x=-.63+i*.22
        radius=.22*(.87 if i in (0,7) else 1)
        ell("BodySegment_%d"%i,(x,0,.30),(radius,.23,.25),"LarvaGreen" if i%2 else "LarvaLight",fauna,24,12)
    ell("Head",(-.88,0,.30),(.22,.225,.24),"LeafOlive",fauna,32,16)
    for side in (-1,1):
        # Three true thoracic legs; four abdominal pairs plus terminal claspers.
        for i,x in enumerate((-.71,-.52,-.33)):
            leg=empty("TrueLeg_%s_%d"%(side,i),fauna)
            tapered("Foot",[(x,side*.14,.20),(x-.08,side*.25,.10),(x-.13,side*.27,.03)],[.035,.025,.012],"LeafOlive",leg,10)
        for i,x in enumerate((-.03,.19,.41,.63,.91)):
            leg=empty("Proleg_%s_%d"%(side,i),fauna)
            ell("SoftFoot",(x,side*.19,.095),(.085,.075,.085),"LarvaGreen",leg,16,8)
        for i,x in enumerate((-.55,-.27,.01,.29,.57,.83)):
            ell("Spiracle_%s_%d"%(side,i),(x,side*.228,.33),(.022,.009,.028),"LeafOlive",spiracles,12,8)
        ell("EyeCluster_%d"%side,(-.98,side*.184,.36),(.036,.014,.041),"Eye",fauna,16,8)
    tech=implant(root,(-.56,0,.54),.72,"insect")
    # External armour cups protect the controller, not a biological mutation.
    for i,x in enumerate((-.08,.24,.56)):
        plate=empty("ArmourPlate_%d"%i,tech)
        # Convert desired animal-space location to implant-local coordinates.
        plate.location=((x+.56)/.72,0,.03)
        ell("GraphitePlate",(0,0,-.03),(.27,.40,.16),"Shell",plate,24,12)
        for side in (-1,1):
            tapered("ArmourClamp_%d"%side,[(0,side*.17,0),(.015,side*.33,-.15),(.03,side*.30,-.25)],
                    [.035,.03,.018],"ShellEdge",plate,10)
    join_geometry(spiracles)
    save("controlled_caterpillar","Slow armoured larva; natural segmented body and all external armour removable")

def toad_study():
    root=reset("AmphibianMountStudyModel")
    fauna=empty("NaturalFauna",root)
    ell("Body",(.18,0,.60),(.73,.45,.48),"ToadSkin",fauna,40,20)
    ell("Throat",(-.48,-.02,.43),(.43,.36,.29),"ToadLight",fauna,32,16)
    ell("Head",(-.53,0,.69),(.47,.38,.29),"ToadSkin",fauna,40,20)
    for side in (-1,1):
        ell("EyeTurret_%d"%side,(-.63,side*.27,.93),(.18,.16,.18),"ToadSkin",fauna,24,12)
        ell("Iris_%d"%side,(-.72,side*.385,.96),(.105,.038,.106),"Iris",fauna,24,12)
        ell("HorizontalPupil_%d"%side,(-.73,side*.418,.962),(.070,.010,.026),"Eye",fauna,20,10)
        ell("Nostril_%d"%side,(-.94,side*.20,.75),(.025,.014,.014),"ToadSpot",fauna,16,8)
        tapered("MouthLine_%d"%side,[(-.95,side*.24,.59),(-.78,side*.35,.55),(-.47,side*.365,.56),(-.29,side*.32,.61)],
                [.009,.011,.009,.004],"ToadSpot",fauna,8)
        fore=empty("Foreleg_%d"%side,fauna)
        tapered("UpperArm",[(-.28,side*.28,.50),(-.42,side*.46,.27),(-.55,side*.49,.12)],[.10,.08,.055],"ToadSkin",fore,14)
        ell("Palm",(-.63,side*.50,.08),(.14,.105,.055),"ToadLight",fore,20,10)
        for j in range(4):
            tapered("Finger_%d"%j,[(-.66,side*.5+(j-1.5)*.045,.08),(-.86,side*.5+(j-1.5)*.06,.045)],[.018,.008],"ToadSkin",fore,8)
        hind=empty("Hindleg_%d"%side,fauna)
        ell("Haunch",(.65,side*.36,.39),(.39,.29,.32),"ToadSkin",hind,32,16)
        tapered("FoldedShin",[(.91,side*.43,.34),(.47,side*.59,.14),(.91,side*.61,.07)],
                [.12,.085,.045],"ToadLight",hind,14)
        for j in range(5):
            tapered("Toe_%d"%j,[(.87,side*.60+(j-2)*.035,.07),(1.12,side*.62+(j-2)*.045,.035)],
                    [.018,.006],"ToadSkin",hind,8)
    # Sparse broad dorsal markings, not gritty skin or exposed biological implants.
    for i,(x,y,z) in enumerate(((.40,-.30,.91),(.70,-.15,.90),(.21,.28,.96),(-.02,-.37,.84))):
        ell("DorsalMark_%d"%i,(x,y,z),(.12,.08,.025),"ToadSpot",fauna,20,10)
    implant(root,(.02,0,1.04),1.10,"amphibian")
    save("amphibian_mount_study","Original giant toad mount study; future lake miniboss visual, not the current UFO boss")

def kit():
    root=reset("CanonicalImplantKitModel")
    for i,variant in enumerate(("insect","mammal","bird","amphibian")):
        mount=empty("Mount_"+variant,root)
        mount.location=((i%2)*1.8-.9,0,1.05-(i//2)*1.1)
        implant(mount,variant=variant).name="AlienControlDevice_"+variant
    save("canonical_implant_kit","Four detachable mounts with one visual identity: insect, mammal, bird, amphibian")

if __name__=="__main__":
    ant()
    caterpillar()
    toad_study()
    kit()
    (OUT/"manifest.json").write_text(json.dumps({"batch":"V09","assets":STATS},indent=2),encoding="utf-8")
    print("FUTURE_BIOMES_V09_BLENDER_OK: "+json.dumps(STATS))

