class_name ZezzlorHq
extends Node3D

const BLUE_UNIFORM := Color(0.12, 0.34, 0.82)
const SIGN_GLOW := Color(0.95, 0.22, 0.12)
const WALL := Color(0.2, 0.24, 0.32)

var hq_id := ""
var hq_label := "Zezzlor HQ"
var _player_inside := false
var _interact_area: Area3D


func setup(entry: Dictionary) -> void:
	hq_id = str(entry.get("id", "zezzlor_hq"))
	hq_label = str(entry.get("label", "Zezzlor HQ"))
	position = entry.get("pos", Vector3.ZERO)
	rotation.y = float(entry.get("rotation_y", 0.0))
	_build_structure()
	_build_interact_area()
	add_to_group("zezzlor_hq")


func is_player_nearby() -> bool:
	return _player_inside


func get_prompt() -> String:
	return "Zezzlor HQ — begär dossier [E]"


func _build_structure() -> void:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(9.0, 5.2, 7.0)
	body.mesh = mesh
	body.position = Vector3(0.0, 2.6, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = WALL
	mat.metallic = 0.35
	mat.roughness = 0.72
	body.material_override = mat
	add_child(body)

	var stripe := MeshInstance3D.new()
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(9.2, 0.45, 7.2)
	stripe.mesh = stripe_mesh
	stripe.position = Vector3(0.0, 4.9, 0.0)
	var stripe_mat := StandardMaterial3D.new()
	stripe_mat.albedo_color = BLUE_UNIFORM
	stripe_mat.emission_enabled = true
	stripe_mat.emission = BLUE_UNIFORM
	stripe_mat.emission_energy_multiplier = 0.35
	stripe.material_override = stripe_mat
	add_child(stripe)

	var sign := Label3D.new()
	sign.text = "ZEZZLOR\nHQ"
	sign.font_size = 52
	sign.position = Vector3(0.0, 3.8, 3.65)
	sign.modulate = SIGN_GLOW
	sign.outline_size = 8
	sign.outline_modulate = Color(0.05, 0.05, 0.08)
	sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(sign)

	var sub_sign := Label3D.new()
	sub_sign.text = hq_label
	sub_sign.font_size = 22
	sub_sign.position = Vector3(0.0, 2.8, 3.62)
	sub_sign.modulate = Color(0.55, 0.75, 1.0)
	sub_sign.outline_size = 4
	add_child(sub_sign)

	var blocker := StaticBody3D.new()
	blocker.name = "Blocker"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(9.0, 5.2, 7.0)
	shape.shape = box
	shape.position = Vector3(0.0, 2.6, 0.0)
	blocker.add_child(shape)
	add_child(blocker)


func _build_interact_area() -> void:
	_interact_area = Area3D.new()
	_interact_area.name = "InteractArea"
	_interact_area.collision_layer = 0
	_interact_area.collision_mask = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(12.0, 4.0, 10.0)
	shape.shape = box
	shape.position = Vector3(0.0, 2.0, 2.0)
	_interact_area.add_child(shape)
	add_child(_interact_area)
	_interact_area.body_entered.connect(_on_body_entered)
	_interact_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player_character") and body.is_multiplayer_authority():
		_player_inside = true


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player_character") and body.is_multiplayer_authority():
		_player_inside = false