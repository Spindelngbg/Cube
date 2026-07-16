class_name StreetLamp
extends Node3D

const StreetLampServiceScript = preload("res://scripts/city/street_lamp_service.gd")
const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")

const BROKEN_CHANCE := 0.11
## Real Spot/Omni lights tank FPS in large cities — emissive fixtures are enough.
const USE_DYNAMIC_LIGHTS := false

var _spot: SpotLight3D
var _bulb_omni: OmniLight3D
var _fixture_mesh: MeshInstance3D
var _pool_mesh: MeshInstance3D
var _spark_omni: OmniLight3D

var _color := Color(0.82, 0.9, 1.0)
var _base_spot_energy := 1.85
var _base_omni_energy := 0.72
var _base_emission := 1.15
var _broken := false
var _rebreak_timer := 0.0

var _rng := RandomNumberGenerator.new()
var _flicker_timer := 0.0
var _flicker_target := 1.0
var _flicker_current := 1.0


static func mount(parent: Node3D, config: Dictionary) -> StreetLamp:
	var lamp := StreetLamp.new()
	lamp.name = "StreetLamp"
	parent.add_child(lamp)
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.get_multiplayer().multiplayer_peer != null:
		lamp.set_multiplayer_authority(MultiplayerEntityAuthorityScript.simulation_peer_id())
	lamp.configure(config)
	StreetLampServiceScript.register(lamp)
	return lamp


func configure(config: Dictionary) -> void:
	position = config.get("position", Vector3.ZERO)
	rotation.y = float(config.get("rotation_y", 0.0))
	_color = config.get("color", Color(0.82, 0.9, 1.0))
	var height: float = float(config.get("height", 4.6))
	var spot_energy: float = float(config.get("spot_energy", 1.85))
	var spot_range: float = float(config.get("spot_range", 15.0))
	var tilt_toward: Vector3 = config.get("tilt_toward", Vector3.ZERO)
	var broken_chance: float = float(config.get("broken_chance", BROKEN_CHANCE))
	var seed: int = int(config.get("seed", hash(str(position))))

	_rng.seed = seed
	_base_spot_energy = spot_energy
	_base_omni_energy = spot_energy * 0.38
	_build_geometry(height)
	if USE_DYNAMIC_LIGHTS:
		_build_lights(height, spot_range, tilt_toward)
	_broken = _rng.randf() < broken_chance
	_apply_light_level(1.0 if not _broken else 0.0)
	if _broken and USE_DYNAMIC_LIGHTS:
		_schedule_next_flicker()
	set_process(_broken and USE_DYNAMIC_LIGHTS)


func is_broken() -> bool:
	return _broken


func get_repair_stand_position() -> Vector3:
	return global_position + global_transform.basis.z * 1.35


func repair(duration_before_rebreak: float = -1.0) -> void:
	if not _broken:
		return
	_broken = false
	_rebreak_timer = duration_before_rebreak
	_apply_light_level(1.0)
	set_process(USE_DYNAMIC_LIGHTS and _rebreak_timer > 0.0)
	_sync_repair_state.rpc(false, _rebreak_timer)


func _build_geometry(height: float) -> void:
	var pole := MeshInstance3D.new()
	var pole_mesh := BoxMesh.new()
	pole_mesh.size = Vector3(0.14, height, 0.14)
	pole.mesh = pole_mesh
	pole.position = Vector3(0.0, height * 0.5, 0.0)
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.16, 0.18, 0.22)
	pole_mat.metallic = 0.55
	pole.material_override = pole_mat
	add_child(pole)

	var head_pos := Vector3(0.0, height + 0.08, 0.0)
	_fixture_mesh = MeshInstance3D.new()
	var fixture_mesh := BoxMesh.new()
	fixture_mesh.size = Vector3(0.46, 0.16, 0.3)
	_fixture_mesh.mesh = fixture_mesh
	_fixture_mesh.position = head_pos
	var fixture_mat := StandardMaterial3D.new()
	fixture_mat.albedo_color = Color(0.2, 0.22, 0.26)
	fixture_mat.metallic = 0.62
	fixture_mat.emission_enabled = true
	fixture_mat.emission = _color
	fixture_mat.emission_energy_multiplier = _base_emission
	_fixture_mesh.material_override = fixture_mat
	add_child(_fixture_mesh)

	var shade := MeshInstance3D.new()
	var shade_mesh := BoxMesh.new()
	shade_mesh.size = Vector3(0.4, 0.06, 0.36)
	shade.mesh = shade_mesh
	shade.position = head_pos + Vector3(0.0, 0.11, 0.0)
	var shade_mat := StandardMaterial3D.new()
	shade_mat.albedo_color = Color(0.12, 0.13, 0.16)
	shade_mat.metallic = 0.48
	shade.material_override = shade_mat
	add_child(shade)

	_pool_mesh = MeshInstance3D.new()
	var pool := CylinderMesh.new()
	pool.top_radius = 1.35
	pool.bottom_radius = 1.35
	pool.height = 0.03
	_pool_mesh.mesh = pool
	_pool_mesh.position = Vector3(0.0, 0.02, 0.0)
	var pool_mat := StandardMaterial3D.new()
	pool_mat.albedo_color = _color
	pool_mat.emission_enabled = true
	pool_mat.emission = _color
	pool_mat.emission_energy_multiplier = 0.22
	pool_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pool_mat.albedo_color.a = 0.55
	_pool_mesh.material_override = pool_mat
	add_child(_pool_mesh)


