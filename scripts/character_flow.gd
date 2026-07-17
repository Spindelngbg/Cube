class_name CharacterFlow
extends RefCounted

const ThreadedLoaderScript = preload("res://scripts/loading/threaded_loader.gd")
const CityKitLibraryScript = preload("res://scripts/assets/city_kit_library.gd")
const SpaceKitLibraryScript = preload("res://scripts/assets/space_kit_library.gd")

const AVATAR_BUILDER_SCENE := "res://scenes/avatar_builder.tscn"
const CHARACTER_SELECT_SCENE := "res://scenes/character_select.tscn"
const GAME_SCENE := "res://scenes/game.tscn"
const CONNECT_TIMEOUT_SEC := 28.0


static func login_scene_after_characters_loaded() -> String:
	if Profile.characters.is_empty():
		return ""
	return CHARACTER_SELECT_SCENE


static func needs_avatar_setup() -> bool:
	return Profile.active_needs_avatar_setup()


static func destination_scene_path() -> String:
	if needs_avatar_setup():
		return AVATAR_BUILDER_SCENE
	return GameFlow.play_scene_path()


static func character_status(entry: Dictionary) -> String:
	if typeof(entry) != TYPE_DICTIONARY:
		return ""
	if bool(entry.get("homeSpawnLocked", false)):
		var spawn_id := str(entry.get("homeSpawnId", ""))
		if spawn_id != "":
			return "Hem: %s" % SpawnPoints.get_colony_label(spawn_id)
	if not bool(entry.get("nestVisited", false)):
		return "Nästet väntar"
	return "Ljusrummet väntar"


static func play_button_label() -> String:
	if needs_avatar_setup():
		return "Skapa utseende"
	if GameFlow.play_scene_path() == GAME_SCENE:
		return "Spela"
	if Profile.needs_nest_intro():
		return "Till nästet"
	if Profile.needs_home_selection():
		return "Till ljusrummet"
	return "Fortsätt"


static func continue_as(caller: Node) -> Dictionary:
	var result := {"ok": false, "error": ""}
	if caller == null or caller.get_tree() == null:
		result.error = "Spelet är inte redo"
		return result

	var path := destination_scene_path()
	if path == GAME_SCENE:
		## Överlappa nätverksanslutning med trådad scenladdning.
		SceneTransition.begin_threaded_scene_load(GAME_SCENE)
		ThreadedLoaderScript.request_many(CityKitLibraryScript.dc_warmup_paths(), true)
		ThreadedLoaderScript.request_many(SpaceKitLibraryScript.common_warmup_paths(), true)
		var connected := await _connect_to_world(caller)
		if not connected.ok:
			result.error = connected.error
			return result
		var packed: PackedScene = await SceneTransition.await_threaded_scene(GAME_SCENE)
		if packed != null:
			var err := caller.get_tree().change_scene_to_packed(packed)
			if err != OK:
				caller.get_tree().change_scene_to_file(GAME_SCENE)
		else:
			caller.get_tree().change_scene_to_file(GAME_SCENE)
		result.ok = true
		return result

	SceneTransition.begin_threaded_scene_load(path)
	var packed_other: PackedScene = await SceneTransition.await_threaded_scene(path)
	if packed_other != null:
		caller.get_tree().change_scene_to_packed(packed_other)
	else:
		caller.get_tree().change_scene_to_file(path)
	result.ok = true
	return result


static func open_avatar_editor(caller: Node) -> void:
	if caller == null or caller.get_tree() == null:
		return
	SceneTransition.begin_threaded_scene_load(AVATAR_BUILDER_SCENE)
	var packed: PackedScene = await SceneTransition.await_threaded_scene(AVATAR_BUILDER_SCENE)
	if packed != null:
		caller.get_tree().change_scene_to_packed(packed)
	else:
		caller.get_tree().change_scene_to_file(AVATAR_BUILDER_SCENE)


static func _connect_to_world(caller: Node) -> Dictionary:
	var result := {"ok": false, "error": ""}
	if Network.peer_connected and caller.get_tree().get_multiplayer().multiplayer_peer != null:
		result.ok = true
		return result

	var state := {"done": false, "ok": false, "error": ""}

	var on_ready := func() -> void:
		state.done = true
		state.ok = true
	var on_failed := func(reason: String) -> void:
		state.done = true
		state.ok = false
		state.error = reason

	Network.world_ready.connect(on_ready, CONNECT_ONE_SHOT)
	Network.connection_failed.connect(on_failed, CONNECT_ONE_SHOT)
	Network.connect_to_world()

	var deadline := Time.get_ticks_msec() + int(CONNECT_TIMEOUT_SEC * 1000.0)
	while not state.done:
		if Time.get_ticks_msec() > deadline:
			Network.stop()
			result.error = "Servern svarade inte i tid — försök igen"
			return result
		await caller.get_tree().process_frame

	if not state.ok:
		result.error = state.error if state.error != "" else "Anslutning misslyckades"
		return result

	result.ok = true
	return result