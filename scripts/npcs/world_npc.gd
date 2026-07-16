extends CharacterBody3D

const HumanCharacterLibraryScript = preload("res://scripts/assets/human_character_library.gd")
const GleazerBuilderScript = preload("res://scripts/monsters/gleazer_builder.gd")
const GleazerLoreScript = preload("res://scripts/story/gleazer_lore.gd")
const PedestrianStyleScript = preload("res://scripts/npcs/pedestrian_style.gd")
const PedestrianCatalogScript = preload("res://scripts/npcs/pedestrian_catalog.gd")
const ZezzlorBuilderScript = preload("res://scripts/monsters/zezzlor_builder.gd")
const StoryInteractableScript = preload("res://scripts/story/story_interactable.gd")
const SlimeDamageScript = preload("res://scripts/combat/slime_damage.gd")
const Hurtbox3DScript = preload("res://scripts/combat/hurtbox_3d.gd")
const NpcHealthBar3DScript = preload("res://scripts/ui/npc_health_bar_3d.gd")
const NpcDialogueBarkScript = preload("res://scripts/audio/npc_dialogue_bark.gd")
const ZezzlorLoreScript = preload("res://scripts/story/zezzlor_lore.gd")
const SrcGuardLoreScript = preload("res://scripts/story/src_guard_lore.gd")
const SrcHqCatalogScript = preload("res://scripts/story/src_hq_catalog.gd")
const CriminalBossLoreScript = preload("res://scripts/story/criminal_boss_lore.gd")
const SimulationLodScript = preload("res://scripts/world/simulation_lod.gd")

const TURN_SPEED := 5.0
const SRC_TURN_SPEED := 6.5
const CORROSION_COLOR := Color(0.22, 0.92, 0.28)
const SYNC_INTERVAL := 0.18

var _model_pivot: Node3D
var _name_label: Label3D
var _health_bar: NpcHealthBar3D
var _display_name := "NPC"
var _move_speed := 1.0
var _wander_dir := Vector3.FORWARD
var _wander_timer := 0.0
var _bounds_center := Vector3.ZERO
var _bounds_radius := 8.0
var _anim_player: AnimationPlayer
var _human_animator: HumanAvatarAnimator
var _avatar_animator: AvatarAnimator
var _moving := false
var _wander_enabled := true
var _rng := RandomNumberGenerator.new()
var _npc_id := ""
var _health := SlimeDamageScript.NPC_MAX_HP
var _max_health := SlimeDamageScript.NPC_MAX_HP
var _dead := false
var _corrosion := 0.0
var _model_root: Node3D
var _is_src_guard := false
var _src_guard_role := ""
var _src_guard_name := ""
var _post_position := Vector3.ZERO
var _post_rotation_y := 0.0
var _snoop_bearing := 0.0
var _src_target: Node3D
var _src_block_timer := 0.0
var _src_harass_timer := 0.0
var _src_block_pos := Vector3.ZERO
var _src_is_blocking := false
var _is_zezzlor := false
var _is_gleazer := false
var _gleazer_role := "recruit"
var _gleazer_name := ""
var _quest_bark_timer := 0.0
var _is_allmakare := false
var _allmakare_name := ""
var _is_pedestrian := false
var _is_criminal_boss := false
var _is_criminal_henchman := false
var _criminal_boss_id := ""
var _criminal_boss_name := ""
var _criminal_henchman_name := ""
var _criminal_harass_timer := 0.0
var _route: Array[Vector3] = []
var _route_index := 0
var _wallet := 0
var _style_seed := 0
var _smell_wobble := 0.0
var _smell_timer := 0.0
var _last_melee_attacker_id := -1
var _game_director: Node
var _sync_accum := 0.0
var _lod_wait := 0.0


func setup(entry: Dictionary, world_pos: Vector3, seed: int) -> void:
	_model_pivot = $ModelPivot
	_name_label = $NameLabel
	_rng.seed = seed
	_npc_id = str(entry.get("id", ""))
	_display_name = _resolve_display_name(entry)
	_move_speed = float(entry.get("speed", 1.0))
	_wander_enabled = bool(entry.get("wander", true)) and _move_speed > 0.01
	_bounds_radius = float(entry.get("wander_radius", 8.0))
	_name_label.text = _display_name
	_is_zezzlor = bool(entry.get("zezzlor", false))
	_is_gleazer = bool(entry.get("gleazer", false))
	_gleazer_role = str(entry.get("gleazer_role", "recruit"))
	_gleazer_name = str(entry.get("gleazer_name", ""))
	_is_allmakare = bool(entry.get("allmakare", false))
	_allmakare_name = str(entry.get("allmakare_name", entry.get("zezzlor_name", "")))
	_is_pedestrian = bool(entry.get("pedestrian", false))
	_is_criminal_boss = bool(entry.get("criminal_boss", false))
	_is_criminal_henchman = bool(entry.get("criminal_henchman", false))
	_criminal_boss_id = str(entry.get("criminal_boss_id", ""))
	_criminal_boss_name = str(entry.get("boss_name", ""))
	_criminal_henchman_name = str(entry.get("henchman_name", ""))
	_wallet = int(entry.get("wallet", 0)) if _is_pedestrian else 0
	_style_seed = int(entry.get("style_seed", seed))
	_configure_route(entry, world_pos)
	if _is_zezzlor:
		var rank_id := str(entry.get("zezzlor_rank", "patrol"))
		_name_label.modulate = ZezzlorLoreScript.rank_color(rank_id)
	elif _is_gleazer:
		_name_label.modulate = GleazerLoreScript.role_color(_gleazer_role)
	elif bool(entry.get("src_guard", false)):
		_name_label.modulate = SrcGuardLoreScript.LABEL_COLOR
		_configure_src_guard(entry, world_pos)
	elif _is_criminal_boss or _is_criminal_henchman:
		_refresh_criminal_label_color()
		if _is_criminal_henchman:
			_criminal_harass_timer = _rng.randf_range(2.0, 6.0)
	position = world_pos
	rotation.y = float(entry.get("rotation_y", 0.0))
	_bounds_center = world_pos
	_mount_model(entry)
	_game_director = get_tree().get_first_node_in_group("game_director")
	if not _is_zezzlor:
		_setup_hurtbox()
		_setup_health_bar()
	if not _is_pedestrian:
		_attach_interactable(entry)
	_pick_new_direction()
	_wander_timer = _rng.randf_range(1.0, 3.0)
	set_meta("npc_id", _npc_id)
	add_to_group("world_npc")
	if _is_gleazer:
		add_to_group("gleazer_npc")
		_quest_bark_timer = _rng.randf_range(6.0, 14.0)
	if _is_allmakare:
		add_to_group("allmakare_npc")
		_post_position = world_pos
		_post_rotation_y = float(entry.get("rotation_y", 0.0))
	if _is_pedestrian:
		add_to_group("pedestrian_npc")
	if _is_criminal_boss:
		add_to_group("criminal_boss_npc")
	if _is_criminal_henchman:
		add_to_group("criminal_henchman_npc")
	if (_is_criminal_boss or _is_criminal_henchman) and _criminal_boss_id != "":
		if not CriminalBossManager.respect_changed.is_connected(_on_criminal_respect_changed):
			CriminalBossManager.respect_changed.connect(_on_criminal_respect_changed)


func _physics_process(delta: float) -> void:
	if not _is_simulation_authority():
		return
	if _dead:
		return
	_lod_wait += delta
	var lod_interval := SimulationLodScript.physics_interval(self)
	if _lod_wait >= lod_interval:
		var step := _lod_wait
		_lod_wait = 0.0
		if _is_gleazer:
			_tick_gleazer(step)
		if _is_criminal_henchman:
			_tick_criminal_henchman(step)
		if _is_allmakare:
			_tick_allmakare(step)
		elif _is_pedestrian:
			_simulate_route(step)
		elif _is_src_guard:
			_tick_src_guard(step)
		elif _wander_enabled:
			_simulate_wander(step)
		else:
			velocity = Vector3.ZERO
			if _moving:
				_moving = false
				_update_animation()
	if multiplayer.multiplayer_peer != null:
		_sync_accum += delta
		if _sync_accum >= SYNC_INTERVAL:
			_sync_accum = 0.0
			_sync_state.rpc(position, rotation.y, _moving)


func _is_simulation_authority() -> bool:
	if multiplayer.multiplayer_peer == null:
		return true
	return is_multiplayer_authority()


