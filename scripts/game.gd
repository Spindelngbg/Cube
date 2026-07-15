extends Node3D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const SPAWN_POINTS := [
	Vector3(-4, 0.5, -4),
	Vector3(4, 0.5, -4),
	Vector3(-4, 0.5, 4),
	Vector3(4, 0.5, 4),
	Vector3(0, 0.5, 0),
	Vector3(-2, 0.5, 2),
	Vector3(2, 0.5, -2),
	Vector3(0, 0.5, -4),
]

var players: Dictionary = {}


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_spawn_player(multiplayer.get_unique_id())
	for peer_id in multiplayer.get_peers():
		_spawn_player(peer_id)
		_request_avatars_from_peer.rpc_id(peer_id)


func _on_peer_connected(peer_id: int) -> void:
	_spawn_player(peer_id)
	_request_avatars_from_peer.rpc_id(peer_id)


@rpc("any_peer", "reliable")
func _request_avatars_from_peer() -> void:
	if not players.has(multiplayer.get_unique_id()):
		return
	var local_player: Node = players[multiplayer.get_unique_id()]
	local_player.respond_with_active_character()


func _on_peer_disconnected(peer_id: int) -> void:
	if players.has(peer_id):
		players[peer_id].queue_free()
		players.erase(peer_id)


func _spawn_player(peer_id: int) -> void:
	if players.has(peer_id):
		return

	var player := PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	player.position = SPAWN_POINTS[peer_id % SPAWN_POINTS.size()]
	player.set_multiplayer_authority(peer_id)
	players[peer_id] = player
	$Players.add_child(player, true)