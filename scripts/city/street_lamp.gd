class_name StreetLamp
extends Node3D

const StreetLampServiceScript = preload("res://scripts/city/street_lamp_service.gd")
const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")
const GlesPerformanceScript = preload("res://scripts/rendering/gles_performance.gd")
const PhysicalLightingScript = preload("res://scripts/rendering/physical_lighting.gd")

const BROKEN_CHANCE := 0.11
## Physical light units (lumens/Kelvin) + distance fade — real Spot/Omni for streetlights.
const USE_DYNAMIC_LIGHTS := true
## God-rays: billiga meshar (delad mesh/material), ingen Light3D, ingen process.
const USE_LIGHT_RAYS := true
const RAY_VISIBILITY_END_M := 38.0
const RAY_VISIBILITY_END_GLES_M := 28.0
## Cull real lights early so hundreds of lamps don't kill FPS.
const LIGHT_FADE_BEGIN_M := 28.0
const LIGHT_FADE_LENGTH_M := 12.0
const LIGHT_FADE_BEGIN_GLES_M := 18.0
const LIGHT_FADE_LENGTH_GLES_M := 8.0

## Delade resurser — noll per-lampa mesh/material-allokering efter första.
static var _shared_cone_mesh: CylinderMesh
static var _shared_plane_mesh: QuadMesh
static var _shared_ray_mat: StandardMaterial3D
static var _shared_plane_mat: StandardMaterial3D

var _spot: SpotLight3D
var _bulb_omni: OmniLight3D
var _fixture_mesh: MeshInstance3D
var _pool_mesh: MeshInstance3D
var _spark_omni: OmniLight3D
var _ray_root: Node3D

var _color := Color(0.82, 0.9, 1.0)
var _base_spot_energy := 1.85
var _base_omni_energy := 0.72
var _base_spot_lumens := PhysicalLightingScript.STREET_SPOT_LUMENS
var _base_omni_lumens := PhysicalLightingScript.STREET_BULB_LUMENS
var _base_emission := 1.15
var _light_temp_k := PhysicalLightingScript.STREET_TEMP_K
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
	## Scale physical intensity from legacy energy configs (1.85 ≈ full street LED).
	var energy_norm := clampf(spot_energy / 1.85, 0.35, 1.6)
	_base_spot_lumens = PhysicalLightingScript.STREET_SPOT_LUMENS * energy_norm
	_base_omni_lumens = PhysicalLightingScript.STREET_BULB_LUMENS * energy_norm
	_light_temp_k = float(config.get("temperature_k", PhysicalLightingScript.STREET_TEMP_K))
	## GLES: skip real lights on some lamps to keep budget (still emissive fixture).
	var use_lights := USE_DYNAMIC_LIGHTS
	if GlesPerformanceScript.is_active() and (_rng.randi() % 3) != 0:
		use_lights = false
	_build_geometry(height)
	if use_lights:
		_build_lights(height, spot_range, tilt_toward)
	if USE_LIGHT_RAYS and not GlesPerformanceScript.skip_light_rays():
		_build_light_rays(height)
	_broken = _rng.randf() < broken_chance
	_apply_light_level(1.0 if not _broken else 0.0)
	if _broken and use_lights:
		_schedule_next_flicker()
	set_process(_broken and use_lights)


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


## Ljusstrålar som rena meshar — ingen realtidsljus, ingen CPU-tick.
func _build_light_rays(height: float) -> void:
	_ensure_shared_ray_resources()
	_ray_root = Node3D.new()
	_ray_root.name = "LightRays"
	add_child(_ray_root)

	var head_y := height + 0.02
	var ray_len := clampf(height * 0.85, 2.8, 4.2)
	var cull_end := GlesPerformanceScript.light_ray_cull_m()
	if cull_end <= 1.0:
		cull_end = RAY_VISIBILITY_END_M

	# En kon räcker — plan-strålar är valfria och dyra i stora städer.
	var cone := MeshInstance3D.new()
	cone.name = "RayCone"
	cone.mesh = _shared_cone_mesh
	cone.material_override = _shared_ray_mat
	cone.position = Vector3(0.0, head_y - ray_len * 0.5, 0.0)
	cone.scale = Vector3(0.85, ray_len / 4.0, 0.85)
	_configure_ray_instance(cone, cull_end)
	_ray_root.add_child(cone)

	var plane_count := GlesPerformanceScript.light_ray_plane_count()
	for i in plane_count:
		var plane := MeshInstance3D.new()
		plane.name = "RayPlane_%d" % i
		plane.mesh = _shared_plane_mesh
		plane.material_override = _shared_plane_mat
		plane.position = Vector3(0.0, head_y - ray_len * 0.5, 0.0)
		plane.rotation.y = float(i) * (PI / float(maxi(plane_count, 1)))
		plane.scale = Vector3(1.0, ray_len / 4.0, 1.0)
		_configure_ray_instance(plane, cull_end)
		_ray_root.add_child(plane)


