class_name BeeMeshKit
extends RefCounted
## Mejora visual: fábrica de modelos propios low-poly hechos por código (sin assets externos, sin dudas de licencia).
## Cada modelo es una "plantilla": triángulos con color por vértice, en dos grupos: sólido (lleva contorno) y lámina (hojas finas,
## doble cara, sin contorno). Las plantillas se hornean juntas por tramo del nivel: un tramo lleno de plantas cuesta 2 o 3 draw calls.

var v := PackedVector3Array()
var n := PackedVector3Array()
var c := PackedColorArray()
var lv := PackedVector3Array()
var ln := PackedVector3Array()
var lc := PackedColorArray()

static var _cache: Dictionary = {}


static func xf(pos: Vector3, rot_deg := Vector3.ZERO, scale := Vector3.ONE) -> Transform3D:
	var basis := Basis.from_euler(Vector3(deg_to_rad(rot_deg.x), deg_to_rad(rot_deg.y), deg_to_rad(rot_deg.z))).scaled_local(scale)
	return Transform3D(basis, pos)


func _push_solid(a: Vector3, b: Vector3, d: Vector3, color: Color, center: Vector3) -> void:
	var normal := (a - d).cross(a - b)
	if normal.length_squared() < 1e-12:
		return
	normal = normal.normalized()
	if normal.dot((a + b + d) / 3.0 - center) < 0.0: # Siempre hacia afuera del sólido (el contorno depende de eso).
		var swap := b
		b = d
		d = swap
		normal = -normal
	v.append(a); v.append(b); v.append(d)
	n.append(normal); n.append(normal); n.append(normal)
	c.append(color); c.append(color); c.append(color)


func _push_sheet(a: Vector3, b: Vector3, d: Vector3, color_a: Color, color_b: Color, color_d: Color) -> void:
	var normal := (a - d).cross(a - b)
	if normal.length_squared() < 1e-12:
		return
	normal = normal.normalized()
	lv.append(a); lv.append(b); lv.append(d)
	ln.append(normal); ln.append(normal); ln.append(normal)
	lc.append(color_a); lc.append(color_b); lc.append(color_d)


func box(t: Transform3D, color: Color) -> BeeMeshKit:
	var center := t.origin
	var corners: Array[Vector3] = []
	for i in 8:
		corners.append(t * Vector3(-0.5 if i & 1 == 0 else 0.5, -0.5 if i & 2 == 0 else 0.5, -0.5 if i & 4 == 0 else 0.5))
	for face in [[0, 1, 3, 2], [4, 5, 7, 6], [0, 1, 5, 4], [2, 3, 7, 6], [0, 2, 6, 4], [1, 3, 7, 5]]:
		var shade := 1.0 if face == [2, 3, 7, 6] else 0.94
		var col := Color(color.r * shade, color.g * shade, color.b * shade)
		_push_solid(corners[face[0]], corners[face[1]], corners[face[2]], col, center)
		_push_solid(corners[face[0]], corners[face[2]], corners[face[3]], col, center)
	return self


## Cilindro o cono truncado con base en el origen de `t` y eje en +Y local.
func cylinder(t: Transform3D, r0: float, r1: float, height: float, sides: int, color: Color, top_color := Color(0, 0, 0, 0)) -> BeeMeshKit:
	var center := t * Vector3(0, height * 0.5, 0)
	var cap: Color = color if top_color.a == 0.0 else top_color
	for i in sides:
		var a0 := TAU * float(i) / float(sides)
		var a1 := TAU * float(i + 1) / float(sides)
		var p00 := t * Vector3(cos(a0) * r0, 0, sin(a0) * r0)
		var p01 := t * Vector3(cos(a1) * r0, 0, sin(a1) * r0)
		var p10 := t * Vector3(cos(a0) * r1, height, sin(a0) * r1)
		var p11 := t * Vector3(cos(a1) * r1, height, sin(a1) * r1)
		_push_solid(p00, p01, p11, color, center)
		if r1 > 0.0001:
			_push_solid(p00, p11, p10, color, center)
			_push_solid(t * Vector3(0, height, 0), p10, p11, cap, center)
		_push_solid(t * Vector3.ZERO, p00, p01, color, center)
	return self


## Esfera facetada de radio 1 escalada por `t`; `flat_bottom` corta la mitad inferior.
func sphere(t: Transform3D, color: Color, rings := 4, sides := 7, color_bottom := Color(0, 0, 0, 0), flat_bottom := false) -> BeeMeshKit:
	var center := t.origin
	var inverse_scale := t.basis.inverse().transposed() # Normales correctas aunque la esfera esté aplastada...
	var normal_basis := inverse_scale * t.basis.inverse() # ...se aplican sobre (punto - centro) ya transformado.
	var low: Color = color if color_bottom.a == 0.0 else color_bottom
	var first := rings / 2 if flat_bottom else 0
	for r in range(first, rings):
		var phi0 := PI * (float(r) / float(rings) - 0.5)
		var phi1 := PI * (float(r + 1) / float(rings) - 0.5)
		var col := low.lerp(color, float(r) / maxf(float(rings - 1), 1.0))
		for s in sides:
			var a0 := TAU * float(s) / float(sides)
			var a1 := TAU * float(s + 1) / float(sides)
			var p00 := t * Vector3(cos(phi0) * cos(a0), sin(phi0), cos(phi0) * sin(a0))
			var p01 := t * Vector3(cos(phi0) * cos(a1), sin(phi0), cos(phi0) * sin(a1))
			var p10 := t * Vector3(cos(phi1) * cos(a0), sin(phi1), cos(phi1) * sin(a0))
			var p11 := t * Vector3(cos(phi1) * cos(a1), sin(phi1), cos(phi1) * sin(a1))
			_push_round(p00, p01, p11, col, center, normal_basis)
			_push_round(p00, p11, p10, col, center, normal_basis)
	return self


