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


static func regular() -> Font:
	if _regular == null:
		_regular = load(REGULAR_PATH) as Font
	return _regular


static func semibold() -> Font:
	if _semibold == null:
		_semibold = load(SEMIBOLD_PATH) as Font
	return _semibold


static func apply_to_theme(theme: Theme) -> void:
	var body := regular()
	var title := semibold()
	for control_type in ["Label", "Button", "LineEdit", "RichTextLabel", "ItemList", "Tree", "TextEdit"]:
		theme.set_font("font", control_type, body)
	theme.default_font = body
	theme.set_font_size("font_size", "Label", FONT_BODY)
	theme.set_font_size("font_size", "Button", FONT_BUTTON)
	theme.set_font_size("font_size", "LineEdit", FONT_INPUT)
	theme.set_font("normal_font", "RichTextLabel", body)
	theme.set_font("bold_font", "RichTextLabel", title)
	theme.set_font_size("normal_font_size", "RichTextLabel", FONT_BODY)


static func draw(
	canvas: Control,
	pos: Vector2,
	text: String,
	size: int = FONT_BODY,
	color: Color = DEFAULT_TEXT_COLOR,
	width: float = -1.0,
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> void:
	canvas.draw_string(regular(), pos, text, alignment, width, size, color)