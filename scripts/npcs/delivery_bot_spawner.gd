class_name DeliveryBotSpawner
extends RefCounted

const DeliveryBotScript = preload("res://scripts/npcs/delivery_bot.gd")
const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")

const ARRIVAL_ROAM_HALF := 92.0
const DC_ROAM_HALF_X := 210.0
const DC_ROAM_HALF_Z := 190.0


static func populate(parent: Node3D, spawn_id: String, owdb_bridge: Node = null) -> Node3D:
	var id := SpawnPoints.normalize_id(spawn_id)
	if id == "":
		return null

	var root := Node3D.new()
	root.name = "DeliveryBots"
	parent.add_child(root)

	var plan := _get_spawn_plan(id)
	var theme := ColonyCityTheme.for_spawn(id)
	var accent: Color = theme.get("beacon_color", Color(0.35, 0.72, 0.95))
	var tree := Engine.get_main_loop() as SceneTree
	var sim_peer := 1
	if tree != null and tree.get_multiplayer().multiplayer_peer != null:
		sim_peer = MultiplayerEntityAuthorityScript.simulation_peer_id()

	for i in range(plan.size()):
		var entry: Dictionary = plan[i]
		var bot: DeliveryBot = DeliveryBotScript.new()
		bot.name = "DeliveryBot_%s_%d" % [id, i]
		if tree != null and tree.get_multiplayer().multiplayer_peer != null:
			bot.set_multiplayer_authority(sim_peer)
		root.add_child(bot)

		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%s_delivery_%d" % [id, i])
		var roam_center: Vector3 = entry.get("roam_center", Vector3.ZERO)
		var roam_half: Vector3 = entry.get("roam_half", Vector3(80.0, 0.0, 80.0))
		var spawn_pos := _random_point_in_roam(roam_center, roam_half, rng)

		bot.setup(
			{
				"position": spawn_pos,
				"roam_center": roam_center,
				"roam_half": roam_half,
				"accent": accent,
				"seed": hash("%s_bot_%d" % [id, i]),
				"label": str(entry.get("label", "PAKET")),
			}
		)

		if owdb_bridge != null and owdb_bridge.has_method("register_runtime_entity"):
			owdb_bridge.register_runtime_entity(
				bot,
				"res://scripts/npcs/delivery_bot.gd",
				1
			)

	return root


static func _get_spawn_plan(spawn_id: String) -> Array:
	var cube_origin := SpawnPoints.get_position(spawn_id)
	var colony_num := SpawnPoints.get_colony_number(spawn_id)
	if spawn_id == "satellite_right":
		var city_origin := cube_origin
		var plaza := city_origin + Vector3(20.0, 0.0, 20.0)
		return [
			_make_entry(plaza, Vector3(DC_ROAM_HALF_X, 0.0, DC_ROAM_HALF_Z), "K%d-001" % colony_num),
			_make_entry(plaza, Vector3(DC_ROAM_HALF_X * 0.75, 0.0, DC_ROAM_HALF_Z * 0.65), "K%d-002" % colony_num),
			_make_entry(plaza + Vector3(-80.0, 0.0, 0.0), Vector3(120.0, 0.0, 120.0), "MALL"),
			_make_entry(plaza + Vector3(60.0, 0.0, -40.0), Vector3(100.0, 0.0, 90.0), "K%d-EXP" % colony_num),
			_make_entry(plaza + Vector3(-40.0, 0.0, 80.0), Vector3(110.0, 0.0, 100.0), "K%d-N" % colony_num),
			_make_entry(plaza + Vector3(100.0, 0.0, 30.0), Vector3(95.0, 0.0, 85.0), "K%d-E" % colony_num),
		]

	var hub_center := cube_origin
	var half := Vector3(ARRIVAL_ROAM_HALF, 0.0, ARRIVAL_ROAM_HALF)
	return [
		_make_entry(hub_center, half, "K%d-001" % colony_num),
		_make_entry(hub_center, half * 0.85, "K%d-002" % colony_num),
		_make_entry(hub_center + Vector3(35.0, 0.0, -28.0), half * 0.55, "K%d-003" % colony_num),
		_make_entry(hub_center + Vector3(-42.0, 0.0, 36.0), half * 0.5, "K%d-004" % colony_num),
	]


static func _make_entry(center: Vector3, half: Vector3, label: String) -> Dictionary:
	return {
		"roam_center": center,
		"roam_half": half,
		"label": label,
	}


static func _random_point_in_roam(center: Vector3, half: Vector3, rng: RandomNumberGenerator) -> Vector3:
	return center + Vector3(
		rng.randf_range(-half.x, half.x),
		0.0,
		rng.randf_range(-half.z, half.z)
	)