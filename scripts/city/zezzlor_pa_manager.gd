class_name ZezzlorPaManager
extends Node3D

const ZezzlorPaCatalogScript = preload("res://scripts/story/zezzlor_pa_catalog.gd")
const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")

const MIN_INTERVAL_SEC := 38.0
const MAX_INTERVAL_SEC := 82.0
const AUDIBLE_RANGE_M := 88.0

var _speakers: Array[ZezzlorPaSpeaker] = []
var _timer := 12.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_timer = _rng.randf_range(8.0, 20.0)
	set_process(true)


func register_speaker(speaker: ZezzlorPaSpeaker) -> void:
	if speaker == null or speaker in _speakers:
		return
	_speakers.append(speaker)


func _process(delta: float) -> void:
	if not _is_simulation_authority():
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = _rng.randf_range(MIN_INTERVAL_SEC, MAX_INTERVAL_SEC)
	if _speakers.is_empty():
		return
	var entry := ZezzlorPaCatalogScript.pick_random(_rng.randi())
	var speaker_idx := _rng.randi() % _speakers.size()
	_broadcast_announcement.rpc(speaker_idx, entry)


func _is_simulation_authority() -> bool:
	var tree := get_tree()
	if tree == null or tree.get_multiplayer().multiplayer_peer == null:
		return true
	return MultiplayerEntityAuthorityScript.simulation_peer_id() == multiplayer.get_unique_id()


@rpc("authority", "call_local", "unreliable")
func _broadcast_announcement(speaker_idx: int, entry: Dictionary) -> void:
	if _speakers.is_empty():
		return
	speaker_idx = clampi(speaker_idx, 0, _speakers.size() - 1)
	var speaker := _speakers[speaker_idx]
	if speaker == null or not is_instance_valid(speaker):
		return
	var player := _find_local_player()
	if player == null:
		return
	if player.global_position.distance_to(speaker.global_position) > AUDIBLE_RANGE_M:
		return
	speaker.play_announcement(entry)
	QuestManager.story_toast.emit("Zezzlor PA", str(entry.get("text", "")))


func _find_local_player() -> Node3D:
	var game := get_tree().get_first_node_in_group("game_director")
	if game != null and game.has_method("get_local_player"):
		var player: Node3D = game.get_local_player()
		if player != null:
			return player
	for node in get_tree().get_nodes_in_group("player_character"):
		if node is Node3D and node.is_multiplayer_authority():
			return node as Node3D
	return null