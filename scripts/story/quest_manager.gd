extends Node

const Lore = preload("res://scripts/story/shawshank_lore.gd")
const NpcCatalogScript = preload("res://scripts/npcs/npc_catalog.gd")
const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")

signal quest_started(quest_id: String)
signal quest_step_changed(quest_id: String, step_index: int)
signal quest_completed(quest_id: String)
signal story_toast(title: String, body: String)

const QUESTS_PATH := "res://data/story/shawshank_questline.json"
const MAIN_QUEST_ID := "operation_redemption"

var _quest_data: Dictionary = {}
var _progress: Dictionary = {}
var _save_slot := "guest"


func _ready() -> void:
	_load_definitions()
	Profile.character_selected.connect(_on_character_selected)
	_on_character_selected()


func get_company_name() -> String:
	return Lore.COMPANY_NAME


func is_quest_active(quest_id: String = MAIN_QUEST_ID) -> bool:
	return _progress.has(quest_id) and not bool(_progress[quest_id].get("completed", false))


func is_quest_completed(quest_id: String = MAIN_QUEST_ID) -> bool:
	return _progress.has(quest_id) and bool(_progress[quest_id].get("completed", false))


func get_current_step_index(quest_id: String = MAIN_QUEST_ID) -> int:
	if not _progress.has(quest_id):
		return -1
	return int(_progress[quest_id].get("step_index", 0))


func get_current_step(quest_id: String = MAIN_QUEST_ID) -> Dictionary:
	var quest := _get_quest_def(quest_id)
	if quest.is_empty():
		return {}
	var idx := get_current_step_index(quest_id)
	if idx < 0:
		return {}
	var steps: Array = quest.get("steps", [])
	if idx >= steps.size():
		return {}
	return steps[idx]


func get_journal_entries() -> Array:
	var entries: Array = []
	for quest_id in _quest_data.get("quests", {}).keys():
		var quest: Dictionary = _quest_data.quests[quest_id]
		var prog: Dictionary = _progress.get(quest_id, {})
		var idx := int(prog.get("step_index", 0))
		var completed := bool(prog.get("completed", false))
		var steps: Array = quest.get("steps", [])
		var current: Dictionary = steps[idx] if idx < steps.size() else {}
		entries.append({
			"id": quest_id,
			"title": quest.get("title", quest_id),
			"company": quest.get("company", ""),
			"tagline": quest.get("tagline", ""),
			"completed": completed,
			"step_index": idx,
			"step_count": steps.size(),
			"current_title": current.get("title", ""),
			"current_objective": _objective_text(quest_id, current),
			"current_briefing": current.get("briefing", ""),
		})
	return entries


func start_quest(quest_id: String = MAIN_QUEST_ID, silent: bool = false) -> void:
	if _progress.has(quest_id) and not bool(_progress[quest_id].get("completed", false)):
		return
	_progress[quest_id] = {
		"step_index": 0,
		"completed": false,
		"evidence_count": 0,
		"witness_count": 0,
		"witnessed_ids": [],
	}
	_save_progress()
	quest_started.emit(quest_id)
	if not silent:
		_emit_step_toast(quest_id)


func on_interact(interact_id: String) -> void:
	if interact_id.begins_with("allmakare_"):
		_trigger_allmakare(interact_id)
		return
	if interact_id.begins_with("gleazer_"):
		_trigger_gleazer(interact_id)
		return
	if interact_id.begins_with("npc_"):
		NpcCatalogScript.trigger_dialogue(interact_id)
		return
	match interact_id:
		"src_leaked_memo":
			if not _progress.has(MAIN_QUEST_ID):
				start_quest(MAIN_QUEST_ID)
			story_toast.emit("Läckt internt memo", Lore.LEAKED_MEMO)
			_complete_step(MAIN_QUEST_ID, "read_memo")
		"src_annex_entry":
			story_toast.emit(
				Lore.COMPANY_SHORT + " Annex",
				"Fältlabbet luktar desinfektionsmedel och varm kretskort. Terminalerna är fortfarande aktiva."
			)
			_complete_step(MAIN_QUEST_ID, "find_annex")
		"src_terminal_a", "src_terminal_b", "src_terminal_c":
			_collect_evidence(interact_id)
		"src_main_console":
			if not _progress.has(MAIN_QUEST_ID):
				return
			if int(_progress[MAIN_QUEST_ID].get("evidence_count", 0)) < 3:
				story_toast.emit(
					"Saknar bevis",
					"Ladda ner alla tre filer från SRC-terminalerna innan du saboterar konsolen."
				)
				return
			_complete_step(MAIN_QUEST_ID, "sabotage_console")


