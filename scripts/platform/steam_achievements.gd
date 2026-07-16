extends Node

const CATALOG_PATH := "res://data/platform/steam_achievements.json"

var _catalog: Dictionary = {}
var _unlocked: Dictionary = {}
var _save_slot := "guest"


func _ready() -> void:
	_load_catalog()
	var steam_works := get_node_or_null("/root/SteamWorks")
	if steam_works != null:
		steam_works.steam_ready.connect(_on_steam_ready)
		if steam_works.is_ready:
			_on_steam_ready()
	else:
		push_warning("[SteamAchievements] SteamWorks autoload missing; achievements stay local only.")
	Profile.character_selected.connect(_on_character_selected)
	_on_character_selected()


func is_steam_ready() -> bool:
	var steam_works := get_node_or_null("/root/SteamWorks")
	return steam_works != null and steam_works.is_ready


func unlock(achievement_id: String) -> void:
	if achievement_id.strip_edges() == "":
		return
	if _unlocked.get(achievement_id, false):
		return
	_unlocked[achievement_id] = true
	_save_unlocked()
	var entry: Dictionary = _catalog.get("achievements", {}).get(achievement_id, {})
	var api_name := str(entry.get("steam_api_name", achievement_id.to_upper()))
	_grant_on_steam(api_name)
	print("[SteamAchievements] Unlocked: %s (%s)" % [achievement_id, api_name])


func _grant_on_steam(api_name: String) -> void:
	var steam_works := get_node_or_null("/root/SteamWorks")
	if steam_works != null:
		steam_works.set_achievement(api_name)


func _on_steam_ready() -> void:
	_sync_pending_to_steam()


func _sync_pending_to_steam() -> void:
	if not is_steam_ready():
		return
	for achievement_id in _unlocked:
		if not _unlocked[achievement_id]:
			continue
		var entry: Dictionary = _catalog.get("achievements", {}).get(achievement_id, {})
		var api_name := str(entry.get("steam_api_name", str(achievement_id).to_upper()))
		_grant_on_steam(api_name)


func _load_catalog() -> void:
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_warning("Steam achievement catalog missing: %s" % CATALOG_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_catalog = parsed


func _on_character_selected() -> void:
	var slot := Profile.active_character_id if Profile.active_character_id != "" else Auth.username
	if slot.strip_edges() == "":
		slot = "guest"
	if slot == _save_slot and not _unlocked.is_empty():
		return
	_save_slot = slot
	_load_unlocked()
	if is_steam_ready():
		_sync_pending_to_steam()


func _unlock_path() -> String:
	return "user://steam_achievements_%s.json" % _save_slot


func _load_unlocked() -> void:
	_unlocked.clear()
	var path := _unlock_path()
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_unlocked = parsed


func _save_unlocked() -> void:
	var file := FileAccess.open(_unlock_path(), FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_unlocked, "\t"))