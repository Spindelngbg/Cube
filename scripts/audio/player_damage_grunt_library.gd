class_name PlayerDamageGruntLibrary
extends RefCounted

const SuperDialogueAudioLibraryScript = preload("res://scripts/audio/super_dialogue_audio_library.gd")

const MALE_ROOT := "res://assets/audio/player_damage_grunts/male/"
const MALE_COUNT := 22

const FEMALE_VOICES: Array[String] = ["karen", "meghan"]


static func normalize_gender(gender: String) -> String:
	var g := gender.strip_edges().to_lower()
	if g in ["man", "male", "m"]:
		return "man"
	if g in ["kvinna", "female", "f", "woman", "kvinn"]:
		return "kvinna"
	if g in ["hermafrodit", "hermaphrodite", "herm", "inter"]:
		return "hermafrodit"
	return "man"


static func grunt_for_gender(gender: String, variant: int = -1) -> AudioStream:
	var normalized := normalize_gender(gender)
	match normalized:
		"man":
			return _male_grunt(variant)
		"kvinna":
			return _female_damage(variant)
		"hermafrodit":
			if randi() % 2 == 0:
				return _male_grunt(variant)
			return _female_damage(variant)
	return _male_grunt(variant)


static func pitch_range_for_gender(gender: String) -> Vector2:
	var normalized := normalize_gender(gender)
	match normalized:
		"hermafrodit":
			return Vector2(0.88, 1.12)
		"kvinna":
			return Vector2(0.96, 1.08)
		_:
			return Vector2(0.92, 1.08)


static func _male_grunt(variant: int) -> AudioStream:
	var pick := variant if variant >= 1 else (randi() % MALE_COUNT + 1)
	for attempt in range(MALE_COUNT):
		var idx := ((pick - 1 + attempt) % MALE_COUNT) + 1
		var path := "%sdamage_grunt_%02d.wav" % [MALE_ROOT, idx]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null


static func _female_damage(variant: int) -> AudioStream:
	var voice := FEMALE_VOICES[randi() % FEMALE_VOICES.size()]
	var stream := SuperDialogueAudioLibraryScript.bark("damage", voice, variant if variant >= 1 else -1)
	if stream != null:
		return stream
	return SuperDialogueAudioLibraryScript.bark("grunting", voice)