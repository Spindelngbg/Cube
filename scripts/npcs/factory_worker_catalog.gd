class_name FactoryWorkerCatalog
extends RefCounted

## Kollegor på fabriken — båda kön, personligheter, stort ordförråd, mänskliga nyanser.

const DcZoneCatalogScript = preload("res://scripts/city/dc_zone_catalog.gd")
const FactoryWorkBuilderScript = preload("res://scripts/city/factory_work_builder.gd")

## Personality: warm | sarcastic | flirt | grumpy | shy | professional | chaotic
const WORKERS: Array = [
	{
		"id": "factory_worker_mira",
		"name": "Mira Voss",
		"role": "skiftledare",
		"gender": "kvinna",
		"personality": "warm",
		"model": "character-f",
		"tint": Color(0.95, 0.72, 0.55),
		"offset": Vector3(-9.5, 0.0, -7.5),
		"rotation_y": 0.4,
	},
	{
		"id": "factory_worker_jon",
		"name": "Jon Halden",
		"role": "pressoperatör",
		"gender": "man",
		"personality": "sarcastic",
		"model": "character-c",
		"tint": Color(0.55, 0.62, 0.7),
		"offset": Vector3(5.5, 0.0, -1.0),
		"rotation_y": -0.8,
	},
	{
		"id": "factory_worker_nova",
		"name": "Nova Rilke",
		"role": "packare",
		"gender": "kvinna",
		"personality": "flirt",
		"model": "character-k",
		"tint": Color(0.85, 0.55, 0.75),
		"offset": Vector3(11.0, 0.0, 4.5),
		"rotation_y": PI,
	},
	{
		"id": "factory_worker_erik",
		"name": "Erik Sköld",
		"role": "lastare",
		"gender": "man",
		"personality": "grumpy",
		"model": "character-h",
		"tint": Color(0.5, 0.48, 0.42),
		"offset": Vector3(1.5, 0.0, -8.5),
		"rotation_y": 0.2,
	},
	{
		"id": "factory_worker_lin",
		"name": "Lin Okada",
		"role": "kvalitetskontroll",
		"gender": "kvinna",
		"personality": "professional",
		"model": "character-d",
		"tint": Color(0.7, 0.78, 0.92),
		"offset": Vector3(-3.5, 0.0, -3.5),
		"rotation_y": 1.2,
	},
	{
		"id": "factory_worker_theo",
		"name": "Theo Brink",
		"role": "nybörjare",
		"gender": "man",
		"personality": "shy",
		"model": "character-b",
		"tint": Color(0.65, 0.7, 0.55),
		"offset": Vector3(-11.0, 0.0, 2.0),
		"rotation_y": -0.3,
	},
	{
		"id": "factory_worker_siri",
		"name": "Siri Dahl",
		"role": "underhåll",
		"gender": "kvinna",
		"personality": "chaotic",
		"model": "character-n",
		"tint": Color(0.55, 0.85, 0.7),
		"offset": Vector3(9.0, 0.0, -6.0),
		"rotation_y": -1.4,
	},
	{
		"id": "factory_worker_axel",
		"name": "Axel Moon",
		"role": "bandtekniker",
		"gender": "man",
		"personality": "flirt",
		"model": "character-g",
		"tint": Color(0.75, 0.58, 0.45),
		"offset": Vector3(-5.5, 0.0, 0.5),
		"rotation_y": 2.2,
	},
]


static func get_spawn_entries(spawn_id: String) -> Array:
	if SpawnPoints.normalize_id(spawn_id) != "satellite_right":
		return []
	var factory_center := _factory_local_center()
	var out: Array = []
	for w in WORKERS:
		var entry: Dictionary = w.duplicate(true)
		entry["factory_worker"] = true
		entry["local_pos"] = factory_center + (w.offset as Vector3)
		entry["wander"] = true
		entry["wander_radius"] = 3.2
		entry["speed"] = 0.75
		entry["scale"] = 1.0
		entry["prompt"] = "Prata med %s [E]" % str(w.name)
		entry["name"] = "%s — %s" % [str(w.name), str(w.role)]
		out.append(entry)
	return out


