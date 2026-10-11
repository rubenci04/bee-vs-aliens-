@tool
extends Control
## Reusable visual HUD. Connect health_changed to set_health(current, maximum).
## Alien colour is reserved for the external control device's health.
@export_range(0.0, 1.0) var ratio := 1.0:
	set(value):
		ratio = clampf(value, 0.0, 1.0)
		queue_redraw()
@export var alien_device := false:
	set(value):
		alien_device = value
		queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(300, 44)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func set_health(current: float, maximum: float) -> void:
	ratio = current / maximum if maximum > 0.0 else 0.0

func _hex(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 6:
		points.append(center + Vector2(cos(i * TAU / 6.0), sin(i * TAU / 6.0)) * radius)
	return points

func _draw() -> void:
	var h := minf(size.y, 44.0)
	var active := BeeAlienPalette.CYAN if alien_device else Color("edb645")
	var edge := Color("242a30")
	var icon_center := Vector2(h * 0.5, h * 0.5)
	var outer := _hex(icon_center, h * 0.46)
	draw_colored_polygon(outer, edge)
	draw_colored_polygon(_hex(icon_center, h * 0.35), active)
	if alien_device:
		draw_circle(icon_center, h * 0.15, edge)
		draw_circle(icon_center, h * 0.075, BeeAlienPalette.VIOLET)
	else:
		draw_line(icon_center + Vector2(-8, -3), icon_center + Vector2(8, -3), edge, 3.0, true)
		draw_line(icon_center + Vector2(-8, 4), icon_center + Vector2(8, 4), edge, 3.0, true)
	var x := h + 7.0
	var width := maxf(size.x - x - 4.0, 0.0)
	var frame := StyleBoxFlat.new()
	frame.bg_color = edge
	frame.set_corner_radius_all(9)
	draw_style_box(frame, Rect2(x, 7, width, h - 14))
	var gap := 4.0
	var cell_width := maxf((width - 14.0 - gap * 4.0) / 5.0, 0.0)
	for i in 5:
		var rect := Rect2(x + 7 + i * (cell_width + gap), 12, cell_width, h - 24)
		draw_rect(rect, Color("41464a"))
		var fill := clampf(ratio * 5.0 - i, 0.0, 1.0)
		if fill > 0.0:
			var colored := rect
			colored.size.x *= fill
			draw_rect(colored, active)
			draw_line(colored.position + Vector2(0, 1), colored.position + Vector2(colored.size.x, 1), active.lightened(0.3), 2)
