class_name SuperZezzlorSpawner
extends RefCounted

const SUPER_ZEZZLOR_SCENE := preload("res://scenes/monsters/super_zezzlor.tscn")
const DcZoneCatalogScript = preload("res://scripts/city/dc_zone_catalog.gd")

const BRUCE_NAMES := [
	"Bruce",
	"Lee-Z",
	"Zezz-Kick",
	"Kapten Blix",
	"Laser-Lee",
	"Hop-Mästaren",
]


static func populate(
	game: Node3D,
	spawn_id: String,
	spawn_center: Vector3,
	owdb_bridge: Node = null
) -> Node3D:
	var root := Node3D.new()
	root.name = "SuperZezzlorPatrol"
	game.add_child(root)

	var placements := _get_placements(spawn_id, spawn_center)
	if placements.is_empty():
		return root

	var tree := Engine.get_main_loop() as SceneTree
	var index := 0
	for entry in placements:
		var hero := SUPER_ZEZZLOR_SCENE.instantiate()
		hero.name = "SuperZezzlor_%d" % index
		if tree != null and tree.get_multiplayer().multiplayer_peer != null:
			hero.set_multiplayer_authority(1)
		root.add_child(hero)
		var personal_name: String = BRUCE_NAMES[index % BRUCE_NAMES.size()]
		hero.setup(
			entry.get("pos", spawn_center),
			entry.get("center", spawn_center),
			float(entry.get("radius", 48.0)),
			personal_name,
			hash("%s_super_%d" % [spawn_id, index])
		)
		if owdb_bridge != null and owdb_bridge.has_method("register_runtime_entity"):
			owdb_bridge.register_runtime_entity(
				hero,
				"res://scenes/monsters/super_zezzlor.tscn",
				1
			)
		if game.has_method("register_zezzlor"):
			game.register_zezzlor(hero)
		index += 1

	return root


static func _get_placements(spawn_id: String, spawn_center: Vector3) -> Array:
	var id := SpawnPoints.normalize_id(spawn_id)
	if id != "satellite_right":
		return []

	var block := float(DcZoneCatalogScript.BLOCK_M)
	return [
		{
			"pos": spawn_center + Vector3(12.0, 0.0, -8.0),
			"center": spawn_center,
			"radius": 36.0,
		},
		{
			"pos": spawn_center + Vector3(34.0, 0.0, 22.0),
			"center": spawn_center + Vector3(28.0, 0.0, 18.0),
			"radius": 52.0,
		},
		{
			"pos": spawn_center + Vector3(-block * 2.2, 0.0, block * 1.6),
			"center": spawn_center + Vector3(-block * 2.0, 0.0, block * 1.5),
			"radius": 58.0,
		},
		{
			"pos": spawn_center + Vector3(-block * 4.2, 0.0, block * 1.2),
			"center": spawn_center + Vector3(-block * 4.5, 0.0, block * 1.5),
			"radius": 62.0,
		},
		{
			"pos": spawn_center + Vector3(-block * 3.0, 0.0, block * 0.2),
			"center": spawn_center + Vector3(-block * 3.0, 0.0, block * 0.25),
			"radius": 50.0,
		},
		{
			"pos": spawn_center + Vector3(-block * 1.8, 0.0, -block * 1.1),
			"center": spawn_center + Vector3(-block * 2.0, 0.0, -block * 1.25),
			"radius": 54.0,
		},
	]