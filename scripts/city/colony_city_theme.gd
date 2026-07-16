class_name ColonyCityTheme
extends RefCounted

## Visuellt tema per satellitkub — samma DC-layout som Koloni 4, men egna färgpaletter.

const THEMES := {
	"satellite_left": {
		"city_name": "Rustport",
		"street_prefix": "Rustport",
		"subtitle": "Industriell futuristisk hamnstad",
		"plate_color": Color(0.15, 0.11, 0.09),
		"building_tint": Color(0.95, 0.72, 0.52),
		"zone_tint": Color(1.05, 0.82, 0.62),
		"dome_albedo": Color(0.82, 0.58, 0.38),
		"dome_emission": Color(0.98, 0.55, 0.22),
		"obelisk_albedo": Color(0.75, 0.52, 0.32),
		"obelisk_emission": Color(1.0, 0.62, 0.28),
		"park_light": Color(0.98, 0.62, 0.32),
		"sign_color": Color(0.98, 0.72, 0.42),
		"beacon_color": Color(0.95, 0.42, 0.18),
	},
	"satellite_top_a": {
		"city_name": "Azuregrid",
		"street_prefix": "Azuregrid",
		"subtitle": "Kommersiell futuristisk mittpunkt",
		"plate_color": Color(0.09, 0.12, 0.16),
		"building_tint": Color(0.58, 0.78, 0.95),
		"zone_tint": Color(0.72, 0.92, 1.08),
		"dome_albedo": Color(0.62, 0.78, 0.92),
		"dome_emission": Color(0.35, 0.72, 0.98),
		"obelisk_albedo": Color(0.55, 0.72, 0.88),
		"obelisk_emission": Color(0.42, 0.78, 1.0),
		"park_light": Color(0.42, 0.82, 0.98),
		"sign_color": Color(0.48, 0.82, 1.0),
		"beacon_color": Color(0.28, 0.62, 0.95),
	},
	"satellite_top_b": {
		"city_name": "Verdant Reach",
		"street_prefix": "Verdant",
		"subtitle": "Grönskande futuristisk förstad",
		"plate_color": Color(0.1, 0.13, 0.11),
		"building_tint": Color(0.72, 0.88, 0.62),
		"zone_tint": Color(0.82, 1.02, 0.72),
		"dome_albedo": Color(0.68, 0.82, 0.58),
		"dome_emission": Color(0.45, 0.88, 0.52),
		"obelisk_albedo": Color(0.62, 0.78, 0.55),
		"obelisk_emission": Color(0.52, 0.92, 0.58),
		"park_light": Color(0.52, 0.95, 0.55),
		"sign_color": Color(0.58, 0.92, 0.62),
		"beacon_color": Color(0.35, 0.82, 0.42),
	},
	"satellite_right": {
		"city_name": "Neo-Washington",
		"street_prefix": "Neo-Washington",
		"subtitle": "Futuristisk huvudstads-layout efter USA:s Washington",
		"plate_color": Color(0.1, 0.11, 0.14),
		"building_tint": Color(1.0, 1.0, 1.0),
		"zone_tint": Color(1.0, 1.0, 1.0),
		"dome_albedo": Color(0.88, 0.9, 0.95),
		"dome_emission": Color(0.45, 0.62, 0.95),
		"obelisk_albedo": Color(0.78, 0.82, 0.9),
		"obelisk_emission": Color(0.55, 0.72, 1.0),
		"park_light": Color(0.72, 0.82, 1.0),
		"street_light": Color(0.82, 0.9, 1.0),
		"surveillance_accent": Color(0.95, 0.18, 0.12),
		"sign_color": Color(0.62, 0.74, 0.92),
		"beacon_color": Color(0.95, 0.2, 0.14),
	},
}


static func for_spawn(spawn_id: String) -> Dictionary:
	var id := SpawnPoints.normalize_id(spawn_id)
	return THEMES.get(id, THEMES["satellite_right"]).duplicate(true)


static func city_label(spawn_id: String) -> String:
	var theme := for_spawn(spawn_id)
	var num := SpawnPoints.get_colony_number(spawn_id)
	return "%s — KOLONI %d" % [theme.get("city_name", ""), num]


static func spawn_subtitle(spawn_id: String) -> String:
	return str(for_spawn(spawn_id).get("subtitle", ""))