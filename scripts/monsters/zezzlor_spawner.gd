class_name ZezzlorSpawner
extends RefCounted

const ZEZZLOR_SCENE := preload("res://scenes/monsters/zezzlor.tscn")
const ZezzlorLoreScript = preload("res://scripts/story/zezzlor_lore.gd")
const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")


static func spawn_for_crime(
	game: Node3D,
	crime_pos: Vector3,
	shooter_id: int,
	players: Dictionary
) -> Node3D:
	if not players.has(shooter_id):
		return null

	var target: Node3D = players[shooter_id]
	var root := game.get_node_or_null("ZezzlorPatrol") as Node3D
	if root == null:
		root = Node3D.new()
		root.name = "ZezzlorPatrol"
		game.add_child(root)

	var spawn_index := root.get_child_count()
	var deployed_ranks: Array[String] = []
	for i in range(SlimeDamage.ZEZZLOR_COUNT):
		var rank_id: String = ZezzlorLoreScript.CHASE_RANK_ORDER[
			i % ZezzlorLoreScript.CHASE_RANK_ORDER.size()
		]
		deployed_ranks.append(rank_id)
		var angle := float(i) / float(SlimeDamage.ZEZZLOR_COUNT) * TAU + 0.4
		var offset := Vector3(cos(angle) * 10.0, 0.0, sin(angle) * 10.0)
		var zezzlor := ZEZZLOR_SCENE.instantiate()
		zezzlor.name = "Zezzlor_%s_%d" % [rank_id, spawn_index]
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.get_multiplayer().multiplayer_peer != null:
			zezzlor.set_multiplayer_authority(MultiplayerEntityAuthorityScript.simulation_peer_id())
		root.add_child(zezzlor)
		zezzlor.setup(target, crime_pos + offset, rank_id)
		if game.has_method("register_zezzlor"):
			game.register_zezzlor(zezzlor)

	if shooter_id == (Engine.get_main_loop() as SceneTree).get_multiplayer().get_unique_id():
		QuestManager.story_toast.emit(
			"Zezzlor aktiverade",
			ZezzlorLoreScript.chase_alert_body(deployed_ranks)
		)

	return root
