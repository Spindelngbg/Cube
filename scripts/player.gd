extends CharacterBody3D

const CheatStateScript = preload("res://scripts/cheat_state.gd")

const MOVE_SPEED := 5.0
const SPRINT_SPEED := 8.5
const JUMP_VELOCITY := 6.5
const GRAVITY := 24.0
const SWIM_GRAVITY := 5.5
const SWIM_SPEED := 4.6
const SWIM_SPRINT_SPEED := 6.8
const SWIM_UP_SPEED := 5.2
const SWIM_SURFACE_CLEARANCE := 0.35
const TURN_SPEED := 8.0
const SWIM_TURN_SPEED := 5.5
const SLIME_PROJECTILE_SCENE := preload("res://scenes/combat/slime_projectile.tscn")
const LASER_PROJECTILE_SCENE := preload("res://scenes/combat/laser_projectile.tscn")
const CATALOG_PROJECTILE_SCENE := preload("res://scenes/combat/catalog_projectile.tscn")
const SlimeBlasterClass = preload("res://scripts/combat/slime_blaster.gd")
const LaserBlasterClass = preload("res://scripts/combat/laser_blaster.gd")
const RangedWeaponBlasterClass = preload("res://scripts/combat/ranged_weapon_blaster.gd")
const WeaponCatalogScript = preload("res://scripts/combat/weapon_catalog.gd")
const LaserMuzzleSmokeFxScript = preload("res://scripts/combat/laser_muzzle_smoke_fx.gd")
const ZnoodDeviceScript = preload("res://scripts/access/znood_device.gd")
const HumanAvatarBuilderScript = preload("res://scripts/human_avatar_builder.gd")
const FirstPersonPunchViewScript = preload("res://scripts/combat/first_person_punch_view.gd")
const FirstPersonMeleeViewScript = preload("res://scripts/combat/first_person_melee_view.gd")
const BoxingPunchScript = preload("res://scripts/combat/boxing_punch.gd")
const MeleeWeaponStrikeScript = preload("res://scripts/combat/melee_weapon_strike.gd")
const PlayerFootstepsScript = preload("res://scripts/audio/player_footsteps.gd")
const ExteriorLadderScript = preload("res://scripts/access/exterior_ladder.gd")
const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const ProceduralSfxScript = preload("res://scripts/audio/procedural_sfx.gd")
const PlayerDamageGruntLibraryScript = preload("res://scripts/audio/player_damage_grunt_library.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")
const GuiFontLibraryScript = preload("res://scripts/ui/gui_font_library.gd")

const FIRST_PERSON_FALLBACK_EYE := Vector3(0.0, 1.62, 0.08)

@onready var avatar_pivot: Node3D = $AvatarPivot
@onready var znood_mount: ZnoodDevice = $AvatarPivot/ZnoodMount
@onready var name_label: Label3D = $NameLabel

signal health_changed(current: float, maximum: float)
signal died

var _player_username := ""
var _avatar_synced := false
var _slime_blaster = SlimeBlasterClass.new()
var _laser_blaster = LaserBlasterClass.new()
var _shop_blasters: Dictionary = {}
var _health := 100.0
var _max_health := 100.0
var _damage_cooldown := 0.0
var _respawn_timer := 0.0
var _is_dead := false
var _spawn_anchor := Vector3.ZERO
var _human_animator: HumanAvatarAnimator
var _avatar_model: Node3D
var _fp_punch: FirstPersonPunchView
var _fp_melee: FirstPersonMeleeView
var _punch_cooldown := 0.0
var _melee_cooldown := 0.0
var _stuck_frames := 0
var _slap_active := false
var _slap_immunity_timer := 0.0
var _slap_airborne := false
const SLAP_LAUNCH_VELOCITY := 20.0
const SLAP_IMMUNITY_SEC := 6.0
const SLAP_POST_LAND_IMMUNITY_SEC := 2.0
const FALL_DAMAGE_MIN_IMPACT_SPEED := 9.0
const FALL_DAMAGE_LETHAL_SPEED := 30.0
const FALL_DAMAGE_MIN_AMOUNT := 8.0
const FALL_DAMAGE_MAX_AMOUNT := 90.0
var _peak_fall_speed := 0.0
var _last_sync_pos := Vector3.ZERO
var _last_sent_pos := Vector3.ZERO
var _last_sent_yaw := 0.0
var _sync_timer := 0.0
const SYNC_INTERVAL := 1.0 / 15.0
const SYNC_MOVE_THRESHOLD := 0.04
const SYNC_TURN_THRESHOLD := 0.05
var _footsteps: PlayerFootsteps
var _piloting_vehicle: Node3D
var _saved_collision_layer := 1
var _saved_collision_mask := 1
var _zezzlor_jail_active := false
var _zezzlor_jail_node: Node3D
var _zezzlor_jail_spawn_id := ""
var _water_volumes: Array[Node] = []


