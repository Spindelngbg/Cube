class_name CriminalBossHq
extends Node3D

const RUST := Color(0.22, 0.14, 0.1)
const STEEL := Color(0.12, 0.12, 0.14)
const BLOOD_NEON := Color(0.95, 0.12, 0.08)
const OIL := Color(0.05, 0.05, 0.06)

var hq_id := ""
var boss_id := ""
var hq_label := "Syndikat HQ"


func setup(entry: Dictionary) -> void:
	hq_id = str(entry.get("hq_id", "criminal_hq"))
	boss_id = str(entry.get("boss_id", ""))
	hq_label = str(entry.get("label", "Syndikat HQ"))
	position = entry.get("local_pos", Vector3.ZERO)
	rotation.y = float(entry.get("rotation_y", 0.0))
	_build_compound()
	add_to_group("criminal_boss_hq")
	set_meta("boss_id", boss_id)


func _build_compound() -> void:
	_build_pad()
	_build_main_den()
	_build_fence_posts()
	_build_burn_barrels()
	_build_watchtower()
	_build_signage()
	_build_collision()


func _build_pad() -> void:
	var pad := MeshInstance3D.new()
	pad.name = "AsphaltPad"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(34.0, 0.35, 28.0)
	pad.mesh = mesh
	pad.position = Vector3(0.0, 0.16, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = OIL
	mat.roughness = 0.92
	pad.material_override = mat
	add_child(pad)

	var stain := MeshInstance3D.new()
	var stain_mesh := BoxMesh.new()
	stain_mesh.size = Vector3(18.0, 0.05, 12.0)
	stain.mesh = stain_mesh
	stain.position = Vector3(4.0, 0.34, -3.0)
	var stain_mat := StandardMaterial3D.new()
	stain_mat.albedo_color = Color(0.35, 0.08, 0.05, 0.55)
	stain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	stain.material_override = stain_mat
	add_child(stain)


func _build_main_den() -> void:
	_add_box(Vector3(16.0, 6.5, 12.0), Vector3(0.0, 3.4, -2.0), RUST)
	_add_box(Vector3(14.0, 1.2, 10.0), Vector3(0.0, 7.0, -2.0), STEEL)
	_add_box(Vector3(4.5, 4.0, 3.0), Vector3(0.0, 2.2, 5.8), STEEL.darkened(0.15))
	for side in [-1.0, 1.0]:
		_add_box(Vector3(3.0, 5.0, 8.0), Vector3(side * 9.5, 2.8, -2.0), RUST.darkened(0.12))


func _build_fence_posts() -> void:
	for offset in [
		Vector3(-15.0, 0.0, 12.0),
		Vector3(15.0, 0.0, 12.0),
		Vector3(-15.0, 0.0, -12.0),
		Vector3(15.0, 0.0, -12.0),
	]:
		_add_box(Vector3(0.35, 3.2, 0.35), offset + Vector3(0.0, 1.6, 0.0), STEEL)
		var wire := MeshInstance3D.new()
		var wire_mesh := BoxMesh.new()
		wire_mesh.size = Vector3(14.0, 0.08, 0.08)
		wire.mesh = wire_mesh
		wire.position = offset + Vector3(0.0, 2.4, 0.0)
		var wire_mat := StandardMaterial3D.new()
		wire_mat.albedo_color = Color(0.45, 0.45, 0.48)
		wire_mat.metallic = 0.8
		wire.material_override = wire_mat
		add_child(wire)


func _build_burn_barrels() -> void:
	for offset in [Vector3(-11.0, 0.0, 9.0), Vector3(12.0, 0.0, 8.0), Vector3(-9.0, 0.0, -10.0)]:
		var barrel := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.55
		mesh.bottom_radius = 0.62
		mesh.height = 1.35
		barrel.mesh = mesh
		barrel.position = offset + Vector3(0.0, 0.72, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.18, 0.12, 0.08)
		barrel.material_override = mat
		add_child(barrel)
		var fire := OmniLight3D.new()
		fire.light_color = Color(1.0, 0.45, 0.12)
		fire.light_energy = 0.55
		fire.omni_range = 7.0
		fire.position = offset + Vector3(0.0, 1.6, 0.0)
		add_child(fire)


func _build_watchtower() -> void:
	_add_box(Vector3(2.8, 8.0, 2.8), Vector3(13.0, 4.2, -10.0), STEEL)
	_add_box(Vector3(4.2, 0.35, 4.2), Vector3(13.0, 8.4, -10.0), RUST)
	var lamp := OmniLight3D.new()
	lamp.light_color = BLOOD_NEON
	lamp.light_energy = 0.35
	lamp.omni_range = 11.0
	lamp.position = Vector3(13.0, 9.0, -10.0)
	add_child(lamp)


func _build_signage() -> void:
	var sign := Label3D.new()
	sign.text = "SYNDIKAT\nHQ"
	sign.font_size = 58
	sign.position = Vector3(0.0, 5.8, 6.4)
	sign.modulate = BLOOD_NEON
	sign.outline_size = 10
	sign.outline_modulate = Color(0.04, 0.02, 0.02)
	add_child(sign)

	var sub := Label3D.new()
	sub.text = hq_label
	sub.font_size = 24
	sub.position = Vector3(0.0, 4.2, 6.35)
	sub.modulate = Color(0.92, 0.55, 0.42)
	sub.outline_size = 4
	add_child(sub)

	var warn := Label3D.new()
	warn.text = "PRIVAT TERRITORIUM"
	warn.font_size = 16
	warn.position = Vector3(0.0, 1.2, 6.3)
	warn.modulate = Color(0.95, 0.2, 0.15, 0.85)
	add_child(warn)


func _build_collision() -> void:
	var blocker := StaticBody3D.new()
	blocker.name = "Blocker"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(16.0, 6.5, 12.0)
	shape.shape = box
	shape.position = Vector3(0.0, 3.4, -2.0)
	blocker.add_child(shape)
	add_child(blocker)


func _add_box(size: Vector3, pos: Vector3, color: Color) -> void:
	var box := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	box.mesh = mesh
	box.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	mat.metallic = 0.18
	box.material_override = mat
	add_child(box)