func _simulate_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_pick_new_direction()
		_wander_timer = _rng.randf_range(2.0, 5.0)

	var to_center := _bounds_center - global_position
	to_center.y = 0.0
	if to_center.length() > _bounds_radius:
		_wander_dir = to_center.normalized()
		_wander_timer = _rng.randf_range(0.8, 1.8)

	if _wander_dir.length_squared() < 0.01:
		velocity = Vector3.ZERO
	else:
		velocity = _wander_dir * _move_speed
		var target_yaw := atan2(_wander_dir.x, _wander_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, TURN_SPEED * delta)

	var prev_pos := global_position
	move_and_slide()
	_moving = global_position.distance_to(prev_pos) > 0.02
	_update_animation()


func _configure_src_guard(entry: Dictionary, world_pos: Vector3) -> void:
	_is_src_guard = true
	_src_guard_role = str(entry.get("src_guard_role", "guard"))
	_src_guard_name = str(entry.get("src_guard_name", ""))
	_post_position = world_pos
	_post_rotation_y = float(entry.get("rotation_y", 0.0))
	_snoop_bearing = _rng.randf_range(0.0, TAU)
	_src_block_timer = _rng.randf_range(1.5, 4.0)
	_src_harass_timer = _rng.randf_range(2.0, 5.0)
	add_to_group("src_guard")


func _tick_src_guard(delta: float) -> void:
	var hq_pos := SrcHqCatalogScript.get_hq_world_position()
	var target := _find_src_target(hq_pos, SrcHqCatalogScript.HQ_RADIUS_M)
	if target == null:
		_src_target = null
		_src_is_blocking = false
		_return_to_post(delta)
		return

	_src_target = target
	_src_harass_timer -= delta
	_src_block_timer -= delta

	if _src_is_blocking:
		_move_toward_point(_src_block_pos, SrcGuardLoreScript.SNOOP_SPEED * 1.15, delta, target)
		if global_position.distance_to(_src_block_pos) < 1.25:
			_src_is_blocking = false
			_try_src_harass(target, "block")
		return

	if (
		_src_block_timer <= 0.0
		and global_position.distance_to(target.global_position) <= SrcGuardLoreScript.BLOCK_RANGE_M
	):
		_src_block_timer = _rng.randf_range(
			SrcGuardLoreScript.BLOCK_COOLDOWN_MIN,
			SrcGuardLoreScript.BLOCK_COOLDOWN_MAX
		)
		_start_src_block(target)
		return

	_snoop_on_target(target, delta)
	if (
		_src_harass_timer <= 0.0
		and global_position.distance_to(target.global_position) <= SrcGuardLoreScript.HARASS_RANGE_M
	):
		_src_harass_timer = SrcGuardLoreScript.HARASS_COOLDOWN
		_try_src_harass(target, "snoop")


func _find_src_target(hq_pos: Vector3, radius: float) -> Node3D:
	var best: Node3D = null
	var best_dist := 999999.0
	for player in _iter_players():
		if SrcHqCatalogScript.flat_distance(player.global_position, hq_pos) > radius:
			continue
		var dist := global_position.distance_to(player.global_position)
		if dist < best_dist:
			best_dist = dist
			best = player
	return best


func _snoop_on_target(target: Node3D, delta: float) -> void:
	var offset := Vector3(sin(_snoop_bearing), 0.0, cos(_snoop_bearing)) * SrcGuardLoreScript.SNOOP_DISTANCE
	var desired := target.global_position + offset
	desired.y = global_position.y
	_move_toward_point(desired, SrcGuardLoreScript.SNOOP_SPEED, delta, target)


func _start_src_block(target: Node3D) -> void:
	var forward := Vector3(sin(target.rotation.y), 0.0, cos(target.rotation.y))
	if target is CharacterBody3D:
		var body := target as CharacterBody3D
		if body.velocity.length() > 0.35:
			forward = body.velocity
			forward.y = 0.0
			forward = forward.normalized()
	_src_block_pos = target.global_position + forward * 2.6
	_src_block_pos.y = global_position.y
	_src_is_blocking = true


func _return_to_post(delta: float) -> void:
	var to_post := _post_position - global_position
	to_post.y = 0.0
	if to_post.length() < 0.35:
		velocity = Vector3.ZERO
		_moving = false
		rotation.y = lerp_angle(rotation.y, _post_rotation_y, SRC_TURN_SPEED * delta)
		_update_animation()
		return
	_move_toward_point(_post_position, SrcGuardLoreScript.RETURN_SPEED, delta, null)


