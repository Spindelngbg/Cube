class_name FurnitureShopDialogUI
extends PanelContainer

signal closed

var _title: Label
var _info: RichTextLabel
var _list: VBoxContainer
var _buy_button: Button
var _close_button: Button
var _selected_id := ""
var _open := false


func is_open() -> bool:
	return _open


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	SpiderTheme.apply_to(self)


func open() -> void:
	_selected_id = ""
	_title.text = "Möbelbutiken"
	_rebuild()
	_info.text = "Köp en möbel och placera den var du vill i världen (bra på din gröna tomt)."
	_open = true
	visible = true
	MouseLook.deactivate()


func close_panel() -> void:
	if not _open:
		return
	_open = false
	visible = false
	_restore_mouse()
	closed.emit()


func _build() -> void:
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -340.0
	offset_top = -280.0
	offset_right = 340.0
	offset_bottom = 280.0

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	add_child(col)

	_title = Label.new()
	SpiderTheme.style_title(_title, 22)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 200)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	_info = RichTextLabel.new()
	_info.custom_minimum_size = Vector2(640, 100)
	_info.fit_content = true
	_info.add_theme_color_override("default_color", SpiderTheme.BONE)
	col.add_child(_info)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)

	_buy_button = Button.new()
	_buy_button.text = "Köp & placera"
	_buy_button.pressed.connect(_on_buy)
	row.add_child(_buy_button)

	_close_button = Button.new()
	_close_button.text = "Stäng"
	_close_button.pressed.connect(close_panel)
	row.add_child(_close_button)


func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	for entry in FurniturePlacementManager.get_shop_catalog():
		var id := str(entry.get("id", ""))
		var btn := Button.new()
		btn.text = "%s — %d %s" % [
			str(entry.get("name", id)),
			int(entry.get("price", 0)),
			ItemCatalog.currency_symbol(),
		]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if InventoryManager.has_item(id):
			btn.text += " [i inventory]"
		btn.pressed.connect(_on_select.bind(id))
		_list.add_child(btn)


func _on_select(item_id: String) -> void:
	_selected_id = item_id
	var def := FurniturePlacementManager.get_furniture_def(item_id)
	_info.text = "%s\n\n%s" % [str(def.get("name", "")), str(def.get("description", ""))]
	_buy_button.disabled = false
	if InventoryManager.has_item(item_id):
		_buy_button.text = "Placera %s" % str(def.get("name", ""))
	else:
		_buy_button.text = "Köp & placera (%d %s)" % [
			int(def.get("price", 0)),
			ItemCatalog.currency_symbol(),
		]


func _on_buy() -> void:
	if _selected_id == "":
		return
	if FurniturePlacementManager.try_buy_and_hold(_selected_id):
		close_panel()


func _restore_mouse() -> void:
	var game := get_tree().get_first_node_in_group("game_director")
	if game and game.has_method("should_capture_mouse") and game.should_capture_mouse():
		if game.has_method("get_camera_pivot") and game.has_method("get_camera"):
			MouseLook.activate(game.get_camera_pivot(), game.get_camera())


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		close_panel()
		get_viewport().set_input_as_handled()
