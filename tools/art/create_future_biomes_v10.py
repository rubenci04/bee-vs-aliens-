"""Small air/artillery POC; imports only the original V09 construction helpers.
Blender Z up, -X forward; compatible with Godot XY side view. No library assets.
"""
from pathlib import Path
import importlib.util, math, json
import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location("bee_canonical_art",ROOT/"tools/art/create_future_biomes_v09.py")
art=importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)
art.OUT=ROOT/"assets/models/future_biomes_v10"
art.SRC=ROOT/"art_source/blender/future_biomes_v10"
for directory in (art.OUT,art.SRC):
    directory.mkdir(parents=True,exist_ok=True)
(art.SRC/".gdignore").write_text("",encoding="utf-8")
art.PALETTE.update({"DragonOlive":(.36,.46,.23),"DragonGold":(.65,.52,.25),
    "Wing":(.72,.73,.58),"WingVein":(.44,.45,.28),"CompoundEye":(.31,.37,.17),
    "MothTan":(.65,.49,.29),"MothDark":(.43,.31,.19),"MothCream":(.80,.69,.43),
    "MushroomCap":(.65,.28,.16),"MushroomCream":(.82,.73,.49),"MushroomStem":(.69,.62,.43)})
empty,ell,mesh=art.empty,art.ell,art.mesh
tapered,tube,smooth=art.tapered,art.tube,art.smooth
implant,save=art.implant,art.save

def reset(name):
    root=art.reset(name)
    art.MATERIALS["Wing"].use_backface_culling=False
    return root

def dragon_wing(group,tip,width):
    direction=Vector(tip)
    tangent=direction.normalized()
    u=(Vector((1,0,0))-tangent*tangent.x).normalized()
    v=tangent.cross(u).normalized()
    n,rings=12,18
    verts=[(0,0,0)]
    for k in range(1,rings):
        t=k/rings
        r=math.sin(math.pi*t)**.72
        center=direction*t
        for j in range(n):
            a=j*math.tau/n
            verts.append(tuple(center+u*(width*r*math.cos(a))+v*(.010*r*math.sin(a))))
    pole=len(verts)
    verts.append(tip)
    faces=[]
    for j in range(n):
        faces.append((0,1+j,1+(j+1)%n))
    for k in range(rings-2):
        for j in range(n):
            a=1+k*n+j
            b=1+k*n+(j+1)%n
            faces.append((a,b,b+n,a+n))
    for j in range(n):
        faces.append((1+(rings-2)*n+j,1+(rings-2)*n+(j+1)%n,pole))
    smooth(mesh("Membrane",verts,faces,"Wing",group))
    tapered("CentralVein",[tuple(v*.014),tuple(direction*.5+v*.014),tuple(direction*.97+v*.004)],
            [.010,.007,.002],"WingVein",group,8)
    for k in (6,10,14):
        t=k/rings
        center=direction*t+v*.012
        extent=width*math.sin(math.pi*t)**.72*.85
        tube("CrossVein_%d"%k,[tuple(center-u*extent),tuple(center+u*extent)],.003,"WingVein",group,6)

def insect_legs(fauna):
    for side in (-1,1):
        for i,x in enumerate((-.31,-.18,-.05)):
            leg=empty("Leg_%s_%d"%(side,i),fauna)
            tapered("Femur",[(x,side*.10,.0),(x-.13,side*.27,-.19)],
                    [.024,.018],"DragonOlive",leg,10)
            tapered("Tibia",[(x-.13,side*.27,-.19),(x-.30,side*.30,-.29),(x-.34,side*.30,-.22)],
                    [.014,.008,.004],"MothDark",leg,10)

