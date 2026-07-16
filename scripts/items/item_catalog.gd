class_name ItemCatalog
extends RefCounted

const CATALOG_PATH := "res://data/items/item_catalog.json"

static var _data: Dictionary = {}
static var _loaded := false


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("Item catalog missing: %s" % CATALOG_PATH)
		_data = {"base_hp": 100, "items": {}}
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_data = parsed


static func base_hp() -> float:
	_ensure_loaded()
	return float(_data.get("base_hp", 100))


static func currency_config() -> Dictionary:
	_ensure_loaded()
	var currency: Variant = _data.get("currency", {})
	return currency if typeof(currency) == TYPE_DICTIONARY else {}


static func currency_name() -> String:
	return str(currency_config().get("name", "Mydrillium"))


static func currency_symbol() -> String:
	return str(currency_config().get("symbol", "Md"))


static func starter_mydrillium() -> int:
	return int(currency_config().get("starter_amount", 10000))


static func get_item(item_id: String) -> Dictionary:
	_ensure_loaded()
	var items: Dictionary = _data.get("items", {})
	return items.get(item_id, {})


static func get_display_name(item_id: String) -> String:
	return str(get_item(item_id).get("name", item_id))


static func get_hp_bonus(item_id: String) -> float:
	return float(get_item(item_id).get("hp_bonus", 0))


static func get_rarity(item_id: String) -> String:
	return str(get_item(item_id).get("rarity", "common"))


static func get_description(item_id: String) -> String:
	return str(get_item(item_id).get("description", ""))


static func get_item_type(item_id: String) -> String:
	return str(get_item(item_id).get("type", "consumable"))


static func is_weapon(item_id: String) -> bool:
	return get_item_type(item_id) == "weapon"


static func get_weapon_kind(item_id: String) -> String:
	return str(get_item(item_id).get("weapon_kind", item_id))


static func cures_poison(item_id: String) -> bool:
	return bool(get_item(item_id).get("cures_poison", false))


static func get_shop_price(item_id: String) -> int:
	return int(get_item(item_id).get("shop_price", 0))


static func get_item_type_label(item_id: String) -> String:
	match get_item_type(item_id):
		"weapon":
			return "Vapen"
		"material":
			return "Material"
		_:
			var hp := int(get_hp_bonus(item_id))
			return "+%d HP" % hp if hp > 0 else "Föremål"


static func compute_max_hp(item_ids: Array) -> float:
	var total := base_hp()
	for raw_id in item_ids:
		total += get_hp_bonus(str(raw_id))
	return total


static func rarity_color(rarity: String) -> Color:
	match rarity:
		"legendary":
			return Color(1.0, 0.78, 0.22)
		"rare":
			return Color(0.55, 0.45, 0.95)
		"uncommon":
			return Color(0.45, 0.82, 0.55)
		_:
			return Color(0.72, 0.7, 0.68)


static func all_item_ids() -> Array:
	_ensure_loaded()
	var items: Dictionary = _data.get("items", {})
	return items.keys()