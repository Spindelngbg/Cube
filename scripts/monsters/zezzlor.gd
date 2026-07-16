extends CharacterBody3D

const SlimeDamageScript = preload("res://scripts/combat/slime_damage.gd")
const ZezzlorBuilderScript = preload("res://scripts/monsters/zezzlor_builder.gd")
const ZezzlorLoreScript = preload("res://scripts/story/zezzlor_lore.gd")
const ZezzlorVoiceLibraryScript = preload("res://scripts/audio/zezzlor_voice_library.gd")
const Hurtbox3DScript = preload("res://scripts/combat/hurtbox_3d.gd")
const ZezzlorDossierRuntimeScript = preload("res://scripts/monsters/zezzlor_dossier_runtime.gd")

enum BehaviorMode { CHASE, PATROL, BACKUP }

const CAPTURE_RAY_SCENE := preload("res://scenes/combat/zezzlor_capture_ray.tscn")
const LASER_BOLT_SCENE := preload("res://scenes/combat/zezzlor_laser_bolt.tscn")
const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")

const TURN_SPEED := 7.0
const LASER_RANGE_MIN := 7.0
const LASER_RANGE_MAX := 34.0
const LASER_COOLDOWN_MIN := 1.5
const LASER_COOLDOWN_MAX := 3.2
const SEARCH_SPEED_MUL := 0.92
const BATON_COLOR := Color(0.18, 0.2, 0.24)
const CONVERSATION_RANGE := 6.5
const CONVERSATION_HOLD_SEC := 2.8
const PATROL_MOVE_SPEED := 3.5
const PATROL_CURIOUS_RANGE := 14.0
const PATROL_APPROACH_CHANCE := 0.06
const PATROL_CURIOSITY_CHECK_MIN := 90.0
const PATROL_CURIOSITY_CHECK_MAX := 180.0
const PATROL_QUESTION_COOLDOWN := 480.0
const WAYPOINT_REACH_M := 1.1
const SYNC_INTERVAL := 0.12

var _model_pivot: Node3D
var _name_label: Label3D
var _target: Node3D
var _attack_cooldown := 0.0
var _avatar_animator: AvatarAnimator
var _model_root: Node3D
var _baton_socket: Node3D
var _rank_id := "patrol"
var _personal_name := ""
var _display_name := ""
var _deflect_flash := false
var _voice_player: AudioStreamPlayer3D
var _conversation_started := false
var _conversation_hold := 0.0
var _conversation_line := ""
var _mode := BehaviorMode.CHASE
var _rng := RandomNumberGenerator.new()
var _roam_center := Vector3.ZERO
var _roam_half := Vector3(30.0, 0.0, 30.0)
var _waypoint := Vector3.ZERO
var _patrol_question_cooldown := 0.0
var _patrol_curiosity_check_cooldown := 0.0
var _curious_player: Node3D
var _awaiting_player_response := false
var _conversation_context := "patrol"
var _backup_mission: Node = null
var _backup_hostile := false
var _backup_scan_point := Vector3.ZERO
var _backup_scanning := false
var _is_jailer := false
var _capture_cooldown := 0.0
var _laser_cooldown := 0.0
var _search_waypoint := Vector3.ZERO
var _spawn_id := "satellite_right"
var _sync_accum := 0.0
var _hurtbox_ready := false


func setup(
	target: Node3D,
	spawn_pos: Vector3,
	rank_id: String = "patrol",
	personal_name: String = ""
) -> void:
	_mode = BehaviorMode.CHASE
	_bind_nodes()
	_target = target
	_rank_id = rank_id
	_personal_name = personal_name.strip_edges()
	position = spawn_pos
	_apply_identity()
	_mount_model()
	_attach_baton()
	_attach_ray_pistol()
	_setup_hurtbox()
	_build_voice()
	var game := get_tree().get_first_node_in_group("game_director")
	if game != null:
		_spawn_id = str(game.get("_active_spawn_id"))
	if target != null:
		ZezzlorHuntManager.begin_hunt(target, spawn_pos)
		ZezzlorHuntManager.register_chaser(target, self)
	set_physics_process(true)


