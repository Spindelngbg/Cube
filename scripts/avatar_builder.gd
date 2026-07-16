extends Control

const PREVIEW_SCENE := preload("res://scenes/avatar_preview.tscn")

@onready var preview_holder: Node3D = %PreviewHolder
@onready var status_label: Label = %StatusLabel
@onready var enter_button: Button = %EnterButton
@onready var welcome_label: Label = %WelcomeLabel
@onready var layout: HBoxContainer = $Layout

var _avatar := AvatarData.new()
var _preview_root: Node3D
var _preview_animator: HumanAvatarAnimator
var _preview_yaw := 0.0
var _connecting := false
var _last_archetype := ""
var _connect_watchdog: SceneTreeTimer


func _ready() -> void:
	SpiderTheme.apply_to(self)
	SpiderTheme.style_title($Layout/Left/TitleBox/Title, 40)
	SpiderTheme.style_subtitle($Layout/Left/TitleBox/Subtitle)
	SpiderTheme.style_status(status_label)

	GlobalChat.set_layout_mode("sidebar_right")
	layout.offset_right = -368.0

	_setup_welcome()
	_configure_human_ui()
	_setup_avatar()
	_bind_sliders()
	call_deferred("_init_preview")

	enter_button.pressed.connect(_on_enter_pressed)
	%LogoutButton.pressed.connect(_on_logout_pressed)
	%BackButton.pressed.connect(_on_back_pressed)
	%RandomizeButton.pressed.connect(_on_randomize_pressed)
	%ResetButton.pressed.connect(_on_reset_pressed)
	Profile.character_saved.connect(_on_character_saved)
	Profile.operation_failed.connect(_on_profile_error)

	Network.world_ready.connect(_on_world_ready)
	Network.connection_failed.connect(_on_connection_failed)

	_update_enter_button()


func _exit_tree() -> void:
	GlobalChat.reset_layout_mode()


func _update_enter_button() -> void:
	if Auth.is_guest:
		enter_button.text = "Gå in i The Cube"
	elif Profile.needs_nest_intro():
		enter_button.text = "Klättra ut i nästet"
	elif Profile.needs_home_selection():
		enter_button.text = "Gå till ljusrummet"
	else:
		enter_button.text = "Gå in i din koloni"


func _setup_welcome() -> void:
	if Auth.is_guest:
		welcome_label.text = "Gäst: %s" % Auth.username
	elif Profile.active_character_name != "":
		welcome_label.text = "%s — %s" % [Auth.username, Profile.active_character_name]
	else:
		welcome_label.text = "Välkommen, %s" % Auth.username


func _init_preview() -> void:
	_build_preview()
	_setup_preview_stage()
	_refresh_preview()


func _setup_avatar() -> void:
	if Profile.avatar_ready:
		_avatar = Profile.get_avatar()
	else:
		_avatar = _random_starter_avatar()
		if not Auth.is_guest:
			status_label.text = "Arketyp: %s — forma din kolonist." % _last_archetype


func _process(delta: float) -> void:
	_preview_yaw += delta * 0.22
	if _preview_root:
		_preview_root.rotation.y = _preview_yaw


