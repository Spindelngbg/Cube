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
		env.ssao_intensity = 1.1
		env.ssao_power = 1.4
		env.ssao_detail = 0.35
		env.ssao_horizon = 0.08
		env.ssao_sharpness = 0.9
		env.ssao_light_affect = 0.35
	env.sdfgi_enabled = false
	env.fog_enabled = true
	env.background_mode = Environment.BG_SKY

	## Himlen först så ambient från sky får rätt färger.
	_apply_day_sky(env)

	if is_exposed_city:
		## Dagsljus: ambient från himmel (inte platt vit fyllnad).
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_sky_contribution = 1.0
		env.ambient_light_color = Color(0.55, 0.62, 0.75)
		env.ambient_light_energy = 0.72 if not shadows_enabled() else 0.5
		env.fog_light_color = Color(0.62, 0.7, 0.82)
		env.fog_density = 0.0012
		env.fog_depth_begin = fog_begin
		env.fog_depth_end = fog_end
		env.fog_sky_affect = 0.18
		env.tonemap_exposure = 1.0
		env.glow_enabled = glow_on
		if glow_on:
			env.glow_intensity = 0.35
			env.glow_strength = 0.6
		else:
			env.glow_intensity = 0.0
			env.glow_strength = 0.0
	else:
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_sky_contribution = 1.0
		env.ambient_light_color = Color(0.5, 0.56, 0.68)
		env.ambient_light_energy = 0.6 if not shadows_enabled() else 0.42
		env.fog_light_color = Color(0.45, 0.52, 0.62)
		env.fog_density = 0.00004
		env.fog_depth_begin = fog_begin
		env.fog_depth_end = fog_end
		env.fog_sky_affect = 0.16
		env.tonemap_exposure = 0.98
		env.glow_enabled = glow_on
		if glow_on:
			env.glow_intensity = 0.32
			env.glow_strength = 0.55
		else:
			env.glow_intensity = 0.0
			env.glow_strength = 0.0


static func _apply_day_sky(env: Environment) -> void:
	## “Taket” / himlen: normal blå dag, inte svart/vit.
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.22, 0.48, 0.86)
	sky_mat.sky_horizon_color = Color(0.68, 0.78, 0.9)
	sky_mat.ground_bottom_color = Color(0.28, 0.32, 0.26)
	sky_mat.ground_horizon_color = Color(0.52, 0.55, 0.48)
	sky_mat.sun_angle_max = 30.0
	sky_mat.sky_curve = 0.1
	sky_mat.sky_energy_multiplier = 1.0
	sky_mat.ground_energy_multiplier = 0.85
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY


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
	return false


static func apply_sun(sun: DirectionalLight3D, is_exposed_city: bool, draw_distance_m: float = -1.0) -> void:
	sun.shadow_enabled = shadows_enabled()
	if sun.shadow_enabled:
		var shadow_distance := draw_distance_m if draw_distance_m > 0.0 else HUB_SHADOW_DISTANCE
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		sun.directional_shadow_blend_splits = false
		sun.directional_shadow_max_distance = clampf(shadow_distance * 0.18, 40.0, 90.0)
		sun.shadow_bias = 0.06
		sun.shadow_normal_bias = 1.2
		sun.shadow_blur = 0.0
	else:
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL

	## Varmt dagsljus — inte vit “physical temperature”-sun.
	if is_exposed_city:
		sun.light_color = Color(1.0, 0.93, 0.78)
		sun.light_energy = 1.05
		sun.rotation_degrees = Vector3(-52, 28, 0)
	else:
		sun.light_color = Color(0.98, 0.94, 0.86)
		sun.light_energy = 0.95
		sun.rotation_degrees = Vector3(-48, 35, 0)