func _build_lights(height: float, spot_range: float, tilt_toward: Vector3) -> void:
	var head_pos := Vector3(0.0, height + 0.04, 0.0)

	_bulb_omni = OmniLight3D.new()
	_bulb_omni.name = "BulbGlow"
	_bulb_omni.position = head_pos
	_bulb_omni.light_color = _color
	_bulb_omni.light_energy = _base_omni_energy
	_bulb_omni.omni_range = 3.8
	_bulb_omni.shadow_enabled = false
	add_child(_bulb_omni)

	_spot = SpotLight3D.new()
	_spot.name = "StreetBeam"
	_spot.position = head_pos
	var tilt_local := tilt_toward.rotated(Vector3.UP, rotation.y)
	if tilt_local.length_squared() > 0.001:
		_spot.look_at(head_pos + tilt_local.normalized(), Vector3.UP)
	else:
		_spot.rotation_degrees = Vector3(-90, 0, 0)
	_spot.light_color = _color
	_spot.light_energy = _base_spot_energy
	_spot.spot_range = spot_range
	_spot.spot_angle = 44.0
	_spot.shadow_enabled = false
	add_child(_spot)

	_spark_omni = OmniLight3D.new()
	_spark_omni.name = "SparkFlash"
	_spark_omni.position = head_pos + Vector3(0.0, -0.08, 0.0)
	_spark_omni.light_color = Color(1.0, 0.72, 0.22)
	_spark_omni.light_energy = 0.0
	_spark_omni.omni_range = 2.2
	_spark_omni.shadow_enabled = false
	add_child(_spark_omni)


func _process(delta: float) -> void:
	if _broken:
		_tick_flicker(delta)
		return
	if _rebreak_timer > 0.0:
		_rebreak_timer -= delta
		if _rebreak_timer <= 0.0:
			_break_again()


func _tick_flicker(delta: float) -> void:
	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		_pick_flicker_state()
	_flicker_current = lerpf(_flicker_current, _flicker_target, delta * 14.0)
	_apply_light_level(_flicker_current)
	if _rng.randf() < delta * 0.35:
		_spark_omni.light_energy = _rng.randf_range(0.4, 1.4)
	else:
		_spark_omni.light_energy = lerpf(_spark_omni.light_energy, 0.0, delta * 18.0)


func _pick_flicker_state() -> void:
	var roll := _rng.randf()
	if roll < 0.28:
		_flicker_target = 0.0
		_flicker_timer = _rng.randf_range(0.12, 0.55)
	elif roll < 0.52:
		_flicker_target = _rng.randf_range(0.08, 0.35)
		_flicker_timer = _rng.randf_range(0.08, 0.22)
	elif roll < 0.62:
		_flicker_target = _rng.randf_range(1.1, 1.65)
		_flicker_timer = _rng.randf_range(0.04, 0.1)
	else:
		_flicker_target = 1.0
		_flicker_timer = _rng.randf_range(0.06, 0.18)


func _schedule_next_flicker() -> void:
	_flicker_timer = _rng.randf_range(0.05, 0.25)
	_pick_flicker_state()


func _apply_light_level(level: float) -> void:
	var clamped := clampf(level, 0.0, 1.35)
	if _spot:
		_spot.light_energy = _base_spot_energy * clamped
	if _bulb_omni:
		_bulb_omni.light_energy = _base_omni_energy * clamped
	if _fixture_mesh and _fixture_mesh.material_override is StandardMaterial3D:
		var mat := _fixture_mesh.material_override as StandardMaterial3D
		mat.emission_energy_multiplier = _base_emission * clamped
	if _pool_mesh and _pool_mesh.material_override is StandardMaterial3D:
		var pool_mat := _pool_mesh.material_override as StandardMaterial3D
		pool_mat.emission_energy_multiplier = 0.22 * clamped
		pool_mat.albedo_color.a = 0.12 + clamped * 0.48


func _break_again() -> void:
	_broken = true
	_rebreak_timer = 0.0
	_schedule_next_flicker()
	set_process(USE_DYNAMIC_LIGHTS)
	_sync_repair_state.rpc(true, 0.0)


@rpc("any_peer", "call_local", "reliable")
func _sync_repair_state(broken: bool, rebreak_in: float) -> void:
	_broken = broken
	_rebreak_timer = rebreak_in
	if broken:
		_apply_light_level(0.0)
		_schedule_next_flicker()
		set_process(USE_DYNAMIC_LIGHTS)
	else:
		_apply_light_level(1.0)
		set_process(USE_DYNAMIC_LIGHTS and _rebreak_timer > 0.0)


func request_repair() -> void:
	var rebreak := _rng.randf_range(90.0, 240.0)
	repair(rebreak)