## Triángulo de esfera con normales suaves: se ve redondo en la banda toon y el contorno no se abre en las aristas.
func _push_round(a: Vector3, b: Vector3, d: Vector3, color: Color, center: Vector3, normal_basis: Basis) -> void:
	var face := (a - d).cross(a - b)
	if face.length_squared() < 1e-12:
		return
	if face.dot((a + b + d) / 3.0 - center) < 0.0:
		var swap := b
		b = d
		d = swap
	v.append(a); v.append(b); v.append(d)
	n.append((normal_basis * (a - center)).normalized())
	n.append((normal_basis * (b - center)).normalized())
	n.append((normal_basis * (d - center)).normalized())
	c.append(color); c.append(color); c.append(color)


## Hoja fina con doblez central. Crece sobre +Y local; `bend` la curva hacia +X.
func leaf(t: Transform3D, length: float, width: float, color_base: Color, color_tip: Color, bend := 0.0, rows := 4) -> BeeMeshKit:
	var prev: Array = []
	for r in rows + 1:
		var u := float(r) / float(rows)
		var half := width * 0.5 * sin(PI * pow(u, 0.75)) if u < 1.0 else 0.0
		var spine := Vector3(bend * u * u, length * u, 0.0)
		var col := color_base.lerp(color_tip, u)
		var row := [t * (spine + Vector3(-half, 0, -half * 0.25)), t * (spine + Vector3(0, 0, half * 0.2)), t * (spine + Vector3(half, 0, -half * 0.25)), col]
		if r > 0:
			for side in [[0, 1], [1, 2]]:
				_push_sheet(prev[side[0]], prev[side[1]], row[side[1]], prev[3], prev[3], col)
				_push_sheet(prev[side[0]], row[side[1]], row[side[0]], prev[3], col, col)
		prev = row
	return self


## Rectángulo fino de doble cara (ropa colgada, carteles, techos).
func sheet(t: Transform3D, color: Color, color_low := Color(0, 0, 0, 0)) -> BeeMeshKit:
	var low: Color = color if color_low.a == 0.0 else color_low
	var a := t * Vector3(-0.5, -0.5, 0)
	var b := t * Vector3(0.5, -0.5, 0)
	var d := t * Vector3(0.5, 0.5, 0)
	var e := t * Vector3(-0.5, 0.5, 0)
	_push_sheet(a, b, d, low, low, color)
	_push_sheet(a, d, e, low, color, color)
	return self


# --- plantillas ---------------------------------------------------------------------------------------------------

static func template(id: StringName) -> BeeMeshKit:
	if _cache.has(id):
		return _cache[id]
	var kit := BeeMeshKit.new()
	var build := Callable(BeeMeshKit, "_t_" + str(id))
	build.call(kit)
	_cache[id] = kit
	return kit


const GREEN := Color(0.26, 0.56, 0.2)
const GREEN_LIGHT := Color(0.52, 0.78, 0.26)
const GREEN_DARK := Color(0.12, 0.34, 0.16)
const STEM := Color(0.3, 0.56, 0.2)
const WOOD := Color(0.5, 0.33, 0.2)
const WOOD_DARK := Color(0.3, 0.19, 0.12)

static func _stem(kit: BeeMeshKit, height: float, radius := 0.06, lean := 0.0) -> Vector3:
	kit.cylinder(xf(Vector3.ZERO, Vector3(0, 0, lean)), radius * 1.3, radius * 0.8, height, 5, STEM)
	return xf(Vector3.ZERO, Vector3(0, 0, lean)) * Vector3(0, height, 0)

static func _petals(kit: BeeMeshKit, at: Vector3, count: int, length: float, width: float, color: Color, color_tip: Color, tilt := 62.0) -> void:
	for i in count:
		var yaw := 360.0 * float(i) / float(count)
		kit.leaf(Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, deg_to_rad(tilt)), at), length, width, color, color_tip, 0.0, 2)

static func _t_dandelion(kit: BeeMeshKit) -> void:
	var top := _stem(kit, 2.6, 0.05, 4.0)
	kit.sphere(xf(top, Vector3.ZERO, Vector3.ONE * 0.5), Color(0.98, 0.97, 0.9), 4, 8, Color(0.82, 0.84, 0.78))
	kit.sphere(xf(top, Vector3.ZERO, Vector3.ONE * 0.12), Color(0.62, 0.52, 0.26))
	for i in 5:
		kit.leaf(xf(Vector3.ZERO, Vector3(0, 72.0 * i, 58)), 1.0, 0.3, GREEN_DARK, GREEN, 0.0, 3)

static func _t_daisy(kit: BeeMeshKit) -> void:
	for spec in [[0.0, 0.0, 2.3], [0.7, 0.2, 1.7], [-0.6, 0.3, 1.5]]:
		var base := Vector3(spec[0], 0, spec[1])
		kit.cylinder(xf(base), 0.06, 0.04, spec[2], 5, STEM)
		var top := base + Vector3(0, spec[2], 0)
		_petals(kit, top, 11, 0.62, 0.22, Color(0.94, 0.94, 0.9), Color(1, 1, 1), 66.0)
		kit.sphere(xf(top + Vector3(0, 0.05, 0), Vector3.ZERO, Vector3(0.2, 0.1, 0.2)), Color(1.0, 0.76, 0.14))
	for i in 7:
		kit.leaf(xf(Vector3.ZERO, Vector3(0, 51.0 * i, 52)), 1.05, 0.34, GREEN_DARK, GREEN_LIGHT, 0.0, 3)

static func _t_clover(kit: BeeMeshKit) -> void:
	for i in 9:
		var at := Vector3(cos(i * 2.4) * (0.2 + i * 0.09), 0, sin(i * 2.4) * (0.2 + i * 0.09))
		var top := at + Vector3(0, 0.34 + 0.03 * (i % 3), 0)
		kit.cylinder(xf(at), 0.03, 0.02, top.y, 4, STEM)
		for k in 3:
			kit.sphere(xf(top + Vector3(cos(k * 2.09) * 0.13, 0, sin(k * 2.09) * 0.13), Vector3.ZERO, Vector3(0.14, 0.04, 0.14)), GREEN_LIGHT if i % 2 else GREEN, 2, 6)
	kit.cylinder(xf(Vector3(0.25, 0, 0.2)), 0.03, 0.02, 0.66, 4, STEM)
	kit.sphere(xf(Vector3(0.25, 0.72, 0.2), Vector3.ZERO, Vector3(0.14, 0.13, 0.14)), Color(0.96, 0.7, 0.86))

