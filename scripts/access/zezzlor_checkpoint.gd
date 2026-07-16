class_name ZezzlorCheckpoint
extends ZnoodAccessDoor

const ZezzlorLoreScript = preload("res://scripts/story/zezzlor_lore.gd")

const BLUE_UNIFORM := Color(0.12, 0.34, 0.82)
const SIGN_GLOW := Color(0.28, 0.58, 0.98)
const BARRIER_CONCRETE := Color(0.42, 0.44, 0.48)


func setup_checkpoint(block_size: Vector3) -> void:
	var road_size := Vector3(
		maxf(block_size.x, 16.0),
		maxf(block_size.y, 4.5),
		maxf(block_size.z, 1.1)
	)
	prompt_locked = "Stämpla Znood vid Zezzlor-checkpoint [E]"
	prompt_open = "Zezzlor-checkpoint öppen"
	setup(road_size)
	_reinforce_road_blockade(road_size)
	_build_zezzlor_signage(road_size)
	if not door_opened.is_connected(_on_checkpoint_opened):
		door_opened.connect(_on_checkpoint_opened)
	_update_status_label()


func _on_checkpoint_opened(_door_id: String) -> void:
	var barricade := get_node_or_null("RoadBarricade")
	if barricade:
		barricade.visible = false


func _update_status_label() -> void:
	if _status_label == null:
		return
	if _locked:
		_status_label.text = "ZEZZLOR\nZNood krävs"
		_status_label.modulate = Color(0.45, 0.72, 1.0)
	else:
		_status_label.text = "ZEZZLOR\nGodkänd"
		_status_label.modulate = Color(0.45, 0.95, 0.42)


func _reinforce_road_blockade(block_size: Vector3) -> void:
	var blocker := get_node_or_null("DoorBlocker") as StaticBody3D
	if blocker == null:
		return

	for child in blocker.get_children():
		child.queue_free()

	var main_shape := CollisionShape3D.new()
	var main_box := BoxShape3D.new()
	main_box.size = Vector3(block_size.x, block_size.y - 0.1, maxf(block_size.z, 1.4))
	main_shape.shape = main_box
	main_shape.position = Vector3(0.0, block_size.y * 0.5, 0.0)
	blocker.add_child(main_shape)

	var wing_span := block_size.x * 0.5 + 1.25

	var barricade_root := Node3D.new()
	barricade_root.name = "RoadBarricade"
	add_child(barricade_root)

	var barricade_mat := StandardMaterial3D.new()
	barricade_mat.albedo_color = BARRIER_CONCRETE
	barricade_mat.metallic = 0.18
	barricade_mat.roughness = 0.82

	var wall := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(block_size.x - 0.3, block_size.y - 0.2, maxf(block_size.z, 1.0))
	wall.mesh = wall_mesh
	wall.position = Vector3(0.0, block_size.y * 0.5, 0.0)
	wall.material_override = barricade_mat
	barricade_root.add_child(wall)

	var stripe_mat := StandardMaterial3D.new()
	stripe_mat.albedo_color = BLUE_UNIFORM
	stripe_mat.emission_enabled = true
	stripe_mat.emission = SIGN_GLOW
	stripe_mat.emission_energy_multiplier = 0.22

	for side in [-1.0, 1.0]:
		var jersey := MeshInstance3D.new()
		var jersey_mesh := BoxMesh.new()
		jersey_mesh.size = Vector3(2.2, 1.1, 1.8)
		jersey.mesh = jersey_mesh
		jersey.position = Vector3(side * wing_span, 0.55, 0.0)
		jersey.material_override = barricade_mat
		barricade_root.add_child(jersey)

		var stripe := MeshInstance3D.new()
		var stripe_mesh := BoxMesh.new()
		stripe_mesh.size = Vector3(2.0, 0.18, 1.6)
		stripe.mesh = stripe_mesh
		stripe.position = Vector3(side * wing_span, 0.95, 0.02)
		stripe.material_override = stripe_mat
		barricade_root.add_child(stripe)

	if _reader_area != null:
		_reader_area.position = Vector3(0.0, 1.35, maxf(block_size.z, 1.0) * 0.5 + 0.22)


func _build_zezzlor_signage(block_size: Vector3) -> void:
	var sign_root := Node3D.new()
	sign_root.name = "ZezzlorSignage"
	sign_root.position = Vector3(0.0, block_size.y + 0.15, 0.0)
	add_child(sign_root)

	var post := MeshInstance3D.new()
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.22, 3.4, 0.22)
	post.mesh = post_mesh
	post.position = Vector3(0.0, 1.7, 0.0)
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = BLUE_UNIFORM
	post_mat.metallic = 0.42
	post_mat.emission_enabled = true
	post_mat.emission = SIGN_GLOW
	post_mat.emission_energy_multiplier = 0.18
	post.material_override = post_mat
	sign_root.add_child(post)

	var banner_width := clampf(block_size.x * 0.22, 2.8, 4.2)
	var banner := MeshInstance3D.new()
	var banner_mesh := BoxMesh.new()
	banner_mesh.size = Vector3(banner_width, 1.1, 0.1)
	banner.mesh = banner_mesh
	banner.position = Vector3(0.0, 3.1, 0.0)
	var banner_mat := StandardMaterial3D.new()
	banner_mat.albedo_color = Color(0.08, 0.12, 0.2)
	banner_mat.metallic = 0.55
	banner_mat.emission_enabled = true
	banner_mat.emission = SIGN_GLOW
	banner_mat.emission_energy_multiplier = 0.32
	banner.material_override = banner_mat
	sign_root.add_child(banner)

	var title := Label3D.new()
	title.name = "ZezzlorTitle"
	title.text = ZezzlorLoreScript.FACTION_NAME.to_upper()
	title.font_size = 64
	title.modulate = Color(0.55, 0.82, 1.0)
	title.outline_modulate = Color(0.04, 0.08, 0.14, 0.95)
	title.position = Vector3(0.0, 3.1, 0.1)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_root.add_child(title)

	var subtitle := Label3D.new()
	subtitle.name = "ZezzlorSubtitle"
	subtitle.text = "Kontrollpunkt — stämpla Znood"
	subtitle.font_size = 24
	subtitle.modulate = Color(0.72, 0.88, 1.0)
	subtitle.position = Vector3(0.0, 2.45, 0.1)
	subtitle.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_root.add_child(subtitle)