func on_enter_colony(spawn_id: String) -> void:
	var id := SpawnPoints.normalize_id(spawn_id)
	if id != "satellite_right":
		return
	if not _progress.has(MAIN_QUEST_ID):
		start_quest(MAIN_QUEST_ID, true)
	if get_current_step_id() == "read_memo":
		_progress[MAIN_QUEST_ID]["step_index"] = 1
		_save_progress()
	_complete_step(MAIN_QUEST_ID, "reach_koloni_4", true)


func tick_hybrid_witness(player_pos: Vector3, hybrids: Array) -> void:
	if not is_quest_active() or get_current_step_id() != "witness_hybrids":
		return
	var prog: Dictionary = _progress[MAIN_QUEST_ID]
	var witnessed: Array = prog.get("witnessed_ids", [])
	for hybrid in hybrids:
		if not hybrid is Node3D:
			continue
		if hybrid.global_position.distance_to(player_pos) > 28.0:
			continue
		var hid: int = hybrid.get_instance_id()
		if witnessed.has(hid):
			continue
		witnessed.append(hid)
		prog["witnessed_ids"] = witnessed
		prog["witness_count"] = witnessed.size()
		_save_progress()
		story_toast.emit(
			"Hybrid upptäckt",
			"En SRC-zombie vandrar förbi — del människa, del spindel, del maskin."
		)
		if witnessed.size() >= 2:
			_complete_step(MAIN_QUEST_ID, "witness_hybrids")
		break


func get_current_step_id(quest_id: String = MAIN_QUEST_ID) -> String:
	var step := get_current_step(quest_id)
	return str(step.get("id", ""))


func get_hud_quest_hint() -> String:
	if ArmamentQuestManager.is_active():
		return ArmamentQuestManager.get_hud_hint()
	if SpiderQuestManager.is_active():
		return SpiderQuestManager.get_hud_hint()
	if ArrivalQuestManager.is_active() or ArrivalQuestManager.is_completed():
		return ArrivalQuestManager.get_hud_hint()
	if GleazerQuestManager.has_active_quest():
		var gq: Dictionary = GleazerQuestManager.get_active_summary()
		return "Gleazers: %s" % str(gq.get("objective", "uppdrag"))
	if is_quest_completed():
		return "Quest klar: SRC avslöjad"
	if not is_quest_active():
		return "Quest: läs läckt memo i ljusrummet (J = journal)"
	var step := get_current_step()
	if step.is_empty():
		return ""
	return "Quest: %s" % _objective_text(MAIN_QUEST_ID, step)


func _trigger_allmakare(npc_id: String) -> void:
	for node in get_tree().get_nodes_in_group("allmakare_npc"):
		if not is_instance_valid(node):
			continue
		if str(node.get_meta("npc_id", "")) != npc_id:
			continue
		if node.has_method("build_allmakare_talk_payload"):
			AllmakareDebtManager.on_interact(npc_id, node.build_allmakare_talk_payload())
		return


func _trigger_gleazer(npc_id: String) -> void:
	for node in get_tree().get_nodes_in_group("gleazer_npc"):
		if not is_instance_valid(node):
			continue
		if str(node.get_meta("npc_id", "")) != npc_id:
			continue
		if node.has_method("build_gleazer_talk_payload"):
			GleazerQuestManager.on_talk(npc_id, node.build_gleazer_talk_payload())
		return


