extends Node3D

const MOVE_SPEED := 4.0
const ROOM_SIZE := Vector3(40, 18, 40)
const LEFT_TUNNEL_VISUAL_M := 28.0

const MARKER_COLORS := {
	"satellite_left": Color(0.2, 0.45, 0.95),
	"satellite_top_a": Color(0.95, 0.75, 0.15),
	"satellite_top_b": Color(0.95, 0.55, 0.1),
	"satellite_right": Color(0.85, 0.25, 0.35),
}

@onready var player: CharacterBody3D = $Player
@onready var camera_pivot: Node3D = $CameraPivot
@onready var hint_label: Label = $UI/HintLabel
@onready var secret_panel: PanelContainer = $UI/SecretPanel
@onready var secret_input: LineEdit = $UI/SecretPanel/VBox/CodeInput
@onready var secret_button: Button = $UI/SecretPanel/VBox/RedeemButton
@onready var secret_status: Label = $UI/SecretPanel/VBox/SecretStatus
@onready var confirm_panel: PanelContainer = $UI/ConfirmPanel
@onready var confirm_title: Label = $UI/ConfirmPanel/VBox/ConfirmTitle
@onready var confirm_body: Label = $UI/ConfirmPanel/VBox/ConfirmBody
@onready var confirm_button: Button = $UI/ConfirmPanel/VBox/ConfirmButton
@onready var cancel_button: Button = $UI/ConfirmPanel/VBox/CancelButton
@onready var player_avatar: Node3D = $Player/AvatarPivot

var _elevators: Dictionary = {}
var _active_spawn_id := ""
var _in_elevator_ride := false
var _ride_timer := 0.0
var _ride_duration := 3.0
var _ride_car: Node3D
var _ride_start := Vector3.ZERO
var _ride_end := Vector3.ZERO
var _transitioning := false
var _near_elevator_id := ""


func _ready() -> void:
	_build_room()
	_build_main_cube_preview()
	_build_elevators()
	_build_wayfinding()
	_build_player()
	_style_ui()
	_hide_confirm()

	secret_button.pressed.connect(_on_secret_pressed)
	confirm_button.pressed.connect(_on_confirm_home_pressed)
	cancel_button.pressed.connect(_on_cancel_confirm_pressed)
	Profile.home_spawn_set.connect(_on_home_spawn_set)
	Profile.operation_failed.connect(_on_profile_error)
	Network.world_ready.connect(_on_world_ready)
	Network.connection_failed.connect(_on_connection_failed)

	if Profile.has_home_spawn():
		_enter_world()
		return

	hint_label.text = (
		"Följ de färgade markörerna på golvet (WASD). "
		+ "Blå=vänster tunnel, Gula=trappor norrut, Röd=höger korridor. "
		+ "Stå i markören och tryck [E] för att åka hiss."
	)


func _physics_process(delta: float) -> void:
	if _transitioning:
		return

	if _in_elevator_ride:
		_process_elevator_ride(delta)
		return

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
	camera_pivot.global_position = player.global_position + Vector3(0, 1.4, 0)
	_update_elevator_proximity()


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning or _in_elevator_ride:
		return
	if event.is_action_pressed("interact") and _near_elevator_id != "":
		_start_elevator_ride(_near_elevator_id)


func _build_player() -> void:
	var body := player.get_node_or_null("Body") as MeshInstance3D
	if body:
		body.visible = false
	SpiderAlienBuilder.build(player_avatar, Profile.get_avatar())
	player_avatar.scale = Vector3.ONE * 0.85


