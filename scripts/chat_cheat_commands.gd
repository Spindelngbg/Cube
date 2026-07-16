class_name ChatCheatCommands
extends RefCounted

const DevWeaponToolsScript = preload("res://scripts/dev/dev_weapon_tools.gd")

const CHEATER_NAMES := ["test", "testare1"]

const WEAPON_IDS := [
	"slimeshooter",
	"laserrifle",
	"mountblast_3000",
	"neon_stinger_mk2",
	"corrosion_cannon_x9",
	"plasma_ripper_7",
	"voltthrower_ultra",
	"shadow_fang",
	"chitin_cleaver",
	"hsg_survival_axe",
	"src_stiletto",
	"redemption_blade",
	"zezzlor_gut_knife",
]

const MATERIAL_IDS := [
	"raw_mydrillium_ore",
	"mydrillium_sludge",
	"tech_scrap",
	"contaminated_ore",
]


static func is_cheater(extra_name: String = "") -> bool:
	var names: Array[String] = [
		str(Auth.username).strip_edges(),
		str(Profile.active_character_name).strip_edges(),
		extra_name.strip_edges(),
	]
	for n in names:
		if n.to_lower() in CHEATER_NAMES:
			return true
	return false


static func try_execute(tree: SceneTree, raw: String, extra_name: String = "") -> String:
	if not is_cheater(extra_name):
		if _looks_like_cheat_attempt(raw):
			return "Cheat avstängt — logga in som Test eller testare1."
		return ""
	var text := raw.strip_edges()
	if text.is_empty():
		return ""
	if text.begins_with("/"):
		return _run_slash_command(tree, text)
	return _run_secret_code(tree, text)


static func _looks_like_cheat_attempt(raw: String) -> bool:
	var t := raw.strip_edges()
	if t.begins_with("/"):
		return true
	var upper := t.to_upper().replace(" ", "")
	return upper in [
		"SHAWSHANK", "REDEMPTION", "GETBUSY", "IDDQD", "IDKFA", "PILLBOT",
		"ALLMAKARE", "SPIDERMAN", "NEOWASH", "KONAMI", "BROOKS", "ANDY",
		"ZUES", "ZEZZLOR", "FATSTACK", "CUBETEST",
	]


static func _run_slash_command(tree: SceneTree, raw: String) -> String:
	var parts := raw.split(" ", false)
	if parts.is_empty():
		return ""
	var cmd := str(parts[0]).to_lower()
	match cmd:
		"/cheats", "/help":
			return _cheats_help_text()
		"/spawn":
			return _cmd_spawn(tree, parts)
		"/heal", "/hp":
			return _cmd_heal(tree)
		"/god":
			return _cmd_god()
		"/money", "/mydrillium", "/md":
			return _cmd_money(parts)
		"/item", "/give":
			return _cmd_item(parts)
		"/weapon", "/vapen":
			return _cmd_weapon(parts)
		"/kit":
			return _cmd_kit()
		"/cure", "/antidote":
			return _cmd_cure()
		"/poison", "/gift":
			return _cmd_poison()
		"/tp", "/teleport":
			return _cmd_tp(tree, parts)
		"/kill", "/suicide":
			return _cmd_kill(tree)
		"/materials", "/mat":
			return _cmd_materials()
		"/fatstack", "/max":
			return _cmd_fatstack(tree)
		"/colony":
			return _cmd_spawn(tree, ["/spawn", str(parts[1]) if parts.size() > 1 else ""])
		"/unjail":
			return _cmd_unjail(tree)
		_:
			return "Okänt kommando: %s — skriv /cheats" % cmd


