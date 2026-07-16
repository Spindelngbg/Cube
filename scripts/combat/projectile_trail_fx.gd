class_name ProjectileTrailFx
extends RefCounted

const TRAIL_LIFETIME := 0.42
const TRAIL_SCALE := Vector3(0.06, 0.06, 0.28)
const SLIME_TRAIL_LIFETIME := 0.62
const SLIME_GREEN := Color(0.12, 0.88, 0.18, 0.72)
const SLIME_GLOW := Color(0.28, 1.0, 0.34, 1.0)


static func spawn_slime(parent: Node, world_pos: Vector3, direction: Vector3) -> void:
	if parent == null:
		return

	var back := direction.normalized() if direction.length_squared() > 0.01 else Vector3.FORWARD
	_spawn_slime_streak(parent, world_pos, back)
	_spawn_slime_droplet(parent, world_pos, back)


static func _make_slime_material(alpha: float, emission_strength: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(SLIME_GREEN.r, SLIME_GREEN.g, SLIME_GREEN.b, alpha)
	mat.emission_enabled = true
	mat.emission = SLIME_GLOW
	mat.emission_energy_multiplier = emission_strength
	mat.roughness = 0.06
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


static func _spawn_slime_streak(parent: Node, world_pos: Vector3, back: Vector3) -> void:
	var ghost := MeshInstance3D.new()
	ghost.name = "SlimeTrailStreak"
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	ghost.mesh = mesh
	ghost.scale = Vector3(
		randf_range(0.08, 0.12),
		randf_range(0.08, 0.12),
		randf_range(0.34, 0.52)
	)

	var mat := _make_slime_material(randf_range(0.55, 0.78), randf_range(0.72, 1.05))
	ghost.material_override = mat

	parent.add_child(ghost)
	ghost.global_position = world_pos
	ghost.look_at(world_pos + back, Vector3.UP)

	var end_scale := ghost.scale * Vector3(0.35, 0.35, 0.25)
	var drift := world_pos + Vector3(0.0, -0.08, 0.0) - back * 0.06

	var tween := ghost.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "scale", end_scale, SLIME_TRAIL_LIFETIME)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "global_position", drift, SLIME_TRAIL_LIFETIME)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var fade := mat.albedo_color
	fade.a = 0.0
	tween.tween_property(mat, "albedo_color", fade, SLIME_TRAIL_LIFETIME)
	tween.tween_property(mat, "emission_energy_multiplier", 0.0, SLIME_TRAIL_LIFETIME)
	tween.chain().tween_callback(ghost.queue_free)


static func _spawn_slime_droplet(parent: Node, world_pos: Vector3, back: Vector3) -> void:
	var ghost := MeshInstance3D.new()
	ghost.name = "SlimeTrailDroplet"
	var mesh := SphereMesh.new()
	mesh.radius = 0.11
	mesh.height = 0.22
	ghost.mesh = mesh

	var spread := Vector3(
		randf_range(-0.04, 0.04),
		randf_range(-0.03, 0.03),
		randf_range(-0.04, 0.04)
	)
	ghost.scale = Vector3(
		randf_range(0.55, 0.95),
		randf_range(0.45, 0.8),
		randf_range(1.0, 1.55)
	)

	var mat := _make_slime_material(randf_range(0.48, 0.68), randf_range(0.55, 0.9))
	ghost.material_override = mat

	parent.add_child(ghost)
	ghost.global_position = world_pos + spread
	ghost.look_at(world_pos + spread + back, Vector3.UP)

	var end_scale := ghost.scale * Vector3(0.2, 0.12, 0.3)
	var drip := world_pos + spread + Vector3(0.0, -0.16, 0.0) - back * 0.05

	var tween := ghost.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "scale", end_scale, SLIME_TRAIL_LIFETIME)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "global_position", drip, SLIME_TRAIL_LIFETIME)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var fade := mat.albedo_color
	fade.a = 0.0
	tween.tween_property(mat, "albedo_color", fade, SLIME_TRAIL_LIFETIME)
	tween.tween_property(mat, "emission_energy_multiplier", 0.0, SLIME_TRAIL_LIFETIME)
	tween.chain().tween_callback(ghost.queue_free)


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