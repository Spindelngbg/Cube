extends Node

const GleazerLoreScript = preload("res://scripts/story/gleazer_lore.gd")
const GleazerQuestCatalogScript = preload("res://scripts/story/gleazer_quest_catalog.gd")
const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")
const NpcDialogueBarkScript = preload("res://scripts/audio/npc_dialogue_bark.gd")

signal gleazer_quest_changed

const COOLDOWN_SEC := 28.0
const MAX_COMPLETED_BEFORE_PAUSE := 6

var _active: Dictionary = {}
var _cooldowns: Dictionary = {}
var _completed_streak := 0
var _save_slot := "guest"
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	Profile.character_selected.connect(_on_character_selected)
	_on_character_selected()


func has_active_quest() -> bool:
	return not _active.is_empty()


func get_active_summary() -> Dictionary:
	if _active.is_empty():
		return {}
	return {
		"title": _active.get("title", "Gleazer-uppdrag"),
		"objective": _active.get("objective", ""),
		"briefing": _active.get("briefing", ""),
		"giver_name": _active.get("giver_name", "Gleazer"),
	}


func on_talk(npc_id: String, entry: Dictionary) -> void:
	if _active.is_empty():
		_try_offer_quest(npc_id, entry)
		return

	if str(_active.get("giver_id", "")) == npc_id:
		_check_return_to_giver(entry)
		return

	var kind := str(_active.get("kind", ""))
	if kind == "talk_role":
		var want_role := str(_active.get("target_role", ""))
		var npc_role := str(entry.get("gleazer_role", ""))
		if npc_role == want_role:
			_fail_active(str(_active.get("fail_detail", GleazerLoreScript.pick_failure())))
		return

	NpcDialogueBarkScript.play_for_id(npc_id, "refusal")
	QuestManager.story_toast.emit(
		GleazerLoreScript.CLAN_NAME,
		"Vi har redan en quest igång. Gleazers kör en i taget — teoretiskt."
	)


func tick(player: Node3D, delta: float) -> void:
	if _active.is_empty() or player == null:
		return

	var timer := float(_active.get("timer", 0.0))
	timer = maxf(0.0, timer - delta)
	_active["timer"] = timer

	var giver_pos: Vector3 = _active.get("giver_pos", Vector3.ZERO)
	var dist := player.global_position.distance_to(giver_pos)
	var kind := str(_active.get("kind", ""))

	match kind:
		"stand_still":
			_tick_stand_still(player, dist, delta)
		"stay_near":
			_tick_stay_near(dist, delta)
		"orbit":
			_tick_orbit(player, giver_pos, dist, delta)
		"move_direction":
			_tick_move_direction(player, giver_pos)
		"return_timer":
			if timer <= 0.0:
				_fail_active("Du kom tillbaka för sent. Vi hade redan gett upp. Quest fail.")
		"wait_fail":
			if timer <= 0.0:
				_fail_active(str(_active.get("fail_detail", GleazerLoreScript.pick_failure())))
		_:
			pass

	gleazer_quest_changed.emit()


func _try_offer_quest(npc_id: String, entry: Dictionary) -> void:
	if _is_on_cooldown(npc_id):
		NpcDialogueBarkScript.play_for_id(npc_id, "refusal")
		QuestManager.story_toast.emit(
			GleazerLoreScript.format_dialogue_title(
				str(entry.get("gleazer_role", "recruit")),
				str(entry.get("gleazer_name", ""))
			),
			GleazerLoreScript.pick_busy_line(_rng.randi())
		)
		return

	if _completed_streak >= MAX_COMPLETED_BEFORE_PAUSE:
		_completed_streak = 0
		QuestManager.story_toast.emit(
			GleazerLoreScript.CLAN_NAME,
			"Vi pausar 10 sekunder för att fira ett tidigare misslyckande."
		)
		return

	var template := GleazerQuestCatalogScript.pick_random(_rng.randi())
	if template.is_empty():
		return

	var role_id := str(entry.get("gleazer_role", "recruit"))
	var personal := str(entry.get("gleazer_name", ""))
	var greeting := GleazerLoreScript.pick_greeting(role_id, _rng.randi())

	_active = template.duplicate(true)
	_active["giver_id"] = npc_id
	_active["giver_name"] = GleazerLoreScript.format_name(role_id, personal)
	_active["giver_pos"] = entry.get("world_pos", Vector3.ZERO)
	_active["timer"] = float(template.get("duration", 30.0))
	_active["_still_timer"] = 0.0
	_active["_orbit_timer"] = 0.0
	_active["_start_player_pos"] = entry.get("player_pos", Vector3.ZERO)

	NpcDialogueBarkScript.play_for_id(npc_id, "greeting")
	NpcDialogueBarkScript.play_for_id(npc_id, "confirmation")
	QuestManager.story_toast.emit(
		GleazerLoreScript.format_dialogue_title(role_id, personal),
		"%s\n\n[Quest] %s\n%s" % [greeting, _active.title, _active.objective]
	)
	GameSfxScript.play_2d_varied(self, RpgAudioLibraryScript.ui_open())
	gleazer_quest_changed.emit()