func _collect_evidence(interact_id: String) -> void:
	if not is_quest_active() or get_current_step_id() != "collect_evidence":
		story_toast.emit("Terminal låst", "Du måste hitta SRC Annex först.")
		return
	var prog: Dictionary = _progress[MAIN_QUEST_ID]
	var collected: Array = prog.get("evidence_ids", [])
	if collected.has(interact_id):
		story_toast.emit("Redan hämtad", "Den här filen finns redan i din journal.")
		return
	collected.append(interact_id)
	prog["evidence_ids"] = collected
	prog["evidence_count"] = collected.size()
	_save_progress()
	var index := collected.size() - 1
	var body: String = Lore.EVIDENCE_LOGS[index] if index < Lore.EVIDENCE_LOGS.size() else "Okänd logg."
	story_toast.emit("Bevis %d/3 nedladdat" % collected.size(), body)
	if collected.size() >= 3:
		_complete_step(MAIN_QUEST_ID, "collect_evidence")


func _complete_step(quest_id: String, step_id: String, silent: bool = false) -> void:
	if not _progress.has(quest_id) or bool(_progress[quest_id].get("completed", false)):
		return
	var quest := _get_quest_def(quest_id)
	var steps: Array = quest.get("steps", [])
	var idx := int(_progress[quest_id].get("step_index", 0))
	if idx >= steps.size():
		return
	if str(steps[idx].get("id", "")) != step_id:
		return
	idx += 1
	_progress[quest_id]["step_index"] = idx
	_save_progress()
	if idx >= steps.size():
		_progress[quest_id]["completed"] = true
		_save_progress()
		quest_completed.emit(quest_id)
		GameSfxScript.play_2d_varied(self, RpgAudioLibraryScript.quest_complete(), Vector2(-10.0, -5.0))
		if not silent:
			story_toast.emit(
				"Operation Redemption avslutad",
				Lore.SABOTAGE_SUCCESS
			)
	else:
		quest_step_changed.emit(quest_id, idx)
		if not silent:
			_emit_step_toast(quest_id)


func _objective_text(quest_id: String, step: Dictionary) -> String:
	var base := str(step.get("objective", ""))
	if str(step.get("id", "")) == "collect_evidence":
		var count := 0
		if _progress.has(quest_id):
			count = int(_progress[quest_id].get("evidence_count", 0))
		return "Ladda ner 3 bevisfiler från SRC-terminaler (%d/3)" % count
	if str(step.get("id", "")) == "witness_hybrids":
		var seen := 0
		if _progress.has(quest_id):
			seen = int(_progress[quest_id].get("witness_count", 0))
		return "Kom nära minst 2 SRC-hybridzombies (%d/2)" % seen
	return base


func _emit_step_toast(quest_id: String) -> void:
	var step := get_current_step(quest_id)
	if step.is_empty():
		return
	story_toast.emit(
		"%s — %s" % [_get_quest_def(quest_id).get("title", "Quest"), step.get("title", "")],
		_objective_text(quest_id, step)
	)


func _get_quest_def(quest_id: String) -> Dictionary:
	var quests: Dictionary = _quest_data.get("quests", {})
	return quests.get(quest_id, {})


func _load_definitions() -> void:
	var file := FileAccess.open(QUESTS_PATH, FileAccess.READ)
	if file == null:
		push_error("Quest definitions missing: %s" % QUESTS_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_quest_data = parsed


func _on_character_selected() -> void:
	var slot := Profile.active_character_id if Profile.active_character_id != "" else Auth.username
	if slot.strip_edges() == "":
		slot = "guest"
	if slot == _save_slot and not _progress.is_empty():
		return
	_save_slot = slot
	_load_progress()


func _progress_path() -> String:
	return "user://quest_progress_%s.json" % _save_slot


func _load_progress() -> void:
	_progress.clear()
	var path := _progress_path()
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_progress = parsed


func _save_progress() -> void:
	var file := FileAccess.open(_progress_path(), FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_progress, "\t"))