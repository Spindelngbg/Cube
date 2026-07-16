class_name ZezzlorPatrolSpawner
extends RefCounted

const ZEZZLOR_SCENE := preload("res://scenes/monsters/zezzlor.tscn")
const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")

const PATROL_NAMES := [
	"Zorbl",
	"Klex",
	"Vaktis",
	"Blå-Väkt",
	"Ordna",
	"Patron",
]


static func populate(parent: Node3D, spawn_id: String, owdb_bridge: Node = null) -> Node3D:
	var id := SpawnPoints.normalize_id(spawn_id)
	if id == "":
		return null

	var root := Node3D.new()
	root.name = "ZezzlorCivilPatrol"
	parent.add_child(root)

	var plan := _get_spawn_plan(id)
	var tree := Engine.get_main_loop() as SceneTree
	var sim_peer := 1
	if tree != null and tree.get_multiplayer().multiplayer_peer != null:
		sim_peer = MultiplayerEntityAuthorityScript.simulation_peer_id()

	for i in range(plan.size()):
		var entry: Dictionary = plan[i]
		var zezzlor := ZEZZLOR_SCENE.instantiate()
		zezzlor.name = "ZezzlorPatrol_%s_%d" % [id, i]
		if tree != null and tree.get_multiplayer().multiplayer_peer != null:
			zezzlor.set_multiplayer_authority(sim_peer)
		root.add_child(zezzlor)
		var rank_id: String = str(entry.get("rank_id", "patrol"))
		var personal_name: String = PATROL_NAMES[i % PATROL_NAMES.size()]
		if zezzlor.has_method("setup_patrol"):
			zezzlor.setup_patrol({
				"spawn_id": id,
				"rank_id": rank_id,
				"personal_name": personal_name,
				"position": entry.get("position", Vector3.ZERO),
				"roam_center": entry.get("roam_center", entry.get("position", Vector3.ZERO)),
				"roam_half": entry.get("roam_half", Vector3(32.0, 0.0, 32.0)),
				"seed": hash("%s_zezzlor_patrol_%d" % [id, i]),
			})

		if owdb_bridge != null and owdb_bridge.has_method("register_runtime_entity"):
			owdb_bridge.register_runtime_entity(
				zezzlor,
				"res://scenes/monsters/zezzlor.tscn",
				1
			)

		if parent.has_method("register_zezzlor"):
			parent.register_zezzlor(zezzlor)

	return root


static func _get_spawn_plan(spawn_id: String) -> Array:
	var play_spawn := SpawnPoints.get_play_spawn_position(spawn_id)
	var hub := SpawnPoints.get_position(spawn_id)

	if spawn_id == "satellite_right":
		return [
			{
				"rank_id": "patrol",
				"position": play_spawn + Vector3(10.0, 0.0, 4.0),
				"roam_center": play_spawn,
				"roam_half": Vector3(55.0, 0.0, 48.0),
			},
			{
				"rank_id": "officer",
				"position": play_spawn + Vector3(-16.0, 0.0, 12.0),
				"roam_center": play_spawn + Vector3(-8.0, 0.0, 6.0),
				"roam_half": Vector3(62.0, 0.0, 50.0),
			},
			{
				"rank_id": "recruit",
				"position": play_spawn + Vector3(22.0, 0.0, -14.0),
				"roam_center": play_spawn + Vector3(14.0, 0.0, -10.0),
				"roam_half": Vector3(48.0, 0.0, 42.0),
			},
		]

	return [
		{
			"rank_id": "patrol",
			"position": hub + Vector3(12.0, 0.0, 10.0),
			"roam_center": hub,
			"roam_half": Vector3(36.0, 0.0, 34.0),
		},
		{
			"rank_id": "officer",
			"position": hub + Vector3(-14.0, 0.0, -6.0),
			"roam_center": hub,
			"roam_half": Vector3(40.0, 0.0, 36.0),
		},
	]