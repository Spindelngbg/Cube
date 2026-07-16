class_name ZezzlorJailBox
extends Node3D

const HOLD_DURATION_SEC := 60.0

var _light: OmniLight3D


func _ready() -> void:
	_build()


func get_hold_position() -> Vector3:
	return global_position + Vector3(0.0, 0.5, 0.0)


func get_duration() -> float:
	return HOLD_DURATION_SEC


func _build() -> void:
	var shell := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(3.2, 3.2, 3.2)
	shell.mesh = mesh
	shell.name = "Shell"
	add_child(shell)

	var outer := StandardMaterial3D.new()
	outer.albedo_color = Color(0.96, 0.97, 1.0)
	outer.emission_enabled = true
	outer.emission = Color(0.92, 0.94, 1.0)
	outer.emission_energy_multiplier = 0.55
	outer.roughness = 0.15
	shell.material_override = outer

	var floor := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(2.8, 0.12, 2.8)
	floor.mesh = floor_mesh
	floor.position = Vector3(0.0, -1.45, 0.0)
	add_child(floor)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.98, 0.98, 1.0)
	floor_mat.emission_enabled = true
	floor_mat.emission = Color(1.0, 1.0, 1.0)
	floor_mat.emission_energy_multiplier = 0.85
	floor.material_override = floor_mat

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.98, 0.95)
	_light.light_energy = 2.4
	_light.omni_range = 6.0
	_light.position = Vector3(0.0, 0.8, 0.0)
	add_child(_light)