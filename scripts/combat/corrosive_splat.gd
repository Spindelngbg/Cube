extends Node3D

const LIFETIME := 2.8


func _ready() -> void:
	_build()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.35, 1.0, 1.35), LIFETIME)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_callback(_fade_out).set_delay(LIFETIME * 0.45)
	tween.chain().tween_callback(queue_free)


func _build() -> void:
	var pool := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.55
	mesh.bottom_radius = 0.7
	mesh.height = 0.05
	pool.mesh = mesh
	pool.position = Vector3(0.0, 0.03, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.55, 0.16, 0.82)
	mat.emission_enabled = true
	mat.emission = Color(0.35, 1.0, 0.28)
	mat.emission_energy_multiplier = 0.75
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.2
	pool.material_override = mat
	add_child(pool)

	var hiss := MeshInstance3D.new()
	var bubble := SphereMesh.new()
	bubble.radius = 0.18
	bubble.height = 0.36
	hiss.mesh = bubble
	hiss.position = Vector3(0.0, 0.18, 0.0)
	var hiss_mat := mat.duplicate() as StandardMaterial3D
	hiss_mat.emission_energy_multiplier = 1.2
	hiss.material_override = hiss_mat
	add_child(hiss)


func _fade_out() -> void:
	for child in get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D:
			var m := child.material_override as StandardMaterial3D
			var tween := create_tween()
			tween.tween_property(m, "albedo_color:a", 0.0, LIFETIME * 0.5)
			tween.parallel().tween_property(m, "emission_energy_multiplier", 0.0, LIFETIME * 0.5)