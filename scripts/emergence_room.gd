extends Node3D

const Lore = preload("res://scripts/story/shawshank_lore.gd")
const StoryInteractableScript = preload("res://scripts/story/story_interactable.gd")
const StoryToastUIScript = preload("res://scripts/ui/story_toast_ui.gd")
const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")
const ThreadedLoaderScript = preload("res://scripts/loading/threaded_loader.gd")
const CityKitLibraryScript = preload("res://scripts/assets/city_kit_library.gd")
const SpaceKitLibraryScript = preload("res://scripts/assets/space_kit_library.gd")

const MOVE_SPEED := 4.0
const ROOM_SIZE := Vector3(40, 18, 40)
const ELEVATOR_RED := Color(1.0, 0.04, 0.08)
const HUB_COLOR := Color(0.92, 0.9, 0.85)
const DOOR_OPEN_SPEED := 3.5
const RIDE_HEIGHT_M := 14.0
const CAB_SIZE := Vector3(2.6, 2.8, 2.4)

const ELEVATOR_SPECS := [
	{"id": "satellite_left", "pos": Vector3(-8.0, 0.0, 2.0), "yaw": PI * 0.5},
	{"id": "satellite_top_a", "pos": Vector3(-2.5, 0.0, -7.0), "yaw": 0.0},
	{"id": "satellite_top_b", "pos": Vector3(2.5, 0.0, -7.0), "yaw": 0.0},
	{"id": "satellite_right", "pos": Vector3(8.0, 0.0, 2.0), "yaw": -PI * 0.5},
]

const MARKER_COLORS := {
	"satellite_left": ELEVATOR_RED,
	"satellite_top_a": ELEVATOR_RED,
	"satellite_top_b": ELEVATOR_RED,
	"satellite_right": ELEVATOR_RED,
}

@onready var player: CharacterBody3D = $Player
@onready var camera_pivot: Node3D = $CameraPivot
var _hint_label: Label
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
var _inside_elevator_id := ""
var _connect_watchdog: SceneTreeTimer


func _ready() -> void:
	_hint_label = get_node_or_null("UI/HintLabel") as Label
	_setup_environment()
	_build_room()
	_build_main_cube_preview()
	_build_elevators()
	_build_wayfinding()
	_build_story_clues()
	GuiFontLibrary.fix_label3d_tree(self)
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

	MouseLook.activate(camera_pivot, camera_pivot.get_node("Camera3D") as Camera3D)
	secret_input.release_focus()

	if Profile.has_home_spawn():
		call_deferred("_redirect_to_play_scene")
		return

	if not Profile.needs_home_selection():
		call_deferred("_redirect_to_play_scene")
		return

	_set_hint(
		"Fyra hissar runt dig — Hiss 1–4 leder till Koloni 1–4 (%s). "
		% SpawnPoints.get_extent_label()
		+ "I kolonin får du en snabbguide (H) om zoner, Mydrillium och markörer. "
		+ "Läs SRC-memot vid väggen. Gå nära en hiss, gå in och tryck [E]."
	)


func _redirect_to_play_scene() -> void:
	get_tree().change_scene_to_file(GameFlow.play_scene_path())


func _exit_tree() -> void:
	MouseLook.deactivate()


func _physics_process(delta: float) -> void:
	if _transitioning:
		return

	if _in_elevator_ride:
		_process_elevator_ride(delta)
		return

	if not player.is_on_floor():
		player.velocity.y -= 18.0 * delta
	else:
		player.velocity.y = 0.0

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3.ZERO
	if MouseLook.is_active():
		direction = MouseLook.get_flat_direction(input_dir)
	elif input_dir != Vector2.ZERO:
		direction = (camera_pivot.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y))
		direction.y = 0.0
		direction = direction.normalized()

	if direction != Vector3.ZERO:
		player.velocity.x = direction.x * MOVE_SPEED
		player.velocity.z = direction.z * MOVE_SPEED
		if MouseLook.is_active():
			player.rotation.y = MouseLook.get_yaw()
		else:
			player.rotation.y = atan2(direction.x, direction.z)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, MOVE_SPEED)
		player.velocity.z = move_toward(player.velocity.z, 0, MOVE_SPEED)

	player.move_and_slide()
	camera_pivot.global_position = player.global_position + Vector3(0, 1.4, 0)
	_update_elevators(delta)


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning or _in_elevator_ride:
		return
	if event.is_action_pressed("interact"):
		for node in get_tree().get_nodes_in_group("story_interactable"):
			if node.has_method("is_player_nearby") and node.is_player_nearby():
				node.trigger()
				return
	if event.is_action_pressed("interact") and _inside_elevator_id != "":
		_start_elevator_ride(_inside_elevator_id)


