extends Area3D

const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")
const ProjectileTrailFxScript = preload("res://scripts/combat/projectile_trail_fx.gd")

const MAX_LIFETIME := 4.8
const TRAIL_INTERVAL := 0.028

var _velocity := Vector3.ZERO
var _shooter_id := -1
var _alive := 0.0
var _trail_timer := 0.0
var _damage := 20.0
var _combat_kind := "energy"
var _hit_ids: Dictionary = {}
var _mesh: MeshInstance3D


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_mesh = get_node_or_null("Mesh") as MeshInstance3D


func launch(origin: Vector3, direction: Vector3, shooter_id: int, weapon_id: String) -> void:
	var stats := WeaponCatalog.get_stats(weapon_id)
	_damage = float(stats.get("damage", 20.0)) * BuffManager.get_weapon_damage_multiplier()
	_combat_kind = str(stats.get("combat_kind", "energy"))
	var speed := float(stats.get("projectile_speed", 40.0))
	var color: Color = stats.get("color", Color.CYAN)

	global_position = origin
	_velocity = direction.normalized() * speed
	_shooter_id = shooter_id
	_alive = 0.0
	_trail_timer = TRAIL_INTERVAL
	_hit_ids.clear()
	if _velocity.length_squared() > 0.01:
		look_at(origin + _velocity, Vector3.UP)
	_apply_color(color)


func _physics_process(delta: float) -> void:
	_alive += delta
	if _alive >= MAX_LIFETIME:
		queue_free()
		return

	global_position += _velocity * delta

	_trail_timer -= delta
	if _trail_timer <= 0.0 and _combat_kind in ["slime", "melt"]:
		_trail_timer = TRAIL_INTERVAL
		_spawn_trail()

	if _mesh:
		var pulse := 1.0 + sin(_alive * 36.0) * 0.1
		_mesh.scale = Vector3(0.16 * pulse, 0.16 * pulse, 1.2 * pulse)


func _spawn_trail() -> void:
	var parent := get_parent()
	if parent == null or _velocity.length_squared() <= 0.01:
		return
	var back := _velocity.normalized()
	ProjectileTrailFxScript.spawn_slime(
		parent,
		global_position - back * randf_range(0.1, 0.2),
		back
	)


func _on_body_entered(body: Node) -> void:
	_try_hit(body)


func _on_area_entered(area: Area3D) -> void:
	if area == self:
		return
	_try_hit(area)


func _try_hit(node: Node) -> void:
	var target := _resolve_target(node)
	if target == null:
		return
	var target_id := target.get_instance_id()
	if _hit_ids.has(target_id):
		return
	if target is CharacterBody3D and target.get_multiplayer_authority() == _shooter_id:
		return
	_hit_ids[target_id] = true
	_apply_damage(target)
	_spawn_hit_fx(global_position)
	queue_free()


func _resolve_target(node: Node) -> Node:
	if node.has_method("take_corrosive_slime") or node.has_method("take_damage") or node.has_method("take_melee_hit"):
		return node
	if node.get_parent() and (
		node.get_parent().has_method("take_corrosive_slime")
		or node.get_parent().has_method("take_damage")
		or node.get_parent().has_method("take_melee_hit")
	):
		return node.get_parent()
	return null


func _apply_damage(target: Node) -> void:
	if _combat_kind == "slime" and target.has_method("take_corrosive_slime"):
		target.take_corrosive_slime(_damage, _shooter_id)
	elif target.has_method("take_melee_hit"):
		target.take_melee_hit(_damage, _shooter_id)
	elif target.has_method("take_damage"):
		target.take_damage(_damage)


func _spawn_hit_fx(pos: Vector3) -> void:
	var parent := get_parent()
	if parent == null:
		return
	GameSfxScript.play_3d_varied(
		parent,
		pos,
		RpgAudioLibraryScript.from_pool(RpgAudioLibraryScript.PROJECTILE_HIT)
	)
	var spark := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.14
	mesh.height = 0.28
	spark.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.5, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.4)
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark.material_override = mat
	parent.add_child(spark)
	spark.global_position = pos
	var tween := spark.create_tween()
	tween.tween_property(spark, "scale", Vector3.ONE * 2.0, 0.16)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.16)
	tween.tween_callback(spark.queue_free)


func _apply_color(color: Color) -> void:
	if _mesh == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.1
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh.material_override = mat