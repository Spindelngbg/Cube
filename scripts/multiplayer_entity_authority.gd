class_name MultiplayerEntityAuthority
extends RefCounted

## Peer som simulerar världs-NPC/monster. Solo i mesh får lokal peer — inte alltid 1.
static func simulation_peer_id() -> int:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return 1
	var mp := tree.get_multiplayer()
	if mp.multiplayer_peer == null:
		return 1
	if mp.get_peers().is_empty():
		return mp.get_unique_id()
	return 1