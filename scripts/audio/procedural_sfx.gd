class_name ProceduralSfx
extends RefCounted

const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")
const SciFiAudioLibraryScript = preload("res://scripts/audio/sci_fi_audio_library.gd")

const SAMPLE_RATE := 22050

static var _footstep_cache: Array[AudioStreamWAV] = []
static var _honk_stream: AudioStreamWAV
static var _bounce_stream: AudioStreamWAV
static var _laugh_cache: Array[AudioStreamWAV] = []


static func footstep_stream(variant: int = 0) -> AudioStream:
	var rpg := RpgAudioLibraryScript.footstep(variant)
	if rpg != null:
		return rpg
	if not _footstep_cache.is_empty():
		return _footstep_cache[variant % _footstep_cache.size()]
	_build_footstep_cache()
	return _footstep_cache[variant % _footstep_cache.size()]


static func _build_footstep_cache() -> void:
	_footstep_cache.clear()
	for i in range(6):
		_footstep_cache.append(_make_footstep(i))


static func _make_footstep(seed: int) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 41
	var duration := rng.randf_range(0.06, 0.1)
	var sample_count := maxi(1, int(SAMPLE_RATE * duration))
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	var base_freq := rng.randf_range(62.0, 110.0)
	var noise_mix := rng.randf_range(0.28, 0.48)

	for i in sample_count:
		var t := float(i) / float(SAMPLE_RATE)
		var attack := clampf(t * 180.0, 0.0, 1.0)
		var decay := exp(-t * rng.randf_range(28.0, 42.0))
		var envelope := attack * decay
		var noise := rng.randf_range(-1.0, 1.0) * noise_mix
		var thump := sin(t * base_freq * TAU) * (1.0 - noise_mix)
		var click := sin(t * rng.randf_range(900.0, 1600.0) * TAU) * exp(-t * 120.0) * 0.08
		var sample := (noise + thump + click) * envelope
		sample = clampf(sample, -1.0, 1.0)
		var int_sample := int(sample * 9000.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


static func honk_stream() -> AudioStream:
	var sci_fi := SciFiAudioLibraryScript.bot_alert()
	if sci_fi != null:
		return sci_fi
	var rpg := RpgAudioLibraryScript.bot_alert()
	if rpg != null:
		return rpg
	if _honk_stream != null:
		return _honk_stream
	_honk_stream = _make_honk()
	return _honk_stream


static func laugh_stream(seed: int = 0) -> AudioStream:
	if not _laugh_cache.is_empty():
		return _laugh_cache[abs(seed) % _laugh_cache.size()]
	_build_laugh_cache()
	return _laugh_cache[abs(seed) % _laugh_cache.size()]


static func _build_laugh_cache() -> void:
	_laugh_cache.clear()
	for i in range(4):
		_laugh_cache.append(_make_laugh(i))


static func _make_laugh(seed: int) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 771
	var duration := rng.randf_range(0.55, 0.9)
	var sample_count := maxi(1, int(SAMPLE_RATE * duration))
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var t := float(i) / float(SAMPLE_RATE)
		var burst := int(t * rng.randf_range(5.0, 8.0))
		var gate := 1.0 if burst % 2 == 0 else 0.35
		var env := gate * exp(-t * rng.randf_range(2.2, 3.4))
		var wobble := sin(t * rng.randf_range(180.0, 320.0) * TAU) * 0.35
		var noise := rng.randf_range(-1.0, 1.0) * 0.55
		var sample := (noise + wobble) * env
		sample = clampf(sample, -1.0, 1.0)
		var int_sample := int(sample * 24000.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF
	return _wav_from_bytes(data)


static func bounce_stream() -> AudioStream:
	var rpg := RpgAudioLibraryScript.landing()
	if rpg != null:
		return rpg
	if _bounce_stream != null:
		return _bounce_stream
	_bounce_stream = _make_bounce()
	return _bounce_stream


static func engine_loop_stream() -> AudioStream:
	var sci_fi := SciFiAudioLibraryScript.engine_loop()
	if sci_fi != null:
		return sci_fi
	var rpg := RpgAudioLibraryScript.engine_loop()
	if rpg != null:
		return rpg
	return honk_stream()


static func _make_honk() -> AudioStreamWAV:
	var duration := 0.34
	var sample_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var t := float(i) / float(SAMPLE_RATE)
		var env := 1.0
		if t < 0.02:
			env = t / 0.02
		elif t > 0.28:
			env = clampf(1.0 - (t - 0.28) / 0.06, 0.0, 1.0)
		var tone_a := sin(t * 420.0 * TAU) * exp(-t * 6.0)
		var tone_b := 0.0
		if t > 0.13:
			var t2 := t - 0.13
			tone_b = sin(t2 * 520.0 * TAU) * exp(-t2 * 7.5)
		var sample := (tone_a * 0.55 + tone_b * 0.65) * env
		sample = clampf(sample, -1.0, 1.0)
		var int_sample := int(sample * 30000.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF
	return _wav_from_bytes(data)


static func _make_bounce() -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 902
	var duration := 0.16
	var sample_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * 22.0)
		var boing := sin(t * rng.randf_range(140.0, 220.0) * TAU) * (1.0 - t * 3.5)
		var slap := sin(t * 80.0 * TAU) * exp(-t * 35.0)
		var sample := (boing * 0.7 + slap * 0.45) * env
		sample = clampf(sample, -1.0, 1.0)
		var int_sample := int(sample * 32000.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF
	return _wav_from_bytes(data)


static func _wav_from_bytes(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream