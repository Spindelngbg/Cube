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

	for i in 40:
		var t := float(i) / 39.0
		var col := SpiderTheme.BG_TOP.lerp(SpiderTheme.BG_BOTTOM, t)
		draw_rect(Rect2(0, t * h, w, h / 39.0 + 1), col)

	var pulse := 0.04 + sin(_time * 0.5) * 0.015
	draw_circle(Vector2(w * 0.5, h * 0.35), min(w, h) * 0.38, Color(SpiderTheme.BLOOD.r, SpiderTheme.BLOOD.g, SpiderTheme.BLOOD.b, pulse))

	_draw_web(Vector2(w * 0.12, h * 0.1), min(w, h) * 0.22, 10, 5)
	_draw_web(Vector2(w * 0.88, h * 0.08), min(w, h) * 0.18, 9, 4)
	_draw_web(Vector2(w * 0.5, h * 0.02), min(w, h) * 0.28, 12, 6)
	_draw_web(Vector2(w * 0.08, h * 0.88), min(w, h) * 0.16, 8, 4)
	_draw_web(Vector2(w * 0.92, h * 0.9), min(w, h) * 0.2, 9, 5)

	var silk := SpiderTheme.WEB
	for i in 3:
		var y := h * (0.2 + i * 0.22) + sin(_time * 0.3 + i) * 3.0
		draw_line(Vector2(0, y), Vector2(w, y + sin(_time + i) * 8.0), Color(silk.r, silk.g, silk.b, 0.04), 1.0)


func _draw_web(origin: Vector2, radius: float, strands: int, rings: int) -> void:
	var web_col := SpiderTheme.WEB
	var sway := sin(_time * 0.4) * 0.02
	for s in strands:
		var angle := TAU * float(s) / float(strands) + sway
		var end := origin + Vector2(cos(angle), sin(angle)) * radius
		draw_line(origin, end, web_col, 1.0)
	for r in range(1, rings + 1):
		var rr := radius * float(r) / float(rings)
		var points: PackedVector2Array = []
		for s in range(strands + 1):
			var angle := TAU * float(s) / float(strands) + sway
			points.append(origin + Vector2(cos(angle), sin(angle)) * rr)
		draw_polyline(points, web_col, 1.0)