class_name PhysicalLighting
extends RefCounted

## Godot physical light units (lumens / lux / Kelvin) + CameraAttributesPhysical.

const PROJECT_SETTING := "rendering/lights_and_shadows/use_physical_light_units"

## Street LED: ~10–20 klm; keep game-friendly so many lamps don't blow exposure.
const STREET_SPOT_LUMENS := 14000.0
const STREET_BULB_LUMENS := 3200.0
const STREET_SPARK_LUMENS := 800.0
const STREET_TEMP_K := 3200.0 ## warm metal halide / LED street

## Night / dusk colony sun (moon + residual sky) in lux.
const CITY_SUN_LUX := 2.5
const CITY_SUN_TEMP_K := 7500.0
const HUB_SUN_LUX := 8.0
const HUB_SUN_TEMP_K := 6200.0

## Camera (night city ISO).
const CAM_ISO := 800.0
const CAM_SHUTTER := 60.0 ## 1/60 s
const CAM_APERTURE := 2.0 ## f/2.0
const CAM_EXPOSURE_MULT := 1.0


static func is_enabled() -> bool:
	return bool(ProjectSettings.get_setting(PROJECT_SETTING, false))


static func ensure_project_enabled() -> void:
	if ProjectSettings.has_setting(PROJECT_SETTING):
		ProjectSettings.set_setting(PROJECT_SETTING, true)


static func apply_camera_physical(camera: Camera3D) -> void:
	if camera == null:
		return
	ensure_project_enabled()
	var attrs := camera.attributes as CameraAttributesPhysical
	if attrs == null:
		attrs = CameraAttributesPhysical.new()
		camera.attributes = attrs
	attrs.exposure_sensitivity = CAM_ISO
	attrs.exposure_shutter_speed = CAM_SHUTTER
	attrs.exposure_aperture = CAM_APERTURE
	attrs.exposure_multiplier = CAM_EXPOSURE_MULT
	## Auto exposure is Forward+ only — fixed physical exposure on GLES/Compatibility.
	var forward_plus := str(ProjectSettings.get_setting(
		"rendering/renderer/rendering_method", "gl_compatibility"
	)) == "forward_plus"
	attrs.auto_exposure_enabled = forward_plus
	if forward_plus:
		attrs.auto_exposure_scale = 0.35
		attrs.auto_exposure_min_exposure_value = -2.5
		attrs.auto_exposure_max_exposure_value = 2.0
		attrs.auto_exposure_speed = 0.8


static func apply_directional_physical(
	sun: DirectionalLight3D,
	is_exposed_city: bool
) -> void:
	if sun == null:
		return
	ensure_project_enabled()
	if is_exposed_city:
		sun.light_intensity_lux = CITY_SUN_LUX
		sun.light_temperature = CITY_SUN_TEMP_K
	else:
		sun.light_intensity_lux = HUB_SUN_LUX
		sun.light_temperature = HUB_SUN_TEMP_K
	## Multiplier kept near 1 so lux is the main control.
	sun.light_energy = 1.0
	sun.light_color = Color(1, 1, 1)


static func apply_omni_physical(
	light: OmniLight3D,
	lumens: float,
	temperature_k: float = STREET_TEMP_K,
	energy_mult: float = 1.0
) -> void:
	if light == null:
		return
	ensure_project_enabled()
	light.light_intensity_lumens = maxf(lumens, 0.0)
	light.light_temperature = temperature_k
	light.light_energy = energy_mult
	light.light_color = Color(1, 1, 1)


static func apply_spot_physical(
	light: SpotLight3D,
	lumens: float,
	temperature_k: float = STREET_TEMP_K,
	energy_mult: float = 1.0
) -> void:
	if light == null:
		return
	ensure_project_enabled()
	light.light_intensity_lumens = maxf(lumens, 0.0)
	light.light_temperature = temperature_k
	light.light_energy = energy_mult
	light.light_color = Color(1, 1, 1)


static func enable_distance_fade(
	light: Light3D,
	begin_m: float = 32.0,
	length_m: float = 14.0
) -> void:
	if light == null:
		return
	light.distance_fade_enabled = true
	light.distance_fade_begin = begin_m
	light.distance_fade_length = length_m
	light.distance_fade_shadow = begin_m * 0.85
