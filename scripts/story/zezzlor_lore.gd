class_name ZezzlorLore
extends RefCounted

const FACTION_NAME := "Zezzlor"
const FACTION_DESC := (
	"Kolonins ordnings- och lagmakt — blåklädda med batong. "
	+ "SRC och andra företag kan ha egna väktare; det är inte samma sak."
)

const RANKS := {
	"recruit": {
		"title": "Rekryt",
		"abbrev": "Rek",
		"color": Color(0.55, 0.72, 0.95),
	},
	"patrol": {
		"title": "Patrull",
		"abbrev": "Pat",
		"color": Color(0.42, 0.65, 0.92),
	},
	"officer": {
		"title": "Officer",
		"abbrev": "Off",
		"color": Color(0.32, 0.58, 0.88),
	},
	"sergeant": {
		"title": "Sergant",
		"abbrev": "Sgt",
		"color": Color(0.22, 0.48, 0.82),
	},
	"inspector": {
		"title": "Inspektör",
		"abbrev": "Ins",
		"color": Color(0.18, 0.38, 0.78),
	},
	"contract": {
		"title": "Kontrakt",
		"abbrev": "Ktr",
		"color": Color(0.38, 0.52, 0.9),
	},
	"superman": {
		"title": "Super-Zezzla",
		"abbrev": "Sup",
		"color": Color(1.0, 0.84, 0.18),
	},
	"jailer": {
		"title": "Fängslare",
		"abbrev": "Fng",
		"color": Color(0.62, 0.38, 0.95),
	},
	"allmakare": {
		## Healing caste within the Zezzlor / Zezzla order — label must say so.
		"title": "Allmakare · Zezzlor",
		"abbrev": "All",
		"color": Color(0.95, 0.86, 0.32),
	},
}

const CHASE_RANK_ORDER: Array[String] = ["recruit", "patrol", "officer", "sergeant"]

const PATROL_QUESTIONS: Array[String] = [
	"Hej, okänd person. Vad gör du här? Något brott på gång?",
	"Ursäkta — du är inte Zezzlor, eller hur? Varför krämar du runt här?",
	"God dag. Jag noterar att du inte bär kolonins blå uniform. Kan du förklara din närvaro?",
	"Hälsningar, främling. Patrullerar du också, eller bara... står du här?",
	"Vi Zezzlor håller ordning här. Vad exakt är ditt uppdrag i den här zonen?",
	"Förlåt avbrottet — du ser förvirrad ut. Ska jag rapportera dig, eller har du en ursäkt?",
	"Kolonin välkomnar besökare, men vi frågar ändå: vad gör du här utan Zezzlor-esort?",
	"Artig hälsning till dig, icke-Zezzlor. Har du tillstånd att röra dig fritt här?",
	"Jag patrullerar för er alla — även er som inte förtjänat uniformen. Vad söker du?",
	"Stopp lite. Du rör dig som någon som gömmer något i fickorna — eller i samvetet.",
	"Kolonins lag gäller även för tjocka ben. Var är du på väg?",
	"Jag har stått här länge nog för att känna igen fel folk. Du är ny, eller?",
	"Zezzlor-fråga nummer ett: varför är du inte Zezzlor?",
	"Du ser ut som du letar efter trubbel. Eller apotek. Eller båda.",
	"Vi blåa håller koll. Vad är din ursäkt den här fina dagen?",
	"Artig kontroll, inget personligt. Vad har du i ärende i blocket?",
	"Jag patrullerar, du vandrar. Skillnaden är uniformen — och batongen.",
	"Kolonin 4 tolererar gäster. Den tolererar inte dåliga svar.",
	"Du går tungt. Antingen dåligt samvete eller för mycket loot.",
	"En fråga från patrullen: är det här din zon, eller lånar du den?",
	"Jag ställer bara en sak — vad gör du här utan Z-nood-stämpel i närheten?",
	"Vi Zezzlor pratar mycket. Det är för att vi faktiskt lyssnar. Förklara dig.",
	"Du verkar vänlig. Det är misstänkt. Vad är din plan?",
	"Kort rutinkontroll: vem är du, var går du, och varför just nu?",
]

const CHASE_OPENERS: Array[String] = [
	"Jag är här för ordning i kolonin. Släpp slem mot civila — annars tas batongen fram.",
	"Slem mot civil? Det räknas som inbjudan till hela patrullen.",
	"Du sköt. Vi jagar. Kolonins regler är enkla — och tjocka.",
	"Sluta spruta slem. Batongen är redan på väg.",
	"Ordning ska hållas. Du valde kaos — nu får du oss.",
	"Det där var inte självförsvar. Det var ett brott med extra slem.",
	"Jag springer inte fort. Jag springer envist. Stanna.",
	"Kolonin har nolltolerans mot slem i ansiktet på oskyldiga.",
	"Du kan springa. Vi är fler. Vi är blå. Vi är tröga men nära.",
	"Patrullen svarar på våld med fler patruller. Grattis — du kallade hit oss.",
]


static func get_rank(rank_id: String) -> Dictionary:
	return RANKS.get(rank_id, RANKS.patrol)


