class_name CriminalBossCatalog
extends RefCounted

const DcZoneCatalogScript = preload("res://scripts/city/dc_zone_catalog.gd")
const CriminalBossLoreScript = preload("res://scripts/story/criminal_boss_lore.gd")

const BOSSES: Array = [
	{"id": "criminal_boss_k1_karl", "name": "Kåken-Karl", "syndicate": "Hamn-syndikatet", "colony": "satellite_left"},
	{"id": "criminal_boss_k1_siv", "name": "Smuggel-Siv", "syndicate": "Tullkartell", "colony": "satellite_left"},
	{"id": "criminal_boss_k1_ragnar", "name": "Blek-Ragnar", "syndicate": "Skrotunionen", "colony": "satellite_left"},
	{"id": "criminal_boss_k1_tyra", "name": "Tull-Tyra", "syndicate": "Industribröderna", "colony": "satellite_left"},
	{"id": "criminal_boss_k1_nisse", "name": "Skrot-Nisse", "syndicate": "Svartplåt", "colony": "satellite_left"},
	{"id": "criminal_boss_k2_greta", "name": "Guld-Greta", "syndicate": "Valutaklanen", "colony": "satellite_top_a"},
	{"id": "criminal_boss_k2_bosse", "name": "Blek-Bosse", "syndicate": "Korridorkartell", "colony": "satellite_top_a"},
	{"id": "criminal_boss_k2_filip", "name": "Fax-Filip", "syndicate": "Pappersvägen", "colony": "satellite_top_a"},
	{"id": "criminal_boss_k2_kim", "name": "Kred-Kim", "syndicate": "Skuldringen", "colony": "satellite_top_a"},
	{"id": "criminal_boss_k2_hugo", "name": "Hamn-Hugo", "syndicate": "Lastbryggan", "colony": "satellite_top_a"},
	{"id": "criminal_boss_k3_fia", "name": "Förort-Fia", "syndicate": "Villakartell", "colony": "satellite_top_b"},
	{"id": "criminal_boss_k3_lars", "name": "Lån-Lars", "syndicate": "Räntemaffian", "colony": "satellite_top_b"},
	{"id": "criminal_boss_k3_petra", "name": "Pärl-Petra", "syndicate": "Garagebanden", "colony": "satellite_top_b"},
	{"id": "criminal_boss_k3_berra", "name": "Betong-Berra", "syndicate": "Byggsvart", "colony": "satellite_top_b"},
	{"id": "criminal_boss_k3_stina", "name": "Skjul-Stina", "syndicate": "Lagerligan", "colony": "satellite_top_b"},
	{"id": "criminal_boss_k4_knut", "name": "Kapitol-Knut", "syndicate": "Kapitol-syndikatet", "colony": "satellite_right"},
	{"id": "criminal_boss_k4_mira", "name": "Mall-Mira", "syndicate": "Köpcenterkartell", "colony": "satellite_right"},
	{"id": "criminal_boss_k4_tore", "name": "Tåg-Tore", "syndicate": "Transitbröderna", "colony": "satellite_right"},
	{"id": "criminal_boss_k4_freja", "name": "Federal-Freja", "syndicate": "Federala ringen", "colony": "satellite_right"},
	{"id": "criminal_boss_k4_mans", "name": "Marknad-Måns", "syndicate": "Svartmarknaden", "colony": "satellite_right"},
]

const HENCHMAN_NAMES := [
	"Rost", "Kniv", "Plåt", "Kedja", "Rök", "Spik", "Tjära", "Svets", "Mörker", "Bly",
	"Klor", "Hugg", "Slag", "Gadd", "Bur", "Torn", "Vakt", "Skugga", "Bränn", "Kross",
]


static func get_hq_placements(spawn_id: String) -> Array:
	var id := SpawnPoints.normalize_id(spawn_id)
	match id:
		"satellite_right":
			return _neo_hqs()
		"satellite_left":
			return _hub_hqs(id, Vector3(120.0, 0.0, -80.0))
		"satellite_top_a":
			return _hub_hqs(id, Vector3(-90.0, 0.0, 110.0))
		"satellite_top_b":
			return _hub_hqs(id, Vector3(70.0, 0.0, -95.0))
		_:
			return []


static func get_npc_spawn_plan(spawn_id: String) -> Array:
	var out: Array = []
	var hqs := get_hq_placements(spawn_id)
	for hq in hqs:
		var boss_id := str(hq.get("boss_id", ""))
		var boss_def := get_boss_def(boss_id)
		if boss_def.is_empty():
			continue
		var local_pos: Vector3 = hq.get("local_pos", Vector3.ZERO)
		var yaw := float(hq.get("rotation_y", 0.0))
		out.append(_boss_entry(boss_def, local_pos + Vector3(0.0, 0.0, 6.0), yaw))
		var henchmen: Array = hq.get("henchmen", [])
		for i in range(henchmen.size()):
			var hench: Dictionary = henchmen[i]
			out.append(_henchman_entry(boss_id, hench, i, local_pos, yaw))
	return out


