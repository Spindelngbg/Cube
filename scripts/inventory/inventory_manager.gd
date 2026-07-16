extends Node

signal inventory_changed
signal item_added(item_id: String)
signal currency_changed(amount: int)

const ModularInventoryScript = preload(
	"res://addons/modular_inventory_system/resources/Inventory.gd"
)
const ItemDefinitionRegistryScript = preload(
	"res://scripts/inventory/item_definition_registry.gd"
)

const INVENTORY_CAPACITY := 32

var _inventory
var _equipped_weapon := ""
var _mydrillium := 0
var _save_slot := "guest"
var _hydrated := false
var _is_new_character := false
var _starter_mydrillium_granted := false


func _ready() -> void:
	ItemDefinitionRegistryScript.preload_catalog()
	_inventory = ModularInventoryScript.new(INVENTORY_CAPACITY)
	_inventory.inventory_changed.connect(_on_modular_inventory_changed)
	Profile.character_selected.connect(_on_character_selected)
	Profile.character_created.connect(_on_character_created)
	Profile.characters_loaded.connect(_on_characters_loaded)
	_on_character_selected()


func get_modular_inventory():
	return _inventory


func get_items() -> Array[String]:
	var result: Array[String] = []
	for i in _inventory.capacity:
		var slot = _inventory.get_slot(i)
		if slot == null or slot.is_empty() or slot.item == null:
			continue
		var item_id: String = str(slot.item.id)
		if ItemCatalog.is_material(item_id):
			continue
		if item_id not in result:
			result.append(item_id)
	return result


func get_materials() -> Dictionary:
	var result: Dictionary = {}
	for i in _inventory.capacity:
		var slot = _inventory.get_slot(i)
		if slot == null or slot.is_empty() or slot.item == null:
			continue
		var item_id: String = str(slot.item.id)
		if not ItemCatalog.is_material(item_id):
			continue
		result[item_id] = int(result.get(item_id, 0)) + slot.count
	return result


func get_material_count(material_id: String) -> int:
	return int(get_materials().get(material_id.strip_edges(), 0))


func add_material(material_id: String, amount: int = 1) -> bool:
	var id := material_id.strip_edges()
	if amount <= 0 or not ItemCatalog.is_material(id):
		push_warning("Unknown material: %s" % id)
		return false
	var def = ItemDefinitionRegistryScript.get_definition(id)
	if def == null:
		return false
	var remaining = _inventory.add_item(def, amount)
	if remaining > 0:
		push_warning("Inventory full, could not add all of %s" % id)
		return false
	_save_inventory()
	return true


func remove_material(material_id: String, amount: int = 1) -> bool:
	var id := material_id.strip_edges()
	if amount <= 0 or get_material_count(id) < amount:
		return false
	var def = ItemDefinitionRegistryScript.get_definition(id)
	if def == null:
		return false
	if not _inventory.remove_item(def, amount):
		return false
	_save_inventory()
	return true


func get_mydrillium() -> int:
	return _mydrillium


func get_currency_name() -> String:
	return ItemCatalog.currency_name()


func has_item(item_id: String) -> bool:
	return _count_item(item_id.strip_edges()) > 0


func get_equipped_weapon() -> String:
	return _equipped_weapon


func set_equipped_weapon(weapon_id: String) -> void:
	var next := weapon_id.strip_edges()
	if next != "" and (not ItemCatalog.is_weapon(next) or not has_item(next)):
		return
	if _equipped_weapon == next:
		return
	_equipped_weapon = next
	_save_inventory()
	inventory_changed.emit()


func get_max_hp() -> float:
	return ItemCatalog.compute_max_hp(get_items())


func get_hp_bonus_total() -> float:
	return get_max_hp() - ItemCatalog.base_hp()


func add_item(item_id: String) -> bool:
	var id := item_id.strip_edges()
	if id == "" or ItemCatalog.get_item(id).is_empty():
		push_warning("Unknown item: %s" % id)
		return false
	if ItemCatalog.is_material(id):
		return add_material(id, 1)
	if not ItemCatalog.is_stackable(id) and has_item(id):
		return false
	var def = ItemDefinitionRegistryScript.get_definition(id)
	if def == null:
		return false
	var remaining = _inventory.add_item(def, 1)
	if remaining > 0:
		return false
	_save_inventory()
	item_added.emit(id)
	return true


func remove_item(item_id: String) -> bool:
	var id := item_id.strip_edges()
	if ItemCatalog.is_material(id):
		return remove_material(id, 1)
	if not has_item(id):
		return false
	var def = ItemDefinitionRegistryScript.get_definition(id)
	if def == null:
		return false
	if not _inventory.remove_item(def, 1):
		return false
	if _equipped_weapon == id:
		_equipped_weapon = ""
	_save_inventory()
	return true


func add_mydrillium(amount: int) -> void:
	if amount <= 0:
		return
	_mydrillium += amount
	_save_inventory()
	currency_changed.emit(_mydrillium)
	inventory_changed.emit()


func spend_mydrillium(amount: int) -> bool:
	if amount <= 0 or _mydrillium < amount:
		return false
	_mydrillium -= amount
	_save_inventory()
	currency_changed.emit(_mydrillium)
	inventory_changed.emit()
	return true


