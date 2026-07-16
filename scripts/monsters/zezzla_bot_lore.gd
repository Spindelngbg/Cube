class_name ZezzlaBotLore
extends RefCounted

const BOT_NAME := "Zezzla-Bot"

const STARE_LINES: Array[String] = [
	"...",
	"Jag bara tittar. Det räcker.",
	"Du rör dig fel. Jag loggar det inte. Än.",
	"Stilla. Jag räknar dina steg.",
	"Jag är inte här. Du ser bara mig.",
	"Zezzla-Bot har inga frågor. Zezzla-Bot har bara ögon.",
	"Din närvaro är noterad i ett fönster ingen öppnat.",
	"Jag åker sakta så du hinner känna dig iakttagen.",
	"Patrull avbruten. Observation pågår.",
	"Kolonin ser dig. Jag gör det också. Längre.",
	"Det här är inte en kontroll. Det är en paus.",
	"Jag åker snart. Men först ska du veta att jag var här.",
]


static func pick_stare_line(rng: RandomNumberGenerator) -> String:
	if rng == null:
		return STARE_LINES[0]
	return STARE_LINES[rng.randi() % STARE_LINES.size()]