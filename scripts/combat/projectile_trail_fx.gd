class_name ProjectileTrailFx
extends RefCounted

const TRAIL_LIFETIME := 0.42
const TRAIL_SCALE := Vector3(0.06, 0.06, 0.28)


static func spawn_weak(parent: Node, world_pos: Vector3, color: Color, yaw: float) -> void:
	if parent == null:
		return

	var ghost := MeshInstance3D.new()
	ghost.name = "WeakTrail"
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	ghost.mesh = mesh
	ghost.scale = TRAIL_SCALE

	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(color.r, color.g, color.b, 0.22)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.18
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost.material_override = mat

	parent.add_child(ghost)
	ghost.global_position = world_pos
	ghost.rotation.y = yaw

	var tween := ghost.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "scale", TRAIL_SCALE * 0.35, TRAIL_LIFETIME)
	if mat:
		var fade := mat.albedo_color
		fade.a = 0.0
		tween.tween_property(mat, "albedo_color", fade, TRAIL_LIFETIME)
		tween.tween_property(mat, "emission_energy_multiplier", 0.0, TRAIL_LIFETIME)
	tween.chain().tween_callback(ghost.queue_free)