class_name NpcDialogUI
extends PanelContainer

signal closed

const NpcDialogueBarkScript = preload("res://scripts/audio/npc_dialogue_bark.gd")

var _title: Label
var _body: Label
var _close_button: Button
var _npc_id := ""
var _open := false


func is_open() -> bool:
	return _open


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	SpiderTheme.apply_to(self)


func open(npc_id: String, title: String, body: String) -> void:
	_npc_id = npc_id
	_title.text = title if title != "" else "NPC"
	_body.text = body if body != "" else "..."
	_open = true
	visible = true
	MouseLook.deactivate()
	if _npc_id != "":
		NpcDialogueBarkScript.play_for_id(_npc_id, "greeting")


func close_panel() -> void:
	if not _open:
		return
	_open = false
	visible = false
	_npc_id = ""
	closed.emit()


func _build() -> void:
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -320.0
	offset_top = -210.0
	offset_right = 320.0
	offset_bottom = 210.0

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	add_child(col)

	_title = Label.new()
	SpiderTheme.style_title(_title, 22)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 220)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SpiderTheme.style_dialogue_body(_body, 19)
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(buttons)

	_close_button = Button.new()
	_close_button.text = "Avsluta samtal"
	_close_button.pressed.connect(close_panel)
	buttons.add_child(_close_button)

	var hint := Label.new()
	hint.text = "Tryck E eller Esc för att stänga"
	SpiderTheme.style_subtitle(hint)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		close_panel()
		get_viewport().set_input_as_handled()
