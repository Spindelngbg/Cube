extends Control
class_name SlotUI

const InventoryRuntimeScript = preload("res://addons/modular_inventory_system/inventory_runtime.gd")

signal drag_started(slot_index: int, button: MouseButton, is_right_click: bool)
signal drag_ended(slot_index: int)
signal slot_input_event(event: InputEvent)
signal tooltip_requested(slot_data: SlotData, global_pos: Vector2)
signal tooltip_hidden()

@export_node_path("TextureRect") var icon_path: NodePath = ^"Icon"
@export_node_path("Label") var count_label_path: NodePath = ^"CountLabel"
@export_node_path("TextureRect") var placeholder_path: NodePath = ^"Placeholder"
@export_node_path("Control") var durability_bar_path: NodePath = ^"DurabilityBar"
@export_node_path("ColorRect") var durability_fill_path: NodePath = ^"DurabilityFill"
@export_node_path("Panel") var highlight_path: NodePath = ^"Highlight"
@export_node_path("PanelContainer") var background_panel_path: NodePath = ^"BackgroundColor"

var icon_rect: TextureRect
var count_label: Label
var placeholder: TextureRect
var durability_bar: Control
var durability_fill: ColorRect
var highlight_panel: PanelContainer
var background_panel: PanelContainer
var _name_label: Label

@export var slot_index: int = -1
var _current_slot_data: SlotData = null

@export var enable_tooltip: bool = true
@export var tooltip_delay: float = 0.3
var _tooltip_timer: Timer
var _is_hovering: bool = false

var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_started: bool = false
var _drag_button: MouseButton = MOUSE_BUTTON_NONE
var _is_hotbar_selected: bool = false
const DRAG_THRESHOLD: float = 0.5

func _ready() -> void:
	icon_rect = get_node_or_null(icon_path) as TextureRect
	count_label = get_node_or_null(count_label_path) as Label
	placeholder = get_node_or_null(placeholder_path) as TextureRect
	durability_bar = get_node_or_null(durability_bar_path) as Control
	durability_fill = get_node_or_null(durability_fill_path) as ColorRect
	highlight_panel = get_node_or_null(highlight_path) as PanelContainer
	background_panel = get_node_or_null(background_panel_path) as PanelContainer
	_name_label = Label.new()
	_name_label.name = "NameFallback"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_name_label.offset_left = 4.0
	_name_label.offset_top = 4.0
	_name_label.offset_right = -4.0
	_name_label.offset_bottom = -4.0
	_name_label.add_theme_font_size_override("font_size", 9)
	_name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92))
	_name_label.visible = false
	add_child(_name_label)
	
	if durability_bar:
		durability_bar.visible = false
		
	if enable_tooltip:
		_tooltip_timer = Timer.new()
		_tooltip_timer.one_shot = true
		_tooltip_timer.timeout.connect(_show_tooltip)
		add_child(_tooltip_timer)
		
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
		
	if slot_index >= 0:
		_refresh_visuals()

func _on_mouse_entered() -> void:
	_is_hovering = true
	var drag_drop := InventoryRuntimeScript.drag_drop()
	if drag_drop != null and drag_drop.is_dragging:
		_update_drag_visual()
		
	if enable_tooltip and _current_slot_data and not _current_slot_data.is_empty():
		if _tooltip_timer:
			_tooltip_timer.start(tooltip_delay)

func _on_mouse_exited() -> void:
	_is_hovering = false
	var drag_drop := InventoryRuntimeScript.drag_drop()
	if drag_drop != null and drag_drop.is_dragging:
		_reset_drag_visual()
		
	if _tooltip_timer:
		_tooltip_timer.stop()
	tooltip_hidden.emit()

func _update_drag_visual() -> void:
	var drag_drop := InventoryRuntimeScript.drag_drop()
	if drag_drop == null or not drag_drop.source_data or not drag_drop.source_data.item:
		return
	var inv = get_meta("inventory", null) as Inventory
	var idx = get_meta("slot_index", -1) as int
	if inv and idx >= 0:
		var item = drag_drop.source_data.item
		var drag_amt = drag_drop.drag_amount
		if inv.can_accept_at_slot(item, idx, drag_amt):
			set_drop_valid(true)
		else:
			set_drop_valid(false)

