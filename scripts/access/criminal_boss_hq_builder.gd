class_name CriminalBossHqBuilder
extends RefCounted

const CriminalBossHqScript = preload("res://scripts/access/criminal_boss_hq.gd")
const CriminalBossCatalogScript = preload("res://scripts/story/criminal_boss_catalog.gd")


static func place_all(parent: Node3D, spawn_id: String, city_origin: Vector3 = Vector3.ZERO) -> Node3D:
	var root := Node3D.new()
	root.name = "CriminalBossHqSites"
	parent.add_child(root)

	var plan := CriminalBossCatalogScript.get_hq_placements(spawn_id)
	if plan.is_empty():
		return root

	for entry in plan:
		var hq: CriminalBossHq = CriminalBossHqScript.new()
		hq.name = str(entry.get("hq_id", "CriminalBossHq"))
		var local_pos: Vector3 = entry.get("local_pos", Vector3.ZERO)
		var world_entry: Dictionary = entry.duplicate(true)
		world_entry["local_pos"] = city_origin + local_pos
		world_entry["local_pos"] = Vector3(world_entry["local_pos"].x, city_origin.y, world_entry["local_pos"].z)
		hq.setup(world_entry)
		root.add_child(hq)

	return root