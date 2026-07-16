class_name HelpRobotVoiceLibrary
extends RefCounted

const SciFiAudioLibraryScript = preload("res://scripts/audio/sci_fi_audio_library.gd")


static func greet_stream() -> AudioStream:
	return SciFiAudioLibraryScript.bot_greet()


static func open_stream() -> AudioStream:
	return SciFiAudioLibraryScript.bot_ui_open()


static func close_stream() -> AudioStream:
	return SciFiAudioLibraryScript.bot_ui_close()


static func answer_stream() -> AudioStream:
	return SciFiAudioLibraryScript.bot_ui_select(0)


static func question_stream(index: int) -> AudioStream:
	return SciFiAudioLibraryScript.bot_ui_select(index)