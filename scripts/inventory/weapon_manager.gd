extends Node

signal equipped_changed(weapon_id: String)

const SLIMESHOOTER_ID := "slimeshooter"


func _ready() -> void:
	InventoryManager.inventory_changed.connect(_on_inventory_changed)


func can_use_slimeshooter() -> bool:
	return (
		InventoryManager.get_equipped_weapon() == SLIMESHOOTER_ID
		and InventoryManager.has_item(SLIMESHOOTER_ID)
	)


func get_equipped_display_name() -> String:
	var weapon_id := InventoryManager.get_equipped_weapon()
	if weapon_id == "":
		return ""
	return ItemCatalog.get_display_name(weapon_id)


func equip(weapon_id: String) -> bool:
	if not InventoryManager.has_item(weapon_id):
		return false
	if not ItemCatalog.is_weapon(weapon_id):
		return false
	InventoryManager.set_equipped_weapon(weapon_id)
	equipped_changed.emit(weapon_id)
	return true


func unequip() -> void:
	if InventoryManager.get_equipped_weapon() == "":
		return
	InventoryManager.set_equipped_weapon("")
	equipped_changed.emit("")


func on_weapon_acquired(weapon_id: String, auto_equip: bool = true) -> void:
	if not ItemCatalog.is_weapon(weapon_id):
		return
	if auto_equip:
		equip(weapon_id)


func grant_slimeshooter(auto_equip: bool = true) -> bool:
	if not InventoryManager.has_item(SLIMESHOOTER_ID):
		if not InventoryManager.add_item(SLIMESHOOTER_ID):
			return false
	if auto_equip:
		return equip(SLIMESHOOTER_ID)
	return true


func _on_inventory_changed() -> void:
	var equipped := InventoryManager.get_equipped_weapon()
	if equipped != "" and not InventoryManager.has_item(equipped):
		unequip()