func setup_patrol(config: Dictionary) -> void:
	_mode = BehaviorMode.PATROL
	_bind_nodes()
	_target = null
	_rank_id = str(config.get("rank_id", "patrol"))
	_personal_name = str(config.get("personal_name", "")).strip_edges()
	_rng.seed = int(config.get("seed", randi()))
	position = config.get("position", Vector3.ZERO)
	_roam_center = config.get("roam_center", position)
	_roam_half = config.get("roam_half", Vector3(30.0, 0.0, 30.0))
	_patrol_question_cooldown = _rng.randf_range(240.0, 420.0)
	_patrol_curiosity_check_cooldown = _rng.randf_range(
		PATROL_CURIOSITY_CHECK_MIN,
		PATROL_CURIOSITY_CHECK_MAX
	)
	_apply_identity()
	_mount_model()
	_attach_baton()
	_setup_hurtbox()
	_build_voice()
	_pick_waypoint()
	add_to_group("zezzlor_patrol")
	set_physics_process(true)


func setup_backup(mission: Node, config: Dictionary) -> void:
	_mode = BehaviorMode.BACKUP
	_bind_nodes()
	_backup_mission = mission
	_target = config.get("caller", null) as Node3D
	_rank_id = str(config.get("rank_id", "patrol"))
	_personal_name = str(config.get("personal_name", "")).strip_edges()
	_is_jailer = _rank_id == "jailer"
	position = config.get("position", Vector3.ZERO)
	_apply_identity()
	_mount_model()
	_attach_baton()
	if _is_jailer:
		_attach_ray_pistol()
	_setup_hurtbox()
	_build_voice()
	set_physics_process(true)


func begin_backup_dialog(line: String) -> void:
	_begin_conversation(
		line,
		_target,
		"Znood-backup",
		false,
		"backup"
	)


func begin_backup_followup(line: String) -> void:
	_begin_conversation(
		line,
		_target,
		"Znood-backup",
		false,
		"backup_followup"
	)


func order_backup_scan(scan_point: Vector3) -> void:
	_backup_scan_point = scan_point
	_backup_scanning = true
	_backup_hostile = false


func order_backup_hostile() -> void:
	_backup_hostile = true
	_backup_scanning = false
	_mode = BehaviorMode.BACKUP


func get_rank_id() -> String:
	return _rank_id


func get_personal_name() -> String:
	return _personal_name


func take_corrosive_slime(_amount: float, _shooter_id: int) -> void:
	_flash_deflect()


func take_damage(_amount: float) -> void:
	_flash_deflect()


func _bind_nodes() -> void:
	_model_pivot = $ModelPivot
	_name_label = $NameLabel


func _setup_hurtbox() -> void:
	if _hurtbox_ready or get_node_or_null("Hurtbox") != null:
		_hurtbox_ready = true
		return
	Hurtbox3DScript.attach(self, 0.78, 2.1, 1.12)
	_hurtbox_ready = true


func _maybe_sync_state(delta: float, moving: bool) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	_sync_accum += delta
	if _sync_accum >= SYNC_INTERVAL:
		_sync_accum = 0.0
		_sync_state.rpc(position, rotation.y, moving)


func _apply_identity() -> void:
	_display_name = ZezzlorLoreScript.format_name(_rank_id, _personal_name)
	_name_label.text = _display_name
	_name_label.modulate = ZezzlorLoreScript.rank_color(_rank_id)


func _physics_process(delta: float) -> void:
	if not _is_simulation_authority():
		return
	if _conversation_hold > 0.0:
		_physics_conversation_hold(delta)
		return
	if _mode == BehaviorMode.PATROL:
		_physics_patrol(delta)
	elif _mode == BehaviorMode.BACKUP:
		_physics_backup(delta)
	else:
		_physics_chase(delta)


func is_awaiting_player_response() -> bool:
	return _awaiting_player_response


func get_conversation_context() -> String:
	return _conversation_context