func _check_return_to_giver(entry: Dictionary) -> void:
	var kind := str(_active.get("kind", ""))
	if kind == "return_timer":
		_fail_active(str(_active.get("fail_detail", GleazerLoreScript.pick_failure())))
		return
	QuestManager.story_toast.emit(
		_active.get("giver_name", GleazerLoreScript.CLAN_NAME),
		"Inte än! Questen är inte klar. Vi känner på oss att något är fel."
	)


func _tick_stand_still(player: Node3D, dist: float, delta: float) -> void:
	var radius := float(_active.get("radius", 8.0))
	var need := float(_active.get("duration", 6.0))
	var still: bool = player.velocity.length() < 0.2 and dist <= radius
	var acc := float(_active.get("_still_timer", 0.0))
	acc = acc + delta if still else 0.0
	_active["_still_timer"] = acc
	if acc >= need:
		_fail_active(str(_active.get("fail_detail", GleazerLoreScript.pick_failure())))


func _tick_stay_near(dist: float, delta: float) -> void:
	var radius := float(_active.get("radius", 5.0))
	var need := float(_active.get("duration", 12.0))
	var acc := float(_active.get("_still_timer", 0.0))
	acc = acc + delta if dist <= radius else 0.0
	_active["_still_timer"] = acc
	if acc >= need:
		_fail_active(str(_active.get("fail_detail", GleazerLoreScript.pick_failure())))


func _tick_orbit(player: Node3D, center: Vector3, dist: float, delta: float) -> void:
	var rmin := float(_active.get("radius_min", 3.0))
	var rmax := float(_active.get("radius_max", 9.0))
	var need := float(_active.get("duration", 8.0))
	var moving: bool = player.velocity.length() > 1.2
	var in_ring := dist >= rmin and dist <= rmax
	var acc := float(_active.get("_orbit_timer", 0.0))
	acc = acc + delta if moving and in_ring else maxf(0.0, acc - delta * 0.5)
	_active["_orbit_timer"] = acc
	if acc >= need:
		_fail_active(str(_active.get("fail_detail", GleazerLoreScript.pick_failure())))


func _tick_move_direction(player: Node3D, giver_pos: Vector3) -> void:
	var dir: Vector3 = _active.get("direction", Vector3.RIGHT)
	dir.y = 0.0
	if dir.length_squared() < 0.01:
		dir = Vector3.RIGHT
	dir = dir.normalized()
	var need := float(_active.get("distance", 25.0))
	var offset := player.global_position - giver_pos
	offset.y = 0.0
	var progress: float = offset.dot(dir)
	if progress >= need:
		_fail_active(str(_active.get("fail_detail", GleazerLoreScript.pick_failure())))


func _fail_active(detail: String) -> void:
	var giver_id := str(_active.get("giver_id", ""))
	_cooldowns[giver_id] = Time.get_ticks_msec() + int(COOLDOWN_SEC * 1000.0)
	_completed_streak += 1
	_save_state()
	NpcDialogueBarkScript.play_for_id(giver_id, "refusal")
	NpcDialogueBarkScript.play_for_id(giver_id, "grunting")
	QuestManager.story_toast.emit(
		"%s — quest fail" % GleazerLoreScript.CLAN_NAME,
		"%s\n\n%s" % [detail, GleazerLoreScript.pick_failure(_rng.randi())]
	)
	GameSfxScript.play_2d_varied(self, RpgAudioLibraryScript.quest_complete())
	_active.clear()
	gleazer_quest_changed.emit()


func set_giver_world_pos(npc_id: String, pos: Vector3) -> void:
	if _active.is_empty():
		return
	if str(_active.get("giver_id", "")) == npc_id:
		_active["giver_pos"] = pos


func update_player_pos_for_offer(pos: Vector3) -> void:
	if not _active.is_empty():
		return
	# stored on next talk via entry


func _is_on_cooldown(npc_id: String) -> bool:
	if not _cooldowns.has(npc_id):
		return false
	return int(_cooldowns[npc_id]) > Time.get_ticks_msec()


func _on_character_selected() -> void:
	var slot := Profile.active_character_id if Profile.active_character_id != "" else Auth.username
	if slot.strip_edges() == "":
		slot = "guest"
	if slot == _save_slot and not _cooldowns.is_empty():
		return
	_save_slot = slot
	_load_state()


func _progress_path() -> String:
	return "user://gleazer_quest_%s.json" % _save_slot


func _save_state() -> void:
	var file := FileAccess.open(_progress_path(), FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"cooldowns": _cooldowns,
		"completed_streak": _completed_streak,
	}, "\t"))


func _load_state() -> void:
	_cooldowns.clear()
	_completed_streak = 0
	if not FileAccess.file_exists(_progress_path()):
		return
	var file := FileAccess.open(_progress_path(), FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_cooldowns = parsed.get("cooldowns", {})
	_completed_streak = int(parsed.get("completed_streak", 0))