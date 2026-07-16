class_name GlesPerformance
extends RefCounted


static func is_active() -> bool:
	return str(ProjectSettings.get_setting(
		"rendering/renderer/rendering_method",
		"gl_compatibility"
	)) != "forward_plus"


static func draw_distance_cap_m() -> float:
	return 120.0 if is_active() else 99999.0


static func render_scale_cap() -> float:
	return 0.65 if is_active() else 1.0


static func entity_sim_radius_m() -> float:
	return 55.0 if is_active() else 100.0


static func entity_render_radius_m() -> float:
	return 90.0 if is_active() else -1.0


static func zone_cull_radius_m() -> float:
	return 105.0 if is_active() else -1.0


static func max_building_grid_dist() -> float:
	return 2.25 if is_active() else 99999.0


static func skip_greenery() -> bool:
	return is_active()


static func minimap_update_interval_s() -> float:
	return 1.0 if is_active() else 0.25