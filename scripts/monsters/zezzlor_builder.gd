class_name ZezzlorBuilder
extends RefCounted

## Flerarmad Zezzlor — mesh-skelett (SpiderAlien) + Sci-Fi GLTF-kropp. Inte människa.

const CORE_MESH := "Enemy_Trilobite"
const UNIFORM_BLUE := Color(0.12, 0.34, 0.82)
const CHITIN_BASE := Color(0.08, 0.18, 0.34)


static func build(parent: Node3D, rank_id: String = "patrol", scale_factor: float = 1.0) -> Dictionary:
	if rank_id == "superman":
		scale_factor *= 1.12
	for child in parent.get_children():
		child.queue_free()

	var rank_color: Color = ZezzlorLore.rank_color(rank_id)
	var avatar := _build_avatar(rank_id, scale_factor)
	SpiderAlienBuilder.build(parent, avatar)

	var root := parent.get_child(0) if parent.get_child_count() > 0 else null
	if root == null:
		root = Node3D.new()
		root.name = "ZezzlorBody"
		parent.add_child(root)

	_apply_uniform_tint(parent, rank_color.lerp(UNIFORM_BLUE, 0.62), 0.58)

	var core := SciFiEssentialsLibrary.spawn(parent, CORE_MESH, Vector3(0.0, 1.08 * scale_factor, 0.02 * scale_factor))
	if core:
		core.scale = Vector3.ONE * 0.5 * scale_factor
		core.rotation_degrees.y = 18.0
		_apply_uniform_tint(core, rank_color.lerp(UNIFORM_BLUE, 0.45), 0.72)

	var baton_socket := _ensure_baton_socket(parent, scale_factor)
	if rank_id == "superman":
		_attach_cape(parent, scale_factor)
	if rank_id == "allmakare":
		_attach_healer_staff(parent, scale_factor)
	return {"root": root, "baton_socket": baton_socket}


static func apply_corrosion_tint(root: Node, strength: float) -> void:
	_apply_uniform_tint(root, Color(0.22, 0.92, 0.28), clampf(strength, 0.0, 1.0) * 0.65)


static func _build_avatar(rank_id: String, scale_factor: float) -> AvatarData:
	var rank_color: Color = ZezzlorLore.rank_color(rank_id)
	if rank_id == "superman":
		rank_color = Color(1.0, 0.84, 0.18)
	var data := AvatarData.new()
	data.mesh_id = "zezzlor"
	data.body_scale = 1.14 * scale_factor
	data.abdomen_scale = 1.36
	data.head_scale = 1.04
	data.leg_length = 0.94
	data.arm_length = 1.12
	data.spider_leg_count = _arm_count_for_rank(rank_id)
	data.eye_count = 6
	data.eye_size = 1.12
	data.eye_spread = 1.08
	data.eye_stalk_length = 0.38
	data.mandible_length = 0.32
	data.fang_length = 0.18
	data.claw_size = 0.52
	data.crest_size = 0.16
	data.glow_strength = 0.55 if rank_id == "superman" else 0.22
	data.spike_amount = 0.16
	data.stance_width = 1.28
	data.body_color = CHITIN_BASE.lerp(rank_color, 0.25)
	data.accent_color = rank_color.lerp(UNIFORM_BLUE, 0.35)
	data.eye_color = rank_color.lightened(0.35)
	data.glow_color = rank_color
	data.chitin_roughness = 0.42
	data.chitin_metallic = 0.38
	return data


static func _attach_healer_staff(parent: Node3D, scale_factor: float) -> void:
	var staff := MeshInstance3D.new()
	staff.name = "HealerStaff"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.04
	mesh.bottom_radius = 0.05
	mesh.height = 1.1
	staff.mesh = mesh
	staff.position = Vector3(0.28 * scale_factor, 1.05 * scale_factor, 0.08 * scale_factor)
	staff.rotation_degrees = Vector3(8.0, 0.0, -18.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.82, 0.28)
	mat.emission_enabled = true
	mat.emission = Color(0.98, 0.9, 0.4)
	mat.emission_energy_multiplier = 0.65
	mat.metallic = 0.55
	staff.material_override = mat
	parent.add_child(staff)

	var orb := MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.1
	orb_mesh.height = 0.2
	orb.mesh = orb_mesh
	orb.position = staff.position + Vector3(0.0, 0.62 * scale_factor, 0.0)
	var orb_mat := StandardMaterial3D.new()
	orb_mat.albedo_color = Color(0.55, 0.92, 1.0)
	orb_mat.emission_enabled = true
	orb_mat.emission = Color(0.45, 0.85, 1.0)
	orb_mat.emission_energy_multiplier = 1.1
	orb.material_override = orb_mat
	parent.add_child(orb)


static func _attach_cape(parent: Node3D, scale_factor: float) -> void:
	var cape := MeshInstance3D.new()
	cape.name = "SuperCape"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(1.05 * scale_factor, 1.45 * scale_factor)
	cape.mesh = mesh
	cape.position = Vector3(0.0, 1.05 * scale_factor, 0.28 * scale_factor)
	cape.rotation_degrees = Vector3(-12.0, 180.0, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.82, 0.1, 0.12)
	mat.emission_enabled = true
	mat.emission = Color(0.45, 0.05, 0.08)
	mat.emission_energy_multiplier = 0.35
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cape.material_override = mat
	parent.add_child(cape)


static func _arm_count_for_rank(rank_id: String) -> int:
	match rank_id:
		"superman":
			return 12
		"recruit":
			return 8
		"patrol":
			return 10
		"officer", "contract":
			return 10
		"sergeant", "inspector":
			return 12
		_:
			return 10


static func _ensure_baton_socket(parent: Node3D, scale_factor: float) -> Node3D:
	var socket := parent.get_node_or_null("BatonSocket") as Node3D
	if socket:
		return socket

	var pedipalp := _find_node_named(parent, "Pedipalp0")
	if pedipalp == null:
		pedipalp = _find_node_named(parent, "Pedipalp1")
	if pedipalp == null:
		pedipalp = parent

	socket = Node3D.new()
	socket.name = "BatonSocket"
	socket.position = Vector3(0.22 * scale_factor, 0.08 * scale_factor, -0.12 * scale_factor)
	pedipalp.add_child(socket)
	return socket


static func _find_node_named(node: Node, node_name: String) -> Node3D:
	if node.name == node_name and node is Node3D:
		return node as Node3D
	for child in node.get_children():
		var found := _find_node_named(child, node_name)
		if found:
			return found
	return null


static func _apply_uniform_tint(node: Node, color: Color, strength: float) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		var src := mesh.get_active_material(0)
		if src is StandardMaterial3D:
			var copy := (src as StandardMaterial3D).duplicate() as StandardMaterial3D
			copy.albedo_color = copy.albedo_color.lerp(color, clampf(strength, 0.0, 1.0))
			copy.metallic = clampf(copy.metallic + 0.12, 0.0, 1.0)
			mesh.material_override = copy
	for child in node.get_children():
		_apply_uniform_tint(child, color, strength)