func on_player_response(response_id: String) -> void:
	_awaiting_player_response = false
	if _target != null:
		ZezzlorDossierRuntimeScript.record_dialogue(_target.get_multiplayer_authority(), response_id)
	if _conversation_context == "backup" and _backup_mission != null and _backup_mission.has_method("on_player_response"):
		_backup_mission.on_player_response(response_id)
	var reaction := ZezzlorLoreScript.get_zezzlor_reaction(
		response_id, _rank_id, _conversation_context, _personal_name
	)
	_conversation_line = reaction
	_conversation_hold = clampf(3.5 + float(reaction.length()) * 0.04, 4.0, 10.0)
	_speak_dialogue(reaction)
	QuestManager.story_toast.emit(
		ZezzlorLoreScript.format_dialogue_title(_rank_id, _personal_name, "Svar"),
		reaction
	)


func on_dialog_dismissed() -> void:
	if not _awaiting_player_response:
		return
	_awaiting_player_response = false
	if _conversation_context.begins_with("backup") and _backup_mission != null and _backup_mission.has_method("on_player_response"):
		var fallback := "deny_backup" if _conversation_context == "backup" else "backpedal"
		_backup_mission.on_player_response(fallback)
	var line := ZezzlorLoreScript.dismiss_without_answer(_rank_id, _personal_name)
	_conversation_line = line
	_conversation_hold = 4.0
	_speak_dialogue(line)
	QuestManager.story_toast.emit(
		ZezzlorLoreScript.format_dialogue_title(_rank_id, _personal_name, "Svar"),
		line
	)


func _physics_conversation_hold(delta: float) -> void:
	if not _awaiting_player_response:
		_conversation_hold = maxf(0.0, _conversation_hold - delta)
		if _conversation_hold <= 0.0:
			_conversation_started = false
	else:
		_conversation_hold = maxf(_conversation_hold, 1.0)
	velocity = Vector3.ZERO
	if _target != null and is_instance_valid(_target):
		_face_target(delta)
	elif _curious_player != null and is_instance_valid(_curious_player):
		_face_player(_curious_player, delta)
	move_and_slide()
	_update_animation(false)
	_maybe_sync_state(delta, false)


func _physics_backup(delta: float) -> void:
	_capture_cooldown = maxf(0.0, _capture_cooldown - delta)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if _target == null or not is_instance_valid(_target):
		velocity = Vector3.ZERO
		return

	if _backup_hostile:
		var to_target := _target.global_position - global_position
		to_target.y = 0.0
		var dist := to_target.length()
		if _is_jailer and dist < 18.0:
			_try_capture_ray(to_target)
		if dist < 1.85:
			velocity = Vector3.ZERO
			_try_baton_strike()
		else:
			var dir := to_target.normalized()
			velocity = dir * SlimeDamageScript.ZEZZLOR_SPEED * 1.15
			_face_direction(dir, delta)
	elif _backup_scanning:
		var to_scan := _backup_scan_point - global_position
		to_scan.y = 0.0
		var dist := to_scan.length()
		if dist > 1.5:
			var dir := to_scan.normalized()
			velocity = dir * PATROL_MOVE_SPEED * 1.35
			_face_direction(dir, delta)
		else:
			velocity = Vector3.ZERO
			if _target != null:
				_face_target(delta)
	else:
		var to_caller := _target.global_position - global_position
		to_caller.y = 0.0
		if to_caller.length() > 3.0:
			var dir := to_caller.normalized()
			velocity = dir * PATROL_MOVE_SPEED
			_face_direction(dir, delta)
		else:
			velocity = Vector3.ZERO
			_face_target(delta)

	move_and_slide()
	_update_animation(velocity.length() > 0.12)
	_maybe_sync_state(delta, velocity.length() > 0.12)


