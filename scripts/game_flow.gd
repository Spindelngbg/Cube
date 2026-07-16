class_name GameFlow
extends RefCounted

## Dev/test: tillfällig koloni-override (t.ex. /spawn 1 för spelaren Test).
static var debug_spawn_override := ""


static func can_enter_world() -> bool:
	if debug_spawn_override != "" and SpawnPoints.is_valid(debug_spawn_override):
		return true
	if Auth.is_guest:
		return true
	return Profile.active_home_spawn_locked and Profile.active_home_spawn_id != ""


static func play_scene_path() -> String:
	if debug_spawn_override != "" and SpawnPoints.is_valid(debug_spawn_override):
		return "res://scenes/game.tscn"
	if Auth.is_guest:
		return "res://scenes/game.tscn"
	if not Profile.active_nest_visited:
		return "res://scenes/nest_room.tscn"
	if not Profile.active_home_spawn_locked or Profile.active_home_spawn_id == "":
		return "res://scenes/emergence_room.tscn"
	return "res://scenes/game.tscn"


static func clear_debug_spawn_override() -> void:
	debug_spawn_override = ""


static func set_debug_spawn_and_reload(spawn_id: String, tree: SceneTree) -> bool:
	var id := SpawnPoints.normalize_id(spawn_id)
	if id == "" or not SpawnPoints.is_valid(id):
		return false
	debug_spawn_override = id
	tree.change_scene_to_file("res://scenes/game.tscn")
	return true