class_name GameFlow
extends RefCounted


static func can_enter_world() -> bool:
	if Auth.is_guest:
		return true
	return Profile.active_home_spawn_locked and Profile.active_home_spawn_id != ""


static func play_scene_path() -> String:
	if Auth.is_guest:
		return "res://scenes/game.tscn"
	if not Profile.active_nest_visited:
		return "res://scenes/nest_room.tscn"
	if not Profile.active_home_spawn_locked or Profile.active_home_spawn_id == "":
		return "res://scenes/emergence_room.tscn"
	return "res://scenes/game.tscn"