func _bind_sliders() -> void:
	_connect_slider(%BodyScaleSlider, "body_scale", 0.75, 1.5)
	_connect_slider(%AbdomenScaleSlider, "abdomen_scale", 0.6, 1.6)
	_connect_slider(%HeadScaleSlider, "head_scale", 0.8, 1.4)
	_connect_slider(%LegLengthSlider, "leg_length", 0.7, 1.5)
	_connect_slider(%ArmLengthSlider, "arm_length", 0.6, 1.4)
	_connect_slider(%EyeSizeSlider, "eye_size", 0.4, 3.0)
	_connect_slider(%EyeSpreadSlider, "eye_spread", 0.4, 2.0)
	_connect_slider(%EyeStalkSlider, "eye_stalk_length", 0.0, 1.5)
	_connect_slider(%MandibleSlider, "mandible_length", 0.0, 2.0)
	_connect_slider(%FangSlider, "fang_length", 0.0, 2.5)
	_connect_slider(%ClawSlider, "claw_size", 0.0, 2.0)
	_connect_slider(%SegmentSlider, "abdomen_segments", 0.0, 1.0)
	_connect_slider(%CrestSlider, "crest_size", 0.0, 1.0)
	_connect_slider(%GlowSlider, "glow_strength", 0.0, 2.0)
	_connect_slider(%SpikeSlider, "spike_amount", 0.0, 1.0)
	_connect_slider(%StanceSlider, "stance_width", 0.5, 1.5)
	_connect_slider(%RoughnessSlider, "chitin_roughness", 0.0, 1.0)
	_connect_slider(%MetallicSlider, "chitin_metallic", 0.0, 1.0)

	_connect_spin(%SpiderLegsSpin, "spider_leg_count", 4, 12)
	_connect_spin(%EyeCountSpin, "eye_count", 2, 12)

	_connect_color(%BodyColorPicker, "body_color")
	_connect_color(%AccentColorPicker, "accent_color")
	_connect_color(%EyeColorPicker, "eye_color")
	_connect_color(%GlowColorPicker, "glow_color")


func _connect_slider(slider: HSlider, prop: String, min_v: float, max_v: float) -> void:
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = 0.01
	slider.value = _avatar.get(prop)
	slider.value_changed.connect(func(v: float) -> void:
		_avatar.set(prop, v)
		_refresh_preview()
	)


func _connect_spin(spin: SpinBox, prop: String, min_v: int, max_v: int) -> void:
	spin.min_value = min_v
	spin.max_value = max_v
	spin.value_changed.connect(func(v: float) -> void:
		_avatar.set(prop, int(v))
		_refresh_preview()
	)
	spin.value = _avatar.get(prop)


func _connect_color(picker: ColorPickerButton, prop: String) -> void:
	picker.color = _avatar.get(prop)
	picker.color_changed.connect(func(c: Color) -> void:
		_avatar.set(prop, c)
		_refresh_preview()
	)


func _build_preview() -> void:
	if _preview_root:
		_preview_root.queue_free()
	var scene := PREVIEW_SCENE.instantiate()
	preview_holder.add_child(scene)
	_preview_root = scene.get_node("Pivot")


func _setup_preview_stage() -> void:
	var viewport := %SubViewport
	var env := viewport.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if env and env.environment:
		env.environment.ambient_light_energy = 1.15
		env.environment.glow_enabled = true
		env.environment.glow_intensity = 1.1
		env.environment.glow_bloom = 0.35
		env.environment.tonemap_mode = Environment.TONE_MAPPER_ACES

	var camera := viewport.get_node_or_null("Camera3D") as Camera3D
	if camera:
		camera.position = Vector3(0.15, 1.35, 2.35)
		camera.look_at(Vector3(0, 1.1, 0), Vector3.UP)


func _configure_human_ui() -> void:
	var controls := $Layout/Right/Scroll/Controls
	$Layout/Left/TitleBox/Subtitle.text = "Forma din kolonist"
	%RandomizeButton.text = "Slumpa utseende"
	controls.get_node("BodyScaleRow/BodyScaleLabel").text = "Längd"
	controls.get_node("BodyColorRow/BodyColorLabel").text = "Hudton"
	controls.get_node("AccentColorRow/AccentColorLabel").text = "Kläder"
	controls.get_node("EyeColorRow/EyeColorLabel").text = "Detalj"
	controls.get_node("GlowColorRow/GlowColorLabel").text = "Neon"
	controls.get_node("GlowRow/GlowLabel").text = "Glow-styrka"
	for row_name in [
		"AbdomenScaleRow", "HeadScaleRow", "StanceRow", "LegLengthRow", "ArmLengthRow",
		"SpiderLegsRow", "EyeSizeRow", "EyeSpreadRow", "EyeStalkRow", "MandibleRow",
		"FangRow", "ClawRow", "SegmentRow", "CrestRow", "SpikeRow",
		"RoughnessRow", "MetallicRow", "EyeCountRow", "LimbsSection", "FaceSection",
		"DetailSection", "StyleSection",
	]:
		var row := controls.get_node_or_null(row_name)
		if row:
			row.visible = false
	controls.get_node("BodySection").text = "KROPP"
	controls.get_node("ColorsSection").text = "FÄRGER"


