extends GridContainer # Can also be HBoxContainer
class_name SlotGrid

@export var slot_scene: PackedScene = preload("res://addons/modular_inventory_system/ui/SlotUI.tscn")
@export var start_index: int = 0
@export var slot_count: int = 0 # 0 means auto-fill to inventory capacity

var _inventory: Inventory
var _generated_slots: Array[SlotUI] = []

func bind_inventory(inv: Inventory) -> void:
	if _inventory == inv: return
	_clear_slots()
	_inventory = inv
	if not _inventory: return
	
	var count = slot_count if slot_count > 0 else (_inventory.capacity - start_index)
	
	for i in count:
		var global_idx = start_index + i
		if global_idx >= _inventory.capacity: break
			
		var slot_ui = slot_scene.instantiate() as SlotUI
		add_child(slot_ui)
		
		slot_ui.slot_index = global_idx
		slot_ui.set_meta("inventory", _inventory)
		slot_ui.set_meta("slot_index", global_idx)
		slot_ui.add_to_group("inventory_drop_targets")
		
		slot_ui.slot_input_event.connect(_on_slot_input.bind(global_idx))
		slot_ui.tooltip_requested.connect(_on_tooltip_requested)
		slot_ui.tooltip_hidden.connect(_on_tooltip_hidden)
		
		_generated_slots.append(slot_ui)
		
	_refresh_all()
	_inventory.inventory_changed.connect(_refresh_all)
	_inventory.slot_changed.connect(_refresh_slot)

func _clear_slots() -> void:
	for slot in _generated_slots:
		if is_instance_valid(slot): slot.queue_free()
	_generated_slots.clear()
	if _inventory:
		if _inventory.inventory_changed.is_connected(_refresh_all):
			_inventory.inventory_changed.disconnect(_refresh_all)
		if _inventory.slot_changed.is_connected(_refresh_slot):
			_inventory.slot_changed.disconnect(_refresh_slot)

func _refresh_all() -> void:
	if not _inventory: return
	for slot_ui in _generated_slots:
		if slot_ui.slot_index < _inventory.capacity:
			slot_ui.set_slot_data(_inventory.get_slot(slot_ui.slot_index), slot_ui.slot_index)

func _refresh_slot(idx: int) -> void:
	if not _inventory: return
	for slot_ui in _generated_slots:
		if slot_ui.slot_index == idx:
			slot_ui.set_slot_data(_inventory.get_slot(idx), idx)

func _on_slot_input(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		var is_shift = event.shift_pressed and event.button_index == MOUSE_BUTTON_LEFT
		if is_shift:
			var target_inv = UIStateManager.get_other_inventory(_inventory)
			if target_inv:
				var amount = 0 if is_shift else 1
				InventoryTransfer.transfer(_inventory, target_inv, idx, 0)

func _on_tooltip_requested(slot_data: SlotData, pos: Vector2):
	var tooltips = get_tree().get_nodes_in_group("item_tooltip")
	if tooltips.size() > 0 and tooltips[0] is ItemTooltip:
		tooltips[0].show_tooltip(slot_data, pos)

func _on_tooltip_hidden():
	var tooltips = get_tree().get_nodes_in_group("item_tooltip")
	if tooltips.size() > 0 and tooltips[0] is ItemTooltip:
		tooltips[0].hide_tooltip()