func _physics_chase(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		velocity = Vector3.ZERO
		return

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_laser_cooldown = maxf(0.0, _laser_cooldown - delta)

	var has_los := _has_line_of_sight(_target)
	if has_los:
		_record_sighting_intel()

	var phase := ZezzlorHuntManager.chaser_tick(_target, self, delta, has_los, _spawn_id)

	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	var dist := to_target.length()

	match phase:
		ZezzlorHuntManager.HuntPhase.SEARCH:
			_physics_chase_search(delta, has_los, dist)
		ZezzlorHuntManager.HuntPhase.CORNER:
			_physics_chase_corner(delta, has_los, dist, to_target)
		_:
			_physics_chase_pursue(delta, has_los, dist, to_target)

	move_and_slide()
	_update_animation(velocity.length() > 0.12)
	_maybe_sync_state(delta, velocity.length() > 0.1)


func _physics_chase_pursue(delta: float, has_los: bool, dist: float, to_target: Vector3) -> void:
	_try_start_conversation(dist)
	if has_los and dist >= LASER_RANGE_MIN and dist <= LASER_RANGE_MAX:
		_try_laser_shot(to_target)
	if dist < 1.85:
		velocity = Vector3.ZERO
		_try_baton_strike()
	elif dist < CONVERSATION_RANGE:
		var dir := to_target.normalized()
		velocity = dir * SlimeDamageScript.ZEZZLOR_SPEED * 0.42
		_face_direction(dir, delta)
	else:
		var dir := to_target.normalized()
		velocity = dir * SlimeDamageScript.ZEZZLOR_SPEED
		_face_direction(dir, delta)


func _physics_chase_search(delta: float, has_los: bool, dist: float) -> void:
	if has_los:
		return
	_search_waypoint = ZezzlorHuntManager.get_search_waypoint(_target, self)
	var to_search := _search_waypoint - global_position
	to_search.y = 0.0
	if to_search.length() < WAYPOINT_REACH_M:
		if _rng.randf() < 0.18 and _laser_cooldown <= 0.0:
			var last_known := ZezzlorHuntManager.get_last_known(_target)
			var guess := (last_known - global_position)
			guess.y = 0.0
			if guess.length_squared() > 0.5:
				_try_laser_shot(guess, true)
		_search_waypoint = ZezzlorHuntManager.get_search_waypoint(_target, self)
		to_search = _search_waypoint - global_position
		to_search.y = 0.0
	if to_search.length_squared() > 0.05:
		var dir := to_search.normalized()
		velocity = dir * SlimeDamageScript.ZEZZLOR_SPEED * SEARCH_SPEED_MUL
		_face_direction(dir, delta)
	else:
		velocity = Vector3.ZERO


func _physics_chase_corner(delta: float, has_los: bool, dist: float, to_target: Vector3) -> void:
	var hold_pos := ZezzlorHuntManager.get_corner_offset(_target, self)
	var to_hold := hold_pos - global_position
	to_hold.y = 0.0
	if has_los and dist >= LASER_RANGE_MIN and dist <= LASER_RANGE_MAX:
		_try_laser_shot(to_target)
	if dist < 1.85:
		velocity = Vector3.ZERO
		_try_baton_strike()
	elif to_hold.length() > 2.0:
		var dir := to_hold.normalized()
		velocity = dir * SlimeDamageScript.ZEZZLOR_SPEED * 0.78
		_face_direction(dir, delta)
	else:
		velocity = Vector3.ZERO
		if has_los:
			_face_direction(to_target.normalized(), delta)


func _physics_patrol(delta: float) -> void:
	_patrol_question_cooldown = maxf(0.0, _patrol_question_cooldown - delta)
	_patrol_curiosity_check_cooldown = maxf(0.0, _patrol_curiosity_check_cooldown - delta)
	_tick_patrol_curiosity()

	var move_target: Node3D = _curious_player if _is_valid_player(_curious_player) else null
	if move_target != null:
		var to_player := move_target.global_position - global_position
		to_player.y = 0.0
		var dist := to_player.length()
		_try_start_patrol_conversation(move_target, dist)
		if dist > 1.2 and not _conversation_started:
			var dir := to_player.normalized()
			velocity = dir * PATROL_MOVE_SPEED
			_face_direction(dir, delta)
		else:
			velocity = Vector3.ZERO
			_face_player(move_target, delta)
	else:
		var to_waypoint := _waypoint - global_position
		to_waypoint.y = 0.0
		var dist := to_waypoint.length()
		if dist < WAYPOINT_REACH_M:
			_pick_waypoint()
			to_waypoint = _waypoint - global_position
			to_waypoint.y = 0.0
			dist = to_waypoint.length()
		if dist > 0.05:
			var dir := to_waypoint.normalized()
			velocity = dir * PATROL_MOVE_SPEED
			_face_direction(dir, delta)
		else:
			velocity = Vector3.ZERO

	move_and_slide()
	global_position.y = _roam_center.y
	_update_animation(velocity.length() > 0.15)
	_maybe_sync_state(delta, velocity.length() > 0.15)


func _tick_patrol_curiosity() -> void:
	if _is_valid_player(_curious_player):
		return
	if _patrol_question_cooldown > 0.0 or _patrol_curiosity_check_cooldown > 0.0:
		return
	var player := _find_nearest_player(PATROL_CURIOUS_RANGE)
	if player == null:
		_patrol_curiosity_check_cooldown = _rng.randf_range(
			PATROL_CURIOSITY_CHECK_MIN * 0.5,
			PATROL_CURIOSITY_CHECK_MAX * 0.5
		)
		return
	if _rng.randf() > PATROL_APPROACH_CHANCE:
		_patrol_curiosity_check_cooldown = _rng.randf_range(
			PATROL_CURIOSITY_CHECK_MIN,
			PATROL_CURIOSITY_CHECK_MAX
		)
		return
	_curious_player = player
	_conversation_started = false


func _try_start_patrol_conversation(player: Node3D, dist: float) -> void:
	if _conversation_started or player == null or dist > CONVERSATION_RANGE:
		return
	if not player.is_multiplayer_authority():
		return
	_begin_conversation(
		ZezzlorLoreScript.pick_patrol_question(_rng.randi()),
		player,
		"Patrull",
		false,
		"patrol"
	)
	_curious_player = null
	_patrol_question_cooldown = PATROL_QUESTION_COOLDOWN
	_patrol_curiosity_check_cooldown = _rng.randf_range(
		PATROL_CURIOSITY_CHECK_MIN,
		PATROL_CURIOSITY_CHECK_MAX
	)


func _try_start_conversation(dist: float) -> void:
	if _conversation_started or _target == null or dist > CONVERSATION_RANGE:
		return
	if not _target.is_multiplayer_authority():
		return
	_begin_conversation(
		ZezzlorLoreScript.chase_conversation_body(_rank_id, _personal_name),
		_target,
		"Kontakt",
		true,
		"chase"
	)


func _begin_conversation(
	line: String,
	_player: Node3D,
	subtitle: String,
	use_greeting_voice: bool,
	context: String
) -> void:
	_conversation_started = true
	_conversation_context = context
	_conversation_line = line
	_awaiting_player_response = true
	_conversation_hold = 999.0
	if use_greeting_voice:
		_play_greeting_voice()
	else:
		_speak_dialogue(line)
	var game := get_tree().get_first_node_in_group("game_director")
	if game != null and game.has_method("open_zezzlor_conversation"):
		game.open_zezzlor_conversation(
			self,
			line,
			ZezzlorLoreScript.format_dialogue_title(_rank_id, _personal_name, subtitle),
			context
		)
	else:
		QuestManager.story_toast.emit(
			ZezzlorLoreScript.format_dialogue_title(_rank_id, _personal_name, subtitle),
			line
		)


func _conversation_hold_duration(line: String, use_greeting_voice: bool) -> float:
	if use_greeting_voice:
		return _greeting_voice_duration()
	return clampf(3.8 + float(line.length()) * 0.045, 4.5, 12.0)


func _is_simulation_authority() -> bool:
	if multiplayer.multiplayer_peer == null:
		return true
	return is_multiplayer_authority()


func _speak_dialogue(line: String) -> void:
	HelpRobotTts.speak(ZezzlorLoreScript.sanitize_spoken_line(line), _voice_player, true)


func _build_voice() -> void:
	_voice_player = AudioStreamPlayer3D.new()
	_voice_player.name = "Voice"
	_voice_player.bus = &"Sfx"
	_voice_player.max_distance = 30.0
	_voice_player.position = Vector3(0.0, 1.45, 0.0)
	add_child(_voice_player)


func _greeting_voice_duration() -> float:
	var stream := ZezzlorVoiceLibraryScript.greeting_stream()
	if stream != null:
		return clampf(stream.get_length() + 0.35, CONVERSATION_HOLD_SEC, 6.0)
	return CONVERSATION_HOLD_SEC


func _play_greeting_voice() -> void:
	if _voice_player == null:
		return
	var stream := ZezzlorVoiceLibraryScript.greeting_stream()
	if stream == null:
		return
	_voice_player.stream = stream
	_voice_player.play()


func _face_target(delta: float) -> void:
	if _target == null:
		return
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.01:
		return
	_face_direction(to_target.normalized(), delta)


func _face_player(player: Node3D, delta: float) -> void:
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.01:
		return
	_face_direction(to_player.normalized(), delta)


func _face_direction(dir: Vector3, delta: float) -> void:
	var target_yaw := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, TURN_SPEED * delta)