func _move_toward_point(
	desired: Vector3,
	speed: float,
	delta: float,
	look_target: Node3D
) -> void:
	var to_point := desired - global_position
	to_point.y = 0.0
	var dist := to_point.length()
	if dist < 0.25:
		velocity = Vector3.ZERO
	else:
		var dir := to_point / dist
		velocity = dir * speed
		var target_yaw := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, SRC_TURN_SPEED * delta)

	if look_target != null and is_instance_valid(look_target):
		var to_target := look_target.global_position - global_position
		to_target.y = 0.0
		if to_target.length() > 0.5:
			var stare_yaw := atan2(to_target.x, to_target.z)
			rotation.y = lerp_angle(rotation.y, stare_yaw, SRC_TURN_SPEED * delta * 1.35)

	var prev_pos := global_position
	move_and_slide()
	_moving = global_position.distance_to(prev_pos) > 0.02
	_update_animation()


func _try_src_harass(target: Node3D, kind: String) -> void:
	if not target.is_multiplayer_authority():
		return
	var line := SrcGuardLoreScript.random_harass_line(kind, _rng)
	NpcDialogueBarkScript.play_for_npc(self, "shouting")
	QuestManager.story_toast.emit(
		SrcGuardLoreScript.format_name(_src_guard_role, _src_guard_name),
		line
	)


func _pick_new_direction() -> void:
	if not _wander_enabled:
		_wander_dir = Vector3.ZERO
		return
	var angle := _rng.randf_range(0.0, TAU)
	_wander_dir = Vector3(sin(angle), 0.0, cos(angle)).normalized()


func _resolve_display_name(entry: Dictionary) -> String:
	if bool(entry.get("zezzlor", false)):
		return ZezzlorLoreScript.format_name(
			str(entry.get("zezzlor_rank", "patrol")),
			str(entry.get("zezzlor_name", ""))
		)
	if bool(entry.get("src_guard", false)):
		return SrcGuardLoreScript.format_name(
			str(entry.get("src_guard_role", "guard")),
			str(entry.get("src_guard_name", ""))
		)
	if bool(entry.get("gleazer", false)):
		return GleazerLoreScript.format_name(
			str(entry.get("gleazer_role", "recruit")),
			str(entry.get("gleazer_name", ""))
		)
	if bool(entry.get("allmakare", false)):
		return ZezzlorLoreScript.format_name("allmakare", str(entry.get("allmakare_name", "")))
	if bool(entry.get("criminal_boss", false)):
		return CriminalBossLoreScript.format_boss_title(
			str(entry.get("boss_name", "")),
			str(entry.get("syndicate", ""))
		)
	if bool(entry.get("criminal_henchman", false)):
		return CriminalBossLoreScript.format_henchman_name(str(entry.get("henchman_name", "")))
	return str(entry.get("name", "NPC"))


func build_allmakare_talk_payload() -> Dictionary:
	return {
		"allmakare_name": _allmakare_name,
		"world_pos": global_position,
	}


func _configure_route(entry: Dictionary, world_pos: Vector3) -> void:
	_route.clear()
	_route_index = 0
	if not _is_pedestrian:
		return
	var raw: Variant = entry.get("route", [])
	if raw is Array:
		for point in raw:
			if point is Vector3:
				_route.append(world_pos + (point as Vector3) - (entry.get("local_pos", Vector3.ZERO) as Vector3))
	if _route.is_empty():
		_route.append(world_pos)
		_route.append(world_pos + Vector3(40.0, 0.0, 0.0))


func _simulate_route(delta: float) -> void:
	if _route.is_empty():
		velocity = Vector3.ZERO
		_moving = false
		_update_animation()
		return
	var target := _route[_route_index]
	var to := target - global_position
	to.y = 0.0
	var dist := to.length()
	if dist <= PedestrianCatalogScript.ROUTE_REACH_M:
		_route_index = (_route_index + 1) % _route.size()
		target = _route[_route_index]
		to = target - global_position
		to.y = 0.0
		dist = to.length()
	if dist < 0.05:
		velocity = Vector3.ZERO
		_moving = false
	else:
		var dir := to / dist
		velocity = dir * _move_speed
		var target_yaw := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, TURN_SPEED * delta)
		_moving = true
	var prev_pos := global_position
	move_and_slide()
	_moving = global_position.distance_to(prev_pos) > 0.02 or _moving
	_update_animation()


