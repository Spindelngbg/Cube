class_name RetroTextureLibrary
extends RefCounted

const BASE_PATH := "res://assets/textures/retro-fantasy/PNG/"


static func texture_path(name: String) -> String:
	var file_name := name if name.ends_with(".png") else "%s.png" % name
	return BASE_PATH + file_name


static func load_texture(name: String) -> Texture2D:
	var path := texture_path(name)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	push_warning("Retro texture not found: %s" % path)
	return null


static func make_material(texture_name: String, uv_scale: Vector2 = Vector2(4, 4)) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var tex := load_texture(texture_name)
	if tex:
		mat.albedo_texture = tex
		mat.uv1_scale = Vector3(uv_scale.x, uv_scale.y, 1.0)
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.roughness = 0.92
	return mat


static func apply_to_mesh(mesh: MeshInstance3D, texture_name: String, uv_scale: Vector2 = Vector2(4, 4)) -> void:
	if mesh == null:
		return
	mesh.material_override = make_material(texture_name, uv_scale)


static func make_nest_material(
	texture_name: String,
	uv_scale: Vector2 = Vector2(4, 4),
	tint: Color = Color(0.35, 0.32, 0.3),
	roughness: float = 0.88
) -> StandardMaterial3D:
	var mat := make_material(texture_name, uv_scale)
	mat.albedo_color = tint
	mat.roughness = roughness
	mat.metallic = 0.04
	return mat