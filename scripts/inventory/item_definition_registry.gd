class_name ItemDefinitionRegistry
extends RefCounted

const ItemDefinitionScript = preload(
	"res://addons/modular_inventory_system/resources/ItemDefinition.gd"
)
const ItemIconFactoryScript = preload("res://scripts/inventory/item_icon_factory.gd")

static var _cache: Dictionary = {}


static func get_definition(item_id: String):
	var id := item_id.strip_edges()
	if id == "":
		return null
	if _cache.has(id):
		return _cache[id]
	if ItemCatalog.get_item(id).is_empty() and not ItemCatalog.is_material(id):
		return null

	var def = ItemDefinitionScript.new()
	def.id = id
	def.display_name = ItemCatalog.get_display_name(id)
	def.description = ItemCatalog.get_description(id)
	def.max_stack_size = 99 if ItemCatalog.is_material(id) else 1
	def.tags = _tags_for(id)
	def.custom_metadata = {
		"rarity": ItemCatalog.get_rarity(id),
		"hp_bonus": ItemCatalog.get_hp_bonus(id),
		"item_type": ItemCatalog.get_item_type(id),
		"weapon_kind": ItemCatalog.get_weapon_kind(id),
		"cures_poison": ItemCatalog.cures_poison(id),
		"shop_price": ItemCatalog.get_shop_price(id),
		"icon_key": ItemCatalog.get_icon_key(id),
	}
	if ItemCatalog.is_weapon(id):
		def.equipment_type = 1
	def.icon = ItemIconFactoryScript.create_icon(def)
	_cache[id] = def
	return def


static func preload_catalog() -> void:
	_cache.clear()
	for raw_id in ItemCatalog.all_item_ids():
		get_definition(str(raw_id))


static func clear_cache() -> void:
	_cache.clear()


static func _tags_for(item_id: String) -> Array[String]:
	var tags: Array[String] = []
	match ItemCatalog.get_item_type(item_id):
		"weapon":
			tags.append("weapon")
		"material":
			tags.append("material")
		"remedy":
			tags.append("remedy")
		"food":
			tags.append("food")
		_:
			tags.append("item")
	return tags