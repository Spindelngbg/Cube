class_name ZnoodUI
extends PanelContainer

const MENU_THEME := preload("res://addons/settings_menus/resources/default_menu_theme.tres")

enum Page { HOME, SEARCH, GROUPS, MAP }

var _page := Page.HOME
var _content: VBoxContainer
var _title: Label
var _screen: PanelContainer
var _options: OptionsMenuUI
var _map_canvas: Control
var _search_field: LineEdit
var _search_results: VBoxContainer
var _group_list: VBoxContainer
var _status_label: Label

var _players: Dictionary = {}
var _monsters: Array = []
var _local_peer_id := 0


func _znood_mgr() -> ZnoodManagerNode:
	return RuntimeGlobals.znood()


func _ready() -> void:
	visible = false
	z_index = 40
	_build()
	SpiderTheme.apply_to(self)
	var znood := _znood_mgr()
	if znood:
		znood.device_open_changed.connect(_on_device_open_changed)
		znood.search_results_changed.connect(_refresh_search_results)
		znood.backup_pings_changed.connect(_queue_map_redraw)


func bind_world_context(players: Dictionary, local_peer_id: int, monsters: Array = []) -> void:
	_players = players
	_local_peer_id = local_peer_id
	_monsters = monsters
	_queue_map_redraw()


func update_world_context(players: Dictionary, monsters: Array = []) -> void:
	_players = players
	_monsters = monsters
	_queue_map_redraw()


func toggle() -> void:
	_znood_mgr().toggle_device()


func _on_device_open_changed(open: bool) -> void:
	visible = open
	if open:
		_show_page(Page.HOME)
		MouseLook.deactivate()
	else:
		if _options and _options.visible:
			_close_settings()
		_restore_mouse_look()


func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -190.0
	offset_right = 190.0
	offset_top = -430.0
	offset_bottom = -36.0
	custom_minimum_size = Vector2(380, 394)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	add_child(outer)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	outer.add_child(header)

	_title = Label.new()
	_title.text = "Znood OS"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SpiderTheme.style_title(_title, 20)
	header.add_child(_title)

	var close_btn := Button.new()
	close_btn.text = "Stäng [Z]"
	close_btn.pressed.connect(func() -> void: _znood_mgr().set_device_open(false))
	header.add_child(close_btn)

	_screen = PanelContainer.new()
	_screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var screen_style := StyleBoxFlat.new()
	screen_style.bg_color = Color(0.03, 0.07, 0.05, 0.96)
	screen_style.border_color = Color(0.35, 0.9, 0.45, 0.55)
	screen_style.set_border_width_all(2)
	screen_style.set_corner_radius_all(6)
	_screen.add_theme_stylebox_override("panel", screen_style)
	outer.add_child(_screen)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 8)
	_screen.add_child(_content)

	_status_label = Label.new()
	SpiderTheme.style_status(_status_label)
	outer.add_child(_status_label)


func _show_page(page: Page) -> void:
	_page = page
	_clear_content()
	match page:
		Page.HOME:
			_title.text = "Znood OS"
			_build_home_page()
		Page.SEARCH:
			_title.text = "Sök platser"
			_build_search_page()
		Page.GROUPS:
			_title.text = "Grupperingar"
			_build_groups_page()
		Page.MAP:
			_title.text = "Karta"
			_build_map_page()
	_update_status()


func _build_home_page() -> void:
	_add_hint("Personlig kolonist-terminal i vänster hand.")
	_add_button("Inställningar", _open_settings)
	_add_button("Chatt", _open_chat)
	_add_button("Ringa Zezzlor", _call_zezzlor)
	_add_button("Ringa Backup", _call_backup)
	_add_button("Sök platser", func() -> void: _show_page(Page.SEARCH))
	_add_button("Karta & vägpunkt", func() -> void: _show_page(Page.MAP))
	_add_button("Tillbaka", func() -> void: _znood_mgr().set_device_open(false))


