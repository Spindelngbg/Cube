class_name RpgAudioLibrary
extends RefCounted

const SciFiAudioLibraryScript = preload("res://scripts/audio/sci_fi_audio_library.gd")

## Kenney RPG Audio (CC0) — https://kenney.nl/assets/rpg-audio

const ROOT := "res://assets/audio/kenney-rpg-audio/Audio/"

## Mjukare tyg-/lädersteg — de hårda footstepXX låter för skarpa i kolonin.
const FOOTSTEPS := [
	ROOT + "cloth1.ogg",
	ROOT + "cloth2.ogg",
	ROOT + "cloth3.ogg",
	ROOT + "cloth4.ogg",
	ROOT + "clothBelt.ogg",
	ROOT + "dropLeather.ogg",
	ROOT + "handleSmallLeather.ogg",
	ROOT + "handleSmallLeather2.ogg",
	ROOT + "footstep06.ogg",
	ROOT + "footstep07.ogg",
]

const PUNCH_SWING := [ROOT + "cloth2.ogg", ROOT + "cloth3.ogg", ROOT + "cloth4.ogg"]
const PUNCH_HIT := [ROOT + "knifeSlice.ogg", ROOT + "knifeSlice2.ogg", ROOT + "chop.ogg"]
const MELEE_SWING := [ROOT + "drawKnife1.ogg", ROOT + "drawKnife2.ogg", ROOT + "clothBelt.ogg"]
const MELEE_HIT := [ROOT + "knifeSlice.ogg", ROOT + "knifeSlice2.ogg", ROOT + "chop.ogg"]
const HSG_AXE_SWING := "res://assets/audio/hsg-axe/axe_swing.mp3"
const LASER_FIRE := [ROOT + "drawKnife1.ogg", ROOT + "drawKnife2.ogg", ROOT + "metalClick.ogg"]
const SLIME_FIRE := [ROOT + "clothBelt.ogg", ROOT + "clothBelt2.ogg", ROOT + "cloth1.ogg"]
const RELOAD := [ROOT + "metalLatch.ogg", ROOT + "beltHandle1.ogg", ROOT + "beltHandle2.ogg"]
const PICKUP_ITEM := [ROOT + "handleSmallLeather.ogg", ROOT + "handleSmallLeather2.ogg", ROOT + "bookPlace1.ogg"]
const PICKUP_WEAPON := [ROOT + "drawKnife3.ogg", ROOT + "beltHandle2.ogg"]
const SHOP_BUY := [ROOT + "handleCoins.ogg", ROOT + "handleCoins2.ogg"]
const DOOR_OPEN := [ROOT + "doorOpen_1.ogg", ROOT + "doorOpen_2.ogg"]
const DOOR_CLOSE := [ROOT + "doorClose_1.ogg", ROOT + "doorClose_2.ogg", ROOT + "doorClose_3.ogg"]
const DOOR_CREAK := [ROOT + "creak1.ogg", ROOT + "creak2.ogg", ROOT + "creak3.ogg"]
const UI_OPEN := [ROOT + "bookOpen.ogg", ROOT + "bookFlip1.ogg"]
const UI_CLOSE := [ROOT + "bookClose.ogg"]
const UI_SELECT := [ROOT + "bookFlip2.ogg", ROOT + "bookFlip3.ogg", ROOT + "bookPlace2.ogg"]
const QUEST_COMPLETE := [ROOT + "bookPlace1.ogg", ROOT + "bookPlace2.ogg", ROOT + "bookPlace3.ogg"]
const BOT_ALERT := [ROOT + "metalPot1.ogg", ROOT + "metalPot2.ogg", ROOT + "metalPot3.ogg"]
const ZEZZLOR_LASER_BANG := [
	ROOT + "metalPot1.ogg",
	ROOT + "metalPot2.ogg",
	ROOT + "metalPot3.ogg",
	ROOT + "metalLatch.ogg",
]
const ZEZZLOR_LASER_HIT := [ROOT + "metalClick.ogg", ROOT + "chop.ogg", ROOT + "knifeSlice2.ogg"]
const BOT_GREET := [ROOT + "cloth1.ogg", ROOT + "cloth2.ogg"]
const LANDING := [ROOT + "dropLeather.ogg", ROOT + "bookPlace3.ogg"]
const PROJECTILE_HIT := [ROOT + "knifeSlice2.ogg", ROOT + "chop.ogg", ROOT + "metalClick.ogg"]
const STAMP := [ROOT + "metalLatch.ogg", ROOT + "metalClick.ogg"]
const ENGINE_LOOP := ROOT + "creak2.ogg"


