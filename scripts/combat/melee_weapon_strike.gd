class_name MeleeWeaponStrike
extends RefCounted

const HIT_DELAY_SEC := 0.16


static func resolve_target(
	space: PhysicsDirectSpaceState3D,
	origin: Vector3,
	direction: Vector3,
	range: float,
	exclude: RID
) -> Node:
	if space == null:
		return null
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		origin + direction.normalized() * range
	)
	query.collision_mask = 15
	query.exclude = [exclude]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return null
	return BoxingPunch._damage_target_from_collider(hit.collider as Object)


static func apply_hit(target: Node, damage: float, attacker_id: int) -> void:
	if target == null:
		return
	if target.has_method("take_melee_hit"):
		target.take_melee_hit(damage, attacker_id)
	elif target.has_method("take_damage"):
		target.take_damage(damage)


static func get_damage(weapon_id: String) -> float:
	return WeaponCatalog.get_damage(weapon_id) * BuffManager.get_weapon_damage_multiplier()


static func get_range(weapon_id: String) -> float:
	return WeaponCatalog.get_melee_range(weapon_id)


static func get_cooldown(weapon_id: String) -> float:
	return WeaponCatalog.get_melee_cooldown(weapon_id)


static func get_hit_delay(weapon_id: String) -> float:
	var style := WeaponCatalog.get_display_style(weapon_id)
	if style.begins_with("axe"):
		return 0.2
	return HIT_DELAY_SEC