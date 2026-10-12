"""One animation-ready derivative of the original V11 eagle, without overwriting it.
Reuses only its audited construction block; never executes the V11 batch/export.
Object pivots (not a skeletal rig) allow independent wing motion in Godot.
"""
from pathlib import Path
import ast, importlib.util, json
import bpy

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("bee_art", ROOT / "tools/art/create_future_biomes_v09.py")
art = importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)
art.OUT = ROOT / "assets/models/eagle_sky_v01"
art.SRC = ROOT / "art_source/blender/eagle_sky_v01"
for folder in (art.OUT, art.SRC):
    folder.mkdir(parents=True, exist_ok=True)
(art.SRC / ".gdignore").write_text("", encoding="utf-8")
art.PALETTE.update({"EagleBrown": (.35,.24,.14), "EagleFeather": (.48,.35,.20),
    "EagleHead": (.81,.76,.58), "EagleGold": (.76,.56,.18), "FeatherTip": (.24,.17,.10)})

source = ast.parse((ROOT / "tools/art/create_future_biomes_v11.py").read_text(encoding="utf-8"))
nodes = []
started = False
for node in source.body:
    if isinstance(node, ast.Assign) and isinstance(node.value, ast.Call):
        if any(isinstance(arg, ast.Constant) and arg.value == "ControlledEagleModel" for arg in node.value.args):
            started = True
    if not started:
        continue
    if isinstance(node, ast.Expr) and isinstance(node.value, ast.Call) and isinstance(node.value.func, ast.Name) and node.value.func.id == "finish":
        break
    nodes.append(node)
assert nodes, "Original eagle construction block missing"
namespace = dict(art=art, ell=art.ell, empty=art.empty, tapered=art.tapered)
exec(compile(ast.Module(body=nodes, type_ignores=[]), "original_eagle_construction", "exec"), namespace)

objects = [o for o in bpy.context.scene.objects if o.type == "MESH"]
before = sum(len(p.vertices)-2 for o in objects for p in o.data.polygons)
for obj in objects:
    modifier = obj.modifiers.new("MidPolyBudget", "DECIMATE")
    modifier.ratio = min(1, 7000 / before)
    modifier.use_collapse_triangulate = True
    art.apply_modifier(obj, modifier)

fauna = bpy.data.objects["NaturalFauna"]
wings = [bpy.data.objects["EagleWing_%d" % side] for side in (-1, 1)]
# Exclude wing meshes from the body batch while preserving world transforms.
for wing in wings:
    world = wing.matrix_world.copy()
    wing.parent = None
    wing.matrix_world = world
art.join_geometry(fauna)
for wing in wings:
    art.join_geometry(wing)
    world = wing.matrix_world.copy()
    wing.parent = fauna
    wing.matrix_world = world
namespace["root"].name = "ControlledEagleFlightModel"
art.save("controlled_eagle_flight", "Sky eagle with two independent wing pivots and removable neck controller")
stats = art.STATS[-1]
assert stats["triangles"] <= 7000
assert stats["mesh_objects"] == 4
for wing in wings:
    assert any(child.type == "MESH" for child in wing.children), wing.name
stats["animation"] = "Independent wing object pivots; no skeletal rig"
(art.OUT / "manifest.json").write_text(json.dumps({"batch": "eagle_sky_v01", "assets": art.STATS}, indent=2), encoding="utf-8")
print("EAGLE_SKY_BLENDER_OK: " + json.dumps(art.STATS))
