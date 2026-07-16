class_name MinimapPanel
extends PanelContainer

var _world_size := 30.0
var _spawn_id := ""
var _players: Dictionary = {}
var _monsters: Array[Node3D] = []
var _local_peer_id := 0
var _canvas: Control
var _map_input_enabled := false


func _ready() -> void:
	SpiderTheme.apply_to(self)
	custom_minimum_size = Vector2(188, 188)

	_canvas = Control.new()
	_canvas.name = "MapCanvas"
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_canvas)
	_canvas.draw.connect(_on_canvas_draw)
	_canvas.gui_input.connect(_on_canvas_input)

	var znood := RuntimeGlobals.znood()
	if znood:
		znood.map_picker_changed.connect(_on_map_picker_changed)
		znood.waypoint_changed.connect(func(_a, _b) -> void: _canvas.queue_redraw())
		znood.backup_pings_changed.connect(func() -> void: _canvas.queue_redraw())
		znood.search_results_changed.connect(func(_r) -> void: _canvas.queue_redraw())


func setup(spawn_id: String, world_size: float = SpawnPoints.get_extent_m()) -> void:
	_spawn_id = SpawnPoints.normalize_id(spawn_id)
	_world_size = maxf(world_size, 1.0)
	_canvas.queue_redraw()


func update_players(players: Dictionary, local_peer_id: int, monsters: Array = []) -> void:
	_players = players
	_local_peer_id = local_peer_id
	_monsters.clear()
	for entry in monsters:
		if entry is Node3D and is_instance_valid(entry):
			_monsters.append(entry)
	_canvas.queue_redraw()


func _on_map_picker_changed(active: bool) -> void:
	_map_input_enabled = active
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE
	_canvas.queue_redraw()


func _on_canvas_draw() -> void:
	var inner := WorldMapDrawer.inner_rect(_canvas.get_rect())
	var znood := RuntimeGlobals.znood()
	WorldMapDrawer.draw(
		_canvas,
		inner,
		_spawn_id,
		_players,
		_local_peer_id,
		_monsters,
		znood.get_visible_pois() if znood else [],
		znood.waypoint if znood else Vector3.ZERO,
		znood.has_waypoint if znood else false,
		znood.get_backup_pings_for_local() if znood else [],
		znood.get_blink_alpha() if znood else 1.0
	)
	if _map_input_enabled:
		_canvas.draw_string(
			ThemeDB.fallback_font,
			inner.position + Vector2(inner.size.x * 0.5 - 48, inner.position.y + 18),
			"Klicka vägpunkt",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			10,
			Color(0.55, 0.9, 1.0, 0.85)
		)


func _on_canvas_input(event: InputEvent) -> void:
	if not _map_input_enabled:
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			var world_pos := WorldMapDrawer.map_click_to_world(
				mouse.position,
				_canvas.get_rect(),
				_spawn_id,
				_players,
				_local_peer_id
			)
			if world_pos != Vector3.ZERO:
				var znood := RuntimeGlobals.znood()
				if znood:
					znood.set_waypoint(world_pos)
				accept_event()