func _build_room() -> void:
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.94, 0.92, 0.88)
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.99, 0.97, 0.93)
	wall_mat.emission_enabled = true
	wall_mat.emission = Color(1.0, 0.95, 0.82)
	wall_mat.emission_energy_multiplier = 0.4
	var ceiling_mat := StandardMaterial3D.new()
	ceiling_mat.albedo_color = Color(1.0, 0.98, 0.92)
	ceiling_mat.emission_enabled = true
	ceiling_mat.emission = Color(1.0, 0.92, 0.7)
	ceiling_mat.emission_energy_multiplier = 0.9

	_add_box($Room, Vector3(ROOM_SIZE.x, 0.3, ROOM_SIZE.z), Vector3(0, -0.15, 0), floor_mat)
	_add_box($Room, Vector3(ROOM_SIZE.x, ROOM_SIZE.y, 0.3), Vector3(0, ROOM_SIZE.y * 0.5, -ROOM_SIZE.z * 0.5), wall_mat)
	_add_box($Room, Vector3(0.3, ROOM_SIZE.y, ROOM_SIZE.z), Vector3(-ROOM_SIZE.x * 0.5, ROOM_SIZE.y * 0.5, 0), wall_mat)
	_add_box($Room, Vector3(0.3, ROOM_SIZE.y, ROOM_SIZE.z), Vector3(ROOM_SIZE.x * 0.5, ROOM_SIZE.y * 0.5, 0), wall_mat)
	_add_box($Room, Vector3(ROOM_SIZE.x, 0.2, ROOM_SIZE.z), Vector3(0, ROOM_SIZE.y, 0), ceiling_mat)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.95, 0.82)
	sun.light_energy = 2.0
	sun.rotation_degrees = Vector3(-55, 25, 0)
	$Room.add_child(sun)


func _build_main_cube_preview() -> void:
	var core := Node3D.new()
	core.name = "MainCubePreview"
	core.position = Vector3(0, 1.5, 0)
	$Room.add_child(core)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.58, 0.62)
	mat.metallic = 0.35
	_add_box(core, Vector3(8, 8, 8), Vector3.ZERO, mat)

	var mark := Label3D.new()
	mark.text = "Huvudkub"
	mark.font_size = 48
	mark.position = Vector3(0, 5.5, 0)
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	core.add_child(mark)


func _build_elevators() -> void:
	var specs := [
		{
			"id": "satellite_left",
			"pos": Vector3(-17, 0, -5),
			"label": "Vänster 10 km",
			"lobby_offset": Vector3(1.5, 0, 0),
		},
		{
			"id": "satellite_top_a",
			"pos": Vector3(-7, 0, -17),
			"label": "Topp A",
			"lobby_offset": Vector3(0, 0, 1.5),
		},
		{
			"id": "satellite_top_b",
			"pos": Vector3(7, 0, -17),
			"label": "Topp B",
			"lobby_offset": Vector3(0, 0, 1.5),
		},
		{
			"id": "satellite_right",
			"pos": Vector3(17, 0, 5),
			"label": "Höger",
			"lobby_offset": Vector3(-1.5, 0, 0),
		},
	]

	for spec in specs:
		_build_elevator_port(spec)


func _build_wayfinding() -> void:
	var hub := Vector3(0, 0.02, 0)
	_add_floor_marker(hub, Color(0.92, 0.9, 0.85), 3.5, "START")

	var guides := [
		{"id": "satellite_left", "from": hub, "to": Vector3(-17, 0.02, -5), "label": "← VÄNSTER TUNNEL"},
		{"id": "satellite_top_a", "from": hub, "to": Vector3(-7, 0.02, -17), "label": "↑ TRAPPOR A"},
		{"id": "satellite_top_b", "from": hub, "to": Vector3(7, 0.02, -17), "label": "↑ TRAPPOR B"},
		{"id": "satellite_right", "from": hub, "to": Vector3(17, 0.02, 5), "label": "HÖGER KORRIDOR →"},
	]
	for guide in guides:
		var spawn_id := str(guide.id)
		var color: Color = MARKER_COLORS.get(spawn_id, Color.WHITE)
		_add_path_strip(guide.from, guide.to, color)
		_add_floor_marker(guide.to, color, 5.0, str(guide.label))
		_add_beacon(guide.to + Vector3(0, 0.1, 0), color)