func _ready() -> void:
	add_to_group("player_character")
	_setup_name_label()
	_spawn_anchor = global_position
	if is_multiplayer_authority():
		InventoryManager.inventory_changed.connect(_on_inventory_changed)
		WeaponManager.equipped_changed.connect(_on_equipped_weapon_changed)
		_refresh_max_health(true)
		_player_username = Auth.username
		var display_name := Profile.active_character_name if not Auth.is_guest else ""
		_apply_identity(_player_username, Profile.get_avatar(), display_name)
		if Auth.is_guest:
			_sync_guest_state.rpc(_player_username, Profile.get_avatar().to_dict())
		else:
			_announce_player.rpc(_player_username)
	else:
		name_label.text = "..."
	if is_multiplayer_authority():
		_footsteps = PlayerFootstepsScript.ensure_on(self)
		call_deferred("ensure_safe_ground")


## Placera fötterna på närmaste golv och knuffa ut ur solid geometri.
func snap_to_floor() -> void:
	ensure_safe_ground()


func ensure_safe_ground() -> void:
	if not is_inside_tree() or not is_multiplayer_authority():
		return
	var space := get_world_3d().direct_space_state
	if space == null:
		return

	var candidates: Array[Vector3] = []
	if _spawn_anchor != Vector3.ZERO:
		candidates.append(_spawn_anchor)
	candidates.append(global_position)
	# Spiral-sök efter fri punkt om vi sitter i vägg/mark.
	for ring in range(1, 6):
		var radius := float(ring) * 1.6
		for step in range(8):
			var angle := float(step) * TAU / 8.0
			candidates.append(global_position + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))
			if _spawn_anchor != Vector3.ZERO:
				candidates.append(_spawn_anchor + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))

	var placed := false
	for candidate in candidates:
		var grounded := _try_place_on_floor(space, candidate)
		if grounded == Vector3.INF:
			continue
		if _capsule_is_blocked(space, grounded):
			continue
		global_position = grounded
		placed = true
		break

	if not placed:
		var fallback_y := maxf(_spawn_anchor.y, SpawnPoints.SPAWN_FOOT_Y) if _spawn_anchor != Vector3.ZERO else SpawnPoints.SPAWN_FOOT_Y
		global_position.y = fallback_y
		# Sista utväg: lyft rakt upp ur eventuell inbäddning.
		for _i in range(12):
			if not _capsule_is_blocked(space, global_position):
				break
			global_position.y += 0.75

	velocity = Vector3.ZERO


func _try_place_on_floor(space: PhysicsDirectSpaceState3D, xz_pos: Vector3) -> Vector3:
	var probe_x := xz_pos.x
	var probe_z := xz_pos.z
	var anchor_y := _spawn_anchor.y if _spawn_anchor != Vector3.ZERO else SpawnPoints.SPAWN_FOOT_Y
	var probe_top := maxf(maxf(xz_pos.y, anchor_y), SpawnPoints.SPAWN_FOOT_Y) + 32.0
	var from := Vector3(probe_x, probe_top, probe_z)
	var to := Vector3(probe_x, -6.0, probe_z)
	var hit := _ray_floor(space, from, to)
	if hit.is_empty():
		return Vector3.INF
	var floor_y := float(hit.position.y)
	var normal: Vector3 = hit.get("normal", Vector3.UP)
	if normal.y < 0.45:
		return Vector3.INF
	# CharacterBody-origin = fötter (kapsel offset y=1, height=2).
	return Vector3(probe_x, floor_y + 0.12, probe_z)


func _ray_floor(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	query.hit_from_inside = true
	return space.intersect_ray(query)


func _capsule_is_blocked(space: PhysicsDirectSpaceState3D, feet_pos: Vector3) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.9
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), feet_pos + Vector3(0.0, 1.0, 0.0))
	params.collision_mask = 1
	params.exclude = [get_rid()]
	params.margin = 0.02
	var hits := space.intersect_shape(params, 4)
	return not hits.is_empty()


func _setup_name_label() -> void:
	GuiFontLibraryScript.apply_to_label3d(name_label)
	name_label.position = Vector3(0, 2.55, 0)
	name_label.font_size = 36
	name_label.outline_size = 10
	name_label.modulate = Color(0.95, 0.9, 0.82, 1)
	name_label.outline_modulate = Color(0.08, 0.06, 0.1, 0.95)
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.no_depth_test = true
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func is_piloting_vehicle() -> bool:
	return _piloting_vehicle != null and is_instance_valid(_piloting_vehicle)


func is_zezzlor_jailed() -> bool:
	return _zezzlor_jail_active


func is_swimming() -> bool:
	return not _water_volumes.is_empty()


func enter_water(volume: Node) -> void:
	if volume == null or volume in _water_volumes:
		return
	_water_volumes.append(volume)


func exit_water(volume: Node) -> void:
	if volume == null:
		return
	_water_volumes.erase(volume)


func _prune_water_volumes() -> void:
	for i in range(_water_volumes.size() - 1, -1, -1):
		var volume = _water_volumes[i]
		if volume == null or not is_instance_valid(volume):
			_water_volumes.remove_at(i)


func _get_active_water() -> Node:
	_prune_water_volumes()
	if _water_volumes.is_empty():
		return null
	var best: Node = _water_volumes[0]
	var best_depth := -999.0
	for volume in _water_volumes:
		if not volume.has_method("get_surface_y"):
			continue
		var depth := float(volume.get_surface_y()) - global_position.y
		if depth > best_depth:
			best_depth = depth
			best = volume
	return best