func _build_player() -> void:
	player.position = Vector3(0.0, 1.0, 3.5)
	player.velocity = Vector3.ZERO
	var body := player.get_node_or_null("Body") as MeshInstance3D
	if body:
		body.visible = false
	var collision := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision:
		collision.position = Vector3(0.0, 1.0, 0.0)
	var model := HumanAvatarBuilder.build(player_avatar, Profile.get_avatar())
	if model:
		var animator := HumanAvatarAnimator.ensure_on(player_avatar, true)
		animator.bind(model)
	camera_pivot.global_position = player.global_position + Vector3(0, 1.4, 0)


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
	sun.light_energy = 2.4
	sun.shadow_enabled = false
	sun.rotation_degrees = Vector3(-50, 30, 0)
	$Room.add_child(sun)

	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 10, 0)
	fill.light_color = Color(1.0, 0.96, 0.88)
	fill.light_energy = 1.8
	fill.omni_range = 45.0
	$Room.add_child(fill)

	var ceiling_fill := OmniLight3D.new()
	ceiling_fill.position = Vector3(0, ROOM_SIZE.y - 1.0, 0)
	ceiling_fill.light_color = Color(1.0, 0.98, 0.92)
	ceiling_fill.light_energy = 2.5
	ceiling_fill.omni_range = 38.0
	$Room.add_child(ceiling_fill)


func _build_main_cube_preview() -> void:
	var core := Node3D.new()
	core.name = "MainCubePreview"
	core.position = Vector3(0, 1.5, 0)
	$Room.add_child(core)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.58, 0.62)
	mat.metallic = 0.35
	_add_procedural_box(core, Vector3(8, 8, 8), Vector3.ZERO, mat)

	var mark := Label3D.new()
	mark.text = "Huvudkub"
	mark.font_size = 48
	mark.position = Vector3(0, 5.5, 0)
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	core.add_child(mark)


func _build_elevators() -> void:
	for spec in ELEVATOR_SPECS:
		_build_elevator_unit(spec)


func _build_story_clues() -> void:
	var board := Label3D.new()
	board.text = (
		"LÄCKT ANSLAG — %s\nProjekt Redemption: robot + spindel + människa\nMisslyckad synk = hybridzombie\n[E] Läs hela memot"
		% Lore.COMPANY_NAME
	)
	board.font_size = 42
	board.modulate = Color(0.95, 0.25, 0.2)
	board.position = Vector3(-12.0, 3.2, -10.0)
	board.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	$Room.add_child(board)

	var area := StoryInteractableScript.new()
	area.interact_id = "src_leaked_memo"
	area.prompt_text = "Läs läckt SRC-memo [E]"
	area.position = Vector3(-12.0, 1.5, -10.0)
	$Room.add_child(area)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.5, 3.0, 2.5)
	shape.shape = box
	area.add_child(shape)

	$UI.add_child(StoryToastUIScript.new())


func _build_wayfinding() -> void:
	var hub := Vector3(0, 0.02, 2.0)
	_add_floor_marker(hub, HUB_COLOR, 2.8, "START")

	for spec in ELEVATOR_SPECS:
		var spawn_id := str(spec.id)
		var dest: Vector3 = spec.pos + Vector3(0, 0.02, 0)
		var elevator_label := SpawnPoints.get_elevator_label(spawn_id)
		_add_path_strip(hub, dest, ELEVATOR_RED)
		_add_floor_marker(dest, ELEVATOR_RED, 3.2, elevator_label)
		_add_beacon(dest + Vector3(0, 0.1, 0), ELEVATOR_RED)