func _build_search_page() -> void:
	_add_hint("Sök t.ex. vapenbutik, pharmacy, medicin.")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_content.add_child(row)

	_search_field = LineEdit.new()
	_search_field.placeholder_text = "vapenbutik..."
	_search_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_field.text_submitted.connect(_run_search)
	row.add_child(_search_field)

	var search_btn := Button.new()
	search_btn.text = "Sök"
	search_btn.pressed.connect(func() -> void: _run_search(_search_field.text))
	row.add_child(search_btn)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 180)
	_content.add_child(scroll)

	_search_results = VBoxContainer.new()
	_search_results.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_search_results)

	_add_button("Tillbaka", func() -> void: _show_page(Page.HOME))
	_refresh_search_results(_znood_mgr().get_search_results())


func _build_groups_page() -> void:
	_add_hint("Gå med i grupperingar för att se varandras backup på kartan.")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 210)
	_content.add_child(scroll)

	_group_list = VBoxContainer.new()
	_group_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_group_list)

	for group_id in ZnoodGroupCatalog.all_ids():
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 2)
		_group_list.add_child(card)

		var toggle := CheckButton.new()
		toggle.text = ZnoodGroupCatalog.get_name(group_id)
		toggle.button_pressed = _znood_mgr().has_joined_group(group_id)
		toggle.toggled.connect(_on_group_toggled.bind(group_id))
		card.add_child(toggle)

		var desc := Label.new()
		desc.text = ZnoodGroupCatalog.get_description(group_id)
		SpiderTheme.style_subtitle(desc)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(desc)

	_add_button("Tillbaka", func() -> void: _show_page(Page.HOME))


func _build_map_page() -> void:
	_add_hint("Klicka på kartan för vägpunkt. Blå markör + pil visar vägen.")
	_map_canvas = Control.new()
	_map_canvas.custom_minimum_size = Vector2(340, 220)
	_map_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_map_canvas.draw.connect(_on_map_draw)
	_map_canvas.gui_input.connect(_on_map_input)
	_content.add_child(_map_canvas)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_content.add_child(row)

	var clear_btn := Button.new()
	clear_btn.text = "Rensa vägpunkt"
	clear_btn.pressed.connect(func() -> void: _znood_mgr().clear_waypoint())
	row.add_child(clear_btn)

	var picker_btn := Button.new()
	picker_btn.text = "Välj på minimap"
	picker_btn.pressed.connect(_toggle_minimap_picker)
	row.add_child(picker_btn)

	_add_button("Tillbaka", func() -> void: _show_page(Page.HOME))
	_queue_map_redraw()