func _find_nearest_player(max_range: float) -> Node3D:
	var game := get_tree().get_first_node_in_group("game_director")
	if game == null:
		return null
	var players_dict: Variant = game.get("players")
	if not players_dict is Dictionary:
		return null
	var best: Node3D = null
	var best_dist := max_range
	for player in (players_dict as Dictionary).values():
		if not _is_valid_player(player):
			continue
		var dist := global_position.distance_to((player as Node3D).global_position)
		if dist < best_dist:
			best_dist = dist
			best = player as Node3D
	return best


func _is_valid_player(player: Node3D) -> bool:
	return player != null and is_instance_valid(player) and player is Node3D


func _pick_waypoint() -> void:
	for _attempt in range(8):
		var offset := Vector3(
			_rng.randf_range(-_roam_half.x, _roam_half.x),
			0.0,
			_rng.randf_range(-_roam_half.z, _roam_half.z)
		)
		var candidate := _roam_center + offset
		if candidate.distance_to(global_position) > 5.0:
			_waypoint = candidate
			return
	_waypoint = _roam_center + Vector3(
		_rng.randf_range(-_roam_half.x, _roam_half.x),
		0.0,
		_rng.randf_range(-_roam_half.z, _roam_half.z)
	)


func _try_baton_strike() -> void:
	if _attack_cooldown > 0.0 or _target == null:
		return
	if not _target.has_method("take_damage"):
		return
	if _target.global_position.distance_to(global_position) > 2.2:
		return
	_attack_cooldown = SlimeDamageScript.BATON_COOLDOWN
	_target.take_damage(SlimeDamageScript.BATON_DAMAGE)
	ZezzlorDossierRuntimeScript.record_baton_strike(_target.get_multiplayer_authority())
	if _target.is_multiplayer_authority():
		QuestManager.story_toast.emit(
			"Zezzlor-batong",
			ZezzlorLoreScript.baton_strike_body(_rank_id, _personal_name)
		)
	if _avatar_animator:
		_avatar_animator.trigger_attack()


