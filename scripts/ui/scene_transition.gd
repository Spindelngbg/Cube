extends Node

const LAYER := 100

var _layer: CanvasLayer
var _overlay: ColorRect
var _vignette: ColorRect
var _title: Label
var _subtitle: Label
var _loading_root: Control
var _loading_panel: PanelContainer
var _loading_label: Label
var _loading_subtitle: Label
var _loading_dots_timer := 0.0
var _loading_dots_phase := 0
var _loading_visible := false
var _busy := false


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = LAYER
	add_child(_layer)

	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color(0, 0, 0, 1)
	_layer.add_child(_overlay)

	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.color = Color(0, 0, 0, 0)
	_layer.add_child(_vignette)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title.offset_top = 180.0
	_title.offset_left = -400.0
	_title.offset_right = 400.0
	_title.offset_bottom = 260.0
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", Color(0.95, 0.9, 0.78))
	_title.modulate.a = 0.0
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_title)

	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_subtitle.offset_top = 270.0
	_subtitle.offset_left = -360.0
	_subtitle.offset_right = 360.0
	_subtitle.offset_bottom = 360.0
	_subtitle.add_theme_font_size_override("font_size", 18)
	_subtitle.add_theme_color_override("font_color", Color(0.78, 0.72, 0.62, 0.9))
	_subtitle.modulate.a = 0.0
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_subtitle)

	_overlay.color.a = 0.0
	_build_loading_overlay()


func _build_loading_overlay() -> void:
	_loading_root = Control.new()
	_loading_root.name = "LoadingOverlay"
	_loading_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_loading_root.visible = false
	_layer.add_child(_loading_root)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.03, 0.06, 0.82)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_root.add_child(backdrop)

	_loading_panel = PanelContainer.new()
	_loading_panel.set_anchors_preset(Control.PRESET_CENTER)
	_loading_panel.offset_left = -320.0
	_loading_panel.offset_right = 320.0
	_loading_panel.offset_top = -120.0
	_loading_panel.offset_bottom = 120.0
	_loading_panel.custom_minimum_size = Vector2(640, 240)
	_loading_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SpiderTheme.apply_to(_loading_panel)
	_loading_root.add_child(_loading_panel)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 18)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_loading_panel.add_child(col)

	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, 12)
	col.add_child(pad)

	_loading_label = Label.new()
	_loading_label.text = "Laddar"
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	SpiderTheme.style_title(_loading_label, 64)
	_loading_label.add_theme_color_override("font_outline_color", Color(0.04, 0.05, 0.1, 0.95))
	_loading_label.add_theme_constant_override("outline_size", 10)
	col.add_child(_loading_label)

	_loading_subtitle = Label.new()
	_loading_subtitle.text = "Bygger koloni och värld..."
	_loading_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	SpiderTheme.style_subtitle(_loading_subtitle)
	_loading_subtitle.add_theme_font_size_override("font_size", 18)
	col.add_child(_loading_subtitle)


func is_busy() -> bool:
	return _busy


func is_loading() -> bool:
	return _loading_visible


func show_loading(message: String = "Laddar", subtitle: String = "Bygger koloni och värld...") -> void:
	_loading_label.text = message
	if _loading_subtitle:
		_loading_subtitle.text = subtitle
	_loading_dots_phase = 0
	_loading_dots_timer = 0.0
	_loading_root.visible = true
	_loading_root.modulate.a = 0.0
	_loading_visible = true
	var tween := create_tween()
	tween.tween_property(_loading_root, "modulate:a", 1.0, 0.22)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func hide_loading() -> void:
	if not _loading_visible:
		return
	_loading_visible = false
	var tween := create_tween()
	tween.tween_property(_loading_root, "modulate:a", 0.0, 0.28)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	_loading_root.visible = false


func _process(delta: float) -> void:
	if not _loading_visible:
		return
	_loading_dots_timer += delta
	if _loading_dots_timer < 0.42:
		return
	_loading_dots_timer = 0.0
	_loading_dots_phase = (_loading_dots_phase + 1) % 4
	_loading_label.text = "Laddar" + ".".repeat(_loading_dots_phase)


func fade_in(duration: float = 0.9, from_color: Color = Color.BLACK) -> void:
	_overlay.color = from_color
	_overlay.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished


func fade_out(duration: float = 0.7, to_color: Color = Color.BLACK) -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "color", Color(to_color.r, to_color.g, to_color.b, 1.0), duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished


func fade_in_from_white(duration: float = 1.2) -> void:
	await fade_in(duration, Color(1, 0.98, 0.92))


func white_flash(duration: float = 0.35) -> void:
	_overlay.color = Color(1, 0.97, 0.88, 0.0)
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 0.95, duration * 0.35)
	tween.tween_property(_overlay, "color:a", 0.0, duration * 0.65)
	await tween.finished


func change_scene(path: String, fade_out_sec: float = 0.6, fade_in_sec: float = 0.9, out_color: Color = Color.BLACK) -> void:
	if _busy:
		return
	_busy = true
	await fade_out(fade_out_sec, out_color)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await fade_in(fade_in_sec)
	_busy = false


func white_flash_then_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	await white_flash(0.5)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await fade_in_from_white(1.4)
	_busy = false


func set_vignette(strength: float) -> void:
	_vignette.color = Color(0, 0, 0, clampf(strength, 0.0, 0.65))


func pulse_vignette(strength: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_method(set_vignette, 0.0, strength, duration * 0.45)
	tween.tween_method(set_vignette, strength, 0.0, duration * 0.55)


func show_arrival_title(title_text: String, subtitle_text: String, hold_sec: float = 3.5) -> void:
	_title.text = title_text
	_subtitle.text = subtitle_text
	_title.modulate.a = 0.0
	_subtitle.modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.tween_property(_title, "modulate:a", 1.0, 1.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_subtitle, "modulate:a", 1.0, 1.4).set_delay(0.35).set_trans(Tween.TRANS_SINE)
	await tween.finished
	await get_tree().create_timer(hold_sec).timeout

	var fade := create_tween().set_parallel(true)
	fade.tween_property(_title, "modulate:a", 0.0, 1.2)
	fade.tween_property(_subtitle, "modulate:a", 0.0, 1.0)
	await fade.finished