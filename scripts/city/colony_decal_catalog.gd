class_name ColonyDecalCatalog
extends RefCounted

## Speltrelaterade affischer / billboards för Koloni 4.

const DECALS: Array = [
	{
		"id": "zezzlor_order",
		"title": "ZEZZLOR",
		"body": "Ordning. Lag.\nBatong.",
		"tag": "KOLONI 4 · POLIS",
		"bg": Color(0.08, 0.14, 0.28),
		"accent": Color(0.35, 0.72, 1.0),
		"text": Color(0.88, 0.94, 1.0),
		"style": "authority",
	},
	{
		"id": "zezzlor_checkpoint",
		"title": "KONTROLLPUNKT",
		"body": "Stämpla Znood\neller vänd om.",
		"tag": "ZEZZLOR · PASS",
		"bg": Color(0.1, 0.16, 0.32),
		"accent": Color(0.45, 0.85, 1.0),
		"text": Color(0.92, 0.96, 1.0),
		"style": "authority",
	},
	{
		"id": "znood_stamp",
		"title": "ZNOOD",
		"body": "Din digitala\nstämpel i kolonin.",
		"tag": "ACCESS · ID",
		"bg": Color(0.06, 0.18, 0.16),
		"accent": Color(0.25, 0.95, 0.72),
		"text": Color(0.85, 1.0, 0.92),
		"style": "tech",
	},
	{
		"id": "src_redemption",
		"title": "SRC",
		"body": "Projekt Redemption\n— vi förbättrar dig.",
		"tag": "SHAWSHANK CORP",
		"bg": Color(0.22, 0.06, 0.06),
		"accent": Color(1.0, 0.22, 0.18),
		"text": Color(1.0, 0.88, 0.85),
		"style": "corp",
	},
	{
		"id": "src_warning",
		"title": "VARNING",
		"body": "Annexet är stängt.\nObehöriga loggas.",
		"tag": "SRC HQ",
		"bg": Color(0.18, 0.05, 0.08),
		"accent": Color(0.95, 0.35, 0.2),
		"text": Color(1.0, 0.9, 0.82),
		"style": "corp",
	},
	{
		"id": "mydrillium",
		"title": "MYDRILLIUM",
		"body": "Malm är lag.\nRåvara. Lön. Makt.",
		"tag": "EKONOMI",
		"bg": Color(0.06, 0.14, 0.08),
		"accent": Color(0.35, 0.95, 0.42),
		"text": Color(0.88, 1.0, 0.9),
		"style": "economy",
	},
	{
		"id": "factory_job",
		"title": "VERKSTAD",
		"body": "Jobba. Tryck knappar.\nFå betalt.",
		"tag": "INDUSTRIKAJ",
		"bg": Color(0.16, 0.12, 0.05),
		"accent": Color(0.98, 0.75, 0.18),
		"text": Color(1.0, 0.95, 0.8),
		"style": "work",
	},
	{
		"id": "neo_welcome",
		"title": "NEO-WASHINGTON",
		"body": "Koloni 4 välkomnar\nbesökare — nästan.",
		"tag": "KAPITOLPLAZA",
		"bg": Color(0.1, 0.1, 0.14),
		"accent": Color(0.95, 0.82, 0.35),
		"text": Color(0.98, 0.95, 0.88),
		"style": "civic",
	},
	{
		"id": "pharmacy",
		"title": "PILL-BOT",
		"body": "Antidot mot slem.\nApotek nära spawn.",
		"tag": "HÄLSA",
		"bg": Color(0.06, 0.14, 0.12),
		"accent": Color(0.45, 0.95, 0.7),
		"text": Color(0.9, 1.0, 0.95),
		"style": "service",
	},
	{
		"id": "allmakare",
		"title": "ALLMAKARE",
		"body": "Heal nu.\nBetala sen (doft).",
		"tag": "ZEZZLOR · KAST",
		"bg": Color(0.16, 0.14, 0.05),
		"accent": Color(0.98, 0.88, 0.28),
		"text": Color(1.0, 0.97, 0.85),
		"style": "service",
	},
	{
		"id": "gleazer",
		"title": "GLEAZERS",
		"body": "Vi ser dig\nfrån taken.",
		"tag": "SPANING",
		"bg": Color(0.08, 0.1, 0.14),
		"accent": Color(0.55, 0.75, 0.95),
		"text": Color(0.9, 0.94, 1.0),
		"style": "faction",
	},
	{
		"id": "mall_neon",
		"title": "NEO-MALL",
		"body": "Köp. Jonglera.\nZnood-dörr.",
		"tag": "SHOPPING",
		"bg": Color(0.14, 0.05, 0.12),
		"accent": Color(1.0, 0.3, 0.65),
		"text": Color(1.0, 0.9, 0.96),
		"style": "neon",
	},
	{
		"id": "playground",
		"title": "LEKPARK 9",
		"body": "Barn springer.\nVakter vakar.",
		"tag": "PARK",
		"bg": Color(0.08, 0.14, 0.1),
		"accent": Color(0.45, 0.9, 0.5),
		"text": Color(0.92, 1.0, 0.9),
		"style": "civic",
	},
	{
		"id": "criminal",
		"title": "INGA FRÅGOR",
		"body": "Respekt köps.\nLjud säljs inte.",
		"tag": "UNDERWORLD",
		"bg": Color(0.1, 0.08, 0.1),
		"accent": Color(0.75, 0.35, 0.55),
		"text": Color(0.95, 0.88, 0.92),
		"style": "crime",
	},
	{
		"id": "spider_cube",
		"title": "THE CUBE",
		"body": "Spindlar. Kolonier.\nDin historia.",
		"tag": "SPINDELNGBG",
		"bg": Color(0.08, 0.07, 0.12),
		"accent": Color(0.78, 0.55, 1.0),
		"text": Color(0.95, 0.9, 1.0),
		"style": "meta",
	},
	{
		"id": "slime_caution",
		"title": "SLEM",
		"body": "Skjut inte civila.\nZezzlor svarar.",
		"tag": "SÄKERHET",
		"bg": Color(0.08, 0.16, 0.08),
		"accent": Color(0.4, 1.0, 0.35),
		"text": Color(0.9, 1.0, 0.88),
		"style": "warning",
	},
]


