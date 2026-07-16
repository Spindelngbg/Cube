@tool
extends InventoryUI
class_name ModularHotbar

const InventoryRuntimeScript = preload("res://addons/modular_inventory_system/inventory_runtime.gd")

@export var slots_container: HBoxContainer
@export var slot_scene: PackedScene = preload("res://addons/modular_inventory_system/ui/SlotUI.tscn")
@export var hotbar_size: int = 9
@export var start_index: int = 0

@export_group("Scroll Navigation")
@export var enable_scroll_navigation: bool = true
@export var scroll_wraps: bool = true

@export_group("Manager Binding")
@export var equipment_manager: NodePath

@export var selected_index: int = 0:
	set(value):
		if selected_index == value: return
		if selected_index >= 0 and selected_index < slot_uis.size():
			if is_instance_valid(slot_uis[selected_index]):
				slot_uis[selected_index].set_hotbar_selected(false)
		selected_index = value
		if selected_index >= 0 and selected_index < slot_uis.size():
			if is_instance_valid(slot_uis[selected_index]):
				slot_uis[selected_index].set_hotbar_selected(true)
		emit_signal("selection_changed", selected_index)

signal selection_changed(new_index: int)

var slot_uis: Array[SlotUI] = []

func _ready():
	super._ready()

func get_selected_global_index() -> int:
	return start_index + selected_index
	
func _on_inventory_attached(inv: Inventory):
	_setup_slots(inv)

func _refresh_all():
	for i in min(slot_uis.size(), hotbar_size):
		var global_idx = start_index + i
		if global_idx < _inventory.capacity:
			slot_uis[i].set_slot_data(_inventory.get_slot(global_idx), global_idx)

func _refresh_slot(global_idx: int):
	var local_idx = global_idx - start_index
	if local_idx >= 0 and local_idx < slot_uis.size():
		slot_uis[local_idx].set_slot_data(_inventory.get_slot(global_idx), global_idx)

func _setup_slots(inv: Inventory):
	_clear_slots()
	if not slots_container or not slot_scene: return
	for i in hotbar_size:
		var global_idx = start_index + i
		if global_idx >= inv.capacity: break
		
		var slot_ui = slot_scene.instantiate() as SlotUI
		slots_container.add_child(slot_ui)
		slot_uis.append(slot_ui)
		slot_ui.set_meta("inventory", inv)
		slot_ui.set_meta("slot_index", global_idx)
		slot_ui.add_to_group("inventory_drop_targets")
		slot_ui.slot_input_event.connect(_on_slot_input.bind(i))
		slot_ui.set_hotbar_selected(i == selected_index) 
		_refresh_slot(global_idx)

func _clear_slots():
	for s in slot_uis: if is_instance_valid(s): s.queue_free()
	slot_uis.clear()

func _unhandled_input(event: InputEvent) -> void:
	
	if InventoryRuntimeScript.is_dragging():
		return
	
	if event is InputEventMouseButton:
		var direction = 0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			direction = -1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			direction = 1
		
		if direction != 0 and event.pressed:
			_select_next_slot(direction)
			get_viewport().set_input_as_handled()

func _select_next_slot(direction: int) -> void:
	if hotbar_size <= 1:
		return
	
	var old_index = selected_index
	var new_index = old_index + direction
	
	if scroll_wraps:
		new_index = wrapi(new_index, 0, hotbar_size)
	else:
		new_index = clamp(new_index, 0, hotbar_size - 1)

	if is_instance_valid(slot_uis[old_index]):
		var tween = create_tween()
		tween.tween_property(slot_uis[old_index], "modulate", Color(1, 1, 1, 1.3), 0.1)
		tween.tween_property(slot_uis[old_index], "modulate", Color.WHITE, 0.1)
		
	if new_index != old_index:
		selected_index = new_index

func _on_slot_input(event: InputEvent, hb_idx: int):
	if InventoryRuntimeScript.is_dragging():
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				selected_index = hb_idx
