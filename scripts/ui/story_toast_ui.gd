class_name StoryToastUI
extends PanelContainer

const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")
const GuiFontLibraryScript = preload("res://scripts/ui/gui_font_library.gd")

const PANEL_WIDTH := 680.0
const MIN_BODY_HEIGHT := 72.0
const MAX_BODY_HEIGHT := 220.0
const BASE_DISPLAY_SEC := 5.5
const CHAR_DISPLAY_SEC := 0.045

var _title: Label
var _body: Label
var _timer := 0.0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	_apply_panel_style()
	GuiFontLibraryScript.apply_to_theme(theme)
	QuestManager.story_toast.connect(_show_toast)


func _process(delta: float) -> void:
	if not visible:
		return
	_timer -= delta
	if _timer <= 0.0:
		visible = false


func _apply_panel_style() -> void:
	add_theme_stylebox_override("panel", SpiderTheme.dialogue_panel_style())


func _build() -> void:
	anchor_left = 0.5
	anchor_top = 1.0
	anchor_right = 0.5
	anchor_bottom = 1.0
	offset_left = -PANEL_WIDTH * 0.5
	offset_right = PANEL_WIDTH * 0.5
	offset_bottom = -28.0

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	add_child(col)

	_title = Label.new()
	SpiderTheme.style_dialogue_title(_title, 28)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_title)

	_body = Label.new()
	SpiderTheme.style_dialogue_body(_body, 22)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_body.custom_minimum_size = Vector2(PANEL_WIDTH - 40.0, MIN_BODY_HEIGHT)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_body)


func _show_toast(title: String, body: String) -> void:
	_title.text = title
	_body.text = body
	_resize_for_content()
	_timer = _display_duration(body)
	visible = true
	GameSfxScript.play_2d_varied(
		self,
		RpgAudioLibraryScript.from_pool(RpgAudioLibraryScript.UI_SELECT),
		Vector2(-16.0, -11.0)
	)


func _resize_for_content() -> void:
	await get_tree().process_frame
	var body_height := clampf(
		_body.get_minimum_size().y,
		MIN_BODY_HEIGHT,
		MAX_BODY_HEIGHT
	)
	_body.custom_minimum_size = Vector2(PANEL_WIDTH - 40.0, body_height)
	var title_height := maxf(_title.get_minimum_size().y, 34.0)
	offset_top = -(body_height + title_height + 56.0)


func _display_duration(body: String) -> float:
	return clampf(BASE_DISPLAY_SEC + float(body.length()) * CHAR_DISPLAY_SEC, 6.0, 14.0)
