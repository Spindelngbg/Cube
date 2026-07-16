extends Area3D

const SlimeDamageScript = preload("res://scripts/combat/slime_damage.gd")
const ProjectileTrailFxScript = preload("res://scripts/combat/projectile_trail_fx.gd")

const SPEED := 30.0
const MAX_LIFETIME := 4.0
const TRAIL_INTERVAL := 0.045
const SPEAR_DAMAGE := 11.0

var _velocity := Vector3.ZERO
var _shooter_id := -1
var _from_enemy := false
var _trail_color := Color(0.85, 0.32, 0.28, 0.35)
var _alive := 0.0
var _trail_timer := 0.0
var _mesh: MeshInstance3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func launch_player(origin: Vector3, direction: Vector3, shooter_id: int) -> void:
	_from_enemy = false
	_shooter_id = shooter_id
	_trail_color = Color(0.35, 0.92, 0.42, 0.3)
	_setup_flight(origin, direction)


func launch_enemy(origin: Vector3, direction: Vector3, trail_color: Color) -> void:
	_from_enemy = true
	_shooter_id = -1
	_trail_color = trail_color
	_setup_flight(origin, direction)


func _setup_flight(origin: Vector3, direction: Vector3) -> void:
	global_position = origin
	_velocity = direction.normalized() * SPEED
	_alive = 0.0
	_trail_timer = 0.0
	_mesh = get_node_or_null("Mesh") as MeshInstance3D
	if _velocity.length_squared() > 0.01:
		look_at(origin + _velocity, Vector3.UP)


func _physics_process(delta: float) -> void:
	_alive += delta
	if _alive >= MAX_LIFETIME:
		queue_free()
		return

	global_position += _velocity * delta

	_trail_timer -= delta
	if _trail_timer <= 0.0:
		_trail_timer = TRAIL_INTERVAL
		var parent := get_parent()
		if parent:
			ProjectileTrailFxScript.spawn_weak(
				parent,
				global_position - _velocity.normalized() * 0.12,
				_trail_color,
				rotation.y
			)

	if _mesh:
		_mesh.rotation.z += delta * 14.0


func _on_body_entered(body: Node) -> void:
	_apply_hit(body)


func _on_area_entered(area: Area3D) -> void:
	_apply_hit(area)


func _apply_hit(collider: Node) -> void:
	if collider == self:
		return
	var target := _resolve_damage_target(collider)
	if target == null:
		return
	if not _from_enemy and target is CharacterBody3D and target.get_multiplayer_authority() == _shooter_id:
		return
	if _from_enemy and target.has_method("get_health_snapshot"):
		return

	if target.has_method("take_corrosive_slime"):
		target.take_corrosive_slime(SlimeDamageScript.DAMAGE_PER_HIT * 0.85, _shooter_id)
	elif target.has_method("take_damage"):
		target.take_damage(SPEAR_DAMAGE)

	queue_free()


func _resolve_damage_target(node: Node) -> Node:
	if node == null:
		return null
	if node.has_method("take_corrosive_slime") or node.has_method("take_damage"):
		return node
	if node.get_parent() != null and (
		node.get_parent().has_method("take_corrosive_slime")
		or node.get_parent().has_method("take_damage")
	):
		return node.get_parent()
	return null