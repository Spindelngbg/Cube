class_name SimulationLod
extends RefCounted

const NEAR_M := 72.0
const MID_M := 130.0

static var _cached_player_xz := Vector2.ZERO
static var _cached_valid := false
static var _cached_physics_frame := -1


static func physics_interval(entity: Node3D) -> float:
	var dist := distance_to_local_player(entity)
	if dist <= NEAR_M:
		return 0.0
	if dist <= MID_M:
		return 0.22
	return 0.5


static func distance_to_local_player(entity: Node3D) -> float:
	if entity == null or not entity.is_inside_tree():
		return 0.0
	_refresh_player_cache(entity)
	if not _cached_valid:
		return 0.0
	return Vector2(
		entity.global_position.x - _cached_player_xz.x,
		entity.global_position.z - _cached_player_xz.y
	).length()


static func _refresh_player_cache(entity: Node3D) -> void:
	var frame := Engine.get_physics_frames()
	if frame == _cached_physics_frame:
		return
	_cached_physics_frame = frame
	_cached_valid = false
	var tree := entity.get_tree()
	if tree == null:
		return
	var game := tree.get_first_node_in_group("game_director")
	if game == null or not game.has_method("get_local_player"):
		return
	var player: Node3D = game.get_local_player()
	if player == null:
		return
	_cached_player_xz = Vector2(player.global_position.x, player.global_position.z)
	_cached_valid = true