static func _t_toadstool(kit: BeeMeshKit) -> void:
	for spec in [[0.0, 0.0, 1.2, 1.0], [0.8, 0.3, 0.75, 0.62], [-0.7, 0.2, 0.55, 0.48]]:
		var base := Vector3(spec[0], 0, spec[1])
		kit.cylinder(xf(base), 0.16 * spec[3] * 1.3, 0.12 * spec[3], spec[2], 6, Color(0.95, 0.92, 0.82))
		var top := base + Vector3(0, spec[2], 0)
		kit.sphere(xf(top, Vector3.ZERO, Vector3(0.6, 0.42, 0.6) * spec[3]), Color(0.9, 0.16, 0.12), 4, 9, Color(0.97, 0.9, 0.78), true)
		for k in 5:
			var a := k * 1.26
			kit.sphere(xf(top + Vector3(cos(a) * 0.32, 0.28, sin(a) * 0.32) * spec[3], Vector3.ZERO, Vector3(0.08, 0.04, 0.08) * spec[3]), Color(1, 1, 0.96), 2, 5)

static func _t_ball(kit: BeeMeshKit) -> void:
	var colors := [Color(0.92, 0.2, 0.2), Color(0.98, 0.96, 0.9), Color(0.2, 0.46, 0.9), Color(0.98, 0.96, 0.9), Color(0.98, 0.78, 0.14), Color(0.98, 0.96, 0.9)]
	var sides := 12
	var rings := 6
	var center := Vector3(0, 1.0, 0)
	for r in rings:
		var phi0 := PI * (float(r) / float(rings) - 0.5)
		var phi1 := PI * (float(r + 1) / float(rings) - 0.5)
		for s in sides:
			var a0 := TAU * float(s) / float(sides)
			var a1 := TAU * float(s + 1) / float(sides)
			var col: Color = colors[int(s / 2) % colors.size()]
			var p00 := center + Vector3(cos(phi0) * cos(a0), sin(phi0), cos(phi0) * sin(a0))
			var p01 := center + Vector3(cos(phi0) * cos(a1), sin(phi0), cos(phi0) * sin(a1))
			var p10 := center + Vector3(cos(phi1) * cos(a0), sin(phi1), cos(phi1) * sin(a0))
			var p11 := center + Vector3(cos(phi1) * cos(a1), sin(phi1), cos(phi1) * sin(a1))
			kit._push_solid(p00, p01, p11, col, center)
			kit._push_solid(p00, p11, p10, col, center)

static func _t_sprinkler(kit: BeeMeshKit) -> void:
	kit.cylinder(xf(Vector3.ZERO), 0.5, 0.42, 0.16, 8, Color(0.25, 0.5, 0.3))
	kit.cylinder(xf(Vector3(0, 0.16, 0)), 0.1, 0.08, 0.8, 6, Color(0.72, 0.74, 0.76))
	for i in 3:
		kit.box(xf(Vector3(0, 0.96, 0), Vector3(0, 60.0 * i, 0), Vector3(1.2, 0.08, 0.12)), Color(0.78, 0.8, 0.82))

static func _t_tulips(kit: BeeMeshKit) -> void:
	var palette := [Color(0.95, 0.2, 0.42), Color(0.98, 0.72, 0.14), Color(0.72, 0.24, 0.84), Color(1.0, 0.44, 0.24)]
	for i in 7:
		var at := Vector3(cos(i * 2.2) * (0.25 + i * 0.13), 0, sin(i * 2.2) * (0.25 + i * 0.1))
		var h := 2.0 + (i % 3) * 0.5
		kit.cylinder(xf(at), 0.06, 0.05, h, 5, STEM)
		var col: Color = palette[i % palette.size()]
		var top := at + Vector3(0, h, 0)
		kit.sphere(xf(top + Vector3(0, 0.2, 0), Vector3.ZERO, Vector3(0.26, 0.36, 0.26)), col, 4, 6, Color(col.r * 0.6, col.g * 0.6, col.b * 0.6))
		for k in 3:
			var yaw := 120.0 * k
			kit.leaf(Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, deg_to_rad(-14.0)), top + Vector3(0, 0.1, 0)), 0.62, 0.34, Color(col.r * 0.8, col.g * 0.8, col.b * 0.8), col, 0.0, 2)
		kit.leaf(xf(at, Vector3(0, 40.0 * i, 16)), 1.4, 0.3, GREEN_DARK, GREEN, 0.3, 3)

static func _t_rose_bush(kit: BeeMeshKit) -> void:
	for i in 6:
		var a := i * 1.05
		kit.sphere(xf(Vector3(cos(a) * 0.9, 1.1 + 0.4 * sin(a * 2.0), sin(a) * 0.7), Vector3.ZERO, Vector3(1.0, 0.9, 0.9)), Color(0.18, 0.5, 0.22), 3, 7, Color(0.08, 0.26, 0.14))
	kit.sphere(xf(Vector3(0, 1.7, 0), Vector3.ZERO, Vector3(1.0, 0.8, 0.8)), Color(0.22, 0.56, 0.24), 3, 7, Color(0.1, 0.3, 0.15))
	var colors := [Color(0.96, 0.2, 0.36), Color(1.0, 0.56, 0.68), Color(0.98, 0.3, 0.46)]
	for i in 12:
		var a := i * 2.4
		var at := Vector3(cos(a) * (0.6 + 0.08 * i), 1.0 + fmod(i * 0.37, 1.3), 0.55 + sin(a) * 0.4)
		kit.sphere(xf(at, Vector3(i * 30.0, i * 50.0, 0), Vector3.ONE * 0.24), colors[i % 3], 3, 6)

