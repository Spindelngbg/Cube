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
	## Avstängt som standard — physical units + vit light_color blekte staden.
	return false


static func ensure_project_enabled() -> void:
	## Tvinga av: spelet ska använda vanliga light_energy/färger.
	if ProjectSettings.has_setting(PROJECT_SETTING):
		ProjectSettings.set_setting(PROJECT_SETTING, false)


static func apply_camera_physical(camera: Camera3D) -> void:
	if camera == null:
		return
	## Ta bort physical camera-attributes (ISO/exponering) som vitade ut bilden.
	camera.attributes = null


static func apply_directional_physical(
	sun: DirectionalLight3D,
	is_exposed_city: bool
) -> void:
	if sun == null:
		return
	## Fallback till klassiska färger — anropas inte när is_enabled() är false.
	if is_exposed_city:
		sun.light_color = Color(1.0, 0.94, 0.82)
		sun.light_energy = 1.15
	else:
		sun.light_color = Color(0.95, 0.92, 0.88)
		sun.light_energy = 1.05


static func apply_omni_physical(
	light: OmniLight3D,
	lumens: float,
	temperature_k: float = STREET_TEMP_K,
	energy_mult: float = 1.0
) -> void:
	if light == null:
		return
	## Konvertera ungefär till vanlig energy (inte physical).
	light.light_intensity_lumens = 0.0
	light.light_energy = clampf(energy_mult * (lumens / 8000.0), 0.15, 2.5)


static func apply_spot_physical(
	light: SpotLight3D,
	lumens: float,
	temperature_k: float = STREET_TEMP_K,
	energy_mult: float = 1.0
) -> void:
	if light == null:
		return
	light.light_intensity_lumens = 0.0
	light.light_energy = clampf(energy_mult * (lumens / 10000.0), 0.2, 3.0)


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
