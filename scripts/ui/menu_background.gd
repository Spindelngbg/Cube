extends Control

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var h := size.y
	var w := size.x
	for i in 32:
		var t := float(i) / 31.0
		var col := LuxuryTheme.BG_TOP.lerp(LuxuryTheme.BG_BOTTOM, t)
		draw_rect(Rect2(0, t * h, w, h / 31.0 + 1), col)

	# Subtle gold vignette glow
	var center := Vector2(w * 0.5, h * 0.38)
	var pulse := 0.03 + sin(_time * 0.6) * 0.01
	draw_circle(center, min(w, h) * 0.42, Color(LuxuryTheme.GOLD.r, LuxuryTheme.GOLD.g, LuxuryTheme.GOLD.b, pulse))

	# Fine grid shimmer
	var grid_col := Color(1, 1, 1, 0.015)
	for x in range(0, int(w), 48):
		draw_line(Vector2(x, 0), Vector2(x, h), grid_col, 1.0)
	for y in range(0, int(h), 48):
		draw_line(Vector2(0, y), Vector2(w, y), grid_col, 1.0)