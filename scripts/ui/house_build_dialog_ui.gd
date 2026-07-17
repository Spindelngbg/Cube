class_name HouseBuildDialogUI
extends PanelContainer

signal closed

const PlayerHouseCatalogScript = preload("res://scripts/cube/player_house_catalog.gd")

var _title: Label
var _info: RichTextLabel
var _list: VBoxContainer
var _build_button: Button
var _spawn_button: Button
var _close_button: Button
var _zone_id := ""
var _spawn_id := ""
var _selected_house_id := ""
var _open := false
var _reopen_block_until_msec := 0


func is_open() -> bool:
	return _open


func can_open() -> bool:
	return Time.get_ticks_msec() >= _reopen_block_until_msec


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	SpiderTheme.apply_to(self)


func open(zone_id: String, spawn_id: String) -> void:
	if not can_open():
		return
	_zone_id = zone_id
	_spawn_id = spawn_id
	_selected_house_id = ""
	_title.text = "Din tomt — bygg hus"
	_rebuild_list()
	_refresh_info()
	_open = true
	visible = true
	MouseLook.deactivate()
	_reopen_block_until_msec = Time.get_ticks_msec() + 180


func close_panel() -> void:
	if not _open:
		return
	_open = false
	visible = false
	_zone_id = ""
	_selected_house_id = ""
	_reopen_block_until_msec = Time.get_ticks_msec() + 220
	_restore_mouse()
	closed.emit()


func _build() -> void:
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -360.0
	offset_top = -300.0
	offset_right = 360.0
	offset_bottom = 300.0

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	add_child(col)

	_title = Label.new()
	SpiderTheme.style_title(_title, 22)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(680, 180)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 5)
	scroll.add_child(_list)

	_info = RichTextLabel.new()
	_info.custom_minimum_size = Vector2(680, 120)
	_info.fit_content = true
	_info.bbcode_enabled = false
	_info.add_theme_color_override("default_color", SpiderTheme.BONE)
	col.add_child(_info)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	col.add_child(buttons)

	_build_button = Button.new()
	_build_button.text = "Bygg hus"
	_build_button.pressed.connect(_on_build_pressed)
	buttons.add_child(_build_button)

	_spawn_button = Button.new()
	_spawn_button.text = "Sätt spawn här"
	_spawn_button.pressed.connect(_on_spawn_pressed)
	buttons.add_child(_spawn_button)

	_close_button = Button.new()
	_close_button.text = "Stäng"
	_close_button.pressed.connect(close_panel)
	buttons.add_child(_close_button)

	var hint := Label.new()
	hint.text = "Egna zoner är gröna | E eller Esc = stäng"
	SpiderTheme.style_subtitle(hint)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)


func _rebuild_list() -> void:
	for child in _list.get_children():
		child.queue_free()
	for house in PlayerHouseCatalogScript.all_houses():
		var house_id := str(house.get("id", ""))
		var btn := Button.new()
		var price := int(house.get("price", 0))
		var zones := int(house.get("zones_required", 1))
		btn.text = "%s — %d %s — %d zon(er)" % [
			str(house.get("name", house_id)),
			price,
			ItemCatalog.currency_symbol(),
			zones,
		]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_house_pressed.bind(house_id))
		_list.add_child(btn)


func _on_house_pressed(house_id: String) -> void:
	_selected_house_id = house_id
	_refresh_info()


func _refresh_info() -> void:
	if _selected_house_id == "":
		_info.text = "Välj en hustyp. Gröna zoner är dina. Stora hus kräver flera tomter bredvid varandra."
		_build_button.disabled = true
		return
	var house := PlayerHouseCatalogScript.get_house(_selected_house_id)
	var check: Dictionary = {}
	if PlayerHouseManager.has_method("can_build_house"):
		check = PlayerHouseManager.can_build_house(_selected_house_id, _zone_id)
	var ok := bool(check.get("ok", false))
	_info.text = "%s\n\n%s\n\n%s" % [
		str(house.get("name", "")),
		str(house.get("description", "")),
		"Redo att bygga." if ok else str(check.get("reason", "")),
	]
	_build_button.disabled = not ok
	_build_button.text = "Bygg %s" % str(house.get("name", "hus"))


func _on_build_pressed() -> void:
	if _selected_house_id == "" or _zone_id == "":
		return
	if PlayerHouseManager.try_build_house(_selected_house_id, _zone_id, _spawn_id):
		close_panel()


func _on_spawn_pressed() -> void:
	var zone_mgr := RuntimeGlobals.zone_ownership()
	if zone_mgr and zone_mgr.has_method("try_interact_building_spawn"):
		# Spawn via zonhanteraren — den läser spelarposition; anropa via game.
		var game := get_tree().get_first_node_in_group("game_director")
		if game and game.has_method("get_local_player"):
			var player: Node3D = game.get_local_player()
			if player:
				zone_mgr.try_interact_building_spawn(player.global_position, _spawn_id)
	close_panel()


func _restore_mouse() -> void:
	var game := get_tree().get_first_node_in_group("game_director")
	if game != null and game.has_method("should_capture_mouse") and game.should_capture_mouse():
		if game.has_method("get_camera_pivot") and game.has_method("get_camera"):
			MouseLook.activate(game.get_camera_pivot(), game.get_camera())


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if (
		event.is_action_pressed("ui_cancel")
		or event.is_action_pressed("pause")
		or event.is_action_pressed("interact")
	):
		if Time.get_ticks_msec() < _reopen_block_until_msec:
			get_viewport().set_input_as_handled()
			return
		close_panel()
		get_viewport().set_input_as_handled()