func _add_hint(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SpiderTheme.style_subtitle(label)
	_content.add_child(label)


func _add_button(text: String, cb: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(cb)
	_content.add_child(button)


func _clear_content() -> void:
	for child in _content.get_children():
		child.queue_free()
	_map_canvas = null
	_search_field = null
	_search_results = null
	_group_list = null


func _run_search(query: String) -> void:
	_znood_mgr().search(query)
	_update_status()


func _refresh_search_results(results: Array) -> void:
	if _search_results == null:
		return
	for child in _search_results.get_children():
		child.queue_free()
	if results.is_empty():
		var empty := Label.new()
		empty.text = "Inga träffar."
		SpiderTheme.style_subtitle(empty)
		_search_results.add_child(empty)
		return

	for poi in results:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_search_results.add_child(row)

		var info := Label.new()
		info.text = str(poi.get("name", "Plats"))
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var mark_btn := Button.new()
		mark_btn.text = "Visa"
		mark_btn.pressed.connect(_focus_poi.bind(poi))
		row.add_child(mark_btn)


func _focus_poi(poi: Dictionary) -> void:
	var pos: Vector3 = poi.get("world_position", Vector3.ZERO)
	_znood_mgr().set_waypoint(pos)
	_show_page(Page.MAP)
	_status_label.text = "Markerar %s på kartan." % str(poi.get("name", "plats"))


func _on_group_toggled(group_id: String, pressed: bool) -> void:
	if pressed != _znood_mgr().has_joined_group(group_id):
		_znood_mgr().toggle_group(group_id)
	_update_status()


func _toggle_minimap_picker() -> void:
	_znood_mgr().set_map_picker_active(not _znood_mgr().map_picker_active)
	_update_status()


func _on_map_draw() -> void:
	if _map_canvas == null:
		return
	var inner := WorldMapDrawer.inner_rect(_map_canvas.get_rect())
	WorldMapDrawer.draw(
		_map_canvas,
		inner,
		_znood_mgr().spawn_id,
		_players,
		_local_peer_id,
		_monsters,
		_znood_mgr().get_visible_pois(),
		_znood_mgr().waypoint,
		_znood_mgr().has_waypoint,
		_znood_mgr().get_backup_pings_for_local(),
		_znood_mgr().get_blink_alpha()
	)


func _on_map_input(event: InputEvent) -> void:
	if _map_canvas == null:
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			var world_pos := WorldMapDrawer.map_click_to_world(
				mouse.position,
				_map_canvas.get_rect(),
				_znood_mgr().spawn_id,
				_players,
				_local_peer_id
			)
			if world_pos != Vector3.ZERO:
				_znood_mgr().set_waypoint(world_pos)
				_queue_map_redraw()
				_update_status()


func _queue_map_redraw() -> void:
	if _map_canvas:
		_map_canvas.queue_redraw()


func _open_settings() -> void:
	if _options == null:
		_options = OptionsMenuUI.new()
		_options.theme_data = MENU_THEME.duplicate() as MenuTheme
		_options.close_requested.connect(_close_settings)
		_options.z_index = 120
		var ui_parent := get_parent()
		if ui_parent:
			ui_parent.add_child(_options)
		else:
			get_tree().current_scene.add_child(_options)
	_options.visible = true
	_options.focus_default()


func _close_settings() -> void:
	if _options:
		_options.visible = false
	_restore_mouse_look()


func _open_chat() -> void:
	GlobalChat.open_from_znood()
	_status_label.text = "Chatt öppnad."


func _call_zezzlor() -> void:
	var game := get_tree().get_first_node_in_group("game_director")
	if game and game.has_method("get_local_player"):
		var player: Node3D = game.get_local_player()
		if player:
			var trouble_dir := MouseLook.get_aim_direction()
			trouble_dir.y = 0.0
			if trouble_dir.length_squared() < 0.01:
				trouble_dir = -player.global_transform.basis.z
				trouble_dir.y = 0.0
			trouble_dir = trouble_dir.normalized()
			_znood_mgr().request_zezzlor_backup(player.global_position, trouble_dir)
			_status_label.text = "Zezzlor tillkallade — peka med siktet åt bråket."


func _call_backup() -> void:
	if _znood_mgr().get_joined_groups().is_empty():
		_status_label.text = "Gå med i minst en gruppering först."
		_show_page(Page.GROUPS)
		return
	var game := get_tree().get_first_node_in_group("game_director")
	if game and game.has_method("get_local_player"):
		var player: Node3D = game.get_local_player()
		if player:
			_znood_mgr().request_group_backup(player.global_position)
			_status_label.text = "Backup skickad till dina grupperingar."


func _update_status() -> void:
	if not visible:
		return
	var znood := _znood_mgr()
	var lines: PackedStringArray = []
	if znood and znood.map_picker_active:
		lines.append("Minimap-läge: klicka för vägpunkt.")
	if znood and znood.has_waypoint:
		lines.append("Vägpunkt aktiv.")
	var groups: Array = znood.get_joined_groups() if znood else []
	if not groups.is_empty():
		lines.append("Grupper: %s" % ", ".join(groups))
	if lines.is_empty():
		_status_label.text = "Znood redo."
	else:
		_status_label.text = "\n".join(lines)


func _restore_mouse_look() -> void:
	if _znood_mgr().device_open:
		return
	if _inventory_blocks_mouse():
		return
	var game := get_tree().get_first_node_in_group("game_director")
	if game and game.has_method("should_capture_mouse") and game.should_capture_mouse():
		MouseLook.activate(game.get_camera_pivot(), game.get_camera())


func _inventory_blocks_mouse() -> bool:
	var game := get_tree().get_first_node_in_group("game_director")
	if game and game.has_method("is_inventory_open"):
		return game.is_inventory_open()
	return false