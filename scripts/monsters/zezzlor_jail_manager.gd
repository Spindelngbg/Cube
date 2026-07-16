extends Node

const ZezzlorJailBoxScript = preload("res://scripts/monsters/zezzlor_jail_box.gd")

var _active_jails: Dictionary = {}


func imprison_player(player: Node3D, jailer: Node3D, spawn_id: String) -> void:
	if player == null or not player.is_multiplayer_authority():
		return
	var peer_id := player.get_multiplayer_authority()
	if _active_jails.has(peer_id):
		return

	var jail := ZezzlorJailBoxScript.new()
	jail.name = "ZezzlorJail_%d" % peer_id
	var game := get_tree().get_first_node_in_group("game_director")
	if game:
		game.add_child(jail)
	else:
		get_tree().current_scene.add_child(jail)

	var anchor := player.global_position + Vector3(0.0, 14.0, 0.0)
	jail.global_position = anchor

	if player.has_method("begin_zezzlor_jail"):
		player.begin_zezzlor_jail(jail, spawn_id)

	_active_jails[peer_id] = {
		"jail": jail,
		"release_at": Time.get_ticks_msec() + int(ZezzlorJailBoxScript.HOLD_DURATION_SEC * 1000.0),
	}

	QuestManager.story_toast.emit(
		"Zezzlor-förvar",
		"Fängslaren har låst in dig i en vit cell i 60 sekunder. Därefter släpps du vid hem eller spawn."
	)


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	var done: Array = []
	for peer_id in _active_jails:
		var entry: Dictionary = _active_jails[peer_id]
		if int(entry.get("release_at", 0)) <= now:
			done.append(peer_id)
	for peer_id in done:
		_release_peer(int(peer_id))


func _release_peer(peer_id: int) -> void:
	if not _active_jails.has(peer_id):
		return
	var entry: Dictionary = _active_jails[peer_id]
	var jail: Node = entry.get("jail")
	if jail != null and is_instance_valid(jail):
		jail.queue_free()
	_active_jails.erase(peer_id)

	var game := get_tree().get_first_node_in_group("game_director")
	if game == null or not game.has("players"):
		return
	if not game.players.has(peer_id):
		return
	var player: Node3D = game.players[peer_id]
	if player != null and player.has_method("release_from_zezzlor_jail"):
		player.release_from_zezzlor_jail()