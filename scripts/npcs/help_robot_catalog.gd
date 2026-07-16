class_name HelpRobotCatalog
extends RefCounted

const DC_BLOCK_M := 40.0


static func get_robot_label(spawn_id: String) -> String:
	var colony := SpawnPoints.get_colony_number(spawn_id)
	if colony > 0:
		return "Guide-Bot K%d" % colony
	return "Guide-Bot"


static func get_greeting() -> String:
	return "Hej! Behöver du hjälp? Välj en fråga nedan så guidar jag dig."


static func get_questions(spawn_id: String) -> Array:
	var id := SpawnPoints.normalize_id(spawn_id)
	var entries: Array = [
		{
			"id": "weapon_shop",
			"question": "Vart ligger vapenbutiken?",
			"answer": _weapon_shop_answer(id),
		},
		{
			"id": "laser_tower",
			"question": "Var hittar jag lasergevär?",
			"answer": _laser_tower_answer(id),
		},
		{
			"id": "pharmacy",
			"question": "Vart ligger apoteket?",
			"answer": _pharmacy_answer(id),
		},
		{
			"id": "movement",
			"question": "Hur rör jag mig?",
			"answer": (
				"WASD för att gå, musen för att titta runt. "
				+ "Håll Shift för att springa. Hoppa med mellanslag. "
				+ "Tryck E för att prata med mig och andra i världen."
			),
		},
		{
			"id": "spawn",
			"question": "Var är spawn och kolonins centrum?",
			"answer": _spawn_answer(id),
		},
		{
			"id": "currency",
			"question": "Vad är Mydrillium och hur tjänar jag det?",
			"answer": (
				"Mydrillium är kolonins valuta. Du ser saldot i HUD:en. "
				+ "Tjäna det genom uppdrag, byteshandel och aktivitet i kolonin. "
				+ "Apoteket och vapenbutiken tar betalt i Mydrillium."
			),
		},
		{
			"id": "znood",
			"question": "Vad gör Z-nood-enheten?",
			"answer": (
				"Z-nood (tangent Z) är din navigator. Den visar intressanta platser, "
				+ "vänner och kartmarkörer. Använd den när du letar efter butiker, "
				+ "uppdrag eller andra spelare."
			),
		},
	]
	if id == "satellite_right":
		entries.append({
			"id": "zones",
			"question": "Hur köper jag en zon i Neo-Washington?",
			"answer": (
				"Gå till ett ledigt gatublock i staden (gul markering på marken). "
				+ "Stå på zonen och tryck E — då öppnas en ruta med pris, saldo och info om zonköp. "
				+ "Köp eller hyr bekräftar du i rutan, inte direkt med E. "
				+ "Varje block är %d meter — Kapitoliet ligger vid spawn-plazan."
				% int(DC_BLOCK_M)
			),
		})
		entries.append({
			"id": "dc_landmarks",
			"question": "Vad finns att se i Koloni 4?",
			"answer": (
				"Neo-Washington har Kapitoliet vid spawn, Nationalmallen västerut, "
				+ "SRC-högkvarter i öster, apotek och vapenbutik nära plazan, "
				+ "samt zoner du kan äga block för block."
			),
		})
	return entries


static func _weapon_shop_answer(spawn_id: String) -> String:
	if spawn_id == "satellite_right":
		return (
			"Vapenbutiken ligger väster om spawn-plazan i Neo-Washington — "
			+ "ungefär 18 meter väster och 14 meter norr om centrum. "
			+ "Leta efter vapenskylten eller öppna Z-nood (Z) och välj vapenbutiken."
		)
	return (
		"Vapenbutiken ligger nära ankomstplattformen i din koloni, "
		+ "ungefär 24 meter väster och 20 meter norr om hub-centrum. "
		+ "Tryck E vid disken för att köpa vapen med Mydrillium."
	)


static func _laser_tower_answer(spawn_id: String) -> String:
	if spawn_id == "satellite_right":
		return (
			"Det lila lasertornet står öster om spawn-plazan — "
			+ "ungefär 22 meter öster och 12 meter söder om centrum. "
			+ "Gå in i höghuset och plocka upp lasergevär på våningsplanen [E]."
		)
	return (
		"Det lila lasertornet ligger nära ankomsthubben, "
		+ "ungefär 28 meter öster och 14 meter söder om centrum. "
		+ "Inuti tornet finns gratis lasergevär att plocka upp."
	)


static func _pharmacy_answer(spawn_id: String) -> String:
	if spawn_id == "satellite_right":
		return (
			"Apoteket med Pill-Bot ligger nordost om spawn-plazan — "
			+ "cirka 14 meter öster och 16 meter norr om centrum. "
			+ "Där kan du köpa Hybrid-Antidot om en SRC-zombie biter dig."
		)
	return (
		"Apoteket med Pill-Bot står vid ankomsthubben, "
		+ "ungefär 22 meter öster och 18 meter norr om centrum. "
		+ "Prata med Pill-Bot [E] om du blir förgiftad."
	)


static func _spawn_answer(spawn_id: String) -> String:
	if spawn_id == "satellite_right":
		return (
			"Du spawnar vid Kapitol-plazan i Neo-Washington (Koloni 4), "
			+ "ungefär 20 meter in från kubens hörn. "
			+ "Det är navet där vägar, butiker och zoner möts."
		)
	var name := SpawnPoints.get_spawn_name(spawn_id)
	return (
		"Du anländer vid %s:s ankomstplattform i kolonins hub. "
		+ "Följ golvmarkeringarna ut mot stadsdelarna — butiker och NPC:er ligger nära centrum."
		% name
	)