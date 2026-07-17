class_name FactoryDialogUI
extends PanelContainer

signal closed
signal response_picked(response_id: String)

const FactoryWorkerCatalogScript = preload("res://scripts/npcs/factory_worker_catalog.gd")
const NpcDialogueBarkScript = preload("res://scripts/audio/npc_dialogue_bark.gd")

var _title: Label
var _body: Label
var _response_list: VBoxContainer
var _exchange: RichTextLabel
var _close_button: Button
var _npc_id := ""
var _personality := "warm"
var _open := false
var _answered := false
var _auto_close_timer: Timer


func is_open() -> bool:
	return _open


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	SpiderTheme.apply_to(self)
	_auto_close_timer = Timer.new()
	_auto_close_timer.name = "AutoCloseTimer"
	_auto_close_timer.one_shot = true
	_auto_close_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_auto_close_timer.timeout.connect(close_panel)
	add_child(_auto_close_timer)


func open_for_worker(npc_id: String) -> void:
	_cancel_auto_close()
	_npc_id = npc_id
	_answered = false
	var on_shift := FactoryWorkManager.is_on_shift()
	var cycles := FactoryWorkManager.get_cycles_done()
	var line: Dictionary = FactoryWorkerCatalogScript.pick_open_line(npc_id, on_shift, cycles)
	_personality = str(line.get("personality", "warm"))
	_title.text = str(line.get("title", "Kollega"))
	_body.text = str(line.get("body", "..."))
	_exchange.text = ""
	_rebuild_responses(on_shift)
	_open = true
	visible = true
	MouseLook.deactivate()
	NpcDialogueBarkScript.play_for_id(npc_id, "greeting")


func close_panel() -> void:
	if not _open:
		return
	_cancel_auto_close()
	_open = false
	visible = false
	_npc_id = ""
	closed.emit()


func _build() -> void:
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -360.0
	offset_top = -290.0
	offset_right = 360.0
	offset_bottom = 290.0

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	add_child(col)

	_title = Label.new()
	SpiderTheme.style_title(_title, 22)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SpiderTheme.style_dialogue_body(_body, 19)
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(_body)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(680, 190)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_response_list = VBoxContainer.new()
	_response_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_response_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_response_list)

	_exchange = RichTextLabel.new()
	_exchange.custom_minimum_size = Vector2(680, 120)
	_exchange.fit_content = true
	_exchange.scroll_active = true
	_exchange.bbcode_enabled = false
	_exchange.add_theme_color_override("default_color", SpiderTheme.BONE)
	col.add_child(_exchange)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(buttons)

	_close_button = Button.new()
	_close_button.text = "Avsluta samtal"
	_close_button.pressed.connect(close_panel)
	buttons.add_child(_close_button)

	var hint := Label.new()
	hint.text = "Svara som du vill — de reagerar mänskligt | Esc/E stänger"
	SpiderTheme.style_subtitle(hint)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)


func _rebuild_responses(on_shift: bool) -> void:
	for child in _response_list.get_children():
		child.queue_free()
	for entry in FactoryWorkerCatalogScript.get_player_responses(_personality, on_shift):
		var button := Button.new()
		button.text = str(entry.get("player", "?"))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_response_pressed.bind(entry))
		_response_list.add_child(button)


func _on_response_pressed(entry: Dictionary) -> void:
	if _answered:
		return
	_answered = true
	var response_id := str(entry.get("id", ""))
	var player_line := str(entry.get("player", ""))
	var reaction := FactoryWorkerCatalogScript.get_reaction(
		_npc_id,
		response_id,
		FactoryWorkManager.is_on_shift(),
		FactoryWorkManager.get_cycles_done()
	)
	_exchange.text = "Du: %s\n\n%s" % [player_line, reaction]
	for child in _response_list.get_children():
		if child is Button:
			(child as Button).disabled = true
	NpcDialogueBarkScript.play_for_id(_npc_id, "miscellaneous")
	response_picked.emit(response_id)
	if response_id == "leave":
		_schedule_auto_close(reaction, true)
	else:
		_schedule_auto_close(reaction, false)


func _schedule_auto_close(reaction: String, force_soon: bool = false) -> void:
	var duration := 2.2 if force_soon else clampf(3.8 + float(reaction.length()) * 0.035, 4.5, 12.0)
	_auto_close_timer.start(duration)


func _cancel_auto_close() -> void:
	if _auto_close_timer != null:
		_auto_close_timer.stop()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		close_panel()
		get_viewport().set_input_as_handled()
