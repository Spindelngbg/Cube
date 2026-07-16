class_name ZezzlorPaCatalog
extends RefCounted

const WARNING_LINES: Array[Dictionary] = [
	{
		"text": "Medborgare. Kolonin påminner: brott bestraffas. Zezzlor ser allt.",
	},
	{
		"text": "Påminnelse från ordningsmakten. Inget våld mot civila. Inget sabotage. Inget tjafs.",
	},
	{
		"text": "Varning. Hackade hisskort till huvudkuben leder till omedelbar avrättning. Ingen överklagan.",
	},
	{
		"text": "Hiss till huvudkuben kräver giltigt Z-nood. Förfalskat kort likställs med självmord.",
	},
	{
		"text": "Vapenlag: endast godkänd Slimeshooter är tillåten i kolonin. Allt annat är brott.",
	},
	{
		"text": "Du bär ett vapen som inte är Slimeshooter? Det är ett brott. Lägg ner det — eller batong.",
	},
	{
		"text": "Kolonin tolererar inte oregistrerade vapen. Slimeshooter eller inget.",
	},
	{
		"text": "Stöld, rån och falsklarm via Z-nood registreras. Batong väntar.",
	},
]

const MOCKERY_LINES: Array[Dictionary] = [
	{
		"text": "Ha ha ha! Titta på gemene man — stapplar runt som om kolonin vore en gåva.",
		"laugh": true,
	},
	{
		"text": "Fniss. Vi hörde att gemene man försökte tänka själv. Så gulligt.",
		"laugh": true,
	},
	{
		"text": "He he he! Gemene man tror att reglerna inte gäller dem. Klassiskt.",
		"laugh": true,
	},
	{
		"text": "Skrattar lite. Gemene man luktar panik och dåliga beslut redan på avstånd.",
		"laugh": true,
	},
	{
		"text": "Ha! Där går en till utan uniform, utan Z-nood och utan hjärna. Vardag i kolonin.",
		"laugh": true,
	},
	{
		"text": "Pff. Gemene man tror att vi Zezzlor patrullerar för skojs skull. Nej.",
		"laugh": true,
	},
	{
		"text": "Höhö! En till som gömmer ett vapen i fickan. Vi ser det ändå, gemene man.",
		"laugh": true,
	},
	{
		"text": "Fniss fniss. Gemene man klagar på batonger men älskar att bryta mot reglerna.",
		"laugh": true,
	},
	{
		"text": "Ha ha! Kolonin skulle stå still utan oss — gemene man skulle redan ha saboterat hissen.",
		"laugh": true,
	},
	{
		"text": "He he! Där har vi gemene man igen. Ingen rang, ingen respekt, mycket snack.",
		"laugh": true,
	},
]


static func pick_random(seed: int = -1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed if seed >= 0 else randi()
	var use_mockery := rng.randf() < 0.38
	var pool: Array = MOCKERY_LINES if use_mockery else WARNING_LINES
	return (pool[rng.randi() % pool.size()] as Dictionary).duplicate(true)