func _apply_swim_physics(delta: float, direction: Vector3, _input_dir: Vector2) -> void:
	var water := _get_active_water()
	if water == null:
		return

	var surface_y := float(water.get_surface_y())
	var floor_y := float(water.get_floor_y()) if water.has_method("get_floor_y") else surface_y - 1.2
	var move_speed := SWIM_SPRINT_SPEED if Input.is_action_pressed("sprint") else SWIM_SPEED

	velocity.y -= SWIM_GRAVITY * delta
	if global_position.y < surface_y - 0.55:
		velocity.y += 14.0 * delta

	if Input.is_action_pressed("jump"):
		velocity.y = SWIM_UP_SPEED
	elif Input.is_action_pressed("move_back") and global_position.y < surface_y - 0.2:
		velocity.y -= 3.5 * delta

	var max_surface := surface_y - SWIM_SURFACE_CLEARANCE
	if global_position.y > max_surface:
		global_position.y = max_surface
		velocity.y = minf(velocity.y, 0.0)

	var min_depth := floor_y + 0.95
	if global_position.y < min_depth:
		global_position.y = min_depth
		velocity.y = maxf(velocity.y, 0.0)

	if direction != Vector3.ZERO:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		var yaw_source := _get_camera_yaw_source()
		if yaw_source >= 0.0:
			rotation.y = yaw_source
		else:
			var target_yaw := atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, SWIM_TURN_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 1.6 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 1.6 * delta)


func capture_by_zezzlor_jailer(jailer: Node3D) -> void:
	if not is_multiplayer_authority() or _zezzlor_jail_active or _is_dead:
		return
	var spawn_id := ""
	var game := get_tree().get_first_node_in_group("game_director")
	if game != null:
		spawn_id = str(game.get("_active_spawn_id"))
	ZezzlorJailManager.imprison_player(self, jailer, spawn_id)


func begin_zezzlor_jail(jail: Node3D, spawn_id: String) -> void:
	_zezzlor_jail_active = true
	_zezzlor_jail_node = jail
	_zezzlor_jail_spawn_id = spawn_id
	velocity = Vector3.ZERO
	MouseLook.deactivate()
	if jail != null and jail.has_method("get_hold_position"):
		global_position = jail.get_hold_position()


func release_from_zezzlor_jail() -> void:
	_zezzlor_jail_active = false
	_zezzlor_jail_node = null
	var colony_id := SpawnPoints.ensure_colony_id(_zezzlor_jail_spawn_id)
	var pos := SpawnPoints.get_play_spawn_position(colony_id)
	var zone_mgr := RuntimeGlobals.zone_ownership()
	if zone_mgr:
		var building_pos := zone_mgr.get_preferred_building_spawn_position(colony_id)
		if building_pos != Vector3.ZERO:
			pos = building_pos
	var game := get_tree().get_first_node_in_group("game_director")
	if game != null and game.has_method("shift_world_position"):
		pos = game.shift_world_position(pos)
	else:
		pos = SpawnPoints.get_shifted_play_spawn(colony_id)
	global_position = pos
	_spawn_anchor = pos
	snap_to_floor()
	if game != null and game.has_method("should_capture_mouse") and game.should_capture_mouse():
		if game.has_method("get_camera_pivot") and game.has_method("get_camera"):
			MouseLook.activate(game.get_camera_pivot(), game.get_camera())


func get_piloting_vehicle() -> Node3D:
	return _piloting_vehicle


func set_piloting_vehicle(vehicle: Node3D) -> void:
	_piloting_vehicle = vehicle
	_refresh_pilot_visibility()
	_refresh_pilot_collision()


func _refresh_pilot_visibility() -> void:
	var hidden := is_piloting_vehicle()
	if _avatar_model:
		_avatar_model.visible = not hidden and is_multiplayer_authority()
	name_label.visible = not hidden


