class_name ItemPickup
extends Area3D

@export var item_id := ""
@export var prompt_text := "Plocka upp [E]"
@export var one_shot := true

var _player_inside := false
var _collected := false


func _ready() -> void:
	add_to_group("item_pickup")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_layer = 0
	collision_mask = 1
	_build_visual()


func is_player_nearby() -> bool:
	return _player_inside and not _collected


func get_prompt() -> String:
	if _collected:
		return ""
	return prompt_text


func try_collect() -> bool:
	if _collected or item_id == "":
		return false
	if not InventoryManager.add_item(item_id):
		return false
	_collected = true
	_on_collected()
	return true


func _on_collected() -> void:
	var item_name := ItemCatalog.get_display_name(item_id)
	QuestManager.story_toast.emit(
		"Upplockat",
		"%s\n+%d max-HP" % [item_name, int(ItemCatalog.get_hp_bonus(item_id))]
	)
	if one_shot:
		visible = false
		monitoring = false
		monitorable = false


func _build_visual() -> void:
	if ItemCatalog.get_item(item_id).is_empty():
		return
	var rarity := ItemCatalog.get_rarity(item_id)
	var color := ItemCatalog.rarity_color(rarity)

	var pedestal := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.18
	mesh.bottom_radius = 0.22
	mesh.height = 0.08
	pedestal.mesh = mesh
	pedestal.position = Vector3(0.0, 0.04, 0.0)
	var ped_mat := StandardMaterial3D.new()
	ped_mat.albedo_color = Color(0.14, 0.15, 0.18)
	pedestal.material_override = ped_mat
	add_child(pedestal)

	var vial := MeshInstance3D.new()
	var vial_mesh := CylinderMesh.new()
	vial_mesh.top_radius = 0.07
	vial_mesh.bottom_radius = 0.09
	vial_mesh.height = 0.28
	vial.mesh = vial_mesh
	vial.position = Vector3(0.0, 0.22, 0.0)
	var vial_mat := StandardMaterial3D.new()
	vial_mat.albedo_color = color
	vial_mat.emission_enabled = true
	vial_mat.emission = color
	vial_mat.emission_energy_multiplier = 0.55 if rarity == "legendary" else 0.3
	vial_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vial_mat.albedo_color.a = 0.88
	vial.material_override = vial_mat
	add_child(vial)

	var label := Label3D.new()
	label.text = ItemCatalog.get_display_name(item_id)
	label.font_size = 22
	label.modulate = color
	label.position = Vector3(0.0, 0.55, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 1.4, 1.2)
	shape.shape = box
	shape.position = Vector3(0.0, 0.6, 0.0)
	add_child(shape)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = false