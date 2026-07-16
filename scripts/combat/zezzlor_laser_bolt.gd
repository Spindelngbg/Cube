extends Area3D

const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")
const ZezzlorDossierRuntimeScript = preload("res://scripts/monsters/zezzlor_dossier_runtime.gd")

const SPEED := 48.0
const MAX_LIFETIME := 2.4
const DAMAGE := 22.0

var _velocity := Vector3.ZERO
var _shooter: Node3D
var _target_id := -1
var _alive := 0.0
var _mesh: MeshInstance3D


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	_mesh = get_node_or_null("Mesh") as MeshInstance3D


func launch(origin: Vector3, direction: Vector3, shooter: Node3D, target_id: int) -> void:
	global_position = origin
	_velocity = direction.normalized() * SPEED
	_shooter = shooter
	_target_id = target_id
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
		var pulse := 1.0 + sin(_alive * 42.0) * 0.14
		_mesh.scale = Vector3(0.2 * pulse, 0.2 * pulse, 1.35 * pulse)


func _on_body_entered(body: Node) -> void:
	if body == _shooter:
		return
	if body.is_in_group("player_character"):
		if body.has_method("_rpc_apply_zezzlor_laser_hit"):
			var peer_id := body.get_multiplayer_authority()
			body._rpc_apply_zezzlor_laser_hit.rpc_id(peer_id, DAMAGE)
		elif body.has_method("apply_zezzlor_laser_hit"):
			body.apply_zezzlor_laser_hit(DAMAGE)
		if _target_id > 0:
			ZezzlorDossierRuntimeScript.record_laser_shot(_target_id, true)
		_spawn_hit_fx(global_position)
		queue_free()
		return
	if body is StaticBody3D or body is CSGShape3D:
		_spawn_hit_fx(global_position)
		queue_free()


func _spawn_hit_fx(pos: Vector3) -> void:
	var parent := get_parent()
	if parent == null:
		return
	GameSfxScript.play_3d_varied(
		parent,
		pos,
		RpgAudioLibraryScript.zezzlor_laser_hit(),
		Vector2(-4.0, 2.0),
		Vector2(0.9, 1.05)
	)