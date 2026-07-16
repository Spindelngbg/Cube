extends Node

## Text-to-speech for Guide-Bot dialog. Uses xAI TTS when XAI_API_KEY is set,
## otherwise falls back to the OS voice (Windows/macOS/Linux).

signal speech_started
signal speech_finished

const XAI_TTS_URL := "https://api.x.ai/v1/tts"
const CACHE_DIR := "user://help_robot_tts/"
const DEFAULT_VOICE_ID := "eve"
const DEFAULT_LANGUAGE := "sv"

var _http: HTTPRequest
var _queue: Array[Dictionary] = []
var _active := false
var _utterance_id := 0
var _api_key := ""
var _active_player: Node = null
var _pending: Dictionary = {}


func _ready() -> void:
	_api_key = OS.get_environment("XAI_API_KEY").strip_edges()
	_http = HTTPRequest.new()
	_http.timeout = 25.0
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	if _system_tts_available():
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, _on_system_utterance)


func is_speaking() -> bool:
	if _active:
		return true
	if _system_tts_available() and DisplayServer.tts_is_speaking():
		return true
	return false


func stop() -> void:
	_queue.clear()
	_active = false
	_pending.clear()
	if _system_tts_available():
		DisplayServer.tts_stop()
	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http.cancel_request()
	_stop_active_player()


func speak(
	text: String,
	player: Variant = null,
	interrupt: bool = false
) -> void:
	var cleaned := _clean_text(text)
	if cleaned.is_empty():
		return
	if interrupt:
		stop()
	_queue.append({
		"text": cleaned,
		"player": player,
	})
	if not _active:
		_process_queue()


func _process_queue() -> void:
	if _queue.is_empty():
		_active = false
		speech_finished.emit()
		return
	_active = true
	var item: Dictionary = _queue.pop_front()
	_pending = item
	var text: String = str(item.get("text", ""))
	var player: Variant = item.get("player", null)
	speech_started.emit()

	var cache_path := _cache_path(text)
	if FileAccess.file_exists(cache_path):
		var cached := _load_mp3_file(cache_path)
		if cached != null:
			_play_stream(cached, player)
			return

	if _api_key != "":
		_request_xai_tts(text, cache_path, player)
		return

	_speak_system(text)


func _request_xai_tts(text: String, cache_path: String, player: Variant) -> void:
	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http.cancel_request()
	var headers := PackedStringArray([
		"Authorization: Bearer %s" % _api_key,
		"Content-Type: application/json",
		"Accept: audio/mpeg",
	])
	var payload := {
		"text": text,
		"voice_id": DEFAULT_VOICE_ID,
		"language": DEFAULT_LANGUAGE,
	}
	var err := _http.request(
		XAI_TTS_URL,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	if err != OK:
		push_warning("HelpRobotTts: xAI request failed (%s), using system voice." % error_string(err))
		_speak_system(text)


func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	var text: String = str(_pending.get("text", ""))
	var player: Variant = _pending.get("player", null)
	var cache_path := _cache_path(text)

	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300 or body.is_empty():
		push_warning(
			"HelpRobotTts: xAI TTS failed (result=%s code=%s), using system voice."
			% [result, response_code]
		)
		_speak_system(text)
		return

	var file := FileAccess.open(cache_path, FileAccess.WRITE)
	if file != null:
		file.store_buffer(body)
		file.close()

	var stream := _mp3_from_bytes(body)
	if stream == null:
		_speak_system(text)
		return
	_play_stream(stream, player)


func _system_tts_available() -> bool:
	return not DisplayServer.tts_get_voices().is_empty()


func _speak_system(text: String) -> void:
	if not _system_tts_available():
		_finish_current_line()
		return
	_utterance_id += 1
	var voice := _pick_voice()
	DisplayServer.tts_speak(text, voice, 85, 1.08, 1.0, _utterance_id, false)


func _on_system_utterance(_utterance_id: int) -> void:
	_finish_current_line()


func _play_stream(stream: AudioStream, player: Variant) -> void:
	_stop_active_player()
	var audio_player: Node = _resolve_player(player)
	if audio_player == null:
		audio_player = _create_fallback_player()
	_active_player = audio_player

	if audio_player is AudioStreamPlayer:
		(audio_player as AudioStreamPlayer).stream = stream
		(audio_player as AudioStreamPlayer).pitch_scale = randf_range(0.98, 1.02)
		if not (audio_player as AudioStreamPlayer).finished.is_connected(_on_audio_finished):
			(audio_player as AudioStreamPlayer).finished.connect(_on_audio_finished)
		(audio_player as AudioStreamPlayer).play()
	elif audio_player is AudioStreamPlayer3D:
		(audio_player as AudioStreamPlayer3D).stream = stream
		(audio_player as AudioStreamPlayer3D).pitch_scale = randf_range(0.98, 1.02)
		if not (audio_player as AudioStreamPlayer3D).finished.is_connected(_on_audio_finished):
			(audio_player as AudioStreamPlayer3D).finished.connect(_on_audio_finished)
		(audio_player as AudioStreamPlayer3D).play()
	else:
		_finish_current_line()


func _resolve_player(player: Variant) -> Node:
	if player is AudioStreamPlayer or player is AudioStreamPlayer3D:
		return player
	return null


func _create_fallback_player() -> AudioStreamPlayer:
	var fallback := AudioStreamPlayer.new()
	fallback.name = "HelpRobotTtsFallback"
	fallback.bus = &"Sfx"
	add_child(fallback)
	return fallback


func _on_audio_finished() -> void:
	_finish_current_line()


func _finish_current_line() -> void:
	_pending.clear()
	call_deferred("_process_queue")


func _stop_active_player() -> void:
	if _active_player == null:
		return
	if _active_player is AudioStreamPlayer:
		var p := _active_player as AudioStreamPlayer
		if p.finished.is_connected(_on_audio_finished):
			p.finished.disconnect(_on_audio_finished)
		p.stop()
	elif _active_player is AudioStreamPlayer3D:
		var p3d := _active_player as AudioStreamPlayer3D
		if p3d.finished.is_connected(_on_audio_finished):
			p3d.finished.disconnect(_on_audio_finished)
		p3d.stop()
	_active_player = null


func _pick_voice() -> String:
	for lang in ["sv-SE", "sv", "sv_SE"]:
		var voices := DisplayServer.tts_get_voices_for_language(lang)
		if not voices.is_empty():
			return str(voices[0])
	for voice_info in DisplayServer.tts_get_voices():
		if voice_info is Dictionary:
			return str(voice_info.get("id", ""))
	return ""


func _clean_text(text: String) -> String:
	var cleaned := text.strip_edges()
	cleaned = cleaned.replace("[E]", "E")
	cleaned = cleaned.replace("Z-nood", "Z nood")
	cleaned = cleaned.replace("Mydrillium", "My drillium")
	cleaned = cleaned.replace("Mountblast 3000", "Mount blast 3000")
	cleaned = cleaned.replace("Mk-II", "Mark 2")
	cleaned = cleaned.replace("Stål-Sven", "Stål Sven")
	return cleaned


func _cache_path(text: String) -> String:
	return CACHE_DIR + "%08x.mp3" % hash(text)


func _mp3_from_bytes(data: PackedByteArray) -> AudioStreamMP3:
	if data.is_empty():
		return null
	var stream := AudioStreamMP3.new()
	stream.data = data
	return stream


func _load_mp3_file(path: String) -> AudioStreamMP3:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return _mp3_from_bytes(file.get_buffer(file.get_length()))