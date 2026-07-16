class_name NpcCatalog
extends RefCounted

const DcZoneCatalogScript = preload("res://scripts/city/dc_zone_catalog.gd")
const Lore = preload("res://scripts/story/shawshank_lore.gd")
const ZezzlorLoreScript = preload("res://scripts/story/zezzlor_lore.gd")
const SrcGuardLoreScript = preload("res://scripts/story/src_guard_lore.gd")


static func get_spawn_plan(spawn_id: String) -> Array:
	var id := SpawnPoints.normalize_id(spawn_id)
	if id != "satellite_right":
		return []
	return [
		{
			"id": "npc_mara",
			"name": "Mara — koloniguide",
			"model": "character-k",
			"scale": 1.0,
			"local_pos": _cell_pos(Vector2i(2, 0)) + Vector3(-12.0, 0.0, 8.0),
			"rotation_y": PI * 0.85,
			"wander": true,
			"wander_radius": 10.0,
			"speed": 1.1,
			"prompt": "Prata med Mara [E]",
			"dialogue_title": "Mara — koloniguide",
			"dialogue_body": (
				"Välkommen till Neo-Washington, Koloni 4.\n"
				+ "Tryck H om du vill läsa intro-guiden — zoner, Mydrillium, markörer och mer.\n"
				+ "Zezzlor har kontrollpunkter runt spawn — stämpla Znood för att passera.\n"
				+ "Kapitolplazan ligger västerut. Undvik röda SRC-skyltar söderut."
			),
		},
		{
			"id": "npc_dr_ellis",
			"name": "Dr. Ellis — avhoppare",
			"model": "character-d",
			"scale": 1.0,
			"tint": Color(0.72, 0.82, 0.95),
			"local_pos": _cell_pos(Vector2i(-4, -3)) + Vector3(28.0, 0.0, 34.0),
			"rotation_y": -PI * 0.35,
			"wander": false,
			"wander_radius": 4.0,
			"speed": 0.0,
			"prompt": "Prata med Dr. Ellis [E]",
			"dialogue_title": "Dr. Ellis — tidigare SRC-forskare",
			"dialogue_body": (
				"Jag byggde synken för Projekt Redemption. Människa, spindel, robot — "
				+ "allt i samma nervsystem.\n\n"
				+ "När det misslyckas blir de zombies. Annexet är inte långt härifrån. "
				+ "Ta bevis innan nästa batch släpps."
			),
		},
		{
			"id": "npc_jonas",
			"name": "Jonas — överlevare",
			"model": "character-c",
			"scale": 1.0,
			"local_pos": Vector3(-24.0, 0.0, -58.0),
			"rotation_y": PI * 0.15,
			"wander": true,
			"wander_radius": 7.0,
			"speed": 0.9,
			"prompt": "Prata med Jonas [E]",
			"dialogue_title": "Jonas — kolonist",
			"dialogue_body": (
				"Jag såg något ragga sig ur tornen igår natt.\n"
				+ "Halva ansiktet var fortfarande mänskligt. Resten... surrade.\n\n"
				+ "%s ska 'återlösa' oss. Jag kallar det bara skräck."
				% Lore.COMPANY_SHORT
			),
		},
		{
			"id": "npc_guard_keller",
			"src_guard": true,
			"src_guard_role": "guard",
			"src_guard_name": "Keller",
			"model": "character-h",
			"scale": 1.05,
			"tint": SrcGuardLoreScript.UNIFORM_COLOR,
			"local_pos": _cell_pos(Vector2i(-5, 1)) + Vector3(6.0, 0.0, -6.0),
			"rotation_y": PI * 0.5,
			"wander": false,
			"wander_radius": 3.0,
			"speed": 0.0,
			"prompt": "Prata med SRC-vakt Keller [E]",
			"dialogue_title": SrcGuardLoreScript.format_dialogue_title("guard", "Keller"),
			"dialogue_body": (
				"Jag jobbar för Shawshank Security — inte Zezzlor.\n"
				+ "Utanför en kilometer från HQ låter vi folk vara.\n"
				+ "Men närmar du dig annexet börjar vi snoka — och lägga oss i.\n\n"
				+ "Zezzlor patrullerar kapitolplazan. Här gäller våra regler."
			),
		},
		{
			"id": "npc_guard_novak",
			"src_guard": true,
			"src_guard_role": "patrol",
			"src_guard_name": "Novak",
			"model": "character-g",
			"scale": 1.05,
			"tint": SrcGuardLoreScript.UNIFORM_COLOR,
			"local_pos": _cell_pos(Vector2i(-4, -3)) + Vector3(8.0, 0.0, -30.0),
			"rotation_y": -PI * 0.25,
			"wander": false,
			"wander_radius": 4.0,
			"speed": 0.0,
			"prompt": "Prata med SRC-patrull Novak [E]",
			"dialogue_title": SrcGuardLoreScript.format_dialogue_title("patrol", "Novak"),
			"dialogue_body": (
				"SRC HQ är låst. Znood räcker inte här — du behöver behörighet i vårt system.\n"
				+ "Inom en kilometer från HQ följer vi dig. Vi lägger oss i. Vi snokar.\n"
				+ "Utanför den zonen? Du får gå i fred.\n\n"
				+ "Försök inte smyga förbi. Kamrorna är värre än väktarna."
			),
		},
		{
			"id": "npc_priya",
			"name": "Priya — besökare",
			"model": "character-f",
			"scale": 1.0,
			"local_pos": _cell_pos(Vector2i(-2, 0)) + Vector3(0.0, 0.0, -6.0),
			"rotation_y": PI,
			"wander": true,
			"wander_radius": 14.0,
			"speed": 1.0,
			"prompt": "Prata med Priya [E]",
			"dialogue_title": "Priya — mallbesökare",
			"dialogue_body": (
				"De sa att Nationalmallen skulle vara som ett minnesmärke för framtiden.\n"
				+ "Obelisken lyser vackert — men varför luktar det ozon och blod vid tornen norrut?"
			),
		},
		{
			"id": "npc_capitol_clerk",
			"name": "Rami — kapitolsekreterare",
			"model": "character-n",
			"scale": 1.0,
			"tint": Color(0.95, 0.82, 0.35),
			"local_pos": _cell_pos(Vector2i(0, 0)) + Vector3(-14.0, 0.0, 10.0),
			"rotation_y": -PI * 0.6,
			"wander": false,
			"wander_radius": 5.0,
			"speed": 0.0,
			"prompt": "Prata med Rami [E]",
			"dialogue_title": "Rami — kapitolsekreterare",
			"dialogue_body": (
				"Neo-Washingtons kapitolplaza är öppen för medborgare.\n"
				+ "Zezzlor patrullerar zonen — se rangmärket bredvid namnet.\n"
				+ "Shawshank Corp har egna rödklädda väktare vid annex och torn.\n"
				+ "De är inte Zezzlor. Fråga inte vem som skrev deras kontrakt."
			),
		},
		{
			"id": "npc_lab_tech",
			"name": "Sven — labbtekniker",
			"model": "character-b",
			"scale": 1.0,
			"tint": Color(0.55, 0.95, 0.45),
			"local_pos": _cell_pos(Vector2i(-4, -3)) + Vector3(8.0, 0.0, 14.0),
			"rotation_y": PI * 0.2,
			"wander": true,
			"wander_radius": 6.0,
			"speed": 0.8,
			"prompt": "Prata med Sven [E]",
			"dialogue_title": "Sven — natttekniker",
			"dialogue_body": (
				"Jag kalibrerar bara drönarsensorerna, jag svär.\n"
				+ "Men ibland blinkar terminalerna 'REDEMPTION BATCH' när ingen är inloggad.\n"
				+ "Du kan ladda ner loggarna inne i annexet om du vågar."
			),
		},
	]


