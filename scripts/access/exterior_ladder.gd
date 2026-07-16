class_name ExteriorLadder
extends Area3D

const CLIMB_SPEED := 4.5

@export var ladder_height := 18.0
@export var prompt_text := "Klättra stege [W] · Ner [S]"

var _players_inside: Array[Node3D] = []


func _ready() -> void:
	add_to_group("exterior_ladder")
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func has_player(player: Node3D) -> bool:
	return player != null and player in _players_inside


func is_player_nearby() -> bool:
	return not _players_inside.is_empty()


func get_prompt() -> String:
	return prompt_text


func get_bottom_y() -> float:
	return global_position.y


func get_top_y() -> float:
	return global_position.y + ladder_height


func get_rail_global_xz() -> Vector2:
	return Vector2(global_position.x, global_position.z)


func apply_climb(player: CharacterBody3D, delta: float) -> bool:
	if player == null or not has_player(player):
		return false

	var rail := get_rail_global_xz()
	player.global_position.x = lerpf(player.global_position.x, rail.x, minf(1.0, delta * 10.0))
	player.global_position.z = lerpf(player.global_position.z, rail.y, minf(1.0, delta * 10.0))

	var vertical := 0.0
	if Input.is_action_pressed("move_forward"):
		vertical = CLIMB_SPEED
	elif Input.is_action_pressed("move_back"):
		vertical = -CLIMB_SPEED

	player.velocity = Vector3.ZERO
	player.velocity.y = vertical
	player.move_and_slide()
	player.global_position.y = clampf(
		player.global_position.y,
		get_bottom_y() + 0.35,
		get_top_y() - 0.55
	)
	return true


static func build_visual(parent: Node3D, height: float, width: float = 1.05) -> ExteriorLadder:
	var ladder := ExteriorLadder.new()
	ladder.name = "ExteriorLadder"
	ladder.ladder_height = height
	ladder.position = Vector3.ZERO
	parent.add_child(ladder)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, height, 0.85)
	collision.shape = shape
	collision.position = Vector3(0.0, height * 0.5, 0.0)
	ladder.add_child(collision)

	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.72, 0.76, 0.82)
	frame_mat.metallic = 0.78
	frame_mat.roughness = 0.34
	frame_mat.emission_enabled = true
	frame_mat.emission = Color(0.42, 0.48, 0.58)
	frame_mat.emission_energy_multiplier = 0.18

	var rung_mat := frame_mat.duplicate()
	rung_mat.albedo_color = Color(0.58, 0.62, 0.68)

	var left_rail := MeshInstance3D.new()
	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(0.1, height, 0.1)
	left_rail.mesh = rail_mesh
	left_rail.position = Vector3(-width * 0.42, height * 0.5, 0.0)
	left_rail.material_override = frame_mat
	ladder.add_child(left_rail)

	var right_rail := MeshInstance3D.new()
	right_rail.mesh = rail_mesh.duplicate()
	right_rail.position = Vector3(width * 0.42, height * 0.5, 0.0)
	right_rail.material_override = frame_mat
	ladder.add_child(right_rail)

	var rung_count := maxi(8, int(height / 2.2))
	for i in range(rung_count):
		var rung := MeshInstance3D.new()
		var rung_box := BoxMesh.new()
		rung_box.size = Vector3(width * 0.82, 0.08, 0.16)
		rung.mesh = rung_box
		rung.position = Vector3(0.0, 0.9 + float(i) * (height - 1.2) / float(rung_count - 1), 0.0)
		rung.material_override = rung_mat
		ladder.add_child(rung)

	return ladder


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player_character") and body not in _players_inside:
		_players_inside.append(body)


func _on_body_exited(body: Node3D) -> void:
	_players_inside.erase(body)