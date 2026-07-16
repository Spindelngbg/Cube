extends Node

signal respect_changed(boss_id: String, respect: int)

const CriminalBossCatalogScript = preload("res://scripts/story/criminal_boss_catalog.gd")
const CriminalBossLoreScript = preload("res://scripts/story/criminal_boss_lore.gd")
const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")

const TALK_RESPECT_BOSS := 8
const TALK_RESPECT_HENCHMAN := 2
const MAX_RESPECT := 100

var _respect: Dictionary = {}
var _save_slot := "guest"
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	Profile.character_selected.connect(_on_character_selected)
	_on_character_selected()


func get_respect(boss_id: String) -> int:
	return clampi(int(_respect.get(boss_id, 0)), 0, MAX_RESPECT)


func get_tier(boss_id: String) -> String:
	return CriminalBossLoreScript.tier_from_respect(get_respect(boss_id))


func is_respected(boss_id: String) -> bool:
	return get_respect(boss_id) >= 75


func on_boss_talk(npc_id: String) -> void:
	var entry := CriminalBossCatalogScript.get_entry(npc_id)
	if entry.is_empty():
		return
	var boss_id := str(entry.get("criminal_boss_id", npc_id))
	_add_respect(boss_id, TALK_RESPECT_BOSS)
	var tier := get_tier(boss_id)
	var boss_name := str(entry.get("boss_name", "Boss"))
	var syndicate := str(entry.get("syndicate", "Syndikat"))
	var greeting := CriminalBossLoreScript.pick_boss_greeting(tier, _rng)
	NpcDialogueBarkScript.play_for_id(npc_id, "greeting" if tier == "respected" else "refusal")
	QuestManager.story_toast.emit(
		CriminalBossLoreScript.format_boss_title(boss_name, syndicate),
		"%s\n\nRespekt: %d / %d" % [greeting, get_respect(boss_id), MAX_RESPECT]
	)
	if tier == "respected":
		GameSfxScript.play_2d_varied(self, RpgAudioLibraryScript.ui_open(), Vector2(-10.0, -4.0))


func on_henchman_talk(npc_id: String) -> void:
	var entry := CriminalBossCatalogScript.get_entry(npc_id)
	if entry.is_empty():
		return
	var boss_id := str(entry.get("criminal_boss_id", ""))
	if boss_id == "":
		return
	_add_respect(boss_id, TALK_RESPECT_HENCHMAN)
	var respected := is_respected(boss_id)
	var line := CriminalBossLoreScript.pick_henchman_line(respected, _rng)
	var hench_name := str(entry.get("henchman_name", "Vakt"))
	NpcDialogueBarkScript.play_for_id(npc_id, "greeting" if respected else "shouting")
	QuestManager.story_toast.emit(
		CriminalBossLoreScript.format_henchman_name(hench_name),
		"%s\n\n(%s: %d respekt)" % [line, CriminalBossCatalogScript.get_boss_def(boss_id).get("name", "Boss"), get_respect(boss_id)]
	)


func _add_respect(boss_id: String, amount: int) -> void:
	if boss_id == "" or amount <= 0:
		return
	var next := mini(MAX_RESPECT, get_respect(boss_id) + amount)
	if next == get_respect(boss_id):
		return
	_respect[boss_id] = next
	_save_progress()
	respect_changed.emit(boss_id, next)


func _on_character_selected() -> void:
	var slot := Profile.active_character_id if Profile.active_character_id != "" else Auth.username
	if slot.strip_edges() == "":
		slot = "guest"
	if slot == _save_slot:
		return
	_save_slot = slot
	_load_progress()


func _progress_path() -> String:
	return "user://criminal_boss_respect_%s.json" % _save_slot


func _load_progress() -> void:
	_respect.clear()
	if not FileAccess.file_exists(_progress_path()):
		return
	var file := FileAccess.open(_progress_path(), FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_respect = parsed.duplicate(true)


func _save_progress() -> void:
	var file := FileAccess.open(_progress_path(), FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_respect, "\t"))