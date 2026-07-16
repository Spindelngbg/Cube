extends Node

const PRESETS_M: Array[float] = [300.0, 700.0, 1400.0, 2800.0]
const PRESET_LABELS := [
	"Nära (300 m)",
	"Normal (700 m)",
	"Långt (1400 m)",
	"Max (2800 m)",
]

const SETTING_KEY := "display.draw_distance_index"
const SHADOWS_KEY := "display.shadows_enabled"
const SSAO_GLOW_KEY := "display.ssao_glow_enabled"
const RENDER_SCALE_KEY := "display.render_scale"
const ColonyLightingScript = preload("res://scripts/rendering/colony_lighting.gd")


func _ready() -> void:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return
	settings.set_default(SETTING_KEY, 0)
	settings.set_default(SHADOWS_KEY, true)
	settings.set_default(SSAO_GLOW_KEY, true)
	settings.set_default(RENDER_SCALE_KEY, 1.0)
	if settings.has_signal("setting_changed"):
		settings.setting_changed.connect(_on_setting_changed)
	if settings.has_signal("settings_loaded"):
		settings.settings_loaded.connect(_on_settings_loaded)
	if settings.has_signal("settings_reset"):
		settings.settings_reset.connect(_on_settings_loaded)


func get_preset_index() -> int:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return 0
	return clampi(int(settings.get_value(SETTING_KEY, 0)), 0, PRESETS_M.size() - 1)


func get_distance_m() -> float:
	return PRESETS_M[get_preset_index()]


func apply_colony(game_root: Node3D, is_exposed_city: bool) -> void:
	if game_root == null:
		return
	var distance_m := get_distance_m()

	var camera := game_root.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if camera:
		camera.far = distance_m * 1.2
		camera.near = 0.05

	var env_node := game_root.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if env_node and env_node.environment:
		ColonyLightingScript.apply_environment(env_node.environment, is_exposed_city, distance_m)

	var sun := game_root.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if sun:
		ColonyLightingScript.apply_sun(sun, is_exposed_city, distance_m)

	_apply_render_scale(game_root)


func refresh_active_scenes() -> void:
	for game in get_tree().get_nodes_in_group("game_director"):
		if not is_instance_valid(game):
			continue
		if game.has_method("refresh_draw_distance"):
			game.refresh_draw_distance()


func _on_setting_changed(key: String, _value) -> void:
	if key in [SETTING_KEY, SHADOWS_KEY, SSAO_GLOW_KEY, RENDER_SCALE_KEY]:
		refresh_active_scenes()


func get_render_scale() -> float:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return 1.0
	return clampf(float(settings.get_value(RENDER_SCALE_KEY, 1.0)), 0.5, 1.0)


func _apply_render_scale(game_root: Node3D) -> void:
	if game_root == null:
		return
	var viewport := game_root.get_viewport()
	if viewport:
		viewport.scaling_3d_scale = get_render_scale()


func _on_settings_loaded() -> void:
	refresh_active_scenes()