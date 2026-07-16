class_name SlotRule
extends Resource

@export var rule_name: String = "Base Rule"

func can_accept_item(item: ItemDefinition, slot_index: int, inventory: Inventory, amount: int = 1) -> bool:
	return true

func get_rejection_reason(item: ItemDefinition, slot_index: int) -> String:
	return ""

func get_invalid_drop_feedback() -> Color:
	return Color.RED

func get_max_allowed_amount(item: ItemDefinition, current_count: int, inventory: Inventory) -> int:
	return -1

static func item_has_tag(item: ItemDefinition, tag: String) -> bool:
	if not item or not item.has_method("has_tag"):
		return false
	return item.has_tag(tag)
