extends Node

## Snabbare / mer responsiv 3D-fysik — tickrate, steps och trådad server.

const RATE_KEY := "physics.rate_index"
const THREAD_KEY := "physics.run_on_separate_thread"

const RATE_HZ: Array[int] = [60, 90, 120]
const RATE_LABELS := [
	"60 Hz (stabil)",
	"90 Hz (snabb)",
	"120 Hz (max)",
]


func _ready() -> void:
	var settings := get_node_or_null("/root/Settings")
	if settings != null:
		settings.set_default(RATE_KEY, 1) ## 90 Hz default
		settings.set_default(THREAD_KEY, true)
		if settings.has_signal("setting_changed"):
			settings.setting_changed.connect(_on_setting_changed)
		if settings.has_signal("settings_loaded"):
			settings.settings_loaded.connect(apply)
		if settings.has_signal("settings_reset"):
			settings.settings_reset.connect(apply)
	call_deferred("apply")


func get_rate_index() -> int:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return 1
	return clampi(int(settings.get_value(RATE_KEY, 1)), 0, RATE_HZ.size() - 1)


func get_physics_hz() -> int:
	return RATE_HZ[get_rate_index()]


func is_threaded() -> bool:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return true
	return bool(settings.get_value(THREAD_KEY, true))


func apply() -> void:
	var hz := get_physics_hz()
	Engine.physics_ticks_per_second = hz
	## Tillåt fler physics-steg per render-frame när tickrate är hög.
	if hz >= 120:
		Engine.max_physics_steps_per_frame = 24
	elif hz >= 90:
		Engine.max_physics_steps_per_frame = 16
	else:
		Engine.max_physics_steps_per_frame = 8

	## Mindre jitter när FPS ≠ physics rate.
	Engine.physics_jitter_fix = 0.0

	_apply_project_thread_flag(is_threaded())
	_try_enable_jolt()


func _apply_project_thread_flag(enabled: bool) -> void:
	## Runtime-byte av separate thread tar oftast effekt vid nästa physics frame
	## om servern stöder det; ProjectSettings speglar preferensen för omstart.
	if ProjectSettings.has_setting("physics/3d/run_on_separate_thread"):
		ProjectSettings.set_setting("physics/3d/run_on_separate_thread", enabled)


func _try_enable_jolt() -> void:
	## Godot 4.6+ har inbyggd Jolt — snabbare än GodotPhysics3D.
	if not ProjectSettings.has_setting("physics/3d/physics_engine"):
		return
	var current := str(ProjectSettings.get_setting("physics/3d/physics_engine", ""))
	if current.contains("Jolt") or current.contains("jolt"):
		return
	## Försök sätta Jolt; ogiltigt namn ignoreras / faller tillbaka av motorn.
	for candidate in ["Jolt Physics", "JoltPhysics", "Jolt"]:
		ProjectSettings.set_setting("physics/3d/physics_engine", candidate)
		var after := str(ProjectSettings.get_setting("physics/3d/physics_engine", ""))
		if after.contains("Jolt") or after.contains("jolt") or after == candidate:
			return


func _on_setting_changed(key: String, _value) -> void:
	if key == RATE_KEY or key == THREAD_KEY:
		apply()
