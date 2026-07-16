class_name ZezzlorDossierUI
extends PanelContainer

signal closed

var _title: Label
var _body: RichTextLabel
var _close_button: Button
var _open := false


func is_open() -> bool:
	return _open


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	SpiderTheme.apply_to(self)


func open(report_text: String, hq_label: String) -> void:
	_title.text = "Zezzlor HQ — %s" % hq_label
	_body.text = report_text
	_open = true
	visible = true
	MouseLook.deactivate()


func close_panel() -> void:
	if not _open:
		return
	_open = false
	visible = false
	var game := get_tree().get_first_node_in_group("game_director")
	if game != null and game.has_method("restore_gameplay_mouse"):
		game.restore_gameplay_mouse()
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

	_body = RichTextLabel.new()
	_body.custom_minimum_size = Vector2(680, 420)
	_body.scroll_active = true
	_body.fit_content = false
	_body.bbcode_enabled = false
	_body.add_theme_color_override("default_color", SpiderTheme.BONE)
	col.add_child(_body)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(buttons)

	_close_button = Button.new()
	_close_button.text = "Stäng dossier"
	_close_button.pressed.connect(close_panel)
	buttons.add_child(_close_button)

	var hint := Label.new()
	hint.text = "Esc eller E = stäng"
	SpiderTheme.style_subtitle(hint)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		close_panel()
		get_viewport().set_input_as_handled()