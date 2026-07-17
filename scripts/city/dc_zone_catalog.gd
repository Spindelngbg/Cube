class_name DcZoneCatalog
extends RefCounted

## Futuristisk tolkning av Washington D.C. (L'Enfant-planen) för Koloni 4.
## +X = öster (Kapitol/spawn), -X = väster (Mall/minnesmonument).

const BLOCK_M := 40.0
const MALL_HALF_WIDTH := 24.0

const ZONE_COLORS := {
	"KAPITOLPLAZA": Color(0.95, 0.78, 0.22),
	"NATIONALMALLEN": Color(0.28, 0.9, 0.42),
	"MONUMENTKÄRNA": Color(0.75, 0.82, 0.95),
	"MINNESPLATS_VÄST": Color(0.62, 0.7, 0.92),
	"PRESIDENTKORRIDOR": Color(0.92, 0.92, 0.96),
	"FEDERALT_KVARTER": Color(0.45, 0.58, 0.82),
	"KONTORSGRID": Color(0.55, 0.62, 0.7),
	"BOSTADSKVARTER": Color(0.72, 0.55, 0.42),
	"AMBASSADNÄSET": Color(0.58, 0.42, 0.72),
	"VATTENFRONT": Color(0.22, 0.62, 0.82),
	"TRANSITNAV": Color(0.38, 0.42, 0.48),
	"INDUSTRIKAJ": Color(0.48, 0.5, 0.54),
	"VERKSTADSFABRIK": Color(0.95, 0.72, 0.18),
	"SRC_LAB": Color(0.95, 0.22, 0.18),
	"PARKBÄLTE": Color(0.32, 0.78, 0.38),
}


static func classify_cell(cell: Vector2i) -> Dictionary:
	var x := cell.x
	var z := cell.y

	if x == 0 and z == 0:
		return _zone("KAPITOLPLAZA", "Kapitolplaza Öst", "commercial", "building-e")
	if x == -6 and z == 0:
		return _zone("MINNESPLATS_VÄST", "Minnesplats Väst", "commercial", "building-d")
	if x == -3 and z == 0:
		return _zone("MONUMENTKÄRNA", "Obeliskmonument", "space", "room-large")
	if x < 0 and abs(z) <= 0 and x > -6:
		return _zone("NATIONALMALLEN", "Nationalmallen Block %d" % abs(x), "roads", "tile-low")
	if x == -2 and z == 3:
		return _zone("PRESIDENTKORRIDOR", "Presidentens Korridor", "commercial", "building-b")
	if x == -4 and z == -3:
		return _zone("SRC_LAB", "SRC HQ — Projekt Redemption", "space", "room-large")
	if x >= 1 and z == 0:
		return _zone("TRANSITNAV", "Östra Transitnav", "industrial", "building-c")
	if x == 2 and z == -3:
		return _zone("VERKSTADSFABRIK", "Verkstadsfabrik — Industrikaj", "industrial", "building-f")
	if z >= 3 and x <= -1 and x >= -5:
		return _zone("AMBASSADNÄSET", "Ambassadnäset %d-%d" % [abs(x), z], "suburban", "building-type-c")
	if z <= -3 and x <= -1 and x >= -5:
		return _zone("VATTENFRONT", "Tidalbassäng %d-%d" % [abs(x), abs(z)], "roads", "tile-low")
	if z >= 2 and x <= -2:
		return _zone("BOSTADSKVARTER", "Bostadskvarter %d-%d" % [abs(x), z], "suburban", "building-type-a")
	if z <= -2 and x <= -3 and x >= -6:
		return _zone("FEDERALT_KVARTER", "Federalt Kvarter %d-%d" % [abs(x), abs(z)], "commercial", "building-a")
	if x <= -1:
		return _zone("KONTORSGRID", "Kontorsgrid %d-%d" % [abs(x), abs(z)], "commercial", "building-c")
	if z >= 2:
		return _zone("BOSTADSKVARTER", "Norra Grid %d-%d" % [x, z], "suburban", "building-type-b")
	if z <= -2:
		return _zone("INDUSTRIKAJ", "Industrikaj %d-%d" % [x, abs(z)], "industrial", "building-f")
	return _zone("KONTORSGRID", "Östra Grid %d-%d" % [x, z], "commercial", "building-b")


static func mall_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(-5, 0):
		cells.append(Vector2i(x, 0))
	return cells


## Rutnätsceller som redan fylls av landmärken eller story-byggnader — inga zonk-byggnader här.
static func reserved_landmark_cells() -> Array[Vector2i]:
	return [
		Vector2i(0, 0),
		Vector2i(-6, 0),
		Vector2i(-2, 3),
		Vector2i(-4, -3),
		Vector2i(-1, 2),
		Vector2i(-5, 1),
	]


static func is_reserved_landmark_cell(cell: Vector2i) -> bool:
	return cell in reserved_landmark_cells()


static func grid_extent() -> Dictionary:
	return {
		"x_min": -7,
		"x_max": 3,
		"z_min": -4,
		"z_max": 5,
	}


static func zone_color(zone_type: String) -> Color:
	return ZONE_COLORS.get(zone_type, Color(0.6, 0.6, 0.65))


static func is_greenery_zone(zone_type: String) -> bool:
	return zone_type in GREENERY_ZONE_TYPES


static func greenery_density(zone_type: String) -> Dictionary:
	return GREENERY_DENSITY.get(zone_type, {"trees": 0, "mushrooms": 0})


const GREENERY_ZONE_TYPES := [
	"NATIONALMALLEN",
	"VATTENFRONT",
	"BOSTADSKVARTER",
	"AMBASSADNÄSET",
	"MONUMENTKÄRNA",
	"PARKBÄLTE",
]


const GREENERY_DENSITY := {
	"NATIONALMALLEN": {"trees": 0, "mushrooms": 0},
	"VATTENFRONT": {"trees": 0, "mushrooms": 0},
	"BOSTADSKVARTER": {"trees": 0, "mushrooms": 0},
	"AMBASSADNÄSET": {"trees": 0, "mushrooms": 0},
	"MONUMENTKÄRNA": {"trees": 0, "mushrooms": 0},
	"PARKBÄLTE": {"trees": 0, "mushrooms": 0},
}


static func _zone(zone_type: String, name: String, kit: String, model: String) -> Dictionary:
	return {
		"zone_type": zone_type,
		"name": name,
		"kit": kit,
		"model": model,
		"tag": "[%s] %s" % [zone_type, name],
	}