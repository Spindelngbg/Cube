class_name ZezzlorBackupMission
extends Node3D

const ZezzlorApcScript = preload("res://scripts/monsters/zezzlor_apc.gd")
const ZezzlorBackupDirectionMarkerScript = preload(
	"res://scripts/monsters/zezzlor_backup_direction_marker.gd"
)
const ZezzlorLoreScript = preload("res://scripts/story/zezzlor_lore.gd")
const ZEZZLOR_SCENE := preload("res://scenes/monsters/zezzlor.tscn")
const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")

enum Phase { APC_INCOMING, DEBRIEF, SCANNING, HOSTILE, DONE }

const SCAN_DISTANCE := 28.0
const SCAN_TIME := 4.5

var _game: Node3D
var _caller: Node3D
var _call_pos := Vector3.ZERO
var _trouble_dir := Vector3.FORWARD
var _spawn_id := ""
var _phase := Phase.APC_INCOMING
var _apc: ZezzlorApc
var _squad: Array[Node3D] = []
var _lead_zezzlor: Node3D
var _scan_timer := 0.0
var _scan_point := Vector3.ZERO
var _confirmed_direction := false
var _force_trouble := false
var _awaiting_followup := false
var _direction_marker: Node3D
var _rng := RandomNumberGenerator.new()


func start(
	game: Node3D,
	caller: Node3D,
	call_pos: Vector3,
	trouble_dir: Vector3,
	spawn_id: String
) -> void:
	_game = game
	_caller = caller
	_call_pos = call_pos
	_trouble_dir = trouble_dir.normalized() if trouble_dir.length_squared() > 0.01 else Vector3.FORWARD
	_spawn_id = spawn_id
	_rng.seed = hash(str(call_pos) + str(Time.get_ticks_msec()))
	_spawn_direction_marker()
	_spawn_apc()


func on_player_response(response_id: String) -> void:
	if _phase != Phase.DEBRIEF:
		return
	if _awaiting_followup:
		_handle_followup_response(response_id)
		return
	match response_id:
		"point_direction", "player_fight":
			_confirmed_direction = true
			_open_followup()
		"hybrid_threat":
			_confirmed_direction = true
			_force_trouble = true
			_open_followup()
		"false_alarm", "deny_backup", "rude":
			call_deferred("_go_hostile", response_id)


func _handle_followup_response(response_id: String) -> void:
	_awaiting_followup = false
	if response_id == "backpedal":
		call_deferred("_go_hostile", "backpedal")
		return
	_begin_scan()


func _spawn_direction_marker() -> void:
	_direction_marker = ZezzlorBackupDirectionMarkerScript.new()
	_direction_marker.name = "BackupDirectionMarker"
	add_child(_direction_marker)
	if _direction_marker.has_method("setup"):
		_direction_marker.setup(_call_pos, _trouble_dir)
	QuestManager.story_toast.emit(
		"Riktning markerad",
		"En glödande markör visar åt vilket håll du pekade när du ringde."
	)


func _open_followup() -> void:
	_awaiting_followup = true
	if _lead_zezzlor == null and not _squad.is_empty():
		_lead_zezzlor = _squad[1] if _squad.size() > 1 else _squad[0]
	if _lead_zezzlor == null:
		_begin_scan()
		return
	var line := ZezzlorLoreScript.pick_backup_followup_line(_rng.randi())
	if _lead_zezzlor.has_method("begin_backup_followup"):
		_lead_zezzlor.begin_backup_followup(line)
	elif _game != null and _game.has_method("open_zezzlor_conversation"):
		_game.open_zezzlor_conversation(
			_lead_zezzlor,
			line,
			ZezzlorLoreScript.format_dialogue_title("officer", "Vakt-A", "Znood-backup"),
			"backup_followup"
		)
	call_deferred("_followup_timeout")


func _followup_timeout() -> void:
	await get_tree().create_timer(22.0).timeout
	if _phase == Phase.DEBRIEF and _awaiting_followup:
		_awaiting_followup = false
		_begin_scan()


func _spawn_apc() -> void:
	var spawn_back := -_trouble_dir.normalized() if _trouble_dir.length_squared() > 0.01 else Vector3.BACK
	var apc_pos := _call_pos + spawn_back * 72.0
	apc_pos.y = _call_pos.y

	_apc = ZezzlorApcScript.new()
	_apc.name = "ZezzlorApc"
	_apc.global_position = apc_pos
	add_child(_apc)
	_apc.arrived.connect(_on_apc_arrived)
	_apc.drive_to(_call_pos)

	QuestManager.story_toast.emit(
		"Zezzlor APC",
		"Tungt pansarfordon på väg — håll position och förbered svar."
	)


func _on_apc_arrived() -> void:
	_phase = Phase.DEBRIEF
	_deploy_squad()
	if _apc:
		_apc.queue_free()
		_apc = null
	await get_tree().create_timer(0.6).timeout
	_open_debrief()


