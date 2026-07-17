class_name PlaygroundNpcSpawner
extends RefCounted

## Barn och parkväktare vid jätte-lekparken (hus 9) på Koloni 4.

const WORLD_NPC_SCENE := preload("res://scenes/npcs/world_npc.tscn")
const PlaygroundParkBuilderScript = preload("res://scripts/city/playground_park_builder.gd")
const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")
const DcZoneCatalogScript = preload("res://scripts/city/dc_zone_catalog.gd")

const CHILD_COUNT := 8
const GUARD_COUNT := 8

const CHILD_NAMES := [
	"Lilla Mia", "Kalle", "Saga", "Noel", "Ebba", "Leo", "Alva", "Elis",
	"Maja", "Hugo", "Vera", "Isak", "Nora", "Otto", "Ellie", "Melvin",
]

const GUARD_NAMES := [
	"Parkvakt Bo", "Parkvakt Kim", "Parkvakt Rut", "Parkvakt Sam",
	"Parkvakt Liv", "Parkvakt Ted", "Parkvakt Pia", "Parkvakt Dan",
	"Parkvakt Ola", "Parkvakt Maj", "Parkvakt Per", "Parkvakt Ulf",
	"Parkvakt Eva", "Parkvakt Jan", "Parkvakt Siv", "Parkvakt Tim",
	"Parkvakt Moa", "Parkvakt Ken",
]


static func populate(
	parent: Node3D,
	spawn_id: String,
	city_origin: Vector3 = Vector3.ZERO,
	owdb_bridge: Node = null
) -> Node3D:
	var root := Node3D.new()
	root.name = "PlaygroundPeople"
	parent.add_child(root)

	if SpawnPoints.normalize_id(spawn_id) != "satellite_right":
		return root

	var park_center := _park_world_center(city_origin)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s_playground_people" % spawn_id)

	_spawn_children(root, park_center, rng, spawn_id, owdb_bridge)
	_spawn_guards(root, park_center, rng, spawn_id, owdb_bridge)

	return root


static func _park_world_center(city_origin: Vector3) -> Vector3:
	var cell := PlaygroundParkBuilderScript.BUILDING_9_CELL
	var local := Vector3(
		float(cell.x) * DcZoneCatalogScript.BLOCK_M + DcZoneCatalogScript.BLOCK_M * 0.5,
		0.0,
		float(cell.y) * DcZoneCatalogScript.BLOCK_M + DcZoneCatalogScript.BLOCK_M * 0.5
	)
	return city_origin + local


static func _spawn_children(
	root: Node3D,
	park_center: Vector3,
	rng: RandomNumberGenerator,
	spawn_id: String,
	owdb_bridge: Node
) -> void:
	for i in CHILD_COUNT:
		var angle := rng.randf() * TAU
		var radius := rng.randf_range(2.5, 12.0)
		var offset := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		# Håll barn inne i parken, undvik ytterkant.
		offset.x = clampf(offset.x, -14.0, 14.0)
		offset.z = clampf(offset.z, -14.0, 14.0)
		var world_pos := park_center + offset
		world_pos.y = city_origin_y(park_center)

		var entry := {
			"id": "playground_child_%d" % i,
			"name": CHILD_NAMES[i % CHILD_NAMES.size()],
			"scale": rng.randf_range(0.52, 0.68),
			"speed": rng.randf_range(1.6, 2.6),
			"wander": true,
			"wander_radius": rng.randf_range(4.0, 9.0),
			"playground_child": true,
			"tint": Color.from_hsv(rng.randf(), rng.randf_range(0.55, 0.9), rng.randf_range(0.75, 1.0)),
		}
		_spawn_npc(root, entry, world_pos, hash("%s_child_%d" % [spawn_id, i]), owdb_bridge, "child")


static func _spawn_guards(
	root: Node3D,
	park_center: Vector3,
	rng: RandomNumberGenerator,
	spawn_id: String,
	owdb_bridge: Node
) -> void:
	# Ring runt staketet + några inne i parken.
	for i in GUARD_COUNT:
		var world_pos: Vector3
		var wander := true
		var wander_radius := 3.5
		var speed := 1.15

		if i < 12:
			# Perimeter-poster längs staketet.
			var t := float(i) / 12.0 * TAU
			var ring_r := 16.5
			world_pos = park_center + Vector3(cos(t) * ring_r, 0.0, sin(t) * ring_r)
			wander = true
			wander_radius = 2.2
			speed = 0.85
		else:
			# Inre patrull nära gungor/rutschkanor.
			var angle := rng.randf() * TAU
			var radius := rng.randf_range(5.0, 11.0)
			world_pos = park_center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
			wander_radius = 5.5
			speed = 1.25

		world_pos.y = city_origin_y(park_center)
		var facing := atan2(park_center.x - world_pos.x, park_center.z - world_pos.z)

		var entry := {
			"id": "playground_guard_%d" % i,
			"name": GUARD_NAMES[i % GUARD_NAMES.size()],
			"scale": 1.05,
			"speed": speed,
			"wander": wander,
			"wander_radius": wander_radius,
			"rotation_y": facing,
			"playground_guard": true,
			"tint": Color(0.12, 0.28, 0.55),
		}
		_spawn_npc(root, entry, world_pos, hash("%s_guard_%d" % [spawn_id, i]), owdb_bridge, "guard")


static func city_origin_y(pos: Vector3) -> float:
	return pos.y


static func _spawn_npc(
	root: Node3D,
	entry: Dictionary,
	world_pos: Vector3,
	seed: int,
	owdb_bridge: Node,
	kind: String
) -> void:
	var npc := WORLD_NPC_SCENE.instantiate()
	npc.name = "Playground_%s_%s" % [kind, str(entry.get("id", "x"))]
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.get_multiplayer().multiplayer_peer != null:
		npc.set_multiplayer_authority(MultiplayerEntityAuthorityScript.simulation_peer_id())
	root.add_child(npc)
	npc.setup(entry, world_pos, seed)
	if kind == "child":
		npc.add_to_group("playground_child")
	elif kind == "guard":
		npc.add_to_group("playground_guard")
	if owdb_bridge != null and owdb_bridge.has_method("register_runtime_entity"):
		owdb_bridge.register_runtime_entity(npc, "res://scenes/npcs/world_npc.tscn", 1)
