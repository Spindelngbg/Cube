class_name UtilityShopDialogUI
extends PanelContainer

signal closed

const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")

var _title: Label
var _info: RichTextLabel
var _list: VBoxContainer
var _buy_button: Button
var _use_button: Button
var _close_button: Button
var _stock: Array[String] = []
var _selected := ""
var _open := false


func is_open() -> bool:
	return _open


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	SpiderTheme.apply_to(self)


func open(stock: Array[String]) -> void:
	_stock = stock
	_selected = ""
	_title.text = "Överlevnadsboden"
	_rebuild()
	_info.text = "Nyttiga grejer för kolonister. Köp och använd när det behövs."
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
	scroll.custom_minimum_size = Vector2(640, 180)
	col.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	_info = RichTextLabel.new()
	_info.custom_minimum_size = Vector2(640, 110)
	_info.fit_content = true
	_info.add_theme_color_override("default_color", SpiderTheme.BONE)
	col.add_child(_info)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)

	_buy_button = Button.new()
	_buy_button.text = "Köp"
	_buy_button.pressed.connect(_on_buy)
	row.add_child(_buy_button)

	_use_button = Button.new()
	_use_button.text = "Använd"
	_use_button.pressed.connect(_on_use)
	row.add_child(_use_button)

	_close_button = Button.new()
	_close_button.text = "Stäng"
	_close_button.pressed.connect(close_panel)
	row.add_child(_close_button)


func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	for item_id in _stock:
		var btn := Button.new()
		var price := ItemCatalog.get_shop_price(item_id)
		btn.text = "%s — %d %s" % [
			ItemCatalog.get_display_name(item_id),
			price,
			ItemCatalog.currency_symbol(),
		]
		if InventoryManager.has_item(item_id):
			btn.text += " [ÄGD]"
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_select.bind(item_id))
		_list.add_child(btn)


func _on_select(item_id: String) -> void:
	_selected = item_id
	_info.text = "%s\n\n%s" % [
		ItemCatalog.get_display_name(item_id),
		ItemCatalog.get_description(item_id),
	]
	_buy_button.disabled = InventoryManager.has_item(item_id) and not ItemCatalog.is_stackable(item_id)
	_use_button.disabled = not InventoryManager.has_item(item_id)


func _on_buy() -> void:
	if _selected == "":
		return
	var price := ItemCatalog.get_shop_price(_selected)
	if InventoryManager.has_item(_selected) and not ItemCatalog.is_stackable(_selected):
		_info.text = "Du har redan den."
		return
	if not InventoryManager.spend_mydrillium(price):
		_info.text = "Du behöver %d %s." % [price, ItemCatalog.currency_symbol()]
		return
	if not InventoryManager.add_item(_selected):
		InventoryManager.add_mydrillium(price)
		_info.text = "Inventory fullt."
		return
	GameSfxScript.play_2d_varied(self, RpgAudioLibraryScript.shop_buy())
	_info.text = "%s köpt!" % ItemCatalog.get_display_name(_selected)
	_rebuild()
	_on_select(_selected)


func _on_use() -> void:
	if _selected == "" or not InventoryManager.has_item(_selected):
		return
	if _apply_utility(_selected):
		if _selected != "pansarväst" and _selected != "hoppskor":
			InventoryManager.remove_item(_selected)
		_rebuild()
		_on_select(_selected)


func _apply_utility(item_id: String) -> bool:
	var game := get_tree().get_first_node_in_group("game_director")
	var player: Node = null
	if game and game.has_method("get_local_player"):
		player = game.get_local_player()
	match item_id:
		"forsta_hjalpen":
			if player and player.has_method("heal_to_full"):
				# Delvis heal om möjligt
				if player.has_method("get_health_snapshot"):
					var snap: Dictionary = player.get_health_snapshot()
					var cur := float(snap.get("current", 0))
					var mx := float(snap.get("max", 100))
					var heal := float(ItemCatalog.get_item(item_id).get("heal_amount", 40))
					if player.has_method("take_damage"):
						# Fake heal via internal if available
						pass
				if player.has_method("heal_amount"):
					player.heal_amount(float(ItemCatalog.get_item(item_id).get("heal_amount", 40)))
				elif player.has_method("heal_to_full"):
					# Om bara full heal finns: heala om under max
					player.heal_to_full()
				QuestManager.story_toast.emit("Första hjälpen", "Du känner dig bättre.")
				return true
		"energi_dryck":
			var mult := float(ItemCatalog.get_item(item_id).get("speed_multiplier", 1.35))
			var dur := float(ItemCatalog.get_item(item_id).get("buff_duration", 45))
			if player and player.has_method("apply_speed_buff"):
				player.apply_speed_buff(mult, dur)
			else:
				# Fallback: reuse damage buff timer style via meta
				if player:
					player.set_meta("speed_buff_mult", mult)
					player.set_meta("speed_buff_timer", dur)
			QuestManager.story_toast.emit("Energidryck", "Du springer fortare en stund!")
			return true
		"kartfyr":
			if player:
				var znood := RuntimeGlobals.znood()
				if znood and znood.has_method("set_waypoint"):
					znood.set_waypoint(player.global_position)
					QuestManager.story_toast.emit("Kartfyr", "Vägpunkt satt vid dig.")
					return true
		"pansarväst":
			QuestManager.story_toast.emit("Pansarväst", "Västen ger max-HP så länge den är i inventory.")
			return true
		"hoppskor":
			InventoryManager.equip_footwear("hoppskor")
			QuestManager.story_toast.emit("Hoppskor", "Skorna är på!")
			return true
	return false


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
