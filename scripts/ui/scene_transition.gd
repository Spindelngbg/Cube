extends Node

const LAYER := 100

var _layer: CanvasLayer
var _overlay: ColorRect
var _vignette: ColorRect
var _title: Label
var _subtitle: Label
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


func is_busy() -> bool:
	return _busy


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