func _try_laser_shot(to_target: Vector3, suppressive: bool = false) -> void:
	if _laser_cooldown > 0.0 or to_target.length_squared() < 0.01:
		return
	if not suppressive and not _has_line_of_sight(_target):
		return
	_laser_cooldown = _rng.randf_range(LASER_COOLDOWN_MIN, LASER_COOLDOWN_MAX)
	var direction := to_target.normalized()
	var origin := global_position + Vector3(0.0, 1.38, 0.0) + direction * 0.4
	var root := get_tree().current_scene
	if root == null:
		return
	GameSfxScript.play_3d(
		root,
		origin,
		RpgAudioLibraryScript.zezzlor_laser_bang(),
		_rng.randf_range(2.0, 8.0),
		_rng.randf_range(0.88, 1.08),
		58.0
	)
	var bolt := LASER_BOLT_SCENE.instantiate()
	root.add_child(bolt)
	var target_id := -1
	if _target != null:
		target_id = _target.get_multiplayer_authority()
		ZezzlorDossierRuntimeScript.record_laser_shot(target_id, false) # avlossning
	if bolt.has_method("launch"):
		bolt.launch(origin, direction, self, target_id)
	var mesh := bolt.get_node_or_null("Mesh") as MeshInstance3D
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.12, 0.08)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.18, 0.06)
		mat.emission_energy_multiplier = 2.2
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override = mat
	if _avatar_animator:
		_avatar_animator.trigger_attack()


