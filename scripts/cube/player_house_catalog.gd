class_name PlayerHouseCatalog
extends RefCounted

## Hus som kan byggas på egna zoner/tomter.

const HOUSES: Array[Dictionary] = [
	{
		"id": "tent",
		"name": "Tält",
		"description": "Liten bas under duk. Billigt och snabbt uppsatt.",
		"price": 400,
		"zones_required": 1,
		"floors": 1,
		"footprint": 1,
		"rarity": "common",
	},
	{
		"id": "container",
		"name": "Containerhus",
		"description": "Metallcontainer ombyggd till boende. Tåligt och kompakt.",
		"price": 1200,
		"zones_required": 1,
		"floors": 1,
		"footprint": 1,
		"rarity": "uncommon",
	},
	{
		"id": "square",
		"name": "Fyrkantigt hus",
		"description": "Större fyrkantig byggnad med rum för bas och förråd.",
		"price": 2800,
		"zones_required": 1,
		"floors": 1,
		"footprint": 1,
		"rarity": "uncommon",
	},
	{
		"id": "luxury",
		"name": "Lyxhus",
		"description": "Fint enfamiljshus med glas och neon. Kräver en zon.",
		"price": 6500,
		"zones_required": 1,
		"floors": 2,
		"footprint": 1,
		"rarity": "rare",
	},
	{
		"id": "mansion",
		"name": "Mansion",
		"description": "Stor herrgård i flera våningar. Kräver 4 zoner i en 2×2-kvadrat.",
		"price": 18000,
		"zones_required": 4,
		"floors": 3,
		"footprint": 2,
		"rarity": "legendary",
	},
]


static func all_houses() -> Array[Dictionary]:
	return HOUSES


static func get_house(house_id: String) -> Dictionary:
	for house in HOUSES:
		if str(house.get("id", "")) == house_id:
			return house
	return {}


static func get_display_name(house_id: String) -> String:
	return str(get_house(house_id).get("name", house_id))


static func get_price(house_id: String) -> int:
	return int(get_house(house_id).get("price", 0))


static func get_zones_required(house_id: String) -> int:
	return int(get_house(house_id).get("zones_required", 1))


static func get_footprint(house_id: String) -> int:
	return int(get_house(house_id).get("footprint", 1))