static func _t_lavender(kit: BeeMeshKit) -> void:
	for i in 12:
		var at := Vector3(float(i) * 0.3 - 1.7, 0, sin(i * 1.7) * 0.4)
		var h := 1.6 + fmod(i * 0.41, 0.8)
		kit.cylinder(xf(at, Vector3(0, 0, sin(i * 2.0) * 6.0)), 0.035, 0.025, h, 4, Color(0.42, 0.56, 0.36))
		kit.sphere(xf(at + Vector3(0, h, 0), Vector3.ZERO, Vector3(0.09, 0.34, 0.09)), Color(0.56, 0.36, 0.86), 3, 5, Color(0.36, 0.24, 0.66))

static func _t_sunflower(kit: BeeMeshKit) -> void:
	var top := _stem(kit, 5.4, 0.13, 3.0)
	_petals(kit, top, 14, 1.0, 0.36, Color(0.98, 0.7, 0.08), Color(1.0, 0.86, 0.2), 76.0)
	kit.sphere(xf(top + Vector3(0, 0, 0.02), Vector3(80, 0, 0), Vector3(0.52, 0.14, 0.52)), Color(0.32, 0.18, 0.08))
	for spec in [[1.4, 40.0], [2.5, 200.0], [3.5, 110.0]]:
		kit.leaf(xf(Vector3(0, spec[0], 0), Vector3(0, spec[1], 62)), 1.5, 0.8, GREEN_DARK, GREEN, 0.0, 3)

static func _t_brick_edge(kit: BeeMeshKit) -> void:
	for row in 2:
		for i in 6:
			var tone := 0.86 + fmod(i * 0.37 + row, 0.28)
			kit.box(xf(Vector3(float(i) * 0.66 - 1.65 + row * 0.33, 0.17 + row * 0.3, 0), Vector3(0, 0, 0), Vector3(0.62, 0.28, 0.42)), Color(0.72 * tone, 0.46 * tone, 0.36 * tone))

static func _t_brick_wall(kit: BeeMeshKit) -> void:
	# Muro de jardín de 7,2 m de largo con ladrillos a la vista, cornisa y hiedra.
	kit.box(xf(Vector3(0, 3.0, 0), Vector3.ZERO, Vector3(7.25, 6.0, 0.7)), Color(0.72, 0.5, 0.42))
	for row in 11:
		for i in 7:
			if int(fmod(float(i) * 3.0 + float(row) * 5.0, 4.0)) == 0:
				var tone := 0.8 + fmod(i * 0.31 + row * 0.17, 0.42)
				kit.box(xf(Vector3(-3.2 + i * 1.05 + (row % 2) * 0.5, 0.3 + row * 0.53, 0.37), Vector3.ZERO, Vector3(1.0, 0.46, 0.06)), Color(0.8 * tone, 0.52 * tone, 0.42 * tone))
	kit.box(xf(Vector3(0, 6.1, 0), Vector3.ZERO, Vector3(7.25, 0.24, 0.95)), Color(0.76, 0.7, 0.62))
	for i in 16:
		var at := Vector3(-3.3 + fmod(i * 1.73, 6.6), 1.2 + fmod(i * 2.3, 4.6), 0.42)
		kit.sphere(xf(at, Vector3.ZERO, Vector3(0.6, 0.5, 0.14)), Color(0.24, 0.54, 0.2) if i % 2 else Color(0.16, 0.42, 0.18), 2, 6)

static func _t_trellis(kit: BeeMeshKit) -> void:
	for i in 5:
		kit.box(xf(Vector3(-1.6 + i * 0.8, 2.5, 0), Vector3.ZERO, Vector3(0.09, 5.0, 0.09)), Color(0.9, 0.86, 0.76))
		kit.box(xf(Vector3(0, 0.6 + i * 1.05, 0), Vector3.ZERO, Vector3(3.5, 0.08, 0.08)), Color(0.9, 0.86, 0.76))
	for i in 15:
		var at := Vector3(-1.6 + fmod(i * 1.37, 3.2), 0.5 + fmod(i * 1.91, 4.3), 0.12)
		kit.sphere(xf(at, Vector3.ZERO, Vector3(0.42, 0.34, 0.14)), GREEN if i % 2 else GREEN_DARK, 2, 6)
		if i % 3 == 0:
			kit.sphere(xf(at + Vector3(0.1, 0.08, 0.12), Vector3.ZERO, Vector3.ONE * 0.16), Color(0.98, 0.32, 0.52), 2, 6)

static func _t_lettuce(kit: BeeMeshKit) -> void:
	kit.sphere(xf(Vector3(0, 0.55, 0), Vector3.ZERO, Vector3(0.75, 0.6, 0.75)), Color(0.6, 0.86, 0.3), 3, 7, Color(0.3, 0.56, 0.2))
	for i in 10:
		var yaw := 36.0 * i
		kit.leaf(Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, deg_to_rad(52.0)), Vector3(0, 0.08, 0)), 1.3, 0.9, Color(0.3, 0.56, 0.2), Color(0.68, 0.9, 0.34), 0.0, 3)

static func _t_carrots(kit: BeeMeshKit) -> void:
	for i in 5:
		var at := Vector3(float(i) * 0.95 - 1.9, 0, 0)
		kit.cylinder(xf(at), 0.2, 0.26, 0.24, 7, Color(0.96, 0.5, 0.1))
		for k in 7:
			kit.leaf(xf(at + Vector3(0, 0.24, 0), Vector3(0, 51.0 * k, 14.0 + (k % 3) * 8.0)), 1.05 + (k % 2) * 0.3, 0.2, Color(0.2, 0.5, 0.16), Color(0.46, 0.76, 0.22), 0.0, 2)

