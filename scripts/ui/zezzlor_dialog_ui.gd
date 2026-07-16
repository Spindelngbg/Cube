class_name ZezzlorDialogUI
extends PanelContainer

signal closed(zezzlor: Node3D)
signal response_picked(response_id: String)

const ZezzlorLoreScript = preload("res://scripts/story/zezzlor_lore.gd")

var _title: Label
var _question: Label
var _response_list: VBoxContainer
var _exchange: RichTextLabel
var _close_button: Button
var _zezzlor: Node3D
var _context := "patrol"
var _rank_id := "patrol"
var _open := false
var _answered := false
var _auto_close_timer: Timer


func is_open() -> bool:
	return _open


func get_zezzlor() -> Node3D:
	return _zezzlor


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


func open(zezzlor: Node3D, question: String, title: String, context: String) -> void:
	_cancel_auto_close()
	_zezzlor = zezzlor
	_context = context
	_rank_id = "patrol"
	if zezzlor != null and zezzlor.has_method("get_rank_id"):
		_rank_id = str(zezzlor.get_rank_id())
	_title.text = title
	_question.text = question
	_exchange.text = ""
	_answered = false
	_rebuild_responses()
	_open = true
	visible = true
	MouseLook.deactivate()


func close_panel() -> void:
	if not _open:
		return
	_cancel_auto_close()
	var zezzlor_ref := _zezzlor
	_open = false
	visible = false
	_zezzlor = null
	closed.emit(zezzlor_ref)


func _build() -> void:
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -340.0
	offset_top = -270.0
	offset_right = 340.0
	offset_bottom = 270.0

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	add_child(col)

	_title = Label.new()
	SpiderTheme.style_title(_title, 22)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)

	_question = Label.new()
	_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SpiderTheme.style_dialogue_body(_question, 20)
	_question.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(_question)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 170)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_response_list = VBoxContainer.new()
	_response_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_response_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_response_list)

	_exchange = RichTextLabel.new()
	_exchange.custom_minimum_size = Vector2(620, 110)
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
	hint.text = "Välj ett svar ovan | E eller Esc = stäng"
	SpiderTheme.style_subtitle(hint)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)


func _rebuild_responses() -> void:
	for child in _response_list.get_children():
		child.queue_free()

	for entry in ZezzlorLoreScript.get_player_responses(_context):
		var button := Button.new()
		button.text = str(entry.get("player", "?"))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_response_pressed.bind(entry))
		_response_list.add_child(button)


func _on_response_pressed(entry: Dictionary) -> void:
	if _answered:
		return
	_answered = true
	var response_id := str(entry.get("id", ""))
	var player_line := str(entry.get("player", ""))
	var personal_name := ""
	if _zezzlor != null and _zezzlor.has_method("get_personal_name"):
		personal_name = str(_zezzlor.get_personal_name())
	var reaction := ZezzlorLoreScript.get_zezzlor_reaction(
		response_id, _rank_id, _context, personal_name
	)
	_exchange.text = "Du: %s\n\n%s" % [player_line, reaction]
	for child in _response_list.get_children():
		child.disabled = true
	response_picked.emit(response_id)
	_schedule_auto_close(reaction)


func _schedule_auto_close(reaction: String) -> void:
	var duration := clampf(3.5 + float(reaction.length()) * 0.04, 4.0, 10.0)
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