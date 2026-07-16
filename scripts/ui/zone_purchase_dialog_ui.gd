class_name ZonePurchaseDialogUI
extends PanelContainer

signal closed

const DcZoneOwnershipCatalogScript = preload("res://scripts/cube/dc_zone_ownership_catalog.gd")

var _title: Label
var _info: RichTextLabel
var _buy_button: Button
var _rent_button: Button
var _close_button: Button
var _zone_mgr: Node
var _context: Dictionary = {}
var _open := false


func is_open() -> bool:
	return _open


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	SpiderTheme.apply_to(self)
	InventoryManager.currency_changed.connect(_on_currency_changed)


func open(zone_mgr: Node, context: Dictionary) -> void:
	_zone_mgr = zone_mgr
	_context = context.duplicate(true)
	_open = true
	visible = true
	_refresh()
	MouseLook.deactivate()


func close_panel() -> void:
	if not _open:
		return
	_open = false
	visible = false
	_context = {}
	_zone_mgr = null
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

	_info = RichTextLabel.new()
	_info.custom_minimum_size = Vector2(680, 300)
	_info.fit_content = true
	_info.scroll_active = true
	_info.bbcode_enabled = false
	_info.add_theme_font_override("normal_font", GuiFontLibrary.regular())
	_info.add_theme_font_size_override("normal_font_size", GuiFontLibrary.FONT_STATUS)
	_info.add_theme_color_override("default_color", Color(SpiderTheme.VENOM.r, SpiderTheme.VENOM.g, SpiderTheme.VENOM.b, 0.9))
	col.add_child(_info)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	col.add_child(buttons)

	_buy_button = Button.new()
	_buy_button.text = "Köp zon"
	_buy_button.pressed.connect(_on_buy_pressed)
	buttons.add_child(_buy_button)

	_rent_button = Button.new()
	_rent_button.text = "Hyr byggnad"
	_rent_button.pressed.connect(_on_rent_pressed)
	buttons.add_child(_rent_button)

	_close_button = Button.new()
	_close_button.text = "Avbryt"
	_close_button.pressed.connect(close_panel)
	buttons.add_child(_close_button)

	var hint := Label.new()
	hint.text = "E eller Esc = stäng utan att köpa"
	SpiderTheme.style_subtitle(hint)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)


func _refresh() -> void:
	var name := str(_context.get("name", "Zon"))
	_title.text = "Zonköp — %s" % name

	var lines: PackedStringArray = []
	lines.append("Zon: %s" % name)
	var zone_type := str(_context.get("zone_type", ""))
	if zone_type != "":
		lines.append("Zontyp: %s" % zone_type)
	var zone_id := str(_context.get("zone_id", ""))
	if zone_id != "":
		lines.append("Zon-ID: %s" % zone_id)

	lines.append("")
	lines.append(
		"Att köpa en zon ger dig permanent äganderätt i spelet. "
		+ "Du kan sätta spawn vid byggnaden i zonen och zonen markeras som din."
	)
	lines.append(
		"Blockstorlek i Neo-Washington: %d×%d meter."
		% [int(DcZoneCatalog.BLOCK_M), int(DcZoneCatalog.BLOCK_M)]
	)

	var balance := int(_context.get("balance", 0))
	var currency := ItemCatalog.currency_name()
	lines.append("")
	lines.append("Ditt saldo: %d %s" % [balance, currency])

	var can_purchase := bool(_context.get("can_purchase", false))
	var can_rent := bool(_context.get("can_rent", false))
	var purchase_price := int(_context.get("purchase_price", 0))
	var rent_price := int(_context.get("rent_price", 0))

	lines.append("")
	if can_purchase and purchase_price > 0:
		lines.append("Köpeskilling: %d %s (permanent ägande)" % [purchase_price, currency])
	if can_rent and rent_price > 0:
		lines.append(
			"Hyra byggnad: %d %s (tillfällig spawn — du respawnar vid byggnaden tills du byter)"
			% [rent_price, currency]
		)

	var nft_note := str(_context.get("nft_note", "")).strip_edges()
	if nft_note != "":
		lines.append("")
		lines.append("NFT: %s" % nft_note)

	if not Auth.is_logged_in or Auth.is_guest:
		lines.append("")
		lines.append("Logga in med konto för att köpa eller hyra zoner.")

	_info.text = "\n".join(lines)
	_buy_button.visible = can_purchase and purchase_price > 0
	_rent_button.visible = can_rent and rent_price > 0
	_buy_button.disabled = (
		not Auth.is_logged_in
		or Auth.is_guest
		or balance < purchase_price
	)
	_rent_button.disabled = (
		not Auth.is_logged_in
		or Auth.is_guest
		or balance < rent_price
	)
	if can_purchase and purchase_price > 0:
		_buy_button.text = "Köp zon (%d %s)" % [purchase_price, currency]
	if can_rent and rent_price > 0:
		_rent_button.text = "Hyr byggnad (%d %s)" % [rent_price, currency]


func _on_buy_pressed() -> void:
	if _zone_mgr == null:
		return
	var zone_id := str(_context.get("zone_id", ""))
	if zone_id == "":
		return
	var spawn_id := str(_context.get("spawn_id", ""))
	if _zone_mgr.confirm_zone_purchase(zone_id, spawn_id):
		close_panel()


func _on_rent_pressed() -> void:
	if _zone_mgr == null:
		return
	var zone_id := str(_context.get("zone_id", ""))
	var spawn_id := str(_context.get("spawn_id", ""))
	if zone_id == "" or spawn_id == "":
		return
	if _zone_mgr.confirm_zone_rental(zone_id, spawn_id):
		close_panel()


func _on_currency_changed(_amount: int) -> void:
	if _open:
		_context["balance"] = InventoryManager.get_mydrillium()
		_refresh()


func _restore_mouse() -> void:
	var game := get_tree().get_first_node_in_group("game_director")
	if game and game.has_method("should_capture_mouse") and game.should_capture_mouse():
		if game.has_method("activate_gameplay_mouse"):
			game.activate_gameplay_mouse()