static func _t_tomato(kit: BeeMeshKit) -> void:
	kit.cylinder(xf(Vector3(0, 0, 0), Vector3(0, 0, 2)), 0.06, 0.05, 4.4, 5, Color(0.76, 0.62, 0.38))
	for i in 9:
		var h := 0.5 + i * 0.42
		var a := i * 2.2
		kit.sphere(xf(Vector3(cos(a) * 0.5, h, sin(a) * 0.4), Vector3.ZERO, Vector3(0.72, 0.56, 0.6)), Color(0.34, 0.62, 0.28), 3, 7, Color(0.22, 0.44, 0.2))
	for i in 7:
		var a := i * 1.8
		kit.sphere(xf(Vector3(cos(a) * 0.55, 0.9 + i * 0.42, 0.34 + sin(a) * 0.3), Vector3.ZERO, Vector3.ONE * 0.26), Color(0.92, 0.16, 0.1) if i % 3 else Color(0.98, 0.5, 0.14), 3, 7)

static func _t_pumpkin(kit: BeeMeshKit) -> void:
	for i in 7:
		var a := TAU * float(i) / 7.0
		kit.sphere(xf(Vector3(cos(a) * 0.55, 0.78, sin(a) * 0.55), Vector3.ZERO, Vector3(0.6, 0.78, 0.6)), Color(0.98, 0.56, 0.1), 3, 7, Color(0.76, 0.32, 0.06))
	kit.cylinder(xf(Vector3(0, 1.45, 0), Vector3(0, 0, 12)), 0.14, 0.08, 0.42, 6, Color(0.36, 0.42, 0.14))
	kit.leaf(xf(Vector3(0.7, 0.04, 0.5), Vector3(70, 30, 0)), 1.5, 1.2, GREEN_DARK, GREEN, 0.0, 3)

static func _t_scarecrow(kit: BeeMeshKit) -> void:
	kit.cylinder(xf(Vector3.ZERO), 0.11, 0.09, 6.0, 6, WOOD)
	kit.box(xf(Vector3(0, 4.3, 0), Vector3.ZERO, Vector3(3.6, 0.16, 0.16)), WOOD)
	kit.box(xf(Vector3(0, 3.6, 0), Vector3.ZERO, Vector3(1.2, 1.7, 0.5)), Color(0.28, 0.44, 0.68))
	kit.box(xf(Vector3(0, 4.3, 0), Vector3.ZERO, Vector3(3.0, 0.42, 0.4)), Color(0.28, 0.44, 0.68))
	kit.sphere(xf(Vector3(0, 5.2, 0), Vector3.ZERO, Vector3(0.5, 0.56, 0.5)), Color(0.86, 0.72, 0.44))
	kit.cylinder(xf(Vector3(0, 5.5, 0)), 0.86, 0.34, 0.22, 9, Color(0.5, 0.34, 0.14))
	kit.cylinder(xf(Vector3(0, 5.7, 0)), 0.38, 0.3, 0.5, 9, Color(0.5, 0.34, 0.14))
	for side in [-1.6, 1.6]:
		for i in 4:
			kit.leaf(xf(Vector3(side, 4.3, 0), Vector3(0, 0, 180 + (i - 1.5) * 20.0)), 0.6, 0.12, Color(0.86, 0.74, 0.34), Color(0.95, 0.84, 0.44), 0.0, 1)

static func _t_wheelbarrow(kit: BeeMeshKit) -> void:
	kit.cylinder(xf(Vector3(-1.5, 0.5, 0), Vector3(90, 0, 0)), 0.5, 0.5, 0.2, 10, Color(0.16, 0.16, 0.18))
	kit.box(xf(Vector3(0.2, 1.15, 0), Vector3(0, 0, -6), Vector3(2.5, 0.75, 1.5)), Color(0.2, 0.52, 0.42))
	kit.box(xf(Vector3(0.2, 1.46, 0), Vector3(0, 0, -6), Vector3(2.2, 0.12, 1.25)), Color(0.32, 0.2, 0.12))
	for z in [-0.6, 0.6]:
		kit.box(xf(Vector3(1.0, 0.92, z), Vector3(0, 0, -10), Vector3(3.8, 0.1, 0.1)), WOOD)
		kit.box(xf(Vector3(0.9, 0.36, z), Vector3.ZERO, Vector3(0.1, 0.8, 0.1)), WOOD)

static func _t_seed_sign(kit: BeeMeshKit) -> void:
	kit.box(xf(Vector3(0, 0.62, 0), Vector3(0, 0, -3), Vector3(0.1, 1.3, 0.05)), Color(0.86, 0.76, 0.56))
	kit.box(xf(Vector3(0, 1.28, 0.02), Vector3(0, 0, -3), Vector3(0.62, 0.84, 0.05)), Color(0.98, 0.94, 0.8))
	kit.box(xf(Vector3(0, 1.32, 0.05), Vector3(0, 0, -3), Vector3(0.44, 0.34, 0.02)), Color(0.96, 0.44, 0.14))
	kit.box(xf(Vector3(0, 1.0, 0.05), Vector3(0, 0, -3), Vector3(0.46, 0.08, 0.02)), Color(0.22, 0.5, 0.22))

static func _t_greenhouse(kit: BeeMeshKit) -> void:
	var glass := Color(0.5, 0.78, 0.74)
	var frame := Color(1.0, 1.0, 1.0)
	kit.box(xf(Vector3(0, 0.5, 0), Vector3.ZERO, Vector3(12, 1.0, 6)), Color(0.58, 0.3, 0.22))
	kit.box(xf(Vector3(0, 3.0, 0), Vector3.ZERO, Vector3(11.8, 4.0, 5.8)), glass)
	for i in 7:
		kit.box(xf(Vector3(-5.9 + i * 1.97, 3.0, 2.95), Vector3.ZERO, Vector3(0.16, 4.0, 0.1)), frame)
	kit.box(xf(Vector3(0, 3.0, 2.97), Vector3.ZERO, Vector3(11.9, 0.14, 0.1)), frame)
	kit.box(xf(Vector3(0, 6.4, 1.6), Vector3(-42, 0, 0), Vector3(12.0, 0.14, 4.6)), Color(0.8, 0.95, 0.92))
	kit.box(xf(Vector3(0, 6.4, -1.6), Vector3(42, 0, 0), Vector3(12.0, 0.14, 4.6)), Color(0.66, 0.84, 0.8))
	for i in 5:
		kit.sphere(xf(Vector3(-4.6 + i * 2.3, 1.7, 2.2), Vector3.ZERO, Vector3(0.9, 0.9, 0.5)), Color(0.32, 0.62, 0.3), 2, 6)

