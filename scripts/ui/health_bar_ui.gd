class_name HealthBarUI
extends PanelContainer

var _hp_label: Label
var _bonus_label: Label
var _bar: ProgressBar


func _ready() -> void:
	_build()
	SpiderTheme.apply_to(self)
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
	offset_left = -190.0
	offset_right = 190.0
	offset_top = 8.0
	offset_bottom = 70.0
	custom_minimum_size = Vector2(380, 62)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 5)
	add_child(col)

	_hp_label = Label.new()
	_hp_label.text = "HP 100 / 100"
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.add_theme_color_override("font_color", SpiderTheme.BONE)
	_hp_label.add_theme_font_size_override("font_size", 16)
	col.add_child(_hp_label)

	_bar = ProgressBar.new()
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.custom_minimum_size = Vector2(360, 20)
	_bar.max_value = 100.0
	_bar.value = 100.0
	_bar.show_percentage = false
	_style_progress_bar()
	col.add_child(_bar)

	_bonus_label = Label.new()
	_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	SpiderTheme.style_subtitle(_bonus_label)
	col.add_child(_bonus_label)


func _style_progress_bar() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.05, 0.08, 0.95)
	bg.set_border_width_all(1)
	bg.border_color = Color(SpiderTheme.BLOOD.r, SpiderTheme.BLOOD.g, SpiderTheme.BLOOD.b, 0.65)
	bg.set_corner_radius_all(5)
	_bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.35, 0.78, 0.38)
	fill.set_corner_radius_all(4)
	_bar.add_theme_stylebox_override("fill", fill)


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
	_bar.value = current
	_hp_label.text = "HP %d / %d" % [int(round(current)), int(round(maximum))]
	var ratio := current / maximum
	var fill := _bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill == null:
		fill = StyleBoxFlat.new()
		_bar.add_theme_stylebox_override("fill", fill)
	if ratio > 0.55:
		fill.bg_color = Color(0.35, 0.78, 0.38)
	elif ratio > 0.25:
		fill.bg_color = Color(0.9, 0.72, 0.2)
	else:
		fill.bg_color = Color(0.9, 0.22, 0.18)
	_refresh_bonus_label()


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