func _tick_allmakare(delta: float) -> void:
	_smell_timer -= delta
	var debt := AllmakareDebtManager.should_smell_follow(_npc_id)
	if debt.is_empty():
		_return_to_post(delta)
		return
	var target := _find_debtor_player()
	if target == null:
		_return_to_post(delta)
		return
	_smell_wobble += delta * 2.4
	var wobble := Vector3(sin(_smell_wobble) * 1.8, 0.0, cos(_smell_wobble * 0.8) * 1.8)
	var desired := target.global_position + wobble
	desired.y = global_position.y
	_move_toward_point(desired, 2.65, delta, null)
	if _smell_timer <= 0.0 and global_position.distance_to(target.global_position) <= 5.0:
		_smell_timer = 6.0
		if target.is_multiplayer_authority():
			NpcDialogueBarkScript.play_for_npc(self, "miscellaneous")
			QuestManager.story_toast.emit(
				"Allmakare — luktspår",
				"%s känner din doft. Betala %d %s — vi ser inget annat."
				% [
					_allmakare_name,
					int(debt.get("amount", 0)),
					ItemCatalog.currency_symbol(),
				]
			)


func _find_debtor_player() -> Node3D:
	for player in _iter_players():
		var pid: int = player.get_multiplayer_authority()
		var pd: Dictionary = AllmakareDebtManager.get_debt_for_peer(pid)
		if pd.is_empty() or str(pd.get("creditor_id", "")) != _npc_id:
			continue
		return player
	return null


func _try_rob_pedestrian(shooter_id: int) -> void:
	if _wallet <= 0:
		return
	var amount := _wallet
	_wallet = 0
	_ensure_game_director()
	if _game_director == null or not _game_director.get("players") is Dictionary:
		return
	if not _game_director.players.has(shooter_id):
		return
	var player: Node3D = _game_director.players[shooter_id]
	if player == null or not player.is_multiplayer_authority():
		return
	InventoryManager.add_mydrillium(amount)
	QuestManager.story_toast.emit(
		"Rån",
		"Du slog ner %s och tog %d %s från plånboken."
		% [_display_name, amount, ItemCatalog.currency_symbol()]
	)


func _refresh_criminal_label_color() -> void:
	if _criminal_boss_id == "":
		return
	var tier := CriminalBossManager.get_tier(_criminal_boss_id)
	_name_label.modulate = CriminalBossLoreScript.label_color_for_tier(tier)


func _tick_criminal_henchman(delta: float) -> void:
	if _criminal_boss_id == "":
		return
	if CriminalBossManager.is_respected(_criminal_boss_id):
		if _wander_enabled:
			_simulate_wander(delta)
		return
	_criminal_harass_timer -= delta
	if _wander_enabled:
		_simulate_wander(delta)
	if _criminal_harass_timer > 0.0:
		return
	var target := _find_nearby_local_player(9.0)
	if target == null:
		return
	_criminal_harass_timer = _rng.randf_range(5.0, 11.0)
	if _rng.randf() > 0.55:
		return
	var line := CriminalBossLoreScript.pick_henchman_line(false, _rng)
	NpcDialogueBarkScript.play_for_npc(self, "shouting")
	QuestManager.story_toast.emit(_display_name, line)
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() > 0.5:
		var stare_yaw := atan2(to_target.x, to_target.z)
		rotation.y = lerp_angle(rotation.y, stare_yaw, SRC_TURN_SPEED * delta * 2.0)


func _on_criminal_respect_changed(boss_id: String, _respect: int) -> void:
	if boss_id != _criminal_boss_id:
		return
	_refresh_criminal_label_color()


func build_criminal_talk_payload() -> Dictionary:
	return {
		"criminal_boss_id": _criminal_boss_id,
		"boss_name": _criminal_boss_name,
		"henchman_name": _criminal_henchman_name,
		"world_pos": global_position,
	}


