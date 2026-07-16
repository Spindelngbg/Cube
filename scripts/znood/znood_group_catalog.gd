class_name ZnoodGroupCatalog
extends RefCounted

const GROUPS := {
	"src_security": {
		"name": "SRC Säkerhet",
		"description": "Federal säkerhetsstyrka — svarar på backup inom Neo-Washington.",
	},
	"colony_patrol": {
		"name": "Koloni Patrull",
		"description": "Lokal patrull i din satellitkub.",
	},
	"medic_support": {
		"name": "Medicinskt Stöd",
		"description": "Pharmacy- och sjukvårdsteam.",
	},
	"zezzlor_response": {
		"name": "Zezzlor Respons",
		"description": "Zezzlor-enheter i närheten av checkpoint.",
	},
}


static func all_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for key in GROUPS.keys():
		ids.append(str(key))
	return ids


static func get_name(group_id: String) -> String:
	return str(GROUPS.get(group_id, {}).get("name", group_id))


static func get_description(group_id: String) -> String:
	return str(GROUPS.get(group_id, {}).get("description", ""))