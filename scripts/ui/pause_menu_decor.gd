extends Control

## Diamanter i hörnen + glimrande spindelnät runt pauspanelen.

const GEM_OUTER := Color(0.55, 0.92, 1.0, 0.95)
const GEM_MID := Color(0.77, 0.12, 0.22, 0.88)
const GEM_CORE := Color(0.98, 0.96, 1.0, 1.0)
const WEB := Color(0.82, 0.8, 0.88, 0.14)

var _time := 0.0
var _inset := 14.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = -_inset
	offset_top = -_inset
	offset_right = _inset
	offset_bottom = _inset
	z_index = 4


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if size.x < 24.0 or size.y < 24.0:
		return
	var pulse := 0.82 + sin(_time * 2.4) * 0.18
	var corners := [
		Vector2(_inset, _inset),
		Vector2(size.x - _inset, _inset),
		Vector2(_inset, size.y - _inset),
		Vector2(size.x - _inset, size.y - _inset),
	]
	for corner in corners:
		_draw_gem(corner, pulse)
	_draw_corner_webs(corners)
	_draw_mini_spiders()


func _draw_gem(center: Vector2, pulse: float) -> void:
	var outer := 11.0 * pulse
	var mid := 7.5 * pulse
	var core := 3.2 * pulse
	var points := PackedVector2Array([
		center + Vector2(0.0, -outer),
		center + Vector2(outer * 0.72, 0.0),
		center + Vector2(0.0, outer),
		center + Vector2(-outer * 0.72, 0.0),
	])
	draw_colored_polygon(points, GEM_OUTER)
	var mid_pts := PackedVector2Array([
		center + Vector2(0.0, -mid),
		center + Vector2(mid * 0.7, 0.0),
		center + Vector2(0.0, mid),
		center + Vector2(-mid * 0.7, 0.0),
	])
	draw_colored_polygon(mid_pts, GEM_MID)
	draw_circle(center + Vector2(-1.5, -2.0), core, GEM_CORE)
	draw_circle(center + Vector2(2.0, 1.5), core * 0.45, Color(1.0, 1.0, 1.0, 0.55))


func _draw_corner_webs(corners: Array) -> void:
	for corner in corners:
		var radius := 28.0 + sin(_time * 0.7 + corner.x * 0.01) * 2.0
		for strand in 5:
			var angle := TAU * float(strand) / 5.0 + _time * 0.08
			var end := corner + Vector2(cos(angle), sin(angle)) * radius
			draw_line(corner, end, WEB, 1.0)
		for ring in range(1, 3):
			var rr := radius * float(ring) / 3.0
			var arc: PackedVector2Array = []
			for step in 6:
				var a := TAU * float(step) / 5.0 + _time * 0.08
				arc.append(corner + Vector2(cos(a), sin(a)) * rr)
			draw_polyline(arc, WEB, 1.0)


func _draw_mini_spiders() -> void:
	var top := Vector2(size.x * 0.5, _inset + 6.0)
	var sway := sin(_time * 1.6) * 4.0
	_draw_spider_glyph(top + Vector2(sway, 0.0), 0.9)
	_draw_spider_glyph(Vector2(_inset + 36.0, size.y * 0.5), 0.7, -0.4)
	_draw_spider_glyph(Vector2(size.x - _inset - 36.0, size.y * 0.5), 0.7, 0.4)


func _draw_spider_glyph(pos: Vector2, scale: float, facing: float = 0.0) -> void:
	draw_set_transform(pos, facing, Vector2(scale, scale))
	var body := Color(0.07, 0.06, 0.08, 0.92)
	var eye := SpiderTheme.BLOOD_BRIGHT
	draw_circle(Vector2(0.0, 5.0), 6.0, body)
	draw_circle(Vector2(0.0, -2.0), 4.5, Color(0.16, 0.12, 0.14))
	for i in 4:
		var side := -1.0 if i % 2 == 0 else 1.0
		var base := side * (0.5 + (i >> 1) * 0.22)
		var start := Vector2(3.5 * side, float(i >> 1) * 0.8 - 1.0)
		var tip := start + Vector2(cos(base), sin(base)) * 14.0
		draw_line(start, tip, Color(0.12, 0.1, 0.12, 0.9), 1.2)
	for i in 4:
		var offset := Vector2(cos(TAU * float(i) / 4.0) * 3.0, -3.0 + sin(TAU * float(i) / 4.0) * 1.5)
		draw_circle(offset, 1.4, eye)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)