func _reset_drag_visual() -> void:
	if _is_hotbar_selected:
		if highlight_panel:
			highlight_panel.visible = true
			highlight_panel.self_modulate = Color(0.833, 0.833, 0.833, 1.0)
	else:
		if highlight_panel:
			highlight_panel.visible = false

func _gui_input(event: InputEvent) -> void:
	slot_input_event.emit(event)
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				if event.shift_pressed and event.button_index == MOUSE_BUTTON_LEFT:
					var inv = get_meta("inventory", null) as Inventory
					var idx = get_meta("slot_index", -1) as int
					if inv and idx >= 0:
						var ui_state := InventoryRuntimeScript.ui_state()
						var target = ui_state.get_other_inventory(inv) if ui_state else null
						if target:
							InventoryTransfer.transfer(inv, target, idx, 0)
					accept_event()
				else:
					_drag_start_pos = event.global_position
					_drag_started = true
					_drag_button = event.button_index
					accept_event()
			else:
				if event.button_index == _drag_button:
					_drag_started = false
	elif event is InputEventMouseMotion and _drag_started:
		var drag_drop := InventoryRuntimeScript.drag_drop()
		if drag_drop != null and drag_drop.is_dragging:
			return
		if event.global_position.distance_to(_drag_start_pos) > DRAG_THRESHOLD:
			var inv = get_meta("inventory", null) as Inventory
			var idx = get_meta("slot_index", -1) as int
			if inv and idx >= 0 and _current_slot_data and not _current_slot_data.is_empty() and drag_drop != null:
				var is_right = _drag_button == MOUSE_BUTTON_RIGHT
				drag_drop.start_drag(inv, _current_slot_data, idx, _drag_button, is_right)
				_drag_started = false

func _handle_right_click_move() -> void:
	var source_inv = get_meta("inventory", null) as Inventory
	var source_idx = get_meta("slot_index", -1) as int
	if not source_inv or source_idx < 0: return
	
	var ui_state := InventoryRuntimeScript.ui_state()
	var target_inv = ui_state.get_other_inventory(source_inv) if ui_state else null
	if target_inv:
		InventoryTransfer.transfer(source_inv, target_inv, source_idx, 1)

func _show_tooltip() -> void:
	if _is_hovering and _current_slot_data and not _current_slot_data.is_empty():
		tooltip_requested.emit(_current_slot_data, get_global_mouse_position())

func set_slot_data(slot_data: SlotData, index: int) -> void:
	if index != -1:
		slot_index = index
	_current_slot_data = slot_data
	_refresh_visuals()

func _refresh_visuals() -> void:
	var slot_data: SlotData = _get_slot_data_from_meta()
	_current_slot_data = slot_data
	if slot_data == null or slot_data.is_empty():
		if icon_rect:
			icon_rect.texture = null
			icon_rect.visible = false
		if count_label:
			count_label.visible = false
		if durability_bar:
			durability_bar.visible = false
		_update_name_fallback(null, false)
		_reset_slot_background()
		_update_placeholder(true)
		return

	var has_icon := slot_data.item != null and slot_data.item.icon != null
	if icon_rect:
		icon_rect.texture = slot_data.item.icon if has_icon else null
		icon_rect.visible = has_icon

	if count_label:
		count_label.visible = slot_data.count > 1
		count_label.text = str(slot_data.count)

	_update_name_fallback(slot_data.item, has_icon)
	_update_slot_background(slot_data.item)
	_update_durability_display(slot_data)
	_update_placeholder(false)

func _update_placeholder(show: bool) -> void:
	if placeholder:
		placeholder.visible = show


func _update_name_fallback(item, has_icon: bool) -> void:
	if _name_label == null:
		return
	if item == null:
		_name_label.visible = false
		_name_label.text = ""
		return
	_name_label.visible = true
	_name_label.text = _slot_label_for(item, has_icon)


