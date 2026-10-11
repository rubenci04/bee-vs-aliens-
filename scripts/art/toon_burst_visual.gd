class_name BeeToonBurstVisual
extends Node3D
## Reusable presentation burst. No damage, physics or bloom dependency.
signal finished
@export var alien := true
@export_range(.1, 3.0) var duration := .55
@export var autoplay := true
@export var free_when_finished := true
var elapsed := 0.0
var playing := false
var core: MeshInstance3D
var ring: MeshInstance3D
var sparks: Array[MeshInstance3D] = []

func _ready() -> void:
	var primary := Color("1bc7d9") if alien else Color("efab26")
	var secondary := Color("9558ce") if alien else Color("ffe49b")
	core = piece("Core", sphere(), primary)
	ring = MeshInstance3D.new()
	ring.name = "ShockRing"
	var torus := TorusMesh.new()
	torus.inner_radius = .89
	torus.outer_radius = 1.0
	torus.rings = 32
	torus.ring_segments = 8
	ring.mesh = torus
	ring.rotation.x = PI/2
	add_child(ring)
	style(ring,primary)
	for i in 10:
		sparks.append(piece("Spark%d"%i,sphere(),secondary if i%3==0 else primary))
	visible = false
	if autoplay:
		play()

func sphere() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 12
	mesh.rings = 6
	return mesh

func piece(label: String, mesh: Mesh, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	add_child(node)
	style(node,color)
	return node

func style(node: MeshInstance3D, color: Color) -> void:
	var source := StandardMaterial3D.new()
	source.albedo_color = color
	source.roughness = .95
	if alien:
		source.emission_enabled = true
		source.emission = color
		source.emission_energy_multiplier = .65
	node.set_surface_override_material(0,source)
	BeeToonStyle.apply(node,true,.0012)
	var own := (node.get_surface_override_material(0) as ShaderMaterial).duplicate() as ShaderMaterial
	own.set_shader_parameter("emission_energy",.65 if alien else 0.0)
	node.set_surface_override_material(0,own)

func play() -> void:
	elapsed = 0.0
	playing = true
	visible = true
	seek(0.0)

## Deterministic seeking also supports effect previews and scrubbing.
func seek(seconds: float) -> void:
	elapsed = clampf(seconds,0,duration)
	var t := elapsed/duration
	var pop := sin(t*PI)
	core.scale = Vector3.ONE*maxf(.001,.75*pop)
	ring.scale = Vector3.ONE*(.12+1.5*t)
	ring.visible = t>.04 and t<.82
	for i in sparks.size():
		var a := TAU*i/sparks.size()+.15
		var direction := Vector3(cos(a),sin(a),0)
		sparks[i].position = direction*(.15+1.7*t)
		sparks[i].scale = Vector3(.09,.20,.07)*maxf(.001,1-t)
		sparks[i].rotation.z = a-PI/2
	visible = t<1.0

func _process(delta: float) -> void:
	if not playing:
		return
	seek(elapsed+delta)
	if elapsed>=duration:
		playing = false
		finished.emit()
		if free_when_finished:
			queue_free()
