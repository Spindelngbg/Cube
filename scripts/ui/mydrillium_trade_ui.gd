class_name MydrilliumTradeUI
extends PanelContainer

signal closed

const MydrilliumMaterialCatalogScript = preload(
	"res://scripts/economy/mydrillium_material_catalog.gd"
)

var _title: Label
var _summary: RichTextLabel
var _material_list: VBoxContainer
var _colony_panel: VBoxContainer
var _refine_button: Button
var _complete_quest_button: Button
var _gift_button: Button
var _close_button: Button
var _station: MydrilliumServiceStation
var _open := false


func is_open() -> bool:
	return _open


func get_station() -> MydrilliumServiceStation:
	return _station


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	SpiderTheme.apply_to(self)
	MydrilliumEconomyManager.colony_quest_changed.connect(_refresh_colony_quest)
	InventoryManager.inventory_changed.connect(_refresh_materials)


func open(station: MydrilliumServiceStation) -> void:
	_station = station
	_title.text = station.display_name
	_open = true
	visible = true
	_refresh_materials()
	_refresh_colony_quest()
	_update_buttons()
	MouseLook.deactivate()


func close_panel() -> void:
	if not _open:
		return
	_open = false
	visible = false
	_station = null
	_restore_mouse()
	closed.emit()


func _build() -> void:
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -320.0
	offset_top = -260.0
	offset_right = 320.0
	offset_bottom = 260.0

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	add_child(col)

	_title = Label.new()
	SpiderTheme.style_title(_title, 22)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)

	_summary = RichTextLabel.new()
	_summary.custom_minimum_size = Vector2(600, 70)
	_summary.fit_content = true
	_summary.scroll_active = false
	_summary.add_theme_font_override("normal_font", GuiFontLibrary.regular())
	_summary.add_theme_font_size_override("normal_font_size", GuiFontLibrary.FONT_STATUS)
	_summary.add_theme_color_override("default_color", Color(SpiderTheme.VENOM.r, SpiderTheme.VENOM.g, SpiderTheme.VENOM.b, 0.85))
	col.add_child(_summary)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 150)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_material_list = VBoxContainer.new()
	_material_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_material_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_material_list)

	_colony_panel = VBoxContainer.new()
	_colony_panel.add_theme_constant_override("separation", 4)
	col.add_child(_colony_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)

	_refine_button = Button.new()
	_refine_button.text = "Raffinera allt"
	_refine_button.pressed.connect(_on_refine_pressed)
	row.add_child(_refine_button)

	_complete_quest_button = Button.new()
	_complete_quest_button.text = "Leverera koloniuppdrag"
	_complete_quest_button.pressed.connect(_on_complete_quest_pressed)
	row.add_child(_complete_quest_button)

	_gift_button = Button.new()
	_gift_button.text = "Skicka 1 malm till närmaste spelare"
	_gift_button.pressed.connect(_on_gift_pressed)
	row.add_child(_gift_button)

	_close_button = Button.new()
	_close_button.text = "Stäng"
	_close_button.pressed.connect(close_panel)
	row.add_child(_close_button)


func _refresh_materials() -> void:
	for child in _material_list.get_children():
		child.queue_free()

	var materials := InventoryManager.get_materials()
	if materials.is_empty():
		var empty := Label.new()
		empty.text = "Inga material i väskan."
		SpiderTheme.style_subtitle(empty)
		_material_list.add_child(empty)
	else:
		for material_id in materials:
			var count := int(materials[material_id])
			if count <= 0:
				continue
			var row := Label.new()
			var value := MydrilliumMaterialCatalogScript.get_refine_value(str(material_id))
			row.text = "%s x%d — ~%d %s/st" % [
				MydrilliumMaterialCatalogScript.get_display_name(str(material_id)),
				count,
				value,
				ItemCatalog.currency_symbol(),
			]
			SpiderTheme.style_status(row)
			_material_list.add_child(row)

	_summary.text = (
		"Plånbok: %s %s\n"
		% [ItemCatalog.currency_symbol(), _comma(InventoryManager.get_mydrillium())]
	)
	_update_buttons()