func _slot_label_for(item, _has_icon: bool) -> String:
	var label := str(item.display_name)
	if label.is_empty():
		return "?"
	if label.contains("-"):
		var parts := label.split("-", false)
		if parts.size() >= 2 and not parts[0].is_empty():
			label = parts[0]
	elif label.length() > 12:
		label = label.substr(0, 12)
	var hp_bonus := int(round(float(item.custom_metadata.get("hp_bonus", 0))))
	if hp_bonus > 0:
		return "%s\n+%d HP" % [label, hp_bonus]
	return label


func _update_slot_background(item) -> void:
	if background_panel == null or item == null:
		_reset_slot_background()
		return
	var rarity := str(item.custom_metadata.get("rarity", "common"))
	var style := StyleBoxFlat.new()
	style.bg_color = _rarity_color(rarity).darkened(0.28)
	style.border_color = _rarity_color(rarity).lightened(0.12)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	background_panel.add_theme_stylebox_override("panel", style)


func _reset_slot_background() -> void:
	if background_panel == null:
		return
	background_panel.remove_theme_stylebox_override("panel")


static func _rarity_color(rarity: String) -> Color:
	match rarity:
		"legendary":
			return Color(1.0, 0.78, 0.22)
		"rare":
			return Color(0.55, 0.45, 0.95)
		"uncommon":
			return Color(0.45, 0.82, 0.55)
		_:
			return Color(0.72, 0.7, 0.68)

func _update_durability_display(slot_data: SlotData) -> void:
	if not durability_bar or not durability_fill or not slot_data.item: return
	if not slot_data.item.has_durability:
		durability_bar.visible = false
		return
		
	var current = slot_data.get_effective_durability()
	var max = slot_data.item.max_durability
	var percent = clamp(float(current) / float(max), 0.0, 1.0)
	
	durability_bar.visible = true
	durability_fill.size.x = durability_bar.size.x * percent
	durability_fill.color = Color.GREEN if percent > 0.5 else Color.YELLOW if percent > 0.25 else Color.RED
	durability_fill.modulate.a = 0.3 if current <= 0 else 1.0

func _get_slot_data_from_meta() -> SlotData:
	var inv = get_meta("inventory", null) as Inventory
	var idx = get_meta("slot_index", -1) as int
	if inv and idx >= 0 and idx < inv.capacity:
		return inv.get_slot(idx)
	return null

func set_drop_valid(is_valid: bool) -> void:
	if not highlight_panel: return
	highlight_panel.visible = true
	if is_valid:
		highlight_panel.self_modulate = Color(0.0, 0.878, 0.125, 1.0)
	else:
		highlight_panel.self_modulate = Color(1.0, 0.639, 0.584, 1.0)

func set_hotbar_selected(is_selected: bool) -> void:
	_is_hotbar_selected = is_selected
	if not highlight_panel: return
	
	if _is_hotbar_selected:
		highlight_panel.visible = true
		highlight_panel.self_modulate = Color(0.833, 0.833, 0.833, 1.0)
	else:
		highlight_panel.visible = false

static func generate_tooltip_text(slot_data: SlotData) -> String:
	if not slot_data or not slot_data.item: return ""
	var lines: PackedStringArray = []
	lines.append("[b]%s[/b]" % slot_data.item.display_name)
	if slot_data.item.description:
		lines.append(slot_data.item.description)
	var hp_bonus := int(round(float(slot_data.item.custom_metadata.get("hp_bonus", 0))))
	if hp_bonus > 0:
		lines.append("[color=#9fd89f]+%d max-HP[/color]" % hp_bonus)
	lines.append("")
	if slot_data.item.max_stack_size > 1:
		lines.append("Stack: %d / %d" % [slot_data.count, slot_data.item.max_stack_size])
	if slot_data.item.has_durability:
		var current = slot_data.get_effective_durability()
		var max = slot_data.item.max_durability
		var percent = int((float(current) / float(max)) * 100)
		var status = "Broken" if current <= 0 else "%d%%" % percent
		lines.append("Durability: [color=%s]%s[/color]" % ["red" if current <= 0 else "yellow" if current < max * 0.3 else "green", "%d / %d (%s)" % [current, max, status]])
	if slot_data.item.weight > 0:
		lines.append("Weight: %.1f" % slot_data.item.weight)
	if not slot_data.item.tags.is_empty():
		lines.append("Tags: " + ", ".join(slot_data.item.tags))
	return "\n".join(lines)