func build_gleazer_talk_payload() -> Dictionary:
	_ensure_game_director()
	var player_pos := Vector3.ZERO
	if _game_director != null and _game_director.has_method("get_local_player"):
		var player: Node3D = _game_director.get_local_player()
		if player != null:
			player_pos = player.global_position
	return {
		"gleazer_role": _gleazer_role,
		"gleazer_name": _gleazer_name,
		"world_pos": global_position,
		"player_pos": player_pos,
	}


func _tick_gleazer(delta: float) -> void:
	GleazerQuestManager.set_giver_world_pos(_npc_id, global_position)
	if not _is_simulation_authority():
		return
	_quest_bark_timer -= delta
	if _quest_bark_timer > 0.0 or GleazerQuestManager.has_active_quest():
		return
	var target := _find_nearby_local_player(11.0)
	if target == null:
		return
	_quest_bark_timer = _rng.randf_range(18.0, 32.0)
	if _rng.randf() > 0.42:
		return
	NpcDialogueBarkScript.play_for_npc(self, "miscellaneous")
	QuestManager.story_toast.emit(
		GleazerLoreScript.format_dialogue_title(_gleazer_role, _gleazer_name),
		"Psst! Gleazers har en ny quest. Den kommer gå åt skogen. Prata med mig!"
	)


func _find_nearby_local_player(radius: float) -> Node3D:
	for player in _iter_players():
		if not player.is_multiplayer_authority():
			continue
		if global_position.distance_to(player.global_position) <= radius:
			return player
	return null


func take_corrosive_slime(amount: float, shooter_id: int) -> void:
	if _dead or amount <= 0.0:
		return
	if multiplayer.multiplayer_peer == null:
		_apply_corrosive_slime_local(amount, shooter_id)
		return
	_apply_corrosive_slime.rpc(amount, shooter_id)


func take_damage(amount: float) -> void:
	take_corrosive_slime(amount, -1)


func take_melee_hit(amount: float, attacker_id: int = -1) -> void:
	if _dead or amount <= 0.0:
		return
	if multiplayer.multiplayer_peer == null:
		_apply_melee_hit_local(amount, attacker_id)
		return
	_apply_melee_hit.rpc(amount, attacker_id)


@rpc("any_peer", "call_local", "reliable")
func _apply_melee_hit(amount: float, attacker_id: int = -1) -> void:
	if not _is_simulation_authority():
		return
	_apply_melee_hit_local(amount, attacker_id)


func _apply_melee_hit_local(amount: float, attacker_id: int = -1) -> void:
	if _dead or amount <= 0.0:
		return
	if _is_zezzlor:
		_flash_corrosion_hit()
		return
	if attacker_id >= 0:
		_last_melee_attacker_id = attacker_id
	_health = maxf(0.0, _health - amount)
	_flash_corrosion_hit()
	NpcDialogueBarkScript.play_for_npc(self, "damage")
	if _is_pedestrian and _wallet > 0 and attacker_id >= 0:
		MydrilliumEconomyManager.rob_pedestrian_wallet(self, attacker_id)
	_broadcast_health()
	if _health <= 0.0:
		_die(attacker_id)


@rpc("any_peer", "call_local", "reliable")
func _apply_corrosive_slime(amount: float, shooter_id: int) -> void:
	if not _is_simulation_authority():
		return
	_apply_corrosive_slime_local(amount, shooter_id)


func _apply_corrosive_slime_local(amount: float, shooter_id: int) -> void:
	if _dead or amount <= 0.0:
		return
	if _is_zezzlor:
		_flash_corrosion_hit()
		return
	_health = maxf(0.0, _health - amount)
	_corrosion = minf(1.0, _corrosion + SlimeDamageScript.CORROSION_BUILDUP)
	_apply_corrosion_visual()
	_flash_corrosion_hit()
	NpcDialogueBarkScript.play_for_npc(self, "damage")
	_broadcast_health()
	if _health <= 0.0:
		_die(shooter_id)


func _setup_hurtbox() -> void:
	Hurtbox3DScript.attach(self)


func _setup_health_bar() -> void:
	_health_bar = NpcHealthBar3DScript.new()
	_health_bar.name = "HealthBar"
	_health_bar.position = Vector3(0.0, 2.75, 0.0)
	add_child(_health_bar)
	_health_bar.tree_entered.connect(func(): _refresh_health_bar(), CONNECT_ONE_SHOT)


