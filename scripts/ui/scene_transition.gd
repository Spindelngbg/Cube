extends Node

const GuiFontLibraryScript = preload("res://scripts/ui/gui_font_library.gd")
const SpawnBriefingCatalogScript = preload("res://scripts/ui/spawn_briefing_catalog.gd")
const ThreadedLoaderScript = preload("res://scripts/loading/threaded_loader.gd")

const LAYER := 128

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
var _briefing_root: Control
var _briefing_scroll: ScrollContainer
var _briefing_body: RichTextLabel
var _briefing_button: Button
var _briefing_loading_label: Label
var _briefing_visible := false
var _briefing_dismissed := false
var _briefing_waiting_dismiss := false
var _briefing_loading_phase := false
var _briefing_loading_title := "Laddar"
var _briefing_loading_subtitle := "Bygger koloni och värld..."
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
	_title.add_theme_font_override("font", GuiFontLibraryScript.semibold())
	_title.add_theme_font_size_override("font_size", 40)
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
	_subtitle.add_theme_font_override("font", GuiFontLibraryScript.regular())
	_subtitle.add_theme_font_size_override("font_size", GuiFontLibraryScript.FONT_BODY)
	_subtitle.add_theme_color_override("font_color", Color(0.78, 0.72, 0.62, 0.9))
	_subtitle.modulate.a = 0.0
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_subtitle)

	_overlay.color.a = 0.0
	_build_loading_overlay()
	_build_spawn_briefing_overlay()


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

	col.add_child(_loading_subtitle)


func is_busy() -> bool:
	return _busy


func is_loading() -> bool:
	return _loading_visible


func is_spawn_briefing_visible() -> bool:
	return _briefing_visible


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
	if not _loading_visible or _loading_root == null or not is_instance_valid(_loading_root):
		_loading_visible = false
		return
	_loading_visible = false
	var tween := create_tween()
	tween.tween_property(_loading_root, "modulate:a", 0.0, 0.28)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	_loading_root.visible = false


func show_spawn_loading_briefing(
	message: String = "Laddar",
	subtitle: String = "Bygger koloni och värld..."
) -> void:
	if _briefing_root == null:
		show_loading(message, subtitle)
		return
	_briefing_dismissed = false
	_briefing_waiting_dismiss = false
	_briefing_loading_phase = true
	_briefing_loading_title = message
	_briefing_loading_subtitle = subtitle
	_loading_dots_phase = 0
	_loading_dots_timer = 0.0
	_briefing_button.visible = false
	if _briefing_loading_label:
		_briefing_loading_label.text = "%s — %s" % [message, subtitle]
		_briefing_loading_label.visible = true
	if _briefing_scroll:
		_briefing_scroll.visible = false
	_briefing_root.visible = true
	_briefing_root.modulate.a = 1.0
	_briefing_visible = true
	_loading_visible = false
	if _loading_root:
		_loading_root.visible = false


func set_spawn_loading_status(message: String, subtitle: String = "") -> void:
	if _briefing_root == null or not _briefing_loading_phase:
		return
	_briefing_loading_title = message
	if subtitle != "":
		_briefing_loading_subtitle = subtitle
	if _briefing_loading_label:
		_briefing_loading_label.text = "%s — %s" % [message, _briefing_loading_subtitle]


func mark_spawn_loading_ready(ready_note: String = "Världen är klar — tryck Fortsätt.") -> void:
	if _briefing_root == null:
		return
	_briefing_loading_phase = false
	_briefing_waiting_dismiss = true
	if _briefing_loading_label:
		_briefing_loading_label.visible = false
	if _briefing_scroll:
		_briefing_scroll.visible = true
	_briefing_button.visible = true


func show_spawn_briefing() -> void:
	if _briefing_root == null:
		return
	_briefing_dismissed = false
	_briefing_waiting_dismiss = true
	_briefing_loading_phase = false
	_briefing_button.visible = true
	if _briefing_loading_label:
		_briefing_loading_label.visible = false
	_briefing_root.visible = true
	_briefing_root.modulate.a = 1.0
	_briefing_visible = true


func dismiss_spawn_briefing() -> void:
	if not _briefing_visible:
		return
	_briefing_dismissed = true


func wait_spawn_briefing_dismissed() -> void:
	while _briefing_waiting_dismiss and not _briefing_dismissed:
		await get_tree().process_frame
	_briefing_waiting_dismiss = false
	_briefing_loading_phase = false
	if _briefing_root == null:
		_briefing_visible = false
		return
	_briefing_visible = false
	var tween := create_tween()
	tween.tween_property(_briefing_root, "modulate:a", 0.0, 0.22)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	_briefing_root.visible = false


