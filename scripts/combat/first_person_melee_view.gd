class_name FirstPersonMeleeView
extends Node3D

const AXE_SCENE := preload("res://assets/models/weapons/hsg-axe/Axe.glb")

const SWING_DURATION := 0.46

var _swing_timer := 0.0
var _weapon_id := ""
var _pivot: Node3D
var _weapon_root: Node3D


static func ensure_on(player: Node3D) -> FirstPersonMeleeView:
	var existing := player.get_node_or_null("FirstPersonMeleeView") as FirstPersonMeleeView
	if existing:
		return existing
	var view := FirstPersonMeleeView.new()
	view.name = "FirstPersonMeleeView"
	player.add_child(view)
	return view


func set_weapon(weapon_id: String) -> void:
	if _weapon_id == weapon_id:
		return
	_weapon_id = weapon_id
	_rebuild_weapon()


func trigger_swing() -> void:
	if _weapon_id == "":
		return
	_swing_timer = SWING_DURATION


func is_swinging() -> bool:
	return _swing_timer > 0.0


func _ready() -> void:
	_pivot = Node3D.new()
	_pivot.name = "MeleePivot"
	add_child(_pivot)
	top_level = true


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null or _weapon_id == "":
		visible = false
		return
	visible = true
	global_transform = camera.global_transform

	if _swing_timer > 0.0:
		_swing_timer = maxf(0.0, _swing_timer - delta)
		_apply_pose(1.0 - (_swing_timer / SWING_DURATION))
	else:
		_apply_idle_pose()


func _rebuild_weapon() -> void:
	if _weapon_root != null:
		_weapon_root.queue_free()
		_weapon_root = null
	if _weapon_id == "":
		visible = false
		return

	_weapon_root = Node3D.new()
	_weapon_root.name = "WeaponRoot"
	_pivot.add_child(_weapon_root)

	var style := WeaponCatalog.get_display_style(_weapon_id)
	if style.begins_with("axe"):
		var axe := AXE_SCENE.instantiate() as Node3D
		if axe != null:
			axe.scale = Vector3(0.42, 0.42, 0.42)
			axe.rotation_degrees = Vector3(12.0, 92.0, -18.0)
			axe.position = Vector3(0.08, -0.02, -0.04)
			_weapon_root.add_child(axe)
	else:
		var knife := _build_knife_mesh(style)
		knife.rotation_degrees = Vector3(8.0, 88.0, -12.0)
		knife.position = Vector3(0.06, -0.04, -0.02)
		_weapon_root.add_child(knife)

	_apply_idle_pose()


func _build_knife_mesh(style: String) -> MeshInstance3D:
	var knife := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	match style:
		"knife_cleaver":
			mesh.size = Vector3(0.05, 0.2, 0.14)
		"knife_sword":
			mesh.size = Vector3(0.04, 0.26, 0.07)
		"knife_legendary":
			mesh.size = Vector3(0.04, 0.22, 0.09)
		"knife_stiletto":
			mesh.size = Vector3(0.03, 0.18, 0.05)
		_:
			mesh.size = Vector3(0.035, 0.15, 0.05)
	knife.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = WeaponCatalog.get_stats(_weapon_id).get("color", Color.SILVER)
	mat.metallic = 0.72
	mat.roughness = 0.34
	knife.material_override = mat
	return knife


func _apply_idle_pose() -> void:
	if _pivot == null:
		return
	_pivot.position = Vector3(0.3, -0.24, -0.44)
	_pivot.rotation_degrees = Vector3(6.0, -14.0, 2.0)
	if _weapon_root:
		_weapon_root.rotation_degrees = Vector3(0.0, 0.0, 0.0)


func _apply_pose(phase: float) -> void:
	if _pivot == null:
		return

	var windup := 1.0 - smoothstep(0.0, 0.22, phase)
	var strike := smoothstep(0.18, 0.34, phase) * (1.0 - smoothstep(0.38, 0.55, phase))
	var recover := smoothstep(0.52, 1.0, phase)
	var is_axe := WeaponCatalog.get_display_style(_weapon_id).begins_with("axe")

	var base_pos := Vector3(0.3, -0.24, -0.44)
	var strike_forward := Vector3(0.0, 0.02, 0.28 if is_axe else 0.2) * strike
	var windup_back := Vector3(-0.06, 0.04 if is_axe else 0.02, -0.12) * windup
	_pivot.position = base_pos + strike_forward + windup_back
	_pivot.rotation_degrees = Vector3(
		lerpf(6.0, -18.0 if is_axe else -10.0, strike),
		lerpf(-14.0, -4.0, strike),
		lerpf(2.0, -22.0 if is_axe else -14.0, strike) + lerpf(0.0, 8.0, recover)
	)

	if _weapon_root:
		_weapon_root.rotation_degrees = Vector3(
			lerpf(0.0, -48.0 if is_axe else -32.0, windup) + lerpf(0.0, 72.0 if is_axe else 48.0, strike),
			lerpf(0.0, 12.0, strike),
			lerpf(0.0, -16.0 if is_axe else -8.0, strike)
		)