static func _t_board_wall(kit: BeeMeshKit) -> void:
	for i in 9:
		var tone := 0.82 + fmod(i * 0.37, 0.3)
		kit.box(xf(Vector3(-3.2 + i * 0.8, 2.6, 0), Vector3.ZERO, Vector3(0.74, 5.2 + fmod(i * 0.71, 0.5), 0.2)), Color(0.62 * tone, 0.42 * tone, 0.24 * tone))
	for y in [1.2, 4.2]:
		kit.box(xf(Vector3(0, y, -0.14), Vector3.ZERO, Vector3(7.25, 0.34, 0.1)), Color(0.42, 0.28, 0.16))

static func _t_fern(kit: BeeMeshKit) -> void:
	for i in 9:
		var yaw := 40.0 * i
		var base := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, deg_to_rad(38.0 + (i % 3) * 8.0)), Vector3.ZERO)
		kit.leaf(base, 2.4 + (i % 3) * 0.3, 0.72, Color(0.06, 0.32, 0.22), Color(0.26, 0.66, 0.34), 0.2, 5)

static func _t_hosta(kit: BeeMeshKit) -> void:
	for i in 8:
		var yaw := 45.0 * i
		var base := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, deg_to_rad(44.0)), Vector3.ZERO)
		kit.leaf(base, 2.4, 1.5, Color(0.08, 0.38, 0.34), Color(0.36, 0.72, 0.5), 0.3, 4)

static func _t_trunk(kit: BeeMeshKit) -> void:
	var bark := Color(0.44, 0.34, 0.27)
	kit.cylinder(xf(Vector3.ZERO), 2.6, 1.7, 5.0, 11, bark)
	kit.cylinder(xf(Vector3(0, 5.0, 0)), 1.7, 1.4, 18.0, 11, Color(0.4, 0.31, 0.25))
	for i in 6:
		var a := i * 60.0
		kit.cylinder(xf(Vector3(0, 0.1, 0), Vector3(0, a, 74)), 0.9, 0.12, 4.6, 6, bark)
	for i in 8:
		kit.sphere(xf(Vector3(cos(i * 1.7) * 2.0, 1.3 + fmod(i * 1.13, 5.0), 1.1 + sin(i * 1.7) * 0.5), Vector3.ZERO, Vector3(0.8, 0.5, 0.3)), Color(0.16, 0.42, 0.22), 2, 6)

static func _t_mossy_log(kit: BeeMeshKit) -> void:
	kit.cylinder(xf(Vector3(-3.2, 0.72, 0), Vector3(0, 0, -90)), 0.76, 0.66, 6.4, 9, Color(0.27, 0.19, 0.14), Color(0.62, 0.46, 0.28))
	for i in 9:
		kit.sphere(xf(Vector3(-2.8 + i * 0.7, 1.32 + sin(i * 2.0) * 0.08, 0.06), Vector3.ZERO, Vector3(0.6, 0.2, 0.48)), Color(0.22, 0.56, 0.24), 2, 6)

static func _t_mushrooms(kit: BeeMeshKit) -> void:
	for i in 7:
		var at := Vector3(cos(i * 2.3) * (0.1 + i * 0.16), 0, sin(i * 2.3) * (0.1 + i * 0.12))
		var size := 0.48 + fmod(i * 0.37, 0.5)
		kit.cylinder(xf(at), 0.07 * size * 2.0, 0.05 * size * 2.0, size, 5, Color(0.82, 0.86, 0.78))
		kit.sphere(xf(at + Vector3(0, size, 0), Vector3.ZERO, Vector3(0.3, 0.2, 0.3) * size * 1.5), Color(0.5, 0.86, 0.72), 3, 7, Color(0.9, 0.94, 0.84), true)

static func _t_canopy_leaf(kit: BeeMeshKit) -> void:
	kit.leaf(xf(Vector3.ZERO), 11.0, 6.4, Color(0.12, 0.3, 0.2), Color(0.4, 0.5, 0.3), 1.0, 6)

static func _t_flower_pot(kit: BeeMeshKit) -> void:
	kit.cylinder(xf(Vector3.ZERO), 0.72, 1.0, 1.4, 9, Color(0.76, 0.4, 0.24))
	kit.cylinder(xf(Vector3(0, 1.3, 0)), 1.1, 1.1, 0.26, 9, Color(0.82, 0.46, 0.28))
	kit.cylinder(xf(Vector3(0, 1.5, 0)), 0.98, 0.96, 0.05, 9, Color(0.22, 0.14, 0.09))
	for i in 7:
		var a := i * 0.9
		var at := Vector3(cos(a) * 0.5, 1.5, sin(a) * 0.5)
		kit.cylinder(xf(at), 0.05, 0.04, 1.2 + fmod(i * 0.4, 0.5), 5, STEM)
		kit.sphere(xf(at + Vector3(0, 1.3 + fmod(i * 0.4, 0.5), 0), Vector3.ZERO, Vector3.ONE * 0.28), [Color(0.96, 0.24, 0.3), Color(1.0, 0.82, 0.2), Color(0.8, 0.3, 0.86)][i % 3], 3, 6)

