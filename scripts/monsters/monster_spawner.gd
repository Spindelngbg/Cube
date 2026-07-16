class_name MonsterSpawner
extends RefCounted

const WORLD_MONSTER_SCENE := preload("res://scenes/monsters/world_monster.tscn")
const HUB_SPAWN_RADIUS_FRAC := 0.08

const SPAWN_OFFSETS := [
	Vector3(-0.35, 0.0, -0.35),
	Vector3(0.3, 0.0, -0.25),
	Vector3(-0.2, 0.0, 0.35),
	Vector3(0.35, 0.0, 0.3),
	Vector3(-0.1, 0.0, -0.45),
	Vector3(0.45, 0.0, 0.1),
	Vector3(0.0, 0.0, 0.4),
	Vector3(-0.4, 0.0, 0.05),
]


static func populate(
	parent: Node3D,
	spawn_id: String,
	size_m: float,
	owdb_bridge: Node = null,
	spawn_center: Vector3 = Vector3.ZERO
) -> Node3D:
	var root := Node3D.new()
	root.name = "Monsters"
	parent.add_child(root)

	var plan := MonsterCatalog.get_spawn_plan(spawn_id)
	if plan.is_empty():
		return root

	var hub_radius := size_m * HUB_SPAWN_RADIUS_FRAC
	var center := spawn_center if spawn_center != Vector3.ZERO else Vector3(size_m * 0.5, 0.0, size_m * 0.5)
	var spawn_index := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(spawn_id)

	for entry in plan:
		var count: int = int(entry.get("count", 1))
		for _i in count:
			var offset: Vector3 = SPAWN_OFFSETS[spawn_index % SPAWN_OFFSETS.size()]
			var jitter := Vector3(
				rng.randf_range(-hub_radius * 0.15, hub_radius * 0.15),
				0.0,
				rng.randf_range(-hub_radius * 0.15, hub_radius * 0.15)
			)
			var pos := center + Vector3(offset.x * hub_radius, 0.0, offset.z * hub_radius) + jitter
			pos.x = clampf(pos.x, 80.0, size_m - 80.0)
			pos.z = clampf(pos.z, 80.0, size_m - 80.0)

			var monster := WORLD_MONSTER_SCENE.instantiate()
			monster.name = "Monster_%d" % spawn_index
			var tree := Engine.get_main_loop() as SceneTree
			if tree != null and tree.get_multiplayer().multiplayer_peer != null:
				monster.set_multiplayer_authority(1)
			root.add_child(monster)
			monster.setup(entry, pos, center, hub_radius * 0.9, hash("%s_%d" % [spawn_id, spawn_index]))
			if owdb_bridge != null and owdb_bridge.has_method("register_runtime_entity"):
				owdb_bridge.register_runtime_entity(
					monster,
					"res://scenes/monsters/world_monster.tscn",
					1
				)
			spawn_index += 1

	return root