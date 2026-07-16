extends Area3D

const SlimeDamageScript = preload("res://scripts/combat/slime_damage.gd")
const CorrosiveSplatScene = preload("res://scripts/combat/corrosive_splat.gd")
const ProjectileTrailFxScript = preload("res://scripts/combat/projectile_trail_fx.gd")

const SPEED := 30.0
const MAX_LIFETIME := 5.2
const TRAIL_INTERVAL := 0.024

var _velocity := Vector3.ZERO
var _shooter_id := -1
var _alive := 0.0
var _trail_timer := 0.0
var _mesh: MeshInstance3D
var _shape: Shape3D
var _hit_ids: Dictionary = {}


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_mesh = $Mesh
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision:
		_shape = collision.shape


func launch(origin: Vector3, direction: Vector3, shooter_id: int) -> void:
	global_position = origin
	_velocity = direction.normalized() * SPEED
	_shooter_id = shooter_id
	_alive = 0.0
	_trail_timer = TRAIL_INTERVAL
	_hit_ids.clear()
	look_at(origin + _velocity, Vector3.UP)
	_spawn_trail()


func _physics_process(delta: float) -> void:
	_alive += delta
	if _alive >= MAX_LIFETIME:
		_splat(global_position)
		return

	var motion: Vector3 = _velocity * delta
	var from_pos := global_position
	var to_pos := from_pos + motion
	if _sweep_hit(from_pos, to_pos):
		return

	global_position = to_pos

	_trail_timer -= delta
	if _trail_timer <= 0.0:
		_trail_timer = TRAIL_INTERVAL
		_spawn_trail()

	if _mesh:
		var wobble := 1.0 + sin(_alive * 22.0) * 0.07
		var stretch := 1.55 + sin(_alive * 16.0) * 0.18
		_mesh.scale = Vector3(0.78 * wobble, 0.78 * wobble, stretch * wobble)
		if _mesh.material_override is StandardMaterial3D:
			var mat := _mesh.material_override as StandardMaterial3D
			mat.emission_energy_multiplier = 0.55 + sin(_alive * 24.0) * 0.25


func _spawn_trail() -> void:
	var parent := get_parent()
	if parent == null or _velocity.length_squared() <= 0.01:
		return
	var back := _velocity.normalized()
	ProjectileTrailFxScript.spawn_slime(
		parent,
		global_position - back * randf_range(0.12, 0.22),
		back
	)


func _sweep_hit(from_pos: Vector3, to_pos: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	if space == null:
		return false

	var motion := to_pos - from_pos
	if motion.length_squared() < 0.0001:
		return false

	if _shape != null:
		var params := PhysicsShapeQueryParameters3D.new()
		params.shape = _shape
		params.transform = Transform3D(Basis.IDENTITY, from_pos)
		params.motion = motion
		params.collision_mask = collision_mask
		params.collide_with_areas = true
		params.collide_with_bodies = true
		params.exclude = [get_rid()]
		var hits := space.cast_motion(params)
		if hits.size() >= 2 and hits[0] < 1.0:
			var hit_pos := from_pos + motion * hits[0]
			params.transform = Transform3D(Basis.IDENTITY, hit_pos)
			for hit in space.intersect_shape(params, 8):
				if _try_hit_collider(hit.get("collider")):
					_splat(hit_pos)
					return true

	var ray := PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	ray.collision_mask = collision_mask
	ray.collide_with_areas = true
	ray.collide_with_bodies = true
	ray.exclude = [get_rid()]
	var ray_hit := space.intersect_ray(ray)
	if not ray_hit.is_empty() and _try_hit_collider(ray_hit.get("collider")):
		_splat(ray_hit.get("position", to_pos))
		return true

	return false


func _on_body_entered(body: Node) -> void:
	if _try_hit_collider(body):
		_splat(global_position)


func _on_area_entered(area: Area3D) -> void:
	if area == self:
		return
	if _try_hit_collider(area):
		_splat(global_position)


func _try_hit_collider(collider: Variant) -> bool:
	if collider == null or not (collider is Node):
		return false
	var node := collider as Node
	if node == self:
		return false

	var target := _resolve_damage_target(node)
	if target == null:
		return false

	var target_id := target.get_instance_id()
	if _hit_ids.has(target_id):
		return false

	if target is CharacterBody3D and target.get_multiplayer_authority() == _shooter_id:
		return false

	_hit_ids[target_id] = true
	_apply_corrosive_hit(target)
	return true


func _resolve_damage_target(node: Node) -> Node:
	if node.has_method("take_corrosive_slime") or node.has_method("take_damage"):
		return node
	if node.get_parent() and (
		node.get_parent().has_method("take_corrosive_slime")
		or node.get_parent().has_method("take_damage")
	):
		return node.get_parent()
	return null


func _apply_corrosive_hit(target: Node) -> void:
	var damage := SlimeDamageScript.DAMAGE_PER_HIT
	if target.has_method("take_corrosive_slime"):
		target.take_corrosive_slime(damage, _shooter_id)
	elif target.has_method("take_damage"):
		target.take_damage(damage)


func _splat(pos: Vector3) -> void:
	_spawn_corrosive_splat(pos)
	queue_free()


func _spawn_corrosive_splat(pos: Vector3) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var splat := CorrosiveSplatScene.new()
	splat.position = Vector3(pos.x, pos.y - 0.05, pos.z)
	scene.add_child(splat)