static func _ensure_shared_ray_resources() -> void:
	if _shared_cone_mesh == null:
		_shared_cone_mesh = CylinderMesh.new()
		_shared_cone_mesh.top_radius = 0.04
		_shared_cone_mesh.bottom_radius = 1.15
		_shared_cone_mesh.height = 4.0
		_shared_cone_mesh.radial_segments = 6 # lågt polytal
		_shared_cone_mesh.rings = 1

	if _shared_plane_mesh == null:
		_shared_plane_mesh = QuadMesh.new()
		_shared_plane_mesh.size = Vector2(1.6, 4.0)

	if _shared_ray_mat == null:
		_shared_ray_mat = StandardMaterial3D.new()
		_shared_ray_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shared_ray_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shared_ray_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_shared_ray_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_shared_ray_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.14)
		_shared_ray_mat.emission_enabled = true
		_shared_ray_mat.emission = Color(0.85, 0.92, 1.0)
		_shared_ray_mat.emission_energy_multiplier = 0.55
		_shared_ray_mat.no_depth_test = false
		_shared_ray_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

	if _shared_plane_mat == null:
		_shared_plane_mat = StandardMaterial3D.new()
		_shared_plane_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shared_plane_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shared_plane_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_shared_plane_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_shared_plane_mat.albedo_color = Color(0.85, 0.92, 1.0, 0.1)
		_shared_plane_mat.emission_enabled = true
		_shared_plane_mat.emission = Color(0.9, 0.95, 1.0)
		_shared_plane_mat.emission_energy_multiplier = 0.4
		_shared_plane_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED


static func _configure_ray_instance(mi: MeshInstance3D, cull_end: float) -> void:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.visibility_range_begin = 0.0
	mi.visibility_range_end = cull_end
	mi.visibility_range_end_margin = 12.0
	mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


func _build_lights(height: float, spot_range: float, tilt_toward: Vector3) -> void:
	var head_pos := Vector3(0.0, height + 0.04, 0.0)
	var fade_begin := LIGHT_FADE_BEGIN_GLES_M if GlesPerformanceScript.is_active() else LIGHT_FADE_BEGIN_M
	var fade_len := LIGHT_FADE_LENGTH_GLES_M if GlesPerformanceScript.is_active() else LIGHT_FADE_LENGTH_M
	_bulb_omni = OmniLight3D.new()
	_bulb_omni.name = "BulbGlow"
	_bulb_omni.position = head_pos
	_bulb_omni.omni_range = 3.8
	_bulb_omni.shadow_enabled = false
	_bulb_omni.light_color = _color
	_bulb_omni.light_energy = _base_omni_energy
	PhysicalLightingScript.enable_distance_fade(_bulb_omni, fade_begin * 0.55, fade_len * 0.7)
	add_child(_bulb_omni)

	_spot = SpotLight3D.new()
	_spot.name = "StreetBeam"
	_spot.position = head_pos
	var tilt_local := tilt_toward.rotated(Vector3.UP, rotation.y)
	if tilt_local.length_squared() > 0.001:
		_spot.look_at(head_pos + tilt_local.normalized(), Vector3.UP)
	else:
		_spot.rotation_degrees = Vector3(-90, 0, 0)
	_spot.spot_range = spot_range
	_spot.spot_angle = 44.0
	_spot.shadow_enabled = false
	_spot.light_color = _color
	_spot.light_energy = _base_spot_energy
	PhysicalLightingScript.enable_distance_fade(_spot, fade_begin, fade_len)
	add_child(_spot)

	_spark_omni = OmniLight3D.new()
	_spark_omni.name = "SparkFlash"
	_spark_omni.position = head_pos + Vector3(0.0, -0.08, 0.0)
	_spark_omni.omni_range = 2.2
	_spark_omni.shadow_enabled = false
	_spark_omni.light_color = Color(1.0, 0.72, 0.22)
	_spark_omni.light_energy = 0.0
	PhysicalLightingScript.enable_distance_fade(_spark_omni, fade_begin * 0.4, fade_len * 0.5)
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
	if _spark_omni == null:
		return
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
	# Trasiga lampor: dölj strålar (ingen process — bara synlighet).
	if _ray_root:
		_ray_root.visible = clamped > 0.08


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