static func rank_title(rank_id: String) -> String:
	return str(get_rank(rank_id).get("title", "Patrull"))


static func rank_color(rank_id: String) -> Color:
	var rank: Dictionary = get_rank(rank_id)
	if rank.has("color"):
		return rank["color"] as Color
	return Color(0.45, 0.72, 1.0)


static func format_name(rank_id: String, personal_name: String = "") -> String:
	var title := rank_title(rank_id)
	var name := personal_name.strip_edges()
	if name != "":
		return "[%s] %s" % [title, name]
	return "[%s] %s" % [title, FACTION_NAME]


## Rensa talrader — namn och rang är bara namnskylt, inte något de säger högt.
static func sanitize_spoken_line(line: String) -> String:
	var out := line.strip_edges()
	if out.begins_with("{name}:"):
		out = out.substr("{name}:".length()).strip_edges()
	return out


static func format_dialogue_title(rank_id: String, personal_name: String, subtitle: String = "") -> String:
	var base := format_name(rank_id, personal_name)
	if subtitle.strip_edges() != "":
		return "%s — %s" % [base, subtitle.strip_edges()]
	return base


static func chase_alert_body(rank_ids: Array) -> String:
	var labels: PackedStringArray = []
	for rank_id in rank_ids:
		labels.append(format_name(str(rank_id)))
	return (
		"%s svarar på slem mot civila.\n%s jagar dig med batong."
		% [FACTION_NAME, ", ".join(labels)]
	)


static func baton_strike_body(_rank_id: String = "", _personal_name: String = "") -> String:
	return "Batongen höjs."


static func pick_patrol_question(seed: int = -1) -> String:
	if PATROL_QUESTIONS.is_empty():
		return "Hej, okänd person. Vad gör du här?"
	var pick := seed if seed >= 0 else randi()
	return PATROL_QUESTIONS[pick % PATROL_QUESTIONS.size()]


static func chase_conversation_body(_rank_id: String = "", _personal_name: String = "", seed: int = -1) -> String:
	var pick := seed if seed >= 0 else randi()
	return CHASE_OPENERS[pick % CHASE_OPENERS.size()]


static func get_player_responses(context: String) -> Array:
	if context == "chase":
		return _CHASE_RESPONSES.duplicate(true)
	if context == "backup":
		return _BACKUP_RESPONSES.duplicate(true)
	if context == "backup_followup":
		return _BACKUP_FOLLOWUP_RESPONSES.duplicate(true)
	return _PATROL_RESPONSES.duplicate(true)


static func get_zezzlor_reaction(
	response_id: String,
	_rank_id: String = "",
	context: String = "patrol",
	_personal_name: String = ""
) -> String:
	var pool: Array = _PATROL_RESPONSES
	if context == "chase":
		pool = _CHASE_RESPONSES
	elif context == "backup" or context == "backup_followup":
		pool = _BACKUP_RESPONSES if context == "backup" else _BACKUP_FOLLOWUP_RESPONSES
	for entry in pool:
		if str(entry.get("id", "")) != response_id:
			continue
		var reactions: Array = entry.get("reactions", [])
		if not reactions.is_empty():
			var idx := absi(hash("%s:%s:%s" % [response_id, context, _personal_name])) % reactions.size()
			return sanitize_spoken_line(str(reactions[idx]))
		return sanitize_spoken_line(str(entry.get("reaction", "")))
	return "Noterat. Du får gå — för den här gången."


const DISMISS_LINES: Array[String] = [
	"Suckar artigt. Inget svar? Då skriver jag upp tystnad som misstänkt beteende.",
	"Du säger inget. Jag skriver allt. Det är skillnaden mellan oss.",
	"Tystnad är också ett svar — ett dåligt ett.",
	"Okej. Jag noterar att du valde att inte samarbeta. Klassiskt.",
	"Inget svar från icke-Zezzlor. Jag lägger det i pärm B.",
	"Du stängde samtalet utan ord. Batongen blev inte glad, men den förstår.",
	"Tyst. Misstänkt. Dokumenterat. Ha en fortsatt tveksam dag.",
]


static func dismiss_without_answer(_rank_id: String = "", _personal_name: String = "", seed: int = -1) -> String:
	var pick := seed if seed >= 0 else randi()
	return DISMISS_LINES[pick % DISMISS_LINES.size()]


const _PATROL_RESPONSES: Array = [
	{
		"id": "visitor",
		"player": "Hej! Jag är bara en besökare som tittar runt.",
		"reaction": "Mm. Besökare utan uniform. Jag skriver upp det — för säkerhets skull.",
	},
	{
		"id": "shopping",
		"player": "Jag letar efter en butik eller en vän.",
		"reaction": "Då bör du gå snabbare. Vi Zezzlor gillar inte folk som står och glor.",
	},
	{
		"id": "innocent",
		"player": "Inget brott, jag lovar.",
		"reaction": "Löften är billiga bland icke-Zezzlor. Jag håller ögonen på dig.",
	},
	{
		"id": "defiant",
		"player": "Har du problem med det?",
		"reaction": "Problem? Nej. Rutin. Stanna kvar så länge du vill — vi patrullerar.",
	},
	{
		"id": "worker",
		"player": "Jag arbetar för kolonin, tro mig.",
		"reaction": "Utan blå uniform? Overkligt. Visa Z-nood om du har tillstånd.",
	},
	{
		"id": "leave",
		"player": "Förlåt, jag går nu.",
		"reaction": "Bra. Gå i lugnt tempo — vi ses säkert igen.",
	},
]

