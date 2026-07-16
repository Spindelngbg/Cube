class_name WallCrawlVehicle
extends CharacterBody3D

const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")

const MOUNT_RANGE := 2.8
const DRIVE_SPEED := 11.5
const SPRINT_SPEED := 16.0
const TURN_SPEED := 2.6
const ALIGN_SPEED := 9.0
const SURFACE_RAY := 2.4
const STICK_OFFSET := 0.42
const WORLD_GRAVITY := 18.0

var _pilot_peer_id := -1
var _surface_normal := Vector3.UP
var _accent := Color(0.35, 0.82, 0.95)
var _label: Label3D
var _glow_panels: Array[MeshInstance3D] = []
var _time := 0.0
var _rng := RandomNumberGenerator.new()


func setup(config: Dictionary) -> void:
	global_position = config.get("position", Vector3.ZERO)
	rotation.y = float(config.get("rotation_y", 0.0))
	_accent = config.get("accent", Color(0.35, 0.82, 0.95))
	_rng.seed = int(config.get("seed", hash(str(global_position))))
	_time = _rng.randf_range(0.0, TAU)
	_build_model()
	_build_collision()
	_build_mount_prompt()
	floor_max_angle = deg_to_rad(89.0)
	floor_snap_length = 0.35
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	up_direction = Vector3.UP
	set_physics_process(true)
	add_to_group("climb_vehicle")
	call_deferred("_snap_to_surface")


func can_mount(player: Node3D) -> bool:
	if _pilot_peer_id >= 0 or player == null:
		return false
	return global_position.distance_to(player.global_position) <= MOUNT_RANGE


func get_prompt() -> String:
	if _pilot_peer_id >= 0:
		return ""
	return "Åk Grip-Crawler [E]"


func try_mount(player: Node3D) -> bool:
	if not can_mount(player):
		return false
	var peer_id := player.get_multiplayer_authority() if player.has_method("get_multiplayer_authority") else 1
	_pilot_peer_id = peer_id
	if multiplayer.multiplayer_peer != null:
		set_multiplayer_authority(peer_id)
	if player.has_method("set_piloting_vehicle"):
		player.set_piloting_vehicle(self)
	QuestManager.story_toast.emit("Grip-Crawler", "WASD kör. Sprint = snabbare. Kör rakt mot väggar — den klättrar. [E] hoppar av.")
	return true


func dismount_pilot(player: Node3D) -> void:
	if player == null:
		return
	var off := global_transform.basis.x * 1.6 + _surface_normal * 0.35
	player.global_position = global_position + off
	if player.has_method("snap_to_floor"):
		player.snap_to_floor()
	if player.has_method("set_piloting_vehicle"):
		player.set_piloting_vehicle(null)
	_pilot_peer_id = -1
	velocity = Vector3.ZERO
	if multiplayer.multiplayer_peer != null:
		set_multiplayer_authority(MultiplayerEntityAuthorityScript.simulation_peer_id())


func is_piloted_by(peer_id: int) -> bool:
	return _pilot_peer_id == peer_id


func get_camera_anchor_global_position() -> Vector3:
	return global_position + global_transform.basis.y * 1.05 - global_transform.basis.z * 0.25


func _physics_process(delta: float) -> void:
	_time += delta
	_animate_idle(delta)
	if not _is_local_pilot():
		return

	_update_surface(delta)
	_handle_drive_input(delta)
	move_and_slide()
	_snap_to_surface()
	if multiplayer.multiplayer_peer != null:
		_sync_vehicle.rpc(global_transform.origin, global_transform.basis.get_euler())


func _handle_drive_input(delta: float) -> void:
	var yaw_input := Input.get_axis("move_right", "move_left")
	rotate(_surface_normal, yaw_input * TURN_SPEED * delta)

	var basis_flat := global_transform.basis
	var forward := -basis_flat.z
	var right := basis_flat.x
	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else DRIVE_SPEED

	if move_input.length_squared() > 0.01:
		var move_dir := (forward * move_input.y + right * move_input.x).normalized()
		velocity = move_dir * speed
	else:
		var horizontal := velocity.slide(_surface_normal)
		velocity = horizontal.move_toward(Vector3.ZERO, speed * delta * 3.5)

	if not is_on_floor():
		velocity -= _surface_normal * WORLD_GRAVITY * delta * 0.35


func _update_surface(delta: float) -> void:
	var probed := _probe_surface_normal()
	if probed.length_squared() > 0.01:
		_surface_normal = _surface_normal.lerp(probed.normalized(), ALIGN_SPEED * delta).normalized()
	up_direction = _surface_normal
	_align_body_to_surface(delta)


