class_name LuxuryTheme
extends RefCounted

const BG_TOP := Color(0.04, 0.04, 0.07)
const BG_BOTTOM := Color(0.1, 0.08, 0.14)
const GOLD := Color(0.82, 0.72, 0.45)
const GOLD_BRIGHT := Color(0.95, 0.86, 0.55)
const CREAM := Color(0.94, 0.91, 0.86)
const MUTED := Color(0.58, 0.56, 0.62)
const PANEL_BG := Color(0.08, 0.08, 0.11, 0.92)
const INPUT_BG := Color(0.05, 0.05, 0.08, 0.95)


static func apply_to(root: Control) -> void:
	var theme := Theme.new()
	theme.set_stylebox("panel", "PanelContainer", _panel_style())
	theme.set_stylebox("normal", "Button", _button_style(false))
	theme.set_stylebox("hover", "Button", _button_style(true))
	theme.set_stylebox("pressed", "Button", _button_pressed_style())
	theme.set_stylebox("disabled", "Button", _button_disabled_style())
	theme.set_stylebox("normal", "LineEdit", _input_style(false))
	theme.set_stylebox("focus", "LineEdit", _input_style(true))
	theme.set_color("font_color", "Label", CREAM)
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_color("font_color", "LineEdit", CREAM)
	theme.set_color("font_color", "Button", CREAM)
	theme.set_color("font_hover_color", "Button", GOLD_BRIGHT)
	theme.set_color("font_disabled_color", "Button", MUTED)
	theme.set_font_size("font_size", "Label", 14)
	theme.set_font_size("font_size", "Button", 15)
	theme.set_font_size("font_size", "LineEdit", 15)
	root.theme = theme


static func style_title(label: Label, size: int = 52) -> void:
	label.add_theme_color_override("font_color", GOLD_BRIGHT)
	label.add_theme_font_size_override("font_size", size)


static func style_subtitle(label: Label) -> void:
	label.add_theme_color_override("font_color", MUTED)
	label.add_theme_font_size_override("font_size", 13)


static func style_status(label: Label) -> void:
	label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.55))
	label.add_theme_font_size_override("font_size", 12)


static func style_tab_button(button: Button, active: bool) -> void:
	if active:
		button.add_theme_color_override("font_color", GOLD_BRIGHT)
		button.add_theme_stylebox_override("normal", _tab_active_style())
	else:
		button.add_theme_color_override("font_color", MUTED)
		button.add_theme_stylebox_override("normal", _tab_inactive_style())
	button.add_theme_stylebox_override("hover", _tab_hover_style())
	button.add_theme_stylebox_override("pressed", _tab_active_style())
	button.flat = false


static func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 24
	style.shadow_offset = Vector2(0, 8)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	return style


static func _button_style(hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.13, 0.18, 0.95) if not hover else Color(0.2, 0.17, 0.24, 0.98)
	style.border_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.55 if hover else 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


static func _button_pressed_style() -> StyleBoxFlat:
	var style := _button_style(true)
	style.bg_color = Color(0.24, 0.2, 0.28)
	return style


static func _button_disabled_style() -> StyleBoxFlat:
	var style := _button_style(false)
	style.bg_color = Color(0.1, 0.1, 0.12, 0.6)
	style.border_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.12)
	return style


static func _input_style(focused: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = INPUT_BG
	style.border_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.7 if focused else 0.22)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


static func _tab_inactive_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_corner_radius_all(8)
	return style


static func _tab_active_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.12)
	style.border_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style


static func _tab_hover_style() -> StyleBoxFlat:
	var style := _tab_active_style()
	style.bg_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.08)
	return style