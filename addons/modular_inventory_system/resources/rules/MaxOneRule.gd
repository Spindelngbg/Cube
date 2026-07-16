class_name MaxOneRule
extends SlotRule

func _init():
	rule_name = "Max 1 Item Per Slot"

func can_accept_item(item: ItemDefinition, slot_index: int, inventory: Inventory, amount: int = 1) -> bool:
	return amount <= 1

func get_rejection_reason(item: ItemDefinition, slot_index: int) -> String:
	return "This slot does not allow stacking"

func get_max_allowed_amount(item: ItemDefinition, current_count: int, inventory: Inventory) -> int:
	return 1
