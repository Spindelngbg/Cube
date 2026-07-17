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
		return 90.0
	return 220.0


static func render_scale_cap() -> float:
	if is_active():
		return 0.55
	return 0.7


static func entity_sim_radius_m() -> float:
	if is_active():
		return 38.0
	return 55.0


static func entity_render_radius_m() -> float:
	if is_active():
		return 55.0
	return 80.0


static func zone_cull_radius_m() -> float:
	# Alltid cull zoner i Neo-Washington — största FPS-vinsten.
	if is_active():
		return 70.0
	return 95.0


static func max_building_grid_dist() -> float:
	if is_active():
		return 1.85
	return 4.5


static func skip_greenery() -> bool:
	return is_active() or low_spec_city()


static func skip_light_rays() -> bool:
	return is_active()


static func light_ray_plane_count() -> int:
	if is_active():
		return 0
	return 1


static func light_ray_cull_m() -> float:
	if is_active():
		return 0.0
	return 38.0


static func minimap_update_interval_s() -> float:
	return 1.25 if is_active() else 0.55


static func shadows_default() -> bool:
	return false


static func default_render_scale() -> float:
	return 0.55 if is_active() else 0.65