func _refresh_colony_quest() -> void:
	for child in _colony_panel.get_children():
		child.queue_free()

	if not MydrilliumEconomyManager.has_active_colony_quest():
		var none := Label.new()
		none.text = "Inget aktivt koloniuppdrag just nu."
		SpiderTheme.style_subtitle(none)
		_colony_panel.add_child(none)
		_update_buttons()
		return

	var quest := MydrilliumEconomyManager.get_active_colony_quest()
	var material := str(quest.get("material", ""))
	var need := int(quest.get("amount", 0))
	var have := InventoryManager.get_material_count(material)
	var quest_label := Label.new()
	quest_label.text = (
		"%s\n%s\nBehöver %d %s (du har %d) — bonus %d %s"
		% [
			str(quest.get("title", "")),
			str(quest.get("description", "")),
			need,
			MydrilliumMaterialCatalogScript.get_display_name(material),
			have,
			int(quest.get("bonus_md", 0)),
			ItemCatalog.currency_symbol(),
		]
	)
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SpiderTheme.style_status(quest_label)
	_colony_panel.add_child(quest_label)
	_update_buttons()


func _update_buttons() -> void:
	var is_trade := _station != null and _station.station_kind == "trade_post"
	var is_colony := _station != null and _station.station_kind == "colony_hub"
	_refine_button.visible = is_trade
	_complete_quest_button.visible = is_colony and MydrilliumEconomyManager.has_active_colony_quest()
	_gift_button.visible = is_trade and InventoryManager.get_material_count("raw_mydrillium_ore") > 0


func _on_refine_pressed() -> void:
	if _station == null:
		return
	var payout := MydrilliumEconomyManager.refine_all_at_station("trade_post")
	if payout <= 0:
		QuestManager.story_toast.emit("Handel", "Inget att sälja.")
		return
	QuestManager.story_toast.emit(
		"Mineral såld",
		"+%d %s (spelarhandel med rabatt)."
		% [payout, ItemCatalog.currency_symbol()]
	)
	var game := get_tree().get_first_node_in_group("game_director")
	if game != null and game.has_method("get_local_player"):
		var player: Node3D = game.get_local_player()
		if player != null:
			ArrivalQuestManager.notify_mineral_refined(player.global_position)
	_refresh_materials()


func _on_complete_quest_pressed() -> void:
	if MydrilliumEconomyManager.try_complete_colony_quest():
		_refresh_colony_quest()
		_refresh_materials()


func _on_gift_pressed() -> void:
	var target_peer := _find_nearest_other_player_peer()
	if target_peer < 0:
		QuestManager.story_toast.emit("Handel", "Ingen annan spelare i närheten.")
		return
	if MydrilliumEconomyManager.try_gift_material_to_player(target_peer, "raw_mydrillium_ore", 1):
		_refresh_materials()


func _find_nearest_other_player_peer() -> int:
	var game := get_tree().get_first_node_in_group("game_director")
	if game == null or not game.has_method("get_local_player"):
		return -1
	var local_player: Node3D = game.get_local_player()
	if local_player == null or not game.get("players") is Dictionary:
		return -1
	var local_id := get_tree().get_multiplayer().get_unique_id()
	var best_peer := -1
	var best_dist := 18.0
	for peer_id in game.players:
		if int(peer_id) == local_id:
			continue
		var player: Node3D = game.players[peer_id]
		if player == null:
			continue
		var dist := local_player.global_position.distance_to(player.global_position)
		if dist < best_dist:
			best_dist = dist
			best_peer = int(peer_id)
	return best_peer


func _comma(value: int) -> String:
	var text := str(maxi(value, 0))
	if text.length() <= 3:
		return text
	var parts: PackedStringArray = []
	while text.length() > 3:
		parts.insert(0, text.substr(text.length() - 3, 3))
		text = text.substr(0, text.length() - 3)
	if text != "":
		parts.insert(0, text)
	return ",".join(parts)


func _restore_mouse() -> void:
	if get_tree().paused:
		return
	var game := get_tree().current_scene
	if game and game.has_method("activate_gameplay_mouse"):
		game.activate_gameplay_mouse()