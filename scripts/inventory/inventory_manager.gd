extends Node

signal inventory_changed
signal item_added(item_id: String)
signal currency_changed(amount: int)

var _items: Array[String] = []
var _mydrillium := 0
var _save_slot := "guest"
var _hydrated := false
var _is_new_character := false


func _ready() -> void:
	Profile.character_selected.connect(_on_character_selected)
	Profile.character_created.connect(_on_character_created)
	_on_character_selected()


func get_items() -> Array[String]:
	return _items.duplicate()


func get_mydrillium() -> int:
	return _mydrillium


func get_currency_name() -> String:
	return ItemCatalog.currency_name()


func has_item(item_id: String) -> bool:
	return item_id in _items


func get_max_hp() -> float:
	return ItemCatalog.compute_max_hp(_items)


func get_hp_bonus_total() -> float:
	return get_max_hp() - ItemCatalog.base_hp()


func add_item(item_id: String) -> bool:
	if item_id.strip_edges() == "" or ItemCatalog.get_item(item_id).is_empty():
		push_warning("Unknown item: %s" % item_id)
		return false
	if has_item(item_id):
		return false
	_items.append(item_id)
	_save_inventory()
	inventory_changed.emit()
	item_added.emit(item_id)
	return true


func remove_item(item_id: String) -> bool:
	if not has_item(item_id):
		return false
	_items.erase(item_id)
	_save_inventory()
	inventory_changed.emit()
	return true


func add_mydrillium(amount: int) -> void:
	if amount <= 0:
		return
	_mydrillium += amount
	_save_inventory()
	currency_changed.emit()
	inventory_changed.emit()


func spend_mydrillium(amount: int) -> bool:
	if amount <= 0 or _mydrillium < amount:
		return false
	_mydrillium -= amount
	_save_inventory()
	currency_changed.emit()
	inventory_changed.emit()
	return true


func grant_starter_kit() -> void:
	if _hydrated:
		return
	_hydrated = true
	if _items.is_empty():
		add_item("koloni_ration")
	if _is_new_character:
		_save_inventory()
		_show_new_character_toast()
		_is_new_character = false


func _on_character_created(character_id: String) -> void:
	if character_id.strip_edges() == "":
		return
	_save_slot = character_id
	_hydrated = false
	_is_new_character = true
	_load_inventory()
	grant_starter_kit()


func _on_character_selected() -> void:
	var slot := Profile.active_character_id if Profile.active_character_id != "" else Auth.username
	if slot.strip_edges() == "":
		slot = "guest"
	if slot == _save_slot and not _items.is_empty():
		return
	_save_slot = slot
	_hydrated = false
	_is_new_character = false
	_load_inventory()
	grant_starter_kit()


func _inventory_path() -> String:
	return "user://inventory_%s.json" % _save_slot


func _load_inventory() -> void:
	_items.clear()
	_mydrillium = 0
	var path := _inventory_path()
	if not FileAccess.file_exists(path):
		_is_new_character = true
		_mydrillium = ItemCatalog.starter_mydrillium()
		inventory_changed.emit()
		currency_changed.emit(_mydrillium)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var stored: Array = parsed.get("items", [])
	for entry in stored:
		var item_id := str(entry)
		if not ItemCatalog.get_item(item_id).is_empty() and item_id not in _items:
			_items.append(item_id)
	_mydrillium = int(parsed.get("mydrillium", 0))
	inventory_changed.emit()
	currency_changed.emit(_mydrillium)


func _save_inventory() -> void:
	var file := FileAccess.open(_inventory_path(), FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"items": _items,
		"mydrillium": _mydrillium,
	}, "\t"))


func _show_new_character_toast() -> void:
	QuestManager.story_toast.emit(
		"Plånbok skapad",
		"Du fick %d %s att starta med."
		% [_mydrillium, ItemCatalog.currency_name()]
	)