class_name LaserMuzzleSmokeFx
extends RefCounted

## Kenney Smoke Particles (CC0) — https://kenney.nl/assets/smoke-particles

const SMOKE_FRAMES := [
	"res://assets/particles/kenney-smoke/PNG/White puff/whitePuff00.png",
	"res://assets/particles/kenney-smoke/PNG/White puff/whitePuff03.png",
	"res://assets/particles/kenney-smoke/PNG/White puff/whitePuff06.png",
	"res://assets/particles/kenney-smoke/PNG/White puff/whitePuff09.png",
	"res://assets/particles/kenney-smoke/PNG/White puff/whitePuff12.png",
]


static func burst(parent: Node, world_pos: Vector3, direction: Vector3) -> void:
	if parent == null:
		return

	var fx := GPUParticles3D.new()
	fx.name = "LaserMuzzleSmoke"
	fx.amount = 14
	fx.lifetime = 0.55
	fx.one_shot = true
	fx.explosiveness = 1.0
	fx.fixed_fps = 0
	fx.emitting = true

	var material := ParticleProcessMaterial.new()
	material.direction = direction.normalized() if direction.length_squared() > 0.01 else Vector3.FORWARD
	material.spread = 22.0
	material.initial_velocity_min = 1.8
	material.initial_velocity_max = 4.6
	material.gravity = Vector3(0.0, -2.4, 0.0)
	material.scale_min = 0.35
	material.scale_max = 0.85
	material.color = Color(0.92, 0.95, 1.0, 0.82)
	fx.process_material = material

	var quad := QuadMesh.new()
	quad.size = Vector2(0.9, 0.9)
	var puff_mat := StandardMaterial3D.new()
	puff_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	puff_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	puff_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.88)
	puff_mat.albedo_texture = load(SMOKE_FRAMES[randi() % SMOKE_FRAMES.size()]) as Texture2D
	quad.material = puff_mat
	fx.draw_pass_1 = quad

	parent.add_child(fx)
	fx.global_position = world_pos
	if direction.length_squared() > 0.01:
		fx.look_at(world_pos + direction.normalized(), Vector3.UP)

	var cleanup := fx.create_tween()
	cleanup.tween_interval(0.75)
	cleanup.tween_callback(fx.queue_free)