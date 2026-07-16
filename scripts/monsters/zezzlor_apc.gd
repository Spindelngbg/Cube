class_name ZezzlorApc
extends Node3D

signal arrived

const DRIVE_SPEED := 58.0
const ARRIVE_DIST := 3.5

var _target := Vector3.ZERO
var _driving := false
var _body: Node3D
var _turret: Node3D


func _ready() -> void:
	_build_visuals()


func drive_to(target: Vector3) -> void:
	_target = target
	_target.y = global_position.y
	_driving = true
	var flat := _target - global_position
	flat.y = 0.0
	if flat.length_squared() > 0.01:
		look_at(global_position + flat.normalized(), Vector3.UP)


func is_driving() -> bool:
	return _driving


func get_dismount_positions() -> Array[Vector3]:
	var out: Array[Vector3] = []
	var back := -global_transform.basis.z
	var right := global_transform.basis.x
	for offset in [right * 2.2, right * -2.2, back * 2.8 + right * 1.2, back * 2.8 + right * -1.2]:
		out.append(global_position + Vector3(offset.x, 0.0, offset.z))
	return out


func _process(delta: float) -> void:
	if not _driving:
		return
	var to := _target - global_position
	to.y = 0.0
	var dist := to.length()
	if dist <= ARRIVE_DIST:
		_driving = false
		arrived.emit()
		return
	var dir := to / dist
	global_position += dir * DRIVE_SPEED * delta
	if dir.length_squared() > 0.01:
		look_at(global_position + dir, Vector3.UP)
	if _turret:
		_turret.rotation.y += delta * 2.4


func _build_visuals() -> void:
	_body = Node3D.new()
	_body.name = "ApcBody"
	add_child(_body)

	var armor := Color(0.18, 0.22, 0.3)
	var trim := Color(0.28, 0.52, 0.88)
	var gun := Color(0.12, 0.12, 0.14)

	var hull := _box("Hull", _body, Vector3(0.0, 0.85, 0.0), Vector3(3.2, 1.1, 5.4), armor)
	_mat(hull, armor, 0.08)

	for side in [-1.0, 1.0]:
		var plate := _box("ArmorPlate", _body, Vector3(1.75 * side, 1.0, 0.2), Vector3(0.35, 1.35, 4.8), armor.lightened(0.05))
		_mat(plate, armor.lightened(0.05), 0.12)
		var skirt := _box("Skirt", _body, Vector3(1.45 * side, 0.35, -1.6), Vector3(0.55, 0.45, 1.8), trim)
		_mat(skirt, trim, 0.35)

	_turret = Node3D.new()
	_turret.name = "Turret"
	_turret.position = Vector3(0.0, 1.55, -0.4)
	_body.add_child(_turret)

	var ring := _cyl("TurretRing", _turret, Vector3.ZERO, Vector3(1.35, 0.22, 1.35), trim)
	_mat(ring, trim, 0.4)

	var mg := _box("RoofMG", _turret, Vector3(0.0, 0.35, -0.55), Vector3(0.18, 0.18, 1.6), gun)
	_mat(mg, gun, 0.05)
	var mg2 := _box("RoofMG2", _turret, Vector3(0.35, 0.28, -0.2), Vector3(0.12, 0.12, 1.1), gun)
	_mat(mg2, gun, 0.05)

	for side in [-1.0, 1.0]:
		var pod := _box("SideGun", _body, Vector3(1.95 * side, 1.15, 1.0), Vector3(0.28, 0.28, 1.4), gun)
		_mat(pod, gun, 0.15)
		var barrel := _cyl("Barrel", _body, Vector3(2.25 * side, 1.15, 1.8), Vector3(0.08, 0.55, 0.08), gun)
		_mat(barrel, gun, 0.2)
		var rocket := _box("RocketPod", _body, Vector3(1.55 * side, 1.55, -1.2), Vector3(0.42, 0.42, 0.9), trim)
		_mat(rocket, trim, 0.25)
		for tube_i in range(3):
			var tube_z := -1.55 + float(tube_i) * 0.28
			var tube := _cyl("RocketTube", _body, Vector3(1.72 * side, 1.55, tube_z), Vector3(0.1, 0.35, 0.1), gun)
			_mat(tube, gun, 0.1)

	var rear_mg := _box("RearMG", _body, Vector3(0.0, 1.45, 2.35), Vector3(0.22, 0.22, 1.3), gun)
	_mat(rear_mg, gun, 0.12)
	var spike_l := _box("SpikeL", _body, Vector3(-1.1, 0.55, 2.6), Vector3(0.18, 0.55, 0.18), armor.lightened(0.08))
	_mat(spike_l, armor.lightened(0.08), 0.05)
	var spike_r := _box("SpikeR", _body, Vector3(1.1, 0.55, 2.6), Vector3(0.18, 0.55, 0.18), armor.lightened(0.08))
	_mat(spike_r, armor.lightened(0.08), 0.05)

	for i in range(4):
		var wx := 1.15 if i % 2 == 0 else -1.15
		var wz := -1.8 + float(i / 2) * 3.2
		var wheel := _cyl("Wheel", _body, Vector3(wx, 0.28, wz), Vector3(0.55, 0.18, 0.55), Color(0.08, 0.08, 0.1))
		_mat(wheel, Color(0.08, 0.08, 0.1), 0.0)

	var beacon := _box("Beacon", _body, Vector3(0.0, 1.75, 1.4), Vector3(0.35, 0.2, 0.35), Color(0.2, 0.65, 1.0))
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.2, 0.65, 1.0)
	bmat.emission_enabled = true
	bmat.emission = Color(0.3, 0.75, 1.0)
	bmat.emission_energy_multiplier = 1.2
	beacon.material_override = bmat


func _box(name: String, parent: Node3D, pos: Vector3, scale: Vector3, _c: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = name
	m.mesh = BoxMesh.new()
	m.position = pos
	m.scale = scale
	parent.add_child(m)
	return m


func _cyl(name: String, parent: Node3D, pos: Vector3, scale: Vector3, _c: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = name
	var mesh := CylinderMesh.new()
	mesh.height = 1.0
	m.mesh = mesh
	m.position = pos
	m.scale = scale
	parent.add_child(m)
	return m


func _mat(mesh: MeshInstance3D, color: Color, emission: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.55
	mat.roughness = 0.38
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	mesh.material_override = mat