func _build_spawn_briefing_overlay() -> void:
	_briefing_root = Control.new()
	_briefing_root.name = "SpawnBriefing"
	_briefing_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_briefing_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_briefing_root.visible = false
	_briefing_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_briefing_root.z_index = 4096
	_layer.add_child(_briefing_root)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(1.0, 1.0, 1.0, 1.0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_briefing_root.add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 36)
	_briefing_root.add_child(margin)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 16)
	margin.add_child(col)

	var title := Label.new()
	title.text = SpawnBriefingCatalogScript.TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", GuiFontLibraryScript.semibold())
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.05, 0.05, 0.08))
	col.add_child(title)

	_briefing_scroll = ScrollContainer.new()
	_briefing_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_briefing_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_briefing_scroll.visible = false
	col.add_child(_briefing_scroll)

	_briefing_body = RichTextLabel.new()
	_briefing_body.bbcode_enabled = false
	_briefing_body.fit_content = true
	_briefing_body.scroll_active = false
	_briefing_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_briefing_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_briefing_body.text = SpawnBriefingCatalogScript.BODY
	_briefing_body.add_theme_font_override("normal_font", GuiFontLibraryScript.regular())
	_briefing_body.add_theme_font_size_override("normal_font_size", 20)
	_briefing_body.add_theme_color_override("default_color", Color(0.08, 0.08, 0.1))
	_briefing_scroll.add_child(_briefing_body)

	_briefing_loading_label = Label.new()
	_briefing_loading_label.text = "Laddar — Bygger koloni och värld..."
	_briefing_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_briefing_loading_label.add_theme_font_override("font", GuiFontLibraryScript.semibold())
	_briefing_loading_label.add_theme_font_size_override("font_size", 22)
	_briefing_loading_label.add_theme_color_override("font_color", Color(0.12, 0.12, 0.16))
	col.add_child(_briefing_loading_label)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(button_row)

	_briefing_button = Button.new()
	_briefing_button.text = "Fortsätt"
	_briefing_button.custom_minimum_size = Vector2(220, 44)
	_briefing_button.visible = false
	_briefing_button.pressed.connect(dismiss_spawn_briefing)
	button_row.add_child(_briefing_button)

	var hint := Label.new()
	hint.text = "E eller Space fungerar också"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", GuiFontLibraryScript.regular())
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.28, 0.28, 0.32))
	col.add_child(hint)

	_briefing_root.gui_input.connect(_on_briefing_gui_input)


func _on_briefing_gui_input(event: InputEvent) -> void:
	if not _briefing_visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
		dismiss_spawn_briefing()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _briefing_waiting_dismiss and not _briefing_dismissed and not _briefing_loading_phase:
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump"):
			dismiss_spawn_briefing()
	if _briefing_loading_phase and _briefing_loading_label:
		_loading_dots_timer += delta
		if _loading_dots_timer >= 0.42:
			_loading_dots_timer = 0.0
			_loading_dots_phase = (_loading_dots_phase + 1) % 4
			_briefing_loading_label.text = "%s%s — %s" % [
				_briefing_loading_title,
				".".repeat(_loading_dots_phase),
				_briefing_loading_subtitle,
			]
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
	await _change_scene_threaded_impl(path)
	await get_tree().process_frame
	await fade_in(fade_in_sec)
	_busy = false


## Ladda scener i bakgrundstrådar medan loading-UI visas (ingen fade).
func change_scene_threaded(
	path: String,
	message: String = "Laddar",
	subtitle: String = "Läser scener i bakgrunden..."
) -> Error:
	if _busy:
		return ERR_BUSY
	_busy = true
	show_loading(message, subtitle)
	var err := await _change_scene_threaded_impl(path)
	await hide_loading()
	_busy = false
	return err


## Starta trådad laddning tidigt (t.ex. under nätverksanslutning).
func begin_threaded_scene_load(path: String) -> void:
	ThreadedLoaderScript.request(path, true)


func await_threaded_scene(path: String) -> PackedScene:
	return await ThreadedLoaderScript.await_packed_scene(self, path, true)


func _change_scene_threaded_impl(path: String) -> Error:
	var scene: PackedScene = await ThreadedLoaderScript.await_packed_scene(self, path, true)
	if scene != null:
		var err := get_tree().change_scene_to_packed(scene)
		if err == OK:
			return OK
	# Fallback om trådad laddning fallerar.
	return get_tree().change_scene_to_file(path)


func white_flash_then_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	await white_flash(0.5)
	await _change_scene_threaded_impl(path)
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