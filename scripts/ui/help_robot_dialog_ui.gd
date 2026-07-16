class_name HelpRobotDialogUI
extends PanelContainer

signal closed

const HelpRobotCatalogScript = preload("res://scripts/npcs/help_robot_catalog.gd")
const NpcDialogueBarkScript = preload("res://scripts/audio/npc_dialogue_bark.gd")

var _title: Label
var _greeting: Label
var _question_list: VBoxContainer
var _answer: RichTextLabel
var _close_button: Button
var _spawn_id := ""
var _open := false


func is_open() -> bool:
	return _open


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	SpiderTheme.apply_to(self)


func open(spawn_id: String, robot_label: String) -> void:
	_spawn_id = spawn_id
	_title.text = robot_label
	_greeting.text = HelpRobotCatalogScript.get_greeting()
	_answer.text = ""
	_rebuild_questions()
	_open = true
	visible = true
	_play_bark("greeting")


func close_panel() -> void:
	if not _open:
		return
	HelpRobotTts.stop()
	_open = false
	visible = false
	closed.emit()


func _build() -> void:
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -320.0
	offset_top = -250.0
	offset_right = 320.0
	offset_bottom = 250.0

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
	scroll.custom_minimum_size = Vector2(600, 180)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_question_list = VBoxContainer.new()
	_question_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_question_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_question_list)

	_answer = RichTextLabel.new()
	_answer.custom_minimum_size = Vector2(600, 120)
	_answer.fit_content = true
	_answer.scroll_active = true
	_answer.bbcode_enabled = false
	_answer.add_theme_color_override("default_color", SpiderTheme.BONE)
	col.add_child(_answer)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(buttons)

	_close_button = Button.new()
	_close_button.text = "Stäng"
	_close_button.pressed.connect(close_panel)
	buttons.add_child(_close_button)

	var hint := Label.new()
	hint.text = "E eller Esc = stäng"
	SpiderTheme.style_subtitle(hint)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)


func _rebuild_questions() -> void:
	for child in _question_list.get_children():
		child.queue_free()

	var questions: Array = HelpRobotCatalogScript.get_questions(_spawn_id)
	for i in range(questions.size()):
		var entry: Dictionary = questions[i]
		var button := Button.new()
		button.text = str(entry.get("question", "?"))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_question_pressed.bind(entry))
		_question_list.add_child(button)


func _on_question_pressed(entry: Dictionary) -> void:
	var question := str(entry.get("question", ""))
	var answer := str(entry.get("answer", ""))
	_answer.text = answer
	_play_bark("confirmation")


func _play_bark(category: String) -> void:
	var game := get_tree().get_first_node_in_group("game_director")
	if game == null:
		return
	for node in get_tree().get_nodes_in_group("help_robot"):
		if not is_instance_valid(node):
			continue
		if node.has_method("is_player_nearby") and not node.is_player_nearby():
			continue
		NpcDialogueBarkScript.play_for_npc(node as Node3D, category, "sean")
		return


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		close_panel()
		get_viewport().set_input_as_handled()