static func _t_chair(kit: BeeMeshKit) -> void:
	var white := Color(0.62, 0.6, 0.56) # Mejora de claridad: un mueble blanco grande distraía del combate.
	for at in [Vector3(-1.2, 1.6, -1.2), Vector3(1.2, 1.6, -1.2), Vector3(-1.2, 1.6, 1.2), Vector3(1.2, 1.6, 1.2)]:
		kit.box(xf(at, Vector3.ZERO, Vector3(0.22, 3.2, 0.22)), white)
	kit.box(xf(Vector3(0, 3.28, 0), Vector3.ZERO, Vector3(2.9, 0.2, 2.9)), white)
	kit.box(xf(Vector3(0, 5.0, -1.34), Vector3(-6, 0, 0), Vector3(2.9, 3.2, 0.18)), Color(0.56, 0.54, 0.5))

static func _t_table(kit: BeeMeshKit) -> void:
	kit.cylinder(xf(Vector3.ZERO), 1.3, 0.5, 0.4, 10, Color(0.26, 0.3, 0.32))
	kit.cylinder(xf(Vector3(0, 0.4, 0)), 0.3, 0.26, 7.6, 8, Color(0.34, 0.38, 0.4))
	kit.cylinder(xf(Vector3(0, 8.0, 0)), 4.6, 4.6, 0.3, 14, Color(0.84, 0.82, 0.76))

static func _t_lantern(kit: BeeMeshKit) -> void:
	kit.cylinder(xf(Vector3.ZERO), 0.26, 0.1, 3.6, 6, Color(0.1, 0.1, 0.12))
	kit.box(xf(Vector3(0, 4.1, 0), Vector3.ZERO, Vector3(0.62, 0.9, 0.62)), Color(1.0, 0.86, 0.46))
	kit.cylinder(xf(Vector3(0, 4.55, 0)), 0.56, 0.08, 0.42, 6, Color(0.1, 0.1, 0.12))

static func _t_clothesline(kit: BeeMeshKit) -> void:
	kit.box(xf(Vector3(-11, 5, 0), Vector3.ZERO, Vector3(0.2, 10, 0.2)), Color(0.5, 0.5, 0.52))
	kit.box(xf(Vector3(11, 5, 0), Vector3.ZERO, Vector3(0.2, 10, 0.2)), Color(0.5, 0.5, 0.52))
	kit.box(xf(Vector3(0, 9.6, 0), Vector3.ZERO, Vector3(22, 0.05, 0.05)), Color(0.92, 0.92, 0.88))
	var colors := [Color(0.92, 0.32, 0.36), Color(0.94, 0.94, 0.92), Color(0.3, 0.54, 0.86), Color(0.98, 0.8, 0.26), Color(0.5, 0.78, 0.5)]
	for i in 7:
		var col: Color = colors[i % colors.size()]
		var w := 1.9 + fmod(i * 0.7, 1.0)
		kit.sheet(xf(Vector3(-9 + i * 3.0, 8.2 - fmod(i * 0.5, 0.5), 0.0), Vector3(0, 0, sin(i * 1.2) * 3.0), Vector3(w, 2.8, 1.0)), col, Color(col.r * 0.72, col.g * 0.72, col.b * 0.72))

static func _t_bbq(kit: BeeMeshKit) -> void:
	kit.sphere(xf(Vector3(0, 4.5, 0), Vector3.ZERO, Vector3(2.0, 1.5, 2.0)), Color(0.14, 0.14, 0.16), 4, 11, Color(0.08, 0.08, 0.1))
	kit.cylinder(xf(Vector3(0, 4.5, 0)), 2.05, 2.05, 0.1, 12, Color(0.42, 0.44, 0.46))
	for at in [Vector3(-1.2, 0, 0.9), Vector3(1.2, 0, 0.9), Vector3(0, 0, -1.4)]:
		kit.cylinder(xf(at, Vector3(0, 0, -at.x * 6.0)), 0.1, 0.1, 3.9, 5, Color(0.2, 0.2, 0.22))

static func _t_house_wall(kit: BeeMeshKit) -> void:
	kit.box(xf(Vector3(0, 8, 0), Vector3.ZERO, Vector3(26, 16, 1)), Color(0.82, 0.74, 0.62))
	kit.box(xf(Vector3(0, 0.5, 0.2), Vector3.ZERO, Vector3(26, 1.0, 1.1)), Color(0.46, 0.4, 0.38))
	for at in [Vector3(-7, 8.5, 0.5), Vector3(7, 8.5, 0.5)]:
		kit.box(xf(at, Vector3.ZERO, Vector3(5.2, 6.4, 0.2)), Color(0.9, 0.9, 0.86))
		kit.box(xf(at + Vector3(0, 0, 0.08), Vector3.ZERO, Vector3(4.6, 5.8, 0.1)), Color(1.0, 0.84, 0.46))
		kit.box(xf(at + Vector3(0, 0, 0.16), Vector3.ZERO, Vector3(0.18, 5.8, 0.08)), Color(0.9, 0.9, 0.86))
		kit.box(xf(at + Vector3(0, 0, 0.16), Vector3.ZERO, Vector3(4.6, 0.18, 0.08)), Color(0.9, 0.9, 0.86))
	kit.box(xf(Vector3(0, 16.5, -2), Vector3(-30, 0, 0), Vector3(28, 0.5, 8)), Color(0.5, 0.26, 0.22))

static func _t_soda_can(kit: BeeMeshKit) -> void:
	# Lata aplastada de costado: se ve la abolladura.
	kit.cylinder(xf(Vector3(-0.9, 0.56, 0), Vector3(0, 0, -90)), 0.56, 0.5, 0.8, 11, Color(0.14, 0.5, 0.9), Color(0.76, 0.78, 0.8))
	kit.cylinder(xf(Vector3(-0.1, 0.5, 0), Vector3(14, 0, -90)), 0.46, 0.36, 0.5, 11, Color(0.92, 0.94, 0.96))
	kit.cylinder(xf(Vector3(0.4, 0.46, 0), Vector3(-10, 0, -86)), 0.38, 0.5, 0.6, 11, Color(0.14, 0.5, 0.9), Color(0.72, 0.74, 0.78))
	kit.box(xf(Vector3(-0.56, 0.56, 0.5), Vector3(0, 0, 0), Vector3(0.5, 0.42, 0.1)), Color(1.0, 0.86, 0.2))

