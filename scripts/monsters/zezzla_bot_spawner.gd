class_name ZezzlaBotSpawner
extends RefCounted

const ZezzlaBotScript = preload("res://scripts/monsters/zezzla_bot.gd")
const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")

const HUB_ROAM_HALF := 48.0
const DC_ROAM_HALF_X := 200.0
const DC_ROAM_HALF_Z := 180.0


static func populate(parent: Node3D, spawn_id: String, owdb_bridge: Node = null) -> Node3D:
	var id := SpawnPoints.normalize_id(spawn_id)
	if id == "":
		return null

	var root := Node3D.new()
	root.name = "ZezzlaBots"
	parent.add_child(root)

	var plan := _get_spawn_plan(id)
	var tree := Engine.get_main_loop() as SceneTree
	var sim_peer := 1
	if tree != null and tree.get_multiplayer().multiplayer_peer != null:
		sim_peer = MultiplayerEntityAuthorityScript.simulation_peer_id()

	for i in range(plan.size()):
		var entry: Dictionary = plan[i]
		var bot: ZezzlaBot = ZezzlaBotScript.new()
		bot.name = "ZezzlaBot_%s_%d" % [id, i]
		if tree != null and tree.get_multiplayer().multiplayer_peer != null:
			bot.set_multiplayer_authority(sim_peer)
		root.add_child(bot)
		var roam_center: Vector3 = entry.get("roam_center", Vector3.ZERO)
		var roam_half: Vector3 = entry.get("roam_half", Vector3(HUB_ROAM_HALF, 0.0, HUB_ROAM_HALF))
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%s_zezzla_%d" % [id, i])
		bot.setup(
			{
				"position": _random_point_in_roam(roam_center, roam_half, rng),
				"roam_center": roam_center,
				"roam_half": roam_half,
				"seed": hash("%s_zezzla_bot_%d" % [id, i]),
				"npc_id": "zezzla_bot_%s_%d" % [id, i],
			}
		)

		if owdb_bridge != null and owdb_bridge.has_method("register_runtime_entity"):
			owdb_bridge.register_runtime_entity(
				bot,
				"res://scripts/monsters/zezzla_bot.gd",
				1
			)

	return root


static func _get_spawn_plan(spawn_id: String) -> Array:
	var cube_origin := SpawnPoints.get_position(spawn_id)
	var play_spawn := SpawnPoints.get_play_spawn_position(spawn_id)

	if spawn_id == "satellite_right":
		var plaza := play_spawn
		return [
			_make_entry(plaza, Vector3(DC_ROAM_HALF_X, 0.0, DC_ROAM_HALF_Z)),
			_make_entry(plaza + Vector3(-60.0, 0.0, 40.0), Vector3(130.0, 0.0, 110.0)),
			_make_entry(plaza + Vector3(80.0, 0.0, -30.0), Vector3(120.0, 0.0, 100.0)),
		]

	var hub := cube_origin
	var half := Vector3(HUB_ROAM_HALF, 0.0, HUB_ROAM_HALF)
	return [
		_make_entry(hub, half * 0.7),
	]


static func _make_entry(center: Vector3, half: Vector3) -> Dictionary:
	return {
		"roam_center": center,
		"roam_half": half,
	}


static func _random_point_in_roam(center: Vector3, half: Vector3, rng: RandomNumberGenerator) -> Vector3:
	return center + Vector3(
		rng.randf_range(-half.x, half.x),
		0.0,
		rng.randf_range(-half.z, half.z)
	)