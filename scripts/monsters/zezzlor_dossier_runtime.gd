extends RefCounted


static func manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ZezzlorDossierManager")


static func get_report_text(player_id: int) -> String:
	var mgr := manager()
	if mgr == null:
		return ""
	return mgr.get_report_text(player_id)


static func reset_for_player(player_id: int) -> void:
	var mgr := manager()
	if mgr:
		mgr.reset_for_player(player_id)


static func record_crime(
	player_id: int,
	crime_pos: Vector3,
	spawn_id: String,
	npc_id: String
) -> void:
	var mgr := manager()
	if mgr:
		mgr.record_crime(player_id, crime_pos, spawn_id, npc_id)


static func record_hunt_started(player_id: int) -> void:
	var mgr := manager()
	if mgr:
		mgr.record_hunt_started(player_id)


static func record_laser_shot(player_id: int, hit: bool) -> void:
	var mgr := manager()
	if mgr:
		mgr.record_laser_shot(player_id, hit)


static func record_target_found(player_id: int, pos: Vector3, spawn_id: String) -> void:
	var mgr := manager()
	if mgr:
		mgr.record_target_found(player_id, pos, spawn_id)


static func record_target_lost(player_id: int, last_pos: Vector3, spawn_id: String) -> void:
	var mgr := manager()
	if mgr:
		mgr.record_target_lost(player_id, last_pos, spawn_id)


static func record_dialogue(player_id: int, response_id: String) -> void:
	var mgr := manager()
	if mgr:
		mgr.record_dialogue(player_id, response_id)


static func record_baton_strike(player_id: int) -> void:
	var mgr := manager()
	if mgr:
		mgr.record_baton_strike(player_id)


static func record_sighting(
	player_id: int,
	pos: Vector3,
	spawn_id: String,
	rank_id: String
) -> void:
	var mgr := manager()
	if mgr:
		mgr.record_sighting(player_id, pos, spawn_id, rank_id)


static func record_weapon(player_id: int, weapon_name: String) -> void:
	var mgr := manager()
	if mgr:
		mgr.record_weapon(player_id, weapon_name)