extends Node

const PRESETS_M: Array[float] = [180.0, 300.0, 500.0, 800.0]
const PRESET_LABELS := [
	"Prestanda (180 m)",
	"Nära (300 m)",
	"Normal (500 m)",
	"Långt (800 m)",
]

const SETTING_KEY := "display.draw_distance_index"
const SHADOWS_KEY := "display.shadows_enabled"
const SSAO_GLOW_KEY := "display.ssao_glow_enabled"
const RENDER_SCALE_KEY := "display.render_scale"
const MESH_LOD_KEY := "display.mesh_lod_index"
const DISTANCE_CULLING_KEY := "display.distance_culling_enabled"
const CULLING_STRENGTH_KEY := "display.culling_strength_index"

## Mesh LOD: högre threshold = lägre detalj tidigare = bättre FPS.
const MESH_LOD_LABELS := [
	"Prestanda",
	"Balanserad",
	"Kvalitet",
	"Max detalj",
]
const MESH_LOD_THRESHOLDS: Array[float] = [6.0, 3.0, 1.5, 0.75]

## Avståndsculling-styrka (visibility range).
const CULLING_STRENGTH_LABELS := [
	"Mjuk",
	"Normal",
	"Aggressiv",
]
const CULLING_STRENGTH_MULT: Array[float] = [1.0, 0.88, 0.72]

const ColonyLightingScript = preload("res://scripts/rendering/colony_lighting.gd")
const RuntimeVisibilityBudgetScript = preload("res://scripts/rendering/runtime_visibility_budget.gd")
const GlesPerformanceScript = preload("res://scripts/rendering/gles_performance.gd")
const PhysicalLightingScript = preload("res://scripts/rendering/physical_lighting.gd")


func _ready() -> void:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return
	settings.set_default(SETTING_KEY, 0)
	settings.set_default(SHADOWS_KEY, GlesPerformanceScript.shadows_default())
	settings.set_default(SSAO_GLOW_KEY, false)
	settings.set_default(RENDER_SCALE_KEY, GlesPerformanceScript.default_render_scale())
	settings.set_default(MESH_LOD_KEY, 1) ## Balanserad
	settings.set_default(DISTANCE_CULLING_KEY, true)
	settings.set_default(CULLING_STRENGTH_KEY, 1) ## Normal
	if settings.has_signal("setting_changed"):
		settings.setting_changed.connect(_on_setting_changed)
	if settings.has_signal("settings_loaded"):
		settings.settings_loaded.connect(_on_settings_loaded)
	if settings.has_signal("settings_reset"):
		settings.settings_reset.connect(_on_settings_loaded)
	call_deferred("_sync_with_settings")


func _sync_with_settings() -> void:
	var settings := get_node_or_null("/root/Settings")
	if settings != null and settings.has_method("has_finished_loading") and not settings.has_finished_loading():
		return
	_on_settings_loaded()


func get_preset_index() -> int:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return 0
	return clampi(int(settings.get_value(SETTING_KEY, 0)), 0, PRESETS_M.size() - 1)


func get_distance_m() -> float:
	var distance_m := PRESETS_M[get_preset_index()]
	# Alltid cap — stora draw distances krossar FPS i Neo-Washington.
	distance_m = minf(distance_m, GlesPerformanceScript.draw_distance_cap_m())
	var competitive := get_node_or_null("/root/CompetitiveMode")
	if competitive != null and competitive.has_method("max_draw_distance_m"):
		var cap := float(competitive.max_draw_distance_m())
		if cap > 0.0:
			distance_m = minf(distance_m, cap)
	return distance_m


func apply_colony(game_root: Node3D, is_exposed_city: bool) -> void:
	if game_root == null:
		return
	var distance_m := get_distance_m()

	## Tvinga klassisk light_energy (inte lumens/ISO) — annars vit/blekt värld.
	PhysicalLightingScript.ensure_project_enabled()

	var camera := game_root.get_viewport().get_camera_3d()
	if camera == null:
		camera = game_root.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if camera:
		camera.far = distance_m * 1.2
		camera.near = 0.05
		## Rensa physical camera (ISO/exponering) som blekte hela bilden.
		PhysicalLightingScript.apply_camera_physical(camera)

	var env_node := game_root.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if env_node and env_node.environment:
		ColonyLightingScript.apply_environment(env_node.environment, is_exposed_city, distance_m)

	var sun := game_root.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if sun:
		ColonyLightingScript.apply_sun(sun, is_exposed_city, distance_m)

	_apply_render_scale(game_root)
	_apply_mesh_lod(game_root)
	_apply_visibility_budget(game_root, is_exposed_city, distance_m)


