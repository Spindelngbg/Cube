class_name JugglerBallAnim
extends Node3D

## Billig jongleringsanimation — tre bollar, ingen physics.

const BALL_COLORS := [
	Color(1.0, 0.25, 0.4),
	Color(0.25, 0.85, 1.0),
	Color(1.0, 0.85, 0.2),
]

var _balls: Array[MeshInstance3D] = []
var _t := 0.0


func setup() -> void:
	for i in 3:
		var ball := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.12
		mesh.height = 0.24
		ball.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = BALL_COLORS[i]
		mat.emission_enabled = true
		mat.emission = BALL_COLORS[i]
		mat.emission_energy_multiplier = 0.55
		ball.material_override = mat
		add_child(ball)
		_balls.append(ball)
	_t = randf() * TAU
	set_process(true)


func _process(delta: float) -> void:
	_t += delta * 3.2
	for i in _balls.size():
		var phase := _t + float(i) * (TAU / 3.0)
		var x := sin(phase) * 0.55
		var y := 1.35 + absf(sin(phase * 0.5 + float(i))) * 0.85
		var z := cos(phase) * 0.15
		_balls[i].position = Vector3(x, y, z)
