class_name PlayerFootsteps
extends Node3D

const ProceduralSfxScript = preload("res://scripts/audio/procedural_sfx.gd")

const STEP_LENGTH_WALK := 0.68
const STEP_LENGTH_SPRINT := 0.58
const MIN_SPEED := 0.38

var _left_player: AudioStreamPlayer3D
var _right_player: AudioStreamPlayer3D
var _step_accum := 0.0
var _left_next := true
var _step_index := 0
var _rng := RandomNumberGenerator.new()


static func ensure_on(player: CharacterBody3D) -> PlayerFootsteps:
	var existing := player.get_node_or_null("Footsteps") as PlayerFootsteps
	if existing:
		return existing
	var footsteps := PlayerFootsteps.new()
	footsteps.name = "Footsteps"
	player.add_child(footsteps)
	footsteps._setup()
	return footsteps


func _setup() -> void:
	_rng.randomize()
	_left_player = _make_foot_player("LeftFoot")
	_right_player = _make_foot_player("RightFoot")
	_left_player.position = Vector3(-0.14, 0.08, 0.0)
	_right_player.position = Vector3(0.14, 0.08, 0.0)


func tick(delta: float, horizontal_speed: float, on_floor: bool, sprinting: bool) -> void:
	if not _footsteps_enabled():
		_step_accum = 0.0
		return
	if not on_floor or horizontal_speed < MIN_SPEED:
		_step_accum = 0.0
		return

	var step_length := STEP_LENGTH_SPRINT if sprinting else STEP_LENGTH_WALK
	_step_accum += horizontal_speed * delta
	while _step_accum >= step_length:
		_step_accum -= step_length
		_play_step(sprinting)


func _make_foot_player(node_name: String) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.name = node_name
	player.bus = &"Footsteps"
	player.max_distance = 10.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	player.unit_size = 5.0
	player.volume_db = -16.0
	add_child(player)
	return player


func _footsteps_enabled() -> bool:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return true
	return bool(settings.get_value("audio.footsteps_enabled", true))


func _play_step(sprinting: bool) -> void:
	var stream_player := _left_player if _left_next else _right_player
	_left_next = not _left_next
	if stream_player == null:
		return

	stream_player.stream = ProceduralSfxScript.footstep_stream(_step_index)
	_step_index += 1
	stream_player.pitch_scale = _rng.randf_range(0.84, 0.96)
	if sprinting:
		stream_player.pitch_scale *= _rng.randf_range(1.02, 1.08)
		stream_player.volume_db = _rng.randf_range(-22.0, -18.5)
	else:
		stream_player.volume_db = _rng.randf_range(-24.5, -20.5)
	stream_player.play()