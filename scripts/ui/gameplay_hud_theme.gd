class_name GameplayHudTheme
extends RefCounted

const GuiFontLibraryScript = preload("res://scripts/ui/gui_font_library.gd")

const ROOT_BLUE := "res://assets/ui/kenney-sci-fi/PNG/Blue/Default/"
const ROOT_GREY := "res://assets/ui/kenney-sci-fi/PNG/Grey/Default/"
const ROOT_EXTRA := "res://assets/ui/kenney-sci-fi/PNG/Extra/Default/"

const SLICE := 14
const CONTENT := 12

const TEXT := Color(0.84, 0.93, 0.98)
const TEXT_ACCENT := Color(0.48, 0.9, 1.0)
const TEXT_MUTED := Color(0.45, 0.6, 0.72)
const TEXT_WARN := Color(1.0, 0.82, 0.42)
const TEXT_DANGER := Color(1.0, 0.55, 0.5)

static var _cache: Dictionary = {}


static func crosshair_texture() -> Texture2D:
	return _load(ROOT_EXTRA + "crosshair_c.png")


static func apply_panel(root: Control) -> void:
	root.add_theme_stylebox_override("panel", panel_style())


static func panel_style() -> StyleBoxTexture:
	# Panels ligger under Extra/, inte Blue/Default i denna Kenney-pack.
	return _texture_style(ROOT_EXTRA + "panel_glass.png", Color(0.72, 0.9, 1.0, 0.95), true, CONTENT)


static func compact_hp_panel_style() -> StyleBoxTexture:
	# Liten HP-mätare: tunn gråblå padding runt innehållet.
	return _texture_style(ROOT_EXTRA + "panel_glass.png", Color(0.72, 0.9, 1.0, 0.92), true, 6)


static func hint_panel_style() -> StyleBoxTexture:
	return _texture_style(ROOT_EXTRA + "panel_rectangle.png", Color(0.68, 0.86, 0.98, 0.9), true, 10)


static func bar_track_style() -> StyleBoxTexture:
	return _texture_style(ROOT_GREY + "bar_square_small_m.png", Color.WHITE, true, 4)


static func wrap_label_in_panel(label: Label) -> PanelContainer:
	var parent := label.get_parent()
	var pos := label.position
	var size := label.size
	var idx := label.get_index() if parent else -1

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", hint_panel_style())
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


static func style_title(label: Label, size: int = GuiFontLibraryScript.FONT_BODY) -> void:
	label.add_theme_font_override("font", GuiFontLibraryScript.semibold())
	label.add_theme_color_override("font_color", TEXT_ACCENT)
	label.add_theme_font_size_override("font_size", size)


static func style_body(label: Label, size: int = GuiFontLibraryScript.FONT_BODY) -> void:
	label.add_theme_font_override("font", GuiFontLibraryScript.semibold())
	label.add_theme_color_override("font_color", TEXT)
	label.add_theme_font_size_override("font_size", size)


static func style_status(label: Label) -> void:
	label.add_theme_font_override("font", GuiFontLibraryScript.regular())
	label.add_theme_color_override("font_color", Color(TEXT_ACCENT.r, TEXT_ACCENT.g, TEXT_ACCENT.b, 0.88))
	label.add_theme_font_size_override("font_size", GuiFontLibraryScript.FONT_STATUS)


static func style_muted(label: Label) -> void:
	label.add_theme_font_override("font", GuiFontLibraryScript.regular())
	label.add_theme_color_override("font_color", TEXT_MUTED)
	label.add_theme_font_size_override("font_size", GuiFontLibraryScript.FONT_SUBTITLE)


static func hp_text_color(ratio: float) -> Color:
	if ratio > 0.55:
		return TEXT
	if ratio > 0.25:
		return TEXT_WARN
	return TEXT_DANGER


static func hp_fill_style(ratio: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	if ratio > 0.55:
		style.bg_color = Color(0.16, 0.78, 0.58, 0.95)
		style.border_color = Color(0.42, 1.0, 0.78, 0.55)
	elif ratio > 0.25:
		style.bg_color = Color(0.92, 0.68, 0.14, 0.95)
		style.border_color = Color(1.0, 0.84, 0.35, 0.55)
	else:
		style.bg_color = Color(0.9, 0.22, 0.24, 0.95)
		style.border_color = Color(1.0, 0.45, 0.42, 0.55)
	return style


static func _load(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		_cache[path] = tex
		return tex
	push_warning("Gameplay HUD texture not found: %s" % path)
	return null


static func _texture_style(
	path: String,
	tint: Color,
	draw_center: bool,
	content: int
) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _load(path)
	style.modulate_color = tint
	style.draw_center = draw_center
	style.texture_margin_left = SLICE
	style.texture_margin_top = SLICE
	style.texture_margin_right = SLICE
	style.texture_margin_bottom = SLICE
	style.content_margin_left = content
	style.content_margin_right = content
	style.content_margin_top = content
	style.content_margin_bottom = content
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return style