class_name NpcSpawner
extends RefCounted

const WORLD_NPC_SCENE := preload("res://scenes/npcs/world_npc.tscn")
const NpcCatalogScript = preload("res://scripts/npcs/npc_catalog.gd")
const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")


static func populate(
	parent: Node3D,
	spawn_id: String,
	city_origin: Vector3 = Vector3.ZERO,
	owdb_bridge: Node = null
) -> Node3D:
	var root := Node3D.new()
	root.name = "NPCs"
	parent.add_child(root)

	var plan := NpcCatalogScript.get_spawn_plan(spawn_id)
	if plan.is_empty():
		return root

	var spawn_index := 0
	for entry in plan:
		var local_pos: Vector3 = entry.get("local_pos", Vector3.ZERO)
		var world_pos := city_origin + local_pos
		world_pos.y = city_origin.y

		var npc := WORLD_NPC_SCENE.instantiate()
		npc.name = "NPC_%s" % str(entry.get("id", spawn_index))
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.get_multiplayer().multiplayer_peer != null:
			npc.set_multiplayer_authority(MultiplayerEntityAuthorityScript.simulation_peer_id())
		root.add_child(npc)
		npc.setup(entry, world_pos, hash("%s_npc_%d" % [spawn_id, spawn_index]))
		if owdb_bridge != null and owdb_bridge.has_method("register_runtime_entity"):
			owdb_bridge.register_runtime_entity(
				npc,
				"res://scenes/npcs/world_npc.tscn",
				1
			)
		spawn_index += 1

	return root