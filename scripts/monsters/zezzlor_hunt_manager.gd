extends Node

const ZezzlorDossierRuntimeScript = preload("res://scripts/monsters/zezzlor_dossier_runtime.gd")

## Samordnar Zezzlor-jakt: tappa spår, söka, omringa.

enum HuntPhase { PURSUE, SEARCH, CORNER }

const LOS_LOSE_SEC := 2.2
const CORNER_MIN_CHASERS := 2
const CORNER_RANGE := 22.0

var _hunts: Dictionary = {}


func begin_hunt(target: Node3D, crime_pos: Vector3) -> void:
	if target == null:
		return
	var target_id := target.get_instance_id()
	_hunts[target_id] = {
		"target": target,
		"phase": HuntPhase.PURSUE,
		"last_known": crime_pos,
		"los_lost_timer": 0.0,
		"chasers": [],
		"los_map": {},
		"was_searching": false,
		"search_seed": randi(),
	}


func register_chaser(target: Node3D, zezzlor: Node3D) -> void:
	if target == null or zezzlor == null:
		return
	var hunt := _get_hunt(target)
	if hunt.is_empty():
		begin_hunt(target, target.global_position)
		hunt = _get_hunt(target)
	var chasers: Array = hunt.get("chasers", [])
	if zezzlor not in chasers:
		chasers.append(zezzlor)
	hunt["chasers"] = chasers


func unregister_chaser(zezzlor: Node3D) -> void:
	for target_id in _hunts.keys():
		var hunt: Dictionary = _hunts[target_id]
		var chasers: Array = hunt.get("chasers", [])
		chasers.erase(zezzlor)
		hunt["chasers"] = chasers
		if chasers.is_empty():
			_hunts.erase(target_id)


func report_sighting(target: Node3D, pos: Vector3, zezzlor: Node3D) -> void:
	var hunt := _get_hunt(target)
	if hunt.is_empty():
		return
	if hunt.get("was_searching", false):
		hunt["was_searching"] = false
	hunt["last_known"] = pos
	hunt["los_lost_timer"] = 0.0
	hunt["phase"] = HuntPhase.PURSUE
	register_chaser(target, zezzlor)


func chaser_tick(
	target: Node3D,
	zezzlor: Node3D,
	delta: float,
	has_los: bool,
	spawn_id: String
) -> HuntPhase:
	register_chaser(target, zezzlor)
	var hunt := _get_hunt(target)
	if hunt.is_empty():
		return HuntPhase.PURSUE

	var los_map: Dictionary = hunt.get("los_map", {})
	los_map[zezzlor.get_instance_id()] = has_los
	hunt["los_map"] = los_map

	var los_count := 0
	for value in los_map.values():
		if bool(value):
			los_count += 1

	if has_los and is_instance_valid(target):
		var was_search := int(hunt.get("phase", HuntPhase.PURSUE)) == HuntPhase.SEARCH
		hunt["last_known"] = target.global_position
		hunt["los_lost_timer"] = 0.0
		if was_search:
			ZezzlorDossierRuntimeScript.record_target_found(
				target.get_multiplayer_authority(),
				target.global_position,
				spawn_id
			)
			hunt["was_searching"] = false
	elif los_count == 0:
		hunt["los_lost_timer"] = float(hunt.get("los_lost_timer", 0.0)) + delta
		if hunt["los_lost_timer"] >= LOS_LOSE_SEC:
			if int(hunt.get("phase", HuntPhase.PURSUE)) != HuntPhase.SEARCH:
				hunt["phase"] = HuntPhase.SEARCH
				hunt["was_searching"] = true
				if is_instance_valid(target):
					ZezzlorDossierRuntimeScript.record_target_lost(
						target.get_multiplayer_authority(),
						hunt.get("last_known", target.global_position),
						spawn_id
					)
	else:
		hunt["los_lost_timer"] = maxf(0.0, float(hunt.get("los_lost_timer", 0.0)) - delta * 0.5)

	if los_count > 0:
		var close := 0
		for chaser in hunt.get("chasers", []):
			if not is_instance_valid(chaser) or not is_instance_valid(target):
				continue
			if (chaser as Node3D).global_position.distance_to(target.global_position) <= CORNER_RANGE:
				close += 1
		if close >= CORNER_MIN_CHASERS and los_count >= CORNER_MIN_CHASERS:
			hunt["phase"] = HuntPhase.CORNER
		else:
			hunt["phase"] = HuntPhase.PURSUE

	return int(hunt.get("phase", HuntPhase.PURSUE))


func get_phase(target: Node3D) -> HuntPhase:
	var hunt := _get_hunt(target)
	if hunt.is_empty():
		return HuntPhase.PURSUE
	return int(hunt.get("phase", HuntPhase.PURSUE))


func get_last_known(target: Node3D) -> Vector3:
	var hunt := _get_hunt(target)
	if hunt.is_empty():
		return Vector3.ZERO
	return hunt.get("last_known", Vector3.ZERO)


func was_searching(target: Node3D) -> bool:
	var hunt := _get_hunt(target)
	return not hunt.is_empty() and bool(hunt.get("was_searching", false))


func clear_searching_flag(target: Node3D) -> void:
	var hunt := _get_hunt(target)
	if not hunt.is_empty():
		hunt["was_searching"] = false


func get_search_waypoint(target: Node3D, zezzlor: Node3D) -> Vector3:
	var hunt := _get_hunt(target)
	if hunt.is_empty() or zezzlor == null:
		return Vector3.ZERO
	var center: Vector3 = hunt.get("last_known", Vector3.ZERO)
	var chasers: Array = hunt.get("chasers", [])
	var idx := chasers.find(zezzlor)
	if idx < 0:
		idx = zezzlor.get_instance_id() % 6
	var count := maxi(chasers.size(), 4)
	var angle := (TAU / float(count)) * float(idx)
	var radius := 10.0 + float(idx % 3) * 4.5
	return center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)


func get_corner_offset(target: Node3D, zezzlor: Node3D) -> Vector3:
	if target == null or zezzlor == null:
		return Vector3.ZERO
	var hunt := _get_hunt(target)
	var chasers: Array = hunt.get("chasers", []) if not hunt.is_empty() else []
	var idx := chasers.find(zezzlor)
	if idx < 0:
		idx = 0
	var count := maxi(chasers.size(), 2)
	var angle := (TAU / float(count)) * float(idx) + PI * 0.25
	var radius := 7.5
	var center := target.global_position
	return center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)


func end_hunt(target: Node3D) -> void:
	if target == null:
		return
	_hunts.erase(target.get_instance_id())


func _get_hunt(target: Node3D) -> Dictionary:
	if target == null or not is_instance_valid(target):
		return {}
	var target_id := target.get_instance_id()
	if not _hunts.has(target_id):
		return {}
	var hunt: Dictionary = _hunts[target_id]
	if not is_instance_valid(hunt.get("target")):
		_hunts.erase(target_id)
		return {}
	return hunt