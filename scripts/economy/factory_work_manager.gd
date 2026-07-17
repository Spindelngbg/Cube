extends Node

## Skiftarbete i Koloni 4:s verkstadsfabrik — minigame med stationer + lön.

const FactoryWorkerCatalogScript = preload("res://scripts/npcs/factory_worker_catalog.gd")

signal shift_changed
signal station_used(station_id: String)

const BASE_CYCLE_PAY := 55
const STREAK_BONUS := 12
const MAX_STREAK_BONUS := 48
const WRONG_STATION_COOLDOWN := 0.35

## Ordning i en arbetscykel (efter stämpling).
const CYCLE_STEPS: Array[String] = [
	"intake",
	"console",
	"press",
	"pack",
	"load",
]

const STATION_LABELS := {
	"clock": "Stämpelklocka",
	"intake": "Rågods-intag",
	"console": "Transportband",
	"press": "Pressmaskin",
	"pack": "Packbord",
	"load": "Lastbrygga",
}

const CARRY_LABELS := {
	"": "ingenting",
	"raw": "råkorg",
	"processed": "halvfabrikat",
	"packed": "färdig låda",
}

var _on_shift := false
var _step_index := 0
var _carrying := ""
var _cycles_done := 0
var _streak := 0
var _shift_earned := 0
var _wrong_cd := 0.0
var _stations: Dictionary = {} ## station_id -> StoryInteractable


func _process(delta: float) -> void:
	if _wrong_cd > 0.0:
		_wrong_cd = maxf(0.0, _wrong_cd - delta)


func is_on_shift() -> bool:
	return _on_shift


func get_carrying() -> String:
	return _carrying


func get_cycles_done() -> int:
	return _cycles_done


func get_shift_earned() -> int:
	return _shift_earned


func get_hud_hint() -> String:
	if not _on_shift:
		return ""
	var next_id := _current_step_id()
	var label := str(STATION_LABELS.get(next_id, next_id))
	var carry := str(CARRY_LABELS.get(_carrying, _carrying))
	return "Fabriksjobb: %s | bär: %s | cykler: %d | +%d %s" % [
		label,
		carry,
		_cycles_done,
		_shift_earned,
		ItemCatalog.currency_symbol(),
	]


func register_station(station_id: String, area: Area3D) -> void:
	if station_id == "" or area == null:
		return
	_stations[station_id] = area
	_refresh_station_prompts()


func clear_stations() -> void:
	_stations.clear()


func on_interact(interact_id: String) -> void:
	if interact_id.begins_with("factory_worker_"):
		_open_worker_talk(interact_id)
		return
	if interact_id.begins_with("factory_"):
		var station_id := interact_id.trim_prefix("factory_")
		use_station(station_id)


func use_station(station_id: String) -> void:
	if _wrong_cd > 0.0:
		return
	match station_id:
		"clock":
			_use_clock()
		"intake", "console", "press", "pack", "load":
			_use_cycle_station(station_id)
		_:
			pass
	_refresh_station_prompts()
	station_used.emit(station_id)
	shift_changed.emit()


func get_station_prompt(station_id: String) -> String:
	var label := str(STATION_LABELS.get(station_id, "Station"))
	if station_id == "clock":
		if _on_shift:
			return "Stämpla ut — avsluta skift [E]"
		return "Stämpla in — börja jobba [E]"
	if not _on_shift:
		return "%s (stämpla in först) [E]" % label
	if station_id == _current_step_id():
		return _active_prompt(station_id)
	return "%s [E]" % label


func _active_prompt(station_id: String) -> String:
	match station_id:
		"intake":
			return "Hämta råkorg [E]"
		"console":
			return "Starta transportband [E]"
		"press":
			return "Kör pressmaskin [E]"
		"pack":
			return "Packa låda [E]"
		"load":
			return "Lämna låda på lastbrygga [E]"
		_:
			return "Arbeta [E]"


func _use_clock() -> void:
	if _on_shift:
		_clock_out()
	else:
		_clock_in()


func _clock_in() -> void:
	_on_shift = true
	_step_index = 0
	_carrying = ""
	_cycles_done = 0
	_streak = 0
	_shift_earned = 0
	QuestManager.story_toast.emit(
		"Fabrik — skift startat",
		"Välkommen till Industrikajens verkstad.\n"
		+ "1) Hämta rågods  2) Starta band  3) Pressa  4) Packa  5) Lämna last\n"
		+ "Prata gärna med kollegorna — de är människor, inte skyltdockor."
	)


