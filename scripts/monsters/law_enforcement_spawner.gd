class_name LawEnforcementSpawner
extends RefCounted

const LAW_ENFORCER_SCENE := preload("res://scenes/monsters/law_enforcer.tscn")


static func spawn_for_crime(
	game: Node3D,
	crime_pos: Vector3,
	shooter_id: int,
	players: Dictionary
) -> Node3D:
	if not players.has(shooter_id):
		return null

	var target: Node3D = players[shooter_id]
	var root := game.get_node_or_null("LawEnforcement") as Node3D
	if root == null:
		root = Node3D.new()
		root.name = "LawEnforcement"
		game.add_child(root)

	var spawn_index := root.get_child_count()
	for i in range(SlimeDamage.ENFORCER_COUNT):
		var angle := float(i) / float(SlimeDamage.ENFORCER_COUNT) * TAU + 0.4
		var offset := Vector3(cos(angle) * 10.0, 0.0, sin(angle) * 10.0)
		var enforcer := LAW_ENFORCER_SCENE.instantiate()
		enforcer.name = "Enforcer_%d_%d" % [spawn_index, i]
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.get_multiplayer().multiplayer_peer != null:
			enforcer.set_multiplayer_authority(1)
		root.add_child(enforcer)
		enforcer.setup(target, crime_pos + offset)
		if game.has_method("register_law_enforcer"):
			game.register_law_enforcer(enforcer)

	if shooter_id == (Engine.get_main_loop() as SceneTree).get_multiplayer().get_unique_id():
		QuestManager.story_toast.emit(
			"ORDNINGSSTÖRNING",
			"Blåklädda vakter med batonger jagar dig — slem på civila har konsekvenser."
		)

	return root