func _build_elevator_unit(spec: Dictionary) -> void:
	var spawn_id := str(spec.id)
	var entry := SpawnPoints.get_entry(spawn_id)
	var elevator_label := SpawnPoints.get_elevator_label(spawn_id)
	var color := ELEVATOR_RED

	var root := Node3D.new()
	root.name = "Elevator_%s" % spawn_id
	root.position = spec.pos
	root.rotation.y = float(spec.get("yaw", 0.0))
	$Elevators.add_child(root)

	var shaft_mat := _frame_material(color.darkened(0.15))
	_add_procedural_box(root, Vector3(CAB_SIZE.x + 0.5, CAB_SIZE.y + 1.0, 0.25), Vector3(0, CAB_SIZE.y * 0.5, -1.35), shaft_mat)
	_add_procedural_box(root, Vector3(0.2, CAB_SIZE.y + 1.0, CAB_SIZE.z + 0.6), Vector3(-CAB_SIZE.x * 0.5 - 0.1, CAB_SIZE.y * 0.5, 0), shaft_mat)
	_add_procedural_box(root, Vector3(0.2, CAB_SIZE.y + 1.0, CAB_SIZE.z + 0.6), Vector3(CAB_SIZE.x * 0.5 + 0.1, CAB_SIZE.y * 0.5, 0), shaft_mat)
	_add_procedural_box(root, Vector3(CAB_SIZE.x + 0.5, 0.25, CAB_SIZE.z + 0.6), Vector3(0, CAB_SIZE.y + 0.12, 0), shaft_mat)

	var car := Node3D.new()
	car.name = "Car"
	root.add_child(car)

	var floor_mat := _marker_material(color, 1.2)
	var wall_mat := _frame_material(color)
	_add_procedural_box(car, Vector3(CAB_SIZE.x, 0.12, CAB_SIZE.z), Vector3(0, 0.06, 0), floor_mat)
	_add_procedural_box(car, Vector3(0.12, CAB_SIZE.y, CAB_SIZE.z), Vector3(-CAB_SIZE.x * 0.5 + 0.06, CAB_SIZE.y * 0.5, 0), wall_mat)
	_add_procedural_box(car, Vector3(0.12, CAB_SIZE.y, CAB_SIZE.z), Vector3(CAB_SIZE.x * 0.5 - 0.06, CAB_SIZE.y * 0.5, 0), wall_mat)
	_add_procedural_box(car, Vector3(CAB_SIZE.x, CAB_SIZE.y, 0.12), Vector3(0, CAB_SIZE.y * 0.5, -CAB_SIZE.z * 0.5 + 0.06), wall_mat)

	var left_door := MeshInstance3D.new()
	left_door.name = "LeftDoor"
	var left_mesh := BoxMesh.new()
	left_mesh.size = Vector3(1.15, CAB_SIZE.y - 0.1, 0.14)
	left_door.mesh = left_mesh
	left_door.material_override = _marker_material(Color(0.85, 0.02, 0.05), 2.0)
	left_door.position = Vector3(-0.58, CAB_SIZE.y * 0.5, CAB_SIZE.z * 0.5)
	car.add_child(left_door)

	var right_door := MeshInstance3D.new()
	right_door.name = "RightDoor"
	var right_mesh := BoxMesh.new()
	right_mesh.size = Vector3(1.15, CAB_SIZE.y - 0.1, 0.14)
	right_door.mesh = right_mesh
	right_door.material_override = _marker_material(Color(0.85, 0.02, 0.05), 2.0)
	right_door.position = Vector3(0.58, CAB_SIZE.y * 0.5, CAB_SIZE.z * 0.5)
	car.add_child(right_door)

	var cab_light := OmniLight3D.new()
	cab_light.light_color = Color(1.0, 0.35, 0.3)
	cab_light.light_energy = 1.4
	cab_light.position = Vector3(0, CAB_SIZE.y - 0.2, 0)
	car.add_child(cab_light)

	var lobby_zone := Area3D.new()
	lobby_zone.name = "LobbyZone"
	lobby_zone.position = Vector3(0, 1.4, 2.2)
	var lobby_shape := CollisionShape3D.new()
	var lobby_box := BoxShape3D.new()
	lobby_box.size = Vector3(4.5, 3.2, 4.5)
	lobby_shape.shape = lobby_box
	lobby_zone.add_child(lobby_shape)
	root.add_child(lobby_zone)

	var cab_zone := Area3D.new()
	cab_zone.name = "CabZone"
	cab_zone.position = Vector3(0, 1.2, 0.2)
	var cab_shape := CollisionShape3D.new()
	var cab_box := BoxShape3D.new()
	cab_box.size = Vector3(CAB_SIZE.x - 0.2, CAB_SIZE.y - 0.2, CAB_SIZE.z - 0.2)
	cab_shape.shape = cab_box
	cab_zone.add_child(cab_shape)
	car.add_child(cab_zone)

	var panel := Label3D.new()
	panel.text = "%s\n%s\n[E] inne i hissen" % [elevator_label, SpawnPoints.get_extent_label()]
	panel.font_size = 52
	panel.modulate = Color(1.0, 0.2, 0.22)
	panel.outline_modulate = Color(1, 1, 1, 1)
	panel.position = Vector3(0, CAB_SIZE.y + 1.2, 1.8)
	panel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(panel)

	_elevators[spawn_id] = {
		"car": car,
		"left_door": left_door,
		"right_door": right_door,
		"lobby_zone": lobby_zone,
		"cab_zone": cab_zone,
		"door_open": 0.0,
		"door_open_prev": 0.0,
		"entry": entry,
		"elevator_label": elevator_label,
	}


