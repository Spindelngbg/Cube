class_name ZezzlorCheckpoint
extends ZnoodAccessDoor

const ZezzlorLoreScript = preload("res://scripts/story/zezzlor_lore.gd")

const BLUE_UNIFORM := Color(0.12, 0.34, 0.82)
const SIGN_GLOW := Color(0.28, 0.58, 0.98)


func setup_checkpoint(block_size: Vector3) -> void:
	prompt_locked = "Stämpla Znood vid Zezzlor-checkpoint [E]"
	prompt_open = "Zezzlor-checkpoint öppen"
	setup(block_size)
	_build_zezzlor_signage(block_size)
	_update_status_label()


func _update_status_label() -> void:
	if _status_label == null:
		return
	if _locked:
		_status_label.text = "ZEZZLOR\nZNood krävs"
		_status_label.modulate = Color(0.45, 0.72, 1.0)
	else:
		_status_label.text = "ZEZZLOR\nGodkänd"
		_status_label.modulate = Color(0.45, 0.95, 0.42)


func _build_zezzlor_signage(block_size: Vector3) -> void:
	var sign_root := Node3D.new()
	sign_root.name = "ZezzlorSignage"
	sign_root.position = Vector3(0.0, block_size.y + 0.15, 0.0)
	add_child(sign_root)

	var post := MeshInstance3D.new()
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.16, 2.8, 0.16)
	post.mesh = post_mesh
	post.position = Vector3(0.0, 1.4, 0.0)
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = BLUE_UNIFORM
	post_mat.metallic = 0.42
	post_mat.emission_enabled = true
	post_mat.emission = SIGN_GLOW
	post_mat.emission_energy_multiplier = 0.18
	post.material_override = post_mat
	sign_root.add_child(post)

	var banner := MeshInstance3D.new()
	var banner_mesh := BoxMesh.new()
	banner_mesh.size = Vector3(2.4, 0.9, 0.08)
	banner.mesh = banner_mesh
	banner.position = Vector3(0.0, 2.55, 0.0)
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
	title.font_size = 56
	title.modulate = Color(0.55, 0.82, 1.0)
	title.outline_modulate = Color(0.04, 0.08, 0.14, 0.95)
	title.position = Vector3(0.0, 2.55, 0.08)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_root.add_child(title)

	var subtitle := Label3D.new()
	subtitle.name = "ZezzlorSubtitle"
	subtitle.text = "Kontrollpunkt — stämpla Znood"
	subtitle.font_size = 22
	subtitle.modulate = Color(0.72, 0.88, 1.0)
	subtitle.position = Vector3(0.0, 2.05, 0.08)
	subtitle.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_root.add_child(subtitle)