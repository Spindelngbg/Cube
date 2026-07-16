class_name ZezzlorBackupDirectionMarker
extends Node3D

const BEAM_LENGTH := 32.0

var _pulse := 0.0


func setup(origin: Vector3, direction: Vector3) -> void:
	global_position = origin
	var dir := direction
	dir.y = 0.0
	if dir.length_squared() < 0.01:
		dir = Vector3.FORWARD
	dir = dir.normalized()
	look_at(global_position + dir, Vector3.UP)
	_build(dir)


func _process(delta: float) -> void:
	_pulse += delta * 3.2
	var glow := 0.55 + sin(_pulse) * 0.25
	for child in get_children():
		if child is MeshInstance3D:
			var mat := child.material_override as StandardMaterial3D
			if mat != null and mat.emission_enabled:
				mat.emission_energy_multiplier = glow


func _build(dir: Vector3) -> void:
	var beam := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.35, 0.08, BEAM_LENGTH)
	beam.mesh = mesh
	beam.position = dir * (BEAM_LENGTH * 0.5) + Vector3(0.0, 0.12, 0.0)
	add_child(beam)
	var beam_mat := StandardMaterial3D.new()
	beam_mat.albedo_color = Color(0.25, 0.72, 1.0, 0.75)
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.emission_enabled = true
	beam_mat.emission = Color(0.35, 0.82, 1.0)
	beam_mat.emission_energy_multiplier = 0.7
	beam.material_override = beam_mat

	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(1.4, 0.1, 1.4)
	head.mesh = head_mesh
	head.position = dir * BEAM_LENGTH + Vector3(0.0, 0.14, 0.0)
	head.rotation.y = PI * 0.25
	add_child(head)
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(1.0, 0.55, 0.15)
	head_mat.emission_enabled = true
	head_mat.emission = Color(1.0, 0.45, 0.1)
	head_mat.emission_energy_multiplier = 1.1
	head.material_override = head_mat

	var label_pivot := Node3D.new()
	label_pivot.position = dir * (BEAM_LENGTH * 0.55) + Vector3(0.0, 1.6, 0.0)
	add_child(label_pivot)
	var label := Label3D.new()
	label.text = "BRÅK / PROBLEM"
	label.font_size = 42
	label.modulate = Color(1.0, 0.82, 0.35)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_pivot.add_child(label)