func _update_elevators(delta: float) -> void:
	_near_elevator_id = ""
	_inside_elevator_id = ""
	var hint_set := false

	for spawn_id in _elevators.keys():
		var data: Dictionary = _elevators[spawn_id]
		var lobby := data.lobby_zone as Area3D
		var cab := data.cab_zone as Area3D
		var near := lobby != null and lobby.overlaps_body(player)
		var inside := cab != null and cab.overlaps_body(player)

		var target_open := 1.0 if near or inside else 0.0
		var prev_open := float(data.door_open)
		data.door_open = move_toward(prev_open, target_open, delta * DOOR_OPEN_SPEED)
		_apply_door_pose(data)
		_maybe_play_elevator_door_sfx(data, prev_open, float(data.door_open))
		data.door_open_prev = float(data.door_open)

		if inside:
			_inside_elevator_id = spawn_id
		if near or inside:
			_near_elevator_id = spawn_id
			if not confirm_panel.visible:
				if inside and float(data.door_open) > 0.75:
					_set_hint(
						"%s — %s. Tryck [E] för att åka upp till kolonin."
						% [str(data.elevator_label), SpawnPoints.get_extent_label()]
					)
				else:
					_set_hint(
						"%s — dörren öppnar. Gå in i hissen och tryck [E]."
						% str(data.elevator_label)
					)
				hint_set = true

	if not hint_set and not confirm_panel.visible:
		_set_hint(
			"Fyra hissar — Hiss 1–4 leder till Koloni 1–4 (vardera %s). "
			% SpawnPoints.get_extent_label()
			+ "Gå nära en hiss — dörren öppnas automatiskt."
		)


func _apply_door_pose(data: Dictionary) -> void:
	var open_amt: float = float(data.door_open)
	var slide := open_amt * 0.85
	var left: MeshInstance3D = data.left_door as MeshInstance3D
	var right: MeshInstance3D = data.right_door as MeshInstance3D
	if left:
		left.position.x = -0.58 - slide
	if right:
		right.position.x = 0.58 + slide


func _maybe_play_elevator_door_sfx(data: Dictionary, prev_open: float, open_now: float) -> void:
	if prev_open > 0.18 and open_now <= 0.18:
		_play_elevator_door_close(data)


func _play_elevator_door_close(data: Dictionary) -> void:
	var car: Node3D = data.get("car") as Node3D
	if car == null:
		return
	GameSfxScript.play_3d_varied(
		self,
		car.global_position + Vector3(0.0, 1.4, 0.0),
		RpgAudioLibraryScript.door_close(),
		Vector2(-9.0, -4.0)
	)


func _start_elevator_ride(spawn_id: String) -> void:
	if not SpawnPoints.is_valid(spawn_id):
		return
	var data: Dictionary = _elevators.get(spawn_id, {})
	if data.is_empty() or float(data.get("door_open", 0.0)) < 0.6:
		return

	_in_elevator_ride = true
	_active_spawn_id = spawn_id
	_ride_car = data.car as Node3D
	_ride_timer = 0.0
	_ride_duration = 4.5
	_ride_start = _ride_car.position
	_ride_end = Vector3(0.0, RIDE_HEIGHT_M, 0.0)
	player.velocity = Vector3.ZERO
	_play_elevator_door_close(data)
	data.door_open = 0.0
	data.door_open_prev = 0.0
	_apply_door_pose(data)
	_set_hint(
		"Hissen åker upp mot %s (%s)..."
		% [str(data.elevator_label), SpawnPoints.get_extent_label()]
	)


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
	MouseLook.deactivate()
	var colony := SpawnPoints.get_colony_label(spawn_id)
	confirm_title.text = "Bo i %s?" % colony
	confirm_body.text = (
		"%s är en kolonikub på %s.\n\n"
		+ "%s\n\n"
		+ "Enda vägen tillbaka till huvudkuben är hissarna i ljusrummet.\n"
		+ "Detta blir ditt permanenta hem."
		% [colony, SpawnPoints.get_extent_label(), SpawnPoints.get_description(spawn_id)]
	)
	confirm_panel.visible = true


