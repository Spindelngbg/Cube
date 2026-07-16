class_name AllmakareSpawner
extends RefCounted

const WORLD_NPC_SCENE := preload("res://scenes/npcs/world_npc.tscn")
const AllmakareCatalogScript = preload("res://scripts/npcs/allmakare_catalog.gd")
const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")


static func populate(
	parent: Node3D,
	spawn_id: String,
	city_origin: Vector3 = Vector3.ZERO,
	owdb_bridge: Node = null
) -> Node3D:
	var root := Node3D.new()
	root.name = "Allmakare"
	parent.add_child(root)

	var plan := AllmakareCatalogScript.get_spawn_plan(spawn_id)
	for i in range(plan.size()):
		var entry: Dictionary = plan[i]
		entry["id"] = "allmakare_%s_%d" % [spawn_id, i]
		var local_pos: Vector3 = entry.get("local_pos", Vector3.ZERO)
		var world_pos := city_origin + local_pos
		world_pos.y = city_origin.y

		var npc := WORLD_NPC_SCENE.instantiate()
		npc.name = "Allmakare_%d" % i
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.get_multiplayer().multiplayer_peer != null:
			npc.set_multiplayer_authority(MultiplayerEntityAuthorityScript.simulation_peer_id())
		root.add_child(npc)
		npc.setup(entry, world_pos, hash("%s_allmakare_%d" % [spawn_id, i]))
		npc.add_to_group("allmakare_npc")
		if owdb_bridge != null and owdb_bridge.has_method("register_runtime_entity"):
			owdb_bridge.register_runtime_entity(npc, "res://scenes/npcs/world_npc.tscn", 1)
	return root