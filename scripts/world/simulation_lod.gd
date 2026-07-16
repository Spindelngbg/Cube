class_name SimulationLod
extends RefCounted

const NEAR_M := 72.0
const MID_M := 130.0


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
	var tree := entity.get_tree()
	if tree == null:
		return 0.0
	var game := tree.get_first_node_in_group("game_director")
	if game == null or not game.has_method("get_local_player"):
		return 0.0
	var player: Node3D = game.get_local_player()
	if player == null:
		return 0.0
	return Vector2(
		entity.global_position.x - player.global_position.x,
		entity.global_position.z - player.global_position.z
	).length()