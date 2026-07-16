class_name WeaponShopDialogUI
extends PanelContainer

signal closed

const WeaponShopCatalogScript = preload("res://scripts/shops/weapon_shop_catalog.gd")
const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")

var _title: Label
var _greeting: Label
var _weapon_list: VBoxContainer
var _answer: RichTextLabel
var _buy_button: Button
var _close_button: Button
var _owner: WeaponShopOwner
var _selected_weapon_id := ""
var _open := false


func is_open() -> bool:
	return _open


func get_shop_owner() -> WeaponShopOwner:
	return _owner


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	SpiderTheme.apply_to(self)


func open(owner: WeaponShopOwner) -> void:
	_owner = owner
	_selected_weapon_id = ""
	_title.text = WeaponShopCatalogScript.OWNER_NAME
	_greeting.text = WeaponShopCatalogScript.get_greeting()
	_answer.text = "Välj ett vapen i listan."
	_rebuild_weapon_list()
	_refresh_buy_button()
	_open = true
	visible = true
	MouseLook.deactivate()
	_speak_line(WeaponShopCatalogScript.get_greeting())


func close_panel() -> void:
	if not _open:
		return
	HelpRobotTts.stop()
	_open = false
	visible = false
	_owner = null
	_selected_weapon_id = ""
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

	_greeting = Label.new()
	_greeting.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SpiderTheme.style_status(_greeting)
	_greeting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_greeting)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 220)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_weapon_list = VBoxContainer.new()
	_weapon_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_weapon_list.add_theme_constant_override("separation", 5)
	scroll.add_child(_weapon_list)

	_answer = RichTextLabel.new()
	_answer.custom_minimum_size = Vector2(640, 130)
	_answer.fit_content = true
	_answer.scroll_active = true
	_answer.bbcode_enabled = false
	_answer.add_theme_color_override("default_color", SpiderTheme.BONE)
	col.add_child(_answer)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	col.add_child(buttons)

	_buy_button = Button.new()
	_buy_button.text = "Köp och utrusta"
	_buy_button.pressed.connect(_on_buy_pressed)
	buttons.add_child(_buy_button)

	_close_button = Button.new()
	_close_button.text = "Stäng"
	_close_button.pressed.connect(close_panel)
	buttons.add_child(_close_button)

	var hint := Label.new()
	hint.text = "Klicka vapen för Stål-Svens kommentar | E eller Esc = stäng"
	SpiderTheme.style_subtitle(hint)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)


func _rebuild_weapon_list() -> void:
	for child in _weapon_list.get_children():
		child.queue_free()

	_add_section_header("— Gevär —")
	for weapon_id in WeaponCatalog.SHOP_RANGED:
		_add_weapon_button(weapon_id)

	_add_section_header("— Knivar & yxor —")
	for weapon_id in WeaponCatalog.SHOP_MELEE:
		_add_weapon_button(weapon_id)


func _add_section_header(text: String) -> void:
	var header := Label.new()
	header.text = text
	SpiderTheme.style_subtitle(header)
	_weapon_list.add_child(header)


func _add_weapon_button(weapon_id: String) -> void:
	var button := Button.new()
	button.text = WeaponShopCatalogScript.get_weapon_button_label(weapon_id)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if InventoryManager.has_item(weapon_id):
		button.text += " [ÄGD]"
	button.pressed.connect(_on_weapon_pressed.bind(weapon_id))
	_weapon_list.add_child(button)


func _on_weapon_pressed(weapon_id: String) -> void:
	_selected_weapon_id = weapon_id
	var reaction := WeaponShopCatalogScript.get_weapon_reaction(weapon_id)
	var summary := WeaponShopCatalogScript.get_weapon_summary(weapon_id)
	_answer.text = "%s\n\n%s" % [summary, reaction]
	_refresh_buy_button()
	_speak_line(reaction)


func _on_buy_pressed() -> void:
	if _selected_weapon_id == "":
		return
	if _try_purchase_weapon(_selected_weapon_id):
		_rebuild_weapon_list()
		_refresh_buy_button()


func _try_purchase_weapon(weapon_id: String) -> bool:
	if InventoryManager.has_item(weapon_id):
		if WeaponManager.equip(weapon_id):
			GameSfxScript.play_2d_varied(self, RpgAudioLibraryScript.pickup_weapon())
			QuestManager.story_toast.emit(
				WeaponShopCatalogScript.OWNER_NAME,
				"%s utrustad." % ItemCatalog.get_display_name(weapon_id)
			)
			return true
		return false

	var price := ItemCatalog.get_shop_price(weapon_id)
	if not InventoryManager.spend_mydrillium(price):
		var broke_line := (
			"Du behöver %d %s för %s. Kom tillbaka när plånboken matchar ambitionerna."
			% [price, ItemCatalog.currency_symbol(), ItemCatalog.get_display_name(weapon_id)]
		)
		_answer.text = broke_line
		_speak_line(broke_line)
		return false

	if not InventoryManager.add_item(weapon_id):
		InventoryManager.add_mydrillium(price)
		return false

	WeaponManager.on_weapon_acquired(weapon_id, true)
	GameSfxScript.play_2d_varied(self, RpgAudioLibraryScript.shop_buy())
	var bought_line := (
		"Utmärkt affär! %s är din. Häng den inte på väggen hemma — använd den."
		% ItemCatalog.get_display_name(weapon_id)
	)
	_answer.text = bought_line
	_speak_line(bought_line)
	QuestManager.story_toast.emit(
		WeaponShopCatalogScript.OWNER_NAME,
		"%s köpt och utrustad." % ItemCatalog.get_display_name(weapon_id)
	)
	return true


func _refresh_buy_button() -> void:
	if _selected_weapon_id == "":
		_buy_button.disabled = true
		_buy_button.text = "Köp och utrusta"
		return
	if InventoryManager.has_item(_selected_weapon_id):
		_buy_button.disabled = false
		_buy_button.text = "Utrusta %s" % ItemCatalog.get_display_name(_selected_weapon_id)
	else:
		_buy_button.disabled = false
		_buy_button.text = "Köp %s" % ItemCatalog.get_display_name(_selected_weapon_id)


func _speak_line(text: String) -> void:
	var player: AudioStreamPlayer3D = null
	if _owner != null:
		player = _owner.get_voice_player()
	HelpRobotTts.speak(text, player, true)


func _restore_mouse() -> void:
	var game := get_tree().get_first_node_in_group("game_director")
	if game != null and game.has_method("should_capture_mouse") and game.has_method("activate_gameplay_mouse"):
		if game.should_capture_mouse():
			game.activate_gameplay_mouse()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		close_panel()
		get_viewport().set_input_as_handled()