func _refresh_pilot_collision() -> void:
	if is_piloting_vehicle():
		if collision_layer != 0:
			_saved_collision_layer = collision_layer
			_saved_collision_mask = collision_mask
		collision_layer = 0
		collision_mask = 0
	else:
		collision_layer = _saved_collision_layer
		collision_mask = _saved_collision_mask


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if is_piloting_vehicle():
		velocity = Vector3.ZERO
		if _footsteps:
			_footsteps.tick(delta, 0.0, true, false)
		return

	if _zezzlor_jail_active:
		velocity = Vector3.ZERO
		if _zezzlor_jail_node != null and is_instance_valid(_zezzlor_jail_node):
			if _zezzlor_jail_node.has_method("get_hold_position"):
				global_position = _zezzlor_jail_node.get_hold_position()
		return

	if _is_dead:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_respawn()
		return

	if _slap_immunity_timer > 0.0:
		_slap_immunity_timer = maxf(0.0, _slap_immunity_timer - delta)

	if _slap_active:
		_process_slap_physics(delta)
		return

	# Nödlösning: under mark / långt under spawn → knuffa upp till säkert golv.
	if global_position.y < SpawnPoints.SPAWN_FOOT_Y - 1.0 or (
		_spawn_anchor != Vector3.ZERO and global_position.y < _spawn_anchor.y - 2.0
	):
		if _spawn_anchor != Vector3.ZERO:
			global_position = _spawn_anchor
		ensure_safe_ground()

	_damage_cooldown = maxf(0.0, _damage_cooldown - delta)
	_punch_cooldown = maxf(0.0, _punch_cooldown - delta)
	_melee_cooldown = maxf(0.0, _melee_cooldown - delta)
	_slime_blaster.tick(delta)
	_laser_blaster.tick(delta)
	_tick_shop_blaster(delta)
	_handle_combat_input()

	var swimming := is_swimming()
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := _get_flat_move_direction(input_dir)
	var pre_move_pos := global_position

	var ladder := _get_active_ladder()
	var was_on_floor := is_on_floor()
	if ladder != null and ladder.apply_climb(self, delta):
		_peak_fall_speed = 0.0
	elif swimming:
		_apply_swim_physics(delta, direction, input_dir)
		move_and_slide()
		_peak_fall_speed = 0.0
	else:
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		elif velocity.y < 0.0:
			velocity.y = 0.0

		if Input.is_action_just_pressed("jump") and is_on_floor():
			if _stuck_frames >= 6:
				_unstuck_nudge()
			else:
				velocity.y = JUMP_VELOCITY

		var move_speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else MOVE_SPEED
		if direction != Vector3.ZERO:
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
			var yaw_source := _get_camera_yaw_source()
			if yaw_source >= 0.0:
				rotation.y = yaw_source
			else:
				var target_yaw := atan2(direction.x, direction.z)
				rotation.y = lerp_angle(rotation.y, target_yaw, TURN_SPEED * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)

		move_and_slide()
		_apply_landing_fall_damage(was_on_floor)

	if not swimming and ladder == null:
		if direction != Vector3.ZERO and is_on_floor() and pre_move_pos.distance_to(global_position) < 0.004:
			_stuck_frames += 1
		else:
			_stuck_frames = 0
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if _human_animator:
		_human_animator.set_moving(horizontal_speed > 0.35)
	if _footsteps:
		_footsteps.tick(
			delta,
			horizontal_speed,
			is_on_floor() and not swimming,
			Input.is_action_pressed("sprint")
		)
	_sync_timer += delta
	var yaw := rotation.y
	var moved := position.distance_to(_last_sent_pos) > SYNC_MOVE_THRESHOLD
	var turned := absf(wrapf(yaw - _last_sent_yaw, -PI, PI)) > SYNC_TURN_THRESHOLD
	if _sync_timer >= SYNC_INTERVAL or moved or turned:
		_sync_timer = 0.0
		_last_sent_pos = position
		_last_sent_yaw = yaw
		_sync_position.rpc(position, yaw)


@rpc("any_peer", "unreliable")
func _sync_position(pos: Vector3, yaw: float) -> void:
	if is_multiplayer_authority():
		return
	var moved := pos.distance_to(_last_sync_pos) > 0.03
	_last_sync_pos = pos
	position = pos
	rotation.y = yaw
	if _human_animator:
		_human_animator.set_moving(moved)


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
	var model := HumanAvatarBuilderScript.build(avatar_pivot, data)
	if model == null:
		return
	_avatar_model = model
	_human_animator = HumanAvatarAnimator.ensure_on(avatar_pivot)
	_human_animator.bind(model)
	if is_multiplayer_authority():
		_fp_punch = FirstPersonPunchViewScript.ensure_on(self)
		_fp_punch.apply_avatar_colors(data.body_color, data.accent_color)
		_fp_melee = FirstPersonMeleeViewScript.ensure_on(self)
		_refresh_melee_view()
	_refresh_first_person_visibility()
	_last_sync_pos = position
	_avatar_synced = true


func get_camera_anchor_global_position() -> Vector3:
	var fallback := global_position + FIRST_PERSON_FALLBACK_EYE
	if _human_animator:
		return _human_animator.get_eye_global_position(fallback)
	return fallback


func _refresh_first_person_visibility() -> void:
	var hide_body := is_multiplayer_authority()
	if _avatar_model:
		_avatar_model.visible = not hide_body
	name_label.visible = not hide_body


func _format_display_name(username: String, character_name: String) -> String:
	if character_name.strip_edges() != "":
		return character_name.strip_edges()
	if username.strip_edges() != "":
		return username.strip_edges()
	return "Kolonist"


func get_slime_status_text() -> String:
	if WeaponManager.can_use_laserrifle():
		return _laser_blaster.get_status_text()
	if WeaponManager.can_use_slimeshooter():
		return _slime_blaster.get_status_text()
	var shop_ranged_id := WeaponManager.get_equipped_shop_ranged_id()
	if shop_ranged_id != "":
		return _get_shop_blaster(shop_ranged_id).get_status_text(shop_ranged_id)
	if WeaponManager.can_use_melee():
		var melee_id := WeaponManager.get_equipped_melee_id()
		return (
			"%s: %d skada | Vänsterklick hugga | Q slag utan vapen"
			% [
				ItemCatalog.get_display_name(melee_id),
				int(WeaponCatalog.get_damage(melee_id)),
			]
		)
	if InventoryManager.has_item(WeaponManager.LASERRIFLE_ID):
		return "Lasergevär i inventory — utrusta via inventory"
	if InventoryManager.has_item(WeaponManager.SLIMESHOOTER_ID):
		return "Slimeshooter i inventory — utrusta vid vapenbutik [E]"
	return "Inget vapen — lila lasertorn eller vapenbutik"