static func get_worker(npc_id: String) -> Dictionary:
	for w in WORKERS:
		if str(w.get("id", "")) == npc_id:
			return w
	return {}


static func pick_open_line(npc_id: String, on_shift: bool, cycles: int) -> Dictionary:
	var w := get_worker(npc_id)
	if w.is_empty():
		return {"title": "Kollega", "body": "Hej."}
	var name := str(w.get("name", "Kollega"))
	var role := str(w.get("role", "arbetare"))
	var personality := str(w.get("personality", "warm"))
	var gender := str(w.get("gender", ""))
	var pool: Array = _openers(personality, gender, on_shift, cycles)
	var idx := absi(hash("%s:%d:%s" % [npc_id, cycles, str(on_shift)])) % maxi(pool.size(), 1)
	var body := str(pool[idx]) if not pool.is_empty() else "Hej."
	return {
		"title": "%s — %s" % [name, role],
		"body": body,
		"personality": personality,
		"gender": gender,
		"name": name,
	}


static func get_player_responses(personality: String, on_shift: bool) -> Array:
	var base: Array = [
		{
			"id": "friendly",
			"player": "Hej! Hur är skiftet i dag?",
		},
		{
			"id": "work_tip",
			"player": "Något tips om flödet här inne?",
		},
		{
			"id": "joke",
			"player": "Om bandet strejkar, strejkar vi med det — eller hur?",
		},
		{
			"id": "compliment",
			"player": "Du ser ut att ha koll. Respekt.",
		},
		{
			"id": "flirt",
			"player": "Är det bara fabriksljusen som får dig att glöda, eller…?",
		},
		{
			"id": "rude",
			"player": "Sluta hänga över mig. Jag har ett jobb att göra.",
		},
		{
			"id": "pay",
			"player": "Är lönen rättvis, eller är det bara propaganda?",
		},
		{
			"id": "leave",
			"player": "Jag måste springa vidare. Vi ses.",
		},
	]
	if not on_shift:
		base.insert(1, {
			"id": "how_start",
			"player": "Hur börjar man jobba här egentligen?",
		})
	# Personality-tweak: grumpy/shy react worse to flirt — still offer it.
	if personality == "professional":
		base.insert(2, {
			"id": "process",
			"player": "Kan du gå igenom kvalitetskraven snabbt?",
		})
	return base


static func get_reaction(
	npc_id: String,
	response_id: String,
	on_shift: bool,
	cycles: int
) -> String:
	var w := get_worker(npc_id)
	var personality := str(w.get("personality", "warm"))
	var gender := str(w.get("gender", ""))
	var name := str(w.get("name", "Kollega"))
	var lines: Array = _reactions(personality, response_id, gender, on_shift, cycles, name)
	if lines.is_empty():
		return "…mm. Okej."
	var idx := absi(hash("%s:%s:%d" % [npc_id, response_id, cycles])) % lines.size()
	return str(lines[idx])


static func _factory_local_center() -> Vector3:
	var cell := FactoryWorkBuilderScript.FACTORY_CELL
	return Vector3(
		float(cell.x) * DcZoneCatalogScript.BLOCK_M + DcZoneCatalogScript.BLOCK_M * 0.5,
		0.0,
		float(cell.y) * DcZoneCatalogScript.BLOCK_M + DcZoneCatalogScript.BLOCK_M * 0.5
	)


