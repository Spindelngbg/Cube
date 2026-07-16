extends Area3D

const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")

const LASER_DAMAGE := 24.0
const SPEED := 52.0
const MAX_LIFETIME := 2.4

var _velocity := Vector3.ZERO
var _shooter_id := -1
var _alive := 0.0
var _mesh: MeshInstance3D


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_mesh = get_node_or_null("Mesh") as MeshInstance3D


func launch(origin: Vector3, direction: Vector3, shooter_id: int) -> void:
	global_position = origin
	_velocity = direction.normalized() * SPEED
	_shooter_id = shooter_id
	_alive = 0.0
	if _velocity.length_squared() > 0.01:
		look_at(origin + _velocity, Vector3.UP)


func _physics_process(delta: float) -> void:
	_alive += delta
	if _alive >= MAX_LIFETIME:
		queue_free()
		return

	global_position += _velocity * delta
	if _mesh:
		var pulse := 1.0 + sin(_alive * 48.0) * 0.12
		_mesh.scale = Vector3(0.14 * pulse, 0.14 * pulse, 1.35 * pulse)


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
	if not target.is_in_group("world_monster"):
		return
	if target.has_method("is_alive") and not target.is_alive():
		return
	if target.has_method("take_damage"):
		target.take_damage(LASER_DAMAGE)
	_spawn_spark(global_position)
	GameSfxScript.play_3d_varied(get_parent(), global_position, RpgAudioLibraryScript.laser_hit())
	queue_free()


func _resolve_target(node: Node) -> Node:
	if node.is_in_group("world_monster") and node.has_method("take_damage"):
		return node
	if node.get_parent() and node.get_parent().is_in_group("world_monster"):
		return node.get_parent()
	return null


func _spawn_spark(pos: Vector3) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var spark := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.36
	spark.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.95, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 1.0, 1.0)
	mat.emission_energy_multiplier = 2.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark.material_override = mat
	parent.add_child(spark)
	spark.global_position = pos
	var tween := spark.create_tween()
	tween.tween_property(spark, "scale", Vector3.ONE * 2.4, 0.18)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.18)
	tween.tween_callback(spark.queue_free)