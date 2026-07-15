class_name FantasyBorderLibrary
extends RefCounted

const BASE := "res://assets/ui/fantasy-borders/PNG/Default/"
const SLICE := 16
const CONTENT := 14

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


static func panel_style(tint: Color = Color(0.82, 0.38, 0.42, 0.95)) -> StyleBoxTexture:
	return style_from_texture(
		texture("Transparent border", "panel-transparent-border-008"),
		tint,
		false,
		20
	)


static func panel_filled_style(tint: Color = Color(0.42, 0.2, 0.24, 0.96)) -> StyleBoxTexture:
	return style_from_texture(texture("Panel", "panel-012"), tint, true, 12)


static func button_style(hover: bool = false, pressed: bool = false) -> StyleBoxTexture:
	if pressed:
		return style_from_texture(
			texture("Panel", "panel-018"),
			Color(0.55, 0.18, 0.22, 1.0),
			true,
			10
		)
	if hover:
		return style_from_texture(
			texture("Panel", "panel-014"),
			Color(0.48, 0.22, 0.26, 1.0),
			true,
			10
		)
	return style_from_texture(
		texture("Panel", "panel-010"),
		Color(0.34, 0.16, 0.19, 0.98),
		true,
		10
	)


static func input_style(focused: bool = false) -> StyleBoxTexture:
	var tint := Color(0.5, 0.24, 0.28, 0.98) if focused else Color(0.28, 0.14, 0.17, 0.95)
	return style_from_texture(
		texture("Transparent border", "panel-transparent-border-004"),
		tint,
		false,
		12
	)


static func tab_style(active: bool = false) -> StyleBoxTexture:
	if active:
		return style_from_texture(
			texture("Border", "panel-border-006"),
			Color(0.88, 0.32, 0.36, 1.0),
			false,
			8
		)
	return style_from_texture(
		texture("Border", "panel-border-002"),
		Color(0.45, 0.4, 0.44, 0.65),
		false,
		8
	)


static func row_style(selected: bool = false) -> StyleBoxTexture:
	if selected:
		return style_from_texture(
			texture("Border", "panel-border-010"),
			Color(0.9, 0.35, 0.38, 0.95),
			false,
			10
		)
	return style_from_texture(
		texture("Border", "panel-border-004"),
		Color(0.55, 0.48, 0.52, 0.75),
		false,
		10
	)


static func hud_style() -> StyleBoxTexture:
	return style_from_texture(
		texture("Transparent border", "panel-transparent-border-012"),
		Color(0.78, 0.34, 0.38, 0.92),
		false,
		12
	)