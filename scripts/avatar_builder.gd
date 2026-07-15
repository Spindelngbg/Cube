extends Control

const PREVIEW_SCENE := preload("res://scenes/avatar_preview.tscn")

@onready var preview_holder: Node3D = %PreviewHolder
@onready var status_label: Label = %StatusLabel
@onready var enter_button: Button = %EnterButton
@onready var welcome_label: Label = %WelcomeLabel

var _avatar := AvatarData.new()
var _preview_root: Node3D
var _preview_yaw := 0.0
var _connecting := false


func _ready() -> void:
	SpiderTheme.apply_to(self)
	SpiderTheme.style_title($Layout/Left/TitleBox/Title, 40)
	SpiderTheme.style_subtitle($Layout/Left/TitleBox/Subtitle)
	SpiderTheme.style_status(status_label)

	_setup_welcome()
	_setup_avatar()
	_build_preview()
	_refresh_preview()
	_bind_sliders()

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


func _update_enter_button() -> void:
	if Auth.is_guest:
		enter_button.text = "Gå in i The Cube"
	elif Profile.needs_nest_intro():
		enter_button.text = "Klättra ut i nästet"
	else:
		enter_button.text = "Gå in i The Cube"


func _setup_welcome() -> void:
	if Auth.is_guest:
		welcome_label.text = "Gäst: %s" % Auth.username
	elif Profile.active_character_name != "":
		welcome_label.text = "%s — %s" % [Auth.username, Profile.active_character_name]
	else:
		welcome_label.text = "Välkommen, %s" % Auth.username


func _setup_avatar() -> void:
	if Profile.avatar_ready:
		_avatar = Profile.get_avatar()
	elif Auth.is_guest:
		_avatar = _random_starter_avatar()
	else:
		_avatar = AvatarData.new()


func _process(delta: float) -> void:
	_preview_yaw += delta * 0.45
	if _preview_root:
		_preview_root.rotation.y = _preview_yaw


func _bind_sliders() -> void:
	_connect_slider(%BodyScaleSlider, "body_scale", 0.75, 1.5)
	_connect_slider(%AbdomenScaleSlider, "abdomen_scale", 0.6, 1.6)
	_connect_slider(%HeadScaleSlider, "head_scale", 0.8, 1.4)
	_connect_slider(%LegLengthSlider, "leg_length", 0.7, 1.5)
	_connect_slider(%ArmLengthSlider, "arm_length", 0.6, 1.4)
	_connect_slider(%EyeSizeSlider, "eye_size", 0.4, 2.0)
	_connect_slider(%MandibleSlider, "mandible_length", 0.0, 2.0)
	_connect_slider(%GlowSlider, "glow_strength", 0.0, 2.0)
	_connect_slider(%SpikeSlider, "spike_amount", 0.0, 1.0)
	_connect_slider(%StanceSlider, "stance_width", 0.5, 1.5)
	_connect_slider(%RoughnessSlider, "chitin_roughness", 0.0, 1.0)
	_connect_slider(%MetallicSlider, "chitin_metallic", 0.0, 1.0)

	_connect_spin(%SpiderLegsSpin, "spider_leg_count")
	_connect_spin(%EyeCountSpin, "eye_count")

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


func _connect_spin(spin: SpinBox, prop: String) -> void:
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


func _refresh_preview() -> void:
	if _preview_root:
		SpiderAlienBuilder.build(_preview_root, _avatar)


func _on_enter_pressed() -> void:
	if _connecting:
		return
	Profile.set_avatar(_avatar)
	_connecting = true
	enter_button.disabled = true

	if Auth.is_guest:
		status_label.text = "Ansluter till The Cube..."
		Network.connect_to_world()
	else:
		status_label.text = "Sparar karaktär..."
		Profile.save_active_character(_avatar)


func _on_character_saved() -> void:
	if not _connecting:
		return
	if Profile.needs_nest_intro():
		status_label.text = "Klättrar in i nästet..."
		_connecting = false
		enter_button.disabled = false
		get_tree().change_scene_to_file("res://scenes/nest_room.tscn")
	else:
		status_label.text = "Ansluter till The Cube..."
		Network.connect_to_world()


func _on_profile_error(message: String) -> void:
	if not _connecting:
		return
	_connecting = false
	enter_button.disabled = false
	status_label.text = message


func _on_world_ready() -> void:
	status_label.text = "Går in i världen..."
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_connection_failed(reason: String) -> void:
	_connecting = false
	enter_button.disabled = false
	status_label.text = "Anslutning misslyckades: %s" % reason


func _on_randomize_pressed() -> void:
	_avatar = _random_starter_avatar()
	_sync_ui_from_avatar()
	_refresh_preview()


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
	%MandibleSlider.value = _avatar.mandible_length
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
	data.body_color = Color.from_hsv(randf(), randf_range(0.2, 0.55), randf_range(0.08, 0.2))
	data.accent_color = Color.from_hsv(randf(), randf_range(0.45, 0.9), randf_range(0.15, 0.35))
	data.eye_color = Color.from_hsv(randf_range(0.0, 0.08), 0.9, 1.0)
	data.glow_color = data.eye_color.lightened(0.15)
	data.body_scale = randf_range(0.9, 1.2)
	data.abdomen_scale = randf_range(0.85, 1.25)
	data.head_scale = randf_range(0.9, 1.15)
	data.leg_length = randf_range(0.9, 1.2)
	data.arm_length = randf_range(0.85, 1.2)
	data.spider_leg_count = randi_range(4, 8)
	data.eye_count = randi_range(4, 8)
	data.eye_size = randf_range(0.7, 1.4)
	data.mandible_length = randf_range(0.5, 1.5)
	data.glow_strength = randf_range(0.3, 1.2)
	data.spike_amount = randf_range(0.1, 0.7)
	data.stance_width = randf_range(0.8, 1.2)
	return data