static func load_stream(path: String) -> AudioStream:
	return load(path) as AudioStream


static func from_pool(pool: Array, index: int = -1) -> AudioStream:
	if pool.is_empty():
		return null
	var pick := index if index >= 0 else randi() % pool.size()
	return load_stream(str(pool[pick % pool.size()]))


static func footstep(index: int) -> AudioStream:
	return from_pool(FOOTSTEPS, index)


static func punch_swing() -> AudioStream:
	return from_pool(PUNCH_SWING)


static func punch_hit() -> AudioStream:
	return from_pool(PUNCH_HIT)


static func melee_swing(weapon_id: String = "") -> AudioStream:
	if weapon_id == "hsg_survival_axe":
		var axe := load_stream(HSG_AXE_SWING)
		if axe != null:
			return axe
	return from_pool(MELEE_SWING)


static func melee_hit() -> AudioStream:
	return from_pool(MELEE_HIT)


static func laser_fire() -> AudioStream:
	var sci_fi := SciFiAudioLibraryScript.laser_fire()
	if sci_fi != null:
		return sci_fi
	return from_pool(LASER_FIRE)


static func laser_hit() -> AudioStream:
	var sci_fi := SciFiAudioLibraryScript.laser_hit()
	if sci_fi != null:
		return sci_fi
	return from_pool(PROJECTILE_HIT)


static func laser_reload() -> AudioStream:
	var sci_fi := SciFiAudioLibraryScript.laser_reload()
	if sci_fi != null:
		return sci_fi
	return from_pool(RELOAD)


static func slime_fire() -> AudioStream:
	return from_pool(SLIME_FIRE)


static func zezzlor_laser_bang() -> AudioStream:
	return from_pool(ZEZZLOR_LASER_BANG)


static func zezzlor_laser_hit() -> AudioStream:
	return from_pool(ZEZZLOR_LASER_HIT)


static func reload() -> AudioStream:
	return from_pool(RELOAD)


static func pickup_item() -> AudioStream:
	return from_pool(PICKUP_ITEM)


static func pickup_weapon() -> AudioStream:
	return from_pool(PICKUP_WEAPON)


static func shop_buy() -> AudioStream:
	return from_pool(SHOP_BUY)


static func door_open() -> AudioStream:
	return from_pool(DOOR_OPEN)


static func door_close() -> AudioStream:
	return from_pool(DOOR_CLOSE)


static func door_creak() -> AudioStream:
	return from_pool(DOOR_CREAK)


static func ui_open() -> AudioStream:
	return from_pool(UI_OPEN)


static func ui_close() -> AudioStream:
	return from_pool(UI_CLOSE)


static func ui_select(index: int = -1) -> AudioStream:
	return from_pool(UI_SELECT, index)


static func quest_complete() -> AudioStream:
	return from_pool(QUEST_COMPLETE)


static func bot_alert() -> AudioStream:
	var sci_fi := SciFiAudioLibraryScript.bot_alert()
	if sci_fi != null:
		return sci_fi
	return from_pool(BOT_ALERT)


static func bot_greet() -> AudioStream:
	var sci_fi := SciFiAudioLibraryScript.bot_greet()
	if sci_fi != null:
		return sci_fi
	return from_pool(BOT_GREET)


static func landing() -> AudioStream:
	return from_pool(LANDING)


static func projectile_hit() -> AudioStream:
	return from_pool(PROJECTILE_HIT)


static func stamp() -> AudioStream:
	return from_pool(STAMP)


static func engine_loop() -> AudioStream:
	var sci_fi := SciFiAudioLibraryScript.engine_loop()
	if sci_fi != null:
		return sci_fi
	return load_stream(ENGINE_LOOP)