class_name GameTutorialUI
extends PanelContainer

var _manager: Node
var _header: Label
var _page_title: Label
var _body: Label
var _page_counter: Label
var _next_button: Button
var _skip_button: Button
var _open := false


func setup(manager: Node) -> void:
	_manager = manager


func is_open() -> bool:
	return _open


func _ready() -> void:
	visible = false
	_build()
	SpiderTheme.apply_to(self)


func show_page(
	tutorial_title: String,
	page_title: String,
	body: String,
	page_number: int,
	page_count: int,
	show_skip: bool
) -> void:
	_header.text = tutorial_title
	_page_title.text = page_title
	_body.text = body
	_page_counter.text = "Sida %d / %d" % [page_number, page_count]
	_skip_button.visible = show_skip
	_next_button.text = "Börja spela" if page_number >= page_count else "Nästa"
	_open = true
	visible = true


func hide_panel() -> void:
	_open = false
	visible = false


func _build() -> void:
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -300.0
	offset_top = -210.0
	offset_right = 300.0
	offset_bottom = 210.0

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	add_child(col)

	_header = Label.new()
	SpiderTheme.style_title(_header, 24)
	_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_header)

	_page_title = Label.new()
	SpiderTheme.style_section(_page_title)
	_page_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_page_title)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(560, 220)
	SpiderTheme.style_status(_body)
	col.add_child(_body)

	_page_counter = Label.new()
	SpiderTheme.style_subtitle(_page_counter)
	_page_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_page_counter)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	col.add_child(buttons)

	_skip_button = Button.new()
	_skip_button.text = "Hoppa över"
	_skip_button.pressed.connect(_on_skip_pressed)
	buttons.add_child(_skip_button)

	_next_button = Button.new()
	_next_button.text = "Nästa"
	_next_button.pressed.connect(_on_next_pressed)
	buttons.add_child(_next_button)

	var hint := Label.new()
	hint.text = "H = öppna guiden igen"
	SpiderTheme.style_subtitle(hint)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)


func _on_next_pressed() -> void:
	if _manager and _manager.has_method("next_page"):
		_manager.next_page()


func _on_skip_pressed() -> void:
	if _manager and _manager.has_method("skip_tutorial"):
		_manager.skip_tutorial()