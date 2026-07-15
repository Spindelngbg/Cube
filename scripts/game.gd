extends Node3D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const CAMERA_OFFSET := Vector3(0, 10, 14)
const CAMERA_LERP_SPEED := 4.0

var players: Dictionary = {}
var _active_spawn_id := ""


func _ready() -> void:
	_hide_legacy_floor()
	_resolve_spawn_context()
	_build_world()
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


func _resolve_spawn_context() -> void:
	if Profile.has_home_spawn():
		_active_spawn_id = SpawnPoints.normalize_id(Profile.active_home_spawn_id)
	elif Auth.is_guest:
		_active_spawn_id = "satellite_left"
	else:
		_active_spawn_id = "satellite_left"


func _hide_legacy_floor() -> void:
	var floor_node := get_node_or_null("Floor")
	if floor_node:
		floor_node.queue_free()


func _build_world() -> void:
	if _active_spawn_id != "":
		SatelliteCubeBuilder.build(self, _active_spawn_id)
	else:
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
		hint.text = "Satellitkub %s | 30×30×30 km" % SpawnPoints.get_name(_active_spawn_id)
		return

	var cube_name := SpawnPoints.get_name(_active_spawn_id)
	var cube_id := SpawnPoints.get_cube_id(_active_spawn_id)
	var home_note := ""
	if Profile.has_home_spawn():
		home_note = " | Ditt permanenta hem"
	elif Auth.is_guest:
		home_note = " | Gäst (ingen hemplats)"

	hint.text = "%s (%s)%s | Endast hiss till huvudkuben | WASD" % [cube_name, cube_id, home_note]


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

	var spawn_pos := SpawnPoints.get_position(_active_spawn_id)
	if peer_id == multiplayer.get_unique_id() and Profile.has_home_spawn():
		spawn_pos = Profile.get_home_spawn_position()

	var player := PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	player.position = spawn_pos + Vector3(
		(peer_id % 3) * 1.5 - 1.5,
		0.0,
		(peer_id % 5) * 1.2 - 2.4
	)
	player.set_multiplayer_authority(peer_id)
	players[peer_id] = player
	$Players.add_child(player, true)