func get_mesh_lod_index() -> int:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return 1
	return clampi(int(settings.get_value(MESH_LOD_KEY, 1)), 0, MESH_LOD_THRESHOLDS.size() - 1)


func get_mesh_lod_threshold() -> float:
	return MESH_LOD_THRESHOLDS[get_mesh_lod_index()]


func is_distance_culling_enabled() -> bool:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return true
	return bool(settings.get_value(DISTANCE_CULLING_KEY, true))


func get_culling_strength_index() -> int:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return 1
	return clampi(int(settings.get_value(CULLING_STRENGTH_KEY, 1)), 0, CULLING_STRENGTH_MULT.size() - 1)


func get_culling_range_mult() -> float:
	if not is_distance_culling_enabled():
		return 99.0 ## i praktiken av
	return CULLING_STRENGTH_MULT[get_culling_strength_index()]


func _apply_mesh_lod(game_root: Node3D = null) -> void:
	var threshold := get_mesh_lod_threshold()
	## Root viewport (hela spelet).
	var tree := get_tree()
	if tree != null and tree.root != null:
		tree.root.mesh_lod_threshold = threshold
	## Aktiv spel-viewport om den skiljer sig.
	if game_root != null:
		var vp := game_root.get_viewport()
		if vp != null:
			vp.mesh_lod_threshold = threshold


func _apply_visibility_budget(game_root: Node3D, is_exposed_city: bool, distance_m: float) -> void:
	if not is_exposed_city:
		return
	var satellite := game_root.get_node_or_null("Satellite_satellite_right")
	if satellite == null:
		return
	var city := satellite.get_node_or_null("NeoWashington") as Node3D
	if city == null:
		return
	if not is_distance_culling_enabled():
		RuntimeVisibilityBudgetScript.clear_from_root(city)
		return
	var end_m := distance_m * 1.05 * get_culling_range_mult()
	RuntimeVisibilityBudgetScript.apply_to_root(city, end_m)


func refresh_active_scenes() -> void:
	_apply_mesh_lod(null)
	for game in get_tree().get_nodes_in_group("game_director"):
		if not is_instance_valid(game):
			continue
		if game.has_method("refresh_draw_distance"):
			game.refresh_draw_distance()


func _on_setting_changed(key: String, _value) -> void:
	if key in [
		SETTING_KEY,
		SHADOWS_KEY,
		SSAO_GLOW_KEY,
		RENDER_SCALE_KEY,
		MESH_LOD_KEY,
		DISTANCE_CULLING_KEY,
		CULLING_STRENGTH_KEY,
	]:
		refresh_active_scenes()


func get_render_scale() -> float:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return GlesPerformanceScript.default_render_scale()
	var scale := clampf(
		float(settings.get_value(RENDER_SCALE_KEY, GlesPerformanceScript.default_render_scale())),
		0.45,
		1.0
	)
	scale = minf(scale, GlesPerformanceScript.render_scale_cap())
	return scale


func _apply_render_scale(game_root: Node3D) -> void:
	if game_root == null:
		return
	var viewport := game_root.get_viewport()
	if viewport:
		viewport.scaling_3d_scale = get_render_scale()


func _on_settings_loaded() -> void:
	_clamp_saved_performance_settings()
	refresh_active_scenes()


func _clamp_saved_performance_settings() -> void:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return
	# Tvinga sparade "tunga" inställningar ner — fixar 16 FPS-profiler.
	var idx := clampi(int(settings.get_value(SETTING_KEY, 0)), 0, PRESETS_M.size() - 1)
	if idx > 1:
		settings.set_value(SETTING_KEY, 0)
	var scale := float(settings.get_value(RENDER_SCALE_KEY, GlesPerformanceScript.default_render_scale()))
	var capped := minf(scale, GlesPerformanceScript.render_scale_cap())
	if scale > capped + 0.001:
		settings.set_value(RENDER_SCALE_KEY, capped)
	if bool(settings.get_value(SHADOWS_KEY, false)):
		settings.set_value(SHADOWS_KEY, false)
	if bool(settings.get_value(SSAO_GLOW_KEY, false)):
		settings.set_value(SSAO_GLOW_KEY, false)