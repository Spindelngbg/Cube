class_name NavigationArrowUI
extends Control

var _arrow: Control
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 25
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -80.0
	offset_right = 80.0
	offset_top = -88.0
	offset_bottom = -24.0

	_arrow = Control.new()
	_arrow.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_arrow.offset_left = -24.0
	_arrow.offset_right = 24.0
	_arrow.offset_top = 0.0
	_arrow.offset_bottom = 48.0
	_arrow.draw.connect(_draw_arrow)
	add_child(_arrow)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_label.offset_left = -80.0
	_label.offset_right = 80.0
	_label.offset_top = -20.0
	_label.offset_bottom = 0.0
	SpiderTheme.style_subtitle(_label)
	add_child(_label)

	visible = false
	var znood := RuntimeGlobals.znood()
	if znood:
		znood.waypoint_changed.connect(_on_waypoint_changed)


func _process(_delta: float) -> void:
	var znood := RuntimeGlobals.znood()
	if not visible or znood == null or not znood.has_waypoint:
		return
	var game := get_tree().get_first_node_in_group("game_director")
	if game == null or not game.has_method("get_local_player"):
		return
	var player: Node3D = game.get_local_player()
	if player == null:
		return

	var to_target: Vector3 = znood.waypoint - player.global_position
	to_target.y = 0.0
	var distance: float = to_target.length()
	if distance < 3.0:
		_label.text = "Du är framme"
		_arrow.rotation = 0.0
		_arrow.queue_redraw()
		return

	var target_yaw := atan2(to_target.x, to_target.z)
	var player_yaw := 0.0
	if player.has_method("get_facing_yaw"):
		player_yaw = float(player.get_facing_yaw())
	elif player is Node3D:
		player_yaw = (player as Node3D).rotation.y

	_arrow.rotation = target_yaw - player_yaw
	_arrow.queue_redraw()
	_label.text = "%d m till vägpunkt" % int(round(distance))


func _on_waypoint_changed(active: bool, _position: Vector3) -> void:
	visible = active


func _draw_arrow() -> void:
	var center := _arrow.size * 0.5
	var tip := center + Vector2(0, -16)
	var left := center + Vector2(-12, 10)
	var right := center + Vector2(12, 10)
	_arrow.draw_colored_polygon(
		PackedVector2Array([tip, left, right]),
		Color(0.55, 0.9, 1.0, 0.95)
	)
	_arrow.draw_polyline(
		PackedVector2Array([tip, left, right, tip]),
		Color(0.2, 0.45, 0.65, 0.9),
		2.0,
		true
	)