func _refresh_preview() -> void:
	if _preview_root:
		var model := HumanAvatarBuilder.build(_preview_root, _avatar)
		if model == null:
			return
		if _preview_animator == null:
			_preview_animator = HumanAvatarAnimator.ensure_on(_preview_root, true)
		_preview_animator.bind(model)


func _on_enter_pressed() -> void:
	if _connecting:
		return
	Profile.set_avatar(_avatar)

	if Auth.is_guest:
		_connecting = true
		enter_button.disabled = true
		status_label.text = "Ansluter till The Cube — väntar på servern..."
		_start_connect_watchdog()
		Network.connect_to_world()
		return

	_connecting = true
	enter_button.disabled = true
	status_label.text = "Sparar karaktär..."
	Profile.save_active_character(_avatar)


func _on_character_saved() -> void:
	if not _connecting:
		return
	var next_scene := GameFlow.play_scene_path()
	if next_scene == "res://scenes/game.tscn":
		status_label.text = "Ansluter till din koloni — väntar på servern..."
		_start_connect_watchdog()
		Network.connect_to_world()
		return

	_connecting = false
	enter_button.disabled = false
	if next_scene == "res://scenes/nest_room.tscn":
		status_label.text = "Klättrar in i nästet..."
	elif next_scene == "res://scenes/emergence_room.tscn":
		status_label.text = "Går mot ljusrummet..."
	get_tree().change_scene_to_file(next_scene)


func _on_profile_error(message: String) -> void:
	if not _connecting:
		return
	_stop_connect_watchdog()
	_connecting = false
	enter_button.disabled = false
	status_label.text = message


func _on_world_ready() -> void:
	_stop_connect_watchdog()
	status_label.text = "Går in i världen..."
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_connection_failed(reason: String) -> void:
	_stop_connect_watchdog()
	_connecting = false
	enter_button.disabled = false
	status_label.text = "Anslutning misslyckades: %s" % reason


func _start_connect_watchdog() -> void:
	_stop_connect_watchdog()
	_connect_watchdog = get_tree().create_timer(28.0)
	_connect_watchdog.timeout.connect(_on_connect_watchdog_timeout, CONNECT_ONE_SHOT)


func _stop_connect_watchdog() -> void:
	if _connect_watchdog != null and is_instance_valid(_connect_watchdog):
		if _connect_watchdog.timeout.is_connected(_on_connect_watchdog_timeout):
			_connect_watchdog.timeout.disconnect(_on_connect_watchdog_timeout)
	_connect_watchdog = null


func _on_connect_watchdog_timeout() -> void:
	if not _connecting:
		return
	Network.stop()
	_connecting = false
	enter_button.disabled = false
	status_label.text = "Servern svarade inte i tid — försök igen om en stund."


func _on_randomize_pressed() -> void:
	randomize()
	_avatar = _random_starter_avatar()
	_sync_ui_from_avatar()
	_refresh_preview()
	status_label.text = "Arketyp: %s" % _last_archetype


func _on_reset_pressed() -> void:
	_avatar = AvatarData.new()
	_sync_ui_from_avatar()
	_refresh_preview()


func _on_back_pressed() -> void:
	if Auth.is_guest:
		_on_logout_pressed()
	else:
		get_tree().change_scene_to_file("res://scenes/character_select.tscn")


func _on_logout_pressed() -> void:
	Profile.clear_characters()
	Auth.logout()
	Network.stop()
	get_tree().change_scene_to_file("res://scenes/login.tscn")


