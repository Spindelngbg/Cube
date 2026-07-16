class_name BoxingPunch
extends RefCounted

const PUNCH_DAMAGE := 16.0
const PUNCH_RANGE := 2.35
const PUNCH_COOLDOWN := 0.38
const HIT_DELAY_SEC := 0.14


static func resolve_target(
	space: PhysicsDirectSpaceState3D,
	origin: Vector3,
	direction: Vector3,
	exclude: RID
) -> Node:
	if space == null:
		return null
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		origin + direction.normalized() * PUNCH_RANGE
	)
	query.collision_mask = 15
	query.exclude = [exclude]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return null
	return _damage_target_from_collider(hit.collider as Object)


static func apply_hit(target: Node, attacker_id: int) -> void:
	if target == null:
		return
	if target.has_method("take_melee_hit"):
		target.take_melee_hit(PUNCH_DAMAGE, attacker_id)
	elif target.has_method("take_damage"):
		target.take_damage(PUNCH_DAMAGE)


static func _damage_target_from_collider(collider: Object) -> Node:
	if collider == null:
		return null
	var node := collider as Node
	if node == null:
		return null
	if node.has_method("take_melee_hit") or node.has_method("take_damage"):
		return node
	if node.get_parent() and (
		node.get_parent().has_method("take_melee_hit")
		or node.get_parent().has_method("take_damage")
	):
		return node.get_parent()
	return null


