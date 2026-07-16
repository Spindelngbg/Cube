class_name ColonyLighting
extends RefCounted

const HUB_SHADOW_DISTANCE := 720.0


static func apply_environment(env: Environment, is_exposed_city: bool) -> void:
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ssao_enabled = _uses_forward_plus()
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
		env.ambient_light_energy = 0.1
		env.fog_light_color = Color(0.14, 0.18, 0.28)
		env.fog_density = 0.0032
		env.fog_depth_begin = 28.0
		env.fog_depth_end = 5200.0
		env.fog_sky_affect = 0.1
		env.tonemap_exposure = 0.84
		env.glow_intensity = 0.72
		env.glow_strength = 0.9
	else:
		env.ambient_light_color = Color(0.14, 0.17, 0.24)
		env.ambient_light_energy = 0.18
		env.fog_light_color = Color(0.16, 0.2, 0.3)
		env.fog_density = 0.00004
		env.fog_depth_begin = 200.0
		env.fog_depth_end = 25_000.0
		env.fog_sky_affect = 0.18
		env.tonemap_exposure = 0.92
		env.glow_intensity = 0.55
		env.glow_strength = 0.82


static func _uses_forward_plus() -> bool:
	return str(ProjectSettings.get_setting(
		"rendering/renderer/rendering_method",
		"gl_compatibility"
	)) == "forward_plus"


static func apply_sun(sun: DirectionalLight3D, is_exposed_city: bool) -> void:
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_blend_splits = true
	sun.directional_shadow_max_distance = HUB_SHADOW_DISTANCE
	sun.directional_shadow_split_1 = 0.08
	sun.directional_shadow_split_2 = 0.22
	sun.directional_shadow_split_3 = 0.55
	sun.directional_shadow_fade_start = 0.82
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.1
	sun.shadow_blur = 1.2

	if is_exposed_city:
		sun.light_color = Color(0.58, 0.68, 0.92)
		sun.light_energy = 0.62
		sun.rotation_degrees = Vector3(-78, 18, 0)
	else:
		sun.light_color = Color(0.68, 0.76, 0.95)
		sun.light_energy = 0.72
		sun.rotation_degrees = Vector3(-48, 35, 0)