static func _openers(personality: String, gender: String, on_shift: bool, cycles: int) -> Array:
	var shift_note := "Du är instämplad — bra." if on_shift else "Du är inte instämplad än."
	var cycle_note := ""
	if cycles > 0:
		cycle_note = " Jag såg dig klara %d cykel%s. Inte illa." % [cycles, "r" if cycles != 1 else ""]
	match personality:
		"warm":
			return [
				"Hej, du. Välkommen in i oljedoften och det lilla hoppet om lönedag. %s%s" % [shift_note, cycle_note],
				"Kom närmare, jag biter inte — pressen gör det. Kaffe finns i hörnet om du orkar lita på det.",
				"Kul att se ett nytt ansikte som inte bara tittar på klockan. Hur känns händerna? Råkorgarna är tunga första veckan.",
				"Vi håller ihop här. Om bandet strejkar hjälper vi varandra — om chefen strejkar… tja, då fikar vi längre.",
			]
		"sarcastic":
			return [
				"Åh, en frivillig. Vilken rar art. %s%s" % [shift_note, cycle_note],
				"Tryck inte på röda knappar om du inte menar det. Eller gör det — jag behöver underhållning.",
				"Du ser ut som någon som läser instruktioner. Det är… ovanligt. Nästan misstänkt.",
				"Välkommen till paradiset av skift och skavsår. Tips: låtsas att du gillar det. Det hjälper inte, men det ser fint ut.",
			]
		"flirt":
			if gender == "kvinna":
				return [
					"Hej där. Ny på golvet — eller bara ny för mig? %s" % shift_note,
					"Säg till om du vill ha en guidad tur. Jag kan peka på maskinerna… eller på dig. Båda är ganska snygga i det här ljuset.",
					"Råkorg i händerna, glimt i ögat — du klarar dig. Vill du ha sällskap till packbordet?",
					"De säger att man inte ska flörta i fabriken. De har aldrig sett hur tråkigt transportbandet är utan det.",
				]
			return [
				"Tjena. Du ser ut som någon som kan bära mer än en låda — och en konversation. %s" % shift_note,
				"Om du kör fel station skyller jag inte dig. Jag skyller på belysningen. Den får folk att se… distraherande bra ut.",
				"Vill du ha ett proffs-tips? Titta på knapparna, inte på mig. …Okej, titta lite på mig.",
				"Skiftet blir kortare om man pratar. Eller längre. Beror på vem man pratar med.",
			]
		"grumpy":
			return [
				"Vad? Prata fort. Bandet väntar inte. %s" % shift_note,
				"Om du ska ställa dumma frågor, gör det efter lastbryggan. Där är det i alla fall tystare.",
				"Jag är inte sur. Jag är realistisk. Det är dyrare.",
				"Nytt folk betyder nya misstag. Bevisa att du inte är en av dem. Snälla.",
			]
		"professional":
			return [
				"God dag. Flödet är intag → band → press → pack → last. Avvik inte utan orsak. %s%s" % [shift_note, cycle_note],
				"Kvalitet före tempo — men tempo utan kvalitet är bara dyrt skrot. Håll dig till ordningen.",
				"Säkerhetsglasögon är frivilliga. Fingrar är det inte. Välj klokt.",
				"Jag dokumenterar avvikelser. Vänligt, men noggrant. Du får gärna vara den trevliga avvikelsen.",
			]
		"shy":
			return [
				"Öh… hej. Jag… jobbar mest med intaget. %s" % shift_note,
				"Du behöver inte prata med mig om du inte vill. Men… det är okej om du vill.",
				"Pressen är högljudd. Jag gillar den. Den pratar inte tillbaka.",
				"Om jag mumlar är det inte dig det gäller. Det är… allt, ungefär.",
			]
		"chaotic":
			return [
				"HEJ! Har du sett min momentnyckel? Den var här. Nu är den… konceptuell. %s" % shift_note,
				"Jag fixade bandet i morse. Det gick fortare. Lite för fort. Vi pratar inte om det.",
				"Regler är som tejp: bra tills de inte sitter. Vill du se min genväg? Den är 40 % genial, 60 % brandfarlig.",
				"Kaffe, knappar, kaos — min treenighet. Du får vara med om du lovar att inte rapportera mig. Skämtar. Delvis.",
			]
		_:
			return ["Hej. Välkommen till verkstaden."]


