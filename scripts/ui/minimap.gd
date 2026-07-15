class_name MinimapPanel
extends PanelContainer

const MAP_PADDING := 10.0

var _world_size := 30.0
var _spawn_id := ""
var _players: Dictionary = {}
var _local_peer_id := 0
var _canvas: Control


func _ready() -> void:
	SpiderTheme.apply_to(self)
	custom_minimum_size = Vector2(188, 188)

	_canvas = Control.new()
	_canvas.name = "MapCanvas"
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_canvas)
	_canvas.draw.connect(_on_canvas_draw)


func setup(spawn_id: String, world_size: float = SpawnPoints.PROTOTYPE_SIZE_M) -> void:
	_spawn_id = SpawnPoints.normalize_id(spawn_id)
	_world_size = maxf(world_size, 1.0)
	_canvas.queue_redraw()


func update_players(players: Dictionary, local_peer_id: int) -> void:
	_players = players
	_local_peer_id = local_peer_id
	_canvas.queue_redraw()


func _on_canvas_draw() -> void:
	var rect := _canvas.get_rect()
	var inner := Rect2(
		MAP_PADDING,
		MAP_PADDING,
		rect.size.x - MAP_PADDING * 2.0,
		rect.size.y - MAP_PADDING * 2.0
	)
	if inner.size.x <= 4.0 or inner.size.y <= 4.0:
		return

	_canvas.draw_rect(inner, Color(0.05, 0.06, 0.08, 0.92), true)
	_canvas.draw_rect(inner, Color(SpiderTheme.BLOOD.r, SpiderTheme.BLOOD.g, SpiderTheme.BLOOD.b, 0.55), false, 2.0)

	var grid_step := inner.size.x / 6.0
	for i in range(1, 6):
		var x := inner.position.x + grid_step * i
		var y := inner.position.y + grid_step * i
		_canvas.draw_line(Vector2(x, inner.position.y), Vector2(x, inner.end.y), Color(1, 1, 1, 0.05), 1.0)
		_canvas.draw_line(Vector2(inner.position.x, y), Vector2(inner.end.x, y), Color(1, 1, 1, 0.05), 1.0)

	var elevator_pos := _elevator_map_position()
	var elev_px := _world_to_map(elevator_pos, inner)
	_canvas.draw_rect(Rect2(elev_px - Vector2(5, 5), Vector2(10, 10)), Color(0.95, 0.75, 0.2, 0.9), true)
	_canvas.draw_string(
		ThemeDB.fallback_font,
		inner.position + Vector2(4, 14),
		"N",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		11,
		Color(1, 1, 1, 0.35)
	)

	var title := SpawnPoints.get_spawn_name(_spawn_id)
	if title == "":
		title = "Karta"
	_canvas.draw_string(
		ThemeDB.fallback_font,
		inner.position + Vector2(4, inner.size.y - 6),
		title,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color(SpiderTheme.BONE.r, SpiderTheme.BONE.g, SpiderTheme.BONE.b, 0.7)
	)

	for peer_id in _players.keys():
		var player: Node3D = _players[peer_id]
		if player == null or not is_instance_valid(player):
			continue
		var px := _world_to_map(player.global_position, inner)
		var is_local := int(peer_id) == _local_peer_id
		var radius := 4.5 if is_local else 3.5
		var color := SpiderTheme.VENOM if is_local else SpiderTheme.BLOOD_BRIGHT
		_canvas.draw_circle(px, radius + 1.5, Color(0, 0, 0, 0.45))
		_canvas.draw_circle(px, radius, color)


func _elevator_map_position() -> Vector3:
	var entry := SpawnPoints.get_entry(_spawn_id)
	var mount := str(entry.get("elevator_mount", "left"))
	var half := _world_size * 0.5
	match mount:
		"left":
			return Vector3(1.2, 0, half)
		"right":
			return Vector3(_world_size - 1.2, 0, half)
		"top":
			return Vector3(half, 0, 1.2)
		_:
			return Vector3(half, 0, half)


func _world_to_map(world_pos: Vector3, inner: Rect2) -> Vector2:
	var nx := clampf(world_pos.x / _world_size, 0.0, 1.0)
	var nz := clampf(world_pos.z / _world_size, 0.0, 1.0)
	return Vector2(
		inner.position.x + nx * inner.size.x,
		inner.position.y + nz * inner.size.y
	)