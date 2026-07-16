class_name MydrilliumColonyQuestCatalog
extends RefCounted

const QUESTS := [
	{
		"id": "deliver_ore_5",
		"title": "Malmleverans till smältverket",
		"material": "raw_mydrillium_ore",
		"amount": 5,
		"bonus_md": 320,
		"description": "Kolonin behöver rå malm till raffinaderiet.",
	},
	{
		"id": "deliver_sludge_4",
		"title": "Slamfiltrering",
		"material": "mydrillium_sludge",
		"amount": 4,
		"bonus_md": 240,
		"description": "Tidalbassängerna måste muddras och slammet förädlas.",
	},
	{
		"id": "deliver_scrap_6",
		"title": "Skrotåtervinning",
		"material": "tech_scrap",
		"amount": 6,
		"bonus_md": 290,
		"description": "Industrikaj skickar in trasig utrustning — extra betalt för spår av mineral.",
	},
	{
		"id": "deliver_mixed",
		"title": "Blandad mineralleverans",
		"material": "raw_mydrillium_ore",
		"amount": 3,
		"bonus_md": 180,
		"description": "Snabb leverans till kolonins förråd.",
	},
]