class_name ColonyLighting
extends RefCounted

const HUB_SHADOW_DISTANCE := 180.0


static func apply_environment(env: Environment, is_exposed_city: bool, draw_distance_m: float = -1.0) -> void:
	var fog_end := draw_distance_m if draw_distance_m > 0.0 else (5200.0 if is_exposed_city else 25_000.0)
	var fog_begin := maxf(28.0 if is_exposed_city else 80.0, fog_end * 0.04)
	var forward_plus := _uses_forward_plus()
	var ssao_on := ssao_glow_enabled() and forward_plus
	var glow_on := ssao_glow_enabled() and forward_plus
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ssao_enabled = ssao_on
	if env.ssao_enabled:
		env.ssao_radius = 1.15
		env.ssao_intensity = 1.35
		env.ssao_power = 1.6
		env.ssao_detail = 0.4
		env.ssao_horizon = 0.08
		env.ssao_sharpness = 0.92
		env.ssao_light_affect = 0.42
	env.sdfgi_enabled = false
	env.fog_enabled = true

	if is_exposed_city:
		env.ambient_light_color = Color(0.1, 0.13, 0.22)
		env.ambient_light_energy = 0.22 if not shadows_enabled() else 0.1
		env.fog_light_color = Color(0.14, 0.18, 0.28)
		env.fog_density = 0.0048
		env.fog_depth_begin = fog_begin
		env.fog_depth_end = fog_end
		env.fog_sky_affect = 0.1
		env.tonemap_exposure = 0.84
		env.glow_enabled = glow_on
		if glow_on:
			env.glow_intensity = 0.72
			env.glow_strength = 0.9
		else:
			env.glow_intensity = 0.0
			env.glow_strength = 0.0
	else:
		env.ambient_light_color = Color(0.14, 0.17, 0.24)
		env.ambient_light_energy = 0.28 if not shadows_enabled() else 0.18
		env.fog_light_color = Color(0.16, 0.2, 0.3)
		env.fog_density = 0.00004
		env.fog_depth_begin = fog_begin
		env.fog_depth_end = fog_end
		env.fog_sky_affect = 0.18
		env.tonemap_exposure = 0.92
		env.glow_enabled = glow_on
		if glow_on:
			env.glow_intensity = 0.55
			env.glow_strength = 0.82
		else:
			env.glow_intensity = 0.0
			env.glow_strength = 0.0


static func ssao_glow_enabled() -> bool:
	var settings := Engine.get_main_loop()
	if settings == null:
		return false
	var tree := settings as SceneTree
	if tree == null:
		return false
	var mgr := tree.root.get_node_or_null("Settings")
	if mgr == null:
		return false
	return bool(mgr.get_value("display.ssao_glow_enabled", false))


static func _uses_forward_plus() -> bool:
	return str(ProjectSettings.get_setting(
		"rendering/renderer/rendering_method",
		"gl_compatibility"
	)) == "forward_plus"


static func shadows_enabled() -> bool:
	var settings_tree := Engine.get_main_loop() as SceneTree
	if settings_tree != null:
		var mgr := settings_tree.root.get_node_or_null("Settings")
		if mgr != null:
			return bool(mgr.get_value("display.shadows_enabled", false))
	# Default: skuggor AV — stor FPS-vinst i staden.
	return false


static func apply_sun(sun: DirectionalLight3D, is_exposed_city: bool, draw_distance_m: float = -1.0) -> void:
	sun.shadow_enabled = shadows_enabled()
	if sun.shadow_enabled:
		var shadow_distance := draw_distance_m if draw_distance_m > 0.0 else HUB_SHADOW_DISTANCE
		# En split = billigare skuggor.
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		sun.directional_shadow_blend_splits = false
		sun.directional_shadow_max_distance = clampf(shadow_distance * 0.18, 40.0, 90.0)
		sun.shadow_bias = 0.06
		sun.shadow_normal_bias = 1.2
		sun.shadow_blur = 0.0
	else:
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL

	if is_exposed_city:
		sun.light_color = Color(0.58, 0.68, 0.92)
		sun.light_energy = 0.62
		sun.rotation_degrees = Vector3(-78, 18, 0)
	else:
		sun.light_color = Color(0.68, 0.76, 0.95)
		sun.light_energy = 0.72
		sun.rotation_degrees = Vector3(-48, 35, 0)