func _refresh_health_bar() -> void:
	if _health_bar:
		_health_bar.update_health(_health, _max_health, _dead)


func _broadcast_health() -> void:
	_refresh_health_bar()
	if multiplayer.multiplayer_peer != null:
		_sync_health_visuals.rpc(_health, _max_health, _dead)


@rpc("any_peer", "call_local", "unreliable")
func _sync_health_visuals(current: float, maximum: float, dead: bool) -> void:
	_health = current
	_max_health = maxf(maximum, 1.0)
	_dead = dead
	_refresh_health_bar()
	if dead:
		_name_label.text = "%s — frätt bort" % _display_name
		_name_label.modulate = Color(0.35, 0.9, 0.32)


func get_health_ratio() -> float:
	return _health / maxf(_max_health, 1.0)


func is_dead() -> bool:
	return _dead


func _mount_model(entry: Dictionary) -> void:
	for child in _model_pivot.get_children():
		child.queue_free()
	var scale_factor := float(entry.get("scale", 1.0))
	if bool(entry.get("zezzlor", false)):
		var rank_id := str(entry.get("zezzlor_rank", "patrol"))
		var built: Dictionary = ZezzlorBuilderScript.build(_model_pivot, rank_id, scale_factor)
		_model_root = built.get("root") as Node3D
		_human_animator = null
		_avatar_animator = AvatarAnimator.ensure_on(_model_pivot)
		_avatar_animator.bind(_model_pivot)
		_anim_player = null
		return
	if bool(entry.get("gleazer", false)):
		var role_id := str(entry.get("gleazer_role", "recruit"))
		var gleazer_built: Dictionary = GleazerBuilderScript.build(_model_pivot, role_id, scale_factor)
		_model_root = gleazer_built.get("root") as Node3D
		if _model_root != null:
			_human_animator = HumanAvatarAnimator.ensure_on(_model_pivot)
			_human_animator.bind(_model_root)
			_anim_player = HumanCharacterLibraryScript.find_anim_player(_model_root)
			_play_idle()
		else:
			_human_animator = null
			_anim_player = null
		_avatar_animator = null
		return
	if _is_criminal_boss or _is_criminal_henchman:
		var criminal_model := HumanCharacterLibraryScript.spawn(
			_model_pivot,
			Vector3.ZERO,
			0.0,
			scale_factor
		)
		if criminal_model == null:
			return
		_model_root = criminal_model
		var criminal_avatar := CriminalBossLoreScript.build_avatar(_style_seed, entry)
		HumanCharacterLibraryScript.apply_avatar_customization(criminal_model, criminal_avatar)
		if criminal_avatar.glow_strength > 0.05:
			HumanCharacterLibraryScript.apply_accent_glow(
				criminal_model,
				criminal_avatar.glow_color,
				criminal_avatar.glow_strength
			)
		_human_animator = HumanAvatarAnimator.ensure_on(_model_pivot)
		_human_animator.bind(criminal_model)
		_anim_player = null
		return

	var model := HumanCharacterLibraryScript.spawn(
		_model_pivot,
		Vector3.ZERO,
		0.0,
		scale_factor
	)
	if model == null:
		return
	_model_root = model
	var avatar := AvatarData.new()
	if _is_pedestrian:
		avatar = PedestrianStyleScript.build_avatar(_style_seed)
		avatar.body_scale *= scale_factor
	elif entry.has("tint"):
		avatar.body_scale = scale_factor
		avatar.body_color = entry.tint
		avatar.accent_color = entry.tint.darkened(0.25)
	else:
		avatar.body_scale = scale_factor
		avatar.body_color = Color.from_hsv(randf(), randf_range(0.15, 0.35), randf_range(0.45, 0.72))
		avatar.accent_color = Color.from_hsv(randf_range(0.55, 0.75), randf_range(0.3, 0.55), randf_range(0.2, 0.38))
	HumanCharacterLibraryScript.apply_avatar_customization(model, avatar)
	if _is_pedestrian and avatar.glow_strength > 0.05:
		HumanCharacterLibraryScript.apply_accent_glow(model, avatar.glow_color, avatar.glow_strength)
	_human_animator = HumanAvatarAnimator.ensure_on(_model_pivot)
	_human_animator.bind(model)
	_anim_player = null


