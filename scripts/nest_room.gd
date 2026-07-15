extends Node3D

const SMALL_SPIDER_SCENE := preload("res://scenes/nest_small_spider.tscn")
const MOVE_SPEED := 4.0
const ROOM_SIZE := Vector3(14, 4.2, 12)

const INTRO_LINES := [
	"Du vaknar i mörker — varmt, vått, levande.",
	"Något stort vakar över dig. Det andas långsamt.",
	"Framför dig: ett sken. En dörr av ljus.",
]
const WHISPER_LINES := [
	"Den vakar inte längre. Den släpper dig.",
	"Gå mot ljuset, unge.",
	"Kuben väntar på andra sidan.",
]

@onready var player: CharacterBody3D = $Player
@onready var camera_pivot: Node3D = $CameraPivot
@onready var door_zone: Area3D = $DoorZone
@onready var hint_label: Label = $UI/HintLabel
@onready var mother_pivot: Node3D = $MotherPivot
@onready var egg_pivot: Node3D = $EggPivot
@onready var spiders_root: Node3D = $Spiders
@onready var door_light: OmniLight3D = $DoorLight
@onready var door_spot: SpotLight3D = $DoorSpot
@onready var egg_flicker: OmniLight3D = $EggFlicker
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var player_avatar: Node3D = $Player/AvatarPivot

var _transitioning := false
var _spawn_timer := 0.0
var _egg_pulse := 0.0
var _mother_anim := 0.0
var _intro_index := 0
var _intro_timer := 0.0
var _door_glow := 2.4
var _fog_density := 0.045


func _ready() -> void:
	_build_room()
	_build_door()
	_build_mother()
	_build_egg()
	_build_player_spider()
	_style_ui()
	_fog_density = world_env.environment.fog_density
	door_zone.body_entered.connect(_on_door_entered)
	Profile.nest_intro_completed.connect(_on_nest_saved)
	Profile.operation_failed.connect(_on_nest_failed)
	_begin_intro()


func _begin_intro() -> void:
	hint_label.text = ""
	_intro_index = 0
	_intro_timer = 0.0
	SceneTransition.fade_in(1.1)


func _physics_process(delta: float) -> void:
	if _transitioning:
		return

	_advance_intro(delta)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (camera_pivot.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction.y = 0

	if direction != Vector3.ZERO:
		player.velocity.x = direction.x * MOVE_SPEED
		player.velocity.z = direction.z * MOVE_SPEED
		player.rotation.y = atan2(direction.x, direction.z)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, MOVE_SPEED)
		player.velocity.z = move_toward(player.velocity.z, 0, MOVE_SPEED)

	player.move_and_slide()
	camera_pivot.global_position = player.global_position + Vector3(0, 1.2, 0)

	_animate_nest(delta)
	_spawn_spiders(delta)
	_update_door_beckon()


func _advance_intro(delta: float) -> void:
	if _intro_index >= INTRO_LINES.size():
		return
	_intro_timer += delta
	if _intro_timer < 2.2:
		return
	_intro_timer = 0.0
	hint_label.text = INTRO_LINES[_intro_index]
	_intro_index += 1


func _update_door_beckon() -> void:
	var door_pos := door_zone.global_position
	var dist := player.global_position.distance_to(door_pos)
	var nearness := clampf(1.0 - dist / 9.0, 0.0, 1.0)
	_door_glow = lerpf(2.4, 6.5, nearness)
	door_light.light_energy = _door_glow
	door_spot.light_energy = lerpf(3.5, 8.0, nearness)

	if nearness > 0.55 and _intro_index >= INTRO_LINES.size():
		hint_label.text = "Ljuset kallar — gå igenom dörren."


func _animate_nest(delta: float) -> void:
	_egg_pulse += delta * 2.2
	_mother_anim += delta

	var pulse := 1.0 + sin(_egg_pulse) * 0.08
	egg_pivot.scale = Vector3.ONE * pulse
	egg_pivot.rotation.y += delta * 0.35
	egg_flicker.light_energy = 0.45 + sin(_egg_pulse * 1.6) * 0.25

	mother_pivot.rotation.y = sin(_mother_anim * 0.7) * 0.12
	var head := mother_pivot.get_node_or_null("Pivot/Hips/HeadPivot")
	if head:
		head.rotation.x = -0.25 + sin(_mother_anim * 1.4) * 0.18
		head.rotation.z = sin(_mother_anim * 0.9) * 0.1