func _deploy_squad() -> void:
	var positions := _apc.get_dismount_positions() if _apc else []
	var squad_plan: Array[Dictionary] = [
		{"rank_id": "jailer", "personal_name": "Klot-9", "role": "jailer"},
		{"rank_id": "officer", "personal_name": "Vakt-A", "role": "officer"},
		{"rank_id": "sergeant", "personal_name": "Vakt-B", "role": "sergeant"},
		{"rank_id": "recruit", "personal_name": "Vakt-C", "role": "recruit"},
	]
	var tree := get_tree()
	var sim_peer := 1
	if tree and tree.get_multiplayer().multiplayer_peer != null:
		sim_peer = MultiplayerEntityAuthorityScript.simulation_peer_id()

	for i in range(squad_plan.size()):
		var zezzlor := ZEZZLOR_SCENE.instantiate()
		zezzlor.name = "BackupZezzlor_%d" % i
		if tree and tree.get_multiplayer().multiplayer_peer != null:
			zezzlor.set_multiplayer_authority(sim_peer)
		add_child(zezzlor)
		var pos := positions[i] if i < positions.size() else _call_pos
		var entry: Dictionary = squad_plan[i]
		if zezzlor.has_method("setup_backup"):
			zezzlor.setup_backup(self, {
				"rank_id": entry.get("rank_id", "patrol"),
				"personal_name": entry.get("personal_name", ""),
				"role": entry.get("role", "patrol"),
				"caller": _caller,
				"position": pos,
			})
		_squad.append(zezzlor)
		if _game and _game.has_method("register_zezzlor"):
			_game.register_zezzlor(zezzlor)
		if i == 1:
			_lead_zezzlor = zezzlor


func _open_debrief() -> void:
	if _lead_zezzlor == null and not _squad.is_empty():
		_lead_zezzlor = _squad[0]
	if _lead_zezzlor == null or _game == null:
		return
	var line := ZezzlorLoreScript.pick_backup_arrival_line(_rng.randi())
	if _lead_zezzlor.has_method("begin_backup_dialog"):
		_lead_zezzlor.begin_backup_dialog(line)
	elif _game.has_method("open_zezzlor_conversation"):
		_game.open_zezzlor_conversation(
			_lead_zezzlor,
			line,
			ZezzlorLoreScript.format_dialogue_title("officer", "Vakt-A", "Znood-backup"),
			"backup"
		)
	call_deferred("_auto_scan_fallback")


func _auto_scan_fallback() -> void:
	await get_tree().create_timer(18.0).timeout
	if _phase == Phase.DEBRIEF and not _confirmed_direction:
		_begin_scan()


func _begin_scan() -> void:
	if _phase == Phase.SCANNING or _phase == Phase.HOSTILE:
		return
	_phase = Phase.SCANNING
	_scan_point = _call_pos + _trouble_dir * SCAN_DISTANCE
	_scan_point.y = _call_pos.y
	_scan_timer = SCAN_TIME
	for unit in _squad:
		if unit != null and unit.has_method("order_backup_scan"):
			unit.order_backup_scan(_scan_point)
	QuestManager.story_toast.emit(
		"Zezzlor patrull",
		"Patrullen går åt det håll du angav och letar efter problem..."
	)


func _process(delta: float) -> void:
	if _phase != Phase.SCANNING:
		return
	_scan_timer -= delta
	if _scan_timer > 0.0:
		return
	if _find_trouble_at_scan():
		_resolve_found_trouble()
	else:
		_go_hostile("no_trouble")


func _find_trouble_at_scan() -> bool:
	if _force_trouble:
		return true
	if _game == null:
		return false
	var monsters: Variant = _game.get("_monsters")
	if monsters is Array:
		for monster in monsters:
			if not is_instance_valid(monster):
				continue
			if monster.global_position.distance_to(_scan_point) <= 14.0:
				return true
	var players_dict: Variant = _game.get("players")
	if players_dict is Dictionary:
		for player in (players_dict as Dictionary).values():
			if player == _caller or not is_instance_valid(player):
				continue
			if player.global_position.distance_to(_scan_point) <= 10.0:
				return true
	return false


func _resolve_found_trouble() -> void:
	_phase = Phase.DONE
	QuestManager.story_toast.emit(
		"Zezzlor patrull",
		"Hot bekräftat i zonen. Patrullen tar över — du är fri att lämna platsen."
	)
	call_deferred("_cleanup", 8.0)


func _go_hostile(reason: String) -> void:
	if _phase == Phase.HOSTILE or _phase == Phase.DONE:
		return
	_phase = Phase.HOSTILE
	var line := ZezzlorLoreScript.pick_backup_no_trouble_line(_rng.randi())
	if reason == "false_alarm":
		line = "Falsklarm bekräftat. Du slösade APC-tid — batong och fängelsecell väntar."
	QuestManager.story_toast.emit("Zezzlor — fientlig", line)
	for unit in _squad:
		if unit != null and unit.has_method("order_backup_hostile"):
			unit.order_backup_hostile()
	call_deferred("_cleanup", 45.0)


func _cleanup(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	for unit in _squad:
		if is_instance_valid(unit):
			unit.queue_free()
	_squad.clear()
	if is_instance_valid(_direction_marker):
		_direction_marker.queue_free()
		_direction_marker = null
	queue_free()