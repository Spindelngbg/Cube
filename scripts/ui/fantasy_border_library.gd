class_name FantasyBorderLibrary
extends RefCounted

const BASE := "res://assets/ui/fantasy-borders/PNG/Default/"
const SLICE := 8
const CONTENT := 10

static var _cache: Dictionary = {}


static func texture(category: String, file_name: String) -> Texture2D:
	var key := "%s/%s" % [category, file_name]
	if _cache.has(key):
		return _cache[key]
	var folder := BASE + category + "/"
	var path := folder + file_name
	if not file_name.ends_with(".png"):
		path += ".png"
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		_cache[key] = tex
		return tex
	push_warning("Fantasy border texture not found: %s" % path)
	return null


static func style_from_texture(
	tex: Texture2D,
	tint: Color = Color.WHITE,
	draw_center: bool = true,
	content: int = CONTENT
) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = tex
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


static func panel_style(tint: Color = SpiderTheme.UI_BORDER) -> StyleBoxTexture:
	return style_from_texture(
		texture("Transparent border", "panel-transparent-border-008"),
		tint,
		false,
		12
	)


static func panel_filled_style(tint: Color = Color(0.14, 0.15, 0.19, 0.96)) -> StyleBoxTexture:
	return style_from_texture(texture("Panel", "panel-012"), tint, true, 10)


static func button_style(hover: bool = false, pressed: bool = false) -> StyleBoxTexture:
	if pressed:
		return style_from_texture(
			texture("Panel", "panel-018"),
			Color(0.2, 0.21, 0.26, 1.0),
			true,
			8
		)
	if hover:
		return style_from_texture(
			texture("Panel", "panel-014"),
			Color(0.18, 0.19, 0.24, 1.0),
			true,
			8
		)
	return style_from_texture(
		texture("Panel", "panel-010"),
		Color(0.12, 0.13, 0.17, 0.98),
		true,
		8
	)


static func input_style(focused: bool = false) -> StyleBoxTexture:
	var tint := SpiderTheme.UI_BORDER_FOCUS if focused else SpiderTheme.UI_BORDER_MUTED
	return style_from_texture(
		texture("Transparent border", "panel-transparent-border-004"),
		tint,
		false,
		10
	)


static func tab_style(active: bool = false) -> StyleBoxTexture:
	if active:
		return style_from_texture(
			texture("Border", "panel-border-006"),
			SpiderTheme.UI_BORDER_FOCUS,
			false,
			6
		)
	return style_from_texture(
		texture("Border", "panel-border-002"),
		SpiderTheme.UI_BORDER_MUTED,
		false,
		6
	)


static func row_style(selected: bool = false) -> StyleBoxTexture:
	if selected:
		return style_from_texture(
			texture("Border", "panel-border-010"),
			SpiderTheme.UI_BORDER_FOCUS,
			false,
			8
		)
	return style_from_texture(
		texture("Border", "panel-border-004"),
		SpiderTheme.UI_BORDER,
		false,
		8
	)


static func hud_style() -> StyleBoxTexture:
	return style_from_texture(
		texture("Transparent border", "panel-transparent-border-012"),
		SpiderTheme.UI_BORDER,
		false,
		10
	)


static func overlay_panel_style(content: int = 8) -> StyleBoxTexture:
	return style_from_texture(
		texture("Transparent border", "panel-transparent-border-008"),
		SpiderTheme.UI_BORDER,
		false,
		content
	)


static func filled_panel_style(
	tint: Color = Color(0.07, 0.08, 0.12, 0.93),
	content: int = 14
) -> StyleBoxTexture:
	return style_from_texture(texture("Panel", "panel-014"), tint, true, content)