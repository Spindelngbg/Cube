extends Node

signal quest_started
signal quest_step_changed(step_index: int)
signal quest_completed

const DATA_PATH := "res://data/story/spider_quest.json"
const QUEST_ID := "spider_whispers"

const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")

var _quest_def: Dictionary = {}
var _step_index := -1
var _completed := false
var _kill_count := 0
var _save_slot := "guest"
var _nickname_unlocked := false


func _ready() -> void:
	_load_definition()
	Profile.character_selected.connect(_on_character_selected)
	_on_character_selected()


func is_active() -> bool:
	return not _completed and _step_index >= 0


func is_completed() -> bool:
	return _completed


func can_use_spider_nickname() -> bool:
	return _nickname_unlocked or _completed


func should_call_player_spider() -> bool:
	if not can_use_spider_nickname():
		return false
	return randf() < 0.34


func get_public_name_for_player(player: Node) -> String:
	if player == null:
		return "Spelare"
	if should_call_player_spider():
		return "Spindeln"
	if player.has_method("get_slap_display_name"):
		return player.get_slap_display_name()
	return "Spelare"


func get_hud_hint() -> String:
	if _completed:
		return "Spindlarnas viskningar avklarade"
	if not is_active():
		return ""
	var step := _current_step()
	if step.is_empty():
		return "Spindlarnas viskningar"
	var extra := ""
	if str(step.get("id", "")) == "hunt_spiders":
		var target := int(step.get("kill_target", 2))
		extra = " (%d/%d)" % [_kill_count, target]
	return "Spindlar: %s%s" % [str(step.get("objective", "")), extra]


func get_journal_entry() -> Dictionary:
	var steps: Array = _quest_def.get("steps", [])
	var current: Dictionary = _current_step()
	return {
		"id": QUEST_ID,
		"title": _quest_def.get("title", "Spindlarnas viskningar"),
		"company": _quest_def.get("company", ""),
		"tagline": _quest_def.get("tagline", ""),
		"completed": _completed,
		"step_index": _step_index,
		"step_count": steps.size(),
		"current_title": current.get("title", ""),
		"current_objective": str(current.get("objective", "")),
		"current_briefing": current.get("briefing", ""),
		"milestones": _milestone_lines(),
	}


func on_enter_colony(_spawn_id: String) -> void:
	if _completed:
		return
	if _step_index < 0:
		_start_quest(true)


func notify_spider_rumor() -> void:
	_complete_step("hear_rumor")


func notify_spider_kill() -> void:
	if not is_active() or str(_current_step().get("id", "")) != "hunt_spiders":
		return
	_kill_count += 1
	_save_progress()
	var target := int(_current_step().get("kill_target", 2))
	if _kill_count >= target:
		_complete_step("hunt_spiders")
		if is_active() and str(_current_step().get("id", "")) == "embrace_name":
			_complete_step("embrace_name")


func _start_quest(silent: bool) -> void:
	_step_index = 0
	_completed = false
	_kill_count = 0
	_nickname_unlocked = false
	_save_progress()
	quest_started.emit()
	if not silent:
		_emit_step_toast()
		QuestManager.story_toast.emit(
			str(_quest_def.get("title", "Spindlarnas viskningar")),
			str(_quest_def.get("tagline", ""))
		)


func _complete_step(step_id: String) -> void:
	if _completed or _step_index < 0:
		return
	var step := _current_step()
	if step.is_empty() or str(step.get("id", "")) != step_id:
		return
	var achievement := str(step.get("achievement", ""))
	if achievement != "":
		SteamAchievements.unlock(achievement)
	_step_index += 1
	_save_progress()
	var steps: Array = _quest_def.get("steps", [])
	if _step_index >= steps.size():
		_completed = true
		_nickname_unlocked = true
		_save_progress()
		SteamAchievements.unlock(str(_quest_def.get("complete_achievement", "spider_whispers_complete")))
		quest_completed.emit()
		GameSfxScript.play_2d_varied(self, RpgAudioLibraryScript.quest_complete(), Vector2(-8.0, -4.0))
		QuestManager.story_toast.emit(
			"Du är Spindeln nu",
			"Kolonin kan kalla dig Spindeln — ibland med respekt, ibland med skräck."
		)
	elif str(_current_step().get("id", "")) == "embrace_name":
		_nickname_unlocked = true
		_save_progress()
		_emit_step_toast()
		QuestManager.story_toast.emit(
			"Smeknamn låst upp",
			"Du kan nu kallas Spindeln i spelet."
		)
	else:
		quest_step_changed.emit(_step_index)
		_emit_step_toast()


func _current_step() -> Dictionary:
	var steps: Array = _quest_def.get("steps", [])
	if _step_index < 0 or _step_index >= steps.size():
		return {}
	return steps[_step_index]


func _milestone_lines() -> String:
	var lines: PackedStringArray = []
	var steps: Array = _quest_def.get("steps", [])
	for i in range(steps.size()):
		var step: Dictionary = steps[i]
		var mark := "[x]" if i < _step_index else ("[ ]" if not _completed else "[x]")
		lines.append("%s %s" % [mark, step.get("title", "")])
	return "\n".join(lines)


func _emit_step_toast() -> void:
	var step := _current_step()
	if step.is_empty():
		return
	QuestManager.story_toast.emit(
		"Spindlar: %s" % step.get("title", ""),
		str(step.get("objective", ""))
	)


func _load_definition() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Spider quest data missing: %s" % DATA_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_quest_def = parsed.get("quest", {})


func _on_character_selected() -> void:
	var slot := Profile.active_character_id if Profile.active_character_id != "" else Auth.username
	if slot.strip_edges() == "":
		slot = "guest"
	if slot == _save_slot and (_step_index >= 0 or _completed):
		return
	_save_slot = slot
	_load_progress()


func _progress_path() -> String:
	return "user://spider_quest_%s.json" % _save_slot


func _load_progress() -> void:
	_step_index = -1
	_completed = false
	_kill_count = 0
	_nickname_unlocked = false
	var path := _progress_path()
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_step_index = int(parsed.get("step_index", -1))
	_completed = bool(parsed.get("completed", false))
	_kill_count = int(parsed.get("kill_count", 0))
	_nickname_unlocked = bool(parsed.get("nickname_unlocked", false))


func _save_progress() -> void:
	var file := FileAccess.open(_progress_path(), FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"step_index": _step_index,
		"completed": _completed,
		"kill_count": _kill_count,
		"nickname_unlocked": _nickname_unlocked,
	}, "\t"))