static func _reactions(
	personality: String,
	response_id: String,
	gender: String,
	on_shift: bool,
	cycles: int,
	name: String
) -> Array:
	match response_id:
		"how_start":
			return [
				"Stämpla in vid gula klockan i entrén. Sen: hämta råkorg, starta band, pressa, packa, lämna last. Upprepa tills plånboken ler.",
				"Börja med stämpelklockan. Missar du ordningen nollställs streak-bonusen — så tänk mer dans, mindre slump.",
			]
		"work_tip":
			return _tip_lines(personality)
		"friendly":
			return _friendly_lines(personality, on_shift, cycles)
		"joke":
			return _joke_lines(personality)
		"compliment":
			return _compliment_lines(personality, gender)
		"flirt":
			return _flirt_lines(personality, gender)
		"rude":
			return _rude_lines(personality)
		"pay":
			return [
				"Lönen är ärlig för kolonin: du får Mydrillium per färdig cykel, mer om du håller streaken. Inte lyx — men inte löneslaveri heller.",
				"Chefen kallar det 'prestationsbaserat'. Jag kallar det 'tryck knappar, få mynt'. Det funkar.",
				"Jämfört med att bli biten av hybridzombies? Ja, det här är rättvist.",
			]
		"process":
			return [
				"Kontrollera att pressytan är ren, att etiketten sitter rakt, och att lådan inte rasslar som en skuld. Enkel checklista, stor skillnad.",
				"Om halvfabrikatet ser skevt ut — kör om pressen. Hellre en minut extra än en reklamation.",
			]
		"leave":
			return _leave_lines(personality, name)
		_:
			return ["Okej."]


static func _tip_lines(personality: String) -> Array:
	match personality:
		"professional":
			return [
				"Följ markeringarna på golvet. De är inte dekoration — de är den kortaste vägen mellan lön och misstag.",
				"Om du bär fel sak till fel station, stanna. Andas. Gå tillbaka. Panik kostar streak.",
			]
		"grumpy":
			return [
				"Tips: gör rätt första gången så slipper jag se dig springa i cirklar.",
				"Hämta rågods innan du leker med bandet. Det är inte rocket science. Det är bara metall och tålamod.",
			]
		"chaotic":
			return [
				"Officiellt tips: följ flödet. Inofficiellt: om knappen känns trög, knacka den. Om den känns för snäll, knacka den ändå.",
				"Jag har en genväg som sparar sju sekunder och tre nerver. Fråga mig inte om den är godkänd.",
			]
		_:
			return [
				"Råkorg → band → press → pack → last. Säg det högt om du måste. Det sätter sig.",
				"Håll streaken — bonusen är liten men den smakar som seger.",
			]


static func _friendly_lines(personality: String, on_shift: bool, cycles: int) -> Array:
	var cycle_bit := " Du har %d cykler i dag — respektingivande." % cycles if cycles > 0 else ""
	match personality:
		"warm":
			return [
				"Skiftet är okej. Lite bullrigt, lite varmt, lite hoppfullt.%s Kaffe i hörnet om du vill dela tystnad." % cycle_bit,
				"Bättre nu när du är här. Det låter fånigt, men nya ansikten gör hallen mindre grå.",
			]
		"sarcastic":
			return [
				"Hur skiftet är? Föreställ dig en monolog av en hydraulpress. Sen lägg till kaffe. Där är vi.",
				"Det går. Vilket i fabriksmått betyder att inget brinner just nu.",
			]
		"flirt":
			return [
				"Bättre sen du klev in, ska jag vara ärlig? Eller ska jag låtsas att jag pratar om ventilationen?",
				"Skiftet är… uthärdligt. Du får gärna göra det mer uthärdligt.",
			]
		"grumpy":
			return [
				"Det är ett skift. Det tar slut. Det är det bästa med det.",
				"Fråga inte hur det är om du inte vill ha sanningen. Sanningen är: buller.",
			]
		"shy":
			return [
				"Det… det går bra. Tack för att du frågar. De flesta gör inte det.",
				"Jag har haft värre dagar. Och tystare. Det här är okej.",
			]
		"professional":
			return [
				"Produktionen ligger inom tolerans. Moralen är… acceptabel. Du påverkar den positivt om du håller flödet.",
				"Stabilt skift. Inga stopp. Bra.",
			]
		"chaotic":
			return [
				"I dag har jag bara tappat en skruv i bandet. Personligt rekord!%s" % cycle_bit,
				"Skiftet är en soap opera med mer olja. Jag ger det fyra stjärnor.",
			]
		_:
			return ["Det går bra."]