func get_hp_status_text() -> String:
	return "HP %d/%d" % [int(round(_health)), int(round(_max_health))]


func get_health_snapshot() -> Dictionary:
	return {"current": _health, "max": _max_health}


func set_spawn_anchor(pos: Vector3) -> void:
	_spawn_anchor = pos


func get_spawn_anchor() -> Vector3:
	return _spawn_anchor


func get_account_username() -> String:
	return _player_username


func matches_player_name(query: String) -> bool:
	var needle := query.strip_edges().to_lower()
	if needle.is_empty():
		return false
	if _player_username.strip_edges().to_lower() == needle:
		return true
	return name_label.text.strip_edges().to_lower() == needle


func get_slap_display_name() -> String:
	if SpiderQuestManager.should_call_player_spider():
		return "Spindeln"
	var label := name_label.text.strip_edges() if name_label else ""
	if label != "":
		return label
	if _player_username.strip_edges() != "":
		return _player_username.strip_edges()
	return "Spelare"


func request_slap() -> String:
	var display := get_slap_display_name()
	if is_multiplayer_authority():
		apply_slap()
	else:
		_rpc_slap.rpc_id(get_multiplayer_authority())
	return "SLAP! %s skickades upp i luften." % display


func apply_slap() -> void:
	if not is_multiplayer_authority():
		return
	if _is_dead or _zezzlor_jail_active or is_piloting_vehicle() or _slap_active:
		return
	_slap_active = true
	_slap_airborne = false
	_slap_immunity_timer = SLAP_IMMUNITY_SEC
	_peak_fall_speed = 0.0
	_stuck_frames = 0
	velocity = Vector3(0.0, SLAP_LAUNCH_VELOCITY, 0.0)


func _process_slap_physics(delta: float) -> void:
	velocity.y -= GRAVITY * delta
	if not is_on_floor():
		_slap_airborne = true
	move_and_slide()
	if _slap_airborne and is_on_floor() and velocity.y <= 0.0:
		_finish_slap_landing()


func _finish_slap_landing() -> void:
	_slap_active = false
	_slap_airborne = false
	var impact_speed := _peak_fall_speed
	_peak_fall_speed = 0.0
	velocity = Vector3.ZERO
	_play_landing_feedback(maxf(impact_speed, SLAP_LAUNCH_VELOCITY * 0.45))
	ensure_safe_ground()
	_slap_immunity_timer = maxf(_slap_immunity_timer, SLAP_POST_LAND_IMMUNITY_SEC)
	_stuck_frames = 0


func _apply_landing_fall_damage(was_on_floor_before: bool) -> void:
	if is_on_floor():
		if not was_on_floor_before:
			var impact_speed := maxf(_peak_fall_speed, maxf(0.0, -velocity.y))
			_peak_fall_speed = 0.0
			_play_landing_feedback(impact_speed)
			var damage := _fall_damage_for_speed(impact_speed)
			if damage > 0.0:
				take_fall_damage(damage)
		else:
			_peak_fall_speed = 0.0
	elif velocity.y < 0.0:
		_peak_fall_speed = maxf(_peak_fall_speed, -velocity.y)


func _play_landing_feedback(impact_speed: float) -> void:
	if not is_multiplayer_authority():
		return
	if impact_speed < 5.5:
		return
	var weight := clampf(
		inverse_lerp(5.5, FALL_DAMAGE_LETHAL_SPEED, impact_speed),
		0.0,
		1.0
	)
	var stream := ProceduralSfxScript.bounce_stream()
	GameSfxScript.play_3d_varied(
		self,
		global_position,
		stream,
		Vector2(-16.0, lerpf(-8.0, -2.0, weight)),
		Vector2(lerpf(0.82, 1.08, weight), lerpf(0.95, 1.18, weight))
	)
	if weight >= 0.2 and MouseLook.has_method("request_shake"):
		MouseLook.request_shake(lerpf(0.04, 0.14, weight), lerpf(0.08, 0.2, weight))


func _fall_damage_for_speed(impact_speed: float) -> float:
	if impact_speed < FALL_DAMAGE_MIN_IMPACT_SPEED:
		return 0.0
	var weight := inverse_lerp(
		FALL_DAMAGE_MIN_IMPACT_SPEED,
		FALL_DAMAGE_LETHAL_SPEED,
		impact_speed
	)
	return lerpf(FALL_DAMAGE_MIN_AMOUNT, FALL_DAMAGE_MAX_AMOUNT, clampf(weight, 0.0, 1.0))


@rpc("any_peer", "call_local", "reliable")
func _rpc_slap() -> void:
	if is_multiplayer_authority():
		apply_slap()


func apply_zezzlor_laser_hit(amount: float) -> void:
	if not is_multiplayer_authority():
		return
	take_damage(amount)