func _apply_corrosion_visual() -> void:
	if _model_root == null:
		return
	var blend := _corrosion
	if _avatar_animator:
		ZezzlorBuilderScript.apply_corrosion_tint(_model_pivot, blend)
		return
	var tint := CORROSION_COLOR.lerp(Color.WHITE, 0.15)
	HumanCharacterLibraryScript.apply_skin_tone(_model_root, tint, blend * 0.65)
	if _name_label:
		_name_label.modulate = Color(0.82, 1.0, 0.72).lerp(Color(0.55, 0.12, 0.12), 1.0 - get_health_ratio())


func _flash_corrosion_hit() -> void:
	if _model_pivot == null:
		return
	var tween := create_tween()
	tween.tween_property(_model_pivot, "scale", Vector3(1.06, 0.94, 1.06), 0.08)
	tween.tween_property(_model_pivot, "scale", Vector3.ONE, 0.12)


func _die(shooter_id: int) -> void:
	if _dead:
		return
	_dead = true
	if not _is_zezzlor:
		NpcDialogueBarkScript.play_for_npc(self, "death")
	_wander_enabled = false
	velocity = Vector3.ZERO
	if _is_pedestrian:
		var robber := shooter_id if shooter_id >= 0 else _last_melee_attacker_id
		_try_rob_pedestrian(robber)
		_name_label.text = "%s — nedslagen" % _display_name
	else:
		_name_label.text = "%s — frätt bort" % _display_name
	_name_label.modulate = Color(0.35, 0.9, 0.32)
	_broadcast_health()
	if _model_pivot:
		_model_pivot.rotation_degrees.x = -90.0
		_model_pivot.position.y = 0.35
	for child in get_children():
		if child is Area3D and child.has_method("get_prompt"):
			child.queue_free()
	if _is_allmakare:
		return
	_ensure_game_director()
	if _game_director != null and _game_director.has_method("on_npc_murdered"):
		_game_director.on_npc_murdered(shooter_id, global_position, _npc_id)


func _ensure_game_director() -> void:
	if _game_director != null and is_instance_valid(_game_director):
		return
	_game_director = get_tree().get_first_node_in_group("game_director")


func _iter_players() -> Array:
	_ensure_game_director()
	if _game_director == null or not _game_director.get("players") is Dictionary:
		return []
	var result: Array = []
	for player in (_game_director.players as Dictionary).values():
		if is_instance_valid(player):
			result.append(player)
	return result


func _attach_interactable(entry: Dictionary) -> void:
	var area := StoryInteractableScript.new()
	area.interact_id = _npc_id
	area.prompt_text = str(entry.get("prompt", "Prata [E]"))
	area.position = Vector3(0.0, 1.0, 0.0)
	add_child(area)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 2.4, 2.2)
	shape.shape = box
	area.add_child(shape)


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_anim_player(child)
		if found != null:
			return found
	return null


func _update_animation() -> void:
	if _avatar_animator:
		_avatar_animator.set_moving(_moving)
		return
	if _human_animator:
		_human_animator.set_moving(_moving)
		return
	if _anim_player == null:
		return
	if _moving:
		_play_anim(["walk", "Walk", "run", "Run", "move", "Move"])
	else:
		_play_anim(["idle", "Idle", "look", "Look", "stand", "Stand"])


func _play_idle() -> void:
	_play_anim(["idle", "Idle", "look", "Look"])


func _play_anim(preferred: Array) -> void:
	if _anim_player == null:
		return
	for anim_name in preferred:
		if _anim_player.has_animation(anim_name):
			if _anim_player.current_animation != anim_name:
				_anim_player.play(anim_name)
			return
	for existing in _anim_player.get_animation_list():
		var lower := String(existing).to_lower()
		for anim_name in preferred:
			if lower == String(anim_name).to_lower():
				if _anim_player.current_animation != existing:
					_anim_player.play(existing)
				return
	if _anim_player.get_animation_list().size() > 0 and _anim_player.current_animation == "":
		_anim_player.play(_anim_player.get_animation_list()[0])


@rpc("any_peer", "unreliable")
func _sync_state(pos: Vector3, yaw: float, moving: bool) -> void:
	if _is_simulation_authority():
		return
	position = pos
	rotation.y = yaw
	if moving != _moving:
		_moving = moving
		_update_animation()