class_name InventoryUI
extends PanelContainer

var _item_list: VBoxContainer
var _summary: Label
var _visible := false


func _ready() -> void:
	visible = false
	_build()
	SpiderTheme.apply_to(self)
	InventoryManager.inventory_changed.connect(_refresh)


func toggle() -> void:
	_visible = not _visible
	visible = _visible
	if _visible:
		_refresh()
		MouseLook.deactivate()
	else:
		_restore_mouse_look()


func _build() -> void:
	custom_minimum_size = Vector2(360, 0)
	offset_left = 900.0
	offset_top = 250.0
	offset_right = 1260.0
	offset_bottom = 520.0

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)

	var header := Label.new()
	header.text = "Inventory"
	SpiderTheme.style_title(header, 22)
	col.add_child(header)

	_summary = Label.new()
	SpiderTheme.style_status(_summary)
	col.add_child(_summary)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 220)
	col.add_child(scroll)

	_item_list = VBoxContainer.new()
	_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_item_list)

	var hint := Label.new()
	hint.text = "I = stäng inventory"
	SpiderTheme.style_subtitle(hint)
	col.add_child(hint)


func _refresh() -> void:
	for child in _item_list.get_children():
		child.queue_free()

	var items := InventoryManager.get_items()
	var equipped := WeaponManager.get_equipped_display_name()
	var equipped_note := " | Utrustat: %s" % equipped if equipped != "" else ""
	_summary.text = (
		"%s: %s | Max HP: %d (bas %d + bonus %d)%s"
		% [
			ItemCatalog.currency_name(),
			_format_mydrillium(InventoryManager.get_mydrillium()),
			int(round(InventoryManager.get_max_hp())),
			int(round(ItemCatalog.base_hp())),
			int(round(InventoryManager.get_hp_bonus_total())),
			equipped_note,
		]
	)

	if items.is_empty():
		var empty := Label.new()
		empty.text = "Tomt — plocka upp föremål i världen."
		SpiderTheme.style_subtitle(empty)
		_item_list.add_child(empty)
		return

	for item_id in items:
		_item_list.add_child(_make_item_row(str(item_id)))


func _make_item_row(item_id: String) -> PanelContainer:
	var row := PanelContainer.new()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	row.add_child(h)

	var rarity := ItemCatalog.get_rarity(item_id)
	var color := ItemCatalog.rarity_color(rarity)

	var name_label := Label.new()
	name_label.text = ItemCatalog.get_display_name(item_id)
	name_label.add_theme_color_override("font_color", color)
	name_label.custom_minimum_size = Vector2(170, 0)
	h.add_child(name_label)

	var bonus := Label.new()
	var hp_bonus := int(ItemCatalog.get_hp_bonus(item_id))
	if hp_bonus > 0:
		bonus.text = "+%d HP" % hp_bonus
	else:
		bonus.text = ItemCatalog.get_item_type_label(item_id)
	SpiderTheme.style_status(bonus)
	h.add_child(bonus)

	var rarity_label := Label.new()
	rarity_label.text = rarity.capitalize()
	SpiderTheme.style_subtitle(rarity_label)
	h.add_child(rarity_label)

	var desc := Label.new()
	desc.text = ItemCatalog.get_description(item_id)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(320, 0)
	SpiderTheme.style_subtitle(desc)

	var wrap := VBoxContainer.new()
	wrap.add_child(row)
	wrap.add_child(desc)
	var container := PanelContainer.new()
	container.add_child(wrap)
	return container


func _format_mydrillium(amount: int) -> String:
	return "%s %s" % [ItemCatalog.currency_symbol(), _comma_separate(amount)]


func _comma_separate(value: int) -> String:
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


func _restore_mouse_look() -> void:
	if get_tree().paused:
		return
	var game := get_tree().current_scene
	if game and game.has_node("CameraPivot/Camera3D"):
		MouseLook.activate(
			game.get_node("CameraPivot") as Node3D,
			game.get_node("CameraPivot/Camera3D") as Camera3D
		)