class_name ColonyCityTheme
extends RefCounted

## Visuellt tema per satellitkub — samma DC-layout som Koloni 4, men egna färgpaletter.

const THEMES := {
	"satellite_left": {
		"city_name": "Rustport",
		"street_prefix": "Rustport",
		"subtitle": "Industriell futuristisk hamnstad",
		"plate_color": Color(0.32, 0.24, 0.18),
		"building_tint": Color(0.95, 0.72, 0.52),
		"zone_tint": Color(1.0, 0.85, 0.68),
		"dome_albedo": Color(0.78, 0.52, 0.34),
		"dome_emission": Color(0.9, 0.48, 0.2),
		"obelisk_albedo": Color(0.7, 0.48, 0.3),
		"obelisk_emission": Color(0.92, 0.55, 0.25),
		"park_light": Color(0.98, 0.62, 0.32),
		"sign_color": Color(0.98, 0.72, 0.42),
		"beacon_color": Color(0.95, 0.42, 0.18),
	},
	"satellite_top_a": {
		"city_name": "Azuregrid",
		"street_prefix": "Azuregrid",
		"subtitle": "Kommersiell futuristisk mittpunkt",
		"plate_color": Color(0.22, 0.28, 0.36),
		"building_tint": Color(0.58, 0.78, 0.95),
		"zone_tint": Color(0.72, 0.9, 1.0),
		"dome_albedo": Color(0.55, 0.7, 0.86),
		"dome_emission": Color(0.32, 0.65, 0.92),
		"obelisk_albedo": Color(0.48, 0.64, 0.8),
		"obelisk_emission": Color(0.38, 0.7, 0.95),
		"park_light": Color(0.42, 0.82, 0.98),
		"sign_color": Color(0.48, 0.82, 1.0),
		"beacon_color": Color(0.28, 0.62, 0.95),
	},
	"satellite_top_b": {
		"city_name": "Verdant Reach",
		"street_prefix": "Verdant",
		"subtitle": "Grönskande futuristisk förstad",
		"plate_color": Color(0.24, 0.32, 0.24),
		"building_tint": Color(0.72, 0.88, 0.62),
		"zone_tint": Color(0.8, 0.95, 0.7),
		"dome_albedo": Color(0.58, 0.74, 0.5),
		"dome_emission": Color(0.4, 0.78, 0.45),
		"obelisk_albedo": Color(0.52, 0.68, 0.48),
		"obelisk_emission": Color(0.45, 0.82, 0.5),
		"park_light": Color(0.52, 0.95, 0.55),
		"sign_color": Color(0.58, 0.92, 0.62),
		"beacon_color": Color(0.35, 0.82, 0.42),
	},
	"satellite_right": {
		"city_name": "Neo-Washington",
		"street_prefix": "Neo-Washington",
		"subtitle": "Futuristisk huvudstads-layout efter USA:s Washington",
		"plate_color": Color(0.3, 0.33, 0.3),
		## Ingen tint — behåll Kenney-färger som de är.
		"building_tint": Color(1.0, 1.0, 1.0),
		"zone_tint": Color(1.0, 1.0, 1.0),
		"dome_albedo": Color(0.72, 0.74, 0.82),
		"dome_emission": Color(0.35, 0.5, 0.78),
		"obelisk_albedo": Color(0.62, 0.66, 0.74),
		"obelisk_emission": Color(0.4, 0.55, 0.82),
		"park_light": Color(1.0, 0.88, 0.55),
		"street_light": Color(1.0, 0.88, 0.62),
		"surveillance_accent": Color(0.95, 0.28, 0.22),
		"sign_color": Color(0.55, 0.72, 0.95),
		"beacon_color": Color(0.95, 0.28, 0.2),
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