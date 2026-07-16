class_name ZezzlorPaSpeaker
extends Node3D

const ProceduralSfxScript = preload("res://scripts/audio/procedural_sfx.gd")

const LAUGH_GAP_SEC := 0.35

var _voice: AudioStreamPlayer3D
var _laugh: AudioStreamPlayer3D
var _pending_line := ""
var _rng := RandomNumberGenerator.new()


static func mount(parent: Node3D, config: Dictionary) -> ZezzlorPaSpeaker:
	var speaker := ZezzlorPaSpeaker.new()
	speaker.name = "ZezzlorPaSpeaker"
	parent.add_child(speaker)
	speaker.configure(config)
	speaker.add_to_group("zezzlor_pa_speaker")
	return speaker


func configure(config: Dictionary) -> void:
	position = config.get("position", Vector3.ZERO)
	rotation.y = float(config.get("rotation_y", 0.0))
	_rng.seed = int(config.get("seed", hash(str(position))))
	_build_visual()
	_build_audio()


func play_announcement(entry: Dictionary) -> void:
	var text := str(entry.get("text", "")).strip_edges()
	if text == "":
		return
	if bool(entry.get("laugh", false)):
		_pending_line = _strip_laugh_prefix(text)
		_play_laugh()
	else:
		_speak(text)


func _build_audio() -> void:
	_laugh = AudioStreamPlayer3D.new()
	_laugh.name = "Laugh"
	_laugh.bus = &"Sfx"
	_laugh.max_distance = 72.0
	_laugh.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_laugh.unit_size = 8.0
	_laugh.volume_db = -4.0
	add_child(_laugh)

	_voice = AudioStreamPlayer3D.new()
	_voice.name = "Voice"
	_voice.bus = &"Sfx"
	_voice.max_distance = 78.0
	_voice.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_voice.unit_size = 10.0
	_voice.volume_db = -2.0
	add_child(_voice)


func _build_visual() -> void:
	var bracket := MeshInstance3D.new()
	bracket.name = "Bracket"
	var bracket_mesh := BoxMesh.new()
	bracket_mesh.size = Vector3(0.42, 0.28, 0.18)
	bracket.mesh = bracket_mesh
	bracket.position = Vector3(0.0, 0.0, 0.08)
	var bracket_mat := StandardMaterial3D.new()
	bracket_mat.albedo_color = Color(0.14, 0.16, 0.2)
	bracket_mat.metallic = 0.55
	bracket_mat.roughness = 0.42
	bracket.material_override = bracket_mat
	add_child(bracket)

	var horn := MeshInstance3D.new()
	horn.name = "Horn"
	var horn_mesh := CylinderMesh.new()
	horn_mesh.top_radius = 0.2
	horn_mesh.bottom_radius = 0.34
	horn_mesh.height = 0.28
	horn.mesh = horn_mesh
	horn.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	horn.position = Vector3(0.0, 0.0, -0.18)
	var horn_mat := StandardMaterial3D.new()
	horn_mat.albedo_color = Color(0.22, 0.24, 0.28)
	horn_mat.metallic = 0.35
	horn_mat.roughness = 0.55
	horn.material_override = horn_mat
	add_child(horn)

	var led := MeshInstance3D.new()
	led.name = "Led"
	var led_mesh := BoxMesh.new()
	led_mesh.size = Vector3(0.08, 0.08, 0.04)
	led.mesh = led_mesh
	led.position = Vector3(0.12, 0.08, 0.12)
	var led_mat := StandardMaterial3D.new()
	led_mat.albedo_color = Color(0.35, 0.62, 0.98)
	led_mat.emission_enabled = true
	led_mat.emission = Color(0.42, 0.72, 1.0)
	led_mat.emission_energy_multiplier = 1.1
	led.material_override = led_mat
	add_child(led)


func _play_laugh() -> void:
	if _laugh == null:
		_speak(_pending_line)
		_pending_line = ""
		return
	_laugh.stream = ProceduralSfxScript.laugh_stream(_rng.randi())
	_laugh.pitch_scale = _rng.randf_range(0.92, 1.08)
	if _laugh.finished.is_connected(_on_laugh_finished):
		_laugh.finished.disconnect(_on_laugh_finished)
	_laugh.finished.connect(_on_laugh_finished, CONNECT_ONE_SHOT)
	_laugh.play()


func _on_laugh_finished() -> void:
	var line := _pending_line
	_pending_line = ""
	if line == "":
		return
	await get_tree().create_timer(LAUGH_GAP_SEC).timeout
	_speak(line)


func _strip_laugh_prefix(text: String) -> String:
	var prefixes: PackedStringArray = [
		"Ha ha ha! ",
		"Fniss fniss. ",
		"Fniss. ",
		"He he he! ",
		"He he! ",
		"Höhö! ",
		"Ha! ",
		"Pff. ",
		"Skrattar lite. ",
	]
	for prefix in prefixes:
		if text.begins_with(prefix):
			return text.substr(prefix.length()).strip_edges()
	return text


func _speak(text: String) -> void:
	if _voice == null:
		return
	HelpRobotTts.speak(text, _voice, true)