func _sync_ui_from_avatar() -> void:
	%BodyScaleSlider.value = _avatar.body_scale
	%AbdomenScaleSlider.value = _avatar.abdomen_scale
	%HeadScaleSlider.value = _avatar.head_scale
	%LegLengthSlider.value = _avatar.leg_length
	%ArmLengthSlider.value = _avatar.arm_length
	%EyeSizeSlider.value = _avatar.eye_size
	%EyeSpreadSlider.value = _avatar.eye_spread
	%EyeStalkSlider.value = _avatar.eye_stalk_length
	%MandibleSlider.value = _avatar.mandible_length
	%FangSlider.value = _avatar.fang_length
	%ClawSlider.value = _avatar.claw_size
	%SegmentSlider.value = _avatar.abdomen_segments
	%CrestSlider.value = _avatar.crest_size
	%GlowSlider.value = _avatar.glow_strength
	%SpikeSlider.value = _avatar.spike_amount
	%StanceSlider.value = _avatar.stance_width
	%RoughnessSlider.value = _avatar.chitin_roughness
	%MetallicSlider.value = _avatar.chitin_metallic
	%SpiderLegsSpin.value = _avatar.spider_leg_count
	%EyeCountSpin.value = _avatar.eye_count
	%BodyColorPicker.color = _avatar.body_color
	%AccentColorPicker.color = _avatar.accent_color
	%EyeColorPicker.color = _avatar.eye_color
	%GlowColorPicker.color = _avatar.glow_color


func _random_starter_avatar() -> AvatarData:
	var data := AvatarData.new()
	data.mesh_id = "reference_human"
	var archetype := randi() % 6

	match archetype:
		0:
			_last_archetype = "Neo-Washington-kolonist"
			data.body_scale = randf_range(0.92, 1.08)
		1:
			_last_archetype = "Gatulurare"
			data.body_scale = randf_range(0.88, 1.02)
		2:
			_last_archetype = "Avhoppare"
			data.body_scale = randf_range(0.95, 1.12)
			data.glow_strength = randf_range(0.6, 1.2)
		3:
			_last_archetype = "Kupéarbetare"
			data.body_scale = randf_range(1.0, 1.18)
		4:
			_last_archetype = "Nästflykting"
			data.body_scale = randf_range(0.82, 0.98)
		_:
			_last_archetype = "Zonköpare"
			data.body_scale = randf_range(0.9, 1.15)
			data.glow_strength = randf_range(0.8, 1.6)

	_apply_human_palette(data)
	return data


func _apply_human_palette(data: AvatarData) -> void:
	var palette := randi() % 6
	match palette:
		0:
			data.body_color = Color.from_hsv(randf_range(0.06, 0.12), randf_range(0.25, 0.45), randf_range(0.55, 0.78))
			data.accent_color = Color.from_hsv(randf_range(0.55, 0.65), randf_range(0.35, 0.6), randf_range(0.18, 0.32))
		1:
			data.body_color = Color.from_hsv(randf_range(0.02, 0.08), randf_range(0.2, 0.38), randf_range(0.42, 0.62))
			data.accent_color = Color.from_hsv(randf_range(0.0, 0.05), randf_range(0.15, 0.35), randf_range(0.12, 0.28))
		2:
			data.body_color = Color.from_hsv(randf_range(0.08, 0.14), randf_range(0.3, 0.5), randf_range(0.62, 0.82))
			data.accent_color = Color.from_hsv(randf_range(0.72, 0.82), randf_range(0.4, 0.7), randf_range(0.22, 0.38))
		3:
			data.body_color = Color.from_hsv(randf_range(0.04, 0.1), randf_range(0.18, 0.35), randf_range(0.48, 0.68))
			data.accent_color = Color.from_hsv(randf_range(0.35, 0.5), randf_range(0.25, 0.55), randf_range(0.2, 0.35))
		4:
			data.body_color = Color.from_hsv(randf_range(0.0, 0.06), randf_range(0.12, 0.28), randf_range(0.72, 0.9))
			data.accent_color = Color.from_hsv(randf_range(0.58, 0.68), randf_range(0.45, 0.75), randf_range(0.25, 0.42))
		_:
			data.body_color = Color.from_hsv(randf_range(0.05, 0.12), randf_range(0.22, 0.42), randf_range(0.38, 0.58))
			data.accent_color = Color.from_hsv(randf(), randf_range(0.35, 0.7), randf_range(0.15, 0.35))

	data.eye_color = data.body_color.darkened(randf_range(0.25, 0.45))
	data.glow_color = data.accent_color.lightened(randf_range(0.15, 0.4))
	if data.glow_strength <= 0.0:
		data.glow_strength = randf_range(0.2, 0.9)