static func _joke_lines(personality: String) -> Array:
	match personality:
		"sarcastic":
			return [
				"Bandet har redan fackförening. Den heter 'trögstart' och tar rasters när den vill.",
				"Om vi strejkar med bandet behöver vi skyltar. Jag har tejp. Det får duga som ideologi.",
			]
		"grumpy":
			return [
				"Humor på arbetstid. Modigt. Nästan lika modigt som att sticka fingrarna i pressen.",
				"Spara skämten till fikarummet. Här skrattar bara maskinerna — och det är inte av glädje.",
			]
		"flirt":
			return [
				"Jag strejkar gärna — om det är axel mot axel vid kaffeautomaten.",
				"Bandet kan strejka. Jag föredrar att dansa med det. Vill du leda?",
			]
		"chaotic":
			return [
				"Jag strejkade en gång i sju minuter. Sedan kom lönekalkylen och bad mig sluta vara konstnärlig.",
				"Strejk? Jag kallar det 'kreativ omplanering av prioriteringar'. Chefen kallar det 'Axel, sluta'.",
			]
		_:
			return [
				"Ha. Om bandet strejkar tar vi fika. Om vi strejkar tar bandet… troligen semester utan oss.",
				"Bra skämt. Skriv upp det på tavlan bredvid säkerhetsreglerna — det är ungefär lika tvingande.",
			]


static func _compliment_lines(personality: String, gender: String) -> Array:
	match personality:
		"shy":
			return [
				"Åh. Tack. Jag… ska bara titta på golvet en stund så jag inte ler för mycket.",
				"Det var snällt. Jag sparar den meningen till efter skiftet.",
			]
		"grumpy":
			return [
				"Smicker. Fint. Gör jobbet ändå.",
				"Jag har koll för att jag måste, inte för att jag är trevlig. Men… tack, antar jag.",
			]
		"flirt":
			return [
				"Respekt, va? Jag tar den — och ger dig en tillbaka. Du lär dig fort.",
				"Fortsätt så så får du både lön och ett leende. Dubbel valuta.",
			]
		"professional":
			return [
				"Tack. Kompetens märks. Fortsätt så.",
				"Noterat. Positiv feedback registrerad — informellt, men ändå.",
			]
		_:
			return [
				"Tack. Det värmer mer än pressen, och den är ganska varm.",
				"Snällt sagt. Vi behöver fler sådana meningar här inne.",
			]


