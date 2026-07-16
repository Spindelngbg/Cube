class_name StoryToastUI
extends PanelContainer

var _title: Label
var _body: Label
var _timer := 0.0


func _ready() -> void:
	visible = false
	_build()
	SpiderTheme.apply_to(self)
	QuestManager.story_toast.connect(_show_toast)


func _process(delta: float) -> void:
	if not visible:
		return
	_timer -= delta
	if _timer <= 0.0:
		visible = false


func _build() -> void:
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -280.0
	offset_right = 280.0
	offset_top = 72.0
	offset_bottom = 200.0

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	add_child(col)

	_title = Label.new()
	SpiderTheme.style_title(_title, 18)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	SpiderTheme.style_status(_body)
	col.add_child(_body)


func _show_toast(title: String, body: String) -> void:
	_title.text = title
	_body.text = body
	_timer = 6.5
	visible = true