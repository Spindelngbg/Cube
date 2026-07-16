class_name ZezzlorVoiceLibrary
extends RefCounted

const GREETING_PATH := "res://assets/audio/zezzlor/zezzlor_greeting_voice.wav"


static func greeting_stream() -> AudioStream:
	return load(GREETING_PATH) as AudioStream