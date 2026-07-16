class_name HealthBarUI
extends PanelContainer

const GuiFontLibraryScript = preload("res://scripts/ui/gui_font_library.gd")
const GameplayHudThemeScript = preload("res://scripts/ui/gameplay_hud_theme.gd")

const TWEEN_SEC := 0.22

var _hp_label: Label
var _bonus_label: Label
var _bar: ProgressBar
var _fill_style: StyleBoxFlat
var _value_tween: Tween
var _displayed_value := 100.0


func _ready() -> void:
	_build()
	GameplayHudThemeScript.apply_panel(self)
	InventoryManager.inventory_changed.connect(_refresh)
	PoisonManager.poison_changed.connect(_on_poison_changed)
	_refresh()


func bind_player(player: Node) -> void:
	if player.has_signal("health_changed"):
		if not player.health_changed.is_connected(_on_health_changed):
			player.health_changed.connect(_on_health_changed)
	if player.has_method("get_health_snapshot"):
		_apply_snapshot(player.get_health_snapshot())


func _build() -> void:
	name = "HealthBar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 30
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -200.0
	offset_right = 200.0
	offset_top = 10.0
	offset_bottom = 78.0
	custom_minimum_size = Vector2(400, 68)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	add_child(col)

	_hp_label = Label.new()
	_hp_label.text = "HP 100 / 100"
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameplayHudThemeScript.style_body(_hp_label)
	col.add_child(_hp_label)

	_bar = ProgressBar.new()
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.custom_minimum_size = Vector2(380, 22)
	_bar.max_value = 100.0
	_bar.value = 100.0
	_bar.show_percentage = false
	_style_progress_bar()
	col.add_child(_bar)

	_bonus_label = Label.new()
	_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameplayHudThemeScript.style_muted(_bonus_label)
	col.add_child(_bonus_label)


func _style_progress_bar() -> void:
	_bar.add_theme_stylebox_override("background", GameplayHudThemeScript.bar_track_style())
	_fill_style = GameplayHudThemeScript.hp_fill_style(1.0)
	_bar.add_theme_stylebox_override("fill", _fill_style)


func _on_health_changed(current: float, maximum: float) -> void:
	_apply_values(current, maximum)


func _apply_snapshot(snapshot: Dictionary) -> void:
	_apply_values(
		float(snapshot.get("current", 0.0)),
		float(snapshot.get("max", 100.0))
	)


func _apply_values(current: float, maximum: float) -> void:
	maximum = maxf(maximum, 1.0)
	current = clampf(current, 0.0, maximum)
	_bar.max_value = maximum
	_hp_label.text = "HP %d / %d" % [int(round(current)), int(round(maximum))]
	var ratio := current / maximum
	_apply_fill_color(ratio)
	if _value_tween != null and _value_tween.is_valid():
		_value_tween.kill()
	if is_inside_tree() and absf(_displayed_value - current) > 0.5:
		_value_tween = create_tween()
		_value_tween.set_ease(Tween.EASE_OUT)
		_value_tween.set_trans(Tween.TRANS_CUBIC)
		_value_tween.tween_method(_set_bar_value, _displayed_value, current, TWEEN_SEC)
	else:
		_set_bar_value(current)
	_refresh_bonus_label()


func _set_bar_value(value: float) -> void:
	_displayed_value = value
	_bar.value = value


func _apply_fill_color(ratio: float) -> void:
	_fill_style = GameplayHudThemeScript.hp_fill_style(ratio)
	_bar.add_theme_stylebox_override("fill", _fill_style)
	_hp_label.add_theme_color_override("font_color", GameplayHudThemeScript.hp_text_color(ratio))


func _refresh() -> void:
	_refresh_bonus_label()


func _on_poison_changed(_active: bool, _severity: float) -> void:
	_refresh_bonus_label()


func _refresh_bonus_label() -> void:
	var lines: PackedStringArray = []
	if PoisonManager.is_poisoned():
		lines.append(PoisonManager.get_status_text())
	var bonus := int(round(InventoryManager.get_hp_bonus_total()))
	if bonus > 0:
		lines.append("+%d HP från inventory" % bonus)
	elif not PoisonManager.is_poisoned():
		lines.append("Inga HP-föremål i inventory")
	_bonus_label.text = "\n".join(lines)