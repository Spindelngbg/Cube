class_name SrcGuardLore
extends RefCounted

const FACTION_NAME := "Shawshank Security"
const FACTION_SHORT := "SRC Security"
const UNIFORM_COLOR := Color(0.85, 0.18, 0.14)
const LABEL_COLOR := Color(0.98, 0.42, 0.32)

const ROLES := {
	"guard": {
		"title": "Vakt",
		"prefix": "SRC-vakt",
	},
	"patrol": {
		"title": "Patrull",
		"prefix": "SRC-patrull",
	},
	"supervisor": {
		"title": "Platschef",
		"prefix": "SRC-platschef",
	},
	"chief": {
		"title": "Säkerhetschef",
		"prefix": "SRC-säkerhetschef",
	},
}


static func get_role(role_id: String) -> Dictionary:
	return ROLES.get(role_id, ROLES.guard)


static func role_title(role_id: String) -> String:
	return str(get_role(role_id).get("title", "Vakt"))


static func role_prefix(role_id: String) -> String:
	return str(get_role(role_id).get("prefix", "SRC-vakt"))


static func format_name(role_id: String, personal_name: String = "") -> String:
	var prefix := role_prefix(role_id)
	var name := personal_name.strip_edges()
	if name != "":
		return "%s %s" % [prefix, name]
	return prefix


static func format_dialogue_title(role_id: String, personal_name: String) -> String:
	return "%s — %s" % [format_name(role_id, personal_name), FACTION_SHORT]


const SNOOP_SPEED := 2.4
const RETURN_SPEED := 1.6
const SNOOP_DISTANCE := 5.0
const BLOCK_RANGE_M := 24.0
const HARASS_RANGE_M := 9.0
const HARASS_COOLDOWN := 5.5
const BLOCK_COOLDOWN_MIN := 4.0
const BLOCK_COOLDOWN_MAX := 8.0

const HARASS_SNOOP_LINES := [
	"Vad gör du här? Det här är SRC-mark.",
	"Håll avstånd från HQ, kolonist.",
	"Vi har ögon överallt. Bokstavligen.",
	"Du rör dig som om du inte vore scannad än.",
	"Stanna lite. Jag vill se ditt Znood igen.",
	"Ingen loitering inom en kilometer från HQ.",
	"Rapporterar din rörelse till Redemption-konsolen.",
	"Du luktar nyfikenhet. SRC gillar inte det.",
]

const HARASS_BLOCK_LINES := [
	"Du ska inte förbi här.",
	"Tillbaka. Detta område är avspärrat.",
	"Jag lägger mig i — det är mitt jobb nära HQ.",
	"Stopp. Shawshank Security har frågor.",
]


static func random_harass_line(kind: String, rng: RandomNumberGenerator) -> String:
	var pool: Array = HARASS_BLOCK_LINES if kind == "block" else HARASS_SNOOP_LINES
	if pool.is_empty():
		return "SRC-vakten snokar på dig."
	return str(pool[rng.randi_range(0, pool.size() - 1)])