@rpc("any_peer", "call_local", "reliable")
func _rpc_apply_zezzlor_laser_hit(amount: float) -> void:
	apply_zezzlor_laser_hit(amount)


func take_damage(amount: float) -> void:
	_apply_damage(amount, true)


func take_fall_damage(amount: float) -> void:
	_apply_damage(amount, false)


func _apply_damage(amount: float, respect_cooldown: bool) -> void:
	if CheatStateScript.god_mode:
		return
	if _slap_active or _slap_immunity_timer > 0.0:
		return
	if _is_dead or amount <= 0.0:
		return
	if respect_cooldown and _damage_cooldown > 0.0:
		return
	_damage_cooldown = 0.85
	_health = maxf(0.0, _health - amount)
	health_changed.emit(_health, _max_health)
	_sync_health.rpc(_health, _max_health)
	_play_damage_bark()
	if _health <= 0.0:
		_die()


func _play_damage_bark() -> void:
	if not is_multiplayer_authority():
		return
	var gender := "man"
	if Profile.avatar_ready:
		gender = Profile.get_avatar().gender
	var stream := PlayerDamageGruntLibraryScript.grunt_for_gender(gender)
	if stream == null:
		return
	var pitch_range := PlayerDamageGruntLibraryScript.pitch_range_for_gender(gender)
	GameSfxScript.play_2d_varied(self, stream, Vector2(-10.0, -5.0), pitch_range)


func heal_to_full() -> void:
	_health = _max_health
	_is_dead = false
	health_changed.emit(_health, _max_health)
	_sync_health.rpc(_health, _max_health)


func _on_inventory_changed() -> void:
	_refresh_max_health(false)
	_refresh_melee_view()


func _on_equipped_weapon_changed(weapon_id: String) -> void:
	_refresh_melee_view()
	if weapon_id != "" and WeaponManager.can_use_shop_ranged():
		_get_shop_blaster(weapon_id).configure(weapon_id)


func _refresh_melee_view() -> void:
	if _fp_melee == null:
		return
	_fp_melee.set_weapon(WeaponManager.get_equipped_melee_id())


func _refresh_max_health(fill_new_bonus: bool) -> void:
	var new_max := InventoryManager.get_max_hp()
	var bonus_delta := new_max - _max_health
	_max_health = new_max
	if fill_new_bonus:
		_health = _max_health
	elif bonus_delta > 0.0:
		_health += bonus_delta
	_health = minf(_health, _max_health)
	health_changed.emit(_health, _max_health)


func _die() -> void:
	_is_dead = true
	_respawn_timer = 3.0
	velocity = Vector3.ZERO
	died.emit()
	name_label.modulate = Color(0.55, 0.12, 0.12)


func _respawn() -> void:
	global_position = _spawn_anchor if _spawn_anchor != Vector3.ZERO else global_position
	global_position.y = maxf(global_position.y, SpawnPoints.SPAWN_FOOT_Y)
	ensure_safe_ground()
	_stuck_frames = 0
	_is_dead = false
	_health = _max_health
	_damage_cooldown = 0.0
	name_label.modulate = Color(0.95, 0.9, 0.82, 1)
	health_changed.emit(_health, _max_health)
	_sync_health.rpc(_health, _max_health)


@rpc("any_peer", "unreliable")
func _sync_health(current: float, maximum: float) -> void:
	if is_multiplayer_authority():
		return
	_health = current
	_max_health = maximum
	health_changed.emit(_health, _max_health)


func get_znood() -> ZnoodDevice:
	return znood_mount


func get_facing_yaw() -> float:
	var yaw_source := _get_camera_yaw_source()
	if yaw_source >= 0.0:
		return yaw_source
	return rotation.y


func _get_active_ladder() -> ExteriorLadderScript:
	for node in get_tree().get_nodes_in_group("exterior_ladder"):
		if node is ExteriorLadderScript and (node as ExteriorLadderScript).has_player(self):
			return node as ExteriorLadderScript
	return null


func _get_flat_move_direction(input_dir: Vector2) -> Vector3:
	if input_dir == Vector2.ZERO:
		return Vector3.ZERO
	if MouseLook.is_active():
		return MouseLook.get_flat_direction(input_dir)
	var pivot := _get_camera_pivot()
	if pivot != null:
		var direction := pivot.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
		direction.y = 0.0
		if direction.length_squared() > 0.0001:
			return direction.normalized()
	return Vector3(input_dir.x, 0.0, input_dir.y).normalized()


func _get_camera_yaw_source() -> float:
	if MouseLook.is_active():
		return MouseLook.get_yaw()
	var pivot := _get_camera_pivot()
	if pivot != null:
		return pivot.rotation.y
	return -1.0


func _get_camera_pivot() -> Node3D:
	var game := get_tree().current_scene
	if game and game.has_method("get_camera_pivot"):
		return game.call("get_camera_pivot") as Node3D
	if game and game.has_node("CameraPivot"):
		return game.get_node("CameraPivot") as Node3D
	return null


