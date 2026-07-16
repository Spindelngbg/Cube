class_name GameSfx
extends RefCounted

const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")


static func play_3d(
	parent: Node,
	world_pos: Vector3,
	stream: AudioStream,
	volume_db: float = -6.0,
	pitch_scale: float = 1.0,
	max_distance: float = 22.0
) -> void:
	if parent == null or stream == null:
		return
	var player := AudioStreamPlayer3D.new()
	player.bus = &"Sfx"
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.max_distance = max_distance
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	parent.add_child(player)
	player.global_position = world_pos
	player.finished.connect(player.queue_free)
	player.play()


static func play_2d(
	parent: Node,
	stream: AudioStream,
	volume_db: float = -8.0,
	pitch_scale: float = 1.0
) -> void:
	if parent == null or stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.bus = &"Sfx"
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	parent.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


static func play_3d_varied(
	parent: Node,
	world_pos: Vector3,
	stream: AudioStream,
	volume_range: Vector2 = Vector2(-10.0, -5.0),
	pitch_range: Vector2 = Vector2(0.94, 1.06)
) -> void:
	var rng := RandomNumberGenerator.new()
	play_3d(
		parent,
		world_pos,
		stream,
		rng.randf_range(volume_range.x, volume_range.y),
		rng.randf_range(pitch_range.x, pitch_range.y)
	)


static func play_2d_varied(
	parent: Node,
	stream: AudioStream,
	volume_range: Vector2 = Vector2(-12.0, -7.0),
	pitch_range: Vector2 = Vector2(0.95, 1.05)
) -> void:
	var rng := RandomNumberGenerator.new()
	play_2d(
		parent,
		stream,
		rng.randf_range(volume_range.x, volume_range.y),
		rng.randf_range(pitch_range.x, pitch_range.y)
	)