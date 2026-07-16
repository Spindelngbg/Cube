extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const PLAYER_SCENE := preload("res://scenes/player.tscn")

var _world_root: Node3D
var _failures: Array[String] = []


func _ready() -> void:
	get_tree().get_multiplayer().multiplayer_peer = OfflineMultiplayerPeer.new()
	call_deferred("_run_all")


func _run_all() -> void:
	for colony_id in SpawnPoints.IDS:
		await _test_colony(colony_id)
	_report_and_quit()


func _test_colony(colony_id: String) -> void:
	_clear_world()
	CityKitLibrary.warmup_dc_city_models()
	SpaceKitLibrary.warmup_common_models()
	_world_root = SatelliteCubeBuilder.build(self, colony_id)
	for _i in range(32):
		await get_tree().physics_frame

	var spawn_xz := SpawnPoints.get_shifted_play_spawn(colony_id)
	var space := get_world_3d().direct_space_state
	var floor_y := PlayerScript.find_highest_floor_y(space, spawn_xz, SpawnPoints.SPAWN_FOOT_Y)
	if floor_y < SpawnPoints.SPAWN_PAD_SURFACE_Y - 0.05:
		_failures.append(
			"%s: saknar golv vid spawn (floor_y=%.3f)" % [colony_id, floor_y]
		)
		return

	var grounded := Vector3(spawn_xz.x, PlayerScript._feet_y_on_floor(floor_y), spawn_xz.z)
	if PlayerScript.probe_feet_blocked(space, grounded):
		_failures.append(
			"%s: kapsel blockerad på spawn-golv (floor_y=%.3f feet_y=%.3f blockers=%s)"
			% [colony_id, floor_y, grounded.y, _describe_blockers(space, grounded)]
		)
		return

	var player: CharacterBody3D = PLAYER_SCENE.instantiate()
	player.name = "SpawnTestPlayer"
	player.position = grounded
	player.set_multiplayer_authority(1)
	add_child(player)
	for _i in range(24):
		await get_tree().physics_frame
	if player.has_method("ensure_safe_ground"):
		player.ensure_safe_ground()
	for _i in range(8):
		await get_tree().physics_frame

	if player.global_position.y < SpawnPoints.SPAWN_PAD_SURFACE_Y - 0.2:
		_failures.append(
			"%s: spelare under mark efter snap (y=%.3f)"
			% [colony_id, player.global_position.y]
		)
		return
	if PlayerScript.probe_feet_blocked(space, player.global_position, [player.get_rid()]):
		_failures.append("%s: spelare fast i kollision efter snap" % colony_id)
		return

	if not _can_step_from(space, player.global_position, [player.get_rid()]):
		_failures.append("%s: kan inte röra sig från spawn" % colony_id)


func _can_step_from(space: PhysicsDirectSpaceState3D, feet_pos: Vector3, exclude: Array[RID]) -> bool:
	var dirs := [
		Vector3(1.0, 0.0, 0.0),
		Vector3(-1.0, 0.0, 0.0),
		Vector3(0.0, 0.0, 1.0),
		Vector3(0.0, 0.0, -1.0),
	]
	for dir: Vector3 in dirs:
		var step_pos: Vector3 = feet_pos + dir * 2.5
		if not PlayerScript.probe_feet_blocked(space, step_pos, exclude):
			return true
	return false


func _describe_blockers(space: PhysicsDirectSpaceState3D, feet_pos: Vector3) -> String:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.9
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), feet_pos + Vector3(0.0, 1.0, 0.0))
	params.collision_mask = 1
	params.margin = 0.02
	var hits := space.intersect_shape(params, 8)
	var names: PackedStringArray = []
	for hit in hits:
		var collider: Object = hit.get("collider", null)
		if collider is Node:
			names.append((collider as Node).get_path())
		else:
			names.append(str(collider))
	return ", ".join(names)


func _clear_world() -> void:
	if _world_root != null and is_instance_valid(_world_root):
		_world_root.queue_free()
		_world_root = null
	for child in get_children():
		if child.name == "SpawnTestPlayer":
			child.queue_free()
	await get_tree().process_frame


func _report_and_quit() -> void:
	if _failures.is_empty():
		print("SPAWN_VALIDATION_OK all=%d" % SpawnPoints.IDS.size())
		get_tree().quit(0)
	else:
		for line in _failures:
			push_error(line)
		print("SPAWN_VALIDATION_FAIL count=%d" % _failures.size())
		get_tree().quit(1)