static func pick(seed_value: int) -> Dictionary:
	if DECALS.is_empty():
		return {}
	var idx := absi(seed_value) % DECALS.size()
	return (DECALS[idx] as Dictionary).duplicate(true)


static func pick_for_zone(zone_type: String, seed_value: int) -> Dictionary:
	var preferred: Array[String] = []
	match zone_type:
		"SRC_LAB":
			preferred = ["src_redemption", "src_warning", "slime_caution"]
		"INDUSTRIKAJ", "VERKSTADSFABRIK", "TRANSITNAV":
			preferred = ["factory_job", "mydrillium", "zezzlor_order"]
		"KAPITOLPLAZA", "NATIONALMALLEN", "MONUMENTKÄRNA":
			preferred = ["neo_welcome", "zezzlor_order", "znood_stamp"]
		"BOSTADSKVARTER", "AMBASSADNÄSET":
			preferred = ["pharmacy", "allmakare", "playground", "znood_stamp"]
		"KONTORSGRID", "FEDERALT_KVARTER":
			preferred = ["zezzlor_checkpoint", "mydrillium", "gleazer"]
		"VATTENFRONT":
			preferred = ["criminal", "gleazer", "src_warning"]
		_:
			preferred = []
	if preferred.is_empty():
		return pick(seed_value)
	var id: String = preferred[absi(seed_value) % preferred.size()]
	for d in DECALS:
		if str(d.get("id", "")) == id:
			return (d as Dictionary).duplicate(true)
	return pick(seed_value)
