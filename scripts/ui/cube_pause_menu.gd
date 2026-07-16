class_name CubePauseMenu
extends PauseMenuUI

const MenuBackgroundScript = preload("res://scripts/ui/menu_background.gd")
const DanglingSpiderScript = preload("res://scripts/ui/dangling_spider.gd")
const PauseMenuDecorScript = preload("res://scripts/ui/pause_menu_decor.gd")
const GuiFontLibraryScript = preload("res://scripts/ui/gui_font_library.gd")


func _ready() -> void:
	_apply_spider_theme_data()
	super._ready()


func _apply_spider_theme_data() -> void:
	if theme_data == null:
		theme_data = MenuTheme.new()
	theme_data.bg_color = SpiderTheme.BG_TOP
	theme_data.panel_bg = Color(0.06, 0.05, 0.08, 0.96)
	theme_data.panel_border = Color(SpiderTheme.BLOOD_BRIGHT.r, SpiderTheme.BLOOD_BRIGHT.g, SpiderTheme.BLOOD_BRIGHT.b, 0.55)
	theme_data.accent = SpiderTheme.BLOOD
	theme_data.accent_hover = SpiderTheme.BLOOD_BRIGHT
	theme_data.text = SpiderTheme.BONE
	theme_data.text_dim = SpiderTheme.MUTED
	theme_data.button_bg = Color(0.08, 0.07, 0.1, 0.94)
	theme_data.button_bg_hover = Color(0.14, 0.08, 0.1, 0.98)
	theme_data.button_bg_pressed = Color(0.05, 0.04, 0.06, 0.98)
	theme_data.slider_track = Color(0.1, 0.08, 0.1, 0.9)
	theme_data.slider_fill = SpiderTheme.BLOOD
	theme_data.heading_font_size = 30
	theme_data.button_font_size = GuiFontLibraryScript.FONT_BUTTON
	theme_data.menu_max_width = 420
	theme_data.game_title = "The Cube"
	theme_data.game_subtitle = "Spindeln väntar i mörkret..."


func _build() -> void:
	var bg := MenuBackgroundScript.new()
	bg.name = "MenuBackground"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.03, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_add_dangling_spider(Vector2(0.78, 0.0), 150.0)
	_add_dangling_spider(Vector2(0.14, 0.02), 120.0)
	_add_dangling_spider(Vector2(0.92, 0.12), 95.0)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _panel_style())
	_panel.custom_minimum_size = Vector2(theme_data.menu_max_width, 0)
	center.add_child(_panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	_panel.add_child(col)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	col.add_child(header)

	var title := Label.new()
	title.text = "Paus"
	SpiderTheme.style_title(title, 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)

	var subtitle := Label.new()
	subtitle.text = theme_data.game_subtitle
	SpiderTheme.style_subtitle(subtitle)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(subtitle)

	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	rule.color = Color(SpiderTheme.BLOOD_BRIGHT.r, SpiderTheme.BLOOD_BRIGHT.g, SpiderTheme.BLOOD_BRIGHT.b, 0.35)
	col.add_child(rule)

	_first_button = _add_button(col, "Fortsätt", resume)
	_add_button(col, "Inställningar", _open_options)
	_add_button(col, "Huvudmeny", _main_menu)
	_add_button(col, "Avsluta spelet", _quit)

	var hint := Label.new()
	hint.text = "Escape · fortsätt"
	SpiderTheme.style_subtitle(hint)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)

	var decor := PauseMenuDecorScript.new()
	decor.name = "PauseDecor"
	decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor.z_index = 4
	_panel.add_child(decor)
	_panel.resized.connect(_sync_pause_decor.bind(decor))
	call_deferred("_sync_pause_decor", decor)


func _sync_pause_decor(decor: Control) -> void:
	if not is_instance_valid(decor) or not is_instance_valid(_panel):
		return
	decor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	decor.offset_left = -14.0
	decor.offset_top = -14.0
	decor.offset_right = 14.0
	decor.offset_bottom = 14.0


func _add_dangling_spider(pivot: Vector2, thread_length: float) -> void:
	var spider := DanglingSpiderScript.new()
	spider.pivot_normalized = pivot
	spider.thread_length = thread_length
	spider.set_anchors_preset(Control.PRESET_FULL_RECT)
	spider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(spider)


func _panel_style() -> StyleBox:
	var filled := FantasyBorderLibrary.panel_filled_style(Color(0.06, 0.05, 0.09, 0.97))
	filled.modulate_color = Color(0.92, 0.88, 0.95, 1.0)
	return filled


func _add_button(parent: Container, text: String, cb: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 46.0
	button.pressed.connect(cb)
	button.add_theme_stylebox_override("normal", FantasyBorderLibrary.button_style(false))
	button.add_theme_stylebox_override("hover", FantasyBorderLibrary.button_style(true))
	button.add_theme_stylebox_override("pressed", FantasyBorderLibrary.button_style(false, true))
	button.add_theme_stylebox_override("focus", FantasyBorderLibrary.button_style(true))
	button.add_theme_font_override("font", GuiFontLibraryScript.semibold())
	button.add_theme_font_size_override("font_size", GuiFontLibraryScript.FONT_BUTTON)
	button.add_theme_color_override("font_color", SpiderTheme.BONE)
	button.add_theme_color_override("font_hover_color", SpiderTheme.BLOOD_BRIGHT)
	button.add_theme_color_override("font_pressed_color", SpiderTheme.VENOM)
	parent.add_child(button)
	return button


func _open_options() -> void:
	_focus_return = get_viewport().gui_get_focus_owner()
	if _options == null:
		_options = OptionsMenuUI.new()
		_options.theme_data = theme_data
		_options.close_requested.connect(_close_options)
		add_child(_options)
		SpiderTheme.apply_to(_options)
	_options.visible = true
	_options.focus_default()
	_panel.visible = false