func _unstuck_nudge() -> void:
	var forward := _get_flat_move_direction(Vector2(0.0, 1.0))
	if forward == Vector3.ZERO:
		forward = Vector3(-global_transform.basis.z.x, 0.0, -global_transform.basis.z.z).normalized()
	if forward.length_squared() < 0.01:
		forward = Vector3(0.0, 0.0, 1.0)
	global_position += Vector3(0.0, 1.1, 0.0) + forward.normalized() * 2.2
	velocity = Vector3.ZERO
	_stuck_frames = 0
	ensure_safe_ground()


func stamp_znood_at(door: Node) -> void:
	if not is_multiplayer_authority():
		return
	if znood_mount == null or not znood_mount.is_ready():
		return
	znood_mount.play_stamp(door.global_position)
	_sync_znood_stamp.rpc(door.global_position)
	if door.has_method("unlock_from_stamp"):
		door.unlock_from_stamp(multiplayer.get_unique_id())


@rpc("any_peer", "call_local", "reliable")
func _sync_znood_stamp(target: Vector3) -> void:
	if is_multiplayer_authority():
		return
	if znood_mount != null:
		znood_mount.play_stamp(target)


func _handle_combat_input() -> void:
	if get_tree().paused or not MouseLook.is_active():
		return
	if Input.is_action_just_pressed("punch"):
		_try_punch()
	if not WeaponManager.can_use_equipped_weapon():
		return
	if Input.is_action_just_pressed("reload"):
		if WeaponManager.can_use_laserrifle() and _laser_blaster.try_reload():
			_play_combat_sfx(RpgAudioLibraryScript.laser_reload())
		elif WeaponManager.can_use_slimeshooter() and _slime_blaster.try_reload():
			_play_combat_sfx(RpgAudioLibraryScript.reload())
		else:
			var shop_ranged_id := WeaponManager.get_equipped_shop_ranged_id()
			if shop_ranged_id != "" and _get_shop_blaster(shop_ranged_id).try_reload():
				_play_combat_sfx(_reload_sfx_for_weapon(shop_ranged_id))
	if Input.is_action_just_pressed("fire"):
		if WeaponManager.can_use_laserrifle():
			_try_fire_laser()
		elif WeaponManager.can_use_slimeshooter():
			_try_fire_slime()
		elif WeaponManager.can_use_shop_ranged():
			_try_fire_shop_ranged()
		elif WeaponManager.can_use_melee():
			_try_melee_strike()


func _try_melee_strike() -> void:
	if _melee_cooldown > 0.0 or _is_dead:
		return
	var weapon_id := WeaponManager.get_equipped_melee_id()
	if weapon_id == "":
		return
	_melee_cooldown = MeleeWeaponStrikeScript.get_cooldown(weapon_id)
	_play_combat_sfx(RpgAudioLibraryScript.melee_swing(weapon_id))
	if _human_animator:
		_human_animator.trigger_attack()
	if _fp_melee:
		_fp_melee.trigger_swing()
	_sync_melee_strike.rpc(weapon_id)
	get_tree().create_timer(MeleeWeaponStrikeScript.get_hit_delay(weapon_id)).timeout.connect(
		_apply_melee_hit.bind(weapon_id),
		CONNECT_ONE_SHOT
	)


func _apply_melee_hit(weapon_id: String) -> void:
	if not is_multiplayer_authority() or _is_dead:
		return
	var origin := MouseLook.get_aim_origin(global_position)
	var direction := MouseLook.get_aim_direction()
	var target := MeleeWeaponStrikeScript.resolve_target(
		get_world_3d().direct_space_state,
		origin,
		direction,
		MeleeWeaponStrikeScript.get_range(weapon_id),
		get_rid()
	)
	MeleeWeaponStrikeScript.apply_hit(
		target,
		MeleeWeaponStrikeScript.get_damage(weapon_id),
		multiplayer.get_unique_id()
	)
	if target != null:
		_play_combat_sfx(RpgAudioLibraryScript.melee_hit())


@rpc("any_peer", "call_local", "reliable")
func _sync_melee_strike(weapon_id: String) -> void:
	if is_multiplayer_authority():
		return
	if _human_animator:
		_human_animator.trigger_attack()
	if _fp_melee:
		_fp_melee.set_weapon(weapon_id)
		_fp_melee.trigger_swing()


func _try_punch() -> void:
	if _punch_cooldown > 0.0 or _is_dead:
		return
	_punch_cooldown = BoxingPunchScript.PUNCH_COOLDOWN
	_play_combat_sfx(RpgAudioLibraryScript.punch_swing())
	if _human_animator:
		_human_animator.trigger_punch()
	if _fp_punch:
		_fp_punch.trigger_punch()
	_sync_punch.rpc()
	get_tree().create_timer(BoxingPunchScript.HIT_DELAY_SEC).timeout.connect(
		_apply_punch_hit,
		CONNECT_ONE_SHOT
	)


func _apply_punch_hit() -> void:
	if not is_multiplayer_authority() or _is_dead:
		return
	var origin := MouseLook.get_aim_origin(global_position)
	var direction := MouseLook.get_aim_direction()
	var target := BoxingPunchScript.resolve_target(
		get_world_3d().direct_space_state,
		origin,
		direction,
		get_rid()
	)
	BoxingPunchScript.apply_hit(target, multiplayer.get_unique_id())
	if target != null:
		_play_combat_sfx(RpgAudioLibraryScript.punch_hit())