static func trigger_dialogue(npc_id: String) -> void:
	var entry := get_entry(npc_id)
	if entry.is_empty():
		return
	var title: String = str(entry.get("dialogue_title", entry.get("name", "NPC")))
	var body: String = str(entry.get("dialogue_body", "..."))
	body = _append_quest_hint(npc_id, body)
	QuestManager.story_toast.emit(title, body)


static func get_entry(npc_id: String) -> Dictionary:
	for entry in get_spawn_plan("satellite_right"):
		if str(entry.get("id", "")) == npc_id:
			return entry
	return {}


static func _append_quest_hint(npc_id: String, body: String) -> String:
	var step_id := QuestManager.get_current_step_id()
	match npc_id:
		"npc_dr_ellis", "npc_lab_tech":
			if step_id == "find_annex":
				return body + "\n\n[Tips] Annexet ligger söder om spawn — leta efter röda SRC-skyltar."
		"npc_jonas", "npc_guard_keller", "npc_guard_novak":
			if step_id == "witness_hybrids":
				return body + "\n\n[Tips] Hybridzombies vandrar nära bostadstornen norrut."
		"npc_mara":
			if step_id == "reach_koloni_4":
				return body + "\n\n[Tips] Tryck J för att öppna questjournalen."
	return body


static func _cell_pos(cell: Vector2i) -> Vector3:
	return Vector3(
		float(cell.x) * DcZoneCatalogScript.BLOCK_M + DcZoneCatalogScript.BLOCK_M * 0.5,
		0.0,
		float(cell.y) * DcZoneCatalogScript.BLOCK_M + DcZoneCatalogScript.BLOCK_M * 0.5
	)