static func _t_lollipop(kit: BeeMeshKit) -> void:
	kit.cylinder(xf(Vector3.ZERO, Vector3(0, 0, 8)), 0.07, 0.06, 3.0, 6, Color(0.96, 0.94, 0.88))
	var top := xf(Vector3.ZERO, Vector3(0, 0, 8)) * Vector3(0, 3.0, 0)
	kit.sphere(xf(top, Vector3(90, 0, 0), Vector3(0.82, 0.22, 0.82)), Color(0.98, 0.32, 0.56), 3, 13, Color(0.8, 0.14, 0.4))
	for i in 3:
		kit.cylinder(xf(top + Vector3(0, 0, 0.2), Vector3(90, 0, 0)), 0.62 - i * 0.2, 0.62 - i * 0.2, 0.05, 13, [Color(1, 0.96, 0.92), Color(0.98, 0.32, 0.56), Color(1, 0.96, 0.92)][i])

static func _t_candy(kit: BeeMeshKit) -> void:
	kit.sphere(xf(Vector3(0, 0.3, 0), Vector3.ZERO, Vector3(0.74, 0.32, 0.4)), Color(0.98, 0.3, 0.2), 3, 9, Color(0.76, 0.16, 0.12))
	for i in 3:
		kit.box(xf(Vector3(-0.42 + i * 0.42, 0.42, 0.26), Vector3(0, 0, 26), Vector3(0.14, 0.42, 0.06)), Color(1, 0.96, 0.84))
	for side in [-1.0, 1.0]:
		kit.cylinder(xf(Vector3(side * 0.66, 0.3, 0), Vector3(0, 0, side * -90.0)), 0.06, 0.32, 0.56, 7, Color(1.0, 0.82, 0.24))

static func _t_wrapper(kit: BeeMeshKit) -> void:
	kit.sheet(xf(Vector3(0, 0.1, 0), Vector3(-84, 12, 0), Vector3(1.9, 1.0, 1)), Color(0.72, 0.34, 0.9), Color(0.92, 0.82, 0.3))
	kit.sheet(xf(Vector3(0.4, 0.24, 0.1), Vector3(-58, 40, 12), Vector3(0.9, 0.7, 1)), Color(0.94, 0.42, 0.64), Color(0.72, 0.34, 0.9))

static func _t_popsicle(kit: BeeMeshKit) -> void:
	kit.box(xf(Vector3(0, 0.05, 0), Vector3(0, 28, 0), Vector3(2.4, 0.07, 0.4)), Color(0.9, 0.78, 0.56))

static func _t_bottle_cap(kit: BeeMeshKit) -> void:
	kit.cylinder(xf(Vector3.ZERO), 0.42, 0.38, 0.14, 12, Color(0.94, 0.72, 0.18), Color(0.98, 0.24, 0.22))

static func _t_hill(kit: BeeMeshKit) -> void:
	kit.sphere(xf(Vector3.ZERO, Vector3.ZERO, Vector3(26, 13, 12)), Color(0.42, 0.6, 0.36), 4, 11, Color(0.34, 0.48, 0.3), true)

static func _t_poplar(kit: BeeMeshKit) -> void:
	kit.cylinder(xf(Vector3.ZERO), 0.5, 0.36, 5.0, 6, Color(0.26, 0.2, 0.16))
	kit.sphere(xf(Vector3(0, 11, 0), Vector3.ZERO, Vector3(3.0, 10.0, 3.0)), Color(0.3, 0.54, 0.3), 4, 8, Color(0.18, 0.36, 0.22))

static func _t_round_tree(kit: BeeMeshKit) -> void:
	kit.cylinder(xf(Vector3.ZERO), 1.0, 0.7, 7.0, 7, Color(0.28, 0.2, 0.16))
	for i in 5:
		var a := i * 1.26
		kit.sphere(xf(Vector3(cos(a) * 4.0, 9.5 + sin(a * 1.7) * 1.5, sin(a) * 2.0), Vector3.ZERO, Vector3(5.0, 4.4, 4.0)), Color(0.36, 0.62, 0.3), 3, 8, Color(0.2, 0.4, 0.22))
	kit.sphere(xf(Vector3(0, 12.0, 0), Vector3.ZERO, Vector3(5.6, 4.8, 4.6)), Color(0.42, 0.68, 0.32), 3, 8, Color(0.24, 0.46, 0.24))

static func _t_hedge(kit: BeeMeshKit) -> void:
	kit.box(xf(Vector3(0, 4.5, 0), Vector3.ZERO, Vector3(14.6, 9.0, 3.0)), Color(0.2, 0.44, 0.3))
	for i in 11:
		kit.sphere(xf(Vector3(-6.6 + i * 1.32, 2.0 + fmod(i * 2.3, 6.6), 1.5), Vector3.ZERO, Vector3(1.3, 1.1, 0.5)), Color(0.28, 0.54, 0.34), 2, 6)

static func _t_roof_house(kit: BeeMeshKit) -> void:
	kit.box(xf(Vector3(0, 6, 0), Vector3.ZERO, Vector3(20, 12, 10)), Color(0.8, 0.72, 0.62))
	kit.box(xf(Vector3(0, 15, 2.6), Vector3(-40, 0, 0), Vector3(22, 0.4, 8.4)), Color(0.56, 0.3, 0.26))
	kit.box(xf(Vector3(0, 15, -2.6), Vector3(40, 0, 0), Vector3(22, 0.4, 8.4)), Color(0.46, 0.24, 0.22))
	for x_at in [-6.0, 0.0, 6.0]:
		kit.box(xf(Vector3(x_at, 7.5, 5.05), Vector3.ZERO, Vector3(2.8, 3.8, 0.1)), Color(1.0, 0.86, 0.5))
