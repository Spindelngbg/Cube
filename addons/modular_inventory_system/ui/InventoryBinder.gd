extends Control
class_name InventoryBinder

var _inventory: Inventory
var _tooltip: ItemTooltip

func _ready() -> void:
	add_to_group("modular_inventory_panel") 
	_tooltip = find_child("ItemTooltip", true, false)
	
	var tooltips = get_tree().get_nodes_in_group("item_tooltip")
	if tooltips.size() > 0 and tooltips[0] is ItemTooltip:
		_tooltip = tooltips[0]
		
	var close_btn = find_child("CloseButton", true, false)
	if close_btn and close_btn is BaseButton:
		# Close all panel
		close_btn.pressed.connect(func(): UIStateManager.close_all())
		# Close only this panel
		#close_btn.pressed.connect(func(): 
			#if UIStateManager:
				#UIStateManager.close_panel(self)
		#)

func bind_inventory(inv: Inventory) -> void:
	if _inventory == inv: return
	_inventory = inv
	if not _inventory: return
	
	for node in find_children("*", "", true, false):
		if node != self and node.has_method("bind_inventory"):
			node.bind_inventory(_inventory)
			
	for slot_ui in find_children("*", "SlotUI", true, false):
		if slot_ui.get_parent() is SlotGrid: continue
		if slot_ui.get_parent() is HBoxContainer and slot_ui.get_parent().has_method("bind_inventory"): continue
		
		if slot_ui.slot_index >= 0 and slot_ui.slot_index < _inventory.capacity:
			slot_ui.set_meta("inventory", _inventory)
			slot_ui.set_meta("slot_index", slot_ui.slot_index)
			slot_ui.add_to_group("inventory_drop_targets")
			slot_ui.slot_input_event.connect(_on_manual_slot_input.bind(slot_ui.slot_index))
			slot_ui.tooltip_requested.connect(_on_tooltip_requested)
			slot_ui.tooltip_hidden.connect(_on_tooltip_hidden)
			slot_ui.set_slot_data(_inventory.get_slot(slot_ui.slot_index), slot_ui.slot_index)

	_inventory.inventory_changed.connect(_refresh_all)
	_inventory.slot_changed.connect(_refresh_slot)

func get_bound_inventory() -> Inventory:
	return _inventory

func _refresh_all() -> void:
	for slot_ui in find_children("*", "SlotUI", true, false):
		if slot_ui.get_parent() is SlotGrid: continue
		if slot_ui.slot_index >= 0 and slot_ui.slot_index < _inventory.capacity:
			slot_ui.set_slot_data(_inventory.get_slot(slot_ui.slot_index), slot_ui.slot_index)

func _refresh_slot(idx: int) -> void:
	for slot_ui in find_children("*", "SlotUI", true, false):
		if slot_ui.get_parent() is SlotGrid: continue
		if slot_ui.slot_index == idx:
			slot_ui.set_slot_data(_inventory.get_slot(idx), idx)

func _on_manual_slot_input(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		var is_shift = event.shift_pressed and event.button_index == MOUSE_BUTTON_LEFT
		if is_shift:
			var target_inv = UIStateManager.get_other_inventory(_inventory)
			if target_inv:
				var amount = 0 if is_shift else 1
				InventoryTransfer.transfer(_inventory, target_inv, idx, 0)

func _on_tooltip_requested(slot_data: SlotData, pos: Vector2):
	if _tooltip: _tooltip.show_tooltip(slot_data, pos)

func _on_tooltip_hidden():
	var tooltips = get_tree().get_nodes_in_group("item_tooltip")
	if tooltips.size() > 0 and tooltips[0] is ItemTooltip:
		tooltips[0].hide_tooltip()