static func _flirt_lines(personality: String, gender: String) -> Array:
	match personality:
		"flirt":
			return [
				"Oj. Direkt på sak. Jag gillar tempo — både på bandet och i konversationen. Fortsätt, men tappa inte lådan.",
				"Fabriksljusen tar äran, men du får en del. Vill du ta en runda vid lastbryggan 'för att kolla flödet'?",
				"Du är farlig för min koncentration. Lyckligtvis är jag professionell… ungefär 60 % av tiden.",
			]
		"warm":
			return [
				"Haha — det där var sött. Jag tar det som vänlig värme, inte som en policyöverträdelse. Än.",
				"Flört i fabriken? Klassiskt. Jag ler, men jag pekar dig också mot rätt knappar. Prioriteringar.",
			]
		"sarcastic":
			return [
				"Wow. Romantik bland hydraulik. Shakespeare hade gråtit olja. Försök igen efter att du packat en låda.",
				"Du flörtar med någon som luktar metall. Respekt för ambitionsnivån.",
			]
		"grumpy":
			return [
				"Nej. Inte intresserad. Jobba.",
				"Spara charmen till någon som inte räknar skift. Jag räknar skift.",
			]
		"shy":
			return [
				"Jag… uh… det blev varmt här. Är ventilationen trasig? Jag menar — tack? Jag tror jag sa tack.",
				"Oj. Jag behöver… titta på en knappsats nu. En säker knappsats. Med instruktioner.",
			]
		"professional":
			return [
				"Olämpligt under pågående produktion. Men… din timing var åtminstone verbal, inte fysisk. Fortsätt jobba.",
				"Jag noterar kommentaren som 'social friktion'. Låt oss återgå till flödet.",
			]
		"chaotic":
			return [
				"HA! Ja. Flörta mer. Det får mig att glömma att jag tappade en bricka i pressen. Vänta, det var kanske dåligt.",
				"Du och jag, kaffe efter skiftet, och en plan att 'bara kolla' om skorstenen fortfarande ryker. Det är en dejt. Typ.",
			]
		_:
			return ["…Okej då."]


static func _rude_lines(personality: String) -> Array:
	match personality:
		"grumpy":
			return [
				"Äntligen någon som pratar klarspråk. Gå då. Och se till att lasta rätt.",
				"Bra. Mindre snack, mer lådor. Vi är överens för en gångs skull.",
			]
		"warm":
			return [
				"Okej. Jag backar. Men om du behöver hjälp senare finns jag kvar — utan sarkasm, lovar jag.",
				"Förstått. Utrymme. Jag tar det inte personligt… mest.",
			]
		"flirt":
			return [
				"Aj. Kallt. Okej, proffs-läge på. Lycka till med knapparna, isprinsessa/isprins.",
				"Så du vill ha tystnad. Fint. Jag kan vara tyst. Svårt, men möjligt.",
			]
		"sarcastic":
			return [
				"Charmig. Vill du ha det skriftligt också, eller räcker den verbala kniven?",
				"Noterat: du är en solstråle. Jag går och pratar med en hydraulslang i stället. Den är trevligare.",
			]
		"shy":
			return [
				"Förlåt. Jag… går.",
				"Okej. Jag sa inget. Alltså, nu säger jag inget mer.",
			]
		"professional":
			return [
				"Respektlös ton registrerad. Återgå till arbetsuppgifter.",
				"Du får vara kort. Du får inte vara slarvig med flödet. Välj din strid.",
			]
		"chaotic":
			return [
				"Wow, okay boss. Jag försvinner in i underhållsschaktet och låtsas att jag är upptagen. Hejdå.",
				"Aggression noterad. Jag svarar med… att skruva ihop något högljutt i närheten. Orelaterat. Kanske.",
			]
		_:
			return ["Okej."]


static func _leave_lines(personality: String, name: String) -> Array:
	match personality:
		"warm":
			return ["Vi ses, då. Se upp för pressen — och för dig själv."]
		"flirt":
			return ["Stick inte för långt. Jag kan behöva… kvalitetssäkra dig senare."]
		"grumpy":
			return ["Ja ja. Gå."]
		"shy":
			return ["Hej… hej då. Lycka till."]
		"professional":
			return ["Avslutat samtal. Lycka till i flödet."]
		"sarcastic":
			return ["Spring vidare, hjälte. Försök att inte bli en incidentrapport."]
		"chaotic":
			return ["Vi ses! Om jag inte har sabbat något till dess. Skämtar. Delvis."]
		_:
			return ["Hejdå från %s." % name]