static func _run_secret_code(tree: SceneTree, raw: String) -> String:
	var code := raw.strip_edges().to_upper().replace(" ", "")
	match code:
		"SHAWSHANK":
			_cmd_money_packed(25000)
			return "Shawshank: +25 000 Mydrillium."
		"REDEMPTION":
			_grant_items(["redemption_tonic", "psyxxrum_serum"])
			return "Redemption: serum och tonic i inventory."
		"GETBUSY", "GETBUSYLIVING":
			_grant_all_weapons()
			return "Get busy living: alla vapen utdelade."
		"IDDQD":
			CheatState.set_god_mode(true)
			_cmd_heal(tree)
			return "IDDQD: odödlighet PÅ + full HP."
		"IDKFA":
			CheatState.set_god_mode(false)
			_grant_all_weapons()
			_cmd_money_packed(50000)
			_cmd_heal(tree)
			return "IDKFA: alla vapen, 50 000 Md, full HP."
		"PILLBOT":
			InventoryManager.add_item("hybrid_antidote")
			PoisonManager.cure()
			return "Pill-Bot: antidot + gift borta."
		"ALLMAKARE":
			_cmd_money_packed(999999)
			return "Allmakare: 999 999 Mydrillium."
		"SPIDERMAN":
			WeaponManager.grant_slimeshooter(true)
			return "Spiderman: Slimeshooter utrustad."
		"NEOWASH", "WASHINGTON":
			return _cmd_spawn(tree, ["/spawn", "4"])
		"KONAMI":
			_cmd_kit()
			_cmd_money_packed(7777)
			return "KONAMI: startkit + 7 777 Md."
		"BROOKS":
			InventoryManager.add_item("chitin_patch")
			InventoryManager.add_item("koloni_ration")
			return "Brooks: ration och kitinplåster."
		"ANDY":
			return _cmd_spawn(tree, ["/spawn", "1"])
		"ZUES", "ZEUS", "ZEZZLOR":
			_cmd_heal(tree)
			PoisonManager.cure()
			return "Zeus/Zezzlor: full HP, gift borta."
		"FATSTACK":
			return _cmd_fatstack(tree)
		"CUBETEST":
			return "Cube-testläge OK — skriv /cheats för alla kommandon."
		_:
			return ""


static func _cheats_help_text() -> String:
	return (
		"=== CUBE CHEATS (Test / testare1) ===\n"
		+ "/spawn 1-4 | /spawn home — byt koloni\n"
		+ "/heal — full HP | /god — odödlighet av/på\n"
		+ "/money [antal] — Mydrillium (default 10 000)\n"
		+ "/item [id] — föremål | /weapon all|slime|laser|…\n"
		+ "/kit — ration, plåster, antidot, slime\n"
		+ "/cure — bota gift | /poison — testa gift\n"
		+ "/tp [x] [z] — teleportera | /kill — dö/respawn\n"
		+ "/materials — malm x99 | /fatstack — allt\n"
		+ "/unjail — släpp från Zezzlor-fängelse\n"
		+ "Kodord (utan /): SHAWSHANK, REDEMPTION, GETBUSY,\n"
		+ "IDDQD, IDKFA, PILLBOT, ALLMAKARE, SPIDERMAN,\n"
		+ "NEOWASH, KONAMI, BROOKS, ANDY, ZEZZLOR, FATSTACK"
	)


static func _cmd_spawn(tree: SceneTree, parts: PackedStringArray) -> String:
	if parts.size() < 2:
		return "Användning: /spawn 1|2|3|4 eller /spawn home"
	var token := str(parts[1]).strip_edges().to_lower()
	if token == "home" or token == "hem":
		GameFlow.clear_debug_spawn_override()
		var home_id := (
			SpawnPoints.ensure_colony_id(Profile.active_home_spawn_id)
			if Profile.has_home_spawn()
			else SpawnPoints.default_colony_id()
		)
		tree.change_scene_to_file("res://scenes/game.tscn")
		return "Återgår till %s..." % SpawnPoints.get_colony_label(home_id)
	var spawn_id := SpawnPoints.resolve_spawn_token(token)
	if spawn_id == "" or not SpawnPoints.is_valid(spawn_id):
		return "Ogiltig koloni — använd 1–4."
	var pos := SpawnPoints.get_play_spawn_position(spawn_id)
	if not GameFlow.set_debug_spawn_and_reload(spawn_id, tree):
		return "Kunde inte byta till %s." % SpawnPoints.get_colony_label(spawn_id)
	return "Byter till %s (%.0f, %.0f)..." % [SpawnPoints.get_colony_label(spawn_id), pos.x, pos.z]


static func _cmd_heal(tree: SceneTree) -> String:
	var player := _local_player(tree)
	if player == null:
		return "Ingen spelare i världen — gå in i en koloni först."
	if player.has_method("heal_to_full"):
		player.heal_to_full()
	return "Full HP."


static func _cmd_god() -> String:
	var on := CheatState.toggle_god_mode()
	return "God mode: %s." % ("PÅ" if on else "AV")


static func _cmd_money(parts: PackedStringArray) -> String:
	var amount := 10000
	if parts.size() > 1 and str(parts[1]).is_valid_int():
		amount = maxi(int(parts[1]), 0)
	_cmd_money_packed(amount)
	return "+%s %s." % [_fmt_int(amount), ItemCatalog.currency_symbol()]


static func _cmd_money_packed(amount: int) -> void:
	if amount > 0:
		InventoryManager.add_mydrillium(amount)


static func _cmd_item(parts: PackedStringArray) -> String:
	if parts.size() < 2:
		return "Användning: /item [id] — t.ex. /item laserrifle"
	var item_id := str(parts[1]).strip_edges().to_lower()
	if ItemCatalog.get_item(item_id).is_empty():
		return "Okänt föremål: %s" % item_id
	if not InventoryManager.add_item(item_id):
		return "Kunde inte ge %s (fullt inventory?)." % item_id
	return "Gav %s." % ItemCatalog.get_display_name(item_id)