func _build_elevator_port(spec: Dictionary) -> void:
	var spawn_id := str(spec.id)
	var entry := SpawnPoints.get_entry(spawn_id)
	var color: Color = MARKER_COLORS.get(spawn_id, Color.WHITE)
	var root := Node3D.new()
	root.name = "Elevator_%s" % spawn_id
	root.position = spec.pos
	$Elevators.add_child(root)

	var mount := str(entry.get("elevator_mount", ""))
	_build_portal_frame(root, mount, color)
	_build_shaft_for_mount(root, mount, entry, color)

	var car := Node3D.new()
	car.name = "Car"
	root.add_child(car)
	_add_procedural_box(car, Vector3(2.4, 0.12, 2.4), Vector3(0, 0.06, 0), _marker_material(color, 0.35))
	_add_procedural_box(car, Vector3(0.15, 2.2, 2.5), Vector3(0, 1.2, -1.25), _frame_material(color.darkened(0.25)))
	_add_procedural_box(car, Vector3(0.15, 2.2, 2.5), Vector3(0, 1.2, 1.25), _frame_material(color.darkened(0.25)))

	var lobby_zone := Area3D.new()
	lobby_zone.name = "LobbyZone"
	lobby_zone.position = spec.get("lobby_offset", Vector3.ZERO)
	var lobby_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(5.5, 3.5, 5.5)
	lobby_shape.shape = box
	lobby_zone.add_child(lobby_shape)
	root.add_child(lobby_zone)

	var label := Label3D.new()
	var length_text := ""
	if mount == "left":
		length_text = "\n10 km tunnel"
	label.text = "%s%s\n[E] Till %s" % [spec.label, length_text, SpawnPoints.get_spawn_name(spawn_id)]
	label.font_size = 52
	label.modulate = color.darkened(0.55)
	label.outline_modulate = Color(1, 1, 1, 0.9)
	label.position = Vector3(0, 3.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)

	_elevators[spawn_id] = {
		"car": car,
		"lobby_zone": lobby_zone,
		"entry": entry,
	}


func _build_portal_frame(root: Node3D, mount: String, color: Color) -> void:
	var frame_mat := _frame_material(color)
	match mount:
		"left":
			_add_procedural_box(root, Vector3(0.35, 4.5, 4.0), Vector3(-0.2, 2.25, 0), frame_mat)
			_add_procedural_box(root, Vector3(0.35, 4.5, 4.0), Vector3(0.2, 2.25, 0), frame_mat)
			_add_procedural_box(root, Vector3(0.5, 0.5, 4.2), Vector3(0, 4.5, 0), frame_mat)
		"top":
			_add_procedural_box(root, Vector3(4.0, 0.35, 0.35), Vector3(0, 0.2, -0.2), frame_mat)
			_add_procedural_box(root, Vector3(4.0, 0.35, 0.35), Vector3(0, 0.2, 0.2), frame_mat)
			_add_procedural_box(root, Vector3(4.2, 0.5, 0.5), Vector3(0, 0.45, 0), frame_mat)
		"right":
			_add_procedural_box(root, Vector3(0.35, 4.5, 4.0), Vector3(0.2, 2.25, 0), frame_mat)
			_add_procedural_box(root, Vector3(0.35, 4.5, 4.0), Vector3(-0.2, 2.25, 0), frame_mat)
			_add_procedural_box(root, Vector3(0.5, 0.5, 4.2), Vector3(0, 4.5, 0), frame_mat)


func _build_shaft_for_mount(root: Node3D, mount: String, _entry: Dictionary, color: Color) -> void:
	var tunnel_mat := _tunnel_material(color)
	var stripe_mat := _marker_material(color, 1.4)
	match mount:
		"left":
			_add_procedural_box(
				root,
				Vector3(LEFT_TUNNEL_VISUAL_M, 3.2, 3.6),
				Vector3(-LEFT_TUNNEL_VISUAL_M * 0.5 - 1.0, 1.6, 0),
				tunnel_mat
			)
			for i in 6:
				var z_off := -1.2 + i * 0.48
				_add_procedural_box(
					root,
					Vector3(LEFT_TUNNEL_VISUAL_M - 2.0, 0.12, 0.35),
					Vector3(-LEFT_TUNNEL_VISUAL_M * 0.5, 0.3, z_off),
					stripe_mat
				)
			_add_shaft_label(root, "10 km TUNNEL", Vector3(-LEFT_TUNNEL_VISUAL_M * 0.5, 3.8, 0), color)
			for i in 4:
				SpaceKitLibrary.spawn(root, "corridor-wide", Vector3(-3.0 - i * 4.0, 0, 0), PI * 0.5)
		"top":
			for step in 10:
				var rise := float(step) * 0.55
				var depth := -2.5 - float(step) * 1.4
				_add_procedural_box(
					root,
					Vector3(3.2, 0.28, 1.6),
					Vector3(0, rise + 0.14, depth),
					tunnel_mat
				)
				_add_procedural_box(
					root,
					Vector3(3.0, 0.08, 0.25),
					Vector3(0, rise + 0.32, depth - 0.5),
					stripe_mat
				)
			_add_shaft_label(root, "TRAPPA UPP", Vector3(0, 5.5, -8), color)
			for i in 5:
				SpaceKitLibrary.spawn(root, "stairs", Vector3(0, i * 1.1, -2.0 - i * 1.6))
		"right":
			_add_procedural_box(
				root,
				Vector3(20.0, 3.0, 3.2),
				Vector3(11.0, 1.5, 0),
				tunnel_mat
			)
			for i in 5:
				_add_procedural_box(
					root,
					Vector3(18.0, 0.1, 0.3),
					Vector3(3.0 + i * 3.2, 0.25, 0),
					stripe_mat
				)
			_add_shaft_label(root, "KORRIDOR", Vector3(10.0, 3.5, 0), color)
			for i in 4:
				SpaceKitLibrary.spawn(root, "corridor", Vector3(3.0 + i * 4.0, 0, 0), -PI * 0.5)


func _update_elevator_proximity() -> void:
	_near_elevator_id = ""
	for spawn_id in _elevators.keys():
		var data: Dictionary = _elevators[spawn_id]
		var zone := data.lobby_zone as Area3D
		if zone and zone.overlaps_body(player):
			_near_elevator_id = spawn_id
			var entry: Dictionary = data.entry
			var mount := str(entry.get("elevator_mount", ""))
			var extra := ""
			if mount == "left":
				extra = " (10 km)"
			hint_label.text = (
				"%s%s — tryck [E]. Enda förbindelse till en 30×30×30 km satellitkub."
				% [SpawnPoints.get_spawn_name(spawn_id), extra]
			)
			return

	if not confirm_panel.visible:
		hint_label.text = (
			"Följ färgstråken på golvet. Blå vänster, gul norr (trappor), röd höger. "
			+ "Stå på den stora färgade plattan och tryck [E]."
		)


func _start_elevator_ride(spawn_id: String) -> void:
	if not SpawnPoints.is_valid(spawn_id):
		return

	var entry := SpawnPoints.get_entry(spawn_id)
	_in_elevator_ride = true
	_active_spawn_id = spawn_id
	_ride_car = _elevators[spawn_id].car as Node3D
	_ride_timer = 0.0
	_ride_duration = float(entry.get("ride_duration", 3.2))
	_ride_start = _ride_car.position
	_ride_end = _ride_target_for_entry(entry)
	player.velocity = Vector3.ZERO
	hint_label.text = "Hissen åker mot %s..." % SpawnPoints.get_spawn_name(spawn_id)


func _ride_target_for_entry(entry: Dictionary) -> Vector3:
	match str(entry.get("ride_axis", "")):
		"horizontal_neg":
			return Vector3(-LEFT_TUNNEL_VISUAL_M, 0.0, 0.0)
		"horizontal_pos":
			return Vector3(18.0, 0.0, 0.0)
		_:
			return Vector3(0.0, 12.0, 0.0)


func _process_elevator_ride(delta: float) -> void:
	_ride_timer += delta
	var t := clampf(_ride_timer / _ride_duration, 0.0, 1.0)
	var eased := t * t * (3.0 - 2.0 * t)
	_ride_car.position = _ride_start.lerp(_ride_end, eased)
	player.global_position = _ride_car.global_position + Vector3(0, 0.6, 0)

	if t >= 1.0:
		_in_elevator_ride = false
		_show_confirm(_active_spawn_id)


func _show_confirm(spawn_id: String) -> void:
	confirm_title.text = "Bo i %s?" % SpawnPoints.get_spawn_name(spawn_id)
	confirm_body.text = (
		"%s\n\nSatellitkub: 30×30×30 km.\n"
		+ "Enda förbindelsen till huvudkuben är hissarna.\n"
		+ "Detta blir ditt permanenta hem — även om du blir hemlös senare."
		% SpawnPoints.get_description(spawn_id)
	)
	confirm_panel.visible = true


func _hide_confirm() -> void:
	confirm_panel.visible = false
	_active_spawn_id = ""


