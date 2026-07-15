extends CharacterBody3D

const MOVE_SPEED := 5.0
const TURN_SPEED := 8.0

@onready var avatar_pivot: Node3D = $AvatarPivot
@onready var name_label: Label3D = $NameLabel

var _player_username := ""
var _avatar_synced := false


func _ready() -> void:
	if is_multiplayer_authority():
		_player_username = Auth.username
		_apply_identity(_player_username, Profile.get_avatar())
		if Auth.is_guest:
			_sync_guest_state.rpc(_player_username, Profile.get_avatar().to_dict())
		else:
			_announce_player.rpc(_player_username)
	else:
		name_label.text = "..."


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * MOVE_SPEED
		velocity.z = direction.z * MOVE_SPEED
		var target_yaw := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, TURN_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, MOVE_SPEED)
		velocity.z = move_toward(velocity.z, 0, MOVE_SPEED)

	move_and_slide()
	_sync_position.rpc(position, rotation.y)


@rpc("any_peer", "unreliable")
func _sync_position(pos: Vector3, yaw: float) -> void:
	if is_multiplayer_authority():
		return
	position = pos
	rotation.y = yaw


@rpc("any_peer", "reliable")
func _announce_player(username: String) -> void:
	if is_multiplayer_authority():
		return
	_load_avatar_from_server(username)


@rpc("any_peer", "reliable")
func _sync_guest_state(username: String, avatar_dict: Dictionary) -> void:
	if is_multiplayer_authority():
		return
	_apply_identity(username, AvatarData.from_dict(avatar_dict))


func respond_with_active_character() -> void:
	if not is_multiplayer_authority():
		return
	if Auth.is_guest:
		_sync_guest_state.rpc(_player_username, Profile.get_avatar().to_dict())
	else:
		_announce_player.rpc(_player_username)


func _load_avatar_from_server(username: String) -> void:
	Profile.fetch_active_for_username(username, func(ok: bool, avatar: AvatarData, character_name: String) -> void:
		if not is_inside_tree():
			return
		if ok:
			_apply_identity(username, avatar, character_name)
		elif _player_username != "":
			pass
		else:
			name_label.text = username
	)


func _apply_identity(username: String, avatar: AvatarData, character_name: String = "") -> void:
	_player_username = username
	name_label.text = _format_display_name(username, character_name)
	_apply_avatar(avatar)


func _apply_avatar(data: AvatarData) -> void:
	SpiderAlienBuilder.build(avatar_pivot, data)
	_avatar_synced = true


func _format_display_name(username: String, character_name: String) -> String:
	if character_name != "":
		return "%s (%s)" % [username, character_name]
	return username if username != "" else "Spindel"