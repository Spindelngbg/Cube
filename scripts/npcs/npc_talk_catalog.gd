class_name NpcTalkCatalog
extends RefCounted

## Generiska dialograder för NPCs som saknar egen story/factory-dialog.

const PEDESTRIAN_LINES: Array[String] = [
	"Hej! Vädret är okej för kolonin — i alla fall idag.",
	"Ursäkta, har bråttom till mallen. Priserna är galna.",
	"Såg du Zezzlor-patrullen? Håll dig snäll så går det bra.",
	"Mydrillium-priserna skenar. Jag sparar till en ny cykel.",
	"Kapitolplazan är fin, men det är trångt på Nationalmallen.",
	"Jag bor två block bort. Grannen har en skrikande drönare.",
	"Hörde rykten om SRC söderut. Jag håller mig norrut.",
	"Kul att se en ny ansikte. Välkommen till Koloni 4.",
	"Gatlyktorna flimrar igen. Någon borde laga dem.",
	"Passa dig för glada säljare vid mallarna — de tar hela plånboken.",
]

const CHILD_LINES: Array[String] = [
	"Titta! Gungan går jättehögt!",
	"Vill du leka ikull? Jag är snabbast!",
	"Parkvakten sa att man inte får kasta sand… men det är roligt.",
	"Min kompis har en laserpinne. Den är inte äkta dock.",
	"Hej! Har du godis? Nej? Okej… hejdå!",
	"Jag såg en stor robot. Den lät som en dammsugare.",
]

const GUARD_LINES: Array[String] = [
	"Parkvakt på pass. Håll er snälla i lekparken.",
	"Inga knuffar på rutschkanan — jag ser dig.",
	"Barnen ska ha kul. Du får gärna titta, men ingen bus.",
	"Om du ser trasig utrustning, säg till. Vi lagar fort.",
	"Kvällspasset är lugnare. Dagtid är det kaos — på ett bra sätt.",
]

const GENERIC_LINES: Array[String] = [
	"Hej där. Bra dag för en promenad i kolonin.",
	"Något du undrar över? Jag kan tipsa lite om området.",
	"Håll dig undan bråk och ha Znood i ordning — det sparar tid.",
	"Koloni 4 har allt: butiker, jobb och lite för mycket patruller.",
	"Lycka till där ute. Det behövs ibland.",
]


static func resolve(entry: Dictionary, display_name: String, seed: int = 0) -> Dictionary:
	var title := str(entry.get("dialogue_title", ""))
	var body := str(entry.get("dialogue_body", ""))
	if title == "":
		title = display_name if display_name != "" else str(entry.get("name", "NPC"))
	if body != "":
		return {"title": title, "body": body}

	var rng := RandomNumberGenerator.new()
	rng.seed = seed if seed != 0 else hash(str(entry.get("id", display_name)))

	if bool(entry.get("playground_child", false)):
		return {
			"title": title,
			"body": _pick(CHILD_LINES, rng),
		}
	if bool(entry.get("playground_guard", false)):
		return {
			"title": title,
			"body": _pick(GUARD_LINES, rng),
		}
	if bool(entry.get("pedestrian", false)):
		var wallet := int(entry.get("wallet", 0))
		var line := _pick(PEDESTRIAN_LINES, rng)
		if wallet > 5000 and rng.randf() < 0.35:
			line += "\n\n(De ser ut att ha ordentligt med Mydrillium i fickan.)"
		return {"title": title, "body": line}

	return {
		"title": title,
		"body": _pick(GENERIC_LINES, rng),
	}


static func default_prompt(display_name: String) -> String:
	if display_name == "" or display_name == "NPC":
		return "Prata [E]"
	return "Prata med %s [E]" % display_name


static func _pick(pool: Array[String], rng: RandomNumberGenerator) -> String:
	if pool.is_empty():
		return "..."
	return pool[rng.randi() % pool.size()]