static func get_boss_def(boss_id: String) -> Dictionary:
	for boss in BOSSES:
		if str(boss.get("id", "")) == boss_id:
			return boss
	return {}


static func get_entry(npc_id: String) -> Dictionary:
	for spawn_id in SpawnPoints.IDS:
		for entry in get_npc_spawn_plan(spawn_id):
			if str(entry.get("id", "")) == npc_id:
				return entry
	return {}


static func _neo_hqs() -> Array:
	var spots: Array = [
		Vector3(-310.0, 0.0, -260.0),
		Vector3(350.0, 0.0, 210.0),
		Vector3(-380.0, 0.0, 170.0),
		Vector3(300.0, 0.0, -340.0),
		Vector3(-210.0, 0.0, 370.0),
	]
	return _hq_entries_for_colony("satellite_right", spots, true)


static func _hub_hqs(spawn_id: String, origin: Vector3) -> Array:
	var spots: Array = [
		origin + Vector3(720.0, 0.0, 840.0),
		origin + Vector3(-780.0, 0.0, 560.0),
		origin + Vector3(520.0, 0.0, -700.0),
		origin + Vector3(-640.0, 0.0, -760.0),
		origin + Vector3(860.0, 0.0, -420.0),
	]
	return _hq_entries_for_colony(spawn_id, spots, false)


static func _hq_entries_for_colony(spawn_id: String, spots: Array, use_dc_yaw: bool) -> Array:
	var out: Array = []
	var colony_bosses: Array = []
	for boss in BOSSES:
		if str(boss.get("colony", "")) == spawn_id:
			colony_bosses.append(boss)
	for i in range(mini(spots.size(), colony_bosses.size())):
		var boss: Dictionary = colony_bosses[i]
		var local_pos: Vector3 = spots[i]
		var yaw := atan2(local_pos.x, local_pos.z) + PI if use_dc_yaw else float(i) * 1.1
		out.append({
			"hq_id": "criminal_hq_%s" % str(boss.get("id", "")).replace("criminal_boss_", ""),
			"boss_id": str(boss.get("id", "")),
			"boss_name": str(boss.get("name", "Boss")),
			"syndicate": str(boss.get("syndicate", "Syndikat")),
			"local_pos": local_pos,
			"rotation_y": yaw,
			"label": "%s HQ" % str(boss.get("name", "")),
			"henchmen": _henchmen_offsets(i),
		})
	return out


static func _henchmen_offsets(seed: int) -> Array:
	return [
		{"offset": Vector3(14.0, 0.0, 10.0), "name": HENCHMAN_NAMES[(seed * 3) % HENCHMAN_NAMES.size()]},
		{"offset": Vector3(-12.0, 0.0, 11.0), "name": HENCHMAN_NAMES[(seed * 3 + 1) % HENCHMAN_NAMES.size()]},
		{"offset": Vector3(9.0, 0.0, -13.0), "name": HENCHMAN_NAMES[(seed * 3 + 2) % HENCHMAN_NAMES.size()]},
		{"offset": Vector3(-10.0, 0.0, -12.0), "name": HENCHMAN_NAMES[(seed * 3 + 4) % HENCHMAN_NAMES.size()]},
	]


static func _boss_entry(boss: Dictionary, local_pos: Vector3, yaw: float) -> Dictionary:
	var name := str(boss.get("name", "Boss"))
	return {
		"id": str(boss.get("id", "")),
		"criminal_boss": true,
		"criminal_boss_id": str(boss.get("id", "")),
		"boss_name": name,
		"syndicate": str(boss.get("syndicate", "")),
		"name": CriminalBossLoreScript.format_boss_title(name, str(boss.get("syndicate", ""))),
		"scale": 1.12,
		"local_pos": local_pos,
		"rotation_y": yaw,
		"wander": false,
		"prompt": "Prata med %s [E]" % name,
	}


static func _henchman_entry(
	boss_id: String,
	hench: Dictionary,
	index: int,
	hq_pos: Vector3,
	yaw: float
) -> Dictionary:
	var personal := str(hench.get("name", "Vakt"))
	var offset: Vector3 = hench.get("offset", Vector3.ZERO)
	return {
		"id": "%s_hench_%d" % [boss_id, index],
		"criminal_henchman": true,
		"criminal_boss_id": boss_id,
		"henchman_name": personal,
		"name": CriminalBossLoreScript.format_henchman_name(personal),
		"scale": 1.14,
		"local_pos": hq_pos + offset,
		"rotation_y": yaw + float(index) * 0.4,
		"wander": true,
		"wander_radius": 5.5,
		"speed": 0.95,
		"prompt": "Prata med %s [E]" % personal,
	}