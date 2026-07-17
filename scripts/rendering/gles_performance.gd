class_name GlesPerformance
extends RefCounted

## Prestandaprofil. GLES (Compatibility) är hårdare; Forward+ får också
## aggressiva tak så kolonistäder inte faller till ~16 FPS.


static func is_active() -> bool:
	return str(ProjectSettings.get_setting(
		"rendering/renderer/rendering_method",
		"gl_compatibility"
	)) != "forward_plus"


## Alltid true för stads-culling / entity-budget (både GLES och Forward+).
static func low_spec_city() -> bool:
	return true


static func draw_distance_cap_m() -> float:
	if is_active():
		return 75.0
	return 180.0


static func render_scale_cap() -> float:
	if is_active():
		return 0.6
	return 0.75


static func entity_sim_radius_m() -> float:
	if is_active():
		return 32.0
	return 48.0


static func entity_render_radius_m() -> float:
	if is_active():
		return 48.0
	return 72.0


static func zone_cull_radius_m() -> float:
	# Alltid cull zoner i Neo-Washington — största FPS-vinsten.
	if is_active():
		return 58.0
	return 82.0


static func max_building_grid_dist() -> float:
	if is_active():
		return 1.65
	return 4.0


static func skip_greenery() -> bool:
	return is_active() or low_spec_city()


static func skip_light_rays() -> bool:
	return true ## God-rays kostar mer än de ger


static func light_ray_plane_count() -> int:
	return 0


static func light_ray_cull_m() -> float:
	return 0.0


static func minimap_update_interval_s() -> float:
	return 1.4 if is_active() else 0.7


static func shadows_default() -> bool:
	return false


static func default_render_scale() -> float:
	return 0.55 if is_active() else 0.65


## Hur ofta entity/zone-budget körs (högre = mer FPS, trögare cull).
static func entity_budget_interval_s() -> float:
	return 0.4 if is_active() else 0.32