func _probe_surface_normal() -> Vector3:
	var space := get_world_3d().direct_space_state
	if space == null:
		return Vector3.UP

	var down := -global_transform.basis.y.normalized()
	var hits: Array[Vector3] = []
	var offsets := [
		Vector3.ZERO,
		Vector3(0.55, 0.0, 0.45),
		Vector3(-0.55, 0.0, 0.45),
		Vector3(0.55, 0.0, -0.45),
		Vector3(-0.55, 0.0, -0.45),
	]

	for offset in offsets:
		var local_offset: Vector3 = offset
		var origin := global_position + global_transform.basis * local_offset + global_transform.basis.y * 0.18
		var normal := _ray_normal(space, origin, down * SURFACE_RAY)
		if normal != Vector3.ZERO:
			hits.append(normal)

	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if move_input.y < -0.1:
		var forward := (-global_transform.basis.z).normalized()
		var ahead_origin := global_position + forward * 0.95 + global_transform.basis.y * 0.2
		var ahead_dir := (forward - global_transform.basis.y * 0.55).normalized()
		var ahead_normal := _ray_normal(space, ahead_origin, ahead_dir * SURFACE_RAY)
		if ahead_normal != Vector3.ZERO:
			hits.append(ahead_normal)
			hits.append(ahead_normal)

	if hits.is_empty():
		var ground := _ray_normal(space, global_position + Vector3.UP * 0.5, Vector3.DOWN * (SURFACE_RAY + 1.5))
		if ground != Vector3.ZERO:
			return ground
		return Vector3.UP

	var avg := Vector3.ZERO
	for n in hits:
		avg += n
	return avg.normalized()


func _ray_normal(space: PhysicsDirectSpaceState3D, from: Vector3, direction: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(from, from + direction)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return Vector3.ZERO
	return hit.get("normal", Vector3.UP) as Vector3


func _align_body_to_surface(delta: float) -> void:
	var up := _surface_normal
	var forward := -global_transform.basis.z.slide(up)
	if forward.length_squared() < 0.01:
		forward = Vector3.FORWARD.slide(up)
	forward = forward.normalized()
	var target := Basis().looking_at(forward, up)
	var current := global_transform.basis.orthonormalized()
	global_transform.basis = current.slerp(target, clampf(ALIGN_SPEED * delta, 0.0, 1.0))


func _snap_to_surface() -> void:
	var space := get_world_3d().direct_space_state
	if space == null:
		return
	var origin := global_position + global_transform.basis.y * 0.2
	var query := PhysicsRayQueryParameters3D.create(origin, origin - global_transform.basis.y * SURFACE_RAY)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	var point: Vector3 = hit.get("position", origin)
	var desired := point + _surface_normal * STICK_OFFSET
	global_position = global_position.lerp(desired, 0.65)


func _is_local_pilot() -> bool:
	if _pilot_peer_id < 0:
		return false
	if multiplayer.multiplayer_peer == null:
		return true
	return _pilot_peer_id == multiplayer.get_unique_id()


func _build_collision() -> void:
	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.35, 0.55, 1.85)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 0.18, 0.0)
	add_child(shape_node)
	collision_layer = 4
	collision_mask = 1


func _build_mount_prompt() -> void:
	_label = Label3D.new()
	_label.text = "Grip-Crawler"
	_label.font_size = 30
	_label.modulate = _accent.lightened(0.15)
	_label.outline_modulate = Color(0.05, 0.08, 0.12, 0.95)
	_label.position = Vector3(0.0, 1.15, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)


func _build_model() -> void:
	var body_color := Color(0.2, 0.22, 0.28)
	var chassis := _box("Chassis", Vector3(0.0, 0.22, 0.0), Vector3(1.2, 0.28, 1.65), body_color)
	chassis.material_override = _mat(body_color, 0.08)

	for side in [-1.0, 1.0]:
		var leg := _box("Leg", Vector3(0.62 * side, 0.12, 0.55), Vector3(0.18, 0.12, 0.55), body_color.lightened(0.05))
		leg.material_override = _glow(_accent, 0.22)
		var leg2 := _box("Leg2", Vector3(0.62 * side, 0.12, -0.55), Vector3(0.18, 0.12, 0.55), body_color.lightened(0.05))
		leg2.material_override = _glow(_accent, 0.22)

	var cockpit := _box("Cockpit", Vector3(0.0, 0.52, -0.15), Vector3(0.72, 0.32, 0.72), Color(0.42, 0.72, 0.92, 0.5))
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.42, 0.72, 0.92, 0.45)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.12
	cockpit.material_override = glass

	for i in range(4):
		var panel := _box("GlowPanel%d" % i, Vector3.ZERO, Vector3(0.12, 0.05, 0.38), _accent)
		panel.position = Vector3(
			0.62 if i % 2 == 0 else -0.62,
			0.3,
			0.65 if i < 2 else -0.65
		)
		panel.material_override = _glow(_accent, 0.55)
		_glow_panels.append(panel)


func _animate_idle(delta: float) -> void:
	for panel in _glow_panels:
		if panel and panel.material_override is StandardMaterial3D:
			var mat := panel.material_override as StandardMaterial3D
			mat.emission_energy_multiplier = 0.45 + sin(_time * 4.5 + float(panel.get_index())) * 0.2
	if _label and _pilot_peer_id < 0:
		_label.visible = true
	elif _label:
		_label.visible = false


@rpc("any_peer", "unreliable")
func _sync_vehicle(pos: Vector3, euler: Vector3) -> void:
	if _is_local_pilot():
		return
	global_position = pos
	global_rotation = euler


func _box(name: String, pos: Vector3, scale: Vector3, _color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	mesh.mesh = BoxMesh.new()
	mesh.position = pos
	mesh.scale = scale
	add_child(mesh)
	return mesh


func _mat(color: Color, emission: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.42
	mat.roughness = 0.58
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	return mat


func _glow(color: Color, strength: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = strength
	return mat