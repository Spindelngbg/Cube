@tool
class_name ItemLogic extends RefCounted

signal use_started
signal use_ended
signal use_finished(item: ItemDefinition, success: bool)

var _item: ItemDefinition
var _player: Node
var _weapon_model: Node3D
var _slot_index: int = -1
var _is_active: bool = false
var _inventory: Inventory

func setup(item: ItemDefinition, player: Node, slot_index: int = -1, weapon_model: Node3D = null, inventory: Inventory = null) -> void:
	_item = item
	_player = player
	_slot_index = slot_index
	_weapon_model = weapon_model
	_inventory = inventory

func on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				on_primary_use(_slot_index)
			else:
				on_release()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				on_secondary_use(_slot_index)

func can_use() -> bool:
	return true

func on_primary_use(slot_index: int = -1) -> void:
	pass

func on_secondary_use(slot_index: int = -1) -> void:
	pass

func on_release() -> void:
	_is_active = false

func update(delta: float) -> void:
	pass

func cleanup() -> void:
	_is_active = false
	_player = null
	_item = null
	_weapon_model = null
	_inventory = null

func _consume_item_durability(slot_index: int, amount: int = 1) -> bool:
	if not _inventory or slot_index < 0: return false
	return _inventory.consume_durability(_item, slot_index, amount)