func _spawn_spiders(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0:
		return
	_spawn_timer = randf_range(0.15, 0.55)

	if spiders_root.get_child_count() >= 28:
		return

	var spider := SMALL_SPIDER_SCENE.instantiate()
	var offset := Vector3(randf_range(-0.35, 0.35), 0.2, randf_range(-0.2, 0.35))
	spiders_root.add_child(spider)
	spider.setup(egg_pivot.global_position + offset, 5.8)


func _style_ui() -> void:
	SpiderTheme.style_status(hint_label)
	SpiderTheme.wrap_label_in_panel(hint_label)


func _build_player_spider() -> void:
	var body := player.get_node_or_null("Body") as MeshInstance3D
	if body:
		body.visible = false
	SpiderAlienBuilder.build(player_avatar, Profile.get_avatar())
	player_avatar.scale = Vector3.ONE * 0.85


func _build_door() -> void:
	var frame_mat := RetroTextureLibrary.make_nest_material(
		"wall_brick_small_stone",
		Vector2(2.5, 2.5),
		Color(0.2, 0.18, 0.16),
		0.9
	)
	var light_mat := StandardMaterial3D.new()
	light_mat.albedo_color = Color(0.95, 0.88, 0.65)
	light_mat.emission_enabled = true
	light_mat.emission = Color(1.0, 0.92, 0.7)
	light_mat.emission_energy_multiplier = 2.2

	_add_box($DoorFrame, Vector3(1.2, 3.4, 0.35), Vector3(-2.1, 0, 0), frame_mat)
	_add_box($DoorFrame, Vector3(1.2, 3.4, 0.35), Vector3(2.1, 0, 0), frame_mat)
	_add_box($DoorFrame, Vector3(4.6, 0.5, 0.35), Vector3(0, 1.75, 0), frame_mat)

	var glow := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(3.2, 3.0)
	glow.mesh = plane
	glow.material_override = light_mat
	glow.position = Vector3(0, 0, 0.6)
	$DoorFrame.add_child(glow)


func _build_room() -> void:
	var floor_mat := RetroTextureLibrary.make_nest_material(
		"floor_stone_pattern",
		Vector2(6, 6),
		Color(0.3, 0.28, 0.26),
		0.92
	)
	var wall_mat := RetroTextureLibrary.make_nest_material(
		"wall_brick_stone_center",
		Vector2(3, 3),
		Color(0.24, 0.22, 0.2),
		0.9
	)
	var ceiling_mat := RetroTextureLibrary.make_nest_material(
		"wall_stone",
		Vector2(4, 4),
		Color(0.16, 0.15, 0.14),
		0.95
	)

	_add_box($Room, Vector3(ROOM_SIZE.x, 0.35, ROOM_SIZE.z), Vector3(0, -0.17, 0), floor_mat)
	_add_box($Room, Vector3(ROOM_SIZE.x, ROOM_SIZE.y, 0.35), Vector3(0, ROOM_SIZE.y * 0.5, -ROOM_SIZE.z * 0.5), wall_mat)
	_add_box($Room, Vector3(0.35, ROOM_SIZE.y, ROOM_SIZE.z), Vector3(-ROOM_SIZE.x * 0.5, ROOM_SIZE.y * 0.5, 0), wall_mat)
	_add_box($Room, Vector3(0.35, ROOM_SIZE.y, ROOM_SIZE.z), Vector3(ROOM_SIZE.x * 0.5, ROOM_SIZE.y * 0.5, 0), wall_mat)
	_add_box($Room, Vector3(ROOM_SIZE.x, 0.25, ROOM_SIZE.z), Vector3(0, ROOM_SIZE.y, 0), ceiling_mat)

	var front_z := ROOM_SIZE.z * 0.5
	_add_box($Room, Vector3(4.5, ROOM_SIZE.y, 0.35), Vector3(-4.75, ROOM_SIZE.y * 0.5, front_z), wall_mat)
	_add_box($Room, Vector3(4.5, ROOM_SIZE.y, 0.35), Vector3(4.75, ROOM_SIZE.y * 0.5, front_z), wall_mat)
	_add_box($Room, Vector3(3.5, 0.8, 0.35), Vector3(0, ROOM_SIZE.y - 0.4, front_z), wall_mat)

	for i in 16:
		var drip := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = randf_range(0.02, 0.06)
		mesh.bottom_radius = mesh.top_radius * 0.4
		mesh.height = randf_range(0.4, 1.4)
		drip.mesh = mesh
		drip.material_override = _slime_material(Color(0.12, 0.22, 0.08), 0.1, 0.25)
		drip.position = Vector3(randf_range(-6, 6), ROOM_SIZE.y - randf_range(0.1, 0.8), randf_range(-5, 5))
		$Room.add_child(drip)

	for i in 10:
		var puddle := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = randf_range(0.25, 0.9)
		mesh.bottom_radius = mesh.top_radius
		mesh.height = 0.04
		puddle.mesh = mesh
		puddle.material_override = _slime_material(Color(0.1, 0.18, 0.06), 0.05, 0.35)
		puddle.position = Vector3(randf_range(-5.5, 5.5), 0.03, randf_range(-4.5, 4.5))
		$Room.add_child(puddle)


func _build_mother() -> void:
	var data := AvatarData.new()
	data.body_color = Color(0.1, 0.12, 0.08)
	data.accent_color = Color(0.35, 0.05, 0.1)
	data.eye_color = Color(0.9, 0.15, 0.2)
	data.glow_color = Color(0.7, 0.1, 0.18)
	data.body_scale = 1.45
	data.abdomen_scale = 1.6
	data.head_scale = 1.2
	data.leg_length = 1.3
	data.arm_length = 1.35
	data.spider_leg_count = 8
	data.eye_count = 8
	data.eye_size = 1.5
	data.mandible_length = 1.6
	data.glow_strength = 1.4
	data.spike_amount = 0.65
	data.stance_width = 1.25
	data.chitin_roughness = 0.35
	data.chitin_metallic = 0.25

	var pivot := Node3D.new()
	pivot.name = "Pivot"
	mother_pivot.add_child(pivot)
	SpiderAlienBuilder.build(pivot, data)
	mother_pivot.position = Vector3(0, 0, -3.2)
	mother_pivot.rotation_degrees = Vector3(0, 180, 0)


func _build_egg() -> void:
	var shell_mat := StandardMaterial3D.new()
	shell_mat.albedo_color = Color(0.18, 0.22, 0.1)
	shell_mat.roughness = 0.2
	shell_mat.emission_enabled = true
	shell_mat.emission = Color(0.35, 0.55, 0.12)
	shell_mat.emission_energy_multiplier = 0.8

	var egg := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.55
	mesh.height = 1.1
	egg.mesh = mesh
	egg.material_override = shell_mat
	egg.scale = Vector3(0.9, 1.15, 0.9)
	egg_pivot.add_child(egg)
	egg_pivot.position = Vector3(0, 0.55, -1.6)

	var glow := OmniLight3D.new()
	glow.light_color = Color(0.4, 0.75, 0.2)
	glow.light_energy = 1.2
	glow.omni_range = 3.5
	egg_pivot.add_child(glow)


func _slime_material(color: Color, roughness: float, emission_strength: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = 0.05
	mat.emission_enabled = emission_strength > 0.01
	mat.emission = Color(color.r * 0.5, color.g * 0.8, color.b * 0.3)
	mat.emission_energy_multiplier = emission_strength
	return mat


func _add_box(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.material_override = material
	body.add_child(mesh_inst)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)

	body.position = pos
	parent.add_child(body)


func _on_door_entered(body: Node3D) -> void:
	if _transitioning or body != player:
		return
	_play_hatching_cinematic()


func _play_hatching_cinematic() -> void:
	_transitioning = true
	player.velocity = Vector3.ZERO
	hint_label.text = WHISPER_LINES[0]

	for i in 10:
		var spider := SMALL_SPIDER_SCENE.instantiate()
		spiders_root.add_child(spider)
		spider.setup(egg_pivot.global_position + Vector3(randf_range(-0.2, 0.2), 0.15, randf_range(-0.2, 0.2)), 7.0)

	var env := world_env.environment
	var tween := create_tween().set_parallel(true)
	tween.tween_property(door_light, "light_energy", 14.0, 1.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(door_spot, "light_energy", 18.0, 1.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(env, "fog_density", 0.0, 1.6)
	tween.tween_property(egg_pivot, "scale", Vector3(1.35, 1.55, 1.35), 0.5)
	tween.chain().tween_property(egg_pivot, "scale", Vector3.ZERO, 0.35)

	var cam_tween := create_tween()
	cam_tween.tween_property(camera_pivot, "position:z", player.global_position.z + 2.5, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	SceneTransition.pulse_vignette(0.35, 1.5)

	await get_tree().create_timer(1.0).timeout
	hint_label.text = WHISPER_LINES[1]
	await get_tree().create_timer(0.8).timeout
	hint_label.text = "Ljuset slukar dig — välkommen till The Cube..."
	await get_tree().create_timer(0.6).timeout
	Profile.complete_nest_intro()


func _on_nest_saved() -> void:
	hint_label.text = WHISPER_LINES[2]
	await SceneTransition.white_flash_then_scene("res://scenes/emergence_room.tscn")


func _on_nest_failed(message: String) -> void:
	_transitioning = false
	hint_label.text = message