class_name HudClockUI
extends PanelContainer

const GuiFontLibraryScript = preload("res://scripts/ui/gui_font_library.gd")
const GameplayHudThemeScript = preload("res://scripts/ui/gameplay_hud_theme.gd")

var _time_label: Label
var _tick := 0.0


func _ready() -> void:
	_build()
	GameplayHudThemeScript.apply_panel(self)
	_refresh()


func _process(delta: float) -> void:
	_tick += delta
	if _tick < 1.0:
		return
	_tick = 0.0
	_refresh()


func _build() -> void:
	name = "HudClock"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 28
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	anchor_left = 0.0
	anchor_right = 0.0
	offset_left = 16.0
	offset_right = 196.0
	offset_top = 12.0
	offset_bottom = 56.0
	custom_minimum_size = Vector2(180, 44)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)

	var caption := Label.new()
	caption.text = "KOLONITID"
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GameplayHudThemeScript.style_muted(caption)
	row.add_child(caption)

	_time_label = Label.new()
	_time_label.text = "00:00"
	_time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GameplayHudThemeScript.style_body(_time_label)
	row.add_child(_time_label)


func _refresh() -> void:
	if _time_label == null:
		return
	var dt := Time.get_datetime_dict_from_system()
	_time_label.text = "%02d:%02d" % [dt.hour, dt.minute]