const _CHASE_RESPONSES: Array = [
	{
		"id": "accident",
		"player": "Det var en olycka — jag menade inget!",
		"reaction": "Olyckor räknas inte när slem träffar civila. Stanna.",
	},
	{
		"id": "self_defense",
		"player": "Jag försvarade mig bara.",
		"reaction": "Mot vem? Inte mot Zezzlor, hoppas jag. Batongen är redan varm.",
	},
	{
		"id": "sorry",
		"player": "Förlåt, jag slutar skjuta nu.",
		"reaction": "Fint. Lägg undan vapnet så slipper du fler av oss.",
	},
	{
		"id": "deny",
		"player": "Jag har inte gjort något!",
		"reaction": "Då förklarar du det till hela patrullen — med batong som bisarr.",
	},
	{
		"id": "run",
		"player": "Jag sticker härifrån!",
		"reaction": "Spring. Vi Zezzlor älskar jakt — det står i handboken.",
	},
]

const BACKUP_ARRIVAL_LINES: Array[String] = [
	"Znood-signal mottagen. Var är problemet? Tala snabbt.",
	"Vi kom i pansarfordon — kolonin förväntar sig svar. Vad har hänt?",
	"Patrull APC på plats. Peka ut bråket eller förklara dig.",
	"Flera Zezzlor-enheter avlossade. Beskriv hotet — exakt.",
]

const BACKUP_NO_TROUBLE_LINES: Array[String] = [
	"Inget hittat åt det hållet. Du slösade vår tid.",
	"Tomt. Inga hot. Misstänkt falsklarm.",
	"Vi ser inget problem. Det här luktar fel.",
]


static func pick_backup_arrival_line(seed: int = -1) -> String:
	var pick := seed if seed >= 0 else randi()
	return BACKUP_ARRIVAL_LINES[pick % BACKUP_ARRIVAL_LINES.size()]


static func pick_backup_no_trouble_line(seed: int = -1) -> String:
	var pick := seed if seed >= 0 else randi()
	return BACKUP_NO_TROUBLE_LINES[pick % BACKUP_NO_TROUBLE_LINES.size()]


const BACKUP_FOLLOWUP_LINES: Array[String] = [
	"Vi ser din riktningsmarkör. Hur många är inblandade?",
	"APC-vapnen är laddade. Är det vapen inblandat åt det hållet?",
	"Fängslaren står redo. Ska vi gripa någon eller bara skingra bråket?",
	"Kolonin kräver detaljer. Beskriv exakt vad du såg — en gång till.",
]


static func pick_backup_followup_line(seed: int = -1) -> String:
	var pick := seed if seed >= 0 else randi()
	return BACKUP_FOLLOWUP_LINES[pick % BACKUP_FOLLOWUP_LINES.size()]


const _BACKUP_FOLLOWUP_RESPONSES: Array = [
	{
		"id": "confirm_scan",
		"player": "Ja — kolla markören nu, hotet är där!",
		"reaction": "Bekräftat. Patrullen rör sig mot din markör.",
	},
	{
		"id": "add_detail",
		"player": "De skrek och slog — precis åt det hållet jag pekade.",
		"reaction": "Noterat. Vi skannar zonen du angav.",
	},
	{
		"id": "urgent",
		"player": "Skynda — det pågår just nu!",
		"reaction": "Förstått. Full fart mot riktningsmarkören.",
	},
	{
		"id": "backpedal",
		"player": "Vänta… kanske var inget ändå.",
		"reaction": "Du ändrar dig? Misstänkt. Batonger fram.",
	},
]


const _BACKUP_RESPONSES: Array = [
	{
		"id": "point_direction",
		"player": "Bråket är åt det håll jag pekar — kolla där!",
		"reaction": "Förstått. Patrullen går dit nu. Stanna här.",
	},
	{
		"id": "hybrid_threat",
		"player": "Det är zombier / SRC-hybrid där borta!",
		"reaction": "Hybridhot bekräftat via Z-nood. Vi skickar patrull dit.",
	},
	{
		"id": "player_fight",
		"player": "Någon bråkar med civila åt det hållet.",
		"reaction": "Civil konflikt noterad. Vi utreder omedelbart.",
	},
	{
		"id": "false_alarm",
		"player": "Förlåt, falsklarm — allt lugnt.",
		"reaction": "Falsklarm? Då får du betala med batong och cell.",
	},
	{
		"id": "deny_backup",
		"player": "Jag vet inte vad ni pratar om.",
		"reaction": "Dåligt svar. Fängslare, förbered raygun.",
	},
	{
		"id": "rude",
		"player": "Sluta trakassera mig, Zezzlor.",
		"reaction": "Trakasseri? Vi är lagen. Batonger fram.",
	},
]