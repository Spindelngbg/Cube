extends Control

@export var thread_length := 160.0
@export var pivot_normalized := Vector2(0.72, 0.0)

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pivot := Vector2(size.x * pivot_normalized.x, size.y * pivot_normalized.y)
	var swing := sin(_time * 1.2) * 0.16 + sin(_time * 2.0 + 0.8) * 0.06
	var wobble := sin(_time * 3.0) * 3.0
	var end := pivot + Vector2(sin(swing) * thread_length, cos(swing) * thread_length)
	end.x += wobble

	draw_line(pivot, end, Color(0.75, 0.75, 0.82, 0.25), 1.0)
	draw_line(pivot, end, Color(1, 1, 1, 0.06), 0.5)
	_draw_spider(end, swing)


func _draw_spider(pos: Vector2, angle: float) -> void:
	var body := Color(0.08, 0.07, 0.09)
	var shine := Color(0.18, 0.14, 0.16)
	var eye := SpiderTheme.BLOOD_BRIGHT
	var leg := Color(0.14, 0.12, 0.14, 0.95)

	draw_set_transform(pos, angle * 0.35, Vector2.ONE)

	# Abdomen
	draw_circle(Vector2(0, 12), 11.0, body)
	draw_circle(Vector2(0, 12), 11.0, Color(shine.r, shine.g, shine.b, 0.2))

	# Thorax
	draw_circle(Vector2(0, -1), 8.0, shine)

	# Eyes – many glowing red
	for i in 6:
		var a := TAU * float(i) / 6.0
		var offset := Vector2(cos(a) * 5.5, -5 + sin(a) * 2.5)
		draw_circle(offset, 2.2, eye)
		draw_circle(offset, 0.8, Color(0.02, 0.02, 0.02))

	# Fangs
	for side in [-1, 1]:
		draw_line(Vector2(3 * side, -2), Vector2(6 * side, 6), Color(SpiderTheme.BLOOD.r, SpiderTheme.BLOOD.g, SpiderTheme.BLOOD.b, 0.9), 2.0)

	# Legs
	for i in 8:
		var side := -1.0 if i % 2 == 0 else 1.0
		var base_angle := side * (0.55 + (i >> 1) * 0.18) + angle * 0.4
		var start := Vector2(5 * side, float(i >> 1) * 1.2 - 2)
		var mid := start + Vector2(cos(base_angle), sin(base_angle)) * 18
		var tip := mid + Vector2(cos(base_angle + side * 0.6), sin(base_angle + side * 0.6)) * 20
		draw_line(start, mid, leg, 1.6)
		draw_line(mid, tip, leg, 1.2)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)