func _hide_confirm() -> void:
	confirm_panel.visible = false
	_active_spawn_id = ""
	if not _transitioning:
		MouseLook.activate(camera_pivot, camera_pivot.get_node("Camera3D") as Camera3D)


func _on_confirm_home_pressed() -> void:
	if _active_spawn_id == "" or _transitioning:
		return
	_transitioning = true
	confirm_button.disabled = true
	cancel_button.disabled = true
	_set_hint("Registrerar ditt hem i kolonin...")
	Profile.set_home_spawn(_active_spawn_id, "elevator")


func _on_cancel_confirm_pressed() -> void:
	if _ride_car:
		_ride_car.position = Vector3.ZERO
	_hide_confirm()
	player.position = Vector3(0, 1.0, 3.5)


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
	_set_hint("Ditt hem i kolonin är låst. Går in...")
	_enter_world()


func _on_profile_error(message: String) -> void:
	_transitioning = false
	confirm_button.disabled = false
	cancel_button.disabled = false
	secret_button.disabled = false
	secret_status.text = message
	_set_hint(message)


func _enter_world() -> void:
	_transitioning = true
	_set_hint("Ansluter till din koloni — väntar på servern...")
	## Starta trådad scenladdning samtidigt som nätverket ansluter.
	SceneTransition.begin_threaded_scene_load("res://scenes/game.tscn")
	ThreadedLoaderScript.request_many(CityKitLibraryScript.dc_warmup_paths(), true)
	ThreadedLoaderScript.request_many(SpaceKitLibraryScript.common_warmup_paths(), true)
	_start_connect_watchdog()
	Network.connect_to_world()


func _on_world_ready() -> void:
	_stop_connect_watchdog()
	_set_hint("Går in i världen...")
	SceneTransition.show_loading("Laddar", "Går in i kolonin (trådad laddning)...")
	var packed: PackedScene = await SceneTransition.await_threaded_scene("res://scenes/game.tscn")
	if packed != null:
		get_tree().change_scene_to_packed(packed)
	else:
		get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_connection_failed(reason: String) -> void:
	_stop_connect_watchdog()
	_transitioning = false
	_set_hint("Anslutning misslyckades: %s — försök igen." % reason)


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
	if not _transitioning:
		return
	Network.stop()
	_transitioning = false
	_set_hint("Servern svarade inte i tid — stå kvar och försök igen via hissen.")


func _style_ui() -> void:
	SpiderTheme.apply_to(secret_panel)
	SpiderTheme.apply_to(confirm_panel)
	var hint := _resolve_hint_label()
	if hint == null:
		return
	SpiderTheme.style_status(hint)
	SpiderTheme.wrap_label_in_panel(hint)
	_hint_label = hint
	hint.offset_right = 900.0
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _resolve_hint_label() -> Label:
	if _hint_label != null and is_instance_valid(_hint_label):
		return _hint_label
	_hint_label = get_node_or_null("UI/HintLabel") as Label
	if _hint_label != null:
		return _hint_label
	var ui := get_node_or_null("UI")
	if ui == null:
		return null
	for child in ui.get_children():
		if child is Label:
			_hint_label = child as Label
			return _hint_label
		if child is PanelContainer:
			for sub in child.get_children():
				if sub is Label:
					_hint_label = sub as Label
					return _hint_label
	return null


func _set_hint(text: String) -> void:
	var hint := _resolve_hint_label()
	if hint:
		hint.text = text


func _setup_environment() -> void:
	var world_env := $WorldEnvironment as WorldEnvironment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.82, 0.8, 0.76)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.97, 0.9)
	env.ambient_light_energy = 1.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.2
	env.sdfgi_enabled = false
	world_env.environment = env


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
	light.light_energy = 3.5
	light.omni_range = 11.0
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
	mat.emission = color.lightened(0.08)
	mat.emission_energy_multiplier = emission_strength
	mat.roughness = 0.25
	return mat


func _frame_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color.darkened(0.08)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.4
	mat.metallic = 0.15
	return mat


func _tunnel_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color.darkened(0.2)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.9
	mat.roughness = 0.55
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