static func _cmd_weapon(parts: PackedStringArray) -> String:
	var token := str(parts[1]).strip_edges().to_lower() if parts.size() > 1 else "all"
	match token:
		"all", "alla", "*":
			_grant_all_weapons()
			return "Alla vapen utdelade."
		"slime", "slimeshooter":
			WeaponManager.grant_slimeshooter(true)
			return "Slimeshooter utrustad."
		"laser", "laserrifle":
			WeaponManager.grant_laserrifle(true)
			return "Lasergevär utrustat."
		_:
			if token in WEAPON_IDS:
				InventoryManager.add_item(token)
				WeaponManager.equip(token)
				return "%s utrustat." % ItemCatalog.get_display_name(token)
			return "Okänt vapen. Prova: all, slime, laser eller vapen-id."


static func _cmd_kit() -> String:
	_grant_items(["koloni_ration", "chitin_patch", "hybrid_antidote"])
	WeaponManager.grant_slimeshooter(true)
	return "Startkit: ration, plåster, antidot, Slimeshooter."


static func _cmd_cure() -> String:
	PoisonManager.cure()
	return "Gift borta."


static func _cmd_poison() -> String:
	PoisonManager.apply_bite()
	return "Du är förgiftad (test)."


static func _cmd_tp(tree: SceneTree, parts: PackedStringArray) -> String:
	var player := _local_player(tree)
	if player == null:
		return "Teleportera funkar bara inne i en koloni."
	if parts.size() < 3:
		return "Användning: /tp [x] [z] — t.ex. /tp 29210 15020"
	if not str(parts[1]).is_valid_float() or not str(parts[2]).is_valid_float():
		return "Ogiltiga koordinater."
	var logical := Vector3(float(parts[1]), SpawnPoints.SPAWN_FOOT_Y, float(parts[2]))
	var pos: Vector3 = logical
	var game := tree.get_first_node_in_group("game_director")
	if game != null and game.has_method("shift_world_position"):
		pos = game.shift_world_position(logical)
	player.global_position = pos
	if player.has_method("set_spawn_anchor"):
		player.set_spawn_anchor(pos)
	if player.has_method("ensure_safe_ground"):
		player.ensure_safe_ground()
	return "Teleporterad till (%.0f, %.0f)." % [pos.x, pos.z]


static func _cmd_kill(tree: SceneTree) -> String:
	var player := _local_player(tree)
	if player == null:
		return "Ingen spelare att döda."
	if player.has_method("take_damage"):
		player.take_damage(99999.0)
	return "Du dog — respawn om 3 s."


static func _cmd_materials() -> String:
	for material_id in MATERIAL_IDS:
		InventoryManager.add_material(material_id, 99)
	return "Material x99 utdelat."


static func _cmd_fatstack(tree: SceneTree) -> String:
	_cmd_money_packed(100000)
	_grant_all_weapons()
	_grant_items(["psyxxrum_serum", "redemption_tonic", "hybrid_antidote", "koloni_ration"])
	for material_id in MATERIAL_IDS:
		InventoryManager.add_material(material_id, 50)
	CheatState.set_god_mode(true)
	_cmd_heal(tree)
	PoisonManager.cure()
	return "Fatstack: pengar, vapen, buffs, material, god mode, full HP."


static func _cmd_unjail(tree: SceneTree) -> String:
	var player := _local_player(tree)
	if player == null:
		return "Ingen spelare i världen."
	if player.has_method("is_zezzlor_jailed") and player.is_zezzlor_jailed():
		if player.has_method("release_from_zezzlor_jail"):
			player.release_from_zezzlor_jail()
		return "Släppt från Zezzlor-fängelset."
	return "Du sitter inte i fängelse."


static func _grant_all_weapons() -> void:
	for weapon_id in WEAPON_IDS:
		InventoryManager.add_item(weapon_id)
	if WeaponManager.grant_laserrifle(false):
		pass
	WeaponManager.equip("zezzlor_gut_knife")


static func _grant_items(item_ids: Array) -> void:
	for raw_id in item_ids:
		InventoryManager.add_item(str(raw_id))


static func _local_player(tree: SceneTree) -> Node3D:
	var game := tree.get_first_node_in_group("game_director")
	if game != null and game.has_method("get_local_player"):
		return game.get_local_player()
	return null


static func _fmt_int(value: int) -> String:
	var s := str(value)
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = " " + out
		out = s[i] + out
		count += 1
	return out