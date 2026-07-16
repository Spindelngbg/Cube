class_name HelpRobotSpawner
extends RefCounted

const HelpRobotScript = preload("res://scripts/npcs/help_robot.gd")
const HelpRobotCatalogScript = preload("res://scripts/npcs/help_robot_catalog.gd")
const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")

const HUB_ROAM_HALF := 42.0
const DC_ROAM_HALF := 95.0


static func populate(parent: Node3D, spawn_id: String, owdb_bridge: Node = null) -> Node3D:
	var id := SpawnPoints.normalize_id(spawn_id)
	if id == "":
		return null

	var root := Node3D.new()
	root.name = "HelpRobots"
	parent.add_child(root)

	var plan := _get_spawn_plan(id)
	var tree := Engine.get_main_loop() as SceneTree
	var sim_peer := 1
	if tree != null and tree.get_multiplayer().multiplayer_peer != null:
		sim_peer = MultiplayerEntityAuthorityScript.simulation_peer_id()

	for i in range(plan.size()):
		var entry: Dictionary = plan[i]
		var bot: HelpRobot = HelpRobotScript.new()
		bot.name = "HelpRobot_%s_%d" % [id, i]
		if tree != null and tree.get_multiplayer().multiplayer_peer != null:
			bot.set_multiplayer_authority(sim_peer)
		root.add_child(bot)
		bot.setup(
			{
				"spawn_id": id,
				"label": HelpRobotCatalogScript.get_robot_label(id),
				"position": entry.get("position", Vector3.ZERO),
				"roam_center": entry.get("roam_center", entry.get("position", Vector3.ZERO)),
				"roam_half": entry.get("roam_half", Vector3(HUB_ROAM_HALF, 0.0, HUB_ROAM_HALF)),
				"seed": hash("%s_help_%d" % [id, i]),
			}
		)

		if owdb_bridge != null and owdb_bridge.has_method("register_runtime_entity"):
			owdb_bridge.register_runtime_entity(
				bot,
				"res://scripts/npcs/help_robot.gd",
				1
			)

	return root


static func _get_spawn_plan(spawn_id: String) -> Array:
	var cube_origin := SpawnPoints.get_position(spawn_id)
	var play_spawn := SpawnPoints.get_play_spawn_position(spawn_id)

	if spawn_id == "satellite_right":
		var plaza := play_spawn
		var half := Vector3(DC_ROAM_HALF, 0.0, DC_ROAM_HALF)
		return [
			{
				"position": plaza + Vector3(6.0, 0.0, 8.0),
				"roam_center": plaza,
				"roam_half": half * 0.45,
			},
			{
				"position": plaza + Vector3(-12.0, 0.0, -6.0),
				"roam_center": plaza,
				"roam_half": half * 0.55,
			},
			{
				"position": plaza + Vector3(18.0, 0.0, -10.0),
				"roam_center": plaza + Vector3(10.0, 0.0, -8.0),
				"roam_half": Vector3(70.0, 0.0, 60.0),
			},
		]

	var hub := cube_origin
	var half_hub := Vector3(HUB_ROAM_HALF, 0.0, HUB_ROAM_HALF)
	return [
		{
			"position": hub + Vector3(8.0, 0.0, 6.0),
			"roam_center": hub,
			"roam_half": half_hub * 0.65,
		},
		{
			"position": hub + Vector3(-10.0, 0.0, -8.0),
			"roam_center": hub,
			"roam_half": half_hub * 0.55,
		},
	]