func _on_confirm_home_pressed() -> void:
	if _active_spawn_id == "" or _transitioning:
		return
	_transitioning = true
	confirm_button.disabled = true
	cancel_button.disabled = true
	hint_label.text = "Registrerar ditt hem i satellitkuben..."
	Profile.set_home_spawn(_active_spawn_id, "elevator")


func _on_cancel_confirm_pressed() -> void:
	if _ride_car:
		_ride_car.position = Vector3.ZERO
	_hide_confirm()
	player.position = Vector3(0, 0.6, 4)


func _on_secret_pressed() -> void:
	if _transitioning:
		return
	var code := secret_input.text.strip_edges()
	if code == "":
		secret_status.text = "Skriv in en hemlig kod."
		return
	_transitioning = true
	secret_button.disabled = true
	secret_status.text = "Kontrollerar kod..."
	Profile.redeem_secret_code(code)


func _on_home_spawn_set(spawn_id: String) -> void:
	_hide_confirm()
	secret_status.text = "Hem: %s (%s)" % [SpawnPoints.get_spawn_name(spawn_id), SpawnPoints.get_cube_id(spawn_id)]
	hint_label.text = "Ditt hem i satellitkuben är låst. Går in..."
	_enter_world()


func _on_profile_error(message: String) -> void:
	_transitioning = false
	confirm_button.disabled = false
	cancel_button.disabled = false
	secret_button.disabled = false
	secret_status.text = message
	hint_label.text = message


func _enter_world() -> void:
	Network.connect_to_world()


func _on_world_ready() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_connection_failed(reason: String) -> void:
	_transitioning = false
	hint_label.text = "Anslutning misslyckades: %s" % reason


func _style_ui() -> void:
	SpiderTheme.apply_to(secret_panel)
	SpiderTheme.apply_to(confirm_panel)
	SpiderTheme.style_status(hint_label)
	SpiderTheme.wrap_label_in_panel(hint_label)
	hint_label.offset_right = 900.0
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _add_floor_marker(pos: Vector3, color: Color, radius: float, text: String) -> void:
	var mat := _marker_material(color, 0.85)
	_add_procedural_box($Room, Vector3(radius * 2.0, 0.06, radius * 2.0), pos, mat)

	var label := Label3D.new()
	label.text = text
	label.font_size = 40
	label.modulate = color.darkened(0.5)
	label.outline_modulate = Color(1, 1, 1, 0.95)
	label.position = pos + Vector3(0, 1.8, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	$Room.add_child(label)


func _add_path_strip(from: Vector3, to: Vector3, color: Color) -> void:
	var delta := to - from
	var length := delta.length()
	if length < 0.5:
		return
	var mid := from + delta * 0.5
	var mat := _marker_material(color, 0.55)
	var strip := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(maxf(absf(delta.x), 1.2), 0.05, maxf(absf(delta.z), 1.2))
	if absf(delta.x) > absf(delta.z):
		mesh.size = Vector3(length, 0.05, 1.4)
	else:
		mesh.size = Vector3(1.4, 0.05, length)
	strip.mesh = mesh
	strip.material_override = mat
	strip.position = mid
	$Room.add_child(strip)


func _add_beacon(pos: Vector3, color: Color) -> void:
	var pillar := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.18
	mesh.bottom_radius = 0.22
	mesh.height = 5.5
	pillar.mesh = mesh
	pillar.material_override = _marker_material(color, 1.1)
	pillar.position = pos + Vector3(0, 2.75, 0)
	$Room.add_child(pillar)

	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 2.2
	light.omni_range = 9.0
	light.position = pos + Vector3(0, 4.5, 0)
	$Room.add_child(light)


func _add_shaft_label(parent: Node3D, text: String, pos: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.modulate = color
	label.outline_modulate = Color(1, 1, 1)
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)


func _add_procedural_box(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.position = pos
	mesh_inst.material_override = material
	parent.add_child(mesh_inst)
	return mesh_inst


func _marker_material(color: Color, emission_strength: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = emission_strength
	mat.roughness = 0.35
	return mat


func _frame_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color.darkened(0.15)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	mat.metallic = 0.2
	return mat


func _tunnel_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color.darkened(0.55)
	mat.emission_enabled = true
	mat.emission = color.darkened(0.2)
	mat.emission_energy_multiplier = 0.35
	mat.roughness = 0.7
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