@rpc("any_peer", "call_local", "reliable")
func _sync_punch() -> void:
	if is_multiplayer_authority():
		return
	if _human_animator:
		_human_animator.trigger_punch()


func _try_fire_slime() -> void:
	if not _slime_blaster.try_fire():
		return
	_play_combat_sfx(RpgAudioLibraryScript.slime_fire())
	if _human_animator:
		_human_animator.trigger_attack()
	var origin := MouseLook.get_aim_origin(global_position)
	var direction := MouseLook.get_aim_direction()
	_spawn_slime_projectile.rpc(origin, direction, multiplayer.get_unique_id())


func _try_fire_laser() -> void:
	if not _laser_blaster.try_fire():
		return
	_play_combat_sfx(RpgAudioLibraryScript.laser_fire())
	if _human_animator:
		_human_animator.trigger_attack()
	var origin := MouseLook.get_aim_origin(global_position)
	var direction := MouseLook.get_aim_direction()
	_spawn_laser_projectile.rpc(origin, direction, multiplayer.get_unique_id())


func _tick_shop_blaster(delta: float) -> void:
	var weapon_id := WeaponManager.get_equipped_shop_ranged_id()
	if weapon_id == "":
		return
	_get_shop_blaster(weapon_id).tick(delta)


func _get_shop_blaster(weapon_id: String):
	if not _shop_blasters.has(weapon_id):
		var blaster = RangedWeaponBlasterClass.new()
		blaster.configure(weapon_id)
		_shop_blasters[weapon_id] = blaster
	return _shop_blasters[weapon_id]


func _try_fire_shop_ranged() -> void:
	var weapon_id := WeaponManager.get_equipped_shop_ranged_id()
	if weapon_id == "":
		return
	if not _get_shop_blaster(weapon_id).try_fire():
		return
	_play_combat_sfx(_fire_sfx_for_weapon(weapon_id))
	if _human_animator:
		_human_animator.trigger_attack()
	var origin := MouseLook.get_aim_origin(global_position)
	var direction := MouseLook.get_aim_direction()
	_spawn_catalog_projectile.rpc(origin, direction, multiplayer.get_unique_id(), weapon_id)


func _fire_sfx_for_weapon(weapon_id: String) -> AudioStream:
	var kind := str(WeaponCatalogScript.get_stats(weapon_id).get("combat_kind", "energy"))
	if kind in ["slime", "melt"]:
		return RpgAudioLibraryScript.slime_fire()
	return RpgAudioLibraryScript.laser_fire()


func _reload_sfx_for_weapon(weapon_id: String) -> AudioStream:
	var kind := str(WeaponCatalogScript.get_stats(weapon_id).get("combat_kind", "energy"))
	if kind in ["slime", "melt"]:
		return RpgAudioLibraryScript.reload()
	return RpgAudioLibraryScript.laser_reload()


@rpc("any_peer", "call_local", "reliable")
func _spawn_catalog_projectile(
	origin: Vector3,
	direction: Vector3,
	shooter_id: int,
	weapon_id: String
) -> void:
	if get_multiplayer_authority() == shooter_id and _human_animator:
		_human_animator.trigger_attack()
	var projectiles_root := _get_projectiles_root()
	if projectiles_root == null:
		return
	var kind := str(WeaponCatalogScript.get_stats(weapon_id).get("combat_kind", "energy"))
	if kind in ["laser", "energy", "volt"]:
		LaserMuzzleSmokeFxScript.burst(projectiles_root, origin, direction)
	var projectile := CATALOG_PROJECTILE_SCENE.instantiate()
	projectiles_root.add_child(projectile)
	if projectile.has_method("launch"):
		projectile.launch(origin, direction, shooter_id, weapon_id)


@rpc("any_peer", "call_local", "reliable")
func _spawn_slime_projectile(origin: Vector3, direction: Vector3, shooter_id: int) -> void:
	if get_multiplayer_authority() == shooter_id and _human_animator:
		_human_animator.trigger_attack()
	var projectiles_root := _get_projectiles_root()
	if projectiles_root == null:
		return
	var projectile := SLIME_PROJECTILE_SCENE.instantiate()
	projectiles_root.add_child(projectile)
	if projectile.has_method("launch"):
		projectile.launch(origin, direction, shooter_id)


@rpc("any_peer", "call_local", "reliable")
func _spawn_laser_projectile(origin: Vector3, direction: Vector3, shooter_id: int) -> void:
	if get_multiplayer_authority() == shooter_id and _human_animator:
		_human_animator.trigger_attack()
	var projectiles_root := _get_projectiles_root()
	if projectiles_root == null:
		return
	LaserMuzzleSmokeFxScript.burst(projectiles_root, origin, direction)
	var projectile := LASER_PROJECTILE_SCENE.instantiate()
	projectiles_root.add_child(projectile)
	if projectile.has_method("launch"):
		projectile.launch(origin, direction, shooter_id)


func _get_projectiles_root() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("Projectiles")


func _play_combat_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	GameSfxScript.play_3d_varied(self, global_position + Vector3(0.0, 1.2, 0.0), stream)