func _has_line_of_sight(target: Node3D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var space := get_world_3d().direct_space_state
	if space == null:
		return true
	var from := global_position + Vector3(0.0, 1.42, 0.0)
	var to := target.global_position + Vector3(0.0, 1.2, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider: Object = hit.get("collider")
	if collider == target:
		return true
	if collider is Node and (collider as Node).get_parent() == target:
		return true
	return false


func _record_sighting_intel() -> void:
	if _target == null:
		return
	var player_id := _target.get_multiplayer_authority()
	ZezzlorDossierRuntimeScript.record_sighting(
		player_id,
		_target.global_position,
		_spawn_id,
		_rank_id
	)
	var weapon_name := ""
	if WeaponManager.can_use_equipped_weapon():
		weapon_name = WeaponManager.get_equipped_display_name()
	ZezzlorDossierRuntimeScript.record_weapon(player_id, weapon_name)


func _mount_model() -> void:
	var built: Dictionary = ZezzlorBuilderScript.build(_model_pivot, _rank_id, 1.1)
	_model_root = built.get("root") as Node3D
	_baton_socket = built.get("baton_socket") as Node3D
	_avatar_animator = AvatarAnimator.ensure_on(_model_pivot)
	_avatar_animator.bind(_model_pivot)


func _try_capture_ray(to_target: Vector3) -> void:
	if _capture_cooldown > 0.0 or to_target.length_squared() < 0.01:
		return
	_capture_cooldown = 2.4
	var direction := to_target.normalized()
	var origin := global_position + Vector3(0.0, 1.35, 0.0) + direction * 0.35
	var root := get_tree().current_scene
	if root == null:
		return
	var ray := CAPTURE_RAY_SCENE.instantiate()
	root.add_child(ray)
	if ray.has_method("launch"):
		ray.launch(origin, direction, self)
	var mesh := ray.get_node_or_null("Mesh") as MeshInstance3D
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.55, 0.35, 0.95)
		mat.emission_enabled = true
		mat.emission = Color(0.65, 0.45, 1.0)
		mat.emission_energy_multiplier = 1.4
		mesh.material_override = mat


func _attach_ray_pistol() -> void:
	var socket: Node3D = _baton_socket if _baton_socket != null else _model_pivot
	var gun := MeshInstance3D.new()
	gun.mesh = BoxMesh.new()
	gun.scale = Vector3(0.12, 0.18, 0.42)
	gun.position = Vector3(0.18, 0.05, -0.12)
	gun.rotation_degrees = Vector3(-12.0, 18.0, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.32, 0.88)
	mat.emission_enabled = true
	mat.emission = Color(0.62, 0.4, 1.0)
	mat.emission_energy_multiplier = 0.7
	gun.material_override = mat
	socket.add_child(gun)


func _attach_baton() -> void:
	var socket: Node3D = _baton_socket if _baton_socket != null else _model_pivot

	var baton := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.035
	mesh.bottom_radius = 0.045
	mesh.height = 0.72
	baton.mesh = mesh
	baton.name = "Baton"
	baton.position = Vector3(0.0, 0.0, -0.08)
	baton.rotation_degrees = Vector3(0.0, 0.0, -28.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = BATON_COLOR
	mat.metallic = 0.55
	mat.roughness = 0.35
	baton.material_override = mat
	socket.add_child(baton)


func _update_animation(moving: bool) -> void:
	if _avatar_animator:
		_avatar_animator.set_moving(moving)


func _flash_deflect() -> void:
	if _deflect_flash or _model_pivot == null:
		return
	_deflect_flash = true
	var tween := create_tween()
	tween.tween_property(_model_pivot, "scale", Vector3(1.04, 0.96, 1.04), 0.06)
	tween.tween_property(_model_pivot, "scale", Vector3.ONE, 0.1)
	tween.tween_callback(func() -> void:
		_deflect_flash = false
	)


@rpc("any_peer", "unreliable")
func _sync_state(pos: Vector3, yaw: float, moving: bool) -> void:
	if _is_simulation_authority():
		return
	position = pos
	rotation.y = yaw
	_update_animation(moving)