func grant_starter_kit() -> void:
	if _hydrated:
		return
	_hydrated = true
	if get_items().is_empty():
		add_item("koloni_ration")
	if _is_new_character:
		_save_inventory()
		_show_new_character_toast()
		_is_new_character = false


func _count_item(item_id: String) -> int:
	if item_id == "":
		return 0
	var def = ItemDefinitionRegistryScript.get_definition(item_id)
	if def == null:
		return 0
	var total := 0
	for i in _inventory.capacity:
		var slot = _inventory.get_slot(i)
		if slot and not slot.is_empty() and slot.item == def:
			total += slot.count
	return total


func _on_modular_inventory_changed() -> void:
	inventory_changed.emit()


func _on_character_created(character_id: String) -> void:
	if character_id.strip_edges() == "":
		return
	_switch_save_slot(character_id, true)
	grant_starter_kit()


func _on_character_selected() -> void:
	var slot := _resolve_save_slot()
	_switch_save_slot(slot, false)


func _on_characters_loaded() -> void:
	if Profile.active_character_id.strip_edges() == "":
		return
	_on_character_selected()


func _resolve_save_slot() -> String:
	var slot := Profile.active_character_id if Profile.active_character_id != "" else Auth.username
	if slot.strip_edges() == "":
		return "guest"
	return slot


func _switch_save_slot(slot: String, is_new: bool) -> void:
	if slot == _save_slot and _hydrated and not is_new:
		return
	_save_slot = slot
	_hydrated = false
	if is_new:
		_is_new_character = true
	_load_inventory()
	if is_new:
		_is_new_character = true
	grant_starter_kit()


func _inventory_path() -> String:
	return "user://inventory_%s.json" % _save_slot


func _load_inventory() -> void:
	_inventory.clear()
	_equipped_weapon = ""
	_mydrillium = 0
	var path := _inventory_path()
	if not FileAccess.file_exists(path):
		_grant_starter_mydrillium(true)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	if parsed.has("slots"):
		_load_modular_slots(parsed)
	else:
		_migrate_legacy_save(parsed)

	_mydrillium = int(parsed.get("mydrillium", 0))
	var equipped := str(parsed.get("equipped_weapon", ""))
	if equipped != "" and has_item(equipped) and ItemCatalog.is_weapon(equipped):
		_equipped_weapon = equipped

	_starter_mydrillium_granted = bool(parsed.get("starter_mydrillium_granted", false))
	if not _starter_mydrillium_granted:
		if _mydrillium <= 0:
			_grant_starter_mydrillium(true)
		else:
			_mark_starter_mydrillium_granted()
		inventory_changed.emit()
		currency_changed.emit(_mydrillium)
		return

	inventory_changed.emit()
	currency_changed.emit(_mydrillium)


func _load_modular_slots(data: Dictionary) -> void:
	for entry in data.get("slots", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var item_id := str(entry.get("item_id", ""))
		var count := int(entry.get("count", 0))
		if item_id == "" or count <= 0:
			continue
		var def = ItemDefinitionRegistryScript.get_definition(item_id)
		if def:
			_inventory.add_item(def, count)


func _migrate_legacy_save(parsed: Dictionary) -> void:
	var stored: Array = parsed.get("items", [])
	for entry in stored:
		var item_id := str(entry)
		var def = ItemDefinitionRegistryScript.get_definition(item_id)
		if def:
			_inventory.add_item(def, 1)
	var stored_materials: Variant = parsed.get("materials", {})
	if typeof(stored_materials) == TYPE_DICTIONARY:
		for raw_id in stored_materials:
			var material_id := str(raw_id)
			var count := int(stored_materials[raw_id])
			var def = ItemDefinitionRegistryScript.get_definition(material_id)
			if count > 0 and def:
				_inventory.add_item(def, count)


func _grant_starter_mydrillium(mark_new_character: bool) -> void:
	_is_new_character = mark_new_character or _is_new_character
	_mydrillium = ItemCatalog.starter_mydrillium()
	_starter_mydrillium_granted = true
	_save_inventory()
	inventory_changed.emit()
	currency_changed.emit(_mydrillium)


func _mark_starter_mydrillium_granted() -> void:
	_starter_mydrillium_granted = true
	_save_inventory()


func _save_inventory() -> void:
	var slots: Array = []
	for i in _inventory.capacity:
		var slot = _inventory.get_slot(i)
		if slot == null or slot.is_empty() or slot.item == null:
			continue
		slots.append({
			"item_id": str(slot.item.id),
			"count": slot.count,
			"durability": slot.current_durability,
		})

	var file := FileAccess.open(_inventory_path(), FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"slots": slots,
		"mydrillium": _mydrillium,
		"equipped_weapon": _equipped_weapon,
		"starter_mydrillium_granted": _starter_mydrillium_granted,
	}, "\t"))


func _show_new_character_toast() -> void:
	QuestManager.story_toast.emit(
		"Plånbok skapad",
		"Du fick %d %s att starta med."
		% [_mydrillium, ItemCatalog.currency_name()]
	)