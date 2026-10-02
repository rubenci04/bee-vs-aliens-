# Helpers shared by the BEE STYLE TEST 01 version-B generators (dev only).
import bpy, math
from mathutils import Vector

RADIAL = 24
RING_STEPS = 3
WING_STEPS = 4


def smooth(o, angle=55.0):
	for p in o.data.polygons:
		p.use_smooth = True
	bpy.ops.object.select_all(action="DESELECT")
	o.select_set(True)
	bpy.context.view_layer.objects.active = o
	try:
		bpy.ops.object.shade_smooth_by_angle(angle=math.radians(angle))
	except Exception:
		pass


def _catmull(p0, p1, p2, p3, t):
	t2, t3 = t * t, t * t * t
	return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)


def ring_surface(name, rings, z_offset, parent, mats):
	"""Same banded abdomen as V01, with interpolated rings and a rounded fan cap at each end."""
	n = len(rings)
	dense = [] # (y, r, band)
	for j in range(n - 1):
		for k in range(RING_STEPS):
			t = k / RING_STEPS
			a, b, c, d = (rings[max(j - 1, 0)], rings[j], rings[j + 1], rings[min(j + 2, n - 1)])
			y = _catmull(a[0], b[0], c[0], d[0], t)
			r = max(_catmull(a[1], b[1], c[1], d[1], t), 0.004)
			dense.append((y, r, j))
	dense.append((rings[-1][0], rings[-1][1], n - 2))
	verts, faces, bands = [], [], []
	for y, r, _band in dense:
		for i in range(RADIAL):
			a = 2 * math.pi * i / RADIAL
			verts.append((r * math.cos(a), y, r * math.sin(a) * .88 + z_offset))
	for j in range(len(dense) - 1):
		for i in range(RADIAL):
			faces.append((j * RADIAL + i, j * RADIAL + (i + 1) % RADIAL, (j + 1) * RADIAL + (i + 1) % RADIAL, (j + 1) * RADIAL + i))
			bands.append(dense[j][2] % 2)
	cap_band = (n - 1) % 2
	front = len(verts)
	verts.append((0, dense[0][0] + dense[0][1] * 0.35, z_offset))
	for i in range(RADIAL):
		faces.append((front, (i + 1) % RADIAL, i))
		bands.append(cap_band)
	last = (len(dense) - 1) * RADIAL
	back = len(verts)
	verts.append((0, dense[-1][0] - dense[-1][1] * 0.45, z_offset))
	for i in range(RADIAL):
		faces.append((back, last + i, last + (i + 1) % RADIAL))
		bands.append(cap_band)
	mesh = bpy.data.meshes.new(name + "Mesh")
	mesh.from_pydata(verts, [], faces)
	mesh.update()
	obj = bpy.data.objects.new(name, mesh)
	bpy.context.collection.objects.link(obj)
	obj.parent = parent
	for m in mats:
		mesh.materials.append(m)
	for p in mesh.polygons:
		p.material_index = bands[p.index]
	smooth(obj, 80.0)
	return obj


def curved_wing(name, outline, centre, mat, parent):
	"""V01 wing fan, but the outline is a closed spline (rounded membrane) instead of 6 corners."""
	pts = [Vector(p) for p in outline]
	n = len(pts)
	dense = []
	for i in range(n):
		for k in range(WING_STEPS):
			dense.append(_catmull(pts[i - 1], pts[i], pts[(i + 1) % n], pts[(i + 2) % n], k / WING_STEPS))
	verts = [tuple(p) for p in dense] + [centre]
	c = len(dense)
	faces = [(c, i, (i + 1) % c) for i in range(c)]
	mesh = bpy.data.meshes.new("WingMesh_" + name)
	mesh.from_pydata(verts, [], faces)
	mesh.materials.append(mat)
	mesh.update()
	obj = bpy.data.objects.new(name, mesh)
	bpy.context.collection.objects.link(obj)
	obj.parent = parent
	smooth(obj, 80.0)
	return obj