func _clock_out() -> void:
	_on_shift = false
	_carrying = ""
	_step_index = 0
	var msg := "Du stämplade ut."
	if _shift_earned > 0:
		msg += "\nIntjänat den här skiften: %d %s (%d cykler)." % [
			_shift_earned,
			ItemCatalog.currency_symbol(),
			_cycles_done,
		]
	else:
		msg += "\nInga färdiga cykler — ingen extra lön den här gången."
	QuestManager.story_toast.emit("Fabrik — skift slut", msg)
	_shift_earned = 0
	_cycles_done = 0
	_streak = 0


func _use_cycle_station(station_id: String) -> void:
	if not _on_shift:
		QuestManager.story_toast.emit(
			"Fabrik",
			"Du är inte instämplad. Använd stämpelklockan vid entrén först."
		)
		_wrong_cd = WRONG_STATION_COOLDOWN
		return
	var expected := _current_step_id()
	if station_id != expected:
		_wrong_station(station_id, expected)
		return

	match station_id:
		"intake":
			_carrying = "raw"
			QuestManager.story_toast.emit(
				"Rågods",
				"Du lyfter en råkorg. Tung, metallisk, doftar olja och hopp.\nGå till transportbandets konsol."
			)
		"console":
			if _carrying != "raw":
				_soft_fail("Du behöver en råkorg först.")
				return
			QuestManager.story_toast.emit(
				"Transportband",
				"Du trycker grön start. Bandet knarrar till liv och matar pressen.\nGå till pressmaskinen."
			)
		"press":
			if _carrying != "raw":
				_soft_fail("Utan rågods har pressen inget att bita i.")
				return
			_carrying = "processed"
			QuestManager.story_toast.emit(
				"Press",
				"Hydrauliken suckar. Halvfabrikatet glänser svagt.\nBär det till packbordet."
			)
		"pack":
			if _carrying != "processed":
				_soft_fail("Packbordet väntar på pressat gods — inte tomma händer.")
				return
			_carrying = "packed"
			QuestManager.story_toast.emit(
				"Packning",
				"Tejp, etikett, stämpel. Lådan är klar för last.\nTill lastbryggan."
			)
		"load":
			if _carrying != "packed":
				_soft_fail("Lastbryggan tar bara färdiga lådor.")
				return
			_complete_cycle()
			return

	_step_index += 1


func _complete_cycle() -> void:
	_carrying = ""
	_cycles_done += 1
	_streak += 1
	var pay := BASE_CYCLE_PAY + mini(_streak * STREAK_BONUS, MAX_STREAK_BONUS)
	# Liten random variation så det känns levande.
	pay += (_cycles_done % 3) * 3
	InventoryManager.add_mydrillium(pay)
	_shift_earned += pay
	_step_index = 0
	QuestManager.story_toast.emit(
		"Leverans klar — +%d %s" % [pay, ItemCatalog.currency_symbol()],
		"Cykel %d klar. Streak ×%d.\n"
		% [_cycles_done, _streak]
		+ "Hämta nästa råkorg, eller stämpla ut när du är nöjd."
	)


func _wrong_station(got: String, expected: String) -> void:
	_wrong_cd = WRONG_STATION_COOLDOWN
	_streak = 0
	QuestManager.story_toast.emit(
		"Fel station",
		"Du tryckte på %s, men nästa steg är %s.\n"
		% [
			str(STATION_LABELS.get(got, got)),
			str(STATION_LABELS.get(expected, expected)),
		]
		+ "Följ flödet: intag → band → press → pack → last."
	)


func _soft_fail(msg: String) -> void:
	_wrong_cd = WRONG_STATION_COOLDOWN
	QuestManager.story_toast.emit("Fabriken fnyser", msg)


func _current_step_id() -> String:
	if CYCLE_STEPS.is_empty():
		return ""
	return CYCLE_STEPS[_step_index % CYCLE_STEPS.size()]


func _refresh_station_prompts() -> void:
	for station_id in _stations:
		var area: Area3D = _stations[station_id]
		if area == null or not is_instance_valid(area):
			continue
		if "prompt_text" in area:
			area.prompt_text = get_station_prompt(str(station_id))


func _open_worker_talk(npc_id: String) -> void:
	var game := get_tree().get_first_node_in_group("game_director")
	if game == null:
		return
	if game.has_method("open_factory_worker_dialog"):
		game.open_factory_worker_dialog(npc_id)
		return
	# Fallback: toast med en rad om UI saknas.
	var line: Dictionary = FactoryWorkerCatalogScript.pick_open_line(npc_id, _on_shift, _cycles_done)
	QuestManager.story_toast.emit(
		str(line.get("title", "Kollega")),
		str(line.get("body", "..."))
	)
