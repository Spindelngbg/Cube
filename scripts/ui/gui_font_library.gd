class_name GuiFontLibrary
extends RefCounted

const REGULAR_PATH := "res://assets/fonts/Cinzel-Regular.ttf"
const SEMIBOLD_PATH := "res://assets/fonts/Cinzel-SemiBold.ttf"

const FONT_BODY := 18
const FONT_BUTTON := 18
const FONT_INPUT := 18
const FONT_SUBTITLE := 16
const FONT_STATUS := 14
const FONT_SECTION := 13
const FONT_SMALL := 14
const FONT_MAP := 13
const FONT_TITLE_DEFAULT := 56
const DEFAULT_TEXT_COLOR := Color(0.9, 0.86, 0.82)

static var _regular: Font
static var _semibold: Font
static var _input: Font
static var _fallback: Font
static var _warned_missing := false


static func regular() -> Font:
	if _regular != null:
		return _regular
	_regular = _load_font(REGULAR_PATH, 400)
	return _regular


static func semibold() -> Font:
	if _semibold != null:
		return _semibold
	_semibold = _load_font(SEMIBOLD_PATH, 600)
	if _semibold == null:
		_semibold = regular()
	return _semibold


## Läsbar UI-font för inmatning — Cinzel har bara versaler/small caps.
static func input() -> Font:
	if _input != null:
		return _input
	_input = _system_font(400)
	return _input


static func apply_to_theme(theme: Theme) -> void:
	if theme == null:
		return
	var body := regular()
	var title := semibold()
	if body == null:
		return
	for control_type in ["Label", "Button", "RichTextLabel", "ItemList", "Tree"]:
		theme.set_font("font", control_type, body)
	var input_font := input()
	for control_type in ["LineEdit", "TextEdit"]:
		theme.set_font("font", control_type, input_font)
	theme.default_font = body
	theme.set_font_size("font_size", "Label", FONT_BODY)
	theme.set_font_size("font_size", "Button", FONT_BUTTON)
	theme.set_font_size("font_size", "LineEdit", FONT_INPUT)
	theme.set_font("normal_font", "RichTextLabel", body)
	if title != null:
		theme.set_font("bold_font", "RichTextLabel", title)
	theme.set_font_size("normal_font_size", "RichTextLabel", FONT_BODY)


static func apply_to_label3d(label: Label3D, bold: bool = false) -> void:
	if label == null:
		return
	var font := semibold() if bold else regular()
	if font == null:
		return
	label.font = font
	if label.outline_size <= 0:
		label.outline_size = 4
		label.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)


static func fix_label3d_tree(root: Node) -> void:
	if root == null:
		return
	if root is Label3D:
		apply_to_label3d(root as Label3D)
	for child in root.get_children():
		fix_label3d_tree(child)


static func draw(
	canvas: Control,
	pos: Vector2,
	text: String,
	size: int = FONT_BODY,
	color: Color = DEFAULT_TEXT_COLOR,
	width: float = -1.0,
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> void:
	if text.is_empty() or canvas == null:
		return
	var font := regular()
	if font == null:
		return
	canvas.draw_string(font, pos, text, alignment, width, size, color)


static func _load_font(path: String, weight: int) -> Font:
	if not _font_file_is_valid(path):
		_log_missing_once("Ogiltig eller saknad font: %s" % path)
		return _system_font(weight)
	if not ResourceLoader.exists(path):
		_log_missing_once("Font saknas: %s" % path)
		return _system_font(weight)
	var resource := ResourceLoader.load(path)
	if resource is Font and _font_renders(resource as Font):
		return resource as Font
	_log_missing_once("Kunde inte rendera font: %s" % path)
	return _system_font(weight)


static func _font_file_is_valid(path: String) -> bool:
	if path.is_empty():
		return false
	var file_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(file_path):
		return false
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return false
	var header := file.get_buffer(4)
	file.close()
	if header.size() < 4:
		return false
	if header[0] == 0 and header[1] == 1 and header[2] == 0 and header[3] == 0:
		return true
	var tag := header.get_string_from_ascii()
	return tag == "OTTO" or tag == "ttcf"


static func _font_renders(font: Font) -> bool:
	if font == null:
		return false
	var size := font.get_string_size("Ag", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	return size.x > 0.5 and size.y > 0.5


static func _system_font(weight: int) -> Font:
	if _fallback != null and weight == 400:
		return _fallback
	var system_font := SystemFont.new()
	system_font.font_names = PackedStringArray(["Segoe UI", "Arial", "Noto Sans", "sans-serif"])
	system_font.font_weight = weight
	if weight == 400:
		_fallback = system_font
	return system_font


static func _log_missing_once(message: String) -> void:
	if _warned_missing:
		return
	_warned_missing = true
	push_warning("GuiFontLibrary: %s — använder systemfont." % message)