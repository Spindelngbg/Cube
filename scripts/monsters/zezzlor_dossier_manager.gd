extends Node

## Zezzlor antecknar vad de vet om varje spelare. Nollställs vid död.

const DcZoneOwnershipCatalogScript = preload("res://scripts/cube/dc_zone_ownership_catalog.gd")

var _records: Dictionary = {}


func reset_for_player(player_id: int) -> void:
	_records.erase(player_id)


func ensure_player(player_id: int) -> Dictionary:
	if not _records.has(player_id):
		_records[player_id] = _empty_record()
	return _records[player_id]


func record_crime(player_id: int, crime_pos: Vector3, spawn_id: String, npc_id: String) -> void:
	var rec := ensure_player(player_id)
	rec["crime_committed"] = true
	rec["crime_npc_id"] = npc_id
	rec["crime_location"] = _format_location(crime_pos, spawn_id)
	rec["zezzlor_alerted"] = true
	_append_note(rec, "Civilmord rapporterat vid %s." % rec["crime_location"])


func record_hunt_started(player_id: int) -> void:
	var rec := ensure_player(player_id)
	rec["zezzlor_alerted"] = true
	_append_note(rec, "Jaktformation utlöst mot misstänkt.")


func record_sighting(player_id: int, pos: Vector3, spawn_id: String, rank_id: String) -> void:
	var rec := ensure_player(player_id)
	rec["last_seen_location"] = _format_location(pos, spawn_id)
	rec["last_seen_time"] = Time.get_datetime_string_from_system()
	rec["sightings"] = int(rec.get("sightings", 0)) + 1
	var rank := rank_id if rank_id != "" else "patrol"
	if rank not in rec.get("ranks_spotted", []):
		rec["ranks_spotted"] = rec.get("ranks_spotted", []) + [rank]


func record_target_lost(player_id: int, last_pos: Vector3, spawn_id: String) -> void:
	var rec := ensure_player(player_id)
	rec["times_lost"] = int(rec.get("times_lost", 0)) + 1
	rec["last_known_location"] = _format_location(last_pos, spawn_id)
	_append_note(
		rec,
		"Misstänkt försvunnen bakom bebyggelse vid %s. Sökinsats utlöst."
		% rec["last_known_location"]
	)


func record_target_found(player_id: int, pos: Vector3, spawn_id: String) -> void:
	var rec := ensure_player(player_id)
	rec["times_refound"] = int(rec.get("times_refound", 0)) + 1
	_append_note(rec, "Visuell kontakt återupprättad vid %s." % _format_location(pos, spawn_id))


func record_laser_shot(player_id: int, hit: bool) -> void:
	var rec := ensure_player(player_id)
	rec["shots_fired"] = int(rec.get("shots_fired", 0)) + 1
	if hit:
		rec["hits_landed"] = int(rec.get("hits_landed", 0)) + 1
		_append_note(rec, "Röd lasermarkering träffade målet.")


func record_baton_strike(player_id: int) -> void:
	var rec := ensure_player(player_id)
	rec["baton_strikes"] = int(rec.get("baton_strikes", 0)) + 1
	_append_note(rec, "Batongingripande registrerat på plats.")


func record_dialogue(player_id: int, response_id: String) -> void:
	var rec := ensure_player(player_id)
	var lines: Array = rec.get("dialogue_lines", [])
	if response_id not in lines:
		lines.append(response_id)
	rec["dialogue_lines"] = lines
	_append_note(rec, "Förhör: svar \"%s\" antecknat." % response_id)


func record_weapon(player_id: int, weapon_name: String) -> void:
	if weapon_name.strip_edges() == "":
		return
	var rec := ensure_player(player_id)
	if weapon_name == rec.get("weapon_observed", ""):
		return
	rec["weapon_observed"] = weapon_name
	_append_note(rec, "Observerat vapen: %s." % weapon_name)


func get_report_text(player_id: int) -> String:
	if not _records.has(player_id):
		return (
			"ZEZZLOR DOSSIER\n"
			+ "────────────────\n"
			+ "Ingen aktiv profil. Kolonist har inte registrerats i ordningsmatrisen."
		)
	var rec: Dictionary = _records[player_id]
	var lines: PackedStringArray = []
	lines.append("ZEZZLOR DOSSIER — KONFIDENTIELLT")
	lines.append("────────────────────────────────")
	lines.append("Status: %s" % ("AKTIV JAKT" if rec.get("zezzlor_alerted", false) else "Övervakning"))
	if rec.get("crime_committed", false):
		lines.append("Brott: Civilmord (%s)" % str(rec.get("crime_npc_id", "?")))
		lines.append("Brottsplats: %s" % str(rec.get("crime_location", "?")))
	if rec.get("weapon_observed", "") != "":
		lines.append("Vapen: %s" % rec["weapon_observed"])
	if rec.get("last_seen_location", "") != "":
		lines.append("Senast sedd: %s" % rec["last_seen_location"])
	if rec.get("last_known_location", "") != "":
		lines.append("Senast kända position: %s" % rec["last_known_location"])
	lines.append(
		"Siktningar: %d | Förlorad spårning: %d | Återfunnen: %d"
		% [
			int(rec.get("sightings", 0)),
			int(rec.get("times_lost", 0)),
			int(rec.get("times_refound", 0)),
		]
	)
	lines.append(
		"Skott avlossade: %d | Träffar: %d | Batong: %d"
		% [
			int(rec.get("shots_fired", 0)),
			int(rec.get("hits_landed", 0)),
			int(rec.get("baton_strikes", 0)),
		]
	)
	var notes: Array = rec.get("notes", [])
	if notes.is_empty():
		lines.append("")
		lines.append("Anteckningar: (tomt)")
	else:
		lines.append("")
		lines.append("Anteckningar:")
		var start := maxi(0, notes.size() - 8)
		for i in range(start, notes.size()):
			lines.append("• %s" % str(notes[i]))
	lines.append("")
	lines.append("Dossier nollställs vid död enligt koloniprotokoll.")
	return "\n".join(lines)


func has_active_dossier(player_id: int) -> bool:
	return _records.has(player_id) and bool(_records[player_id].get("zezzlor_alerted", false))


func _empty_record() -> Dictionary:
	return {
		"crime_committed": false,
		"crime_npc_id": "",
		"crime_location": "",
		"zezzlor_alerted": false,
		"weapon_observed": "",
		"last_seen_location": "",
		"last_known_location": "",
		"last_seen_time": "",
		"sightings": 0,
		"times_lost": 0,
		"times_refound": 0,
		"shots_fired": 0,
		"hits_landed": 0,
		"baton_strikes": 0,
		"ranks_spotted": [],
		"dialogue_lines": [],
		"notes": [],
	}


func _append_note(rec: Dictionary, line: String) -> void:
	var notes: Array = rec.get("notes", [])
	notes.append(line)
	if notes.size() > 24:
		notes = notes.slice(notes.size() - 24)
	rec["notes"] = notes


func _format_location(pos: Vector3, spawn_id: String) -> String:
	if spawn_id == "satellite_right":
		var entry := DcZoneOwnershipCatalogScript.world_to_zone_id(pos, spawn_id)
		if entry != "":
			return DcZoneOwnershipCatalogScript.get_zone_display_name(entry)
	return "X%.0f Z%.0f" % [pos.x, pos.z]