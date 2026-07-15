extends Node3D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const CAMERA_OFFSET := Vector3(0, 10, 14)
const CAMERA_LERP_SPEED := 4.0

var players: Dictionary = {}


func _ready() -> void:
	_hide_legacy_floor()
	_build_cube_city()
	_style_hud()
	_update_hud_text()

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_spawn_player(multiplayer.get_unique_id())
	for peer_id in multiplayer.get_peers():
		_spawn_player(peer_id)
		_request_avatars_from_peer.rpc_id(peer_id)


func _process(delta: float) -> void:
	_follow_local_player_camera(delta)
	_update_hud_text()


func _hide_legacy_floor() -> void:
	var floor_node := get_node_or_null("Floor")
	if floor_node:
		floor_node.queue_free()


func _build_cube_city() -> void:
	CubeCityBuilder.build(self)
	$DirectionalLight3D.rotation_degrees = Vector3(-48, 35, 0)


func _follow_local_player_camera(delta: float) -> void:
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	var camera := $Camera3D as Camera3D
	var target_pos := player.global_position + CAMERA_OFFSET
	camera.global_position = camera.global_position.lerp(target_pos, min(delta * CAMERA_LERP_SPEED, 1.0))
	camera.look_at(player.global_position + Vector3(0, 1.6, 0))


func _update_hud_text() -> void:
	var hint := $UI/Hint as Label
	if hint == null:
		return

	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		hint.text = CubeRegistry.full_summary()
		return

	var player: Node3D = players[local_id]
	var zone_id := CubeZoneId.prototype_position_to_zone(player.global_position)
	var zone := CubeRegistry.get_zone(zone_id)
	var permit := CubeRegistry.build_permit_status(zone_id)

	if zone.is_empty():
		hint.text = "Lager %d | Utanför registrerad zon | %s" % [CubeConstants.PROTOTYPE_LAYER, permit]
		return

	var block_id := str(zone.get("block_id", ""))
	var layer_id := str(zone.get("layer_id", ""))
	var zone_name := str(zone.get("name", zone_id))
	var ownership := str(zone.get("ownership", "public"))
	var governor := CubeGovernance.get_effective_block_governor(block_id)
	var governor_name := str(governor.get("account", "ingen"))

	hint.text = (
		"%s | %s | Ägande: %s | Block: %s | Lager: %s | Styrd av: %s | %s"
		% [zone_id, zone_name, ownership, block_id, layer_id, governor_name, permit]
	)


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


func _style_hud() -> void:
	var hint := $UI/Hint as Label
	if hint == null:
		return
	SpiderTheme.style_status(hint)
	SpiderTheme.wrap_label_in_panel(hint)
	hint.offset_right = 920.0
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _spawn_player(peer_id: int) -> void:
	if players.has(peer_id):
		return

	var player := PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	player.position = CubeZoneId.prototype_spawn_position() + Vector3(
		(peer_id % 3) * 2.0 - 2.0,
		0.0,
		(peer_id % 5) * 1.5 - 3.0
	)
	player.set_multiplayer_authority(peer_id)
	players[peer_id] = player
	$Players.add_child(player, true)