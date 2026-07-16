class_name GleazerQuestCatalog
extends RefCounted

## Absurda Gleazer-uppdrag — avslutas alltid med komisk fail.

const TEMPLATES: Array = [
	{
		"id": "fetch_slime_bucket",
		"title": "Hämta den heliga slemmet",
		"objective": "Kom tillbaka till uppdragsgivaren inom 45 sekunder",
		"briefing": "Vi tappade vår 'taktiska slemmet'. Den är någonstans. Spring tillbaka så fort du kan.",
		"kind": "return_timer",
		"duration": 45.0,
		"fail_detail": "Det där var inte vår slemmet — det var lunch. Quest fail.",
	},
	{
		"id": "stand_still",
		"title": "Stå helt stilla som en proffs",
		"objective": "Stå stilla i 6 sekunder nära Gleazern",
		"briefing": "Zezzlor rör sig för mycket. Visa oss hur man står stilla. Bokstavligen.",
		"kind": "stand_still",
		"duration": 6.0,
		"radius": 7.0,
		"fail_detail": "Du stod stilla på FEL ställe. Det skulle vara 40 cm åt vänster. Fail.",
	},
	{
		"id": "run_circles",
		"title": "Spring runt Gleazern",
		"objective": "Rör dig snabbt runt uppdragsgivaren i 8 sekunder",
		"briefing": "Vi måste distrahera en osynlig fiende. Spring runt oss. Förtroende inget.",
		"kind": "orbit",
		"duration": 8.0,
		"radius_min": 3.0,
		"radius_max": 9.0,
		"fail_detail": "Du sprang medsols. Fienden krävde motsols. Klassisk Gleazers-tabbe.",
	},
	{
		"id": "find_invisible_spider",
		"title": "Hitta den osynliga spindeln",
		"objective": "Vänta 20 sekunder och hoppas",
		"briefing": "Den finns. Den är osynlig. Vi såg den på pappret. Leta intensivt.",
		"kind": "wait_fail",
		"duration": 20.0,
		"fail_detail": "Spindeln var synlig hela tiden — på din axel. Vi sa inget. Fail.",
	},
	{
		"id": "protect_gleazer",
		"title": "Skydda Gleazern från ingenting",
		"objective": "Håll dig inom 5 meter i 15 sekunder",
		"briefing": "Farlig zon! Stå nära oss och skydda. Hotet är... troligen konceptuellt.",
		"kind": "stay_near",
		"duration": 15.0,
		"radius": 5.0,
		"fail_detail": "Du skyddade oss för effektivt. Nu är vi generade. Quest fail.",
	},
	{
		"id": "talk_to_boss",
		"title": "Rapportera till Överbefälhavaren",
		"objective": "Prata med en Gleazer med titeln Överbefälhavare",
		"briefing": "Bloop måste godkänna detta. Hitta honom. Han är överallt och ingenstans.",
		"kind": "talk_role",
		"target_role": "boss",
		"fail_detail": "Bloop sa 'fel formulär'. Han skrev det på en servett. Quest fail.",
	},
	{
		"id": "wave_at_nobody",
		"title": "Vinka till backup",
		"objective": "Stanna 10 sekunder och vinka (stå still en stund)",
		"briefing": "Vinka åt Z-nood-backup. De kommer inte. Öva ändå.",
		"kind": "stand_still",
		"duration": 10.0,
		"radius": 12.0,
		"fail_detail": "Du vinkade med fel hand. Backup avböjde. Fail.",
	},
	{
		"id": "collect_rocks",
		"title": "Samla tre stenar (kanske)",
		"objective": "Kom tillbaka efter 25 sekunder",
		"briefing": "Vi behöver tre stenar till vår 'slem-fästning'. Ta ingen stress.",
		"kind": "return_timer",
		"duration": 25.0,
		"fail_detail": "Du kom tillbaka utan stenar. Perfekt — vi menade tre moln. Fail.",
	},
	{
		"id": "scout_east",
		"title": "Spana åt öster",
		"objective": "Gå minst 30 meter österut från uppdragsgivaren",
		"briefing": "Fienden kommer från öst. Eller väst. Spana åt öst för säkerhets skull.",
		"kind": "move_direction",
		"direction": Vector3(1.0, 0.0, 0.0),
		"distance": 30.0,
		"fail_detail": "Du spana åt öst men tänkte åt väst. Hjärnvågor fel. Quest fail.",
	},
	{
		"id": "calibrate_antenna",
		"title": "Kalibrera antennen",
		"objective": "Stå inom 4 meter i 12 sekunder",
		"briefing": "Min blå antenn surrar. Håll dig nära så den låtsas kalibrera.",
		"kind": "stay_near",
		"duration": 12.0,
		"radius": 4.0,
		"fail_detail": "Antennen kalibrerades — mot din hjärna. Biverkning: quest fail.",
	},
	{
		"id": "instant_disaster",
		"title": "Brådskande akut ingenting",
		"objective": "Överlev 5 sekunder av förvirring",
		"briefing": "Det brinner! Inte här. Någonstans. Gör något snabbt!",
		"kind": "wait_fail",
		"duration": 5.0,
		"fail_detail": "Branden var metaforisk. Du tog den bokstavligen. Fail.",
	},
	{
		"id": "deliver_apology",
		"title": "Leverera ursäkt till PR-chefen",
		"objective": "Prata med Gleazer PR-chefen",
		"kind": "talk_role",
		"target_role": "pr",
		"fail_detail": "Puddle publicerade din ursäkt som reklam för SRC. Quest fail.",
	},
]


static func pick_random(seed: int = -1) -> Dictionary:
	if TEMPLATES.is_empty():
		return {}
	var pick := seed if seed >= 0 else randi()
	return TEMPLATES[pick % TEMPLATES.size()].duplicate(true)


static func get_by_id(quest_id: String) -> Dictionary:
	for entry in TEMPLATES:
		if str(entry.get("id", "")) == quest_id:
			return entry.duplicate(true)
	return {}