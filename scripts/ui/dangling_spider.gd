extends Control

@export var thread_length := 140.0
@export var pivot_normalized := Vector2(0.78, 0.0)

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pivot := Vector2(size.x * pivot_normalized.x, size.y * pivot_normalized.y)
	var swing := sin(_time * 1.35) * 0.14 + sin(_time * 2.1 + 1.2) * 0.05
	var wobble := sin(_time * 3.2) * 2.0
	var end := pivot + Vector2(sin(swing) * thread_length, cos(swing) * thread_length)
	end.x += wobble

	# Silk thread
	draw_line(pivot, end, Color(0.85, 0.85, 0.9, 0.35), 1.0)
	draw_line(pivot, end, Color(1, 1, 1, 0.08), 0.5)

	_draw_spider(end, swing)


func _draw_spider(pos: Vector2, angle: float) -> void:
	var body_col := Color(0.12, 0.12, 0.14)
	var highlight := Color(0.28, 0.26, 0.3)
	var eye_col := Color(0.95, 0.82, 0.35)
	var leg_col := Color(0.2, 0.2, 0.22, 0.9)

	# Abdomen
	draw_set_transform(pos, angle * 0.3, Vector2.ONE)
	draw_circle(Vector2(0, 10), 9.0, body_col)
	draw_circle(Vector2(0, 10), 9.0, Color(highlight.r, highlight.g, highlight.b, 0.25))

	# Cephalothorax
	draw_circle(Vector2(0, -2), 7.0, highlight)

	# Eyes
	draw_circle(Vector2(-2.5, -4), 1.8, eye_col)
	draw_circle(Vector2(2.5, -4), 1.8, eye_col)
	draw_circle(Vector2(-2.5, -4), 0.7, Color(0.05, 0.05, 0.05))
	draw_circle(Vector2(2.5, -4), 0.7, Color(0.05, 0.05, 0.05))

	# Legs
	for i in 8:
		var side := -1.0 if i < 4 else 1.0
		var leg_index := i if i < 4 else i - 4
		var base_angle := side * (0.5 + leg_index * 0.22) + angle * 0.5
		var leg_start := Vector2(side * 4, -1 + leg_index * 1.5)
		var leg_mid := leg_start + Vector2(cos(base_angle), sin(base_angle)) * 14
		var leg_end := leg_mid + Vector2(cos(base_angle + side * 0.5), sin(base_angle + side * 0.5)) * 16
		draw_line(leg_start, leg_mid, leg_col, 1.2)
		draw_line(leg_mid, leg_end, leg_col, 1.0)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)