class_name MydrilliumMaterialCatalog
extends RefCounted

const MATERIALS := {
	"raw_mydrillium_ore": {
		"name": "Rå Mydrillium-malm",
		"refine_value": 45,
		"description": "Grönaktig mineralmalm från kubväggarna. Raffineras till Md.",
	},
	"mydrillium_sludge": {
		"name": "Mydrillium-slam",
		"refine_value": 28,
		"description": "Sediment från tidalbassänger. Filtreras till rå mineral.",
	},
	"tech_scrap": {
		"name": "Tech-skrot",
		"refine_value": 35,
		"description": "Återvunnet kretskort och legeringar med spår av Mydrillium.",
	},
	"contaminated_ore": {
		"name": "Kontaminerad malm",
		"refine_value": 95,
		"description": "SRC-märkt malm. Farlig men värdefull på svarta marknaden.",
	},
}


static func is_material(item_id: String) -> bool:
	return MATERIALS.has(item_id)


static func get_refine_value(item_id: String) -> int:
	return int(MATERIALS.get(item_id, {}).get("refine_value", 0))


static func get_display_name(item_id: String) -> String:
	return str(MATERIALS.get(item_id, {}).get("name", item_id))


static func all_material_ids() -> Array:
	return MATERIALS.keys()