def dragonfly():
    root=reset("ControlledDragonflyModel")
    fauna=empty("NaturalFauna",root)
    ell("Thorax",(-.18,0,.04),(.29,.17,.19),"DragonOlive",fauna,32,16)
    ell("Head",(-.53,0,.04),(.17,.18,.16),"DragonGold",fauna,24,12)
    for side in (-1,1):
        ell("CompoundEye_%d"%side,(-.58,side*.13,.12),(.135,.105,.14),"CompoundEye",fauna,32,16)
        tapered("ShortAntenna_%d"%side,[(-.66,side*.06,.16),(-.74,side*.07,.24)],[.010,.004],"MothDark",fauna,8)
    # One continuous abdomen; shallow ring relief and material bands avoid z-fighting.
    verts,faces=[],[]
    rings,sides=55,20
    for k in range(rings):
        t=k/(rings-1)
        radius=(.103*(1-t)+.024*t)*(1+.035*math.cos(t*math.tau*9))
        for j in range(sides):
            a=j*math.tau/sides
            verts.append((.01+1.56*t,radius*math.cos(a),.015-.115*t+radius*.85*math.sin(a)))
    faces.append(tuple(reversed(range(sides))))
    for k in range(rings-1):
        for j in range(sides):
            faces.append((k*sides+j,k*sides+(j+1)%sides,(k+1)*sides+(j+1)%sides,(k+1)*sides+j))
    faces.append(tuple(range((rings-1)*sides,rings*sides)))
    abdomen=smooth(mesh("SegmentedAbdomen",verts,faces,"DragonOlive",fauna))
    abdomen.data.materials.append(art.MATERIALS["DragonGold"])
    for p in abdomen.data.polygons:
        row=max(0,(p.index-1)//sides)
        if row%18 in (3,4):
            p.material_index=1
    for side in (-1,1):
        # Four wing roots; banked pose separates fore/hind and near/far silhouettes.
        for rear in (False,True):
            wing=empty("FlightWing_%s_%s"%(side,"Hind" if rear else "Fore"),fauna)
            wing.location=(-.08 if rear else -.29,side*.11,.13)
            tip=(1.02 if rear else -.91,side*1.14,.55 if side<0 else .27)
            dragon_wing(wing,tip,.115 if not rear else .15)
            art.join_geometry(wing)
    insect_legs(fauna)
    implant(root,(-.20,0,.23),.54,"insect")
    save("controlled_dragonfly","Fast air enemy visual; long segmented abdomen, four natural wings and removable canonical controller")

def moth():
    root=reset("ControlledBombMothModel")
    fauna=empty("NaturalFauna",root)
    ell("Abdomen",(.22,0,-.02),(.42,.15,.18),"MothTan",fauna,32,16)
    ell("Thorax",(-.20,0,.04),(.26,.20,.24),"MothCream",fauna,32,16)
    ell("Head",(-.49,0,.07),(.17,.155,.17),"MothTan",fauna,24,12)
    for side in (-1,1):
        ell("Eye_%d"%side,(-.56,side*.13,.115),(.052,.022,.061),"Eye",fauna,20,10)
        antenna=empty("FeatheryAntenna_%d"%side,fauna)
        tapered("AntennaStem",[(-.52,side*.07,.20),(-.65,side*.13,.40),(-.81,side*.16,.45)],[.013,.011,.004],"MothDark",antenna,8)
        for i in range(6):
            x=-.58-i*.031
            z=.29+i*.027
            tapered("AntennaFeather_%d"%i,[(x,side*.12,z),(x-.045,side*.13,z+.065)],[.007,.002],"MothDark",antenna,6)
        art.join_geometry(antenna)
        for rear in (False,True):
            wing=empty("FlightWing_%s_%s"%(side,"Hind" if rear else "Fore"),fauna)
            wing.location=(-.06,side*.14,.06)
            wing.rotation_euler.x=side*(.82 if side<0 else .34)
            outline=[(-.12,.02),(-.36,.62),(-.30,1.07),(-.06,1.28),(.38,1.17),(.58,.82),(.48,.31),(.22,.06)] if not rear else [(.08,.02),(.31,.18),(.68,.35),(.82,.70),(.62,.91),(.32,.88),(.11,.62)]
            # Lens-shaped 3D wing: closed rings, smooth thickness, rounded outline.
            outline=art.soften_closed(outline,4)
            cx=sum(x for x,z in outline)/len(outline)
            cy=sum(z for x,z in outline)/len(outline)
            verts=[]
            rings,n=6,len(outline)
            for face in (-1,1):
                verts.append((cx,side*cy,face*.04))
                for k in range(1,rings+1):
                    rho=k/rings
                    for x,y in outline:
                        verts.append((cx+(x-cx)*rho,side*(cy+(y-cy)*rho),face*.04*math.sqrt(max(0,1-rho*rho))))
            length=1+rings*n
            faces=[]
            for f in (0,1):
                off=f*length
                for j in range(n):
                    faces.append((off,off+1+j,off+1+(j+1)%n))
                for k in range(rings-1):
                    for j in range(n):
                        a=off+1+k*n+j
                        b=off+1+k*n+(j+1)%n
                        faces.append((a,b,b+n,a+n))
            # Equator weld closes the two domed faces; art.save validates manifold edges.
            panel=smooth(mesh("NaturalPanel",verts,faces,"MothTan" if not rear else "MothDark",wing))
            for face in (-1,1):
                for j in range(3 if not rear else 2):
                    ell("NaturalMark_%s_%d"%(face,j),(.02+j*.16,side*(.64+j*.11),face*.038),(.065,.11,.008),"MothCream",wing,20,10)
            art.join_geometry(wing)
    insect_legs(fauna)
    tech=implant(root,(-.46,-.18,.28),.48,"insect")
    # Bomb storage remains visibly technological and removable with the controller.
    rack=empty("BombRack",tech)
    rack.location=((.22+.46)/.48,.18/.48,(-.27-.28)/.48)
    for side in (-1,1):
        tapered("RackStrut_%d"%side,[(0,side*.22,.56),(.12,side*.28,.20),(.30,side*.27,0)],[.035,.025,.022],"Shell",rack,10)
    ell("GraphiteMagazine",(.28,0,0),(.30,.22,.11),"Shell",rack,24,12)
    ell("CyanReleaseLatch",(.28,-.22,0),(.10,.016,.035),"Cyan",rack,20,10)
    anchor=empty("BombDropAnchor",root)
    anchor.location=(.32,0,-.38)
    save("controlled_bomb_moth","Bomb moth with four scaled wings, feathery antennae and removable alien bomb magazine")

def mushroom():
    root=reset("ControlledMushroomCannonModel")
    fauna=empty("NaturalFauna",root)
    ell("Stem",(.10,0,.55),(.20,.20,.55),"MushroomStem",fauna,32,16)
    ell("StemBase",(.10,0,.12),(.32,.27,.14),"MushroomCream",fauna,32,16)
    # Lathed cap with distinct convex top and shallow gilled underside, solid volume.
    profile=[(.0,1.47),(.18,1.45),(.39,1.36),(.61,1.18),(.74,1.04),(.76,.99),(.68,.94),(.42,.96),(.16,1.01),(.0,1.04)]
    n=64
    verts=[(0,0,profile[0][1])]
    for r,z in profile[1:-1]:
        for j in range(n):
            a=j*math.tau/n
            verts.append((r*math.cos(a),r*math.sin(a),z))
    bottom=len(verts)
    verts.append((0,0,profile[-1][1]))
    faces=[]
    for j in range(n):
        faces.append((0,1+j,1+(j+1)%n))
    for k in range(len(profile)-3):
        for j in range(n):
            a=1+k*n+j
            b=1+k*n+(j+1)%n
            faces.append((a,b,b+n,a+n))
    for j in range(n):
        a=1+(len(profile)-3)*n+j
        b=1+(len(profile)-3)*n+(j+1)%n
        faces.append((a,b,bottom))
    cap=smooth(mesh("NaturalCap",verts,faces,"MushroomCap",fauna))
    cap.data.materials.append(art.MATERIALS["MushroomCream"])
    for p in cap.data.polygons:
        if p.index>=n*5:
            p.material_index=1
    spots=empty("CapSpots",fauna)
    for i,(a,r) in enumerate(((-1.7,.36),(-.7,.47),(-2.5,.51),(.5,.32),(2.2,.43))):
        x,y=r*math.cos(a),r*math.sin(a)
        z=1.47-.9*r*r
        obj=ell("Spot_%d"%i,(x,y,z+.013),(.11,.085,.025),"MushroomCream",spots,20,10)
        normal=Vector((1.8*x,1.8*y,1)).normalized()
        obj.rotation_mode="QUATERNION"
        obj.rotation_quaternion=normal.to_track_quat("Z","Y")
    art.join_geometry(spots)
    tech=implant(root,(.05,0,.73),.78,"insect")
    # Horizontal closed barrel: exterior shell, cyan lip, recessed dark bore and rear cap.
    cannon=empty("CannonAssembly",tech)
    cannon.location=(-.15,-.24,-.05)
    profile=[(-.14,.15),(-.64,.15),(-.72,.13),(-.72,.085),(-.57,.085),(-.57,.0)]
    verts=[]
    sides=32
    # Last zero-radius ring is a single pole, avoiding degenerate bore faces.
    for x,r in profile[:-1]:
        for j in range(sides):
            a=j*math.tau/sides
            verts.append((x,r*math.cos(a),r*math.sin(a)))
    pole=len(verts)
    verts.append((profile[-1][0],0,0))
    faces=[tuple(reversed(range(sides)))]
    for k in range(len(profile)-2):
        for j in range(sides):
            faces.append((k*sides+j,k*sides+(j+1)%sides,(k+1)*sides+(j+1)%sides,(k+1)*sides+j))
    for j in range(sides):
        faces.append(((len(profile)-2)*sides+j,(len(profile)-2)*sides+(j+1)%sides,pole))
    barrel=smooth(mesh("GraphiteBarrel",verts,faces,"Shell",cannon))
    barrel.data.materials.append(art.MATERIALS["Cyan"])
    barrel.data.materials.append(art.MATERIALS["Rubber"])
    for p in barrel.data.polygons:
        if 1+sides<=p.index<1+3*sides:
            p.material_index=1
        elif p.index>=1+3*sides:
            p.material_index=2
    muzzle=empty("MuzzleAnchor",root)
    muzzle.location=(-.64,-.187,.691)
    save("controlled_mushroom_cannon","Static ground artillery visual; natural mushroom with fully detachable horizontal cyan cannon")

def mine():
    root=reset("MothStationaryBombModel")
    device=empty("AlienControlDevice",root)
    ell("GraphiteBomb",(0,0,0),(.17,.15,.17),"Shell",device,32,16)
    for side in (-1,1):
        ell("CyanChargeWindow_%d"%side,(0,side*.142,0),(.10,.016,.08),"Cyan",device,24,12)
    for i in range(3):
        a=i*math.tau/3
        tapered("Stabilizer_%d"%i,[(.12*math.cos(a),0,.12*math.sin(a)),(.24*math.cos(a),0,.24*math.sin(a))],
                [.035,.016],"ShellEdge",device,10)
    ell("VioletFuse",(0,0,.19),(.035,)*3,"Violet",device,16,8)
    save("moth_stationary_bomb","Separate small alien mine visual; designed to hang stationary after release")

dragonfly()
moth()
mushroom()
mine()
(art.OUT/"manifest.json").write_text(json.dumps({"batch":"V10","assets":art.STATS},indent=2),encoding="utf-8")
print("FUTURE_BIOMES_V10_BLENDER_OK: "+json.dumps(art.STATS))
