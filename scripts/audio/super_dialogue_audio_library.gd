class_name SuperDialogueAudioLibrary
extends RefCounted

## Super Dialogue Audio Pack v1 — korta röstbarks (wav), inte full TTS.

const ROOT := (
	"res://assets/audio/super_dialogue_pack/Super Dialogue Audio Pack v1/Step 2 - Audio Files/"
)

const VOICES := {
	"karen": "Female/Karen Cenon",
	"meghan": "Female/Meghan Christian",
	"alex": "Male/Alex Brodie",
	"ian": "Male/Ian Lampert",
	"sean": "Male/Sean Lenhart",
}

const CATEGORIES := {
	"completion": {"dir": "1 - Completion", "prefix": "completion", "max": 10},
	"confirmation": {"dir": "2 - Confirmation", "prefix": "confirmation", "max": 10},
	"greeting": {"dir": "3 - Greeting", "prefix": "greeting", "max": 10},
	"farewell": {"dir": "4 - Farewell", "prefix": "farewell", "max": 10},
	"refusal": {"dir": "5 - Refusal", "prefix": "refusal", "max": 10},
	"miscellaneous": {"dir": "6 - Miscellaneous", "prefix": "miscellaneous", "max": 20},
	"damage": {"dir": "7 - Damage", "prefix": "damage", "max": 10},
	"death": {"dir": "8 - Death", "prefix": "death", "max": 10},
	"grunting": {"dir": "9 - Grunting", "prefix": "grunting", "max": 10},
	"shouting": {"dir": "10 - Shouting", "prefix": "shouting", "max": 10},
}

const FEMALE_VOICE_HINTS := [
	"mara", "ellis", "priya", "karen", "meghan", "gleazer", "allmakare",
]


static func bark(category: String, voice: String, index: int = -1) -> AudioStream:
	var cat: Dictionary = CATEGORIES.get(category, {})
	if cat.is_empty():
		return null
	var voice_key := voice.to_lower()
	if not VOICES.has(voice_key):
		voice_key = "ian"
	var max_idx: int = int(cat.get("max", 10))
	var pick := index if index >= 1 else (randi() % max_idx + 1)
	var prefix: String = str(cat.get("prefix", category))
	for attempt in range(max_idx):
		var idx := ((pick - 1 + attempt) % max_idx) + 1
		var path := (
			ROOT
			+ str(cat.get("dir", ""))
			+ "/"
			+ str(VOICES[voice_key])
			+ "/"
			+ "%s_%d_%s.wav" % [prefix, idx, voice_key]
		)
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null


static func voice_for_id(id: String) -> String:
	var lower := id.to_lower()
	for hint in FEMALE_VOICE_HINTS:
		if lower.contains(hint):
			return "karen" if abs(hash(id)) % 2 == 0 else "meghan"
	var male: PackedStringArray = PackedStringArray(["alex", "ian", "sean"])
	return male[abs(hash(id)) % male.size()]