class_name SpiderTheme
extends RefCounted

const GuiFontLibraryScript = preload("res://scripts/ui/gui_font_library.gd")

const BG_TOP := Color(0.04, 0.03, 0.06)
const BG_BOTTOM := Color(0.1, 0.05, 0.09)
const CHITIN := Color(0.12, 0.1, 0.14, 0.94)
const WEB := Color(0.82, 0.8, 0.88, 0.09)
const BLOOD := Color(0.77, 0.12, 0.22)
const BLOOD_BRIGHT := Color(0.95, 0.22, 0.28)
const UI_BORDER := Color(0.24, 0.26, 0.32, 0.7)
const UI_BORDER_FOCUS := Color(0.42, 0.44, 0.52, 0.88)
const UI_BORDER_MUTED := Color(0.14, 0.15, 0.19, 0.55)
const VENOM := Color(0.45, 0.72, 0.28)
const BONE := Color(0.9, 0.86, 0.82)
const MUTED := Color(0.55, 0.5, 0.56)
const INPUT_BG := Color(0.06, 0.05, 0.08, 0.96)


static func hud_panel_style(alpha: float = 0.78) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, alpha)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = UI_BORDER_MUTED
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.anti_aliasing = true
	return style


## Snygg fantasy-GUI — tunna kanter, inte platt HUD.
static func apply_gui(root: Control) -> void:
	apply_to(root)


static func apply_hud_clean(root: Control) -> void:
	apply_gui(root)


static func apply_to(root: Control) -> void:
	var theme := Theme.new()
	theme.set_stylebox("panel", "PanelContainer", FantasyBorderLibrary.panel_style())
	theme.set_stylebox("normal", "Button", FantasyBorderLibrary.button_style(false))
	theme.set_stylebox("hover", "Button", FantasyBorderLibrary.button_style(true))
	theme.set_stylebox("pressed", "Button", FantasyBorderLibrary.button_style(false, true))
	theme.set_stylebox("disabled", "Button", _button_disabled_style())
	theme.set_stylebox("normal", "LineEdit", FantasyBorderLibrary.input_style(false))
	theme.set_stylebox("focus", "LineEdit", FantasyBorderLibrary.input_style(true))
	theme.set_stylebox("normal", "HSlider", _slider_style())
	theme.set_stylebox("grabber_area", "HSlider", _slider_area_style())
	theme.set_stylebox("grabber_area_highlight", "HSlider", _slider_area_style())
	theme.set_stylebox("grabber", "HSlider", _slider_grabber_style())
	theme.set_color("font_color", "Label", BONE)
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_color("font_color", "LineEdit", BONE)
	theme.set_color("font_color", "Button", BONE)
	theme.set_color("font_hover_color", "Button", BLOOD_BRIGHT)
	theme.set_color("font_disabled_color", "Button", MUTED)
	GuiFontLibraryScript.apply_to_theme(theme)
	root.theme = theme


static func style_title(label: Label, size: int = GuiFontLibraryScript.FONT_TITLE_DEFAULT) -> void:
	label.add_theme_font_override("font", GuiFontLibraryScript.semibold())
	label.add_theme_color_override("font_color", BLOOD_BRIGHT)
	label.add_theme_font_size_override("font_size", size)


static func style_subtitle(label: Label) -> void:
	label.add_theme_font_override("font", GuiFontLibraryScript.regular())
	label.add_theme_color_override("font_color", Color(BONE.r, BONE.g, BONE.b, 0.55))
	label.add_theme_font_size_override("font_size", GuiFontLibraryScript.FONT_SUBTITLE)


static func style_status(label: Label) -> void:
	label.add_theme_font_override("font", GuiFontLibraryScript.regular())
	label.add_theme_color_override("font_color", Color(VENOM.r, VENOM.g, VENOM.b, 0.85))
	label.add_theme_font_size_override("font_size", GuiFontLibraryScript.FONT_STATUS)


static func style_section(label: Label) -> void:
	label.add_theme_font_override("font", GuiFontLibraryScript.semibold())
	label.add_theme_color_override("font_color", BLOOD)
	label.add_theme_font_size_override("font_size", GuiFontLibraryScript.FONT_SECTION)


static func style_tab_button(button: Button, active: bool) -> void:
	button.add_theme_font_override("font", GuiFontLibraryScript.semibold() if active else GuiFontLibraryScript.regular())
	button.add_theme_font_size_override("font_size", GuiFontLibraryScript.FONT_BUTTON)
	if active:
		button.add_theme_color_override("font_color", BLOOD_BRIGHT)
		button.add_theme_stylebox_override("normal", FantasyBorderLibrary.tab_style(true))
	else:
		button.add_theme_color_override("font_color", MUTED)
		button.add_theme_stylebox_override("normal", FantasyBorderLibrary.tab_style(false))
	button.add_theme_stylebox_override("hover", FantasyBorderLibrary.tab_style(true))
	button.add_theme_stylebox_override("pressed", FantasyBorderLibrary.tab_style(true))
	button.flat = false


static func wrap_label_in_panel(label: Label, style: StyleBoxTexture = null) -> PanelContainer:
	var parent := label.get_parent()
	var pos := label.position
	var size := label.size
	var idx := label.get_index() if parent else -1

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style if style else FantasyBorderLibrary.hud_style())
	if parent:
		parent.remove_child(label)
	panel.add_child(label)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if parent:
		parent.add_child(panel)
		if idx >= 0:
			parent.move_child(panel, idx)
		panel.position = pos
		panel.size = size
	return panel


static func _hud_button_style(hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.16, 0.92) if hover else Color(0.08, 0.09, 0.12, 0.82)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


static func _hud_input_style(focused: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.08, 0.11, 0.95)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = UI_BORDER_FOCUS if focused else UI_BORDER_MUTED
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


static func _button_disabled_style() -> StyleBoxTexture:
	var style := FantasyBorderLibrary.button_style(false)
	style.modulate_color = Color(0.2, 0.16, 0.18, 0.55)
	return style


static func _slider_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.1, 0.8)
	style.set_corner_radius_all(4)
	return style


static func _slider_area_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(BLOOD.r, BLOOD.g, BLOOD.b, 0.25)
	style.set_corner_radius_all(4)
	return style


static func _slider_grabber_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BLOOD_BRIGHT
	style.set_corner_radius_all(6)
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style