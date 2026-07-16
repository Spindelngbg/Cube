class_name CriminalBossLore
extends RefCounted

const LABEL_HOSTILE := Color(0.95, 0.22, 0.18)
const LABEL_WARM := Color(0.98, 0.72, 0.28)
const LABEL_RESPECTED := Color(0.55, 0.95, 0.62)

const BOSS_GREETINGS := {
	"hostile": [
		"Vad fan glor du på? Försvinn innan jag ringer på mer folk.",
		"Du har ingen respekt här. Stick.",
		"Jag känner inte igen dig — och det är en förolämpning.",
	],
	"suspicious": [
		"Du vågar kliva in på mitt område. Förklara varför.",
		"Min folk håller koll på dig. Prata snabbt.",
		"Jag har hört rykten. Inte nödvändigtvis bra.",
	],
	"neutral": [
		"Du börjar bli bekant. Det kan vara bra — eller dyrt.",
		"Kolonisäkerhet bryr sig inte om oss. Vi bryr oss om lojalitet.",
		"Fortsätt visa respekt så kanske vi gör affärer.",
	],
	"respected": [
		"Ah — en av våra. Gå in, ta en drink. Ingen skjuter dig idag.",
		"Du har bevisat dig. Mitt folk ska slappna av när du är här.",
		"Respekt är allt i den här kuben. Du har förtjänat din.",
	],
}

const HENCHMAN_HOSTILE := [
	"Ey! Tillbaka till spawn med dig!",
	"Bossen sa åt mig att kasta ut folk som dig.",
	"Du luktar problem. Försvinn.",
	"Vi känner inte dig. Stick.",
	"En fel rörelse till så ringer jag backup.",
]

const HENCHMAN_RESPECTED := [
	"Bossen väntar inne. Du är okej här.",
	"Hej. Håll dig på stigen så blir det ingen skada.",
	"Vi har fått order: du är gäst, inte måltavla.",
	"Respekt till dig. Gå vidare.",
]


static func tier_from_respect(respect: int) -> String:
	if respect < 20:
		return "hostile"
	if respect < 45:
		return "suspicious"
	if respect < 75:
		return "neutral"
	return "respected"


static func format_boss_title(boss_name: String, syndicate: String) -> String:
	return "%s — %s" % [boss_name, syndicate]


static func format_henchman_name(name: String) -> String:
	return "Syndikatmus — %s" % name


static func pick_boss_greeting(tier: String, rng: RandomNumberGenerator) -> String:
	var lines: Array = BOSS_GREETINGS.get(tier, BOSS_GREETINGS.neutral)
	return str(lines[rng.randi() % lines.size()])


static func pick_henchman_line(respected: bool, rng: RandomNumberGenerator) -> String:
	var pool: Array = HENCHMAN_RESPECTED if respected else HENCHMAN_HOSTILE
	return str(pool[rng.randi() % pool.size()])


static func label_color_for_tier(tier: String) -> Color:
	match tier:
		"hostile", "suspicious":
			return LABEL_HOSTILE
		"neutral":
			return LABEL_WARM
		_:
			return LABEL_RESPECTED


static func build_avatar(seed: int, entry: Dictionary) -> AvatarData:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var data := AvatarData.new()
	var is_boss := bool(entry.get("criminal_boss", false))
	data.body_scale = float(entry.get("scale", 1.0)) * (1.08 if is_boss else 1.12)
	data.body_color = Color.from_hsv(rng.randf_range(0.0, 0.06), rng.randf_range(0.35, 0.55), rng.randf_range(0.08, 0.16))
	data.accent_color = Color.from_hsv(0.0, rng.randf_range(0.7, 0.95), rng.randf_range(0.25, 0.45))
	data.glow_color = Color(0.95, 0.15, 0.1)
	data.glow_strength = 0.35 if is_boss else 0.22
	data.leg_length = rng.randf_range(1.05, 1.2)
	data.arm_length = rng.randf_range(1.1, 1.28)
	return data