class_name SciFiAudioLibrary
extends RefCounted

## Kenney Sci-fi Sounds (CC0) — https://kenney.nl/assets/sci-fi-sounds

const ROOT := "res://assets/audio/kenney-sci-fi-sounds/Audio/"

const LASER_FIRE := [
	ROOT + "laserSmall_000.ogg",
	ROOT + "laserSmall_001.ogg",
	ROOT + "laserSmall_002.ogg",
	ROOT + "laserSmall_003.ogg",
	ROOT + "laserSmall_004.ogg",
	ROOT + "laserRetro_000.ogg",
	ROOT + "laserRetro_001.ogg",
	ROOT + "laserRetro_002.ogg",
]

const LASER_HEAVY := [
	ROOT + "laserLarge_000.ogg",
	ROOT + "laserLarge_001.ogg",
	ROOT + "laserLarge_002.ogg",
	ROOT + "laserLarge_003.ogg",
]

const LASER_HIT := [
	ROOT + "impactMetal_000.ogg",
	ROOT + "impactMetal_001.ogg",
	ROOT + "impactMetal_002.ogg",
	ROOT + "forceField_000.ogg",
	ROOT + "forceField_001.ogg",
]

const LASER_RELOAD := [
	ROOT + "forceField_002.ogg",
	ROOT + "forceField_003.ogg",
	ROOT + "forceField_004.ogg",
]

const BOT_VOICE := [
	ROOT + "computerNoise_000.ogg",
	ROOT + "computerNoise_001.ogg",
	ROOT + "computerNoise_002.ogg",
	ROOT + "computerNoise_003.ogg",
]

const BOT_GREET := [
	ROOT + "computerNoise_000.ogg",
	ROOT + "computerNoise_002.ogg",
]

const BOT_ALERT := [
	ROOT + "engineCircular_000.ogg",
	ROOT + "engineCircular_001.ogg",
	ROOT + "thrusterFire_000.ogg",
	ROOT + "thrusterFire_001.ogg",
]

const BOT_UI_OPEN := [
	ROOT + "forceField_000.ogg",
	ROOT + "computerNoise_001.ogg",
]

const BOT_UI_CLOSE := [
	ROOT + "doorClose_000.ogg",
	ROOT + "doorClose_001.ogg",
]

const BOT_UI_SELECT := [
	ROOT + "computerNoise_001.ogg",
	ROOT + "computerNoise_003.ogg",
	ROOT + "forceField_001.ogg",
]

const ENGINE_LOOP := [
	ROOT + "spaceEngine_000.ogg",
	ROOT + "spaceEngine_001.ogg",
	ROOT + "spaceEngine_002.ogg",
	ROOT + "spaceEngineSmall_000.ogg",
	ROOT + "spaceEngineSmall_001.ogg",
]

const ENGINE_HEAVY := [
	ROOT + "spaceEngineLarge_000.ogg",
	ROOT + "spaceEngineLarge_001.ogg",
	ROOT + "spaceEngineLow_000.ogg",
]


static func load_stream(path: String) -> AudioStream:
	return load(path) as AudioStream


static func from_pool(pool: Array, index: int = -1) -> AudioStream:
	if pool.is_empty():
		return null
	var pick := index if index >= 0 else randi() % pool.size()
	return load_stream(str(pool[pick % pool.size()]))


static func laser_fire() -> AudioStream:
	return from_pool(LASER_FIRE)


static func laser_heavy() -> AudioStream:
	return from_pool(LASER_HEAVY)


static func laser_hit() -> AudioStream:
	return from_pool(LASER_HIT)


static func laser_reload() -> AudioStream:
	return from_pool(LASER_RELOAD)


static func bot_voice(index: int = -1) -> AudioStream:
	return from_pool(BOT_VOICE, index)


static func bot_greet() -> AudioStream:
	return from_pool(BOT_GREET)


static func bot_alert() -> AudioStream:
	return from_pool(BOT_ALERT)


static func bot_ui_open() -> AudioStream:
	return from_pool(BOT_UI_OPEN)


static func bot_ui_close() -> AudioStream:
	return from_pool(BOT_UI_CLOSE)


static func bot_ui_select(index: int = -1) -> AudioStream:
	return from_pool(BOT_UI_SELECT, index)


static func engine_loop() -> AudioStream:
	return from_pool(ENGINE_LOOP)


static func engine_heavy() -> AudioStream:
	return from_pool(ENGINE_HEAVY)