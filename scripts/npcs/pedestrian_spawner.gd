class_name PedestrianSpawner
extends RefCounted

const WORLD_NPC_SCENE := preload("res://scenes/npcs/world_npc.tscn")
const PedestrianCatalogScript = preload("res://scripts/npcs/pedestrian_catalog.gd")
const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")
const SpawnDensityScript = preload("res://scripts/world/spawn_density.gd")


static func populate(
	parent: Node3D,
	spawn_id: String,
	city_origin: Vector3 = Vector3.ZERO,
	owdb_bridge: Node = null
) -> Node3D:
	var root := Node3D.new()
	root.name = "Pedestrians"
	parent.add_child(root)

	var plan := PedestrianCatalogScript.get_spawn_plan(spawn_id)
	for i in range(plan.size()):
		var entry: Dictionary = plan[i]
		var local_pos: Vector3 = entry.get("local_pos", Vector3.ZERO)
		var world_pos := city_origin + local_pos
		world_pos.y = city_origin.y
		if not SpawnDensityScript.should_spawn_entity(world_pos, city_origin, i):
			continue

		var npc := WORLD_NPC_SCENE.instantiate()
		npc.name = "Pedestrian_%d" % i
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.get_multiplayer().multiplayer_peer != null:
			npc.set_multiplayer_authority(MultiplayerEntityAuthorityScript.simulation_peer_id())
		root.add_child(npc)
		npc.setup(entry, world_pos, hash("%s_ped_%d" % [spawn_id, i]))
		npc.add_to_group("pedestrian_npc")
		if owdb_bridge != null and owdb_bridge.has_method("register_runtime_entity"):
			owdb_bridge.register_runtime_entity(npc, "res://scenes/npcs/world_npc.tscn", 1)
	return root